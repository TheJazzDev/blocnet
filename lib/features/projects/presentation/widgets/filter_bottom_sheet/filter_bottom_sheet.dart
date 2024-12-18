import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/primary_tag.dart';
import 'package:blocknet/features/projects/data/models/priority.dart';
import 'package:blocknet/features/projects/data/models/secondary_tag.dart';
import 'package:blocknet/features/projects/presentation/widgets/horizontal_divider.dart';
import 'package:blocknet/shared/styled/primary_button.dart';
import 'package:blocknet/shared/styled/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/shared/styled/text.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'dropdown_section.dart';
import 'priority_dropdown.dart';

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

  // Gets all selected filters
  // Map<String, dynamic> _getAllFilters() {
  void _getAllFilters() {
    final allFilters = {
      'primaryTags': _selectedPrimaryTags.toList(),
      'secondaryTags': _selectedSecondaryTags.toList(),
      'priorities': _selectedPriorities
          .map((priority) => priority.label.toLowerCase())
          .toList(),
    };

    print('All Filters: $allFilters');
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        color: AppColors.darkGrey100,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledLabelLarge('Filters'),
              const SizedBox(height: 16),
              DropdownSection(
                title: 'Primary Tag',
                icon: Symbols.bookmark_star,
                selectedTags: _selectedPrimaryTags,
                unselectedTags: _primaryTags,
                onTagToggle: _togglePrimaryTag,
              ),
              CustomHorizontalDivider(margin: 16),
              DropdownSection(
                title: 'Secondary Tag',
                icon: Symbols.bookmark,
                selectedTags: _selectedSecondaryTags,
                unselectedTags: _secondaryTags,
                onTagToggle: _toggleSecondaryTag,
              ),
              CustomHorizontalDivider(margin: 16),
              PriorityDropdown(
                selectedPriorities: _selectedPriorities,
                unselectedPriorities: _priorities,
                onPriorityToggle: _togglePriority,
              ),
              SizedBox(height: 16),
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
        ),
      ),
    );
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
}
