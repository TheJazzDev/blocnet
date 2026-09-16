import 'dart:math' as math;

import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:flutter/material.dart';

/// The cycle ring: a track and a round-capped fill arc from 12 o'clock.
///
/// [glow] is the blur radius of the fill's halo (the design's drop-shadow),
/// animated by the card while a cycle runs.
class MineRingPainter extends CustomPainter {
  const MineRingPainter({
    required this.fraction,
    required this.color,
    required this.glowColor,
    required this.glow,
  });

  final double fraction;
  final Color color;
  final Color glowColor;
  final double glow;

  /// Stroke and radius as the design's 100-unit viewBox: 7 and 44.
  static const double strokeRatio = 0.07;
  static const double radiusRatio = 0.44;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final stroke = side * strokeRatio;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: side * radiusRatio);

    canvas.drawCircle(
      center,
      side * radiusRatio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = MinePalette.track,
    );

    final sweep = fraction.clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep <= 0) return;

    const start = -math.pi / 2;
    if (glow > 0) {
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = glowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow),
      );
    }
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(MineRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.glow != glow;
}

/// Ring plus its centre stack (icon, number, unit).
class MineProgressRing extends StatelessWidget {
  const MineProgressRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.glowColor,
    required this.glow,
    required this.center,
    this.size = 116,
  });

  final double fraction;
  final Color color;
  final Color glowColor;
  final double glow;
  final Widget center;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        key: const ValueKey('mine-ring'),
        painter: MineRingPainter(
          fraction: fraction,
          color: color,
          glowColor: glowColor,
          glow: glow,
        ),
        child: Center(child: center),
      ),
    );
  }
}
