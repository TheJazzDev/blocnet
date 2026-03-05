import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/projects/projects_store.dart';

class YourProjectsViewModel {
  final List<Project> allProjects = [];
  final List<Project> filteredProjects = [];
  final Set<String> allPrimaryTags = {};
  final Set<String> selectedFilters = {};

  YourProjectsViewModel(ProjectsStore store) {
    allProjects.addAll(store.projects);
    _extractPrimaryTags();
    _applyFilters();
  }

  void _extractPrimaryTags() {
    allPrimaryTags
      ..clear()
      ..addAll(allProjects.map((project) => project.primaryTag.toString()));
  }

  void _applyFilters() {
    filteredProjects.clear();
    if (selectedFilters.isEmpty) {
      filteredProjects.addAll(allProjects);
    } else {
      filteredProjects.addAll(
        allProjects.where(
          (project) => selectedFilters.contains(project.primaryTag.toString()),
        ),
      );
    }
  }

  void toggleTag(String tag) {
    if (tag == 'All') {
      allPrimaryTags.addAll(selectedFilters);
      selectedFilters.clear();
    } else {
      if (selectedFilters.contains(tag)) {
        selectedFilters.remove(tag);
        allPrimaryTags.add(tag);
      } else {
        selectedFilters.add(tag);
        allPrimaryTags.remove(tag);
      }
    }
    _applyFilters();
  }
}
