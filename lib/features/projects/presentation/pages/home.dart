import 'package:blocknet/features/projects/data/models/post.dart';
import 'package:blocknet/features/projects/data/models/sections.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/features/projects/presentation/widgets/tag_card.dart';
import 'package:blocknet/shared/styled/text.dart';
import 'package:blocknet/features/projects/presentation/widgets/toggle_button.dart';
import 'package:blocknet/features/projects/presentation/widgets/app_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Jazzdev'),
      body: SingleChildScrollView(
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
                  : _buildExploreSection()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForYouSection() {
    return Column(
      children: List.generate(
        Post.dummyPosts.length,
        (index) => PostCard(Post.dummyPosts[index]),
      ),
    );
  }

  Widget _buildExploreSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TagCard(label: 'Trending', iconName: 'timeline', onTap: () {}),
                TagCard(
                    label: 'High Urgency', iconName: 'emergency', onTap: () {}),
                TagCard(
                    label: 'Mid Urgency', iconName: 'brightness', onTap: () {}),
                TagCard(label: 'Low Urgency', iconName: 'calm', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 32),
          StyledBodyText400('Latest News'),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: Post.dummyPosts.length,
            itemBuilder: (context, index) {
              return PostCard(Post.dummyPosts[index]);
            },
          ),
        ],
      ),
    );
  }
}
