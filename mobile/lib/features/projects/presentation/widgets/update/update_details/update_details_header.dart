import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.md),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
          if (headerTitle != null && headerTitle.isNotEmpty) ...[
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                headerTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppText.bodySize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
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
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Icon(icon, size: AppIcon.md, color: AppColors.textMuted),
      ),
    );
  }
}
