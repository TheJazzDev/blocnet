import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_details/project_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GemCard extends StatelessWidget {
  const GemCard({
    super.key,
    required this.project,
    required this.isFollowed,
    required this.onFollowToggle,
    required this.isLoading,
  });

  final Project project;
  final bool isFollowed;
  final VoidCallback onFollowToggle;
  final bool isLoading;

  void _openDetails(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProjectDetailsDialog(projectId: project.id);
      },
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  /// Derives a hype score 0–10 from followers + update count.
  double _hypoScore() {
    final followers = project.followersCount;
    final updates = project.posts?.length ?? 0;
    // Score formula: clamp to 10
    final raw = (followers * 0.05 + updates * 0.3).clamp(0.0, 10.0);
    return double.parse(raw.toStringAsFixed(1));
  }

  Color _scoreColor(double score) {
    if (score >= 7) return AppColors.hypeHigh;
    if (score >= 4) return AppColors.hypeMid;
    return AppColors.hypeLow;
  }

  @override
  Widget build(BuildContext context) {
    final score = _hypoScore();
    final scoreColor = _scoreColor(score);
    final admin = project.admin;

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: logo + name + hype score ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary500.withValues(alpha: 0.2),
                      ),
                    ),
                    child: project.logo.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.network(
                              project.logo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.layers_outlined,
                                size: 20,
                                color: AppColors.primary400,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.layers_outlined,
                            size: 20,
                            color: AppColors.primary400,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Name + tag
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              project.primaryTag.name,
                              style: GoogleFonts.inter(
                                color: AppColors.textFaint,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal400.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      AppColors.teal400.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'GEM',
                                style: GoogleFonts.inter(
                                  color: AppColors.teal400,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Hype Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'HYPE SCORE',
                        style: GoogleFonts.inter(
                          color: AppColors.textFaint,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 6,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: Stack(
                                children: [
                                  Container(color: AppColors.bgElevated),
                                  FractionallySizedBox(
                                    widthFactor: (score / 10).clamp(0.0, 1.0),
                                    child: Container(color: scoreColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            score.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              color: scoreColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Hunted by row ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: AppColors.borderMuted.withValues(alpha: 0.95),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.bgSurface,
                      backgroundImage: (admin?.imageUrl.isNotEmpty ?? false)
                          ? NetworkImage(admin!.imageUrl)
                          : null,
                      child: (admin == null || admin.imageUrl.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 11,
                              color: AppColors.textFaint,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Hunted by ',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: admin?.name ?? 'Unknown',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Action row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: isLoading ? null : onFollowToggle,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: isLoading ? 0.6 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isFollowed
                              ? AppColors.primary500.withValues(alpha: 0.14)
                              : AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isFollowed
                                ? AppColors.primary500.withValues(alpha: 0.45)
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFollowed
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 14,
                              color: isFollowed
                                  ? AppColors.primary400
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isFollowed ? 'Following' : 'Follow',
                              style: GoogleFonts.inter(
                                color: isFollowed
                                    ? AppColors.primary400
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
