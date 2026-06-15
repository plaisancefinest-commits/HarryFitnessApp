import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/program.dart';
import '../providers/workout_provider.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/add_activity_dialog.dart';
import 'exercise_detail_screen.dart';

/// Full view of a workout day: every exercise with sets × reps and target
/// muscles. Exercises can be swapped, dragged into a new order (persisted),
/// and tapped to drill down into the full prescription.
class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutDay day;

  const WorkoutDetailScreen({super.key, required this.day});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late List<PlannedExercise> _exercises;
  late List<PlannedActivity> _activities;

  @override
  void initState() {
    super.initState();
    _exercises = [...widget.day.exercises]
      ..sort((a, b) => a.order.compareTo(b.order));
    _activities = [...widget.day.activities];
    _loadActivityOverride();
  }

  Future<void> _loadActivityOverride() async {
    final overrides =
        await DatabaseService.instance.getActivityOverrides();
    final override = overrides[widget.day.id];
    if (override != null && mounted) {
      setState(() => _activities = override);
    }
  }

  Future<void> _addActivity() async {
    final result = await showDialog<PlannedActivity>(
      context: context,
      builder: (context) => const AddActivityDialog(),
    );
    if (result != null) {
      setState(() => _activities.add(result));
      await DatabaseService.instance
          .saveActivityOverride(widget.day.id, _activities);
    }
  }

  Future<void> _removeActivity(PlannedActivity a) async {
    setState(() => _activities.remove(a));
    await DatabaseService.instance
        .saveActivityOverride(widget.day.id, _activities);
  }

  Future<void> _logActivity(PlannedActivity a) async {
    final db = DatabaseService.instance;
    if (a.countsAsCardio) {
      await db.addCardioEntry(DateTime.now(), a.minutes, a.label);
    } else {
      await db.addSaunaEntry(DateTime.now(), a.minutes, a.label);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(a.countsAsCardio
              ? '${a.label} · ${a.minutes} min logged to zone-2 cardio.'
              : 'Sauna · ${a.minutes} min logged.')));
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
      for (var i = 0; i < _exercises.length; i++) {
        _exercises[i].order = i;
      }
      // Keep the shared day object in sync so "Start Workout" follows
      // the new order immediately.
      widget.day.exercises
        ..clear()
        ..addAll(_exercises);
    });
    DatabaseService.instance.saveExerciseOrder(
        widget.day.id, _exercises.map((e) => e.id).toList());
  }

  String _muscleNames(Exercise e) =>
      e.primaryMuscles.map(_muscleName).join(', ');

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

  Future<void> _swapExercise(PlannedExercise planned) async {
    final current = planned.exercise;
    // Exercises hitting the same primary muscles first, then the rest
    final similar = exerciseLibrary
        .where((e) =>
            e.id != current.id &&
            e.primaryMuscles.any(current.primaryMuscles.contains))
        .toList();
    final others = exerciseLibrary
        .where((e) => e.id != current.id && !similar.contains(e))
        .toList();

    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: context.colors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SwapSheet(similar: similar, others: others),
    );

    if (picked != null) {
      setState(() => planned.exercise = picked);
      await DatabaseService.instance.saveExerciseOverride(planned.id, picked.id);
    }
  }

  String _setLine(PlannedExercise pe, WeightUnit unit) {
    var line = '${pe.sets} sets × ${pe.reps} reps';
    final lbs = pe.targetWeightLbs;
    if (lbs != null) {
      final v = unit == WeightUnit.kg ? lbs / kLbsPerKg : lbs;
      final label = unit == WeightUnit.kg ? 'kg' : 'lbs';
      line += ' @ ${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} $label';
    }
    return '$line · ${_muscleNames(pe.exercise)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unit = context.watch<WorkoutProvider>().weightUnit;
    final exercises = _exercises;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.day.name} · ${widget.day.description}',
            style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.all(24),
        onReorder: _onReorder,
        buildDefaultDragHandles: false,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.day.warmUpStretches.isNotEmpty) ...[
              _PhaseCard(
                label: 'WARM UP',
                lines: widget.day.warmUpStretches
                    .map((s) => '${s.name} · ${s.durationSeconds}s')
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Hold the handle to drag exercises into a new order.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActivitiesCard(
              activities: _activities,
              onAdd: _addActivity,
              onRemove: _removeActivity,
              onLog: _logActivity,
            ),
            if (widget.day.coolDownStretches.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PhaseCard(
                label: 'COOL DOWN',
                lines: widget.day.coolDownStretches
                    .map((s) => '${s.name} · ${s.durationSeconds}s')
                    .toList(),
              ),
            ],
          ],
        ),
        children: [
          for (var i = 0; i < exercises.length; i++)
            Card(
              key: ValueKey(exercises[i].id),
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ExerciseDetailScreen(planned: exercises[i]),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                            Text(exercises[i].exercise.name,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              _setLine(exercises[i], unit),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (exercises[i].notes != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                exercises[i].notes!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: c.faint,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.swap_horiz,
                            color: c.muted, size: 20),
                        tooltip: 'Swap exercise',
                        onPressed: () => _swapExercise(exercises[i]),
                      ),
                      Icon(Icons.chevron_right, color: c.borderStrong),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivitiesCard extends StatelessWidget {
  final List<PlannedActivity> activities;
  final VoidCallback onAdd;
  final ValueChanged<PlannedActivity> onRemove;
  final ValueChanged<PlannedActivity> onLog;

  const _ActivitiesCard({
    required this.activities,
    required this.onAdd,
    required this.onRemove,
    required this.onLog,
  });

  static IconData _icon(ActivityType t) {
    switch (t) {
      case ActivityType.sauna:
        return Icons.hot_tub_outlined;
      case ActivityType.swim:
        return Icons.pool_outlined;
      case ActivityType.run:
        return Icons.directions_run;
      case ActivityType.walk:
        return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVITIES',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(letterSpacing: 1.0)),
                GestureDetector(
                  onTap: onAdd,
                  child: Icon(Icons.add_circle_outline,
                      size: 18, color: c.ink),
                ),
              ],
            ),
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Nothing extra today — tap + to add a sauna, swim, run or walk.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ...activities.map((a) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(_icon(a.type), size: 20, color: c.muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('${a.label} · ${a.minutes} min',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      TextButton(
                        onPressed: () => onLog(a),
                        child: Text('Log',
                            style: TextStyle(
                                color: c.data,
                                fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: c.faint),
                        tooltip: 'Remove for today',
                        onPressed: () => onRemove(a),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final String label;
  final List<String> lines;

  const _PhaseCard({required this.label, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.0)),
            const SizedBox(height: 8),
            ...lines.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child:
                      Text(l, style: Theme.of(context).textTheme.bodyMedium),
                )),
          ],
        ),
      ),
    );
  }
}

class _SwapSheet extends StatelessWidget {
  final List<Exercise> similar;
  final List<Exercise> others;

  const _SwapSheet({required this.similar, required this.others});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Swap exercise',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (similar.isNotEmpty) ...[
            Text('SAME MUSCLE GROUP',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.0)),
            const SizedBox(height: 8),
            ...similar.map((e) => _ExerciseTile(exercise: e)),
            const SizedBox(height: 16),
          ],
          if (others.isNotEmpty) ...[
            Text('EVERYTHING ELSE',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.0)),
            const SizedBox(height: 8),
            ...others.map((e) => _ExerciseTile(exercise: e)),
          ],
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(exercise.name,
            style: Theme.of(context).textTheme.titleMedium),
        trailing:
            Icon(Icons.chevron_right, color: context.colors.borderStrong),
        onTap: () => Navigator.pop(context, exercise),
      ),
    );
  }
}
