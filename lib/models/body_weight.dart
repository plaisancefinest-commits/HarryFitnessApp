/// Body-weight goal: where the user started and where they want to end up.
/// Weights are stored in lbs (display converts to the chosen unit).
class WeightGoal {
  final double startWeightLbs;
  final DateTime startDate;
  final double goalWeightLbs;
  final DateTime endDate;

  const WeightGoal({
    required this.startWeightLbs,
    required this.startDate,
    required this.goalWeightLbs,
    required this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'start_weight_lbs': startWeightLbs,
        'start_date': startDate.toIso8601String(),
        'goal_weight_lbs': goalWeightLbs,
        'end_date': endDate.toIso8601String(),
      };

  factory WeightGoal.fromJson(Map<String, dynamic> json) => WeightGoal(
        startWeightLbs: (json['start_weight_lbs'] as num).toDouble(),
        startDate: DateTime.parse(json['start_date']),
        goalWeightLbs: (json['goal_weight_lbs'] as num).toDouble(),
        endDate: DateTime.parse(json['end_date']),
      );
}

/// A single logged weigh-in. One entry per calendar day.
class WeightEntry {
  final DateTime date;
  final double weightLbs;

  const WeightEntry({required this.date, required this.weightLbs});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight_lbs': weightLbs,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        date: DateTime.parse(json['date']),
        weightLbs: (json['weight_lbs'] as num).toDouble(),
      );
}
