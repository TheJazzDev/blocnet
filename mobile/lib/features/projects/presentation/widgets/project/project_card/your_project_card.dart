import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';
import '../project_details/project_details_dialog.dart';
import 'your_project_card_info.dart';
import 'your_project_card_overview.dart';
import 'your_project_card_update.dart';

class YourProjectCard extends StatefulWidget {
  const YourProjectCard({required this.project, super.key});

  final Project project;

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

    return GestureDetector(
      onTap: _openDetails,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YourProjectCardOverview(project: widget.project),
            const SizedBox(height: 12),
            YourProjectCardInfo(project: widget.project),
            if (recentUpdates.isNotEmpty) ...[
              const SizedBox(height: 12),
              _UpdatesDivider(),
              const SizedBox(height: 8),
              ...recentUpdates.map((update) => YourProjectCardUpdate(post: update)),
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
            fontSize: 10,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: AppColors.borderSubtle),
        ),
      ],
    );
  }
}
