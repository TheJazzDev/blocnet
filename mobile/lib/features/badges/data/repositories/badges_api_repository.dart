import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/services/api/api_client.dart';

Map<String, dynamic> _asStringKeyMap(Object? raw) {
  if (raw is! Map) return const <String, dynamic>{};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

class BadgesApiRepository {
  BadgesApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Fetch all available badges
  Future<List<BadgeModel>> fetchAllBadges() async {
    final response = await _apiClient.get('/badges');
    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map>()
        .map((entry) => BadgeModel.fromApi(_asStringKeyMap(entry)))
        .toList();
  }

  /// Fetch badges earned by a specific user
  Future<UserBadgesResponse?> fetchUserBadges(String userId) async {
    final response = await _apiClient.get('/badges/users/$userId');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return UserBadgesResponse.fromApi(response);
  }

  /// Fetch current user's badges
  Future<UserBadgesResponse?> fetchMyBadges() async {
    final response = await _apiClient.get('/badges/me');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return UserBadgesResponse.fromApi(response);
  }

  /// Set user's primary badge (displayed next to username)
  Future<void> setPrimaryBadge(String badgeId) async {
    await _apiClient.put(
      '/badges/me/primary',
      body: {'badgeId': badgeId},
    );
  }
}
