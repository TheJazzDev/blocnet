import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/profile/domain/activity_target.dart';
import 'package:blocnet/features/profile/presentation/navigation/activity_opener.dart';
import 'package:blocnet/features/profile/presentation/widgets/activity_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_inline_state.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_row_group.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_tab_list.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef ActivityTargetOpener = void Function(
  BuildContext context,
  ActivityTarget target,
);

/// "Activity" tab: the member's own recent actions, newest first. Each row
/// opens what it refers to; rows with nothing to open carry no chevron.
class ProfileActivityTab extends StatelessWidget {
  const ProfileActivityTab({
    super.key,
    required this.accent,
    this.onOpen = openActivityTarget,
  });

  final Color accent;
  final ActivityTargetOpener onOpen;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserProfileStore>();
    final items = store.activity
        .where((item) => !hiddenActivityActions.contains(item.action))
        .toList(growable: false);

    if (items.isEmpty && (store.isLoadingActivity || !store.hasLoadedActivity)) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(color: accent, strokeWidth: 2),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      final failed = store.activityError != null;
      return ProfileRowGroup(
        children: [
          ProfileInlineState(
            icon: failed ? Icons.cloud_off_rounded : Icons.history_rounded,
            title: failed ? 'Could not load activity' : 'No activity yet',
            actionLabel: failed ? 'Retry' : null,
            onAction: failed ? store.refreshActivity : null,
          ),
        ],
      );
    }

    return ProfileTabList(
      itemCount: items.length,
      itemBuilder: (context, index) => _row(context, items[index]),
    );
  }

  Widget _row(BuildContext context, ActivityItem item) {
    final target = activityTargetFor(item);
    return ActivityCard(
      key: ValueKey('activity-${item.id}'),
      icon: _iconFor(target?.kind),
      title: item.label,
      subtitle: '',
      time: getTimeStamp(item.createdAt),
      onTap: target == null ? null : () => onOpen(context, target),
    );
  }

  static IconData _iconFor(ActivityTargetKind? kind) => switch (kind) {
        ActivityTargetKind.update => Icons.article_outlined,
        ActivityTargetKind.gem => Icons.diamond_outlined,
        ActivityTargetKind.communityPost => Icons.forum_outlined,
        ActivityTargetKind.person => Icons.person_outline_rounded,
        ActivityTargetKind.mine => Icons.bolt_rounded,
        ActivityTargetKind.referrals => Icons.group_add_outlined,
        null => Icons.history_rounded,
      };
}
