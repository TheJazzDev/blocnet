import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

/// Horizontal scrollable row of top hunters (admin avatars) at the top of the feed.
class TopHuntersRow extends StatelessWidget {
  const TopHuntersRow({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<UpdatesStore>().posts;
    final canManageUpdates = context.watch<AuthStore>().canCreateUpdate;

    // Collect unique admins from posts (in order of appearance)
    final seen = <String>{};
    final admins = <Admin>[];
    for (final post in posts) {
      final admin = post.admin;
      if (admin != null && seen.add(admin.id)) {
        admins.add(admin);
        if (admins.length >= 8) break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP HUNTERS',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 0.9,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed(ProtectedRoutes.topHunters),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'View All',
                  style: AppTypography.custom(
                    color: AppColors.teal400,
                    size: 11,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // "My Updates" — create button
                _HunterAvatar.create(
                  onTap: () {
                    if (canManageUpdates) {
                      Navigator.of(context)
                          .pushNamed(ProtectedRoutes.manageUpdates);
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Only hunters and admins can manage updates.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Real hunters
                ...admins.map((admin) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _HunterAvatar(
                        imageUrl: admin.imageUrl,
                        name: admin.name,
                        currentLevel: admin.currentLevel,
                        hasRing: true,
                        onTap: () =>
                            PublicProfileScreen.showSheet(context, admin),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HunterAvatar extends StatelessWidget {
  const _HunterAvatar({
    required this.imageUrl,
    required this.name,
    this.currentLevel,
    this.hasRing = false,
    this.onTap,
  }) : isCreate = false;

  const _HunterAvatar.create({
    this.onTap,
  })
      : imageUrl = '',
        name = 'My Updates',
        currentLevel = null,
        hasRing = false,
        isCreate = true;

  final String imageUrl;
  final String name;
  final UserLevelModel? currentLevel;
  final bool hasRing;
  final bool isCreate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: isCreate ? 56 : 72,
        child: Column(
          children: [
            if (isCreate)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderMuted,
                    width: 1.5,
                  ),
                  color: AppColors.bgElevated,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.teal400,
                  size: 20,
                ),
              )
            else if (hasRing)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.teal400, AppColors.primary500],
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgBase,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: _buildAvatarCircle(),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderMuted, width: 1),
                ),
                padding: const EdgeInsets.all(2),
                child: _buildAvatarCircle(),
              ),
            const SizedBox(height: 5),
            if (isCreate)
              Text(
                'My Updates',
                style: AppTypography.custom(
                  color: AppColors.teal400,
                  size: 10,
                  weight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              UserNameWithLevelIcon(
                name: name,
                currentLevel: currentLevel,
                levelBadgeSize: LevelBadgeSize.tiny,
                iconSpacing: 3,
                textStyle: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 10,
                  weight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle() {
    return AppAvatar(
      radius: 20,
      imageUrl: imageUrl,
      fallback: Icon(Icons.person, size: 16, color: AppColors.textMuted),
    );
  }
}
