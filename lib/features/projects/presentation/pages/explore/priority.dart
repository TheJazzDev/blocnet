import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/data/models/priority_model.dart';
import 'package:blocknet/features/projects/data/services/post_by_priority.dart';
import 'package:blocknet/features/projects/presentation/widgets/app_bar.dart';
import 'package:blocknet/features/projects/presentation/widgets/filter_label/filter_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class PriorityScreens extends StatefulWidget {
  const PriorityScreens({super.key});

  @override
  State<PriorityScreens> createState() => _PriorityScreensState();
}

class _PriorityScreensState extends State<PriorityScreens> {
  late Priority priority;
  List<Post> priorityPosts = [];
  List<Post> filteredPosts = [];
  final Set<String> _allSecondaryTags = {};
  final Set<String> _selectedFilters = {};

  // Get priority from the page and pass it to the fetchposts
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    priority = args?['priority'] ?? Priority.high;

    _loadPosts(priority);
  }

  void _loadPosts(Priority priority) {
    final posts = PostByPriority.fetchPostsByPriority(priority);
    setState(() {
      priorityPosts = posts;
      _extractSecondaryTags();
      _applyFilters();
    });
  }

  // Extract unique secondary tags from the posts
  void _extractSecondaryTags() {
    final tags = <String>{};

    for (var post in priorityPosts) {
      for (var tag in post.secondaryTags) {
        tags.add(tag.toString());
      }
    }

    setState(() {
      _allSecondaryTags.clear();
      _allSecondaryTags.addAll(tags);
    });
  }

  // Apply filters to the posts based on selected tags
  void _applyFilters() {
    if (_selectedFilters.isEmpty) {
      filteredPosts = List.from(priorityPosts);
    } else {
      filteredPosts = priorityPosts.where((post) {
        for (var tag in post.secondaryTags) {
          if (_selectedFilters.contains(tag.toString())) {
            return true;
          }
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
          _allSecondaryTags.add(tag);
        } else {
          _selectedFilters.add(tag);
          _allSecondaryTags.remove(tag);
        }
      }

      // Apply the updated filters
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: ''),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                StyledBodyText700('$priority Urgency'),
                FilterLabel(
                  selectedTags: _selectedFilters,
                  unselectedTags: _allSecondaryTags,
                  onTagToggle: _toggleTag,
                )
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(
                    filteredPosts.length,
                    (index) => PostCard(post: filteredPosts[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
