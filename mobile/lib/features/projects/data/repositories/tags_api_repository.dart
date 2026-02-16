import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class TagsApiRepository {
  TagsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PrimaryTag>> fetchPrimaryTags() async {
    final response = await _apiClient.get('/tags/primary');
    if (response is! List) return [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(PrimaryTag.fromApi)
        .toList();
  }

  Future<List<SecondaryTag>> fetchSecondaryTags() async {
    final response = await _apiClient.get('/tags/secondary');
    if (response is! List) return [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(SecondaryTag.fromApi)
        .toList();
  }
}
