import 'package:flutter/material.dart';
import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/program.dart';
import '../services/database_service.dart';

/// Full view of a workout day: every exercise with sets × reps and target
/// muscles. Each exercise can be swapped for another from the library.
class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutDay day;

  const WorkoutDetailScreen({super.key, required this.day});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
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
      backgroundColor: const Color(0xFFF7F5F2),
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

  @override
  Widget build(BuildContext context) {
    final exercises = [...widget.day.exercises]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.day.name} · ${widget.day.description}',
            style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.day.warmUpStretches.isNotEmpty)
            _PhaseCard(
              label: 'WARM UP',
              lines: widget.day.warmUpStretches
                  .map((s) => '${s.name} · ${s.durationSeconds}s')
                  .toList(),
            ),
          const SizedBox(height: 12),
          ...exercises.map((pe) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pe.exercise.name,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '${pe.sets} sets × ${pe.reps} reps · ${_muscleNames(pe.exercise)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz,
                            color: Color(0xFF6B6B6B), size: 20),
                        tooltip: 'Swap exercise',
                        onPressed: () => _swapExercise(pe),
                      ),
                    ],
                  ),
                ),
              )),
          if (widget.day.coolDownStretches.isNotEmpty)
            _PhaseCard(
              label: 'COOL DOWN',
              lines: widget.day.coolDownStretches
                  .map((s) => '${s.name} · ${s.durationSeconds}s')
                  .toList(),
            ),
        ],
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
            const Icon(Icons.chevron_right, color: Color(0xFFCCC8C2)),
        onTap: () => Navigator.pop(context, exercise),
      ),
    );
  }
}
