import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final snapshot = walletStore.snapshot;
    final address = snapshot?.walletAddress;
    final status = snapshot?.walletStatus ?? 'provisioning';
    final addressText = address != null && address.isNotEmpty
        ? truncateMiddle(address)
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
                '\$${formatUsd(totalUsd)}',
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
                    showWalletToast(
                      context,
                      message: 'Wallet address is not ready yet.',
                      type: WalletToastType.error,
                    );
                    return;
                  }
                  Clipboard.setData(ClipboardData(text: address));
                  showWalletToast(
                    context,
                    message: 'Address copied.',
                    type: WalletToastType.success,
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
