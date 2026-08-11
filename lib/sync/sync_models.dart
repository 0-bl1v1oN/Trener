class SyncEntityTypes {
  static const workout = 'WORKOUT';
}

class SyncOperations {
  static const workoutUpsert = 'WORKOUT_UPSERT';
}

class SyncQueueStatuses {
  static const pending = 'PENDING';
  static const processing = 'PROCESSING';
  static const failed = 'FAILED';
}

class SyncLogResults {
  static const success = 'SUCCESS';
  static const error = 'ERROR';
}

enum SyncRunStatus { completed, notConfigured }

enum SyncRunStopReason { transientFailure, permanentFailure }

class SyncProgress {
  const SyncProgress({required this.sent, required this.total});

  final int sent;
  final int total;
}

class SyncRunResult {
  const SyncRunResult({
    required this.status,
    this.succeeded = 0,
    this.failed = 0,
    this.stopReason,
    this.errorMessage,
    this.httpStatus,
    this.responseBody,
  });

  final SyncRunStatus status;
  final int succeeded;
  final int failed;
  final SyncRunStopReason? stopReason;
  final String? errorMessage;
  final int? httpStatus;
  final String? responseBody;
}

enum SingleSyncStatus { success, failure, notConfigured, notFound }

class SingleSyncResult {
  const SingleSyncResult({
    required this.status,
    required this.message,
    this.httpStatus,
    this.recordId,
    this.responseBody,
    this.queueTaskDeleted = false,
  });

  final SingleSyncStatus status;
  final String message;
  final int? httpStatus;
  final String? recordId;
  final String? responseBody;
  final bool queueTaskDeleted;
}
