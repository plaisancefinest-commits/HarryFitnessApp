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
  bool _editMode = false;
  int? _reorderIndex;

  Future<bool> _confirmRemove(BuildContext context, String exerciseName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return AlertDialog(
          backgroundColor: c.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Remove Exercise',
              style: Theme.of(ctx).textTheme.titleMedium),
          content: Text('Remove "$exerciseName" from this workout?',
              style: Theme.of(ctx).textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('No', style: TextStyle(color: c.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes',
                  style: TextStyle(color: Color(0xFFE53935))),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _moveExercise(WorkoutProvider provider, int from, int to) {
    final exercises = provider.currentDay?.exercises;
    if (exercises == null) return;
    if (to < 0 || to >= exercises.length) return;
    provider.reorderExercises(from, to);
    setState(() => _reorderIndex = to);
  }

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

        // Clear reorder index if it's out of bounds
        if (_reorderIndex != null && _reorderIndex! >= exercises.length) {
          _reorderIndex = null;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: c.ink),
              onPressed: () {
                _reorderIndex = null;
                Navigator.pop(context);
              },
            ),
            title: Text('Workout Overview',
                style: Theme.of(context).textTheme.titleMedium),
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  _editMode = !_editMode;
                  _reorderIndex = null;
                }),
                child: Text(
                  _editMode ? 'Done' : 'Edit',
                  style: TextStyle(
                    color: _editMode ? const Color(0xFFE53935) : c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: c.accent,
            onPressed: () => _addExercise(provider),
            child: Icon(Icons.add, color: c.onAccent),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Tap empty space to exit reorder mode
              if (_reorderIndex != null) {
                setState(() => _reorderIndex = null);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: exercises.length,
              itemBuilder: (context, i) {
                final ex = exercises[i];
                final isCurrent = i == provider.currentExerciseIndex;
                final isComplete =
                    provider.isExerciseComplete(ex.exercise.id);
                final isReordering = _reorderIndex == i;

                return _ExerciseCard(
                  key: ValueKey(ex.id),
                  exercise: ex,
                  index: i,
                  totalCount: exercises.length,
                  isCurrent: isCurrent,
                  isComplete: isComplete,
                  isReordering: isReordering,
                  editMode: _editMode,
                  onTap: () {
                    if (_reorderIndex != null) {
                      // Tap any card while reordering → exit reorder mode
                      setState(() => _reorderIndex = null);
                      return;
                    }
                    if (_editMode) return;
                    if (i != provider.currentExerciseIndex) {
                      provider.jumpToExercise(i);
                    }
                    Navigator.pop(context);
                  },
                  onDoubleTap: () {
                    setState(() {
                      _reorderIndex = _reorderIndex == i ? null : i;
                    });
                  },
                  onLongPress: () async {
                    if (exercises.length <= 1) return;
                    final confirmed =
                        await _confirmRemove(context, ex.exercise.name);
                    if (confirmed && mounted) {
                      if (_reorderIndex == i) _reorderIndex = null;
                      provider.removeExerciseMidWorkout(i);
                      setState(() {});
                    }
                  },
                  onMoveUp: () => _moveExercise(provider, i, i - 1),
                  onMoveDown: () => _moveExercise(provider, i, i + 1),
                  onRemove: () async {
                    final confirmed =
                        await _confirmRemove(context, ex.exercise.name);
                    if (confirmed && mounted) {
                      if (_reorderIndex == i) _reorderIndex = null;
                      provider.removeExerciseMidWorkout(i);
                      setState(() {});
                    }
                  },
                  colors: c,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Individual exercise card with shake animation for reorder mode.
class _ExerciseCard extends StatefulWidget {
  final PlannedExercise exercise;
  final int index;
  final int totalCount;
  final bool isCurrent;
  final bool isComplete;
  final bool isReordering;
  final bool editMode;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final AppColors colors;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.totalCount,
    required this.isCurrent,
    required this.isComplete,
    required this.isReordering,
    required this.editMode,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPress,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.colors,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(begin: -0.012, end: 0.012).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    if (widget.isReordering) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReordering && !oldWidget.isReordering) {
      _shakeController.repeat(reverse: true);
    } else if (!widget.isReordering && oldWidget.isReordering) {
      _shakeController.stop();
      _shakeController.value = 0.5; // center position (no rotation)
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final ex = widget.exercise;

    Widget card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: widget.isReordering ? 6 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: widget.isReordering
            ? BorderSide(color: c.accent, width: 2)
            : widget.isCurrent
                ? BorderSide(color: c.accent, width: 2)
                : BorderSide.none,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.isReordering ? null : widget.onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Arrow buttons when in reorder mode
              if (widget.isReordering) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _arrowButton(
                      icon: Icons.keyboard_arrow_up_rounded,
                      enabled: widget.index > 0,
                      onTap: widget.onMoveUp,
                      colors: c,
                    ),
                    const SizedBox(height: 2),
                    _arrowButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      enabled: widget.index < widget.totalCount - 1,
                      onTap: widget.onMoveDown,
                      colors: c,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
              ],
              // Exercise info
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
                            color: widget.isComplete ? c.faint : c.ink,
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
              // Status / edit icons
              if (widget.editMode && widget.totalCount > 1)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.cancel,
                        color: Color(0xFFE53935), size: 22),
                  ),
                )
              else if (widget.isReordering)
                Icon(Icons.open_with_rounded, color: c.accent, size: 22)
              else if (widget.isComplete)
                Icon(Icons.check_circle, color: c.green, size: 22)
              else if (widget.isCurrent)
                Icon(Icons.play_circle_filled, color: c.accent, size: 22)
              else
                Icon(Icons.radio_button_unchecked,
                    color: c.borderStrong, size: 22),
            ],
          ),
        ),
      ),
    );

    // Wrap with shake animation when in reorder mode
    if (widget.isReordering) {
      return AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationZ(_shakeAnimation.value),
            child: child,
          );
        },
        child: card,
      );
    }

    return card;
  }

  Widget _arrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? colors.accent : colors.fill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? colors.onAccent : colors.faint,
        ),
      ),
    );
  }
}

class _AddExerciseSheet extends StatefulWidget {
  final List<Exercise> exercises;

  const _AddExerciseSheet({required this.exercises});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  MuscleGroup? _selectedGroup;

  Map<MuscleGroup, List<Exercise>> get _grouped {
    final map = <MuscleGroup, List<Exercise>>{};
    for (final e in widget.exercises) {
      for (final m in e.primaryMuscles) {
        map.putIfAbsent(m, () => []).add(e);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_selectedGroup == null) {
      return _buildGroupList(c);
    }
    return _buildExerciseList(c);
  }

  Widget _buildGroupList(AppColors c) {
    final groups = _grouped;
    // Sort muscle groups by name for consistency
    final sortedGroups = groups.keys.toList()
      ..sort((a, b) => _muscleName(a).compareTo(_muscleName(b)));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Add exercise',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...sortedGroups.map((group) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(_muscleName(group),
                      style: Theme.of(context).textTheme.titleMedium),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${groups[group]!.length}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: c.muted)),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: c.borderStrong),
                    ],
                  ),
                  onTap: () => setState(() => _selectedGroup = group),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExerciseList(AppColors c) {
    final exercises = _grouped[_selectedGroup] ?? [];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedGroup = null),
                child: Icon(Icons.arrow_back, color: c.ink, size: 22),
              ),
              const SizedBox(width: 12),
              Text(_muscleName(_selectedGroup!),
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          ...exercises.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(e.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  trailing: Icon(Icons.add_circle_outline,
                      color: c.borderStrong),
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
