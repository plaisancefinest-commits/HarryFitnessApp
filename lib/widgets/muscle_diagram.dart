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

class _BodyPainter extends CustomPainter {
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final DiagramSide side;

  static const _primary = Color(0xFF1A1A1A);
  static const _secondary = Color(0xFFAAAAAA);
  static const _base = Color(0xFFE8E4DF);
  static const _outline = Color(0xFFCCC8C2);

  _BodyPainter({
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.side,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final scale = size.height / 200.0;

    if (side == DiagramSide.front) {
      _drawFront(canvas, cx, scale);
    } else {
      _drawBack(canvas, cx, scale);
    }
  }

  void _drawFront(Canvas canvas, double cx, double s) {
    // Head
    _drawOval(canvas, cx, 12 * s, 10 * s, 12 * s, _base, _outline);

    // Neck
    _drawRect(canvas, cx - 4 * s, 22 * s, 8 * s, 8 * s, _base, _outline);

    // Torso
    _drawRect(canvas, cx - 22 * s, 30 * s, 44 * s, 55 * s, _base, _outline);

    // Chest region (upper torso)
    _drawRect(
      canvas, cx - 22 * s, 30 * s, 44 * s, 25 * s,
      _colorFor(MuscleGroup.chest), _outline,
    );

    // Core / abs (lower torso)
    _drawRect(
      canvas, cx - 14 * s, 58 * s, 28 * s, 27 * s,
      _colorFor(MuscleGroup.core), _outline,
    );

    // Left shoulder
    _drawOval(canvas, cx - 28 * s, 35 * s, 10 * s, 14 * s,
        _colorFor(MuscleGroup.shoulders), _outline);

    // Right shoulder
    _drawOval(canvas, cx + 28 * s, 35 * s, 10 * s, 14 * s,
        _colorFor(MuscleGroup.shoulders), _outline);

    // Left upper arm (biceps)
    _drawRect(canvas, cx - 36 * s, 46 * s, 10 * s, 22 * s,
        _colorFor(MuscleGroup.biceps), _outline);

    // Right upper arm (biceps)
    _drawRect(canvas, cx + 26 * s, 46 * s, 10 * s, 22 * s,
        _colorFor(MuscleGroup.biceps), _outline);

    // Left forearm
    _drawRect(canvas, cx - 37 * s, 70 * s, 9 * s, 20 * s,
        _colorFor(MuscleGroup.forearms), _outline);

    // Right forearm
    _drawRect(canvas, cx + 28 * s, 70 * s, 9 * s, 20 * s,
        _colorFor(MuscleGroup.forearms), _outline);

    // Left quads
    _drawRect(canvas, cx - 21 * s, 87 * s, 18 * s, 40 * s,
        _colorFor(MuscleGroup.quads), _outline);

    // Right quads
    _drawRect(canvas, cx + 3 * s, 87 * s, 18 * s, 40 * s,
        _colorFor(MuscleGroup.quads), _outline);

    // Left calves
    _drawRect(canvas, cx - 20 * s, 132 * s, 16 * s, 30 * s,
        _colorFor(MuscleGroup.calves), _outline);

    // Right calves
    _drawRect(canvas, cx + 4 * s, 132 * s, 16 * s, 30 * s,
        _colorFor(MuscleGroup.calves), _outline);
  }

  void _drawBack(Canvas canvas, double cx, double s) {
    // Head
    _drawOval(canvas, cx, 12 * s, 10 * s, 12 * s, _base, _outline);

    // Neck
    _drawRect(canvas, cx - 4 * s, 22 * s, 8 * s, 8 * s, _base, _outline);

    // Torso
    _drawRect(canvas, cx - 22 * s, 30 * s, 44 * s, 55 * s, _base, _outline);

    // Back / lats region
    _drawRect(
      canvas, cx - 22 * s, 30 * s, 44 * s, 55 * s,
      _colorFor(MuscleGroup.back), _outline,
    );

    // Left shoulder (rear)
    _drawOval(canvas, cx - 28 * s, 35 * s, 10 * s, 14 * s,
        _colorFor(MuscleGroup.shoulders), _outline);

    // Right shoulder (rear)
    _drawOval(canvas, cx + 28 * s, 35 * s, 10 * s, 14 * s,
        _colorFor(MuscleGroup.shoulders), _outline);

    // Left upper arm (triceps)
    _drawRect(canvas, cx - 36 * s, 46 * s, 10 * s, 22 * s,
        _colorFor(MuscleGroup.triceps), _outline);

    // Right upper arm (triceps)
    _drawRect(canvas, cx + 26 * s, 46 * s, 10 * s, 22 * s,
        _colorFor(MuscleGroup.triceps), _outline);

    // Left forearm
    _drawRect(canvas, cx - 37 * s, 70 * s, 9 * s, 20 * s,
        _colorFor(MuscleGroup.forearms), _outline);

    // Right forearm
    _drawRect(canvas, cx + 28 * s, 70 * s, 9 * s, 20 * s,
        _colorFor(MuscleGroup.forearms), _outline);

    // Glutes
    _drawRect(canvas, cx - 21 * s, 85 * s, 42 * s, 22 * s,
        _colorFor(MuscleGroup.glutes), _outline);

    // Left hamstrings
    _drawRect(canvas, cx - 21 * s, 108 * s, 18 * s, 34 * s,
        _colorFor(MuscleGroup.hamstrings), _outline);

    // Right hamstrings
    _drawRect(canvas, cx + 3 * s, 108 * s, 18 * s, 34 * s,
        _colorFor(MuscleGroup.hamstrings), _outline);

    // Left calves
    _drawRect(canvas, cx - 20 * s, 145 * s, 16 * s, 26 * s,
        _colorFor(MuscleGroup.calves), _outline);

    // Right calves
    _drawRect(canvas, cx + 4 * s, 145 * s, 16 * s, 26 * s,
        _colorFor(MuscleGroup.calves), _outline);
  }

  Color _colorFor(MuscleGroup group) {
    if (primaryMuscles.contains(group)) return _primary;
    if (secondaryMuscles.contains(group)) return _secondary;
    return _base;
  }

  void _drawRect(Canvas canvas, double x, double y, double w, double h,
      Color fill, Color stroke) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = fill);
    canvas.drawRRect(
        rect,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
  }

  void _drawOval(Canvas canvas, double cx, double cy, double rx, double ry,
      Color fill, Color stroke) {
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    canvas.drawOval(rect, Paint()..color = fill);
    canvas.drawOval(
        rect,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.primaryMuscles != primaryMuscles ||
      old.secondaryMuscles != secondaryMuscles ||
      old.side != side;
}
