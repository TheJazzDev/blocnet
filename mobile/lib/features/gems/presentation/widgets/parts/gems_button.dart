import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_tone.dart';
import 'package:flutter/material.dart';

/// Filled in the space accent, or dark outlined. 44px, or 34px when
/// [small].
class GemsButton extends StatelessWidget {
  const GemsButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.small = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool filled;
  final bool small;

  /// Take the full width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? GemsTone.onAccent : AppColors.textPrimary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: small ? 34 : 44,
          width: expand ? double.infinity : null,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: small ? AppSpace.md : AppSpace.lg,
          ),
          decoration: BoxDecoration(
            color: filled ? GemsTone.accent : AppColors.bgElevated,
            borderRadius: AppRadius.md,
            border: filled ? null : Border.all(color: AppColors.borderMuted),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIcon.sm, color: foreground),
                AppSpace.wGapXs,
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(foreground, weight: AppText.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
