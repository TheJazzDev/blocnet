import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_sheet_copy.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Your last tips to this member, as rows in one card.
class TipRecentList extends StatelessWidget {
  const TipRecentList({
    super.key,
    required this.items,
    required this.isLoading,
  });

  final List<TipTransaction> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: AppColors.primary500,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return AppSurface(
        width: double.infinity,
        child: Text(
          'No tips to them yet.',
          style: AppText.label(AppColors.textMuted),
        ),
      );
    }
    final rows = items.take(8).toList(growable: false);
    return AppSurface(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.borderSubtle),
            _TipRow(item: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.item});

  final TipTransaction item;

  @override
  Widget build(BuildContext context) {
    final note = item.note?.trim() ?? '';
    return Padding(
      padding: AppSpace.row,
      child: Row(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: AppIcon.md,
            color: AppColors.primary400,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.isEmpty ? 'Tip' : note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    AppColors.textPrimary,
                    weight: AppText.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  tipDateLabel(item.createdAt),
                  style: AppText.caption(AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            '${item.amount} ${item.currency.symbol}',
            style: AppText.label(
              AppColors.textPrimary,
              weight: AppText.bold,
            ).merge(AppText.tabular),
          ),
        ],
      ),
    );
  }
}
