import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// Full-width filled button of the wallet send pages, with a busy state.
class SendSubmitButton extends StatelessWidget {
  const SendSubmitButton({
    super.key,
    required this.label,
    required this.submitting,
    required this.onPressed,
  });

  final String label;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onAccent = WalletTone.onAccent;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: submitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: WalletTone.accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: AppColors.bgElevated,
          disabledForegroundColor: AppColors.textFaint,
          elevation: 0,
          minimumSize: const Size.fromHeight(46),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
        child: submitting
            ? SizedBox(
                width: AppIcon.sm,
                height: AppIcon.sm,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              )
            : Text(
                label,
                style: AppText.body(onAccent, weight: AppText.bold),
              ),
      ),
    );
  }
}
