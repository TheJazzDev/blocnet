import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class YourProjectCardInfo extends StatelessWidget {
  const YourProjectCardInfo({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final lastEdited = project.posts != null && project.posts!.isNotEmpty
        ? project.posts![0].lastEditedAt
        : null;

    return Row(
      children: [
        _InfoChip(
          icon: Symbols.group,
          label: '${project.followersCount} followers',
        ),
        if (lastEdited != null) ...[
          const SizedBox(width: 8),
          _InfoChip(
            icon: Symbols.update,
            label: formatDateWithSuffix(lastEdited),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textFaint),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
