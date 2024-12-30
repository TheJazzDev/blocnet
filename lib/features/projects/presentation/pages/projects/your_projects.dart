import 'package:blocknet/features/projects/presentation/viewmodels/your_projects_view_model.dart';
import 'package:blocknet/features/projects/presentation/widgets/cards/stat_card.dart';
import 'package:blocknet/features/projects/presentation/widgets/filter_label/filter_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/project/project_card/your_project_card.dart';
import 'package:flutter/material.dart';

class YourProjectsSection extends StatefulWidget {
  const YourProjectsSection({super.key});

  @override
  State<YourProjectsSection> createState() => _YourProjectsSectionState();
}

class _YourProjectsSectionState extends State<YourProjectsSection> {
  late YourProjectsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = YourProjectsViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: StatCard(
                label: 'Followed Projects',
                value: 345,
                iconName: 'style',
              ),
            ),
            Expanded(
              flex: 1,
              child: StatCard(
                label: 'New Posts',
                value: 1200,
                iconName: 'post',
              ),
            ),
            Expanded(
              flex: 1,
              child: StatCard(
                label: 'High Urgency Posts',
                value: 20,
                iconName: 'emergency',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FilterLabel(
          selectedTags: viewModel.selectedFilters,
          unselectedTags: viewModel.allPrimaryTags,
          onTagToggle: (tag) {
            setState(() {
              viewModel.toggleTag(tag);
            });
          },
        ),
        const SizedBox(height: 16),
        _buildYourProjectsSection()
      ],
    );
  }

  Widget _buildYourProjectsSection() {
    return Wrap(
      children: List.generate(
        viewModel.filteredProjects.length,
        (index) => YourProjectCard(project: viewModel.filteredProjects[index]),
      ),
    );
  }
}
