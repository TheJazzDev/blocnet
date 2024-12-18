import 'package:blocknet/features/projects/data/models/post.dart';
import 'package:blocknet/features/projects/presentation/widgets/primary_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/secondary_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/vertical_divider.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/app/theme.dart';

import 'package:blocknet/shared/styled/text.dart';

class PostCardTagRow extends StatelessWidget {
  const PostCardTagRow({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const tagWidth = 120;
        final maxTags = (availableWidth / tagWidth).floor();

        int hiddenCount = post.secondaryTags.length > maxTags
            ? post.secondaryTags.length - maxTags
            : 0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(width: 2)
              ],
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: post.secondaryTags.take(maxTags).map((tag) {
                  return Container(
                    padding: const EdgeInsets.only(right: 4),
                    child: SecondaryLabel(tag),
                  );
                }).toList(),
              ),
            ),

            // Hidden tags count
            if (hiddenCount > 0)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey200,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: StyledBodyText('+$hiddenCount'),
                ),
              ),
          ],
        );
      },
    );
  }
}
