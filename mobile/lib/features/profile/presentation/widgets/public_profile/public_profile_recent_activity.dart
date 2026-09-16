import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/activity_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/empty_activity_card.dart';
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
      children: [
        const SectionLabel('Recent Activity'),
        const SizedBox(height: AppSpace.sm),
        if (posts.isEmpty)
          const EmptyActivityCard()
        else
          ...posts.take(4).map(
                (post) => ActivityCard(
                  title: post.title,
                  subtitle: post.project?.name ?? 'Gem',
                  time: getTimeStamp(post.createdAt),
                  onTap: post.id.trim().isEmpty
                      ? null
                      : () => showUpdateDetailsDialog(context, post.id),
                ),
              ),
      ],
    );
  }
}
