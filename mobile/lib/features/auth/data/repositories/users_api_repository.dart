import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/profile/data/models/public_profile_model.dart';
import 'package:blocnet/features/projects/data/models/follow_preference_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class UsersApiRepository {
  UsersApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>?> fetchMe() async {
    final response = await _apiClient.get('/me');
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return response;
  }

  Future<Set<String>> fetchFollowedProjectIds() async {
    final response = await fetchMe();
    if (response == null) {
      return <String>{};
    }

    final values = response['followedProjectIds'];
    if (values is! List) {
      return <String>{};
    }

    return values.map((value) => value.toString()).toSet();
  }

  Map<String, FollowPreference> parseFollowPreferencesFromMe(
    Map<String, dynamic>? mePayload,
  ) {
    final entries = mePayload?['followedProjects'];
    if (entries is! List) {
      return const <String, FollowPreference>{};
    }

    final preferences = <String, FollowPreference>{};
    for (final raw in entries) {
      if (raw is! Map<String, dynamic>) continue;
      final projectId = raw['projectId']?.toString() ?? '';
      if (projectId.isEmpty) continue;
      preferences[projectId] = FollowPreference.fromApi(raw);
    }

    return preferences;
  }

  Future<Set<String>> fetchFollowedProfileIds() async {
    final response = await fetchMe();
    if (response == null) {
      return <String>{};
    }

    final values = response['followedProfileIds'];
    if (values is! List) {
      return <String>{};
    }

    return values.map((value) => value.toString()).toSet();
  }

  Future<List<Project>> fetchWatchlist(
      {int limit = 100, int offset = 0}) async {
    final response = await _apiClient.get(
      '/me/watchlist',
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

  Future<List<CommunityPost>> fetchBookmarks({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/me/bookmarks',
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
        .map(CommunityPost.fromApi)
        .toList();
  }

  Future<List<ActivityItem>> fetchActivity({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/me/activity',
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
        .map(ActivityItem.fromApi)
        .toList();
  }

  Future<void> followProfile(String profileId) async {
    await _apiClient.post('/profiles/$profileId/follow');
  }

  Future<void> unfollowProfile(String profileId) async {
    await _apiClient.delete('/profiles/$profileId/follow');
  }

  Future<RadarSummary?> fetchRadar() async {
    final response = await _apiClient.get('/me/radar');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return RadarSummary.fromApi(response);
  }

  Future<void> ackRadar({DateTime? seenAt}) async {
    await _apiClient.post(
      '/me/radar/ack',
      body: {
        if (seenAt != null) 'seenAt': seenAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<PublicProfileModel?> fetchPublicProfile(String profileId) async {
    final response = await _apiClient.get('/profiles/$profileId/public');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return PublicProfileModel.fromApi(response);
  }
}
