import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_details/project_details_dialog.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/comments_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/projects/update_bookmarks_store.dart';
import 'package:blocnet/services/projects/update_likes_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_role_chip.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_project_chip.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_tag_pill.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_action_row.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_card_emphasis.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blocnet/app/typography.dart';
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

  Widget _buildListLayout({
    required BuildContext context,
    required Project project,
    required String previewText,
    required String? roleLabel,
    required Color roleColor,
    required Color priorityColor,
    required String displayUsername,
    required UserLevelModel? authorLevel,
  }) {
    final author = post.admin!;
    return InkWell(
      onTap: () => _openDetails(context),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
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
                    radius: 20,
                    imageUrl: author.imageUrl,
                    fallback: Icon(
                      Icons.person,
                      size: AppIcon.md,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openAuthorProfile(context),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: UserNameWithLevelIcon(
                                      name: author.name,
                                      currentLevel: authorLevel,
                                      levelBadgeSize: LevelBadgeSize.small,
                                      textStyle: AppTypography.custom(
                                        color: AppColors.textPrimary,
                                        size: AppText.bodySize,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (roleLabel != null) ...[
                            const SizedBox(width: AppSpace.sm),
                            FeedRoleChip(label: roleLabel, color: roleColor),
                          ],
                          const SizedBox(width: AppSpace.sm),
                          Text(
                            getTimeStamp(post.createdAt),
                            style: AppTypography.custom(
                              color: AppColors.textFaint,
                              size: AppText.captionSize,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.hair),
                      Text(
                        displayUsername,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: AppText.labelSize,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      GestureDetector(
                        onTap: () => _openProjectDetails(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: AppIcon.xs,
                              color: AppColors.textFaint,
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                'in ${project.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.custom(
                                  color: AppColors.textMuted,
                                  size: AppText.labelSize,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.hair,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.fullValue),
                                border: Border.all(
                                  color: priorityColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                post.priority.label.toUpperCase(),
                                style: AppTypography.custom(
                                  color: priorityColor,
                                  size: AppText.captionSize,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (post.secondaryTags.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.md),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: post.secondaryTags.take(3).map((tag) {
                            return FeedTagPill(label: tag.name);
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: AppSpace.md),
                      Text(
                        previewText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: AppColors.textSecondary,
                          size: AppText.bodySize,
                          weight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      GestureDetector(
                        onTap: () {},
                        behavior: HitTestBehavior.translucent,
                        child: FeedActionRow(
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
                              color: _isLiked
                                  ? AppColors.primary400
                                  : AppColors.textMuted,
                            ),
                          ),
                          onLikeTap: () => _handleLikeTap(context),
                          onCommentTap: () => _handleCommentTap(context),
                          onShareTap: () => _handleShareTap(context),
                          onBookmarkTap: _handleBookmarkTap,
                          isBookmarked: _isBookmarked,
                          isCommented: _isCommented,
                          likeCount: _likeCount,
                          commentCount: _commentCount,
                          bookmarkCount: _bookmarkCount,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final author = post.admin!;
    final project = post.project!;
    final authorLevel = author.currentLevel ?? _resolvedAuthorLevel;
    final displayUsername = _displayUsername(author.username, author.name);
    final priorityColor = post.priority.color;
    final roleLabel = author.displayRoleLabel;
    final roleColor =
        roleLabel == 'HUNTER' ? const Color(0xFFC084FC) : AppColors.primary400;
    final previewText = post.description.trim().isEmpty
        ? post.content.trim()
        : post.description.trim();
    final title = post.title.trim();
    // Some updates carry a title that just restates the opening of the body.
    // Showing both then reads as a stutter, so the title wins and the body is
    // left to the detail view.
    final showTitle = title.isNotEmpty &&
        !previewText.toLowerCase().startsWith(title.toLowerCase());

    if (widget.layout == FeedCardLayout.list) {
      return _buildListLayout(
        context: context,
        project: project,
        previewText: previewText,
        roleLabel: roleLabel,
        roleColor: roleColor,
        priorityColor: priorityColor,
        displayUsername: displayUsername,
        authorLevel: authorLevel,
      );
    }

    // Priority drives the whole card, not a pill in its corner. See
    // [FeedCardEmphasis]: an urgent update keeps its chronological place and
    // simply becomes a heavier object.
    final emphasis = FeedCardEmphasis.of(post.priority);

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: DecoratedBox(
        // A card is a row in a stream, not a floating panel: full-bleed, its
        // own padding, and a hairline to the next one.
        decoration: BoxDecoration(
          gradient: emphasis.ground,
          border: const Border(
            bottom: BorderSide(color: AppColors.borderFaint),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The card's only signal red. 3px, full height, so it reads as
            // mass rather than as a badge.
            SizedBox(
              width: 3,
              child: emphasis.edgeColor == null
                  ? null
                  : ColoredBox(color: emphasis.edgeColor!),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg - 3,
                  AppSpace.lg,
                  AppSpace.lg,
                  AppSpace.lg,
                ),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: avatar + author + timestamp + priority pill ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _openAuthorProfile(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(AppSpace.hair),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              priorityColor.withValues(alpha: 0.3),
                              priorityColor.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                        child: AppAvatar(
                          radius: 20,
                          imageUrl: author.imageUrl,
                          fallback: Icon(
                            Icons.person,
                            size: AppIcon.md,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openAuthorProfile(context),
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: UserNameWithLevelIcon(
                                          name: author.name,
                                          currentLevel: authorLevel,
                                          levelBadgeSize: LevelBadgeSize.small,
                                          textStyle: AppTypography.custom(
                                            color: AppColors.textPrimary,
                                            size: AppText.bodySize,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (roleLabel != null) ...[
                                const SizedBox(width: AppSpace.sm),
                                FeedRoleChip(
                                  label: roleLabel,
                                  color: roleColor,
                                ),
                              ],
                              const SizedBox(width: AppSpace.sm),
                              Text(
                                getTimeStamp(post.createdAt),
                                style: AppTypography.custom(
                                  color: AppColors.textFaint,
                                  size: AppText.captionSize,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.hair),
                          Text(
                            displayUsername,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.custom(
                              color: AppColors.textMuted,
                              size: AppText.labelSize,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Priority pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md, vertical: AppSpace.xs),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadius.fullValue),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            post.priority.label.toUpperCase(),
                            style: AppTypography.custom(
                              color: priorityColor,
                              size: AppText.captionSize,
                              weight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpace.lg),

                // ── Project chip with gradient ──
                FeedProjectChip(
                  project: project,
                  onTap: () => _openProjectDetails(context),
                ),

                // ── Title ──
                // The feed used to throw the title away and show only the
                // body. It is the most informative line an update has, so it
                // now leads, and it is the thing that grows with priority.
                if (showTitle) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: emphasis.titleSize,
                      weight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],

                // ── Body ──
                if (previewText.isNotEmpty) ...[
                  SizedBox(height: showTitle ? AppSpace.xs : AppSpace.md),
                  Text(
                    previewText,
                    maxLines: showTitle ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: AppText.bodySize,
                      weight: FontWeight.w400,
                      height: 1.55,
                    ),
                  ),
                ],

                // ── Secondary tags ──
                // Below the body, not above it: they are how an update is
                // classified, which matters after reading it, not before.
                if (post.secondaryTags.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Wrap(
                    spacing: AppSpace.xs + 2,
                    runSpacing: AppSpace.xs + 2,
                    children: post.secondaryTags
                        .take(3)
                        .map((tag) => FeedTagPill(label: tag.name))
                        .toList(),
                  ),
                ],

                const SizedBox(height: AppSpace.lg),

                // ── Action row: like · comment · share | bookmark ──
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.translucent,
                  child: FeedActionRow(
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
                        color: _isLiked
                            ? AppColors.primary400
                            : AppColors.textMuted,
                      ),
                    ),
                    onLikeTap: () => _handleLikeTap(context),
                    onCommentTap: () => _handleCommentTap(context),
                    onShareTap: () => _handleShareTap(context),
                    onBookmarkTap: _handleBookmarkTap,
                    isBookmarked: _isBookmarked,
                    isCommented: _isCommented,
                    likeCount: _likeCount,
                    commentCount: _commentCount,
                    bookmarkCount: _bookmarkCount,
                    onTipTap: _tipHandler(context),
                  ),
                ),
              ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the tip sheet for this update's author, or returns null when there
  /// is nobody to tip: no resolvable author, or the reader is the author. The
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

  String _displayUsername(String raw, String fallbackName) {
    final normalizedRaw = raw.trim();
    if (normalizedRaw.isNotEmpty) {
      return normalizedRaw.startsWith('@') ? normalizedRaw : '@$normalizedRaw';
    }
    return '@${fallbackName.toLowerCase().replaceAll(' ', '_')}';
  }
}
