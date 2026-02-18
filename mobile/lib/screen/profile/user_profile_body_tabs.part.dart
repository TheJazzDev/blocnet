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
                      color: isActive ? AppColors.teal400 : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                height: 44,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isActive ? AppColors.teal400 : AppColors.textFaint,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: const [
          _BookmarkItem(
            title: 'Gem Alert: New L2 Launching',
            subtitle:
                'Detailed breakdown of the upcoming zkEVM scaling solution.',
            author: '@AlphaHunter',
            tag: 'Analysis',
            timeAgo: '2h ago',
          ),
          _BookmarkItem(
            title: 'Yield Farming Strategy v2',
            subtitle: 'Optimizing stablecoin pairs on Curve for maximum APY.',
            author: '@DeFiDegan',
            tag: 'Strategy',
            timeAgo: '1d ago',
          ),
          SizedBox(height: 16),
          _BookmarksEmptyState(),
        ],
      ),
    );
  }
}

class _BookmarksEmptyState extends StatelessWidget {
  const _BookmarksEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.bookmark_add_outlined, size: 36, color: AppColors.textFaint),
        const SizedBox(height: 8),
        Text(
          'Explore more projects to add bookmarks',
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _BookmarkItem extends StatelessWidget {
  const _BookmarkItem({
    required this.title,
    required this.subtitle,
    required this.author,
    required this.tag,
    required this.timeAgo,
  });

  final String title;
  final String subtitle;
  final String author;
  final String tag;
  final String timeAgo;

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
                  AppColors.primary500.withValues(alpha: 0.2),
                  AppColors.teal500.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(Icons.article_outlined, size: 22, color: AppColors.textFaint),
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
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(
                        color: AppColors.textFaint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      author,
                      style: GoogleFonts.inter(
                        color: AppColors.textFaint,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          color: AppColors.textFaint,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistTab extends StatelessWidget {
  const _WatchlistTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Icon(Icons.visibility_outlined, size: 36, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(
            'No watchlist items yet',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 36, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(
            'No activity history yet',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
