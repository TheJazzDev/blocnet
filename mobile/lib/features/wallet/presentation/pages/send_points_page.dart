import 'dart:math';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/points_transfer_form.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:blocnet/features/wallet/presentation/widgets/points_recipient_field.dart';
import 'package:blocnet/features/wallet/presentation/widgets/send_header_card.dart';
import 'package:blocnet/features/wallet/presentation/widgets/send_submit_button.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_form_field.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Send BNP to another member by @username. Off-chain: no network choice,
/// no address, and it works while the on-chain wallet is disabled.
/// Pops with a success message once the transfer is recorded.
class SendPointsPage extends StatefulWidget {
  const SendPointsPage({
    super.key,
    required this.asset,
    this.search,
  });

  final WalletAssetBalance asset;

  /// Recipient suggestions source; injectable for tests.
  final ProfileSearch? search;

  @override
  State<SendPointsPage> createState() => _SendPointsPageState();
}

class _SendPointsPageState extends State<SendPointsPage> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _submitting = false;
  String? _error;

  /// One key per page: a double tap or a retry after a timeout replays the
  /// same transfer instead of sending twice.
  late final String _idempotencyKey =
      'bnp-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random().nextInt(0x7fffffff).toRadixString(16)}';

  int get _decimals => widget.asset.decimals ?? 3;

  String? _ownUsername;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _ownUsername = Provider.of<AuthStore>(context, listen: false).username;
    } on ProviderNotFoundException {
      _ownUsername = null;
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final walletStore = context.read<WalletStore>();
    final available = walletStore.findAsset(walletPointsAsset)?.available ??
        widget.asset.available;
    final validationError = validatePointsTransfer(
      recipient: _recipientController.text,
      amount: _amountController.text,
      available: available,
      ownUsername: _ownUsername,
      decimals: _decimals,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final username = normalizePointsRecipient(_recipientController.text)!;
    final amount = _amountController.text.trim();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await walletStore.sendPoints(
        recipient: username,
        amountAtomic: pointsAmountToAtomic(amount, decimals: _decimals)!,
        idempotencyKey: _idempotencyKey,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        '${formatTokenAmount(amount, maxDecimals: _decimals)} BNP sent to @$username.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = walletErrorText(walletStore, error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final asset = walletStore.findAsset(walletPointsAsset) ?? widget.asset;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text('Send BNP', style: AppText.title(AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SendHeaderCard(
                icon: Icons.compare_arrows_rounded,
                title: 'Send Blocnet Points',
                subtitle: 'Arrives instantly, to any member',
              ),
              const SizedBox(height: AppSpace.md),
              WalletCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PointsRecipientField(
                      controller: _recipientController,
                      search: widget.search,
                      ownUsername: _ownUsername,
                    ),
                    const SizedBox(height: AppSpace.md),
                    WalletFormField(
                      fieldKey: const ValueKey('points-amount'),
                      label: 'Amount (BNP)',
                      controller: _amountController,
                      hint: '0.0',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Available: ${formatAssetAmount(asset)} BNP',
                      style: AppText.caption(AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpace.md),
                    WalletFormField(
                      fieldKey: const ValueKey('points-note'),
                      label: 'Note (optional)',
                      controller: _noteController,
                      hint: 'Add a note',
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.md),
                Text(_error!, style: AppText.label(AppColors.tagWarning)),
              ],
              const SizedBox(height: AppSpace.lg),
              SendSubmitButton(
                label: 'Send BNP',
                submitting: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
