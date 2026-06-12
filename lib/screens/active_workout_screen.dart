import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/program.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/muscle_diagram.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Program program;
  final WorkoutDay day;
  final bool isFirstWeek;
  final Map<String, int>? previousRestAverages;

  const ActiveWorkoutScreen({
    super.key,
    required this.program,
    required this.day,
    required this.isFirstWeek,
    this.previousRestAverages,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  DiagramSide _diagramSide = DiagramSide.front;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().startSession(
            program: widget.program,
            day: widget.day,
            isFirstWeek: widget.isFirstWeek,
            previousRestAverages: widget.previousRestAverages,
          );
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        if (provider.state == WorkoutState.complete) {
          return _buildCompleteScreen(context);
        }

        if (provider.state == WorkoutState.stretching) {
          return _buildStretchScreen(context, provider);
        }

        final exercise = provider.currentExercise;
        if (exercise == null) return const SizedBox.shrink();

        final c = context.colors;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: c.ink),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(widget.day.name,
                style: Theme.of(context).textTheme.titleMedium),
            actions: [
              _UnitToggle(
                unit: provider.weightUnit,
                onToggle: provider.toggleUnit,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise name
                Text(exercise.exercise.name,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _NavArrow(
                      icon: Icons.chevron_left,
                      enabled: provider.currentExerciseIndex > 0,
                      onTap: provider.goToPreviousExercise,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${provider.currentExerciseIndex + 1} of ${widget.day.exercises.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    _NavArrow(
                      icon: Icons.chevron_right,
                      enabled: !provider.isLastExercise,
                      onTap: provider.goToNextExercise,
                    ),
                  ],
                ),
                if (exercise.targetWeightLbs != null ||
                    exercise.notes != null) ...[
                  const SizedBox(height: 12),
                  _TargetInfo(exercise: exercise, unit: provider.weightUnit),
                ],
                const SizedBox(height: 20),

                // Muscle diagram
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Front / Back toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SideToggle(
                              side: _diagramSide,
                              onChanged: (s) =>
                                  setState(() => _diagramSide = s),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MuscleDiagram(
                          primaryMuscles:
                              exercise.exercise.primaryMuscles,
                          secondaryMuscles:
                              exercise.exercise.secondaryMuscles,
                          side: _diagramSide,
                        ),
                        const SizedBox(height: 8),
                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendDot(color: c.accent),
                            const SizedBox(width: 4),
                            Text('Primary',
                                style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(width: 16),
                            _LegendDot(color: c.faint),
                            const SizedBox(width: 4),
                            Text('Secondary',
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions
                if (exercise.exercise.instructions != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How to perform',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          Text(
                            exercise.exercise.instructions!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _VideoLink(
                  name: exercise.exercise.name,
                  url: exercise.exercise.videoUrl,
                ),
                const SizedBox(height: 16),

                // Set table
                _SetTable(
                  exercise: exercise,
                  provider: provider,
                  unit: provider.weightUnit,
                ),
                const SizedBox(height: 16),

                // Timer card (shown during rest)
                if (provider.state == WorkoutState.resting)
                  _TimerCard(
                    seconds: provider.timerSeconds,
                    mode: provider.timerMode,
                    formatTime: _formatTime,
                    onSkip: provider.endRest,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStretchScreen(BuildContext context, WorkoutProvider provider) {
    final stretch = provider.currentStretch;
    if (stretch == null) return const SizedBox.shrink();

    final isWarmUp = stretch.phase == StretchPhase.warmUp;
    final index = provider.currentExerciseIndex;
    final total = provider.totalStretches;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isWarmUp ? 'Warm Up' : 'Cool Down',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1} of $total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Text(
                stretch.name,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                stretch.durationSeconds >= 120
                    ? '${stretch.durationSeconds ~/ 60} minutes'
                    : 'Hold for ${stretch.durationSeconds} seconds',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (stretch.instructions != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How to perform',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        Text(
                          stretch.instructions!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _VideoLink(name: stretch.name, url: stretch.videoUrl),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.completeStretch,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text('Workout\nComplete',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 16),
              Text(
                'Great work. Session saved.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Target Info ─────────────────────────────────────────────────────────────

/// Prescribed sets × reps @ weight, rest time, and coach notes for the
/// current exercise.
class _TargetInfo extends StatelessWidget {
  final PlannedExercise exercise;
  final WeightUnit unit;

  const _TargetInfo({required this.exercise, required this.unit});

  String _formatWeight(double lbs) {
    final v = unit == WeightUnit.kg ? lbs / 2.20462 : lbs;
    final label = unit == WeightUnit.kg ? 'kg' : 'lbs';
    return '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} $label';
  }

  String _formatRest(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '$m:00' : '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (exercise.targetWeightLbs != null)
        '${exercise.sets} × ${exercise.reps} @ ${_formatWeight(exercise.targetWeightLbs!)}',
      if (exercise.restSeconds != null)
        'Rest ${_formatRest(exercise.restSeconds!)}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.isNotEmpty)
          Text(
            parts.join(' · '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink,
                ),
          ),
        if (exercise.notes != null) ...[
          const SizedBox(height: 4),
          Text(
            exercise.notes!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: context.colors.muted,
                ),
          ),
        ],
      ],
    );
  }
}

// ─── Video Link ──────────────────────────────────────────────────────────────

/// Opens the configured video for an exercise/stretch, or falls back to a
/// YouTube search for the exercise name + "form" when no link is set.
class _VideoLink extends StatelessWidget {
  final String name;
  final String? url;

  const _VideoLink({required this.name, this.url});

  Future<void> _open() async {
    final uri = url != null
        ? Uri.parse(url!)
        : Uri.https('www.youtube.com', '/results',
            {'search_query': '$name form'});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline,
              size: 18, color: context.colors.muted),
          const SizedBox(width: 6),
          Text(
            url != null ? 'Watch video' : 'Find video on YouTube',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: context.colors.borderStrong,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Arrow ────────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        size: 20,
        color: enabled ? context.colors.ink : context.colors.borderStrong,
      ),
    );
  }
}

// ─── Unit Toggle ──────────────────────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  final WeightUnit unit;
  final VoidCallback onToggle;

  const _UnitToggle({required this.unit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _UnitLabel(label: 'kg', active: unit == WeightUnit.kg),
            const SizedBox(width: 4),
            Text('·',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: c.faint)),
            const SizedBox(width: 4),
            _UnitLabel(label: 'lbs', active: unit == WeightUnit.lbs),
          ],
        ),
      ),
    );
  }
}

class _UnitLabel extends StatelessWidget {
  final String label;
  final bool active;
  const _UnitLabel({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        color: active ? context.colors.accent : context.colors.faint,
      ),
    );
  }
}

// ─── Side Toggle ─────────────────────────────────────────────────────────────

class _SideToggle extends StatelessWidget {
  final DiagramSide side;
  final ValueChanged<DiagramSide> onChanged;

  const _SideToggle({required this.side, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SideBtn(
              label: 'Front',
              active: side == DiagramSide.front,
              onTap: () => onChanged(DiagramSide.front)),
          _SideBtn(
              label: 'Back',
              active: side == DiagramSide.back,
              onTap: () => onChanged(DiagramSide.back)),
        ],
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SideBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  const BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? c.accent : c.faint,
          ),
        ),
      ),
    );
  }
}

// ─── Legend Dot ───────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Set Table ────────────────────────────────────────────────────────────────

class _SetTable extends StatelessWidget {
  final PlannedExercise exercise;
  final WorkoutProvider provider;
  final WeightUnit unit;

  const _SetTable({
    required this.exercise,
    required this.provider,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final drafts =
        provider.getDraftsForExercise(exercise.exercise.id) ?? [];
    final isResting = provider.state == WorkoutState.resting;
    final unitLabel = unit == WeightUnit.lbs ? 'lbs' : 'kg';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text('Set',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Weight ($unitLabel)',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 20,
                    child: Text('×',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Reps',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Divider(height: 1, color: context.colors.fill),
            const SizedBox(height: 4),
            ...List.generate(drafts.length, (i) {
              return _SetRow(
                // Key includes the unit so rows rebuild their text fields
                // with converted values when the kg/lbs toggle is used.
                key: ValueKey('${exercise.exercise.id}_${i}_$unit'),
                setNumber: i + 1,
                draft: drafts[i],
                disabled: isResting,
                onWeightChanged: (v) => provider.updateDraftWeight(
                    exercise.exercise.id, i, v),
                onRepsChanged: (v) =>
                    provider.updateDraftReps(exercise.exercise.id, i, v),
                onComplete: () =>
                    provider.completeSetByIndex(exercise.exercise.id, i),
                onUncomplete: () =>
                    provider.uncompleteSetByIndex(exercise.exercise.id, i),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Set Row ─────────────────────────────────────────────────────────────────

class _SetRow extends StatefulWidget {
  final int setNumber;
  final dynamic draft; // _SetDraft
  final bool disabled;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onComplete;
  final VoidCallback onUncomplete;

  const _SetRow({
    super.key,
    required this.setNumber,
    required this.draft,
    required this.disabled,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onComplete,
    required this.onUncomplete,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.draft.weight > 0
          ? widget.draft.weight.toStringAsFixed(
              widget.draft.weight % 1 == 0 ? 0 : 1)
          : '',
    );
    _repsCtrl = TextEditingController(
      text: widget.draft.reps > 0 ? '${widget.draft.reps}' : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final completed = widget.draft.completed as bool;
    final bg = completed ? c.bg : c.card;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 36,
            child: Text(
              '${widget.setNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: completed ? c.faint : c.ink,
              ),
            ),
          ),
          // Weight field
          Expanded(
            flex: 3,
            child: _InlineField(
              controller: _weightCtrl,
              enabled: !completed && !widget.disabled,
              decimal: true,
              onChanged: (v) {
                final parsed = double.tryParse(v) ?? 0;
                widget.onWeightChanged(parsed);
              },
            ),
          ),
          // ×
          SizedBox(
            width: 20,
            child: Text('×',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: completed ? c.faint : c.ink)),
          ),
          // Reps field
          Expanded(
            flex: 2,
            child: _InlineField(
              controller: _repsCtrl,
              enabled: !completed && !widget.disabled,
              decimal: false,
              onChanged: (v) {
                final parsed = int.tryParse(v) ?? 0;
                widget.onRepsChanged(parsed);
              },
            ),
          ),
          // Complete / uncheck button
          SizedBox(
            width: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                completed ? Icons.check_circle : Icons.check_circle_outline,
                color: completed ? c.accent : c.borderStrong,
                size: 20,
              ),
              onPressed: completed
                  ? widget.onUncomplete
                  : (widget.disabled ? null : widget.onComplete),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _InlineField({
    required this.controller,
    required this.enabled,
    required this.decimal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      keyboardType:
          TextInputType.numberWithOptions(decimal: decimal),
      style: TextStyle(
        fontSize: 14,
        color: enabled ? c.ink : c.faint,
      ),
      decoration: InputDecoration(
        hintText: decimal ? '0' : '—',
        hintStyle: TextStyle(color: c.borderStrong),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: enabled ? c.card : c.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.fill),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.accent),
        ),
      ),
    );
  }
}

// ─── Timer Card ───────────────────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final int seconds;
  final TimerMode mode;
  final String Function(int) formatTime;
  final VoidCallback onSkip;

  const _TimerCard({
    required this.seconds,
    required this.mode,
    required this.formatTime,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == TimerMode.stopwatch ? 'Rest (tracking)' : 'Rest',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  formatTime(seconds),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                    color: context.colors.ink,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip Rest'),
            ),
          ],
        ),
      ),
    );
  }
}
