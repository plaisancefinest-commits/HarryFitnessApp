import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Displays a picture at a zoom level determined by [progress].
///
/// At progress 0.0 the image is zoomed to 8× (showing ~1/64th of the area —
/// unrecognizable). At 1.0 the full image is visible.
///
/// When [animate] is true, the widget transitions from the previous zoom
/// level to the current one over 1.5 seconds.
class PictureRevealWidget extends StatelessWidget {
  final String imagePath;

  /// 0.0 = fully zoomed (start), 1.0 = all workouts done.
  final double progress;

  /// Previous progress value — used to animate from → to when [animate] is true.
  final double previousProgress;

  /// Whether to animate the zoom-out transition.
  final bool animate;

  /// Whether the full reveal conditions are met (all workouts + past end date).
  final bool fullyRevealed;

  static const _maxScale = 8.0;
  static const _minScale = 1.0;

  const PictureRevealWidget({
    super.key,
    required this.imagePath,
    required this.progress,
    this.previousProgress = 0.0,
    this.animate = false,
    this.fullyRevealed = false,
  });

  static double scaleForProgress(double p) =>
      _maxScale - (p.clamp(0.0, 1.0) * (_maxScale - _minScale));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(
          begin: scaleForProgress(previousProgress),
          end: scaleForProgress(progress),
        ),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) => _buildFrame(context, scale, colors),
      );
    }

    return _buildFrame(context, scaleForProgress(progress), colors);
  }

  Widget _buildFrame(BuildContext context, double scale, AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: fullyRevealed
            ? Border.all(color: colors.warm, width: 3)
            : Border.all(color: colors.border, width: 1),
        boxShadow: fullyRevealed
            ? [BoxShadow(color: colors.warm.withValues(alpha: 0.4), blurRadius: 16)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            SizedBox.expand(
              child: Transform.scale(
                scale: scale,
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            if (fullyRevealed)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Picture Revealed!',
                      style: TextStyle(
                        color: colors.onAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
