import 'package:flutter/foundation.dart';
import 'package:blocnet/services/api/api_client.dart';

class BlockedUser {
  final String id;
  final String blockerId;
  final String blockedId;
  final String? reason;
  final DateTime createdAt;
  final BlockedUserProfile blocked;

  BlockedUser({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    this.reason,
    required this.createdAt,
    required this.blocked,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final blockedJson = json['blocked'];
    if (blockedJson is! Map<String, dynamic>) {
      throw FormatException('Missing blocked user payload');
    }

    return BlockedUser(
      id: (json['id'] ?? '').toString(),
      blockerId: (json['blockerId'] ?? '').toString(),
      blockedId: (json['blockedId'] ?? '').toString(),
      reason: json['reason']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      blocked: BlockedUserProfile.fromJson(blockedJson),
    );
  }
}

class BlockedUserProfile {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  BlockedUserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory BlockedUserProfile.fromJson(Map<String, dynamic> json) {
    return BlockedUserProfile(
      id: (json['id'] ?? '').toString(),
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class BlocksStore extends ChangeNotifier {
  final ApiClient _apiClient;

  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = false;
  String? _error;

  BlocksStore(this._apiClient);

  List<BlockedUser> get blockedUsers => _blockedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBlockedUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/blocks');
      if (response is List) {
        _blockedUsers = response
            .whereType<Map<String, dynamic>>()
            .map(BlockedUser.fromJson)
            .toList();
        _error = null;
      } else {
        _error = 'Unexpected blocked users response';
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> blockUser(String userId, {String? reason}) async {
    _error = null;

    try {
      final response = await _apiClient.post(
        '/blocks',
        body: {
          'blockedId': userId,
          if (reason != null) 'reason': reason,
        },
      );

      if (response is Map<String, dynamic>) {
        try {
          final blockedUser = BlockedUser.fromJson(response);
          _blockedUsers
              .removeWhere((b) => b.blockedId == blockedUser.blockedId);
          _blockedUsers.insert(0, blockedUser);
        } on FormatException {
          // Existing block responses may omit nested user; refresh canonical list.
          await fetchBlockedUsers();
        }
        notifyListeners();
        return true;
      } else {
        _error = 'Unexpected block response';
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    _error = null;

    try {
      final response = await _apiClient.delete('/blocks/$userId');

      if (response == null ||
          response is! Map<String, dynamic> ||
          response['deleted'] == true) {
        _blockedUsers.removeWhere((b) => b.blockedId == userId);
        notifyListeners();
        return true;
      } else {
        _error = 'Unexpected unblock response';
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> isBlocked(String userId) async {
    try {
      final response = await _apiClient.get('/blocks/check/$userId');
      if (response is Map<String, dynamic>) {
        return response['blocked'] == true;
      }
      return false;
    } on ApiException {
      return false;
    } catch (e) {
      return false;
    }
  }

  bool isUserBlocked(String userId) {
    return _blockedUsers.any((b) => b.blockedId == userId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
