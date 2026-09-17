import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_sheet_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Who the tip goes to: avatar, name, @handle, and the HUNTER pill.
class TipRecipientCard extends StatelessWidget {
  const TipRecipientCard({super.key, required this.recipient});

  final TipRecipient recipient;

  @override
  Widget build(BuildContext context) {
    final handle = recipient.username?.trim() ?? '';
    final label = recipient.label;
    final showHandle = handle.isNotEmpty && !label.startsWith('@');
    return AppSurface(
      width: double.infinity,
      child: Row(
        children: [
          AppAvatar(
            radius: 18,
            imageUrl: recipient.avatarUrl?.trim() ?? '',
            fallback: Icon(
              Icons.person_rounded,
              color: AppColors.textMuted,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    AppColors.textPrimary,
                    weight: AppText.bold,
                  ),
                ),
                if (showHandle) ...[
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    handle.startsWith('@') ? handle : '@$handle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (recipient.isHunterHint) ...[
            const SizedBox(width: AppSpace.sm),
            const TipPill(label: 'Hunter', color: AppColors.tagPartnership),
          ],
        ],
      ),
    );
  }
}
