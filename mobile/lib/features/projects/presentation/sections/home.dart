import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/sections/explore/explore.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/top_hunters_row.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Section _activeSection = Sections.forYou;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ProjectsStore>(context, listen: false).fetchProjectsOnce();
      Provider.of<UpdatesStore>(context, listen: false).fetchUpdatesOnce();
    });
  }

  void _onTabChanged(Section section) {
    if (_activeSection == section) return;
    setState(() => _activeSection = section);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _FeedTabDelegate(
              activeSection: _activeSection,
              onTabChanged: _onTabChanged,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: TopHuntersRow()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          Consumer<UpdatesStore>(
            builder: (context, store, _) {
              final enrichedPosts = store.posts
                  .where(
                    (post) => post.project != null && post.admin != null,
                  )
                  .toList();

              if (_activeSection == Sections.forYou) {
                if (enrichedPosts.isEmpty) {
                  return const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _EmptyFeed()),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => FeedCard(post: enrichedPosts[index]),
                      childCount: enrichedPosts.length,
                    ),
                  ),
                );
              }

              return SliverToBoxAdapter(
                  child: ExploreSection(allPosts: store.posts));
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed tab bar: Updates · General (underline style)
// ─────────────────────────────────────────────────────────────────────────────

class _FeedTabDelegate extends SliverPersistentHeaderDelegate {
  const _FeedTabDelegate({
    required this.activeSection,
    required this.onTabChanged,
  });

  final Section activeSection;
  final ValueChanged<Section> onTabChanged;

  static const double _height = 44.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_FeedTabDelegate oldDelegate) =>
      oldDelegate.activeSection != activeSection;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _FeedTabBar(
      activeSection: activeSection,
      onTabChanged: onTabChanged,
    );
  }
}

class _FeedTabBar extends StatelessWidget {
  const _FeedTabBar({
    required this.activeSection,
    required this.onTabChanged,
  });

  final Section activeSection;
  final ValueChanged<Section> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Updates',
            isActive: activeSection == Sections.forYou,
            onTap: () => onTabChanged(Sections.forYou),
          ),
          _Tab(
            label: 'General',
            isActive: activeSection == Sections.explore,
            onTap: () => onTabChanged(Sections.explore),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty feed state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 36,
            color: AppColors.textFaint,
          ),
          const SizedBox(height: 10),
          Text(
            'No updates yet',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hunter intel will appear here when updates are posted.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
