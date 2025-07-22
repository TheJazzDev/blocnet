import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/post/shared/post_project_title.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../post/more_from/more_from_project_name_card.dart';

class MoreFromProjectName extends StatelessWidget {
  const MoreFromProjectName({
    required this.label,
    required this.projectTitle,
    required this.posts,
    super.key,
  });

  final String label;
  final String projectTitle;
  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StyledBodyText600(label),
                PostProjectTitle(projectTitle: projectTitle, margin: false),
              ],
            ),
          ],
        ),
        posts.isEmpty
            ? StyledBodyText500("No posts available for this $projectTitle!")
            : Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: SvgPicture.asset(
                        "assets/icons/corner_down_right.svg",
                        width: 12,
                        height: 12,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(posts.length, (index) {
                            final post = posts[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: MoreFromProjectNameCard(post: post),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}
