import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/activity_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_inline_state.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_row_group.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/detail_dialogs.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

/// The profile owner's latest updates; each row opens that update.
class PublicProfileRecentActivity extends StatelessWidget {
  const PublicProfileRecentActivity({super.key, required this.posts});

  final List<Update> posts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Recent updates', icon: Icons.article_outlined),
        AppSpace.gapSm,
        ProfileRowGroup(
          children: [
            if (posts.isEmpty)
              const ProfileInlineState(
                icon: Icons.article_outlined,
                title: 'No updates yet',
              )
            else
              for (final post in posts.take(4))
                ActivityCard(
                  title: post.title,
                  subtitle: post.project?.name ?? 'Gem',
                  time: getTimeStamp(post.createdAt),
                  onTap: post.id.trim().isEmpty
                      ? null
                      : () => showUpdateDetailsDialog(context, post.id),
                ),
          ],
        ),
      ],
    );
  }
}
