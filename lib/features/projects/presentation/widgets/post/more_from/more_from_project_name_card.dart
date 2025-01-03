import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/shared/post_tag_row.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/features/projects/presentation/widgets/labels/priority_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/dividers/vertical_divider.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:blocknet/shared/utils/format_date_utils.dart';

class MoreFromProjectNameCard extends StatelessWidget {
  const MoreFromProjectNameCard({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 295,
      height: 216,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        border: Border.all(color: AppColors.darkGrey200),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostTagRow(post: post, moreFrom: true),
          const SizedBox(height: 12),
          StyledTitleMedium(post.title),
          const SizedBox(height: 8),
          Expanded(
            child: StyledBodyText(
              post.description,
              applyOverflow: true,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StyledBodyText500(
                formatDateWithSuffix(post.createdAt),
                size: 12,
              ),
              const SizedBox(width: 12),
              CustomVerticalDivider(height: 20),
              const SizedBox(width: 12),
              PriorityLabel(priority: post.priority, miniCard: true),
            ],
          ),
        ],
      ),
    );
  }
}
