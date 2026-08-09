import 'workout_sync_payload.dart';

enum SyncFailureKind { transient, permanent }

class SyncTransportResult {
  const SyncTransportResult.success({this.httpStatus})
    : isSuccess = true,
      message = 'Синхронизировано',
      failureKind = null;

  const SyncTransportResult.failure({
    required this.message,
    this.httpStatus,
    this.failureKind,
  }) : isSuccess = false;

  final bool isSuccess;
  final int? httpStatus;
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
