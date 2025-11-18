import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/project_model.dart';
import '../../data/models/post_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/interactions_provider.dart';
import '../../../../shared/widgets/buttons/follow_button.dart';
import '../../../../core/routes/route_names.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  Project? _project;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (doc.exists) {
        setState(() {
          _project = Project.fromFirestore(doc, null);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Project not found';
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

    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Project not found'),
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
        title: Text(_project!.name),
      ),
      body: ListView(
        children: [
          // Project Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _project!.logo.isNotEmpty
                      ? NetworkImage(_project!.logo)
                      : null,
                  child: _project!.logo.isEmpty
                      ? Text(
                          _project!.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  _project!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Category
                Chip(
                  label: Text(_project!.category),
                  backgroundColor: Colors.blue.shade100,
                ),
                const SizedBox(height: 16),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Followers', _project!.followersCount),
                    _buildStatColumn('Posts', _project!.postsCount),
                    _buildStatColumn('Likes', _project!.totalLikes),
                  ],
                ),
                const SizedBox(height: 24),

                // Follow Button
                if (currentUser != null)
                  FollowButton(
                    isFollowing: _project!.isFollowedByUser(currentUser.id),
                    onTap: () {
                      interactionsProvider.toggleFollowProject(
                        currentUser.id,
                        _project!.id,
                        _project!.isFollowedByUser(currentUser.id),
                      );
                    },
                  ),
              ],
            ),
          ),

          const Divider(),

          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _project!.description,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),

                // Website
                TextButton.icon(
                  onPressed: () => _launchUrl(_project!.website),
                  icon: const Icon(Icons.link),
                  label: Text(_project!.website),
                ),
              ],
            ),
          ),

          const Divider(),

          // Posts
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Posts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Posts List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('projectId', isEqualTo: widget.projectId)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final posts = snapshot.data!.docs
                  .map((doc) => Post.fromFirestore(doc, null))
                  .toList();

              if (posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No posts yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: posts.map((post) => _buildPostCard(post)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getPostTypeColor(post.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPostTypeIcon(post.type),
            color: _getPostTypeColor(post.type),
          ),
        ),
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          post.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(
          context,
          RouteNames.postDetail,
          arguments: post.id,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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
