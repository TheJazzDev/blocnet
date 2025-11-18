import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/projects/presentation/providers/interactions_provider.dart';

class SaveButton extends StatefulWidget {
  final String postId;
  final String postTitle;
  final bool isSaved;
  final VoidCallback? onSaveChanged;

  const SaveButton({
    super.key,
    required this.postId,
    required this.postTitle,
    required this.isSaved,
    this.onSaveChanged,
  });

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
  }

  @override
  void didUpdateWidget(SaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSaved != widget.isSaved) {
      _isSaved = widget.isSaved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final interactionsProvider = context.read<InteractionsProvider>();

    if (authProvider.currentUser == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () async {
        // Optimistic update
        setState(() {
          _isSaved = !_isSaved;
        });

        try {
          await interactionsProvider.toggleSavePost(
            userId: authProvider.currentUser!.id,
            postId: widget.postId,
            postTitle: widget.postTitle,
            isCurrentlySaved: !_isSaved, // Use previous state
          );

          widget.onSaveChanged?.call();
        } catch (e) {
          // Revert on error
          if (mounted) {
            setState(() {
              _isSaved = !_isSaved;
            });
          }
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          _isSaved ? Icons.bookmark : Icons.bookmark_border,
          size: 20,
          color: _isSaved ? Theme.of(context).primaryColor : null,
        ),
      ),
    );
  }
}
