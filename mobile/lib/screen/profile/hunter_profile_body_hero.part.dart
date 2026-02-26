part of 'hunter_profile_body.dart';

class _HunterHero extends StatelessWidget {
  const _HunterHero({
    required this.displayName,
    required this.avatarUrl,
    required this.email,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.onEditTap,
  });

  final String displayName;
  final String? avatarUrl;
  final String? email;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl?.trim().isNotEmpty == true;
    final normalizedBio = (bio?.trim().isNotEmpty ?? false)
        ? bio!.trim()
        : 'Building trusted alpha for the Blocnet community';

    Widget fallbackAvatarText() {
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
                  AppColors.primary500.withValues(alpha: 0.14),
                  AppColors.teal500.withValues(alpha: 0.08),
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
                        colors: [
                          AppColors.teal400,
                          AppColors.primary500,
                        ],
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
                                      Center(child: fallbackAvatarText()),
                                )
                              : Center(child: fallbackAvatarText()),
                        ),
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
                        Icons.verified_rounded,
                        size: 12,
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
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color:
                                  AppColors.primary500.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Hunter Space',
                            style: AppTypography.custom(
                              color: AppColors.primary300,
                              size: 9,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                    const SizedBox(height: 4),
                    Text(
                      normalizedBio,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InlineStat(
                          value: _formatCompact(followersCount),
                          label: 'Followers',
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.borderSubtle,
                        ),
                        const SizedBox(width: 14),
                        _InlineStat(
                          value: followingCount.toString(),
                          label: 'Following',
                        ),
                      ],
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
      ],
    );
  }
}

String _formatCompact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 13,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 10,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HunterStatCard extends StatelessWidget {
  const _HunterStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.footnote,
    this.valueSize = 17,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String footnote;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.06),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1.1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 9,
                      weight: FontWeight.w700,
                      letterSpacing: 0.55,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.custom(
                      color: iconColor,
                      size: valueSize,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    footnote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 9,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
