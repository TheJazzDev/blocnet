import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "More" and "Account" rows. Every entry is shown to everyone; the only
/// role-gated rows are System Alerts (owner/dev, matching the backend
/// guard), received tips for hunters, and Become a Hunter for members who
/// do not hold the role yet.
class ProfileMoreSection extends StatelessWidget {
  const ProfileMoreSection({
    super.key,
    required this.auth,
    required this.onSignOut,
  });

  final AuthStore auth;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final isHunter = auth.hasHunterSpace;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('More', icon: Icons.apps_rounded),
          AppSpace.gapSm,
          AppRowGroup(
            children: [
              if (!isHunter) const _BecomeHunterRow(),
              AppListRow(
                icon: Icons.emoji_events_outlined,
                title: 'Badges',
                onTap: () => navigator.pushNamed(AppRoutes.badges),
              ),
              AppListRow(
                icon: Icons.task_alt_outlined,
                title: 'Quests',
                onTap: () => navigator.pushNamed(AppRoutes.quests),
              ),
              AppListRow(
                icon: Icons.stairs_outlined,
                title: 'Levels',
                onTap: () => navigator.pushNamed(AppRoutes.levels),
              ),
              AppListRow(
                icon: Icons.volunteer_activism_outlined,
                title: 'Tip History',
                subtitle: 'Sent',
                onTap: () => navigator.pushNamed(AppRoutes.tipsHistory),
              ),
              if (isHunter)
                AppListRow(
                  icon: Icons.savings_outlined,
                  title: 'Tips Received',
                  onTap: () => navigator.pushNamed(
                    AppRoutes.tipsHistory,
                    arguments: const {'direction': 'received'},
                  ),
                ),
            ],
          ),
          AppSpace.gapXl,
          const SectionLabel('Account', icon: Icons.person_outline_rounded),
          AppSpace.gapSm,
          AppRowGroup(
            children: [
              AppListRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => navigator.pushNamed(AppRoutes.settings),
              ),
              AppListRow(
                icon: Icons.support_agent_outlined,
                title: 'Help & Support',
                onTap: () => navigator.pushNamed(AppRoutes.helpSupport),
              ),
              // Backend allows only owner/dev on /audit-log/system-alerts.
              if (auth.isOwner || auth.isDev)
                AppListRow(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.warning500,
                  title: 'System Alerts',
                  onTap: () => navigator.pushNamed(AppRoutes.systemAlerts),
                ),
              AppListRow(
                icon: Icons.logout_rounded,
                iconColor: AppColors.error500,
                title: 'Sign Out',
                titleColor: AppColors.error500,
                onTap: onSignOut,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BecomeHunterRow extends StatelessWidget {
  const _BecomeHunterRow();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<HunterApplicationStore>().status;
    final subtitle = switch (status) {
      HunterApplicationStatus.pending => 'Application in review',
      HunterApplicationStatus.approved => 'Approved',
      HunterApplicationStatus.rejected => 'Not approved · apply again',
      HunterApplicationStatus.none => 'Post updates, earn tips',
    };
    final pill = switch (status) {
      HunterApplicationStatus.pending =>
        AppPill.caps(label: 'Pending', color: AppColors.warning500),
      HunterApplicationStatus.approved =>
        AppPill.caps(label: 'Approved', color: AppColors.successColor),
      _ => null,
    };
    return AppListRow(
      icon: Icons.radar_rounded,
      iconColor: AppColors.tagPartnership,
      title: 'Become a Hunter',
      subtitle: subtitle,
      trailing: pill,
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.becomeHunter),
    );
  }
}
