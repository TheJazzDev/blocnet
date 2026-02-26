import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
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
                  _CommunityTabs(
                    controller: _tabController,
                    accentColor: accent,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _CommunityFeedList(
                          posts: _filterPosts(posts, CommunityTopic.general),
                          bottomPad: bottomPad,
                          controller:
                              _scrollControllers[CommunityTopic.general]!,
                          accentColor: accent,
                          onRefresh: _handleRefresh,
                          onLike: store.toggleLike,
                          onBookmark: store.toggleBookmark,
                        ),
                        _CommunityFeedList(
                          posts: _filterPosts(posts, CommunityTopic.marketTalk),
                          bottomPad: bottomPad,
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

class _CommunityTabs extends StatelessWidget {
  const _CommunityTabs({
    required this.controller,
    required this.accentColor,
  });

  final TabController controller;
  final Color accentColor;

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
        labelColor: accentColor,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: accentColor,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.custom(
          size: 13,
          color: Colors.black,
          weight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.custom(
          size: 13,
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Market Talk'),
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
    required this.accentColor,
    required this.onRefresh,
    required this.onLike,
    required this.onBookmark,
  });

  final List<CommunityPost> posts;
  final double bottomPad;
  final ScrollController controller;
  final Color accentColor;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String postId) onLike;
  final Future<void> Function(String postId) onBookmark;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return RefreshIndicator(
        color: accentColor,
        backgroundColor: AppColors.bgSurface,
        onRefresh: onRefresh,
        child: ListView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 32, 16, bottomPad),
          children: [
            SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'No posts in this section yet.',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 13,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      backgroundColor: AppColors.bgSurface,
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
        itemCount: posts.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppColors.borderSubtle.withValues(alpha: 0.8),
        ),
        itemBuilder: (context, index) => _CommunityCard(
          post: posts[index],
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.communityDiscussion,
            arguments: posts[index].id,
          ),
          onLike: () => onLike(posts[index].id),
          onBookmark: () => onBookmark(posts[index].id),
        ),
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
    final username = _formatUsername(
      admin?.username,
      fallbackName: displayName,
    );
    final role = _resolveRoleLabel(admin);
    final roleColor = _resolveRoleColor(role);
    final badge = admin?.primaryBadge;
    final content = post.content.trim();

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openAuthorProfile(context),
                  behavior: HitTestBehavior.opaque,
                  child: AppAvatar(
                    radius: 22,
                    imageUrl: admin?.imageUrl,
                    fallback: _avatarFallback(displayName, roleColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () => _openAuthorProfile(context),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.custom(
                                        color: AppColors.textPrimary,
                                        size: 14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: 6),
                                    BadgeIcon(
                                      badge: badge,
                                      size: BadgeSize.small,
                                      showTooltip: false,
                                    ),
                                  ],
                                  if (role != null) ...[
                                    const SizedBox(width: 6),
                                    _RoleChip(label: role, color: roleColor),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            getTimeStamp(post.createdAt),
                            style: AppTypography.custom(
                              color: AppColors.textFaint,
                              size: 11,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 12,
                          weight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MentionText(
                        text: content,
                        style: AppTypography.custom(
                          color: AppColors.textSecondary,
                          size: 13,
                          height: 1.6,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CommunityAction(
                    icon: post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    value: '${post.likesCount}',
                    color: post.isLiked
                        ? AppColors.warning500
                        : AppColors.textMuted,
                    onTap: onLike,
                  ),
                ),
                Expanded(
                  child: _CommunityAction(
                    icon: Icons.mode_comment_outlined,
                    value: '${post.commentsCount}',
                    color: AppColors.textMuted,
                    onTap: onTap,
                  ),
                ),
                Expanded(
                  child: _CommunityAction(
                    icon: post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    value: '',
                    color: post.isBookmarked
                        ? AppColors.primary400
                        : AppColors.textMuted,
                    onTap: onBookmark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name, Color color) {
    final firstChar = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    return Text(
      firstChar,
      style: AppTypography.custom(
        color: color,
        size: 18,
        weight: FontWeight.w800,
      ),
    );
  }

  String _formatUsername(String? value, {required String fallbackName}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized.startsWith('@') ? normalized : '@$normalized';
    }

    final fallback = fallbackName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (fallback.isEmpty) return '@member';
    return '@$fallback';
  }

  String? _resolveRoleLabel(Admin? admin) {
    final roles = (admin?.roles ?? const <String>[])
        .map((role) => role.toLowerCase())
        .toSet();
    if (roles.contains('owner') || roles.contains('admin')) return 'ADMIN';
    if (roles.contains('hunter')) return 'HUNTER';
    return null;
  }

  Color _resolveRoleColor(String? role) {
    if (role == 'HUNTER') {
      return const Color(0xFFC084FC);
    }
    if (role == 'ADMIN') {
      return AppColors.primary400;
    }
    return AppColors.primary400;
  }
}

class _CommunityAction extends StatelessWidget {
  const _CommunityAction({
    required this.icon,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        if (value.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.custom(
              color: color,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.center,
          child: content,
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
        style: AppTypography.custom(
          color: color,
          size: 9,
          weight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
