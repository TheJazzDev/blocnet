/*
  Warnings:

  - The values [poster] on the enum `ApplicationTargetRole` will be removed. If these variants are still used in the database, this will fail.
  - The values [poster] on the enum `RoleName` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the `ProjectPoster` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `ProjectPosterInvite` table. If the table is not empty, all the data it contains will be lost.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "ApplicationTargetRole_new" AS ENUM ('admin', 'hunter');
ALTER TABLE "public"."AdminApplication" ALTER COLUMN "targetRole" DROP DEFAULT;
ALTER TABLE "AdminApplication" ALTER COLUMN "targetRole" TYPE "ApplicationTargetRole_new" USING ("targetRole"::text::"ApplicationTargetRole_new");
ALTER TYPE "ApplicationTargetRole" RENAME TO "ApplicationTargetRole_old";
ALTER TYPE "ApplicationTargetRole_new" RENAME TO "ApplicationTargetRole";
DROP TYPE "public"."ApplicationTargetRole_old";
ALTER TABLE "AdminApplication" ALTER COLUMN "targetRole" SET DEFAULT 'admin';
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "RoleName_new" AS ENUM ('owner', 'admin', 'hunter', 'user');
ALTER TABLE "UserRole" ALTER COLUMN "role" TYPE "RoleName_new" USING ("role"::text::"RoleName_new");
ALTER TYPE "RoleName" RENAME TO "RoleName_old";
ALTER TYPE "RoleName_new" RENAME TO "RoleName";
DROP TYPE "public"."RoleName_old";
COMMIT;

-- DropForeignKey
ALTER TABLE "ProjectPoster" DROP CONSTRAINT "ProjectPoster_posterId_fkey";

-- DropForeignKey
ALTER TABLE "ProjectPoster" DROP CONSTRAINT "ProjectPoster_projectId_fkey";

-- DropForeignKey
ALTER TABLE "ProjectPosterInvite" DROP CONSTRAINT "ProjectPosterInvite_invitedBy_fkey";

-- DropForeignKey
ALTER TABLE "ProjectPosterInvite" DROP CONSTRAINT "ProjectPosterInvite_posterId_fkey";

-- DropForeignKey
ALTER TABLE "ProjectPosterInvite" DROP CONSTRAINT "ProjectPosterInvite_projectId_fkey";

-- DropForeignKey
ALTER TABLE "ProjectPosterInvite" DROP CONSTRAINT "ProjectPosterInvite_reviewedBy_fkey";

-- AlterTable
ALTER TABLE "Update" RENAME CONSTRAINT "Post_pkey" TO "Update_pkey";

-- DropTable
DROP TABLE "ProjectPoster";

-- DropTable
DROP TABLE "ProjectPosterInvite";

-- CreateTable
CREATE TABLE "ProjectHunter" (
    "id" UUID NOT NULL,
    "projectId" UUID NOT NULL,
    "hunterId" UUID NOT NULL,
    "assignedBy" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProjectHunter_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProjectHunterInvite" (
    "id" UUID NOT NULL,
    "projectId" UUID NOT NULL,
    "hunterId" UUID NOT NULL,
    "invitedBy" UUID NOT NULL,
    "note" TEXT,
    "status" "InviteStatus" NOT NULL DEFAULT 'pending',
    "reviewedBy" UUID,
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProjectHunterInvite_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ProjectHunter_hunterId_idx" ON "ProjectHunter"("hunterId");

-- CreateIndex
CREATE UNIQUE INDEX "ProjectHunter_projectId_hunterId_key" ON "ProjectHunter"("projectId", "hunterId");

-- CreateIndex
CREATE INDEX "ProjectHunterInvite_hunterId_status_idx" ON "ProjectHunterInvite"("hunterId", "status");

-- CreateIndex
CREATE INDEX "ProjectHunterInvite_projectId_status_idx" ON "ProjectHunterInvite"("projectId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "ProjectHunterInvite_projectId_hunterId_key" ON "ProjectHunterInvite"("projectId", "hunterId");

-- AddForeignKey
ALTER TABLE "ProjectHunter" ADD CONSTRAINT "ProjectHunter_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectHunter" ADD CONSTRAINT "ProjectHunter_hunterId_fkey" FOREIGN KEY ("hunterId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectHunterInvite" ADD CONSTRAINT "ProjectHunterInvite_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectHunterInvite" ADD CONSTRAINT "ProjectHunterInvite_hunterId_fkey" FOREIGN KEY ("hunterId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectHunterInvite" ADD CONSTRAINT "ProjectHunterInvite_invitedBy_fkey" FOREIGN KEY ("invitedBy") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectHunterInvite" ADD CONSTRAINT "ProjectHunterInvite_reviewedBy_fkey" FOREIGN KEY ("reviewedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;
