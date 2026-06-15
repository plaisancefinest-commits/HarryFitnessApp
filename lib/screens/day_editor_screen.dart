import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/program.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/add_activity_dialog.dart';

/// Edit one day of a custom program: add/remove exercises and set
/// sets / reps / target weight / rest / notes per exercise.
/// Pops with the updated [WorkoutDay].
class DayEditorScreen extends StatefulWidget {
  final WorkoutDay day;

  const DayEditorScreen({super.key, required this.day});

  @override
  State<DayEditorScreen> createState() => _DayEditorScreenState();
}

class _ExerciseDraft {
  final String id;
  Exercise exercise;
  int sets;
  int reps;
  double? weightLbs;
  int? restSeconds;
  String? notes;

  _ExerciseDraft({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    this.weightLbs,
    this.restSeconds,
    this.notes,
  });
}

class _DayEditorScreenState extends State<DayEditorScreen> {
  static const _uuid = Uuid();
  late final List<_ExerciseDraft> _drafts;
  late final List<PlannedActivity> _activities;

  @override
  void initState() {
    super.initState();
    _activities = [...widget.day.activities];
    _drafts = widget.day.exercises
        .map((pe) => _ExerciseDraft(
              id: pe.id,
              exercise: pe.exercise,
              sets: pe.sets,
              reps: pe.reps,
              weightLbs: pe.targetWeightLbs,
              restSeconds: pe.restSeconds,
              notes: pe.notes,
            ))
        .toList();
  }

  WorkoutDay _buildDay() {
    final totalSets = _drafts.fold<int>(0, (sum, d) => sum + d.sets);
    return WorkoutDay(
      id: widget.day.id,
      name: widget.day.name,
      description: widget.day.description,
      estimatedMinutes: (totalSets * 3 + 10).clamp(15, 150),
      exercises: [
        for (var i = 0; i < _drafts.length; i++)
          PlannedExercise(
            id: _drafts[i].id,
            exercise: _drafts[i].exercise,
            sets: _drafts[i].sets,
            reps: _drafts[i].reps,
            order: i,
            targetWeightLbs: _drafts[i].weightLbs,
            restSeconds: _drafts[i].restSeconds,
            notes: (_drafts[i].notes?.trim().isEmpty ?? true)
                ? null
                : _drafts[i].notes!.trim(),
          ),
      ],
      activities: [..._activities],
    );
  }

  Future<void> _addActivity() async {
    final result = await showDialog<PlannedActivity>(
      context: context,
      builder: (context) => const AddActivityDialog(),
    );
    if (result != null) {
      setState(() => _activities.add(result));
    }
  }

  void _pop() => Navigator.pop(context, _buildDay());

  Future<void> _addExercise() async {
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: context.colors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _ExercisePickerSheet(),
    );
    if (picked != null) {
      setState(() {
        _drafts.add(_ExerciseDraft(
          id: _uuid.v4(),
          exercise: picked,
          sets: 3,
          reps: 10,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unit = context.watch<WorkoutProvider>().weightUnit;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: c.ink),
            onPressed: _pop,
          ),
          title: Text(widget.day.name,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_drafts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No exercises yet — add your first one.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (var i = 0; i < _drafts.length; i++)
              _ExerciseEditorCard(
                key: ValueKey(_drafts[i].id),
                draft: _drafts[i],
                unit: unit,
                onRemove: () => setState(() => _drafts.removeAt(i)),
                onChanged: () => setState(() {}),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: Icon(Icons.add, size: 18, color: c.ink),
              label: Text('Add Exercise',
                  style: TextStyle(color: c.ink)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: c.border),
              ),
            ),
            const SizedBox(height: 24),
            Text('ACTIVITIES',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.0)),
            const SizedBox(height: 8),
            if (_activities.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Optional extras for this day — sauna, swim, run or walk.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ..._activities.map((a) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${a.label} · ${a.minutes} min',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: c.muted),
                          tooltip: 'Remove activity',
                          onPressed: () =>
                              setState(() => _activities.remove(a)),
                        ),
                      ],
                    ),
                  ),
                )),
            OutlinedButton.icon(
              onPressed: _addActivity,
              icon: Icon(Icons.add, size: 18, color: c.ink),
              label: Text('Add Activity',
                  style: TextStyle(color: c.ink)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: c.border),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Exercise editor card ─────────────────────────────────────────────────────

class _ExerciseEditorCard extends StatefulWidget {
  final _ExerciseDraft draft;
  final WeightUnit unit;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExerciseEditorCard({
    super.key,
    required this.draft,
    required this.unit,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ExerciseEditorCard> createState() => _ExerciseEditorCardState();
}

class _ExerciseEditorCardState extends State<_ExerciseEditorCard> {
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _restCtrl;
  late final TextEditingController _notesCtrl;

  double? get _displayWeight {
    final lbs = widget.draft.weightLbs;
    if (lbs == null) return null;
    return widget.unit == WeightUnit.kg ? lbs / kLbsPerKg : lbs;
  }

  String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _setsCtrl = TextEditingController(text: '${d.sets}');
    _repsCtrl = TextEditingController(text: '${d.reps}');
    _weightCtrl = TextEditingController(
        text: _displayWeight != null ? _fmt(_displayWeight!) : '');
    _restCtrl = TextEditingController(
        text: d.restSeconds != null ? '${d.restSeconds}' : '');
    _notesCtrl = TextEditingController(text: d.notes ?? '');
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _restCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.unit == WeightUnit.lbs ? 'lbs' : 'kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.draft.exercise.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: context.colors.muted),
                  tooltip: 'Remove exercise',
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _NumberField(
                  label: 'Sets',
                  controller: _setsCtrl,
                  onChanged: (v) {
                    widget.draft.sets = (int.tryParse(v) ?? 3).clamp(1, 10);
                    widget.onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _NumberField(
                  label: 'Reps',
                  controller: _repsCtrl,
                  onChanged: (v) {
                    widget.draft.reps = (int.tryParse(v) ?? 10).clamp(1, 100);
                    widget.onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _NumberField(
                  label: 'Weight ($unitLabel)',
                  controller: _weightCtrl,
                  decimal: true,
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed == null) {
                      widget.draft.weightLbs = null;
                    } else {
                      widget.draft.weightLbs = widget.unit == WeightUnit.kg
                          ? parsed * kLbsPerKg
                          : parsed;
                    }
                    widget.onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _NumberField(
                  label: 'Rest (sec)',
                  controller: _restCtrl,
                  onChanged: (v) {
                    widget.draft.restSeconds = int.tryParse(v);
                    widget.onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              onChanged: (v) {
                widget.draft.notes = v;
                widget.onChanged();
              },
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Notes (form cues, warm-up sets…)',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            style: TextStyle(fontSize: 14, color: c.ink),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              filled: true,
              fillColor: c.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise picker ──────────────────────────────────────────────────────────

class _ExercisePickerSheet extends StatelessWidget {
  const _ExercisePickerSheet();

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

  @override
  Widget build(BuildContext context) {
    // Group the library by first primary muscle, in enum order.
    final groups = <MuscleGroup, List<Exercise>>{};
    for (final e in exerciseLibrary) {
      groups.putIfAbsent(e.primaryMuscles.first, () => []).add(e);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Add exercise', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final entry in groups.entries) ...[
            Text(_muscleName(entry.key).toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.0)),
            const SizedBox(height: 8),
            ...entry.value.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(e.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    trailing: Icon(Icons.chevron_right,
                        color: context.colors.borderStrong),
                    onTap: () => Navigator.pop(context, e),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
