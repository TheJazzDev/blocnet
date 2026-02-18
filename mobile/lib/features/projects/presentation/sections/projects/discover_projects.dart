import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_card/gem_card.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DiscoverProjectsSection extends StatefulWidget {
  const DiscoverProjectsSection({super.key});

  @override
  State<DiscoverProjectsSection> createState() =>
      _DiscoverProjectsSectionState();
}

class _DiscoverProjectsSectionState extends State<DiscoverProjectsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ProjectsStore>(context, listen: false).fetchProjectsOnce();
    });
  }

  Future<void> _toggleFollow(Project project) async {
    await Provider.of<ProjectsStore>(
      context,
      listen: false,
    ).toggleFollowProject(project.id);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsStore>(
      builder: (context, store, _) {
        if (store.isFetching && store.projects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (store.projects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.diamond_outlined,
                  size: 40,
                  color: AppColors.textFaint,
                ),
                const SizedBox(height: 12),
                Text(
                  'No gems found',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gems will appear here when projects are listed.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textFaint,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURATED FEED',
                    style: GoogleFonts.inter(
                      color: AppColors.textFaint,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.9,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Sort: Hype Score',
                      style: GoogleFonts.inter(
                        color: AppColors.textFaint,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Gem cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: store.projects.map((project) {
                  final isFollowed = store.isProjectFollowed(project.id);
                  return GemCard(
                    project: project,
                    isFollowed: isFollowed,
                    isLoading: store.isTogglingFollow,
                    onFollowToggle: () => _toggleFollow(project),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
