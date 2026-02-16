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
}
