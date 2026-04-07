-- CreateTable
CREATE TABLE "SupportContact" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "key" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "usernameOrPhone" TEXT NOT NULL,
    "appUrl" TEXT NOT NULL,
    "webUrl" TEXT NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "SupportContact_key_key" ON "SupportContact"("key");
