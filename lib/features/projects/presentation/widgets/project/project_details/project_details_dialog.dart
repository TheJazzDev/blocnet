import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/services/project_by_id_service.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/more_from_project_name.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:flutter/material.dart';
import '../more_from/urgent_post_in_project_name.dart';
import 'project_details_header.dart';
import 'project_details_info.dart';

class ProjectDetailsDialog extends StatefulWidget {
  const ProjectDetailsDialog({required this.projectId, super.key});

  final String projectId;

  @override
  State<ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<ProjectDetailsDialog> {
  late Project project;
  late List<Post> recentPostInProjectName;

  @override
  void initState() {
    super.initState();

    // Fetch the project
    project = ProjectByIdService.fetchProjectById(widget.projectId);

    // Filter posts related to this project and also fetch urgent posts
    setState(() {
      recentPostInProjectName = project.posts?.take(5).toList() ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.darkGrey100,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
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
                        SizedBox(height: 32),
                        RenderMarkdownContent(content: project.details),
                        SizedBox(height: 40),
                        MoreFromProjectName(
                          label: 'Recent Posts in',
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
}
