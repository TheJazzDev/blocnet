import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// An icon-only toggle shown in the app bar for users who have hunter access.
/// Allows switching between User and Hunter spaces.
///
/// Only renders when [AuthStore.hasHunterSpace] is true.
class SpaceSwitcher extends StatelessWidget {
  const SpaceSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (!auth.hasHunterSpace) return const SizedBox.shrink();

    final isHunterActive = auth.isInHunterSpace;
    final icon = isHunterActive ? Icons.radar_rounded : Icons.public_rounded;
    final accent = AppColors.accentForSpace(isHunterActive);
    final targetLabel = isHunterActive ? 'User' : 'Hunter';

    return Tooltip(
      message: auth.isSwitchingSpace
          ? 'Switching space...'
          : 'Switch to $targetLabel space',
      child: Semantics(
        button: true,
        label: auth.isSwitchingSpace
            ? 'Switching space'
            : 'Switch to $targetLabel space',
        child: GestureDetector(
          onTap: () {
            if (auth.isSwitchingSpace) return;
            HapticFeedback.selectionClick();
            auth.toggleSpace();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.38),
                width: 1,
              ),
            ),
            child: Center(
              child: auth.isSwitchingSpace
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 18,
                      color: accent,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
