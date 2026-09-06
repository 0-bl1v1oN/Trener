import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

const _fixes =
    <
      ({
        String clientId,
        String clientName,
        int slotId,
        String displayName,
        String targetName,
        String targetUuid,
      })
    >[
      (
        clientId: '1771968976799655',
        clientName: 'Алёна (ФСБ 😎)',
        slotId: 66,
        displayName: 'Сведение рук',
        targetName: 'Сведение рук в кроссовере',
        targetUuid: '68c9bf93-f67f-47d2-a884-4d50a58dac5e',
      ),
      (
        clientId: '1785867203298113',
        clientName: 'Роман Скворцов',
        slotId: 12,
        displayName: 'Жим ногами',
        targetName: 'Жим ногами',
        targetUuid: '7ef69ad0-3588-4a50-935e-6d4c11431fa0',
      ),
      (
        clientId: '1785867203298113',
        clientName: 'Роман Скворцов',
        slotId: 13,
        displayName: 'Гакка',
        targetName: 'Гакка',
        targetUuid: '7c245fca-e2b2-4a27-9177-7a3349b1b0dd',
      ),
      (
        clientId: '1771968976799655',
        clientName: 'Алёна (ФСБ 😎)',
        slotId: 65,
        displayName: 'Отжимания',
        targetName: 'Отжимания',
        targetUuid: 'aa6b34ae-f299-44b5-a32f-f26593d1f71d',
      ),
      (
        clientId: '1771969323937422',
        clientName: 'Влад Воронин',
        slotId: 21,
        displayName: 'Тяга в кроссовере',
        targetName: 'Тяга одной рукой в кроссовере',
        targetUuid: 'd467d747-275e-47b8-ad26-1bdb0adfbc07',
      ),
      (
        clientId: '1772007370007117',
        clientName: 'Степан (друг Андрея)',
        slotId: 38,
        displayName: 'Тяга штанги в наклоне',
        targetName: 'Тяга штанги в наклоне',
        targetUuid: '41adb3a8-ea0a-4597-b9c3-66ed36728134',
      ),
      (
        clientId: '1772007370007117',
        clientName: 'Степан (друг Андрея)',
        slotId: 39,
        displayName: 'Тяга нижнего блока параллельным хватом',
        targetName: 'Тяга нижнего блока параллельным хватом',
        targetUuid: '1b1e4ff8-8eca-4051-b4d4-7d90aee41a0e',
      ),
      (
        clientId: '1785867203298113',
        clientName: 'Роман Скворцов',
        slotId: 28,
        displayName: 'Жим штанги стоя с подъёмами на предплечье',
        targetName: 'Жим штанги стоя с подъёмами на предплечье',
        targetUuid: '5be9453d-358e-4d13-9c9f-0cdb61b750cb',
      ),
      (
        clientId: '1785867203298113',
        clientName: 'Роман Скворцов',
        slotId: 29,
        displayName: 'Самурай',
        targetName: 'Самурай',
        targetUuid: '0884df83-8139-42cf-af30-aed32d4ec3e3',
      ),
      (
        clientId: '1771969023161770',
        clientName: 'Амир 🥷',
        slotId: 44,
        displayName: 'Отрицательный жим штанги',
        targetName: 'Отрицательный жим штанги',
        targetUuid: '55afb5da-b70f-4fa6-81af-6936ea6d8f0b',
      ),
      (
        clientId: '1771969023161770',
        clientName: 'Амир 🥷',
        slotId: 46,
        displayName: 'Подъёмы гантелей перед собой',
        targetName: 'Подъёмы гантелей перед собой',
        targetUuid: '907e322b-b492-4116-9105-ab815d452999',
      ),
      (
        clientId: '1771968730757039',
        clientName: 'Степан (друг Темы)',
        slotId: 2,
        displayName: 'Т-образная тяга',
        targetName: 'Тяга Т-образный гриф',
        targetUuid: 'ae6344bc-7203-4cae-9ded-0f157c889fb4',
      ),
      (
        clientId: '1771968730757039',
        clientName: 'Степан (друг Темы)',
        slotId: 3,
        displayName: 'Пуловер',
        targetName: 'Пуловер',
        targetUuid: 'a9960e54-5dc1-49e6-b507-36a14a194f41',
      ),
      (
        clientId: '1771969364280756',
        clientName: 'Гриша 🐸',
        slotId: 26,
        displayName: 'Жим гантелей',
        targetName: 'Жим гантелей лёжа на скамье',
        targetUuid: 'ef5f6400-c408-4eb5-b520-dbd1e45abf5b',
      ),
      (
        clientId: '1788251777595645',
        clientName: 'Максим (сын Ани)',
        slotId: 9,
        displayName: 'Сведение рук в кроссовере',
        targetName: 'Сведение рук в кроссовере',
        targetUuid: '68c9bf93-f67f-47d2-a884-4d50a58dac5e',
      ),
    ];

void main() {
  test('schema 18 migration materializes all 15 confirmed overrides', () async {
    final temp = await Directory.systemTemp.createTemp('trener-current-slots-');
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');
    var db = AppDb.forTesting(NativeDatabase(file));
    final historyId = await _seedFixture(db);
    final historyBefore = await _readResult(db, historyId);
    final unrelatedBefore = await _readOverride(db, 'unrelated-client', 1);
    await db.customStatement('PRAGMA user_version = 18');
    await db.close();

    var automaticSyncTriggers = 0;
    db = AppDb.forTesting(NativeDatabase(file));
    db.configureAutomaticSyncTrigger(() => automaticSyncTriggers++);

    await _expectAllMappings(db);
    expect(automaticSyncTriggers, 0);
    expect(await _readResult(db, historyId), historyBefore);
    expect(await _readOverride(db, 'unrelated-client', 1), unrelatedBefore);

    for (var index = 0; index < _fixes.length; index++) {
      final fix = _fixes[index];
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              externalId: Value(
                '90000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
              ),
              clientId: fix.clientId,
              performedAt: DateTime(2026, 9, 7 + index, 12),
              planInstance: 1,
              gender: 'Ж',
              templateIdx: 2,
            ),
          );
      await db.saveWorkoutResultsAndMarkDone(
        clientId: fix.clientId,
        day: DateTime(2026, 9, 7 + index),
        sessionId: sessionId,
        resultsByTemplateExerciseId: {fix.slotId: (10, 12)},
      );
      final future = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.sessionId.equals(sessionId))).getSingle();
      final target = await _findByUuid(db, fix.targetUuid);
      expect(future.exerciseIdentityId, target.id, reason: fix.displayName);
      expect(future.exerciseNameSnapshot, fix.displayName);
    }
    await db.close();
  });

  test('confirmed current overrides fix is idempotent', () async {
    final temp = await Directory.systemTemp.createTemp(
      'trener-current-slots-idempotent-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');
    var db = AppDb.forTesting(NativeDatabase(file));
    await _seedFixture(db);
    await db.customStatement('PRAGMA user_version = 18');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    await _expectAllMappings(db);
    final before = await db.select(db.clientTemplateExerciseOverrides).get();
    await db.customStatement('PRAGMA user_version = 18');
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    await _expectAllMappings(db);
    expect(await db.select(db.clientTemplateExerciseOverrides).get(), before);
    await db.close();
  });

  test(
    'guard preserves a different explicit identity selected later',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'trener-current-slots-guard-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');
      var db = AppDb.forTesting(NativeDatabase(file));
      await _seedFixture(db);
      final first = _fixes.first;
      final differentTarget = await _findByUuid(db, _fixes[1].targetUuid);
      await db
          .into(db.clientTemplateExerciseOverrides)
          .insert(
            ClientTemplateExerciseOverridesCompanion.insert(
              clientId: first.clientId,
              templateExerciseId: first.slotId,
              exerciseIdentityId: Value(differentTarget.id),
            ),
          );
      await db.customStatement('PRAGMA user_version = 18');
      await db.close();

      db = AppDb.forTesting(NativeDatabase(file));
      final preserved = await _readOverride(db, first.clientId, first.slotId);
      expect(preserved?.exerciseIdentityId, differentTarget.id);
      for (final fix in _fixes.skip(1)) {
        final target = await _findByUuid(db, fix.targetUuid);
        expect(
          (await _readOverride(
            db,
            fix.clientId,
            fix.slotId,
          ))?.exerciseIdentityId,
          target.id,
          reason: fix.displayName,
        );
      }
      await db.close();
    },
  );

  test('restore of schema 18 backup applies confirmed overrides', () async {
    final source = AppDb.forTesting(NativeDatabase.memory());
    await _seedFixture(source);
    final backup = await source.buildBackupPayload(
      appVersion: '1.15.6',
      buildNumber: '113',
    );
    backup['schemaVersion'] = 18;
    await source.close();

    final restored = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(restored.close);
    var automaticSyncTriggers = 0;
    restored.configureAutomaticSyncTrigger(() => automaticSyncTriggers++);
    await restored.importBackupPayload(backup);
    await _expectAllMappings(restored);
    expect(automaticSyncTriggers, 0);
  });
}

Future<int> _seedFixture(AppDb db) async {
  await db.getActiveExercises();
  final targets = <String, ({String name, String uuid})>{
    for (final fix in _fixes)
      fix.targetUuid: (name: fix.targetName, uuid: fix.targetUuid),
  };
  var targetId = 2000;
  for (final target in targets.values) {
    final normalized = AppDb.normalizeExerciseName(target.name);
    await (db.update(
      db.exerciseIdentities,
    )..where((row) => row.normalizedName.equals(normalized))).write(
      const ExerciseIdentitiesCompanion(
        status: Value(AppDb.archivedExerciseStatus),
      ),
    );
    await db
        .into(db.exerciseIdentities)
        .insert(
          ExerciseIdentitiesCompanion.insert(
            id: Value(targetId++),
            externalId: target.uuid,
            canonicalName: Value(target.name),
            normalizedName: Value(normalized),
          ),
        );
  }

  final clients = <String, String>{
    for (final fix in _fixes) fix.clientId: fix.clientName,
  };
  var clientIndex = 1;
  for (final entry in clients.entries) {
    await db
        .into(db.clients)
        .insert(
          ClientsCompanion.insert(
            id: entry.key,
            externalId: Value(
              '91000000-0000-4000-8000-${clientIndex.toString().padLeft(12, '0')}',
            ),
            name: entry.value,
            gender: const Value('Ж'),
          ),
        );
    clientIndex++;
  }
  for (final fix in _fixes) {
    await db.customStatement(
      'INSERT INTO client_exercise_name_overrides '
      '(client_id, template_exercise_id, custom_name) VALUES (?, ?, ?)',
      [fix.clientId, fix.slotId, fix.displayName],
    );
  }

  await db
      .into(db.clients)
      .insert(
        ClientsCompanion.insert(
          id: 'unrelated-client',
          externalId: const Value('92000000-0000-4000-8000-000000000001'),
          name: 'Unrelated',
        ),
      );
  final unrelatedIdentity = (await db.getActiveExercises()).first;
  await db
      .into(db.clientTemplateExerciseOverrides)
      .insert(
        ClientTemplateExerciseOverridesCompanion.insert(
          clientId: 'unrelated-client',
          templateExerciseId: 1,
          exerciseIdentityId: Value(unrelatedIdentity.id),
        ),
      );

  final sourceIdentity = (await db.select(db.exerciseIdentities).get()).first;
  final sessionId = await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          externalId: const Value('93000000-0000-4000-8000-000000000001'),
          clientId: _fixes.first.clientId,
          performedAt: DateTime(2026, 9, 1, 12),
          planInstance: 1,
          gender: 'Ж',
          templateIdx: 2,
        ),
      );
  return db
      .into(db.workoutExerciseResults)
      .insert(
        WorkoutExerciseResultsCompanion.insert(
          sessionId: sessionId,
          templateExerciseId: _fixes.first.slotId,
          exerciseIdentityId: Value(sourceIdentity.id),
          exerciseNameSnapshot: const Value('Историческое имя'),
          lastWeightKg: const Value(17.5),
          lastReps: const Value(9),
        ),
      );
}

Future<void> _expectAllMappings(AppDb db) async {
  for (final fix in _fixes) {
    final target = await _findByUuid(db, fix.targetUuid);
    final override = await _readOverride(db, fix.clientId, fix.slotId);
    expect(override?.exerciseIdentityId, target.id, reason: fix.displayName);
    expect(
      await db.getExerciseExternalId(
        clientId: fix.clientId,
        templateExerciseId: fix.slotId,
      ),
      fix.targetUuid,
      reason: fix.displayName,
    );
    final name = await db
        .customSelect(
          'SELECT custom_name FROM client_exercise_name_overrides '
          'WHERE client_id = ? AND template_exercise_id = ?',
          variables: [
            Variable.withString(fix.clientId),
            Variable.withInt(fix.slotId),
          ],
        )
        .getSingle();
    expect(name.read<String>('custom_name'), fix.displayName);
  }
  final audit = await db.analyzeLegacyExerciseBindings();
  for (final fix in _fixes) {
    expect(
      audit.candidates.where(
        (candidate) =>
            candidate.clientId == fix.clientId &&
            candidate.templateExerciseId == fix.slotId,
      ),
      isEmpty,
      reason: fix.displayName,
    );
  }
}

Future<ClientTemplateExerciseOverride?> _readOverride(
  AppDb db,
  String clientId,
  int slotId,
) {
  return (db.select(db.clientTemplateExerciseOverrides)..where(
        (row) =>
            row.clientId.equals(clientId) &
            row.templateExerciseId.equals(slotId),
      ))
      .getSingleOrNull();
}

Future<ExerciseIdentity> _findByUuid(AppDb db, String uuid) {
  return (db.select(
    db.exerciseIdentities,
  )..where((row) => row.externalId.equals(uuid))).getSingle();
}

Future<WorkoutExerciseResult> _readResult(AppDb db, int id) {
  return (db.select(
    db.workoutExerciseResults,
  )..where((row) => row.id.equals(id))).getSingle();
}
