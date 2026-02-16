import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';

class PriorityScreenViewModel {
  final Priority priority;
  List<Post> _allPosts = [];
  List<Post> priorityPosts = [];
  List<Post> filteredPosts = [];
  final Set<String> allSecondaryTags = {};
  final Set<String> selectedFilters = {};

  PriorityScreenViewModel({
    required this.priority,
    List<Post> allPosts = const [],
  }) {
    setPosts(allPosts);
  }

  void setPosts(List<Post> allPosts) {
    _allPosts = allPosts;
    _loadPosts();
  }

  void _loadPosts() {
    priorityPosts =
        _allPosts.where((post) => post.priority == priority).toList();
    _extractSecondaryTags();
    _applyFilters();
  }

  void _extractSecondaryTags() {
    final tags = <String>{};

    for (var post in priorityPosts) {
      for (var tag in post.secondaryTags) {
        tags.add(tag.toString());
      }
    }

    allSecondaryTags.clear();
    allSecondaryTags.addAll(tags);
  }

  void _applyFilters() {
    if (selectedFilters.isEmpty) {
      filteredPosts = List.from(priorityPosts);
    } else {
      filteredPosts = priorityPosts.where((post) {
        for (var tag in post.secondaryTags) {
          if (selectedFilters.contains(tag.toString())) {
            return true;
          }
        }
        return false;
      }).toList();
    }
  }

  void toggleTag(String tag) {
    if (tag == 'All') {
      selectedFilters.clear();
    } else {
      if (selectedFilters.contains(tag)) {
        selectedFilters.remove(tag);
        allSecondaryTags.add(tag);
      } else {
        selectedFilters.add(tag);
        allSecondaryTags.remove(tag);
      }
    }
    _applyFilters();
  }
}
