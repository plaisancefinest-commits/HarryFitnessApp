import 'exercise.dart';

enum UserLevel { noob, beginner, intermediate, advanced }

enum StretchPhase { warmUp, coolDown }

class StretchStep {
  final String name;
  final int durationSeconds;
  final StretchPhase phase;

  const StretchStep({
    required this.name,
    required this.durationSeconds,
    required this.phase,
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
  final Exercise exercise;
  final int sets;
  final int reps;
  int order;

  PlannedExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.order,
  });
}
