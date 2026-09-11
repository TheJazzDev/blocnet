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

/// Header line + subtitle + two project pills, like [AlphaRadarCard].
class RadarCardSkeleton extends StatelessWidget {
  const RadarCardSkeleton({super.key});

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
              const Expanded(child: _Line(widthFactor: 0.35)),
            ],
          ),
          AppSpace.gapSm,
          const _Line(widthFactor: 0.7, height: AppText.bodySize),
          AppSpace.gapMd,
          Row(
            children: const [
              SkeletonBox(
                width: AppSpace.xxxl * 2,
                height: AppText.titleSize,
                radius: AppRadius.fullValue,
              ),
              SizedBox(width: AppSpace.sm),
              SkeletonBox(
                width: AppSpace.xxxl * 1.5,
                height: AppText.titleSize,
                radius: AppRadius.fullValue,
              ),
            ],
          ),
        ],
      ),
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

/// Row of avatar circles with a name line under each, like the hunters in
/// [TopHuntersRow]. Rendered inside the row after the "My Updates" button.
class TopHuntersSkeleton extends StatelessWidget {
  const TopHuntersSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.lg),
              child: Column(
                children: const [
                  SkeletonBox(
                    width: AppIcon.xxl,
                    height: AppIcon.xxl,
                    radius: AppRadius.fullValue,
                  ),
                  SizedBox(height: AppSpace.xs),
                  SkeletonBox(
                    width: AppSpace.xxxl,
                    height: AppText.captionSize,
                    radius: AppRadius.smValue,
                  ),
                ],
              ),
            ),
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
