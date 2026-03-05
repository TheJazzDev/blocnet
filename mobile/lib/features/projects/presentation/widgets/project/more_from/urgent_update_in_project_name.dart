import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_card/update_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/shared/update_project_title.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UrgentPostInProjectName extends StatefulWidget {
  const UrgentPostInProjectName({
    required this.projectName,
    required this.projectId,
    super.key,
  });

  final String projectName;
  final String projectId;

  @override
  State<UrgentPostInProjectName> createState() =>
      _UrgentPostInProjectNameState();
}

class _UrgentPostInProjectNameState extends State<UrgentPostInProjectName> {
  late List<Update> urgentPosts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    final postStore = Provider.of<UpdatesStore>(context, listen: false);
    urgentPosts = postStore.getUpdatesByProjectIdAndPriority(
      widget.projectId,
      Priority.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Urgent Update In',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                UpdateProjectTitle(
                  projectTitle: widget.projectName,
                  margin: false,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        urgentPosts.isEmpty
            ? Text(
                'No urgent updates available for this project!',
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              )
            : Column(
                children: List.generate(
                  urgentPosts.length,
                  (index) =>
                      UpdateCard(post: urgentPosts[index], miniCard: true),
                ),
              ),
      ],
    );
  }
}
