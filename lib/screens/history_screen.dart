import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../services/database_service.dart';
import '../data/exercise_library.dart';
import '../data/sample_programs.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<WorkoutSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = DatabaseService.instance.getCompletedSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('History', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Text(
                'No workouts yet.\nComplete your first session to see it here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _SessionCard(session: session);
            },
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  const _SessionCard({required this.session});

  String _dayName() {
    for (final p in samplePrograms) {
      for (final d in p.days) {
        if (d.id == session.workoutDayId) {
          return '${d.name} · ${d.description}';
        }
      }
    }
    return session.workoutDayId;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Group sets by exercise
    final Map<String, List<SetLog>> byExercise = {};
    for (final s in session.sets) {
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text(_dayName(), style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          _formatDate(session.date),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Text(
          '${session.sets.length} sets',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: byExercise.entries.map((entry) {
          final exerciseName = exerciseLibrary
                  .firstWhere(
                    (e) => e.id == entry.key,
                    orElse: () => exerciseLibrary.first,
                  )
                  .name;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 20, color: Color(0xFFEDEAE5)),
              Text(exerciseName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...entry.value.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          'Set ${s.setNumber}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${s.weight.toStringAsFixed(s.weight % 1 == 0 ? 0 : 1)} lbs × ${s.reps} reps',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (s.notes != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.notes!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
            ],
          );
        }).toList(),
      ),
    );
  }
}
