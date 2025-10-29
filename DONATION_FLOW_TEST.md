# How to Verify Donation Flow (Step-by-Step)

## ❌ Problem: Donations Not Accumulating

**Symptoms:**
- You donate Rp 2.000
- API still shows `totalAmount: 2000` (same as before)
- DataStore doesn't update
- Top spender board doesn't change

## ✅ Solution: Verify Each Step

### Step 1: Verify Donation is Saved

**Test donation via simulator:**
```
https://webhook-integration-zeta.vercel.app/api/test/simulate-donation?donor=moonzet16&amount=2000
```

**Expected response:**
```json
{
  "ok": true,
  "message": "Test donation sent to webhook",
  "webhookResponse": {
    "ok": true,
    "donation": {
      "donor": "moonzet16",
      "amount": 2000,
      "matchedUsername": "moonzet16"  ← IMPORTANT!
    }
  }
}
```

**✅ Good:** `matchedUsername` is set  
**❌ Bad:** `matchedUsername` is null/undefined

---

### Step 2: Check Donations.json

**View all donations:**
```
https://webhook-integration-zeta.vercel.app/api/debug/donations?limit=50
```

**Look for:**
```json
{
  "latestDonations": [
    {
      "donor": "moonzet16",
      "amount": 2000,
      "matchedUsername": "moonzet16",  ← MUST EXIST!
      "timestamp": "2025-10-29T..."
    }
  ]
}
```

**Check stats:**
```json
{
  "stats": {
    "total": 15,
    "withMatchedUsername": 12,     ← Should increase after donation
    "withoutMatchedUsername": 3
  }
}
```

---

### Step 3: Verify Top Spenders API

**Check aggregation:**
```
https://webhook-integration-zeta.vercel.app/api/roblox/top-spenders?limit=10
```

**Expected (after 2 donations of 2000 each):**
```json
{
  "ok": true,
  "topSpenders": [
    {
      "username": "moonzet16",
      "totalAmount": 4000  ← Should be 2000 + 2000!
    }
  ]
}
```

**If still showing 2000:**
- ❌ Second donation doesn't have `matchedUsername`
- ❌ Second donation saved with different username
- ❌ Aggregation bug

---

### Step 4: Check Roblox Server Logs

**In Roblox Studio Output (Server tab):**

After donation, within **15 seconds** you should see:
```
📊 Cache age: 16 seconds (max: 15)
⚠️ Cache expired, fetching fresh data...
🔄 Updating top spenders cache...
📊 Fetched data sample:
  [1] moonzet16 - 4000  ← Should show new total!
✅ Top spenders cache updated: 1 entries
```

**If not updating:**
1. Wait 15 seconds (cache max age)
2. Client refresh will trigger server to fetch new data

---

### Step 5: Check Client Logs

**In Roblox Studio Output (Client tab):**

Every **15 seconds** you should see:
```
🔄 [TOP BOARD] Updating top spender leaderboard...
📊 [TOP BOARD] Received 1 top spenders
  [1] moonzet16 - 4000  ← Should match API!
✅ [TOP BOARD] Leaderboard updated with 1 entries
```

---

## 🔧 Common Issues & Fixes

### Issue 1: `matchedUsername` is null

**Problem:**
Donation saved but `matchedUsername` not set

**Debug:**
```
https://your-app.vercel.app/api/debug/donations
```

Look at latest donation - if `matchedUsername` is null:

**Causes:**
1. Donor name doesn't match any registered username
2. No registration exists
3. Donor name format different

**Fix:**
Use **exact same name** when donating:
- Donor name in BagiBagi: `moonzet16`
- Roblox username: `moonzet16`
- Must match exactly (case-insensitive)

---

### Issue 2: Different `matchedUsername` Each Time

**Problem:**
Each donation creates new entry instead of accumulating

**Example:**
```json
{
  "topSpenders": [
    { "username": "moonzet16", "totalAmount": 2000 },
    { "username": "Moonzet16", "totalAmount": 2000 },  ← Different case!
    { "username": "moonzet_16", "totalAmount": 2000 }  ← Different format!
  ]
}
```

**Fix:**
Always use **exact same donor name** when donating

---

### Issue 3: Cache Not Updating

**Problem:**
API shows correct data but Roblox still shows old data

**Debug:**
Check server output for cache age:
```
📊 Cache age: 5 seconds (max: 15)
✅ Using cached data (1 entries, 5 seconds old)
```

**If cache age > 15, it should auto-refresh:**
```
📊 Cache age: 20 seconds (max: 15)
⚠️ Cache expired, fetching fresh data...
```

**Fix:**
- Wait 15 seconds for auto-refresh
- Or restart Roblox server to force reload

---

## 🚀 New Settings (Faster Updates!)

### Server (WebhookIntegration.luau):
```lua
TOP_SPENDERS_REFRESH_INTERVAL = 10  -- Background refresh every 10s
TOP_SPENDERS_CACHE_MAX_AGE = 15     -- Cache expires after 15s
```

### Client (SaweriaTopBoard.luau):
```lua
REFRESH_INTERVAL = 15  -- Client refreshes every 15s (was 60s)
```

**Result:**
- Donations will appear in top board within **15-20 seconds** maximum
- Much faster than old 60s interval!

---

## 📝 Manual Test Checklist

Do these steps IN ORDER:

### Before Donation:
1. ✅ Check current total:
   ```
   https://your-app.vercel.app/api/roblox/top-spenders
   ```
   Note the `totalAmount`

### During Donation:
2. ✅ Make donation via BagiBagi
   - Donor name: Use exact Roblox username
   - Amount: 2000

3. ✅ Wait 2-3 seconds, check webhook received:
   ```
   https://your-app.vercel.app/api/debug/donations?limit=1
   ```
   - Latest donation should appear
   - `matchedUsername` should be set

### After Donation:
4. ✅ Check API updated (within 5 seconds):
   ```
   https://your-app.vercel.app/api/roblox/top-spenders
   ```
   - `totalAmount` should be OLD + 2000

5. ✅ Wait 15-20 seconds, check Roblox:
   - Server logs should show cache refresh
   - Client should display new amount
   - Board should show updated total

---

## 🧪 Quick Test (No Real Donation)

**Simulate donation:**
```
https://webhook-integration-zeta.vercel.app/api/test/simulate-donation?donor=moonzet16&amount=5000
```

**Then check:**
1. Debug endpoint - should show new donation
2. Top spenders - should show increased total
3. Wait 15s - Roblox should update

---

## ✅ Success Indicators

You'll know it's working when:

1. **Webhook:** Donation saved with `matchedUsername`
2. **API:** `totalAmount` increases correctly
3. **Server:** Cache refreshes within 15s
4. **Client:** Board updates within 15-20s
5. **DataStore:** Shows updated amount

---

## 🆘 Still Not Working?

If donations still don't accumulate:

1. **Check webhook logs** (Vercel dashboard)
2. **Verify donor name** matches exactly
3. **Clear DataStore** and restart:
   ```lua
   -- Roblox Studio Command Bar:
   local DS = game:GetService("DataStoreService")
   local store = DS:GetDataStore("TopSpendersCache")
   store:RemoveAsync("CurrentTopSpenders")
   print("✅ Cache cleared - restart server")
   ```
4. **Test with simulator** first before real donations
5. **Check API response** after each donation

---

## 📊 Expected Timeline

```
Donation made
    ↓
2-3 seconds   → Saved to donations.json
    ↓
2-3 seconds   → API endpoint returns new total
    ↓
0-15 seconds  → Server cache expires & refreshes
    ↓
15-20 seconds → Client sees update on board
```

**Total: ~20-25 seconds maximum** from donation to display!

Much better than old 60+ seconds! 🎉
