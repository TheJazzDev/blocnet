import 'package:blocknet/features/projects/data/models/project_model.dart';
import 'package:blocknet/app/theme.dart';
import 'package:flutter/material.dart';
import '../project_details/project_details_dialog.dart';
import 'your_project_card_info.dart';
import 'your_project_card_overview.dart';
import 'your_project_card_post.dart';

class YourProjectCard extends StatefulWidget {
  const YourProjectCard({required this.project, super.key});

  final Project project;

  @override
  State<YourProjectCard> createState() => _YourProjectCardState();
}

class _YourProjectCardState extends State<YourProjectCard> {
  @override
  Widget build(BuildContext context) {
    final firstThreePosts = widget.project.posts!.take(3).toList();

    return GestureDetector(
      onTap: () => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProjectDetailsDialog(projectId: widget.project.id);
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.darkGrey100,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: Column(
          children: [
            YourProjectCardOverview(project: widget.project),
            SizedBox(height: 8),
            YourProjectCardInfo(project: widget.project),
            SizedBox(height: 8),
            Wrap(
              children: firstThreePosts.map((post) {
                return YourProjectCardPost(post: post);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
