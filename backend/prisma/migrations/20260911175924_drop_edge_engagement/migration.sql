/*
  Warnings:

  - You are about to drop the `EdgeEngagement` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "EdgeEngagement" DROP CONSTRAINT "EdgeEngagement_decisionRecordId_fkey";

-- DropForeignKey
ALTER TABLE "EdgeEngagement" DROP CONSTRAINT "EdgeEngagement_updateId_fkey";

-- DropForeignKey
ALTER TABLE "EdgeEngagement" DROP CONSTRAINT "EdgeEngagement_userId_fkey";

-- DropTable
DROP TABLE "EdgeEngagement";
