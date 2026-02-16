import 'package:flutter/material.dart';
import 'tag_selector.dart';

class FilterDropdownSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Set<String> selectedTags;
  final Set<String> unselectedTags;
  final Function(String) onTagToggle;

  const FilterDropdownSection({
    required this.title,
    required this.icon,
    required this.selectedTags,
    required this.unselectedTags,
    required this.onTagToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TagSelector(
      title: title,
      icon: icon,
      selectedTags: selectedTags,
      unselectedTags: unselectedTags,
      onTagToggle: onTagToggle,
    );
  }
}
