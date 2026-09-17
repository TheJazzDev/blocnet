import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Empty or error message inside a card: icon, one line, an optional hint
/// and an optional action. Left-aligned.
class ProfileInlineState extends StatelessWidget {
  const ProfileInlineState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpace.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIcon.md, color: AppColors.textFaint),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(
                    AppColors.textSecondary,
                    weight: AppText.medium,
                  ),
                ),
                if (hint != null) ...[
                  AppSpace.gapHair,
                  Text(hint!, style: AppText.label(AppColors.textFaint)),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style:
                    AppText.label(AppColors.primary400, weight: AppText.bold),
              ),
            ),
        ],
      ),
    );
  }
}
