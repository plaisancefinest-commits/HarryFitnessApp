import '../models/exercise.dart';
import '../models/program.dart';
import 'exercise_library.dart';

Exercise _findExercise(String id) => exerciseLibrary.firstWhere((e) => e.id == id);

// ─── Noob Program ─────────────────────────────────────────────────────────────

final noobProgram = Program(
  id: 'noob_full_body',
  name: 'Full Body',
  level: UserLevel.noob,
  days: [
    WorkoutDay(
      id: 'noob_day_a',
      name: 'Day A',
      description: 'Full Body',
      estimatedMinutes: 40,
      exercises: [
        PlannedExercise(id: 'n_a1', exercise: _findExercise('squat'), sets: 3, reps: 10, order: 0),
        PlannedExercise(id: 'n_a2', exercise: _findExercise('bench_press'), sets: 3, reps: 10, order: 1),
        PlannedExercise(id: 'n_a3', exercise: _findExercise('bent_over_row'), sets: 3, reps: 10, order: 2),
        PlannedExercise(id: 'n_a4', exercise: _findExercise('overhead_press'), sets: 3, reps: 8, order: 3),
        PlannedExercise(id: 'n_a5', exercise: _findExercise('plank'), sets: 3, reps: 1, order: 4),
      ],
      warmUpStretches: const [
        StretchStep(name: 'Hip Flexor Stretch', durationSeconds: 30, phase: StretchPhase.warmUp),
        StretchStep(name: 'Quad Stretch', durationSeconds: 30, phase: StretchPhase.warmUp),
        StretchStep(name: 'Chest Opener', durationSeconds: 30, phase: StretchPhase.warmUp),
        StretchStep(name: 'Shoulder Rolls', durationSeconds: 20, phase: StretchPhase.warmUp),
      ],
      coolDownStretches: const [
        StretchStep(name: 'Seated Hamstring Stretch', durationSeconds: 40, phase: StretchPhase.coolDown),
        StretchStep(name: 'Pigeon Pose', durationSeconds: 40, phase: StretchPhase.coolDown),
        StretchStep(name: 'Chest Doorframe Stretch', durationSeconds: 30, phase: StretchPhase.coolDown),
        StretchStep(name: 'Lat Side Stretch', durationSeconds: 30, phase: StretchPhase.coolDown),
      ],
    ),
    WorkoutDay(
      id: 'noob_day_b',
      name: 'Day B',
      description: 'Full Body',
      estimatedMinutes: 40,
      exercises: [
        PlannedExercise(id: 'n_b1', exercise: _findExercise('romanian_deadlift'), sets: 3, reps: 10, order: 0),
        PlannedExercise(id: 'n_b2', exercise: _findExercise('push_up'), sets: 3, reps: 10, order: 1),
        PlannedExercise(id: 'n_b3', exercise: _findExercise('lat_pulldown'), sets: 3, reps: 10, order: 2),
        PlannedExercise(id: 'n_b4', exercise: _findExercise('lunge'), sets: 3, reps: 10, order: 3),
        PlannedExercise(id: 'n_b5', exercise: _findExercise('crunch'), sets: 3, reps: 10, order: 4),
      ],
      warmUpStretches: const [
        StretchStep(name: 'Cat-Cow', durationSeconds: 30, phase: StretchPhase.warmUp),
        StretchStep(name: 'Hip Circles', durationSeconds: 20, phase: StretchPhase.warmUp),
        StretchStep(name: 'Thoracic Rotation', durationSeconds: 30, phase: StretchPhase.warmUp),
        StretchStep(name: 'Ankle Circles', durationSeconds: 20, phase: StretchPhase.warmUp),
      ],
      coolDownStretches: const [
        StretchStep(name: 'Standing Hip Flexor Stretch', durationSeconds: 40, phase: StretchPhase.coolDown),
        StretchStep(name: 'Figure-Four Glute Stretch', durationSeconds: 40, phase: StretchPhase.coolDown),
        StretchStep(name: "Child's Pose", durationSeconds: 40, phase: StretchPhase.coolDown),
        StretchStep(name: 'Wrist Flexor Stretch', durationSeconds: 20, phase: StretchPhase.coolDown),
      ],
    ),
    WorkoutDay(
      id: 'noob_day_c',
      name: 'Day C',
      description: 'Full Body',
      estimatedMinutes: 40,
      exercises: [
        PlannedExercise(id: 'n_c1', exercise: _findExercise('overhead_press'), sets: 3, reps: 8, order: 0),
        PlannedExercise(id: 'n_c2', exercise: _findExercise('deadlift'), sets: 3, reps: 8, order: 1),
        PlannedExercise(id: 'n_c3', exercise: _findExercise('seated_cable_row'), sets: 3, reps: 10, order: 2),
        PlannedExercise(id: 'n_c4', exercise: _findExercise('lunge'), sets: 3, reps: 10, order: 3),
        PlannedExercise(id: 'n_c5', exercise: _findExercise('plank'), sets: 3, reps: 1, order: 4),
      ],
      warmUpStretches: const [
        StretchStep(name: 'Neck Rolls', durationSeconds: 20, phase: StretchPhase.warmUp),
        StretchStep(name: 'Cross-Body Shoulder Stretch', durationSeconds: 30, phase: StretchPhase.warmUp),
        StretchStep(name: 'Spinal Twist', durationSeconds: 30, phase: StretchPhase.warmUp),
        StretchStep(name: 'Leg Swings', durationSeconds: 20, phase: StretchPhase.warmUp),
      ],
      coolDownStretches: const [
        StretchStep(name: 'Overhead Tricep Stretch', durationSeconds: 30, phase: StretchPhase.coolDown),
        StretchStep(name: 'Standing Quad Stretch', durationSeconds: 30, phase: StretchPhase.coolDown),
        StretchStep(name: 'Lower Back Twist', durationSeconds: 40, phase: StretchPhase.coolDown),
        StretchStep(name: 'Deep Squat Hold', durationSeconds: 40, phase: StretchPhase.coolDown),
      ],
    ),
  ],
);

// ─── Beginner Program ─────────────────────────────────────────────────────────

final beginnerProgram = Program(
  id: 'beginner_ppl',
  name: 'Push / Pull / Legs',
  level: UserLevel.beginner,
  days: [
    WorkoutDay(
      id: 'day_a_lower_push',
      name: 'Day A',
      description: 'Lower + Push',
      estimatedMinutes: 50,
      exercises: [
        PlannedExercise(id: 'pe_1', exercise: _findExercise('squat'), sets: 3, reps: 8, order: 0),
        PlannedExercise(id: 'pe_2', exercise: _findExercise('bench_press'), sets: 3, reps: 10, order: 1),
        PlannedExercise(id: 'pe_3', exercise: _findExercise('overhead_press'), sets: 3, reps: 10, order: 2),
        PlannedExercise(id: 'pe_4', exercise: _findExercise('db_flyes'), sets: 3, reps: 12, order: 3),
      ],
    ),
    WorkoutDay(
      id: 'day_b_upper_pull',
      name: 'Day B',
      description: 'Upper + Pull',
      estimatedMinutes: 45,
      exercises: [
        PlannedExercise(id: 'pe_5', exercise: _findExercise('romanian_deadlift'), sets: 3, reps: 8, order: 0),
        PlannedExercise(id: 'pe_6', exercise: _findExercise('lat_pulldown'), sets: 3, reps: 10, order: 1),
        PlannedExercise(id: 'pe_7', exercise: _findExercise('bench_press'), sets: 3, reps: 10, order: 2),
      ],
    ),
  ],
);

final samplePrograms = [noobProgram, beginnerProgram];
