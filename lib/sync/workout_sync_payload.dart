import 'dart:convert';

class WorkoutSyncExerciseSource {
  const WorkoutSyncExerciseSource({
    required this.exerciseExternalId,
    required this.name,
    required this.weightKg,
    required this.reps,
  });

  final String exerciseExternalId;
  final String name;
  final double? weightKg;
  final int? reps;
}

class WorkoutSyncSource {
  const WorkoutSyncSource({
    required this.clientExternalId,
    required this.clientName,
    required this.workoutExternalId,
    required this.performedAt,
    required this.templateIndex,
    required this.dayLabel,
    required this.dayTitle,
    required this.planInstance,
    required this.exercises,
  });

  final String clientExternalId;
  final String clientName;
  final String workoutExternalId;
  final DateTime performedAt;
  final int templateIndex;
  final String? dayLabel;
  final String? dayTitle;
  final int planInstance;
  final List<WorkoutSyncExerciseSource> exercises;
}

class WorkoutSyncPayload {
  const WorkoutSyncPayload._(this._json);

  factory WorkoutSyncPayload.fromSource(WorkoutSyncSource source) {
    return WorkoutSyncPayload._(_serialize(source));
  }

  factory WorkoutSyncPayload.fromJson(Map<String, dynamic> json) {
    final workout = json['workout'];
    final exercises = json['exercises'];
    final client = json['client'];
    if (workout is! Map || exercises is! List || client is! Map) {
      throw const FormatException('Некорректный workout sync payload');
    }
    return WorkoutSyncPayload._(json);
  }

  final Map<String, dynamic> _json;

  String get workoutExternalId {
    final workout = _json['workout'] as Map;
    return workout['workout_id'] as String;
  }

  Map<String, dynamic> toJson() => _json;

  String encode() => jsonEncode(_json);

  static Map<String, dynamic> _serialize(WorkoutSyncSource source) => {
    'client': {'client_id': source.clientExternalId, 'name': source.clientName},
    'workout': {
      'workout_id': source.workoutExternalId,
      'performed_at': source.performedAt.toUtc().toIso8601String(),
      'day_index': source.templateIndex,
      if (source.dayLabel != null) 'day_label': source.dayLabel,
      if (source.dayTitle != null) 'day_title': source.dayTitle,
      'plan_instance': source.planInstance,
    },
    'exercises': [
      for (final exercise in source.exercises)
        {
          'exercise_id': exercise.exerciseExternalId,
          'name': exercise.name,
          'weight_kg': exercise.weightKg,
          'reps': exercise.reps,
        },
    ],
  };
}
