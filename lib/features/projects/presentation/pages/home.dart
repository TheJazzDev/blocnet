import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/dummy/dummy_admins.dart';
import 'package:blocknet/features/projects/data/dummy/dummy_posts.dart';
import 'package:blocknet/features/projects/data/dummy/dummy_projects.dart';
import 'package:blocknet/features/projects/data/models/admin_model.dart';
import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/data/models/project_model.dart';
import 'package:blocknet/features/projects/data/models/sections_model.dart';
import 'package:blocknet/features/projects/presentation/widgets/app_bar.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/features/projects/presentation/widgets/tag_card.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
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

  // Enrich posts with project and admin details
  List<Post> _enrichedPosts() {
    return dummyPosts.map((post) {
      Admin? admin;
      Project? project;

      try {
        project = dummyProjects.firstWhere((p) => p.id == post.projectId);
      } catch (e) {
        // debugPrint('Project not found for postId: ${post.projectId}');
        project = null;
      }

      try {
        admin = dummyAdmins.firstWhere((a) => a.id == post.adminId);
      } catch (e) {
        // debugPrint('Admin not found for adminId: ${post.adminId}');
        admin = null;
      }

      return post.copyWith(project: project, admin: admin);
    }).toList();
  }

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
                    : _buildExploreSection()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForYouSection() {
    final enrichedPosts = _enrichedPosts()
        .where((post) => post.project != null && post.admin != null)
        .toList();

    return Column(
      children: List.generate(
        enrichedPosts.length,
        (index) => PostCard(post: enrichedPosts[index]),
      ),
    );
  }

  Widget _buildExploreSection() {
    final enrichedPosts = _enrichedPosts();

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
            itemCount: dummyPosts.length,
            itemBuilder: (context, index) {
              return PostCard(post: enrichedPosts[index]);
            },
          ),
        ],
      ),
    );
  }
}
