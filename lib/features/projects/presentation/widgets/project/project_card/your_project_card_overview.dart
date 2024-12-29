import 'package:blocknet/features/projects/data/models/project_model.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../post/shared/post_project_logo.dart';

class YourProjectCardOverview extends StatelessWidget {
  const YourProjectCardOverview({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PostProjectLogo(
          logoUrl: project.logo,
          size: 40,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StyledBodyText500(project.primaryTag.toString()),
              SizedBox(width: 4),
              StyledBodyText700(project.name)
            ],
          ),
        ),
        SizedBox(width: 12),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
        )
      ],
    );
  }
}
