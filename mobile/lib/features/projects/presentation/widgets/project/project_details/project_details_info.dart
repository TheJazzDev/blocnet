import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/dot_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/post/shared/post_project_logo.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:blocnet/shared/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';

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
        _buildTitleRow(),
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
        PostProjectLogo(logoUrl: project.logo, size: 60),
        const SizedBox(width: 24),
        Flexible(child: PrimaryLabel(primaryTag: project.primaryTag)),
      ],
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        StyledLabelLarge(project.name),
        const Spacer(),
        SecondaryButton(
          onPressed: () {},
          title: 'Following',
          isEnabled: true,
          variant: ButtonVariant.small,
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
    return Row(
      children: [
        StyledBodyText600('1,700 Followers', size: 12),
        DotDivider(12),
        StyledBodyText600('700 Total Posts', size: 12),
      ],
    );
  }

  Widget _buildAdditionalDetails() {
    return Wrap(
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildDetailCard('Market Cap', '\$1.2B'),
        DotDivider(12),
        _buildDetailCard('Active Users', '45,000'),
        DotDivider(12),
        _buildDetailCard('Launched', '2021'),
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
