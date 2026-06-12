import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/program.dart';
import '../services/database_service.dart';
import 'day_editor_screen.dart';

/// Edit a custom program: rename it, add/remove/rename days, and open
/// each day to edit its exercises. Every change is persisted immediately.
class ProgramEditorScreen extends StatefulWidget {
  final Program program;

  const ProgramEditorScreen({super.key, required this.program});

  @override
  State<ProgramEditorScreen> createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends State<ProgramEditorScreen> {
  static const _uuid = Uuid();

  late String _name;
  late List<WorkoutDay> _days;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _name = widget.program.name;
    _days = [...widget.program.days];
    _nameCtrl = TextEditingController(text: _name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    await DatabaseService.instance.saveCustomProgram(Program(
      id: widget.program.id,
      name: _name.trim().isEmpty ? 'My Program' : _name.trim(),
      level: UserLevel.intermediate,
      days: _days,
    ));
  }

  void _addDay() {
    setState(() {
      _days.add(WorkoutDay(
        id: _uuid.v4(),
        name: 'Day ${_days.length + 1}',
        description: 'Workout',
        estimatedMinutes: 45,
        exercises: [],
      ));
    });
    _persist();
  }

  Future<void> _removeDay(WorkoutDay day) async {
    if (_days.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A program needs at least one day.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove day?'),
        content: Text('"${day.name}" and its exercises will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _days.remove(day));
    _persist();
  }

  Future<void> _renameDay(WorkoutDay day) async {
    final nameCtrl = TextEditingController(text: day.name);
    final descCtrl = TextEditingController(text: day.description);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      _replaceDay(
          day,
          WorkoutDay(
            id: day.id,
            name: nameCtrl.text.trim().isEmpty ? day.name : nameCtrl.text.trim(),
            description: descCtrl.text.trim(),
            estimatedMinutes: day.estimatedMinutes,
            exercises: day.exercises,
          ));
    }
  }

  void _replaceDay(WorkoutDay oldDay, WorkoutDay newDay) {
    final i = _days.indexWhere((d) => d.id == oldDay.id);
    if (i == -1) return;
    setState(() => _days[i] = newDay);
    _persist();
  }

  Future<void> _editDay(WorkoutDay day) async {
    final updated = await Navigator.push<WorkoutDay>(
      context,
      MaterialPageRoute(builder: (_) => DayEditorScreen(day: day)),
    );
    if (updated != null) _replaceDay(day, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Program',
            style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('PROGRAM NAME',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.0)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            onChanged: (v) {
              _name = v;
              _persist();
            },
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text('DAYS',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.0)),
          const SizedBox(height: 8),
          ..._days.map((day) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _editDay(day),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                '${day.description} · '
                                '${day.exercises.length} exercise${day.exercises.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF6B6B6B)),
                          tooltip: 'Rename day',
                          onPressed: () => _renameDay(day),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFF6B6B6B)),
                          tooltip: 'Remove day',
                          onPressed: () => _removeDay(day),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Color(0xFFCCC8C2)),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addDay,
            icon: const Icon(Icons.add, size: 18, color: Color(0xFF2C2C2C)),
            label: const Text('Add Day',
                style: TextStyle(color: Color(0xFF2C2C2C))),
            style: OutlinedButton.styleFrom(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFDDDAD6)),
            ),
          ),
        ],
      ),
    );
  }
}
