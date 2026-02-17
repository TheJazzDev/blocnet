import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/vertical_divider.dart';
import 'package:flutter/material.dart';

class TagSelector extends StatefulWidget {
  const TagSelector({
    super.key,
    required this.title,
    required this.icon,
    required this.selectedTags,
    required this.unselectedTags,
    required this.onTagToggle,
  });

  final String title;
  final IconData icon;
  final Set<String> selectedTags;
  final Set<String> unselectedTags;
  final Function(String) onTagToggle;

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            Icon(widget.icon, color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_drop_down,
          color: AppColors.textMuted,
          size: 20,
        ),
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._buildTagList(widget.selectedTags, true),
                if (widget.selectedTags.isNotEmpty)
                  CustomVerticalDivider(height: 25),
                ..._buildTagList(widget.unselectedTags, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTagList(Set<String> tags, bool isSelected) {
    return tags.map((tag) {
      return GestureDetector(
        onTap: () => widget.onTagToggle(tag),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.teal500.withValues(alpha: 0.12)
                : AppColors.bgElevated,
            border: Border.all(
              color: isSelected ? AppColors.teal500 : AppColors.borderSubtle,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            spacing: 6,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.teal400,
                  size: 14,
                ),
              Text(
                tag,
                style: TextStyle(
                  color: isSelected ? AppColors.teal400 : AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
