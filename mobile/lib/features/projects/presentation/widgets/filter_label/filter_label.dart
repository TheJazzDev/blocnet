import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FilterLabel extends StatefulWidget {
  const FilterLabel({
    super.key,
    required this.selectedTags,
    required this.unselectedTags,
    required this.onTagToggle,
  });

  final Set<String> selectedTags;
  final Set<String> unselectedTags;
  final Function(String) onTagToggle;

  @override
  State<FilterLabel> createState() => _FilterLabelState();
}

class _FilterLabelState extends State<FilterLabel> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Wrap(
              spacing: 4,
              children: [
                TagButton(
                  tag: 'All',
                  isSelected: widget.selectedTags.isEmpty,
                  onTap: () => widget.onTagToggle('All'),
                ),
                ..._buildTagList(widget.selectedTags, true),
                ..._buildTagList(widget.unselectedTags, false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTagList(Set<String> tags, bool isSelected) {
    final sortedTags = tags.toList();

    return sortedTags.map((tag) {
      return TagButton(
        tag: tag,
        isSelected: isSelected,
        onTap: () => widget.onTagToggle(tag),
      );
    }).toList();
  }
}

class TagButton extends StatelessWidget {
  const TagButton({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  final String tag;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.teal500 : AppColors.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.teal500.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Wrap(
          spacing: 6,
          children: [
            Text(
              tag,
              style: TextStyle(
                color: isSelected ? AppColors.teal400 : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
            ),
            if (isSelected && tag != 'All')
              SvgPicture.asset(
                "assets/icons/mutiply_circle.svg",
                width: 12,
                height: 12,
              ),
          ],
        ),
      ),
    );
  }
}
