import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/priority_label.dart';

class PostDetailsHeader extends StatelessWidget {
  const PostDetailsHeader({required this.priority, super.key});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          PriorityLabel(priority: priority),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => {},
          ),
        ],
      ),
    );
  }
}
