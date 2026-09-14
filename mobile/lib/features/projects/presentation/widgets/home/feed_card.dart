import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_details/project_details_dialog.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/comments_store.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/projects/update_bookmarks_store.dart';
import 'package:blocnet/services/projects/update_likes_store.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_content.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_emphasis.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

enum FeedCardLayout { card, list }

/// A single feed card showing a hunter update in the home screen.
class FeedCard extends StatefulWidget {
  const FeedCard({
    super.key,
    required this.post,
    this.layout = FeedCardLayout.card,
  });

  final Update post;
  final FeedCardLayout layout;

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard>
    with SingleTickerProviderStateMixin {
  bool _isBookmarked = false;
  bool _isCommented = false;
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  int _bookmarkCount = 0;
  UserLevelModel? _resolvedAuthorLevel;
  String? _resolvedAuthorId;
  late final AnimationController _likePulseController;

  Update get post => widget.post;

  void _syncCountsFromPost({bool? likedOverride}) {
    final liked = likedOverride ?? _isLiked;
    final baseLikeCount = post.likesCount;
    _likeCount = liked && baseLikeCount < 1 ? 1 : baseLikeCount;
    _commentCount = post.commentsCount;
    _isCommented = _isCommented || post.isCommented;
    // Don't sync bookmark count from server if we have a local bookmark state
    // because bookmarks are local-only and server always returns 0
    final shouldPreserveLocalCount = _isBookmarked && _bookmarkCount > 0;
    _bookmarkCount = shouldPreserveLocalCount
        ? _bookmarkCount
        : UpdateBookmarksStore.resolveBookmarkCount(
            post.id,
            post.bookmarksCount,
          );
  }

  @override
  void initState() {
    super.initState();
    _likePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _syncCountsFromPost();
    _loadBookmarkState();
    _loadLikeState();
    _syncCommentStateFromStore();
    _ensureAuthorLevel();
  }

  @override
  void didUpdateWidget(covariant FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final postChanged = oldWidget.post.id != widget.post.id;
    final countsChanged = oldWidget.post.likesCount != widget.post.likesCount ||
        oldWidget.post.commentsCount != widget.post.commentsCount ||
        oldWidget.post.bookmarksCount != widget.post.bookmarksCount;

    if (postChanged) {
      _isLiked = false;
      _isCommented = false;
      _likeCount = 0;
      _commentCount = 0;
      _bookmarkCount = 0;
      _resolvedAuthorLevel = null;
      _resolvedAuthorId = null;
      _loadBookmarkState();
      _loadLikeState();
      _ensureAuthorLevel();
    }

    if (postChanged || countsChanged) {
      _syncCountsFromPost();
      _syncCommentStateFromStore();
    }
  }

  /// Resolves the author's level without a network round-trip.
  ///
  /// The updates payload already carries `author.currentLevel`; when it is
  /// missing we only consult the [LevelsStore] cache. Fetching
  /// `/levels/user/:id` per card caused an N+1 on the feed, so no request is
  /// made here. Called from [initState] and [didUpdateWidget], both of which
  /// are followed by a build, so fields are assigned directly.
  void _ensureAuthorLevel() {
    final author = post.admin;
    if (author == null || author.currentLevel != null) return;

    final authorId = author.id.trim();
    if (authorId.isEmpty) return;
    if (_resolvedAuthorId == authorId && _resolvedAuthorLevel != null) return;

    UserLevelModel? cachedLevel;
    try {
      cachedLevel = context.read<LevelsStore>().cachedLevelForUser(authorId);
    } catch (_) {
      // Ignore provider errors in previews/tests where stores are absent.
      return;
    }
    if (cachedLevel == null) return;

    _resolvedAuthorId = authorId;
    _resolvedAuthorLevel = cachedLevel;
  }

  Future<void> _loadBookmarkState() async {
    final bookmarked = await UpdateBookmarksStore.isBookmarked(post.id);
    if (!mounted) return;
    setState(() {
      _isBookmarked = bookmarked;
      // Bookmarks are local-only today; preserve a visible count after reload.
      if (bookmarked && _bookmarkCount < 1) {
        _bookmarkCount = 1;
      }
    });
  }

  Future<void> _loadLikeState() async {
    final liked = await UpdateLikesStore.isLiked(post.id);
    if (!mounted) return;
    setState(() {
      _isLiked = liked;
      _syncCountsFromPost(likedOverride: liked);
    });
  }

  Future<void> _openDetails(
    BuildContext context, {
    bool focusCommentComposer = false,
    bool commentsOnly = false,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      pageBuilder: (context, _, __) => UpdateDetailsDialog(
        id: post.id,
        focusCommentComposer: focusCommentComposer,
        commentsOnly: commentsOnly,
      ),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
    if (!mounted) return;
    _syncCommentStateFromStore();
  }

  void _openAuthorProfile(BuildContext context) {
    final author = post.admin;
    if (author == null) return;
    PublicProfileScreen.showSheet(context, author);
  }

  void _openProjectDetails(BuildContext context) {
    final projectId = post.project?.id ?? post.projectId;
    if (projectId.trim().isEmpty) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProjectDetailsDialog(projectId: projectId);
      },
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  Future<void> _handleLikeTap(BuildContext context) async {
    try {
      HapticFeedback.selectionClick();
      final next = await UpdateLikesStore.toggle(post.id);
      if (!mounted) return;
      setState(() {
        _isLiked = next;
        _likeCount =
            next ? _likeCount + 1 : (_likeCount > 0 ? _likeCount - 1 : 0);
      });
      _likePulseController
        ..stop()
        ..reset()
        ..forward();
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Could not like update right now');
    }
  }

  Future<void> _handleCommentTap(BuildContext context) async {
    HapticFeedback.selectionClick();
    await _openDetails(
      context,
      focusCommentComposer: true,
      commentsOnly: true,
    );
  }

  Future<void> _handleShareTap(BuildContext context) async {
    HapticFeedback.selectionClick();
    await _openShareSheet(context);
  }

  Future<void> _openShareSheet(BuildContext context) async {
    final deepPath = '/updates/${post.id}';
    final webLink =
        'https://blocnet.app/open?path=${Uri.encodeComponent(deepPath)}';
    final shareText = '${post.title}\n$webLink';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: post.title,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Unable to open share options right now.');
    }
  }

  Future<void> _handleBookmarkTap() async {
    try {
      HapticFeedback.selectionClick();
      final next = await UpdateBookmarksStore.toggle(post.id);
      if (!mounted) return;
      final nextCount = next
          ? _bookmarkCount + 1
          : (_bookmarkCount > 0 ? _bookmarkCount - 1 : 0);
      UpdateBookmarksStore.setBookmarkCountOverride(post.id, nextCount);
      setState(() {
        _isBookmarked = next;
        _bookmarkCount = nextCount;
      });
      AppSnackbar.showSuccess(
        context,
        next ? 'Update bookmarked' : 'Bookmark removed',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Could not update bookmark');
    }
  }

  void _syncCommentStateFromStore() {
    try {
      final commentsStore = context.read<CommentsStore>();
      final authStore = context.read<AuthStore>();
      final comments = commentsStore.commentsForUpdate(post.id);
      final userId = authStore.userId?.trim() ?? '';

      var hasCommented = _isCommented;
      if (userId.isNotEmpty) {
        hasCommented = comments.any((comment) => comment.authorId == userId);
      }

      final nextCommentCount =
          comments.length > _commentCount ? comments.length : _commentCount;

      if (_isCommented == hasCommented && _commentCount == nextCommentCount) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _isCommented = hasCommented;
        _commentCount = nextCommentCount;
      });
    } catch (_) {
      // Ignore provider errors in previews/tests where stores are absent.
    }
  }

  @override
  void dispose() {
    _likePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final author = post.admin;
    final project = post.project;
    // A card without an author or a gem cannot be laid out truthfully, and the
    // feed already filters these out; this is the belt for anything that slips
    // through a cache.
    if (author == null || project == null) return const SizedBox.shrink();

    final emphasis = FeedCardEmphasis.of(post.priority);
    final dense = widget.layout == FeedCardLayout.list;
    final pad = dense ? AppSpace.md : AppSpace.lg;
    final edge = context.watch<EdgeEngineStore>().decisionForUpdate(post.id);
    // `ignore` earns no space: a verdict meaning "nothing to do" is not worth
    // a row of a member's screen.
    final showEdge =
        edge != null && edge.recommendedAction.toLowerCase() != 'ignore';

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: DecoratedBox(
        // A card is a row in a stream, not a floating panel: full-bleed, its
        // own padding, and a hairline to the next one. The urgency edge is a
        // border rather than a child, so it needs no height of its own, and it
        // is always 3px — merely transparent when there is no signal — so body
        // text keeps one left margin at every priority.
        decoration: BoxDecoration(
          gradient: emphasis.ground,
          border: Border(
            left: BorderSide(
              color: emphasis.edgeColor ?? Colors.transparent,
              width: 3,
            ),
            bottom: const BorderSide(color: AppColors.borderFaint),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad - 3, pad, pad, pad),
          child: FeedCardContent(
            post: post,
            emphasis: emphasis,
            authorLevel: author.currentLevel ?? _resolvedAuthorLevel,
            dense: dense,
            likeIcon: ScaleTransition(
              scale: TweenSequence<double>([
                TweenSequenceItem(
                  tween: Tween<double>(begin: 1, end: 1.28),
                  weight: 45,
                ),
                TweenSequenceItem(
                  tween: Tween<double>(begin: 1.28, end: 1),
                  weight: 55,
                ),
              ]).animate(_likePulseController),
              child: Icon(
                _isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: AppIcon.md,
                color: _isLiked ? AppColors.primary400 : AppColors.textMuted,
              ),
            ),
            isBookmarked: _isBookmarked,
            isCommented: _isCommented,
            likeCount: _likeCount,
            commentCount: _commentCount,
            bookmarkCount: _bookmarkCount,
            onLike: () => _handleLikeTap(context),
            onComment: () => _handleCommentTap(context),
            onShare: () => _handleShareTap(context),
            onBookmark: _handleBookmarkTap,
            onOpenAuthor: () => _openAuthorProfile(context),
            onOpenProject: () => _openProjectDetails(context),
            onTip: _tipHandler(context),
            edgeSignals: showEdge ? edge.reasonCodes.length : null,
            edgeVerdict: showEdge ? edge.recommendedAction : null,
          ),
        ),
      ),
    );
  }

  /// action row omits the pill rather than showing a dead one.
  VoidCallback? _tipHandler(BuildContext context) {
    final recipientId = post.adminId.toString();
    if (recipientId.trim().isEmpty) return null;
    final myId = context.read<AuthStore>().userId;
    if (myId != null && myId == recipientId) return null;

    return () => TipHunterSheet.show(
          context,
          recipient: TipRecipient(
            userId: recipientId,
            username: post.admin?.username,
            displayName: post.admin?.name,
            avatarUrl: post.admin?.imageUrl,
            isHunterHint: true,
          ),
          contextType: 'update',
          contextId: post.id.toString(),
        );
  }
}
