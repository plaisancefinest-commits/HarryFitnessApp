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
  final DateTime weekStart; // Monday of that week
  final bool isPreWeek; // true = start-of-week, false = end-of-week
  final List<MuscleRecoveryRating> ratings;
  final DateTime createdAt;

  const RecoveryCheck({
    required this.id,
    required this.programId,
    required this.weekStart,
    required this.isPreWeek,
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
