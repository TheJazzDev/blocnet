import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'discover_projects.dart';
import 'your_projects.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  Section _activeSection = Sections.discoverProjects;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _pendingNewProjectIds = <String>{};
  Timer? _newProjectsPollTimer;
  bool _isCheckingForNewProjects = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _newProjectsPollTimer = Timer.periodic(
      const Duration(seconds: 14),
      (_) => _checkForNewProjects(),
    );
  }

  @override
  void dispose() {
    _newProjectsPollTimer?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged(Section section) {
    if (_activeSection == section) return;
    setState(() {
      _activeSection = section;
      if (section != Sections.discoverProjects) {
        _pendingNewProjectIds.clear();
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 20 && _pendingNewProjectIds.isNotEmpty) {
      setState(() => _pendingNewProjectIds.clear());
    }
  }

  Future<void> _checkForNewProjects() async {
    if (!mounted ||
        _activeSection != Sections.discoverProjects ||
        _isCheckingForNewProjects) {
      return;
    }

    final projectsStore = context.read<ProjectsStore>();
    final existingIds = projectsStore.projects.map((p) => p.id).toSet();

    _isCheckingForNewProjects = true;
    try {
      await projectsStore.refreshProjects();
    } finally {
      _isCheckingForNewProjects = false;
    }

    if (!mounted) return;

    final refreshed = projectsStore.projects;
    final newIds =
        refreshed.where((p) => !existingIds.contains(p.id)).map((p) => p.id);

    if (newIds.isEmpty) return;
    final isNearTop =
        _scrollController.hasClients && _scrollController.offset < 80;
    if (isNearTop) return;

    setState(() => _pendingNewProjectIds.addAll(newIds));
  }

  Future<void> _jumpToLatest() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    setState(() => _pendingNewProjectIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _activeSection == Sections.yourProjects
                      ? const _YourGemsWrapper()
                      : const DiscoverProjectsSection(),
                ),
              ),
            ],
          ),
          if (_activeSection == Sections.discoverProjects &&
              _pendingNewProjectIds.isNotEmpty)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _jumpToLatest,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_pendingNewProjectIds.length} new projects',
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
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            _Tab(
              label: 'Discover',
              isActive: activeSection == Sections.discoverProjects,
              onTap: () => onTabChanged(Sections.discoverProjects),
            ),
            _Tab(
              label: 'My Gems',
              isActive: activeSection == Sections.yourProjects,
              onTap: () => onTabChanged(Sections.yourProjects),
            ),
          ],
        ),
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
        height: 40,
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
