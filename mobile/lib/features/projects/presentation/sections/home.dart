import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:provider/provider.dart';
import 'explore/explore.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/toggle_button.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Section activeSection = Sections.forYou;

  void _handleToggle(Section activeButton) {
    setState(() {
      activeSection = activeButton;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectsStore>(context, listen: false).fetchProjectsOnce();
      Provider.of<PostsStore>(context, listen: false).fetchPostsOnce();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Blocnet'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StyledToggleButton(
                section1: Sections.forYou,
                section2: Sections.explore,
                activeSection: activeSection,
                onToggle: _handleToggle,
              ),
              const SizedBox(height: 16),
              Consumer<PostsStore>(builder: (context, store, _) {
                return activeSection == Sections.forYou
                    ? _buildForYouSection(store.posts)
                    : ExploreSection(allPosts: store.posts);
              })
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForYouSection(List<Post> allPosts) {
    final enrichedPosts = allPosts
        .where((post) => post.project != null && post.admin != null)
        .toList();

    return Column(
      children: List.generate(
        enrichedPosts.length,
        (index) => PostCard(post: enrichedPosts[index]),
      ),
    );
  }
}
