import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Tappable "Couldn't load tips. Tap to retry." line used by the Hunter Hub
/// tip balance and recent-tips cards. The raw exception is logged by
/// `TipsStore`; this widget deliberately never renders it.
class TipsLoadErrorRow extends StatelessWidget {
  const TipsLoadErrorRow({
    super.key,
    required this.onRetry,
    this.compact = false,
  });

  final Future<void> Function() onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 10.0 : 12.0;
    return GestureDetector(
      onTap: onRetry,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: size + 4,
              color: AppColors.warning500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "Couldn't load tips. Tap to retry.",
                style: AppTypography.custom(
                  color: AppColors.warning500,
                  size: size,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
