import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

enum WalletToastType { info, success, error }

/// A short message pinned under the app bar: elevated ground, a coloured
/// hairline and icon for its kind.
void showWalletToast(
  BuildContext context, {
  required String message,
  WalletToastType type = WalletToastType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final (Color tone, IconData icon) = switch (type) {
    WalletToastType.success => (
        AppColors.successColor,
        Icons.check_circle_rounded
      ),
    WalletToastType.error => (AppColors.tagWarning, Icons.error_rounded),
    WalletToastType.info => (AppColors.primary500, Icons.info_rounded),
  };

  messenger.hideCurrentSnackBar();
  final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;
  final bottomInset = MediaQuery.sizeOf(context).height - topInset - 72;
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 6),
      showCloseIcon: true,
      closeIconColor: AppColors.textMuted,
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.bgElevated,
      elevation: 0,
      margin: EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        bottomInset.clamp(16, 1200).toDouble(),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: BorderSide(color: tone.withValues(alpha: 0.5)),
      ),
      content: Row(
        children: [
          Icon(icon, size: AppIcon.md, color: tone),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              message,
              style: AppText.label(AppColors.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}
