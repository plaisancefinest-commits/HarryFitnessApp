import 'exercise.dart';

enum UserLevel { noob, beginner, intermediate, advanced }

enum StretchPhase { warmUp, coolDown }

class StretchStep {
  final String name;
  final int durationSeconds;
  final StretchPhase phase;
  final String? instructions;
  final String? videoUrl;

  const StretchStep({
    required this.name,
    required this.durationSeconds,
    required this.phase,
    this.instructions,
    this.videoUrl,
  });
}

/// Non-lifting activities that can be attached to a workout day
/// (planned in the program, or added/removed on the day of).
enum ActivityType { sauna, swim, run, walk }

class PlannedActivity {
  final String id;
  final ActivityType type;
  final int minutes;

  const PlannedActivity({
    required this.id,
    required this.type,
    required this.minutes,
  });

  String get label {
    switch (type) {
      case ActivityType.sauna:
        return 'Sauna';
      case ActivityType.swim:
        return 'Swim';
      case ActivityType.run:
        return 'Run';
      case ActivityType.walk:
        return 'Walk';
    }
  }

  /// Sauna has its own weekly tracker; everything else is zone-2 cardio.
  bool get countsAsCardio => type != ActivityType.sauna;
}

class Program {
  final String id;
  final String name;
  final UserLevel level;
  final List<WorkoutDay> days;
  final List<int>? restDayPositions; // 0-indexed positions in 7-day week that are rest days

  const Program({
    required this.id,
    required this.name,
    required this.level,
    required this.days,
    this.restDayPositions,
  });

  /// 7-slot schedule: workout days placed at their positions, null = rest day.
  /// If [restDayPositions] is set, uses manual layout. Otherwise auto-distributes.
  List<WorkoutDay?> get weekSchedule {
    if (days.length >= 7) {
      return days.take(7).cast<WorkoutDay?>().toList();
    }
    final schedule = List<WorkoutDay?>.filled(7, null);
    if (restDayPositions != null) {
      int wi = 0;
      for (int i = 0; i < 7; i++) {
        if (!restDayPositions!.contains(i) && wi < days.length) {
          schedule[i] = days[wi++];
        }
      }
    } else {
      final spacing = 7.0 / days.length;
      for (int i = 0; i < days.length; i++) {
        schedule[(i * spacing).floor().clamp(0, 6)] = days[i];
      }
    }
    return schedule;
  }
}

class WorkoutDay {
  final String id;
  final String name;
  final String description;
  final int estimatedMinutes;
  final List<PlannedExercise> exercises;
  final List<StretchStep> warmUpStretches;
  final List<StretchStep> coolDownStretches;

  /// Optional planned activities (sauna, swim, run, walk) for this day.
  final List<PlannedActivity> activities;

  const WorkoutDay({
    required this.id,
    required this.name,
    required this.description,
    required this.estimatedMinutes,
    required this.exercises,
    this.warmUpStretches = const [],
    this.coolDownStretches = const [],
    this.activities = const [],
  });
}

class PlannedExercise {
  final String id;
  Exercise exercise; // mutable so the user can swap in a different exercise
  final int sets;
  final int reps;
  int order;

  /// Prescribed working weight, stored in lbs (display converts).
  final double? targetWeightLbs;

  /// Prescribed rest between sets, in seconds.
  final int? restSeconds;

  /// Coach/program notes (form cues, warm-up sets, substitutions).
  final String? notes;

  PlannedExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.order,
    this.targetWeightLbs,
    this.restSeconds,
    this.notes,
  });
}
