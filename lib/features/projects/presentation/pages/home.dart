import 'explore/explore.dart';
import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/sections_model.dart';
import 'package:blocknet/features/projects/data/services/all_posts_service.dart';
import 'package:blocknet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/features/projects/presentation/widgets/shared/toggle_button.dart';
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

  final allPosts = AllPostsService.getAllPosts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Blocnet'),
      body: RefreshIndicator(
        color: AppColors.primary400,
        backgroundColor: AppColors.darkGrey300,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
        },
        child: SingleChildScrollView(
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
                activeSection == Sections.forYou
                    ? _buildForYouSection()
                    : ExploreSection(allPosts: allPosts)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForYouSection() {
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
