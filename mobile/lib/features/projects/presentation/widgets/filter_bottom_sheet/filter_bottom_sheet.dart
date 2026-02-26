import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/shared/widgets/app_primary_button.dart';
import 'package:blocnet/shared/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import '../shared/custom_backdrop_filter.dart';
import '../dividers/horizontal_divider.dart';
import 'filter_dropdown_section.dart';
import 'priority_selector.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  Set<String> _primaryTagOptions = <String>{};
  Set<String> _secondaryTagOptions = <String>{};
  Set<String> _selectedPrimaryTags = <String>{};
  Set<String> _selectedSecondaryTags = <String>{};
  Set<Priority> _selectedPriorities = <Priority>{};

  @override
  void initState() {
    super.initState();
    final projectsStore = context.read<ProjectsStore>();
    final updatesStore = context.read<UpdatesStore>();
    _selectedPrimaryTags = {...projectsStore.discoverPrimaryTagFilters};
    _selectedSecondaryTags = {...projectsStore.discoverSecondaryTagFilters};
    _selectedPriorities = {...projectsStore.discoverPriorityFilters};
    _hydrateFilterOptions(projectsStore, updatesStore);
  }

  void _hydrateFilterOptions(
    ProjectsStore projectsStore,
    UpdatesStore updatesStore,
  ) {
    final primaryTagValues = projectsStore.projects
        .map((project) => project.primaryTag.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((left, right) => left.compareTo(right));

    final secondaryTagValues = projectsStore.projects
        .expand((project) => project.secondaryTags)
        .map((tag) => tag.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((left, right) => left.compareTo(right));

    final priorities = updatesStore.updates
        .map((update) => update.priority)
        .toSet()
        .toList()
      ..sort((left, right) => left.label.compareTo(right.label));

    _primaryTagOptions = {...primaryTagValues};
    _secondaryTagOptions = {...secondaryTagValues};

    final allowedPriorities = priorities.isEmpty
        ? Priority.getAll().toSet()
        : priorities.toSet();
    _selectedPriorities = _selectedPriorities
        .where(allowedPriorities.contains)
        .toSet();
  }

  Set<String> get _unselectedPrimaryTags =>
      _primaryTagOptions.difference(_selectedPrimaryTags);
  Set<String> get _unselectedSecondaryTags =>
      _secondaryTagOptions.difference(_selectedSecondaryTags);
  Set<Priority> get _unselectedPriorities =>
      Priority.getAll().toSet().difference(_selectedPriorities);
  bool get _hasSelection =>
      _selectedPrimaryTags.isNotEmpty ||
      _selectedSecondaryTags.isNotEmpty ||
      _selectedPriorities.isNotEmpty;

  void _togglePrimaryTag(String tag) {
    setState(() {
      if (_selectedPrimaryTags.contains(tag)) {
        _selectedPrimaryTags.remove(tag);
      } else {
        _selectedPrimaryTags.add(tag);
      }
    });
  }

  void _toggleSecondaryTag(String tag) {
    setState(() {
      if (_selectedSecondaryTags.contains(tag)) {
        _selectedSecondaryTags.remove(tag);
      } else {
        _selectedSecondaryTags.add(tag);
      }
    });
  }

  void _togglePriority(Priority priority) {
    setState(() {
      if (_selectedPriorities.contains(priority)) {
        _selectedPriorities.remove(priority);
      } else {
        _selectedPriorities.add(priority);
      }
    });
  }

  void _applyFilters() {
    final projectsStore = context.read<ProjectsStore>();
    projectsStore.setDiscoverFilters(
      primaryTags: _selectedPrimaryTags,
      secondaryTags: _selectedSecondaryTags,
      priorities: _selectedPriorities,
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedPrimaryTags.clear();
      _selectedSecondaryTags.clear();
      _selectedPriorities.clear();
    });
    context.read<ProjectsStore>().clearDiscoverFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [CustomBackdropFilter(), _buildBottomSheetContent()],
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
            color: AppColors.bgSurface,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilterDropdownSection(
                    title: 'Primary Tag',
                    icon: Symbols.bookmark_star,
                    selectedTags: _selectedPrimaryTags,
                    unselectedTags: _unselectedPrimaryTags,
                    onTagToggle: _togglePrimaryTag,
                  ),
                  CustomHorizontalDivider(margin: 16),
                  FilterDropdownSection(
                    title: 'Secondary Tag',
                    icon: Symbols.bookmark,
                    selectedTags: _selectedSecondaryTags,
                    unselectedTags: _unselectedSecondaryTags,
                    onTagToggle: _toggleSecondaryTag,
                  ),
                  CustomHorizontalDivider(margin: 16),
                  PrioritySelector(
                    selectedPriorities: _selectedPriorities,
                    unselectedPriorities: _unselectedPriorities,
                    onPriorityToggle: _togglePriority,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SecondaryButton(
                        onPressed: _clearFilters,
                        title: 'Clear All Filters',
                        isEnabled: _hasSelection,
                      ),
                      const SizedBox(width: 12),
                      PrimaryButton(
                        onPressed: _applyFilters,
                        title: 'Apply Filters',
                        isEnabled: _hasSelection,
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
}
