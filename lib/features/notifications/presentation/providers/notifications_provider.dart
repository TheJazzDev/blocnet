import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/fcm_service.dart';

class NotificationsProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();
  final FCMService _fcmService = FCMService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize(String userId) async {
    try {
      await _fcmService.initialize(userId);
    } catch (e) {
      print('FCM initialization error: $e');
      // Continue even if FCM fails
    }
  }

  void listenToNotifications(String userId) {
    _repository.getUserNotifications(userId).listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              ))
          .toList();
      notifyListeners();
    });

    _repository.getUnreadCount(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.markAllAsRead(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
