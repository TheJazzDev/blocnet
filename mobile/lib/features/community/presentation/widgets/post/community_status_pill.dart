import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/shared/widgets/app_pill.dart';
import 'package:flutter/material.dart';

/// `HIDDEN` / `ARCHIVED` beside a moderated post or comment. Staff are the only
/// ones who ever see these, since members are served active content only.
class CommunityStatusPill extends StatelessWidget {
  const CommunityStatusPill({super.key, required this.status});

  final CommunityContentModerationStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == CommunityContentModerationStatus.active) {
      return const SizedBox.shrink();
    }
    final hidden = status == CommunityContentModerationStatus.hidden;
    return AppPill(
      label: hidden ? 'Hidden' : 'Archived',
      color: hidden ? AppColors.warning500 : AppColors.tagWarning,
      dense: true,
      uppercase: true,
    );
  }
}
