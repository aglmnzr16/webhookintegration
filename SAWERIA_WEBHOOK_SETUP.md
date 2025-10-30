# 🎉 Saweria Webhook Integration Setup

## 📋 Overview

Sistem webhook donation sekarang support **2 platform**:
1. **BagiBagi** - `/api/webhooks/bagibagi`
2. **Saweria** - `/api/webhooks/saweria` ← NEW!

Kedua platform memiliki board terpisah di Roblox Studio dengan live donation feed dan top spenders leaderboard.

---

## 🌐 API Endpoints

### BagiBagi Webhook
```
POST https://your-domain.com/api/webhooks/bagibagi
```

### Saweria Webhook (NEW)
```
POST https://your-domain.com/api/webhooks/saweria
```

---

## 🔧 Environment Variables

Add to your `.env.local`:

```env
# Existing
DATABASE_URL="postgresql://..."
DIRECT_URL="postgresql://..."
WEBHOOK_TOKEN="your_bagibagi_token"
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."

# NEW - Saweria specific (optional, falls back to WEBHOOK_TOKEN)
SAWERIA_WEBHOOK_TOKEN="your_saweria_token"
```

---

## 📊 Database Schema

Both platforms use the same database tables:

### Donations Table
```sql
model Donation {
  id             Int       @id @default(autoincrement())
  donationId     String    @unique
  donorName      String
  robloxUsername String?   -- Matched Roblox username
  amount         Float
  message        String?
  source         String    @default("bagibagi") -- "bagibagi" or "saweria"
  rawData        Json?
  createdAt      DateTime  @default(now())
}
```

### TopSpender Table
```sql
model TopSpender {
  id             Int       @id @default(autoincrement())
  robloxUsername String    @unique
  totalAmount    Float     @default(0)
  donationCount  Int       @default(0)
  lastDonation   DateTime
  createdAt      DateTime  @default(now())
  updatedAt      DateTime  @updatedAt
}
```

**Note:** TopSpender combines donations from BOTH platforms (BagiBagi + Saweria)

---

## 🎮 Roblox Studio Setup

### Workspace Structure

```
Workspace/
├── BagibagiBoard/          -- BagiBagi donation board
│   ├── BagibagiBoard/      -- SurfaceGui (Top Spenders)
│   └── LiveDonation/       -- SurfaceGui (Live Feed)
│
└── SaweriaBoard/           -- Saweria donation board (NEW)
    ├── SaweriaBoard/       -- SurfaceGui (Top Spenders)
    └── LiveDonation/       -- SurfaceGui (Live Feed)
```

### Required Client Scripts (StarterPlayerScripts)

#### BagiBagi Scripts:
1. `BagiBagiLiveDonation.luau` - Live feed display
2. `BagiBagiTopDonation.luau` - Top spenders leaderboard
3. `RupiahNotification.luau` - Popup notifications (optional)

#### Saweria Scripts (NEW):
1. `SaweriaLiveDonation.luau` - Live feed display ✅
2. `SaweriaTopDonation.luau` - Top spenders leaderboard ✅
3. `SaweriaNotification.luau` - Popup notifications ✅

### Required Server Scripts (ServerScriptService)

1. `WebhookIntegration.luau` - Main webhook handler
   - Polls both `/api/roblox/donations?source=bagibagi` 
   - Polls both `/api/roblox/donations?source=saweria` (NEW)
   - Fires RemoteEvents to clients

2. `Bagibagi.luau` - BagiBagi board controller
3. `Saweria.luau` - Saweria board controller (NEW - needs to be created)

### Required RemoteEvents (ReplicatedStorage)

#### BagiBagi:
- `RealtimeDonation` (Server → Client)
- `GetTopSpenders` (RemoteFunction)

#### Saweria (NEW):
- `SaweriaRealtimeDonation` (Server → Client)
- `SaweriaDonationSystem/ShowSaweriaDonationNotif` (for notifications)

---

## 🔄 Data Flow

### BagiBagi Webhook Flow:
```
1. Donation on BagiBagi → POST /api/webhooks/bagibagi
2. API saves to database (source: "bagibagi")
3. API saves to saweria-donations.json (backup)
4. Roblox polls /api/roblox/donations?source=bagibagi
5. Server fires RealtimeDonation → Clients
6. BagiBagiLiveDonation displays on board
```

### Saweria Webhook Flow (NEW):
```
1. Donation on Saweria → POST /api/webhooks/saweria
2. API saves to database (source: "saweria")
3. API saves to saweria-donations.json (backup)
4. Roblox polls /api/roblox/donations?source=saweria
5. Server fires SaweriaRealtimeDonation → Clients
6. SaweriaLiveDonation displays on board
```

### Top Spenders Flow (Shared):
```
1. Both platforms update same TopSpender table
2. Roblox calls GetTopSpenders RemoteFunction
3. Server queries database (combines both sources)
4. Returns aggregated top 10 donors
5. Both boards display same leaderboard
```

---

## 📝 Files Created

### Next.js API:
- ✅ `app/api/webhooks/saweria/route.ts` - Saweria webhook endpoint

### Roblox Client Scripts:
- ✅ `roblox/StarterPlayer/StarterPlayerScripts/SaweriaNotification.luau`
- ✅ `roblox/StarterPlayer/StarterPlayerScripts/SaweriaLiveDonation.luau`
- ✅ `roblox/StarterPlayer/StarterPlayerScripts/SaweriaTopDonation.luau`

### Documentation:
- ✅ `SAWERIA_WEBHOOK_SETUP.md` (this file)

---

## 🚀 Deployment Steps

### 1. Deploy Next.js API

```bash
# Add new environment variable
echo "SAWERIA_WEBHOOK_TOKEN=your_token_here" >> .env.local

# Deploy to Vercel/Railway
git add .
git commit -m "Add Saweria webhook support"
git push origin main
```

### 2. Configure Saweria Webhook

Go to Saweria dashboard and set webhook URL:
```
https://your-domain.com/api/webhooks/saweria
```

Add header (optional):
```
X-Webhook-Token: your_saweria_token
```

### 3. Setup Roblox Workspace

1. Create `SaweriaBoard` Part in Workspace
2. Add `SaweriaBoard` SurfaceGui (for top spenders)
3. Add `LiveDonation` SurfaceGui (for live feed)
4. Copy UI structure from BagibagiBoard

### 4. Add Roblox Scripts

1. Place client scripts in `StarterPlayer/StarterPlayerScripts/`
2. Update `WebhookIntegration.luau` to poll Saweria endpoint
3. Create `Saweria.luau` server script (similar to Bagibagi.luau)

---

## 🧪 Testing

### Test Saweria Webhook

```bash
curl -X POST https://your-domain.com/api/webhooks/saweria \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: your_token" \
  -d '{
    "donor": "TestUser",
    "name": "TestUser",
    "amount": 50000,
    "message": "Test donation #ABC123"
  }'
```

Expected Response:
```json
{
  "ok": true,
  "donation": {
    "id": "...",
    "donor": "TestUser",
    "amount": 50000,
    "matchedUsername": "TestUser"
  }
}
```

### Test in Roblox Studio

1. Run game in Studio
2. Check console logs:
   ```
   ✅ Saweria Live Donation system ready!
   ✅ Saweria Top Board system ready!
   ✅ Saweria notification system ready!
   ```

3. Send test webhook (see above)
4. Check boards update in ~5 seconds
5. Verify notification popup appears

---

## 🎯 Features Comparison

| Feature | BagiBagi | Saweria |
|---------|----------|---------|
| **Webhook Endpoint** | `/api/webhooks/bagibagi` | `/api/webhooks/saweria` |
| **Database Source** | `"bagibagi"` | `"saweria"` |
| **JSON Backup** | `donations.json` | `saweria-donations.json` |
| **Live Feed Board** | BagibagiBoard/LiveDonation | SaweriaBoard/LiveDonation |
| **Top Spenders** | Shared (combined) | Shared (combined) |
| **Notifications** | RupiahNotification | SaweriaNotification |
| **Currency Format** | Rp. 5.000 | Rp. 5.000 |
| **RemoteEvent** | RealtimeDonation | SaweriaRealtimeDonation |

---

## 🔒 Security

Both webhooks use the same security measures:

1. **Token Verification** (optional)
   - BagiBagi: `WEBHOOK_TOKEN`
   - Saweria: `SAWERIA_WEBHOOK_TOKEN` or fallback to `WEBHOOK_TOKEN`

2. **Database Validation**
   - Duplicate prevention via unique `donationId`
   - Timestamp validation
   - Amount validation

3. **Rate Limiting**
   - API route level protection
   - Roblox polling intervals (5s for live, 30s for leaderboard)

---

## 📊 Monitoring

### Check Donations by Source

```sql
-- BagiBagi donations
SELECT COUNT(*), SUM(amount) 
FROM donations 
WHERE source = 'bagibagi';

-- Saweria donations
SELECT COUNT(*), SUM(amount) 
FROM donations 
WHERE source = 'saweria';

-- Combined total
SELECT 
  source,
  COUNT(*) as count,
  SUM(amount) as total
FROM donations
GROUP BY source;
```

### Check Top Spenders (Combined)

```sql
SELECT 
  robloxUsername,
  totalAmount,
  donationCount,
  lastDonation
FROM TopSpender
ORDER BY totalAmount DESC
LIMIT 10;
```

---

## 🐛 Troubleshooting

### Saweria Webhook Not Working

1. Check webhook URL in Saweria dashboard
2. Verify `SAWERIA_WEBHOOK_TOKEN` in `.env.local`
3. Check API logs: `vercel logs` or Railway logs
4. Test with curl (see Testing section)

### Board Not Updating

1. Check RemoteEvent exists: `ReplicatedStorage.SaweriaRealtimeDonation`
2. Check workspace structure: `Workspace.SaweriaBoard`
3. Check console logs in Roblox Studio
4. Verify API endpoint: `/api/roblox/donations?source=saweria`

### Notifications Not Showing

1. Check RemoteEvent: `SaweriaDonationSystem/ShowSaweriaDonationNotif`
2. Verify script running: Check console for "✅ Saweria notification system ready!"
3. Check payload data structure matches expected format

---

## 🎉 Summary

### What's New:

1. ✅ **Saweria Webhook API** - `/api/webhooks/saweria`
2. ✅ **Separate JSON Backup** - `saweria-donations.json`
3. ✅ **Database Integration** - Source: "saweria"
4. ✅ **3 Roblox Client Scripts** - Live feed, top board, notifications
5. ✅ **Shared Top Spenders** - Combines BagiBagi + Saweria

### What's Shared:

- 💾 **Database Schema** - Same tables for both platforms
- 📊 **Top Spenders** - Combined leaderboard
- 🎨 **UI Design** - Same styling and layout
- 🔒 **Security** - Same token verification
- 💬 **Discord Logs** - Both send to same channel

### Next Steps:

1. Deploy API changes to production
2. Configure Saweria webhook URL
3. Setup SaweriaBoard in Roblox Studio
4. Test with real donations
5. Monitor both boards in-game

**🎊 You now have a dual-platform donation system!** 🎊
