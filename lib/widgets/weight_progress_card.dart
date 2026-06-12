import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/body_weight.dart';
import '../providers/workout_provider.dart';
import '../services/database_service.dart';

const _kgFactor = 2.20462;

/// Home-screen card: line graph of body weight from the starting weight/date
/// toward the goal weight/end date, with logged weigh-ins along the way.
class WeightProgressCard extends StatefulWidget {
  const WeightProgressCard({super.key});

  @override
  State<WeightProgressCard> createState() => _WeightProgressCardState();
}

class _WeightProgressCardState extends State<WeightProgressCard> {
  WeightGoal? _goal;
  List<WeightEntry> _entries = [];
  bool _loaded = false;

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
      unit == WeightUnit.kg ? v * _kgFactor : v;

  double _fromLbs(double lbs, WeightUnit unit) =>
      unit == WeightUnit.kg ? lbs / _kgFactor : lbs;

  String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  Future<void> _editGoal(WeightUnit unit) async {
    final result = await showModalBottomSheet<WeightGoal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F5F2),
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
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            side: const BorderSide(color: Color(0xFFDDDAD6)),
          ),
          child: const Text('Set Goal',
              style: TextStyle(color: Color(0xFF2C2C2C))),
        ),
      ],
    );
  }

  Widget _buildChart(
      BuildContext context, WeightUnit unit, String unitLabel) {
    final goal = _goal!;
    final current = _entries.isNotEmpty
        ? _entries.last.weightLbs
        : goal.startWeightLbs;

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
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _logWeight(unit),
                  child: const Icon(Icons.add_circle_outline,
                      size: 18, color: Color(0xFF2C2C2C)),
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
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _WeightChartPainter(
              goal: goal,
              entries: _entries,
              toDisplay: (lbs) => _fromLbs(lbs, unit),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmtDate(goal.startDate),
                style: Theme.of(context).textTheme.labelSmall),
            Text(_fmtDate(goal.endDate),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ─── Chart painter ────────────────────────────────────────────────────────────

class _WeightChartPainter extends CustomPainter {
  final WeightGoal goal;
  final List<WeightEntry> entries;
  final double Function(double lbs) toDisplay;

  _WeightChartPainter({
    required this.goal,
    required this.entries,
    required this.toDisplay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startMs = goal.startDate.millisecondsSinceEpoch.toDouble();
    var endMs = goal.endDate.millisecondsSinceEpoch.toDouble();
    if (entries.isNotEmpty) {
      endMs = math.max(
          endMs, entries.last.date.millisecondsSinceEpoch.toDouble());
    }
    if (endMs <= startMs) endMs = startMs + 1;

    final weights = [
      goal.startWeightLbs,
      goal.goalWeightLbs,
      ...entries.map((e) => e.weightLbs),
    ].map(toDisplay).toList();
    var minW = weights.reduce(math.min);
    var maxW = weights.reduce(math.max);
    final pad = math.max((maxW - minW) * 0.15, 1.0);
    minW -= pad;
    maxW += pad;

    double x(DateTime d) =>
        (d.millisecondsSinceEpoch - startMs) / (endMs - startMs) * size.width;
    double y(double lbs) =>
        size.height -
        (toDisplay(lbs) - minW) / (maxW - minW) * size.height;

    // Dashed goal line: start → goal/end date
    _dashedLine(
      canvas,
      Offset(x(goal.startDate), y(goal.startWeightLbs)),
      Offset(x(goal.endDate), y(goal.goalWeightLbs)),
      Paint()
        ..color = const Color(0xFFCCC8C2)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // Goal end marker
    canvas.drawCircle(
      Offset(x(goal.endDate), y(goal.goalWeightLbs)),
      3,
      Paint()
        ..color = const Color(0xFFCCC8C2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    if (entries.isEmpty) return;

    // Actual weigh-in line
    final line = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final p = Offset(x(entries[i].date), y(entries[i].weightLbs));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, line);

    // Dots on each weigh-in; latest one slightly larger
    for (var i = 0; i < entries.length; i++) {
      final p = Offset(x(entries[i].date), y(entries[i].weightLbs));
      canvas.drawCircle(
          p, i == entries.length - 1 ? 4 : 2.5,
          Paint()..color = const Color(0xFF1A1A1A));
      if (i == entries.length - 1) {
        canvas.drawCircle(p, 4,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    final total = (b - a).distance;
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
      old.goal != goal || old.entries != entries;
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
      widget.unit == WeightUnit.kg ? lbs / _kgFactor : lbs;

  double _toLbs(double v) =>
      widget.unit == WeightUnit.kg ? v * _kgFactor : v;

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
