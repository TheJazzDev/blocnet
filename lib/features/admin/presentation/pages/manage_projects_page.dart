import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/helpers.dart';

class ManageProjectsPage extends StatelessWidget {
  const ManageProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                Navigator.pushNamed(context, RouteNames.createProject),
            tooltip: 'Create Project',
          ),
        ],
      ),
      body: adminProvider.adminProjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No projects yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, RouteNames.createProject),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Project'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adminProvider.adminProjects.length,
              itemBuilder: (context, index) {
                final project = adminProvider.adminProjects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: project.logo.isNotEmpty
                              ? NetworkImage(project.logo)
                              : null,
                          child: project.logo.isEmpty
                              ? Text(project.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(
                          project.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              project.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.article,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${project.postsCount} posts',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.people,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${project.followersCount} followers',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.pushNamed(
                                context,
                                RouteNames.editProject,
                                arguments: project,
                              );
                            } else if (value == 'delete') {
                              _showDeleteDialog(
                                context,
                                project.id,
                                project.name,
                                authProvider,
                                adminProvider,
                              );
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RouteNames.createPost,
                                arguments: project.id,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('New Post'),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RouteNames.manageProjectPosts,
                                arguments: project.id,
                              ),
                              icon: const Icon(Icons.list),
                              label: const Text('View Posts'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String projectId,
    String projectName,
    AuthProvider authProvider,
    AdminProvider adminProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "$projectName"? This will also delete all posts associated with this project. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await adminProvider.deleteProject(
                projectId,
                authProvider.currentUser!.id,
              );

              if (context.mounted) {
                if (success) {
                  Helpers.showSnackBar(
                    context,
                    'Project deleted successfully',
                  );
                } else {
                  Helpers.showSnackBar(
                    context,
                    'Failed to delete project: ${adminProvider.error}',
                    isError: true,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
