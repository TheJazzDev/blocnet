import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';

/// Presentation metadata for one of the three app spaces.
///
/// Spaces are a client-side view mode over the same account: the backend
/// only knows roles. Which spaces are available is derived from
/// [AuthStore] role getters; nothing here decides permissions.
class SpaceMeta {
  const SpaceMeta._({
    required this.id,
    required this.label,
    required this.description,
    required this.purpose,
    required this.icon,
    required this.accent,
  });

  /// Stable id used by [AuthStore.activeSpace] ('user' | 'hunter' |
  /// 'moderation').
  final String id;

  /// Short chip / sheet label.
  final String label;

  /// One-line subtitle for the switcher sheet.
  final String description;

  /// Longer explanation used by the one-time explainer.
  final String purpose;
  final IconData icon;
  final Color accent;

  static const SpaceMeta user = SpaceMeta._(
    id: 'user',
    label: 'User',
    description: 'Social feed and community',
    purpose:
        'Find Gems, follow updates, mine BNP, tip Hunters and join the community.',
    icon: Icons.public_rounded,
    accent: AppColors.userAccent,
  );

  static final SpaceMeta hunter = SpaceMeta._(
    id: 'hunter',
    label: 'Hunter',
    description: 'Post updates and manage your gems',
    purpose:
        'Post Updates for the Gems assigned to you, submit new Gems and track your hunter stats and tips.',
    icon: Icons.radar_rounded,
    accent: AppColors.hunterAccent,
  );

  static const SpaceMeta moderation = SpaceMeta._(
    id: 'moderation',
    label: 'Moderation',
    description: 'Community moderation hub',
    purpose:
        'Review reports and appeals and keep the community safe.',
    icon: Icons.shield_rounded,
    accent: AppColors.moderationAccent,
  );

  static SpaceMeta byId(String id) {
    switch (id) {
      case 'hunter':
        return hunter;
      case 'moderation':
        return moderation;
      case 'user':
      default:
        return user;
    }
  }

  /// The space the user is currently viewing.
  static SpaceMeta currentFor(AuthStore auth) {
    if (auth.isInModerationSpace) return moderation;
    if (auth.isInHunterSpace) return hunter;
    return user;
  }

  /// Spaces the user can switch into, in display order. Always contains
  /// [user].
  static List<SpaceMeta> availableFor(AuthStore auth) {
    return [
      user,
      if (auth.hasHunterSpace) hunter,
      if (auth.hasModerationSpace) moderation,
    ];
  }
}
