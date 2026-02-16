import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/cards/stat_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/filter_label/filter_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_card/your_project_card.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class YourProjectsSection extends StatefulWidget {
  const YourProjectsSection({super.key});

  @override
  State<YourProjectsSection> createState() => _YourProjectsSectionState();
}

class _YourProjectsSectionState extends State<YourProjectsSection> {
  final Set<String> _selectedFilters = <String>{};

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
    return Consumer2<ProjectsStore, PostsStore>(
      builder: (context, projectsStore, postsStore, _) {
        if (projectsStore.isFetching && projectsStore.projects.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (projectsStore.projects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: StyledBodyText500('No projects available yet.'),
          );
        }

        final allProjects = projectsStore.projects;
        final allPrimaryTags =
            allProjects.map((project) => project.primaryTag.toString()).toSet();
        final filteredProjects = _selectedFilters.isEmpty
            ? allProjects
            : allProjects.where((project) {
                return _selectedFilters.contains(project.primaryTag.toString());
              }).toList();

        final followedIds = projectsStore.followedProjectIds;
        final projectsForStats = followedIds.isEmpty
            ? allProjects
            : allProjects.where((project) => followedIds.contains(project.id));
        final postsForStats = postsStore.posts.where((post) {
          if (followedIds.isEmpty) return true;
          return followedIds.contains(post.projectId);
        });

        final followedCount = projectsForStats.length;
        final postCount = postsForStats.length;
        final highUrgencyCount = postsForStats
            .where((post) => post.priority == Priority.high)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: StatCard(
                    label: 'Followed Projects',
                    value: followedCount,
                    iconName: 'style',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: StatCard(
                    label: 'New Posts',
                    value: postCount,
                    iconName: 'post',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: StatCard(
                    label: 'High Urgency Posts',
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
            Wrap(
              children: List.generate(
                filteredProjects.length,
                (index) => YourProjectCard(project: filteredProjects[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}
