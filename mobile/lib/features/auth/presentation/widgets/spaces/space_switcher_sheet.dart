import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet listing every space the user can switch into.
class SpaceSwitcherSheet extends StatelessWidget {
  const SpaceSwitcherSheet({
    super.key,
    required this.auth,
    required this.availableSpaces,
    required this.currentSpace,
  });

  final AuthStore auth;
  final List<SpaceMeta> availableSpaces;
  final SpaceMeta currentSpace;

  static Future<void> show(BuildContext context, AuthStore auth) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SpaceSwitcherSheet(
        auth: auth,
        availableSpaces: SpaceMeta.availableFor(auth),
        currentSpace: SpaceMeta.currentFor(auth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Switch Space',
                    style: AppTypography.custom(
                      size: 16,
                      weight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final space in availableSpaces)
              _SpaceOptionTile(
                space: space,
                isCurrent: space.id == currentSpace.id,
                onTap: () {
                  Navigator.pop(context);
                  if (space.id == currentSpace.id) return;
                  HapticFeedback.selectionClick();
                  auth.switchSpaceWithTransition(space.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SpaceOptionTile extends StatelessWidget {
  const _SpaceOptionTile({
    required this.space,
    required this.isCurrent,
    required this.onTap,
  });

  final SpaceMeta space;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: space.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(space.icon, size: 22, color: space.accent),
      ),
      title: Text(
        space.label,
        style: AppTypography.custom(
          size: 15,
          weight: isCurrent ? FontWeight.w600 : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        space.description,
        style: AppTypography.custom(
          size: 13,
          weight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isCurrent
          ? Icon(Icons.check_circle_rounded, color: space.accent, size: 22)
          : null,
      onTap: onTap,
    );
  }
}
