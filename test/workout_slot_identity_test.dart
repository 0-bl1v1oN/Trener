import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/pult/pult_store.dart';

void main() {
  group('program workout slot identity', () {
    late AppDb db;

    setUp(() async {
      db = AppDb.forTesting(NativeDatabase.memory());
      await _createProgramClient(db, 'slot-client');
    });

    tearDown(() => db.close());

    test(
      'first save creates one session and repeat updates results, UUID and queue',
      () async {
        final exerciseId = await _firstExerciseId(db, 'slot-client');
        final first = await db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: DateTime(2026, 8, 10, 10),
          templateIdx: 0,
          results: {exerciseId: (40, 10)},
        );
        final stateAfterFirst = await db.getProgramStateForClient(
          'slot-client',
        );

        final repeated = await db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: DateTime(2026, 8, 10, 12),
          templateIdx: 0,
          results: {exerciseId: (55.5, 12)},
        );

        final sessions = await db.select(db.workoutSessions).get();
        final results = await db.select(db.workoutExerciseResults).get();
        final queue = await db.select(db.syncQueue).get();
        final stateAfterRepeat = await db.getProgramStateForClient(
          'slot-client',
        );

        expect(sessions, hasLength(1));
        expect(first.id, repeated.id);
        expect(first.externalId, repeated.externalId);
        expect(sessions.single.absoluteIndex, 0);
        expect(results, hasLength(1));
        expect(results.single.lastWeightKg, 55.5);
        expect(results.single.lastReps, 12);
        expect(queue, hasLength(1));
        expect(queue.single.entityExternalId, first.externalId);
        expect(queue.single.payload, contains('55.5'));
        expect(stateAfterFirst?.completedInPlan, 1);
        expect(stateAfterRepeat?.completedInPlan, 1);
      },
    );

    test(
      'different absolute indexes and the same template are allowed on one day',
      () async {
        final day = DateTime(2026, 8, 10, 10);
        await db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: day,
          templateIdx: 0,
          results: const {},
        );
        await db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 1,
          performedAt: day.add(const Duration(hours: 1)),
          templateIdx: 0,
          results: const {},
        );

        final sessions = await db.select(db.workoutSessions).get();
        expect(sessions, hasLength(2));
        expect(sessions.map((row) => row.absoluteIndex), containsAll([0, 1]));
        expect(sessions.map((row) => row.templateIdx).toSet(), {0});
      },
    );

    test(
      'program overview resolves sessions by stored absolute index',
      () async {
        final slot0 = await db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: DateTime(2026, 8, 11),
          templateIdx: 0,
          results: const {},
        );
        final slot1 = await db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 1,
          performedAt: DateTime(2026, 8, 10),
          templateIdx: 1,
          results: const {},
        );

        final overview = await db.getProgramOverview('slot-client');
        final resolved0 = overview.slots.singleWhere(
          (slot) => slot.absoluteIndex == 0,
        );
        final resolved1 = overview.slots.singleWhere(
          (slot) => slot.absoluteIndex == 1,
        );
        expect(resolved0.sessionId, slot0.id);
        expect(resolved1.sessionId, slot1.id);
      },
    );

    test('partial unique index rejects a duplicate non-null slot', () async {
      final existing = await db.saveCompletedProgramSlot(
        clientId: 'slot-client',
        planInstance: 1,
        absoluteIndex: 0,
        performedAt: DateTime(2026, 8, 10),
        templateIdx: 0,
        results: const {},
      );

      await expectLater(
        db
            .into(db.workoutSessions)
            .insert(
              WorkoutSessionsCompanion.insert(
                externalId: const Value('00000000-0000-4000-8000-000000000001'),
                clientId: existing.clientId,
                performedAt: existing.performedAt,
                planInstance: existing.planInstance,
                absoluteIndex: const Value(0),
                gender: existing.gender,
                templateIdx: existing.templateIdx,
              ),
            ),
        throwsA(anything),
      );
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
    });

    test('two concurrent saves leave one row and one queue task', () async {
      await Future.wait([
        db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: DateTime(2026, 8, 10, 10),
          templateIdx: 0,
          results: const {},
        ),
        db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: DateTime(2026, 8, 10, 11),
          templateIdx: 0,
          results: const {},
        ),
      ]);

      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.select(db.syncQueue).get(), hasLength(1));
      expect(
        (await db.getProgramStateForClient('slot-client'))?.completedInPlan,
        1,
      );
    });

    test(
      'explicit slot reference is used instead of current position',
      () async {
        final day = DateTime(2026, 8, 10);
        await db.saveWorkoutResultsAndMarkDone(
          clientId: 'slot-client',
          day: day,
          templateIdx: 2,
          planInstance: 1,
          absoluteIndex: 3,
          resultsByTemplateExerciseId: const {},
        );

        final session = await db.select(db.workoutSessions).getSingle();
        expect(session.planInstance, 1);
        expect(session.absoluteIndex, 3);
        expect(session.templateIdx, 2);
      },
    );

    test('stale plan cannot create a workout in the renewed plan', () async {
      await db.restartClientPlanProgress('slot-client');

      await expectLater(
        db.saveCompletedProgramSlot(
          clientId: 'slot-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: DateTime(2026, 8, 10),
          templateIdx: 0,
          results: const {},
        ),
        throwsA(isA<StaleProgramSlotException>()),
      );

      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.syncQueue).get(), isEmpty);
      expect(
        (await db.getProgramStateForClient('slot-client'))?.planInstance,
        2,
      );
    });

    test('legacy null slot can still be opened by session id', () async {
      final legacyId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              externalId: const Value('00000000-0000-4000-8000-000000000002'),
              clientId: 'slot-client',
              performedAt: DateTime(2026, 8, 9),
              planInstance: 1,
              gender: 'М',
              templateIdx: 0,
            ),
          );

      final details = await db.getWorkoutDetailsForClientProgramSlot(
        clientId: 'slot-client',
        planInstance: 1,
        absoluteIndex: 0,
        templateIdx: 0,
        sessionId: legacyId,
      );

      expect(details.$2, legacyId);
      expect(
        (await db.select(db.workoutSessions).getSingle()).absoluteIndex,
        isNull,
      );
    });
  });

  group('slot identity backup and migration', () {
    test(
      'new backup round-trip preserves absolute index and sync task',
      () async {
        final source = AppDb.forTesting(NativeDatabase.memory());
        await _createProgramClient(source, 'backup-client');
        final saved = await source.saveCompletedProgramSlot(
          clientId: 'backup-client',
          planInstance: 1,
          absoluteIndex: 2,
          performedAt: DateTime(2026, 8, 10),
          templateIdx: 2,
          results: const {},
        );
        final backup = await source.buildBackupPayload(
          appVersion: '1.9.9',
          buildNumber: '101',
        );
        await source.close();

        final restored = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(restored.close);
        await restored.importBackupPayload(backup);

        final session = await restored
            .select(restored.workoutSessions)
            .getSingle();
        final queue = await restored.select(restored.syncQueue).getSingle();
        expect(backup['schemaVersion'], 15);
        expect(session.absoluteIndex, 2);
        expect(session.externalId, saved.externalId);
        expect(queue.entityExternalId, saved.externalId);
      },
    );

    test('old backup without absolute_index restores it as null', () async {
      final source = AppDb.forTesting(NativeDatabase.memory());
      await _createProgramClient(source, 'old-backup-client');
      final saved = await source.saveCompletedProgramSlot(
        clientId: 'old-backup-client',
        planInstance: 1,
        absoluteIndex: 0,
        performedAt: DateTime(2026, 8, 10),
        templateIdx: 0,
        results: const {},
      );
      final modern = await source.buildBackupPayload(
        appVersion: '1.9.9',
        buildNumber: '101',
      );
      final old = jsonDecode(jsonEncode(modern)) as Map<String, dynamic>;
      old['schemaVersion'] = 10;
      final tables = old['tables'] as Map<String, dynamic>;
      for (final raw in tables['workout_sessions'] as List<dynamic>) {
        (raw as Map<String, dynamic>).remove('absolute_index');
      }
      await source.close();

      final restored = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);
      await restored.importBackupPayload(old);

      final session = await restored
          .select(restored.workoutSessions)
          .getSingle();
      final queue = await restored.select(restored.syncQueue).getSingle();
      expect(session.absoluteIndex, isNull);
      expect(session.externalId, saved.externalId);
      expect(queue.entityExternalId, saved.externalId);
    });

    test(
      'schema 10 migration keeps historical session and queue unchanged',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'trener-slot-migration-',
        );
        addTearDown(() => temp.delete(recursive: true));
        final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

        var db = AppDb.forTesting(NativeDatabase(file));
        await _createProgramClient(db, 'migration-client');
        final saved = await db.saveCompletedProgramSlot(
          clientId: 'migration-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: DateTime(2026, 8, 10),
          templateIdx: 0,
          results: const {},
        );
        final queueBefore = await db.select(db.syncQueue).getSingle();

        await db.customStatement(
          'DROP INDEX workout_sessions_program_slot_unique',
        );
        await db.customStatement(
          'ALTER TABLE workout_sessions RENAME TO workout_sessions_v11',
        );
        await db.customStatement('''
        CREATE TABLE workout_sessions (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          external_id TEXT NULL,
          client_id TEXT NOT NULL,
          performed_at INTEGER NOT NULL,
          plan_instance INTEGER NOT NULL,
          gender TEXT NOT NULL,
          template_idx INTEGER NOT NULL
        )
      ''');
        await db.customStatement('''
        INSERT INTO workout_sessions
          (id, external_id, client_id, performed_at, plan_instance, gender, template_idx)
        SELECT id, external_id, client_id, performed_at, plan_instance, gender, template_idx
        FROM workout_sessions_v11
      ''');
        await db.customStatement('DROP TABLE workout_sessions_v11');
        await db.customStatement('PRAGMA user_version = 10');
        await db.close();

        db = AppDb.forTesting(NativeDatabase(file));
        addTearDown(db.close);
        final migrated = await db.select(db.workoutSessions).getSingle();
        final queueAfter = await db.select(db.syncQueue).getSingle();
        final indexes = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'workout_sessions_program_slot_unique'",
            )
            .get();

        expect(migrated.externalId, saved.externalId);
        expect(migrated.absoluteIndex, isNull);
        expect(queueAfter.id, queueBefore.id);
        expect(queueAfter.entityExternalId, queueBefore.entityExternalId);
        expect(queueAfter.payload, queueBefore.payload);
        expect(indexes, hasLength(1));
      },
    );
  });

  test('Pult tab persists captured plan instance', () async {
    final encoded = jsonEncode(
      PultTabEntry(
        clientId: 'pult-client',
        clientName: 'Client',
        day: DateTime(2026, 8, 10),
        templateIdx: 2,
        planInstance: 7,
        absoluteIndex: 12,
      ).toJson(),
    );
    final restored = PultTabEntry.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );

    expect(restored.planInstance, 7);
    expect(restored.absoluteIndex, 12);
  });
}

Future<void> _createProgramClient(AppDb db, String clientId) async {
  await db.upsertClient(
    ClientsCompanion.insert(
      id: clientId,
      name: 'Test client',
      gender: const Value('М'),
      plan: const Value('4'),
    ),
  );
  await db.ensureProgramStateForClient(clientId);
}

Future<int> _firstExerciseId(AppDb db, String clientId) async {
  final exercises = await db.getWorkoutPreviewForClient(
    clientId: clientId,
    gender: 'М',
    templateIdx: 0,
  );
  return exercises.first.templateExerciseId;
}
