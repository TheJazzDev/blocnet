import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// `filled` accent · `outline` neutral · `warn` orange outline (used by
/// *Hand over*).
enum HubButtonTone { filled, outline, warn }

/// The Hub's 40px (or 34px small) button.
class HubButton extends StatelessWidget {
  const HubButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.tone = HubButtonTone.filled,
    this.small = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final HubButtonTone tone;
  final bool small;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final (foreground, fill, outline) = switch (tone) {
      HubButtonTone.filled => (HubTone.onAccent, HubTone.accent, null),
      HubButtonTone.outline => (
          AppColors.textPrimary,
          AppColors.bgElevated,
          AppColors.borderMuted,
        ),
      HubButtonTone.warn => (
          HubTone.quiet,
          HubTone.quiet.withValues(alpha: 0.08),
          HubTone.quiet.withValues(alpha: 0.45),
        ),
    };
    // A null onTap (and not busy) reads as disabled.
    final disabled = onTap == null && !busy;
    return Semantics(
      button: true,
      enabled: !disabled,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: disabled ? 0.45 : 1,
          child: Container(
            height: small ? 34 : 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: AppRadius.md,
              border: outline == null ? null : Border.all(color: outline),
            ),
            child: busy ? _spinner(foreground) : _label(foreground),
          ),
        ),
      ),
    );
  }

  Widget _spinner(Color color) {
    return SizedBox(
      width: AppIcon.xs + 2,
      height: AppIcon.xs + 2,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  Widget _label(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppIcon.sm, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(color, weight: AppText.bold),
          ),
        ),
      ],
    );
  }
}
