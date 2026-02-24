import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/updates_api_repository.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectsStore manageable helpers', () {
    test('manageableProjectIds includes owned and contributed projects', () {
      final store = ProjectsStore();
      store.addProject(_project(id: 'p1', adminId: 'u1', createdAt: 1));
      store.addProject(_project(id: 'p2', adminId: 'u2', createdAt: 2));
      store.addProject(_project(id: 'p3', adminId: 'u3', createdAt: 3));

      final updates = <Update>[
        _update(id: 'up1', adminId: 'u1', projectId: 'p2'),
        _update(id: 'up2', adminId: 'u2', projectId: 'p3'),
      ];

      final manageable = store.manageableProjectIds(
        userId: 'u1',
        updates: updates,
      );

      expect(manageable, equals({'p1', 'p2'}));
      expect(
        store.isProjectManageable(
          projectId: 'p2',
          userId: 'u1',
          updates: updates,
        ),
        isTrue,
      );
      expect(
        store.isProjectManageable(
          projectId: 'p3',
          userId: 'u1',
          updates: updates,
        ),
        isFalse,
      );
    });

    test('followedAndManagedProjects merges followed and managed ids',
        () async {
      final store = ProjectsStore(
        projectsRepository: _FakeProjectsApiRepository([
          _project(id: 'p1', adminId: 'u1', createdAt: 1),
          _project(id: 'p2', adminId: 'u2', createdAt: 2),
          _project(id: 'p3', adminId: 'u3', createdAt: 3),
        ]),
        postsRepository: _FakeUpdatesApiRepository(const []),
        usersRepository: _FakeUsersApiRepository(
          followedProjectIds: const ['p2'],
        ),
      );

      await store.refreshProjects();

      final merged = store.followedAndManagedProjects(
        userId: 'u1',
        updates: <Update>[_update(id: 'up-1', adminId: 'u1', projectId: 'p3')],
      );

      expect(
        merged.map((project) => project.id).toSet(),
        equals({'p1', 'p2', 'p3'}),
      );
    });
  });
}

Project _project({
  required String id,
  required String adminId,
  required int createdAt,
}) {
  return Project(
    id: id,
    name: 'Project $id',
    logo: '',
    details: '',
    adminId: adminId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    primaryTagId: 'tag-1',
    primaryTag: const PrimaryTag(id: 'tag-1', name: 'Infrastructure'),
    description: '',
    followersCount: 0,
  );
}

Update _update({
  required String id,
  required String adminId,
  required String projectId,
}) {
  return Update(
    id: id,
    title: 'Update $id',
    content: '...',
    adminId: adminId,
    priority: Priority.high,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1),
    projectId: projectId,
    description: 'desc',
    secondaryTagIds: const [],
    secondaryTags: const [],
  );
}

class _FakeProjectsApiRepository extends ProjectsApiRepository {
  _FakeProjectsApiRepository(this.projects);

  final List<Project> projects;

  @override
  Future<List<Project>> fetchProjects({int limit = 100, int offset = 0}) async {
    return projects;
  }

  @override
  Future<void> followProject(String projectId) async {}

  @override
  Future<void> unfollowProject(String projectId) async {}
}

class _FakeUpdatesApiRepository extends UpdatesApiRepository {
  _FakeUpdatesApiRepository(this.updates);

  final List<Update> updates;

  @override
  Future<List<Update>> fetchUpdates({int limit = 200, int offset = 0}) async {
    return updates;
  }
}

class _FakeUsersApiRepository extends UsersApiRepository {
  _FakeUsersApiRepository({required this.followedProjectIds});

  final List<String> followedProjectIds;

  @override
  Future<Map<String, dynamic>?> fetchMe() async {
    return <String, dynamic>{
      'followedProjectIds': followedProjectIds,
      'followedProjects': const <Map<String, dynamic>>[],
    };
  }
}
