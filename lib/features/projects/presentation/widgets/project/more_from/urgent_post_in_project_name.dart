import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/data/models/priority_model.dart';
import 'package:blocknet/features/projects/data/services/posts_by_project_id_and_priority_service.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/shared/post_project_title.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class UrgentPostInProjectName extends StatefulWidget {
  const UrgentPostInProjectName(
      {required this.projectName, required this.projectId, super.key});

  final String projectName;
  final String projectId;

  @override
  State<UrgentPostInProjectName> createState() =>
      _UrgentPostInProjectNameState();
}

class _UrgentPostInProjectNameState extends State<UrgentPostInProjectName> {
  late List<Post> urgentPosts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      urgentPosts =
          PostsByProjectIdAndPriorityService.fetchPostsByIdAndPriority(
              widget.projectId, Priority.high);

      print(urgentPosts);
      print(widget.projectId);
    });
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
                StyledBodyText600("Urgent Post In"),
                PostProjectTitle(
                    projectTitle: widget.projectName, margin: false)
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        urgentPosts.isEmpty
            ? const Text("No urgent posts available for this project!")
            : Column(
                children: List.generate(
                  urgentPosts.length,
                  (index) => PostCard(post: urgentPosts[index], miniCard: true),
                ),
              ),
      ],
    );
  }
}
