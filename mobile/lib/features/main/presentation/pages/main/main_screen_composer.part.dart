part of '../main_screen.dart';

extension _MainScreenComposerSheet on _MainScreenState {
  Future<void> _openComposerSheet(BuildContext context) async {
    if (!mounted) return;

    final canCreate = context.read<AuthStore>().canCreateUpdate;
    final applicationPending =
        context.read<HunterApplicationStore>().isPending;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CREATE',
                    style: AppTypography.custom(
                      size: 10,
                      weight: FontWeight.w600,
                      color: AppColors.textFaint,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (canCreate) ...[
                  _ComposerTile(
                    title: 'Post Hunter Update',
                    subtitle: 'Share intel about a gem you track',
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.teal400,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed(AppRoutes.createUpdate);
                    },
                  ),
                  const SizedBox(height: 8),
                  _ComposerTile(
                    title: 'Submit New Gem',
                    subtitle: 'Propose a gem to be listed on Blocnet',
                    icon: Icons.diamond_outlined,
                    iconColor: AppColors.primary400,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed(AppRoutes.submitProject);
                    },
                  ),
                ] else
                  _ComposerTile(
                    title: 'Become a Hunter',
                    subtitle: applicationPending
                        ? 'Application pending review'
                        : 'Hunters post updates and submit gems',
                    icon: Icons.radar_rounded,
                    iconColor: AppColors.primary400,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed(AppRoutes.becomeHunter);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ComposerTile extends StatelessWidget {
  const _ComposerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textFaint,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}
