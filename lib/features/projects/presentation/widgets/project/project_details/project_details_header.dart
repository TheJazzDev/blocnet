import 'package:flutter/material.dart';

class ProjectDetailsHeader extends StatelessWidget {
  const ProjectDetailsHeader({required this.projectId, super.key});

  final String projectId;

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
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => {},
          ),
        ],
      ),
    );
  }
}
