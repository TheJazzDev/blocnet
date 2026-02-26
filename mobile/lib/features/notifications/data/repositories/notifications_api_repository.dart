import 'package:blocnet/features/notifications/data/models/digest_summary_model.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/data/models/notification_preferences_model.dart';
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

  Future<DigestSummary?> fetchDigestSummary({int windowDays = 7}) async {
    final response = await _apiClient.get(
      '/me/digest/summary',
      query: {'windowDays': '$windowDays'},
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return DigestSummary.fromApi(response);
  }

  Future<NotificationPreferencesCatalog> fetchPreferenceCatalog() async {
    final response = await _apiClient.get('/notifications/preferences/catalog');
    if (response is! Map<String, dynamic>) {
      return const NotificationPreferencesCatalog(
        categories: [],
        criticalTypes: [],
      );
    }

    return NotificationPreferencesCatalog.fromApi(response);
  }

  Future<NotificationPreferences?> fetchPreferences() async {
    final response = await _apiClient.get('/notifications/preferences');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return NotificationPreferences.fromApi(response);
  }

  Future<NotificationPreferences?> updatePreferences({
    Map<String, dynamic>? body,
  }) async {
    final response = await _apiClient.patch(
      '/notifications/preferences',
      body: body,
    );
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return NotificationPreferences.fromApi(response);
  }
}
