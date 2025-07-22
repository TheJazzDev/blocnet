import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:flutter/material.dart';
import 'post_card_details.dart';
import '../shared/post_tag_row.dart';
import '../shared/post_project_title.dart';
import '../post_details/post_details_dialog.dart';

class PostCard extends StatefulWidget {
  const PostCard({required this.post, this.miniCard = false, super.key});

  final Post post;
  final bool miniCard;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        pageBuilder: (context, animation, secondaryAnimation) {
          return PostDetailsDialog(postId: widget.post.postId);
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
            PostProjectTitle(
              projectTitle: widget.post.project?.name ?? 'No project name',
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
          PostTagRow(post: widget.post),
          const SizedBox(height: 16),
          PostCardDetails(post: widget.post, miniCard: widget.miniCard),
        ],
      ),
    );
  }
}
