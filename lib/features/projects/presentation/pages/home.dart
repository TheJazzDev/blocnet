import 'explore/explore.dart';
import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/sections_model.dart';
import 'package:blocknet/features/projects/data/services/all_posts.dart';
import 'package:blocknet/features/projects/presentation/widgets/app_bar.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/features/projects/presentation/widgets/toggle_button.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Sections activeSection = Sections.forYou;

  void _handleToggle(Sections activeButton) {
    setState(() {
      activeSection = activeButton;
    });
  }

  final allPosts = AllPosts.getAllPosts();

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
                  text1: 'For You',
                  text2: 'Explore',
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
