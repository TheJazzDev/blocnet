import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/followed_projects_tab.dart';
import '../widgets/saved_posts_tab.dart';
import '../widgets/activity_tab.dart';
import '../../../../core/routes/route_names.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    if (authProvider.currentUser != null) {
      profileProvider.loadUserProfile(authProvider.currentUser!.id);
      profileProvider
          .loadFollowedProjects(authProvider.currentUser!.followedProjectIds);
      profileProvider.loadSavedPosts(authProvider.currentUser!.savedPostIds);
      profileProvider.listenToActivities(authProvider.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    if (authProvider.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('Please sign in to view your profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.editProfile);
            },
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ProfileHeader(user: authProvider.currentUser!),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Followed'),
                    Tab(text: 'Saved'),
                    Tab(text: 'Activity'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      FollowedProjectsTab(
                        projects: profileProvider.followedProjects,
                      ),
                      SavedPostsTab(
                        posts: profileProvider.savedPosts,
                      ),
                      ActivityTab(
                        activities: profileProvider.activities,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
