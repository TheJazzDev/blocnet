import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// `filled` cyan · `outline` zinc (`.btn.w`) · `warn` orange outline
/// (`.btn.o`, used by *Hand over*).
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

  /// `#fb923c4d` — the warn tone's 1px outline.
  static const Color warnOutline = Color(0x4DFB923C);

  @override
  Widget build(BuildContext context) {
    final filled = tone == HubButtonTone.filled;
    final (foreground, outline) = switch (tone) {
      HubButtonTone.filled => (Colors.white, null),
      HubButtonTone.outline => (AppColors.zincStrong, AppColors.borderSubtle),
      HubButtonTone.warn => (AppColors.quietOrange, warnOutline),
    };
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: small ? 34 : 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: filled ? AppColors.hunterFill : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: outline == null ? null : Border.all(color: outline),
          ),
          child: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: foreground),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            HubType.meta(foreground, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
