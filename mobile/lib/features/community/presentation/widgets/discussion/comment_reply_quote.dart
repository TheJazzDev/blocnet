import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:flutter/material.dart';

/// "Replying to @name" with a line of the parent, shown when the parent is
/// not in the loaded thread (so the reply cannot sit under it).
class CommentReplyQuote extends StatelessWidget {
  const CommentReplyQuote({super.key, required this.parent});

  final ReplyToData parent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subdirectory_arrow_right_rounded,
                size: AppIcon.xs,
                color: AppColors.textFaint,
              ),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Text(
                  'Replying to @${replyHandle(parent)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.hair),
          Text(
            parent.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.labelSize,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

String replyHandle(ReplyToData data) {
  final username = data.username?.trim().replaceAll('@', '') ?? '';
  if (username.isNotEmpty) return username;
  final name = data.displayName?.trim() ?? '';
  if (name.isNotEmpty) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
  return data.id.length > 6 ? data.id.substring(0, 6) : data.id;
}
