import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/foundation.dart';

import '../models/mention_user_model.dart';

class MentionsRepository {
  final ApiClient _apiClient;

  MentionsRepository(this._apiClient);

  Future<List<MentionUserModel>> searchUsers(String query,
      {int limit = 10}) async {
    try {
      final normalizedQuery = query.trim().replaceAll('@', '');
      final response = await _apiClient.get(
        '/mentions/search',
        query: {
          'q': normalizedQuery,
          'limit': limit.toString(),
        },
      );

      final dynamic payload = response is Map<String, dynamic>
          ? (response['items'] ??
              response['users'] ??
              response['data'] ??
              const [])
          : response;
      if (payload is! List) return [];

      return payload
          .whereType<Map<String, dynamic>>()
          .map(MentionUserModel.fromJson)
          .toList();
    } catch (e) {
      debugPrint('Error searching users for mentions: $e');
      return [];
    }
  }
}
