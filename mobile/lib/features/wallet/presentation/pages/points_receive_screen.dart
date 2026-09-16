import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Opens [PointsReceiveScreen] for the signed-in member.
Future<void> openPointsReceive(BuildContext context) {
  String? username;
  try {
    username = Provider.of<AuthStore>(context, listen: false).username;
  } on ProviderNotFoundException {
    username = null;
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PointsReceiveScreen(username: username),
    ),
  );
}

/// Receive view for BNP. BNP moves between members by @username, so this
/// shows the member's handle to share — never the on-chain address, which
/// cannot receive points.
class PointsReceiveScreen extends StatelessWidget {
  const PointsReceiveScreen({super.key, required this.username});

  final String? username;

  String? get _handle {
    final value = username?.trim() ?? '';
    return value.isEmpty ? null : '@$value';
  }

  void _copy(BuildContext context, String handle) {
    Clipboard.setData(ClipboardData(text: handle));
    showWalletToast(
      context,
      message: 'Username copied.',
      type: WalletToastType.success,
    );
  }

  Future<void> _share(BuildContext context, String handle) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Send me BNP on Blocnet: $handle',
          subject: 'My Blocnet username',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      showWalletToast(
        context,
        message: 'Unable to open share options right now.',
        type: WalletToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final handle = _handle;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Receive BNP',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.titleSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xl),
        child: AppSurface(
          radius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Share your username to receive BNP',
                textAlign: TextAlign.center,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'Blocnet Points move between members in the app. '
                'Anyone can send you BNP with your @username.',
                textAlign: TextAlign.center,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.labelSize,
                  weight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                handle ?? 'Set a username in your profile to receive BNP.',
                textAlign: TextAlign.center,
                style: AppTypography.custom(
                  color: handle == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  size: handle == null ? AppText.labelSize : AppText.titleSize,
                  weight: FontWeight.w800,
                ),
              ),
              if (handle != null) ...[
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copy(context, handle),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(44),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.mdValue),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: AppIcon.sm),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _share(context, handle),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: AppColors.borderMuted),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.mdValue),
                          ),
                        ),
                        icon: const Icon(
                          Icons.ios_share_rounded,
                          size: AppIcon.sm,
                        ),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
