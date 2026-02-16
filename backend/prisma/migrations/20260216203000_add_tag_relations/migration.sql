-- Tag catalogs
CREATE TABLE "PrimaryTag" (
  "id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "slug" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "PrimaryTag_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SecondaryTag" (
  "id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "slug" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "SecondaryTag_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "PrimaryTag_name_key" ON "PrimaryTag"("name");
CREATE UNIQUE INDEX "PrimaryTag_slug_key" ON "PrimaryTag"("slug");
CREATE UNIQUE INDEX "SecondaryTag_name_key" ON "SecondaryTag"("name");
CREATE UNIQUE INDEX "SecondaryTag_slug_key" ON "SecondaryTag"("slug");

-- Seed primary tags from existing text fields
INSERT INTO "PrimaryTag" ("id", "name", "slug", "createdAt", "updatedAt")
SELECT gen_random_uuid(), x.name, lower(regexp_replace(trim(x.name), '[^a-zA-Z0-9\s-]', '', 'g'))::text, NOW(), NOW()
FROM (
  SELECT DISTINCT "primaryTag" AS name FROM "Project" WHERE "primaryTag" IS NOT NULL
  UNION
  SELECT DISTINCT "primaryTag" AS name FROM "ProjectProposal" WHERE "primaryTag" IS NOT NULL
) x
ON CONFLICT ("name") DO NOTHING;

ALTER TABLE "Project" ADD COLUMN "primaryTagId" UUID;
ALTER TABLE "ProjectProposal" ADD COLUMN "primaryTagId" UUID;

UPDATE "Project" p
SET "primaryTagId" = pt."id"
FROM "PrimaryTag" pt
WHERE lower(pt."name") = lower(p."primaryTag");

UPDATE "ProjectProposal" pp
SET "primaryTagId" = pt."id"
FROM "PrimaryTag" pt
WHERE lower(pt."name") = lower(pp."primaryTag");

ALTER TABLE "Project" ALTER COLUMN "primaryTagId" SET NOT NULL;
ALTER TABLE "ProjectProposal" ALTER COLUMN "primaryTagId" SET NOT NULL;

ALTER TABLE "Project" ADD CONSTRAINT "Project_primaryTagId_fkey"
  FOREIGN KEY ("primaryTagId") REFERENCES "PrimaryTag"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ProjectProposal" ADD CONSTRAINT "ProjectProposal_primaryTagId_fkey"
  FOREIGN KEY ("primaryTagId") REFERENCES "PrimaryTag"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Project" DROP COLUMN "primaryTag";
ALTER TABLE "ProjectProposal" DROP COLUMN "primaryTag";

-- Project secondary tags
CREATE TABLE "ProjectSecondaryTag" (
  "id" UUID NOT NULL,
  "projectId" UUID NOT NULL,
  "secondaryTagId" UUID NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ProjectSecondaryTag_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ProjectSecondaryTag_projectId_secondaryTagId_key"
  ON "ProjectSecondaryTag"("projectId", "secondaryTagId");
CREATE INDEX "ProjectSecondaryTag_secondaryTagId_idx"
  ON "ProjectSecondaryTag"("secondaryTagId");

ALTER TABLE "ProjectSecondaryTag" ADD CONSTRAINT "ProjectSecondaryTag_projectId_fkey"
  FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProjectSecondaryTag" ADD CONSTRAINT "ProjectSecondaryTag_secondaryTagId_fkey"
  FOREIGN KEY ("secondaryTagId") REFERENCES "SecondaryTag"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Update secondary tags
CREATE TABLE "UpdateSecondaryTag" (
  "id" UUID NOT NULL,
  "updateId" UUID NOT NULL,
  "secondaryTagId" UUID NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UpdateSecondaryTag_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "UpdateSecondaryTag_updateId_secondaryTagId_key"
  ON "UpdateSecondaryTag"("updateId", "secondaryTagId");
CREATE INDEX "UpdateSecondaryTag_secondaryTagId_idx"
  ON "UpdateSecondaryTag"("secondaryTagId");

ALTER TABLE "UpdateSecondaryTag" ADD CONSTRAINT "UpdateSecondaryTag_updateId_fkey"
  FOREIGN KEY ("updateId") REFERENCES "Update"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UpdateSecondaryTag" ADD CONSTRAINT "UpdateSecondaryTag_secondaryTagId_fkey"
  FOREIGN KEY ("secondaryTagId") REFERENCES "SecondaryTag"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
