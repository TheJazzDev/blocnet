import 'package:blocnet/features/engagement/data/models/edge_feed_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class EdgeEngineApiRepository {
  EdgeEngineApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<EdgeFeedResponse?> fetchFeed({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _apiClient.get(
      '/me/edge/feed',
      query: {
        'limit': '$limit',
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return EdgeFeedResponse.fromApi(response);
  }
}
