import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/sync/sync_connection_config.dart';
import 'package:myfitness/sync/sync_http_client.dart';
import 'package:myfitness/sync/sync_models.dart';
import 'package:myfitness/sync/sync_service.dart';
import 'package:myfitness/sync/sync_transport.dart';
import 'package:myfitness/sync/workout_sync_payload.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

void main() {
  group('sync queue and payload', () {
    test('draft does not enqueue, completed workout does', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);

      await fixture.db.saveWorkoutDraftResults(
        clientId: fixture.client.id,
        day: fixture.day,
        templateIdx: fixture.template.idx,
        resultsByTemplateExerciseId: {fixture.exercise.id: (42.5, 10)},
      );
      expect(await fixture.db.getPendingSyncTaskCount(), 0);

      await _saveCompletedResult(fixture, weight: 42.5, reps: 10);
      final queue = await fixture.db.select(fixture.db.syncQueue).get();
      expect(queue, hasLength(1));
      expect(queue.single.status, SyncQueueStatuses.pending);
      expect(queue.single.operation, SyncOperations.workoutUpsert);
    });

    test('upsert deduplicates a workout and keeps latest payload', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);
      await _saveCompletedResult(fixture, weight: 50, reps: 8);
      await _saveCompletedResult(fixture, weight: 55, reps: 9);

      final queue = await fixture.db.select(fixture.db.syncQueue).get();
      expect(queue, hasLength(1));
      final payload = jsonDecode(queue.single.payload) as Map<String, dynamic>;
      final exercises = payload['exercises'] as List<dynamic>;
      expect(exercises, hasLength(1));
      expect((exercises.single as Map<String, dynamic>)['weight_kg'], 55.0);
      expect((exercises.single as Map<String, dynamic>)['reps'], 9);
    });

    test('payload uses external UUIDs and historical result values', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);
      final historicalName = fixture.exercise.name;
      await _saveCompletedResult(fixture, weight: 61.5, reps: 7);

      final queue = await fixture.db.select(fixture.db.syncQueue).getSingle();
      final firstPayload = jsonDecode(queue.payload) as Map<String, dynamic>;
      final firstExercise =
          (firstPayload['exercises'] as List<dynamic>).single
              as Map<String, dynamic>;
      await fixture.db.replaceExerciseIdentityForClient(
        clientId: fixture.client.id,
        templateExerciseId: fixture.exercise.id,
      );
      await fixture.db.renameWorkoutExerciseForClient(
        clientId: fixture.client.id,
        templateExerciseId: fixture.exercise.id,
        newName: 'Совсем другое упражнение',
      );
      await fixture.db.enqueueWorkoutSync(queue.entityExternalId);

      final refreshedQueue = await fixture.db
          .select(fixture.db.syncQueue)
          .getSingle();
      final payload =
          jsonDecode(refreshedQueue.payload) as Map<String, dynamic>;
      final client = payload['client'] as Map<String, dynamic>;
      final workout = payload['workout'] as Map<String, dynamic>;
      final exercises = payload['exercises'] as List<dynamic>;
      final exercise = exercises.single as Map<String, dynamic>;

      expect(client['client_id'], fixture.client.externalId);
      expect(client['client_id'], matches(_uuidV4));
      expect(workout['workout_id'], queue.entityExternalId);
      expect(workout['workout_id'], matches(_uuidV4));
      expect(workout['date'], '2026-08-05');
      expect(workout['date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(workout['name'], fixture.template.title);
      expect(exercise['exercise_id'], matches(_uuidV4));
      expect(exercise['exercise_id'], firstExercise['exercise_id']);
      expect(exercise['name'], historicalName);
      expect(exercise['weight_kg'], 61.5);
      expect(exercise['reps'], 7);
      expect(exercises, hasLength(1));
      expect(client.containsKey('uuid'), isFalse);
      expect(workout.containsKey('uuid'), isFalse);
      expect(exercise.containsKey('uuid'), isFalse);
      expect(exercise.containsKey('template_exercise_id'), isFalse);
      expect(workout.containsKey('session_id'), isFalse);
      expect(workout.containsKey('performed_at'), isFalse);
      expect(workout.containsKey('day_index'), isFalse);
      expect(workout.containsKey('plan_instance'), isFalse);
      expect(workout.containsKey('absolute_index'), isFalse);
      expect(exercise.containsKey('sets'), isFalse);
      expect(firstPayload.containsKey('trainer_uuid'), isFalse);
      expect(workout.containsKey('duration'), isFalse);
      expect(workout.containsKey('volume'), isFalse);
    });

    test('legacy queued payload is normalized to compact contract', () {
      final payload = WorkoutSyncPayload.fromJson({
        'client': {'client_id': 'client-uuid', 'name': 'Клиент'},
        'workout': {
          'workout_id': 'workout-uuid',
          'performed_at': '2026-08-05T09:00:00.000Z',
          'day_index': 2,
          'day_label': 'День 3',
          'day_title': 'Ноги',
          'plan_instance': 1,
        },
        'exercises': [
          {
            'exercise_id': 'exercise-uuid',
            'name': 'Присед',
            'weight_kg': null,
            'reps': 10,
          },
        ],
      }).toJson();

      expect(payload['client'], {'client_id': 'client-uuid', 'name': 'Клиент'});
      expect(payload['workout'], {
        'workout_id': 'workout-uuid',
        'date': '2026-08-05',
        'name': 'Ноги',
      });
      expect(
        ((payload['exercises'] as List).single as Map)['exercise_id'],
        'exercise-uuid',
      );
    });

    test(
      'building the new payload does not rewrite existing queue rows',
      () async {
        final fixture = await _createFixture();
        addTearDown(fixture.db.close);
        await _saveCompletedResult(fixture, weight: 45, reps: 11);
        final queued = await fixture.db
            .select(fixture.db.syncQueue)
            .getSingle();
        const oldPayload = '{"old_contract":true}';
        await (fixture.db.update(fixture.db.syncQueue)
              ..where((row) => row.id.equals(queued.id)))
            .write(const SyncQueueCompanion(payload: Value(oldPayload)));

        final rebuilt = await fixture.db.buildWorkoutSyncPayload(
          queued.entityExternalId,
        );
        final queueAfter = await fixture.db
            .select(fixture.db.syncQueue)
            .getSingle();

        expect(rebuilt?.workoutExternalId, queued.entityExternalId);
        expect(queueAfter.id, queued.id);
        expect(queueAfter.payload, oldPayload);
      },
    );

    test('queue survives closing and reopening the database', () async {
      final temp = await Directory.systemTemp.createTemp('trener-sync-queue-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}${Platform.pathSeparator}sync.sqlite');

      final first = AppDb.forTesting(NativeDatabase(file));
      final fixture = await _createFixture(db: first);
      await _saveCompletedResult(fixture, weight: 35, reps: 12);
      final externalId =
          (await first.select(first.syncQueue).getSingle()).entityExternalId;
      await first.close();

      final reopened = AppDb.forTesting(NativeDatabase(file));
      addTearDown(reopened.close);
      final queue = await reopened.select(reopened.syncQueue).get();
      expect(queue, hasLength(1));
      expect(queue.single.entityExternalId, externalId);
      expect(queue.single.status, SyncQueueStatuses.pending);
    });

    test('backup includes pending queue but excludes diagnostic log', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);
      await _saveCompletedResult(fixture, weight: 40, reps: 11);
      await fixture.db.addSyncLog(
        entityType: SyncEntityTypes.workout,
        entityExternalId: 'diagnostic-only',
        result: SyncLogResults.error,
        attemptNumber: 1,
        message: 'Не переносить',
      );

      final backup = await fixture.db.buildBackupPayload();
      final tables = backup['tables'] as Map<String, dynamic>;
      expect(tables['sync_queue'], isNotEmpty);
      expect(tables.containsKey('sync_log'), isFalse);
    });

    test('queue failure never rolls back the local workout', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);
      await fixture.db.customStatement('DROP TABLE sync_queue');

      await _saveCompletedResult(fixture, weight: 90, reps: 4);

      expect(
        await fixture.db.select(fixture.db.workoutSessions).get(),
        hasLength(1),
      );
      final result = await fixture.db
          .select(fixture.db.workoutExerciseResults)
          .getSingle();
      expect(result.lastWeightKg, 90);
      expect(result.lastReps, 4);
    });
  });

  group('sync log', () {
    test('cleanup removes entries older than seven days only', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime(2026, 8, 5, 12);
      await db.addSyncLog(
        entityType: SyncEntityTypes.workout,
        entityExternalId: 'old',
        result: SyncLogResults.error,
        attemptNumber: 1,
        message: 'Старая ошибка',
        timestamp: now.subtract(const Duration(days: 8)),
      );
      await db.addSyncLog(
        entityType: SyncEntityTypes.workout,
        entityExternalId: 'fresh',
        result: SyncLogResults.success,
        attemptNumber: 2,
        message: 'Свежая запись',
        timestamp: now.subtract(const Duration(days: 2)),
      );

      expect(await db.cleanupSyncLogs(now: now), 1);
      final logs = await db.getRecentSyncLogs();
      expect(logs, hasLength(1));
      expect(logs.single.entityExternalId, 'fresh');
      expect(logs.single.attemptNumber, 2);
    });
  });

  group('SyncService', () {
    test(
      'real HTTP transport deletes 201 task then stops on HTTP error',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final first = await _createFixture(
          db: db,
          day: DateTime(2026, 8, 5, 12),
        );
        await _saveCompletedResult(first, weight: 50, reps: 8);
        final second = await _createFixture(
          db: db,
          day: DateTime(2026, 8, 6, 12),
        );
        await _saveCompletedResult(second, weight: 55, reps: 9);
        const config = SyncConnectionConfig(
          endpoint: 'https://training.viro35.ru/api/ingest',
          token: 'bulk-sync-test-token',
        );
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          if (requests.length == 1) {
            return http.Response('{"message":"Stored.","id":1}', 201);
          }
          return http.Response('{"detail":"Invalid workout"}', 422);
        });
        final progress = <SyncProgress>[];

        final result = await SyncService(
          db: db,
          transport: HttpSyncTransport(
            config: config,
            client: SyncHttpClient(config: config, client: client),
          ),
        ).syncPending(onProgress: progress.add);

        expect(requests, hasLength(2));
        expect(requests.every((request) => request.method == 'POST'), isTrue);
        expect(result.succeeded, 1);
        expect(result.failed, 1);
        expect(result.stopReason, SyncRunStopReason.permanentFailure);
        expect(result.httpStatus, 422);
        expect(result.responseBody, contains('Invalid workout'));
        expect(progress.map((value) => value.sent), [0, 1]);
        expect(progress.every((value) => value.total == 2), isTrue);
        final queue = await db.select(db.syncQueue).get();
        expect(queue, hasLength(1));
        expect(queue.single.status, SyncQueueStatuses.failed);
        expect(queue.single.attempts, 1);
      },
    );

    test('starts the next workout only after the previous response', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final newer = await _createFixture(db: db, day: DateTime(2026, 8, 6, 12));
      await _saveCompletedResult(newer, weight: 60, reps: 6);
      final older = await _createFixture(db: db, day: DateTime(2026, 8, 5, 12));
      await _saveCompletedResult(older, weight: 50, reps: 5);
      final transport = _ControlledTransport(2);
      final service = SyncService(db: db, transport: transport);
      final progress = <SyncProgress>[];

      final run = service.syncPending(onProgress: progress.add);
      await transport.started[0].future;
      await Future<void>.delayed(Duration.zero);
      expect(transport.payloads, hasLength(1));
      expect(
        (transport.payloads.first.toJson()['workout'] as Map)['date'],
        '2026-08-05',
      );

      transport.responses[0].complete(
        const SyncTransportResult.success(httpStatus: 200),
      );
      await transport.started[1].future;
      expect(transport.payloads, hasLength(2));
      transport.responses[1].complete(
        const SyncTransportResult.success(httpStatus: 200),
      );

      final result = await run;
      expect(result.succeeded, 2);
      expect(progress.map((value) => value.sent), [0, 1, 2]);
      expect(progress.every((value) => value.total == 2), isTrue);
      expect(await db.getPendingSyncTaskCount(), 0);
    });

    test('transient server error stops the current queue pass', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final first = await _createFixture(db: db);
      await _saveCompletedResult(first, weight: 40, reps: 10);
      final second = await _createFixture(db: db);
      await _saveCompletedResult(second, weight: 45, reps: 9);
      final transport = _FakeTransport(
        const SyncTransportResult.failure(
          message: 'Сервер недоступен',
          httpStatus: 503,
        ),
      );

      final result = await SyncService(
        db: db,
        transport: transport,
      ).syncPending();

      expect(result.stopReason, SyncRunStopReason.transientFailure);
      expect(result.failed, 1);
      expect(transport.payloads, hasLength(1));
      final queue = await db.select(db.syncQueue).get();
      expect(queue.where((task) => task.attempts == 1), hasLength(1));
      expect(queue.where((task) => task.attempts == 0), hasLength(1));
      expect(
        queue.every((task) => task.status == SyncQueueStatuses.pending),
        isTrue,
      );
    });

    test(
      '4xx is permanent for the pass and does not start the next task',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final first = await _createFixture(db: db);
        await _saveCompletedResult(first, weight: 40, reps: 10);
        final second = await _createFixture(db: db);
        await _saveCompletedResult(second, weight: 45, reps: 9);
        final transport = _FakeTransport(
          const SyncTransportResult.failure(
            message: 'Некорректный контракт',
            httpStatus: 422,
          ),
        );

        final result = await SyncService(
          db: db,
          transport: transport,
        ).syncPending();

        expect(result.stopReason, SyncRunStopReason.permanentFailure);
        expect(transport.payloads, hasLength(1));
        final queue = await db.select(db.syncQueue).get();
        expect(
          queue.where((task) => task.status == SyncQueueStatuses.failed),
          hasLength(1),
        );
        expect(queue.where((task) => task.attempts == 0), hasLength(1));
      },
    );

    test(
      'a workout changed during send keeps and sends latest payload',
      () async {
        final fixture = await _createFixture();
        addTearDown(fixture.db.close);
        await _saveCompletedResult(fixture, weight: 50, reps: 8);
        final transport = _ControlledTransport(2);
        final service = SyncService(db: fixture.db, transport: transport);

        final run = service.syncPending();
        await transport.started[0].future;
        await _saveCompletedResult(fixture, weight: 55, reps: 9);
        transport.responses[0].complete(
          const SyncTransportResult.success(httpStatus: 200),
        );

        await transport.started[1].future;
        final retainedTask = await fixture.db
            .select(fixture.db.syncQueue)
            .getSingle();
        final retainedPayload =
            jsonDecode(retainedTask.payload) as Map<String, dynamic>;
        final retainedExercise =
            (retainedPayload['exercises'] as List).single as Map;
        expect(retainedExercise['weight_kg'], 55.0);
        final latestExercise =
            (transport.payloads[1].toJson()['exercises'] as List).single as Map;
        expect(latestExercise['weight_kg'], 55.0);
        expect(latestExercise['reps'], 9);
        transport.responses[1].complete(
          const SyncTransportResult.success(httpStatus: 200),
        );

        final result = await run;
        expect(result.succeeded, 2);
        expect(await fixture.db.getPendingSyncTaskCount(), 0);
      },
    );

    test('a 2000 task backlog begins only one task before failure', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final payload = jsonEncode({
        'client': {'uuid': 'client-uuid', 'name': 'Клиент'},
        'workout': {
          'uuid': 'workout-uuid',
          'performed_at': '2026-08-05T09:00:00.000Z',
          'day_index': 0,
          'plan_instance': 1,
        },
        'exercises': <Object?>[],
      });
      await db.batch((batch) {
        for (var index = 0; index < 2000; index++) {
          batch.insert(
            db.syncQueue,
            SyncQueueCompanion.insert(
              entityType: SyncEntityTypes.workout,
              entityExternalId: 'workout-$index',
              operation: SyncOperations.workoutUpsert,
              payload: payload,
            ),
          );
        }
      });
      final transport = _FakeTransport(
        const SyncTransportResult.failure(message: 'Сеть недоступна'),
      );

      final result = await SyncService(
        db: db,
        transport: transport,
      ).syncPending();

      expect(result.failed, 1);
      expect(transport.payloads, hasLength(1));
      final attempted = await (db.select(
        db.syncQueue,
      )..where((task) => task.attempts.isBiggerThanValue(0))).get();
      expect(attempted, hasLength(1));
      expect(await db.getPendingSyncTaskCount(), 2000);
    });

    test('confirmed success removes queue task and writes log', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);
      await _saveCompletedResult(fixture, weight: 80, reps: 5);
      final transport = _FakeTransport(
        const SyncTransportResult.success(httpStatus: 200),
      );
      final service = SyncService(db: fixture.db, transport: transport);

      final result = await service.syncPending();

      expect(result.status, SyncRunStatus.completed);
      expect(result.succeeded, 1);
      expect(await fixture.db.getPendingSyncTaskCount(), 0);
      expect(transport.payloads, hasLength(1));
      final logs = await fixture.db.getRecentSyncLogs();
      expect(logs.single.result, SyncLogResults.success);
      expect(logs.single.attemptNumber, 1);
      expect(logs.single.httpStatus, 200);
    });

    test(
      'error keeps task pending, increments attempts and writes log',
      () async {
        final fixture = await _createFixture();
        addTearDown(fixture.db.close);
        await _saveCompletedResult(fixture, weight: 30, reps: 15);
        final service = SyncService(
          db: fixture.db,
          transport: _FakeTransport(
            const SyncTransportResult.failure(
              message: 'Сервер недоступен',
              httpStatus: 503,
            ),
          ),
        );

        final first = await service.syncPending();
        final second = await service.syncPending();

        expect(first.failed, 1);
        expect(second.failed, 1);
        final task = await fixture.db.select(fixture.db.syncQueue).getSingle();
        expect(task.status, SyncQueueStatuses.pending);
        expect(task.attempts, 2);
        expect(task.lastError, 'Сервер недоступен');
        final logs = await fixture.db.getRecentSyncLogs();
        expect(logs, hasLength(2));
        expect(logs.first.result, SyncLogResults.error);
        expect(logs.first.attemptNumber, 2);
        expect(logs.first.httpStatus, 503);
      },
    );

    test('disabled transport leaves pending tasks untouched', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);
      await _saveCompletedResult(fixture, weight: 20, reps: 20);
      final service = SyncService(
        db: fixture.db,
        transport: const DisabledSyncTransport(),
      );

      final result = await service.syncPending();

      expect(result.status, SyncRunStatus.notConfigured);
      final task = await fixture.db.select(fixture.db.syncQueue).getSingle();
      expect(task.attempts, 0);
      expect(await fixture.db.getRecentSyncLogs(), isEmpty);
    });
  });
}

class _SyncFixture {
  const _SyncFixture({
    required this.db,
    required this.client,
    required this.template,
    required this.exercise,
    required this.day,
  });

  final AppDb db;
  final Client client;
  final WorkoutTemplate template;
  final WorkoutTemplateExercise exercise;
  final DateTime day;
}

Future<_SyncFixture> _createFixture({AppDb? db, DateTime? day}) async {
  final database = db ?? AppDb.forTesting(NativeDatabase.memory());
  final clientId = 'sync-client-${DateTime.now().microsecondsSinceEpoch}';
  await database.upsertClient(
    ClientsCompanion.insert(
      id: clientId,
      name: 'Клиент синхронизации',
      gender: const Value('М'),
      plan: const Value('4'),
    ),
  );
  await database.ensureProgramStateForClient(clientId);
  final client = (await database.getClientById(clientId))!;
  final template = await (database.select(
    database.workoutTemplates,
  )..where((row) => row.gender.equals('М') & row.idx.equals(0))).getSingle();
  final exercise =
      await (database.select(database.workoutTemplateExercises)
            ..where((row) => row.templateId.equals(template.id))
            ..orderBy([(row) => OrderingTerm.asc(row.orderIndex)])
            ..limit(1))
          .getSingle();
  return _SyncFixture(
    db: database,
    client: client,
    template: template,
    exercise: exercise,
    day: day ?? DateTime(2026, 8, 5, 12),
  );
}

Future<void> _saveCompletedResult(
  _SyncFixture fixture, {
  required double weight,
  required int reps,
}) {
  return fixture.db.saveWorkoutResultsAndMarkDone(
    clientId: fixture.client.id,
    day: fixture.day,
    templateIdx: fixture.template.idx,
    resultsByTemplateExerciseId: {fixture.exercise.id: (weight, reps)},
  );
}

class _FakeTransport implements SyncTransport {
  _FakeTransport(this.result);

  final SyncTransportResult result;
  final List<WorkoutSyncPayload> payloads = [];

  @override
  bool get isConfigured => true;

  @override
  Future<SyncTransportResult> sendWorkout(WorkoutSyncPayload payload) async {
    payloads.add(payload);
    return result;
  }
}

class _ControlledTransport implements SyncTransport {
  _ControlledTransport(int requestCount)
    : started = List.generate(requestCount, (_) => Completer<void>()),
      responses = List.generate(
        requestCount,
        (_) => Completer<SyncTransportResult>(),
      );

  final List<Completer<void>> started;
  final List<Completer<SyncTransportResult>> responses;
  final List<WorkoutSyncPayload> payloads = [];

  @override
  bool get isConfigured => true;

  @override
  Future<SyncTransportResult> sendWorkout(WorkoutSyncPayload payload) {
    final index = payloads.length;
    payloads.add(payload);
    started[index].complete();
    return responses[index].future;
  }
}
