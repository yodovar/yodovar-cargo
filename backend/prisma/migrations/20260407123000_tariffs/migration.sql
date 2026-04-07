-- CreateTable
CREATE TABLE "Tariff" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "key" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "pricePerKgUsd" REAL NOT NULL,
    "pricePerCubicUsd" REAL NOT NULL,
    "minChargeWeightG" INTEGER NOT NULL,
    "etaDaysMin" INTEGER NOT NULL,
    "etaDaysMax" INTEGER NOT NULL,
    "detailsJson" TEXT NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "Tariff_key_key" ON "Tariff"("key");
