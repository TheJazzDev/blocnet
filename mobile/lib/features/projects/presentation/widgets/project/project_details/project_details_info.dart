import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/dot_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/shared/update_project_logo.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:blocnet/shared/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectDetailsInfo extends StatelessWidget {
  const ProjectDetailsInfo({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildTitleRow(context),
        const SizedBox(height: 16),
        _buildDescription(),
        const SizedBox(height: 8),
        const CustomHorizontalDivider(margin: 12),
        _buildStatsRow(),
        const SizedBox(height: 2),
        const CustomHorizontalDivider(margin: 12),
        _buildAdditionalDetails(),
        const CustomHorizontalDivider(margin: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        UpdateProjectLogo(logoUrl: project.logo, size: 60),
        const SizedBox(width: 24),
        Flexible(child: PrimaryLabel(primaryTag: project.primaryTag)),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StyledLabelLarge(project.name),
        ),
        Consumer<ProjectsStore>(
          builder: (context, store, _) {
            final isFollowed = store.isProjectFollowed(project.id);
            return SecondaryButton(
              onPressed: () {
                store.toggleFollowProject(project.id);
              },
              title: isFollowed ? 'Following' : 'Follow',
              isEnabled: true,
              variant: ButtonVariant.small,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: StyledBodyText600(
        project.description,
        size: 12,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatsRow() {
    final postsCount = project.posts?.length ?? 0;
    return Row(
      children: [
        StyledBodyText600('${project.followersCount} Followers', size: 12),
        DotDivider(12),
        StyledBodyText600('$postsCount Total Updates', size: 12),
      ],
    );
  }

  Widget _buildAdditionalDetails() {
    final ownerName = project.admin?.name ?? 'Admin';

    return Wrap(
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildDetailCard('Owner', ownerName),
        DotDivider(12),
        _buildDetailCard(
          'Primary Tag',
          project.primaryTag.toString(),
        ),
        DotDivider(12),
        _buildDetailCard('Created', formatDateWithSuffix(project.createdAt)),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey75,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: AppColors.darkGrey300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StyledBodyText400(label, size: 12),
          const SizedBox(width: 8),
          StyledBodyText600(value, size: 12),
        ],
      ),
    );
  }
}
