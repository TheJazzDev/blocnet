import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/presentation/controllers/bottom_sheet_filter_controller.dart';
import 'package:blocnet/shared/widgets/app_primary_button.dart';
import 'package:blocnet/shared/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
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
  late BottomSheetFilterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BottomSheetFilterController();
  }

  void _getAllFilters() {
    final allFilters = _controller.getFilters();
    debugPrint(allFilters.toString());
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
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
                        selectedTags: _controller.selectedPrimaryTags,
                        unselectedTags: _controller.primaryTags,
                        onTagToggle: (tag) {
                          setState(() {
                            _controller.togglePrimaryTag(tag);
                          });
                        },
                      ),
                      CustomHorizontalDivider(margin: 16),
                      FilterDropdownSection(
                        title: 'Secondary Tag',
                        icon: Symbols.bookmark,
                        selectedTags: _controller.selectedSecondaryTags,
                        unselectedTags: _controller.secondaryTags,
                        onTagToggle: (tag) {
                          setState(() {
                            _controller.toggleSecondaryTag(tag);
                          });
                        },
                      ),
                      CustomHorizontalDivider(margin: 16),
                      PrioritySelector(
                        selectedPriorities: _controller.selectedPriorities,
                        unselectedPriorities: _controller.priorities,
                        onPriorityToggle: (priority) {
                          setState(() {
                            _controller.togglePriority(priority);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SecondaryButton(
                            onPressed: () {
                              setState(() {
                                _controller.clearAllFilters();
                              });
                            },
                            title: 'Clear All Filters',
                            isEnabled: _controller.isEnabled,
                          ),
                          SizedBox(width: 12),
                          PrimaryButton(
                            onPressed: _getAllFilters,
                            title: 'Apply Filters',
                            isEnabled: _controller.isEnabled,
                          ),
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
}
