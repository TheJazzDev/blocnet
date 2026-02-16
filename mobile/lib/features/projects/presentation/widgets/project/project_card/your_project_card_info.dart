import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:flutter/material.dart';

class YourProjectCardInfo extends StatelessWidget {
  const YourProjectCardInfo({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.darkGrey100,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(color: AppColors.darkGrey200),
          ),
          child: StyledBodyText600(
            '${project.followersCount} followers',
            size: 10,
          ),
        ),
        SizedBox(width: 8),
        if (project.posts != null && project.posts!.isNotEmpty)
          if (project.posts![0].lastEditedAt != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.darkGrey100,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(color: AppColors.darkGrey200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StyledBodyText400('Last updated', size: 12),
                  const SizedBox(width: 8),
                  StyledBodyText600(
                    formatDateWithSuffix(project.posts![0].lastEditedAt!),
                    size: 12,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
