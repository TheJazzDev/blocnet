import 'package:blocknet/features/projects/data/models/post.dart';
import 'package:blocknet/features/projects/presentation/widgets/post_card.dart';
import 'package:blocknet/shared/styles/text.dart';
import 'package:blocknet/shared/widgets/toggle_button.dart';
import 'package:blocknet/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String activeSection = 'first-section';

  void _handleToggle(String activeButton) {
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
              if (activeSection == 'first-section')
                Column(
                  children: List.generate(
                    Post.dummyPosts.length,
                    (index) => PostCard(Post.dummyPosts[index]),
                  ),
                )
              else if (activeSection == 'second-section')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StyledHeading('Explore page'),
                    // Add more widgets if necessary
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
