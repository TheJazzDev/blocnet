part of '../wallet_screen.dart';

Color _assetAccentColor(String assetCode) {
  switch (assetCode.toUpperCase()) {
    case 'BNB':
      return const Color(0xFFF3BA2F);
    case 'USDT':
      return const Color(0xFF26A17B);
    case 'BNT':
    default:
      return AppColors.teal400;
  }
}

String _formatUsd(String value, {int decimals = 2}) {
  final parsed = num.tryParse(value);
  if (parsed == null) return value;
  return parsed.toStringAsFixed(decimals);
}

String _assetBadgeText(WalletAssetBalance asset) {
  return asset.isNative ? 'BSC' : 'BEP-20';
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  String _truncateMiddle(String value, {int head = 8, int tail = 6}) {
    if (value.length <= head + tail + 3) return value;
    final prefix = value.substring(0, head);
    final suffix = value.substring(value.length - tail);
    return '$prefix...$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final snapshot = walletStore.snapshot;
    final address = snapshot?.walletAddress;
    final status = snapshot?.walletStatus ?? 'provisioning';
    final addressText = address != null && address.isNotEmpty
        ? _truncateMiddle(address)
        : (status == 'disabled'
            ? 'Wallet feature disabled'
            : status == 'error'
                ? 'Provisioning error'
                : 'Provisioning wallet...');

    final totalUsd = snapshot?.totalUsdValue ?? '0';

    return Stack(
      children: [
        // Background glow effects
        Positioned(
          right: -40,
          top: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.teal500.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -30,
          bottom: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary500.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Main content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F1419),
                AppColors.bgSurface,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.teal500.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.teal400,
                          AppColors.teal500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'My Wallet',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'TOTAL BALANCE',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_formatUsd(totalUsd)}',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 44,
                  weight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'BSC Network',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Address section
              GestureDetector(
                onTap: () {
                  if (address == null || address.isEmpty) {
                    _showWalletToast(
                      context,
                      message: 'Wallet address is not ready yet.',
                      type: _WalletToastType.error,
                    );
                    return;
                  }
                  Clipboard.setData(ClipboardData(text: address));
                  _showWalletToast(
                    context,
                    message: 'Address copied.',
                    type: _WalletToastType.success,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.borderSubtle.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.qr_code_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addressText,
                              style: AppTypography.custom(
                                color: AppColors.textSecondary,
                                size: 12,
                                weight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to copy address',
                              style: AppTypography.custom(
                                color: AppColors.textFaint,
                                size: 10,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: AppColors.teal400,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.arrow_downward_rounded,
            label: 'Receive',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.successColor,
                AppColors.successColor.withValues(alpha: 0.7),
              ],
            ),
            onTap: () {
              _showWalletToast(
                context,
                message: 'Tap on an asset to view receive address.',
                type: _WalletToastType.info,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Send',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary500,
                AppColors.primary600,
              ],
            ),
            onTap: () {
              _showWalletToast(
                context,
                message: 'Tap on an asset to send or withdraw.',
                type: _WalletToastType.info,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Swap',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.teal500,
                AppColors.teal400,
              ],
            ),
            onTap: () {
              _showWalletToast(
                context,
                message: 'Swap feature coming soon.',
                type: _WalletToastType.info,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.black,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.custom(
                size: 12,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetBalanceCard extends StatelessWidget {
  const _AssetBalanceCard({required this.assetCode});

  final String assetCode;

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final asset = walletStore.findAsset(assetCode);
    final accent = _assetAccentColor(assetCode);

    if (asset == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          'Loading $assetCode balance...',
          style: AppTypography.custom(color: AppColors.textMuted,
            size: 13,
            weight: FontWeight.w400,),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            AppColors.primary500.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                asset.name,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 17,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  _assetBadgeText(asset),
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 10,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${asset.available} ${asset.asset}',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 32,
              weight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${_formatUsd(asset.usdValue)} • Price \$${_formatUsd(asset.usdPrice, decimals: 4)}',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    this.actionLabel,
    this.actionRoute,
  });

  final String label;
  final String? actionLabel;
  final String? actionRoute;

  @override
  Widget build(BuildContext context) {
    final canShowAction = actionLabel != null && actionRoute != null;

    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        if (canShowAction)
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(actionRoute!),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary500,
            ),
            child: Text(
              actionLabel!,
              style: AppTypography.custom(
                color: AppColors.primary500,
                size: 11,
                weight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _AssetsSection extends StatelessWidget {
  const _AssetsSection();

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final snapshot = walletStore.snapshot;
    final assets = snapshot?.assets ?? const <WalletAssetBalance>[];

    if (walletStore.isLoadingSummary && snapshot == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.teal400,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    if (assets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          'No assets available yet.',
          style: AppTypography.custom(color: AppColors.textMuted,
            size: 12,
            weight: FontWeight.w400,),
        ),
      );
    }

    return Column(
      children: assets
          .map((asset) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AssetRow(asset: asset),
              ))
          .toList(),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset});

  final WalletAssetBalance asset;

  @override
  Widget build(BuildContext context) {
    final accent = _assetAccentColor(asset.asset);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.walletAssetDetail,
          arguments: {'assetCode': asset.asset},
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                asset.symbol,
                style: AppTypography.custom(
                  color: accent,
                  size: 13,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        asset.asset,
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: 11,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _assetBadgeText(asset),
                          style: AppTypography.custom(
                            color: accent,
                            size: 8,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  asset.available,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${_formatUsd(asset.usdValue)}',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textFaint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletActivityItem {
  const _WalletActivityItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.amountColor,
    required this.occurredAt,
    required this.isOutgoing,
    required this.isIncoming,
    this.transaction,
    this.withdrawal,
    this.badgeLabel,
    this.badgeColor,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String amountLabel;
  final Color amountColor;
  final DateTime? occurredAt;
  final bool isOutgoing;
  final bool isIncoming;
  final WalletTransaction? transaction;
  final WalletWithdrawalRequest? withdrawal;
  final String? badgeLabel;
  final Color? badgeColor;
}

class _WalletDetailField {
  const _WalletDetailField({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool copyable;
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    this.limit,
    this.assetCode,
  });

  final int? limit;
  final String? assetCode;

  String _truncateMiddle(String value, {int head = 8, int tail = 6}) {
    if (value.isEmpty) return value;
    if (value.length <= head + tail + 3) return value;
    final prefix = value.substring(0, head);
    final suffix = value.substring(value.length - tail);
    return '$prefix...$suffix';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'just now';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    return '$month ${local.day}, ${local.year} • $hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.successColor;
      case 'rejected':
      case 'reverted':
      case 'failed':
        return AppColors.error500;
      case 'broadcasting':
      case 'approved':
      case 'pending_review':
      case 'requested':
        return AppColors.primary500;
      default:
        return AppColors.textMuted;
    }
  }

  String _toTitleCase(String value) {
    final words = value
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (words.isEmpty) return value;
    return words
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _directionLabel(String direction) {
    switch (direction) {
      case 'incoming':
        return 'Received';
      case 'outgoing':
        return 'Sent';
      default:
        return 'Internal';
    }
  }

  String _trimValue(String? value) {
    return value?.trim() ?? '';
  }

  void _showCopiedToast(BuildContext context, String message) {
    _showWalletToast(
      context,
      message: message,
      type: _WalletToastType.success,
    );
  }

  void _showTransactionDetails(BuildContext context, _WalletActivityItem row) {
    final tx = row.transaction;
    final withdrawal = row.withdrawal;
    if (tx == null && withdrawal == null) {
      return;
    }

    final fields = <_WalletDetailField>[];
    if (tx != null) {
      final metadata = tx.metadata;
      final counterparty = tx.counterparty;
      final counterpartyLabel = counterparty?.preferredLabel ?? '';
      final counterpartyAddress = _trimValue(
        counterparty?.walletAddress ??
            (tx.isOutgoing
                ? tx.metadataString('recipientAddress')
                : tx.metadataString('senderAddress')),
      );
      final fromAddress = _trimValue(tx.metadataString('fromAddress'));
      final toAddress = _trimValue(tx.metadataString('toAddress'));
      final txHash = _trimValue(tx.metadataString('txHash'));
      final note = _trimValue(tx.metadataString('note'));

      fields.addAll([
        _WalletDetailField(label: 'Type', value: _toTitleCase(tx.reason)),
        _WalletDetailField(
            label: 'Direction', value: _directionLabel(tx.direction)),
        _WalletDetailField(label: 'Amount', value: '${tx.amount} ${tx.asset}'),
        _WalletDetailField(label: 'Date', value: _formatDate(tx.createdAt)),
      ]);

      if (counterpartyLabel.isNotEmpty) {
        fields.add(_WalletDetailField(
            label: 'Counterparty', value: counterpartyLabel));
      }
      if (counterpartyAddress.isNotEmpty) {
        fields.add(
          _WalletDetailField(
            label: 'Counterparty Wallet',
            value: counterpartyAddress,
            copyable: true,
          ),
        );
      }
      if (fromAddress.isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'From Wallet', value: fromAddress, copyable: true),
        );
      }
      if (toAddress.isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'To Wallet', value: toAddress, copyable: true),
        );
      }
      if (txHash.isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'Transaction Hash', value: txHash, copyable: true),
        );
      }
      final logIndex = tx.metadataInt('logIndex');
      if (logIndex != null) {
        fields.add(
            _WalletDetailField(label: 'Log Index', value: logIndex.toString()));
      }
      final depositId = _trimValue(metadata?['depositId']?.toString());
      if (depositId.isNotEmpty) {
        fields.add(_WalletDetailField(
            label: 'Deposit ID', value: depositId, copyable: true));
      }
      if (note.isNotEmpty) {
        fields.add(_WalletDetailField(label: 'Note', value: note));
      }
      if (tx.referenceId != null && tx.referenceId!.trim().isNotEmpty) {
        fields.add(
          _WalletDetailField(
            label: 'Reference ID',
            value: tx.referenceId!,
            copyable: true,
          ),
        );
      }
      fields.add(_WalletDetailField(
          label: 'Ledger Entry ID', value: tx.id, copyable: true));
    }

    if (withdrawal != null) {
      fields.addAll([
        _WalletDetailField(label: 'Type', value: 'Withdrawal'),
        _WalletDetailField(
            label: 'Status', value: _toTitleCase(withdrawal.status)),
        _WalletDetailField(
          label: 'Amount',
          value: '-${withdrawal.amount} ${withdrawal.asset}',
        ),
        _WalletDetailField(
          label: 'Destination Wallet',
          value: withdrawal.toAddress,
          copyable: true,
        ),
        _WalletDetailField(label: 'Reason', value: withdrawal.reason),
        _WalletDetailField(
          label: 'Requested At',
          value: _formatDate(withdrawal.requestedAt),
        ),
      ]);
      if (withdrawal.broadcastTxHash != null &&
          withdrawal.broadcastTxHash!.trim().isNotEmpty) {
        fields.add(
          _WalletDetailField(
            label: 'Broadcast Tx Hash',
            value: withdrawal.broadcastTxHash!,
            copyable: true,
          ),
        );
      }
      if (withdrawal.rejectReason != null &&
          withdrawal.rejectReason!.trim().isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'Reject Reason', value: withdrawal.rejectReason!),
        );
      }
      if (withdrawal.failureReason != null &&
          withdrawal.failureReason!.trim().isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'Failure Reason', value: withdrawal.failureReason!),
        );
      }
      fields.add(
        _WalletDetailField(
          label: 'Withdrawal ID',
          value: withdrawal.id,
          copyable: true,
        ),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final title =
            tx != null ? _toTitleCase(tx.reason) : 'Withdrawal Details';
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              18 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderMuted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 18,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.label,
                                    style: AppTypography.custom(
                                      color: AppColors.textFaint,
                                      size: 11,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    field.value,
                                    style: AppTypography.custom(
                                      color: AppColors.textSecondary,
                                      size: 12,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (field.copyable) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: field.value),
                                  );
                                  _showCopiedToast(
                                    sheetContext,
                                    '${field.label} copied.',
                                  );
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.borderSubtle),
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 15,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_WalletActivityItem> _buildRows(WalletStore walletStore) {
    final rows = <_WalletActivityItem>[];
    final transactionIds = <String>{};
    final selectedAsset = assetCode?.toUpperCase();

    final transactions = selectedAsset == null
        ? walletStore.transactions
        : walletStore.transactionsForAsset(selectedAsset);
    final withdrawals = selectedAsset == null
        ? walletStore.withdrawals
        : walletStore.withdrawalsForAsset(selectedAsset);

    for (final tx in transactions) {
      if (tx.id.isNotEmpty) {
        transactionIds.add(tx.id);
      }

      final isOutgoing = tx.direction == 'outgoing';
      final isIncoming = tx.direction == 'incoming';
      final sign = isOutgoing
          ? '-'
          : isIncoming
              ? '+'
              : '';
      final icon = isOutgoing
          ? Icons.arrow_upward_rounded
          : isIncoming
              ? Icons.arrow_downward_rounded
              : Icons.swap_horiz_rounded;

      rows.add(
        _WalletActivityItem(
          id: tx.id.isNotEmpty ? 'tx_${tx.id}' : 'tx_${rows.length}',
          icon: icon,
          title: tx.reason.replaceAll('_', ' ').toUpperCase(),
          subtitle: _formatDate(tx.createdAt),
          amountLabel: '$sign${tx.amount} ${tx.asset}',
          amountColor: isOutgoing
              ? AppColors.error500
              : isIncoming
                  ? AppColors.successColor
                  : AppColors.textMuted,
          occurredAt: tx.createdAt,
          isOutgoing: isOutgoing,
          isIncoming: isIncoming,
          transaction: tx,
        ),
      );
    }

    for (final withdrawal in withdrawals) {
      if (withdrawal.id.isNotEmpty && transactionIds.contains(withdrawal.id)) {
        continue;
      }

      final statusLabel = withdrawal.status.replaceAll('_', ' ').toUpperCase();
      final addressLabel = withdrawal.toAddress.isEmpty
          ? 'External wallet'
          : _truncateMiddle(withdrawal.toAddress);

      rows.add(
        _WalletActivityItem(
          id: withdrawal.id.isNotEmpty
              ? 'withdrawal_${withdrawal.id}'
              : 'withdrawal_${rows.length}',
          icon: Icons.call_made_rounded,
          title: 'WITHDRAWAL',
          subtitle: '$addressLabel • ${_formatDate(withdrawal.requestedAt)}',
          amountLabel: '-${withdrawal.amount} ${withdrawal.asset}',
          amountColor: AppColors.error500,
          occurredAt: withdrawal.requestedAt,
          isOutgoing: true,
          isIncoming: false,
          withdrawal: withdrawal,
          badgeLabel: statusLabel,
          badgeColor: _statusColor(withdrawal.status),
        ),
      );
    }

    rows.sort((a, b) {
      final aDate = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final rows = _buildRows(walletStore);
    final visibleRows = limit == null ? rows : rows.take(limit!).toList();
    final selectedAsset = assetCode?.toUpperCase();
    final isLoading = selectedAsset == null
        ? walletStore.isLoadingTransactions || walletStore.isLoadingWithdrawals
        : walletStore.isLoadingTransactionsForAsset(selectedAsset) ||
            walletStore.isLoadingWithdrawalsForAsset(selectedAsset);

    if (isLoading && rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.teal400,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      final title = selectedAsset == null
          ? 'No transactions yet'
          : 'No $selectedAsset transactions yet';
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.textFaint,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: 14,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your wallet activity will appear here after your first transaction.',
              textAlign: TextAlign.center,
              style: AppTypography.custom(color: AppColors.textFaint,
                size: 12,
                weight: FontWeight.w400,
                height: 1.5,),
            ),
          ],
        ),
      );
    }

    return Column(
      children: visibleRows.map((row) {
        final badgeColor = row.badgeColor;
        final canOpenDetails =
            row.transaction != null || row.withdrawal != null;

        return Padding(
          key: ValueKey(row.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: canOpenDetails
                ? () => _showTransactionDetails(context, row)
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
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
                      size: 18,
                      color: row.isIncoming
                          ? AppColors.successColor
                          : row.isOutgoing
                              ? AppColors.primary500
                              : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (row.badgeLabel != null &&
                                badgeColor != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  row.badgeLabel!,
                                  style: AppTypography.custom(
                                    color: badgeColor,
                                    size: 8,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          row.subtitle,
                          style: AppTypography.custom(
                            color: AppColors.textFaint,
                            size: 11,
                            weight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        row.amountLabel,
                        style: AppTypography.custom(
                          color: row.amountColor,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      if (canOpenDetails) ...[
                        const SizedBox(height: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.textFaint,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
