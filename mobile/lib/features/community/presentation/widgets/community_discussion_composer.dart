import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text_field.dart';
import 'package:flutter/material.dart';

/// The comment box pinned under a discussion, with the "Replying to" line
/// when answering a comment.
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

  /// The server's limit for a community comment.
  static const int maxLength = 300;

  final TextEditingController controller;
  final FocusNode focusNode;
  final MentionsRepository mentionsRepository;
  final bool isSending;
  final VoidCallback onSendTap;
  final String? replyingToUsername;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (replyingToUsername != null)
                _ReplyingTo(
                  username: replyingToUsername!,
                  onCancel: onCancelReply,
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: MentionTextField(
                      controller: controller,
                      focusNode: focusNode,
                      mentionsRepository: mentionsRepository,
                      hintText: 'Write a comment',
                      minLines: 1,
                      maxLines: 4,
                      maxLength: maxLength,
                      suggestionsAbove: true,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _SendButton(
                    controller: controller,
                    isSending: isSending,
                    onTap: onSendTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyingTo extends StatelessWidget {
  const _ReplyingTo({required this.username, required this.onCancel});

  final String username;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: AppIcon.sm,
            color: AppColors.textFaint,
          ),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              'Replying to @$username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w500,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Cancel reply',
            child: GestureDetector(
              onTap: onCancel,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.close_rounded,
                  size: AppIcon.sm,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled accent square; dimmed until there is something to send.
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.controller,
    required this.isSending,
    required this.onTap,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    final onAccent =
        accent.computeLuminance() > 0.4 ? AppColors.bgBase : Colors.white;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final ready = value.text.trim().isNotEmpty && !isSending;
        return Semantics(
          button: true,
          label: 'Send comment',
          enabled: ready,
          child: GestureDetector(
            onTap: ready ? onTap : null,
            child: Opacity(
              opacity: ready || isSending ? 1 : 0.45,
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: AppSpace.hair),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: AppRadius.md,
                ),
                child: Center(
                  child: isSending
                      ? SizedBox(
                          width: AppIcon.sm,
                          height: AppIcon.sm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: onAccent,
                          ),
                        )
                      : Icon(Icons.send_rounded,
                          size: AppIcon.md, color: onAccent),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
