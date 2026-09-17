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
import 'package:blocnet/services/projects/update_reactions_store.dart';
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
  bool _isCommented = false;
  int _commentCount = 0;
  UserLevelModel? _resolvedAuthorLevel;
  String? _resolvedAuthorId;
  late final AnimationController _likePulseController;

  Update get post => widget.post;

  /// Likes and saves live on the server; this store layers the member's
  /// in-flight toggles over the post. Null only in previews/tests that do not
  /// provide it, where the card shows the post as it came.
  UpdateReactionsStore? _reactionsStore(BuildContext context,
      {bool listen = false}) {
    try {
      return listen
          ? context.watch<UpdateReactionsStore>()
          : context.read<UpdateReactionsStore>();
    } catch (_) {
      return null;
    }
  }

  void _syncCountsFromPost() {
    _commentCount = post.commentsCount;
    _isCommented = _isCommented || post.isCommented;
  }

  @override
  void initState() {
    super.initState();
    _likePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _syncCountsFromPost();
    _syncCommentStateFromStore();
    _ensureAuthorLevel();
  }

  @override
  void didUpdateWidget(covariant FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final postChanged = oldWidget.post.id != widget.post.id;
    final countsChanged =
        oldWidget.post.commentsCount != widget.post.commentsCount;

    if (postChanged) {
      _isCommented = false;
      _commentCount = 0;
      _resolvedAuthorLevel = null;
      _resolvedAuthorId = null;
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
    final store = _reactionsStore(context);
    if (store == null) return;
    HapticFeedback.selectionClick();
    // The store flips the heart and count at once; the pulse plays with it.
    if (!store.isLiked(post)) {
      _likePulseController
        ..stop()
        ..reset()
        ..forward();
    }
    try {
      await store.toggleLike(post);
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
    final store = _reactionsStore(context);
    if (store == null) return;
    HapticFeedback.selectionClick();
    try {
      final next = await store.toggleBookmark(post);
      if (!mounted) return;
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

    final reactions = _reactionsStore(context, listen: true);
    final isLiked = reactions?.isLiked(post) ?? post.likedByMe;
    final likeCount = reactions?.likesCount(post) ?? post.likesCount;
    final isBookmarked = reactions?.isBookmarked(post) ?? post.bookmarkedByMe;
    final bookmarkCount =
        reactions?.bookmarksCount(post) ?? post.bookmarksCount;

    final emphasis = FeedCardEmphasis.of(post.priority);
    final dense = widget.layout == FeedCardLayout.list;
    final edge = context.watch<EdgeEngineStore>().decisionForUpdate(post.id);
    // `ignore` earns no space: a verdict meaning "nothing to do" is not worth
    // a row of a member's screen.
    final showEdge =
        edge != null && edge.recommendedAction.toLowerCase() != 'ignore';

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        // List mode is a plain row between dividers; card mode is a flat
        // surface with a hairline border, as the feed has always drawn them.
        margin: dense ? null : const EdgeInsets.only(bottom: AppSpace.md),
        padding: dense
            ? const EdgeInsets.symmetric(vertical: AppSpace.md)
            : AppSpace.card,
        decoration: dense
            ? const BoxDecoration(color: Colors.transparent)
            : const BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadius.lg,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.borderSubtle),
                ),
              ),
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
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: AppIcon.md,
              color: isLiked ? AppColors.primary400 : AppColors.textMuted,
            ),
          ),
          isBookmarked: isBookmarked,
          isCommented: _isCommented,
          likeCount: likeCount,
          commentCount: _commentCount,
          bookmarkCount: bookmarkCount,
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
