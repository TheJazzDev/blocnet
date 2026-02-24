import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/services/api/api_client.dart';

Map<String, dynamic> _asStringKeyMap(Object? raw) {
  if (raw is! Map) return const <String, dynamic>{};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

class QuestsApiRepository {
  QuestsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Fetch all active quests
  Future<List<QuestModel>> fetchAllQuests() async {
    final response = await _apiClient.get('/quests');
    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map>()
        .map((entry) => QuestModel.fromApi(_asStringKeyMap(entry)))
        .toList();
  }

  /// Fetch current user's quests with progress
  Future<UserQuestsResponse?> fetchMyQuests({String? status}) async {
    final response = await _apiClient.get(
      '/quests/me',
      query: status != null ? {'status': status} : null,
    );
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return UserQuestsResponse.fromApi(response);
  }

  /// Fetch all quests with user progress
  Future<List<dynamic>> fetchQuestsWithProgress() async {
    final response = await _apiClient.get('/quests/me/with-progress');
    if (response is! List) {
      return [];
    }

    return response;
  }

  /// Start a quest
  Future<void> startQuest(String questSlug) async {
    await _apiClient.post('/quests/$questSlug/start', body: {});
  }

  /// Submit quest proof for manual verification
  Future<QuestSubmissionModel?> submitQuestProof({
    required String questSlug,
    String? proofUrl,
    String? proofText,
    String? screenshot,
  }) async {
    final response = await _apiClient.post(
      '/quests/$questSlug/submit',
      body: {
        if (proofUrl != null) 'proofUrl': proofUrl,
        if (proofText != null) 'proofText': proofText,
        if (screenshot != null) 'screenshot': screenshot,
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return QuestSubmissionModel.fromApi(response);
  }

  /// Claim quest reward (auto-verified quests only)
  Future<void> claimQuestReward(String questSlug) async {
    await _apiClient.post('/quests/$questSlug/claim', body: {});
  }
}
