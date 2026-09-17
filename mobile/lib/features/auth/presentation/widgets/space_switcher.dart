import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_switcher_sheet.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Compact app-bar chip naming the current space (icon + "User" /
/// "Hunter" / "Moderation"). Tapping it opens [SpaceSwitcherSheet].
///
/// Drawn as the old app's outlined pill: a faint tint of the space colour,
/// a coloured hairline and coloured text. Only renders when the user has
/// more than one available space.
class SpaceSwitcher extends StatelessWidget {
  const SpaceSwitcher({
    super.key,
    this.minimal = true,
  });

  /// Kept for call-site compatibility; the chip has one visual style.
  final bool minimal;

  /// The pill's own height. The tap area around it is 44px tall.
  static const double chipHeight = 32;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    final availableSpaces = SpaceMeta.availableFor(auth);
    if (availableSpaces.length <= 1) return const SizedBox.shrink();

    final current = SpaceMeta.currentFor(auth);
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
          child: ConstrainedBox(
            // Touch target minimum without growing the pill itself.
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              widthFactor: 1,
              child: _SpaceChip(space: current, switching: switching),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpaceChip extends StatelessWidget {
  const _SpaceChip({required this.space, required this.switching});

  final SpaceMeta space;
  final bool switching;

  @override
  Widget build(BuildContext context) {
    final accent = space.accent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: SpaceSwitcher.chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (switching)
            SizedBox(
              width: AppIcon.xs,
              height: AppIcon.xs,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          else
            Icon(space.icon, size: AppIcon.sm, color: accent),
          const SizedBox(width: 6),
          Text(space.label, style: AppText.label(accent, weight: AppText.bold)),
          const SizedBox(width: AppSpace.hair),
          Icon(Icons.expand_more_rounded, size: AppIcon.sm, color: accent),
        ],
      ),
    );
  }
}
