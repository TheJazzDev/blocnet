import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/edge_explain_model.dart';
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

  Future<EdgeBriefResponse?> fetchBrief({int windowDays = 7}) async {
    final response = await _apiClient.get(
      '/me/edge/brief',
      query: {
        'windowDays': '$windowDays',
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return EdgeBriefResponse.fromApi(response);
  }

  Future<EdgeExplainResponse?> fetchExplain(String decisionId) async {
    final response = await _apiClient.get('/me/edge/explain/$decisionId');
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return EdgeExplainResponse.fromApi(response);
  }

  Future<bool> sendFeedback({
    required String decisionId,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    final response = await _apiClient.post(
      '/me/edge/feedback',
      body: {
        'decisionId': decisionId,
        'action': action,
        if (context != null) 'context': context,
      },
    );

    if (response is! Map<String, dynamic>) {
      return false;
    }

    return response['ok'] == true;
  }
}
