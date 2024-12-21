import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/presentation/widgets/dot_divider.dart';
import 'package:blocknet/features/projects/presentation/widgets/horizontal_divider.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:blocknet/shared/utils/format_date_utils.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/features/projects/data/models/post_model.dart';
import '../shared/post_project_logo.dart';
import '../shared/post_project_title.dart';

class PostDetailsInfo extends StatelessWidget {
  const PostDetailsInfo({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PostProjectLogo(logoUrl: post.project?.logo ?? '', size: 60),
            const SizedBox(width: 24),
            Flexible(
              child: PostProjectTitle(
                  projectTitle: post.project?.name ?? '', margin: false),
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
                    post.project?.logo ?? '',
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 4),
                StyledBodyText600(post.admin?.name ?? 'No admin name'),
              ],
            ),
            DotDivider(12),
            StyledBodyText500(formatDateWithSuffix(post.createdAt)),
            DotDivider(12),
            StyledBodyText500('12 mins read'),
            SizedBox(width: 12),
            // DotDivider(12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                  StyledBodyText600(formatDateWithSuffix(post.createdAt),
                      size: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
