import 'dart:math' as math;

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// The Mine core's two orbit rings, with the cycle's progress drawn along
/// the outer one from 12 o'clock and a glowing dot at its head — the old
/// Mine hero's orbit, now carrying the ring's meaning.
///
/// [glow] is the blur radius of the head dot's halo, animated by the card
/// while a cycle runs.
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

  /// Outer and inner orbit radii as a share of the side.
  static const double outerRatio = 0.45;
  static const double innerRatio = 0.34;

  static const double _arcStroke = 3;
  static const double _dotRadius = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    final outer = side * outerRatio;

    Paint orbit(double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: alpha);

    canvas.drawCircle(center, outer, orbit(0.22));
    canvas.drawCircle(center, side * innerRatio, orbit(0.14));

    final share = fraction.clamp(0.0, 1.0);
    if (share <= 0) return;

    const start = -math.pi / 2;
    final sweep = share * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outer),
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _arcStroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    final head = center +
        Offset(math.cos(start + sweep), math.sin(start + sweep)) * outer;
    if (glow > 0) {
      canvas.drawCircle(
        head,
        _dotRadius + glow,
        Paint()
          ..color = glowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow),
      );
    }
    canvas.drawCircle(head, _dotRadius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(MineRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.glow != glow;
}

/// Soft halo, orbit rings with progress, and the rounded-square core that
/// holds [center] (icon, number, unit).
class MineProgressRing extends StatelessWidget {
  const MineProgressRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.glowColor,
    required this.glow,
    required this.halo,
    required this.center,
    this.size = 164,
  });

  final double fraction;
  final Color color;
  final Color glowColor;
  final double glow;

  /// Opacity of the radial halo behind the core.
  final double halo;
  final Widget center;
  final double size;

  @override
  Widget build(BuildContext context) {
    final core = size * 0.52;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: halo), Colors.transparent],
              ),
            ),
            child: SizedBox.square(dimension: size),
          ),
          CustomPaint(
            key: const ValueKey('mine-ring'),
            size: Size.square(size),
            painter: MineRingPainter(
              fraction: fraction,
              color: color,
              glowColor: glowColor,
              glow: glow,
            ),
          ),
          _Core(size: core, color: color, lit: halo > 0.1, child: center),
        ],
      ),
    );
  }
}

class _Core extends StatelessWidget {
  const _Core({
    required this.size,
    required this.color,
    required this.lit,
    required this.child,
  });

  final double size;
  final Color color;
  final bool lit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: AppSpace.allXs,
      decoration: BoxDecoration(
        borderRadius: AppRadius.xl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgElevated, AppColors.bgSurface],
        ),
        border: Border.all(color: AppColors.borderMuted),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: lit ? 0.24 : 0.1),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: child)),
    );
  }
}
