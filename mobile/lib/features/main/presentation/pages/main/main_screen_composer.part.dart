part of '../main_screen.dart';

extension _MainScreenComposerSheet on _MainScreenState {
  Future<void> _openComposerSheet(BuildContext context) async {
    if (!mounted) return;

    final canCreate = context.read<AuthStore>().canCreateUpdate;
    final applicationStatus = context.read<HunterApplicationStore>().status;
    final becomeHunterSubtitle = switch (applicationStatus) {
      HunterApplicationStatus.pending => 'Application pending review',
      HunterApplicationStatus.approved => 'Approved. Hunter tools on the way',
      HunterApplicationStatus.rejected => 'Not approved. You can apply again',
      HunterApplicationStatus.none => 'Hunters post updates and submit gems',
    };

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
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpace.xl),
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(AppRadius.fullValue),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CREATE',
                    style: AppTypography.custom(
                      size: AppText.captionSize,
                      weight: FontWeight.w600,
                      color: AppColors.textFaint,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
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
                  const SizedBox(height: AppSpace.sm),
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
                    subtitle: becomeHunterSubtitle,
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.lgValue),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
              ),
              child: Icon(icon, color: iconColor, size: AppIcon.md),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      size: AppText.bodySize,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      size: AppText.bodySize,
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
              size: AppIcon.xs,
            ),
          ],
        ),
      ),
    );
  }
}
