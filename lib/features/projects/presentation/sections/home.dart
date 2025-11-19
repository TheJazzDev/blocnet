import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:blocnet/core/routes/route_names.dart';
import 'package:provider/provider.dart';
import 'explore/explore.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  Section _activeSection = Sections.forYou;
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  void _handleToggle(Section activeButton) {
    setState(() {
      _activeSection = activeButton;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostsStore>(context, listen: false).fetchPostsOnce();
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    Provider.of<PostsStore>(context, listen: false).fetchPostsOnce();
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: theme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.currency_bitcoin,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'BlocNet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.search_rounded, color: theme.primaryColor),
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.search);
                    },
                    tooltip: 'Search',
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: theme.primaryColor),
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.notifications);
                    },
                    tooltip: 'Notifications',
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Toggle Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: _buildModernToggle(),
                ),
              ),

              // Content
              Consumer<PostsStore>(
                builder: (context, store, _) {
                  if (_isRefreshing && store.posts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return _activeSection == Sections.forYou
                      ? _buildForYouSection(store.posts)
                      : SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ExploreSection(allPosts: store.posts),
                          ),
                        );
                },
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, RouteNames.adminDashboard);
        },
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildModernToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'For You',
              section: Sections.forYou,
              icon: Icons.home_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildToggleButton(
              label: 'Explore',
              section: Sections.explore,
              icon: Icons.explore_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required Section section,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isActive = _activeSection == section;
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: () => _handleToggle(section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? primaryColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForYouSection(List<Post> allPosts) {
    final enrichedPosts = allPosts
        .where((post) => post.project != null && post.admin != null)
        .toList();

    if (enrichedPosts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Follow some projects to see updates',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PostCard(post: enrichedPosts[index]),
            );
          },
          childCount: enrichedPosts.length,
        ),
      ),
    );
  }
}
