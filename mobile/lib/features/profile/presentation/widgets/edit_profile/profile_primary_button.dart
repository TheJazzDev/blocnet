import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Filled accent button, 44px tall, with a busy state.
class ProfilePrimaryButton extends StatelessWidget {
  const ProfilePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.foreground,
    this.busy = false,
    this.background,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color foreground;
  final bool busy;

  /// Defaults to the space accent.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? AppColors.primary500;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: foreground,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
        child: busy
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  color: foreground,
                  strokeWidth: 2,
                ),
              )
            : Text(label,
                style: AppText.label(foreground, weight: AppText.bold)),
      ),
    );
  }
}
