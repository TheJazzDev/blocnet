import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_details_sheet.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_rows.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransactionsList extends StatelessWidget {
  const TransactionsList({
    super.key,
    this.limit,
    this.assetCode,
  });

  final int? limit;
  final String? assetCode;

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final viewMode = context.watch<FeedViewModeStore>().mode;
    final isCardMode = viewMode == FeedViewMode.card;
    final rows = buildWalletActivityRows(walletStore, assetCode: assetCode);
    final visibleRows = limit == null ? rows : rows.take(limit!).toList();
    final selectedAsset = assetCode?.toUpperCase();
    final isLoading = selectedAsset == null
        ? walletStore.isLoadingTransactions || walletStore.isLoadingWithdrawals
        : walletStore.isLoadingTransactionsForAsset(selectedAsset) ||
            walletStore.isLoadingWithdrawalsForAsset(selectedAsset);

    if (isLoading && rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      final title = selectedAsset == null
          ? 'No transactions yet'
          : 'No $selectedAsset transactions yet';
      return Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textFaint,
            size: AppIcon.lg,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            title,
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.bodySize,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Your wallet activity will appear here after your first transaction.',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
        ],
      );
    }

    return Column(
      children: visibleRows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final badgeColor = row.badgeColor;
        final canOpenDetails =
            row.transaction != null || row.withdrawal != null;

        return Column(
          key: ValueKey(row.id),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
              onTap: canOpenDetails
                  ? () => showWalletActivityDetails(context, row)
                  : null,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: isCardMode ? 10 : 0),
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpace.md, horizontal: AppSpace.md),
                decoration: isCardMode
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.bgSurface,
                            AppColors.bgSurface.withValues(alpha: 0.82),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lgValue),
                        border: Border.all(
                          color: AppColors.borderSubtle.withValues(alpha: 0.75),
                          width: 1.2,
                        ),
                      )
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: row.isIncoming
                            ? AppColors.successColor.withValues(alpha: 0.12)
                            : row.isOutgoing
                                ? AppColors.primary500.withValues(alpha: 0.12)
                                : AppColors.bgElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        row.icon,
                        size: AppIcon.sm,
                        color: row.isIncoming
                            ? AppColors.successColor
                            : row.isOutgoing
                                ? AppColors.primary500
                                : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  row.title,
                                  style: AppTypography.custom(
                                    color: AppColors.textPrimary,
                                    size: AppText.labelSize,
                                    weight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (row.badgeLabel != null &&
                                  badgeColor != null) ...[
                                const SizedBox(width: AppSpace.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.xs,
                                    vertical: AppSpace.hair,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.smValue),
                                  ),
                                  child: Text(
                                    row.badgeLabel!,
                                    style: AppTypography.custom(
                                      color: badgeColor,
                                      size: AppText.captionSize,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpace.hair),
                          Text(
                            row.subtitle,
                            style: AppTypography.custom(
                              color: AppColors.textFaint,
                              size: AppText.captionSize,
                              weight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          row.amountLabel,
                          style: AppTypography.custom(
                            color: row.amountColor,
                            size: AppText.labelSize,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isCardMode && index != visibleRows.length - 1)
              Divider(
                height: 1,
                color: AppColors.borderSubtle.withValues(alpha: 0.8),
              ),
          ],
        );
      }).toList(),
    );
  }
}
