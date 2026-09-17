import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/community/presentation/widgets/community_feed_list.dart';
import 'package:blocnet/features/community/presentation/widgets/community_tabs.dart';
import 'package:blocnet/features/community/presentation/widgets/feed/community_new_items_pill.dart';
import 'package:blocnet/features/community/presentation/widgets/feed/community_save_toggle.dart';
import 'package:blocnet/features/community/presentation/widgets/moderation/moderation_actions.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/shared/application/feed/feed_sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Community tab: General and Market Talk, new-post polling, and the
/// compose button.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  static const _topics = [CommunityTopic.general, CommunityTopic.marketTalk];

  late final TabController _tabController =
      TabController(length: _topics.length, vsync: this);
  final Map<CommunityTopic, ScrollController> _scrollControllers = {
    for (final topic in _topics) topic: ScrollController(),
  };
  final Set<String> _pendingNewPostIds = <String>{};
  final FeedSyncController _feedSync =
      FeedSyncController(debugLabel: 'Community');
  final CommunityModerationApiRepository _moderationRepository =
      CommunityModerationApiRepository();

  CommunityTopic get _activeTopic => _topics[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(_clearPendingIfAtTop);
    });
    for (final controller in _scrollControllers.values) {
      controller.addListener(_handleScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CommunityPostsStore>().fetchPostsOnce();
    });
    _feedSync.start(
      realtimeEnabled: AppConfig.isSupabaseConfigured,
      pollInterval: const Duration(seconds: 12),
      channelName: 'community-new-posts',
      table: 'CommunityPost',
      onSyncRequested: _checkForNewPosts,
    );
  }

  @override
  void dispose() {
    _feedSync.dispose();
    for (final controller in _scrollControllers.values) {
      controller
        ..removeListener(_handleScroll)
        ..dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  void _clearPendingIfAtTop() {
    if (_isActiveListNearTop()) _pendingNewPostIds.clear();
  }

  void _handleScroll() {
    if (_pendingNewPostIds.isNotEmpty && _isActiveListNearTop()) {
      setState(_pendingNewPostIds.clear);
    }
  }

  bool _isActiveListNearTop() {
    final controller = _scrollControllers[_activeTopic];
    if (controller == null || !controller.hasClients) return true;
    return controller.offset < 80;
  }

  Future<void> _checkForNewPosts() async {
    if (!mounted) return;
    final store = context.read<CommunityPostsStore>();
    final existing = store.posts.map((post) => post.id).toSet();
    await store.refreshPosts();
    if (!mounted || existing.isEmpty) return;
    final fresh = store.posts
        .where((post) => !existing.contains(post.id))
        .map((post) => post.id);
    if (fresh.isEmpty || _isActiveListNearTop()) return;
    setState(() => _pendingNewPostIds.addAll(fresh));
  }

  Future<void> _jumpToLatest() async {
    final controller = _scrollControllers[_activeTopic];
    if (controller != null && controller.hasClients) {
      await controller.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(_pendingNewPostIds.clear);
  }

  Future<void> _refresh() async {
    await context.read<CommunityPostsStore>().refreshPosts();
    if (mounted) setState(_pendingNewPostIds.clear);
  }

  Future<void> _compose() async {
    final result =
        await Navigator.of(context).pushNamed(AppRoutes.communityCreatePost);
    if (result is! CommunityTopic || !mounted) return;
    final target = _topics.indexOf(result);
    if (target >= 0 && _tabController.index != target) {
      _tabController.animateTo(target);
    }
    // The new post is at the top of its list; show it.
    final controller = _scrollControllers[result];
    if (controller != null && controller.hasClients) controller.jumpTo(0);
  }

  List<CommunityPost> _postsFor(List<CommunityPost> posts, CommunityTopic t) =>
      posts.where((post) => post.topic == t).toList();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final store = context.watch<CommunityPostsStore>();
    final viewMode = context.watch<FeedViewModeStore>().mode;
    final accent = AppColors.accentForSpace(auth.isInHunterSpace);
    final onAccent = AppColors.onAccentForSpace(auth.isInHunterSpace);
    final canModerate = auth.canAccessCommunityStaffTools;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;
    final posts = store.posts;
    final pending = _postsFor(posts, _activeTopic)
        .where((post) => _pendingNewPostIds.contains(post.id))
        .length;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      floatingActionButton: FloatingActionButton(
        tooltip: 'New post',
        onPressed: _compose,
        backgroundColor: accent,
        elevation: 0,
        child: Icon(Icons.add_rounded, color: onAccent),
      ),
      body: Column(
        children: [
          CommunityTabs(controller: _tabController, accentColor: accent),
          Expanded(
            child: store.isFetchingPosts && posts.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 2,
                    ),
                  )
                : Stack(
                    children: [
                      TabBarView(
                        controller: _tabController,
                        children: [
                          for (final topic in _topics)
                            CommunityFeedList(
                              posts: _postsFor(posts, topic),
                              error: store.postsError,
                              bottomPad: bottomPad,
                              mode: viewMode,
                              controller: _scrollControllers[topic]!,
                              accentColor: accent,
                              onRefresh: _refresh,
                              onLike: store.toggleLike,
                              onBookmark: (id) =>
                                  toggleCommunitySave(context, id),
                              onModeratePost: !canModerate
                                  ? null
                                  : (postId, decision) => applyPostModeration(
                                        context,
                                        repository: _moderationRepository,
                                        postId: postId,
                                        decision: decision,
                                      ),
                              canArchiveModeration: auth.isCommunityAdmin,
                            ),
                        ],
                      ),
                      if (pending > 0)
                        Positioned(
                          top: AppSpace.sm,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: CommunityNewItemsPill(
                              count: pending,
                              noun: 'post',
                              onTap: _jumpToLatest,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
