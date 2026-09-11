import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_switcher_sheet.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Compact app-bar chip naming the current space (icon + "User" /
/// "Hunter" / "Moderation"). Tapping it opens [SpaceSwitcherSheet].
///
/// Only renders when the user has more than one available space.
class SpaceSwitcher extends StatelessWidget {
  const SpaceSwitcher({
    super.key,
    this.minimal = true,
  });

  /// Kept for call-site compatibility; the chip has one visual style.
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    final availableSpaces = SpaceMeta.availableFor(auth);
    if (availableSpaces.length <= 1) return const SizedBox.shrink();

    final current = SpaceMeta.currentFor(auth);
    final accent = current.accent;
    final switching = auth.isSwitchingSpace;

    return Tooltip(
      message: switching
          ? 'Switching space...'
          : 'Switch space (currently ${current.label})',
      child: Semantics(
        button: true,
        label: switching
            ? 'Switching space'
            : 'Switch space, currently in ${current.label}',
        child: GestureDetector(
          onTap: () {
            if (switching) return;
            HapticFeedback.selectionClick();
            SpaceSwitcherSheet.show(context, auth);
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 30,
            padding: const EdgeInsets.only(left: AppSpace.sm, right: AppSpace.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.fullValue),
              border: Border.all(
                color: accent.withValues(alpha: 0.38),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (switching)
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  )
                else
                  Icon(current.icon, size: AppIcon.sm, color: accent),
                const SizedBox(width: AppSpace.xs),
                Text(
                  current.label,
                  style: AppTypography.custom(
                    size: AppText.captionSize,
                    weight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: AppSpace.hair),
                Icon(
                  Icons.expand_more_rounded,
                  size: AppIcon.sm,
                  color: accent.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
