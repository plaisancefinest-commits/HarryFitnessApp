import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/program.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';

/// Drill-down for a single planned exercise: prescription (sets, reps,
/// weight, rest), notes, target muscles, and how-to instructions.
class ExerciseDetailScreen extends StatelessWidget {
  final PlannedExercise planned;

  const ExerciseDetailScreen({super.key, required this.planned});

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

  static String _fmtRest(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return s == 0 ? '$m min' : '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final exercise = planned.exercise;
    final unit = context.watch<WorkoutProvider>().weightUnit;
    final unitLabel = unit == WeightUnit.kg ? 'kg' : 'lbs';

    String? weightText;
    final lbs = planned.targetWeightLbs;
    if (lbs != null) {
      final v = unit == WeightUnit.kg ? lbs / 2.20462 : lbs;
      weightText = '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} $unitLabel';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(exercise.name,
            style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Prescription
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRESCRIPTION',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(letterSpacing: 1.0)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Stat(label: 'Sets', value: '${planned.sets}'),
                      _Stat(label: 'Reps', value: '${planned.reps}'),
                      _Stat(label: 'Weight', value: weightText ?? '—'),
                      _Stat(
                          label: 'Rest',
                          value: planned.restSeconds != null
                              ? _fmtRest(planned.restSeconds!)
                              : '—'),
                    ],
                  ),
                  if (planned.notes != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      planned.notes!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: c.faint,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Muscles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MUSCLES',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text(
                    exercise.primaryMuscles.map(_muscleName).join(', '),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (exercise.secondaryMuscles.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Also: ${exercise.secondaryMuscles.map(_muscleName).join(', ')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Instructions
          if (exercise.instructions != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HOW TO',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Text(
                      exercise.instructions!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
