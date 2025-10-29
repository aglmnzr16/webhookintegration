# Live Donation Persistence

## 🎯 New Behavior

**Live donation entries akan TETAP DITAMPILKAN selama ada players di server!**

### ✅ What Changed

**Before (OLD):**
```
Donation appears
    ↓
Wait 60 seconds (ENTRY_LIFETIME)
    ↓
❌ Entry deleted automatically (even with players online!)
```

**After (NEW):**
```
Donation appears
    ↓
Stays visible as long as players in server
    ↓
Server becomes empty (0 players)
    ↓
✅ Entries cleared (ready for fresh start)
```

---

## 📊 Behavior Details

### Case 1: Players in Server
```
Player joins
    ↓
Donation 1: Rp 2.000  ← Added to list
Donation 2: Rp 5.000  ← Added to list
Donation 3: Rp 1.000  ← Added to list
    ↓
Wait 5 minutes... (players still online)
    ↓
✅ ALL 3 donations still visible!
```

**No time-based deletion!** Entries stay forever while players online.

### Case 2: Max Entries Limit (50)
```
50 donations already showing
    ↓
New donation comes in
    ↓
✅ Oldest donation removed (FIFO)
✅ New donation added
    ↓
Always keep latest 50 donations
```

### Case 3: Server Becomes Empty
```
3 players online → All donations visible
    ↓
2 players leave
    ↓
1 player online → Still visible
    ↓
Last player leaves (0 players)
    ↓
Wait 5 seconds...
    ↓
🧹 All entries cleared!
    ↓
Next player joins → Fresh start with empty board
```

---

## ⚙️ Settings

```lua
-- Settings
local MAX_ENTRIES = 50  -- Maximum entries to show (increased from 20)
local ANIMATION_DURATION = 0.5
-- ENTRY_LIFETIME removed - entries now persist!
```

**Changes:**
- ✅ `MAX_ENTRIES`: 20 → **50** (more entries visible)
- ❌ `ENTRY_LIFETIME`: **Removed** (no time-based deletion)
- ✅ **New logic**: Only clear when server empty

---

## 🔄 Cleanup Logic

### Auto-Cleanup Loop (Every 5 seconds)

```lua
while true do
    wait 5 seconds
    
    Check player count
    
    IF playerCount == 0:
        IF has entries:
            Print: "Server empty, clearing entries..."
            Fade out all entries
            Delete all entries
    ELSE:
        Keep all entries (no action)
end
```

**Key Points:**
- ✅ Check every **5 seconds** (lightweight)
- ✅ Only clear if **0 players** in server
- ✅ Fade-out animation before deletion
- ✅ No time-based deletion

---

## 📝 Server Logs

### Normal Operation (Players Online)
```
[Client] ✅ Donation added to live feed: moonzet16 Rp. 2.000
[Client]    Total entries: 5/50 | Players in server: 2

... (entries stay visible) ...

[Client] ✅ Donation added to live feed: player2 Rp. 5.000
[Client]    Total entries: 6/50 | Players in server: 2
```

### Server Becomes Empty
```
[Client]    Players in server: 1
[Client]    Players in server: 1
[Client]    Players in server: 0  ← Last player left

Wait 5 seconds...

[Client] 🧹 Server empty (0 players), clearing live donation entries...
[Client]    (fade out animation)
[Client]    All entries deleted
```

### Max Entries Reached
```
[Client] ✅ Donation added to live feed: newDonor Rp. 10.000
[Client]    Total entries: 50/50 | Players in server: 3
[Client]    ⚠️ Max entries reached, removing oldest entry
[Client]    Total entries: 50/50 (after cleanup)
```

---

## 🎮 Player Experience

### Scenario 1: Long Play Session
```
Player joins at 10:00 AM
    ↓
Donations come in throughout the day:
  10:05 - Rp 2.000
  10:30 - Rp 5.000
  11:00 - Rp 1.000
  12:00 - Rp 3.000
    ↓
Player still playing at 2:00 PM
    ↓
✅ ALL donations still visible on board!
```

**Benefit:** Player can see **complete donation history** during their session!

### Scenario 2: Multiple Players
```
Player A joins → Sees all current donations
Player B joins → Sees same donations as Player A
Player C joins → Sees same donations
    ↓
All players leave
    ↓
5 seconds later → Board cleared
    ↓
New player joins → Fresh empty board
```

**Benefit:** Consistent view for all players, fresh start when server resets.

### Scenario 3: Stream/Event
```
Event starts with 0 donations
    ↓
Donations come in:
  Donation 1, 2, 3, ... 20, 21, ... 50
    ↓
All 50 latest donations visible throughout event
    ↓
Event ends, everyone leaves
    ↓
Board clears automatically
```

**Benefit:** Perfect for streams - viewers can see **all recent donations**!

---

## 🔍 Technical Details

### Player Count Check

```lua
local Players = game:GetService("Players")
local playerCount = #Players:GetPlayers()

if playerCount == 0 then
    -- Server is empty, clear entries
else
    -- Keep all entries
end
```

### Entry Lifecycle

```
Entry Created
    ↓
Added to board (visible)
    ↓
┌─────────────────────────┐
│ While players online:   │
│   - Entry persists      │
│   - No time limit       │
│   - Always visible      │
└─────────────────────────┘
    ↓
Server becomes empty
    ↓
Entry fades out (0.5s animation)
    ↓
Entry deleted
```

### Max Entries Management

```
Current: 50 entries (MAX_ENTRIES)
    ↓
New donation arrives
    ↓
IF count > MAX_ENTRIES:
    Remove oldest entry (by LayoutOrder)
    Add new entry
ELSE:
    Just add new entry
    ↓
Result: Always ≤ MAX_ENTRIES
```

---

## ✅ Benefits

### 1. **Better Player Experience**
- ✅ See complete donation history during session
- ✅ No donations suddenly disappearing
- ✅ More engaging and informative

### 2. **Stream-Friendly**
- ✅ Perfect for live streams
- ✅ Viewers can see all recent donations
- ✅ Creates FOMO effect (more donations!)

### 3. **Fair Display**
- ✅ All donations get equal visibility
- ✅ No premature deletion
- ✅ Donors feel appreciated

### 4. **Clean Reset**
- ✅ Automatic cleanup when server empty
- ✅ Fresh start for new players
- ✅ No stale old data

---

## 🧪 Testing

### Test 1: Persistence During Play
1. Join server
2. Make donation → See on board ✅
3. Wait 2 minutes (old limit was 60s)
4. Check board → **Still visible!** ✅
5. Make another donation → Both visible ✅

### Test 2: Server Empty Cleanup
1. Join server, see donations on board
2. Leave server (player count = 0)
3. Wait 5 seconds
4. Rejoin server
5. Check board → **Empty!** ✅ (cleaned up)

### Test 3: Max Entries
1. Simulate 51 donations
2. Check board → Shows latest 50 ✅
3. New donation → Oldest removed ✅
4. Always shows 50 max ✅

### Test 4: Multiple Players
1. Player A joins, makes donation
2. Player B joins → Sees Player A's donation ✅
3. Both leave (server empty)
4. Wait 5 seconds
5. Player C joins → Empty board ✅

---

## 📊 Comparison

| Feature | Before | After |
|---------|--------|-------|
| **Auto-delete** | After 60 seconds | Only when server empty |
| **Max entries** | 20 | 50 |
| **Persistence** | Time-limited | Unlimited (while players online) |
| **Cleanup** | Time-based | Player-based |
| **Stream-friendly** | ❌ (entries disappear) | ✅ (stays visible) |

---

## 🎯 Summary

**Old System:**
```
Donation → Show 60s → Delete (regardless of players) ❌
```

**New System:**
```
Donation → Show forever while players online → Delete only when server empty ✅
```

**Result:**
- ✅ Better player experience
- ✅ Stream-friendly
- ✅ More engaging
- ✅ Automatic cleanup when needed
- ✅ No manual management required

Perfect for live streams and events! 🎉
