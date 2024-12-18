import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/presentation/widgets/vertical_divider.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/shared/styled/text.dart';

class DropdownSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Set<String> selectedTags;
  final Set<String> unselectedTags;
  final Function(String) onTagToggle;

  const DropdownSection({
    super.key,
    required this.title,
    required this.icon,
    required this.selectedTags,
    required this.unselectedTags,
    required this.onTagToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(0),
        title: Row(
          children: [
            Icon(
              icon,
              color: AppColors.darkGrey500,
              size: 16,
            ),
            const SizedBox(width: 8),
            StyledBodyText500(title),
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
                ..._buildTagList(selectedTags, true),
                if (selectedTags.isNotEmpty) CustomVerticalDivider(height: 25),
                ..._buildTagList(unselectedTags, false),
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
        onTap: () => onTagToggle(tag),
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
