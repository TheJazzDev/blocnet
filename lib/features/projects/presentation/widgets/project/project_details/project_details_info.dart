import 'package:blocknet/features/projects/data/models/project_model.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/shared/post_project_logo.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/shared/post_project_title.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class ProjectDetailsInfo extends StatelessWidget {
  const ProjectDetailsInfo({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PostProjectLogo(logoUrl: project.logo, size: 60),
            const SizedBox(width: 24),
            Flexible(
              child:
                  PostProjectTitle(projectTitle: project.name, margin: false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StyledLabelLarge(project.name),
      ],
    );
  }
}
