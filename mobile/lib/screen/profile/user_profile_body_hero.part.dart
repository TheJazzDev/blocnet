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
        // Background glow effect
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [
                  AppColors.primary500.withValues(alpha: 0.12),
                  AppColors.teal500.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Main content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          child: Column(
            children: [
              Stack(
                children: [
                  // Outer glow ring
                  Container(
                    width: 100,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.teal400.withValues(alpha: 0.4),
                          AppColors.primary500.withValues(alpha: 0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal400.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.teal400, AppColors.primary500],
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgBase,
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: CircleAvatar(
                        radius: 45,
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
                                  size: 32,
                                  weight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Edit button with gradient
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary400,
                            AppColors.primary500,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgBase, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 22,
                      weight: FontWeight.w800,
                    ),
                  ),
                  if (primaryBadge != null) ...[
                    const SizedBox(width: 8),
                    BadgeIcon(
                      badge: primaryBadge!,
                      size: BadgeSize.medium,
                      showTooltip: false,
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.badges),
                    ),
                  ],
                ],
              ),
              if (email?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 6),
                Text(
                  email!.trim(),
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
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
        padding: const EdgeInsets.all(16),
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
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 10,
                weight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.15),
                    AppColors.primary500.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                value,
                style: AppTypography.custom(
                  color: AppColors.primary400,
                  size: 24,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
