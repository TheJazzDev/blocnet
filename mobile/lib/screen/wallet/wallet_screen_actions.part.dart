part of '../wallet_screen.dart';

enum _SendFlowAction { internalTransfer, externalWithdrawal }

class _ActionRow extends StatelessWidget {
  const _ActionRow({this.assetCode = 'BNT'});

  final String assetCode;

  bool _isWalletReady(WalletStore store) {
    final status = store.snapshot?.walletStatus ?? 'provisioning';
    return status == 'ready';
  }

  String _notReadyMessage(WalletStore store) {
    final status = store.snapshot?.walletStatus ?? 'provisioning';
    if (store.isLoadingSummary && store.snapshot == null) {
      return 'Wallet is syncing. Try again in a moment.';
    }

    if (status == 'disabled') {
      return 'Wallet is currently disabled.';
    }

    if (status == 'error') {
      return 'Wallet setup has an issue. Pull to refresh and try again.';
    }

    return 'Wallet is not ready yet.';
  }

  Future<void> _openSendMenu(BuildContext context) async {
    final walletStore = context.read<WalletStore>();
    final selectedAsset = assetCode.trim().toUpperCase();
    final canTransfer = walletStore.canTransferAsset(selectedAsset);
    final canWithdraw = walletStore.canWithdrawAsset(selectedAsset);

    if (!_isWalletReady(walletStore)) {
      _showWalletToast(
        context,
        message: _notReadyMessage(walletStore),
        type: _WalletToastType.error,
      );
      return;
    }

    if (!canTransfer && !canWithdraw) {
      _showWalletToast(
        context,
        message: '$selectedAsset send and withdrawal are currently disabled.',
        type: _WalletToastType.info,
      );
      return;
    }

    final resultMessage = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _SendTokenPage(
          assetCode: selectedAsset,
          canTransfer: canTransfer,
          canWithdraw: canWithdraw,
        ),
      ),
    );

    if (!context.mounted || resultMessage == null || resultMessage.isEmpty) {
      return;
    }

    _showWalletToast(
      context,
      message: resultMessage,
      type: _WalletToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final address = walletStore.snapshot?.walletAddress;
    final hasAddress = address != null && address.isNotEmpty;

    return Row(
      children: [
        _ActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Send',
          onTap: () => _openSendMenu(context),
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.arrow_downward_rounded,
          label: 'Receive',
          onTap: () {
            if (!hasAddress) {
              _showWalletToast(
                context,
                message: _notReadyMessage(walletStore),
                type: _WalletToastType.error,
              );
              return;
            }
            Clipboard.setData(ClipboardData(text: address));
            _showWalletToast(
              context,
              message: 'Wallet address copied successfully.',
              type: _WalletToastType.success,
            );
          },
        ),
      ],
    );
  }
}

class _SendTokenPage extends StatefulWidget {
  const _SendTokenPage({
    required this.assetCode,
    required this.canTransfer,
    required this.canWithdraw,
  });

  final String assetCode;
  final bool canTransfer;
  final bool canWithdraw;

  @override
  State<_SendTokenPage> createState() => _SendTokenPageState();
}

class _SendTokenPageState extends State<_SendTokenPage> {
  static final RegExp _evmAddressPattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
  static final RegExp _usernamePattern = RegExp(r'^@?[a-zA-Z0-9_]{3,24}$');
  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,18})?$');

  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();

  late _SendFlowAction _action;
  bool _submitting = false;
  String? _error;

  bool get _isInternal => _action == _SendFlowAction.internalTransfer;

  @override
  void initState() {
    super.initState();
    _action = widget.canTransfer
        ? _SendFlowAction.internalTransfer
        : _SendFlowAction.externalWithdrawal;
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
        size: 12,
        weight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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

  String _idempotencyKey(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch.toString()}';

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
          idempotencyKey: _idempotencyKey('itr'),
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
        idempotencyKey: _idempotencyKey('wdr'),
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

  void _changeAction(_SendFlowAction action) {
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            _isInternal
                ? Icons.compare_arrows_rounded
                : Icons.call_made_rounded,
            color: AppColors.teal400,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11,
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
            size: 18,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              size: 17,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isInternal
                                ? 'Instant wallet-to-wallet transfer'
                                : 'Queued and reviewed before payout',
                            style: AppTypography.custom(color: AppColors.textMuted,
                              size: 12,
                              weight: FontWeight.w400,),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                            _changeAction(_SendFlowAction.internalTransfer),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SendModeTile(
                        icon: Icons.call_made_rounded,
                        title: 'External',
                        subtitle: 'Approval queue',
                        isActive: !_isInternal,
                        onTap: () =>
                            _changeAction(_SendFlowAction.externalWithdrawal),
                      ),
                    ),
                  ],
                )
              else
                _modeHint(),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isInternal
                          ? 'Recipient (@username or wallet)'
                          : 'Recipient wallet address',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.custom(color: AppColors.textSecondary,
                        size: 13,
                        weight: FontWeight.w400,),
                      decoration: _fieldDecoration(
                        _isInternal ? '@username or 0x...' : '0x...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Amount (${widget.assetCode})',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      style: AppTypography.custom(color: AppColors.textSecondary,
                        size: 13,
                        weight: FontWeight.w400,),
                      decoration: _fieldDecoration('0.0'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isInternal ? 'Note (optional)' : 'Reason (required)',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller:
                          _isInternal ? _noteController : _reasonController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      style: AppTypography.custom(color: AppColors.textSecondary,
                        size: 13,
                        weight: FontWeight.w400,),
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
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: AppTypography.custom(color: AppColors.error500,
                    size: 12,
                    weight: FontWeight.w400,),
                ),
              ],
              const SizedBox(height: 16),
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
                      borderRadius: BorderRadius.circular(14),
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
                            size: 14,
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.teal400),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 12,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 10,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.teal400, size: 17),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 11,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
