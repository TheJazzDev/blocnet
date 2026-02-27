import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

class MentionProfileNavigator {
  MentionProfileNavigator._();

  static final MentionsRepository _mentionsRepository =
      MentionsRepository(ApiClient());
  static final Map<String, Admin> _profileCache = <String, Admin>{};
  static final Map<String, Future<Admin?>> _inFlightLookups =
      <String, Future<Admin?>>{};

  static Future<void> openFromUsername(
    BuildContext context,
    String mentionUsername,
  ) async {
    final normalizedUsername = _normalizeUsername(mentionUsername);
    if (normalizedUsername.isEmpty) return;

    final admin = await _resolveAdmin(normalizedUsername);
    if (!context.mounted) return;

    if (admin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this profile right now.')),
      );
      return;
    }

    await PublicProfileScreen.showSheet(context, admin);
  }

  static Future<Admin?> _resolveAdmin(String normalizedUsername) async {
    final cached = _profileCache[normalizedUsername];
    if (cached != null) return cached;

    final pending = _inFlightLookups[normalizedUsername];
    if (pending != null) {
      return pending;
    }

    final lookup = _lookupAdmin(normalizedUsername);
    _inFlightLookups[normalizedUsername] = lookup;

    try {
      final resolved = await lookup;
      if (resolved != null) {
        _profileCache[normalizedUsername] = resolved;
      }
      return resolved;
    } finally {
      _inFlightLookups.remove(normalizedUsername);
    }
  }

  static Future<Admin?> _lookupAdmin(String normalizedUsername) async {
    final users = await _mentionsRepository.searchUsers(
      normalizedUsername,
      limit: 20,
    );
    if (users.isEmpty) return null;

    final exact = users.where(
      (candidate) =>
          _normalizeUsername(candidate.username) == normalizedUsername &&
          candidate.id.trim().isNotEmpty,
    );
    final resolvedUser = exact.isNotEmpty
        ? exact.first
        : users.firstWhere(
            (candidate) => candidate.id.trim().isNotEmpty,
            orElse: () => users.first,
          );

    final displayName = (resolvedUser.displayName?.trim().isNotEmpty ?? false)
        ? resolvedUser.displayName!.trim()
        : resolvedUser.username.replaceAll('@', '');
    final username = resolvedUser.username.trim().isNotEmpty
        ? resolvedUser.username.trim()
        : normalizedUsername;

    return Admin(
      id: resolvedUser.id,
      name: displayName.isNotEmpty ? displayName : 'User',
      username: username.startsWith('@') ? username : '@$username',
      imageUrl: resolvedUser.avatarUrl?.trim() ?? '',
      followers: 0,
      roles: const [],
    );
  }

  static String _normalizeUsername(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
  }
}
