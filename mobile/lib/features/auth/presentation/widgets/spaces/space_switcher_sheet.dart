import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_option_row.dart';
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
      isScrollControlled: true,
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
        borderRadius: AppRadius.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                AppSpace.sm,
                AppSpace.xl,
                AppSpace.lg,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: AppIcon.md,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Text(
                    'Switch Space',
                    style: AppText.subtitle(AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
            const SizedBox(height: AppSpace.sm),
            for (final space in availableSpaces)
              SpaceOptionRow(
                space: space,
                isCurrent: space.id == currentSpace.id,
                onTap: () {
                  Navigator.pop(context);
                  if (space.id == currentSpace.id) return;
                  HapticFeedback.selectionClick();
                  auth.switchSpaceWithTransition(space.id);
                },
              ),
            const SizedBox(height: AppSpace.md),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderMuted,
          borderRadius: AppRadius.full,
        ),
      ),
    );
  }
}
