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

  Future<SyncRunResult> syncPending() async {
    await _db.cleanupSyncLogs();
    if (!_transport.isConfigured) {
      return const SyncRunResult(status: SyncRunStatus.notConfigured);
    }

    await _db.recoverInterruptedSyncTasks();
    final tasks = await _db.getPendingSyncTasks();
    var succeeded = 0;
    var failed = 0;

    for (final queued in tasks) {
      final task = await _db.beginSyncAttempt(queued.id);
      if (task == null) continue;

      try {
        if (task.operation != SyncOperations.workoutUpsert) {
          throw StateError('Неподдерживаемая sync-операция: ${task.operation}');
        }
        final decoded = jsonDecode(task.payload);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Некорректный payload очереди');
        }
        final payload = WorkoutSyncPayload.fromJson(decoded);
        final result = await _transport.sendWorkout(payload);

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
          continue;
        }

        await _db.markSyncTaskForRetry(task.id, result.message);
        await _writeLogSafely(
          task: task,
          result: SyncLogResults.error,
          message: result.message,
          httpStatus: result.httpStatus,
        );
        failed++;
      } catch (error) {
        final message = 'Ошибка синхронизации: $error';
        await _db.markSyncTaskForRetry(task.id, message);
        await _writeLogSafely(
          task: task,
          result: SyncLogResults.error,
          message: message,
        );
        failed++;
      }
    }

    return SyncRunResult(
      status: SyncRunStatus.completed,
      succeeded: succeeded,
      failed: failed,
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
