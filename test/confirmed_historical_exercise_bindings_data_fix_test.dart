import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

const _sourceIdentityId = 267;
const _zerkerIdentityId = 284;
const _seatedHammerIdentityId = 348;
const _sourceUuid = 'af51b1f6-eb6a-43a0-be8a-5a8c5ba34315';
const _zerkerUuid = 'cb6d8ee9-d99f-4e43-907b-454f0636c809';
const _seatedHammerUuid = '44998917-34b1-42e1-bfca-3ff98f50d178';

const _fixes =
    <
      ({
        int resultId,
        int sessionId,
        String workoutUuid,
        String clientId,
        int performedAtSeconds,
        String gender,
        int templateIdx,
        int templateExerciseId,
        String snapshot,
        double weight,
        int targetIdentityId,
      })
    >[
      (
        resultId: 665,
        sessionId: 365,
        workoutUuid: 'f4501956-b13d-4e4e-bf01-5a2156313232',
        clientId: '1771968319889522',
        performedAtSeconds: 1772701200,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 0,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 1267,
        sessionId: 485,
        workoutUuid: '7768dbfe-01b7-4a5b-9615-adbc9ce42a8a',
        clientId: '1771968319889522',
        performedAtSeconds: 1773392400,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 0,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 3058,
        sessionId: 836,
        workoutUuid: '86ac7051-fb70-46ee-bb79-7ac955a0c42f',
        clientId: '1771968319889522',
        performedAtSeconds: 1775466000,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 0,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 4563,
        sessionId: 1095,
        workoutUuid: 'ef0e5a48-2c31-46af-8256-5814fcdb3473',
        clientId: '1771968319889522',
        performedAtSeconds: 1777021200,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 4,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 5797,
        sessionId: 1313,
        workoutUuid: '0a4db11e-5ceb-45d5-b130-62991aa71058',
        clientId: '1771968319889522',
        performedAtSeconds: 1778662800,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 4,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 7490,
        sessionId: 1607,
        workoutUuid: '0c0115b3-8c76-46c1-a538-712967767b3f',
        clientId: '1771968319889522',
        performedAtSeconds: 1780650000,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 4,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 8560,
        sessionId: 1804,
        workoutUuid: 'd51c53be-9738-4ae2-913e-93a7b6028e9e',
        clientId: '1771968319889522',
        performedAtSeconds: 1782291600,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 4,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 9627,
        sessionId: 2011,
        workoutUuid: '92d06e3b-8cb4-4fff-a8d1-bd467b599ee9',
        clientId: '1771968319889522',
        performedAtSeconds: 1784106000,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 4,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 10491,
        sessionId: 2180,
        workoutUuid: '8b27e94d-c66d-4a70-82d7-bb3976cc59eb',
        clientId: '1771968319889522',
        performedAtSeconds: 1785747600,
        gender: 'Ж',
        templateIdx: 0,
        templateExerciseId: 58,
        snapshot: 'Зеркер',
        weight: 4,
        targetIdentityId: _zerkerIdentityId,
      ),
      (
        resultId: 33,
        sessionId: 44,
        workoutUuid: '2921ea59-f7e4-45bf-9795-58a74351a26c',
        clientId: '1771968856758008',
        performedAtSeconds: 1772010000,
        gender: 'М',
        templateIdx: 6,
        templateExerciseId: 40,
        snapshot: 'Молоточки',
        weight: 9,
        targetIdentityId: _seatedHammerIdentityId,
      ),
      (
        resultId: 2336,
        sessionId: 702,
        workoutUuid: '83abf407-4193-4bb2-9645-a524e6622c0d',
        clientId: '1771968856758008',
        performedAtSeconds: 1774515600,
        gender: 'М',
        templateIdx: 6,
        templateExerciseId: 40,
        snapshot: 'Молоточки',
        weight: 30,
        targetIdentityId: _seatedHammerIdentityId,
      ),
      (
        resultId: 4765,
        sessionId: 1131,
        workoutUuid: 'b7deefd5-eb4a-494d-814e-e76738be56ab',
        clientId: '1771968856758008',
        performedAtSeconds: 1777280400,
        gender: 'М',
        templateIdx: 6,
        templateExerciseId: 40,
        snapshot: 'Молоточки',
        weight: 10,
        targetIdentityId: _seatedHammerIdentityId,
      ),
      (
        resultId: 7069,
        sessionId: 1532,
        workoutUuid: 'f0efa31e-61d7-4fe4-bbd3-f83197cd354f',
        clientId: '1771968856758008',
        performedAtSeconds: 1780045200,
        gender: 'М',
        templateIdx: 6,
        templateExerciseId: 40,
        snapshot: 'Молоточки',
        weight: 10,
        targetIdentityId: _seatedHammerIdentityId,
      ),
      (
        resultId: 9194,
        sessionId: 1927,
        workoutUuid: '8a1e6a2d-456b-40a0-bb8a-35dda94e13fe',
        clientId: '1771968856758008',
        performedAtSeconds: 1783414800,
        gender: 'М',
        templateIdx: 6,
        templateExerciseId: 40,
        snapshot: 'Молоточки',
        weight: 10,
        targetIdentityId: _seatedHammerIdentityId,
      ),
      (
        resultId: 10675,
        sessionId: 2219,
        workoutUuid: '727440a8-8af8-43a2-a850-0eda8da0ea6c',
        clientId: '1771968856758008',
        performedAtSeconds: 1786093200,
        gender: 'М',
        templateIdx: 6,
        templateExerciseId: 40,
        snapshot: 'Молоточки',
        weight: 10,
        targetIdentityId: _seatedHammerIdentityId,
      ),
    ];

void main() {
  test(
    'schema 16 migration repairs both confirmed historical groups',
    () async {
      final temp = await Directory.systemTemp.createTemp('trener-history-fix-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

      var db = AppDb.forTesting(NativeDatabase(file));
      await _seedFixture(db);
      await db.customStatement('PRAGMA user_version = 16');
      await db.close();

      var automaticSyncTriggers = 0;
      db = AppDb.forTesting(NativeDatabase(file));
      db.configureAutomaticSyncTrigger(() => automaticSyncTriggers++);
      final fixed = await _readFixedRows(db);
      final queue = await db.select(db.syncQueue).get();

      expect(
        fixed.where((row) => row.exerciseIdentityId == _zerkerIdentityId),
        hasLength(9),
      );
      expect(
        fixed.where((row) => row.exerciseIdentityId == _seatedHammerIdentityId),
        hasLength(6),
      );
      for (final fix in _fixes) {
        final row = fixed.singleWhere((item) => item.id == fix.resultId);
        expect(row.exerciseNameSnapshot, fix.snapshot);
        expect(row.lastWeightKg, fix.weight);
        expect(row.lastReps, 10);
        expect(row.templateExerciseId, fix.templateExerciseId);

        final payload = await db.buildWorkoutSyncPayload(fix.workoutUuid);
        expect(payload, isNotNull);
        final json = jsonDecode(payload!.encode()) as Map<String, dynamic>;
        final exercise = (json['exercises'] as List).single as Map;
        expect(
          exercise['exercise_id'],
          fix.targetIdentityId == _zerkerIdentityId
              ? _zerkerUuid
              : _seatedHammerUuid,
        );
        expect(exercise['name'], fix.snapshot);
      }
      expect(queue, hasLength(15));
      expect(
        queue.every((row) => row.status == 'PENDING' && row.attempts == 0),
        isTrue,
      );
      expect(
        queue.map((row) => row.entityExternalId).toSet(),
        _fixes.map((fix) => fix.workoutUuid).toSet(),
      );
      expect(automaticSyncTriggers, 0);

      final unrelated = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(20000))).getSingle();
      expect(unrelated.exerciseIdentityId, _sourceIdentityId);
      expect(unrelated.exerciseNameSnapshot, 'unrelated');
      expect(unrelated.lastWeightKg, 12.5);
      expect(unrelated.lastReps, 8);
      final rebuild = await db.analyzeWorkoutSyncQueueRebuild();
      expect(rebuild.payloadErrors, 0);
      expect(rebuild.conflicts, isEmpty);
      await db.close();
    },
  );

  test('confirmed historical binding fix is idempotent', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-history-fix-idempotent-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedFixture(db);
    await db.customStatement('PRAGMA user_version = 16');
    await db.close();
    db = AppDb.forTesting(NativeDatabase(file));
    final firstQueue = await db.select(db.syncQueue).get();
    await db.customStatement('PRAGMA user_version = 16');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    final secondQueue = await db.select(db.syncQueue).get();
    expect(secondQueue, firstQueue);
    expect(await _readFixedRows(db), hasLength(15));
    await db.close();
  });

  test('guard skips only a result whose confirmed data differs', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-history-fix-guard-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedFixture(db, changedResultId: 665);
    await db.customStatement('PRAGMA user_version = 16');
    await db.close();
    db = AppDb.forTesting(NativeDatabase(file));

    final skipped = await (db.select(
      db.workoutExerciseResults,
    )..where((row) => row.id.equals(665))).getSingle();
    expect(skipped.exerciseIdentityId, _sourceIdentityId);
    expect(skipped.exerciseNameSnapshot, 'Зеркер');
    expect(skipped.lastWeightKg, 0.5);
    expect(
      (await _readFixedRows(
        db,
      )).where((row) => row.exerciseIdentityId == _zerkerIdentityId),
      hasLength(8),
    );
    expect(
      (await _readFixedRows(
        db,
      )).where((row) => row.exerciseIdentityId == _seatedHammerIdentityId),
      hasLength(6),
    );
    expect(await db.select(db.syncQueue).get(), hasLength(14));
    await db.close();
  });

  test('restore of an older backup applies the guarded fix', () async {
    final source = AppDb.forTesting(NativeDatabase.memory());
    await _seedFixture(source);
    final backup = await source.buildBackupPayload(
      appVersion: '1.15.3',
      buildNumber: '110',
    );
    backup['schemaVersion'] = 16;
    await source.close();

    var automaticSyncTriggers = 0;
    final restored = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(restored.close);
    restored.configureAutomaticSyncTrigger(() => automaticSyncTriggers++);
    await restored.importBackupPayload(backup);

    final fixed = await _readFixedRows(restored);
    expect(
      fixed.where((row) => row.exerciseIdentityId == _zerkerIdentityId),
      hasLength(9),
    );
    expect(
      fixed.where((row) => row.exerciseIdentityId == _seatedHammerIdentityId),
      hasLength(6),
    );
    expect(await restored.select(restored.syncQueue).get(), hasLength(15));
    expect(automaticSyncTriggers, 0);
  });
}

Future<List<WorkoutExerciseResult>> _readFixedRows(AppDb db) {
  return (db.select(
    db.workoutExerciseResults,
  )..where((row) => row.id.isIn(_fixes.map((fix) => fix.resultId)))).get();
}

Future<void> _seedFixture(AppDb db, {int? changedResultId}) async {
  await db.getActiveExercises();
  await _insertIdentity(
    db,
    id: _sourceIdentityId,
    uuid: _sourceUuid,
    name: 'Сгибание рук в кроссовере',
  );
  await _insertIdentity(
    db,
    id: _zerkerIdentityId,
    uuid: _zerkerUuid,
    name: 'Сгибание штанги на бицепс верхним хватом',
  );
  await _insertIdentity(
    db,
    id: _seatedHammerIdentityId,
    uuid: _seatedHammerUuid,
    name: 'Молотки сидя',
  );
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion.insert(
          id: '1771968319889522',
          externalId: const Value('10000000-0000-4000-8000-000000000001'),
          name: 'Таня (сестра Тани)',
          gender: const Value('Ж'),
        ),
      );
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion.insert(
          id: '1771968856758008',
          externalId: const Value('10000000-0000-4000-8000-000000000002'),
          name: 'Александр (КВН)',
          gender: const Value('М'),
        ),
      );

  for (final fix in _fixes) {
    await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: Value(fix.sessionId),
            externalId: Value(fix.workoutUuid),
            clientId: fix.clientId,
            performedAt: DateTime.fromMillisecondsSinceEpoch(
              fix.performedAtSeconds * 1000,
            ),
            planInstance: 1,
            gender: fix.gender,
            templateIdx: fix.templateIdx,
          ),
        );
    await db
        .into(db.workoutExerciseResults)
        .insert(
          WorkoutExerciseResultsCompanion.insert(
            id: Value(fix.resultId),
            sessionId: fix.sessionId,
            templateExerciseId: fix.templateExerciseId,
            exerciseIdentityId: const Value(_sourceIdentityId),
            exerciseNameSnapshot: Value(fix.snapshot),
            lastWeightKg: Value(
              fix.resultId == changedResultId ? fix.weight + 0.5 : fix.weight,
            ),
            lastReps: const Value(10),
          ),
        );
  }

  await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          id: const Value(20000),
          externalId: const Value('10000000-0000-4000-8000-000000020000'),
          clientId: '1771968856758008',
          performedAt: DateTime(2026, 9, 5, 12),
          planInstance: 8,
          gender: 'М',
          templateIdx: 5,
        ),
      );
  await db
      .into(db.workoutExerciseResults)
      .insert(
        WorkoutExerciseResultsCompanion.insert(
          id: const Value(20000),
          sessionId: 20000,
          templateExerciseId: 999,
          exerciseIdentityId: const Value(_sourceIdentityId),
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
}) async {
  await db
      .into(db.exerciseIdentities)
      .insert(
        ExerciseIdentitiesCompanion.insert(
          id: Value(id),
          externalId: uuid,
          canonicalName: Value(name),
          normalizedName: Value(name.toLowerCase()),
          status: const Value(AppDb.activeExerciseStatus),
        ),
      );
}
