-- Ensure EdgeEngagement.id keeps the UUID default expected by Prisma migrations.
-- Safe and idempotent.
DO $$
BEGIN
  IF to_regclass('"EdgeEngagement"') IS NOT NULL THEN
    ALTER TABLE "EdgeEngagement"
      ALTER COLUMN "id" SET DEFAULT gen_random_uuid();
  END IF;
END
$$;
