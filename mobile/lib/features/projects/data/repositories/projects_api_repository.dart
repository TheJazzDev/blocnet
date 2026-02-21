import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class ProjectsApiRepository {
  ProjectsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Project>> fetchProjects({int limit = 100, int offset = 0}) async {
    final response = await _apiClient.get(
      '/projects',
      query: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(Project.fromApi)
        .toList();
  }

  Future<Project?> fetchProjectById(String id) async {
    final response = await _apiClient.get('/projects/$id');

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return Project.fromApi(response);
  }

  Future<void> followProject(String projectId) async {
    await _apiClient.post('/projects/$projectId/follow');
  }

  Future<void> unfollowProject(String projectId) async {
    await _apiClient.delete('/projects/$projectId/follow');
  }

  Future<Map<String, dynamic>?> updateFollowPreferences(
    String projectId, {
    String? alertMinUrgency,
    DateTime? mutedUntil,
    bool clearMute = false,
  }) async {
    final body = <String, dynamic>{};
    if (alertMinUrgency != null) {
      body['alertMinUrgency'] = alertMinUrgency;
    }

    if (clearMute) {
      body['mutedUntil'] = null;
    } else if (mutedUntil != null) {
      body['mutedUntil'] = mutedUntil.toUtc().toIso8601String();
    }

    final response = await _apiClient.patch(
      '/projects/$projectId/follow/preferences',
      body: body,
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return response;
  }

  Future<Map<String, dynamic>?> fetchFollowPreferences(String projectId) async {
    final response =
        await _apiClient.get('/projects/$projectId/follow/preferences');
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return response;
  }
}
