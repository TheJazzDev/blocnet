import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_button.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_fields.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_rows.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Bottom sheet with every detail of one activity row.
void showWalletActivityDetails(BuildContext context, WalletActivityItem row) {
  if (row.transaction == null && row.withdrawal == null) return;
  final details = WalletActivityDetails.from(
    row,
    context.read<WalletStore>().snapshot,
  );
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WalletActivitySheet(item: row, details: details),
  );
}

class WalletActivitySheet extends StatelessWidget {
  const WalletActivitySheet({
    super.key,
    required this.item,
    required this.details,
  });

  final WalletActivityItem item;
  final WalletActivityDetails details;

  @override
  Widget build(BuildContext context) {
    final explorerUrl = details.explorerUrl;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bgBase,
          borderRadius: AppRadius.sheet,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Grabber(),
              const SizedBox(height: AppSpace.lg),
              _Header(item: item, title: details.title),
              const SizedBox(height: AppSpace.lg),
              _FieldsCard(fields: details.fields),
              if (explorerUrl != null) ...[
                const SizedBox(height: AppSpace.lg),
                SizedBox(
                  width: double.infinity,
                  child: WalletButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'View on block explorer',
                    onPressed: () => openExplorerTx(context, explorerUrl),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: const BoxDecoration(
          color: AppColors.borderMuted,
          borderRadius: AppRadius.full,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item, required this.title});

  final WalletActivityItem item;
  final String title;

  @override
  Widget build(BuildContext context) {
    final badge = item.badgeLabel;
    final badgeColor = item.badgeColor;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title(AppColors.textPrimary)),
              const SizedBox(height: AppSpace.hair),
              Text(
                item.amountLabel,
                style: AppText.body(item.amountColor, weight: AppText.bold)
                    .merge(AppText.tabular),
              ),
            ],
          ),
        ),
        if (badge != null && badgeColor != null)
          AppPill.caps(label: badge, color: badgeColor, dense: true),
      ],
    );
  }
}

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.fields});

  final List<WalletDetailField> fields;

  @override
  Widget build(BuildContext context) {
    return AppRowGroup(
      children: [
        for (final field in fields) _FieldRow(field: field),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final WalletDetailField field;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: field.value));
    // The root overlay: a SnackBar would sit behind this sheet.
    AppSnackbar.showSuccess(context, '${field.label} copied.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        field.copyable ? AppSpace.xs : AppSpace.lg,
        AppSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label.toUpperCase(),
                  style: WalletType.caps(AppColors.textFaint),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  field.value,
                  style: AppText.label(
                    AppColors.textSecondary,
                    weight: AppText.semibold,
                  ).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          if (field.copyable)
            IconButton(
              onPressed: () => _copy(context),
              tooltip: 'Copy ${field.label.toLowerCase()}',
              iconSize: AppIcon.sm,
              icon: Icon(Icons.copy_rounded, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
