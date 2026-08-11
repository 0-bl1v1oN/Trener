import 'workout_sync_payload.dart';
import 'sync_connection_config.dart';
import 'sync_http_client.dart';

enum SyncFailureKind { transient, permanent }

class SyncTransportResult {
  const SyncTransportResult.success({this.httpStatus, this.recordId})
    : isSuccess = true,
      message = 'Синхронизировано',
      failureKind = null;

  const SyncTransportResult.failure({
    required this.message,
    this.httpStatus,
    this.failureKind,
  }) : isSuccess = false,
       recordId = null;

  final bool isSuccess;
  final int? httpStatus;
  final String? recordId;
  final String message;
  final SyncFailureKind? failureKind;

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
  }) : _client = client ?? SyncHttpClient(config: config);

  factory HttpSyncTransport.fromEnvironment() {
    final config = SyncConnectionConfig.fromEnvironment();
    return HttpSyncTransport(config: config);
  }

  final SyncHttpClient _client;

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
      return SyncTransportResult.failure(
        message: 'Сервер вернул ошибку: HTTP ${response.statusCode}',
        httpStatus: response.statusCode,
      );
    } catch (_) {
      return const SyncTransportResult.failure(
        message: 'Не удалось подключиться к серверу.',
        failureKind: SyncFailureKind.transient,
      );
    }
  }
}
