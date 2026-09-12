import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';

/// The gradient project chip on a feed card — the tap target that takes a
/// member from an update to the gem it belongs to.
class FeedProjectChip extends StatelessWidget {
  const FeedProjectChip({
    super.key,
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgElevated.withValues(alpha: 0.9),
              AppColors.bgElevated.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
          border: Border.all(
            color: AppColors.primary500.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.25),
                    AppColors.primary500.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                border: Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: project.logo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.smValue),
                      child: AppNetworkImage(
                        url: project.logo,
                        fit: BoxFit.cover,
                        fallback: Icon(
                          Icons.layers_outlined,
                          size: AppIcon.sm,
                          color: AppColors.primary400,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.layers_outlined,
                      size: AppIcon.sm,
                      color: AppColors.primary400,
                    ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Row(
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: AppIcon.xs,
                        color: AppColors.textFaint,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          project.primaryTag.name,
                          style: AppTypography.custom(
                            color: AppColors.textFaint,
                            size: AppText.captionSize,
                            weight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: AppIcon.xs,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
