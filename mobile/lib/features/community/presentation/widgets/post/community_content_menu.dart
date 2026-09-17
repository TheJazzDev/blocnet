import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/presentation/widgets/report/community_report_sheet.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:blocnet/shared/widgets/app_sheet.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Whether the ⋯ menu on a post or comment has anything to offer: staff can
/// moderate, and anyone can report or block another member.
bool communityMenuHasItems(
  BuildContext context, {
  required Admin? author,
  required bool canModerate,
}) {
  if (canModerate) return true;
  final myId = context.read<AuthStore>().userId;
  return author != null && author.id != myId;
}

/// The ⋯ menu on a post or comment: Moderate (staff), Report and Block.
Future<void> showCommunityContentMenu(
  BuildContext context, {
  required CommunityReportTargetType targetType,
  required String targetId,
  required String content,
  required Admin? author,
  Future<void> Function()? onModerate,
}) async {
  final myId = context.read<AuthStore>().userId;
  final other = author == null || author.id == myId ? null : author;
  final noun = targetType == CommunityReportTargetType.communityComment
      ? 'comment'
      : 'post';

  final choice = await AppSheet.show<_MenuChoice>(
    context: context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onModerate != null)
          _MenuRow(
            icon: Icons.shield_outlined,
            label: 'Moderate $noun',
            color: AppColors.textPrimary,
            onTap: () => Navigator.pop(sheetContext, _MenuChoice.moderate),
          ),
        if (other != null) ...[
          _MenuRow(
            icon: Icons.flag_outlined,
            label: 'Report $noun',
            color: AppColors.tagWarning,
            onTap: () => Navigator.pop(sheetContext, _MenuChoice.report),
          ),
          _MenuRow(
            icon: Icons.block_rounded,
            label: other.name.trim().isEmpty
                ? 'Block member'
                : 'Block ${other.name.trim()}',
            color: AppColors.tagWarning,
            onTap: () => Navigator.pop(sheetContext, _MenuChoice.block),
          ),
        ],
      ],
    ),
  );

  if (choice == null || !context.mounted) return;
  switch (choice) {
    case _MenuChoice.moderate:
      await onModerate?.call();
    case _MenuChoice.report:
      await openCommunityReportSheet(
        context,
        targetType: targetType,
        targetId: targetId,
        content: content,
      );
    case _MenuChoice.block:
      if (author != null) await blockCommunityAuthor(context, author);
  }
}

/// Confirms, blocks [author], and drops their posts and comments from view.
Future<void> blockCommunityAuthor(BuildContext context, Admin author) async {
  final name = author.name.trim().isEmpty ? 'this member' : author.name;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      title: Text(
        'Block $name?',
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: AppText.subtitleSize,
          weight: FontWeight.w700,
        ),
      ),
      content: Text(
        'You won’t see their posts or comments.',
        style: AppTypography.custom(
          color: AppColors.textSecondary,
          size: AppText.bodySize,
          weight: FontWeight.w400,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.labelSize,
              weight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'Block',
            style: AppTypography.custom(
              color: AppColors.tagWarning,
              size: AppText.labelSize,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // The card that opened this disappears once the block lands, so messages
  // go through the navigator's context, which outlives it.
  final hostContext = Navigator.of(context).context;
  final blocks = context.read<BlocksStore>();
  final posts = context.read<CommunityPostsStore>();
  final ok = await blocks.blockUser(author.id);
  if (!hostContext.mounted) return;

  if (ok) {
    posts.removeContentByAuthor(author.id);
    AppSnackbar.showSuccess(hostContext, 'Blocked $name');
  } else {
    AppSnackbar.showError(hostContext, 'Could not block $name');
  }
}

enum _MenuChoice { moderate, report, block }

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(icon, size: AppIcon.md, color: color),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: color,
                  size: AppText.bodySize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
