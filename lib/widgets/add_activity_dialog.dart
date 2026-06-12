import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/program.dart';
import '../theme/app_colors.dart';
import '../utils/minutes_input.dart';

/// Dialog to pick an activity (sauna, swim, run, walk) and a minutes
/// target. Pops with a new [PlannedActivity], or null on cancel.
class AddActivityDialog extends StatefulWidget {
  const AddActivityDialog({super.key});

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  static const _uuid = Uuid();

  static const _defaults = {
    ActivityType.sauna: 15,
    ActivityType.swim: 30,
    ActivityType.run: 25,
    ActivityType.walk: 30,
  };

  ActivityType _type = ActivityType.sauna;
  String? _error;
  late final TextEditingController _minutesCtrl;

  @override
  void initState() {
    super.initState();
    _minutesCtrl = TextEditingController(text: '${_defaults[_type]}');
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    super.dispose();
  }

  static String _label(ActivityType t) =>
      PlannedActivity(id: '', type: t, minutes: 0).label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title:
          Text('Add activity', style: Theme.of(context).textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final t in ActivityType.values)
                ChoiceChip(
                  label: Text(_label(t)),
                  selected: _type == t,
                  selectedColor: c.accent,
                  labelStyle: TextStyle(
                      color:
                          _type == t ? c.onAccent : c.muted),
                  onSelected: (_) => setState(() {
                    _type = t;
                    _minutesCtrl.text = '${_defaults[t]}';
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
            Navigator.pop(
              context,
              PlannedActivity(id: _uuid.v4(), type: _type, minutes: minutes),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
