import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/widgets/profile_tile.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "More" and "Account" tiles. Every entry here is shown to everyone; the
/// only role-gated rows are System Alerts (owner/dev, matching the
/// backend guard), the received-tips shortcut for hunters and the
/// Become a Hunter entry for users who do not hold the role yet.
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
    final applicationPending =
        context.watch<HunterApplicationStore>().isPending;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('More'),
          const SizedBox(height: 8),
          if (!isHunter)
            ProfileTile(
              icon: Icons.radar_rounded,
              iconColor: AppColors.primary400,
              title: 'Become a Hunter',
              subtitle: applicationPending
                  ? 'Application pending review'
                  : 'Post updates for gems and earn tips',
              trailing: applicationPending
                  ? ProfileTilePill(
                      label: 'PENDING',
                      color: AppColors.warning500,
                    )
                  : null,
              onTap: () => navigator.pushNamed(AppRoutes.becomeHunter),
            ),
          ProfileTile(
            icon: Icons.emoji_events_outlined,
            title: 'Badges',
            subtitle: 'View and manage your earned badges',
            onTap: () => navigator.pushNamed(AppRoutes.badges),
          ),
          ProfileTile(
            icon: Icons.task_alt_outlined,
            title: 'Quests',
            subtitle: 'Complete quests to earn rewards',
            onTap: () => navigator.pushNamed(AppRoutes.quests),
          ),
          ProfileTile(
            icon: Icons.stairs_outlined,
            title: 'Levels',
            subtitle: 'See every level, its requirements and your progress',
            onTap: () => navigator.pushNamed(AppRoutes.levels),
          ),
          ProfileTile(
            icon: Icons.volunteer_activism_outlined,
            title: 'Tip History',
            subtitle: 'See all tips you sent to hunters',
            onTap: () => navigator.pushNamed(AppRoutes.tipsHistory),
          ),
          if (isHunter)
            ProfileTile(
              icon: Icons.history_edu_outlined,
              title: 'Tip History (Received)',
              subtitle: 'Review tips you received from supporters',
              onTap: () => navigator.pushNamed(
                AppRoutes.tipsHistory,
                arguments: const {'direction': 'received'},
              ),
            ),
          ProfileTile(
            icon: Icons.redeem_outlined,
            title: 'Referral Code',
            subtitle: 'View and manage your referral code',
            onTap: () => navigator.pushNamed(AppRoutes.referralCode),
          ),
          ProfileTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Account preferences',
            onTap: () => navigator.pushNamed(AppRoutes.settings),
          ),
          ProfileTile(
            icon: Icons.support_agent_outlined,
            title: 'Help & Support',
            subtitle: 'Get help with account and app issues',
            showDivider: false,
            onTap: () => navigator.pushNamed(AppRoutes.helpSupport),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Account'),
          const SizedBox(height: 8),
          // Backend allows only owner/dev on /audit-log/system-alerts.
          if (auth.isOwner || auth.isDev)
            ProfileTile(
              icon: Icons.warning_amber_rounded,
              title: 'System Alerts',
              subtitle: 'Operational warnings and error events',
              onTap: () => navigator.pushNamed(AppRoutes.systemAlerts),
            ),
          ProfileTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            iconColor: AppColors.textMuted,
            titleColor: AppColors.textSecondary,
            showDivider: false,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}
