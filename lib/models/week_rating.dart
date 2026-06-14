class WeekRating {
  final String id;
  final String programId;
  final DateTime weekStart; // Monday of that week
  final int rating; // 1-10
  final DateTime createdAt;

  const WeekRating({
    required this.id,
    required this.programId,
    required this.weekStart,
    required this.rating,
    required this.createdAt,
  });
}
