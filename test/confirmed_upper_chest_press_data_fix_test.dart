import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

const _oldId = 236;
const _canonicalId = 290;
const _dumbbellId = 513;
const _oldUuid = '02179b87-ae75-4e0c-ba15-920861fc9010';
const _canonicalUuid = '8271280e-6aff-428d-b922-76dc958916ca';
const _dumbbellUuid = 'bec68760-2e03-412c-8251-d3548e3b833c';
const _canonicalName = 'Жим в тренажёре на верх груди';

const _dumbbellFixes =
    <
      ({
        int resultId,
        int sessionId,
        String workoutUuid,
        int performedAtSeconds,
        int planInstance,
        double weight,
        int reps,
      })
    >[
      (
        resultId: 1603,
        sessionId: 549,
        workoutUuid: 'a098f4b0-eac3-43b4-b48f-36aa8e5bafea',
        performedAtSeconds: 1773824400,
        planInstance: 1,
        weight: 20,
        reps: 12,
      ),
      (
        resultId: 3905,
        sessionId: 981,
        workoutUuid: '202a8e75-b8ab-4940-a448-c69bdc6eebb6',
        performedAtSeconds: 1776330000,
        planInstance: 2,
        weight: 20,
        reps: 12,
      ),
      (
        resultId: 6705,
        sessionId: 1469,
        workoutUuid: '685cf0a9-a1e6-4b00-8503-b1dd58321033',
        performedAtSeconds: 1779699600,
        planInstance: 3,
        weight: 10,
        reps: 10,
      ),
      (
        resultId: 8892,
        sessionId: 1865,
        workoutUuid: 'a33286c4-1086-44f7-a7ed-27ea09e43a41',
        performedAtSeconds: 1782896400,
        planInstance: 4,
        weight: 10,
        reps: 10,
      ),
      (
        resultId: 10300,
        sessionId: 2141,
        workoutUuid: '8d00e820-f332-40a1-b2c6-6692f29ba32e',
        performedAtSeconds: 1785315600,
        planInstance: 5,
        weight: 10,
        reps: 10,
      ),
    ];

void main() {
  test(
    'schema 17 merges, renames and repairs five historical results',
    () async {
      final temp = await Directory.systemTemp.createTemp('trener-chest-fix-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

      var db = AppDb.forTesting(NativeDatabase(file));
      await _seedFixture(db);
      await db.customStatement('PRAGMA user_version = 17');
      await db.close();

      var automaticSyncTriggers = 0;
      db = AppDb.forTesting(NativeDatabase(file));
      db.configureAutomaticSyncTrigger(() => automaticSyncTriggers++);

      final old = (await db.getExerciseById(_oldId))!;
      final canonical = (await db.getExerciseById(_canonicalId))!;
      final alias = await (db.select(
        db.exerciseIdentityAliases,
      )..where((row) => row.oldExternalId.equals(_oldUuid))).getSingle();
      expect(old.status, AppDb.archivedExerciseStatus);
      expect(old.mergedIntoIdentityId, _canonicalId);
      expect(alias.canonicalIdentityId, _canonicalId);
      expect(canonical.externalId, _canonicalUuid);
      expect(canonical.canonicalName, _canonicalName);

      final slot = await (db.select(
        db.workoutTemplateExercises,
      )..where((row) => row.id.equals(7000))).getSingle();
      final binding = await (db.select(
        db.exerciseIdentityBindings,
      )..where((row) => row.sourceId.equals(7000))).getSingle();
      expect(slot.exerciseIdentityId, _canonicalId);
      expect(slot.name, _canonicalName);
      expect(binding.identityId, _canonicalId);

      final mergedResult = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(30000))).getSingle();
      expect(mergedResult.exerciseIdentityId, _canonicalId);
      expect(mergedResult.exerciseNameSnapshot, 'Исторический жим');
      expect(mergedResult.lastWeightKg, 30);
      expect(mergedResult.lastReps, 11);

      final fixed = await _readDumbbellRows(db);
      expect(fixed, hasLength(5));
      for (final fix in _dumbbellFixes) {
        final row = fixed.singleWhere((item) => item.id == fix.resultId);
        expect(row.exerciseIdentityId, _dumbbellId);
        expect(row.exerciseNameSnapshot, 'Гантели');
        expect(row.lastWeightKg, fix.weight);
        expect(row.lastReps, fix.reps);
        expect(row.templateExerciseId, 65);

        final payload = await db.buildWorkoutSyncPayload(fix.workoutUuid);
        final json = jsonDecode(payload!.encode()) as Map<String, dynamic>;
        final exercise = (json['exercises'] as List).single as Map;
        expect(exercise['exercise_id'], _dumbbellUuid);
        expect(exercise['name'], 'Гантели');
      }
      final mergedPayload = await db.buildWorkoutSyncPayload(
        '10000000-0000-4000-8000-000000030000',
      );
      final mergedJson =
          jsonDecode(mergedPayload!.encode()) as Map<String, dynamic>;
      expect(
        ((mergedJson['exercises'] as List).single as Map)['exercise_id'],
        _canonicalUuid,
      );

      final queue = await db.select(db.syncQueue).get();
      expect(queue, hasLength(6));
      expect(
        queue.every((row) => row.status == 'PENDING' && row.attempts == 0),
        isTrue,
      );
      expect(automaticSyncTriggers, 0);
      final unrelated = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(30001))).getSingle();
      expect(unrelated.exerciseIdentityId, _canonicalId);
      expect(unrelated.exerciseNameSnapshot, 'unrelated');
      expect(unrelated.lastWeightKg, 12.5);
      expect(unrelated.lastReps, 8);
      final rebuild = await db.analyzeWorkoutSyncQueueRebuild();
      expect(rebuild.payloadErrors, 0);
      expect(rebuild.conflicts, isEmpty);
      await db.close();
    },
  );

  test('confirmed upper chest data fix is idempotent', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-chest-fix-idempotent-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');
    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedFixture(db);
    await db.customStatement('PRAGMA user_version = 17');
    await db.close();
    db = AppDb.forTesting(NativeDatabase(file));
    final firstQueue = await db.select(db.syncQueue).get();
    await db.customStatement('PRAGMA user_version = 17');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    expect(await db.select(db.syncQueue).get(), firstQueue);
    expect(
      (await db.getExerciseById(_oldId))!.mergedIntoIdentityId,
      _canonicalId,
    );
    expect(
      (await db.getExerciseById(_canonicalId))!.canonicalName,
      _canonicalName,
    );
    expect(
      (await _readDumbbellRows(
        db,
      )).every((row) => row.exerciseIdentityId == _dumbbellId),
      isTrue,
    );
    await db.close();
  });

  test('guard skips only a changed dumbbell result', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-chest-fix-guard-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');
    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedFixture(db, changedResultId: 1603);
    await db.customStatement('PRAGMA user_version = 17');
    await db.close();
    db = AppDb.forTesting(NativeDatabase(file));

    final skipped = await (db.select(
      db.workoutExerciseResults,
    )..where((row) => row.id.equals(1603))).getSingle();
    expect(skipped.exerciseIdentityId, _canonicalId);
    expect(skipped.exerciseNameSnapshot, 'Гантели');
    expect(skipped.lastWeightKg, 20.5);
    expect(
      (await _readDumbbellRows(
        db,
      )).where((row) => row.exerciseIdentityId == _dumbbellId),
      hasLength(4),
    );
    expect(await db.select(db.syncQueue).get(), hasLength(5));
    await db.close();
  });

  test('restore of a schema 17 backup applies both fixes', () async {
    final source = AppDb.forTesting(NativeDatabase.memory());
    await _seedFixture(source);
    final backup = await source.buildBackupPayload(
      appVersion: '1.15.4',
      buildNumber: '111',
    );
    backup['schemaVersion'] = 17;
    await source.close();

    var automaticSyncTriggers = 0;
    final restored = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(restored.close);
    restored.configureAutomaticSyncTrigger(() => automaticSyncTriggers++);
    await restored.importBackupPayload(backup);

    expect(
      (await restored.getExerciseById(_oldId))!.mergedIntoIdentityId,
      _canonicalId,
    );
    expect(
      (await restored.getExerciseById(_canonicalId))!.canonicalName,
      _canonicalName,
    );
    expect(
      (await _readDumbbellRows(
        restored,
      )).every((row) => row.exerciseIdentityId == _dumbbellId),
      isTrue,
    );
    expect(await restored.select(restored.syncQueue).get(), hasLength(6));
    expect(automaticSyncTriggers, 0);
  });
}

Future<List<WorkoutExerciseResult>> _readDumbbellRows(AppDb db) {
  return (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.isIn(_dumbbellFixes.map((fix) => fix.resultId))))
      .get();
}

Future<void> _seedFixture(AppDb db, {int? changedResultId}) async {
  await db.getActiveExercises();
  await (db.update(db.exerciseIdentities)..where(
        (row) => row.normalizedName.equals(_canonicalName.toLowerCase()),
      ))
      .write(
        const ExerciseIdentitiesCompanion(
          status: Value(AppDb.archivedExerciseStatus),
        ),
      );
  await _insertIdentity(
    db,
    id: _oldId,
    uuid: _oldUuid,
    name: _canonicalName,
    status: AppDb.archivedExerciseStatus,
  );
  await _insertIdentity(
    db,
    id: _canonicalId,
    uuid: _canonicalUuid,
    name: 'Жим в тренажёре на вверх груди',
  );
  await _insertIdentity(
    db,
    id: _dumbbellId,
    uuid: _dumbbellUuid,
    name: 'Жим гантелей под углом',
  );
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion.insert(
          id: '1772877700578140',
          externalId: const Value('10000000-0000-4000-8000-000000000003'),
          name: 'Елена (мамы)',
          gender: const Value('Ж'),
        ),
      );
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion.insert(
          id: 'merge-client',
          externalId: const Value('10000000-0000-4000-8000-000000000004'),
          name: 'Merge client',
          gender: const Value('М'),
        ),
      );

  final template = await (db.select(
    db.workoutTemplates,
  )..limit(1)).getSingleOrNull();
  await db
      .into(db.workoutTemplateExercises)
      .insert(
        WorkoutTemplateExercisesCompanion.insert(
          id: const Value(7000),
          templateId: template!.id,
          orderIndex: 1000,
          name: _canonicalName,
          exerciseIdentityId: const Value(_oldId),
        ),
      );
  await db
      .into(db.exerciseIdentityBindings)
      .insert(
        ExerciseIdentityBindingsCompanion.insert(
          sourceType: 'TEMPLATE',
          sourceId: 7000,
          identityId: _oldId,
        ),
      );

  await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          id: const Value(30000),
          externalId: const Value('10000000-0000-4000-8000-000000030000'),
          clientId: 'merge-client',
          performedAt: DateTime(2026, 1, 1, 12),
          planInstance: 1,
          gender: 'М',
          templateIdx: template.idx,
        ),
      );
  await db
      .into(db.workoutExerciseResults)
      .insert(
        WorkoutExerciseResultsCompanion.insert(
          id: const Value(30000),
          sessionId: 30000,
          templateExerciseId: 7000,
          exerciseIdentityId: const Value(_oldId),
          exerciseNameSnapshot: const Value('Исторический жим'),
          lastWeightKg: const Value(30),
          lastReps: const Value(11),
        ),
      );

  for (final fix in _dumbbellFixes) {
    await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: Value(fix.sessionId),
            externalId: Value(fix.workoutUuid),
            clientId: '1772877700578140',
            performedAt: DateTime.fromMillisecondsSinceEpoch(
              fix.performedAtSeconds * 1000,
            ),
            planInstance: fix.planInstance,
            gender: 'Ж',
            templateIdx: 2,
          ),
        );
    await db
        .into(db.workoutExerciseResults)
        .insert(
          WorkoutExerciseResultsCompanion.insert(
            id: Value(fix.resultId),
            sessionId: fix.sessionId,
            templateExerciseId: 65,
            exerciseIdentityId: const Value(_canonicalId),
            exerciseNameSnapshot: const Value('Гантели'),
            lastWeightKg: Value(
              fix.resultId == changedResultId ? fix.weight + 0.5 : fix.weight,
            ),
            lastReps: Value(fix.reps),
          ),
        );
  }
  await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          id: const Value(30001),
          externalId: const Value('10000000-0000-4000-8000-000000030001'),
          clientId: 'merge-client',
          performedAt: DateTime(2026, 1, 2, 12),
          planInstance: 1,
          gender: 'М',
          templateIdx: template.idx,
        ),
      );
  await db
      .into(db.workoutExerciseResults)
      .insert(
        WorkoutExerciseResultsCompanion.insert(
          id: const Value(30001),
          sessionId: 30001,
          templateExerciseId: 7001,
          exerciseIdentityId: const Value(_canonicalId),
          exerciseNameSnapshot: const Value('unrelated'),
          lastWeightKg: const Value(12.5),
          lastReps: const Value(8),
        ),
      );
}

Future<void> _insertIdentity(
  AppDb db, {
  required int id,
  required String uuid,
  required String name,
  String status = AppDb.activeExerciseStatus,
}) async {
  await db
      .into(db.exerciseIdentities)
      .insert(
        ExerciseIdentitiesCompanion.insert(
          id: Value(id),
          externalId: uuid,
          canonicalName: Value(name),
          normalizedName: Value(name.toLowerCase()),
          status: Value(status),
        ),
      );
}
