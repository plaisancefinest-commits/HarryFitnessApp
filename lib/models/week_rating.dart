class WeekRating {
  final String id;
  final String programId;
  final DateTime weekStart; // Monday of that week (legacy, kept for compat)
  final int? rotationNumber; // rotation this rating belongs to
  final int rating; // 1-10
  final DateTime createdAt;

  const WeekRating({
    required this.id,
    required this.programId,
    required this.weekStart,
    this.rotationNumber,
    required this.rating,
    required this.createdAt,
  });
}
