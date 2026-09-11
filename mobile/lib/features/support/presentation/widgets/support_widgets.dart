import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Heading + subtitle at the top of a support screen.
class SupportHeader extends StatelessWidget {
  const SupportHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.titleSize,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          subtitle,
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: AppText.bodySize,
            weight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// Expandable question/answer row used by the FAQ screen.
class SupportFaqTile extends StatefulWidget {
  const SupportFaqTile({
    super.key,
    required this.icon,
    required this.question,
    required this.answer,
  });

  final IconData icon;
  final String question;
  final String answer;

  @override
  State<SupportFaqTile> createState() => _SupportFaqTileState();
}

class _SupportFaqTileState extends State<SupportFaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
          border: Border.all(
            color: _expanded
                ? AppColors.primary500.withValues(alpha: 0.35)
                : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon,
                    size: AppIcon.md, color: AppColors.primary400),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    widget.question,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: AppIcon.md,
                  color: AppColors.textFaint,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpace.md),
              Text(
                widget.answer,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Numbered step card used by the Getting Started screen.
class SupportStepCard extends StatelessWidget {
  const SupportStepCard({
    super.key,
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      radius: AppRadius.lg,
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                ),
                child:
                    Icon(icon, size: AppIcon.md, color: AppColors.primary400),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.bodySize,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            body,
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTypography.custom(
                        color: AppColors.primary400,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: AppIcon.sm,
                      color: AppColors.primary400,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
