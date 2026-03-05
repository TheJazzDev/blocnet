import 'package:blocnet/features/system_alerts/data/models/system_alert_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class SystemAlertsApiRepository {
  SystemAlertsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<SystemAlertModel>> fetchSystemAlerts({
    int limit = 50,
    int offset = 0,
    String status = 'all',
  }) async {
    final response = await _apiClient.get(
      '/audit-log/system-alerts',
      query: {
        'limit': '$limit',
        'offset': '$offset',
        'status': status,
      },
    );

    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(SystemAlertModel.fromApi)
        .toList();
  }
}
