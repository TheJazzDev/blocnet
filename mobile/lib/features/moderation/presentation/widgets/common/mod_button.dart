import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:flutter/material.dart';

/// `filled` moderation red · `outline` dark neutral · `tinted` outlined in
/// [ModButton.color] (green Resolve, red Uphold).
enum ModButtonTone { filled, outline, tinted }

/// The moderation space's 40px button, drawn like the Hub's: filled accent
/// or a dark outlined one, [AppRadius.md] corners.
class ModButton extends StatelessWidget {
  const ModButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.tone = ModButtonTone.outline,
    this.color,
    this.busy = false,
  });

  final String label;

  /// Null (and not [busy]) reads as disabled.
  final VoidCallback? onTap;
  final IconData? icon;
  final ModButtonTone tone;

  /// The tint for [ModButtonTone.tinted].
  final Color? color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? ModTone.accent;
    final (Color fg, Color fill, Color? outline) = switch (tone) {
      ModButtonTone.filled => (ModTone.onAccent, ModTone.accent, null),
      ModButtonTone.outline => (
          AppColors.textPrimary,
          AppColors.bgElevated,
          AppColors.borderMuted,
        ),
      ModButtonTone.tinted => (
          tint,
          tint.withValues(alpha: 0.1),
          tint.withValues(alpha: 0.45),
        ),
    };
    final disabled = onTap == null && !busy;
    return Semantics(
      button: true,
      enabled: !disabled,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Material(
          color: fill,
          borderRadius: AppRadius.md,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: busy ? null : onTap,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              decoration: outline == null
                  ? null
                  : BoxDecoration(
                      borderRadius: AppRadius.md,
                      border: Border.all(color: outline),
                    ),
              child: busy ? _spinner(fg) : _label(fg),
            ),
          ),
        ),
      ),
    );
  }

  Widget _spinner(Color color) => SizedBox(
        width: AppIcon.sm,
        height: AppIcon.sm,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );

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
