import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/presentation/widgets/feed/community_new_items_pill.dart';
import 'package:blocnet/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

/// Everything above the composer: a spinner while the post loads, a retry if
/// it could not be opened, otherwise the thread with a "new comments" pill.
class DiscussionBody extends StatelessWidget {
  const DiscussionBody({
    super.key,
    required this.hasPost,
    required this.loadError,
    required this.onRetry,
    required this.pendingCount,
    required this.onJumpToNewest,
    required this.thread,
  });

  final bool hasPost;
  final String? loadError;
  final VoidCallback onRetry;
  final int pendingCount;
  final VoidCallback onJumpToNewest;
  final Widget? thread;

  @override
  Widget build(BuildContext context) {
    if (!hasPost || thread == null) {
      if (loadError != null) {
        return Center(
          child: AppEmptyState.error(
            title: 'Couldn’t open this post',
            message: loadError,
            onAction: onRetry,
          ),
        );
      }
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary400,
          strokeWidth: 2,
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: thread!),
        if (pendingCount > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpace.md,
            child: Center(
              child: CommunityNewItemsPill(
                count: pendingCount,
                noun: 'comment',
                icon: Icons.arrow_downward_rounded,
                onTap: onJumpToNewest,
              ),
            ),
          ),
      ],
    );
  }
}
