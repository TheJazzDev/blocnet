import 'package:blocnet/features/hunter/data/models/hunter_application_model.dart';
import 'package:blocnet/services/api/api_client.dart';

/// Client for the role-application endpoints used by Become a Hunter.
class HunterApplicationsApiRepository {
  HunterApplicationsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `POST /admin-applications` with `targetRole: 'hunter'`. The backend
  /// rejects a second application while one is still pending (400).
  Future<HunterApplicationModel?> applyForHunter({
    required String reason,
  }) async {
    final response = await _apiClient.post(
      '/admin-applications',
      body: {
        'targetRole': 'hunter',
        'reason': reason,
      },
    );
    if (response is! Map) return null;
    return HunterApplicationModel.fromApi(
      response.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
