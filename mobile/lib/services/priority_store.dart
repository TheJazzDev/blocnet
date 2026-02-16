import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:provider/provider.dart';

class PriorityStore extends ChangeNotifier {
  final Priority priority;
  List<Update> _priorityPosts = [];
  List<Update> _filteredPosts = [];
  final Set<String> _allSecondaryTags = {};
  final Set<String> _selectedFilters = {};

  PriorityStore({required this.priority, required BuildContext context}) {
    _loadPosts(context);
  }

  List<Update> get filteredPosts => _filteredPosts;
  Set<String> get allSecondaryTags => _allSecondaryTags;
  Set<String> get selectedFilters => _selectedFilters;

  void _loadPosts(BuildContext context) {
    _priorityPosts = Provider.of<UpdatesStore>(context, listen: false)
        .getUpdatesByPriority(priority);
    _extractSecondaryTags();
    _applyFilters();
  }

  void _extractSecondaryTags() {
    final tags = <String>{};

    for (var post in _priorityPosts) {
      for (var tag in post.secondaryTags) {
        tags.add(tag.toString());
      }
    }

    _allSecondaryTags
      ..clear()
      ..addAll(tags);
  }

  void _applyFilters() {
    if (_selectedFilters.isEmpty) {
      _filteredPosts = List.from(_priorityPosts);
    } else {
      _filteredPosts = _priorityPosts.where((post) {
        return post.secondaryTags
            .any((tag) => _selectedFilters.contains(tag.toString()));
      }).toList();
    }
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (tag == 'All') {
      _selectedFilters.clear();
    } else {
      if (_selectedFilters.contains(tag)) {
        _selectedFilters.remove(tag);
        _allSecondaryTags.add(tag);
      } else {
        _selectedFilters.add(tag);
        _allSecondaryTags.remove(tag);
      }
    }
    _applyFilters();
  }
}
