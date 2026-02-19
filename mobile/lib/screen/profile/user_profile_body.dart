import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/services/user_profile_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

part 'user_profile_body_hero.part.dart';
part 'user_profile_body_tabs.part.dart';
part 'user_profile_body_shared.part.dart';

/// Profile body shown when the user is in User space (no hunter role, or
/// hunter/admin who has not switched to Hunter space).
class UserProfileBody extends StatefulWidget {
  const UserProfileBody({
    super.key,
    required this.onSignOut,
    required this.auth,
  });

  final VoidCallback onSignOut;
  final AuthStore auth;

  @override
  State<UserProfileBody> createState() => _UserProfileBodyState();
}

class _UserProfileBodyState extends State<UserProfileBody> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProfileStore>().fetchInitialOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final followingCount = context.watch<UserProfileStore>().watchlist.length;
    final auth = widget.auth;

    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? '').split('@').first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserHero(
            displayName: displayName,
            avatarUrl: auth.avatarUrl,
            walletAddress: auth.walletAddress,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                _StatCard(value: followingCount.toString(), label: 'Following'),
                const SizedBox(width: 10),
                const _StatCard(value: '—', label: 'Tips Sent'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileTabBar(
            tabs: const ['Bookmarks', 'Watchlist', 'History'],
            activeIndex: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
          const SizedBox(height: 12),
          if (_tabIndex == 0) const _BookmarksTab(),
          if (_tabIndex == 1) const _WatchlistTab(),
          if (_tabIndex == 2) const _HistoryTab(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('More'),
                const SizedBox(height: 8),
                _ProfileTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update your avatar and public details',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.editProfile),
                ),
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'View alerts and activity',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                ),
                _ProfileTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Account preferences',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
                const SizedBox(height: 12),
                const _SectionLabel('Account'),
                const SizedBox(height: 8),
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  iconColor: AppColors.textMuted,
                  titleColor: AppColors.textSecondary,
                  onTap: widget.onSignOut,
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
