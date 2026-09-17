import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:flutter/material.dart';

/// `1–20 of 45` with previous and next page buttons.
class ReportsPaginationBar extends StatelessWidget {
  const ReportsPaginationBar({
    super.key,
    required this.from,
    required this.to,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int from;
  final int to;
  final int total;

  /// Null disables the button.
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ModTone.gutter,
        AppSpace.xs,
        AppSpace.sm,
        AppSpace.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                total == 0 ? 'No reports' : '$from–$to of $total',
                style: ModText.meta(AppColors.textMuted),
              ),
            ),
            _PageButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Previous page',
              onTap: onPrev,
            ),
            _PageButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Next page',
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: AppIcon.lg),
      color: AppColors.textPrimary,
      disabledColor: AppColors.textFaint.withValues(alpha: 0.5),
    );
  }
}
