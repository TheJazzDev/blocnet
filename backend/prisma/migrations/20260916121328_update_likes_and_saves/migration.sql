-- CreateTable
CREATE TABLE "UpdateLike" (
    "id" UUID NOT NULL,
    "updateId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UpdateLike_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UpdateBookmark" (
    "id" UUID NOT NULL,
    "updateId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UpdateBookmark_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "UpdateLike_updateId_idx" ON "UpdateLike"("updateId");

-- CreateIndex
CREATE INDEX "UpdateLike_userId_createdAt_idx" ON "UpdateLike"("userId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "UpdateLike_updateId_userId_key" ON "UpdateLike"("updateId", "userId");

-- CreateIndex
CREATE INDEX "UpdateBookmark_updateId_idx" ON "UpdateBookmark"("updateId");

-- CreateIndex
CREATE INDEX "UpdateBookmark_userId_createdAt_idx" ON "UpdateBookmark"("userId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "UpdateBookmark_updateId_userId_key" ON "UpdateBookmark"("updateId", "userId");

-- AddForeignKey
ALTER TABLE "UpdateLike" ADD CONSTRAINT "UpdateLike_updateId_fkey" FOREIGN KEY ("updateId") REFERENCES "Update"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UpdateLike" ADD CONSTRAINT "UpdateLike_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UpdateBookmark" ADD CONSTRAINT "UpdateBookmark_updateId_fkey" FOREIGN KEY ("updateId") REFERENCES "Update"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UpdateBookmark" ADD CONSTRAINT "UpdateBookmark_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
