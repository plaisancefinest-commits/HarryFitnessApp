enum PRType { heaviestWeight, mostReps, estimated1RM }

/// A single personal record for one exercise and one PR type.
class PersonalRecord {
  final String exerciseId;
  final PRType type;
  final double value; // weight in lbs, reps as double, or 1RM in lbs
  final double weight; // the set's weight (lbs) that produced this PR
  final int reps; // the set's reps that produced this PR
  final DateTime achievedAt;

  const PersonalRecord({
    required this.exerciseId,
    required this.type,
    required this.value,
    required this.weight,
    required this.reps,
    required this.achievedAt,
  });
}

/// All-time PR set for one exercise: best weight, best reps, best estimated 1RM.
class ExercisePRSet {
  final PersonalRecord? heaviestWeight;
  final PersonalRecord? mostReps;
  final PersonalRecord? estimated1RM;

  const ExercisePRSet({this.heaviestWeight, this.mostReps, this.estimated1RM});
}

/// Compact summary of one exercise within a single completed workout.
class ExerciseSummary {
  final String exerciseId;
  final double bestSetWeight; // lbs (canonical)
  final int bestSetReps;
  final double totalVolume; // sum of weight × reps across all sets (lbs)
  final double estimated1RM; // Epley from best set (lbs)
  final List<PRType> newPRs; // empty if no records broken

  const ExerciseSummary({
    required this.exerciseId,
    required this.bestSetWeight,
    required this.bestSetReps,
    required this.totalVolume,
    required this.estimated1RM,
    required this.newPRs,
  });
}
