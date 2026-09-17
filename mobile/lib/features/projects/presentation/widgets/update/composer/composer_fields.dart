import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:flutter/material.dart';

/// A label above a composer field.
class ComposerFieldLabel extends StatelessWidget {
  const ComposerFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Text(
        label,
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: AppText.labelSize,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A group of fields on a flat card, under a small caps header.
class ComposerSection extends StatelessWidget {
  const ComposerSection({
    super.key,
    required this.icon,
    required this.label,
    required this.children,
  });

  final IconData icon;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomePanelHeader(
            icon: icon,
            label: label.toUpperCase(),
            iconColor: AppColors.primary500,
          ),
          AppSpace.gapLg,
          ...children,
        ],
      ),
    );
  }
}

/// Vertical room between two fields in a section.
const Widget composerFieldGap = SizedBox(height: AppSpace.lg);

/// A failed send, stated once above the form.
class ComposerErrorNotice extends StatelessWidget {
  const ComposerErrorNotice(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('composer-error'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: AppSpace.card,
      decoration: BoxDecoration(
        color: AppColors.tagWarning.withValues(alpha: 0.08),
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.tagWarning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: AppIcon.sm,
            color: AppColors.tagWarning,
          ),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              message,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: AppText.labelSize,
                weight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A send error as a person should read it: no `Exception:` prefix.
String composerErrorText(Object error) {
  final text = error.toString().trim();
  const prefix = 'Exception: ';
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}

/// The composer's text style for field values.
TextStyle composerValueStyle() => AppTypography.custom(
      color: AppColors.textSecondary,
      size: AppText.bodySize,
      weight: FontWeight.w400,
    );

/// The shared input decoration for composer fields.
InputDecoration composerFieldDecoration({String? hintText}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTypography.custom(
      color: AppColors.textFaint,
      size: AppText.bodySize,
      weight: FontWeight.w400,
    ),
    filled: true,
    fillColor: AppColors.bgBase,
    border: border(AppColors.borderSubtle),
    enabledBorder: border(AppColors.borderSubtle),
    disabledBorder: border(AppColors.borderSubtle),
    focusedBorder: border(AppColors.primary500),
    errorBorder: border(AppColors.tagWarning),
    focusedErrorBorder: border(AppColors.tagWarning),
    errorStyle: AppTypography.custom(
      color: AppColors.tagWarning,
      size: AppText.labelSize,
      weight: FontWeight.w500,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.lg,
      vertical: AppSpace.md,
    ),
  );
}
