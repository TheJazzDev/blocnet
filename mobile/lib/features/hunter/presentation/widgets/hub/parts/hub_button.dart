import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

enum HubButtonTone { filled, outline }

/// The Hub's 40px (or 34px small) button: filled cyan, or a zinc outline.
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
    final filled = tone == HubButtonTone.filled;
    final foreground = filled ? Colors.white : AppColors.zincStrong;
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
            border: filled ? null : Border.all(color: AppColors.borderSubtle),
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
