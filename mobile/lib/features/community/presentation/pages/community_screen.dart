import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/community/presentation/widgets/community_feed_list.dart';
import 'package:blocnet/features/community/presentation/widgets/community_tabs.dart';
import 'package:blocnet/shared/application/feed/feed_sync_controller.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<CommunityTopic, ScrollController> _scrollControllers = {
    CommunityTopic.general: ScrollController(),
    CommunityTopic.marketTalk: ScrollController(),
  };
  final Set<String> _pendingNewPostIds = <String>{};
  final FeedSyncController _feedSyncController =
      FeedSyncController(debugLabel: 'Community');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_isActiveListNearTop() && _pendingNewPostIds.isNotEmpty) {
        setState(() => _pendingNewPostIds.clear());
      } else {
        setState(() {});
      }
    });
    for (final controller in _scrollControllers.values) {
      controller.addListener(_handleScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CommunityPostsStore>().fetchPostsOnce();
    });
    _feedSyncController.start(
      realtimeEnabled: AppConfig.isSupabaseConfigured,
      pollInterval: const Duration(seconds: 12),
      channelName: 'community-new-posts',
      table: 'CommunityPost',
      onSyncRequested: _checkForNewPosts,
    );
  }

  @override
  void dispose() {
    _feedSyncController.dispose();
    for (final controller in _scrollControllers.values) {
      controller
        ..removeListener(_handleScroll)
        ..dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_isActiveListNearTop() && _pendingNewPostIds.isNotEmpty) {
      setState(() => _pendingNewPostIds.clear());
    }
  }

  CommunityTopic _activeTopic() {
    switch (_tabController.index) {
      case 1:
        return CommunityTopic.marketTalk;
      default:
        return CommunityTopic.general;
    }
  }

  bool _isActiveListNearTop() {
    final controller = _scrollControllers[_activeTopic()];
    if (controller == null || !controller.hasClients) return true;
    return controller.offset < 80;
  }

  Future<void> _checkForNewPosts() async {
    if (!mounted) return;

    final store = context.read<CommunityPostsStore>();
    final existingIds = store.posts.map((post) => post.id).toSet();

    await store.refreshPosts();

    if (!mounted) return;

    final newIds = store.posts
        .where((post) => !existingIds.contains(post.id))
        .map((post) => post.id);

    if (newIds.isEmpty || _isActiveListNearTop()) return;

    setState(() => _pendingNewPostIds.addAll(newIds));
  }

  int _pendingCountForActiveTopic(List<CommunityPost> posts) {
    final active = _activeTopic();
    final visible = _filterPosts(posts, active);
    return visible.where((post) => _pendingNewPostIds.contains(post.id)).length;
  }

  Future<void> _jumpToLatest() async {
    final controller = _scrollControllers[_activeTopic()];
    if (controller != null && controller.hasClients) {
      await controller.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    setState(() => _pendingNewPostIds.clear());
  }

  Future<void> _handleRefresh() async {
    await context.read<CommunityPostsStore>().refreshPosts();
    if (!mounted) return;
    setState(() => _pendingNewPostIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;
    final isHunterSpace = context.watch<AuthStore>().isInHunterSpace;
    final viewMode = context.watch<FeedViewModeStore>().mode;
    final accent = AppColors.accentForSpace(isHunterSpace);
    final onAccent = AppColors.onAccentForSpace(isHunterSpace);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.communityCreatePost),
        backgroundColor: accent,
        elevation: 0,
        child: Icon(Icons.add_rounded, color: onAccent),
      ),
      body: Consumer<CommunityPostsStore>(
        builder: (context, store, _) {
          final posts = store.posts;

          if (store.isFetchingPosts && posts.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: accent,
                strokeWidth: 2,
              ),
            );
          }

          final pendingCount = _pendingCountForActiveTopic(posts);

          return Stack(
            children: [
              Column(
                children: [
                  CommunityTabs(
                    controller: _tabController,
                    accentColor: accent,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        CommunityFeedList(
                          posts: _filterPosts(posts, CommunityTopic.general),
                          bottomPad: bottomPad,
                          mode: viewMode,
                          controller:
                              _scrollControllers[CommunityTopic.general]!,
                          accentColor: accent,
                          onRefresh: _handleRefresh,
                          onLike: store.toggleLike,
                          onBookmark: store.toggleBookmark,
                        ),
                        CommunityFeedList(
                          posts: _filterPosts(posts, CommunityTopic.marketTalk),
                          bottomPad: bottomPad,
                          mode: viewMode,
                          controller:
                              _scrollControllers[CommunityTopic.marketTalk]!,
                          accentColor: accent,
                          onRefresh: _handleRefresh,
                          onLike: store.toggleLike,
                          onBookmark: store.toggleBookmark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (pendingCount > 0)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _jumpToLatest,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$pendingCount new posts',
                          style: AppTypography.custom(
                            color: onAccent,
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<CommunityPost> _filterPosts(
      List<CommunityPost> posts, CommunityTopic tab) {
    return posts.where((post) => post.topic == tab).toList();
  }
}
