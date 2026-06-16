import 'dart:convert';

class PictureChallenge {
  final String id;
  final String programId;
  final String imageAssetPath;
  final int totalWorkouts;
  final int numberOfWeeks;
  final DateTime startDate;
  final DateTime goalEndDate;
  int completedWorkouts;

  PictureChallenge({
    required this.id,
    required this.programId,
    required this.imageAssetPath,
    required this.totalWorkouts,
    required this.numberOfWeeks,
    required this.startDate,
    required this.goalEndDate,
    this.completedWorkouts = 0,
  });

  /// 0.0 (fully zoomed) to 1.0 (all workouts done).
  double get revealProgress =>
      totalWorkouts > 0 ? (completedWorkouts / totalWorkouts).clamp(0.0, 1.0) : 0.0;

  /// True only when every workout is done AND the goal date has passed.
  bool get isFullyRevealed =>
      completedWorkouts >= totalWorkouts &&
      !DateTime.now().isBefore(goalEndDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'programId': programId,
        'imageAssetPath': imageAssetPath,
        'totalWorkouts': totalWorkouts,
        'numberOfWeeks': numberOfWeeks,
        'startDate': startDate.toIso8601String(),
        'goalEndDate': goalEndDate.toIso8601String(),
        'completedWorkouts': completedWorkouts,
      };

  factory PictureChallenge.fromJson(Map<String, dynamic> json) =>
      PictureChallenge(
        id: json['id'],
        programId: json['programId'],
        imageAssetPath: json['imageAssetPath'],
        totalWorkouts: json['totalWorkouts'],
        numberOfWeeks: json['numberOfWeeks'],
        startDate: DateTime.parse(json['startDate']),
        goalEndDate: DateTime.parse(json['goalEndDate']),
        completedWorkouts: json['completedWorkouts'] ?? 0,
      );

  String encode() => jsonEncode(toJson());

  static PictureChallenge? decode(String? raw) {
    if (raw == null) return null;
    return PictureChallenge.fromJson(jsonDecode(raw));
  }
}
