import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
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
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.teal400,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (store.projects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Text(
              'No projects available yet. Check back soon.',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 13,
                fontFamily: 'Geist',
              ),
            ),
          );
        }

        if (store.lastError != null && store.lastError!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(store.lastError!)),
            );
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Discover and follow relevant projects.',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 13,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 12),
            ...store.projects.map((project) {
              final isFollowed = store.isProjectFollowed(project.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        project.logo,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: AppColors.bgElevated,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.layers,
                            size: 18,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project.description.isEmpty
                                ? project.details
                                : project.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textFaint,
                              fontSize: 12,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${project.followersCount} followers',
                            style: TextStyle(
                              color: AppColors.textFaint,
                              fontSize: 11,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FollowButton(
                      isFollowed: isFollowed,
                      isLoading: store.isTogglingFollow,
                      onTap: () => _toggleFollow(project),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ─── Follow Button ────────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.isFollowed,
    required this.isLoading,
    required this.onTap,
  });

  final bool isFollowed;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isFollowed
              ? null
              : LinearGradient(
                  colors: [AppColors.teal500, AppColors.primary500],
                ),
          color: isFollowed ? AppColors.bgElevated : null,
          borderRadius: BorderRadius.circular(20),
          border: isFollowed
              ? Border.all(color: AppColors.borderSubtle)
              : null,
        ),
        child: Text(
          isFollowed ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowed ? AppColors.textMuted : Colors.white,
            fontSize: 12,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
