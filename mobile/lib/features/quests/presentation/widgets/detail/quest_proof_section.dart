import 'dart:io';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/quests/presentation/widgets/detail/quest_detail_sections.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// "In review" line shown once proof has been sent.
class QuestProofPending extends StatelessWidget {
  const QuestProofPending({super.key});

  @override
  Widget build(BuildContext context) {
    return QuestSectionCard(
      icon: Icons.hourglass_top_rounded,
      label: 'Proof sent',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPill(
            label: 'In review',
            color: AppColors.warning500,
            dense: true,
            uppercase: true,
          ),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              'A moderator will check it. You get a notification when it is done.',
              style: AppText.label(AppColors.textSecondary,
                  weight: AppText.regular),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screenshot picker, optional note and submit button.
class QuestProofForm extends StatelessWidget {
  const QuestProofForm({
    super.key,
    required this.screenshot,
    required this.noteController,
    required this.isSubmitting,
    required this.onPick,
    required this.onClearScreenshot,
    required this.onSubmit,
  });

  final File? screenshot;
  final TextEditingController noteController;
  final bool isSubmitting;
  final VoidCallback onPick;
  final VoidCallback onClearScreenshot;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final file = screenshot;
    return QuestSectionCard(
      icon: Icons.upload_file_outlined,
      label: 'Submit proof',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add a screenshot that shows the quest done.',
            style:
                AppText.label(AppColors.textSecondary, weight: AppText.regular),
          ),
          AppSpace.gapMd,
          if (file != null) ...[
            _Preview(
                file: file, onClear: isSubmitting ? null : onClearScreenshot),
            AppSpace.gapMd,
          ],
          AppButton(
            label: file == null ? 'Add screenshot' : 'Change screenshot',
            icon: Icons.image_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: isSubmitting ? null : onPick,
          ),
          AppSpace.gapMd,
          AppTextField(
            label: 'Note (optional)',
            hint: 'Anything the moderator should know',
            controller: noteController,
            maxLines: 3,
            enabled: !isSubmitting,
          ),
          AppSpace.gapLg,
          AppButton(
            label: 'Submit proof',
            icon: Icons.send_rounded,
            isLoading: isSubmitting,
            onPressed: file == null ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.file, required this.onClear});

  final File file;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.md,
      child: Stack(
        children: [
          Image.file(
            file,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: AppSpace.sm,
            right: AppSpace.sm,
            child: Material(
              color: AppColors.bgBase.withValues(alpha: 0.7),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Remove screenshot',
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  size: AppIcon.md,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
