import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/projects/presentation/providers/interactions_provider.dart';

class LikeButton extends StatefulWidget {
  final String postId;
  final String projectId;
  final String postTitle;
  final bool isLiked;
  final int likesCount;
  final VoidCallback? onLikeChanged;

  const LikeButton({
    super.key,
    required this.postId,
    required this.projectId,
    required this.postTitle,
    required this.isLiked,
    required this.likesCount,
    this.onLikeChanged,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likesCount = widget.likesCount;
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
    }
    if (oldWidget.likesCount != widget.likesCount) {
      _likesCount = widget.likesCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final interactionsProvider = context.read<InteractionsProvider>();

    if (authProvider.currentUser == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 20),
          const SizedBox(width: 4),
          Text('$_likesCount'),
        ],
      );
    }

    return InkWell(
      onTap: () async {
        // Optimistic update
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });

        try {
          await interactionsProvider.toggleLikePost(
            userId: authProvider.currentUser!.id,
            postId: widget.postId,
            projectId: widget.projectId,
            postTitle: widget.postTitle,
            isCurrentlyLiked: !_isLiked, // Use previous state
          );

          widget.onLikeChanged?.call();
        } catch (e) {
          // Revert on error
          if (mounted) {
            setState(() {
              _isLiked = !_isLiked;
              _likesCount += _isLiked ? 1 : -1;
            });
          }
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: _isLiked ? Colors.red : null,
            ),
            const SizedBox(width: 4),
            Text(
              '$_likesCount',
              style: TextStyle(
                color: _isLiked ? Colors.red : null,
                fontWeight: _isLiked ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
