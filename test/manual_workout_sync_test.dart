import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/more/manual_workout_sync_sheet.dart';
import 'package:myfitness/sync/sync_connection_config.dart';
import 'package:myfitness/sync/sync_http_client.dart';
import 'package:myfitness/sync/sync_models.dart';
import 'package:myfitness/sync/sync_service.dart';
import 'package:myfitness/sync/sync_transport.dart';

const _endpoint = 'https://training.viro35.ru/api/ingest';
const _token = 'manual-sync-test-token';

void main() {
  group('manual workout sync', () {
    test(
      'lists only clients and workouts represented by pending tasks',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final first = await _createWorkout(
          db,
          clientId: 'first-client',
          name: 'Анна',
          day: DateTime(2026, 8, 10, 12),
        );
        final second = await _createWorkout(
          db,
          clientId: 'second-client',
          name: 'Борис',
          day: DateTime(2026, 8, 11, 12),
        );
        await db.upsertClient(
          ClientsCompanion.insert(
            id: 'without-workout',
            name: 'Без тренировки',
          ),
        );

        final clients = await db.getPendingWorkoutSyncClients();
        final firstTasks = await db.getPendingWorkoutSyncTasksForClient(
          first.client.id,
        );

        expect(clients.map((client) => client.clientId), {
          first.client.id,
          second.client.id,
        });
        expect(
          clients.every((client) => client.pendingWorkoutCount == 1),
          isTrue,
        );
        expect(firstTasks, hasLength(1));
        expect(firstTasks.single.workoutExternalId, first.workoutExternalId);
        expect(
          firstTasks.single.workoutExternalId,
          isNot(second.workoutExternalId),
        );
        expect(firstTasks.single.exerciseCount, 1);
      },
    );

    test(
      'HTTP 201 sends selected payload once and deletes only its task',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final selected = await _createWorkout(
          db,
          clientId: 'selected-client',
          name: 'Иван Иванов',
          day: DateTime(2026, 8, 11, 12),
          weight: 70,
          reps: 10,
        );
        final untouched = await _createWorkout(
          db,
          clientId: 'untouched-client',
          name: 'Другой клиент',
          day: DateTime(2026, 8, 12, 12),
        );
        final queuedBefore = await (db.select(
          db.syncQueue,
        )..where((row) => row.id.equals(selected.taskId))).getSingle();
        final legacyPayload =
            jsonDecode(queuedBefore.payload) as Map<String, dynamic>;
        final legacyClient = legacyPayload['client'] as Map<String, dynamic>;
        legacyClient.remove('gender');
        legacyClient.remove('subscription_size');
        legacyClient.remove('subscription_start');
        legacyClient.remove('subscription_end');
        legacyClient.remove('remaining_sessions');
        await (db.update(
          db.syncQueue,
        )..where((row) => row.id.equals(selected.taskId))).write(
          SyncQueueCompanion(payload: Value(jsonEncode(legacyPayload))),
        );
        final requests = <http.Request>[];
        final service = _service(
          db,
          MockClient((request) async {
            requests.add(request);
            return http.Response('{"message":"Stored.","id":31}', 201);
          }),
        );

        final result = await service.syncTaskById(selected.taskId);

        expect(result.status, SingleSyncStatus.success);
        expect(result.recordId, '31');
        expect(result.queueTaskDeleted, isTrue);
        expect(requests, hasLength(1));
        expect(requests.single.method, 'POST');
        expect(requests.single.headers['authorization'], 'Bearer $_token');
        expect(requests.single.headers['content-type'], 'application/json');
        final json = jsonDecode(requests.single.body) as Map<String, dynamic>;
        final client = json['client'] as Map<String, dynamic>;
        final workout = json['workout'] as Map<String, dynamic>;
        final exercise =
            (json['exercises'] as List).single as Map<String, dynamic>;
        expect(client['client_id'], selected.client.externalId);
        expect(client['name'], selected.client.name);
        expect(client['gender'], 'male');
        expect(client['subscription_size'], 8);
        expect(client['subscription_start'], '2026-07-20');
        expect(client['subscription_end'], '2026-08-17');
        expect(client['remaining_sessions'], 7);
        expect(workout['workout_id'], selected.workoutExternalId);
        expect(workout['date'], '2026-08-11');
        expect(workout['name'], selected.template.title);
        expect(workout.containsKey('performed_at'), isFalse);
        expect(workout.containsKey('day_index'), isFalse);
        expect(workout.containsKey('plan_instance'), isFalse);
        expect(workout.containsKey('absolute_index'), isFalse);
        expect(exercise['exercise_id'], selected.exerciseExternalId);
        expect(exercise['name'], selected.exercise.name);
        expect(exercise['weight_kg'], 70.0);
        expect(exercise['reps'], 10);
        expect(jsonEncode(json), isNot(contains('"sets"')));
        expect(client.containsKey('uuid'), isFalse);
        expect(workout.containsKey('uuid'), isFalse);
        expect(exercise.containsKey('uuid'), isFalse);

        final remaining = await db.select(db.syncQueue).get();
        expect(remaining, hasLength(1));
        expect(remaining.single.id, untouched.taskId);
        expect(remaining.single.attempts, 0);
        final logs = await db.getRecentSyncLogs();
        expect(logs, hasLength(1));
        expect(logs.single.message, isNot(contains(_token)));
      },
    );

    test('HTTP 422 keeps JSON body and both tasks pending', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final selected = await _createWorkout(
        db,
        clientId: 'http-error-client',
        name: 'Ошибка HTTP',
        day: DateTime(2026, 8, 10),
      );
      final untouched = await _createWorkout(
        db,
        clientId: 'next-client',
        name: 'Следующий',
        day: DateTime(2026, 8, 11),
      );
      var calls = 0;
      final service = _service(
        db,
        MockClient((_) async {
          calls++;
          return http.Response(
            '{"error":"validation_failed","field":"workout.date"}',
            422,
          );
        }),
      );

      final result = await service.syncTaskById(selected.taskId);

      expect(result.status, SingleSyncStatus.failure);
      expect(result.httpStatus, 422);
      expect(
        result.responseBody,
        '{\n  "error": "validation_failed",\n  "field": "workout.date"\n}',
      );
      expect(calls, 1);
      final tasks = await db.select(db.syncQueue).get();
      expect(tasks, hasLength(2));
      expect(
        tasks.singleWhere((task) => task.id == selected.taskId).status,
        SyncQueueStatuses.pending,
      );
      expect(
        tasks.singleWhere((task) => task.id == untouched.taskId).attempts,
        0,
      );
      expect(
        (await db.getRecentSyncLogs()).single.message,
        isNot(contains(_token)),
      );
    });

    test('empty HTTP error body is handled without failure', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final selected = await _createWorkout(
        db,
        clientId: 'empty-body-client',
        name: 'Пустой ответ',
        day: DateTime(2026, 8, 11),
      );
      final service = _service(
        db,
        MockClient((_) async => http.Response('', 422)),
      );

      final result = await service.syncTaskById(selected.taskId);

      expect(result.status, SingleSyncStatus.failure);
      expect(result.httpStatus, 422);
      expect(result.responseBody, isNull);
      expect(
        (await db.select(db.syncQueue).getSingle()).status,
        SyncQueueStatuses.pending,
      );
    });

    test('long HTTP error body is safely truncated to 4 KB', () async {
      final longBody = List.filled(5000, 'x').join();
      final formattedBody = formatSyncErrorBody(longBody);
      expect(formattedBody, isNotNull);
      expect(utf8.encode(formattedBody!).length, lessThanOrEqualTo(4096));
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final selected = await _createWorkout(
        db,
        clientId: 'long-body-client',
        name: 'Длинный ответ',
        day: DateTime(2026, 8, 11),
      );
      final service = _service(
        db,
        MockClient((_) async => http.Response(longBody, 422)),
      );

      final result = await service.syncTaskById(selected.taskId);

      expect(utf8.encode(result.responseBody!).length, lessThanOrEqualTo(4096));
      expect(result.responseBody, endsWith('… [ответ обрезан]'));
    });

    test(
      'debug output contains status and body but no auth or token',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final selected = await _createWorkout(
          db,
          clientId: 'safe-log-client',
          name: 'Безопасный лог',
          day: DateTime(2026, 8, 11),
        );
        final service = _service(
          db,
          MockClient(
            (_) async => http.Response(
              '{"error":"bad payload","Authorization":"Bearer $_token"}',
              422,
            ),
          ),
        );
        final messages = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (message, {wrapWidth}) {
          if (message != null) messages.add(message);
        };
        addTearDown(() => debugPrint = originalDebugPrint);

        final result = await service.syncTaskById(selected.taskId);

        debugPrint = originalDebugPrint;
        final output = messages.join('\n');
        expect(output, contains('WorkoutSync HTTP 422'));
        expect(output, contains('bad payload'));
        expect(output, isNot(contains(_token)));
        expect(output, isNot(contains('Authorization')));
        expect(result.responseBody, isNot(contains(_token)));
        expect(result.responseBody, isNot(contains('Authorization')));
      },
    );

    testWidgets('HTTP 422 body is shown below the status in manual UI', (
      tester,
    ) async {
      await initializeDateFormatting('ru_RU');
      String? copiedText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final selected = await _createWorkout(
        db,
        clientId: 'ui-error-client',
        name: 'Ошибка интерфейса',
        day: DateTime(2026, 8, 11),
      );
      final service = _service(
        db,
        MockClient(
          (_) async => http.Response(
            '{"detail":"Invalid workout",'
            '"Authorization":"Bearer $_token"}',
            422,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualWorkoutSyncSheet(db: db, service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(selected.client.name));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отправить эту тренировку'));
      await tester.pumpAndSettle();

      expect(find.text('Сервер вернул ошибку: HTTP 422'), findsOneWidget);
      expect(find.text('Ответ сервера:'), findsOneWidget);
      expect(find.textContaining('Invalid workout'), findsOneWidget);
      expect(find.text('Скопировать ошибку'), findsOneWidget);

      await tester.tap(find.text('Скопировать ошибку'));
      await tester.pump();
      final copied = copiedText;
      expect(copied, contains('Ошибка отправки тренировки'));
      expect(copied, contains('HTTP: 422'));
      expect(copied, contains('Ответ сервера:'));
      expect(copied, contains('Invalid workout'));
      expect(copied, isNot(contains(_token)));
      expect(copied, isNot(contains('Authorization')));
      expect(find.text('Ошибка скопирована'), findsOneWidget);
    });

    test(
      'network error keeps the selected task and sends no next task',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final selected = await _createWorkout(
          db,
          clientId: 'offline-client',
          name: 'Без сети',
          day: DateTime(2026, 8, 10),
        );
        final untouched = await _createWorkout(
          db,
          clientId: 'offline-next-client',
          name: 'Не отправлять',
          day: DateTime(2026, 8, 11),
        );
        var calls = 0;
        final service = _service(
          db,
          MockClient((_) async {
            calls++;
            throw const SocketException('offline');
          }),
        );

        final result = await service.syncTaskById(selected.taskId);

        expect(result.status, SingleSyncStatus.failure);
        expect(calls, 1);
        final tasks = await db.select(db.syncQueue).get();
        expect(tasks, hasLength(2));
        expect(
          tasks.singleWhere((task) => task.id == selected.taskId).status,
          SyncQueueStatuses.pending,
        );
        expect(
          tasks.singleWhere((task) => task.id == untouched.taskId).attempts,
          0,
        );
      },
    );
  });
}

class _WorkoutFixture {
  const _WorkoutFixture({
    required this.client,
    required this.template,
    required this.exercise,
    required this.taskId,
    required this.workoutExternalId,
    required this.exerciseExternalId,
  });

  final Client client;
  final WorkoutTemplate template;
  final WorkoutTemplateExercise exercise;
  final int taskId;
  final String workoutExternalId;
  final String exerciseExternalId;
}

Future<_WorkoutFixture> _createWorkout(
  AppDb db, {
  required String clientId,
  required String name,
  required DateTime day,
  double weight = 40,
  int reps = 12,
}) async {
  await db.upsertClient(
    ClientsCompanion.insert(
      id: clientId,
      name: name,
      gender: const Value('М'),
      plan: const Value('8'),
      planStart: Value(DateTime(2026, 7, 20)),
      planEnd: Value(DateTime(2026, 8, 17)),
    ),
  );
  await db.ensureProgramStateForClient(clientId);
  final client = (await db.getClientById(clientId))!;
  final template = await (db.select(
    db.workoutTemplates,
  )..where((row) => row.gender.equals('М') & row.idx.equals(0))).getSingle();
  final exercise =
      await (db.select(db.workoutTemplateExercises)
            ..where((row) => row.templateId.equals(template.id))
            ..orderBy([(row) => OrderingTerm.asc(row.orderIndex)])
            ..limit(1))
          .getSingle();
  await db.saveWorkoutResultsAndMarkDone(
    clientId: clientId,
    day: day,
    templateIdx: template.idx,
    resultsByTemplateExerciseId: {exercise.id: (weight, reps)},
  );
  final task =
      await (db.select(db.syncQueue)
            ..where((row) => row.entityExternalId.isNotValue(''))
            ..orderBy([(row) => OrderingTerm.desc(row.id)])
            ..limit(1))
          .getSingle();
  final session = await (db.select(
    db.workoutSessions,
  )..where((row) => row.externalId.equals(task.entityExternalId))).getSingle();
  final result = await (db.select(
    db.workoutExerciseResults,
  )..where((row) => row.sessionId.equals(session.id))).getSingle();
  final identity = await (db.select(
    db.exerciseIdentities,
  )..where((row) => row.id.equals(result.exerciseIdentityId!))).getSingle();
  return _WorkoutFixture(
    client: client,
    template: template,
    exercise: exercise,
    taskId: task.id,
    workoutExternalId: task.entityExternalId,
    exerciseExternalId: identity.externalId,
  );
}

SyncService _service(AppDb db, http.Client client) {
  const config = SyncConnectionConfig(endpoint: _endpoint, token: _token);
  return SyncService(
    db: db,
    transport: HttpSyncTransport(
      config: config,
      client: SyncHttpClient(config: config, client: client),
    ),
  );
}
