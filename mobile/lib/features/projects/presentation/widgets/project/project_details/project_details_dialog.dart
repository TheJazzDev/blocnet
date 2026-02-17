import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/more_from_project_name.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../more_from/urgent_update_in_project_name.dart';
import 'project_details_header.dart';
import 'project_details_info.dart';

class ProjectDetailsDialog extends StatelessWidget {
  const ProjectDetailsDialog({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final projectsStore = Provider.of<ProjectsStore>(context);
    final postsStore = Provider.of<UpdatesStore>(context);

    final project = _resolveProject(
      projectId: projectId,
      projectsStore: projectsStore,
      postsStore: postsStore,
    );

    if (project == null) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final recentPostInProjectName = (project.posts ?? []).take(5).toList();
    final detailsContent =
        project.details.isEmpty ? project.description : project.details;

    return SafeArea(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                ProjectDetailsHeader(projectId: project.id),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProjectDetailsInfo(project: project),
                        const SizedBox(height: 32),
                        RenderMarkdownContent(content: detailsContent),
                        const SizedBox(height: 40),
                        MoreFromProjectName(
                          label: 'Recent Updates in',
                          projectTitle: project.name,
                          posts: recentPostInProjectName,
                        ),
                        const CustomHorizontalDivider(margin: 16),
                        UrgentPostInProjectName(
                          projectName: project.name,
                          projectId: project.id,
                        ),
                        const CustomHorizontalDivider(margin: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Project? _resolveProject({
    required String projectId,
    required ProjectsStore projectsStore,
    required UpdatesStore postsStore,
  }) {
    final relatedPosts =
        postsStore.posts.where((post) => post.projectId == projectId).toList();

    final fromProjectsStore = projectsStore.getProjectById(projectId);
    if (fromProjectsStore != null) {
      return fromProjectsStore.copyWith(posts: relatedPosts);
    }

    final postWithProject = relatedPosts.where((post) => post.project != null);
    if (postWithProject.isNotEmpty) {
      final project = postWithProject.first.project!;
      return project.copyWith(posts: relatedPosts);
    }

    return null;
  }
}
