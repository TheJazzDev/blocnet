import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

class ProjectDetailsHeader extends StatelessWidget {
  const ProjectDetailsHeader({
    required this.projectId,
    this.title = 'Gem',
    super.key,
  });

  final String projectId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppText.subtitleSize,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          _HeaderIconButton(
            icon: Icons.share_outlined,
            onTap: () {},
          ),
          const SizedBox(width: AppSpace.sm),
          _HeaderIconButton(
            icon: Icons.bookmark_border,
            onTap: () {},
          ),
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Icon(icon, size: AppIcon.md, color: AppColors.textSecondary),
      ),
    );
  }
}
