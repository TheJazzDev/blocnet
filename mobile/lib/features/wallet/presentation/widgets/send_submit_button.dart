import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Full-width primary button of the wallet send pages, with a busy state.
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: submitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal500,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.bgElevated.withValues(alpha: 0.8),
          disabledForegroundColor: AppColors.textFaint,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lgValue),
          ),
        ),
        child: submitting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.bgBase,
                ),
              )
            : Text(
                label,
                style: AppTypography.custom(
                  color: Colors.black,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
