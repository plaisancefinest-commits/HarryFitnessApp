import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/program.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';

/// Full workout overview accessible mid-session. Allows reordering exercises,
/// adding new exercises, and jumping to a specific exercise.
class ActiveWorkoutOverviewScreen extends StatefulWidget {
  const ActiveWorkoutOverviewScreen({super.key});

  @override
  State<ActiveWorkoutOverviewScreen> createState() =>
      _ActiveWorkoutOverviewScreenState();
}

class _ActiveWorkoutOverviewScreenState
    extends State<ActiveWorkoutOverviewScreen> {
  Future<void> _addExercise(WorkoutProvider provider) async {
    final exercises = provider.currentDay?.exercises ?? [];
    final usedIds = exercises.map((e) => e.exercise.id).toSet();

    final others = <Exercise>[];
    for (final e in exerciseLibrary) {
      if (usedIds.contains(e.id)) continue;
      others.add(e);
    }

    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: context.colors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddExerciseSheet(exercises: others),
    );

    if (picked != null) {
      final planned = PlannedExercise(
        id: const Uuid().v4(),
        exercise: picked,
        sets: 3,
        reps: 10,
        order: exercises.length,
      );
      provider.addExerciseMidWorkout(planned);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final day = provider.currentDay;
        if (day == null) return const SizedBox.shrink();
        final exercises = day.exercises;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: c.ink),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Workout Overview',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: c.accent,
            onPressed: () => _addExercise(provider),
            child: Icon(Icons.add, color: c.onAccent),
          ),
          body: ReorderableListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: exercises.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              provider.reorderExercises(oldIndex, newIndex);
            },
            itemBuilder: (context, i) {
              final ex = exercises[i];
              final isCurrent = i == provider.currentExerciseIndex;
              final isComplete =
                  provider.isExerciseComplete(ex.exercise.id);

              return Card(
                key: ValueKey(ex.id),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isCurrent
                      ? BorderSide(color: c.accent, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    provider.jumpToExercise(i);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.drag_indicator,
                                color: c.borderStrong, size: 20),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.exercise.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: isComplete ? c.faint : c.ink,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ex.sets} sets × ${ex.reps} reps',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        if (isComplete)
                          Icon(Icons.check_circle, color: c.green, size: 22)
                        else if (isCurrent)
                          Icon(Icons.play_circle_filled,
                              color: c.accent, size: 22)
                        else
                          Icon(Icons.radio_button_unchecked,
                              color: c.borderStrong, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AddExerciseSheet extends StatelessWidget {
  final List<Exercise> exercises;

  const _AddExerciseSheet({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Add exercise',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...exercises.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(e.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(
                    e.primaryMuscles.map(_muscleName).join(', '),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: context.colors.muted),
                  ),
                  trailing: Icon(Icons.add_circle_outline,
                      color: context.colors.borderStrong),
                  onTap: () => Navigator.pop(context, e),
                ),
              )),
        ],
      ),
    );
  }

  static String _muscleName(MuscleGroup g) {
    switch (g) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.quads:
        return 'Quads';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
    }
  }
}
