import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_form_field.dart';
import 'package:flutter/material.dart';

/// Recipient, amount and note (or reason) for a token send.
class SendTokenFields extends StatelessWidget {
  const SendTokenFields({
    super.key,
    required this.assetCode,
    required this.inBlocnet,
    required this.recipient,
    required this.amount,
    required this.note,
    required this.reason,
    this.available,
  });

  final String assetCode;
  final bool inBlocnet;
  final TextEditingController recipient;
  final TextEditingController amount;
  final TextEditingController note;
  final TextEditingController reason;

  /// Formatted balance, shown under the amount when known.
  final String? available;

  @override
  Widget build(BuildContext context) {
    return WalletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WalletFormField(
            fieldKey: const ValueKey('token-recipient'),
            label: inBlocnet ? 'To (@username or wallet)' : 'To wallet address',
            controller: recipient,
            hint: inBlocnet ? '@username or 0x…' : '0x…',
          ),
          const SizedBox(height: AppSpace.md),
          WalletFormField(
            fieldKey: const ValueKey('token-amount'),
            label: 'Amount ($assetCode)',
            controller: amount,
            hint: '0.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (available != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              'Available: $available $assetCode',
              style: AppText.caption(AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          // Separate controllers keep each mode's text when switching.
          WalletFormField(
            key: ValueKey(inBlocnet),
            fieldKey: const ValueKey('token-note'),
            label: inBlocnet ? 'Note (optional)' : 'Reason',
            controller: inBlocnet ? note : reason,
            hint: inBlocnet ? 'Add a note' : 'What is this withdrawal for?',
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
