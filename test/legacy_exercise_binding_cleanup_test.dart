import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

void main() {
  Future<AppDb> openDb() async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    await db.getActiveExercises();
    addTearDown(db.close);
    return db;
  }

  Future<ExerciseIdentity> addExercise(
    AppDb db,
    String name,
    String uuid,
  ) async {
    final id = await db
        .into(db.exerciseIdentities)
        .insert(
          ExerciseIdentitiesCompanion.insert(
            externalId: uuid,
            canonicalName: Value(name),
            normalizedName: Value(AppDb.normalizeExerciseName(name)),
          ),
        );
    return (await db.getExerciseById(id))!;
  }

  Future<int> addSession(
    AppDb db, {
    required String clientId,
    required String uuid,
    required String gender,
    required int templateIdx,
    required DateTime day,
  }) {
    return db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            externalId: Value(uuid),
            clientId: clientId,
            performedAt: day,
            planInstance: 1,
            gender: gender,
            templateIdx: templateIdx,
          ),
        );
  }

  Future<int> addResult(
    AppDb db, {
    required int sessionId,
    required int slotId,
    required int identityId,
    required String snapshot,
    double weight = 10,
    int reps = 8,
  }) {
    return db
        .into(db.workoutExerciseResults)
        .insert(
          WorkoutExerciseResultsCompanion.insert(
            sessionId: sessionId,
            templateExerciseId: slotId,
            exerciseIdentityId: Value(identityId),
            exerciseNameSnapshot: Value(snapshot),
            lastWeightKg: Value(weight),
            lastReps: Value(reps),
          ),
        );
  }

  test(
    'sync resolves merged chains but preserves snapshot and archived UUID',
    () async {
      final db = await openDb();
      final a = await addExercise(
        db,
        'Legacy A',
        '11000000-0000-4000-8000-000000000001',
      );
      final b = await addExercise(
        db,
        'Legacy B',
        '11000000-0000-4000-8000-000000000002',
      );
      final c = await addExercise(
        db,
        'Canonical C',
        '11000000-0000-4000-8000-000000000003',
      );
      final archived = await addExercise(
        db,
        'Archived standalone',
        '11000000-0000-4000-8000-000000000004',
      );
      await db.archiveExercise(archived.id);
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: 'canonical-sync-client',
              externalId: const Value('12000000-0000-4000-8000-000000000001'),
              name: 'Canonical client',
              gender: const Value('М'),
            ),
          );
      final template = (await db.getWorkoutTemplatesByGender('М')).first;
      final firstSession = await addSession(
        db,
        clientId: 'canonical-sync-client',
        uuid: '13000000-0000-4000-8000-000000000001',
        gender: 'М',
        templateIdx: template.idx,
        day: DateTime(2026, 9, 1),
      );
      final secondSession = await addSession(
        db,
        clientId: 'canonical-sync-client',
        uuid: '13000000-0000-4000-8000-000000000002',
        gender: 'М',
        templateIdx: template.idx,
        day: DateTime(2026, 9, 2),
      );
      final mergedResult = await addResult(
        db,
        sessionId: firstSession,
        slotId: 90001,
        identityId: a.id,
        snapshot: 'Старое отображаемое имя',
      );
      await addResult(
        db,
        sessionId: secondSession,
        slotId: 90002,
        identityId: archived.id,
        snapshot: 'Archived snapshot',
      );
      await db.mergeExerciseIdentities(
        canonicalIdentityId: b.id,
        duplicateIdentityIds: [a.id],
        retainLegacyRows: true,
      );
      await db.mergeExerciseIdentities(
        canonicalIdentityId: c.id,
        duplicateIdentityIds: [b.id],
        retainLegacyRows: true,
      );
      // Simulates an imported legacy result that still references the first link.
      await (db.update(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(mergedResult))).write(
        WorkoutExerciseResultsCompanion(exerciseIdentityId: Value(a.id)),
      );

      final mergedPayload = (await db.buildWorkoutSyncPayload(
        '13000000-0000-4000-8000-000000000001',
      ))!;
      expect(mergedPayload.exercises.single.exerciseExternalId, c.externalId);
      expect(mergedPayload.exercises.single.name, 'Старое отображаемое имя');

      final archivedPayload = (await db.buildWorkoutSyncPayload(
        '13000000-0000-4000-8000-000000000002',
      ))!;
      expect(
        archivedPayload.exercises.single.exerciseExternalId,
        archived.externalId,
      );
    },
  );

  test(
    'diagnostics group normalized legacy names and never suggest fuzzy match',
    () async {
      final db = await openDb();
      final wrong = await addExercise(
        db,
        'Неверная identity grouping',
        '18000000-0000-4000-8000-000000000001',
      );
      final exact = await addExercise(
        db,
        'Точный стульчик 774',
        '18000000-0000-4000-8000-000000000002',
      );
      final template = (await db.getWorkoutTemplatesByGender('М')).first;
      final slot =
          await (db.select(db.workoutTemplateExercises)
                ..where((row) => row.templateId.equals(template.id))
                ..limit(1))
              .getSingle();
      for (final item in <(String, String)>[
        ('group-client-1', 'Точный стульчик 774'),
        ('group-client-2', '  ТОЧНЫЙ   СТУЛЬЧИК 774 '),
        ('group-client-3', 'Точный стульчек 774'),
      ]) {
        await db
            .into(db.clients)
            .insert(ClientsCompanion.insert(id: item.$1, name: item.$1));
        await db
            .into(db.clientTemplateExerciseOverrides)
            .insert(
              ClientTemplateExerciseOverridesCompanion.insert(
                clientId: item.$1,
                templateExerciseId: slot.id,
                exerciseIdentityId: Value(wrong.id),
              ),
            );
        await db.customStatement(
          'INSERT INTO client_exercise_name_overrides '
          '(client_id, template_exercise_id, custom_name) VALUES (?, ?, ?)',
          [item.$1, slot.id, item.$2],
        );
      }

      final groups = (await db.analyzeLegacyExerciseBindings()).groups;
      final exactGroup = groups.singleWhere(
        (item) => item.normalizedName == 'точный стульчик 774',
      );
      final fuzzyGroup = groups.singleWhere(
        (item) => item.normalizedName == 'точный стульчек 774',
      );
      expect(exactGroup.clientCount, 2);
      expect(exactGroup.slotCount, 2);
      expect(exactGroup.exactCatalogMatch?.id, exact.id);
      expect(fuzzyGroup.clientCount, 1);
      expect(fuzzyGroup.exactCatalogMatch, equals(null));
    },
  );

  test(
    'mixed history correction changes only selected results and queues manually',
    () async {
      final db = await openDb();
      var autoSyncCalls = 0;
      db.configureAutomaticSyncTrigger(() => autoSyncCalls++);
      final curl = await addExercise(
        db,
        'Сгибание штанги',
        '21000000-0000-4000-8000-000000000001',
      );
      final hammer = await addExercise(
        db,
        'Молоточки',
        '21000000-0000-4000-8000-000000000002',
      );
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: 'mixed-client',
              externalId: const Value('22000000-0000-4000-8000-000000000001'),
              name: 'Mixed client',
              gender: const Value('М'),
            ),
          );
      final template = (await db.getWorkoutTemplatesByGender('М')).first;
      final slot =
          await (db.select(db.workoutTemplateExercises)
                ..where((row) => row.templateId.equals(template.id))
                ..limit(1))
              .getSingle();
      await db
          .into(db.clientTemplateExerciseOverrides)
          .insert(
            ClientTemplateExerciseOverridesCompanion.insert(
              clientId: 'mixed-client',
              templateExerciseId: slot.id,
              exerciseIdentityId: Value(curl.id),
            ),
          );
      await db.customStatement(
        'INSERT INTO client_exercise_name_overrides '
        '(client_id, template_exercise_id, custom_name) VALUES (?, ?, ?)',
        ['mixed-client', slot.id, 'Молоточки'],
      );
      final regularSession = await addSession(
        db,
        clientId: 'mixed-client',
        uuid: '23000000-0000-4000-8000-000000000001',
        gender: 'М',
        templateIdx: template.idx,
        day: DateTime(2026, 9, 1),
      );
      final trialSession = await addSession(
        db,
        clientId: 'mixed-client',
        uuid: '23000000-0000-4000-8000-000000000002',
        gender: 'П',
        templateIdx: 0,
        day: DateTime(2026, 9, 2),
      );
      final hammerSession = await addSession(
        db,
        clientId: 'mixed-client',
        uuid: '23000000-0000-4000-8000-000000000004',
        gender: 'М',
        templateIdx: template.idx,
        day: DateTime(2026, 9, 2),
      );
      final curlResult = await addResult(
        db,
        sessionId: regularSession,
        slotId: slot.id,
        identityId: curl.id,
        snapshot: 'Сгибание штанги',
        weight: 31.5,
        reps: 7,
      );
      final hammerResult = await addResult(
        db,
        sessionId: hammerSession,
        slotId: slot.id,
        identityId: curl.id,
        snapshot: 'Молоточки',
        weight: 14.5,
        reps: 11,
      );
      await addResult(
        db,
        sessionId: trialSession,
        slotId: slot.id,
        identityId: curl.id,
        snapshot: 'Молоточки',
      );
      final orphanBindingId = await db
          .into(db.exerciseIdentityBindings)
          .insert(
            ExerciseIdentityBindingsCompanion.insert(
              sourceType: 'TEMPLATE',
              sourceId: 987654321,
              identityId: curl.id,
            ),
          );

      final audit = await db.analyzeLegacyExerciseBindings();
      final identityCountBefore =
          (await db.select(db.exerciseIdentities).get()).length;
      final resultCountBefore =
          (await db.select(db.workoutExerciseResults).get()).length;
      final candidate = audit.candidates.singleWhere(
        (item) =>
            item.clientId == 'mixed-client' &&
            item.templateExerciseId == slot.id,
      );
      expect(candidate.hasMixedIdentityHistory, isTrue);
      expect(candidate.isCleanCandidate, isFalse);
      expect(audit.orphanBindings, greaterThanOrEqualTo(1));
      expect(candidate.snapshotGroups.map((group) => group.name).toSet(), {
        'Сгибание штанги',
        'Молоточки',
      });
      final group = audit.groups.singleWhere(
        (item) => item.normalizedName == 'молоточки',
      );
      expect(group.clientCount, 1);
      expect(group.slotCount, 1);
      expect(group.historicalResultCount, 2);
      expect(group.exactCatalogMatch?.id, hammer.id);

      final before = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(hammerResult))).getSingle();
      final request = LegacyExerciseBulkCorrectionRequest(
        normalizedLegacyName: group.normalizedName,
        targetExerciseIdentityId: hammer.id,
      );
      final preview = await db.previewLegacyExerciseBulkCorrection([request]);
      expect(preview.groups, 1);
      expect(preview.historicalResults, 2);
      expect(preview.currentSlots, 1);
      expect(preview.affectedSessions, 1);
      final result = await db.reassignLegacyExerciseGroups([request]);
      final after = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(hammerResult))).getSingle();
      final untouched = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(curlResult))).getSingle();

      expect(result.changedHistoricalResults, 2);
      expect(result.changedCurrentSlots, 1);
      expect(result.requeuedWorkoutSessions, 1);
      expect(result.groups, 1);
      expect(after.exerciseIdentityId, hammer.id);
      expect(after.exerciseNameSnapshot, before.exerciseNameSnapshot);
      expect(after.sessionId, before.sessionId);
      expect(after.lastWeightKg, before.lastWeightKg);
      expect(after.lastReps, before.lastReps);
      expect(untouched.exerciseIdentityId, curl.id);
      expect(untouched.exerciseNameSnapshot, 'Сгибание штанги');
      expect(await db.getExerciseUuidAliases(), isEmpty);
      expect(
        (await db.select(db.exerciseIdentities).get()).length,
        identityCountBefore,
      );
      expect(
        (await db.select(db.workoutExerciseResults).get()).length,
        resultCountBefore,
      );
      expect(
        await (db.select(
          db.exerciseIdentityBindings,
        )..where((row) => row.id.equals(orphanBindingId))).getSingleOrNull(),
        isNot(equals(null)),
      );
      expect(autoSyncCalls, 0);
      expect(
        await db.getExerciseExternalId(
          clientId: 'mixed-client',
          templateExerciseId: slot.id,
        ),
        hammer.externalId,
      );
      expect(
        await db
            .customSelect(
              'SELECT * FROM client_exercise_name_overrides '
              'WHERE client_id = ? AND template_exercise_id = ?',
              variables: [
                Variable.withString('mixed-client'),
                Variable.withInt(slot.id),
              ],
            )
            .get(),
        isEmpty,
      );
      final queue = await db.select(db.syncQueue).get();
      expect(queue, hasLength(1));
      expect(
        queue.single.entityExternalId,
        '23000000-0000-4000-8000-000000000004',
      );
      expect(queue.single.status, 'PENDING');

      final laterSession = await addSession(
        db,
        clientId: 'mixed-client',
        uuid: '23000000-0000-4000-8000-000000000003',
        gender: 'М',
        templateIdx: template.idx,
        day: DateTime(2026, 9, 3),
      );
      await db.saveWorkoutResultsAndMarkDone(
        clientId: 'mixed-client',
        day: DateTime(2026, 9, 3),
        resultsByTemplateExerciseId: {slot.id: (20, 12)},
        sessionId: laterSession,
      );
      final laterResult = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.sessionId.equals(laterSession))).getSingle();
      expect(laterResult.exerciseIdentityId, hammer.id);
      expect(
        (await db.analyzeLegacyExerciseBindings()).candidates.where(
          (item) => item.clientId == 'mixed-client',
        ),
        isEmpty,
      );
    },
  );

  test(
    'correction rolls back results and current slot when enqueue fails',
    () async {
      final db = await openDb();
      final from = await addExercise(
        db,
        'Rollback from',
        '31000000-0000-4000-8000-000000000001',
      );
      final target = await addExercise(
        db,
        'Rollback target',
        '31000000-0000-4000-8000-000000000002',
      );
      final template = (await db.getWorkoutTemplatesByGender('М')).first;
      final slot =
          await (db.select(db.workoutTemplateExercises)
                ..where((row) => row.templateId.equals(template.id))
                ..limit(1))
              .getSingle();
      final session = await addSession(
        db,
        clientId: 'missing-client',
        uuid: '33000000-0000-4000-8000-000000000001',
        gender: 'М',
        templateIdx: template.idx,
        day: DateTime(2026, 9, 4),
      );
      final resultId = await addResult(
        db,
        sessionId: session,
        slotId: slot.id,
        identityId: from.id,
        snapshot: target.canonicalName,
      );
      await db
          .into(db.clientTemplateExerciseOverrides)
          .insert(
            ClientTemplateExerciseOverridesCompanion.insert(
              clientId: 'missing-client',
              templateExerciseId: slot.id,
              exerciseIdentityId: Value(from.id),
            ),
          );
      await db.customStatement(
        'INSERT INTO client_exercise_name_overrides '
        '(client_id, template_exercise_id, custom_name) VALUES (?, ?, ?)',
        ['missing-client', slot.id, target.canonicalName],
      );

      await expectLater(
        db.reassignLegacyExerciseGroups([
          LegacyExerciseBulkCorrectionRequest(
            normalizedLegacyName: target.canonicalName,
            targetExerciseIdentityId: target.id,
          ),
        ]),
        throwsStateError,
      );
      final result = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(resultId))).getSingle();
      expect(result.exerciseIdentityId, from.id);
      final slotAfter = await (db.select(
        db.clientTemplateExerciseOverrides,
      )..where((row) => row.clientId.equals('missing-client'))).getSingle();
      expect(slotAfter.exerciseIdentityId, from.id);
      expect(
        await db
            .customSelect(
              'SELECT * FROM client_exercise_name_overrides '
              'WHERE client_id = ?',
              variables: [Variable.withString('missing-client')],
            )
            .get(),
        hasLength(1),
      );
      expect(await db.select(db.syncQueue).get(), isEmpty);
    },
  );

  test('corrected binding and results survive backup round-trip', () async {
    final db = await openDb();
    final from = await addExercise(
      db,
      'Backup legacy',
      '41000000-0000-4000-8000-000000000001',
    );
    final target = await addExercise(
      db,
      'Backup target',
      '41000000-0000-4000-8000-000000000002',
    );
    await db
        .into(db.clients)
        .insert(
          ClientsCompanion.insert(
            id: 'backup-cleanup-client',
            externalId: const Value('42000000-0000-4000-8000-000000000001'),
            name: 'Backup cleanup',
            gender: const Value('М'),
          ),
        );
    final template = (await db.getWorkoutTemplatesByGender('М')).first;
    final slot =
        await (db.select(db.workoutTemplateExercises)
              ..where((row) => row.templateId.equals(template.id))
              ..limit(1))
            .getSingle();
    final session = await addSession(
      db,
      clientId: 'backup-cleanup-client',
      uuid: '43000000-0000-4000-8000-000000000001',
      gender: 'М',
      templateIdx: template.idx,
      day: DateTime(2026, 9, 4),
    );
    final resultId = await addResult(
      db,
      sessionId: session,
      slotId: slot.id,
      identityId: from.id,
      snapshot: 'Backup snapshot',
    );
    await db.reassignLegacyExerciseData(
      clientId: 'backup-cleanup-client',
      templateExerciseId: slot.id,
      historicalResultIds: [resultId],
      targetExerciseIdentityId: target.id,
      reassignCurrentSlot: true,
    );

    final backup = await db.buildBackupPayload(
      appVersion: '1.15.0',
      buildNumber: '107',
    );
    final restored = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(restored.close);
    await restored.importBackupPayload(
      jsonDecode(jsonEncode(backup)) as Map<String, dynamic>,
    );
    final restoredResult = await (restored.select(
      restored.workoutExerciseResults,
    )..where((row) => row.id.equals(resultId))).getSingle();
    expect(restoredResult.exerciseIdentityId, target.id);
    expect(restoredResult.exerciseNameSnapshot, 'Backup snapshot');
    expect(
      await restored.getExerciseExternalId(
        clientId: 'backup-cleanup-client',
        templateExerciseId: slot.id,
      ),
      target.externalId,
    );
    expect(await restored.getExerciseUuidAliases(), isEmpty);
  });
}
