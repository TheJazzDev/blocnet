import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/widgets/profile_tile.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:flutter/material.dart';

/// Hunter content shortcuts (submit / manage gems / manage updates).
/// Shown to anyone with the hunter, admin, owner or dev role.
class HunterContentSection extends StatelessWidget {
  const HunterContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Content'),
          const SizedBox(height: AppSpace.sm),
          ProfileTile(
            icon: Icons.send_outlined,
            title: 'Submit New Gem',
            subtitle: 'Send a gem for approval before publishing',
            onTap: () => navigator.pushNamed(AppRoutes.submitProject),
          ),
          ProfileTile(
            icon: Icons.folder_copy_outlined,
            title: 'Manage My Gems',
            subtitle: 'See gems you created or contribute to',
            onTap: () => navigator.pushNamed(AppRoutes.manageProjects),
          ),
          ProfileTile(
            icon: Icons.post_add_outlined,
            title: 'Manage My Updates',
            subtitle: 'Review and edit your hunter updates',
            showDivider: false,
            onTap: () => navigator.pushNamed(AppRoutes.manageUpdates),
          ),
        ],
      ),
    );
  }
}
