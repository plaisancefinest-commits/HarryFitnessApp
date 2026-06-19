import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sample_programs.dart';
import '../models/program.dart';
import '../models/recovery_check.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../data/exercise_library.dart';
import '../theme/app_colors.dart';
import 'recovery_check_screen.dart';
import '../widgets/cardio_card.dart';
import '../widgets/set_program_weeks_dialog.dart';
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
        backgroundColor: context.colors.card,
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
  int _currentRotation = 1;
  int _sessionsInRotation = 0;
  bool _rotationJustCompleted = false;
  int? _totalRotations;
  bool _isFirstWeek = true;
  Map<String, int> _restRecommendations = {};
  String? _lastCompletedDayId;
  String? _overrideDayId; // user tapped a pill; null = follow rotation
  bool _showRecoveryCheck = false;
  bool _recoveryIsPreWeek = true;

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
    final totalSessions =
        await db.getCompletedSessionCountForProgram(program.id);
    final rotationState =
        DatabaseService.computeRotation(totalSessions, program.days.length);
    final programWeeks = await db.getProgramWeeks(program.id);
    final hasHistory = await db.hasCompletedSessionForProgram(program.id);
    // One-time reset of stale rest recommendations (skipped rests logged as
    // 1-second averages were polluting the countdown timer). Remove after
    // one release cycle.
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('rest_recs_reset_v1')) {
      await db.clearRestRecommendations(program.id);
      await prefs.setBool('rest_recs_reset_v1', true);
    }
    final recs = hasHistory ? await db.getRestRecommendations(program.id) : <String, int>{};
    final lastDayId = await db.getLastCompletedDayId(program.id);
    final inProgress = await db.getInProgressWorkout();
    if (mounted) {
      setState(() {
        _program = program;
        _currentRotation = rotationState.rotation;
        _sessionsInRotation = rotationState.sessionsInRotation;
        _rotationJustCompleted = rotationState.justCompleted;
        _totalRotations = programWeeks;
        _isFirstWeek = !hasHistory;
        _restRecommendations = recs;
        _lastCompletedDayId = lastDayId;
        _overrideDayId = null; // a finished workout resets any manual pick
      });
      if (inProgress != null) {
        _showResumeDialog(program, inProgress);
      }
      // Check recovery prompt
      await _checkRecovery(program);
    }
  }

  Future<void> _checkRecovery(Program program) async {
    final db = DatabaseService.instance;

    // Show pre-rotation recovery check when a rotation just completed
    if (!_rotationJustCompleted) {
      if (mounted) setState(() => _showRecoveryCheck = false);
      return;
    }

    final nextRotation = _currentRotation + 1;
    final existing =
        await db.getRecoveryCheckForRotation(program.id, nextRotation, true);
    if (mounted) {
      setState(() {
        _showRecoveryCheck = existing == null;
        _recoveryIsPreWeek = true;
      });
    }
  }

  Future<void> _openRecoveryCheck() async {
    if (_program == null) return;
    final muscles = muscleGroupsForProgram(_program!.days);
    final rotNum = _recoveryIsPreWeek
        ? _currentRotation + 1
        : _currentRotation;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecoveryCheckScreen(
          programId: _program!.id,
          muscleGroups: muscles,
          isPreWeek: _recoveryIsPreWeek,
          rotationNumber: rotNum,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() => _showRecoveryCheck = false);
    }
  }

  Future<void> _showResumeDialog(
      Program program, Map<String, dynamic> data) async {
    final dayId = data['dayId'] as String?;
    final savedAt = data['savedAt'] as String?;
    final day = program.days.where((d) => d.id == dayId).firstOrNull;
    if (day == null) {
      // Day no longer exists in program — discard
      await DatabaseService.instance.clearInProgressWorkout();
      if (mounted) setState(() {});
      return;
    }

    final timeLabel = savedAt != null
        ? _formatSavedTime(DateTime.parse(savedAt))
        : '';

    if (!mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resume workout?'),
        content: Text(
            'You have an unfinished ${day.name} workout${timeLabel.isNotEmpty ? ' from $timeLabel' : ''}.\n\nResume or discard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );

    if (resume == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            program: program,
            day: day,
            isFirstWeek: _isFirstWeek,
            previousRestAverages: _restRecommendations,
            resumeData: data,
          ),
        ),
      );
      _loadStats();
    } else {
      await DatabaseService.instance.clearInProgressWorkout();
      if (mounted) setState(() {});
    }
  }

  String _formatSavedTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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

  Future<void> _pickTheme(BuildContext context) async {
    final provider = context.read<ThemeProvider>();
    final choice = await showDialog<AppThemeChoice>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Theme', style: Theme.of(context).textTheme.titleLarge),
        children: [
          _ThemeOption(
            label: 'Cream',
            subtitle: 'Light neutral · orange',
            palette: AppColors.cream,
            selected: provider.choice == AppThemeChoice.cream,
            onTap: () => Navigator.pop(context, AppThemeChoice.cream),
          ),
          _ThemeOption(
            label: 'Black & Gold',
            subtitle: 'Dark black · gold accent',
            palette: AppColors.blackGold,
            selected: provider.choice == AppThemeChoice.blackGold,
            onTap: () => Navigator.pop(context, AppThemeChoice.blackGold),
          ),
          _ThemeOption(
            label: 'Carabinero',
            subtitle: 'Shell red · black outline',
            palette: AppColors.carabinero,
            selected: provider.choice == AppThemeChoice.carabinero,
            onTap: () => Navigator.pop(context, AppThemeChoice.carabinero),
          ),
          _ThemeOption(
            label: 'Knicks',
            subtitle: 'Royal blue · orange accent',
            palette: AppColors.knicks,
            selected: provider.choice == AppThemeChoice.knicks,
            onTap: () => Navigator.pop(context, AppThemeChoice.knicks),
          ),
        ],
      ),
    );
    if (choice != null) await provider.setChoice(choice);
  }

  Future<void> _setWeeks(BuildContext context) async {
    if (_program == null) return;
    final currentWeeks =
        await DatabaseService.instance.getProgramWeeks(_program!.id);
    if (!context.mounted) return;
    await showDialog<int>(
      context: context,
      builder: (context) => SetProgramWeeksDialog(
        program: _program!,
        currentWeeks: currentWeeks,
      ),
    );
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Harry',
                          style: Theme.of(context).textTheme.displaySmall),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _pickTheme(context),
                  icon: Icon(Icons.palette_outlined,
                      size: 22, color: context.colors.muted),
                  tooltip: 'Theme',
                ),
                IconButton(
                  onPressed: () => _setWeeks(context),
                  icon: Icon(Icons.timer_outlined,
                      size: 22, color: context.colors.muted),
                  tooltip: 'Program Duration',
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_showRecoveryCheck) ...[
              _RecoveryCheckCard(
                isPreWeek: _recoveryIsPreWeek,
                onTap: _openRecoveryCheck,
              ),
              const SizedBox(height: 16),
            ],

            _ThisWeekCard(
              currentRotation: _currentRotation,
              sessionsInRotation: _sessionsInRotation,
              totalDaysPerRotation: program.days.length,
              totalRotations: _totalRotations,
              justCompleted: _rotationJustCompleted,
            ),
            const SizedBox(height: 16),

            const WeightProgressCard(),
            const SizedBox(height: 16),

            const CardioCard(),
            const SizedBox(height: 16),

            _DaySelector(
              weekSchedule: program.weekSchedule,
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

class _RecoveryCheckCard extends StatelessWidget {
  final bool isPreWeek;
  final VoidCallback onTap;

  const _RecoveryCheckCard({required this.isPreWeek, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.healing, color: c.data, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPreWeek ? 'Pre-Week Recovery Check' : 'End-of-Week Recovery',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'How are your muscles feeling?',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.borderStrong),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThisWeekCard extends StatelessWidget {
  final int currentRotation;
  final int sessionsInRotation;
  final int totalDaysPerRotation;
  final int? totalRotations;
  final bool justCompleted;

  const _ThisWeekCard({
    required this.currentRotation,
    required this.sessionsInRotation,
    required this.totalDaysPerRotation,
    required this.totalRotations,
    required this.justCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final weekLabel = totalRotations != null
        ? 'Week $currentRotation of $totalRotations'
        : 'Week $currentRotation';
    final progress = justCompleted
        ? 'Complete!'
        : '$sessionsInRotation of $totalDaysPerRotation days';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(weekLabel, style: Theme.of(context).textTheme.titleMedium),
            Text(
              progress,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: justCompleted ? c.green : null,
                    fontWeight: justCompleted ? FontWeight.w600 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<WorkoutDay?> weekSchedule;
  final String selectedDayId;
  final String suggestedDayId;
  final ValueChanged<String> onSelect;

  const _DaySelector({
    required this.weekSchedule,
    required this.selectedDayId,
    required this.suggestedDayId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = c.accent;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final slot in weekSchedule) ...[
            if (slot == null)
              // Rest day — visual only, not tappable
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.fill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border.withAlpha(77)),
                ),
                child: Text(
                  'Rest',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.faint,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => onSelect(slot.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: slot.id == selectedDayId ? accent : c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: slot.id == selectedDayId ? accent : c.border,
                    ),
                  ),
                  child: Text(
                    slot.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          slot.id == selectedDayId ? c.onAccent : c.muted,
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
                    side: BorderSide(color: context.colors.border),
                  ),
                  child: Text('View Full Workout', style: TextStyle(color: context.colors.ink)),
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

class _ThemeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final AppColors palette;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.subtitle,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SimpleDialogOption(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          // Mini swatch previewing the palette.
          Container(
            width: 44,
            height: 32,
            decoration: BoxDecoration(
              color: palette.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.borderStrong),
            ),
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(4),
                border: palette.cardOutline == Colors.transparent
                    ? null
                    : Border.all(color: palette.cardOutline),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 14,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.warm,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (selected) Icon(Icons.check, size: 18, color: c.ink),
        ],
      ),
    );
  }
}
