import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/data/dummy/dummy_posts.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/shared/post_project_title.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'more_from_project_name_card.dart';

class MoreFromProjectName extends StatefulWidget {
  const MoreFromProjectName(
      {required this.projectId, required this.projectTitle, super.key});

  final String projectId;
  final String projectTitle;

  @override
  State<MoreFromProjectName> createState() => _MoreFromProjectNameState();
}

class _MoreFromProjectNameState extends State<MoreFromProjectName> {
  late List<Post> morePosts;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      morePosts = dummyPosts
          .where((post) => post.projectId == widget.projectId)
          .toList();
    });
  }

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
                StyledBodyText600("More From"),
                PostProjectTitle(
                    projectTitle: widget.projectTitle, margin: false)
              ],
            ),
          ],
        ),
        morePosts.isEmpty
            ? StyledBodyText500(
                "No posts available for this ${widget.projectTitle}!")
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
                          children: List.generate(
                            morePosts.length,
                            (index) {
                              final post = morePosts[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: MoreFromProjectNameCard(post: post),
                              );
                            },
                          ),
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
