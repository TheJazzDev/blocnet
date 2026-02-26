part of 'user_profile_body.dart';

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isActive = i == activeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isActive ? AppColors.userAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                height: 44,
                child: Text(
                  label,
                  style: AppTypography.custom(
                    color:
                        isActive ? AppColors.userAccent : AppColors.textFaint,
                    size: 13,
                    weight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BookmarksTab extends StatefulWidget {
  const _BookmarksTab();

  @override
  State<_BookmarksTab> createState() => _BookmarksTabState();
}

class _BookmarksTabState extends State<_BookmarksTab> {
  Set<String> _bookmarkedIds = <String>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarkIds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UpdatesStore>().fetchUpdatesOnce();
    });
  }

  Future<void> _loadBookmarkIds() async {
    final bookmarkedIds = await UpdateBookmarksStore.bookmarkedIds();
    if (!mounted) return;
    setState(() {
      _bookmarkedIds = bookmarkedIds;
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(String updateId) async {
    await UpdateBookmarksStore.remove(updateId);
    await _loadBookmarkIds();
  }

  @override
  Widget build(BuildContext context) {
    final updatesStore = context.watch<UpdatesStore>();
    final bookmarks = updatesStore.updates
        .where((update) => _bookmarkedIds.contains(update.id))
        .toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    if ((_isLoading || updatesStore.isFetching) && bookmarks.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.userAccent,
          strokeWidth: 2,
        ),
      );
    }

    if (bookmarks.isEmpty) {
      return const _BookmarksEmptyState();
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final update = bookmarks[index];
        return _BookmarkedUpdateItem(
          update: update,
          onRemove: () => _removeBookmark(update.id),
        );
      },
    );
  }
}

class _BookmarksEmptyState extends StatelessWidget {
  const _BookmarksEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_add_outlined,
                size: 36, color: AppColors.textFaint),
            const SizedBox(height: 8),
            Text(
              'Bookmark updates to save them here',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkedUpdateItem extends StatelessWidget {
  const _BookmarkedUpdateItem({
    required this.update,
    required this.onRemove,
  });

  final Update update;
  final VoidCallback onRemove;

  void _openUpdate(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      pageBuilder: (context, _, __) => UpdateDetailsDialog(id: update.id),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, _, child) {
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

  @override
  Widget build(BuildContext context) {
    final projectName = update.project?.name ?? 'Project';
    final preview = update.description.trim().isEmpty
        ? update.content.trim()
        : update.description.trim();

    return GestureDetector(
      onTap: () => _openUpdate(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.userAccent.withValues(alpha: 0.2),
                    AppColors.userAccent.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: AppColors.textFaint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          update.title,
                          style: AppTypography.custom(
                            color: AppColors.textPrimary,
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getTimeStamp(update.createdAt),
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: 10,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 11,
                      weight: FontWeight.w400,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        projectName,
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: 10,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onRemove,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.bookmark_remove_outlined,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistTab extends StatelessWidget {
  const _WatchlistTab();

  @override
  Widget build(BuildContext context) {
    final profileStore = context.watch<UserProfileStore>();
    final watchlist = profileStore.watchlist;

    if (profileStore.isLoadingWatchlist && watchlist.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.userAccent,
          strokeWidth: 2,
        ),
      );
    }

    if (watchlist.isEmpty) {
      return const _WatchlistEmptyState();
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: watchlist.length,
      itemBuilder: (context, index) {
        return _WatchlistItem(project: watchlist[index]);
      },
    );
  }
}

class _WatchlistEmptyState extends StatelessWidget {
  const _WatchlistEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined,
                size: 36, color: AppColors.textFaint),
            const SizedBox(height: 8),
            Text(
              'No watchlist items yet',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistItem extends StatelessWidget {
  const _WatchlistItem({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  project.primaryTag.name,
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 10,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            project.description,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 11,
              weight: FontWeight.w400,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline, size: 14, color: AppColors.textFaint),
              const SizedBox(width: 5),
              Text(
                '${project.followersCount} followers',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final profileStore = context.watch<UserProfileStore>();
    final activityItems = profileStore.activity;

    if (profileStore.isLoadingActivity && activityItems.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.userAccent,
          strokeWidth: 2,
        ),
      );
    }

    if (activityItems.isEmpty) {
      return const _HistoryEmptyState();
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: activityItems.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Activity',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          );
        }
        return _HistoryItem(item: activityItems[index - 1]);
      },
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 36, color: AppColors.textFaint),
            const SizedBox(height: 8),
            Text(
              'No activity history yet',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: AppColors.userAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  getTimeStamp(item.createdAt),
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 10,
                    weight: FontWeight.w400,
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
