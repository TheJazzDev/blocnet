import { NotificationCategory, NotificationType } from '@prisma/client';

export const NOTIFICATION_CATEGORY_ORDER: NotificationCategory[] = [
  NotificationCategory.updates,
  NotificationCategory.social,
  NotificationCategory.governance,
  NotificationCategory.wallet,
  NotificationCategory.mining_referrals,
  NotificationCategory.rewards,
  NotificationCategory.system,
];

export const NOTIFICATION_CATEGORY_LABELS: Record<
  NotificationCategory,
  string
> = {
  [NotificationCategory.updates]: 'Updates',
  [NotificationCategory.social]: 'Social',
  [NotificationCategory.governance]: 'Governance',
  [NotificationCategory.wallet]: 'Wallet',
  [NotificationCategory.mining_referrals]: 'Mining & Referrals',
  [NotificationCategory.rewards]: 'Rewards',
  [NotificationCategory.system]: 'System',
};

export const NOTIFICATION_TYPES_BY_CATEGORY: Record<
  NotificationCategory,
  NotificationType[]
> = {
  [NotificationCategory.updates]: [
    NotificationType.project_update,
    NotificationType.comment_received,
    NotificationType.project_followed,
    NotificationType.project_unfollowed,
  ],
  [NotificationCategory.social]: [
    NotificationType.profile_followed,
    NotificationType.profile_unfollowed,
    NotificationType.community_liked,
    NotificationType.community_bookmarked,
  ],
  [NotificationCategory.governance]: [
    NotificationType.project_proposal_submitted,
    NotificationType.project_proposal_reviewed,
    NotificationType.admin_application_submitted,
    NotificationType.admin_application_reviewed,
    NotificationType.project_invite_received,
    NotificationType.project_invite_responded,
    NotificationType.project_assignment_changed,
  ],
  [NotificationCategory.wallet]: [
    NotificationType.wallet_transfer_sent,
    NotificationType.wallet_transfer_received,
    NotificationType.wallet_deposit_credited,
    NotificationType.wallet_withdrawal_requested,
    NotificationType.wallet_withdrawal_approved,
    NotificationType.wallet_withdrawal_rejected,
    NotificationType.wallet_withdrawal_broadcasted,
    NotificationType.wallet_withdrawal_confirmed,
    NotificationType.wallet_withdrawal_reverted,
    NotificationType.wallet_kyc_reviewed,
    NotificationType.wallet_provision_ready,
    NotificationType.wallet_provision_failed,
  ],
  [NotificationCategory.mining_referrals]: [
    NotificationType.mining_claimed,
    NotificationType.referral_bound,
    NotificationType.referral_admin_bound,
  ],
  [NotificationCategory.rewards]: [
    NotificationType.badge_earned,
    NotificationType.quest_completed,
    NotificationType.quest_verified,
    NotificationType.quest_rejected,
  ],
  [NotificationCategory.system]: [
    NotificationType.system,
    NotificationType.role_changed,
  ],
};

export const NOTIFICATION_TYPE_TO_CATEGORY: Record<
  NotificationType,
  NotificationCategory
> = Object.values(NotificationType).reduce(
  (acc, type) => {
    const category = NOTIFICATION_CATEGORY_ORDER.find((candidate) =>
      NOTIFICATION_TYPES_BY_CATEGORY[candidate].includes(type),
    );
    acc[type] = category ?? NotificationCategory.system;
    return acc;
  },
  {} as Record<NotificationType, NotificationCategory>,
);

export const CRITICAL_NOTIFICATION_TYPES = new Set<NotificationType>([
  NotificationType.role_changed,
  NotificationType.wallet_withdrawal_approved,
  NotificationType.wallet_withdrawal_rejected,
  NotificationType.wallet_withdrawal_broadcasted,
  NotificationType.wallet_withdrawal_confirmed,
  NotificationType.wallet_withdrawal_reverted,
  NotificationType.wallet_kyc_reviewed,
  NotificationType.wallet_provision_failed,
]);

export const DEFAULT_DIGEST_HOUR_LOCAL = 8;
export const DEFAULT_DIGEST_MINUTE_LOCAL = 0;
export const DEFAULT_TIMEZONE = 'UTC';

export function isCriticalNotificationType(type: NotificationType): boolean {
  return CRITICAL_NOTIFICATION_TYPES.has(type);
}
