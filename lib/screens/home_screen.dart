import 'package:flutter/material.dart';
import '../data/sample_programs.dart';
import '../models/program.dart';
import '../services/database_service.dart';
import 'active_workout_screen.dart';
import 'history_screen.dart';

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
      body: _selectedTab == 0 ? const _DashboardTab() : const HistoryScreen(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
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

  final program = samplePrograms.first;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = DatabaseService.instance;
    final count = await db.getSessionsThisWeek();
    final hasHistory = await db.hasCompletedSessionForProgram(program.id);
    final recs = hasHistory ? await db.getRestRecommendations(program.id) : <String, int>{};
    if (mounted) {
      setState(() {
        _completedThisWeek = count;
        _isFirstWeek = !hasHistory;
        _restRecommendations = recs;
      });
    }
  }

  WorkoutDay get _nextDay {
    // In a real app this would track which day was last done
    return program.days.first;
  }

  @override
  Widget build(BuildContext context) {
    final nextDay = _nextDay;

    return SafeArea(
      child: Padding(
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

            _NextDayCard(
              day: nextDay,
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

class _NextDayCard extends StatelessWidget {
  final WorkoutDay day;
  final VoidCallback onStart;
  const _NextDayCard({required this.day, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEXT DAY',
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
                  onPressed: () {},
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
    );
  }
}
