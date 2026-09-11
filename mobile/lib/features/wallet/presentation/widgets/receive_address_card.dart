import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
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
    return AppSurface(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Text(
            'YOUR WALLET ADDRESS',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            networkLabel,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.labelSize,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
            ),
            child: QrImageView(
              data: address,
              version: QrVersions.auto,
              size: 200,
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
          const SizedBox(height: AppSpace.lg),
          GestureDetector(
            onTap: () => _copy(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md, vertical: AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: SelectableText(
                address,
                textAlign: TextAlign.center,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copy(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(44),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: AppIcon.sm),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: AppColors.borderMuted),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                    ),
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: AppIcon.sm),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
