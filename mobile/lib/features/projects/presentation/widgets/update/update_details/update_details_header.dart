import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/priority_label.dart';

class UpdateDetailsHeader extends StatelessWidget {
  const UpdateDetailsHeader({
    required this.priority,
    this.title,
    this.showPriority = true,
    super.key,
  });

  final Priority priority;
  final String? title;
  final bool showPriority;

  @override
  Widget build(BuildContext context) {
    final headerTitle = title?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
          if (headerTitle != null && headerTitle.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                headerTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            const Spacer(),
            if (showPriority) PriorityLabel(priority: priority),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Icon(icon, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
