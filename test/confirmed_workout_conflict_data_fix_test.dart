import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

const _uuid74 = '6c9dbb07-b094-47c9-bad2-ee83a7afc20b';
const _uuid75 = '343337f9-027e-4cda-8a5c-414d711911da';
const _uuid76 = 'c92e8971-07f3-474b-ae53-ce43593669e1';

void main() {
  test(
    'schema 15 guarded fix removes duplicates and queues only session 76',
    () async {
      final temp = await Directory.systemTemp.createTemp('trener-motya-fix-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

      var db = AppDb.forTesting(NativeDatabase(file));
      await _seedConflict(db);
      await db.customStatement('PRAGMA user_version = 15');
      await db.close();

      var automaticSyncTriggers = 0;
      db = AppDb.forTesting(NativeDatabase(file));
      db.configureAutomaticSyncTrigger(() => automaticSyncTriggers++);
      final sessions = await (db.select(
        db.workoutSessions,
      )..where((row) => row.id.isIn(const [74, 75, 76]))).get();
      final results = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.sessionId.isIn(const [74, 75, 76]))).get();
      final queue = await db.select(db.syncQueue).get();
      final payload = await db.buildWorkoutSyncPayload(_uuid76);
      final rebuild = await db.analyzeWorkoutSyncQueueRebuild();

      expect(sessions.map((row) => row.id), [76]);
      expect(results, hasLength(4));
      expect(results.every((row) => row.sessionId == 76), isTrue);
      expect(queue, hasLength(2));
      expect(queue.map((row) => row.entityExternalId).toSet(), {
        _uuid76,
        '10000000-0000-4000-8000-000000000077',
      });
      expect(
        queue.singleWhere((row) => row.entityExternalId == _uuid76).status,
        'PENDING',
      );
      expect(automaticSyncTriggers, 0);
      expect(payload, isNotNull);
      final payloadJson = jsonDecode(payload!.encode()) as Map<String, dynamic>;
      final exercises = (payloadJson['exercises'] as List)
          .cast<Map<String, dynamic>>();
      expect(exercises, hasLength(4));
      expect(exercises.last['name'], 'Супермен');
      expect(exercises.last['weight_kg'], 20.0);
      expect(exercises.last['reps'], 10);
      expect(rebuild.conflicts, isEmpty);
      expect(rebuild.payloadErrors, 0);

      final unrelatedSession = await (db.select(
        db.workoutSessions,
      )..where((row) => row.id.equals(77))).getSingle();
      final unrelatedResult = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(62))).getSingle();
      expect(
        unrelatedSession.externalId,
        '10000000-0000-4000-8000-000000000077',
      );
      expect(unrelatedResult.exerciseNameSnapshot, 'unrelated snapshot');
      expect(unrelatedResult.lastWeightKg, 12.5);
      expect(unrelatedResult.lastReps, 8);
      await db.close();
    },
  );

  test('confirmed workout conflict fix is idempotent', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-motya-fix-idempotent-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedConflict(db);
    await db.customStatement('PRAGMA user_version = 15');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    final firstQueue = await (db.select(
      db.syncQueue,
    )..where((row) => row.entityExternalId.equals(_uuid76))).getSingle();
    final firstResults = await (db.select(
      db.workoutExerciseResults,
    )..where((row) => row.sessionId.equals(76))).get();
    await db.customStatement('PRAGMA user_version = 15');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    final secondQueue = await (db.select(
      db.syncQueue,
    )..where((row) => row.entityExternalId.equals(_uuid76))).getSingle();
    final secondResults = await (db.select(
      db.workoutExerciseResults,
    )..where((row) => row.sessionId.equals(76))).get();

    expect(secondQueue.id, firstQueue.id);
    expect(secondQueue.payload, firstQueue.payload);
    expect(secondQueue.updatedAt, firstQueue.updatedAt);
    expect(secondResults, firstResults);
    expect(await _conflictSessions(db), [76]);
    await db.close();
  });

  test('guard skips the complete conflict when one result differs', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-motya-fix-skip-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedConflict(db, session75SupermanReps: 2);
    await db.customStatement('PRAGMA user_version = 15');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    expect(await _conflictSessions(db), [74, 75, 76]);
    expect(
      await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.sessionId.isIn(const [74, 75, 76]))).get(),
      hasLength(12),
    );
    final rebuild = await db.analyzeWorkoutSyncQueueRebuild();
    expect(rebuild.conflicts, hasLength(1));
    await db.close();
  });

  test('restore applies the guarded conflict fix safely', () async {
    final source = AppDb.forTesting(NativeDatabase.memory());
    await _seedConflict(source);
    final backup = await source.buildBackupPayload(
      appVersion: '1.15.2',
      buildNumber: '109',
    );
    backup['schemaVersion'] = 15;
    await source.close();

    var automaticSyncTriggers = 0;
    final restored = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(restored.close);
    restored.configureAutomaticSyncTrigger(() => automaticSyncTriggers++);
    await restored.importBackupPayload(backup);

    expect(await _conflictSessions(restored), [76]);
    expect(
      await (restored.select(
        restored.workoutExerciseResults,
      )..where((row) => row.sessionId.isIn(const [74, 75]))).get(),
      isEmpty,
    );
    expect(await restored.buildWorkoutSyncPayload(_uuid76), isNotNull);
    expect(automaticSyncTriggers, 0);
  });
}

Future<List<int>> _conflictSessions(AppDb db) async {
  final rows =
      await (db.select(db.workoutSessions)
            ..where((row) => row.id.isIn(const [74, 75, 76]))
            ..orderBy([(row) => OrderingTerm.asc(row.id)]))
          .get();
  return rows.map((row) => row.id).toList(growable: false);
}

Future<void> _seedConflict(AppDb db, {int session75SupermanReps = 1}) async {
  await db.getActiveExercises();
  await _insertIdentity(
    db,
    id: 253,
    uuid: 'ce672f3a-927b-40a9-b982-b9726abd37e7',
    name: 'Жим штанги на верх груди',
  );
  await _insertIdentity(
    db,
    id: 310,
    uuid: '7a3a762d-0dcf-4e12-8315-412a882f798d',
    name: 'Жим в хамере',
  );
  await _insertIdentity(
    db,
    id: 255,
    uuid: '7c57be41-dc72-4b85-b14e-b4da1f552e04',
    name: 'Сведение рук стоя',
  );
  await _insertIdentity(
    db,
    id: 257,
    uuid: '66acd7e5-ffa2-4bf8-9a74-ddc2a489c94e',
    name: 'Супермен с канатным грифом',
  );
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion.insert(
          id: '1772007727103362',
          externalId: const Value('5a6db5bf-3bae-4531-849c-1edbc7ef35db'),
          name: 'Мотя',
          gender: const Value('М'),
        ),
      );

  const sessionUuids = {74: _uuid74, 75: _uuid75, 76: _uuid76};
  for (final entry in sessionUuids.entries) {
    await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: Value(entry.key),
            externalId: Value(entry.value),
            clientId: '1772007727103362',
            performedAt: DateTime.fromMillisecondsSinceEpoch(1772010000000),
            planInstance: 1,
            gender: 'М',
            templateIdx: 4,
          ),
        );
  }

  var resultId = 50;
  for (final sessionId in const [74, 75, 76]) {
    final supermanReps = switch (sessionId) {
      74 => 18,
      75 => session75SupermanReps,
      _ => 10,
    };
    for (final result in [
      (25, 253, 'Жим штанги на верх груди', 2.5, 10),
      (26, 310, 'Жим в хаммере', 5.0, 10),
      (27, 255, 'Сведение рук стоя', 20.0, 10),
      (29, 257, 'Супермен', 20.0, supermanReps),
    ]) {
      await db
          .into(db.workoutExerciseResults)
          .insert(
            WorkoutExerciseResultsCompanion.insert(
              id: Value(resultId++),
              sessionId: sessionId,
              templateExerciseId: result.$1,
              exerciseIdentityId: Value(result.$2),
              exerciseNameSnapshot: Value(result.$3),
              lastWeightKg: Value(result.$4),
              lastReps: Value(result.$5),
            ),
          );
    }
  }

  await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          id: const Value(77),
          externalId: const Value('10000000-0000-4000-8000-000000000077'),
          clientId: '1772007727103362',
          performedAt: DateTime(2026, 2, 27, 12),
          planInstance: 1,
          gender: 'М',
          templateIdx: 5,
        ),
      );
  await db
      .into(db.workoutExerciseResults)
      .insert(
        WorkoutExerciseResultsCompanion.insert(
          id: const Value(62),
          sessionId: 77,
          templateExerciseId: 30,
          exerciseIdentityId: const Value(253),
          exerciseNameSnapshot: const Value('unrelated snapshot'),
          lastWeightKg: const Value(12.5),
          lastReps: const Value(8),
        ),
      );

  for (final uuid in [
    _uuid74,
    _uuid75,
    _uuid76,
    '10000000-0000-4000-8000-000000000077',
  ]) {
    await db.enqueueWorkoutSync(uuid, triggerAutoSync: false);
  }
}

Future<void> _insertIdentity(
  AppDb db, {
  required int id,
  required String uuid,
  required String name,
}) async {
  await db
      .into(db.exerciseIdentities)
      .insert(
        ExerciseIdentitiesCompanion.insert(
          id: Value(id),
          externalId: uuid,
          canonicalName: Value(name),
          normalizedName: Value(AppDb.normalizeExerciseName(name)),
        ),
      );
}
