import 'dart:convert';

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
    onProgress?.call(SyncProgress(sent: 0, total: total));

    while (true) {
      final queued = await _db.getNextPendingSyncTask();
      if (queued == null) break;
      final task = await _db.beginSyncAttempt(queued.id);
      if (task == null) continue;

      WorkoutSyncPayload payload;
      try {
        if (task.operation != SyncOperations.workoutUpsert) {
          throw StateError('Неподдерживаемая sync-операция: ${task.operation}');
        }
        final decoded = jsonDecode(task.payload);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Некорректный payload очереди');
        }
        payload = WorkoutSyncPayload.fromJson(decoded);
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
        break;
      }

      SyncTransportResult result;
      try {
        result = await _transport.sendWorkout(payload);
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
