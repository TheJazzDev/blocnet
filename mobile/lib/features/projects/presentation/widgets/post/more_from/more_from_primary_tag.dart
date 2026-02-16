import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MoreFromPrimaryTag extends StatelessWidget {
  const MoreFromPrimaryTag({required this.primaryTag, super.key});

  final PrimaryTag primaryTag;

  @override
  Widget build(BuildContext context) {
    final postStore = Provider.of<PostsStore>(context);
    final morePosts = postStore.getPostsByPrimaryTag(primaryTag, context);

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
                PrimaryLabel(primaryTag: primaryTag),
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
                  (index) => PostCard(post: morePosts[index], miniCard: true),
                ),
              ),
      ],
    );
  }
}
