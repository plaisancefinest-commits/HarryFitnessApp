import 'package:flutter/material.dart';
import '../data/sample_programs.dart';
import '../models/program.dart';
import '../services/database_service.dart';
import '../data/exercise_library.dart';
import '../widgets/weight_progress_card.dart';
import 'active_workout_screen.dart';
import 'history_screen.dart';
import 'programs_screen.dart';
import 'workout_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: switch (_selectedTab) {
        0 => const _DashboardTab(),
        1 => const ProgramsScreen(),
        _ => const HistoryScreen(),
      },
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Programs'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  int _completedThisWeek = 0;
  bool _isFirstWeek = true;
  Map<String, int> _restRecommendations = {};
  String? _lastCompletedDayId;
  String? _overrideDayId; // user tapped a pill; null = follow rotation

  Program? _program;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = DatabaseService.instance;

    // Resolve the active program: built-in or custom, falling back to the
    // first built-in if the selection is missing (e.g. deleted program).
    final selectedId = await db.getSelectedProgramId();
    final custom = await db.getCustomPrograms();
    final all = [...samplePrograms, ...custom];
    final program = all.firstWhere(
      (p) => p.id == selectedId,
      orElse: () => samplePrograms.first,
    );

    await _applyExerciseOverrides(db, program);
    final count = await db.getSessionsThisWeek();
    final hasHistory = await db.hasCompletedSessionForProgram(program.id);
    final recs = hasHistory ? await db.getRestRecommendations(program.id) : <String, int>{};
    final lastDayId = await db.getLastCompletedDayId(program.id);
    if (mounted) {
      setState(() {
        _program = program;
        _completedThisWeek = count;
        _isFirstWeek = !hasHistory;
        _restRecommendations = recs;
        _lastCompletedDayId = lastDayId;
        _overrideDayId = null; // a finished workout resets any manual pick
      });
    }
  }

  /// Re-apply any exercise swaps and custom exercise ordering the user
  /// saved in previous sessions.
  Future<void> _applyExerciseOverrides(
      DatabaseService db, Program program) async {
    final overrides = await db.getExerciseOverrides();
    final orderOverrides = await db.getExerciseOrderOverrides();
    for (final day in program.days) {
      for (final pe in day.exercises) {
        final overrideId = overrides[pe.id];
        if (overrideId != null && overrideId != pe.exercise.id) {
          final replacement =
              exerciseLibrary.where((e) => e.id == overrideId).firstOrNull;
          if (replacement != null) pe.exercise = replacement;
        }
      }
      final order = orderOverrides[day.id];
      if (order != null) {
        // Saved ids first (in saved order); anything new keeps its place after.
        final index = {for (var i = 0; i < order.length; i++) order[i]: i};
        day.exercises.sort((a, b) => (index[a.id] ?? 1000 + a.order)
            .compareTo(index[b.id] ?? 1000 + b.order));
        for (var i = 0; i < day.exercises.length; i++) {
          day.exercises[i].order = i;
        }
      }
    }
  }

  /// Rotation: the day after the last completed one, wrapping (A→B→C→A).
  WorkoutDay get _suggestedDay {
    final days = _program!.days;
    final lastIndex = days.indexWhere((d) => d.id == _lastCompletedDayId);
    if (lastIndex == -1) return days.first;
    return days[(lastIndex + 1) % days.length];
  }

  WorkoutDay get _nextDay {
    if (_overrideDayId != null) {
      return _program!.days.firstWhere(
        (d) => d.id == _overrideDayId,
        orElse: () => _suggestedDay,
      );
    }
    return _suggestedDay;
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;
    if (program == null || program.days.isEmpty) {
      // Still loading, or the selected custom program has no days yet.
      return const SizedBox.shrink();
    }
    final nextDay = _nextDay;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Good morning', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Harry', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 32),

            _ThisWeekCard(completedCount: _completedThisWeek),
            const SizedBox(height: 16),

            const WeightProgressCard(),
            const SizedBox(height: 16),

            _DaySelector(
              days: program.days,
              selectedDayId: nextDay.id,
              suggestedDayId: _suggestedDay.id,
              onSelect: (id) => setState(() {
                _overrideDayId = id == _suggestedDay.id ? null : id;
              }),
            ),
            const SizedBox(height: 12),

            _NextDayCard(
              day: nextDay,
              isSuggested: nextDay.id == _suggestedDay.id,
              onViewFull: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(day: nextDay),
                  ),
                );
                setState(() {}); // reflect any exercise swaps
              },
              onStart: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkoutScreen(
                      program: program,
                      day: nextDay,
                      isFirstWeek: _isFirstWeek,
                      previousRestAverages: _restRecommendations,
                    ),
                  ),
                );
                _loadStats(); // refresh after returning
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThisWeekCard extends StatelessWidget {
  final int completedCount;
  const _ThisWeekCard({required this.completedCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('This Week', style: Theme.of(context).textTheme.titleMedium),
            Text(
              'Workouts: $completedCount completed',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<WorkoutDay> days;
  final String selectedDayId;
  final String suggestedDayId;
  final ValueChanged<String> onSelect;

  const _DaySelector({
    required this.days,
    required this.selectedDayId,
    required this.suggestedDayId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1A1A1A);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      children: [
        for (final day in days) ...[
          GestureDetector(
            onTap: () => onSelect(day.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: day.id == selectedDayId ? accent : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: day.id == selectedDayId ? accent : const Color(0xFFDDDAD6),
                ),
              ),
              child: Text(
                day.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: day.id == selectedDayId ? Colors.white : const Color(0xFF6B6B6B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
      ),
    );
  }
}

class _NextDayCard extends StatelessWidget {
  final WorkoutDay day;
  final bool isSuggested;
  final VoidCallback onStart;
  final VoidCallback onViewFull;
  const _NextDayCard({
    required this.day,
    required this.isSuggested,
    required this.onStart,
    required this.onViewFull,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onViewFull,
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuggested ? 'UP NEXT' : 'YOUR PICK',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(day.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day.description, style: Theme.of(context).textTheme.bodyMedium),
                Text('${day.estimatedMinutes} min', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onStart,
                    child: const Text('Start Workout'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onViewFull,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    side: const BorderSide(color: Color(0xFFDDDAD6)),
                  ),
                  child: const Text('View Full Workout', style: TextStyle(color: Color(0xFF2C2C2C))),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
