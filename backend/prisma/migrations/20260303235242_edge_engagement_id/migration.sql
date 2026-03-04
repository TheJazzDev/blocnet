-- AlterTable
ALTER TABLE "AdminTotpRecoveryCode" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "AdminTwoFactorSession" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "EdgeEngagement" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "SocialCredential" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "UserLevel" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "UserLevelProgress" ALTER COLUMN "id" DROP DEFAULT;
