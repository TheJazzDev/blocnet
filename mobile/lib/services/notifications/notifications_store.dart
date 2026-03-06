import 'dart:async';

import 'package:blocnet/features/notifications/data/models/digest_summary_model.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/data/repositories/notifications_api_repository.dart';
import 'package:blocnet/services/notifications/notification_target_resolver.dart';
import 'package:flutter/material.dart';

class NotificationsStore extends ChangeNotifier {
  NotificationsStore({NotificationsApiRepository? repository})
      : _repository = repository ?? NotificationsApiRepository();

  static const int _pageSize = 50;
  static const List<String> _categoryKeys = [
    'all',
    'updates',
    'social',
    'governance',
    'wallet',
    'mining_referrals',
    'rewards',
    'system',
  ];

  final NotificationsApiRepository _repository;
  final Map<String, _NotificationFeedState> _feeds = {};
  DigestSummary? _digestSummary;
  bool _isFetchingDigest = false;
  String _activeCategory = 'all';

  List<NotificationModel> get notifications =>
      List.unmodifiable(_activeFeed.items);
  DigestSummary? get digestSummary => _digestSummary;
  bool get isFetching => _activeFeed.isFetching;
  bool get isFetchingMore => _activeFeed.isFetchingMore;
  bool get isFetchingDigest => _isFetchingDigest;
  bool get hasMore => _activeFeed.hasMore;
  String get activeCategory => _activeCategory;
  String? get lastError => _activeFeed.lastError;

  int get unreadCount {
    final allFeed = _feeds['all'];
    final source = allFeed != null && allFeed.items.isNotEmpty
        ? allFeed.items
        : _activeFeed.items;
    return source.where((item) => !item.isRead).length;
  }

  Future<void> fetchNotificationsOnce({String? category}) async {
    final key = _normalizeCategory(category);
    if (_activeCategory != key) {
      _activeCategory = key;
    }

    _hydrateFromAllIfNeeded(key);
    if (_feedFor(key).items.isNotEmpty || _feedFor(key).isFetching) {
      notifyListeners();
      return;
    }
    await refreshNotifications(category: key);
  }

  void selectCategory(String category) {
    final key = _normalizeCategory(category);
    var shouldNotify = false;

    if (_activeCategory != key) {
      _activeCategory = key;
      shouldNotify = true;
    }

    if (_hydrateFromAllIfNeeded(key)) {
      shouldNotify = true;
    }

    final feed = _feedFor(key);
    if (!feed.fetchedFromBackend && !feed.isFetching) {
      unawaited(refreshNotifications(category: key));
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> refreshNotifications({String? category}) async {
    final key = _normalizeCategory(category ?? _activeCategory);
    final feed = _feedFor(key);
    if (feed.isFetching) return;

    feed
      ..isFetching = true
      ..lastError = null;
    notifyListeners();

    try {
      final useCategory = key != 'all';
      final response = await _repository.fetchNotifications(
        limit: _pageSize,
        offset: 0,
        category: useCategory ? key : null,
      );

      feed.items
        ..clear()
        ..addAll(response);
      feed
        ..hasMore = response.length >= _pageSize
        ..fetchedFromBackend = true;

      if (!useCategory) {
        _digestSummary = await _repository.fetchDigestSummary(windowDays: 7);
        _hydratePendingCategoryCachesFromAll();
      }
    } catch (error) {
      feed.lastError = error.toString();
    } finally {
      feed.isFetching = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNotifications({String? category}) async {
    final key = _normalizeCategory(category ?? _activeCategory);
    final feed = _feedFor(key);
    if (feed.isFetching || feed.isFetchingMore || !feed.hasMore) return;

    feed
      ..isFetchingMore = true
      ..lastError = null;
    notifyListeners();

    try {
      final useCategory = key != 'all';
      final response = await _repository.fetchNotifications(
        limit: _pageSize,
        offset: feed.items.length,
        category: useCategory ? key : null,
      );

      final existingIds = feed.items.map((item) => item.id).toSet();
      final append = response
          .where((item) => !existingIds.contains(item.id))
          .toList(growable: false);

      if (append.isNotEmpty) {
        feed.items.addAll(append);
      }

      if (response.length < _pageSize || append.isEmpty) {
        feed.hasMore = false;
      }

      if (!useCategory && append.isNotEmpty) {
        _hydratePendingCategoryCachesFromAll();
      }
    } catch (error) {
      feed.lastError = error.toString();
    } finally {
      feed.isFetchingMore = false;
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
      _activeFeed.lastError = null;
    } catch (error) {
      _activeFeed.lastError = error.toString();
    } finally {
      _isFetchingDigest = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    var changed = false;
    for (final feed in _feeds.values) {
      final index = feed.items.indexWhere((item) => item.id == notificationId);
      if (index == -1) continue;
      if (!feed.items[index].isRead) {
        feed.items[index] = feed.items[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }

    try {
      final updated = await _repository.markAsRead(notificationId);
      if (updated == null) return;

      for (final feed in _feeds.values) {
        final index =
            feed.items.indexWhere((item) => item.id == notificationId);
        if (index != -1) {
          feed.items[index] = updated;
        }
      }
      notifyListeners();
    } catch (_) {
      // Keep optimistic read state and rely on refresh.
    }
  }

  Future<void> markAllRead() async {
    final unreadIds = notifications
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toList();

    if (unreadIds.isEmpty) return;

    for (final id in unreadIds) {
      await markAsRead(id);
    }
  }

  bool _hydrateFromAllIfNeeded(String key) {
    if (key == 'all') return false;
    final target = _feedFor(key);
    if (target.items.isNotEmpty) return false;

    final allFeed = _feeds['all'];
    if (allFeed == null || allFeed.items.isEmpty) return false;

    target.items
      ..clear()
      ..addAll(_filterByCategory(allFeed.items, key));
    target.hasMore = true;
    return true;
  }

  void _hydratePendingCategoryCachesFromAll() {
    final allFeed = _feeds['all'];
    if (allFeed == null) return;

    for (final key in _categoryKeys) {
      if (key == 'all') continue;
      final feed = _feedFor(key);
      if (feed.fetchedFromBackend) continue;
      feed.items
        ..clear()
        ..addAll(_filterByCategory(allFeed.items, key));
      feed.hasMore = true;
    }
  }

  List<NotificationModel> _filterByCategory(
    List<NotificationModel> source,
    String category,
  ) {
    return source
        .where(
          (item) =>
              NotificationTargetResolver.categoryForType(item.type) == category,
        )
        .toList(growable: false);
  }

  _NotificationFeedState _feedFor(String key) {
    return _feeds.putIfAbsent(key, _NotificationFeedState.new);
  }

  _NotificationFeedState get _activeFeed => _feedFor(_activeCategory);

  String _normalizeCategory(String? category) {
    final normalized = category?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return 'all';
    return _categoryKeys.contains(normalized) ? normalized : 'all';
  }
}

class _NotificationFeedState {
  final List<NotificationModel> items = [];
  bool isFetching = false;
  bool isFetchingMore = false;
  bool hasMore = true;
  bool fetchedFromBackend = false;
  String? lastError;
}
