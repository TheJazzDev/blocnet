import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/shared/update_project_logo.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:blocnet/shared/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectDetailsInfo extends StatelessWidget {
  const ProjectDetailsInfo({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final postsCount = project.posts?.length ?? 0;
    final ownerName = project.admin?.name ?? 'Admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo + tag row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UpdateProjectLogo(logoUrl: project.logo, size: 52),
            const SizedBox(width: 12),
            PrimaryLabel(primaryTag: project.primaryTag),
          ],
        ),
        const SizedBox(height: 14),
        // Title + follow button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                project.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Consumer<ProjectsStore>(
              builder: (context, store, _) {
                final isFollowed = store.isProjectFollowed(project.id);
                return SecondaryButton(
                  onPressed: () => store.toggleFollowProject(project.id),
                  title: isFollowed ? 'Following' : 'Follow',
                  isEnabled: true,
                  variant: ButtonVariant.small,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Text(
            project.description,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Stats row
        Row(
          children: [
            _StatChip(label: 'Followers', value: '${project.followersCount}'),
            const SizedBox(width: 8),
            _StatChip(label: 'Updates', value: '$postsCount'),
          ],
        ),
        const SizedBox(height: 12),
        // Details chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DetailChip(label: 'Owner', value: ownerName),
            _DetailChip(label: 'Category', value: project.primaryTag.toString()),
            _DetailChip(label: 'Created', value: formatDateWithSuffix(project.createdAt)),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 12,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 11,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
