import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

const _workoutUuid = '99d787bd-d229-4d3c-aabe-2986b2a4ca48';
const _canonicalExerciseUuid = '44998917-34b1-42e1-bfca-3ff98f50d178';

void main() {
  test(
    'schema 14 migration repairs only confirmed result and queues workout',
    () async {
      final temp = await Directory.systemTemp.createTemp('trener-hammer-fix-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

      var db = AppDb.forTesting(NativeDatabase(file));
      await _seedFixture(db);
      await db.customStatement('PRAGMA user_version = 14');
      await db.close();

      db = AppDb.forTesting(NativeDatabase(file));
      final fixed = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(2158))).getSingle();
      final unrelated = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(2159))).getSingle();
      final payload = await db.buildWorkoutSyncPayload(_workoutUuid);
    final rebuildPreview = await db.analyzeWorkoutSyncQueueRebuild();
      final queue = await db.select(db.syncQueue).get();

      expect(fixed.sessionId, 669);
      expect(fixed.templateExerciseId, -21);
      expect(fixed.exerciseIdentityId, 348);
      expect(fixed.exerciseNameSnapshot, 'молоточки');
      expect(fixed.lastWeightKg, 9.0);
      expect(fixed.lastReps, 10);
      expect(unrelated.exerciseIdentityId, 324);
      expect(unrelated.exerciseNameSnapshot, 'unrelated snapshot');
      expect(unrelated.lastWeightKg, 17.5);
      expect(unrelated.lastReps, 7);

      expect(payload, isNotNull);
      final json = jsonDecode(payload!.encode()) as Map<String, dynamic>;
      final exercises = (json['exercises'] as List)
          .cast<Map<String, dynamic>>();
      expect(exercises, hasLength(1));
      expect(exercises.single['exercise_id'], _canonicalExerciseUuid);
      expect(exercises.single['name'], 'молоточки');
      expect(exercises.single['weight_kg'], 9.0);
      expect(exercises.single['reps'], 10);
      expect(rebuildPreview.payloadErrors, 0);

      expect(queue, hasLength(1));
      expect(queue.single.entityExternalId, _workoutUuid);
      expect(queue.single.status, 'PENDING');
      expect(queue.single.attempts, 0);
      expect(queue.single.payload, payload.encode());
      await db.close();
    },
  );

  test('confirmed data fix is idempotent', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-hammer-fix-idempotent-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedFixture(db);
    await db.customStatement('PRAGMA user_version = 14');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    final firstQueue = await db.select(db.syncQueue).getSingle();
    final firstResult = await (db.select(
      db.workoutExerciseResults,
    )..where((row) => row.id.equals(2158))).getSingle();
    await db.customStatement('PRAGMA user_version = 14');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    final secondQueue = await db.select(db.syncQueue).getSingle();
    final secondResult = await (db.select(
      db.workoutExerciseResults,
    )..where((row) => row.id.equals(2158))).getSingle();

    expect(secondResult, firstResult);
    expect(secondQueue.id, firstQueue.id);
    expect(secondQueue.payload, firstQueue.payload);
    expect(secondQueue.updatedAt, firstQueue.updatedAt);
    expect(await db.select(db.syncQueue).get(), hasLength(1));
    await db.close();
  });

  test('confirmed data fix skips an unexpected source row', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-hammer-fix-skip-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedFixture(db, resultWeight: 8.5);
    await db.customStatement('PRAGMA user_version = 14');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    final unchanged = await (db.select(
      db.workoutExerciseResults,
    )..where((row) => row.id.equals(2158))).getSingle();

    expect(unchanged.exerciseIdentityId, 324);
    expect(unchanged.exerciseNameSnapshot, isNull);
    expect(unchanged.lastWeightKg, 8.5);
    expect(await db.select(db.syncQueue).get(), isEmpty);
    await db.close();
  });
}

Future<void> _seedFixture(AppDb db, {double resultWeight = 9.0}) async {
  await db.getActiveExercises();
  await db
      .into(db.exerciseIdentities)
      .insert(
        ExerciseIdentitiesCompanion.insert(
          id: const Value(324),
          externalId: '9cf98acc-49e1-4271-b4d1-a351f6a8efd7',
          canonicalName: const Value('Неизвестное упражнение 324'),
          normalizedName: const Value('неизвестное упражнение 324'),
          status: const Value(AppDb.archivedExerciseStatus),
        ),
      );
  await db
      .into(db.exerciseIdentities)
      .insert(
        ExerciseIdentitiesCompanion.insert(
          id: const Value(348),
          externalId: _canonicalExerciseUuid,
          canonicalName: const Value('Молотки сидя'),
          normalizedName: const Value('молотки сидя'),
          status: const Value(AppDb.activeExerciseStatus),
        ),
      );
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion.insert(
          id: '1772001915174699',
          externalId: const Value('bddef745-d881-4435-85c8-16f9652ecc08'),
          name: 'Павел',
          gender: const Value('М'),
        ),
      );
  await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          id: const Value(669),
          externalId: const Value(_workoutUuid),
          clientId: '1772001915174699',
          performedAt: DateTime.fromMillisecondsSinceEpoch(1774429200000),
          planInstance: 2,
          gender: 'М',
          templateIdx: 6,
        ),
      );
  await db
      .into(db.workoutExerciseResults)
      .insert(
        WorkoutExerciseResultsCompanion.insert(
          id: const Value(2158),
          sessionId: 669,
          templateExerciseId: -21,
          exerciseIdentityId: const Value(324),
          exerciseNameSnapshot: const Value(null),
          lastWeightKg: Value(resultWeight),
          lastReps: const Value(10),
        ),
      );

  await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          id: const Value(670),
          externalId: const Value('10000000-0000-4000-8000-000000000670'),
          clientId: '1772001915174699',
          performedAt: DateTime(2026, 3, 26, 12),
          planInstance: 2,
          gender: 'М',
          templateIdx: 5,
        ),
      );
  await db
      .into(db.workoutExerciseResults)
      .insert(
        WorkoutExerciseResultsCompanion.insert(
          id: const Value(2159),
          sessionId: 670,
          templateExerciseId: -22,
          exerciseIdentityId: const Value(324),
          exerciseNameSnapshot: const Value('unrelated snapshot'),
          lastWeightKg: const Value(17.5),
          lastReps: const Value(7),
        ),
      );
}
