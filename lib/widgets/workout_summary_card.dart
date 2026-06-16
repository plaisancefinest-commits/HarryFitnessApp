import 'package:flutter/material.dart';
import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/personal_record.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';

/// Compact post-workout exercise summary shown on the complete screen.
class WorkoutSummaryCard extends StatelessWidget {
  final List<ExerciseSummary> summaries;
  final WeightUnit unit;

  const WorkoutSummaryCard({
    super.key,
    required this.summaries,
    required this.unit,
  });

  String _fmtWeight(double lbs) {
    final v = unit == WeightUnit.kg ? lbs / kLbsPerKg : lbs;
    return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }

  String _fmtVolume(double lbs) {
    final v = unit == WeightUnit.kg ? lbs / kLbsPerKg : lbs;
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  String _unitLabel() => unit == WeightUnit.kg ? 'kg' : 'lbs';

  String _prLabel(PRType type) {
    switch (type) {
      case PRType.heaviestWeight:
        return 'Weight';
      case PRType.mostReps:
        return 'Reps';
      case PRType.estimated1RM:
        return '1RM';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Session Summary',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...summaries.map((s) => _ExerciseRow(
              summary: s,
              colors: colors,
              fmtWeight: _fmtWeight,
              fmtVolume: _fmtVolume,
              unitLabel: _unitLabel(),
              prLabel: _prLabel,
              textTheme: Theme.of(context).textTheme,
            )),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ExerciseSummary summary;
  final AppColors colors;
  final String Function(double) fmtWeight;
  final String Function(double) fmtVolume;
  final String unitLabel;
  final String Function(PRType) prLabel;
  final TextTheme textTheme;

  const _ExerciseRow({
    required this.summary,
    required this.colors,
    required this.fmtWeight,
    required this.fmtVolume,
    required this.unitLabel,
    required this.prLabel,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = exerciseLibrary
        .cast<Exercise?>()
        .firstWhere((e) => e!.id == summary.exerciseId, orElse: () => null);
    final name = exercise?.name ?? summary.exerciseId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: summary.newPRs.isNotEmpty
              ? Border.all(color: colors.data.withValues(alpha: 0.4))
              : Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontSize: 14)),
                ),
                if (summary.newPRs.isNotEmpty)
                  ...summary.newPRs.map((pr) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.data.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events,
                                  size: 12, color: colors.data),
                              const SizedBox(width: 2),
                              Text(prLabel(pr),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors.data,
                                  )),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Best: ${fmtWeight(summary.bestSetWeight)} $unitLabel × ${summary.bestSetReps}'
              '  ·  Vol: ${fmtVolume(summary.totalVolume)} $unitLabel'
              '  ·  1RM: ${fmtWeight(summary.estimated1RM)} $unitLabel',
              style: TextStyle(
                fontSize: 12,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
