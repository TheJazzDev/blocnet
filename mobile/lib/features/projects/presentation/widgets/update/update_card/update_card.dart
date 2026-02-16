import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:flutter/material.dart';
import 'update_card_details.dart';
import '../shared/update_tag_row.dart';
import '../shared/update_project_title.dart';
import '../update_details/update_details_dialog.dart';

class UpdateCard extends StatefulWidget {
  const UpdateCard({required this.post, this.miniCard = false, super.key});

  final Update post;
  final bool miniCard;

  @override
  State<UpdateCard> createState() => _PostCardState();
}

class _PostCardState extends State<UpdateCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        pageBuilder: (context, animation, secondaryAnimation) {
          return UpdateDetailsDialog(id: widget.post.id);
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.darkGrey200,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UpdateProjectTitle(
              projectTitle: widget.post.project?.name ?? 'Project',
              applyOverflow: true,
            ),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: [
          UpdateTagRow(post: widget.post),
          const SizedBox(height: 16),
          UpdateCardDetails(post: widget.post, miniCard: widget.miniCard),
        ],
      ),
    );
  }
}
