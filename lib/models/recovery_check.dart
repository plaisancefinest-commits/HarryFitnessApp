import 'exercise.dart';

enum RecoveryStatus { fullyRecovered, slightlySore, verySore, injured }

class MuscleRecoveryRating {
  final MuscleGroup muscleGroup;
  final RecoveryStatus status;

  const MuscleRecoveryRating({
    required this.muscleGroup,
    required this.status,
  });
}

class RecoveryCheck {
  final String id;
  final String programId;
  final DateTime weekStart; // Monday of that week (legacy, kept for compat)
  final bool isPreWeek; // true = start-of-rotation, false = end-of-rotation
  final int? rotationNumber; // rotation this check belongs to
  final List<MuscleRecoveryRating> ratings;
  final DateTime createdAt;

  const RecoveryCheck({
    required this.id,
    required this.programId,
    required this.weekStart,
    required this.isPreWeek,
    this.rotationNumber,
    required this.ratings,
    required this.createdAt,
  });
}

/// All unique muscle groups trained in a program (primary + secondary).
Set<MuscleGroup> muscleGroupsForProgram(
    List<dynamic> days) {
  final muscles = <MuscleGroup>{};
  for (final day in days) {
    for (final pe in day.exercises) {
      muscles.addAll(pe.exercise.primaryMuscles);
    }
  }
  return muscles;
}
