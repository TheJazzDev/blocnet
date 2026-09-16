import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// Chip label for the role a public profile leads with.
String publicProfileRoleLabel(String roleKey) {
  switch (roleKey) {
    case 'core_team':
      return 'CORE TEAM';
    case 'community_admin':
      return 'ADMIN';
    case 'community_moderator':
      return 'MODERATOR';
    case 'hunter':
      return 'HUNTER';
    default:
      return roleKey.toUpperCase();
  }
}

/// Chip text colour for that role; border and fill are tints of it.
Color publicProfileRoleTextColor(String roleKey) {
  switch (roleKey) {
    case 'core_team':
      return const Color(0xFF38BDF8);
    case 'hunter':
      return const Color(0xFFC084FC);
    case 'community_moderator':
      return const Color(0xFFF59E0B);
    case 'community_admin':
      return AppColors.primary400;
    default:
      return AppColors.textMuted;
  }
}
