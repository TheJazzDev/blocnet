import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class UpdatesApiRepository {
  UpdatesApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Update>> fetchUpdates({int limit = 200, int offset = 0}) async {
    final response = await _apiClient.get(
      '/updates',
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
        .map(Update.fromApi)
        .toList();
  }

  Future<Update?> createUpdate({
    required String projectId,
    required String title,
    required String content,
    required Priority priority,
    List<String>? secondaryTagIds,
  }) async {
    final response = await _apiClient.post(
      '/projects/$projectId/updates',
      body: {
        'title': title,
        'contentMd': content,
        'urgency': _priorityToUrgency(priority),
        'secondaryTagIds': secondaryTagIds ?? const [],
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return Update.fromApi(response);
  }

  Future<Update?> updateUpdate(Update update) async {
    final response = await _apiClient.patch(
      '/updates/${update.id}',
      body: {
        'title': update.title,
        'contentMd': update.content,
        'urgency': _priorityToUrgency(update.priority),
        'secondaryTagIds': update.secondaryTagIds,
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return Update.fromApi(response);
  }

  String _priorityToUrgency(Priority priority) {
    final value = priority.toString().toLowerCase();

    if (value.contains('high')) return 'high';
    if (value.contains('mid') || value.contains('medium')) return 'medium';
    return 'low';
  }

  // Backward-compatible aliases during migration.
  Future<List<Update>> fetchPosts({int limit = 200, int offset = 0}) =>
      fetchUpdates(limit: limit, offset: offset);
  Future<Update?> createPost({
    required String projectId,
    required String title,
    required String content,
    required Priority priority,
    List<String>? secondaryTagIds,
  }) =>
      createUpdate(
        projectId: projectId,
        title: title,
        content: content,
        priority: priority,
        secondaryTagIds: secondaryTagIds,
      );
  Future<Update?> updatePost(Update update) => updateUpdate(update);
}
