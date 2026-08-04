import 'workout_sync_payload.dart';

class SyncTransportResult {
  const SyncTransportResult.success({this.httpStatus})
    : isSuccess = true,
      message = 'Синхронизировано';

  const SyncTransportResult.failure({required this.message, this.httpStatus})
    : isSuccess = false;

  final bool isSuccess;
  final int? httpStatus;
  final String message;
}

abstract interface class SyncTransport {
  bool get isConfigured;

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
