DO $$
BEGIN
  IF to_regclass('"SocialCredential"') IS NOT NULL THEN
    ALTER TABLE "SocialCredential" ALTER COLUMN "id" DROP DEFAULT;
  END IF;
END
$$;
