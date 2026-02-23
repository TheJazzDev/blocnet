import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:flutter/material.dart';

class UserProfileStore extends ChangeNotifier {
  UserProfileStore({UsersApiRepository? usersRepository})
      : _usersRepository = usersRepository ?? UsersApiRepository();

  final UsersApiRepository _usersRepository;

  final List<Project> _watchlist = [];
  final List<CommunityPost> _bookmarks = [];
  final List<ActivityItem> _activity = [];
  int _followingProfilesCount = 0;
  String? _boundUserId;

  bool _initialized = false;
  bool _isLoadingWatchlist = false;
  bool _isLoadingBookmarks = false;
  bool _isLoadingActivity = false;
  bool _isLoadingFollowingProfiles = false;
  String? _lastError;

  List<Project> get watchlist => List.unmodifiable(_watchlist);
  List<CommunityPost> get bookmarks => List.unmodifiable(_bookmarks);
  List<ActivityItem> get activity => List.unmodifiable(_activity);
  int get followingProfilesCount => _followingProfilesCount;

  bool get isLoadingWatchlist => _isLoadingWatchlist;
  bool get isLoadingBookmarks => _isLoadingBookmarks;
  bool get isLoadingActivity => _isLoadingActivity;
  bool get isLoadingFollowingProfiles => _isLoadingFollowingProfiles;
  bool get isLoadingAny =>
      _isLoadingWatchlist ||
      _isLoadingBookmarks ||
      _isLoadingActivity ||
      _isLoadingFollowingProfiles;
  String? get lastError => _lastError;

  Future<void> fetchInitialOnce({String? userId}) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      if (_boundUserId != null) {
        _boundUserId = null;
        _resetState(notify: false);
        _initialized = false;
      }
    } else if (_boundUserId != normalizedUserId) {
      _boundUserId = normalizedUserId;
      _resetState(notify: false);
      _initialized = false;
    }

    if (_initialized) return;
    _initialized = true;
    await refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshWatchlist(),
      refreshBookmarks(),
      refreshActivity(),
      refreshFollowingProfiles(),
    ]);
  }

  Future<void> refreshFollowingProfiles() async {
    if (_isLoadingFollowingProfiles) return;

    _isLoadingFollowingProfiles = true;
    notifyListeners();

    try {
      final me = await _usersRepository.fetchMe();
      final followingCountRaw = me?['followingCount'];
      final parsed = int.tryParse(followingCountRaw?.toString() ?? '');

      if (parsed != null) {
        _followingProfilesCount = parsed;
      } else {
        final followedProfileIds = me?['followedProfileIds'];
        _followingProfilesCount =
            followedProfileIds is List ? followedProfileIds.length : 0;
      }
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isLoadingFollowingProfiles = false;
      notifyListeners();
    }
  }

  void applyFollowingProfilesDelta(int delta) {
    final next = (_followingProfilesCount + delta).clamp(0, 1 << 31);
    if (next == _followingProfilesCount) return;
    _followingProfilesCount = next;
    notifyListeners();
  }

  void clear() {
    _boundUserId = null;
    _resetState(notify: true);
    _initialized = false;
  }

  Future<void> refreshWatchlist() async {
    if (_isLoadingWatchlist) return;

    _isLoadingWatchlist = true;
    notifyListeners();

    try {
      final items = await _usersRepository.fetchWatchlist(limit: 200);
      _watchlist
        ..clear()
        ..addAll(items);
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isLoadingWatchlist = false;
      notifyListeners();
    }
  }

  Future<void> refreshBookmarks() async {
    if (_isLoadingBookmarks) return;

    _isLoadingBookmarks = true;
    notifyListeners();

    try {
      final items = await _usersRepository.fetchBookmarks(limit: 200);
      _bookmarks
        ..clear()
        ..addAll(items);
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isLoadingBookmarks = false;
      notifyListeners();
    }
  }

  Future<void> refreshActivity() async {
    if (_isLoadingActivity) return;

    _isLoadingActivity = true;
    notifyListeners();

    try {
      final items = await _usersRepository.fetchActivity(limit: 200);
      _activity
        ..clear()
        ..addAll(items);
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isLoadingActivity = false;
      notifyListeners();
    }
  }

  void _resetState({required bool notify}) {
    _watchlist.clear();
    _bookmarks.clear();
    _activity.clear();
    _followingProfilesCount = 0;
    _lastError = null;
    _isLoadingWatchlist = false;
    _isLoadingBookmarks = false;
    _isLoadingActivity = false;
    _isLoadingFollowingProfiles = false;
    if (notify) {
      notifyListeners();
    }
  }
}
