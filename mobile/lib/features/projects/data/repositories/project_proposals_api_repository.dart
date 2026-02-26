import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/features/projects/data/models/project_proposal_model.dart';

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

  Future<List<ProjectProposalModel>> listMine({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    final normalizedStatus = status?.trim().toLowerCase();
    if (normalizedStatus != null &&
        normalizedStatus.isNotEmpty &&
        normalizedStatus != 'all') {
      query['status'] = normalizedStatus;
    }

    final response = await _apiClient.get('/project-proposals/mine', query: query);
    if (response is! List) return const <ProjectProposalModel>[];

    return response
        .whereType<Map<String, dynamic>>()
        .map(ProjectProposalModel.fromApi)
        .toList(growable: false);
  }
}
