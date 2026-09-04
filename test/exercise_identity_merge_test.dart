import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/sync/schedule_sync_payload.dart';
import 'package:myfitness/sync/sync_service.dart';
import 'package:myfitness/sync/sync_transport.dart';
import 'package:myfitness/sync/workout_sync_payload.dart';

void main() {
  Future<AppDb> openDb() async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    await db.getActiveExercises();
    addTearDown(db.close);
    return db;
  }

  Future<ExerciseIdentity> insertIdentity(
    AppDb db, {
    required String uuid,
    required String name,
    String status = AppDb.activeExerciseStatus,
  }) async {
    final id = await db
        .into(db.exerciseIdentities)
        .insert(
          ExerciseIdentitiesCompanion.insert(
            externalId: uuid,
            canonicalName: Value(name),
            normalizedName: Value(AppDb.normalizeExerciseName(name)),
            status: Value(status),
          ),
        );
    return (await db.getExerciseById(id))!;
  }

  test(
    'merge repoints every identity reference and preserves history',
    () async {
      final db = await openDb();
      final canonical = await insertIdentity(
        db,
        uuid: '10000000-0000-4000-8000-000000000001',
        name: 'Гиперэкстензия',
      );
      final duplicateA = await insertIdentity(
        db,
        uuid: '10000000-0000-4000-8000-000000000002',
        name: 'Гиперэкстензия',
      );
      final duplicateB = await insertIdentity(
        db,
        uuid: '10000000-0000-4000-8000-000000000003',
        name: 'ГИПЕРЭКСТЕНЗИЯ',
        status: AppDb.archivedExerciseStatus,
      );
      final template = (await db.getWorkoutTemplatesByGender('М')).first;
      final templateSlotId = await db
          .into(db.workoutTemplateExercises)
          .insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: template.id,
              orderIndex: 1000,
              name: duplicateA.canonicalName,
              exerciseIdentityId: Value(duplicateA.id),
            ),
          );
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: 'merge-client',
              externalId: const Value('20000000-0000-4000-8000-000000000001'),
              name: 'Клиент merge',
              gender: const Value('М'),
            ),
          );
      await db.customStatement(
        'INSERT INTO client_added_exercises '
        '(client_id, template_id, order_index, name, exercise_identity_id) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          'merge-client',
          template.id,
          1001,
          duplicateB.canonicalName,
          duplicateB.id,
        ],
      );
      await db
          .into(db.clientTemplateExerciseOverrides)
          .insert(
            ClientTemplateExerciseOverridesCompanion.insert(
              clientId: 'merge-client',
              templateExerciseId: templateSlotId,
              exerciseIdentityId: Value(duplicateA.id),
            ),
          );
      await db
          .into(db.exerciseIdentityBindings)
          .insert(
            ExerciseIdentityBindingsCompanion.insert(
              sourceType: 'TEMPLATE',
              sourceId: templateSlotId,
              identityId: duplicateB.id,
            ),
          );
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              externalId: const Value('30000000-0000-4000-8000-000000000001'),
              clientId: 'merge-client',
              performedAt: DateTime(2026, 9, 4),
              planInstance: 1,
              gender: 'М',
              templateIdx: template.idx,
            ),
          );
      final resultId = await db
          .into(db.workoutExerciseResults)
          .insert(
            WorkoutExerciseResultsCompanion.insert(
              sessionId: sessionId,
              templateExerciseId: templateSlotId,
              exerciseIdentityId: Value(duplicateA.id),
              exerciseNameSnapshot: const Value('Старое имя на тренировке'),
              lastWeightKg: const Value(42.5),
              lastReps: const Value(11),
            ),
          );
      final resultCountBefore = await db
          .select(db.workoutExerciseResults)
          .get()
          .then((rows) => rows.length);

      await db.mergeExerciseIdentities(
        canonicalIdentityId: canonical.id,
        duplicateIdentityIds: [duplicateA.id, duplicateB.id],
      );

      final canonicalAfter = (await db.getExerciseById(canonical.id))!;
      expect(canonicalAfter.externalId, canonical.externalId);
      expect(canonicalAfter.status, AppDb.activeExerciseStatus);
      for (final duplicate in [duplicateA, duplicateB]) {
        final after = (await db.getExerciseById(duplicate.id))!;
        expect(after.externalId, duplicate.externalId);
        expect(after.status, AppDb.archivedExerciseStatus);
        expect(after.mergedIntoIdentityId, canonical.id);
      }
      expect(
        (await db.select(db.workoutTemplateExercises).get())
            .firstWhere((row) => row.id == templateSlotId)
            .exerciseIdentityId,
        canonical.id,
      );
      expect(
        (await db.select(db.clientTemplateExerciseOverrides).getSingle())
            .exerciseIdentityId,
        canonical.id,
      );
      expect(
        (await db.select(db.exerciseIdentityBindings).get())
            .firstWhere((row) => row.sourceId == templateSlotId)
            .identityId,
        canonical.id,
      );
      final added = await db
          .customSelect(
            'SELECT exercise_identity_id FROM client_added_exercises '
            'WHERE client_id = ? AND order_index = ?',
            variables: [
              Variable.withString('merge-client'),
              Variable.withInt(1001),
            ],
          )
          .getSingle();
      expect(added.read<int>('exercise_identity_id'), canonical.id);
      final result = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(resultId))).getSingle();
      expect(result.exerciseIdentityId, canonical.id);
      expect(result.exerciseNameSnapshot, 'Старое имя на тренировке');
      expect(result.lastWeightKg, 42.5);
      expect(result.lastReps, 11);
      expect(result.sessionId, sessionId);
      expect(
        await db.select(db.workoutExerciseResults).get().then((r) => r.length),
        resultCountBefore,
      );
      expect(
        (await db.getActiveExercises()).where(
          (item) => item.id == duplicateA.id || item.id == duplicateB.id,
        ),
        isEmpty,
      );
      final aliases = await db.getExerciseUuidAliases();
      expect(aliases, hasLength(2));
      expect(aliases.map((item) => item.canonicalExternalId).toSet(), {
        canonical.externalId,
      });
    },
  );

  test(
    'exact duplicate query includes archived rows and reports usage',
    () async {
      final db = await openDb();
      final first = await insertIdentity(
        db,
        uuid: '40000000-0000-4000-8000-000000000001',
        name: 'Тяга блока',
      );
      final second = await insertIdentity(
        db,
        uuid: '40000000-0000-4000-8000-000000000002',
        name: ' тяга   БЛОКА ',
        status: AppDb.archivedExerciseStatus,
      );
      final template = (await db.getWorkoutTemplatesByGender('М')).first;
      await db
          .into(db.workoutTemplateExercises)
          .insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: template.id,
              orderIndex: 1002,
              name: first.canonicalName,
              exerciseIdentityId: Value(first.id),
            ),
          );

      final groups = await db.getExerciseDuplicateGroups();
      final group = groups.firstWhere(
        (item) => item.normalizedName == 'тяга блока',
      );
      expect(group.items.map((item) => item.exercise.id).toSet(), {
        first.id,
        second.id,
      });
      expect(
        group.items
            .firstWhere((item) => item.exercise.id == first.id)
            .templateSlots,
        1,
      );

      await db.mergeExerciseIdentities(
        canonicalIdentityId: first.id,
        duplicateIdentityIds: [second.id],
      );
      expect(
        (await db.getExerciseDuplicateGroups()).where(
          (item) => item.normalizedName == 'тяга блока',
        ),
        isEmpty,
      );
    },
  );

  test(
    'merge rejects self, rolls back invalid batch and prevents cycles',
    () async {
      final db = await openDb();
      final a = await insertIdentity(
        db,
        uuid: '50000000-0000-4000-8000-000000000001',
        name: 'A',
      );
      final b = await insertIdentity(
        db,
        uuid: '50000000-0000-4000-8000-000000000002',
        name: 'B',
      );

      await expectLater(
        db.mergeExerciseIdentities(
          canonicalIdentityId: a.id,
          duplicateIdentityIds: [a.id],
        ),
        throwsArgumentError,
      );
      await expectLater(
        db.mergeExerciseIdentities(
          canonicalIdentityId: a.id,
          duplicateIdentityIds: [b.id, 999999],
        ),
        throwsStateError,
      );
      expect((await db.getExerciseById(b.id))!.mergedIntoIdentityId, isNull);
      expect(await db.getExerciseUuidAliases(), isEmpty);

      await db.mergeExerciseIdentities(
        canonicalIdentityId: b.id,
        duplicateIdentityIds: [a.id],
      );
      await expectLater(
        db.mergeExerciseIdentities(
          canonicalIdentityId: a.id,
          duplicateIdentityIds: [b.id],
        ),
        throwsStateError,
      );
    },
  );

  test('alias chains flatten to the final canonical UUID', () async {
    final db = await openDb();
    final a = await insertIdentity(
      db,
      uuid: '60000000-0000-4000-8000-000000000001',
      name: 'Название A',
    );
    final b = await insertIdentity(
      db,
      uuid: '60000000-0000-4000-8000-000000000002',
      name: 'Название B',
    );
    final c = await insertIdentity(
      db,
      uuid: '60000000-0000-4000-8000-000000000003',
      name: 'Название C',
    );

    await db.mergeExerciseIdentities(
      canonicalIdentityId: b.id,
      duplicateIdentityIds: [a.id],
    );
    await db.mergeExerciseIdentities(
      canonicalIdentityId: c.id,
      duplicateIdentityIds: [b.id],
    );

    expect(await db.resolveCanonicalExerciseUuid(a.externalId), c.externalId);
    expect(await db.resolveCanonicalExerciseUuid(b.externalId), c.externalId);
    final mappings = await db.getExerciseUuidAliases();
    expect(mappings, hasLength(2));
    expect(mappings.map((item) => item.canonicalExternalId).toSet(), {
      c.externalId,
    });
  });

  test('rebuilt and pending workout payloads use canonical UUID', () async {
    final db = await openDb();
    final canonical = await insertIdentity(
      db,
      uuid: '70000000-0000-4000-8000-000000000001',
      name: 'Canonical',
    );
    final duplicate = await insertIdentity(
      db,
      uuid: '70000000-0000-4000-8000-000000000002',
      name: 'Legacy name',
    );
    await db
        .into(db.clients)
        .insert(
          ClientsCompanion.insert(
            id: 'sync-merge-client',
            externalId: const Value('80000000-0000-4000-8000-000000000001'),
            name: 'Sync client',
            gender: const Value('М'),
          ),
        );
    final template = (await db.getWorkoutTemplatesByGender('М')).first;
    final sessionId = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            externalId: const Value('90000000-0000-4000-8000-000000000001'),
            clientId: 'sync-merge-client',
            performedAt: DateTime(2026, 9, 4),
            planInstance: 1,
            gender: 'М',
            templateIdx: template.idx,
          ),
        );
    await db
        .into(db.workoutExerciseResults)
        .insert(
          WorkoutExerciseResultsCompanion.insert(
            sessionId: sessionId,
            templateExerciseId: 123456,
            exerciseIdentityId: Value(duplicate.id),
            exerciseNameSnapshot: const Value('Legacy snapshot'),
            lastWeightKg: const Value(12),
            lastReps: const Value(9),
          ),
        );
    final task = await db.enqueueWorkoutSync(
      '90000000-0000-4000-8000-000000000001',
    );
    expect(
      ((jsonDecode(task.payload) as Map)['exercises'] as List)
          .cast<Map>()
          .single['exercise_id'],
      duplicate.externalId,
    );

    await db.mergeExerciseIdentities(
      canonicalIdentityId: canonical.id,
      duplicateIdentityIds: [duplicate.id],
    );
    final rebuilt = (await db.buildWorkoutSyncPayload(
      '90000000-0000-4000-8000-000000000001',
    ))!;
    expect(rebuilt.exercises.single.exerciseExternalId, canonical.externalId);
    expect(rebuilt.exercises.single.name, 'Legacy snapshot');

    final transport = _RecordingTransport();
    final run = await SyncService(db: db, transport: transport).syncPending();
    expect(run.succeeded, 1);
    expect(transport.workouts, hasLength(1));
    expect(
      transport.workouts.single.exercises.single.exerciseExternalId,
      canonical.externalId,
    );
    expect(transport.workouts.single.exercises.single.name, 'Legacy snapshot');
  });

  test(
    'backup round-trip preserves aliases and legacy backup needs none',
    () async {
      final db = await openDb();
      final canonical = await insertIdentity(
        db,
        uuid: 'a0000000-0000-4000-8000-000000000001',
        name: 'Backup canonical',
      );
      final duplicate = await insertIdentity(
        db,
        uuid: 'a0000000-0000-4000-8000-000000000002',
        name: 'Backup duplicate',
      );
      await db.mergeExerciseIdentities(
        canonicalIdentityId: canonical.id,
        duplicateIdentityIds: [duplicate.id],
      );
      final backup = await db.buildBackupPayload(
        appVersion: '1.12.0',
        buildNumber: '104',
      );
      final tables = backup['tables'] as Map<String, dynamic>;
      expect(tables['exercise_identity_aliases'], hasLength(1));
      expect(
        (tables['exercise_identities'] as List).cast<Map>().firstWhere(
          (row) => row['id'] == duplicate.id,
        )['merged_into_identity_id'],
        canonical.id,
      );

      final restored = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);
      await restored.importBackupPayload(backup);
      expect(
        await restored.resolveCanonicalExerciseUuid(duplicate.externalId),
        canonical.externalId,
      );

      final legacy = jsonDecode(jsonEncode(backup)) as Map<String, dynamic>;
      legacy['schemaVersion'] = 12;
      final legacyTables = legacy['tables'] as Map<String, dynamic>;
      legacyTables.remove('exercise_identity_aliases');
      for (final row
          in (legacyTables['exercise_identities'] as List).cast<Map>()) {
        row.remove('merged_into_identity_id');
      }
      final legacyRestored = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(legacyRestored.close);
      await legacyRestored.importBackupPayload(legacy);
      expect(await legacyRestored.getExerciseUuidAliases(), isEmpty);
    },
  );
}

class _RecordingTransport implements SyncTransport {
  final List<WorkoutSyncPayload> workouts = [];

  @override
  bool get isConfigured => true;

  @override
  Future<SyncTransportResult> sendWorkout(WorkoutSyncPayload payload) async {
    workouts.add(payload);
    return const SyncTransportResult.success(httpStatus: 201);
  }

  @override
  Future<SyncTransportResult> sendSchedule(ScheduleSyncPayload payload) async {
    return const SyncTransportResult.success(httpStatus: 201);
  }
}
