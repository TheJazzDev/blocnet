import 'dart:ui';

import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocknet/features/projects/data/models/priority_model.dart';
import 'package:blocknet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocknet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocknet/shared/styles/app_primary_button.dart';
import 'package:blocknet/shared/styles/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'tag_selector.dart';
import 'priority_selector.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  Set<String> _primaryTags = {};
  Set<String> _secondaryTags = {};
  Set<Priority> _priorities = {};

  final Set<String> _selectedPrimaryTags = {};
  final Set<String> _selectedSecondaryTags = {};
  final Set<Priority> _selectedPriorities = {};

  bool get isEnabled =>
      _selectedPrimaryTags.isNotEmpty ||
      _selectedSecondaryTags.isNotEmpty ||
      _selectedPriorities.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _primaryTags = Set.from(PrimaryTag.getAll());
    _secondaryTags = Set.from(SecondaryTag.getAll());
    _priorities = Set.from(Priority.getAll());
  }

  void _getAllFilters() {
    final allFilters = {
      'primaryTags': _selectedPrimaryTags.toList(),
      'secondaryTags': _selectedSecondaryTags.toList(),
      'priorities': _selectedPriorities.toList(),
    };
    debugPrint(allFilters.toString());
  }

  void _togglePrimaryTag(String tag) {
    setState(() {
      if (_selectedPrimaryTags.contains(tag)) {
        _selectedPrimaryTags.remove(tag);
        _primaryTags.add(tag);
      } else {
        _selectedPrimaryTags.add(tag);
        _primaryTags.remove(tag);
      }
    });
  }

  void _toggleSecondaryTag(String tag) {
    setState(() {
      if (_selectedSecondaryTags.contains(tag)) {
        _selectedSecondaryTags.remove(tag);
        _secondaryTags.add(tag);
      } else {
        _selectedSecondaryTags.add(tag);
        _secondaryTags.remove(tag);
      }
    });
  }

  void _togglePriority(Priority priority) {
    setState(() {
      if (_selectedPriorities.contains(priority)) {
        _selectedPriorities.remove(priority);
        _priorities.add(priority);
      } else {
        _selectedPriorities.add(priority);
        _priorities.remove(priority);
      }
    });
  }

  // Clears all selected filters
  void _clearAllFilters() {
    setState(() {
      // Move all selected primary tags back to unselected
      _primaryTags.addAll(_selectedPrimaryTags);
      _selectedPrimaryTags.clear();

      // Move all selected secondary tags back to unselected
      _secondaryTags.addAll(_selectedSecondaryTags);
      _selectedSecondaryTags.clear();

      // Move all selected priorities back to unselected
      _priorities.addAll(_selectedPriorities);
      _selectedPriorities.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackdropFilter(),
        _buildBottomSheetContent(),
      ],
    );
  }

  Widget _buildBackdropFilter() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.darkGrey100,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StyledLabelLarge('Filters'),
                      const SizedBox(height: 16),
                      _buildDropdownSection(
                        title: 'Primary Tag',
                        icon: Symbols.bookmark_star,
                        selectedTags: _selectedPrimaryTags,
                        unselectedTags: _primaryTags,
                        onTagToggle: _togglePrimaryTag,
                      ),
                      CustomHorizontalDivider(margin: 16),
                      _buildDropdownSection(
                        title: 'Secondary Tag',
                        icon: Symbols.bookmark,
                        selectedTags: _selectedSecondaryTags,
                        unselectedTags: _secondaryTags,
                        onTagToggle: _toggleSecondaryTag,
                      ),
                      CustomHorizontalDivider(margin: 16),
                      PrioritySelector(
                        selectedPriorities: _selectedPriorities,
                        unselectedPriorities: _priorities,
                        onPriorityToggle: _togglePriority,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SecondaryButton(
                              onPressed: _clearAllFilters,
                              title: 'Clear All Filters',
                              isEnabled: isEnabled),
                          SizedBox(width: 12),
                          PrimaryButton(
                            onPressed: _getAllFilters,
                            title: 'Apply Filters',
                            isEnabled: isEnabled,
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required IconData icon,
    required Set<String> selectedTags,
    required Set<String> unselectedTags,
    required Function(String) onTagToggle,
  }) {
    return TagSelector(
      title: title,
      icon: icon,
      selectedTags: selectedTags,
      unselectedTags: unselectedTags,
      onTagToggle: onTagToggle,
    );
  }
}
