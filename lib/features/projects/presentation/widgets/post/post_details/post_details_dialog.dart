import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/post.dart';
import 'package:blocknet/features/projects/presentation/widgets/dot_divider.dart';
import 'package:blocknet/features/projects/presentation/widgets/horizontal_divider.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_details/post_details_tags.dart';
import 'package:blocknet/features/projects/presentation/widgets/priority_label.dart';
import 'package:blocknet/shared/styled/text.dart';
import 'package:blocknet/shared/utils/format_date.dart';
import 'package:flutter/material.dart';
import '../shared/post_project_logo.dart';
import '../shared/post_project_title.dart';

class PostDetailsDialog extends StatelessWidget {
  const PostDetailsDialog(this.post, {super.key});

  final Post post;

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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      PriorityLabel(post.priority),
                      IconButton(
                        icon: const Icon(Icons.bookmark_outline),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PostProjectLogo(
                          logoUrl: post.logoUrl,
                          size: 60,
                        ),
                        SizedBox(width: 24),
                        Flexible(
                          child: PostProjectTitle(
                            post.projectTitle,
                            margin: false,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    StyledLabelLarge(post.title),
                    SizedBox(height: 4),
                    CustomHorizontalDivider(margin: 12),
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
                                post.logoUrl,
                                width: 20,
                                height: 20,
                              ),
                            ),
                            const SizedBox(width: 4),
                            StyledBodyText600(post.admin.name),
                          ],
                        ),
                        DotDivider(12),
                        StyledBodyText500(formatDateWithSuffix(post.createdAt)),
                        DotDivider(12),
                        StyledBodyText500('12 mins read'),
                        SizedBox(width: 12),
                        // DotDivider(12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.darkGrey75,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20)),
                            border: Border.all(color: AppColors.darkGrey300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StyledBodyText400('last edited', size: 12),
                              const SizedBox(width: 8),
                              StyledBodyText600(
                                  formatDateWithSuffix(post.createdAt),
                                  size: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                    CustomHorizontalDivider(margin: 12),
                    PostDetailsTags(post),
                    CustomHorizontalDivider(margin: 12),
                    StyledBodyText600('Overview')
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
