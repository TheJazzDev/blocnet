import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
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
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (store.projects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 28),
            child: StyledBodyText500(
              'No projects available yet. Check back soon.',
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
            const StyledBodyText500('Discover and follow relevant projects.'),
            const SizedBox(height: 12),
            ...store.projects.map((project) {
              final isFollowed = store.isProjectFollowed(project.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkGrey200),
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
                          color: AppColors.darkGrey200,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.layers,
                            size: 18,
                            color: AppColors.darkGrey600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StyledBodyText700(project.name, size: 14),
                          const SizedBox(height: 4),
                          StyledBodyText500(
                            project.description.isEmpty
                                ? project.details
                                : project.description,
                            size: 12,
                          ),
                          const SizedBox(height: 8),
                          StyledBodyText500(
                            '${project.followersCount} followers',
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: store.isTogglingFollow
                          ? null
                          : () => _toggleFollow(project),
                      style: TextButton.styleFrom(
                        backgroundColor: isFollowed
                            ? AppColors.darkGrey200
                            : AppColors.primary500,
                        foregroundColor:
                            isFollowed ? AppColors.darkGrey700 : Colors.black,
                      ),
                      child: Text(isFollowed ? 'Following' : 'Follow'),
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
