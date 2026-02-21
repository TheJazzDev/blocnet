import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_card/update_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/cards/tag_card.dart';

class ExploreSection extends StatelessWidget {
  const ExploreSection({required this.allPosts, super.key});

  final List<Update> allPosts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allPosts.length,
                  itemBuilder: (context, index) {
                    return UpdateCard(post: allPosts[index]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
