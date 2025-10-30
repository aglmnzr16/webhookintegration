# ✅ Setup Complete: Dual Platform Donation System

## 🎉 What's Done

Sistem donation sekarang support **2 platform terpisah**:
- **BagiBagi** - Board, webhook, database terpisah
- **Saweria** - Board, webhook, database terpisah

Dengan **toggle config** untuk enable/disable masing-masing platform!

---

## 📁 Files Created/Modified

### ✅ Environment Configuration:
- `env.example` - Template dengan BAGIBAGI_WEBHOOK_TOKEN dan SAWERIA_WEBHOOK_TOKEN

### ✅ Database Schema:
- `prisma/schema.prisma` - Separate tables:
  - `BagiBagiDonation` + `BagiBagiTopSpender`
  - `SaweriaDonation` + `SaweriaTopSpender`

### ✅ API Webhooks:
- `app/api/webhooks/bagibagi/route.ts` - Updated untuk use `bagiBagiDonation`
- `app/api/webhooks/saweria/route.ts` - NEW! Use `saweriaDonation`

### ✅ Roblox Configuration:
- `roblox/ServerStorage/DonationConfig.luau` - **ModuleScript config**
  ```lua
  Config.BagiBagi.Enabled = true/false
  Config.Saweria.Enabled = true/false
  ```

### ✅ Roblox Client Scripts (Saweria):
- `roblox/StarterPlayer/StarterPlayerScripts/SaweriaNotification.luau`
- `roblox/StarterPlayer/StarterPlayerScripts/SaweriaLiveDonation.luau`  
- `roblox/StarterPlayer/StarterPlayerScripts/SaweriaTopDonation.luau`

### ✅ Documentation:
- `SAWERIA_WEBHOOK_SETUP.md` - Setup guide untuk Saweria
- `MIGRATION_GUIDE.md` - Migration steps dari old schema
- `SETUP_COMPLETE.md` - This file!

---

## ⚡ Next Steps (IMPORTANT!)

### 1. Fix TypeScript Errors

Run command ini untuk regenerate Prisma client:

```bash
npx prisma generate
```

**This will fix all TypeScript errors:**
- ✅ `Property 'bagiBagiDonation' does not exist`
- ✅ `Property 'bagiBagiTopSpender' does not exist`  
- ✅ `Property 'saweriaDonation' does not exist`
- ✅ `Property 'saweriaTopSpender' does not exist`

### 2. Create Database Migration

```bash
# Development (with prompt)
npx prisma migrate dev --name separate_bagibagi_saweria_tables

# Production (auto-apply)
npx prisma migrate deploy
```

### 3. Update Environment Variables

Edit `.env.local` dan tambahkan:

```env
# Database
DATABASE_URL="postgresql://..."
DIRECT_URL="postgresql://..."

# Webhooks
BAGIBAGI_WEBHOOK_TOKEN="your_bagibagi_token"
SAWERIA_WEBHOOK_TOKEN="your_saweria_token"

# Discord
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

### 4. Deploy to Production

```bash
git add .
git commit -m "Add Saweria webhook support with separate tables"
git push origin main
```

### 5. Setup Roblox Studio

**A. Place ModuleScript:**
1. Open Roblox Studio
2. Copy `DonationConfig.luau` ke `ServerStorage`

**B. Configure Platforms:**
```lua
-- In DonationConfig.luau

Config.BagiBagi = {
    Enabled = true,  -- ✅ Enable BagiBagi
    -- ...
}

Config.Saweria = {
    Enabled = true,  -- ✅ Enable Saweria
    -- ...
}
```

**C. Create Boards:**
1. **BagibagiBoard** Part di Workspace
   - Add `BagibagiBoard` SurfaceGui
   - Add `LiveDonation` SurfaceGui
   
2. **SaweriaBoard** Part di Workspace
   - Add `SaweriaBoard` SurfaceGui
   - Add `LiveDonation` SurfaceGui

**D. Place Client Scripts:**
Copy to `StarterPlayer/StarterPlayerScripts/`:
- `BagiBagiLiveDonation.luau` (existing)
- `BagiBagiTopDonation.luau` (existing)
- `SaweriaLiveDonation.luau` (NEW)
- `SaweriaTopDonation.luau` (NEW)
- `SaweriaNotification.luau` (NEW)

### 6. Test System

**Test BagiBagi:**
```bash
curl -X POST https://your-domain.com/api/webhooks/bagibagi \
  -H "Content-Type: application/json" \
  -d '{"donor":"TestUser","amount":50000,"message":"Test #ABC123"}'
```

**Test Saweria:**
```bash
curl -X POST https://your-domain.com/api/webhooks/saweria \
  -H "Content-Type: application/json" \
  -d '{"donor":"TestUser","amount":50000,"message":"Test Saweria"}'
```

---

## 🎮 Configuration Examples

### Enable Both Platforms (Default):
```lua
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = true
```
**Result:** Both boards active, both webhooks work

### Only BagiBagi:
```lua
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = false
```
**Result:** Only BagiBagi board active, Saweria webhook still saves to DB but board hidden

### Only Saweria:
```lua
Config.BagiBagi.Enabled = false
Config.Saweria.Enabled = true
```
**Result:** Only Saweria board active, BagiBagi webhook still saves to DB but board hidden

### Disable All (Maintenance):
```lua
Config.BagiBagi.Enabled = false
Config.Saweria.Enabled = false
```
**Result:** No boards active, webhooks still save to DB (data preserved)

---

## 📊 Database Structure

### BagiBagi Tables:
```sql
bagibagi_donations
├── id (PK)
├── donation_id (Unique)
├── donor_name
├── roblox_username
├── amount (Float)
├── message
├── raw_data (JSON)
└── created_at

bagibagi_top_spenders
├── id (PK)
├── roblox_username (Unique)
├── total_amount (Float)
├── donation_count
├── last_donation
├── created_at
└── updated_at
```

### Saweria Tables:
```sql
saweria_donations
├── id (PK)
├── donation_id (Unique)
├── donor_name
├── roblox_username
├── amount (Float)
├── message
├── raw_data (JSON)
└── created_at

saweria_top_spenders
├── id (PK)
├── roblox_username (Unique)
├── total_amount (Float)
├── donation_count
├── last_donation
├── created_at
└── updated_at
```

---

## 🔒 Security

Both platforms use separate tokens:
- `BAGIBAGI_WEBHOOK_TOKEN` - For BagiBagi webhook
- `SAWERIA_WEBHOOK_TOKEN` - For Saweria webhook
- `WEBHOOK_TOKEN` - Legacy fallback

**Best Practice:**
- Use different tokens for each platform
- Rotate tokens regularly
- Never commit tokens to Git

---

## 📈 Monitoring

### Check Database:
```sql
-- BagiBagi donations
SELECT COUNT(*), SUM(amount) FROM bagibagi_donations;

-- Saweria donations  
SELECT COUNT(*), SUM(amount) FROM saweria_donations;

-- BagiBagi top spenders
SELECT * FROM bagibagi_top_spenders ORDER BY total_amount DESC LIMIT 10;

-- Saweria top spenders
SELECT * FROM saweria_top_spenders ORDER BY total_amount DESC LIMIT 10;
```

### Check Roblox:
```lua
-- In server script
local Config = require(ServerStorage.DonationConfig)
Config:PrintStatus()

-- Output:
-- 🔧 ========== DONATION SYSTEM CONFIGURATION ==========
-- BagiBagi: ✅ ENABLED
-- Saweria:  ✅ ENABLED
-- Platforms Active: 2
-- 🔧 ===================================================
```

---

## 🐛 Common Issues & Fixes

### Issue: TypeScript errors about missing properties

**Solution:**
```bash
npx prisma generate
# Restart VS Code TypeScript server (Ctrl+Shift+P → Restart TS Server)
```

### Issue: Migration fails with "table already exists"

**Solution:**
```bash
# Reset database (⚠️ deletes data!)
npx prisma migrate reset

# Or drop tables manually
psql $DATABASE_URL -c "DROP TABLE IF EXISTS donations CASCADE;"
psql $DATABASE_URL -c "DROP TABLE IF EXISTS top_spenders CASCADE;"

# Then migrate
npx prisma migrate dev
```

### Issue: Roblox board not showing data

**Solution:**
1. Check `DonationConfig.luau` platform enabled
2. Check workspace has correct board (BagibagiBoard/SaweriaBoard)
3. Check API endpoints in config
4. Check console logs in Roblox Studio

### Issue: Webhook returns 500 error

**Solution:**
1. Check `.env.local` has database URLs
2. Run `npx prisma generate`
3. Check Vercel/Railway logs
4. Test database connection: `npx prisma db pull`

---

## 🎉 What You Can Do Now

### Platform Control:
- ✅ Enable/disable BagiBagi independently
- ✅ Enable/disable Saweria independently
- ✅ Run both platforms simultaneously
- ✅ Disable all for maintenance

### Data Isolation:
- ✅ BagiBagi data completely separate
- ✅ Saweria data completely separate
- ✅ No data conflicts
- ✅ Independent leaderboards

### Testing:
- ✅ Test BagiBagi without affecting Saweria
- ✅ Test Saweria without affecting BagiBagi
- ✅ Compare both platforms performance

### Deployment:
- ✅ Deploy with confidence (separate tables)
- ✅ Rollback easily if issues occur
- ✅ Monitor each platform independently

---

## 📚 Documentation Links

- **Setup Guide:** `SAWERIA_WEBHOOK_SETUP.md`
- **Migration:** `MIGRATION_GUIDE.md`  
- **BagiBagi Fix:** `ROBUX_NOTIFICATION_FIX.md`
- **Saweria Fix:** `SAWERIA_NOTIFICATION_FIX.md`
- **BlackHole Effect:** `SAWERIA_BLACKHOLE_EFFECT.md`

---

## 🆘 Need Help?

1. Check console logs (API and Roblox)
2. Review migration guide
3. Check database schema
4. Test with curl commands
5. Contact support with error details

---

## 🎊 Success Checklist

Before going live, verify:

### Database:
- [ ] `npx prisma generate` runs successfully
- [ ] `npx prisma migrate dev` creates 4 tables
- [ ] Database connection works
- [ ] Both webhook endpoints return 200 OK

### API:
- [ ] Environment variables set correctly
- [ ] BagiBagi webhook saves to `bagibagi_donations`
- [ ] Saweria webhook saves to `saweria_donations`
- [ ] Discord notifications work

### Roblox:
- [ ] `DonationConfig.luau` in ServerStorage
- [ ] Both boards exist in Workspace
- [ ] Client scripts load without errors
- [ ] Live donations appear on correct boards
- [ ] Top spenders update independently
- [ ] Notifications work for both platforms
- [ ] Effects trigger correctly

### Integration:
- [ ] BagiBagi donation → BagiBagi board
- [ ] Saweria donation → Saweria board
- [ ] No data conflicts
- [ ] Performance acceptable
- [ ] Users can see both boards

---

**🚀 You're ready to launch the dual-platform donation system!**

**System Status:**
- ✅ Separate database tables
- ✅ Independent webhooks
- ✅ Toggle configuration  
- ✅ Complete documentation
- ✅ Testing ready

**Next:** Run `npx prisma generate` and test! 🎉
