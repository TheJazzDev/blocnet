import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/priority_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/vertical_divider.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:flutter/material.dart';
import '../shared/post_project_logo.dart';

class PostCardDetails extends StatelessWidget {
  const PostCardDetails({required this.post, this.miniCard = false, super.key});

  final Post post;
  final bool miniCard;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostProjectLogo(logoUrl: post.project?.logo ?? '', size: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StyledTitleMedium(post.title),
              const SizedBox(height: 8),
              StyledBodyText(post.description, applyOverflow: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  StyledBodyText500(
                    formatDateWithSuffix(post.createdAt),
                    size: 12,
                  ),
                  const SizedBox(width: 12),
                  CustomVerticalDivider(height: 12.9),
                  const SizedBox(width: 12),
                  PriorityLabel(priority: post.priority, miniCard: miniCard),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
