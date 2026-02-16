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
}
