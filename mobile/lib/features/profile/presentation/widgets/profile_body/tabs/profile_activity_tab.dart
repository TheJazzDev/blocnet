import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_tab_bar.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Activity" tab: the user's own recent actions on Blocnet.
class ProfileActivityTab extends StatelessWidget {
  const ProfileActivityTab({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final profileStore = context.watch<UserProfileStore>();
    final isCardMode =
        context.watch<FeedViewModeStore>().mode == FeedViewMode.card;
    final items = List<ActivityItem>.from(profileStore.activity);

    if (profileStore.isLoadingActivity && items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: accent, strokeWidth: 2),
      );
    }

    if (items.isEmpty) {
      return const ProfileTabEmptyState(
        icon: Icons.history_rounded,
        title: 'No activity yet',
      );
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ProfileTabTileFrame(
          isCardMode: isCardMode,
          showDivider: !isCardMode && index != items.length - 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt_rounded, size: AppIcon.sm, color: accent),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpace.hair),
                    Text(
                      getTimeStamp(item.createdAt),
                      style: AppTypography.custom(
                        color: AppColors.textFaint,
                        size: AppText.captionSize,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
