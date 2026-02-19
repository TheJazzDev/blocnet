import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:flutter/material.dart';
import 'update_card_details.dart';
import '../shared/update_tag_row.dart';
import '../update_details/update_details_dialog.dart';

class UpdateCard extends StatelessWidget {
  const UpdateCard({required this.post, this.miniCard = false, super.key});

  final Update post;
  final bool miniCard;

  void _openDetails(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      pageBuilder: (context, _, __) => UpdateDetailsDialog(id: post.id),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = post.priority.color;

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left priority accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project name header row
                      _ProjectHeader(
                        projectName: post.project?.name ?? 'Project',
                        priorityColor: priorityColor,
                        priorityLabel: post.priority.label,
                      ),
                      const SizedBox(height: 10),
                      // Tags
                      UpdateTagRow(post: post),
                      const SizedBox(height: 12),
                      // Title + description + meta
                      UpdateCardDetails(post: post, miniCard: miniCard),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.projectName,
    required this.priorityColor,
    required this.priorityLabel,
  });

  final String projectName;
  final Color priorityColor;
  final String priorityLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.workspaces_outlined,
          size: 13,
          color: AppColors.textFaint,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            projectName,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Priority pill — small, right-aligned
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: priorityColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                priorityLabel,
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 9,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
