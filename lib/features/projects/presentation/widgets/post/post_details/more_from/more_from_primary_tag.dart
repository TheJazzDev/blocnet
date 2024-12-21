import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocknet/features/projects/data/services/post_by_primary_tag_service.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/features/projects/presentation/widgets/primary_label.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class MoreFromPrimaryTag extends StatefulWidget {
  const MoreFromPrimaryTag({required this.primaryTag, super.key});

  final PrimaryTag primaryTag;

  @override
  State<MoreFromPrimaryTag> createState() => _MoreFromPrimaryTagState();
}

class _MoreFromPrimaryTagState extends State<MoreFromPrimaryTag> {
  late List<Post> morePosts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      morePosts =
          PostByPrimaryTagService.fetchPostsByPrimaryTag(widget.primaryTag);
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
                PrimaryLabel(primaryTag: widget.primaryTag),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        morePosts.isEmpty
            ? const Text("No posts available for this tag!")
            : Column(
                children: List.generate(
                  morePosts.length,
                  (index) => PostCard(post: morePosts[index], moreFrom: true),
                ),
              ),
      ],
    );
  }
}
