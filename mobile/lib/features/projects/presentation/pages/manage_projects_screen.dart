import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageProjectsScreen extends StatefulWidget {
  const ManageProjectsScreen({super.key});

  @override
  State<ManageProjectsScreen> createState() => _ManageProjectsScreenState();
}

class _ManageProjectsScreenState extends State<ManageProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projects = context.read<ProjectsStore>();
      final updates = context.read<UpdatesStore>();
      await Future.wait([
        projects.fetchProjectsOnce(),
        updates.fetchUpdatesOnce(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    if (!auth.canSubmitProject) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('Manage Projects'), centerTitle: false),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: StyledBodyText500(
            'Your current role does not allow managing projects.',
          ),
        ),
      );
    }

    return Consumer2<ProjectsStore, UpdatesStore>(
      builder: (context, projectsStore, updatesStore, _) {
        final userId = auth.userId ?? '';
        final ownedProjects = projectsStore.projects
            .where((project) => project.adminId == userId)
            .toList();

        final contributedProjectIds = updatesStore.updates
            .where((update) => update.adminId == userId)
            .map((update) => update.projectId)
            .toSet();

        final contributedProjects = projectsStore.projects
            .where((project) =>
                project.adminId != userId &&
                contributedProjectIds.contains(project.id))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Projects'),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: auth.canSubmitProject
                    ? () =>
                        Navigator.of(context).pushNamed(AppRoutes.submitProject)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: projectsStore.isFetching && projectsStore.projects.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      projectsStore.refreshProjects(),
                      updatesStore.refreshUpdates(),
                    ]);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (projectsStore.lastError != null &&
                          projectsStore.lastError!.isNotEmpty) ...[
                        StyledBodyText500(projectsStore.lastError!, size: 12),
                        const SizedBox(height: 10),
                      ],
                      const StyledBodyText700('Projects Created By You',
                          size: 14),
                      const SizedBox(height: 8),
                      if (ownedProjects.isEmpty)
                        const StyledBodyText500(
                          'No approved projects created by you yet.',
                          size: 12,
                        )
                      else
                        ...ownedProjects.map(_projectTile),
                      const SizedBox(height: 20),
                      const StyledBodyText700('Projects You Contribute To',
                          size: 14),
                      const SizedBox(height: 8),
                      if (contributedProjects.isEmpty)
                        const StyledBodyText500(
                          'No contribution projects yet.',
                          size: 12,
                        )
                      else
                        ...contributedProjects.map(_projectTile),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _projectTile(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkGrey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StyledBodyText700(project.name, size: 13),
          const SizedBox(height: 4),
          StyledBodyText500(project.primaryTag.toString(), size: 12),
          const SizedBox(height: 6),
          StyledBodyText500(
            '${project.followersCount} followers',
            size: 11,
          ),
        ],
      ),
    );
  }
}
