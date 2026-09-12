-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "NotificationType" ADD VALUE 'project_update_requested';
ALTER TYPE "NotificationType" ADD VALUE 'project_reported_inactive';

-- CreateTable
CREATE TABLE "ProjectUpdateRequest" (
    "id" UUID NOT NULL,
    "projectId" UUID NOT NULL,
    "memberId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProjectUpdateRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProjectInactivityReport" (
    "id" UUID NOT NULL,
    "projectId" UUID NOT NULL,
    "reporterId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolvedAt" TIMESTAMP(3),
    "resolvedBy" UUID,

    CONSTRAINT "ProjectInactivityReport_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ProjectUpdateRequest_projectId_createdAt_idx" ON "ProjectUpdateRequest"("projectId", "createdAt");

-- CreateIndex
CREATE INDEX "ProjectUpdateRequest_memberId_projectId_createdAt_idx" ON "ProjectUpdateRequest"("memberId", "projectId", "createdAt");

-- CreateIndex
CREATE INDEX "ProjectInactivityReport_projectId_resolvedAt_idx" ON "ProjectInactivityReport"("projectId", "resolvedAt");

-- CreateIndex
CREATE UNIQUE INDEX "ProjectInactivityReport_projectId_reporterId_key" ON "ProjectInactivityReport"("projectId", "reporterId");

-- AddForeignKey
ALTER TABLE "ProjectUpdateRequest" ADD CONSTRAINT "ProjectUpdateRequest_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectUpdateRequest" ADD CONSTRAINT "ProjectUpdateRequest_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectInactivityReport" ADD CONSTRAINT "ProjectInactivityReport_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectInactivityReport" ADD CONSTRAINT "ProjectInactivityReport_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
