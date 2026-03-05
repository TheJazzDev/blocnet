import 'dart:math' as math;

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_card/update_card.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UpdatesStore>(context, listen: false).fetchUpdatesOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Trending', backButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<UpdatesStore>(
          builder: (context, store, _) {
            if (store.isFetching && store.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final trendingPosts = _getTrendingPosts(store.posts);
            if (trendingPosts.isEmpty) {
              return _EmptyState();
            }

            return SingleChildScrollView(
              child: Column(
                children: List.generate(
                  trendingPosts.length,
                  (index) => UpdateCard(post: trendingPosts[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Update> _getTrendingPosts(List<Update> posts) {
    final now = DateTime.now();
    final ranked = posts
        .map((post) => (post: post, score: _trendScore(post, now)))
        .toList();

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.post.createdAt.compareTo(a.post.createdAt);
    });

    return ranked.take(20).map((entry) => entry.post).toList();
  }

  double _trendScore(Update post, DateTime now) {
    var priorityWeight = 18.0;
    if (post.priority == Priority.high) {
      priorityWeight = 46.0;
    } else if (post.priority == Priority.mid) {
      priorityWeight = 30.0;
    }

    final hoursSincePost = now.difference(post.createdAt).inHours.toDouble();
    final recencyBoost = (48 - hoursSincePost).clamp(0, 48) * 0.6;
    final projectFollowers =
        math.min(post.project?.followersCount ?? 0, 800) * 0.03;
    final adminFollowers = math.min(post.admin?.followers ?? 0, 2000) * 0.01;
    final tagBoost = math.min(post.secondaryTags.length, 4) * 1.5;

    return priorityWeight +
        recencyBoost +
        projectFollowers +
        adminFollowers +
        tagBoost;
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.teal400.withValues(alpha: 0.2),
                    AppColors.teal400.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: 40,
                color: AppColors.teal400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Trending Updates',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 18,
                weight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'There are no trending updates at the moment.\nCheck back later to see what\'s hot!',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 14,
                weight: FontWeight.w400,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
