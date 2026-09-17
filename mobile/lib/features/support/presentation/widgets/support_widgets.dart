import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Title and a one-line count at the top of a support screen.
class SupportHeader extends StatelessWidget {
  const SupportHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.title(AppColors.textPrimary)),
        AppSpace.gapXs,
        Text(subtitle, style: AppText.label(AppColors.textMuted)),
      ],
    );
  }
}

/// A tinted icon square, the list-row leading used across support.
class SupportIconSquare extends StatelessWidget {
  const SupportIconSquare({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
      ),
      child: Icon(icon, size: AppIcon.sm, color: AppColors.primary400),
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
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        padding: AppSpace.card,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.md,
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
                SupportIconSquare(icon: widget.icon),
                AppSpace.wGapMd,
                Expanded(
                  child: Text(
                    widget.question,
                    style: AppText.body(AppColors.textPrimary,
                        weight: AppText.semibold),
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
              AppSpace.gapMd,
              Text(
                widget.answer,
                style:
                    AppText.body(AppColors.textSecondary).copyWith(height: 1.5),
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
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SupportIconSquare(icon: icon),
              AppSpace.wGapMd,
              Expanded(
                child: Text(
                  '$number. $title',
                  style:
                      AppText.body(AppColors.textPrimary, weight: AppText.bold),
                ),
              ),
            ],
          ),
          AppSpace.gapMd,
          Text(
            body,
            style: AppText.body(AppColors.textSecondary).copyWith(height: 1.5),
          ),
          if (actionLabel != null && onAction != null) ...[
            AppSpace.gapMd,
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderMuted),
                  shape:
                      const RoundedRectangleBorder(borderRadius: AppRadius.md),
                ),
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  size: AppIcon.sm,
                  color: AppColors.primary400,
                ),
                label: Text(
                  actionLabel!,
                  style: AppText.label(AppColors.textPrimary,
                      weight: AppText.semibold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
