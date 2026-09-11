import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/services/api/api_client.dart';

Map<String, dynamic> _asStringKeyMap(Object? raw) {
  if (raw is! Map) return const <String, dynamic>{};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

/// Client for the hunter side of project assignments
/// (`/project-invites/*`).
class ProjectInvitesApiRepository {
  ProjectInvitesApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /project-invites/mine`. [status] is a backend `InviteStatus`.
  Future<List<ProjectInviteModel>> listMine({
    String? status,
    int limit = 30,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };
    final response =
        await _apiClient.get('/project-invites/mine', query: query);
    if (response is! List) return const <ProjectInviteModel>[];
    return response
        .whereType<Map>()
        .map((entry) => ProjectInviteModel.fromApi(_asStringKeyMap(entry)))
        .toList(growable: false);
  }

  /// `PATCH /project-invites/:inviteId/respond` with
  /// `status: accepted | rejected`.
  Future<ProjectInviteModel?> respond({
    required String inviteId,
    required bool accept,
  }) async {
    final response = await _apiClient.patch(
      '/project-invites/$inviteId/respond',
      body: {'status': accept ? 'accepted' : 'rejected'},
    );
    if (response is! Map) return null;
    return ProjectInviteModel.fromApi(_asStringKeyMap(response));
  }
}
