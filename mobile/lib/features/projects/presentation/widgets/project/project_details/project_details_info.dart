import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/follow_preference_bottom_sheet.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/shared/update_project_logo.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectDetailsInfo extends StatelessWidget {
  const ProjectDetailsInfo({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final postsCount = project.posts?.length ?? 0;
    final ownerName = project.admin?.name ?? 'Admin';
    final ownerLevel = project.admin?.currentLevel;
    final humberCount = (project.posts ?? [])
        .map((post) => post.adminId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -34,
                child: _GlowBubble(color: AppColors.primary500),
              ),
              Positioned(
                bottom: -40,
                left: -30,
                child: _GlowBubble(color: AppColors.secondary500),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary500,
                            AppColors.secondary500
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: UpdateProjectLogo(
                              logoUrl: project.logo, size: 56),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    project.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      PrimaryLabel(primaryTag: project.primaryTag),
                      Text(
                        '•',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 12,
                          fontFamily: 'Geist',
                        ),
                      ),
                      Text(
                        formatDateWithSuffix(project.createdAt),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                            label: 'Followers',
                            value: '${project.followersCount}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _StatCard(label: 'Updates', value: '$postsCount'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _StatCard(label: 'Humbers', value: '$humberCount'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<ProjectsStore>(
                          builder: (context, store, _) {
                            final isFollowed =
                                store.isProjectFollowed(project.id);
                            return GestureDetector(
                              onTap: () =>
                                  store.toggleFollowProject(project.id),
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary500,
                                      AppColors.primary600
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppColors.primary400
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    isFollowed ? 'Following' : 'Follow Project',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontFamily: 'Geist',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer<ProjectsStore>(
                        builder: (context, store, _) {
                          final isFollowed =
                              store.isProjectFollowed(project.id);
                          if (!isFollowed) {
                            return const SizedBox.shrink();
                          }

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionIcon(
                                icon: Icons.notifications_active_outlined,
                                onTap: () => showFollowPreferenceBottomSheet(
                                  context,
                                  projectId: project.id,
                                  projectName: project.name,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          );
                        },
                      ),
                      _ActionIcon(icon: Icons.share_outlined),
                      const SizedBox(width: 8),
                      _ActionIcon(icon: Icons.bookmark_border),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          project.description,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DetailChip(
              label: 'Lead Humber',
              value: ownerName,
              currentLevel: ownerLevel,
            ),
            _DetailChip(
                label: 'Category', value: project.primaryTag.toString()),
            _DetailChip(
              label: 'Created',
              value: formatDateWithSuffix(project.createdAt),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgBase.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.value,
    this.currentLevel,
  });

  final String label;
  final String value;
  final UserLevelModel? currentLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 11,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w400,
            ),
          ),
          if (currentLevel != null)
            UserNameWithLevelIcon(
              name: value,
              currentLevel: currentLevel,
              levelBadgeSize: LevelBadgeSize.tiny,
              iconSpacing: 4,
              textStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.bgBase.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}
