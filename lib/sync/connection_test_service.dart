import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sync_connection_config.dart';

enum ConnectionTestStatus { success, httpError, connectionError, notConfigured }

class ConnectionTestResult {
  const ConnectionTestResult.success({this.recordId})
    : status = ConnectionTestStatus.success,
      httpStatus = null;

  const ConnectionTestResult.httpError(this.httpStatus)
    : status = ConnectionTestStatus.httpError,
      recordId = null;

  const ConnectionTestResult.connectionError()
    : status = ConnectionTestStatus.connectionError,
      httpStatus = null,
      recordId = null;

  const ConnectionTestResult.notConfigured()
    : status = ConnectionTestStatus.notConfigured,
      httpStatus = null,
      recordId = null;

  final ConnectionTestStatus status;
  final int? httpStatus;
  final String? recordId;
}

class ConnectionTestService {
  ConnectionTestService({
    required SyncConnectionConfig config,
    http.Client? client,
  }) : _config = config,
       _client = client;

  factory ConnectionTestService.fromEnvironment() {
    return ConnectionTestService(
      config: SyncConnectionConfig.fromEnvironment(),
    );
  }

  static const Map<String, String> testPayload = {
    'type': 'connection_test',
    'message': 'Test from Trener app',
  };

  final SyncConnectionConfig _config;
  final http.Client? _client;

  Future<ConnectionTestResult> run() async {
    final endpoint = _config.endpointUri;
    final token = _config.token.trim();
    if (endpoint == null || token.isEmpty) {
      return const ConnectionTestResult.notConfigured();
    }

    final ownedClient = _client == null;
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(testPayload),
          )
          .timeout(_config.timeout);

      if (response.statusCode != 201) {
        return ConnectionTestResult.httpError(response.statusCode);
      }

      return ConnectionTestResult.success(
        recordId: _readRecordId(response.body),
      );
    } on TimeoutException {
      return const ConnectionTestResult.connectionError();
    } catch (_) {
      return const ConnectionTestResult.connectionError();
    } finally {
      if (ownedClient) client.close();
    }
  }

  String? _readRecordId(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final id = decoded['id'];
      return id is num || id is String ? id.toString() : null;
    } catch (_) {
      return null;
    }
  }
}
