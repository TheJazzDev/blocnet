import 'package:blocknet/features/projects/data/models/post.dart';
import 'package:blocknet/features/projects/presentation/widgets/priority_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/vertical_divider.dart';
import 'package:blocknet/shared/styled/text.dart';
import 'package:blocknet/shared/utils/format_date.dart';
import 'package:flutter/material.dart';
import '../shared/post_project_logo.dart';

class PostCardDetails extends StatelessWidget {
  const PostCardDetails({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostProjectLogo(
          logoUrl: post.logoUrl,
          size: 40,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StyledTitleSmall(post.title),
              const SizedBox(height: 8),
              StyledBodyText(post.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  StyledBodyText500(formatDateWithSuffix(post.createdAt)),
                  const SizedBox(width: 12),
                  CustomVerticalDivider(height: 25),
                  const SizedBox(width: 12),
                  PriorityLabel(post.priority),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
