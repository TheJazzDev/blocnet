part of 'hunter_profile_body.dart';

class _HunterSectionLabel extends StatelessWidget {
  const _HunterSectionLabel(this.label);

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

class _HunterTile extends StatelessWidget {
  const _HunterTile({
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

class _HunterTrustChips extends StatelessWidget {
  const _HunterTrustChips({
    required this.updatesLast7d,
    required this.updatesLast30d,
    required this.highUrgencyShare30d,
    required this.medianHoursBetweenUpdates,
    required this.lastActiveAt,
  });

  final int updatesLast7d;
  final int updatesLast30d;
  final double highUrgencyShare30d;
  final double? medianHoursBetweenUpdates;
  final DateTime? lastActiveAt;

  @override
  Widget build(BuildContext context) {
    final lastActiveLabel = lastActiveAt == null
        ? 'N/A'
        : '${DateTime.now().difference(lastActiveAt!).inHours}h ago';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TrustChip(label: '7D', value: '$updatesLast7d'),
        _TrustChip(label: '30D', value: '$updatesLast30d'),
        _TrustChip(
          label: 'High%',
          value: '${highUrgencyShare30d.toStringAsFixed(0)}%',
        ),
        _TrustChip(
          label: 'Median',
          value: medianHoursBetweenUpdates == null
              ? 'N/A'
              : '${medianHoursBetweenUpdates!.toStringAsFixed(1)}h',
        ),
        _TrustChip(label: 'Last', value: lastActiveLabel),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: 10,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}
