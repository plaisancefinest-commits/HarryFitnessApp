import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/body_weight.dart';
import '../providers/workout_provider.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';

enum _Range { w1, m1, m3, ytd, y1, all }

/// Home-screen card: Robinhood-style line graph of body weight with a
/// time-range selector, plus the dashed trajectory toward the goal.
class WeightProgressCard extends StatefulWidget {
  const WeightProgressCard({super.key});

  @override
  State<WeightProgressCard> createState() => _WeightProgressCardState();
}

class _WeightProgressCardState extends State<WeightProgressCard> {
  WeightGoal? _goal;
  List<WeightEntry> _entries = [];
  bool _loaded = false;
  _Range _range = _Range.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final goal = await db.getWeightGoal();
    final entries = await db.getWeightEntries();
    if (mounted) {
      setState(() {
        _goal = goal;
        _entries = entries;
        _loaded = true;
      });
    }
  }

  double _toLbs(double v, WeightUnit unit) =>
      unit == WeightUnit.kg ? v * kLbsPerKg : v;

  double _fromLbs(double lbs, WeightUnit unit) =>
      unit == WeightUnit.kg ? lbs / kLbsPerKg : lbs;

  String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  Future<void> _editGoal(WeightUnit unit) async {
    final result = await showModalBottomSheet<WeightGoal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GoalSheet(goal: _goal, unit: unit),
    );
    if (result != null) {
      await DatabaseService.instance.saveWeightGoal(result);
      // Seed the chart with the starting weight if there are no entries yet
      if (_entries.isEmpty) {
        await DatabaseService.instance.addWeightEntry(WeightEntry(
            date: result.startDate, weightLbs: result.startWeightLbs));
      }
      await _load();
    }
  }

  Future<void> _logWeight(WeightUnit unit) async {
    final ctrl = TextEditingController();
    final unitLabel = unit == WeightUnit.kg ? 'kg' : 'lbs';
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Today's weight",
            style: Theme.of(context).textTheme.titleLarge),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: unitLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(ctrl.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      await DatabaseService.instance.addWeightEntry(WeightEntry(
          date: DateTime.now(), weightLbs: _toLbs(value, unit)));
      await _load();
    }
  }

  /// Start of the visible window for the selected range.
  DateTime get _windowStart {
    final now = DateTime.now();
    switch (_range) {
      case _Range.w1:
        return now.subtract(const Duration(days: 7));
      case _Range.m1:
        return now.subtract(const Duration(days: 30));
      case _Range.m3:
        return now.subtract(const Duration(days: 90));
      case _Range.ytd:
        return DateTime(now.year, 1, 1);
      case _Range.y1:
        return now.subtract(const Duration(days: 365));
      case _Range.all:
        var start = _goal!.startDate;
        if (_entries.isNotEmpty && _entries.first.date.isBefore(start)) {
          start = _entries.first.date;
        }
        return start;
    }
  }

  /// End of the visible window. "All" projects forward to the goal date so
  /// the runway to the goal stays visible; other ranges end today.
  DateTime get _windowEnd {
    final now = DateTime.now();
    if (_range == _Range.all) {
      var end = _goal!.endDate;
      if (_entries.isNotEmpty && _entries.last.date.isAfter(end)) {
        end = _entries.last.date;
      }
      if (now.isAfter(end)) end = now;
      return end;
    }
    return now;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final unit = context.watch<WorkoutProvider>().weightUnit;
    final unitLabel = unit == WeightUnit.kg ? 'kg' : 'lbs';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _goal == null
            ? _buildEmpty(context, unit)
            : _buildChart(context, unit, unitLabel),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WeightUnit unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WEIGHT GOAL', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Text(
          'Track your weight against a goal and end date.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _editGoal(unit),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: context.colors.border),
          ),
          child: Text('Set Goal',
              style: TextStyle(color: context.colors.ink)),
        ),
      ],
    );
  }

  Widget _buildChart(
      BuildContext context, WeightUnit unit, String unitLabel) {
    final c = context.colors;
    final goal = _goal!;
    final windowStart = _windowStart;
    final windowEnd = _windowEnd;
    final visible = _entries
        .where((e) =>
            !e.date.isBefore(windowStart) && !e.date.isAfter(windowEnd))
        .toList();
    final current = _entries.isNotEmpty
        ? _entries.last.weightLbs
        : goal.startWeightLbs;

    // Change over the visible window (first → last visible weigh-in).
    String? deltaText;
    if (visible.length >= 2) {
      final delta = _fromLbs(visible.last.weightLbs, unit) -
          _fromLbs(visible.first.weightLbs, unit);
      final sign = delta >= 0 ? '+' : '−';
      const periods = {
        _Range.w1: 'past week',
        _Range.m1: 'past month',
        _Range.m3: 'past 3 months',
        _Range.ytd: 'this year',
        _Range.y1: 'past year',
        _Range.all: 'overall',
      };
      deltaText = '$sign${_fmt(delta.abs())} $unitLabel ${periods[_range]}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('WEIGHT', style: Theme.of(context).textTheme.labelSmall),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _editGoal(unit),
                  child: Icon(Icons.edit_outlined,
                      size: 16, color: c.faint),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _logWeight(unit),
                  child: Icon(Icons.add_circle_outline,
                      size: 18, color: c.ink),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_fmt(_fromLbs(current, unit))} $unitLabel',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'goal ${_fmt(_fromLbs(goal.goalWeightLbs, unit))} $unitLabel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (deltaText != null) ...[
          const SizedBox(height: 2),
          Text(
            deltaText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.data,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(
            painter: _WeightChartPainter(
              goal: goal,
              entries: visible,
              windowStart: windowStart,
              windowEnd: windowEnd,
              toDisplay: (lbs) => _fromLbs(lbs, unit),
              lineColor: c.data,
              glowColor: c.warm,
              guideColor: c.borderStrong,
              dotRingColor: c.card,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmtDate(windowStart),
                style: Theme.of(context).textTheme.labelSmall),
            Text(_fmtDate(windowEnd),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final r in _Range.values)
              _RangePill(
                label: _rangeLabel(r),
                selected: r == _range,
                onTap: () => setState(() => _range = r),
              ),
          ],
        ),
      ],
    );
  }

  static String _rangeLabel(_Range r) {
    switch (r) {
      case _Range.w1:
        return '1W';
      case _Range.m1:
        return '1M';
      case _Range.m3:
        return '3M';
      case _Range.ytd:
        return 'YTD';
      case _Range.y1:
        return '1Y';
      case _Range.all:
        return 'ALL';
    }
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _RangePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.data.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: selected ? c.data : c.faint,
          ),
        ),
      ),
    );
  }
}

// ─── Chart painter ────────────────────────────────────────────────────────────

class _WeightChartPainter extends CustomPainter {
  final WeightGoal goal;
  final List<WeightEntry> entries; // already filtered to the window
  final DateTime windowStart;
  final DateTime windowEnd;
  final double Function(double lbs) toDisplay;
  final Color lineColor;
  final Color glowColor;
  final Color guideColor;
  final Color dotRingColor;

  _WeightChartPainter({
    required this.goal,
    required this.entries,
    required this.windowStart,
    required this.windowEnd,
    required this.toDisplay,
    required this.lineColor,
    required this.glowColor,
    required this.guideColor,
    required this.dotRingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startMs = windowStart.millisecondsSinceEpoch.toDouble();
    var endMs = windowEnd.millisecondsSinceEpoch.toDouble();
    if (endMs <= startMs) endMs = startMs + 1;

    // Goal trajectory interpolated at any time, clamped to the goal span.
    final goalStartMs = goal.startDate.millisecondsSinceEpoch.toDouble();
    final goalEndMs = goal.endDate.millisecondsSinceEpoch.toDouble();
    double goalAt(double ms) {
      if (goalEndMs <= goalStartMs) return goal.goalWeightLbs;
      final t = ((ms - goalStartMs) / (goalEndMs - goalStartMs)).clamp(0.0, 1.0);
      return goal.startWeightLbs +
          (goal.goalWeightLbs - goal.startWeightLbs) * t;
    }

    // Visible segment of the goal line within the window.
    final segStartMs = math.max(startMs, goalStartMs);
    final segEndMs = math.min(endMs, goalEndMs);
    final hasGoalSegment = segEndMs > segStartMs;

    final weights = <double>[
      ...entries.map((e) => toDisplay(e.weightLbs)),
      if (hasGoalSegment) ...[
        toDisplay(goalAt(segStartMs)),
        toDisplay(goalAt(segEndMs)),
      ],
      if (entries.isEmpty && !hasGoalSegment)
        toDisplay(goal.goalWeightLbs),
    ];
    var minW = weights.reduce(math.min);
    var maxW = weights.reduce(math.max);
    final pad = math.max((maxW - minW) * 0.15, 1.0);
    minW -= pad;
    maxW += pad;

    double xAt(double ms) => (ms - startMs) / (endMs - startMs) * size.width;
    double x(DateTime d) => xAt(d.millisecondsSinceEpoch.toDouble());
    double y(double lbs) =>
        size.height - (toDisplay(lbs) - minW) / (maxW - minW) * size.height;

    // Dashed goal trajectory across the visible window.
    if (hasGoalSegment) {
      _dashedLine(
        canvas,
        Offset(xAt(segStartMs), y(goalAt(segStartMs))),
        Offset(xAt(segEndMs), y(goalAt(segEndMs))),
        Paint()
          ..color = guideColor
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
      // Goal end marker when it's in view
      if (goalEndMs >= startMs && goalEndMs <= endMs) {
        canvas.drawCircle(
          Offset(x(goal.endDate), y(goal.goalWeightLbs)),
          3,
          Paint()
            ..color = guideColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }

    if (entries.isEmpty) return;

    // Actual weigh-in line — Robinhood-style orange with a soft fill below.
    final linePath = Path();
    for (var i = 0; i < entries.length; i++) {
      final p = Offset(x(entries[i].date), y(entries[i].weightLbs));
      if (i == 0) {
        linePath.moveTo(p.dx, p.dy);
      } else {
        linePath.lineTo(p.dx, p.dy);
      }
    }

    if (entries.length >= 2) {
      final fillPath = Path.from(linePath)
        ..lineTo(x(entries.last.date), size.height)
        ..lineTo(x(entries.first.date), size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              glowColor.withValues(alpha: 0.20),
              glowColor.withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Latest weigh-in dot only (Robinhood keeps the line clean).
    final last = Offset(x(entries.last.date), y(entries.last.weightLbs));
    canvas.drawCircle(last, 4, Paint()..color = lineColor);
    canvas.drawCircle(
        last,
        4,
        Paint()
          ..color = dotRingColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var dist = 0.0;
    while (dist < total) {
      final next = math.min(dist + dash, total);
      canvas.drawLine(a + dir * dist, a + dir * next, paint);
      dist = next + gap;
    }
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) =>
      old.goal != goal ||
      old.entries != entries ||
      old.windowStart != windowStart ||
      old.windowEnd != windowEnd ||
      old.lineColor != lineColor ||
      old.glowColor != glowColor ||
      old.guideColor != guideColor ||
      old.dotRingColor != dotRingColor;
}

// ─── Goal setup sheet ────────────────────────────────────────────────────────

class _GoalSheet extends StatefulWidget {
  final WeightGoal? goal;
  final WeightUnit unit;

  const _GoalSheet({required this.goal, required this.unit});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController _startCtrl;
  late final TextEditingController _goalCtrl;
  late DateTime _startDate;
  late DateTime _endDate;

  double _fromLbs(double lbs) =>
      widget.unit == WeightUnit.kg ? lbs / kLbsPerKg : lbs;

  double _toLbs(double v) =>
      widget.unit == WeightUnit.kg ? v * kLbsPerKg : v;

  String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _startCtrl = TextEditingController(
        text: g != null ? _fmt(_fromLbs(g.startWeightLbs)) : '');
    _goalCtrl = TextEditingController(
        text: g != null ? _fmt(_fromLbs(g.goalWeightLbs)) : '');
    _startDate = g?.startDate ?? DateTime.now();
    _endDate = g?.endDate ?? DateTime.now().add(const Duration(days: 84));
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _save() {
    final start = double.tryParse(_startCtrl.text);
    final goalW = double.tryParse(_goalCtrl.text);
    if (start == null || goalW == null || start <= 0 || goalW <= 0) return;
    if (!_endDate.isAfter(_startDate)) return;
    Navigator.pop(
      context,
      WeightGoal(
        startWeightLbs: _toLbs(start),
        startDate: _startDate,
        goalWeightLbs: _toLbs(goalW),
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.unit == WeightUnit.kg ? 'kg' : 'lbs';
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weight goal', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Starting weight',
                    suffixText: unitLabel,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _goalCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Goal weight',
                    suffixText: unitLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start date',
                  date: _startDate,
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DateField(
                  label: 'End date',
                  date: _endDate,
                  onTap: () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Goal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${date.month}/${date.day}/${date.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
