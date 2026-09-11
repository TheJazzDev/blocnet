import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/profile/data/models/profile_search_result_model.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';

/// A user/hunter row in the global search results.
class BlocnetSearchPeopleTile extends StatelessWidget {
  const BlocnetSearchPeopleTile({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final ProfileSearchResult profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim() ?? '';
    final roles = _roleLabels(profile.roles);
    final subtitle = profile.handle.isNotEmpty
        ? (roles.isNotEmpty ? '${profile.handle} · $roles' : profile.handle)
        : roles;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: AppAvatar(
        radius: 14,
        imageUrl: avatarUrl,
        fallback: Icon(
          Icons.person_outline_rounded,
          color: AppColors.textMuted,
          size: AppIcon.sm,
        ),
      ),
      title: UserNameWithLevelIcon(
        name: profile.label,
        currentLevel: profile.currentLevel,
        levelBadgeSize: LevelBadgeSize.tiny,
        iconSpacing: 4,
        textStyle: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Geist',
          fontSize: AppText.bodySize,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textFaint,
          fontFamily: 'Geist',
          fontSize: AppText.bodySize,
        ),
      ),
      onTap: onTap,
    );
  }

  String _roleLabels(List<String> roles) {
    final normalized = roles.map((role) => role.toLowerCase()).toSet();
    final labels = <String>[];
    if (normalized.contains('owner') || normalized.contains('admin')) {
      labels.add('Admin');
    }
    if (normalized.contains('hunter')) labels.add('Hunter');
    return labels.join(' • ');
  }
}
