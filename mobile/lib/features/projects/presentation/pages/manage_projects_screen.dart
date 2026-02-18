import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      await Future.wait([
        context.read<ProjectsStore>().fetchProjectsOnce(),
        context.read<UpdatesStore>().fetchUpdatesOnce(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (!auth.canSubmitProject) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _buildAppBar(context, auth, showAdd: false),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: _AccessDenied(
            message: 'Your current role does not allow managing projects.',
          ),
        ),
      );
    }

    return Consumer2<ProjectsStore, UpdatesStore>(
      builder: (context, projectsStore, updatesStore, _) {
        final userId = auth.userId ?? '';
        final owned = projectsStore.projects
            .where((p) => p.adminId == userId)
            .toList();

        final contributedIds = updatesStore.updates
            .where((u) => u.adminId == userId)
            .map((u) => u.projectId)
            .toSet();

        final contributed = projectsStore.projects
            .where((p) => p.adminId != userId && contributedIds.contains(p.id))
            .toList();

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: _buildAppBar(context, auth, showAdd: true),
          body: projectsStore.isFetching && projectsStore.projects.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal400,
                    strokeWidth: 2,
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.teal400,
                  backgroundColor: AppColors.bgSurface,
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
                        Text(
                          projectsStore.lastError!,
                          style: GoogleFonts.inter(
                            color: AppColors.error500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _SectionLabel('Created by you'),
                      const SizedBox(height: 8),
                      if (owned.isEmpty)
                        _EmptyHint('No approved gems created by you yet.')
                      else
                        ...owned.map(_buildProjectTile),
                      const SizedBox(height: 20),
                      _SectionLabel('Gems you contribute to'),
                      const SizedBox(height: 8),
                      if (contributed.isEmpty)
                        _EmptyHint('No contribution gems yet.')
                      else
                        ...contributed.map(_buildProjectTile),
                    ],
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthStore auth, {
    required bool showAdd,
  }) {
    return AppBar(
      backgroundColor: AppColors.bgBase,
      title: Text(
        'Manage My Gems',
        style: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textMuted),
      actions: [
        if (showAdd)
          GestureDetector(
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.submitProject),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Icon(Icons.add, size: 18, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectTile(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            project.primaryTag.toString(),
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${project.followersCount} followers',
            style: GoogleFonts.inter(
              color: AppColors.textFaint,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppColors.textFaint,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: GoogleFonts.inter(
          color: AppColors.textFaint,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 14,
      ),
    );
  }
}
