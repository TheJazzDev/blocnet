import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class NotificationsApiRepository {
  NotificationsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NotificationModel>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/notifications',
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
        .map(NotificationModel.fromApi)
        .toList();
  }

  Future<NotificationModel?> markAsRead(String notificationId) async {
    final response =
        await _apiClient.patch('/notifications/$notificationId/read');

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return NotificationModel.fromApi(response);
  }
}
