import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/data/repositories/notifications_api_repository.dart';
import 'package:flutter/material.dart';

class NotificationsStore extends ChangeNotifier {
  NotificationsStore({NotificationsApiRepository? repository})
      : _repository = repository ?? NotificationsApiRepository();

  final NotificationsApiRepository _repository;

  final List<NotificationModel> _notifications = [];
  bool _isFetching = false;
  String? _lastError;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isFetching => _isFetching;
  String? get lastError => _lastError;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> fetchNotificationsOnce() async {
    if (_notifications.isNotEmpty || _isFetching) return;
    await refreshNotifications();
  }

  Future<void> refreshNotifications() async {
    if (_isFetching) return;
    _isFetching = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _repository.fetchNotifications();
      _notifications
        ..clear()
        ..addAll(response);
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index =
        _notifications.indexWhere((item) => item.id == notificationId);
    if (index == -1) return;

    if (!_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      notifyListeners();
    }

    try {
      final updated = await _repository.markAsRead(notificationId);
      if (updated != null) {
        final refreshedIndex =
            _notifications.indexWhere((item) => item.id == notificationId);
        if (refreshedIndex != -1) {
          _notifications[refreshedIndex] = updated;
          notifyListeners();
        }
      }
    } catch (_) {
      // Keep optimistic read state and rely on next refresh.
    }
  }

  Future<void> markAllRead() async {
    final unreadIds = _notifications
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toList();

    if (unreadIds.isEmpty) return;

    for (final id in unreadIds) {
      await markAsRead(id);
    }
  }
}
