import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/follow_preference_bottom_sheet.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_card/gem_card.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class DiscoverProjectsSection extends StatefulWidget {
  const DiscoverProjectsSection({
    required this.viewMode,
    super.key,
  });

  final FeedViewMode viewMode;

  @override
  State<DiscoverProjectsSection> createState() =>
      _DiscoverProjectsSectionState();
}

class _DiscoverProjectsSectionState extends State<DiscoverProjectsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ProjectsStore>(context, listen: false).fetchProjectsOnce();
      Provider.of<UpdatesStore>(context, listen: false).fetchUpdatesOnce();
    });
  }

  Future<void> _toggleFollow(Project project) async {
    await Provider.of<ProjectsStore>(
      context,
      listen: false,
    ).toggleFollowProject(project.id);
  }

  Future<void> _openPreferences(Project project) async {
    await showFollowPreferenceBottomSheet(
      context,
      projectId: project.id,
      projectName: project.name,
    );
  }

  List<Widget> _buildProjectRows({
    required List<Project> visibleProjects,
    required ProjectsStore store,
    required Set<String> manageableIds,
    required Map<String, int> updateCountByProject,
  }) {
    final rows = <Widget>[];
    for (var index = 0; index < visibleProjects.length; index++) {
      final project = visibleProjects[index];
      final isFollowed = store.isProjectFollowed(project.id);
      final hypeScore = store.hypeScoreForProject(
        project,
        updatesCountOverride: updateCountByProject[project.id],
      );
      rows.add(
        GemCard(
          project: project,
          hypeScore: hypeScore,
          isFollowed: isFollowed,
          isLoading: store.isTogglingFollow,
          layout: widget.viewMode == FeedViewMode.card
              ? GemCardLayout.card
              : GemCardLayout.list,
          onFollowToggle: () => _toggleFollow(project),
          onPreferencesTap: isFollowed ? () => _openPreferences(project) : null,
          onManageTap: manageableIds.contains(project.id)
              ? () => Navigator.of(context).pushNamed(AppRoutes.manageProjects)
              : null,
        ),
      );
      if (widget.viewMode == FeedViewMode.list &&
          index < visibleProjects.length - 1) {
        rows.add(
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
        );
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProjectsStore, UpdatesStore, AuthStore>(
      builder: (context, store, updatesStore, authStore, _) {
        final manageableIds = authStore.canSubmitProject
            ? store.manageableProjectIds(
                userId: authStore.userId ?? '',
                updates: updatesStore.updates,
              )
            : const <String>{};
        final updateCountByProject = <String, int>{};
        for (final update in updatesStore.updates) {
          updateCountByProject.update(
            update.projectId,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
        final visibleProjects = store.discoverProjects(
          updates: updatesStore.updates,
        );

        if (store.isFetching && store.projects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (store.projects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              children: [
                Icon(
                  Icons.diamond_outlined,
                  size: AppIcon.xxl,
                  color: AppColors.textFaint,
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  'No gems found',
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: AppText.bodySize,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Gems will appear here once they are listed.',
                  textAlign: TextAlign.center,
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.bodySize,
                    weight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        if (visibleProjects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              children: [
                Icon(
                  Icons.filter_alt_off_outlined,
                  size: AppIcon.xl,
                  color: AppColors.textFaint,
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  'No gems match this filter',
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: AppText.bodySize,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Adjust your filters to see more gems.',
                  textAlign: TextAlign.center,
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.bodySize,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(0, AppSpace.lg, 0, AppSpace.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURATED FEED',
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: AppText.captionSize,
                      weight: FontWeight.w600,
                      letterSpacing: 0.9,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm, vertical: AppSpace.xs),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(AppRadius.smValue),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Sort: Hype Score',
                      style: AppTypography.custom(
                        color: AppColors.textFaint,
                        size: AppText.captionSize,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: _buildProjectRows(
                visibleProjects: visibleProjects,
                store: store,
                manageableIds: manageableIds,
                updateCountByProject: updateCountByProject,
              ),
            ),
          ],
        );
      },
    );
  }
}
