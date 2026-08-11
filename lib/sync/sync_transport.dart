import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'workout_sync_payload.dart';
import 'sync_connection_config.dart';
import 'sync_http_client.dart';

const int maxSyncErrorBodyBytes = 4 * 1024;

enum SyncFailureKind { transient, permanent }

class SyncTransportResult {
  const SyncTransportResult.success({this.httpStatus, this.recordId})
    : isSuccess = true,
      message = 'Синхронизировано',
      failureKind = null,
      responseBody = null;

  const SyncTransportResult.failure({
    required this.message,
    this.httpStatus,
    this.failureKind,
    this.responseBody,
  }) : isSuccess = false,
       recordId = null;

  final bool isSuccess;
  final int? httpStatus;
  final String? recordId;
  final String message;
  final SyncFailureKind? failureKind;
  final String? responseBody;

  SyncFailureKind get resolvedFailureKind {
    final explicit = failureKind;
    if (explicit != null) return explicit;
    final status = httpStatus;
    if (status != null && status >= 400 && status < 500) {
      return SyncFailureKind.permanent;
    }
    return SyncFailureKind.transient;
  }
}

abstract interface class SyncTransport {
  bool get isConfigured;

  // A concrete HTTP transport owns base URL, endpoint, auth, timeout and
  // success/error body parsing, then reports the classified result here.
  Future<SyncTransportResult> sendWorkout(WorkoutSyncPayload payload);
}

class DisabledSyncTransport implements SyncTransport {
  const DisabledSyncTransport();

  @override
  bool get isConfigured => false;

  @override
  Future<SyncTransportResult> sendWorkout(WorkoutSyncPayload payload) async {
    return const SyncTransportResult.failure(
      message: 'Сервер пока не настроен',
    );
  }
}

class HttpSyncTransport implements SyncTransport {
  HttpSyncTransport({
    required SyncConnectionConfig config,
    SyncHttpClient? client,
  }) : _client = client ?? SyncHttpClient(config: config),
       _token = config.token.trim();

  factory HttpSyncTransport.fromEnvironment() {
    final config = SyncConnectionConfig.fromEnvironment();
    return HttpSyncTransport(config: config);
  }

  final SyncHttpClient _client;
  final String _token;

  @override
  bool get isConfigured => _client.isConfigured;

  @override
  Future<SyncTransportResult> sendWorkout(WorkoutSyncPayload payload) async {
    if (!isConfigured) {
      return const SyncTransportResult.failure(
        message: 'Токен сервера не настроен.',
      );
    }
    try {
      final response = await _client.postJson(payload.encode());
      if (response.statusCode == 201) {
        return SyncTransportResult.success(
          httpStatus: response.statusCode,
          recordId: SyncHttpClient.readRecordId(response.body),
        );
      }
      final responseBody = formatSyncErrorBody(
        response.body,
        secretToken: _token,
      );
      debugPrint(
        'WorkoutSync HTTP ${response.statusCode}: '
        '${responseBody ?? '<empty response body>'}',
      );
      return SyncTransportResult.failure(
        message: 'Сервер вернул ошибку: HTTP ${response.statusCode}',
        httpStatus: response.statusCode,
        responseBody: responseBody,
      );
    } catch (_) {
      return const SyncTransportResult.failure(
        message: 'Не удалось подключиться к серверу.',
        failureKind: SyncFailureKind.transient,
      );
    }
  }
}

String? formatSyncErrorBody(String body, {String secretToken = ''}) {
  final rawValue = body.trim();
  if (rawValue.isEmpty) return null;

  String value;
  try {
    value = const JsonEncoder.withIndent(
      '  ',
    ).convert(_sanitizeResponseValue(jsonDecode(rawValue), secretToken));
  } catch (_) {
    value = _sanitizeResponseText(rawValue, secretToken);
  }

  return _truncateUtf8(value, maxSyncErrorBodyBytes);
}

Object? _sanitizeResponseValue(Object? value, String secretToken) {
  if (value is Map) {
    final sanitized = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (key.toLowerCase() == 'authorization') continue;
      sanitized[key] = _sanitizeResponseValue(entry.value, secretToken);
    }
    return sanitized;
  }
  if (value is List) {
    return value
        .map((item) => _sanitizeResponseValue(item, secretToken))
        .toList();
  }
  if (value is String) return _sanitizeResponseText(value, secretToken);
  return value;
}

String _sanitizeResponseText(String value, String secretToken) {
  final withoutAuthorizationLines = value
      .split('\n')
      .where((line) => !line.toLowerCase().contains('authorization:'))
      .join('\n');
  var sanitized = withoutAuthorizationLines;
  if (secretToken.isNotEmpty) {
    sanitized = sanitized.replaceAll(secretToken, '[REDACTED]');
  }
  return sanitized.replaceAllMapped(
    RegExp(r'Bearer\s+[^\s"\x27,}\]]+', caseSensitive: false),
    (_) => 'Bearer [REDACTED]',
  );
}

String _truncateUtf8(String value, int maxBytes) {
  final bytes = utf8.encode(value);
  if (bytes.length <= maxBytes) return value;

  const suffix = '\n… [ответ обрезан]';
  final suffixBytes = utf8.encode(suffix);
  final available = maxBytes - suffixBytes.length;
  var end = available.clamp(0, bytes.length);
  while (end > 0) {
    try {
      return '${utf8.decode(bytes.sublist(0, end))}$suffix';
    } on FormatException {
      end--;
    }
  }
  return suffix;
}
