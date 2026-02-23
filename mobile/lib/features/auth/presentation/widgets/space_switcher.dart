import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

/// A pill toggle shown in the app bar for users who have the hunter role.
/// Allows switching between "User" and "Hunter" spaces.
///
/// Only renders when [AuthStore.hasHunterSpace] is true.
class SpaceSwitcher extends StatelessWidget {
  const SpaceSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (!auth.hasHunterSpace) return const SizedBox.shrink();

    final isHunterActive = auth.isInHunterSpace;

    return GestureDetector(
      onTap: () {
        if (auth.isSwitchingSpace) return;
        HapticFeedback.selectionClick();
        auth.toggleSpace();
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderMuted, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SpacePill(
              label: 'User',
              isActive: !isHunterActive,
              icon: Icons.person_outline_rounded,
            ),
            _SpacePill(
              label: 'Hunter',
              isActive: isHunterActive,
              icon: Icons.radar_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpacePill extends StatelessWidget {
  const _SpacePill({
    required this.label,
    required this.isActive,
    required this.icon,
  });

  final String label;
  final bool isActive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary500.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(
                color: AppColors.primary500.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isActive ? AppColors.primary400 : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.custom(
              color: isActive ? AppColors.primary400 : AppColors.textMuted,
              size: 11,
              weight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
