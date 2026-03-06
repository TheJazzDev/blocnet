export const COMMUNITY_REPORT_TARGET_TYPE = {
  community_post: 'community_post',
  community_comment: 'community_comment',
  user_profile: 'user_profile',
} as const;

export type CommunityReportTargetType =
  (typeof COMMUNITY_REPORT_TARGET_TYPE)[keyof typeof COMMUNITY_REPORT_TARGET_TYPE];

export const COMMUNITY_REPORT_STATUS = {
  open: 'open',
  resolved: 'resolved',
  dismissed: 'dismissed',
} as const;

export type CommunityReportStatus =
  (typeof COMMUNITY_REPORT_STATUS)[keyof typeof COMMUNITY_REPORT_STATUS];

export const COMMUNITY_ACTION_TYPE = {
  warning: 'warning',
  mute: 'mute',
  suspend: 'suspend',
  restrict_posting: 'restrict_posting',
  restrict_commenting: 'restrict_commenting',
  clear_restrictions: 'clear_restrictions',
} as const;

export type CommunityActionType =
  (typeof COMMUNITY_ACTION_TYPE)[keyof typeof COMMUNITY_ACTION_TYPE];
