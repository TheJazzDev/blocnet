import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_tone.dart';
import 'package:flutter/material.dart';

/// Follow, filled in the accent; once followed, an outlined `Following`
/// with a bell for the notification preferences.
class GemFollowButton extends StatelessWidget {
  const GemFollowButton({
    super.key,
    required this.isFollowed,
    required this.onToggle,
    this.onPreferences,
  });

  final bool isFollowed;
  final VoidCallback onToggle;

  /// Shown only while followed.
  final VoidCallback? onPreferences;

  @override
  Widget build(BuildContext context) {
    final label = isFollowed ? 'Following' : 'Follow';
    final fg = isFollowed ? AppColors.textSecondary : GemsTone.onAccent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFollowed && onPreferences != null) ...[
          _Bell(onTap: onPreferences!),
          AppSpace.wGapXs,
        ],
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('gem-follow'),
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 34,
              constraints: const BoxConstraints(minWidth: 76),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              decoration: BoxDecoration(
                color: isFollowed ? AppColors.bgBase : GemsTone.accent,
                borderRadius: AppRadius.md,
                border: isFollowed
                    ? Border.all(color: AppColors.borderMuted)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFollowed ? Icons.check_rounded : Icons.add_rounded,
                    size: AppIcon.sm,
                    color: fg,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(label, style: AppText.label(fg, weight: AppText.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notification settings',
      child: GestureDetector(
        key: const ValueKey('gem-follow-prefs'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.borderMuted),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: AppIcon.sm,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
