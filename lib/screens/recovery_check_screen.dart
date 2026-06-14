import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/recovery_check.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';

class RecoveryCheckScreen extends StatefulWidget {
  final String programId;
  final Set<MuscleGroup> muscleGroups;
  final bool isPreWeek;

  const RecoveryCheckScreen({
    super.key,
    required this.programId,
    required this.muscleGroups,
    required this.isPreWeek,
  });

  @override
  State<RecoveryCheckScreen> createState() => _RecoveryCheckScreenState();
}

class _RecoveryCheckScreenState extends State<RecoveryCheckScreen> {
  final Map<MuscleGroup, RecoveryStatus> _ratings = {};

  bool get _allRated => _ratings.length == widget.muscleGroups.length;

  Future<void> _submit() async {
    if (!_allRated) return;
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    await DatabaseService.instance.saveRecoveryCheck(RecoveryCheck(
      id: const Uuid().v4(),
      programId: widget.programId,
      weekStart: monday,
      isPreWeek: widget.isPreWeek,
      ratings: _ratings.entries
          .map((e) =>
              MuscleRecoveryRating(muscleGroup: e.key, status: e.value))
          .toList(),
      createdAt: now,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final groups = widget.muscleGroups.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isPreWeek ? 'Pre-Week Recovery' : 'End-of-Week Recovery',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'How does each muscle group feel?',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: c.muted),
                ),
                const SizedBox(height: 20),
                ...groups.map((group) => _MuscleRatingCard(
                      muscleGroup: group,
                      status: _ratings[group],
                      onChanged: (status) =>
                          setState(() => _ratings[group] = status),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allRated ? _submit : null,
                child: const Text('Submit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleRatingCard extends StatelessWidget {
  final MuscleGroup muscleGroup;
  final RecoveryStatus? status;
  final ValueChanged<RecoveryStatus> onChanged;

  const _MuscleRatingCard({
    required this.muscleGroup,
    required this.status,
    required this.onChanged,
  });

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

  static String _statusLabel(RecoveryStatus s) {
    switch (s) {
      case RecoveryStatus.fullyRecovered:
        return 'Recovered';
      case RecoveryStatus.slightlySore:
        return 'Slightly sore';
      case RecoveryStatus.verySore:
        return 'Very sore';
      case RecoveryStatus.injured:
        return 'Injured';
    }
  }

  static Color _statusColor(RecoveryStatus s, AppColors c) {
    switch (s) {
      case RecoveryStatus.fullyRecovered:
        return c.green;
      case RecoveryStatus.slightlySore:
        return c.data;
      case RecoveryStatus.verySore:
        return c.warm;
      case RecoveryStatus.injured:
        return const Color(0xFFD32F2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_muscleName(muscleGroup),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RecoveryStatus.values.map((s) {
                final selected = status == s;
                final color = _statusColor(s, c);
                return GestureDetector(
                  onTap: () => onChanged(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color.withAlpha(30) : c.fill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? color : c.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      _statusLabel(s),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? color : c.muted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
