import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/utils/token_send_form.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/send_header_card.dart';
import 'package:blocnet/features/wallet/presentation/widgets/send_mode_tile.dart';
import 'package:blocnet/features/wallet/presentation/widgets/send_submit_button.dart';
import 'package:blocnet/features/wallet/presentation/widgets/send_token_fields.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SendFlowAction { internalTransfer, externalWithdrawal }

/// Send a token: inside Blocnet (instant) or on-chain (reviewed first).
/// Pops with a success message once the request is accepted.
class SendTokenPage extends StatefulWidget {
  const SendTokenPage({
    super.key,
    required this.assetCode,
    required this.canTransfer,
    required this.canWithdraw,
  });

  final String assetCode;
  final bool canTransfer;
  final bool canWithdraw;

  @override
  State<SendTokenPage> createState() => _SendTokenPageState();
}

class _SendTokenPageState extends State<SendTokenPage> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();

  late SendFlowAction _action;
  bool _submitting = false;
  String? _error;
  late final String _transferIdempotencyKey =
      'itr-${DateTime.now().microsecondsSinceEpoch}';
  late final String _withdrawalIdempotencyKey =
      'wdr-${DateTime.now().microsecondsSinceEpoch}';

  bool get _isInternal => _action == SendFlowAction.internalTransfer;

  @override
  void initState() {
    super.initState();
    _action = widget.canTransfer
        ? SendFlowAction.internalTransfer
        : SendFlowAction.externalWithdrawal;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validationError = validateTokenSend(
      inBlocnet: _isInternal,
      recipient: _addressController.text,
      amount: _amountController.text,
      reason: _reasonController.text,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final walletStore = context.read<WalletStore>();
    final asset = widget.assetCode;
    final amount = _amountController.text.trim();
    try {
      if (_isInternal) {
        final recipient = _addressController.text.trim();
        final toUsername = tokenSendUsername(recipient);
        final note = _noteController.text.trim();
        await walletStore.createInternalTransfer(
          amount: amount,
          asset: asset,
          toAddress: toUsername == null ? recipient : null,
          toUsername: toUsername,
          note: note.isEmpty ? null : note,
          idempotencyKey: _transferIdempotencyKey,
        );
        if (!mounted) return;
        Navigator.of(context).pop('${_amountLabel(amount)} $asset sent.');
        return;
      }

      await walletStore.createWithdrawal(
        toAddress: _addressController.text.trim(),
        amount: amount,
        reason: _reasonController.text.trim(),
        asset: asset,
        idempotencyKey: _withdrawalIdempotencyKey,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        'Withdrawal of ${_amountLabel(amount)} $asset requested. '
        "It's reviewed before it's sent.",
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = walletErrorText(walletStore, error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _amountLabel(String amount) => formatTokenAmount(amount);

  void _changeAction(SendFlowAction action) {
    if (_submitting || _action == action) return;
    setState(() {
      _action = action;
      _error = null;
    });
  }

  Widget _modeChoice() {
    if (!(widget.canTransfer && widget.canWithdraw)) {
      return SendHeaderCard(
        icon: _isInternal
            ? Icons.compare_arrows_rounded
            : Icons.call_made_rounded,
        title: _isInternal ? 'Send inside Blocnet' : 'Withdraw on-chain',
        subtitle: _isInternal ? 'Arrives instantly' : 'Reviewed before sending',
      );
    }
    return Row(
      children: [
        Expanded(
          child: SendModeTile(
            icon: Icons.compare_arrows_rounded,
            title: 'In Blocnet',
            subtitle: 'Instant',
            isActive: _isInternal,
            onTap: () => _changeAction(SendFlowAction.internalTransfer),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: SendModeTile(
            icon: Icons.call_made_rounded,
            title: 'On-chain',
            subtitle: 'Reviewed first',
            isActive: !_isInternal,
            onTap: () => _changeAction(SendFlowAction.externalWithdrawal),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = context.watch<WalletStore>().findAsset(widget.assetCode);
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Send ${widget.assetCode}',
          style: AppText.title(AppColors.textPrimary),
        ),
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
              _modeChoice(),
              const SizedBox(height: AppSpace.md),
              SendTokenFields(
                assetCode: widget.assetCode,
                inBlocnet: _isInternal,
                recipient: _addressController,
                amount: _amountController,
                note: _noteController,
                reason: _reasonController,
                available: asset == null ? null : formatAssetAmount(asset),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.md),
                Text(_error!, style: AppText.label(AppColors.tagWarning)),
              ],
              const SizedBox(height: AppSpace.lg),
              SendSubmitButton(
                label: _isInternal ? 'Send' : 'Request withdrawal',
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
