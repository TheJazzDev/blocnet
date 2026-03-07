import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:flutter/material.dart';

class CommunityContentModerationDecision {
  const CommunityContentModerationDecision({
    required this.status,
    required this.reason,
  });

  final CommunityContentModerationStatus status;
  final String reason;
}

Future<CommunityContentModerationDecision?> showCommunityContentModerationSheet(
  BuildContext context, {
  required String targetLabel,
  required bool canArchive,
}) async {
  final status = await showModalBottomSheet<CommunityContentModerationStatus>(
    context: context,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$targetLabel actions',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 17,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                canArchive
                    ? 'Hide, restore, or archive this content.'
                    : 'Hide or restore this content. Archive is reserved for community admins and governance roles.',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _ActionTile(
                icon: Icons.visibility_off_outlined,
                label: 'Hide $targetLabel',
                tone: const Color(0xFFF59E0B),
                onTap: () => Navigator.of(context).pop(
                  CommunityContentModerationStatus.hidden,
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.visibility_outlined,
                label: 'Restore $targetLabel',
                tone: const Color(0xFF34D399),
                onTap: () => Navigator.of(context).pop(
                  CommunityContentModerationStatus.active,
                ),
              ),
              if (canArchive) ...[
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.archive_outlined,
                  label: 'Archive $targetLabel',
                  tone: AppColors.error500,
                  onTap: () => Navigator.of(context).pop(
                    CommunityContentModerationStatus.archived,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  if (status == null || !context.mounted) {
    return null;
  }

  final reason = await _showModerationReasonDialog(
    context,
    targetLabel: targetLabel,
    status: status,
  );

  if (reason == null) {
    return null;
  }

  final trimmed = reason.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return CommunityContentModerationDecision(
    status: status,
    reason: trimmed,
  );
}

Future<String?> _showModerationReasonDialog(
  BuildContext context, {
  required String targetLabel,
  required CommunityContentModerationStatus status,
}) async {
  final controller = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          '${status.label} $targetLabel',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 13,
            weight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Add moderation reason',
            hintStyle: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w400,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(
              'Confirm',
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 12,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );

  controller.dispose();
  return result;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tone.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: tone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 13,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
