import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/features/hunter/data/repositories/project_invites_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/projects/project_invites_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

Map<String, dynamic> _invite(String id, {String status = 'pending'}) => {
      'id': id,
      'projectId': 'proj-$id',
      'hunterId': 'me',
      'invitedBy': 'admin',
      'note': 'Please hunt this one',
      'status': status,
      'createdAt': '2026-09-01T00:00:00Z',
      'project': {'id': 'proj-$id', 'name': 'Gem $id', 'slug': 'gem-$id'},
    };

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(httpClient: _NoopHttpClient());

  final List<String> calls = <String>[];
  Map<String, dynamic>? lastBody;
  bool failRespond = false;

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    calls.add('GET $path');
    expect(path, '/project-invites/mine');
    return [_invite('a'), _invite('b', status: 'accepted')];
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    calls.add('PATCH $path');
    lastBody = body;
    if (failRespond) {
      throw ApiException(
        'Request failed',
        statusCode: 403,
        responseBody: '{"message":"You can only respond to your own invites"}',
      );
    }
    final id = path.split('/')[2];
    return _invite(id, status: body!['status'] as String);
  }
}

void main() {
  test('ProjectInviteModel parses the project summary', () {
    final model = ProjectInviteModel.fromApi(_invite('x'));
    expect(model.projectName, 'Gem x');
    expect(model.projectSlug, 'gem-x');
    expect(model.note, 'Please hunt this one');
    expect(model.isPending, isTrue);
  });

  test('loadMine keeps only pending invites in pendingInvites', () async {
    final api = _FakeApiClient();
    final store = ProjectInvitesStore(
      repository: ProjectInvitesApiRepository(apiClient: api),
    );

    await store.loadMine();

    expect(store.invites.length, 2);
    expect(store.pendingInvites.map((i) => i.id), ['a']);
    expect(store.hasLoaded, isTrue);

    await store.loadMine();
    expect(api.calls.where((c) => c.startsWith('GET')).length, 1,
        reason: 'second call without force is a no-op');
  });

  test('accepting an invite sends status=accepted and drops it from pending',
      () async {
    final api = _FakeApiClient();
    final store = ProjectInvitesStore(
      repository: ProjectInvitesApiRepository(apiClient: api),
    );
    await store.loadMine();

    final ok = await store.respond('a', accept: true);

    expect(ok, isTrue);
    expect(api.calls.last, 'PATCH /project-invites/a/respond');
    expect(api.lastBody, {'status': 'accepted'});
    expect(store.pendingInvites, isEmpty);
    expect(store.invites.firstWhere((i) => i.id == 'a').status, 'accepted');
  });

  test('declining sends status=rejected', () async {
    final api = _FakeApiClient();
    final store = ProjectInvitesStore(
      repository: ProjectInvitesApiRepository(apiClient: api),
    );
    await store.loadMine();

    await store.respond('a', accept: false);

    expect(api.lastBody, {'status': 'rejected'});
    expect(store.invites.firstWhere((i) => i.id == 'a').status, 'rejected');
  });

  test('a failed response surfaces the backend message', () async {
    final api = _FakeApiClient()..failRespond = true;
    final store = ProjectInvitesStore(
      repository: ProjectInvitesApiRepository(apiClient: api),
    );
    await store.loadMine();

    final ok = await store.respond('a', accept: true);

    expect(ok, isFalse);
    expect(store.lastError, 'You can only respond to your own invites');
    expect(store.pendingInvites.length, 1);
  });
}
