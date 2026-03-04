part of 'user_profile_body.dart';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.custom(
        color: AppColors.textFaint,
        size: 10,
        weight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.iconColor,
    this.titleColor,
  });

  final FeedViewMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isCardMode = mode == FeedViewMode.card;
    final tile = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: isCardMode ? 8 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: isCardMode
            ? BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              )
            : null,
        child: Row(
          children: [
            if (isCardMode)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: iconColor ?? AppColors.textMuted,
                ),
              )
            else
              Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.textMuted,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: titleColor ?? AppColors.textPrimary,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 11,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
          ],
        ),
      ),
    );

    if (isCardMode) {
      return tile;
    }

    return Column(
      children: [
        tile,
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
      ],
    );
  }
}
