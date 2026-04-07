-- AlterTable
ALTER TABLE "User" ADD COLUMN "clientCode" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "User_clientCode_key" ON "User"("clientCode");
