import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/priority.dart';
import 'package:blocknet/features/projects/presentation/widgets/priority_label.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/shared/styled/text.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class PriorityDropdown extends StatefulWidget {
  final Set<Priority> selectedPriorities;
  final Set<Priority> unselectedPriorities;
  final Function(Priority) onPriorityToggle;

  const PriorityDropdown({
    super.key,
    required this.selectedPriorities,
    required this.unselectedPriorities,
    required this.onPriorityToggle,
  });

  @override
  State<PriorityDropdown> createState() => _PriorityDropdownState();
}

class _PriorityDropdownState extends State<PriorityDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(0),
        title: Row(
          children: [
            Icon(
              Symbols.e911_emergency,
              color: AppColors.darkGrey500,
              size: 16,
            ),
            const SizedBox(width: 8),
            StyledBodyText500('Priority Level'),
          ],
        ),
        trailing: AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.arrow_drop_down,
            color: AppColors.darkGrey500,
            size: 20,
          ),
        ),
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._buildTagList(widget.selectedPriorities, true),
                ..._buildTagList(widget.unselectedPriorities, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTagList(Set<Priority> priorities, bool isSelected) {
    return priorities.map((priority) {
      return GestureDetector(
        onTap: () => widget.onPriorityToggle(priority),
        child: Wrap(
          children: [
            PriorityLabel(
              priority,
              isButton: isSelected,
            )
          ],
        ),
      );
    }).toList();
  }
}
