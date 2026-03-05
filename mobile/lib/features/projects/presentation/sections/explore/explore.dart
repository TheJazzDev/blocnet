import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/cards/tag_card.dart';

class ExploreSection extends StatelessWidget {
  const ExploreSection({
    required this.allPosts,
    required this.feedViewMode,
    super.key,
  });

  final List<Update> allPosts;
  final FeedViewMode feedViewMode;

  List<Widget> _buildFeedRows(List<Update> posts) {
    final safePosts =
        posts.where((post) => post.project != null && post.admin != null);
    if (feedViewMode == FeedViewMode.card) {
      return safePosts.map((post) => FeedCard(post: post)).toList();
    }

    final rows = <Widget>[];
    final list = safePosts.toList();
    for (var index = 0; index < list.length; index++) {
      rows.add(
        FeedCard(
          post: list[index],
          layout: FeedCardLayout.list,
        ),
      );
      if (index < list.length - 1) {
        rows.add(
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
        );
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final latestPosts = [...allPosts]..sort((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });
    final rows = _buildFeedRows(latestPosts);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'FILTER',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 10,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TagCard(
                  label: 'Trending',
                  iconName: 'timeline',
                  onTap: () =>
                      Navigator.pushNamed(context, ProtectedRoutes.trending),
                ),
                TagCard(
                  label: 'High Urgency',
                  iconName: 'emergency',
                  onTap: () => Navigator.pushNamed(
                    context,
                    ProtectedRoutes.highPriority,
                    arguments: {'priority': Priority.high},
                  ),
                ),
                TagCard(
                  label: 'Medium Urgency',
                  iconName: 'brightness',
                  onTap: () => Navigator.pushNamed(
                    context,
                    ProtectedRoutes.midPriority,
                    arguments: {'priority': Priority.mid},
                  ),
                ),
                TagCard(
                  label: 'Low Urgency',
                  iconName: 'calm',
                  onTap: () => Navigator.pushNamed(
                    context,
                    ProtectedRoutes.lowPriority,
                    arguments: {'priority': Priority.low},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest News',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'No updates yet.',
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 12,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Column(children: rows),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
