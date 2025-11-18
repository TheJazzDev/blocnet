import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/interactions_provider.dart';
import '../../../../shared/widgets/buttons/like_button.dart';
import '../../../../shared/widgets/buttons/save_button.dart';
import '../../../../core/utils/helpers.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (doc.exists) {
        setState(() {
          _post = Post.fromFirestore(doc, null);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Post not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Post not found'),
            ],
          ),
        ),
      );
    }

    final authProvider = context.watch<AuthProvider>();
    final interactionsProvider = context.watch<InteractionsProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Post Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPostTypeColor(_post!.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPostTypeIcon(_post!.type),
                        color: _getPostTypeColor(_post!.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post!.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(_post!.createdAt),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Post Image
                if (_post!.image != null && _post!.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _post!.image!,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 16),

                // Post Content
                Text(
                  _post!.content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (currentUser != null)
                  Row(
                    children: [
                      LikeButton(
                        isLiked: _post!.isLikedByUser(currentUser.id),
                        likesCount: _post!.likesCount,
                        onTap: () {
                          interactionsProvider.toggleLikePost(
                            currentUser.id,
                            _post!.id,
                            _post!.isLikedByUser(currentUser.id),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      SaveButton(
                        isSaved: currentUser.hasPostSaved(_post!.id),
                        onTap: () {
                          interactionsProvider.toggleSavePost(
                            currentUser.id,
                            _post!.id,
                            currentUser.hasPostSaved(_post!.id),
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        '${_post!.viewsCount} views',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),

                const Divider(height: 32),

                // Comments Section
                Text(
                  'Comments (${_post!.commentsCount})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Comments List
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('comments')
                      .where('postId', isEqualTo: widget.postId)
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data!.docs
                        .map((doc) => Comment.fromFirestore(doc, null))
                        .toList();

                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: comments.map((comment) => _buildCommentCard(comment, currentUser)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Comment Input
          if (currentUser != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _addComment(currentUser.id, interactionsProvider),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment, currentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(comment.userId[0].toUpperCase()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        timeago.format(comment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.content),
          ],
        ),
      ),
    );
  }

  Future<void> _addComment(String userId, InteractionsProvider provider) async {
    if (_commentController.text.trim().isEmpty) return;

    final success = await provider.addComment(
      userId: userId,
      postId: widget.postId,
      projectId: _post!.projectId,
      content: _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      if (mounted) {
        Helpers.showSnackBar(context, 'Comment added');
      }
    } else {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Failed to add comment',
          isError: true,
        );
      }
    }
  }

  IconData _getPostTypeIcon(PostType type) {
    switch (type) {
      case PostType.update:
        return Icons.update;
      case PostType.announcement:
        return Icons.campaign;
      case PostType.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.update:
        return Colors.blue;
      case PostType.announcement:
        return Colors.orange;
      case PostType.urgent:
        return Colors.red;
    }
  }
}
