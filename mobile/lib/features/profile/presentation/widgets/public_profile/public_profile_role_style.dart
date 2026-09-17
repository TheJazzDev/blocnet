import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// Pill label for the role a public profile leads with.
String publicProfileRoleLabel(String roleKey) {
  switch (roleKey) {
    case 'core_team':
      return 'Core team';
    case 'community_admin':
      return 'Admin';
    case 'community_moderator':
      return 'Moderator';
    case 'hunter':
      return 'Hunter';
    default:
      return roleKey.replaceAll('_', ' ');
  }
}

/// Pill colour for that role, from the app palette.
Color publicProfileRoleColor(String roleKey) {
  switch (roleKey) {
    case 'core_team':
      return AppColors.tagInfo;
    case 'hunter':
      return AppColors.tagPartnership;
    case 'community_moderator':
      return AppColors.warning500;
    case 'community_admin':
      return AppColors.primary400;
    default:
      return AppColors.textMuted;
  }
}
