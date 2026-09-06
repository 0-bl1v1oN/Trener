import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

void main() {
  group('external identity migration', () {
    test(
      'migrates a populated schema 7 database without changing local ids',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'trener-v7-migration-',
        );
        addTearDown(() => temp.delete(recursive: true));
        final file = File('${temp.path}${Platform.pathSeparator}legacy.sqlite');
        _createLegacyV7Database(file);

        final db = AppDb.forTesting(NativeDatabase(file));
        addTearDown(db.close);

        final client = await db.getClientById('legacy-client');
        expect(client, isNotNull);
        expect(client!.id, 'legacy-client');
        expect(client.name, 'Старый клиент');
        expect(client.status, AppDb.activeClientStatus);
        expect(client.externalId, matches(_uuidV4));

        final session = await (db.select(
          db.workoutSessions,
        )..where((row) => row.id.equals(41))).getSingle();
        expect(session.id, 41);
        expect(session.clientId, 'legacy-client');
        expect(session.externalId, matches(_uuidV4));

        final result = await (db.select(
          db.workoutExerciseResults,
        )..where((row) => row.id.equals(51))).getSingle();
        expect(result.sessionId, 41);
        expect(result.templateExerciseId, 31);
        expect(result.lastWeightKg, 42.5);
        expect(result.lastReps, 9);
        expect(result.exerciseIdentityId, isNotNull);
        expect(result.exerciseNameSnapshot, 'Тяга');

        final identity =
            await (db.select(db.exerciseIdentities)
                  ..where((row) => row.id.equals(result.exerciseIdentityId!)))
                .getSingle();
        expect(identity.externalId, matches(_uuidV4));

        final clientCount = await _count(db, 'clients');
        final sessionCount = await _count(db, 'workout_sessions');
        final resultCount = await _count(db, 'workout_exercise_results');
        expect((clientCount, sessionCount, resultCount), (2, 2, 2));
        final allClients = await db.getAllClients();
        final allSessions = await db.select(db.workoutSessions).get();
        expect(allClients.map((row) => row.id).toSet(), {
          'legacy-client',
          'legacy-client-2',
        });
        expect(allClients.map((row) => row.externalId).toSet().length, 2);
        expect(allClients.every((row) => row.status == 'ACTIVE'), isTrue);
        expect(allSessions.map((row) => row.externalId).toSet().length, 2);

        final version = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), 15);
      },
    );

    test('migrates schema 8 to current schema without data loss', () async {
      final temp = await Directory.systemTemp.createTemp(
        'trener-v8-migration-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final file = File(
        '${temp.path}${Platform.pathSeparator}legacy-v8.sqlite',
      );
      _createLegacyV8Database(file);

      final db = AppDb.forTesting(NativeDatabase(file));
      addTearDown(db.close);

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 15);
      expect(await _count(db, 'clients'), 2);
      expect(await _count(db, 'workout_sessions'), 2);
      expect(await _count(db, 'workout_exercise_results'), 2);
      final queue = await db.select(db.syncQueue).get();
      expect(queue, hasLength(2));
      expect(queue.every((entry) => entry.status == 'PENDING'), isTrue);
      expect(queue.map((entry) => entry.entityExternalId).toSet(), {
        '33333333-3333-4333-8333-333333333333',
        '44444444-4444-4444-8444-444444444444',
      });
      expect(await db.select(db.syncLog).get(), isEmpty);
    });

    test('schema 12 migrates to current merge infrastructure', () async {
      final temp = await Directory.systemTemp.createTemp(
        'trener-v12-merge-migration-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final file = File(
        '${temp.path}${Platform.pathSeparator}schema-v12.sqlite',
      );

      var db = AppDb.forTesting(NativeDatabase(file));
      await db.getActiveExercises();
      await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: 'aaaa0000-0000-4000-8000-000000000001',
              canonicalName: const Value('Legacy duplicate'),
              normalizedName: const Value('legacy duplicate'),
            ),
          );
      await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: 'aaaa0000-0000-4000-8000-000000000002',
              canonicalName: const Value('Legacy duplicate'),
              normalizedName: const Value('legacy duplicate'),
            ),
          );
      final countBefore = await _count(db, 'exercise_identities');
      await db.close();

      final sqliteDb = sqlite.sqlite3.open(file.path);
      try {
        sqliteDb.execute('DROP TABLE exercise_identity_aliases');
        sqliteDb.execute(
          'ALTER TABLE exercise_identities RENAME TO exercise_identities_v13',
        );
        sqliteDb.execute('''
          CREATE TABLE exercise_identities (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            external_id TEXT NOT NULL,
            canonical_name TEXT NOT NULL DEFAULT '',
            normalized_name TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT 'ACTIVE',
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
            updated_at INTEGER,
            archived_at INTEGER
          )
        ''');
        sqliteDb.execute('''
          INSERT INTO exercise_identities
            (id, external_id, canonical_name, normalized_name, status,
             created_at, updated_at, archived_at)
          SELECT id, external_id, canonical_name, normalized_name, status,
                 created_at, updated_at, archived_at
          FROM exercise_identities_v13
        ''');
        sqliteDb.execute('DROP TABLE exercise_identities_v13');
        sqliteDb.execute('PRAGMA user_version = 12');
      } finally {
        sqliteDb.dispose();
      }

      db = AppDb.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 15);
      expect(await _count(db, 'exercise_identities'), countBefore);
      expect(await db.select(db.exerciseIdentityAliases).get(), isEmpty);
      final duplicates = (await db.getExerciseDuplicateGroups()).where(
        (group) => group.normalizedName == 'legacy duplicate',
      );
      expect(duplicates, hasLength(1));
      expect(duplicates.single.items, hasLength(2));
      expect(
        duplicates.single.items.every(
          (item) => item.exercise.mergedIntoIdentityId == null,
        ),
        isTrue,
      );
    });

    test(
      'schema 13 to 14 merges only the four validated empty duplicates',
      () async {
        const pairs = <(String, String, String)>[
          (
            '0e6d41b3-8e85-430b-b2fa-e74145517065',
            'ca91d5b0-5a80-43ca-91f6-7b591086bbdd',
            'Тяга верхнего блока параллельным хватом',
          ),
          (
            'a5e82f98-6165-4843-b572-8b2b9417765a',
            '7ef69ad0-3588-4a50-935e-6d4c11431fa0',
            'Жим ногами',
          ),
          (
            'c416f9e9-be64-4fe7-ae16-1d3de9d4c0c0',
            '81b869d0-2881-4ca5-8990-986ace32a00c',
            'Жим в хамере',
          ),
          (
            'ff9c9b6e-5f77-48a5-9118-e3ed758fb23c',
            '966607d2-84a0-4d63-a66a-65f66e655695',
            'Выпады на месте',
          ),
        ];
        final temp = await Directory.systemTemp.createTemp(
          'trener-v13-empty-duplicate-migration-',
        );
        addTearDown(() => temp.delete(recursive: true));
        final file = File(
          '${temp.path}${Platform.pathSeparator}schema-v13.sqlite',
        );

        var db = AppDb.forTesting(NativeDatabase(file));
        await db.getActiveExercises();
        await db
            .into(db.clients)
            .insert(
              ClientsCompanion.insert(
                id: 'known-merge-client',
                externalId: const Value('11111111-2222-4333-8444-555555555555'),
                name: 'Проверка merge',
                gender: const Value('М'),
              ),
            );
        final template = (await db.getWorkoutTemplatesByGender('М')).first;
        final templateSlot = (await db.getTemplateExercisesByTemplateId(
          template.id,
        )).first;
        final canonicalResultIds = <int>[];
        final queuePayloads = <String>[];

        for (var index = 0; index < pairs.length; index++) {
          final pair = pairs[index];
          final canonicalId = await db
              .into(db.exerciseIdentities)
              .insert(
                ExerciseIdentitiesCompanion.insert(
                  externalId: pair.$2,
                  canonicalName: Value(pair.$3),
                  normalizedName: Value(AppDb.normalizeExerciseName(pair.$3)),
                ),
              );
          final oldId = await db
              .into(db.exerciseIdentities)
              .insert(
                ExerciseIdentitiesCompanion.insert(
                  externalId: pair.$1,
                  canonicalName: Value(pair.$3),
                  normalizedName: Value(AppDb.normalizeExerciseName(pair.$3)),
                ),
              );
          await db
              .into(db.exerciseIdentityBindings)
              .insert(
                ExerciseIdentityBindingsCompanion.insert(
                  sourceType: 'TEMPLATE',
                  sourceId: 9000 + index,
                  identityId: oldId,
                ),
              );

          final workoutUuid =
              '22222222-3333-4${index}44-8555-66666666666$index';
          final sessionId = await db
              .into(db.workoutSessions)
              .insert(
                WorkoutSessionsCompanion.insert(
                  externalId: Value(workoutUuid),
                  clientId: 'known-merge-client',
                  performedAt: DateTime(2026, 9, 1 + index),
                  planInstance: 1,
                  gender: 'М',
                  templateIdx: template.idx,
                ),
              );
          canonicalResultIds.add(
            await db
                .into(db.workoutExerciseResults)
                .insert(
                  WorkoutExerciseResultsCompanion.insert(
                    sessionId: sessionId,
                    templateExerciseId: templateSlot.id,
                    exerciseIdentityId: Value(canonicalId),
                    exerciseNameSnapshot: Value(pair.$3),
                  ),
                ),
          );
          final queuePayload = '{"exercise_id":"${pair.$2}"}';
          queuePayloads.add(queuePayload);
          await db
              .into(db.syncQueue)
              .insert(
                SyncQueueCompanion.insert(
                  entityType: 'WORKOUT',
                  entityExternalId: workoutUuid,
                  operation: 'WORKOUT_UPSERT',
                  payload: queuePayload,
                ),
              );
        }
        final sentinelId = await db
            .into(db.exerciseIdentities)
            .insert(
              ExerciseIdentitiesCompanion.insert(
                externalId: '33333333-4444-4555-8666-777777777777',
                canonicalName: const Value('Не связанное упражнение'),
                normalizedName: const Value('не связанное упражнение'),
              ),
            );
        await db.close();

        final sqliteDb = sqlite.sqlite3.open(file.path);
        try {
          sqliteDb.execute('PRAGMA user_version = 13');
        } finally {
          sqliteDb.dispose();
        }

        db = AppDb.forTesting(NativeDatabase(file));
        addTearDown(db.close);
        final version = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), 15);

        for (final pair in pairs) {
          final old = await (db.select(
            db.exerciseIdentities,
          )..where((row) => row.externalId.equals(pair.$1))).getSingle();
          final canonical = await (db.select(
            db.exerciseIdentities,
          )..where((row) => row.externalId.equals(pair.$2))).getSingle();
          expect(old.status, AppDb.archivedExerciseStatus);
          expect(old.mergedIntoIdentityId, canonical.id);
          expect(canonical.status, AppDb.activeExerciseStatus);
          expect(canonical.mergedIntoIdentityId, null);
          expect(await db.resolveCanonicalExerciseUuid(pair.$1), pair.$2);
          expect(
            await (db.select(
              db.workoutExerciseResults,
            )..where((row) => row.exerciseIdentityId.equals(old.id))).get(),
            isEmpty,
          );
          expect(
            await (db.select(
              db.exerciseIdentityBindings,
            )..where((row) => row.identityId.equals(old.id))).get(),
            isEmpty,
          );
        }
        for (final resultId in canonicalResultIds) {
          expect(
            await (db.select(
              db.workoutExerciseResults,
            )..where((row) => row.id.equals(resultId))).getSingle(),
            isNotNull,
          );
        }
        expect(
          (await db.getExerciseById(sentinelId))?.status,
          AppDb.activeExerciseStatus,
        );
        expect(
          (await db.select(db.syncQueue).get()).map((row) => row.payload),
          queuePayloads,
        );
        final active = await db.getActiveExercises();
        for (final pair in pairs) {
          expect(
            active.where(
              (item) =>
                  item.externalId == pair.$1 || item.externalId == pair.$2,
            ),
            hasLength(1),
          );
        }
      },
    );

    test('schema 14 data fix skips a known duplicate with history', () async {
      final temp = await Directory.systemTemp.createTemp(
        'trener-v14-unsafe-duplicate-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final file = File(
        '${temp.path}${Platform.pathSeparator}unsafe-v13.sqlite',
      );

      var db = AppDb.forTesting(NativeDatabase(file));
      await db.getActiveExercises();
      final canonicalId = await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: 'ca91d5b0-5a80-43ca-91f6-7b591086bbdd',
              canonicalName: const Value(
                'Тяга верхнего блока параллельным хватом',
              ),
              normalizedName: const Value(
                'тяга верхнего блока параллельным хватом',
              ),
            ),
          );
      final oldId = await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: '0e6d41b3-8e85-430b-b2fa-e74145517065',
              canonicalName: const Value(
                'Тяга верхнего блока параллельным хватом',
              ),
              normalizedName: const Value(
                'тяга верхнего блока параллельным хватом',
              ),
            ),
          );
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: 'unsafe-merge-client',
              externalId: const Value('44444444-5555-4666-8777-888888888888'),
              name: 'Исторический клиент',
            ),
          );
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              externalId: const Value('55555555-6666-4777-8888-999999999999'),
              clientId: 'unsafe-merge-client',
              performedAt: DateTime(2026, 9, 5),
              planInstance: 1,
              gender: 'М',
              templateIdx: 0,
            ),
          );
      final slot = (await db.getTemplateExercisesByTemplateId(
        (await db.getWorkoutTemplatesByGender('М')).first.id,
      )).first;
      await db
          .into(db.workoutExerciseResults)
          .insert(
            WorkoutExerciseResultsCompanion.insert(
              sessionId: sessionId,
              templateExerciseId: slot.id,
              exerciseIdentityId: Value(oldId),
              exerciseNameSnapshot: const Value(
                'Тяга верхнего блока параллельным хватом',
              ),
            ),
          );
      await db.close();

      final sqliteDb = sqlite.sqlite3.open(file.path);
      try {
        sqliteDb.execute('PRAGMA user_version = 13');
      } finally {
        sqliteDb.dispose();
      }

      db = AppDb.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      final old = (await db.getExerciseById(oldId))!;
      expect(old.status, AppDb.activeExerciseStatus);
      expect(old.mergedIntoIdentityId, null);
      expect(
        await db.resolveCanonicalExerciseUuid(old.externalId),
        old.externalId,
      );
      expect(
        (await db.getExerciseById(canonicalId))?.status,
        AppDb.activeExerciseStatus,
      );
      expect(await db.getExerciseUuidAliases(), isEmpty);
    });

    test(
      'new client and workout receive stable UUIDs and ACTIVE status',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        await db.upsertClient(
          ClientsCompanion.insert(
            id: 'local-client',
            name: 'Новый клиент',
            gender: const Value('М'),
            plan: const Value('4'),
          ),
        );
        final created = (await db.getClientById('local-client'))!;
        expect(created.externalId, matches(_uuidV4));
        expect(created.status, AppDb.activeClientStatus);

        await db.upsertClient(
          ClientsCompanion.insert(
            id: 'local-client',
            name: 'Новое имя',
            gender: const Value('Ж'),
            plan: const Value('8'),
          ),
        );
        final edited = (await db.getClientById('local-client'))!;
        expect(edited.externalId, created.externalId);
        expect(edited.status, AppDb.activeClientStatus);
        await expectLater(
          db.upsertClient(
            ClientsCompanion.insert(
              id: 'local-client',
              externalId: const Value('00000000-0000-4000-8000-000000000000'),
              name: 'Попытка сменить UUID',
            ),
          ),
          throwsStateError,
        );
        expect(
          (await db.getClientById('local-client'))!.externalId,
          created.externalId,
        );

        final day = DateTime(2026, 8, 4, 12);
        await db.completeWorkoutForClient(clientId: 'local-client', when: day);
        final session = await (db.select(
          db.workoutSessions,
        )..where((row) => row.clientId.equals('local-client'))).getSingle();
        expect(session.externalId, matches(_uuidV4));

        final template =
            await (db.select(db.workoutTemplates)..where(
                  (row) =>
                      row.gender.equals('Ж') &
                      row.idx.equals(session.templateIdx),
                ))
                .getSingle();
        final exercise =
            await (db.select(db.workoutTemplateExercises)
                  ..where((row) => row.templateId.equals(template.id))
                  ..limit(1))
                .getSingle();
        await db.saveWorkoutResultsAndMarkDone(
          clientId: 'local-client',
          day: day,
          templateIdx: session.templateIdx,
          resultsByTemplateExerciseId: {exercise.id: (55.5, 12)},
        );

        final result = await db.select(db.workoutExerciseResults).getSingle();
        expect(result.exerciseIdentityId, isNotNull);
        expect(result.exerciseNameSnapshot, exercise.name);
        final externalBefore = await db.getExerciseExternalId(
          clientId: 'local-client',
          templateExerciseId: exercise.id,
        );
        await db.renameWorkoutExerciseForClient(
          clientId: 'local-client',
          templateExerciseId: exercise.id,
          newName: 'Переименованное упражнение',
        );
        final externalAfterRename = await db.getExerciseExternalId(
          clientId: 'local-client',
          templateExerciseId: exercise.id,
        );
        expect(externalAfterRename, externalBefore);

        final replacementExternal = await db.replaceExerciseIdentityForClient(
          clientId: 'local-client',
          templateExerciseId: exercise.id,
        );
        expect(replacementExternal, matches(_uuidV4));
        expect(replacementExternal, isNot(externalBefore));

        final historicalIdentity =
            await (db.select(db.exerciseIdentities)
                  ..where((row) => row.id.equals(result.exerciseIdentityId!)))
                .getSingle();
        expect(historicalIdentity.externalId, externalBefore);

        await db.addWorkoutExerciseForClient(
          clientId: 'local-client',
          templateId: template.id,
          name: 'Добавленное упражнение',
        );
        final added = await db
            .customSelect(
              "SELECT id FROM client_added_exercises WHERE client_id = 'local-client' LIMIT 1",
            )
            .getSingle();
        final addedSyntheticId = -added.read<int>('id');
        final addedExternalBefore = await db.getExerciseExternalId(
          clientId: 'local-client',
          templateExerciseId: addedSyntheticId,
        );
        await db.renameWorkoutExerciseForClient(
          clientId: 'local-client',
          templateExerciseId: addedSyntheticId,
          newName: 'Переименованное добавленное',
        );
        expect(
          await db.getExerciseExternalId(
            clientId: 'local-client',
            templateExerciseId: addedSyntheticId,
          ),
          addedExternalBefore,
        );
        expect(
          await db.replaceExerciseIdentityForClient(
            clientId: 'local-client',
            templateExerciseId: addedSyntheticId,
          ),
          isNot(addedExternalBefore),
        );
      },
    );

    test('new backup round-trip preserves every external identity', () async {
      final source = AppDb.forTesting(NativeDatabase.memory());
      await _createClientWorkoutAndResult(
        source,
        clientId: 'round-trip-client',
      );

      final sourceClient = (await source.getClientById('round-trip-client'))!;
      final sourceSession = await source
          .select(source.workoutSessions)
          .getSingle();
      final sourceResult = await source
          .select(source.workoutExerciseResults)
          .getSingle();
      final sourceIdentity =
          await (source.select(source.exerciseIdentities)..where(
                (row) => row.id.equals(sourceResult.exerciseIdentityId!),
              ))
              .getSingle();
      final payload = await source.buildBackupPayload(
        appVersion: '1.9.9',
        buildNumber: '101',
      );
      await source.close();

      final restored = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);
      await restored.importBackupPayload(payload);

      final restoredClient = (await restored.getClientById(
        'round-trip-client',
      ))!;
      final restoredSession = await restored
          .select(restored.workoutSessions)
          .getSingle();
      final restoredResult = await restored
          .select(restored.workoutExerciseResults)
          .getSingle();
      final restoredIdentity =
          await (restored.select(restored.exerciseIdentities)..where(
                (row) => row.id.equals(restoredResult.exerciseIdentityId!),
              ))
              .getSingle();

      expect(restoredClient.externalId, sourceClient.externalId);
      expect(restoredClient.status, sourceClient.status);
      expect(restoredSession.externalId, sourceSession.externalId);
      expect(restoredIdentity.externalId, sourceIdentity.externalId);
      expect(restoredResult.lastWeightKg, sourceResult.lastWeightKg);
      expect(restoredResult.lastReps, sourceResult.lastReps);
      expect(
        restoredResult.exerciseNameSnapshot,
        sourceResult.exerciseNameSnapshot,
      );
    });

    test(
      'old backup is normalized before restore and receives identities',
      () async {
        final source = AppDb.forTesting(NativeDatabase.memory());
        await _createClientWorkoutAndResult(
          source,
          clientId: 'old-backup-client',
        );
        final modernPayload = await source.buildBackupPayload(
          appVersion: '1.9.9',
          buildNumber: '101',
        );
        await source.close();
        final oldPayload =
            jsonDecode(jsonEncode(modernPayload)) as Map<String, dynamic>;
        oldPayload['schemaVersion'] = 7;
        final tables = oldPayload['tables'] as Map<String, dynamic>;
        tables.remove('exercise_identities');
        tables.remove('exercise_identity_bindings');
        tables.remove('sync_queue');
        tables.remove('sync_log');
        for (final raw in tables['clients'] as List<dynamic>) {
          final row = raw as Map<String, dynamic>;
          row.remove('external_id');
          row.remove('status');
        }
        for (final raw in tables['workout_sessions'] as List<dynamic>) {
          (raw as Map<String, dynamic>).remove('external_id');
        }
        for (final raw in tables['workout_exercise_results'] as List<dynamic>) {
          final row = raw as Map<String, dynamic>;
          row.remove('exercise_identity_id');
          row.remove('exercise_name_snapshot');
        }

        final restored = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(restored.close);
        await restored.importBackupPayload(oldPayload);

        final client = (await restored.getClientById('old-backup-client'))!;
        final session = await restored
            .select(restored.workoutSessions)
            .getSingle();
        final result = await restored
            .select(restored.workoutExerciseResults)
            .getSingle();
        expect(client.id, 'old-backup-client');
        expect(client.externalId, matches(_uuidV4));
        expect(client.status, AppDb.activeClientStatus);
        expect(session.externalId, matches(_uuidV4));
        expect(result.lastWeightKg, 60.0);
        expect(result.lastReps, 10);
        expect(result.exerciseIdentityId, isNotNull);
        expect(result.exerciseNameSnapshot, isNotEmpty);
        expect(await restored.getPendingSyncTaskCount(), 1);
      },
    );

    test('failed restore rolls back the initial table cleanup', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertClient(
        ClientsCompanion.insert(id: 'protected-client', name: 'Не потерять'),
      );
      final payload = await db.buildBackupPayload(
        appVersion: '1.9.9',
        buildNumber: '101',
      );
      final broken = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
      final tables = broken['tables'] as Map<String, dynamic>;
      final clientRow =
          (tables['clients'] as List<dynamic>).single as Map<String, dynamic>;
      clientRow.remove('name');

      await expectLater(
        db.importBackupPayload(broken),
        throwsA(isA<Exception>()),
      );
      final preserved = await db.getClientById('protected-client');
      expect(preserved?.name, 'Не потерять');
    });
  });
}

Future<int> _count(AppDb db, String table) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS c FROM $table')
      .getSingle();
  return row.read<int>('c');
}

Future<void> _createClientWorkoutAndResult(
  AppDb db, {
  required String clientId,
}) async {
  await db.upsertClient(
    ClientsCompanion.insert(
      id: clientId,
      name: 'Клиент backup',
      gender: const Value('М'),
      plan: const Value('4'),
    ),
  );
  final day = DateTime(2026, 7, 10, 12);
  await db.completeWorkoutForClient(clientId: clientId, when: day);
  final session = await (db.select(
    db.workoutSessions,
  )..where((row) => row.clientId.equals(clientId))).getSingle();
  final template =
      await (db.select(db.workoutTemplates)..where(
            (row) =>
                row.gender.equals('М') & row.idx.equals(session.templateIdx),
          ))
          .getSingle();
  final exercise =
      await (db.select(db.workoutTemplateExercises)
            ..where((row) => row.templateId.equals(template.id))
            ..limit(1))
          .getSingle();
  await db.saveWorkoutResultsAndMarkDone(
    clientId: clientId,
    day: day,
    templateIdx: session.templateIdx,
    resultsByTemplateExerciseId: {exercise.id: (60.0, 10)},
  );
}

void _createLegacyV7Database(File file) {
  final db = sqlite.sqlite3.open(file.path);
  try {
    final statements = <String>[
      '''CREATE TABLE clients (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        gender TEXT,
        plan TEXT,
        plan_start INTEGER,
        plan_end INTEGER,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
      )''',
      '''CREATE TABLE appointments (
        id TEXT NOT NULL PRIMARY KEY,
        client_id TEXT NOT NULL,
        start_at INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
      )''',
      '''CREATE TABLE workout_templates (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        gender TEXT NOT NULL,
        idx INTEGER NOT NULL,
        label TEXT NOT NULL,
        title TEXT NOT NULL,
        payload_json TEXT,
        UNIQUE(gender, idx)
      )''',
      '''CREATE TABLE client_program_states (
        client_id TEXT NOT NULL PRIMARY KEY,
        plan_size INTEGER NOT NULL,
        plan_instance INTEGER NOT NULL DEFAULT 1,
        completed_in_plan INTEGER NOT NULL DEFAULT 0,
        cycle_start_index INTEGER NOT NULL DEFAULT 0,
        next_offset INTEGER NOT NULL DEFAULT 0,
        window_start INTEGER NOT NULL DEFAULT 0,
        plan_start INTEGER,
        plan_end INTEGER
      )''',
      '''CREATE TABLE client_template_exercise_overrides (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL,
        template_exercise_id INTEGER NOT NULL,
        superset_group INTEGER,
        UNIQUE(client_id, template_exercise_id)
      )''',
      '''CREATE TABLE workout_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL,
        performed_at INTEGER NOT NULL,
        plan_instance INTEGER NOT NULL,
        gender TEXT NOT NULL,
        template_idx INTEGER NOT NULL
      )''',
      '''CREATE TABLE workout_template_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        group_id INTEGER,
        name TEXT NOT NULL,
        UNIQUE(template_id, order_index)
      )''',
      '''CREATE TABLE workout_exercise_results (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        template_exercise_id INTEGER NOT NULL,
        last_weight_kg REAL,
        last_reps INTEGER,
        UNIQUE(session_id, template_exercise_id)
      )''',
      '''CREATE TABLE workout_drafts (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL,
        day INTEGER NOT NULL,
        template_idx INTEGER NOT NULL DEFAULT -1,
        template_exercise_id INTEGER NOT NULL,
        last_weight_kg REAL,
        last_reps INTEGER,
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
        UNIQUE(client_id, day, template_idx, template_exercise_id)
      )''',
    ];
    for (final statement in statements) {
      db.execute(statement);
    }
    db.execute(
      "INSERT INTO clients (id, name, gender, plan, created_at) "
      "VALUES ('legacy-client', 'Старый клиент', 'М', '4', 1700000000)",
    );
    db.execute(
      "INSERT INTO clients (id, name, gender, plan, created_at) "
      "VALUES ('legacy-client-2', 'Второй клиент', 'Ж', '8', 1700000100)",
    );
    db.execute(
      "INSERT INTO workout_templates (id, gender, idx, label, title) "
      "VALUES (21, 'М', 0, 'Спина', 'Старая тренировка')",
    );
    db.execute(
      "INSERT INTO workout_template_exercises "
      "(id, template_id, order_index, name) VALUES (31, 21, 0, 'Тяга')",
    );
    db.execute(
      "INSERT INTO client_program_states "
      "(client_id, plan_size, plan_instance, completed_in_plan) "
      "VALUES ('legacy-client', 4, 1, 1)",
    );
    db.execute(
      "INSERT INTO workout_sessions "
      "(id, client_id, performed_at, plan_instance, gender, template_idx) "
      "VALUES (41, 'legacy-client', 1700000000, 1, 'М', 0)",
    );
    db.execute(
      "INSERT INTO workout_sessions "
      "(id, client_id, performed_at, plan_instance, gender, template_idx) "
      "VALUES (42, 'legacy-client-2', 1700000100, 1, 'Ж', 0)",
    );
    db.execute(
      "INSERT INTO workout_exercise_results "
      "(id, session_id, template_exercise_id, last_weight_kg, last_reps) "
      "VALUES (51, 41, 31, 42.5, 9)",
    );
    db.execute(
      "INSERT INTO workout_exercise_results "
      "(id, session_id, template_exercise_id, last_weight_kg, last_reps) "
      "VALUES (52, 42, 31, 37.5, 11)",
    );
    db.execute('PRAGMA user_version = 7');
  } finally {
    db.dispose();
  }
}

void _createLegacyV8Database(File file) {
  _createLegacyV7Database(file);
  final db = sqlite.sqlite3.open(file.path);
  try {
    db.execute('ALTER TABLE clients ADD COLUMN external_id TEXT');
    db.execute(
      "ALTER TABLE clients ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE'",
    );
    db.execute('ALTER TABLE workout_sessions ADD COLUMN external_id TEXT');
    db.execute(
      'ALTER TABLE workout_exercise_results '
      'ADD COLUMN exercise_identity_id INTEGER',
    );
    db.execute(
      'ALTER TABLE workout_exercise_results '
      'ADD COLUMN exercise_name_snapshot TEXT',
    );
    db.execute('''CREATE TABLE exercise_identities (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      external_id TEXT NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
    )''');
    db.execute('''CREATE TABLE exercise_identity_bindings (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      client_id TEXT,
      source_type TEXT NOT NULL,
      source_id INTEGER NOT NULL,
      identity_id INTEGER NOT NULL,
      is_current INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
      retired_at INTEGER
    )''');
    db.execute(
      "UPDATE clients SET external_id = CASE id "
      "WHEN 'legacy-client' THEN '11111111-1111-4111-8111-111111111111' "
      "ELSE '22222222-2222-4222-8222-222222222222' END",
    );
    db.execute(
      "UPDATE workout_sessions SET external_id = CASE id "
      "WHEN 41 THEN '33333333-3333-4333-8333-333333333333' "
      "ELSE '44444444-4444-4444-8444-444444444444' END",
    );
    db.execute(
      "INSERT INTO exercise_identities (id, external_id) "
      "VALUES (61, '55555555-5555-4555-8555-555555555555')",
    );
    db.execute(
      "INSERT INTO exercise_identity_bindings "
      "(client_id, source_type, source_id, identity_id, is_current) "
      "VALUES (NULL, 'TEMPLATE', 31, 61, 1)",
    );
    db.execute(
      "UPDATE workout_exercise_results "
      "SET exercise_identity_id = 61, exercise_name_snapshot = 'Тяга'",
    );
    db.execute('PRAGMA user_version = 8');
  } finally {
    db.dispose();
  }
}
