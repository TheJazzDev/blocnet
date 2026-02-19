import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/services/api/api_client.dart';

class WalletApiRepository {
  WalletApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<WalletSnapshot?> fetchWalletSummary() async {
    try {
      final response = await _apiClient.get('/wallet/me');
      if (response is! Map<String, dynamic>) {
        return null;
      }
      return WalletSnapshot.fromApi(response);
    } on ApiException catch (error) {
      // Backward-compat for environments that haven't deployed wallet routes yet.
      if (error.statusCode == 404) {
        final meResponse = await _apiClient.get('/me');
        if (meResponse is! Map<String, dynamic>) {
          return null;
        }

        return WalletSnapshot(
          walletStatus:
              meResponse['walletStatus']?.toString() ?? 'provisioning',
          walletAddress: meResponse['walletAddress']?.toString(),
          available: '0',
          pending: '0',
          locked: '0',
          kycStatus: meResponse['kycStatus']?.toString() ?? 'not_submitted',
          kycTier: 'basic',
        );
      }
      rethrow;
    }
  }

  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/wallet/transactions',
        query: {
          'limit': '$limit',
          'offset': '$offset',
        },
      );

      if (response is! List) {
        return [];
      }

      return response
          .whereType<Map<String, dynamic>>()
          .map(WalletTransaction.fromApi)
          .toList();
    } on ApiException catch (error) {
      // Backward-compat for environments that haven't deployed wallet routes yet.
      if (error.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }
}
