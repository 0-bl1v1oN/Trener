import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/app/app_db_scope.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/more/sync_screen.dart';
import 'package:myfitness/sync/sync_models.dart';

void main() {
  group('workout sync queue rebuild', () {
    late AppDb db;

    setUp(() {
      db = AppDb.forTesting(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test(
      'dry-run rebuilds payload and preserves history and workout UUID',
      () async {
        await _createProgramClient(db, 'normal-client');
        final saved = await _saveSessionWithResult(
          db,
          clientId: 'normal-client',
          absoluteIndex: 0,
          templateIdx: 0,
          performedAt: DateTime(2026, 1, 10, 10),
          weight: 40,
        );
        final resultBefore = await db
            .select(db.workoutExerciseResults)
            .getSingle();
        await (db.update(
          db.workoutExerciseResults,
        )..where((row) => row.id.equals(resultBefore.id))).write(
          const WorkoutExerciseResultsCompanion(lastWeightKg: Value(77.5)),
        );
        final oldTask = await db.select(db.syncQueue).getSingle();
        await (db.update(
          db.syncQueue,
        )..where((row) => row.id.equals(oldTask.id))).write(
          const SyncQueueCompanion(
            payload: Value('old-queue-payload'),
            status: Value(SyncQueueStatuses.failed),
            attempts: Value(9),
            lastError: Value('old error'),
          ),
        );

        final preview = await db.analyzeWorkoutSyncQueueRebuild();
        final afterDryRun = await db.select(db.syncQueue).getSingle();
        expect(preview.totalSessions, 1);
        expect(preview.tasksToCreate, 1);
        expect(afterDryRun.payload, 'old-queue-payload');
        expect(afterDryRun.status, SyncQueueStatuses.failed);
        expect(afterDryRun.attempts, 9);

        final rebuild = await db.rebuildWorkoutSyncQueue(preview);
        final rebuiltTask = await db.select(db.syncQueue).getSingle();
        final sessionAfter = await db.select(db.workoutSessions).getSingle();
        final resultAfter = await db
            .select(db.workoutExerciseResults)
            .getSingle();

        expect(rebuild.createdTasks, 1);
        expect(rebuiltTask.entityExternalId, saved.externalId);
        expect(rebuiltTask.payload, isNot('old-queue-payload'));
        expect(rebuiltTask.payload, contains('77.5'));
        expect(rebuiltTask.status, SyncQueueStatuses.pending);
        expect(rebuiltTask.attempts, 0);
        expect(rebuiltTask.lastError, isNull);
        expect(rebuiltTask.nextAttemptAt, isNull);
        expect(sessionAfter.id, saved.id);
        expect(sessionAfter.externalId, saved.externalId);
        expect(resultAfter.id, resultBefore.id);
        expect(resultAfter.lastWeightKg, 77.5);
      },
    );

    test(
      'empty, missing-client, missing-UUID and bad payload sessions are excluded',
      () async {
        await _createProgramClient(db, 'empty-client');
        await db.saveCompletedProgramSlot(
          clientId: 'empty-client',
          planInstance: 1,
          absoluteIndex: 0,
          performedAt: DateTime(2026, 1, 1),
          templateIdx: 0,
          results: const {},
        );

        await _createProgramClient(db, 'deleted-client');
        await _saveSessionWithResult(
          db,
          clientId: 'deleted-client',
          absoluteIndex: 0,
          templateIdx: 0,
          performedAt: DateTime(2026, 1, 2),
        );
        await (db.delete(
          db.clients,
        )..where((row) => row.id.equals('deleted-client'))).go();

        await _createProgramClient(db, 'uuid-client');
        final missingUuid = await _saveSessionWithResult(
          db,
          clientId: 'uuid-client',
          absoluteIndex: 0,
          templateIdx: 0,
          performedAt: DateTime(2026, 1, 3),
        );
        await (db.update(db.workoutSessions)
              ..where((row) => row.id.equals(missingUuid.id)))
            .write(const WorkoutSessionsCompanion(externalId: Value(null)));

        await _createProgramClient(db, 'payload-client');
        final badPayload = await _saveSessionWithResult(
          db,
          clientId: 'payload-client',
          absoluteIndex: 0,
          templateIdx: 0,
          performedAt: DateTime(2026, 1, 4),
        );
        await (db.update(
          db.workoutExerciseResults,
        )..where((row) => row.sessionId.equals(badPayload.id))).write(
          const WorkoutExerciseResultsCompanion(
            exerciseNameSnapshot: Value(''),
          ),
        );

        final preview = await db.analyzeWorkoutSyncQueueRebuild();
        expect(preview.totalSessions, 4);
        expect(preview.emptySessions, 1);
        expect(preview.missingClients, 1);
        expect(preview.missingWorkoutExternalIds, 1);
        expect(preview.payloadErrors, 1);
        expect(preview.tasksToCreate, 0);

        await db.rebuildWorkoutSyncQueue(preview);
        expect(
          await (db.select(
                db.syncQueue,
              )..where((row) => row.entityType.equals(SyncEntityTypes.workout)))
              .get(),
          isEmpty,
        );
        expect(await db.select(db.workoutSessions).get(), hasLength(4));
        expect(await db.select(db.workoutExerciseResults).get(), hasLength(3));
      },
    );

    test('same date exact template-plan conflicts are skipped', () async {
      await _createProgramClient(db, 'conflict-client');
      final first = await _saveSessionWithResult(
        db,
        clientId: 'conflict-client',
        absoluteIndex: 0,
        templateIdx: 0,
        performedAt: DateTime(2026, 2, 10, 10),
      );
      final second = await _saveSessionWithResult(
        db,
        clientId: 'conflict-client',
        absoluteIndex: 1,
        templateIdx: 0,
        performedAt: DateTime(2026, 2, 10, 18),
      );

      final preview = await db.analyzeWorkoutSyncQueueRebuild();
      expect(preview.conflicts, hasLength(1));
      expect(preview.conflictSessions, 2);
      expect(preview.tasksToCreate, 0);
      expect(
        preview.conflicts.single.sessions.map((row) => row.sessionId).toSet(),
        {first.id, second.id},
      );

      await db.rebuildWorkoutSyncQueue(preview);
      expect(await db.select(db.syncQueue).get(), isEmpty);
      expect(await db.select(db.workoutSessions).get(), hasLength(2));
      expect(await db.select(db.workoutExerciseResults).get(), hasLength(2));
    });

    test(
      'different templates on one date both enter queue in historical order',
      () async {
        await _createProgramClient(db, 'two-workouts-client');
        final later = await _saveSessionWithResult(
          db,
          clientId: 'two-workouts-client',
          absoluteIndex: 0,
          templateIdx: 0,
          performedAt: DateTime(2026, 3, 10, 18),
        );
        final earlier = await _saveSessionWithResult(
          db,
          clientId: 'two-workouts-client',
          absoluteIndex: 1,
          templateIdx: 1,
          performedAt: DateTime(2026, 3, 10, 9),
        );

        final preview = await db.analyzeWorkoutSyncQueueRebuild();
        expect(preview.conflictSessions, 0);
        expect(preview.tasksToCreate, 2);
        await db.rebuildWorkoutSyncQueue(preview);

        final queue = await (db.select(
          db.syncQueue,
        )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).get();
        expect(queue, hasLength(2));
        expect(queue.first.entityExternalId, earlier.externalId);
        expect(queue.last.entityExternalId, later.externalId);
        expect(queue.map((row) => row.entityExternalId).toSet(), hasLength(2));
      },
    );

    test(
      'successful rebuild adds unqueued session and preserves non-workout tasks',
      () async {
        await _createProgramClient(db, 'unqueued-client');
        final session = await _saveSessionWithResult(
          db,
          clientId: 'unqueued-client',
          absoluteIndex: 0,
          templateIdx: 0,
          performedAt: DateTime(2026, 4, 10),
        );
        await db.deleteWorkoutSyncTask(session.externalId);
        await db.upsertSyncQueueTask(
          entityType: 'CLIENT',
          entityExternalId: 'client-task',
          operation: 'UPSERT',
          payload: '{"keep":true}',
        );

        final preview = await db.analyzeWorkoutSyncQueueRebuild();
        expect(preview.tasksToCreate, 1);
        await db.rebuildWorkoutSyncQueue(preview);

        final queue = await db.select(db.syncQueue).get();
        expect(queue, hasLength(2));
        expect(
          queue
              .where((row) => row.entityType == SyncEntityTypes.workout)
              .single
              .entityExternalId,
          session.externalId,
        );
        expect(
          queue.where((row) => row.entityType == 'CLIENT').single.payload,
          '{"keep":true}',
        );
      },
    );

    test(
      'insert failure rolls back deletion of the old workout queue',
      () async {
        await _createProgramClient(db, 'rollback-client');
        await _saveSessionWithResult(
          db,
          clientId: 'rollback-client',
          absoluteIndex: 0,
          templateIdx: 0,
          performedAt: DateTime(2026, 5, 10),
        );
        final oldTask = await db.select(db.syncQueue).getSingle();
        await (db.update(
          db.syncQueue,
        )..where((row) => row.id.equals(oldTask.id))).write(
          const SyncQueueCompanion(
            payload: Value('must-survive-rollback'),
            status: Value(SyncQueueStatuses.failed),
            attempts: Value(3),
          ),
        );
        final preview = await db.analyzeWorkoutSyncQueueRebuild();
        await db.customStatement('''
        CREATE TRIGGER fail_workout_queue_rebuild
        BEFORE INSERT ON sync_queue
        WHEN NEW.entity_type = 'WORKOUT'
        BEGIN
          SELECT RAISE(ABORT, 'forced rebuild failure');
        END
      ''');

        await expectLater(
          db.rebuildWorkoutSyncQueue(preview),
          throwsA(anything),
        );

        final preserved = await db.select(db.syncQueue).getSingle();
        expect(preserved.id, oldTask.id);
        expect(preserved.payload, 'must-survive-rollback');
        expect(preserved.status, SyncQueueStatuses.failed);
        expect(preserved.attempts, 3);
      },
    );

    testWidgets('Sync screen shows dry-run and cancel changes nothing', (
      tester,
    ) async {
      await _createProgramClient(db, 'ui-client');
      await _saveSessionWithResult(
        db,
        clientId: 'ui-client',
        absoluteIndex: 0,
        templateIdx: 0,
        performedAt: DateTime(2026, 6, 10),
      );
      final oldTask = await db.select(db.syncQueue).getSingle();
      await (db.update(db.syncQueue)..where((row) => row.id.equals(oldTask.id)))
          .write(const SyncQueueCompanion(payload: Value('ui-old-payload')));

      await tester.pumpWidget(
        AppDbScope(
          db: db,
          child: const MaterialApp(home: SyncScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Пересобрать очередь'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Пересобрать очередь?').evaluate().isNotEmpty) break;
      }

      expect(find.text('Пересобрать очередь?'), findsOneWidget);
      expect(find.text('Всего workout_sessions: 1'), findsOneWidget);
      expect(find.text('Будет добавлено в очередь: 1'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      final preserved = await db.select(db.syncQueue).getSingle();
      expect(preserved.id, oldTask.id);
      expect(preserved.payload, 'ui-old-payload');
    });
  });
}

Future<void> _createProgramClient(AppDb db, String clientId) async {
  await db.upsertClient(
    ClientsCompanion.insert(
      id: clientId,
      name: 'Client $clientId',
      gender: const Value('М'),
      plan: const Value('4'),
    ),
  );
  await db.ensureProgramStateForClient(clientId);
}

Future<WorkoutSession> _saveSessionWithResult(
  AppDb db, {
  required String clientId,
  required int absoluteIndex,
  required int templateIdx,
  required DateTime performedAt,
  double weight = 50,
}) async {
  final exercises = await db.getWorkoutPreviewForClient(
    clientId: clientId,
    gender: 'М',
    templateIdx: templateIdx,
  );
  return db.saveCompletedProgramSlot(
    clientId: clientId,
    planInstance: 1,
    absoluteIndex: absoluteIndex,
    performedAt: performedAt,
    templateIdx: templateIdx,
    results: {exercises.first.templateExerciseId: (weight, 10)},
  );
}
