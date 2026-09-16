import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

/// Stack of feed-card sized rows, shown only when there is no cached Home
/// payload to paint on the first frame.
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
