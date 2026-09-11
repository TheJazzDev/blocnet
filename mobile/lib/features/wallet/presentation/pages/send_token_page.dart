import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SendFlowAction { internalTransfer, externalWithdrawal }

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
  static final RegExp _evmAddressPattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
  static final RegExp _usernamePattern = RegExp(r'^@?[a-zA-Z0-9_]{3,24}$');
  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,18})?$');

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

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.custom(
        color: AppColors.textFaint,
        size: AppText.bodySize,
        weight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: AppColors.teal500),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
    );
  }

  String? _validate() {
    final recipient = _addressController.text.trim();
    final amount = _amountController.text.trim();

    if (_isInternal) {
      if (recipient.isEmpty) {
        return 'Enter a recipient @username or wallet address.';
      }
      if (!_evmAddressPattern.hasMatch(recipient)) {
        if (recipient.toLowerCase().startsWith('0x')) {
          return 'Enter a valid recipient wallet address.';
        }
        if (!_usernamePattern.hasMatch(recipient)) {
          return 'Enter a valid recipient @username or wallet address.';
        }
      }
    } else if (!_evmAddressPattern.hasMatch(recipient)) {
      return 'Enter a valid destination wallet address.';
    }
    if (!_amountPattern.hasMatch(amount)) {
      return 'Enter a valid amount (up to 18 decimals).';
    }
    final parsedAmount = num.tryParse(amount);
    if (parsedAmount == null || parsedAmount <= 0) {
      return 'Amount must be greater than zero.';
    }
    if (!_isInternal && _reasonController.text.trim().length < 3) {
      return 'Reason must be at least 3 characters.';
    }
    return null;
  }

  String? _normalizedRecipientUsername(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _evmAddressPattern.hasMatch(trimmed)) {
      return null;
    }
    if (!_usernamePattern.hasMatch(trimmed)) {
      return null;
    }
    return trimmed.replaceFirst(RegExp('^@'), '').toLowerCase();
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final walletStore = context.read<WalletStore>();
    try {
      if (_isInternal) {
        final recipientInput = _addressController.text.trim();
        final toUsername = _normalizedRecipientUsername(recipientInput);
        await walletStore.createInternalTransfer(
          amount: _amountController.text.trim(),
          asset: widget.assetCode,
          toAddress: toUsername == null ? recipientInput : null,
          toUsername: toUsername,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          idempotencyKey: _transferIdempotencyKey,
        );
        if (!mounted) return;
        Navigator.of(context).pop('${widget.assetCode} transfer submitted.');
        return;
      }

      final created = await walletStore.createWithdrawal(
        toAddress: _addressController.text.trim(),
        amount: _amountController.text.trim(),
        reason: _reasonController.text.trim(),
        asset: widget.assetCode,
        idempotencyKey: _withdrawalIdempotencyKey,
      );
      if (!mounted) return;
      final status = created?.status ?? 'pending_review';
      Navigator.of(
        context,
      ).pop('${widget.assetCode} withdrawal submitted ($status).');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = walletStore.describeError(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _changeAction(SendFlowAction action) {
    if (_submitting || _action == action) return;
    setState(() {
      _action = action;
      _error = null;
    });
  }

  Widget _modeHint() {
    final title = _isInternal ? 'Internal transfer' : 'External withdrawal';
    final subtitle = _isInternal
        ? 'Settles instantly between Blocnet wallets.'
        : 'Requests admin approval before on-chain send.';
    return AppSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Icon(
            _isInternal
                ? Icons.compare_arrows_rounded
                : Icons.call_made_rounded,
            color: AppColors.teal400,
            size: AppIcon.sm,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  subtitle,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSwitch = widget.canTransfer && widget.canWithdraw;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Send ${widget.assetCode}',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.titleSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lgValue),
                  border: Border.all(
                    color: AppColors.teal500.withValues(alpha: 0.28),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0D2628),
                      const Color(0xFF121922),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.teal500.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isInternal
                            ? Icons.compare_arrows_rounded
                            : Icons.call_made_rounded,
                        color: AppColors.teal400,
                        size: AppIcon.md,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isInternal
                                ? 'Internal transfer'
                                : 'External withdrawal',
                            style: AppTypography.custom(
                              color: AppColors.textPrimary,
                              size: AppText.subtitleSize,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpace.hair),
                          Text(
                            _isInternal
                                ? 'Instant wallet-to-wallet transfer'
                                : 'Queued and reviewed before payout',
                            style: AppTypography.custom(
                              color: AppColors.textMuted,
                              size: AppText.bodySize,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              if (hasSwitch)
                Row(
                  children: [
                    Expanded(
                      child: _SendModeTile(
                        icon: Icons.compare_arrows_rounded,
                        title: 'Internal',
                        subtitle: 'Instant',
                        isActive: _isInternal,
                        onTap: () =>
                            _changeAction(SendFlowAction.internalTransfer),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: _SendModeTile(
                        icon: Icons.call_made_rounded,
                        title: 'External',
                        subtitle: 'Approval queue',
                        isActive: !_isInternal,
                        onTap: () =>
                            _changeAction(SendFlowAction.externalWithdrawal),
                      ),
                    ),
                  ],
                )
              else
                _modeHint(),
              const SizedBox(height: AppSpace.lg),
              AppSurface(
                radius: AppRadius.lg,
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isInternal
                          ? 'Recipient (@username or wallet)'
                          : 'Recipient wallet address',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    TextField(
                      controller: _addressController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: AppText.bodySize,
                        weight: FontWeight.w400,
                      ),
                      decoration: _fieldDecoration(
                        _isInternal ? '@username or 0x...' : '0x...',
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Amount (${widget.assetCode})',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: AppText.bodySize,
                        weight: FontWeight.w400,
                      ),
                      decoration: _fieldDecoration('0.0'),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      _isInternal ? 'Note (optional)' : 'Reason (required)',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    TextField(
                      controller:
                          _isInternal ? _noteController : _reasonController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: AppText.bodySize,
                        weight: FontWeight.w400,
                      ),
                      decoration: _fieldDecoration(
                        _isInternal
                            ? 'Optional transfer note'
                            : 'Why is this withdrawal needed?',
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  _error!,
                  style: AppTypography.custom(
                    color: AppColors.error500,
                    size: AppText.bodySize,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal500,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.bgElevated.withValues(alpha: 0.8),
                    disabledForegroundColor: AppColors.textFaint,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lgValue),
                    ),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bgBase,
                          ),
                        )
                      : Text(
                          _isInternal ? 'Send now' : 'Submit withdrawal',
                          style: AppTypography.custom(
                            color: Colors.black,
                            size: AppText.bodySize,
                            weight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendModeTile extends StatelessWidget {
  const _SendModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? AppColors.teal500.withValues(alpha: 0.55)
        : AppColors.borderSubtle;
    final bgColor = isActive
        ? AppColors.teal500.withValues(alpha: 0.1)
        : AppColors.bgSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.mdValue),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppIcon.sm, color: AppColors.teal400),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.captionSize,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
