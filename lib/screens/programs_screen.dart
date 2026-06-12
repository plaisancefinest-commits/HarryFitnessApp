import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/sample_programs.dart';
import '../models/program.dart';
import '../services/database_service.dart';
import 'program_editor_screen.dart';

/// "My Programs" tab: pick the active program, create your own, and
/// edit or delete custom ones.
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  List<Program> _custom = [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final custom = await db.getCustomPrograms();
    final selected = await db.getSelectedProgramId();
    if (mounted) {
      setState(() {
        _custom = custom;
        _selectedId = selected ?? samplePrograms.first.id;
      });
    }
  }

  Future<void> _select(Program p) async {
    await DatabaseService.instance.saveSelectedProgramId(p.id);
    setState(() => _selectedId = p.id);
  }

  Future<void> _createProgram() async {
    const uuid = Uuid();
    final program = Program(
      id: uuid.v4(),
      name: 'My Program',
      level: UserLevel.intermediate,
      days: [
        WorkoutDay(
          id: uuid.v4(),
          name: 'Day 1',
          description: 'Workout',
          estimatedMinutes: 45,
          exercises: [],
        ),
      ],
    );
    await DatabaseService.instance.saveCustomProgram(program);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgramEditorScreen(program: program)),
    );
    _load();
  }

  Future<void> _editProgram(Program p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgramEditorScreen(program: p)),
    );
    _load();
  }

  Future<void> _deleteProgram(Program p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete program?'),
        content: Text('"${p.name}" will be removed. Workout history is kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DatabaseService.instance.deleteCustomProgram(p.id);
    // If the deleted program was active, fall back to the default.
    if (_selectedId == p.id) {
      await DatabaseService.instance
          .saveSelectedProgramId(samplePrograms.first.id);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Text('Programs', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          Text('BUILT IN',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.0)),
          const SizedBox(height: 8),
          ...samplePrograms.map((p) => _ProgramCard(
                program: p,
                selected: p.id == _selectedId,
                onSelect: () => _select(p),
              )),
          const SizedBox(height: 16),
          Text('MY PROGRAMS',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.0)),
          const SizedBox(height: 8),
          if (_custom.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nothing here yet — build your own program.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ..._custom.map((p) => _ProgramCard(
                program: p,
                selected: p.id == _selectedId,
                onSelect: () => _select(p),
                onEdit: () => _editProgram(p),
                onDelete: () => _deleteProgram(p),
              )),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _createProgram,
            icon: const Icon(Icons.add, size: 18, color: Color(0xFF2C2C2C)),
            label: const Text('New Program',
                style: TextStyle(color: Color(0xFF2C2C2C))),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFDDDAD6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final Program program;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProgramCard({
    required this.program,
    required this.selected,
    required this.onSelect,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dayCount = program.days.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: selected
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFCCC8C2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '$dayCount ${dayCount == 1 ? 'day' : 'days'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Color(0xFF6B6B6B)),
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFF6B6B6B)),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
