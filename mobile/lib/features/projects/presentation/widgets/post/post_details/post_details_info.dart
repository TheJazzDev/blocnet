import 'dart:math';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/dot_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import '../shared/post_project_logo.dart';
import '../shared/post_project_title.dart';

class PostDetailsInfo extends StatelessWidget {
  const PostDetailsInfo({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final readMinutes = _estimateReadMinutes(post.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PostProjectLogo(logoUrl: post.project?.logo ?? '', size: 60),
            const SizedBox(width: 24),
            Flexible(
              child: PostProjectTitle(
                projectTitle: post.project?.name ?? '',
                margin: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StyledLabelLarge(post.title),
        const SizedBox(height: 4),
        const CustomHorizontalDivider(margin: 12),
        Wrap(
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StyledBodyText400('By'),
                const SizedBox(width: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    post.admin?.imageUrl ?? post.project?.logo ?? '',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => Container(
                      width: 20,
                      height: 20,
                      color: AppColors.darkGrey200,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                StyledBodyText600(post.admin?.name ?? 'No admin name'),
              ],
            ),
            DotDivider(12),
            StyledBodyText600(
              formatDateWithSuffix(post.createdAt),
              size: 12,
              fontWeight: FontWeight.w400,
            ),
            DotDivider(12),
            StyledBodyText600(
              '$readMinutes mins read',
              size: 12,
              fontWeight: FontWeight.w400,
            ),
            SizedBox(width: 12),
            // DotDivider(12),
            if (post.lastEditedAt != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey75,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  border: Border.all(color: AppColors.darkGrey300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StyledBodyText400('last edited', size: 12),
                    const SizedBox(width: 8),
                    StyledBodyText600(
                      formatDateWithSuffix(post.lastEditedAt!),
                      size: 12,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  int _estimateReadMinutes(String content) {
    final words = content
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .length;

    if (words == 0) return 1;
    return max(1, (words / 220).ceil());
  }
}
