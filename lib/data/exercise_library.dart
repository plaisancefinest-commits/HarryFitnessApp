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
    id: 'smith_bench_press',
    name: 'Smith Machine Flat Bench Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
    instructions:
        'Lie flat on the bench with the bar lined up over your mid-chest. Grip just outside shoulder width. '
        'Unrack by rotating the hooks, lower the bar to your chest with a controlled eccentric, and pause briefly at the chest. '
        'Press back up until arms are fully extended. The fixed bar path lets you focus on driving through the chest.',
  ),
  const Exercise(
    id: 'smith_incline_press',
    name: 'Smith Machine Incline Bench Press',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
    instructions:
        'Set the bench to roughly a 30° incline under the Smith bar, lined up with your upper chest. '
        'Grip just outside shoulder width, unrack, and lower the bar to your upper chest with control. '
        'Press back up until arms are extended. Keep your feet flat and lower back against the pad.',
  ),
  const Exercise(
    id: 'pec_deck_fly',
    name: 'Pec Deck Fly',
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.shoulders],
    instructions:
        'Sit with your back flat against the pad, forearms or hands on the handles at chest height. '
        'Squeeze your chest to bring the handles together in front of you. '
        'Hold the squeeze at the peak for a beat, then return slowly with a controlled negative. '
        'Keep your shoulders back and down throughout.',
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
    id: 'smith_row',
    name: 'Smith Machine Bent-Over Row',
    primaryMuscles: [MuscleGroup.back],
    secondaryMuscles: [MuscleGroup.biceps],
    instructions:
        'Stand over the Smith bar with feet hip-width apart and hinge at the hips until your torso is close to parallel. '
        'Take an overhand grip just outside your knees. '
        'Pull the bar to your lower chest, driving elbows back and squeezing your shoulder blades. '
        'Lower with control. Keep your back flat the entire set.',
  ),
  const Exercise(
    id: 'db_single_arm_row',
    name: 'Dumbbell Single-Arm Row',
    primaryMuscles: [MuscleGroup.back],
    secondaryMuscles: [MuscleGroup.biceps],
    instructions:
        'Place one knee and the same-side hand on a bench, holding a dumbbell in the other hand. '
        'Let the dumbbell hang for a full stretch at the bottom. '
        'Row the dumbbell up to your hip, driving the elbow back and keeping your torso square. '
        'Lower slowly back to the full stretch. Complete all reps, then switch sides.',
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
    id: 'seated_db_press',
    name: 'Dumbbell Overhead Press (Seated)',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.triceps],
    instructions:
        'Sit on an upright bench with dumbbells at shoulder height, palms facing forward or in a neutral grip. '
        'Press both dumbbells overhead until your arms are extended, without clanging them together. '
        'Lower back to shoulder height with control. '
        'Keep your lower back against the pad and core braced — no arching.',
  ),
  const Exercise(
    id: 'rear_delt_fly',
    name: 'DB Rear Delt Fly',
    primaryMuscles: [MuscleGroup.shoulders],
    secondaryMuscles: [MuscleGroup.back],
    instructions:
        'Hinge forward at the hips with light dumbbells hanging below your chest, slight bend in the elbows. '
        'Raise the dumbbells out to the sides until they reach shoulder height, leading with your elbows. '
        'Focus on the contraction in your rear delts — not momentum. '
        'Lower slowly. Go lighter than you think; this is a contraction exercise.',
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
    id: 'db_curl',
    name: 'Dumbbell Curl',
    primaryMuscles: [MuscleGroup.biceps],
    secondaryMuscles: [MuscleGroup.forearms],
    instructions:
        'Stand holding dumbbells at your sides with an underhand grip. '
        'Keeping your elbows pinned to your sides, curl the dumbbells up toward your shoulders. '
        'Squeeze the biceps at the top, then lower slowly back to the start. '
        'No swinging — if you have to rock your body, the weight is too heavy.',
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
    id: 'db_overhead_tricep_extension',
    name: 'Dumbbell Overhead Tricep Extension',
    primaryMuscles: [MuscleGroup.triceps],
    secondaryMuscles: [],
    instructions:
        'Sit or stand holding one dumbbell with both hands overhead, arms extended. '
        'Lower the dumbbell behind your head by bending only at the elbows, keeping them pointed forward. '
        'Extend back up and squeeze the triceps hard at lockout. '
        'Keep your upper arms still — only the forearms move.',
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
    id: 'smith_squat',
    name: 'Smith Machine Squat',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.core],
    instructions:
        'Set the bar across your upper traps and place your feet slightly forward of the bar. '
        'Brace your core and sit back and down, keeping your chest up. '
        'Descend only through a pain-free range of motion — depth is earned, not forced. '
        'Drive through your heels to stand back up.',
  ),
  const Exercise(
    id: 'smith_rdl',
    name: 'Smith Machine Romanian Deadlift',
    primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.back],
    instructions:
        'Stand holding the Smith bar at hip height, feet hip-width apart. '
        'Hinge at the hips, pushing them back as the bar travels down your legs. '
        'Keep a slight bend in your knees and your back flat — you should feel a strong hamstring stretch. '
        'Drive your hips forward to return to standing and squeeze your glutes at the top.',
  ),
  const Exercise(
    id: 'leg_extension',
    name: 'Leg Extension',
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [],
    instructions:
        'Sit in the machine with the pad on your shins just above the ankles. '
        'Extend your legs until they are fully straight, squeezing the quads hard at the top. '
        'Lower with control — do not let the stack slam. '
        'Keep your back against the pad and grip the handles for stability.',
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
    id: 'smith_calf_raise',
    name: 'Standing Calf Raise (Smith)',
    primaryMuscles: [MuscleGroup.calves],
    secondaryMuscles: [],
    instructions:
        'Stand under the Smith bar with the balls of your feet on a block or plate, heels hanging off. '
        'Rise up onto your toes as high as possible, squeezing the calves at the top. '
        'Lower slowly until your heels drop below the platform for a full stretch at the bottom. '
        'Keep your knees nearly straight throughout.',
  ),
  const Exercise(
    id: 'db_walking_lunge',
    name: 'Dumbbell Walking Lunge',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    instructions:
        'Hold dumbbells at your sides and step forward into a lunge, lowering your back knee toward the floor. '
        'Front thigh parallel to the floor, front knee over your ankle. '
        'Push through the front heel and step straight into the next lunge with the other leg. '
        'If your hip flares up, stop and substitute a goblet squat to a box.',
  ),
  const Exercise(
    id: 'db_step_up',
    name: 'Dumbbell Step-Up',
    primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
    secondaryMuscles: [MuscleGroup.hamstrings],
    instructions:
        'Hold dumbbells at your sides facing a bench or box. '
        'Place one full foot on the bench and drive through the front heel to step up — '
        'no push-off from the back foot. '
        'Lower back down with control. Complete all reps on one leg, then switch.',
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
