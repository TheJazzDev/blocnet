import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Asks a moderator why. Returns null on cancel.
Future<String?> showModerationReasonDialog(
  BuildContext context, {
  required String title,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(title: title),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title});

  final String title;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  // Owned by the dialog so it is disposed after the closing animation, not
  // while the field is still on screen.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      title: Text(
        widget.title,
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: AppText.subtitleSize,
          weight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: AppText.bodySize,
          weight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Reason',
          hintStyle: AppTypography.custom(
            color: AppColors.textFaint,
            size: AppText.bodySize,
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
              size: AppText.labelSize,
              weight: FontWeight.w600,
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final ready = value.text.trim().isNotEmpty;
            return TextButton(
              onPressed:
                  ready ? () => Navigator.of(context).pop(value.text) : null,
              child: Text(
                'Confirm',
                style: AppTypography.custom(
                  color: ready ? AppColors.primary400 : AppColors.textFaint,
                  size: AppText.labelSize,
                  weight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
