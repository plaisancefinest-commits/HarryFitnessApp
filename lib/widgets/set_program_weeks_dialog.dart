import 'package:flutter/material.dart';
import '../models/program.dart';
import '../services/database_service.dart';
import '../services/picture_challenge_service.dart';
import '../theme/app_colors.dart';

/// Dialog for setting the number of weeks for a program.
/// If the program qualifies for a picture reveal, prompts the user to start one.
class SetProgramWeeksDialog extends StatefulWidget {
  final Program program;
  final int? currentWeeks;

  const SetProgramWeeksDialog({
    super.key,
    required this.program,
    this.currentWeeks,
  });

  @override
  State<SetProgramWeeksDialog> createState() => _SetProgramWeeksDialogState();
}

class _SetProgramWeeksDialogState extends State<SetProgramWeeksDialog> {
  late int _weeks;
  bool _eligible = false;

  @override
  void initState() {
    super.initState();
    _weeks = widget.currentWeeks ?? 4;
    _checkEligibility();
  }

  void _checkEligibility() {
    setState(() {
      _eligible =
          PictureChallengeService.isEligible(widget.program, _weeks);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalWorkouts = widget.program.days.length * _weeks;

    return AlertDialog(
      title: Text('Program Duration',
          style: Theme.of(context).textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.program.days.length} days per rotation',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _weeks > 1
                    ? () {
                        setState(() => _weeks--);
                        _checkEligibility();
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '$_weeks weeks',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: _weeks < 52
                    ? () {
                        setState(() => _weeks++);
                        _checkEligibility();
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalWorkouts total workouts',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_eligible) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.fill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.data.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: colors.data, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Qualifies for Picture Reveal!',
                      style: TextStyle(
                        color: colors.data,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await DatabaseService.instance
                .saveProgramWeeks(widget.program.id, _weeks);
            if (_eligible) {
              // Check if a challenge already exists for this program
              final existing = await PictureChallengeService.getActiveChallenge(
                  widget.program.id);
              if (existing == null) {
                await PictureChallengeService.createChallenge(
                    widget.program, _weeks);
              }
            }
            if (context.mounted) Navigator.pop(context, _weeks);
          },
          child: Text(_eligible ? 'Start Challenge' : 'Set'),
        ),
      ],
    );
  }
}
