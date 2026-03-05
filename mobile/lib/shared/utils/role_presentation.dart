Set<String> normalizeRoles(Iterable<String> roles) {
  return roles
      .map((role) => role.trim().toLowerCase())
      .where((role) => role.isNotEmpty)
      .toSet();
}

String? resolvePrimaryRoleKeyFromRoles(Iterable<String> roles) {
  final normalized = normalizeRoles(roles);

  if (normalized.contains('core_team')) return 'core_team';
  if (normalized.contains('community_admin') ||
      normalized.contains('owner') ||
      normalized.contains('dev') ||
      normalized.contains('admin')) {
    return 'community_admin';
  }
  if (normalized.contains('community_moderator') ||
      normalized.contains('moderator')) {
    return 'community_moderator';
  }
  if (normalized.contains('hunter')) return 'hunter';

  return null;
}

String? resolvePrimaryRoleLabelFromRoles(Iterable<String> roles) {
  final key = resolvePrimaryRoleKeyFromRoles(roles);
  switch (key) {
    case 'core_team':
      return 'CORE TEAM';
    case 'community_admin':
      return 'ADMIN';
    case 'community_moderator':
      return 'MODERATOR';
    case 'hunter':
      return 'HUNTER';
    default:
      return null;
  }
}
