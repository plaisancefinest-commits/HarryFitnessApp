import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/picture_challenge.dart';
import '../models/program.dart';
import 'database_service.dart';

/// Bundled reveal images. Add/remove entries as images are added to assets/.
const _revealImages = [
  'assets/reveal_images/01.jpg',
  'assets/reveal_images/02.jpg',
  'assets/reveal_images/03.jpg',
  'assets/reveal_images/04.jpg',
  'assets/reveal_images/05.jpg',
  'assets/reveal_images/06.jpg',
  'assets/reveal_images/07.jpg',
  'assets/reveal_images/08.jpg',
  'assets/reveal_images/09.jpg',
  'assets/reveal_images/10.jpg',
  'assets/reveal_images/11.jpg',
  'assets/reveal_images/12.jpg',
  'assets/reveal_images/13.jpg',
  'assets/reveal_images/14.jpg',
  'assets/reveal_images/15.jpg',
];

class PictureChallengeService {
  PictureChallengeService._();

  /// Check whether a program qualifies for the picture reveal feature.
  ///
  /// Rules:
  /// - At least 4 weeks
  /// - At least 4 unique exercises across all days
  /// - Every day must be at least 40 estimated minutes
  static bool isEligible(Program program, int numberOfWeeks) {
    if (numberOfWeeks < 4) return false;

    final uniqueExercises = <String>{};
    for (final day in program.days) {
      if (day.estimatedMinutes < 40) return false;
      for (final pe in day.exercises) {
        uniqueExercises.add(pe.exercise.id);
      }
    }
    if (uniqueExercises.length < 4) return false;

    return true;
  }

  /// Create and persist a new challenge for the given program.
  static Future<PictureChallenge> createChallenge(
      Program program, int numberOfWeeks) async {
    final now = DateTime.now();
    final challenge = PictureChallenge(
      id: const Uuid().v4(),
      programId: program.id,
      imageAssetPath: _revealImages[Random().nextInt(_revealImages.length)],
      totalWorkouts: program.days.length * numberOfWeeks,
      numberOfWeeks: numberOfWeeks,
      startDate: now,
      goalEndDate: now.add(Duration(days: numberOfWeeks * 7)),
      completedWorkouts: 0,
    );
    await DatabaseService.instance.savePictureChallenge(challenge);
    return challenge;
  }

  /// True if no completed session exists for this program on today's date.
  ///
  /// MUST be called BEFORE saveSession() writes the new session — otherwise
  /// the just-saved session would make this return false.
  static Future<bool> isFirstWorkoutToday(String programId) async {
    final sessions = await DatabaseService.instance.getCompletedSessions();
    final today = DateTime.now();
    return !sessions.any((s) =>
        s.programId == programId &&
        s.date.year == today.year &&
        s.date.month == today.month &&
        s.date.day == today.day);
  }

  /// Increment the reveal counter and persist. Returns the updated challenge,
  /// or null if no active challenge exists.
  static Future<PictureChallenge?> recordProgress() async {
    final challenge = await DatabaseService.instance.getPictureChallenge();
    if (challenge == null) return null;
    if (challenge.completedWorkouts >= challenge.totalWorkouts) return challenge;
    challenge.completedWorkouts++;
    await DatabaseService.instance.savePictureChallenge(challenge);
    return challenge;
  }

  /// Load the active challenge for a given program, or null.
  static Future<PictureChallenge?> getActiveChallenge(String programId) async {
    final challenge = await DatabaseService.instance.getPictureChallenge();
    if (challenge == null || challenge.programId != programId) return null;
    return challenge;
  }
}
