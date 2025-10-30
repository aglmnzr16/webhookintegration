# ⚠️ DONATION ACCUMULATION ISSUE - Not Summing Properly

## 🐛 Problem Reported

**Issue:** Donation amounts **ditimpa** (overwrite), bukan **dijumlahkan** (accumulated)

**Example:**
```
User donate Rp. 1.000 → Shows: Rp. 1.000 ✅
User donate Rp. 2.000 → Shows: Rp. 2.000 ❌ (should be Rp. 3.000!)
```

---

## 🔍 Root Cause Analysis

### Current Flow:

```
[BagiBagi Webhook] 
    ↓ POST donation data
[Backend API]
    ↓ Save to database (per transaction)
    ↓ GET /api/roblox/top-spenders
[Roblox] 
    ↓ Fetch and display
[Top Board] Shows: Rp. 2.000 ❌ (latest only, not sum!)
```

### Problem Location:

**Backend API tidak accumulate donations per user!**

API endpoint `/api/roblox/top-spenders` kemungkinan return:
```json
{
  "ok": true,
  "topSpenders": [
    {
      "username": "moonzet16",
      "totalAmount": 2000  // ❌ Latest donation only, not SUM!
    }
  ]
}
```

**Should return:**
```json
{
  "ok": true,
  "topSpenders": [
    {
      "username": "moonzet16",
      "totalAmount": 3000,  // ✅ SUM of all donations (1000 + 2000)
      "donationCount": 2
    }
  ]
}
```

---

## ✅ Solution: Pakai Prisma DB (RECOMMENDED!)

### Why Prisma?

- ✅ **Type-safe** database queries
- ✅ **Migrations** automatic
- ✅ **Atomic operations** (ACID compliance)
- ✅ **Easy accumulation** with `increment`
- ✅ Support **PostgreSQL, MySQL, SQLite, SQL Server, MongoDB**
- ✅ Built-in **connection pooling**

---

## 📋 Implementation Steps

### Step 1: Install Prisma

```bash
cd backend-api-folder
npm install prisma @prisma/client
npx prisma init
```

This creates:
```
prisma/
  └── schema.prisma
.env (DATABASE_URL)
```

---

### Step 2: Configure Database

Edit `.env`:
```env
# PostgreSQL (recommended for production)
DATABASE_URL="postgresql://user:password@localhost:5432/saweria_db?schema=public"

# Or MySQL
DATABASE_URL="mysql://user:password@localhost:3306/saweria_db"

# Or SQLite (for testing)
DATABASE_URL="file:./dev.db"
```

---

### Step 3: Define Schema

Edit `prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"  // or "mysql", "sqlite"
  url      = env("DATABASE_URL")
}

// Individual donations (transaction log)
model Donation {
  id             Int       @id @default(autoincrement())
  donorName      String    // Saweria donor name
  robloxUsername String?   // Matched Roblox username
  amount         Int       // Amount in Rupiah
  message        String?   // Donation message
  source         String    @default("saweria") // "saweria" or "bagibagi"
  createdAt      DateTime  @default(now())
  
  // Indexes for performance
  @@index([robloxUsername])
  @@index([createdAt])
  @@index([source])
  @@map("donations")
}

// Aggregated top spenders (fast lookup)
model TopSpender {
  id             Int       @id @default(autoincrement())
  robloxUsername String    @unique
  totalAmount    Int       @default(0)     // ✅ ACCUMULATED total
  donationCount  Int       @default(0)     // Count of donations
  lastDonation   DateTime                  // Last donation time
  updatedAt      DateTime  @updatedAt
  
  @@index([totalAmount(sort: Desc)])  // For fast sorting
  @@map("top_spenders")
}

// Optional: Webhook log for debugging
model WebhookLog {
  id        Int       @id @default(autoincrement())
  payload   String    @db.Text  // JSON payload
  processed Boolean   @default(false)
  error     String?
  createdAt DateTime  @default(now())
  
  @@index([processed])
  @@index([createdAt])
  @@map("webhook_logs")
}
```

---

### Step 4: Create Database & Tables

```bash
npx prisma migrate dev --name init
```

This will:
1. Create database (if not exists)
2. Create tables based on schema
3. Generate Prisma Client

---

### Step 5: Backend Code (Node.js + Express)

**File: `server.js` or `index.js`**

```javascript
import express from 'express'
import { PrismaClient } from '@prisma/client'

const app = express()
const prisma = new PrismaClient()

app.use(express.json())

// ========================================================================
// WEBHOOK ENDPOINT - Receive donation from Saweria/BagiBagi
// ========================================================================

app.post('/api/webhook/donation', async (req, res) => {
  try {
    const { donor, amount, message, robloxUsername } = req.body
    
    console.log('[WEBHOOK] Received donation:', { donor, amount, robloxUsername })
    
    // Log webhook (optional, for debugging)
    await prisma.webhookLog.create({
      data: {
        payload: JSON.stringify(req.body),
        processed: false
      }
    })
    
    // Save donation (transaction log)
    const donation = await prisma.donation.create({
      data: {
        donorName: donor,
        robloxUsername: robloxUsername || null,
        amount: parseInt(amount),
        message: message || null,
        source: 'saweria'
      }
    })
    
    console.log('[DONATION] Saved:', donation.id)
    
    // ✅ UPDATE TOP SPENDER (ACCUMULATE!)
    if (robloxUsername) {
      const topSpender = await prisma.topSpender.upsert({
        where: { 
          robloxUsername: robloxUsername 
        },
        update: {
          totalAmount: {
            increment: parseInt(amount)  // ✅ INCREMENT (accumulate!)
          },
          donationCount: {
            increment: 1
          },
          lastDonation: new Date()
        },
        create: {
          robloxUsername: robloxUsername,
          totalAmount: parseInt(amount),
          donationCount: 1,
          lastDonation: new Date()
        }
      })
      
      console.log('[TOP SPENDER] Updated:', topSpender.robloxUsername, '→', topSpender.totalAmount)
    }
    
    // Mark webhook as processed
    await prisma.webhookLog.updateMany({
      where: { 
        payload: JSON.stringify(req.body)
      },
      data: { 
        processed: true 
      }
    })
    
    res.json({ 
      ok: true, 
      message: 'Donation processed',
      donationId: donation.id
    })
    
  } catch (error) {
    console.error('[ERROR]', error)
    
    // Log error
    await prisma.webhookLog.create({
      data: {
        payload: JSON.stringify(req.body),
        processed: false,
        error: error.message
      }
    })
    
    res.status(500).json({ 
      ok: false, 
      error: error.message 
    })
  }
})

// ========================================================================
// GET TOP SPENDERS - For Roblox to fetch
// ========================================================================

app.get('/api/roblox/top-spenders', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10
    
    // Fetch from aggregated table (FAST!)
    const topSpenders = await prisma.topSpender.findMany({
      orderBy: {
        totalAmount: 'desc'  // Sort by total (highest first)
      },
      take: limit
    })
    
    console.log('[TOP SPENDERS] Fetched:', topSpenders.length)
    
    res.json({
      ok: true,
      topSpenders: topSpenders.map(s => ({
        username: s.robloxUsername,
        totalAmount: s.totalAmount,      // ✅ ACCUMULATED!
        donationCount: s.donationCount,
        lastDonation: s.lastDonation
      }))
    })
    
  } catch (error) {
    console.error('[ERROR]', error)
    res.status(500).json({ 
      ok: false, 
      error: error.message 
    })
  }
})

// ========================================================================
// GET RECENT DONATIONS - For live feed
// ========================================================================

app.get('/api/webhook/donations', async (req, res) => {
  try {
    const since = req.query.since ? new Date(parseInt(req.query.since) * 1000) : new Date(Date.now() - 3600000)
    
    const donations = await prisma.donation.findMany({
      where: {
        createdAt: {
          gte: since
        }
      },
      orderBy: {
        createdAt: 'desc'
      },
      take: 50
    })
    
    res.json({
      ok: true,
      donations: donations.map(d => ({
        donor: d.donorName,
        amount: d.amount,
        message: d.message,
        robloxUsername: d.robloxUsername,
        timestamp: Math.floor(d.createdAt.getTime() / 1000)
      }))
    })
    
  } catch (error) {
    console.error('[ERROR]', error)
    res.status(500).json({ 
      ok: false, 
      error: error.message 
    })
  }
})

// Start server
const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`)
})

// Cleanup on shutdown
process.on('beforeExit', async () => {
  await prisma.$disconnect()
})
```

---

### Step 6: Test Accumulation

```bash
# Donate 1000
curl -X POST http://localhost:3000/api/webhook/donation \
  -H "Content-Type: application/json" \
  -d '{
    "donor": "Test User",
    "amount": 1000,
    "message": "First donation",
    "robloxUsername": "moonzet16"
  }'

# Response:
# { "ok": true, "donationId": 1 }

# Donate 2000
curl -X POST http://localhost:3000/api/webhook/donation \
  -H "Content-Type: application/json" \
  -d '{
    "donor": "Test User",
    "amount": 2000,
    "message": "Second donation",
    "robloxUsername": "moonzet16"
  }'

# Response:
# { "ok": true, "donationId": 2 }

# Check top spenders
curl http://localhost:3000/api/roblox/top-spenders

# Response:
# {
#   "ok": true,
#   "topSpenders": [
#     {
#       "username": "moonzet16",
#       "totalAmount": 3000,    ✅ ACCUMULATED! (1000 + 2000)
#       "donationCount": 2,
#       "lastDonation": "2025-10-30T..."
#     }
#   ]
# }
```

---

## 📊 Benefits

### Before (Without Prisma):
```
❌ Donations not accumulated
❌ Manual SQL queries prone to errors
❌ No type safety
❌ Race conditions possible
❌ Hard to maintain
```

### After (With Prisma):
```
✅ Donations properly accumulated with `increment`
✅ Type-safe queries (TypeScript)
✅ Atomic operations (no race conditions)
✅ Easy migrations
✅ Fast queries with indexes
✅ Transaction log + aggregated table
```

---

## 🚀 Deployment

### Option 1: Vercel (Easiest)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set DATABASE_URL in Vercel dashboard
```

### Option 2: Railway (Database + App)
```bash
# Railway provides PostgreSQL + Node.js hosting
# Just connect GitHub repo
```

### Option 3: Docker
```dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npx prisma generate
EXPOSE 3000
CMD ["npm", "start"]
```

---

## 🔧 Alternative: Quick Fix (Temporary)

Jika belum bisa setup Prisma, temporary fix sudah saya apply di `WebhookIntegration.luau`:

**Changes:**
- Trust API value (assume backend will fix accumulation)
- Keep DataStore value if higher (data integrity)
- Added TODO comment for backend fix

**But this is NOT a proper solution!** Backend harus fix accumulation logic.

---

## ✅ Recommendation

**USE PRISMA DB!** Ini best practice untuk:
- ✅ Persistent data storage
- ✅ Proper accumulation logic
- ✅ Type safety
- ✅ Easy maintenance
- ✅ Scalability

**Steps:**
1. Setup Prisma (10 minutes)
2. Update backend API (30 minutes)
3. Test accumulation (5 minutes)
4. Deploy (10 minutes)

**Total time: ~1 hour** untuk proper solution yang akan work forever! 🚀

---

**Last Updated:** 2025-10-30  
**Status:** ⚠️ NEEDS BACKEND FIX  
**Solution:** Prisma DB with proper accumulation  
**Temporary Fix:** Applied in WebhookIntegration.luau
