import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sync_connection_config.dart';
import 'sync_http_client.dart';

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
  }) : _httpClient = SyncHttpClient(config: config, client: client);

  factory ConnectionTestService.fromEnvironment() {
    return ConnectionTestService(
      config: SyncConnectionConfig.fromEnvironment(),
    );
  }

  static const Map<String, String> testPayload = {
    'type': 'connection_test',
    'message': 'Test from Trener app',
  };

  final SyncHttpClient _httpClient;

  Future<ConnectionTestResult> run() async {
    if (!_httpClient.isConfigured) {
      return const ConnectionTestResult.notConfigured();
    }

    try {
      final response = await _httpClient.postJson(jsonEncode(testPayload));

      if (response.statusCode != 201) {
        return ConnectionTestResult.httpError(response.statusCode);
      }

      return ConnectionTestResult.success(
        recordId: SyncHttpClient.readRecordId(response.body),
      );
    } catch (_) {
      return const ConnectionTestResult.connectionError();
    }
  }
}
