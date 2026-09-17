import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_button.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
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
        message: "Couldn't open sharing.",
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
        title: Text('Receive BNP', style: AppText.title(AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xl,
        ),
        child: WalletCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share your username to receive BNP',
                style: WalletType.rowTitle(AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpace.hair),
              Text(
                'Members send BNP to your @username.',
                style: WalletType.meta(AppColors.textMuted),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'YOUR USERNAME',
                style: WalletType.caps(AppColors.textFaint),
              ),
              const SizedBox(height: AppSpace.xs),
              if (handle == null)
                Text(
                  'Set a username in your profile to receive BNP.',
                  style: AppText.body(AppColors.textMuted),
                )
              else ...[
                Text(handle, style: AppText.headline(AppColors.textPrimary)),
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: WalletButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        onPressed: () => _copy(context, handle),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: WalletButton.outlined(
                        icon: Icons.ios_share_rounded,
                        label: 'Share',
                        onPressed: () => _share(context, handle),
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
