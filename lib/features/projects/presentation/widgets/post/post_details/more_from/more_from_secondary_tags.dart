import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/data/services/post_by_secondary_tag_service.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/features/projects/presentation/widgets/secondary_label.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class MoreFromSecondaryTags extends StatefulWidget {
  const MoreFromSecondaryTags({required this.post, super.key});

  final Post post;

  @override
  State<MoreFromSecondaryTags> createState() => _MoreFromSecondaryTagsState();
}

class _MoreFromSecondaryTagsState extends State<MoreFromSecondaryTags> {
  late List<Post> morePosts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    final secondaryTags = widget.post.secondaryTags;

    // Fetch posts by secondary tags using the PostService
    setState(() {
      morePosts =
          PostBySecondaryTagService.fetchPostsBySecondaryTags(secondaryTags);
    });
  }

  @override
  Widget build(BuildContext context) {
    final secondaryTags = widget.post.secondaryTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StyledBodyText600("More From"),
            SizedBox(width: 8),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    secondaryTags.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SecondaryLabel(
                        secondaryTags[index],
                        useDisplayText: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        morePosts.isEmpty
            ? const Text("No posts available for this secondary tag!")
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
