import 'exercise.dart';

enum UserLevel { noob, beginner, intermediate, advanced }

enum StretchPhase { warmUp, coolDown }

class StretchStep {
  final String name;
  final int durationSeconds;
  final StretchPhase phase;
  final String? instructions;
  final String? videoUrl;

  const StretchStep({
    required this.name,
    required this.durationSeconds,
    required this.phase,
    this.instructions,
    this.videoUrl,
  });
}

class Program {
  final String id;
  final String name;
  final UserLevel level;
  final List<WorkoutDay> days;

  const Program({
    required this.id,
    required this.name,
    required this.level,
    required this.days,
  });
}

class WorkoutDay {
  final String id;
  final String name;
  final String description;
  final int estimatedMinutes;
  final List<PlannedExercise> exercises;
  final List<StretchStep> warmUpStretches;
  final List<StretchStep> coolDownStretches;

  const WorkoutDay({
    required this.id,
    required this.name,
    required this.description,
    required this.estimatedMinutes,
    required this.exercises,
    this.warmUpStretches = const [],
    this.coolDownStretches = const [],
  });
}

class PlannedExercise {
  final String id;
  Exercise exercise; // mutable so the user can swap in a different exercise
  final int sets;
  final int reps;
  int order;

  /// Prescribed working weight, stored in lbs (display converts).
  final double? targetWeightLbs;

  /// Prescribed rest between sets, in seconds.
  final int? restSeconds;

  /// Coach/program notes (form cues, warm-up sets, substitutions).
  final String? notes;

  PlannedExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.order,
    this.targetWeightLbs,
    this.restSeconds,
    this.notes,
  });
}
