import 'package:blocknet/features/projects/data/models/post.dart';
import 'package:blocknet/features/projects/presentation/widgets/primary_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/secondary_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/vertical_divider.dart';
import 'package:flutter/material.dart';

class PostDetailsTags extends StatelessWidget {
  const PostDetailsTags(this.post, {super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PrimaryLabel(post.primaryTag),
            CustomVerticalDivider(
              height: 25,
              single: true,
            ),
            SizedBox(width: 8)
          ],
        ),
        Expanded(
          child: Wrap(
            runSpacing: 12,
            children: post.secondaryTags.map((tag) {
              return Container(
                padding: const EdgeInsets.only(right: 4),
                child: SecondaryLabel(
                  tag,
                  useDisplayText: false,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
