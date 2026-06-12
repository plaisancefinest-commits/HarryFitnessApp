import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/exercise.dart';

enum DiagramSide { front, back }

class MuscleDiagram extends StatelessWidget {
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final DiagramSide side;

  const MuscleDiagram({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _BodyPainter(
          primaryMuscles: primaryMuscles,
          secondaryMuscles: secondaryMuscles,
          side: side,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Draws the figure in a Vitruvian Man pose: arms outstretched to the
/// sides, legs apart, framed by a faint circle.
class _BodyPainter extends CustomPainter {
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final DiagramSide side;

  static const _primary = Color(0xFF1A1A1A);
  static const _secondary = Color(0xFFAAAAAA);
  static const _base = Color(0xFFE8E4DF);
  static const _outline = Color(0xFFCCC8C2);
  static const _frame = Color(0xFFE0DCD6);

  // Limb angles (degrees from straight down; positive swings left on screen)
  static const _armAngle = 75.0;
  static const _legAngle = 14.0;

  _BodyPainter({
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.side,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Arms span wide, so scale on both axes.
    final s = math.min(size.height / 200.0, size.width / 170.0);
    final cx = size.width / 2;

    // Vitruvian framing circle, centered on the torso
    canvas.drawCircle(
      Offset(cx, 88 * s),
      82 * s,
      Paint()
        ..color = _frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    _drawBody(canvas, cx, s);
  }

  void _drawBody(Canvas canvas, double cx, double s) {
    final isFront = side == DiagramSide.front;

    // Head + neck
    _drawOval(canvas, cx, 14 * s, 10 * s, 12 * s, _base);
    _drawRect(canvas, cx - 4 * s, 24 * s, 8 * s, 7 * s, _base);

    // Torso base
    _drawRect(canvas, cx - 22 * s, 31 * s, 44 * s, 52 * s, _base);

    if (isFront) {
      // Chest (upper torso)
      _drawRect(canvas, cx - 22 * s, 31 * s, 44 * s, 24 * s,
          _colorFor(MuscleGroup.chest));
      // Core / abs (lower torso)
      _drawRect(canvas, cx - 14 * s, 57 * s, 28 * s, 26 * s,
          _colorFor(MuscleGroup.core));
    } else {
      // Back / lats
      _drawRect(canvas, cx - 22 * s, 31 * s, 44 * s, 52 * s,
          _colorFor(MuscleGroup.back));
    }

    // Shoulders
    _drawOval(canvas, cx - 26 * s, 36 * s, 9 * s, 9 * s,
        _colorFor(MuscleGroup.shoulders));
    _drawOval(canvas, cx + 26 * s, 36 * s, 9 * s, 9 * s,
        _colorFor(MuscleGroup.shoulders));

    // Arms — outstretched. Front shows biceps, back shows triceps.
    final upperArm =
        _colorFor(isFront ? MuscleGroup.biceps : MuscleGroup.triceps);
    final forearm = _colorFor(MuscleGroup.forearms);

    // Left arm
    final lForearmPivot = _drawLimb(
        canvas, cx - 30 * s, 38 * s, 9 * s, 23 * s, _armAngle, upperArm);
    _drawLimb(canvas, lForearmPivot.dx, lForearmPivot.dy, 8 * s, 21 * s,
        _armAngle, forearm);

    // Right arm (mirrored)
    final rForearmPivot = _drawLimb(
        canvas, cx + 30 * s, 38 * s, 9 * s, 23 * s, -_armAngle, upperArm);
    _drawLimb(canvas, rForearmPivot.dx, rForearmPivot.dy, 8 * s, 21 * s,
        -_armAngle, forearm);

    // Glutes (back view only)
    if (!isFront) {
      _drawRect(canvas, cx - 21 * s, 84 * s, 42 * s, 16 * s,
          _colorFor(MuscleGroup.glutes));
    }

    // Legs — apart. Front shows quads, back shows hamstrings.
    final thigh =
        _colorFor(isFront ? MuscleGroup.quads : MuscleGroup.hamstrings);
    final calf = _colorFor(MuscleGroup.calves);
    final thighTop = (isFront ? 84 : 100) * s;
    final thighLen = (isFront ? 42 : 32) * s;

    // Left leg
    final lCalfPivot = _drawLimb(
        canvas, cx - 12 * s, thighTop, 16 * s, thighLen, _legAngle, thigh);
    _drawLimb(canvas, lCalfPivot.dx, lCalfPivot.dy, 12 * s, 30 * s,
        _legAngle, calf);

    // Right leg (mirrored)
    final rCalfPivot = _drawLimb(
        canvas, cx + 12 * s, thighTop, 16 * s, thighLen, -_legAngle, thigh);
    _drawLimb(canvas, rCalfPivot.dx, rCalfPivot.dy, 12 * s, 30 * s,
        -_legAngle, calf);
  }

  Color _colorFor(MuscleGroup group) {
    if (primaryMuscles.contains(group)) return _primary;
    if (secondaryMuscles.contains(group)) return _secondary;
    return _base;
  }

  /// Draws a limb segment of [w]×[h] hanging from pivot (x, y), rotated
  /// [angleDeg] degrees from straight down (positive = leftward on screen).
  /// Returns the pivot point for the next segment (the limb's far end).
  Offset _drawLimb(Canvas canvas, double x, double y, double w, double h,
      double angleDeg, Color fill) {
    final a = angleDeg * math.pi / 180.0;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(a);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w / 2, 0, w, h),
      Radius.circular(w / 2),
    );
    canvas.drawRRect(rect, Paint()..color = fill);
    canvas.drawRRect(
        rect,
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
    canvas.restore();
    // Far end of the segment in canvas coordinates
    return Offset(x - h * math.sin(a), y + h * math.cos(a));
  }

  void _drawRect(Canvas canvas, double x, double y, double w, double h,
      Color fill) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = fill);
    canvas.drawRRect(
        rect,
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
  }

  void _drawOval(Canvas canvas, double cx, double cy, double rx, double ry,
      Color fill) {
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    canvas.drawOval(rect, Paint()..color = fill);
    canvas.drawOval(
        rect,
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.primaryMuscles != primaryMuscles ||
      old.secondaryMuscles != secondaryMuscles ||
      old.side != side;
}
