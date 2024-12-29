import 'package:blocknet/features/projects/data/models/project_model.dart';
import 'package:blocknet/features/projects/data/services/all_projects.dart';
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
  List<Project> allProjects = [];
  List<Project> filteredProjects = [];
  final Set<String> _allPrimaryTags = {};
  final Set<String> _selectedFilters = {};

  void _loadPosts() {
    final projects = AllProjects.getAllProjects();

    setState(() {
      allProjects = projects;
      _extractPrimaryTags();
      _applyFilters();
    });
  }

  // Extract unique secondary tags from the posts
  void _extractPrimaryTags() {
    final tags = <String>{};

    for (var project in allProjects) {
      tags.add(project.primaryTag.toString());
    }

    setState(() {
      _allPrimaryTags.clear();
      _allPrimaryTags.addAll(tags);
    });
  }

  // Apply filters to the posts based on selected tags
  void _applyFilters() {
    if (_selectedFilters.isEmpty) {
      filteredProjects = List.from(allProjects);
    } else {
      filteredProjects = allProjects.where((project) {
        if (_selectedFilters.contains(project.primaryTag.toString())) {
          return true;
        }
        return false;
      }).toList();
    }
  }

// Toggle the selection of a tag
  void _toggleTag(String tag) {
    setState(() {
      if (tag == 'All') {
        // Clear all other tags and select only 'All'
        _selectedFilters.clear();
      } else {
        // Toggle the current tag
        if (_selectedFilters.contains(tag)) {
          _selectedFilters.remove(tag);
          _allPrimaryTags.add(tag);
        } else {
          _selectedFilters.add(tag);
          _allPrimaryTags.remove(tag);
        }
      }

      // Apply the updated filters
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    _loadPosts();
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
          selectedTags: _selectedFilters,
          unselectedTags: _allPrimaryTags,
          onTagToggle: _toggleTag,
        ),
        const SizedBox(height: 16),
        _buildYourProjectsSection()
      ],
    );
  }

  Widget _buildYourProjectsSection() {
    return Wrap(
      children: List.generate(
        allProjects.length,
        (index) => YourProjectCard(project: allProjects[index]),
      ),
    );
  }
}
