-- AlterTable
ALTER TABLE "Update" ADD COLUMN     "deadlineAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "Update_status_deadlineAt_idx" ON "Update"("status", "deadlineAt");
