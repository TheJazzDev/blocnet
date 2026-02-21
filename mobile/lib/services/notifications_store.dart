import 'package:blocnet/features/notifications/data/models/digest_summary_model.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/data/repositories/notifications_api_repository.dart';
import 'package:flutter/material.dart';

class NotificationsStore extends ChangeNotifier {
  NotificationsStore({NotificationsApiRepository? repository})
      : _repository = repository ?? NotificationsApiRepository();

  final NotificationsApiRepository _repository;

  final List<NotificationModel> _notifications = [];
  DigestSummary? _digestSummary;
  bool _isFetching = false;
  bool _isFetchingDigest = false;
  String? _lastError;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  DigestSummary? get digestSummary => _digestSummary;
  bool get isFetching => _isFetching;
  bool get isFetchingDigest => _isFetchingDigest;
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
      final digest = await _repository.fetchDigestSummary(windowDays: 7);
      _notifications
        ..clear()
        ..addAll(response);
      _digestSummary = digest;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> refreshDigestSummary({int windowDays = 7}) async {
    if (_isFetchingDigest) return;

    _isFetchingDigest = true;
    notifyListeners();
    try {
      _digestSummary =
          await _repository.fetchDigestSummary(windowDays: windowDays);
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isFetchingDigest = false;
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
