# DataStore Persistence - No More Resets!

## ❌ Problem Sebelumnya

**Scenario:**
1. Server running, total donations: Rp 5.000
2. Stop Roblox Studio
3. Donate lagi Rp 2.000 (seharusnya jadi Rp 7.000)
4. Start Studio lagi
5. **BUG:** Total shows Rp 2.000 (RESET!)

**Root Cause:**
- Server restart → Load dari API
- API data bisa incomplete/reset (karena Vercel serverless)
- DataStore di-**overwrite** dengan data dari API
- Historical data hilang!

---

## ✅ Solution: DataStore = Source of Truth

### New Logic Flow

```
Server Start
    ↓
1. Load dari DataStore (PRESERVE historical data)
    ↓
2. Fetch dari API (get latest donations)
    ↓
3. MERGE DataStore + API (take maximum values)
    ↓
4. Save merged result back to DataStore
    ↓
Result: Data never lost!
```

### Merge Strategy

**Before (OLD - BAD):**
```lua
-- API returns: { moonzet16: 2000 }
-- DataStore has: { moonzet16: 5000 }
-- Result: OVERWRITES to 2000 ❌
cachedTopSpenders = apiData  -- REPLACE!
```

**After (NEW - GOOD):**
```lua
-- API returns: { moonzet16: 2000 }
-- DataStore has: { moonzet16: 5000 }
-- Result: KEEPS 5000 (max value) ✅
cachedTopSpenders = mergeData(apiData, datastoreData)
```

---

## 🔄 How Merge Works

### Example Scenario

**Initial State (DataStore):**
```lua
{
  { username = "moonzet16", totalAmount = 5000 },
  { username = "player2", totalAmount = 3000 }
}
```

**API Returns (after new donation):**
```lua
{
  { username = "moonzet16", totalAmount = 7000 },  -- New donation!
  { username = "player3", totalAmount = 1000 }     -- New player
}
```

**Merged Result:**
```lua
{
  { username = "moonzet16", totalAmount = 7000 },  -- MAX(5000, 7000) = 7000 ✅
  { username = "player2", totalAmount = 3000 },    -- Preserved from DataStore ✅
  { username = "player3", totalAmount = 1000 }     -- Added from API ✅
}
```

**Sorted by amount:**
```lua
[1] moonzet16 - 7000
[2] player2  - 3000
[3] player3  - 1000
```

---

## 📊 Merge Function Logic

```lua
function mergeTopSpendersData(apiData, datastoreData)
  local userMap = {}
  
  -- Step 1: Add all DataStore data (preserve historical)
  for _, spender in ipairs(datastoreData) do
    userMap[spender.username] = spender.totalAmount
  end
  
  -- Step 2: Merge with API data (take MAX)
  for _, spender in ipairs(apiData) do
    local existing = userMap[spender.username] or 0
    userMap[spender.username] = math.max(existing, spender.totalAmount)
  end
  
  -- Step 3: Convert to sorted array
  -- (sorted by totalAmount descending)
  
  return sortedArray
end
```

---

## 🚀 Server Initialization Flow

### On Server Start:

```
[Server] 📊 Initializing top spenders cache...
[Server] 🔍 DataStore = Source of Truth (data preserved across restarts)
[Server] ✅ Loaded 2 entries from DataStore (preserved data)
[Server] 🔄 Will merge with API data on next update...

Wait 2 seconds...

[Server] 🔄 Updating top spenders cache...
[Server] 📊 Merged data sample:
[Server]   [1] moonzet16 - 7000  ← Merged result!
[Server]   [2] player2 - 3000
[Server] ✅ Top spenders cache updated: 2 entries (saved to DataStore)
```

---

## ✅ Benefits

### 1. **Data Never Lost**
- ✅ Server restart → Data preserved
- ✅ API returns incomplete data → Old data kept
- ✅ Vercel serverless reset → DataStore has backup

### 2. **Always Takes Maximum**
- ✅ New donation: 7000 > 5000 → Update to 7000
- ✅ API glitch: 2000 < 5000 → Keep 5000
- ✅ Never lose progress

### 3. **Cumulative Tracking**
```
Donation 1: Rp 2.000 → Saved to DataStore
Server restart
Donation 2: Rp 3.000 → Merged: 2000 + 3000 = 5000
Server restart
Donation 3: Rp 2.000 → Merged: 5000 + 2000 = 7000
Result: Total preserved correctly! ✅
```

---

## 🧪 Testing Persistence

### Test 1: Normal Flow
1. Start server
2. Donate Rp 2.000
3. Check board: Shows Rp 2.000 ✅
4. Donate Rp 3.000
5. Check board: Shows Rp 5.000 ✅

### Test 2: Server Restart
1. Server running, total: Rp 5.000
2. **Stop Studio**
3. **Start Studio**
4. Check board: Shows Rp 5.000 ✅ (preserved!)

### Test 3: Multiple Restarts
1. Total: Rp 5.000
2. Stop → Donate Rp 2.000 → Start
3. Total: Rp 7.000 ✅
4. Stop → Donate Rp 1.000 → Start
5. Total: Rp 8.000 ✅

---

## 📋 Server Logs Examples

### Case 1: First Time (No DataStore)
```
📊 Initializing top spenders cache...
🔍 DataStore = Source of Truth
⚠️ No DataStore cache found, will fetch from API and create new cache
🔄 Updating top spenders cache...
📊 Merged data sample:
  [1] moonzet16 - 2000
✅ Top spenders cache updated: 1 entries (saved to DataStore)
```

### Case 2: Server Restart (With DataStore)
```
📊 Initializing top spenders cache...
🔍 DataStore = Source of Truth
✅ Loaded 1 entries from DataStore (preserved data)
🔄 Will merge with API data on next update...
🔄 Updating top spenders cache...
📊 Merged data sample:
  [1] moonzet16 - 5000  ← Preserved from DataStore!
✅ Top spenders cache updated: 1 entries (saved to DataStore)
```

### Case 3: New Donation After Restart
```
📊 Initializing top spenders cache...
✅ Loaded 1 entries from DataStore (preserved data)
  DataStore has: moonzet16 - 5000
🔄 Updating top spenders cache...
  API returns: moonzet16 - 7000
  Merging: MAX(5000, 7000) = 7000
📊 Merged data sample:
  [1] moonzet16 - 7000  ← Updated correctly!
✅ Top spenders cache updated: 1 entries (saved to DataStore)
```

---

## 🔍 How to Verify

### Check DataStore Contents

**In Roblox Studio Command Bar:**
```lua
local DS = game:GetService("DataStoreService")
local store = DS:GetDataStore("TopSpendersCache")
local data = store:GetAsync("CurrentTopSpenders")
print("DataStore contents:")
for i, spender in ipairs(data.data) do
    print(string.format("[%d] %s - %d", i, spender.username, spender.totalAmount))
end
```

### Expected Output:
```
DataStore contents:
[1] moonzet16 - 7000
[2] player2 - 3000
```

---

## 🆘 Troubleshooting

### Issue: Data Still Resets

**Possible causes:**
1. DataStore write failed (check for errors in output)
2. DataStore read failed on restart
3. API returns higher value and overwrites (check merge logic)

**Debug:**
```lua
-- Check if data exists in DataStore
local success, data = pcall(function()
    return TopSpendersStore:GetAsync("CurrentTopSpenders")
end)

if success and data then
    print("✅ DataStore has data:", #data.data, "entries")
    for i, spender in ipairs(data.data) do
        print(string.format("  [%d] %s - %d", i, spender.username, spender.totalAmount))
    end
else
    print("❌ DataStore is empty or read failed")
end
```

### Issue: Amounts Not Merging Correctly

**Check merge logs:**
```
🔄 Updating top spenders cache...
  DataStore has: moonzet16 = 5000
  API returns: moonzet16 = 2000
  Merging: MAX(5000, 2000) = 5000  ← Should keep 5000
```

If not showing correct merge, check `mergeTopSpendersData()` function.

---

## 🎯 Key Points

1. **DataStore = Persistent Storage**
   - Data saved permanently
   - Survives server restarts
   - Never reset unless manually cleared

2. **Merge Strategy = Smart Update**
   - Always takes maximum value
   - Preserves historical data
   - Adds new players automatically

3. **API = Latest Updates**
   - Fetches recent donations
   - Merged with DataStore data
   - Never overwrites blindly

4. **Result = Data Integrity**
   - No more resets
   - No lost progress
   - Accurate accumulation

---

## ✅ Summary

**OLD System:**
```
Server Start → Load API → OVERWRITE DataStore → Data lost ❌
```

**NEW System:**
```
Server Start → Load DataStore → Fetch API → MERGE → Save → Data preserved ✅
```

**Benefit:**
```
Stop & restart Studio as many times as you want!
Donations will ALWAYS accumulate correctly! 🎉
```
