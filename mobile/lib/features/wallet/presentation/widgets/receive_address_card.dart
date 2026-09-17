import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_button.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR code + full address + copy/share actions for the Receive view.
class ReceiveAddressCard extends StatelessWidget {
  const ReceiveAddressCard({
    super.key,
    required this.address,
    required this.networkLabel,
    required this.onShare,
  });

  final String address;
  final String networkLabel;
  final VoidCallback onShare;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: address));
    showWalletToast(
      context,
      message: 'Address copied.',
      type: WalletToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WalletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_rounded,
                size: AppIcon.sm,
                color: AppColors.textFaint,
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                'YOUR WALLET ADDRESS',
                style: WalletType.caps(AppColors.textFaint),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(networkLabel, style: WalletType.meta(AppColors.textMuted)),
          const SizedBox(height: AppSpace.lg),
          // A QR code must sit on white to scan.
          Center(
            child: Container(
              padding: AppSpace.allMd,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.md,
              ),
              child: QrImageView(
                data: address,
                version: QrVersions.auto,
                size: 180,
                gapless: true,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Container(
            width: double.infinity,
            padding: AppSpace.allMd,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: AppRadius.sm,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: SelectableText(
              address,
              style: AppText.label(
                AppColors.textSecondary,
                weight: AppText.semibold,
              ).merge(AppText.tabular).copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: WalletButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onPressed: () => _copy(context),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: WalletButton.outlined(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onPressed: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
