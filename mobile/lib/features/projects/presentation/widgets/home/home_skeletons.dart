import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

/// Skeletons for the Home tab, shown only when a section has no cached
/// payload to paint on the first frame. Each one mirrors the real card's
/// silhouette so the swap to live content does not shift the layout.

class _SkeletonSurface extends StatelessWidget {
  const _SkeletonSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Container(
        width: double.infinity,
        padding: AppSpace.card,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: child,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.widthFactor, this.height = AppText.captionSize});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: SkeletonBox(height: height, radius: AppRadius.smValue),
    );
  }
}

/// Header line + headline + stats line, like [EdgeBriefTeaserCard].
class EdgeBriefSkeleton extends StatelessWidget {
  const EdgeBriefSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(
                width: AppIcon.sm,
                height: AppIcon.sm,
                radius: AppRadius.fullValue,
              ),
              AppSpace.wGapSm,
              const Expanded(child: _Line(widthFactor: 0.45)),
            ],
          ),
          AppSpace.gapMd,
          const _Line(widthFactor: 0.9, height: AppText.labelSize),
          AppSpace.gapSm,
          const _Line(widthFactor: 0.55),
        ],
      ),
    );
  }
}

/// Stack of feed-card sized rows for the first-frame empty feed.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key, this.items = 4});

  final int items;

  @override
  Widget build(BuildContext context) {
    return SkeletonList(
      items: items,
      itemHeight: AppSpace.xxxl * 2,
      spacing: AppSpace.md,
    );
  }
}
