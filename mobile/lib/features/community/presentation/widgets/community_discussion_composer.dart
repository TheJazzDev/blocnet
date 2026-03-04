import 'package:blocnet/app/theme.dart';
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final MentionsRepository mentionsRepository;
  final bool isSending;
  final VoidCallback onSendTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        child: Row(
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isSending ? null : onSendTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
