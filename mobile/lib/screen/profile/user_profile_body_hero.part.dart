part of 'user_profile_body.dart';

class _UserHero extends StatelessWidget {
  const _UserHero({
    required this.displayName,
    required this.avatarUrl,
    required this.email,
    this.primaryBadge,
  });

  final String displayName;
  final String? avatarUrl;
  final String? email;
  final BadgeModel? primaryBadge;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                      child: CircleAvatar(
                        radius: 31,
                        backgroundColor: AppColors.bgElevated,
                        backgroundImage:
                            avatarUrl != null && avatarUrl!.isNotEmpty
                                ? NetworkImage(avatarUrl!)
                                : null,
                        child: avatarUrl == null || avatarUrl!.isEmpty
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: AppTypography.custom(
                                  color: AppColors.teal400,
                                  size: 22,
                                  weight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary400,
                            AppColors.primary500,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgBase, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 10,
                        color: Colors.black,
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
                        if (primaryBadge != null) ...[
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary500.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary500.withValues(alpha: 0.05),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 8.5,
                weight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 16,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
