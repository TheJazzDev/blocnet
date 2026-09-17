import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/presentation/widgets/moderation/moderation_reason_dialog.dart';
import 'package:blocnet/shared/widgets/app_sheet.dart';
import 'package:flutter/material.dart';

class CommunityContentModerationDecision {
  const CommunityContentModerationDecision({
    required this.status,
    required this.reason,
  });

  final CommunityContentModerationStatus status;
  final String reason;
}

/// Staff actions on a post or comment: hide, restore, and (for community
/// admins) archive. Each asks for a reason before it is returned.
Future<CommunityContentModerationDecision?> showCommunityContentModerationSheet(
  BuildContext context, {
  required String targetLabel,
  required bool canArchive,
}) async {
  final status = await AppSheet.show<CommunityContentModerationStatus>(
    context: context,
    title: 'Moderate $targetLabel',
    icon: Icons.shield_outlined,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionRow(
          icon: Icons.visibility_off_outlined,
          label: 'Hide',
          tone: AppColors.warning500,
          onTap: () => Navigator.of(sheetContext)
              .pop(CommunityContentModerationStatus.hidden),
        ),
        _ActionRow(
          icon: Icons.visibility_outlined,
          label: 'Restore',
          tone: AppColors.successColor,
          onTap: () => Navigator.of(sheetContext)
              .pop(CommunityContentModerationStatus.active),
        ),
        if (canArchive)
          _ActionRow(
            icon: Icons.archive_outlined,
            label: 'Archive',
            tone: AppColors.tagWarning,
            onTap: () => Navigator.of(sheetContext)
                .pop(CommunityContentModerationStatus.archived),
          )
        else ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            'Only community admins can archive.',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.labelSize,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ],
    ),
  );

  if (status == null || !context.mounted) return null;

  final reason = await showModerationReasonDialog(
    context,
    title: '${status.label} $targetLabel',
  );
  final trimmed = reason?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  return CommunityContentModerationDecision(status: status, reason: trimmed);
}

/// A list row with a tinted icon square, as elsewhere in the app.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: AppRadius.sm,
                border: Border.all(color: tone.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, size: AppIcon.sm, color: tone),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.md,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
