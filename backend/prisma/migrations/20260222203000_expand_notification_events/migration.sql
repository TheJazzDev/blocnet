-- Expand notification enum values for event-driven notification fanout
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'profile_followed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'profile_unfollowed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'project_followed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'project_unfollowed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'community_liked';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'community_bookmarked';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'comment_received';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'project_proposal_submitted';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'project_proposal_reviewed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'admin_application_submitted';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'admin_application_reviewed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'project_invite_received';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'project_invite_responded';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'project_assignment_changed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'role_changed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_transfer_sent';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_transfer_received';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_deposit_credited';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_withdrawal_requested';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_withdrawal_approved';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_withdrawal_rejected';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_withdrawal_broadcasted';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_withdrawal_confirmed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_withdrawal_reverted';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_kyc_reviewed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_provision_ready';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'wallet_provision_failed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'mining_claimed';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'referral_bound';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'referral_admin_bound';

-- Add metadata fields used by in-app rendering and push routing
ALTER TABLE "Notification"
ADD COLUMN IF NOT EXISTS "actorUserId" UUID,
ADD COLUMN IF NOT EXISTS "payload" JSONB,
ADD COLUMN IF NOT EXISTS "deeplink" TEXT,
ADD COLUMN IF NOT EXISTS "dedupeKey" TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Notification_actorUserId_fkey'
  ) THEN
    ALTER TABLE "Notification"
    ADD CONSTRAINT "Notification_actorUserId_fkey"
    FOREIGN KEY ("actorUserId")
    REFERENCES "Profile"("id")
    ON DELETE SET NULL
    ON UPDATE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS "Notification_userId_isRead_createdAt_idx"
ON "Notification"("userId", "isRead", "createdAt");

CREATE INDEX IF NOT EXISTS "Notification_type_createdAt_idx"
ON "Notification"("type", "createdAt");

CREATE UNIQUE INDEX IF NOT EXISTS "Notification_userId_dedupeKey_key"
ON "Notification"("userId", "dedupeKey");
