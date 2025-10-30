# 🎮 Roblox Dual Platform Setup Guide

## 📋 Overview

System ini support **2 platform terpisah**: BagiBagi dan Saweria, dengan toggle configuration untuk enable/disable per platform.

---

## 🗂️ File Structure

### ServerStorage:
```
ServerStorage/
└── DonationConfig.luau  ✅ Config ModuleScript
```

### ServerScriptService:
```
ServerScriptService/
├── WebhookIntegrationDual.luau  ✅ Main polling script (NEW!)
├── SaweriaDonationEffect.luau   ✅ Visual effects
├── Bagibagi.luau                 ✅ BagiBagi board controller
└── Saweria.luau                  ✅ Saweria board controller (to be created)
```

### StarterPlayerScripts:
```
StarterPlayer/StarterPlayerScripts/
├── BagiBagiLiveDonation.luau    ✅ BagiBagi live feed
├── BagiBagiTopDonation.luau     ✅ BagiBagi top spenders
├── RupiahNotification.luau      ✅ BagiBagi notifications
├── SaweriaLiveDonation.luau     ✅ Saweria live feed
├── SaweriaTopDonation.luau      ✅ Saweria top spenders
└── SaweriaNotification.luau     ✅ Saweria notifications
```

---

## 🚀 Setup Steps

### Step 1: Place ModuleScript Config

1. Open Roblox Studio
2. **ServerStorage** → Create ModuleScript
3. Rename to: `DonationConfig`
4. Copy content from: `roblox/ServerStorage/DonationConfig.luau`

**Verify:**
```lua
-- Should see this structure
local Config = {}
Config.BagiBagi = { Enabled = true, ... }
Config.Saweria = { Enabled = true, ... }
```

### Step 2: Place Server Script

**Option A: Use New Dual Script (Recommended)**
1. **ServerScriptService** → Create Script
2. Rename to: `WebhookIntegrationDual`
3. Copy content from: `roblox/ServerScriptService/WebhookIntegrationDual.luau`

**Option B: Update Existing Script**
- Update your existing `WebhookIntegration.luau` to use DonationConfig

**Verify:**
- Check Output should show:
  ```
  🎮 ========== DUAL PLATFORM DONATION SYSTEM ==========
  BagiBagi: ✅ ENABLED
  Saweria: ✅ ENABLED
  Platforms Active: 2
  ```

### Step 3: Place Client Scripts

Copy all 6 client scripts to `StarterPlayer/StarterPlayerScripts/`:

**BagiBagi:**
- `BagiBagiLiveDonation.luau` (existing)
- `BagiBagiTopDonation.luau` (existing)
- `RupiahNotification.luau` (existing)

**Saweria:**
- `SaweriaLiveDonation.luau` ✅ NEW
- `SaweriaTopDonation.luau` ✅ NEW
- `SaweriaNotification.luau` ✅ NEW

**Verify:**
- Check Output should show:
  ```
  ✅ BagiBagi Live Donation system ready!
  ✅ BagiBagi Top Board system ready!
  ✅ Saweria Live Donation system ready!
  ✅ Saweria Top Board system ready!
  ```

### Step 4: Create Workspace Boards

**BagiBagi Board:**
1. Workspace → Insert Part
2. Rename to: `BagibagiBoard`
3. Add SurfaceGui → Name: `BagibagiBoard` (Top Spenders)
4. Add SurfaceGui → Name: `LiveDonation` (Live Feed)

**Saweria Board:**
1. Workspace → Insert Part
2. Rename to: `SaweriaBoard`
3. Add SurfaceGui → Name: `SaweriaBoard` (Top Spenders)
4. Add SurfaceGui → Name: `LiveDonation` (Live Feed)

**Copy UI structure from existing boards!**

---

## ⚙️ Configuration

### Enable/Disable Platforms

Edit `ServerStorage/DonationConfig`:

```lua
-- Enable both platforms
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = true
```

**Scenarios:**

#### Production (Both Active):
```lua
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = true
```
**Result:** Both boards showing, both polling active

#### Testing BagiBagi Only:
```lua
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = false
```
**Result:** Only BagiBagi board, Saweria polling disabled

#### Testing Saweria Only:
```lua
Config.BagiBagi.Enabled = false
Config.Saweria.Enabled = true
```
**Result:** Only Saweria board, BagiBagi polling disabled

#### Maintenance (All Disabled):
```lua
Config.BagiBagi.Enabled = false
Config.Saweria.Enabled = false
```
**Result:** No boards, no polling, webhooks still save to database

---

## 🔄 How It Works

### BagiBagi Flow:
```
1. Donation on BagiBagi
   ↓
2. POST /api/webhooks/bagibagi
   ↓
3. Save to bagibagi_donations table
   ↓
4. Roblox polls /api/roblox/donations?source=bagibagi
   ↓
5. Fire BagiBagiRealtimeDonation → Clients
   ↓
6. Display on BagibagiBoard
```

### Saweria Flow:
```
1. Donation on Saweria
   ↓
2. POST /api/webhooks/saweria
   ↓
3. Save to saweria_donations table
   ↓
4. Roblox polls /api/roblox/donations?source=saweria
   ↓
5. Fire SaweriaRealtimeDonation → Clients
   ↓
6. Display on SaweriaBoard
```

---

## 📊 RemoteEvents Created

### BagiBagi:
```
ReplicatedStorage/
├── RealtimeDonation (RemoteEvent)              → Live feed
└── BagiBagiDonationSystem/
    └── ShowBagiBagiDonationNotif (RemoteEvent) → Notifications
```

### Saweria:
```
ReplicatedStorage/
├── SaweriaRealtimeDonation (RemoteEvent)       → Live feed
└── SaweriaDonationSystem/
    └── ShowSaweriaDonationNotif (RemoteEvent)  → Notifications
```

---

## 🧪 Testing

### Test Configuration:

```lua
-- In DonationConfig
Config.BagiBagi.Enabled = true
Config.Saweria.Enabled = true
```

### Test BagiBagi:
```bash
curl -X POST https://your-domain.com/api/webhooks/bagibagi \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: your_token" \
  -d '{"donor":"TestUser","amount":50000,"message":"Test"}'
```

**Expected in Roblox Output:**
```
🔄 [BAGIBAGI] Poll successful, donations: 1
💰 [BAGIBAGI] TestUser → 50000 | Matched: TestUser
```

### Test Saweria:
```bash
curl -X POST https://your-domain.com/api/webhooks/saweria \
  -H "Content-Type: application/json" \
  -d '{"donor":"TestUser","amount":50000,"message":"Test"}'
```

**Expected in Roblox Output:**
```
🔄 [SAWERIA] Poll successful, donations: 1
💰 [SAWERIA] TestUser → 50000 | Matched: TestUser
```

---

## 🐛 Troubleshooting

### Issue: Config not found

**Error:** `DonationConfig is not a valid member of ServerStorage`

**Fix:**
1. Check `DonationConfig.luau` exists in ServerStorage
2. Check it's a **ModuleScript** (not Script)
3. Restart game in Studio

### Issue: Boards not showing data

**Check:**
1. Config enabled: `Config.BagiBagi.Enabled = true`
2. Board exists in Workspace: `Workspace.BagibagiBoard`
3. Client scripts loaded in StarterPlayerScripts
4. Check Output for polling logs

### Issue: Polling not working

**Check:**
1. API URL correct in `WebhookIntegrationDual.luau`:
   ```lua
   local WEBHOOK_API_BASE = "https://your-domain.com/"
   ```
2. HttpService enabled:
   - Game Settings → Security → HTTP Requests → Enabled
3. Check Output for error messages

### Issue: RemoteEvents not found

**Check:**
1. Server script running (WebhookIntegrationDual)
2. Check ReplicatedStorage for:
   - `RealtimeDonation`
   - `SaweriaRealtimeDonation`
   - `BagiBagiDonationSystem`
   - `SaweriaDonationSystem`

---

## 📝 Configuration Options

### Poll Interval:
```lua
-- In WebhookIntegrationDual.luau
local POLL_INTERVAL = 5  -- Poll every 5 seconds
```

### API Endpoints:
```lua
-- In DonationConfig
Config.BagiBagi.API.Endpoint = "/api/roblox/donations?source=bagibagi"
Config.Saweria.API.Endpoint = "/api/roblox/donations?source=saweria"
```

### Board Paths:
```lua
-- In DonationConfig
Config.BagiBagi.Board.WorkspacePath = "BagibagiBoard"
Config.Saweria.Board.WorkspacePath = "SaweriaBoard"
```

---

## ✅ Success Checklist

### Server Side:
- [ ] `DonationConfig.luau` in ServerStorage
- [ ] `WebhookIntegrationDual.luau` in ServerScriptService
- [ ] `SaweriaDonationEffect.luau` in ServerScriptService
- [ ] HttpService enabled
- [ ] Output shows config status

### Client Side:
- [ ] 6 client scripts in StarterPlayerScripts
- [ ] All scripts load without errors
- [ ] RemoteEvents exist in ReplicatedStorage

### Workspace:
- [ ] `BagibagiBoard` Part exists
- [ ] `SaweriaBoard` Part exists
- [ ] Both have SurfaceGuis (Board + LiveDonation)

### Testing:
- [ ] Config shows both platforms enabled
- [ ] Polling logs appear in Output
- [ ] Test donations trigger updates
- [ ] Boards show data
- [ ] Notifications popup

---

## 🎉 Complete Setup Example

### 1. ServerStorage:
```
ServerStorage/
└── DonationConfig ✅ (ModuleScript)
```

### 2. ServerScriptService:
```
ServerScriptService/
├── WebhookIntegrationDual ✅ (Script)
└── SaweriaDonationEffect ✅ (Script)
```

### 3. StarterPlayerScripts:
```
StarterPlayerScripts/
├── BagiBagiLiveDonation ✅
├── BagiBagiTopDonation ✅
├── RupiahNotification ✅
├── SaweriaLiveDonation ✅
├── SaweriaTopDonation ✅
└── SaweriaNotification ✅
```

### 4. Workspace:
```
Workspace/
├── BagibagiBoard ✅ (Part)
│   ├── BagibagiBoard (SurfaceGui)
│   └── LiveDonation (SurfaceGui)
└── SaweriaBoard ✅ (Part)
    ├── SaweriaBoard (SurfaceGui)
    └── LiveDonation (SurfaceGui)
```

### 5. Output (When Working):
```
🎮 ========== DUAL PLATFORM DONATION SYSTEM ==========
BagiBagi: ✅ ENABLED
Saweria: ✅ ENABLED
Platforms Active: 2
🚀 [BAGIBAGI] Polling started!
🚀 [SAWERIA] Polling started!
✅ Dual Platform Donation System ready!
✅ BagiBagi Live Donation system ready!
✅ Saweria Live Donation system ready!
```

---

## 🆘 Need Help?

1. Check Output console for errors
2. Verify config with `Config:PrintStatus()`
3. Test with curl commands
4. Review `TROUBLESHOOTING.md`
5. Check Discord for API errors

---

**Setup Time:** 30-45 minutes  
**Complexity:** Medium  
**Result:** Dual platform donation system! 🎊
