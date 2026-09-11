import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text_field.dart';
import 'package:flutter/material.dart';

class CommunityDiscussionComposer extends StatelessWidget {
  const CommunityDiscussionComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.mentionsRepository,
    required this.isSending,
    required this.onSendTap,
    this.replyingToUsername,
    this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final MentionsRepository mentionsRepository;
  final bool isSending;
  final VoidCallback onSendTap;
  final String? replyingToUsername;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingToUsername != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md, vertical: AppSpace.sm),
                margin: const EdgeInsets.only(bottom: AppSpace.sm),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadius.smValue),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: AppIcon.sm,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        'Replying to @$replyingToUsername',
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: AppText.labelSize,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: Icon(
                        Icons.close,
                        size: AppIcon.md,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: MentionTextField(
                    controller: controller,
                    focusNode: focusNode,
                    mentionsRepository: mentionsRepository,
                    hintText: 'Write a comment...',
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 300,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                GestureDetector(
                  onTap: isSending ? null : onSendTap,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: AppIcon.md,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
