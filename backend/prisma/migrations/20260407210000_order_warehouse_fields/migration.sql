-- AlterTable
ALTER TABLE "Order" ADD COLUMN "clientId" TEXT;
ALTER TABLE "Order" ADD COLUMN "weightGrams" INTEGER;
ALTER TABLE "Order" ADD COLUMN "handedOverAt" DATETIME;
