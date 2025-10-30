/*
  Warnings:

  - You are about to drop the `donations` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `top_spenders` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropTable
DROP TABLE "public"."donations";

-- DropTable
DROP TABLE "public"."top_spenders";

-- CreateTable
CREATE TABLE "bagibagi_donations" (
    "id" SERIAL NOT NULL,
    "donationId" VARCHAR(255) NOT NULL,
    "donorName" VARCHAR(255) NOT NULL,
    "robloxUsername" VARCHAR(255),
    "amount" DOUBLE PRECISION NOT NULL,
    "message" TEXT,
    "rawData" JSONB,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bagibagi_donations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bagibagi_top_spenders" (
    "id" SERIAL NOT NULL,
    "robloxUsername" VARCHAR(255) NOT NULL,
    "totalAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "donationCount" INTEGER NOT NULL DEFAULT 0,
    "lastDonation" TIMESTAMPTZ NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "bagibagi_top_spenders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saweria_donations" (
    "id" SERIAL NOT NULL,
    "donationId" VARCHAR(255) NOT NULL,
    "donorName" VARCHAR(255) NOT NULL,
    "robloxUsername" VARCHAR(255),
    "amount" DOUBLE PRECISION NOT NULL,
    "message" TEXT,
    "rawData" JSONB,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saweria_donations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saweria_top_spenders" (
    "id" SERIAL NOT NULL,
    "robloxUsername" VARCHAR(255) NOT NULL,
    "totalAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "donationCount" INTEGER NOT NULL DEFAULT 0,
    "lastDonation" TIMESTAMPTZ NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "saweria_top_spenders_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "bagibagi_donations_donationId_key" ON "bagibagi_donations"("donationId");

-- CreateIndex
CREATE INDEX "bagibagi_donations_robloxUsername_idx" ON "bagibagi_donations"("robloxUsername");

-- CreateIndex
CREATE INDEX "bagibagi_donations_createdAt_idx" ON "bagibagi_donations"("createdAt" DESC);

-- CreateIndex
CREATE INDEX "bagibagi_donations_donationId_idx" ON "bagibagi_donations"("donationId");

-- CreateIndex
CREATE UNIQUE INDEX "bagibagi_top_spenders_robloxUsername_key" ON "bagibagi_top_spenders"("robloxUsername");

-- CreateIndex
CREATE INDEX "bagibagi_top_spenders_totalAmount_idx" ON "bagibagi_top_spenders"("totalAmount" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "saweria_donations_donationId_key" ON "saweria_donations"("donationId");

-- CreateIndex
CREATE INDEX "saweria_donations_robloxUsername_idx" ON "saweria_donations"("robloxUsername");

-- CreateIndex
CREATE INDEX "saweria_donations_createdAt_idx" ON "saweria_donations"("createdAt" DESC);

-- CreateIndex
CREATE INDEX "saweria_donations_donationId_idx" ON "saweria_donations"("donationId");

-- CreateIndex
CREATE UNIQUE INDEX "saweria_top_spenders_robloxUsername_key" ON "saweria_top_spenders"("robloxUsername");

-- CreateIndex
CREATE INDEX "saweria_top_spenders_totalAmount_idx" ON "saweria_top_spenders"("totalAmount" DESC);
