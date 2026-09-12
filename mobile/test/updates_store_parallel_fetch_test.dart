import 'dart:async';

import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/updates_api_repository.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// refreshUpdates fetched projects, then updates, one after the other, though
/// neither depends on the other's result — the same shape already fixed in
/// ProjectsStore. Two waits where one would do, on the feed's own refresh path.
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
  Future<List<Update>> fetchUpdates({int limit = 200, int offset = 0}) {
    if (!started.isCompleted) started.complete();
    return release.future;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('projects and updates are both in flight before either returns',
      () async {
    final projects = _GatedProjectsRepository();
    final updates = _GatedUpdatesRepository();

    final store = UpdatesStore(
      projectsRepository: projects,
      updatesRepository: updates,
    );

    final refresh = store.refreshUpdates();
    await pumpEventQueue();

    expect(projects.started.isCompleted, isTrue,
        reason: 'projects should have been requested');
    expect(updates.started.isCompleted, isTrue,
        reason: 'updates should not wait for projects to return');

    projects.release.complete(const <Project>[]);
    updates.release.complete(const <Update>[]);
    await refresh;
  });

  test('a failing fetch still settles the store', () async {
    final projects = _GatedProjectsRepository();
    final updates = _GatedUpdatesRepository();

    final store = UpdatesStore(
      projectsRepository: projects,
      updatesRepository: updates,
    );

    final refresh = store.refreshUpdates();
    await pumpEventQueue();

    projects.release.completeError(StateError('offline'));
    updates.release.complete(const <Update>[]);
    await refresh;

    expect(store.isFetching, isFalse);
  });
}
