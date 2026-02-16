import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:flutter/material.dart';

class BlocnetSearchDelegate extends SearchDelegate<void> {
  BlocnetSearchDelegate({
    required this.projects,
    required this.posts,
  });

  final List<Project> projects;
  final List<Post> posts;

  @override
  String get searchFieldLabel => 'Search projects or posts';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppColors.darkGrey500,
          fontFamily: 'Geist',
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildMatches(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildMatches(context);
  }

  Widget _buildMatches(BuildContext context) {
    final q = query.trim().toLowerCase();

    final projectMatches = (q.isEmpty
            ? projects.take(12)
            : projects.where(
                (project) =>
                    project.name.toLowerCase().contains(q) ||
                    project.description.toLowerCase().contains(q) ||
                    project.primaryTag.toString().toLowerCase().contains(q),
              ))
        .take(20)
        .toList();

    final postMatches = (q.isEmpty
            ? posts.take(15)
            : posts.where(
                (post) =>
                    post.title.toLowerCase().contains(q) ||
                    post.description.toLowerCase().contains(q) ||
                    post.content.toLowerCase().contains(q) ||
                    (post.project?.name.toLowerCase().contains(q) ?? false),
              ))
        .take(30)
        .toList();

    if (projectMatches.isEmpty && postMatches.isEmpty) {
      return Center(
        child: Text(
          'No matches found',
          style: TextStyle(
            color: AppColors.darkGrey500,
            fontFamily: 'Geist',
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (projectMatches.isNotEmpty) ...[
          Text(
            'Projects',
            style: TextStyle(
              color: AppColors.darkGrey600,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...projectMatches.map(
            (project) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.layers_outlined,
                color: AppColors.darkGrey600,
                size: 20,
              ),
              title: Text(
                project.name,
                style: TextStyle(
                  color: AppColors.darkGrey700,
                  fontFamily: 'Geist',
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                project.primaryTag.toString(),
                style: TextStyle(
                  color: AppColors.darkGrey500,
                  fontFamily: 'Geist',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (postMatches.isNotEmpty) ...[
          Text(
            'Posts',
            style: TextStyle(
              color: AppColors.darkGrey600,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...postMatches.map(
            (post) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.article_outlined,
                color: AppColors.darkGrey600,
                size: 20,
              ),
              title: Text(
                post.title,
                style: TextStyle(
                  color: AppColors.darkGrey700,
                  fontFamily: 'Geist',
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                post.project?.name ?? 'Unknown Project',
                style: TextStyle(
                  color: AppColors.darkGrey500,
                  fontFamily: 'Geist',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
