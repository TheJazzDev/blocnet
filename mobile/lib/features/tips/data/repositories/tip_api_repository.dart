import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/services/api/api_client.dart';

class TipApiRepository {
  TipApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<TipOverview?> fetchOverview() async {
    final response = await _apiClient.get('/tips/me');
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return TipOverview.fromApi(response);
  }

  Future<TipHistoryResponse?> fetchHistory({
    int limit = 30,
    int offset = 0,
    String direction = 'all',
    String? currencyCode,
  }) async {
    final response = await _apiClient.get(
      '/tips/history',
      query: {
        'limit': '$limit',
        'offset': '$offset',
        if (direction.trim().isNotEmpty) 'direction': direction.trim(),
        if (currencyCode != null && currencyCode.trim().isNotEmpty)
          'currencyCode': currencyCode.trim().toUpperCase(),
      },
    );
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return TipHistoryResponse.fromApi(response);
  }

  Future<TipTransaction?> sendTip({
    required String amount,
    String? toUserId,
    String? toUsername,
    String? currencyCode,
    String? note,
    String? contextType,
    String? contextId,
    String? idempotencyKey,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount.trim(),
      if (toUserId != null && toUserId.trim().isNotEmpty)
        'toUserId': toUserId.trim(),
      if (toUsername != null && toUsername.trim().isNotEmpty)
        'toUsername': toUsername.trim(),
      if (currencyCode != null && currencyCode.trim().isNotEmpty)
        'currencyCode': currencyCode.trim().toUpperCase(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (contextType != null && contextType.trim().isNotEmpty)
        'contextType': contextType.trim(),
      if (contextId != null && contextId.trim().isNotEmpty)
        'contextId': contextId.trim(),
      if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty)
        'idempotencyKey': idempotencyKey.trim(),
    };

    final response = await _apiClient.post('/tips/send', body: payload);
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return TipTransaction.fromApi(response);
  }
}
