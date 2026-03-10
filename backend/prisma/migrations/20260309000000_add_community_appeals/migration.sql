-- Manual migration for Community Appeals System
-- Apply this when you have database connectivity
-- This bypasses the prisma migrate issue with verify_fixed

-- CreateEnum
CREATE TYPE "CommunityAppealStatus" AS ENUM ('pending', 'under_review', 'approved', 'rejected');

-- CreateEnum
CREATE TYPE "CommunityAppealDecision" AS ENUM ('overturn', 'uphold', 'partial');

-- CreateTable
CREATE TABLE "CommunityReportAppeal" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "reportId" UUID NOT NULL,
    "appealerId" UUID NOT NULL,
    "reason" TEXT NOT NULL,
    "status" "CommunityAppealStatus" NOT NULL DEFAULT 'pending',
    "reviewedById" UUID,
    "reviewedAt" TIMESTAMP(3),
    "reviewNotes" TEXT,
    "decision" "CommunityAppealDecision",
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CommunityReportAppeal_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "CommunityReportAppeal_appealerId_idx" ON "CommunityReportAppeal"("appealerId");

-- CreateIndex
CREATE INDEX "CommunityReportAppeal_status_idx" ON "CommunityReportAppeal"("status");

-- CreateIndex
CREATE INDEX "CommunityReportAppeal_createdAt_idx" ON "CommunityReportAppeal"("createdAt");

-- CreateIndex
CREATE INDEX "CommunityReportAppeal_reportId_idx" ON "CommunityReportAppeal"("reportId");

-- AddForeignKey
ALTER TABLE "CommunityReportAppeal" ADD CONSTRAINT "CommunityReportAppeal_reportId_fkey" FOREIGN KEY ("reportId") REFERENCES "CommunityModerationReport"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommunityReportAppeal" ADD CONSTRAINT "CommunityReportAppeal_appealerId_fkey" FOREIGN KEY ("appealerId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommunityReportAppeal" ADD CONSTRAINT "CommunityReportAppeal_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- After applying this SQL, run: bunx prisma db pull to sync the schema
-- Then run: bunx prisma generate to update the client
