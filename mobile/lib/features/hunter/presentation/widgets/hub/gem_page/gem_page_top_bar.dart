import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// `← Your gem ⋯` — the gem page's own header. The menu holds *View as
/// member*; *Hand over* lives beside *Post update* on the page itself.
class GemPageTopBar extends StatelessWidget {
  const GemPageTopBar({
    super.key,
    required this.onBack,
    required this.onViewAsMember,
  });

  final VoidCallback onBack;
  final VoidCallback onViewAsMember;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: AppColors.zincMuted),
            ),
            Expanded(
              child: Text(
                'Your gem',
                style: AppTypography.custom(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            PopupMenuButton<String>(
              key: const ValueKey('gem-page-menu'),
              tooltip: 'More',
              color: AppColors.bgSurface,
              icon: const Icon(Icons.more_horiz_rounded,
                  size: 20, color: AppColors.zincMuted),
              onSelected: (value) {
                if (value == 'member') onViewAsMember();
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'member',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined,
                          size: 16, color: AppColors.zincMuted),
                      const SizedBox(width: 12),
                      Text(
                        'View as member',
                        style: AppTypography.custom(
                          size: 15,
                          weight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
