import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final email = auth.email ?? 'No email';
    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : email.split('@').first;
    final roles = auth.roles;
    final canManageContent = auth.canSubmitProject || auth.canCreateUpdate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkGrey100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkGrey200),
            ),
            child: Row(
              children: [
                auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(auth.avatarUrl!),
                        onBackgroundImageError: (_, __) {},
                      )
                    : CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.darkGrey300,
                        child: Icon(Icons.person, color: AppColors.darkGrey700),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StyledBodyText700(displayName, size: 16),
                      const SizedBox(height: 4),
                      StyledBodyText500(email),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.darkGrey500),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles
                .map(
                  (role) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkGrey200),
                    ),
                    child: StyledBodyText600(
                      role.toUpperCase(),
                      size: 11,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (canManageContent)
            _ProfileTile(
              icon: Icons.send_outlined,
              title: 'Submit New Project',
              subtitle: 'Send project for approval before publishing',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.submitProject),
            ),
          if (canManageContent)
            _ProfileTile(
              icon: Icons.folder_copy_outlined,
              title: 'Manage My Projects',
              subtitle: 'See projects you created or contribute to',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.manageProjects),
            ),
          if (canManageContent)
            _ProfileTile(
              icon: Icons.post_add_outlined,
              title: 'Manage My Updates',
              subtitle: 'Review and edit your project updates',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.manageUpdates),
            ),
          _ProfileTile(
            icon: Icons.bookmark_border,
            title: 'Saved updates',
            subtitle: 'Review updates you bookmarked',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.groups_outlined,
            title: 'Followed projects',
            subtitle: 'Manage your tracked projects',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password and account safety',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkGrey200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.darkGrey600),
        title: StyledBodyText700(title, size: 14),
        subtitle: StyledBodyText500(subtitle, size: 12),
        trailing: Icon(Icons.chevron_right, color: AppColors.darkGrey500),
        onTap: onTap,
      ),
    );
  }
}
