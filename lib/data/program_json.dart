import '../models/program.dart';
import 'exercise_library.dart';

/// JSON serialization for user-created programs. Exercises are stored by
/// library id and resolved against [exerciseLibrary] on load.

Map<String, dynamic> programToJson(Program p) => {
      'id': p.id,
      'name': p.name,
      'days': p.days.map(_dayToJson).toList(),
    };

Map<String, dynamic> _dayToJson(WorkoutDay d) => {
      'id': d.id,
      'name': d.name,
      'description': d.description,
      'estimated_minutes': d.estimatedMinutes,
      'exercises': d.exercises.map(_exerciseToJson).toList(),
      'activities': d.activities.map(activityToJson).toList(),
    };

Map<String, dynamic> activityToJson(PlannedActivity a) => {
      'id': a.id,
      'type': a.type.name,
      'minutes': a.minutes,
    };

PlannedActivity activityFromJson(Map<String, dynamic> json) =>
    PlannedActivity(
      id: json['id'],
      type: ActivityType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ActivityType.walk,
      ),
      minutes: json['minutes'],
    );

Map<String, dynamic> _exerciseToJson(PlannedExercise pe) => {
      'id': pe.id,
      'exercise_id': pe.exercise.id,
      'sets': pe.sets,
      'reps': pe.reps,
      'order': pe.order,
      'target_weight_lbs': pe.targetWeightLbs,
      'rest_seconds': pe.restSeconds,
      'notes': pe.notes,
    };

Program programFromJson(Map<String, dynamic> json) => Program(
      id: json['id'],
      name: json['name'],
      level: UserLevel.intermediate,
      days: (json['days'] as List)
          .map((d) => _dayFromJson(Map<String, dynamic>.from(d)))
          .toList(),
    );

WorkoutDay _dayFromJson(Map<String, dynamic> json) => WorkoutDay(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      estimatedMinutes: json['estimated_minutes'],
      exercises: (json['exercises'] as List)
          .map((e) => _exerciseFromJson(Map<String, dynamic>.from(e)))
          .toList(),
      activities: (json['activities'] as List? ?? [])
          .map((a) => activityFromJson(Map<String, dynamic>.from(a)))
          .toList(),
    );

PlannedExercise _exerciseFromJson(Map<String, dynamic> json) =>
    PlannedExercise(
      id: json['id'],
      exercise: exerciseLibrary.firstWhere(
        (e) => e.id == json['exercise_id'],
        orElse: () => exerciseLibrary.first,
      ),
      sets: json['sets'],
      reps: json['reps'],
      order: json['order'],
      targetWeightLbs: (json['target_weight_lbs'] as num?)?.toDouble(),
      restSeconds: json['rest_seconds'],
      notes: json['notes'],
    );
