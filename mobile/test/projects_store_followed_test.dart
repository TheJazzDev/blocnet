import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/updates_api_repository.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gems/gems_fixtures.dart';

/// `GET /projects` is capped, so a followed gem can be missing from it. The
/// board must still show every gem the member follows.
class _ProjectsRepo extends ProjectsApiRepository {
  _ProjectsRepo(this.listed, this.followed);

  final List<Project> listed;
  final List<Project> followed;
  int followedCalls = 0;
  bool failFollowed = false;

  @override
  Future<List<Project>> fetchProjects({int limit = 100, int offset = 0}) async =>
      listed;

  @override
  Future<List<Project>> fetchFollowedProjects({
    int limit = 100,
    int offset = 0,
  }) async {
    followedCalls++;
    if (failFollowed) throw StateError('offline');
    return followed.skip(offset).take(limit).toList();
  }
}

class _PostsRepo extends UpdatesApiRepository {
  @override
  Future<List<Update>> fetchPosts({int limit = 200, int offset = 0}) async =>
      const [];
}

class _UsersRepo extends UsersApiRepository {
  _UsersRepo(this.followedIds);

  final List<String> followedIds;

  @override
  Future<Map<String, dynamic>?> fetchMe({bool forceRefresh = false}) async =>
      {'followedProjectIds': followedIds};
}

ProjectsStore _store(_ProjectsRepo projects, List<String> followedIds) =>
    ProjectsStore(
      projectsRepository: projects,
      postsRepository: _PostsRepo(),
      usersRepository: _UsersRepo(followedIds),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('adds followed gems the capped list left out, once each', () async {
    final repo = _ProjectsRepo(
      [gemProject('p1')],
      [gemProject('p2'), gemProject('p1')],
    );
    final store = _store(repo, ['p1', 'p2']);

    await store.refreshProjects();

    expect(store.projects.map((p) => p.id), ['p1', 'p2']);
    expect(repo.followedCalls, 1);
  });

  test('asks nothing more when every followed gem is already listed',
      () async {
    final repo = _ProjectsRepo([gemProject('p1')], const []);
    final store = _store(repo, ['p1']);

    await store.refreshProjects();

    expect(repo.followedCalls, 0);
  });

  test('keeps the list when the followed read fails', () async {
    final repo = _ProjectsRepo([gemProject('p1')], const [])
      ..failFollowed = true;
    final store = _store(repo, ['p1', 'p2']);

    await store.refreshProjects();

    expect(store.projects.map((p) => p.id), ['p1']);
    expect(store.lastError, isNull);
  });
}
