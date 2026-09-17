part of '../main_screen.dart';

extension _MainScreenComposerSheet on _MainScreenState {
  Future<void> _openComposerSheet(BuildContext context) async {
    if (!mounted) return;

    final canCreate = context.read<AuthStore>().canCreateUpdate;
    final applicationStatus = context.read<HunterApplicationStore>().status;
    final becomeHunterSubtitle = switch (applicationStatus) {
      HunterApplicationStatus.pending => 'Application in review',
      HunterApplicationStatus.approved => 'Approved. Hunter tools on the way',
      HunterApplicationStatus.rejected => 'Not approved. You can apply again',
      HunterApplicationStatus.none => 'Hunters post updates and submit gems',
    };

    void open(BuildContext sheetContext, String route) {
      Navigator.of(sheetContext).pop();
      Navigator.of(context).pushNamed(route);
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) {
        final rows = <Widget>[
          if (canCreate) ...[
            _ComposerRow(
              title: 'Post Hunter Update',
              subtitle: 'Share news on a gem you track',
              icon: Icons.bolt_rounded,
              onTap: () => open(ctx, AppRoutes.createUpdate),
            ),
            _ComposerRow(
              title: 'Submit New Gem',
              subtitle: 'Propose a gem for Blocnet',
              icon: Icons.diamond_outlined,
              onTap: () => open(ctx, AppRoutes.submitProject),
            ),
          ] else
            _ComposerRow(
              title: 'Become a Hunter',
              subtitle: becomeHunterSubtitle,
              icon: Icons.radar_rounded,
              onTap: () => open(ctx, AppRoutes.becomeHunter),
            ),
        ];

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpace.lg),
                    decoration: BoxDecoration(
                      color: AppColors.borderMuted,
                      borderRadius: AppRadius.full,
                    ),
                  ),
                ),
                Text(
                  'CREATE',
                  style: AppText.caption(
                    AppColors.textFaint,
                    weight: AppText.bold,
                  ).copyWith(letterSpacing: 1.0),
                ),
                const SizedBox(height: AppSpace.md),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderSubtle,
                          ),
                        rows[i],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A list row: accent icon in a tinted square, bold title, muted
/// subtitle, chevron.
class _ComposerRow extends StatelessWidget {
  const _ComposerRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpace.card,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.md,
                ),
                child: Icon(icon, color: accent, size: AppIcon.md),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.body(
                        AppColors.textPrimary,
                        weight: AppText.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpace.hair),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        AppColors.textMuted,
                        weight: AppText.regular,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textFaint,
                size: AppIcon.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
