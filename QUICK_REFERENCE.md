# ⚡ Quick Reference Card

## 🚨 IMPORTANT: Fix Errors First!

```bash
npx prisma generate
```

**This fixes all TypeScript errors!** (30 seconds)

---

## 📋 Checklist

### 1. Environment Variables (`.env.local`)
```env
DATABASE_URL="postgresql://..."
DIRECT_URL="postgresql://..."
BAGIBAGI_WEBHOOK_TOKEN="your_token"
SAWERIA_WEBHOOK_TOKEN="your_token"
DISCORD_WEBHOOK_URL="https://..."
```

### 2. Generate Prisma Client
```bash
npx prisma generate
```

### 3. Create Database Tables
```bash
npx prisma migrate dev --name separate_tables
```

### 4. Deploy
```bash
git add .
git commit -m "Dual platform support"
git push
```

### 5. Roblox Setup
- ✅ Place `DonationConfig.luau` in `ServerStorage`
- ✅ Create `BagibagiBoard` in Workspace
- ✅ Create `SaweriaBoard` in Workspace
- ✅ Place 6 client scripts in `StarterPlayerScripts`

---

## 🎮 Roblox Config

```lua
-- ServerStorage/DonationConfig.luau

-- Enable both platforms
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = true

-- Or only one
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = false
```

---

## 🌐 Webhook URLs

### BagiBagi:
```
POST https://your-domain.com/api/webhooks/bagibagi
Header: X-Webhook-Token: BAGIBAGI_WEBHOOK_TOKEN
```

### Saweria:
```
POST https://your-domain.com/api/webhooks/saweria
Header: X-Webhook-Token: SAWERIA_WEBHOOK_TOKEN
```

---

## 🧪 Test Commands

### Test BagiBagi:
```bash
curl -X POST https://your-domain.com/api/webhooks/bagibagi \
  -H "Content-Type: application/json" \
  -d '{"donor":"TestUser","amount":50000,"message":"Test"}'
```

### Test Saweria:
```bash
curl -X POST https://your-domain.com/api/webhooks/saweria \
  -H "Content-Type: application/json" \
  -d '{"donor":"TestUser","amount":50000,"message":"Test"}'
```

---

## 📊 Database Tables

### BagiBagi:
- `bagibagi_donations`
- `bagibagi_top_spenders`

### Saweria:
- `saweria_donations`
- `saweria_top_spenders`

---

## 📁 Files Created

### API:
- `app/api/webhooks/saweria/route.ts` ✅

### Roblox Config:
- `roblox/ServerStorage/DonationConfig.luau` ✅

### Roblox Scripts:
- `SaweriaNotification.luau` ✅
- `SaweriaLiveDonation.luau` ✅
- `SaweriaTopDonation.luau` ✅

### Docs:
- `env.example` ✅
- `SETUP_COMPLETE.md` ✅
- `MIGRATION_GUIDE.md` ✅
- `FIX_TYPESCRIPT_ERRORS.md` ✅

---

## 🐛 Common Issues

### TypeScript Errors?
```bash
npx prisma generate
```

### Migration Fails?
```bash
npx prisma migrate reset
npx prisma migrate dev
```

### Board Not Showing?
```lua
-- Check config
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = true

-- Check workspace
Workspace.BagibagiBoard (must exist)
Workspace.SaweriaBoard (must exist)
```

---

## 🎯 Quick Config Examples

### Production (Both ON):
```lua
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = true
```

### Testing (One Platform):
```lua
Config.BagiBagi.Enabled = false
Config.Saweria.Enabled = true
```

### Maintenance (All OFF):
```lua
Config.BagiBagi.Enabled = false
Config.Saweria.Enabled = false
```

---

## 📖 Full Docs

- **Complete Setup:** `SETUP_COMPLETE.md`
- **Migration:** `MIGRATION_GUIDE.md`
- **Dual Platform:** `README_DUAL_PLATFORM.md`
- **Fix Errors:** `FIX_TYPESCRIPT_ERRORS.md`

---

## ✅ Success Steps

1. ✅ Run `npx prisma generate`
2. ✅ Run `npx prisma migrate dev`
3. ✅ Update `.env.local`
4. ✅ Deploy to production
5. ✅ Place Roblox scripts
6. ✅ Configure platforms (enable/disable)
7. ✅ Test webhooks
8. ✅ Check boards in-game

---

## 🆘 Need Help?

1. Check console logs (API & Roblox)
2. Review `FIX_TYPESCRIPT_ERRORS.md`
3. Review `MIGRATION_GUIDE.md`
4. Check database with `npx prisma studio`

---

**Time to Setup:** 15-30 minutes  
**Next Step:** Run `npx prisma generate` 🚀
