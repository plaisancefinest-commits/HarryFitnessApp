import '../models/personal_record.dart';
import '../models/workout_session.dart';

/// Stateless utility for computing personal records and exercise summaries.
/// All weights are canonical lbs — display conversion happens at the UI boundary.
class PRService {
  PRService._();

  /// Epley estimated one-rep max: weight × (1 + reps / 30).
  /// For reps == 1, returns weight directly (actual 1RM).
  /// Returns 0 for invalid inputs.
  static double epley1RM(double weightLbs, int reps) {
    if (weightLbs <= 0 || reps <= 0) return 0;
    if (reps == 1) return weightLbs;
    return weightLbs * (1 + reps / 30.0);
  }

  /// Compute all-time PRs for a single exercise from its full set history.
  static ExercisePRSet computeAllTimePRs(
      String exerciseId, List<SetLog> allSets) {
    PersonalRecord? bestWeight;
    PersonalRecord? bestReps;
    PersonalRecord? best1RM;

    for (final s in allSets) {
      if (s.weight <= 0 || s.reps <= 0) continue;

      // Heaviest weight
      if (bestWeight == null || s.weight > bestWeight.value) {
        bestWeight = PersonalRecord(
          exerciseId: exerciseId,
          type: PRType.heaviestWeight,
          value: s.weight,
          weight: s.weight,
          reps: s.reps,
          achievedAt: s.completedAt,
        );
      }

      // Most reps
      if (bestReps == null || s.reps > bestReps.value) {
        bestReps = PersonalRecord(
          exerciseId: exerciseId,
          type: PRType.mostReps,
          value: s.reps.toDouble(),
          weight: s.weight,
          reps: s.reps,
          achievedAt: s.completedAt,
        );
      }

      // Best estimated 1RM
      final e1rm = epley1RM(s.weight, s.reps);
      if (best1RM == null || e1rm > best1RM.value) {
        best1RM = PersonalRecord(
          exerciseId: exerciseId,
          type: PRType.estimated1RM,
          value: e1rm,
          weight: s.weight,
          reps: s.reps,
          achievedAt: s.completedAt,
        );
      }
    }

    return ExercisePRSet(
      heaviestWeight: bestWeight,
      mostReps: bestReps,
      estimated1RM: best1RM,
    );
  }

  /// Detect which PRs were beaten in this session compared to prior history.
  ///
  /// [sessionSets]: the sets from the just-completed session.
  /// [previousPRs]: PRs computed from all sessions BEFORE this one.
  /// Returns a map of exerciseId → list of PR types that were broken.
  static Map<String, List<PRType>> detectNewPRs(
    List<SetLog> sessionSets,
    Map<String, ExercisePRSet> previousPRs,
  ) {
    final result = <String, List<PRType>>{};

    // Group session sets by exercise
    final byExercise = <String, List<SetLog>>{};
    for (final s in sessionSets) {
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    for (final entry in byExercise.entries) {
      final exerciseId = entry.key;
      final sets = entry.value;
      final prev = previousPRs[exerciseId];
      final prs = <PRType>[];

      double sessionMaxWeight = 0;
      int sessionMaxReps = 0;
      double sessionMax1RM = 0;

      for (final s in sets) {
        if (s.weight <= 0 || s.reps <= 0) continue;
        if (s.weight > sessionMaxWeight) sessionMaxWeight = s.weight;
        if (s.reps > sessionMaxReps) sessionMaxReps = s.reps;
        final e1rm = epley1RM(s.weight, s.reps);
        if (e1rm > sessionMax1RM) sessionMax1RM = e1rm;
      }

      // Compare against previous PRs (null means first time = automatic PR)
      if (prev?.heaviestWeight == null ||
          sessionMaxWeight > prev!.heaviestWeight!.value) {
        if (sessionMaxWeight > 0) prs.add(PRType.heaviestWeight);
      }
      if (prev?.mostReps == null ||
          sessionMaxReps > prev!.mostReps!.value) {
        if (sessionMaxReps > 0) prs.add(PRType.mostReps);
      }
      if (prev?.estimated1RM == null ||
          sessionMax1RM > prev!.estimated1RM!.value) {
        if (sessionMax1RM > 0) prs.add(PRType.estimated1RM);
      }

      if (prs.isNotEmpty) result[exerciseId] = prs;
    }

    return result;
  }

  /// Build a compact summary for one exercise within a single session.
  static ExerciseSummary summarizeExercise(
    String exerciseId,
    List<SetLog> sessionSets, {
    List<PRType> newPRs = const [],
  }) {
    double bestWeight = 0;
    int bestReps = 0;
    double totalVolume = 0;
    double best1RM = 0;

    for (final s in sessionSets) {
      if (s.weight <= 0 || s.reps <= 0) continue;
      totalVolume += s.weight * s.reps;
      final e1rm = epley1RM(s.weight, s.reps);
      if (s.weight > bestWeight ||
          (s.weight == bestWeight && s.reps > bestReps)) {
        bestWeight = s.weight;
        bestReps = s.reps;
      }
      if (e1rm > best1RM) best1RM = e1rm;
    }

    return ExerciseSummary(
      exerciseId: exerciseId,
      bestSetWeight: bestWeight,
      bestSetReps: bestReps,
      totalVolume: totalVolume,
      estimated1RM: best1RM,
      newPRs: newPRs,
    );
  }
}
