import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_card/update_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/secondary_label.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MoreFromUpdateSecondaryTags extends StatefulWidget {
  const MoreFromUpdateSecondaryTags({required this.post, super.key});

  final Update post;

  @override
  State<MoreFromUpdateSecondaryTags> createState() => _MoreFromSecondaryTagsState();
}

class _MoreFromSecondaryTagsState extends State<MoreFromUpdateSecondaryTags> {
  @override
  Widget build(BuildContext context) {
    final secondaryTags = widget.post.secondaryTags;
    final postsStore = Provider.of<UpdatesStore>(context);
    final morePosts = postsStore.getUpdatesBySecondaryTags(secondaryTags);

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
            ? const Text("No updates available for this secondary tag!")
            : Column(
                children: List.generate(
                  morePosts.length,
                  (index) => UpdateCard(post: morePosts[index], miniCard: true),
                ),
              ),
      ],
    );
  }
}
