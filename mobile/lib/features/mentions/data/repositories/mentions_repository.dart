import 'package:blocnet/services/api/api_client.dart';
import '../models/mention_user_model.dart';

class MentionsRepository {
  final ApiClient _apiClient;

  MentionsRepository(this._apiClient);

  Future<List<MentionUserModel>> searchUsers(String query, {int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/mentions/search',
        query: {
          'q': query,
          'limit': limit.toString(),
        },
      );

      if (response is List) {
        return response
            .map((json) => MentionUserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error searching users for mentions: $e');
      return [];
    }
  }
}
