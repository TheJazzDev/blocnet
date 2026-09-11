import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_tab_bar.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Following" tab: the Gems the user follows.
class ProfileFollowingTab extends StatelessWidget {
  const ProfileFollowingTab({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final profileStore = context.watch<UserProfileStore>();
    final isCardMode =
        context.watch<FeedViewModeStore>().mode == FeedViewMode.card;
    final watchlist = List<Project>.from(profileStore.watchlist);

    if (profileStore.isLoadingWatchlist && watchlist.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: accent, strokeWidth: 2),
      );
    }

    if (watchlist.isEmpty) {
      return const ProfileTabEmptyState(
        icon: Icons.visibility_outlined,
        title: 'No followed gems yet',
        hint: 'Tap Follow on any gem to add it here.',
      );
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: watchlist.length,
      itemBuilder: (context, index) {
        return ProfileTabTileFrame(
          isCardMode: isCardMode,
          showDivider: !isCardMode && index != watchlist.length - 1,
          child: _FollowedGem(project: watchlist[index], isCardMode: isCardMode),
        );
      },
    );
  }
}

class _FollowedGem extends StatelessWidget {
  const _FollowedGem({required this.project, required this.isCardMode});

  final Project project;
  final bool isCardMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 13,
                  weight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isCardMode ? AppColors.bgElevated : AppColors.bgSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                project.primaryTag.name,
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          project.description,
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 11,
            weight: FontWeight.w400,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.people_outline, size: 14, color: AppColors.textFaint),
            const SizedBox(width: 5),
            Text(
              '${project.followersCount} followers',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 10,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
