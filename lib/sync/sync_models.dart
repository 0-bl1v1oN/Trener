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

class SyncRunResult {
  const SyncRunResult({
    required this.status,
    this.succeeded = 0,
    this.failed = 0,
  });

  final SyncRunStatus status;
  final int succeeded;
  final int failed;
}
