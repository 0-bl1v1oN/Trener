import '../db/app_db.dart';
import 'sync_models.dart';
import 'sync_transport.dart';
import 'workout_sync_payload.dart';

class SyncService {
  SyncService({required AppDb db, required SyncTransport transport})
    : _db = db,
      _transport = transport;

  final AppDb _db;
  final SyncTransport _transport;

  bool get isConfigured => _transport.isConfigured;

  Future<SingleSyncResult> syncTaskById(int taskId) async {
    if (!_transport.isConfigured) {
      return const SingleSyncResult(
        status: SingleSyncStatus.notConfigured,
        message: 'Токен сервера не настроен.',
      );
    }

    final queued = await _db.getPendingWorkoutSyncTask(taskId);
    if (queued == null) {
      return const SingleSyncResult(
        status: SingleSyncStatus.notFound,
        message: 'Тренировка уже не ожидает отправки.',
      );
    }
    final task = await _db.beginSyncAttempt(queued.id);
    if (task == null) {
      return const SingleSyncResult(
        status: SingleSyncStatus.notFound,
        message: 'Тренировка уже не ожидает отправки.',
      );
    }

    WorkoutSyncPayload payload;
    try {
      final rebuilt = await _db.buildWorkoutSyncPayload(task.entityExternalId);
      if (rebuilt == null) {
        throw StateError('Завершённая тренировка не найдена');
      }
      payload = rebuilt;
    } catch (error) {
      final message = 'Не удалось подготовить тренировку: $error';
      await _db.markSyncTaskAsPermanentFailure(task.id, message);
      await _writeLogSafely(
        task: task,
        result: SyncLogResults.error,
        message: message,
      );
      return SingleSyncResult(
        status: SingleSyncStatus.failure,
        message: message,
      );
    }

    SyncTransportResult result;
    try {
      result = await _transport.sendWorkout(payload);
    } catch (_) {
      result = const SyncTransportResult.failure(
        message: 'Не удалось подключиться к серверу.',
        failureKind: SyncFailureKind.transient,
      );
    }

    if (result.isSuccess) {
      final deleted = await _db.deleteSyncTaskAfterSuccess(
        id: task.id,
        sentPayload: task.payload,
      );
      await _writeLogSafely(
        task: task,
        result: SyncLogResults.success,
        message: result.message,
        httpStatus: result.httpStatus,
      );
      return SingleSyncResult(
        status: SingleSyncStatus.success,
        message: 'Тренировка успешно отправлена',
        httpStatus: result.httpStatus,
        recordId: result.recordId,
        queueTaskDeleted: deleted,
      );
    }

    // A manual send must never remove or permanently sideline the selected
    // workout. Keep it pending so it can be retried after the server-side
    // validation or contract issue has been resolved.
    await _db.markSyncTaskForRetry(task.id, result.message);
    await _writeLogSafely(
      task: task,
      result: SyncLogResults.error,
      message: result.message,
      httpStatus: result.httpStatus,
    );
    return SingleSyncResult(
      status: SingleSyncStatus.failure,
      message: result.message,
      httpStatus: result.httpStatus,
      responseBody: result.responseBody,
    );
  }

  Future<SyncRunResult> syncPending({
    void Function(SyncProgress progress)? onProgress,
  }) async {
    await _db.cleanupSyncLogs();
    if (!_transport.isConfigured) {
      return const SyncRunResult(status: SyncRunStatus.notConfigured);
    }

    await _db.recoverInterruptedSyncTasks();
    final total = await _db.getPendingSyncTaskCount();
    var succeeded = 0;
    var failed = 0;
    SyncRunStopReason? stopReason;
    String? errorMessage;
    int? httpStatus;
    String? responseBody;
    onProgress?.call(SyncProgress(sent: 0, total: total));

    while (true) {
      final queued = await _db.getNextPendingSyncTask();
      if (queued == null) break;
      final task = await _db.beginSyncAttempt(queued.id);
      if (task == null) continue;

      late Future<SyncTransportResult> Function() send;
      try {
        if (task.entityType == SyncEntityTypes.workout &&
            task.operation == SyncOperations.workoutUpsert) {
          final payload = await _db.buildWorkoutSyncPayload(
            task.entityExternalId,
          );
          if (payload == null) {
            throw StateError('Завершённая тренировка не найдена');
          }
          send = () => _transport.sendWorkout(payload);
        } else if (task.entityType == SyncEntityTypes.client &&
            task.operation == SyncOperations.scheduleUpsert) {
          final payload = await _db.buildScheduleSyncPayload(
            task.entityExternalId,
          );
          if (payload == null) {
            throw StateError('Клиент для синхронизации расписания не найден');
          }
          send = () => _transport.sendSchedule(payload);
        } else {
          throw StateError(
            'Неподдерживаемая sync-задача: '
            '${task.entityType}/${task.operation}',
          );
        }
      } catch (error) {
        final message = 'Ошибка синхронизации: $error';
        await _db.markSyncTaskAsPermanentFailure(task.id, message);
        await _writeLogSafely(
          task: task,
          result: SyncLogResults.error,
          message: message,
        );
        failed++;
        stopReason = SyncRunStopReason.permanentFailure;
        errorMessage = message;
        break;
      }

      SyncTransportResult result;
      try {
        result = await send();
      } catch (error) {
        final message = 'Ошибка сети: $error';
        await _db.markSyncTaskForRetry(task.id, message);
        await _writeLogSafely(
          task: task,
          result: SyncLogResults.error,
          message: message,
        );
        failed++;
        stopReason = SyncRunStopReason.transientFailure;
        errorMessage = message;
        break;
      }

      if (result.isSuccess) {
        await _db.deleteSyncTaskAfterSuccess(
          id: task.id,
          sentPayload: task.payload,
        );
        await _writeLogSafely(
          task: task,
          result: SyncLogResults.success,
          message: result.message,
          httpStatus: result.httpStatus,
        );
        succeeded++;
        onProgress?.call(SyncProgress(sent: succeeded, total: total));
        continue;
      }

      final isPermanent =
          result.resolvedFailureKind == SyncFailureKind.permanent;
      if (isPermanent) {
        await _db.markSyncTaskAsPermanentFailure(task.id, result.message);
      } else {
        await _db.markSyncTaskForRetry(task.id, result.message);
      }
      await _writeLogSafely(
        task: task,
        result: SyncLogResults.error,
        message: result.message,
        httpStatus: result.httpStatus,
      );
      failed++;
      errorMessage = result.message;
      httpStatus = result.httpStatus;
      responseBody = result.responseBody;
      stopReason = isPermanent
          ? SyncRunStopReason.permanentFailure
          : SyncRunStopReason.transientFailure;
      break;
    }

    return SyncRunResult(
      status: SyncRunStatus.completed,
      succeeded: succeeded,
      failed: failed,
      stopReason: stopReason,
      errorMessage: errorMessage,
      httpStatus: httpStatus,
      responseBody: responseBody,
    );
  }

  Future<void> _writeLogSafely({
    required SyncQueueEntry task,
    required String result,
    required String message,
    int? httpStatus,
  }) async {
    try {
      await _db.addSyncLog(
        entityType: task.entityType,
        entityExternalId: task.entityExternalId,
        result: result,
        httpStatus: httpStatus,
        message: message,
        attemptNumber: task.attempts,
      );
    } catch (_) {
      // Журнал диагностический и не управляет судьбой подтверждённой задачи.
    }
  }
}
