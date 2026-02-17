import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final followingCount =
        context.watch<ProjectsStore>().followedProjectIds.length;

    final email = auth.email ?? '';
    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : email.split('@').first;
    final username = auth.username;
    final memberSince = auth.memberSince;
    final roles = auth.roles;
    final canManageContent = auth.canSubmitProject || auth.canCreateUpdate;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _ProfileAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  _ProfileHeader(
                    displayName: displayName,
                    email: email,
                    username: username,
                    memberSince: memberSince,
                    avatarUrl: auth.avatarUrl,
                    roles: roles,
                  ),
                  const SizedBox(height: 16),
                  _StatsRow(followingCount: followingCount),
                  const SizedBox(height: 20),
                  if (canManageContent) ...[
                    _SectionLabel('Content'),
                    const SizedBox(height: 8),
                    _ProfileTile(
                      icon: Icons.send_outlined,
                      title: 'Submit New Project',
                      subtitle: 'Send a project for approval before publishing',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.submitProject),
                    ),
                    _ProfileTile(
                      icon: Icons.folder_copy_outlined,
                      title: 'Manage My Projects',
                      subtitle: 'See projects you created or contribute to',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.manageProjects),
                    ),
                    _ProfileTile(
                      icon: Icons.post_add_outlined,
                      title: 'Manage My Updates',
                      subtitle: 'Review and edit your project updates',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.manageUpdates),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _SectionLabel('Activity'),
                  const SizedBox(height: 8),
                  _ProfileTile(
                    icon: Icons.bookmark_border,
                    title: 'Saved Updates',
                    subtitle: 'Review updates you bookmarked',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.groups_outlined,
                    title: 'Followed Projects',
                    subtitle: 'Manage your tracked projects',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _SectionLabel('More'),
                  const SizedBox(height: 8),
                  _ProfileTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet',
                    subtitle: 'BNT balance, tips, and rewards — coming soon',
                    trailing: _SoonBadge(),
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.wallet),
                  ),
                  _ProfileTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Account preferences and notifications',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                  _ProfileTile(
                    icon: Icons.security_outlined,
                    title: 'Security',
                    subtitle: 'Password and account safety',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  _ProfileTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    iconColor: AppColors.textMuted,
                    titleColor: AppColors.textSecondary,
                    onTap: () => _confirmSignOut(context, auth),
                  ),
                  const SizedBox(height: 32),
                ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthStore auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: AppColors.textMuted,
            fontFamily: 'Geist',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Geist',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.teal400,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
    }
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.username,
    required this.memberSince,
    required this.avatarUrl,
    required this.roles,
  });

  final String displayName;
  final String email;
  final String? username;
  final DateTime? memberSince;
  final String? avatarUrl;
  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    final memberSinceText = memberSince != null
        ? 'Member since ${DateFormat('MMM yyyy').format(memberSince!)}'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(avatarUrl: avatarUrl, displayName: displayName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (username != null && username!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: TextStyle(
                          color: AppColors.teal400,
                          fontSize: 12,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (username == null || username!.isEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontFamily: 'Geist',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (memberSinceText != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: AppColors.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            memberSinceText,
                            style: TextStyle(
                              color: AppColors.textFaint,
                              fontSize: 11,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: roles.map((role) => _RoleBadge(role: role)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.followingCount});

  final int followingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(value: '—', label: 'Followers'),
        _StatDivider(),
        _StatCell(value: followingCount.toString(), label: 'Following'),
        _StatDivider(),
        _StatCell(value: '—', label: 'Updates Read'),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 10,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 8);
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.displayName});

  final String? avatarUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initials = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.teal500.withValues(alpha: 0.3),
            AppColors.primary500.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
          color: AppColors.teal500.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.teal300,
            fontSize: 20,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Role Badge ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.teal500.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: AppColors.teal300,
          fontSize: 10,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.textFaint,
        fontSize: 10,
        fontFamily: 'Geist',
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─── Soon Badge ───────────────────────────────────────────────────────────────

class _SoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.teal500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.teal500.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'Soon',
        style: TextStyle(
          color: AppColors.teal400,
          fontSize: 9,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Profile Tile ─────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Icon(
                icon,
                size: 17,
                color: iconColor ?? AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
