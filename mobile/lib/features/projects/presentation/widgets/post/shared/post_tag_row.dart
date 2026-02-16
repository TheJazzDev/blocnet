import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/secondary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/vertical_divider.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/theme.dart';

import 'package:blocnet/shared/styles/app_text_styles.dart';

class PostTagRow extends StatelessWidget {
  const PostTagRow({required this.post, this.moreFrom = false, super.key});

  final Post post;
  final bool moreFrom;

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
            if (!moreFrom)
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PrimaryLabel(
                    primaryTag: post.project?.primaryTag ?? PrimaryTag.none,
                  ),
                  CustomVerticalDivider(height: 25, single: true),
                  const SizedBox(width: 2),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
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
