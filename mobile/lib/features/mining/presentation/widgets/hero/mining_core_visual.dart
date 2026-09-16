import 'dart:math' as math;

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// The animated bolt at the top of the Mine hero. Moves only while a cycle
/// is live.
class MiningCoreVisual extends StatelessWidget {
  const MiningCoreVisual({
    super.key,
    required this.isRunning,
    required this.orbitValue,
    required this.counterOrbitValue,
    required this.pulseValue,
    required this.waveValue,
  });

  final bool isRunning;
  final double orbitValue;
  final double counterOrbitValue;
  final double pulseValue;
  final double waveValue;

  @override
  Widget build(BuildContext context) {
    final primary = isRunning ? AppColors.primary500 : AppColors.textFaint;
    final scale = isRunning ? 0.9 + (pulseValue * 0.22) : 1.0;
    final glowOpacity = isRunning ? 0.26 + (pulseValue * 0.22) : 0.09;
    final orbitAngle = orbitValue * 2 * math.pi;
    final counterAngle = (1 - counterOrbitValue) * 2 * math.pi;
    final wobble = isRunning ? math.sin(orbitAngle) * 0.14 : 0.0;

    return SizedBox(
      width: 208,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: scale,
            child: Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: glowOpacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary500.withValues(alpha: 0.2),
              ),
            ),
          ),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary400.withValues(alpha: 0.16),
              ),
            ),
          ),
          _OrbitDot(
            angle: orbitAngle,
            radius: 78,
            color: primary,
            size: 11,
          ),
          _OrbitDot(
            angle: counterAngle,
            radius: 58,
            color:
                AppColors.primary300.withValues(alpha: isRunning ? 0.9 : 0.45),
            size: 8,
          ),
          Transform.rotate(
            angle: wobble,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xlValue),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bgElevated,
                    AppColors.bgSurface,
                  ],
                ),
                border: Border.all(color: AppColors.borderMuted),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.24),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: AppIcon.xl,
                color: primary,
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: _SignalBars(
              active: isRunning,
              waveValue: waveValue,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot({
    required this.angle,
    required this.radius,
    required this.color,
    required this.size,
  });

  final double angle;
  final double radius;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.active, required this.waveValue});

  final bool active;
  final double waveValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        final phase = (waveValue * 2 * math.pi) + (index * 0.72);
        final pulse = (math.sin(phase) + 1) / 2;
        final height = active
            ? (5 + (pulse * 15)).toDouble()
            : (4 + ((index % 2) * 2)).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.hair),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 5,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.fullValue),
              color: active
                  ? AppColors.primary400.withValues(alpha: 0.92)
                  : AppColors.textFaint.withValues(alpha: 0.65),
            ),
          ),
        );
      }),
    );
  }
}
