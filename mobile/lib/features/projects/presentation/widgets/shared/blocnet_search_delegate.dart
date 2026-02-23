import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/profile/data/models/profile_search_result_model.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:flutter/material.dart';

class BlocnetSearchDelegate extends SearchDelegate<Admin?> {
  BlocnetSearchDelegate({
    required this.projects,
    required this.posts,
    UsersApiRepository? usersRepository,
  }) : _usersRepository = usersRepository ?? UsersApiRepository();

  final List<Project> projects;
  final List<Update> posts;
  final UsersApiRepository _usersRepository;
  final Map<String, Future<List<ProfileSearchResult>>> _profileSearchCache = {};

  @override
  String get searchFieldLabel => 'Search projects, updates, users, hunters';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: AppColors.bgBase,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppColors.textFaint,
          fontFamily: 'Geist',
        ),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Geist',
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: AppColors.textMuted),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: AppColors.textMuted),
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

    final futureProfiles = q.isEmpty
        ? Future<List<ProfileSearchResult>>.value(const [])
        : _profileSearch(q);

    return FutureBuilder<List<ProfileSearchResult>>(
      future: futureProfiles,
      builder: (context, snapshot) {
        final profileMatches = snapshot.data ?? const <ProfileSearchResult>[];
        final isProfileLoading =
            q.isNotEmpty && snapshot.connectionState == ConnectionState.waiting;

        if (projectMatches.isEmpty &&
            postMatches.isEmpty &&
            profileMatches.isEmpty &&
            !isProfileLoading) {
          return Center(
            child: Text(
              'No matches found',
              style: TextStyle(
                color: AppColors.textFaint,
                fontFamily: 'Geist',
              ),
            ),
          );
        }

        return Container(
          color: AppColors.bgBase,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              if (isProfileLoading || profileMatches.isNotEmpty) ...[
                _sectionTitle('Users & Hunters'),
                const SizedBox(height: 8),
                if (isProfileLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.primary500,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                else
                  ...profileMatches.map((profile) {
                    final avatarUrl = profile.avatarUrl?.trim() ?? '';
                    final roles = _searchRoleLabels(profile.roles);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.bgElevated,
                        backgroundImage:
                            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.textMuted,
                                size: 16,
                              )
                            : null,
                      ),
                      title: Text(
                        profile.label,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Geist',
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        profile.handle.isNotEmpty
                            ? '${profile.handle} · $roles'
                            : roles,
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontFamily: 'Geist',
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        close(context, _asAdmin(profile));
                      },
                    );
                  }),
                const SizedBox(height: 10),
              ],
              if (projectMatches.isNotEmpty) ...[
                _sectionTitle('Projects'),
                const SizedBox(height: 8),
                ...projectMatches.map(
                  (project) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.layers_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    title: Text(
                      project.name,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Geist',
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      project.primaryTag.toString(),
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontFamily: 'Geist',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (postMatches.isNotEmpty) ...[
                _sectionTitle('Updates'),
                const SizedBox(height: 8),
                ...postMatches.map(
                  (post) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.article_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    title: Text(
                      post.title,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Geist',
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      post.project?.name ?? 'Unknown Project',
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontFamily: 'Geist',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<List<ProfileSearchResult>> _profileSearch(String q) {
    final normalized = q.trim().toLowerCase();
    if (normalized.isEmpty) return Future.value(const []);

    return _profileSearchCache.putIfAbsent(
      normalized,
      () => _usersRepository.searchProfiles(query: normalized, limit: 20),
    );
  }

  Widget _sectionTitle(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textFaint,
        fontFamily: 'Geist',
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }

  String _searchRoleLabels(List<String> roles) {
    final normalized = roles.map((role) => role.toLowerCase()).toSet();
    final labels = <String>[];
    if (normalized.contains('core_team')) labels.add('Core Team');
    if (normalized.contains('admin')) labels.add('Admin');
    if (normalized.contains('moderator')) labels.add('Moderator');
    if (normalized.contains('hunter')) labels.add('Hunter');
    if (labels.isEmpty) labels.add('User');
    return labels.join(' • ');
  }

  Admin _asAdmin(ProfileSearchResult result) {
    final name = (result.displayName?.trim().isNotEmpty ?? false)
        ? result.displayName!.trim()
        : (result.handle.isNotEmpty ? result.handle.substring(1) : 'User');

    return Admin(
      id: result.id,
      name: name,
      username: result.handle.isNotEmpty ? result.handle : '@${name.toLowerCase().replaceAll(' ', '_')}',
      imageUrl: result.avatarUrl?.trim() ?? '',
      followers: result.followersCount,
    );
  }
}
