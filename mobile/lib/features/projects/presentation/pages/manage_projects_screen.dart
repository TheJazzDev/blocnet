import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/project_proposal_model.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class ManageProjectsScreen extends StatefulWidget {
  const ManageProjectsScreen({super.key});

  @override
  State<ManageProjectsScreen> createState() => _ManageProjectsScreenState();
}

class _ManageProjectsScreenState extends State<ManageProjectsScreen> {
  final _proposalRepository = ProjectProposalsApiRepository();
  List<ProjectProposalModel> _proposals = const <ProjectProposalModel>[];
  bool _isLoadingProposals = false;
  String? _proposalError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        context.read<ProjectsStore>().fetchProjectsOnce(),
        context.read<UpdatesStore>().fetchUpdatesOnce(),
        _loadMyProposals(force: true),
      ]);
    });
  }

  Future<void> _loadMyProposals({bool force = false}) async {
    if (_isLoadingProposals && !force) {
      return;
    }

    setState(() {
      _isLoadingProposals = true;
      _proposalError = null;
    });

    try {
      final proposals = await _proposalRepository.listMine(limit: 100);
      if (!mounted) return;
      setState(() {
        _proposals = proposals;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _proposalError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProposals = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (!auth.canSubmitProject) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _buildAppBar(context, showAdd: false),
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
          appBar: _buildAppBar(context, showAdd: true),
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
                      _loadMyProposals(force: true),
                    ]);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (projectsStore.lastError != null &&
                          projectsStore.lastError!.isNotEmpty) ...[
                        Text(
                          projectsStore.lastError!,
                          style: AppTypography.custom(color: AppColors.error500,
                            size: 12,
                            weight: FontWeight.w400,),
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
                      const SizedBox(height: 20),
                      _SectionLabel('Submitted for Review'),
                      const SizedBox(height: 8),
                      if (_proposalError != null && _proposalError!.isNotEmpty)
                        Text(
                          _proposalError!,
                          style: AppTypography.custom(
                            color: AppColors.error500,
                            size: 12,
                            weight: FontWeight.w400,
                          ),
                        ),
                      if (_isLoadingProposals && _proposals.isEmpty) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.primary500,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ] else if (_proposals.isEmpty)
                        _EmptyHint('No submitted project proposals yet.')
                      else
                        ..._proposals.map(_buildProposalTile),
                    ],
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    {
    required bool showAdd,
  }) {
    return CustomAppBar(
      title: 'Manage My Gems',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary500.withValues(alpha: 0.2),
                  AppColors.primary500.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary500.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: project.logo.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      project.logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.layers_outlined,
                        size: 24,
                        color: AppColors.primary400,
                      ),
                    ),
                  )
                : Icon(
                    Icons.layers_outlined,
                    size: 24,
                    color: AppColors.primary400,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 12,
                      color: AppColors.textFaint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      project.primaryTag.name,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 12,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary500.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: AppColors.primary400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.followersCount} followers',
                        style: AppTypography.custom(
                          color: AppColors.primary400,
                          size: 11,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textFaint,
          ),
        ],
      ),
    );
  }

  Widget _buildProposalTile(ProjectProposalModel proposal) {
    final reviewNote = proposal.reviewNote?.trim();
    final hasReviewNote = reviewNote != null && reviewNote.isNotEmpty;
    final statusColor = switch (proposal.status.toLowerCase()) {
      'approved' => AppColors.successColor,
      'rejected' => AppColors.error500,
      _ => AppColors.warning500,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  proposal.name,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  proposal.statusLabel,
                  style: AppTypography.custom(
                    color: statusColor,
                    size: 11,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Submitted ${_formatDate(proposal.createdAt)}',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 11,
              weight: FontWeight.w500,
            ),
          ),
          if (proposal.isApproved && proposal.createdProjectId != null) ...[
            const SizedBox(height: 6),
            Text(
              'Approved and converted to a live gem.',
              style: AppTypography.custom(
                color: AppColors.successColor,
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ],
          if (hasReviewNote) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'Admin note: $reviewNote',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
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
      style: AppTypography.custom(
        color: AppColors.textFaint,
        size: 10,
        weight: FontWeight.w600,
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
        style: AppTypography.custom(color: AppColors.textFaint,
          size: 13,
          weight: FontWeight.w400,),
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
      style: AppTypography.custom(color: AppColors.textMuted,
        size: 14,
        weight: FontWeight.w400,),
    );
  }
}
