import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/services/api/api_client.dart';

class MiningApiRepository {
  MiningApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<MiningSnapshot?> fetchMiningSnapshot() async {
    final response = await _apiClient.get('/mining/me');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return MiningSnapshot.fromApi(response);
  }

  Future<void> startMining() async {
    await _apiClient.post('/mining/start', body: {});
  }

  Future<void> claimMining() async {
    await _apiClient.post('/mining/claim', body: {});
  }

  Future<ReferralValidation?> validateReferralCode(String code) async {
    final response = await _apiClient.get(
      '/referrals/validate',
      query: {'code': code.trim().toUpperCase()},
    );
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return ReferralValidation.fromApi(response);
  }

  Future<void> bindReferralCode(String code) async {
    await _apiClient.post(
      '/referrals/bind',
      body: {'code': code.trim().toUpperCase()},
    );
  }

  Future<DownlineResponse?> fetchDownline({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/referrals/downline',
      query: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return DownlineResponse.fromApi(response);
  }

  Future<MiningLeaderboardResponse?> fetchLeaderboard({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/mining/leaderboard',
      query: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return MiningLeaderboardResponse.fromApi(response);
  }
}
