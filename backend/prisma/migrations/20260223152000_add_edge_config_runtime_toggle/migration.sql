CREATE TABLE IF NOT EXISTS "EdgeConfig" (
  "id" TEXT NOT NULL,
  "enabled" BOOLEAN NOT NULL DEFAULT true,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "EdgeConfig_pkey" PRIMARY KEY ("id")
);
