import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/chain_chip.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_tag_pill.dart';
import 'package:flutter/material.dart';

/// The gem's chain chip and up to two category tags.
class GemTags extends StatelessWidget {
  const GemTags({super.key, required this.project, this.maxSecondary = 2});

  final Project project;
  final int maxSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = project.secondaryTags
        .map((t) => t.name.trim())
        .where((n) => n.isNotEmpty)
        .take(maxSecondary);
    return Wrap(
      spacing: AppSpace.xs + 2,
      runSpacing: AppSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChainChip(tag: project.primaryTag.name),
        for (final name in secondary) FeedTagPill(label: name),
      ],
    );
  }
}
