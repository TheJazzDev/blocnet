import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_leaderboard_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/data/models/reliability_json.dart';
import 'package:blocnet/services/api/api_client.dart';

/// Client for hunter reliability (`/hunters/*`, `/me/hunter/board`).
class HunterReliabilityApiRepository {
  HunterReliabilityApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /me/hunter/board`. 403 for accounts that cannot hunt.
  Future<HunterBoard> fetchBoard() async {
    final response = await _apiClient.get('/me/hunter/board');
    return HunterBoard.fromApi(jsonMap(response));
  }

  /// `GET /hunters/:profileId/reliability`.
  Future<HunterReliability> fetchReliability(String profileId) async {
    final response =
        await _apiClient.get('/hunters/${profileId.trim()}/reliability');
    return HunterReliability.fromApi(jsonMap(response));
  }

  /// `GET /hunters/leaderboard?limit&cursor`.
  Future<HunterLeaderboardPage> fetchLeaderboard({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _apiClient.get(
      '/hunters/leaderboard',
      query: {
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return HunterLeaderboardPage.fromApi(jsonMap(response));
  }
}
