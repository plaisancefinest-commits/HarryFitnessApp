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
        StretchStep(
            name: 'Hip Flexor Stretch', durationSeconds: 30, phase: StretchPhase.warmUp,
            instructions: 'Kneel on one knee with the other foot planted in front. Push your hips forward until you feel a stretch in the front of the rear hip. Keep your torso upright. Switch sides halfway.'),
        StretchStep(
            name: 'Quad Stretch', durationSeconds: 30, phase: StretchPhase.warmUp,
            instructions: 'Standing, grab one ankle behind you and pull your heel toward your glutes. Keep knees together and hips pushed slightly forward. Hold a wall for balance if needed. Switch sides halfway.'),
        StretchStep(
            name: 'Chest Opener', durationSeconds: 30, phase: StretchPhase.warmUp,
            instructions: 'Clasp your hands behind your back, straighten your arms, and lift them away from your body while squeezing your shoulder blades together and opening your chest.'),
        StretchStep(
            name: 'Shoulder Rolls', durationSeconds: 20, phase: StretchPhase.warmUp,
            instructions: 'Roll your shoulders up, back, and down in big slow circles. After half the time, reverse direction.'),
      ],
      coolDownStretches: const [
        StretchStep(
            name: 'Seated Hamstring Stretch', durationSeconds: 40, phase: StretchPhase.coolDown,
            instructions: 'Sit with one leg extended, the other foot against your inner thigh. Hinge at the hips and reach toward your toes with a flat back. Switch sides halfway.'),
        StretchStep(
            name: 'Pigeon Pose', durationSeconds: 40, phase: StretchPhase.coolDown,
            instructions: 'From all fours, bring one shin forward and across under your chest, extending the other leg straight behind you. Lower your hips toward the floor. Switch sides halfway.'),
        StretchStep(
            name: 'Chest Doorframe Stretch', durationSeconds: 30, phase: StretchPhase.coolDown,
            instructions: 'Place your forearm against a doorframe with your elbow at shoulder height, then gently lean forward through the doorway until you feel a stretch across your chest. Switch sides halfway.'),
        StretchStep(
            name: 'Lat Side Stretch', durationSeconds: 30, phase: StretchPhase.coolDown,
            instructions: 'Reach one arm overhead and lean to the opposite side, letting the stretch run down the side of your torso. Keep hips square. Switch sides halfway.'),
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
        StretchStep(
            name: 'Cat-Cow', durationSeconds: 30, phase: StretchPhase.warmUp,
            instructions: 'On all fours, alternate between arching your back up like a cat (exhale) and dipping it down while lifting your head (inhale). Move slowly with your breath.'),
        StretchStep(
            name: 'Hip Circles', durationSeconds: 20, phase: StretchPhase.warmUp,
            instructions: 'Hands on hips, feet shoulder-width apart. Make big slow circles with your hips. Reverse direction halfway through.'),
        StretchStep(
            name: 'Thoracic Rotation', durationSeconds: 30, phase: StretchPhase.warmUp,
            instructions: 'On all fours, place one hand behind your head and rotate that elbow toward the ceiling, following it with your eyes. Switch sides halfway.'),
        StretchStep(
            name: 'Ankle Circles', durationSeconds: 20, phase: StretchPhase.warmUp,
            instructions: 'Balance on one foot (hold something if needed) and draw slow circles with the other foot. Switch feet and direction halfway through.'),
      ],
      coolDownStretches: const [
        StretchStep(
            name: 'Standing Hip Flexor Stretch', durationSeconds: 40, phase: StretchPhase.coolDown,
            instructions: 'Take a long stride stance, back heel up. Tuck your pelvis and bend the front knee until you feel a stretch in the front of the rear hip. Switch sides halfway.'),
        StretchStep(
            name: 'Figure-Four Glute Stretch', durationSeconds: 40, phase: StretchPhase.coolDown,
            instructions: 'Lying on your back, cross one ankle over the opposite knee, then pull that thigh toward your chest until you feel it in the glute. Switch sides halfway.'),
        StretchStep(
            name: "Child's Pose", durationSeconds: 40, phase: StretchPhase.coolDown,
            instructions: 'Kneel, sit back on your heels, and fold forward with arms extended on the floor in front of you. Let your forehead rest down and breathe deeply.'),
        StretchStep(
            name: 'Wrist Flexor Stretch', durationSeconds: 20, phase: StretchPhase.coolDown,
            instructions: 'Extend one arm palm-up and use the other hand to gently pull the fingers back and down. Switch sides halfway.'),
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
        StretchStep(
            name: 'Neck Rolls', durationSeconds: 20, phase: StretchPhase.warmUp,
            instructions: 'Slowly drop your ear toward one shoulder, roll your chin down across your chest, and up to the other side. Reverse direction halfway. Keep it gentle.'),
        StretchStep(
            name: 'Cross-Body Shoulder Stretch', durationSeconds: 30, phase: StretchPhase.warmUp,
            instructions: 'Pull one arm straight across your chest with the opposite hand, keeping the shoulder relaxed and down. Switch sides halfway.'),
        StretchStep(
            name: 'Spinal Twist', durationSeconds: 30, phase: StretchPhase.warmUp,
            instructions: 'Standing with arms out or seated, rotate your torso slowly to one side, then the other, keeping hips facing forward.'),
        StretchStep(
            name: 'Leg Swings', durationSeconds: 20, phase: StretchPhase.warmUp,
            instructions: 'Hold a wall and swing one leg forward and back in a relaxed arc, gradually increasing the range. Switch legs halfway.'),
      ],
      coolDownStretches: const [
        StretchStep(
            name: 'Overhead Tricep Stretch', durationSeconds: 30, phase: StretchPhase.coolDown,
            instructions: 'Reach one arm overhead, bend the elbow so your hand drops behind your neck, and gently push the elbow down with the other hand. Switch sides halfway.'),
        StretchStep(
            name: 'Standing Quad Stretch', durationSeconds: 30, phase: StretchPhase.coolDown,
            instructions: 'Grab one ankle behind you and pull your heel to your glutes, knees together, hips forward. Use a wall for balance. Switch sides halfway.'),
        StretchStep(
            name: 'Lower Back Twist', durationSeconds: 40, phase: StretchPhase.coolDown,
            instructions: 'Lying on your back with arms out, drop both knees to one side while keeping shoulders on the floor. Switch sides halfway.'),
        StretchStep(
            name: 'Deep Squat Hold', durationSeconds: 40, phase: StretchPhase.coolDown,
            instructions: 'Sink into a deep squat with heels down and feet slightly turned out. Use your elbows to gently press your knees outward. Hold and breathe.'),
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
