import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/sync/connection_test_service.dart';
import 'package:myfitness/sync/sync_connection_config.dart';
import 'package:myfitness/sync/sync_models.dart';

const _endpoint = 'https://training.viro35.ru/api/ingest';
const _testToken = 'test-only-token';

void main() {
  group('connection test', () {
    test(
      'sends exactly one authenticated JSON POST and accepts HTTP 201',
      () async {
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          return http.Response('{"message":"Stored.","id":17}', 201);
        });

        final result = await ConnectionTestService(
          config: _config(),
          client: client,
        ).run();

        expect(requests, hasLength(1));
        final request = requests.single;
        expect(request.method, 'POST');
        expect(request.url, Uri.parse(_endpoint));
        expect(request.headers['authorization'], 'Bearer $_testToken');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), ConnectionTestService.testPayload);
        expect(result.status, ConnectionTestStatus.success);
        expect(result.recordId, '17');
      },
    );

    test('treats a status other than HTTP 201 as an HTTP error', () async {
      final client = MockClient((_) async => http.Response('Rejected', 422));

      final result = await ConnectionTestService(
        config: _config(),
        client: client,
      ).run();

      expect(result.status, ConnectionTestStatus.httpError);
      expect(result.httpStatus, 422);
    });

    test('turns timeout into a safe connection error', () async {
      final neverCompletes = Completer<http.Response>();
      final client = MockClient((_) => neverCompletes.future);

      final result = await ConnectionTestService(
        config: _config(timeout: const Duration(milliseconds: 1)),
        client: client,
      ).run();

      expect(result.status, ConnectionTestStatus.connectionError);
    });

    test('turns network exception into a safe connection error', () async {
      final client = MockClient((_) async {
        throw const SocketException('offline');
      });

      final result = await ConnectionTestService(
        config: _config(),
        client: client,
      ).run();

      expect(result.status, ConnectionTestStatus.connectionError);
    });

    test('does not send when token is not configured', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('', 201);
      });

      final result = await ConnectionTestService(
        config: const SyncConnectionConfig(endpoint: _endpoint, token: ''),
        client: client,
      ).run();

      expect(calls, 0);
      expect(result.status, ConnectionTestStatus.notConfigured);
    });

    test('does not read or modify sync_queue or sync_log', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              entityType: SyncEntityTypes.workout,
              entityExternalId: 'workout-uuid',
              operation: SyncOperations.workoutUpsert,
              payload: '{"unchanged":true}',
              attempts: const Value(3),
              lastError: const Value('existing error'),
            ),
          );
      final queueBefore = await db.select(db.syncQueue).get();
      final logsBefore = await db.select(db.syncLog).get();
      final client = MockClient((_) async => http.Response('{"id":1}', 201));

      final result = await ConnectionTestService(
        config: _config(),
        client: client,
      ).run();

      expect(result.status, ConnectionTestStatus.success);
      expect(await db.select(db.syncQueue).get(), queueBefore);
      expect(await db.select(db.syncLog).get(), logsBefore);
      expect(await db.getPendingSyncTaskCount(), 1);
    });
  });
}

SyncConnectionConfig _config({Duration timeout = const Duration(seconds: 12)}) {
  return SyncConnectionConfig(
    endpoint: _endpoint,
    token: _testToken,
    timeout: timeout,
  );
}
