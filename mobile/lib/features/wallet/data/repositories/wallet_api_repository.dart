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
          assets: const [],
          totalUsdValue: '0',
          supportedAssets: const ['BNT'],
          transferEnabledAssets: const ['BNT'],
          withdrawalEnabledAssets: const ['BNT'],
        );
      }
      rethrow;
    }
  }

  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
    String? asset,
  }) async {
    try {
      final response = await _apiClient.get(
        '/wallet/transactions',
        query: {
          'limit': '$limit',
          'offset': '$offset',
          if (asset != null && asset.trim().isNotEmpty)
            'asset': asset.trim().toUpperCase(),
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

  Future<List<WalletWithdrawalRequest>> fetchWithdrawals({
    int limit = 50,
    int offset = 0,
    String? status,
    String? asset,
  }) async {
    try {
      final response = await _apiClient.get(
        '/wallet/withdrawals',
        query: {
          'limit': '$limit',
          'offset': '$offset',
          if (status != null && status.isNotEmpty) 'status': status,
          if (asset != null && asset.trim().isNotEmpty)
            'asset': asset.trim().toUpperCase(),
        },
      );

      if (response is! List) {
        return [];
      }

      return response
          .whereType<Map<String, dynamic>>()
          .map(WalletWithdrawalRequest.fromApi)
          .toList();
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  Future<WalletTransaction?> createInternalTransfer({
    required String amount,
    String? toUserId,
    String? toUsername,
    String? toAddress,
    String? asset,
    String? note,
    String? idempotencyKey,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount,
      if (asset != null && asset.trim().isNotEmpty)
        'asset': asset.trim().toUpperCase(),
      if (toUserId != null && toUserId.isNotEmpty) 'toUserId': toUserId,
      if (toUsername != null && toUsername.isNotEmpty) 'toUsername': toUsername,
      if (toAddress != null && toAddress.isNotEmpty) 'toAddress': toAddress,
      if (note != null && note.isNotEmpty) 'note': note,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };

    final response =
        await _apiClient.post('/wallet/transfers/internal', body: payload);
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return WalletTransaction.fromApi(response);
  }

  Future<WalletWithdrawalRequest?> createWithdrawal({
    required String toAddress,
    required String amount,
    required String reason,
    String? asset,
    String? idempotencyKey,
  }) async {
    final payload = <String, dynamic>{
      'toAddress': toAddress,
      'amount': amount,
      'reason': reason,
      if (asset != null && asset.trim().isNotEmpty)
        'asset': asset.trim().toUpperCase(),
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };

    final response =
        await _apiClient.post('/wallet/withdrawals', body: payload);
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return WalletWithdrawalRequest.fromApi(response);
  }
}
