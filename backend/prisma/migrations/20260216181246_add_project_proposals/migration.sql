/*
  Warnings:

  - A unique constraint covering the columns `[normalizedName]` on the table `Project` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[symbol]` on the table `Project` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[websiteDomain]` on the table `Project` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "InviteStatus" AS ENUM ('pending', 'accepted', 'rejected', 'cancelled');

-- CreateEnum
CREATE TYPE "ProjectProposalStatus" AS ENUM ('pending', 'approved', 'rejected');

-- AlterTable
ALTER TABLE "Project" ADD COLUMN     "normalizedName" TEXT,
ADD COLUMN     "symbol" TEXT,
ADD COLUMN     "websiteDomain" TEXT,
ADD COLUMN     "websiteUrl" TEXT;

-- CreateTable
CREATE TABLE "ProjectPosterInvite" (
    "id" UUID NOT NULL,
    "projectId" UUID NOT NULL,
    "posterId" UUID NOT NULL,
    "invitedBy" UUID NOT NULL,
    "note" TEXT,
    "status" "InviteStatus" NOT NULL DEFAULT 'pending',
    "reviewedBy" UUID,
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProjectPosterInvite_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProjectProposal" (
    "id" UUID NOT NULL,
    "applicantId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "normalizedName" TEXT NOT NULL,
    "symbol" TEXT,
    "websiteUrl" TEXT,
    "websiteDomain" TEXT,
    "description" TEXT NOT NULL,
    "primaryTag" TEXT NOT NULL,
    "reason" TEXT,
    "status" "ProjectProposalStatus" NOT NULL DEFAULT 'pending',
    "reviewerId" UUID,
    "reviewNote" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "createdProjectId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProjectProposal_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ProjectPosterInvite_posterId_status_idx" ON "ProjectPosterInvite"("posterId", "status");

-- CreateIndex
CREATE INDEX "ProjectPosterInvite_projectId_status_idx" ON "ProjectPosterInvite"("projectId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "ProjectPosterInvite_projectId_posterId_key" ON "ProjectPosterInvite"("projectId", "posterId");

-- CreateIndex
CREATE INDEX "ProjectProposal_applicantId_status_idx" ON "ProjectProposal"("applicantId", "status");

-- CreateIndex
CREATE INDEX "ProjectProposal_status_createdAt_idx" ON "ProjectProposal"("status", "createdAt");

-- CreateIndex
CREATE INDEX "ProjectProposal_normalizedName_status_idx" ON "ProjectProposal"("normalizedName", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Project_normalizedName_key" ON "Project"("normalizedName");

-- CreateIndex
CREATE UNIQUE INDEX "Project_symbol_key" ON "Project"("symbol");

-- CreateIndex
CREATE UNIQUE INDEX "Project_websiteDomain_key" ON "Project"("websiteDomain");

-- AddForeignKey
ALTER TABLE "ProjectPosterInvite" ADD CONSTRAINT "ProjectPosterInvite_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectPosterInvite" ADD CONSTRAINT "ProjectPosterInvite_posterId_fkey" FOREIGN KEY ("posterId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectPosterInvite" ADD CONSTRAINT "ProjectPosterInvite_invitedBy_fkey" FOREIGN KEY ("invitedBy") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectPosterInvite" ADD CONSTRAINT "ProjectPosterInvite_reviewedBy_fkey" FOREIGN KEY ("reviewedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectProposal" ADD CONSTRAINT "ProjectProposal_applicantId_fkey" FOREIGN KEY ("applicantId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectProposal" ADD CONSTRAINT "ProjectProposal_reviewerId_fkey" FOREIGN KEY ("reviewerId") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectProposal" ADD CONSTRAINT "ProjectProposal_createdProjectId_fkey" FOREIGN KEY ("createdProjectId") REFERENCES "Project"("id") ON DELETE SET NULL ON UPDATE CASCADE;
