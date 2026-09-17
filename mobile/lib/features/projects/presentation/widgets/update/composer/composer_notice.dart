import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_choice_fields.dart';
import 'package:flutter/material.dart';

/// A form that cannot be shown: why, in one line, and the next step if
/// there is one.
class ComposerNotice extends StatelessWidget {
  const ComposerNotice({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: HomePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppIcon.md, color: AppColors.textMuted),
                AppSpace.wGapSm,
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.bodySize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (message != null) ...[
              AppSpace.gapSm,
              Text(
                message!,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              AppSpace.gapLg,
              ComposerSubmitButton(
                label: actionLabel!,
                icon: actionIcon,
                busy: false,
                onTap: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The spinner a composer shows while its lists load.
class ComposerLoading extends StatelessWidget {
  const ComposerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          color: AppColors.primary500,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
