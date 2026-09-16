import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class MiningActionState {
  const MiningActionState({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    required this.isLoading,
    this.showLockIcon = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showLockIcon;
}

class MiningStatusTag extends StatelessWidget {
  const MiningStatusTag({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.fullValue),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          size: AppText.captionSize,
          weight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class MiningCompactStat extends StatelessWidget {
  const MiningCompactStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        color: AppColors.bgElevated.withValues(alpha: 0.5),
        border:
            Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.smValue),
            ),
            child: Icon(icon, size: AppIcon.sm, color: color),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.custom(
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                    color: AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  value,
                  style: AppTypography.custom(
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MiningActionButton extends StatelessWidget {
  const MiningActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    required this.isLoading,
    this.showLockIcon = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showLockIcon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !isLoading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.95),
          foregroundColor: textColor,
          disabledForegroundColor: textColor.withValues(alpha: 0.9),
          side: BorderSide(
            color: disabled
                ? AppColors.borderSubtle.withValues(alpha: 0.9)
                : color.withValues(alpha: 0.2),
            width: 1.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lgValue),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                // No visible text while busy: keep the action's name so the
                // button is never announced unlabelled.
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                  semanticsLabel: label,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showLockIcon) ...[
                    Icon(
                      Icons.lock_rounded,
                      size: AppIcon.sm,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  Text(
                    label,
                    style: AppTypography.custom(
                      size: AppText.labelSize,
                      weight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
