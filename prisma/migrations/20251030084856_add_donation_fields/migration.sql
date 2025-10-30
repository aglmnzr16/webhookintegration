/*
  Warnings:

  - A unique constraint covering the columns `[donationId]` on the table `donations` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `donationId` to the `donations` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "donations" ADD COLUMN     "donationId" VARCHAR(255) NOT NULL,
ADD COLUMN     "rawData" JSONB,
ALTER COLUMN "amount" SET DATA TYPE DOUBLE PRECISION;

-- AlterTable
ALTER TABLE "top_spenders" ALTER COLUMN "totalAmount" SET DEFAULT 0,
ALTER COLUMN "totalAmount" SET DATA TYPE DOUBLE PRECISION;

-- CreateIndex
CREATE UNIQUE INDEX "donations_donationId_key" ON "donations"("donationId");

-- CreateIndex
CREATE INDEX "donations_donationId_idx" ON "donations"("donationId");
