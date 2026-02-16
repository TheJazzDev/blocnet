import 'package:blocnet/services/api/api_client.dart';

class ProjectProposalsApiRepository {
  ProjectProposalsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>?> submitProposal({
    required String name,
    String? symbol,
    String? websiteUrl,
    required String description,
    required String primaryTagId,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '/project-proposals',
      body: {
        'name': name,
        'symbol': symbol,
        'websiteUrl': websiteUrl,
        'description': description,
        'primaryTagId': primaryTagId,
        'reason': reason,
      },
    );

    if (response is! Map<String, dynamic>) return null;
    return response;
  }
}
