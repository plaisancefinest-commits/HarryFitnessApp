class WorkoutSession {
  final String id;
  final String programId;
  final String workoutDayId;
  final DateTime date;
  final List<SetLog> sets;
  final List<RestLog> rests;
  bool isComplete;
  int? dayRating; // 1-10 rating given at end of workout

  WorkoutSession({
    required this.id,
    required this.programId,
    required this.workoutDayId,
    required this.date,
    this.sets = const [],
    this.rests = const [],
    this.isComplete = false,
    this.dayRating,
  });

  // Average rest per exercise across all sets in this session
  Map<String, Duration> get averageRestPerExercise {
    final Map<String, List<int>> restsByExercise = {};
    for (final r in rests) {
      restsByExercise.putIfAbsent(r.exerciseId, () => []).add(r.restSeconds);
    }
    return restsByExercise.map((exerciseId, seconds) {
      final avg = seconds.reduce((a, b) => a + b) ~/ seconds.length;
      return MapEntry(exerciseId, Duration(seconds: avg));
    });
  }
}

class SetLog {
  final String id;
  final String exerciseId;
  final int setNumber;
  final double weight;
  final int reps;
  final String? notes;
  final DateTime completedAt;

  const SetLog({
    required this.id,
    required this.exerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.notes,
    required this.completedAt,
  });
}

class RestLog {
  final String exerciseId;
  final int setNumber;
  final int restSeconds;

  const RestLog({
    required this.exerciseId,
    required this.setNumber,
    required this.restSeconds,
  });
}
