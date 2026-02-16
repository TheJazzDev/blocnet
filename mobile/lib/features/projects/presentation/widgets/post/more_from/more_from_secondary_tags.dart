import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/secondary_label.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MoreFromSecondaryTags extends StatefulWidget {
  const MoreFromSecondaryTags({required this.post, super.key});

  final Post post;

  @override
  State<MoreFromSecondaryTags> createState() => _MoreFromSecondaryTagsState();
}

class _MoreFromSecondaryTagsState extends State<MoreFromSecondaryTags> {
  @override
  Widget build(BuildContext context) {
    final secondaryTags = widget.post.secondaryTags;
    final postsStore = Provider.of<PostsStore>(context);
    final morePosts = postsStore.getPostsBySecondaryTags(secondaryTags);

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
                  (index) => PostCard(post: morePosts[index], miniCard: true),
                ),
              ),
      ],
    );
  }
}
