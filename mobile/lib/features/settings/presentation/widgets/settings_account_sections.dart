import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_list_row.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_row_group.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/settings/presentation/widgets/settings_choice_row.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Feed layout: list or card.
class SettingsDisplaySection extends StatelessWidget {
  const SettingsDisplaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FeedViewModeStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Display', icon: Icons.view_agenda_outlined),
        AppSpace.gapSm,
        ProfileRowGroup(
          children: [
            SettingsChoiceRow<FeedViewMode>(
              icon: Icons.view_stream_outlined,
              title: 'Feed layout',
              options: const {
                FeedViewMode.list: 'List',
                FeedViewMode.card: 'Card',
              },
              selected: store.mode,
              onChanged: store.setMode,
            ),
          ],
        ),
      ],
    );
  }
}

/// Reports, blocked users and deactivation. Always reachable, even when
/// notification settings fail to load.
class SettingsPrivacySection extends StatelessWidget {
  const SettingsPrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Privacy & security', icon: Icons.lock_outline),
        AppSpace.gapSm,
        ProfileRowGroup(
          children: [
            ProfileListRow(
              icon: Icons.flag_outlined,
              title: 'My reports',
              onTap: () => navigator.pushNamed(AppRoutes.myReports),
            ),
            ProfileListRow(
              icon: Icons.block_outlined,
              title: 'Blocked users',
              onTap: () => navigator.pushNamed(AppRoutes.blockedUsers),
            ),
            ProfileListRow(
              icon: Icons.no_accounts_outlined,
              iconColor: AppColors.error500,
              title: 'Deactivate account',
              onTap: () => navigator.pushNamed(AppRoutes.deactivateAccount),
            ),
          ],
        ),
      ],
    );
  }
}
