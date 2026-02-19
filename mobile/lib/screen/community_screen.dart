import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final TabController _tabController;
  final Map<CommunityTopic, ScrollController> _scrollControllers = {
    CommunityTopic.general: ScrollController(),
    CommunityTopic.marketTalk: ScrollController(),
    CommunityTopic.introductions: ScrollController(),
  };
  final Set<String> _pendingNewPostIds = <String>{};
  Timer? _newPostsPollTimer;
  bool _isCheckingForNewPosts = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController = TabController(length: 3, vsync: Scaffold.of(context));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: NavigatorState());
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
    _newPostsPollTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _checkForNewPosts(),
    );
  }

  @override
  void dispose() {
    _newPostsPollTimer?.cancel();
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
      case 2:
        return CommunityTopic.introductions;
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

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.communityCreatePost),
        backgroundColor: AppColors.primary500,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      body: Consumer<CommunityPostsStore>(
        builder: (context, store, _) {
          final posts = store.posts;

          if (store.isFetchingPosts && posts.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary400,
                strokeWidth: 2,
              ),
            );
          }

          if (posts.isEmpty) {
            return const Center(
              child: Text('No community updates yet.'),
            );
          }

          final pendingCount = _pendingCountForActiveTopic(posts);

          return Stack(
            children: [
              Column(
                children: [
                  _CommunityTabs(controller: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _CommunityFeedList(
                          posts: _filterPosts(posts, CommunityTopic.general),
                          bottomPad: bottomPad,
                          controller: _scrollControllers[CommunityTopic.general]!,
                          onLike: store.toggleLike,
                          onBookmark: store.toggleBookmark,
                        ),
                        _CommunityFeedList(
                          posts: _filterPosts(posts, CommunityTopic.marketTalk),
                          bottomPad: bottomPad,
                          controller:
                              _scrollControllers[CommunityTopic.marketTalk]!,
                          onLike: store.toggleLike,
                          onBookmark: store.toggleBookmark,
                        ),
                        _CommunityFeedList(
                          posts:
                              _filterPosts(posts, CommunityTopic.introductions),
                          bottomPad: bottomPad,
                          controller:
                              _scrollControllers[CommunityTopic.introductions]!,
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
                          color: AppColors.primary500,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$pendingCount new posts',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
    if (tab == CommunityTopic.general) {
      return posts;
    }

    return posts.where((post) => post.topic == tab).toList();
  }
}

class _CommunityTabs extends StatelessWidget {
  const _CommunityTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: TabBar(
        controller: controller,
        labelColor: AppColors.primary400,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary400,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Market Talk'),
          Tab(text: 'Introductions'),
        ],
      ),
    );
  }
}

class _CommunityFeedList extends StatelessWidget {
  const _CommunityFeedList({
    required this.posts,
    required this.bottomPad,
    required this.controller,
    required this.onLike,
    required this.onBookmark,
  });

  final List<CommunityPost> posts;
  final double bottomPad;
  final ScrollController controller;
  final Future<void> Function(String postId) onLike;
  final Future<void> Function(String postId) onBookmark;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'No posts in this section yet.',
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _CommunityCard(
        post: posts[index],
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.communityDiscussion,
          arguments: posts[index].id,
        ),
        onLike: () => onLike(posts[index].id),
        onBookmark: () => onBookmark(posts[index].id),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onBookmark,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onBookmark;

  void _openAuthorProfile(BuildContext context) {
    final admin = post.admin;
    if (admin == null) return;
    PublicProfileScreen.showSheet(context, admin);
  }

  @override
  Widget build(BuildContext context) {
    final admin = post.admin;
    final displayName =
        admin?.name.trim().isNotEmpty == true ? admin!.name : 'Blocnet User';
    final role = _resolveRole(post);
    final roleColor =
        role == 'HUNTER' ? const Color(0xFFC084FC) : AppColors.primary400;
    final content = post.content.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openAuthorProfile(context),
                  behavior: HitTestBehavior.opaque,
                  child: _Avatar(
                      adminName: displayName, imageUrl: admin?.imageUrl),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => _openAuthorProfile(context),
                                    behavior: HitTestBehavior.opaque,
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _RoleChip(label: role, color: roleColor),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            getTimeStamp(post.createdAt),
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 11),
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_up_alt_outlined,
                        size: 20,
                        color: post.isLiked
                            ? AppColors.primary400
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${post.likesCount}',
                        style: GoogleFonts.inter(
                          color: post.isLiked
                              ? AppColors.primary400
                              : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Icon(Icons.mode_comment_outlined,
                    size: 20, color: AppColors.textMuted),
                const SizedBox(width: 7),
                Text(
                  '${post.commentsCount}',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onBookmark,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 20,
                    color: post.isBookmarked
                        ? AppColors.primary400
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _resolveRole(CommunityPost post) {
    final raw = (post.admin?.username ?? post.admin?.name ?? '').toLowerCase();
    if (raw.contains('hunter')) return 'HUNTER';
    return 'USER';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.adminName, required this.imageUrl});

  final String adminName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.bgElevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasNetworkImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    final firstChar = adminName.isNotEmpty ? adminName[0].toUpperCase() : 'B';
    return Center(
      child: Text(
        firstChar,
        style: GoogleFonts.inter(
          color: AppColors.primary400,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.9), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
