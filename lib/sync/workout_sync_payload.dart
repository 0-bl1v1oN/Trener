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
    this.clientGender,
    this.subscriptionSize,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.remainingSessions,
    required this.workoutExternalId,
    required this.performedAt,
    required this.workoutName,
    required this.exercises,
  });

  final String clientExternalId;
  final String clientName;
  final String? clientGender;
  final int? subscriptionSize;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final int? remainingSessions;
  final String workoutExternalId;
  final DateTime performedAt;
  final String? workoutName;
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
    return workout['workout_id'] as String;
  }

  String get clientExternalId {
    final client = _json['client'] as Map;
    return client['client_id'] as String;
  }

  String get clientName {
    final client = _json['client'] as Map;
    return client['name'] as String;
  }

  DateTime get performedAt {
    final workout = _json['workout'] as Map;
    return DateTime.parse(workout['date'] as String);
  }

  String? get dayLabel => null;

  String? get dayTitle {
    final workout = _json['workout'] as Map;
    return workout['name'] as String?;
  }

  List<WorkoutSyncExerciseSource> get exercises {
    final exercises = _json['exercises'] as List;
    return [
      for (final exercise in exercises.cast<Map>())
        WorkoutSyncExerciseSource(
          exerciseExternalId: exercise['exercise_id'] as String,
          name: exercise['name'] as String,
          weightKg: (exercise['weight_kg'] as num?)?.toDouble(),
          reps: exercise['reps'] as int?,
        ),
    ];
  }

  Map<String, dynamic> toJson() => _json;

  String encode() => jsonEncode(_json);

  static Map<String, dynamic> _serialize(WorkoutSyncSource source) {
    final workoutName = _nonEmpty(source.workoutName);
    return {
      'client': {
        'client_id': source.clientExternalId,
        'name': source.clientName,
        if (source.clientGender != null) 'gender': source.clientGender,
        if (source.subscriptionSize != null)
          'subscription_size': source.subscriptionSize,
        if (source.subscriptionStart != null)
          'subscription_start': _dateOnly(source.subscriptionStart!),
        if (source.subscriptionEnd != null)
          'subscription_end': _dateOnly(source.subscriptionEnd!),
        if (source.remainingSessions != null)
          'remaining_sessions': source.remainingSessions,
      },
      'workout': {
        'workout_id': source.workoutExternalId,
        'date': _dateOnly(source.performedAt),
        if (workoutName != null) 'name': workoutName,
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

  static Map<String, dynamic> _normalize(Map<String, dynamic> json) {
    final client = Map<String, dynamic>.from(json['client'] as Map);
    final workout = Map<String, dynamic>.from(json['workout'] as Map);
    final exercises = json['exercises'] as List;
    final workoutName = _nonEmpty(
      workout['name'] ?? workout['day_title'] ?? workout['day_label'],
    );

    return {
      'client': {
        'client_id': client['client_id'] ?? client['uuid'],
        'name': client['name'],
        if (client['gender'] != null) 'gender': client['gender'],
        if (client['subscription_size'] != null)
          'subscription_size': client['subscription_size'],
        if (client['subscription_start'] != null)
          'subscription_start': client['subscription_start'],
        if (client['subscription_end'] != null)
          'subscription_end': client['subscription_end'],
        if (client['remaining_sessions'] != null)
          'remaining_sessions': client['remaining_sessions'],
      },
      'workout': {
        'workout_id': workout['workout_id'] ?? workout['uuid'],
        'date': _normalizedDate(workout['date'] ?? workout['performed_at']),
        if (workoutName != null) 'name': workoutName,
      },
      'exercises': [
        for (final rawExercise in exercises)
          if (rawExercise is Map)
            {
              'exercise_id': rawExercise['exercise_id'] ?? rawExercise['uuid'],
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

  static String _dateOnly(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
  }

  static String _normalizedDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('В workout payload отсутствует дата');
    }
    final date = DateTime.tryParse(value.trim());
    if (date == null) {
      throw const FormatException('Некорректная дата workout payload');
    }
    return _dateOnly(date);
  }

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
