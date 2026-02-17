import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// Inline project name badge — used in "more from" horizontal scroll cards.
class UpdateProjectTitle extends StatelessWidget {
  const UpdateProjectTitle({
    required this.projectTitle,
    this.margin = true,
    this.applyOverflow = false,
    super.key,
  });

  final String projectTitle;
  final bool margin;
  final bool applyOverflow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin
          ? const EdgeInsets.only(bottom: 6)
          : EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspaces_outlined,
            size: 12,
            color: AppColors.textFaint,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              projectTitle,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
              ),
              overflow:
                  applyOverflow ? TextOverflow.ellipsis : TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
