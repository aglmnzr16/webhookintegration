-- CreateTable
CREATE TABLE "donations" (
    "id" SERIAL NOT NULL,
    "donorName" VARCHAR(255) NOT NULL,
    "robloxUsername" VARCHAR(255),
    "amount" INTEGER NOT NULL,
    "message" TEXT,
    "source" VARCHAR(50) NOT NULL DEFAULT 'saweria',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "donations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "top_spenders" (
    "id" SERIAL NOT NULL,
    "robloxUsername" VARCHAR(255) NOT NULL,
    "totalAmount" INTEGER NOT NULL DEFAULT 0,
    "donationCount" INTEGER NOT NULL DEFAULT 0,
    "lastDonation" TIMESTAMPTZ NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "top_spenders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "webhook_logs" (
    "id" SERIAL NOT NULL,
    "payload" TEXT NOT NULL,
    "processed" BOOLEAN NOT NULL DEFAULT false,
    "error" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "webhook_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "donations_robloxUsername_idx" ON "donations"("robloxUsername");

-- CreateIndex
CREATE INDEX "donations_createdAt_idx" ON "donations"("createdAt" DESC);

-- CreateIndex
CREATE INDEX "donations_source_idx" ON "donations"("source");

-- CreateIndex
CREATE UNIQUE INDEX "top_spenders_robloxUsername_key" ON "top_spenders"("robloxUsername");

-- CreateIndex
CREATE INDEX "top_spenders_totalAmount_idx" ON "top_spenders"("totalAmount" DESC);

-- CreateIndex
CREATE INDEX "webhook_logs_processed_idx" ON "webhook_logs"("processed");

-- CreateIndex
CREATE INDEX "webhook_logs_createdAt_idx" ON "webhook_logs"("createdAt" DESC);
