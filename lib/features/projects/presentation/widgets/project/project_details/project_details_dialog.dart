import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/data/models/project_model.dart';
import 'package:blocknet/features/projects/data/services/post_by_id.dart';
import 'package:blocknet/features/projects/data/services/project_by_id.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    project = ProjectById.fetchProjectById(widget.projectId);
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
              )),
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
                        // const CustomHorizontalDivider(margin: 12),
                        // PostDetailsTags(post),
                        // const CustomHorizontalDivider(margin: 12),
                        // PostDetailsOverview(content: post.content),
                        // SizedBox(height: 40),
                        // MoreFromProjectName(
                        //     projectId: post.project?.id ?? '',
                        //     projectTitle: post.project?.name ?? ''),
                        // const CustomHorizontalDivider(margin: 16),
                        // const SizedBox(height: 16),
                        // MoreFromPrimaryTag(
                        //     primaryTag:
                        //         post.project?.primaryTag ?? PrimaryTag.none),
                        // SizedBox(height: 8),
                        // const CustomHorizontalDivider(margin: 16),
                        // SizedBox(height: 8),
                        // MoreFromSecondaryTags(post: post),
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
