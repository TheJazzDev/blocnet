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
            weight: FontWeight.w700,
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

/// One Getting Started step: a flat card with a tinted icon square, the
/// numbered title and the body, left-aligned. A step with a shortcut ends in
/// a hairline and a tappable row with a chevron.
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
    final hasAction = actionLabel != null && onAction != null;
    return AppSurface.flush(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpace.card,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sm,
                  ),
                  child:
                      Icon(icon, size: AppIcon.sm, color: AppColors.primary400),
                ),
                AppSpace.wGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$number. $title',
                        style: AppText.body(
                          AppColors.textPrimary,
                          weight: AppText.bold,
                        ),
                      ),
                      AppSpace.gapXs,
                      Text(body,
                          style: AppText.label(AppColors.textMuted)
                              .copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasAction) ...[
            Divider(height: 1, color: AppColors.borderSubtle),
            AppListRow(
              title: actionLabel!,
              titleColor: AppColors.primary400,
              dense: true,
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: AppIcon.md,
                color: AppColors.textFaint,
              ),
              onTap: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
