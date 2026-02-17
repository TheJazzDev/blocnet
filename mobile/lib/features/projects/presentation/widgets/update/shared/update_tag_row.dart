import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/secondary_label.dart';
import 'package:flutter/material.dart';

class UpdateTagRow extends StatelessWidget {
  const UpdateTagRow({required this.post, this.moreFrom = false, super.key});

  final Update post;
  final bool moreFrom;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!moreFrom) ...[
            PrimaryLabel(
              primaryTag: post.project?.primaryTag ?? PrimaryTag.none,
            ),
            const SizedBox(width: 6),
          ],
          ...post.secondaryTags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SecondaryLabel(tag),
              )),
        ],
      ),
    );
  }
}
