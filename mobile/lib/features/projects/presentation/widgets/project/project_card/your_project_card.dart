import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import '../project_details/project_details_dialog.dart';
import 'your_project_card_info.dart';
import 'your_project_card_overview.dart';
import 'your_project_card_update.dart';

enum YourProjectCardLayout { card, list }

class YourProjectCard extends StatefulWidget {
  const YourProjectCard({
    required this.project,
    this.layout = YourProjectCardLayout.card,
    super.key,
  });

  final Project project;
  final YourProjectCardLayout layout;

  @override
  State<YourProjectCard> createState() => _YourProjectCardState();
}

class _YourProjectCardState extends State<YourProjectCard> {
  void _openDetails() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProjectDetailsDialog(projectId: widget.project.id);
      },
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentUpdates = widget.project.posts?.take(3).toList() ?? [];
    if (widget.layout == YourProjectCardLayout.list) {
      return InkWell(
        onTap: _openDetails,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSurface.flush(
                width: 42,
                height: 42,
                child: widget.project.logo.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          widget.project.logo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.layers_outlined,
                            size: AppIcon.md,
                            color: AppColors.textFaint,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.layers_outlined,
                        size: AppIcon.md,
                        color: AppColors.textFaint,
                      ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppText.bodySize,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.hair),
                    Text(
                      '${widget.project.primaryTag.name} • ${widget.project.followersCount} followers • ${widget.project.posts?.length ?? 0} updates',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontSize: AppText.captionSize,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.project.description.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        widget.project.description.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppText.bodySize,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: AppIcon.md,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _openDetails,
      child: AppSurface(
        radius: AppRadius.lg,
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YourProjectCardOverview(project: widget.project),
            const SizedBox(height: AppSpace.md),
            YourProjectCardInfo(project: widget.project),
            if (recentUpdates.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              _UpdatesDivider(),
              const SizedBox(height: AppSpace.sm),
              ...recentUpdates
                  .map((update) => YourProjectCardUpdate(post: update)),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpdatesDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Recent updates',
          style: TextStyle(
            color: AppColors.textFaint,
            fontSize: AppText.captionSize,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Container(height: 1, color: AppColors.borderSubtle),
        ),
      ],
    );
  }
}
