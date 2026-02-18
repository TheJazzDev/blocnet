import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'discover_projects.dart';
import 'your_projects.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  Section _activeSection = Sections.yourProjects;

  void _onTabChanged(Section section) {
    if (_activeSection == section) return;
    setState(() => _activeSection = section);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: CustomScrollView(
        slivers: [
          // Sticky underline tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _DiscoverTabDelegate(
              activeSection: _activeSection,
              onTabChanged: _onTabChanged,
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: _activeSection == Sections.yourProjects
                ? const _YourGemsWrapper()
                : const DiscoverProjectsSection(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverTabDelegate extends SliverPersistentHeaderDelegate {
  const _DiscoverTabDelegate({
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
  bool shouldRebuild(_DiscoverTabDelegate oldDelegate) =>
      oldDelegate.activeSection != activeSection;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _DiscoverTabBar(
      activeSection: activeSection,
      onTabChanged: onTabChanged,
    );
  }
}

class _DiscoverTabBar extends StatelessWidget {
  const _DiscoverTabBar({
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
            label: 'My Gems',
            isActive: activeSection == Sections.yourProjects,
            onTap: () => onTabChanged(Sections.yourProjects),
          ),
          _Tab(
            label: 'Discover',
            isActive: activeSection == Sections.discoverProjects,
            onTap: () => onTabChanged(Sections.discoverProjects),
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
// Wrapper to add bottom padding to YourProjectsSection scroll content
// ─────────────────────────────────────────────────────────────────────────────

class _YourGemsWrapper extends StatelessWidget {
  const _YourGemsWrapper();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;
    return Column(
      children: [
        const YourProjectsSection(),
        SizedBox(height: bottomPad),
      ],
    );
  }
}
