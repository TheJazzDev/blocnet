import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/shared/widgets/app_button.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';

/// Confirms a sent report, with a shortcut to My reports.
void showCommunityReportSent(BuildContext context) {
  final navigator = Navigator.of(context);
  AppSnackbar.showSuccess(
    context,
    'Report sent',
    actionLabel: 'My reports',
    onAction: () => navigator.pushNamed(AppRoutes.myReports),
  );
}

/// The reported text, quoted.
class CommunityReportPreview extends StatelessWidget {
  const CommunityReportPreview({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: AppText.labelSize,
          weight: FontWeight.w400,
          height: 1.4,
        ),
      ),
    );
  }
}

/// A small uppercase section label inside the sheet.
class CommunityReportLabel extends StatelessWidget {
  const CommunityReportLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.custom(
        color: AppColors.textFaint,
        size: AppText.captionSize,
        weight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

/// One reason, as a radio row.
class CommunityReportReasonRow extends StatelessWidget {
  const CommunityReportReasonRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary400;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: AppIcon.md,
                color: selected ? accent : AppColors.textFaint,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.custom(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    size: AppText.bodySize,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The optional (or, for "Other", required) details box.
class CommunityReportDetailsField extends StatelessWidget {
  const CommunityReportDetailsField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.maxLength,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: color),
        );
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: 2,
      maxLines: 4,
      maxLength: maxLength,
      onChanged: onChanged,
      style: AppTypography.custom(
        color: AppColors.textPrimary,
        size: AppText.bodySize,
        weight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: 'What’s wrong with it?',
        hintStyle: AppTypography.custom(
          color: AppColors.textFaint,
          size: AppText.bodySize,
          weight: FontWeight.w400,
        ),
        counterStyle: AppTypography.custom(
          color: AppColors.textFaint,
          size: AppText.captionSize,
          weight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.bgBase,
        contentPadding: const EdgeInsets.all(AppSpace.md),
        border: border(AppColors.borderSubtle),
        enabledBorder: border(AppColors.borderSubtle),
        disabledBorder: border(AppColors.borderSubtle),
        focusedBorder: border(AppColors.primary400),
      ),
    );
  }
}

class CommunityReportSendButton extends StatelessWidget {
  const CommunityReportSendButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Send report',
      onPressed: onPressed,
      isLoading: isSubmitting,
      fullWidth: true,
    );
  }
}
