import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gems_ordering.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// `12 GEMS` on the left, the sort menu on the right, and the chain filter
/// underneath.
class DiscoverControls extends StatelessWidget {
  const DiscoverControls({
    super.key,
    required this.count,
    required this.sort,
    required this.onSort,
    required this.tags,
    required this.selectedTag,
    required this.onSelectTag,
  });

  final int count;
  final GemSort sort;
  final ValueChanged<GemSort> onSort;
  final List<String> tags;

  /// Null for all chains.
  final String? selectedTag;
  final ValueChanged<String?> onSelectTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                count == 1 ? '1 GEM' : '$count GEMS',
                style: HubType.caps(AppColors.textFaint),
              ),
            ),
            _SortMenu(sort: sort, onSort: onSort),
          ],
        ),
        if (tags.length > 1) ...[
          AppSpace.gapSm,
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TagChip(
                  label: 'All',
                  selected: selectedTag == null,
                  onTap: () => onSelectTag(null),
                ),
                for (final tag in tags)
                  _TagChip(
                    label: tag,
                    selected: selectedTag?.toLowerCase() == tag.toLowerCase(),
                    onTap: () => onSelectTag(tag),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onSort});

  final GemSort sort;
  final ValueChanged<GemSort> onSort;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GemSort>(
      key: const ValueKey('gems-sort'),
      initialValue: sort,
      onSelected: onSort,
      color: AppColors.bgElevated,
      tooltip: 'Sort',
      itemBuilder: (_) => [
        for (final option in GemSort.values)
          PopupMenuItem(
            value: option,
            child: Text(
              option.label,
              style: HubType.body(
                option == sort ? AppColors.primary500 : AppColors.textPrimary,
              ),
            ),
          ),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.full,
          border: Border.all(color: AppColors.borderMuted),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: AppIcon.xs, color: AppColors.textMuted),
            AppSpace.wGapXs,
            Text(
              sort.label,
              style: HubType.meta(AppColors.textSecondary, weight: AppText.semibold),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: AppIcon.sm,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    final color = selected ? accent : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpace.xs + 2),
      child: GestureDetector(
        key: ValueKey('tag-chip-$label'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : null,
            borderRadius: AppRadius.full,
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: HubType.caps(color, tracking: 0.6),
          ),
        ),
      ),
    );
  }
}
