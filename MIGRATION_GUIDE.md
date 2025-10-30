# 🔄 Migration Guide: Separate Tables untuk BagiBagi & Saweria

## 📋 Overview

Perubahan ini memisahkan database tables untuk BagiBagi dan Saweria untuk mencegah data conflict dan memudahkan management.

### ❌ Before (Single Table)
```
donations (source: "bagibagi" | "saweria")
top_spenders (combined)
```

### ✅ After (Separate Tables)
```
bagibagi_donations
bagibagi_top_spenders
saweria_donations  
saweria_top_spenders
```

---

## 🚀 Migration Steps

### 1. Update Environment Variables

Edit `.env.local`:

```env
# Add database URLs (if not exist)
DATABASE_URL="postgresql://user:password@host:5432/database?pgbouncer=true"
DIRECT_URL="postgresql://user:password@host:5432/database"

# Rename WEBHOOK_TOKEN to BAGIBAGI_WEBHOOK_TOKEN
BAGIBAGI_WEBHOOK_TOKEN="your_bagibagi_token"

# Add Saweria token
SAWERIA_WEBHOOK_TOKEN="your_saweria_token"

# Keep legacy for backward compatibility
WEBHOOK_TOKEN="your_legacy_token"
```

### 2. Generate Prisma Client

```bash
# Regenerate Prisma client untuk new models
npx prisma generate
```

**Expected Output:**
```
✔ Generated Prisma Client (v5.x.x)

Models:
- BagiBagiDonation
- BagiBagiTopSpender  
- SaweriaDonation
- SaweriaTopSpender
- WebhookLog
```

### 3. Create Database Migration

```bash
# Create migration file
npx prisma migrate dev --name separate_bagibagi_saweria_tables

# Or for production
npx prisma migrate deploy
```

**Migration will:**
- Create `bagibagi_donations` table
- Create `bagibagi_top_spenders` table
- Create `saweria_donations` table
- Create `saweria_top_spenders` table
- ⚠️ Drop old `donations` and `top_spenders` tables (if exist)

### 4. Migrate Existing Data (Optional)

Jika ada data di old tables, run SQL migration:

```sql
-- Migrate donations from old table
INSERT INTO bagibagi_donations (donation_id, donor_name, roblox_username, amount, message, raw_data, created_at)
SELECT donation_id, donor_name, roblox_username, amount, message, raw_data, created_at
FROM donations
WHERE source = 'bagibagi';

INSERT INTO saweria_donations (donation_id, donor_name, roblox_username, amount, message, raw_data, created_at)
SELECT donation_id, donor_name, roblox_username, amount, message, raw_data, created_at
FROM donations
WHERE source = 'saweria';

-- Migrate top spenders (requires manual split if combined)
-- You may need to recalculate from donations
```

### 5. Deploy API Changes

```bash
# Commit changes
git add .
git commit -m "Separate BagiBagi and Saweria database tables"

# Push to production
git push origin main

# Vercel/Railway will auto-deploy
```

### 6. Setup Roblox Configuration

1. **Place ModuleScript** di `ServerStorage`:
   - `DonationConfig.luau`

2. **Edit configuration:**
   ```lua
   Config.BagiBagi.Enabled = true  -- Enable BagiBagi
   Config.Saweria.Enabled = true   -- Enable Saweria
   ```

3. **Update server scripts** untuk use config:
   ```lua
   local Config = require(ServerStorage.DonationConfig)
   
   if Config:IsBagiBagiEnabled() then
       -- Initialize BagiBagi polling & board
   end
   
   if Config:IsSaweriaEnabled() then
       -- Initialize Saweria polling & board
   end
   ```

---

## ✅ Verification Checklist

### API Level:
- [ ] `npx prisma generate` runs without errors
- [ ] `npx prisma migrate dev` creates new tables
- [ ] Test BagiBagi webhook: `POST /api/webhooks/bagibagi`
- [ ] Test Saweria webhook: `POST /api/webhooks/saweria`
- [ ] Check database has separate tables:
  ```sql
  SELECT table_name FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name LIKE '%donation%';
  ```

### Roblox Level:
- [ ] `DonationConfig.luau` placed in ServerStorage
- [ ] Both boards exist in Workspace (BagibagiBoard, SaweriaBoard)
- [ ] Client scripts load without errors:
  - BagiBagiLiveDonation
  - BagiBagiTopDonation
  - SaweriaLiveDonation
  - SaweriaTopDonation
- [ ] Server polling starts for enabled platforms
- [ ] Live donations appear on correct boards
- [ ] Top spenders update independently

### Integration Test:
- [ ] Send BagiBagi donation → Shows on BagiBagi board only
- [ ] Send Saweria donation → Shows on Saweria board only
- [ ] Both boards show correct top spenders
- [ ] Notifications work for both platforms
- [ ] Effects trigger for both platforms

---

## 🔧 Troubleshooting

### TypeScript Errors: Property 'bagiBagiDonation' does not exist

**Cause:** Prisma client not regenerated

**Fix:**
```bash
npx prisma generate
# Restart TypeScript server in VS Code (Ctrl+Shift+P → "Restart TS Server")
```

### Migration Fails: Table already exists

**Cause:** Old tables still exist

**Fix:**
```bash
# Drop old tables first
npx prisma migrate reset  # ⚠️ Deletes all data!

# Or manually drop
psql $DATABASE_URL -c "DROP TABLE IF EXISTS donations CASCADE;"
psql $DATABASE_URL -c "DROP TABLE IF EXISTS top_spenders CASCADE;"

# Then migrate
npx prisma migrate dev
```

### Webhook Returns 500 Error

**Cause:** Prisma client mismatch or database connection issue

**Fix:**
```bash
# Check environment variables
cat .env.local

# Test database connection
npx prisma db pull

# Regenerate and redeploy
npx prisma generate
npm run build
```

### Board Not Showing Data

**Cause:** Platform disabled in config or wrong API endpoint

**Fix:**
1. Check `DonationConfig.luau`:
   ```lua
   Config.BagiBagi.Enabled = true
   Config.Saweria.Enabled = true
   ```

2. Check API endpoints in config:
   ```lua
   Endpoint = "/api/roblox/donations?source=bagibagi"
   TopSpendersEndpoint = "/api/roblox/top-spenders?source=bagibagi"
   ```

3. Check console logs in Roblox Studio

---

## 📊 Rollback Plan

If migration causes issues, rollback:

### 1. Revert Database Schema

```bash
# Revert to previous migration
npx prisma migrate resolve --rolled-back <migration-name>

# Restore old schema.prisma from git
git checkout HEAD~1 prisma/schema.prisma

# Regenerate client
npx prisma generate
```

### 2. Revert API Code

```bash
# Revert webhook routes
git checkout HEAD~1 app/api/webhooks/
npx prisma generate
npm run build
```

### 3. Revert Roblox Config

```lua
-- Disable new system
Config.BagiBagi.Enabled = false
Config.Saweria.Enabled = false

-- Use old single-table system
```

---

## 🎉 Post-Migration

### Benefits:
- ✅ **Data Isolation** - BagiBagi and Saweria data completely separate
- ✅ **No Conflicts** - Each platform has own leaderboard
- ✅ **Easy Toggle** - Enable/disable platforms independently
- ✅ **Better Performance** - Separate indexes, faster queries
- ✅ **Clear Metrics** - Track performance per platform

### Next Steps:
1. Monitor both webhook endpoints
2. Check database growth (both tables)
3. Monitor Roblox server performance
4. Gather user feedback on both boards

---

## 📝 Important Notes

### Database Size:
- Old system: 1 table for all donations
- New system: 2 tables (separated)
- Impact: Minimal (same total data, just split)

### API Changes:
- Old: `/api/roblox/donations` (all sources)
- New: `/api/roblox/donations?source=bagibagi` (filtered)
- New: `/api/roblox/donations?source=saweria` (filtered)

### Backward Compatibility:
- `WEBHOOK_TOKEN` still works (fallback)
- Old JSON files still used (backup)
- Client scripts backward compatible

---

## 🆘 Support

If stuck, check:
1. **Logs:** Vercel/Railway deployment logs
2. **Database:** Check tables exist with correct schema
3. **Roblox:** Check console output in Studio
4. **GitHub:** Check commit history for recent changes

Contact: [Your support channel]

---

**Migration Time:** ~15-30 minutes  
**Downtime:** None (if done during low traffic)  
**Risk Level:** Low (with backup)
