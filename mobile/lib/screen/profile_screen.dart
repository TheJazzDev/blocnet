import 'package:blocnet/app/theme.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.darkGrey300,
                  child: Icon(Icons.person, color: AppColors.darkGrey700),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StyledBodyText700('Your Profile', size: 16),
                      SizedBox(height: 4),
                      StyledBodyText500('profile@blocnet.app'),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.darkGrey500),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileTile(
            icon: Icons.bookmark_border,
            title: 'Saved posts',
            subtitle: 'Review updates you bookmarked',
          ),
          _ProfileTile(
            icon: Icons.groups_outlined,
            title: 'Followed projects',
            subtitle: 'Manage your tracked projects',
          ),
          _ProfileTile(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password and account safety',
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
        onTap: () {},
      ),
    );
  }
}
