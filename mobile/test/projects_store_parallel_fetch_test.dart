import 'dart:async';

import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/updates_api_repository.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// refreshProjects awaited projects, then posts, then `/me` in sequence, even
/// though none of the three depends on another's result. On a link where a
/// round trip costs real time that is three waits where one would do.
class _GatedProjectsRepository extends ProjectsApiRepository {
  final started = Completer<void>();
  final release = Completer<List<Project>>();

  @override
  Future<List<Project>> fetchProjects({int limit = 100, int offset = 0}) {
    if (!started.isCompleted) started.complete();
    return release.future;
  }
}

class _GatedUpdatesRepository extends UpdatesApiRepository {
  final started = Completer<void>();
  final release = Completer<List<Update>>();

  @override
  Future<List<Update>> fetchPosts({int limit = 200, int offset = 0}) {
    if (!started.isCompleted) started.complete();
    return release.future;
  }
}

class _GatedUsersRepository extends UsersApiRepository {
  final started = Completer<void>();
  final release = Completer<Map<String, dynamic>?>();
  bool failMe = false;

  @override
  Future<Map<String, dynamic>?> fetchMe({bool forceRefresh = false}) {
    if (!started.isCompleted) started.complete();
    if (failMe) return Future<Map<String, dynamic>?>.error(StateError('no me'));
    return release.future;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('projects, posts and /me are all in flight before any of them returns',
      () async {
    final projects = _GatedProjectsRepository();
    final posts = _GatedUpdatesRepository();
    final users = _GatedUsersRepository();

    final store = ProjectsStore(
      projectsRepository: projects,
      postsRepository: posts,
      usersRepository: users,
    );

    final refresh = store.refreshProjects();

    // Let the microtask queue drain without completing any request.
    await pumpEventQueue();

    expect(projects.started.isCompleted, isTrue,
        reason: 'projects should have been requested');
    expect(posts.started.isCompleted, isTrue,
        reason: 'posts should not wait for projects to return');
    expect(users.started.isCompleted, isTrue,
        reason: '/me should not wait for projects and posts to return');

    projects.release.complete(const <Project>[]);
    posts.release.complete(const <Update>[]);
    users.release.complete(<String, dynamic>{'followedProjectIds': <String>[]});
    await refresh;
  });

  test('a failing /me still leaves projects and posts applied', () async {
    final projects = _GatedProjectsRepository();
    final posts = _GatedUpdatesRepository();
    final users = _GatedUsersRepository()..failMe = true;

    final store = ProjectsStore(
      projectsRepository: projects,
      postsRepository: posts,
      usersRepository: users,
    );

    final refresh = store.refreshProjects();
    await pumpEventQueue();

    projects.release.complete(const <Project>[]);
    posts.release.complete(const <Update>[]);
    await refresh;

    // /me failing is handled on its own and must not surface as a store error.
    expect(store.lastError, isNull);
  });
}
