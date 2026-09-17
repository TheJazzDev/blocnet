import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_sheet_styles.dart';
import 'package:flutter/material.dart';

/// Amount, note, the error line and the send button.
class TipForm extends StatelessWidget {
  const TipForm({
    super.key,
    required this.amountController,
    required this.noteController,
    required this.symbol,
    required this.error,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController amountController;
  final TextEditingController noteController;
  final String symbol;
  final String? error;
  final bool isSending;

  /// Null disables the button.
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Amount ($symbol)'),
        TextField(
          key: const ValueKey('tip-amount'),
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          style: AppText.body(AppColors.textPrimary, weight: AppText.medium),
          decoration: tipFieldDecoration('0.0'),
        ),
        const SizedBox(height: AppSpace.md),
        _label('Note (optional)'),
        TextField(
          key: const ValueKey('tip-note'),
          controller: noteController,
          maxLines: 2,
          minLines: 1,
          style: AppText.body(AppColors.textPrimary),
          decoration: tipFieldDecoration('Thanks for the call'),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(error!, style: AppText.label(AppColors.tagWarning)),
        ],
        const SizedBox(height: AppSpace.lg),
        _SendButton(isSending: isSending, onSend: onSend),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: Text(
          text,
          style: AppText.label(AppColors.textSecondary, weight: AppText.bold),
        ),
      );
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSending, required this.onSend});

  final bool isSending;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final onAccent = tipOnAccent();
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: isSending ? null : onSend,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary500,
          foregroundColor: onAccent,
          disabledBackgroundColor: AppColors.bgElevated,
          disabledForegroundColor: AppColors.textFaint,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
        child: isSending
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppColors.textMuted,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Send tip',
                style: AppText.body(
                  onSend == null ? AppColors.textFaint : onAccent,
                  weight: AppText.bold,
                ),
              ),
      ),
    );
  }
}
