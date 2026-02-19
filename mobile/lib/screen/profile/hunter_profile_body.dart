import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

part 'hunter_profile_body_hero.part.dart';
part 'hunter_profile_body_content.part.dart';
part 'hunter_profile_body_shared.part.dart';

/// Profile body shown when the user is in Hunter space
/// (owner, admin, or hunter who has toggled to Hunter space).
class HunterProfileBody extends StatelessWidget {
  const HunterProfileBody({
    super.key,
    required this.auth,
    required this.onSignOut,
  });

  final AuthStore auth;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? '').split('@').first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HunterHero(
            displayName: displayName,
            avatarUrl: auth.avatarUrl,
            walletAddress: auth.walletAddress,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _HunterStatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.primary400,
                  label: 'Success Rate',
                  value: '85%',
                  footnote: 'Last 30 days',
                ),
                SizedBox(width: 10),
                _HunterStatCard(
                  icon: Icons.thumb_up_alt_outlined,
                  iconColor: Color(0xFF4ADE80),
                  label: 'Sentiment',
                  value: 'Positive',
                  valueSize: 16,
                  footnote: '142 reviews',
                ),
              ],
            ),
          ),
          const _CommunityVoiceSection(),
          const SizedBox(height: 20),
          const _HunterSignalsSection(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HunterSectionLabel('Content'),
                const SizedBox(height: 8),
                _HunterTile(
                  icon: Icons.send_outlined,
                  title: 'Submit New Gem',
                  subtitle: 'Send a project for approval before publishing',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.submitProject),
                ),
                _HunterTile(
                  icon: Icons.folder_copy_outlined,
                  title: 'Manage My Gems',
                  subtitle: 'See projects you created or contribute to',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.manageProjects),
                ),
                _HunterTile(
                  icon: Icons.post_add_outlined,
                  title: 'Manage My Updates',
                  subtitle: 'Review and edit your hunter updates',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.manageUpdates),
                ),
                const SizedBox(height: 12),
                const _HunterSectionLabel('More'),
                const SizedBox(height: 8),
                _HunterTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update your avatar and public details',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.editProfile),
                ),
                _HunterTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'View alerts and activity',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                ),
                _HunterTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Account preferences',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
                const SizedBox(height: 12),
                const _HunterSectionLabel('Account'),
                const SizedBox(height: 8),
                _HunterTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  iconColor: AppColors.textMuted,
                  titleColor: AppColors.textSecondary,
                  onTap: onSignOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
