-- CreateEnum
CREATE TYPE "ProjectInviteKind" AS ENUM ('co_own', 'handover');

-- AlterTable
ALTER TABLE "ProjectHunterInvite" ADD COLUMN     "kind" "ProjectInviteKind" NOT NULL DEFAULT 'co_own';
