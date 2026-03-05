import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/cards/stat_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/filter_label/filter_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_card/your_project_card.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class YourProjectsSection extends StatefulWidget {
  const YourProjectsSection({
    required this.viewMode,
    super.key,
  });

  final FeedViewMode viewMode;

  @override
  State<YourProjectsSection> createState() => _YourProjectsSectionState();
}

class _YourProjectsSectionState extends State<YourProjectsSection> {
  final Set<String> _selectedFilters = <String>{};

  List<Widget> _buildProjectRows(List<Project> projects) {
    final rows = <Widget>[];
    for (var index = 0; index < projects.length; index++) {
      rows.add(
        YourProjectCard(
          project: projects[index],
          layout: widget.viewMode == FeedViewMode.card
              ? YourProjectCardLayout.card
              : YourProjectCardLayout.list,
        ),
      );

      if (widget.viewMode == FeedViewMode.list && index < projects.length - 1) {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = context.read<ProjectsStore>();
      await store.fetchProjectsOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectsStore, UpdatesStore>(
      builder: (context, projectsStore, postsStore, _) {
        final authStore = context.watch<AuthStore>();
        if (projectsStore.isFetching && projectsStore.projects.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.teal400,
              strokeWidth: 2,
            ),
          );
        }

        if (projectsStore.projects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'No projects available yet.',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 13,
                fontFamily: 'Geist',
              ),
            ),
          );
        }

        final allProjects = projectsStore.followedAndManagedProjects(
          userId: authStore.userId ?? '',
          updates: postsStore.updates,
        );
        if (allProjects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'No followed or managed gems yet.',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 13,
                fontFamily: 'Geist',
              ),
            ),
          );
        }

        final allPrimaryTags =
            allProjects.map((project) => project.primaryTag.toString()).toSet();
        final filteredProjects = _selectedFilters.isEmpty
            ? allProjects
            : allProjects.where((project) {
                return _selectedFilters.contains(project.primaryTag.toString());
              }).toList();

        final projectsForStats = allProjects;
        final statsProjectIds =
            projectsForStats.map((project) => project.id).toSet();
        final postsForStats = postsStore.posts.where((post) {
          return statsProjectIds.contains(post.projectId);
        });

        final followedCount = projectsForStats.length;
        final postCount = postsForStats.length;
        final highUrgencyCount = postsForStats
            .where((post) => post.priority == Priority.high)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: StatCard(
                    label: 'My Gems',
                    value: followedCount,
                    iconName: 'style',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: StatCard(
                    label: 'New Updates',
                    value: postCount,
                    iconName: 'post',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: StatCard(
                    label: 'High Urgency Updates',
                    value: highUrgencyCount,
                    iconName: 'emergency',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FilterLabel(
              selectedTags: _selectedFilters,
              unselectedTags: allPrimaryTags,
              onTagToggle: (tag) {
                setState(() {
                  if (tag == 'All') {
                    _selectedFilters.clear();
                    return;
                  }

                  if (_selectedFilters.contains(tag)) {
                    _selectedFilters.remove(tag);
                  } else {
                    _selectedFilters.add(tag);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Column(
              children: _buildProjectRows(filteredProjects),
            ),
          ],
        );
      },
    );
  }
}
