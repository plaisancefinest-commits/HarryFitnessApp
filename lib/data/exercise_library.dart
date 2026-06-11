import '../models/exercise.dart';

final exerciseLibrary = <Exercise>[
  // Chest
  const Exercise(
    id: 'bench_press',
    name: 'Bench Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
    instructions:
        'Lie flat on the bench with feet on the floor. Grip the bar just outside shoulder width. '
        'Lower the bar to your mid-chest with control, keeping elbows at roughly 45°. '
        'Press the bar back up explosively until arms are fully extended. Keep your back flat and core tight throughout.',
  ),
  const Exercise(
    id: 'db_flyes',
    name: 'DB Flies',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders],
    instructions:
        'Lie on a flat bench holding dumbbells directly above your chest, palms facing each other. '
        'With a slight bend in your elbows, lower the dumbbells in a wide arc until you feel a stretch in your chest. '
        'Squeeze your chest to bring the dumbbells back up along the same arc. Do not lock out the elbows at the top.',
  ),
  const Exercise(
    id: 'incline_press',
    name: 'Incline Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
    instructions:
        'Set the bench to a 30–45° incline. Grip the bar just outside shoulder width. '
        'Lower the bar to your upper chest with control. '
        'Press back up until arms are extended. Keep your feet flat and lower back against the pad.',
  ),
  const Exercise(
    id: 'push_up',
    name: 'Push Up',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
    instructions:
        'Start in a high plank with hands slightly wider than shoulder width. '
        'Keep your body in a straight line from head to heels — no sagging hips. '
        'Lower your chest to just above the floor, then push back up. '
        'If needed, drop to your knees while keeping a straight back.',
  ),

  // Back
  const Exercise(
    id: 'lat_pulldown',
    name: 'Lat Pulldown',
    primaryMuscles: [MuscleGroup.back],
    secondaryMuscles: [MuscleGroup.biceps],
    instructions:
        'Sit at the cable machine and grip the bar wider than shoulder width, palms facing away. '
        'Lean back slightly and pull the bar down to your upper chest, squeezing your lats. '
        'Control the bar back up slowly until arms are fully extended. '
        'Avoid using momentum — let your back do the work.',
  ),
  const Exercise(
    id: 'bent_over_row',
    name: 'Bent Over Row',
    primaryMuscles: [MuscleGroup.back],
    secondaryMuscles: [MuscleGroup.biceps],
    instructions:
        'Stand with feet hip-width apart, hinge at the hips until your torso is nearly parallel to the floor. '
        'Grip the bar just outside your knees. Pull the bar to your lower ribcage, driving elbows back. '
        'Squeeze your shoulder blades at the top, then lower with control. Keep your back flat throughout.',
  ),
  const Exercise(
    id: 'seated_cable_row',
    name: 'Seated Cable Row',
    primaryMuscles: [MuscleGroup.back],
    secondaryMuscles: [MuscleGroup.biceps],
    instructions:
        'Sit upright at the cable row machine with feet on the platform and knees slightly bent. '
        'Pull the handle to your lower abdomen, driving elbows straight back. '
        'Squeeze your shoulder blades together at the end of the movement. '
        'Slowly extend arms back to the start — do not round your lower back.',
  ),
  const Exercise(
    id: 'deadlift',
    name: 'Deadlift',
    primaryMuscles: [MuscleGroup.back, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.core],
    instructions:
        'Stand with feet hip-width apart, bar over mid-foot. Hinge down and grip the bar just outside your legs. '
        'Take a deep breath, brace your core, and drive through the floor to stand up. '
        'Keep the bar close to your body the entire way. Lock out hips and knees at the top. '
        'Lower back down by hinging at the hips first, then bending the knees.',
  ),

  // Shoulders
  const Exercise(
    id: 'overhead_press',
    name: 'Overhead Press',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.triceps],
    instructions:
        'Stand with feet shoulder-width apart, bar resting on your upper chest, grip just outside shoulder width. '
        'Press the bar directly overhead, moving your head back slightly to clear your chin. '
        'Lock out your arms at the top, then lower the bar back to your chest with control. '
        'Keep your core braced and avoid arching your lower back.',
  ),
  const Exercise(
    id: 'lateral_raise',
    name: 'Lateral Raise',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [],
    instructions:
        'Stand holding dumbbells at your sides, slight bend in your elbows. '
        'Raise both arms out to the side until they reach shoulder height, leading with your elbows. '
        'Pause briefly at the top, then lower slowly. '
        'Avoid shrugging your traps — keep tension on the side delts.',
  ),
  const Exercise(
    id: 'face_pull',
    name: 'Face Pull',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.back],
    instructions:
        'Set a cable at face height with a rope attachment. Stand back and grip the rope with both hands. '
        'Pull the rope toward your face, separating your hands as you pull back. '
        'Elbows should flare out and finish higher than your hands. '
        'Squeeze at the end of the movement, then return slowly.',
  ),

  // Arms
  const Exercise(
    id: 'barbell_curl',
    name: 'Barbell Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    instructions:
        'Stand holding a barbell with an underhand grip, hands shoulder-width apart. '
        'Keeping your elbows pinned to your sides, curl the bar up toward your shoulders. '
        'Squeeze the biceps at the top, then lower slowly back to the start. '
        'Avoid swinging your body to generate momentum.',
  ),
  const Exercise(
    id: 'hammer_curl',
    name: 'Hammer Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    instructions:
        'Hold dumbbells at your sides with palms facing each other (neutral grip). '
        'Curl one or both dumbbells up toward your shoulder, keeping the neutral grip throughout. '
        'Squeeze at the top and lower with control. '
        'Keep elbows stationary — do not let them drift forward.',
  ),
  const Exercise(
    id: 'tricep_pushdown',
    name: 'Tricep Pushdown',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [],
    instructions:
        'Stand at a cable machine with a bar or rope attachment set at head height. '
        'Grip the attachment with elbows tucked at your sides. '
        'Push down until your arms are fully extended, squeezing the triceps. '
        'Return slowly to the start — keep elbows fixed throughout.',
  ),
  const Exercise(
    id: 'skull_crusher',
    name: 'Skull Crusher',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [],
    instructions:
        'Lie on a bench holding an EZ-bar or dumbbells directly above your chest, arms extended. '
        'Lower the weight toward your forehead by bending only at the elbows. '
        'Stop just before the weight reaches your head, then extend back up. '
        'Keep your upper arms perpendicular to the floor throughout.',
  ),

  // Legs
  const Exercise(
    id: 'squat',
    name: 'Squat',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.core],
    instructions:
        'Stand with feet shoulder-width apart, bar across your upper traps. '
        'Brace your core, take a breath, and sit back and down, keeping your chest up. '
        'Descend until your thighs are parallel to the floor (or as low as mobility allows). '
        'Drive through your heels to stand back up. Knees should track over your toes.',
  ),
  const Exercise(
    id: 'romanian_deadlift',
    name: 'Romanian Deadlift',
    primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.back],
    instructions:
        'Stand holding a barbell at hip height, feet hip-width apart. '
        'Hinge at the hips, pushing them back as you lower the bar down your legs. '
        'Keep a slight bend in your knees and your back flat. Lower until you feel a strong hamstring stretch. '
        'Drive your hips forward to return to standing — squeeze glutes at the top.',
  ),
  const Exercise(
    id: 'leg_press',
    name: 'Leg Press',
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
    instructions:
        'Sit in the leg press machine with feet shoulder-width apart on the platform. '
        'Lower the platform until your knees reach roughly 90°. '
        'Press through your heels to extend your legs, stopping just before locking out. '
        'Keep your lower back flat against the seat throughout.',
  ),
  const Exercise(
    id: 'leg_curl',
    name: 'Leg Curl',
    primaryMuscles: [MuscleGroup.hamstrings],
    secondaryMuscles: [],
    instructions:
        'Lie face down on the leg curl machine with the pad just above your heels. '
        'Curl your legs up toward your glutes as far as possible. '
        'Squeeze the hamstrings at the top, then lower slowly. '
        'Avoid lifting your hips off the pad.',
  ),
  const Exercise(
    id: 'calf_raise',
    name: 'Calf Raise',
    primaryMuscles: [MuscleGroup.calves],
    secondaryMuscles: [],
    instructions:
        'Stand on the edge of a step or calf raise platform, heels hanging off. '
        'Rise up onto your toes as high as possible, squeezing the calves. '
        'Slowly lower your heels below the platform level for a full stretch. '
        'Keep a slight bend in your knees throughout.',
  ),
  const Exercise(
    id: 'lunge',
    name: 'Lunge',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    instructions:
        'Stand with feet together. Step one foot forward and lower your back knee toward the floor. '
        'Front thigh should be parallel to the floor, front knee over your ankle. '
        'Push through the front heel to return to standing. Alternate legs each rep. '
        'Keep your torso upright throughout.',
  ),

  // Core
  const Exercise(
    id: 'plank',
    name: 'Plank',
    primaryMuscles: [MuscleGroup.core],
    secondaryMuscles: [],
    instructions:
        'Start in a forearm plank position — elbows under shoulders, body in a straight line. '
        'Squeeze your abs, glutes, and quads. Do not let your hips sag or rise. '
        'Breathe steadily and hold for the prescribed duration. '
        'Each "rep" counts as one hold of the target time.',
  ),
  const Exercise(
    id: 'crunch',
    name: 'Crunch',
    primaryMuscles: [MuscleGroup.core],
    secondaryMuscles: [],
    instructions:
        'Lie on your back with knees bent, feet flat on the floor. '
        'Place hands lightly behind your head — do not pull on your neck. '
        'Curl your upper back off the floor by contracting your abs. '
        'Pause at the top, then lower with control. Keep your lower back on the floor throughout.',
  ),
];
