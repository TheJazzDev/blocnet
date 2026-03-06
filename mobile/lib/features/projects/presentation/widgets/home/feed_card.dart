import 'package:blocnet/app/theme.dart';
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

  Future<void> _ensureAuthorLevel() async {
    final author = post.admin;
    if (author == null) return;
    if (author.currentLevel != null) return;

    final authorId = author.id.trim();
    if (authorId.isEmpty) return;

    final levelsStore = context.read<LevelsStore>();
    final cachedLevel = levelsStore.cachedLevelForUser(authorId);
    if (cachedLevel != null) {
      if (!mounted) return;
      setState(() {
        _resolvedAuthorId = authorId;
        _resolvedAuthorLevel = cachedLevel;
      });
      return;
    }

    if (_resolvedAuthorId == authorId && _resolvedAuthorLevel != null) {
      return;
    }

    final progress = await levelsStore.getUserLevel(authorId);
    if (!mounted) return;
    if (post.admin?.id.trim() != authorId) return;
    if (progress?.currentLevel == null) return;

    setState(() {
      _resolvedAuthorId = authorId;
      _resolvedAuthorLevel = progress!.currentLevel;
    });
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
                    radius: 20,
                    imageUrl: author.imageUrl,
                    fallback: Icon(
                      Icons.person,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                                        size: 14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (roleLabel != null) ...[
                            const SizedBox(width: 8),
                            _FeedRoleChip(label: roleLabel, color: roleColor),
                          ],
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
                        displayUsername,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 12,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openProjectDetails(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 13,
                              color: AppColors.textFaint,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'in ${project.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.custom(
                                  color: AppColors.textMuted,
                                  size: 12,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: priorityColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                post.priority.label.toUpperCase(),
                                style: AppTypography.custom(
                                  color: priorityColor,
                                  size: 9,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (post.secondaryTags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: post.secondaryTags.take(3).map((tag) {
                            return _TagPill(label: tag.name);
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        previewText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: AppColors.textSecondary,
                          size: 13,
                          weight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {},
                        behavior: HitTestBehavior.translucent,
                        child: _ActionRow(
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
                              size: 21,
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

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Stack(
        children: [
          // Subtle glow effect on left side based on priority
          Positioned(
            left: -20,
            top: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    priorityColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main card content
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgSurface,
                  AppColors.bgSurface.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: priorityColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
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
                        padding: const EdgeInsets.all(2),
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
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                                            size: 14,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (roleLabel != null) ...[
                                const SizedBox(width: 8),
                                _FeedRoleChip(
                                  label: roleLabel,
                                  color: roleColor,
                                ),
                              ],
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
                            displayUsername,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.custom(
                              color: AppColors.textMuted,
                              size: 12,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Priority pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
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
                          const SizedBox(width: 5),
                          Text(
                            post.priority.label.toUpperCase(),
                            style: AppTypography.custom(
                              color: priorityColor,
                              size: 9,
                              weight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Project chip with gradient ──
                _ModernProjectChip(
                  project: project,
                  onTap: () => _openProjectDetails(context),
                ),

                const SizedBox(height: 12),

                // ── Secondary tags ──
                if (post.secondaryTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.secondaryTags.take(3).map((tag) {
                      return _TagPill(label: tag.name);
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Update text ──
                Text(
                  previewText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: 13,
                    weight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Action row: like · comment · share | bookmark ──
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.translucent,
                  child: _ActionRow(
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
                        size: 21,
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

class _FeedRoleChip extends StatelessWidget {
  const _FeedRoleChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.85), width: 0.8),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: color,
          size: 9,
          weight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern project chip with gradient and enhanced visuals
// ─────────────────────────────────────────────────────────────────────────────

class _ModernProjectChip extends StatelessWidget {
  const _ModernProjectChip({
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgElevated.withValues(alpha: 0.9),
              AppColors.bgElevated.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary500.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.25),
                    AppColors.primary500.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: project.logo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        project.logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.layers_outlined,
                          size: 16,
                          color: AppColors.primary400,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.layers_outlined,
                      size: 16,
                      color: AppColors.primary400,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 10,
                        color: AppColors.textFaint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project.primaryTag.name,
                          style: AppTypography.custom(
                            color: AppColors.textFaint,
                            size: 11,
                            weight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag pill
// ─────────────────────────────────────────────────────────────────────────────

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  Color _colorForLabel(String lbl) {
    final lower = lbl.toLowerCase();
    if (lower.contains('alpha') || lower.contains('launch')) {
      return AppColors.tagAlpha;
    }
    if (lower.contains('partner')) {
      return AppColors.tagPartnership;
    }
    if (lower.contains('warning') || lower.contains('rug')) {
      return AppColors.tagWarning;
    }
    if (lower.contains('airdrop')) {
      return AppColors.tagAirdrop;
    }
    return AppColors.tagGeneral;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          color: color,
          size: 9,
          weight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern action row with subtle backgrounds
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.likeIcon,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onBookmarkTap,
    required this.isBookmarked,
    required this.isCommented,
    required this.likeCount,
    required this.commentCount,
    required this.bookmarkCount,
  });

  final Widget likeIcon;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onBookmarkTap;
  final bool isBookmarked;
  final bool isCommented;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: likeIcon,
          onTap: onLikeTap,
          count: likeCount,
        ),
        _ActionButton(
          icon: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 21,
            color: isCommented ? AppColors.primary400 : AppColors.textMuted,
          ),
          onTap: onCommentTap,
          count: commentCount,
        ),
        _ActionButton(
          icon: Icon(
            isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            size: 21,
            color: isBookmarked ? AppColors.primary400 : AppColors.textMuted,
          ),
          onTap: onBookmarkTap,
          count: bookmarkCount > 0 ? bookmarkCount : null,
        ),
        _ActionButton(
          icon: Icon(
            Icons.share_outlined,
            size: 21,
            color: AppColors.teal400,
          ),
          onTap: onShareTap,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.count,
  });

  final Widget icon;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '${count!}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
