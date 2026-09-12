import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/users/me_snapshot_cache.dart';

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
    try {
      await _apiClient.post('/projects/$projectId/follow');
    } finally {
      // `/me` carries `followedProjectIds` + `followedProjects`; drop the
      // snapshot even on failure, which may still have applied server-side.
      MeSnapshotCache.invalidate();
    }
  }

  Future<void> unfollowProject(String projectId) async {
    try {
      await _apiClient.delete('/projects/$projectId/follow');
    } finally {
      MeSnapshotCache.invalidate();
    }
  }

  /// Asks this gem's hunter for an update.
  ///
  /// Followers only, once per member per gem per week. However many members
  /// ask, the hunter is notified once per gem per week with the count, so this
  /// is a way to reach a hunter rather than a way to pile on one.
  ///
  /// Returns how many members are waiting, or null when the call failed.
  Future<int?> requestUpdate(String projectId) async {
    final response = await _apiClient.post(
      '/projects/$projectId/request-update',
    );
    if (response is! Map<String, dynamic>) return null;
    return int.tryParse(response['membersWaiting']?.toString() ?? '');
  }

  /// Reports that this gem has been abandoned.
  ///
  /// Raises it to moderators; it does not reassign the gem, because taking
  /// coverage away from a hunter is a decision a person makes. Returns the
  /// number of open reports.
  Future<int?> reportInactive(String projectId) async {
    final response = await _apiClient.post(
      '/projects/$projectId/report-inactive',
    );
    if (response is! Map<String, dynamic>) return null;
    return int.tryParse(response['openReports']?.toString() ?? '');
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

    final dynamic response;
    try {
      response = await _apiClient.patch(
        '/projects/$projectId/follow/preferences',
        body: body,
      );
    } finally {
      // Preferences are mirrored in `/me`'s `followedProjects`.
      MeSnapshotCache.invalidate();
    }

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
