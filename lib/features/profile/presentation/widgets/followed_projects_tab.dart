import 'package:flutter/material.dart';
import '../../../projects/data/models/project_model.dart';

class FollowedProjectsTab extends StatelessWidget {
  final List<Project> projects;

  const FollowedProjectsTab({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No followed projects yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start following projects to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(project.logo),
            ),
            title: Text(project.name),
            subtitle: Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${project.followersCount} followers',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              // Navigate to project detail
            },
          ),
        );
      },
    );
  }
}
