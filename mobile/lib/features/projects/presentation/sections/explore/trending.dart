import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocnet/services/posts_store.dart';
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
      Provider.of<PostsStore>(context, listen: false).fetchPostsOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Trending', backButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<PostsStore>(
          builder: (context, store, _) {
            if (store.isFetching && store.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final trendingPosts = _getTrendingPosts(store.posts);
            if (trendingPosts.isEmpty) {
              return const Center(child: Text('No trending posts available.'));
            }

            return SingleChildScrollView(
              child: Column(
                children: List.generate(
                  trendingPosts.length,
                  (index) => PostCard(post: trendingPosts[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Post> _getTrendingPosts(List<Post> posts) {
    final ranking = <Priority, int>{
      Priority.high: 0,
      Priority.mid: 1,
      Priority.low: 2,
    };

    final sorted = [...posts];
    sorted.sort((a, b) {
      final byPriority =
          (ranking[a.priority] ?? 99).compareTo(ranking[b.priority] ?? 99);
      if (byPriority != 0) return byPriority;
      return b.createdAt.compareTo(a.createdAt);
    });

    return sorted.take(20).toList();
  }
}
