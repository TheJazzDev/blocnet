import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/presentation/widgets/dividers/vertical_divider.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';

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
        tilePadding: EdgeInsets.all(0),
        title: Row(
          children: [
            Icon(
              widget.icon,
              color: AppColors.darkGrey500,
              size: 16,
            ),
            const SizedBox(width: 8),
            StyledBodyText500(widget.title),
          ],
        ),
        trailing: Icon(
          Icons.arrow_drop_down,
          color: AppColors.darkGrey500,
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.darkGrey200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            spacing: 8,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.darkGrey500,
                  size: 16,
                ),
              StyledBodyText(tag),
            ],
          ),
        ),
      );
    }).toList();
  }
}
