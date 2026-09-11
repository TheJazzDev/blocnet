import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// Lightweight pulse skeleton used while list pages load, instead of a bare
/// centered spinner. No package dependency: one repeating opacity animation
/// shared by every box under a [SkeletonPulse].
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.45, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// A single rounded placeholder block.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A card-shaped placeholder: leading square, two text lines, trailing pill.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 72});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 44, height: 18, radius: 999),
        ],
      ),
    );
  }
}

/// A vertical list of [SkeletonCard]s wrapped in one [SkeletonPulse].
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.items = 5,
    this.itemHeight = 72,
    this.spacing = 10,
    this.padding = EdgeInsets.zero,
  });

  final int items;
  final double itemHeight;
  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            for (var i = 0; i < items; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              SkeletonCard(height: itemHeight),
            ],
          ],
        ),
      ),
    );
  }
}
