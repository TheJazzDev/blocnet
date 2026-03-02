import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/community/presentation/widgets/community_feed_list.dart';
import 'package:blocnet/features/community/presentation/widgets/community_tabs.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/services/feed_view_mode_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Timer? _newPostsPollTimer;
  RealtimeChannel? _newPostsRealtimeChannel;
  bool _isCheckingForNewPosts = false;

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
    _startNewPostsSync();
  }

  @override
  void dispose() {
    _newPostsPollTimer?.cancel();
    _stopNewPostsRealtimeSubscription();
    for (final controller in _scrollControllers.values) {
      controller
        ..removeListener(_handleScroll)
        ..dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  void _startNewPostsSync() {
    if (!AppConfig.isSupabaseConfigured) {
      _newPostsPollTimer = Timer.periodic(
        const Duration(seconds: 12),
        (_) => _checkForNewPosts(),
      );
      return;
    }

    _startNewPostsRealtimeSubscription();
  }

  void _startNewPostsRealtimeSubscription() {
    _stopNewPostsRealtimeSubscription();
    _newPostsRealtimeChannel = Supabase.instance.client
        .channel('community-new-posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'CommunityPost',
          callback: (_) => unawaited(_checkForNewPosts()),
        )
        .subscribe((status, [error]) {
      debugPrint(
        '[RT][Community] posts status=$status error=$error',
      );
    });
  }

  void _stopNewPostsRealtimeSubscription() {
    final channel = _newPostsRealtimeChannel;
    if (channel == null) return;
    _newPostsRealtimeChannel = null;
    Supabase.instance.client.removeChannel(channel);
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
    if (!mounted || _isCheckingForNewPosts) return;

    final store = context.read<CommunityPostsStore>();
    final existingIds = store.posts.map((post) => post.id).toSet();

    _isCheckingForNewPosts = true;
    try {
      await store.refreshPosts();
    } finally {
      _isCheckingForNewPosts = false;
    }

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
