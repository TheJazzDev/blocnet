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
    return HunterApplicationModel.fromApi(_asStringMap(response));
  }

  /// `GET /admin-applications/mine?targetRole=hunter`: every application
  /// the current user filed for the role, newest first. Throws an
  /// [ApiException] with status 404 on deployments that predate the
  /// endpoint; callers fall back to local state in that case.
  Future<List<HunterApplicationModel>> fetchMine({
    String targetRole = 'hunter',
  }) async {
    final response = await _apiClient.get(
      '/admin-applications/mine',
      query: {'targetRole': targetRole},
    );
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => HunterApplicationModel.fromApi(_asStringMap(row)))
        .toList(growable: false);
  }

  static Map<String, dynamic> _asStringMap(Map raw) =>
      raw.map((key, value) => MapEntry(key.toString(), value));
}
