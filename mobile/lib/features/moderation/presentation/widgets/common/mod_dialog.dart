import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// The flat dialog every moderation form sits in: surface, hairline border,
/// left-aligned title, Cancel and one confirm button side by side.
class ModDialog extends StatelessWidget {
  const ModDialog({
    super.key,
    required this.title,
    required this.children,
    required this.confirmLabel,
    required this.onConfirm,
    this.confirmColor,
  });

  final String title;
  final List<Widget> children;
  final String confirmLabel;

  /// Null disables the confirm button.
  final VoidCallback? onConfirm;

  /// The confirm button's fill. Defaults to the moderation red.
  final Color? confirmColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgSurface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.xxl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: AppSpace.allXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppText.subtitle(
                  AppColors.textPrimary,
                  weight: AppText.bold,
                ),
              ),
              AppSpace.gapLg,
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              AppSpace.gapLg,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.compact,
                    ),
                  ),
                  AppSpace.wGapSm,
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      color: confirmColor ?? ModTone.accent,
                      onPressed: onConfirm,
                      size: AppButtonSize.compact,
                    ),
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

/// A small red line under a form, for a validation message.
class ModInlineError extends StatelessWidget {
  const ModInlineError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Text(text, style: AppText.label(AppColors.tagWarning)),
    );
  }
}
