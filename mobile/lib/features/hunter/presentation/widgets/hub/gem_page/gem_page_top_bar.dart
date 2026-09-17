import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
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
              icon: Icon(Icons.arrow_back_rounded,
                  size: AppIcon.lg, color: AppColors.textPrimary),
            ),
            Expanded(
              child: Text(
                'Your gem',
                style: AppText.title(AppColors.textPrimary),
              ),
            ),
            PopupMenuButton<String>(
              key: const ValueKey('gem-page-menu'),
              tooltip: 'More',
              color: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.md,
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              icon: Icon(Icons.more_horiz_rounded,
                  size: AppIcon.lg, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'member') onViewAsMember();
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'member',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined,
                          size: AppIcon.md, color: AppColors.textMuted),
                      AppSpace.wGapMd,
                      Text(
                        'View as member',
                        style: AppText.body(AppColors.textPrimary,
                            weight: AppText.medium),
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
