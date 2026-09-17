import 'package:blocnet/features/gems/presentation/pages/gem_page.dart';
import 'package:flutter/material.dart';

/// The member's gem page, as every existing caller opens it.
///
/// Kept under its old name so feed cards, search, update detail and the
/// Hub's "View as member" all land on the rebuilt page.
class ProjectDetailsDialog extends StatelessWidget {
  const ProjectDetailsDialog({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) => GemPage(projectId: projectId);
}
