import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/program.dart';
import '../providers/workout_provider.dart';
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

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF2C2C2C)),
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
                Text(
                  '${provider.currentExerciseIndex + 1} of ${widget.day.exercises.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                            _LegendDot(color: const Color(0xFF1A1A1A)),
                            const SizedBox(width: 4),
                            Text('Primary',
                                style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(width: 16),
                            _LegendDot(color: const Color(0xFFAAAAAA)),
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
          icon: const Icon(Icons.close, color: Color(0xFF2C2C2C)),
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
                'Hold for ${stretch.durationSeconds} seconds',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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

// ─── Unit Toggle ──────────────────────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  final WeightUnit unit;
  final VoidCallback onToggle;

  const _UnitToggle({required this.unit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEAE5),
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
                    ?.copyWith(color: const Color(0xFF9E9E9E))),
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
        color: active ? const Color(0xFF1A1A1A) : const Color(0xFF9E9E9E),
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
        color: const Color(0xFFEDEAE5),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
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
            color: active ? const Color(0xFF1A1A1A) : const Color(0xFF9E9E9E),
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
            const Divider(height: 1, color: Color(0xFFEDEAE5)),
            const SizedBox(height: 4),
            ...List.generate(drafts.length, (i) {
              return _SetRow(
                setNumber: i + 1,
                draft: drafts[i],
                disabled: isResting,
                onWeightChanged: (v) => provider.updateDraftWeight(
                    exercise.exercise.id, i, v),
                onRepsChanged: (v) =>
                    provider.updateDraftReps(exercise.exercise.id, i, v),
                onComplete: () =>
                    provider.completeSetByIndex(exercise.exercise.id, i),
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

  const _SetRow({
    required this.setNumber,
    required this.draft,
    required this.disabled,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onComplete,
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
    final completed = widget.draft.completed as bool;
    final bg = completed ? const Color(0xFFF7F5F2) : Colors.white;

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
                color: completed
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFF2C2C2C),
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
                    color: completed
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF2C2C2C))),
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
          // Complete button
          SizedBox(
            width: 40,
            child: completed
                ? const Icon(Icons.check_circle,
                    color: Color(0xFF1A1A1A), size: 20)
                : IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.check_circle_outline,
                        color: Color(0xFFCCC8C2), size: 20),
                    onPressed: widget.disabled ? null : widget.onComplete,
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
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      keyboardType:
          TextInputType.numberWithOptions(decimal: decimal),
      style: TextStyle(
        fontSize: 14,
        color: enabled ? const Color(0xFF2C2C2C) : const Color(0xFF9E9E9E),
      ),
      decoration: InputDecoration(
        hintText: decimal ? '0' : '—',
        hintStyle: const TextStyle(color: Color(0xFFCCC8C2)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF7F5F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDAD6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDAD6)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEDEAE5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
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
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                    color: Color(0xFF2C2C2C),
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
