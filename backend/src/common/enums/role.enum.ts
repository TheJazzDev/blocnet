export enum AppRole {
  OWNER = 'owner',
  DEV = 'dev',
  ADMIN = 'admin',
  COMMUNITY_ADMIN = 'community_admin',
  COMMUNITY_MODERATOR = 'community_moderator',
  // Legacy role retained for compatibility with pre-migration records.
  MODERATOR = 'moderator',
  CORE_TEAM = 'core_team',
  HUNTER = 'hunter',
  USER = 'user',
}
