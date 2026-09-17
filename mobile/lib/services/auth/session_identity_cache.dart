import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Who the signed-in user was the last time the backend confirmed it.
class SessionIdentity {
  const SessionIdentity({
    required this.userId,
    required this.roles,
    this.email,
    this.displayName,
    this.username,
    this.avatarUrl,
  });

  final String userId;
  final List<String> roles;
  final String? email;
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'roles': roles,
        'email': email,
        'displayName': displayName,
        'username': username,
        'avatarUrl': avatarUrl,
      };

  static SessionIdentity? fromJson(Object? json) {
    if (json is! Map) return null;
    final userId = json['userId']?.toString();
    final rawRoles = json['roles'];
    if (userId == null || userId.isEmpty || rawRoles is! List) return null;
    final roles = rawRoles
        .map((role) => role.toString())
        .where((role) => role.isNotEmpty)
        .toList();
    if (roles.isEmpty) return null;
    return SessionIdentity(
      userId: userId,
      roles: roles,
      email: json['email']?.toString(),
      displayName: json['displayName']?.toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

/// Persists the last confirmed [SessionIdentity] so a cold start without a
/// connection still knows the user's roles instead of falling back to a bare
/// `user`. [MeSnapshotCache] is in-memory and short-lived; this survives
/// restarts. Cleared on every sign-out.
class SessionIdentityCache {
  SessionIdentityCache._();

  static const String _key = 'blocnet_session_identity_v1';

  static Future<void> save(SessionIdentity identity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(identity.toJson()));
    } catch (_) {
      // Losing the cache only costs the offline fallback.
    }
  }

  static Future<SessionIdentity?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      return SessionIdentity.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Nothing else to do.
    }
  }
}
