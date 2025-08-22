import 'package:blocnet/features/projects/presentation/viewmodels/your_projects_view_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/cards/stat_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/filter_label/filter_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_card/your_project_card.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class YourProjectsSection extends StatefulWidget {
  const YourProjectsSection({super.key});

  @override
  State<YourProjectsSection> createState() => _YourProjectsSectionState();
}

class _YourProjectsSectionState extends State<YourProjectsSection> {
  YourProjectsViewModel? viewModel;

  @override
  void initState() {
    super.initState();

    // Delay viewModel creation until after build context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<ProjectsStore>(context, listen: false);
      
      setState(() {
        viewModel = YourProjectsViewModel(store);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;

    if (vm == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
          selectedTags: vm.selectedFilters,
          unselectedTags: vm.allPrimaryTags,
          onTagToggle: (tag) {
            setState(() {
              vm.toggleTag(tag);
            });
          },
        ),
        const SizedBox(height: 16),
        _buildYourProjectsSection(vm),
      ],
    );
  }

  Widget _buildYourProjectsSection(vm) {
    return Wrap(
      children: List.generate(
        vm.filteredProjects.length,
        (index) => YourProjectCard(project: vm.filteredProjects[index]),
      ),
    );
  }
}
