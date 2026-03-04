part of 'user_profile_body.dart';

class _UserHero extends StatelessWidget {
  const _UserHero({
    required this.displayName,
    required this.avatarUrl,
    required this.email,
    required this.onEditTap,
    this.badges = const [],
    this.primaryBadge,
    this.currentLevel,
  });

  final String displayName;
  final String? avatarUrl;
  final String? email;
  final VoidCallback onEditTap;
  final List<BadgeModel> badges;
  final BadgeModel? primaryBadge;
  final UserLevelModel? currentLevel;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl?.trim().isNotEmpty == true;

    Widget fallbackAvatar() {
      return Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: AppTypography.custom(
          color: AppColors.teal400,
          size: 22,
          weight: FontWeight.w800,
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  AppColors.primary500.withValues(alpha: 0.12),
                  AppColors.teal500.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.teal400, AppColors.primary500],
                      ),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgBase,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Container(
                          color: AppColors.bgElevated,
                          child: hasAvatar
                              ? Image.network(
                                  avatarUrl!.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Center(child: fallbackAvatar()),
                                )
                              : Center(child: fallbackAvatar()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppTypography.custom(
                              color: AppColors.textPrimary,
                              size: 18,
                              weight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (primaryBadge != null && badges.isEmpty) ...[
                          const SizedBox(width: 6),
                          BadgeIcon(
                            badge: primaryBadge!,
                            size: BadgeSize.medium,
                            showTooltip: false,
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.badges),
                          ),
                        ],
                      ],
                    ),
                    if (email?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        email!.trim(),
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 10,
                          weight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: badges
                            .map(
                              (badge) => BadgeIcon(
                                badge: badge,
                                size: BadgeSize.small,
                                showTooltip: false,
                                onTap: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.badges),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        'User Space',
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: 9,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          bottom: 0,
          child: GestureDetector(
            onTap: onEditTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 17,
                color: AppColors.primary400,
              ),
            ),
          ),
        ),
        if (currentLevel != null)
          Positioned(
            right: 16,
            top: 14,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.levels),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LevelBadgeIcon(
                      level: currentLevel!,
                      size: LevelBadgeSize.small,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        currentLevel!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: 11,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 15,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 8.5,
                weight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
