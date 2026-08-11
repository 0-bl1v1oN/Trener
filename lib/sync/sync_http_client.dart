import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sync_connection_config.dart';

class SyncHttpClient {
  SyncHttpClient({required SyncConnectionConfig config, http.Client? client})
    : _config = config,
      _client = client;

  final SyncConnectionConfig _config;
  final http.Client? _client;

  bool get isConfigured => _config.isConfigured;

  Future<http.Response> postJson(String body) async {
    final endpoint = _config.endpointUri;
    final token = _config.token.trim();
    if (endpoint == null || token.isEmpty) {
      throw const SyncHttpNotConfiguredException();
    }

    final ownedClient = _client == null;
    final client = _client ?? http.Client();
    try {
      return await client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(_config.timeout);
    } finally {
      if (ownedClient) client.close();
    }
  }

  static String? readRecordId(String body) {
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

class SyncHttpNotConfiguredException implements Exception {
  const SyncHttpNotConfiguredException();
}
