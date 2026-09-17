import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:flutter/material.dart';

/// `‹  Page 1 of 9  ›`
class MineLeaderboardPager extends StatelessWidget {
  const MineLeaderboardPager({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPage,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpace.allMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageButton(
            key: const ValueKey('mine-page-prev'),
            icon: Icons.chevron_left_rounded,
            label: 'Previous page',
            onTap: page > 1 ? () => onPage(page - 1) : null,
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            'Page $page of $pageCount',
            style: AppText.label(MinePalette.muted, weight: AppText.semibold),
          ),
          const SizedBox(width: AppSpace.sm),
          _PageButton(
            key: const ValueKey('mine-page-next'),
            icon: Icons.chevron_right_rounded,
            label: 'Next page',
            onTap: page < pageCount ? () => onPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 44 px target around the design's 32 px square.
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: mineTileDecoration(radius: AppRadius.sm),
              child: Icon(
                icon,
                size: AppIcon.sm,
                color: enabled ? MinePalette.text : MinePalette.faint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
