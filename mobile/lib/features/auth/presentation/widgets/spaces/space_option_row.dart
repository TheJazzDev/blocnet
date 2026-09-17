import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:flutter/material.dart';

/// One space in the switcher sheet: a tinted icon square, the space name in
/// bold, a muted one-line purpose, and a tick on the current space.
class SpaceOptionRow extends StatelessWidget {
  const SpaceOptionRow({
    super.key,
    required this.space,
    required this.isCurrent,
    required this.onTap,
  });

  final SpaceMeta space;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isCurrent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xl,
              vertical: AppSpace.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: space.accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.md,
                  ),
                  child: Icon(space.icon, size: AppIcon.lg, color: space.accent),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        space.label,
                        style: AppText.body(
                          AppColors.textPrimary,
                          weight: AppText.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpace.hair),
                      Text(
                        space.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          AppColors.textSecondary,
                          weight: AppText.regular,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: AppSpace.md),
                  Icon(
                    Icons.check_circle_rounded,
                    size: AppIcon.lg,
                    color: space.accent,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
