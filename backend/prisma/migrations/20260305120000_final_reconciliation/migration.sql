-- Final reconciliation migration to sync Prisma with database state
-- This migration ensures all schema changes are properly tracked

-- Ensure EdgeEngagement id has the correct default
DO $$
BEGIN
  -- Only update if the default is not already set
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'EdgeEngagement'
      AND column_name = 'id'
      AND column_default IS NULL
  ) THEN
    ALTER TABLE "EdgeEngagement" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();
  END IF;
END $$;
