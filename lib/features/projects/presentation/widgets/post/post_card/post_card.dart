import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/post.dart';
import 'package:flutter/material.dart';
import 'post_card_details.dart';
import 'post_card_tag_row.dart';
import '../shared/post_project_title.dart';
import '../post_details/post_details_dialog.dart';

class PostCard extends StatefulWidget {
  const PostCard(
    this.post, {
    super.key,
  });

  final Post post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int hiddenCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        pageBuilder: (context, animation, secondaryAnimation) {
          return PostDetailsDialog(widget.post);
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
            PostProjectTitle(widget.post.projectTitle, applyOverflow: true),
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
          PostCardTagRow(
            post: widget.post,
          ),
          const SizedBox(height: 16),
          PostCardDetails(post: widget.post),
        ],
      ),
    );
  }
}
