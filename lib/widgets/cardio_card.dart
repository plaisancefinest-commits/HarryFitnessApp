import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../utils/minutes_input.dart';

/// Home-screen card with two weekly trackers, logged manually or from a
/// day's activities: zone-2 cardio (110–150 min) and sauna (57–140 min).
class CardioCard extends StatefulWidget {
  const CardioCard({super.key});

  @override
  State<CardioCard> createState() => _CardioCardState();
}

class _CardioCardState extends State<CardioCard> {
  static const _cardioLow = 110;
  static const _cardioHigh = 150;
  static const _saunaLow = 57;
  static const _saunaHigh = 140;

  bool _loaded = false;
  List<Map<String, dynamic>> _cardio = [];
  List<Map<String, dynamic>> _sauna = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final cardio = await db.getCardioEntriesThisWeek();
    final sauna = await db.getSaunaEntriesThisWeek();
    if (mounted) {
      setState(() {
        _cardio = cardio;
        _sauna = sauna;
        _loaded = true;
      });
    }
  }

  Future<void> _log() async {
    final result = await showDialog<(String, int, String)>(
      context: context,
      builder: (context) => const _LogDialog(),
    );
    if (result != null) {
      final (kind, minutes, label) = result;
      final db = DatabaseService.instance;
      if (kind == 'sauna') {
        await db.addSaunaEntry(DateTime.now(), minutes, label);
      } else {
        await db.addCardioEntry(DateTime.now(), minutes, label);
      }
      await _load();
    }
  }

  static int _total(List<Map<String, dynamic>> entries) =>
      entries.fold<int>(0, (sum, e) => sum + (e['minutes'] as num).toInt());

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final recent = [
      ..._cardio.map((e) => (e, false)),
      ..._sauna.map((e) => (e, true)),
    ]..sort((a, b) => (a.$1['date'] as String).compareTo(b.$1['date']));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('THIS WEEK · RECOVERY',
                    style: Theme.of(context).textTheme.labelSmall),
                GestureDetector(
                  onTap: _log,
                  child: Icon(Icons.add_circle_outline,
                      size: 18, color: context.colors.ink),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Tracker(
              label: 'Zone 2',
              minutes: _total(_cardio),
              low: _cardioLow,
              high: _cardioHigh,
            ),
            const SizedBox(height: 12),
            _Tracker(
              label: 'Sauna',
              minutes: _total(_sauna),
              low: _saunaLow,
              high: _saunaHigh,
            ),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...recent.reversed.take(3).map((r) {
                final (e, isSauna) = r;
                final label = (e['label'] as String?)?.isNotEmpty == true
                    ? e['label'] as String
                    : (isSauna ? 'Sauna' : 'Cardio');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${_fmtDay(e['date'])} · $label',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text('${e['minutes']} min',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDay(String iso) {
    final d = DateTime.parse(iso);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }
}

class _Tracker extends StatelessWidget {
  final String label;
  final int minutes;
  final int low;
  final int high;

  const _Tracker({
    required this.label,
    required this.minutes,
    required this.low,
    required this.high,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final progress = (minutes / low).clamp(0.0, 1.0);
    final inZone = minutes >= low;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text('$minutes of $low–$high min',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: c.fill,
            valueColor: AlwaysStoppedAnimation(inZone ? c.green : c.warm),
          ),
        ),
      ],
    );
  }
}

class _LogDialog extends StatefulWidget {
  const _LogDialog();

  @override
  State<_LogDialog> createState() => _LogDialogState();
}

class _LogDialogState extends State<_LogDialog> {
  static const _kinds = [
    ('Sauna', 'sauna', 15),
    ('Swim', 'cardio', 30),
    ('Run', 'cardio', 25),
    ('Walk', 'cardio', 30),
  ];

  int _selected = 0;
  String? _error;
  late final TextEditingController _minutesCtrl;

  @override
  void initState() {
    super.initState();
    _minutesCtrl = TextEditingController(text: '${_kinds[_selected].$3}');
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: Text('Log activity',
          style: Theme.of(context).textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < _kinds.length; i++)
                ChoiceChip(
                  label: Text(_kinds[i].$1),
                  selected: _selected == i,
                  selectedColor: c.accent,
                  labelStyle: TextStyle(
                      color: _selected == i
                          ? c.onAccent
                          : c.muted),
                  onSelected: (_) => setState(() {
                    _selected = i;
                    _minutesCtrl.text = '${_kinds[i].$3}';
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _minutesCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: 'Minutes', suffixText: 'min', errorText: _error),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final minutes = parseMinutes(_minutesCtrl.text);
            if (minutes == null) {
              setState(() => _error = 'Enter minutes, e.g. 45 or 43:59');
              return;
            }
            Navigator.pop(context,
                (_kinds[_selected].$2, minutes, _kinds[_selected].$1));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
