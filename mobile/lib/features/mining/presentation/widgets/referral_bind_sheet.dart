import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';

/// Opens the bind sheet. Resolves to true when a code was bound.
Future<bool> showReferralBindSheet(
  BuildContext context,
  MiningStore store,
) async {
  final bound = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ReferralBindSheet(store: store),
  );
  return bound == true;
}

/// Enter-and-bind form for a referrer's code.
///
/// A real [State] rather than a `StatefulBuilder` so it can check its *own*
/// `mounted` after each await (the sheet can be dismissed mid-request while
/// the screen behind it stays mounted) and dispose its controller.
class ReferralBindSheet extends StatefulWidget {
  const ReferralBindSheet({super.key, required this.store});

  final MiningStore store;

  @override
  State<ReferralBindSheet> createState() => _ReferralBindSheetState();
}

class _ReferralBindSheetState extends State<ReferralBindSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _validating = false;
  bool _binding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() => _error = 'Codes are 8 characters.');
      return;
    }

    setState(() {
      _error = null;
      _validating = true;
    });

    final store = widget.store;
    final validation = await store.validateReferralCode(code);
    if (!mounted) return;

    if (validation == null || !validation.valid) {
      setState(() {
        _validating = false;
        _error = "That code doesn't exist.";
      });
      return;
    }

    setState(() {
      _validating = false;
      _binding = true;
    });

    try {
      await store.bindReferralCode(code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _binding = false;
        _error = store.actionError ?? "Couldn't link that code. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _validating || _binding;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpace.lg,
          right: AppSpace.lg,
          top: AppSpace.lg,
          bottom: AppSpace.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: BorderRadius.circular(AppRadius.fullValue),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              "Enter a friend's code",
              style: AppTypography.custom(
                size: AppText.titleSize,
                weight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _controller,
              maxLength: 8,
              textCapitalization: TextCapitalization.characters,
              style: AppTypography.custom(
                size: AppText.bodySize,
                weight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '8 characters',
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                _error!,
                style: AppTypography.custom(
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                  color: AppColors.dueAmber,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                ),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Link code',
                        style: AppTypography.custom(
                          size: AppText.labelSize,
                          weight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
