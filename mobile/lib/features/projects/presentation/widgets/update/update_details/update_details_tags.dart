import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/secondary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/vertical_divider.dart';
import 'package:flutter/material.dart';

class UpdateDetailsTags extends StatelessWidget {
  const UpdateDetailsTags(this.post, {super.key});

  final Update post;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PrimaryLabel(
              primaryTag: post.project?.primaryTag ?? PrimaryTag.none,
            ),
            CustomVerticalDivider(height: 25, single: true),
            SizedBox(width: 8),
          ],
        ),
        Expanded(
          child: Wrap(
            runSpacing: 12,
            children: post.secondaryTags.map((tag) {
              return Container(
                padding: const EdgeInsets.only(right: 4),
                child: SecondaryLabel(tag, useDisplayText: false),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
