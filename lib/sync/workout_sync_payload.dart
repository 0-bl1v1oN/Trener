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
    return WorkoutSyncPayload._(_normalize(json));
  }

  final Map<String, dynamic> _json;

  String get workoutExternalId {
    final workout = _json['workout'] as Map;
    return workout['uuid'] as String;
  }

  Map<String, dynamic> toJson() => _json;

  String encode() => jsonEncode(_json);

  static Map<String, dynamic> _serialize(WorkoutSyncSource source) => {
    'client': {'uuid': source.clientExternalId, 'name': source.clientName},
    'workout': {
      'uuid': source.workoutExternalId,
      'performed_at': source.performedAt.toUtc().toIso8601String(),
      'day_index': source.templateIndex,
      if (source.dayLabel != null) 'day_label': source.dayLabel,
      if (source.dayTitle != null) 'day_title': source.dayTitle,
      'plan_instance': source.planInstance,
    },
    'exercises': [
      for (final exercise in source.exercises)
        {
          'uuid': exercise.exerciseExternalId,
          'name': exercise.name,
          'weight_kg': exercise.weightKg,
          'reps': exercise.reps,
        },
    ],
  };

  static Map<String, dynamic> _normalize(Map<String, dynamic> json) {
    final client = Map<String, dynamic>.from(json['client'] as Map);
    final workout = Map<String, dynamic>.from(json['workout'] as Map);
    final exercises = json['exercises'] as List;

    return {
      'client': {
        'uuid': client['uuid'] ?? client['client_id'],
        'name': client['name'],
      },
      'workout': {
        'uuid': workout['uuid'] ?? workout['workout_id'],
        'performed_at': workout['performed_at'],
        'day_index': workout['day_index'],
        if (workout['day_label'] != null) 'day_label': workout['day_label'],
        if (workout['day_title'] != null) 'day_title': workout['day_title'],
        'plan_instance': workout['plan_instance'],
      },
      'exercises': [
        for (final rawExercise in exercises)
          if (rawExercise is Map)
            {
              'uuid': rawExercise['uuid'] ?? rawExercise['exercise_id'],
              'name': rawExercise['name'],
              'weight_kg': rawExercise['weight_kg'],
              'reps': rawExercise['reps'],
            }
          else
            throw const FormatException(
              'Некорректное упражнение в workout sync payload',
            ),
      ],
    };
  }
}
