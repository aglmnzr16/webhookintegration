# Debug Guide - Troubleshooting Donation System

## 🔍 Issue: Popup Tidak Muncul & Top Board Tidak Update

### Debug Steps:

#### 1. Check Server Console (Output - Server tab)

**Look for these logs when donation received:**

```
🎉 Donasi baru: [donor] donated [amount] | Roblox: [username]

🔔 [POPUP] Starting popup notification process...
🔔 [POPUP] Matched username: moonzet16
🔔 [POPUP] Display name: PuffXDom | UserId: 123456789
🔔 [POPUP] Popup data prepared: {"amount":2000,...}
🎉 [POPUP NOTIF] Triggering Saweria notification popup for: PuffXDom ( moonzet16 )
🔔 [POPUP] Firing ShowNewDonationNotif to all clients...
🔔 [POPUP] ShowNewDonationNotif fired successfully!

🔄 [CACHE] ========== CACHE INVALIDATION ==========
🔄 [CACHE] Before - lastTopSpendersUpdate: 1234567890
🔄 [CACHE] Invalidating cache for user: moonzet16
🔄 [CACHE] After - lastTopSpendersUpdate: 0
🔄 [CACHE] Cache invalidated! Next request will fetch fresh data.
🔄 [CACHE] ========== END ==========
```

**If you DON'T see these logs:**
- ❌ Server tidak receive donation dari API
- Check: Webhook API connection
- Check: Polling berjalan? (should see "🔄 Webhook poll berhasil")

---

#### 2. Check Client Console (Output - Client tab)

**Look for these logs:**

```
🔔 [NOTIF CLIENT] Setting up OnClientEvent listener...
🔔 [NOTIF CLIENT] Listener setup complete!
[NEW DONATION NOTIFICATIONS] Loaded successfully!

... (when donation received) ...

🔔 [NOTIF CLIENT] ========== RECEIVED DONATION NOTIFICATION ==========
🔔 [NOTIF CLIENT] Raw data received!
[NEW DONATION NOTIF] Received: moonzet16 - 2000 Rupiah - "test"
[NEW DONATION NOTIF] DonatorId: 123456789
[NEW DONATION NOTIF] Currency: IDR
🔔 [NOTIF CLIENT] Adding to queue...
🔔 [NOTIF CLIENT] Queue size: 1
🔔 [NOTIF CLIENT] Calling pump()...
test isi dari notification queue [table]
[DONATION NOTIF] Showing for 7 seconds
🔔 [NOTIF CLIENT] ========== END ==========
```

**If you DON'T see "RECEIVED DONATION NOTIFICATION":**
- ❌ Client tidak receive RemoteEvent
- Check: DonationNotif.luau script running?
- Check: Script errors?

**If you see received but no "Showing for X seconds":**
- ❌ makeGui() function error
- Check: Script errors in makeGui

---

#### 3. Check for Script Errors

**In Output console, look for:**
```
❌ Error messages (red text)
⚠️ Warning messages (yellow text)
Stack traces
```

**Common errors:**
- "attempt to index nil" → Missing data field
- "Unable to cast" → Wrong data type
- "HttpError: NetFail" → API connection issue

---

## 🧪 Quick Test Commands

### Test 1: Check RemoteEvent Exists

**Run in Command Bar (Server):**
```lua
local RS = game:GetService("ReplicatedStorage")
local NDS = RS:FindFirstChild("NewDonationSystem")
local ShowNotif = NDS and NDS:FindFirstChild("ShowNewDonationNotif")
print("NewDonationSystem:", NDS)
print("ShowNewDonationNotif:", ShowNotif)
```

**Expected:**
```
NewDonationSystem: NewDonationSystem
ShowNewDonationNotif: ShowNewDonationNotif
```

---

### Test 2: Manual Fire Test

**Run in Command Bar (Server):**
```lua
local RS = game:GetService("ReplicatedStorage")
local ShowNotif = RS.NewDonationSystem.ShowNewDonationNotif

local testData = {
    donatorName = "testuser",
    donatorDisplayName = "TestUser",
    donatorId = 1,
    amount = 1000,
    customMessage = "Test notification",
    currencyType = "IDR"
}

print("Firing test notification...")
ShowNotif:FireAllClients(testData)
print("Test notification fired!")
```

**Expected:**
- Server: "Test notification fired!"
- Client: Should show popup!

**If popup shows:**
- ✅ System works! Issue is with webhook → server communication

**If popup doesn't show:**
- ❌ Client script issue
- Check: DonationNotif.luau errors

---

### Test 3: Check Cache Status

**Run in Command Bar (Server):**
```lua
print("lastTopSpendersUpdate:", lastTopSpendersUpdate)
print("Current time:", os.time())
print("Cache age:", os.time() - lastTopSpendersUpdate, "seconds")
print("Cached entries:", #cachedTopSpenders)
```

---

### Test 4: Force Refresh Top Board

**Type in chat (Client):**
```
/refreshboard
```

**Check console:**
```
🔄 Force refreshing board from API...
✅ Force refresh successful!
```

---

## 📋 Checklist

### Server Side:
- [ ] WebhookIntegration.luau running?
- [ ] NewDonationSystem folder exists in ReplicatedStorage?
- [ ] ShowNewDonationNotif RemoteEvent exists?
- [ ] Polling logs show "Webhook poll berhasil"?
- [ ] See "POPUP" logs when donation received?
- [ ] See "CACHE INVALIDATION" logs?
- [ ] No red error messages?

### Client Side:
- [ ] DonationNotif.luau in StarterPlayerScripts?
- [ ] See "Listener setup complete!" in console?
- [ ] See "RECEIVED DONATION NOTIFICATION" when donate?
- [ ] See "Showing for X seconds"?
- [ ] No red error messages?

### API Side:
- [ ] Webhook receives donation?
- [ ] Donation saved to donations.json?
- [ ] Check: https://your-app.vercel.app/api/debug/donations

---

## 🔧 Common Fixes

### Issue: Popup Tidak Muncul

**Fix 1: Restart Client**
```
1. Leave game
2. Rejoin
3. Check console for "Listener setup complete!"
4. Try donate again
```

**Fix 2: Check Script Parent**
```
DonationNotif.luau must be in:
StarterPlayer
└── StarterPlayerScripts
    └── DonationNotif.luau ✅
```

**Fix 3: Check for Typos**
```lua
-- Must match exactly:
showNewDonationNotif.OnClientEvent:Connect(...)
```

---

### Issue: Top Board Tidak Update

**Fix 1: Force Refresh**
```
Type in chat: /refreshboard
Wait 2 seconds
```

**Fix 2: Check Cache Invalidation**
```lua
-- In server console, should see:
🔄 [CACHE] After - lastTopSpendersUpdate: 0
```

**Fix 3: Check API Data**
```
Visit: https://your-app.vercel.app/api/debug/donations
Look for: Your username and total amount
```

**Fix 4: Clear DataStore**
```lua
-- Run in Command Bar (Server):
local DS = game:GetService("DataStoreService")
local store = DS:GetDataStore("TopSpendersCache")
store:RemoveAsync("CurrentTopSpenders")
print("DataStore cleared!")
```

---

## 📊 Expected Flow

### Normal Donation Flow:

```
[1] Donate via BagiBagi
    ↓
[2] Webhook receives (2-3 seconds)
    ↓
[3] Server polls API (every 3 seconds)
    ↓
[4] Server logs: "Donasi baru..."
    ↓
[5] Server fires RemoteEvents:
    - RealtimeDonation (Live Board) ✅
    - ShowNewDonationNotif (Popup) ✅
    ↓
[6] Server invalidates cache ✅
    ↓
[7] Client receives:
    - Live Board updates immediately ✅
    - Popup appears ✅
    ↓
[8] Top Board refreshes (within 15s) ✅
    - Cache expired, fetches fresh data
    - Shows updated amount
```

**Total time: ~5-16 seconds**

---

## 🆘 Still Not Working?

### Collect These Logs:

1. **Server Console:**
   - Copy ALL logs from last donation
   - Include timestamps

2. **Client Console:**
   - Copy ALL logs from last donation
   - Include timestamps

3. **Test Results:**
   - Manual fire test result?
   - RemoteEvent exists test result?
   - Force refresh result?

4. **Screenshots:**
   - Output console (Server tab)
   - Output console (Client tab)
   - Game view showing boards

### Check API:
```
Visit: https://webhook-integration-zeta.vercel.app/api/debug/donations

Look for:
- Your donation in list
- matchedUsername correct
- amount correct
```

---

## ✅ Success Indicators

**When everything works:**

**Server Console:**
```
🎉 Donasi baru: [donor] donated [amount]
🔔 [POPUP] ShowNewDonationNotif fired successfully!
🔄 [CACHE] Cache invalidated!
```

**Client Console:**
```
🔔 [NOTIF CLIENT] RECEIVED DONATION NOTIFICATION
[DONATION NOTIF] Showing for 7 seconds
```

**In Game:**
- ✅ Popup muncul di atas
- ✅ Live Board shows immediately
- ✅ Top Board updates within 15s

---

## 🎯 Quick Diagnosis

| Symptom | Cause | Fix |
|---------|-------|-----|
| No server logs | Webhook not reaching server | Check API URL |
| Server logs but no client logs | RemoteEvent not firing | Check RemoteEvent exists |
| Client logs but no popup | makeGui() error | Check console errors |
| Popup shows but wrong format | Currency detection issue | Check currencyType field |
| Top Board not updating | Cache not refreshing | Force refresh or wait 15s |

---

Happy debugging! 🔍✨
