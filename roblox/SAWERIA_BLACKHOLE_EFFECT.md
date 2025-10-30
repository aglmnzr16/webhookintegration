# 🌌 Saweria BlackHole Special Effect

## 📋 Overview

Menambahkan special effect **BlackHole** untuk donation Saweria/BagiBagi sebesar **Rp. 1,000,000 (1 juta rupiah)**.

Effect ini sama dengan BlackHole effect yang digunakan untuk Robux donation Rp. 10,000, namun di-trigger untuk donation Saweria 1 juta rupiah.

---

## 🎯 Specification

### Trigger Amount
- **Exact Match:** Rp. 1,000,000 (1 juta)
- **Conversion:** 1,000,000 ÷ 1,000 = 1,000 Robux equivalent

### Effect Type
- **Name:** BlackHole
- **Source:** JPass.Event("FireBlackHole")
- **Duration:** 120 seconds (2 minutes)
- **Type:** Special visual effect (overwrites level effects)

### Behavior
1. **Level Effects First:** Donation 1 juta akan trigger Level 4 effects (VFX + Sound)
2. **Then BlackHole:** Setelah level effects, BlackHole effect di-trigger
3. **Effect Duration:** BlackHole berlangsung selama 120 detik
4. **Early Return:** Prevents effect overlap dengan exit early setelah trigger

---

## 🔧 Implementation Details

### File Modified: `SaweriaDonationEffect.luau`

#### 1. Added JPass Integration (Lines 52-58)

**Before:**
```lua
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")

-- Track active effects to prevent overlaps
local activeEffects = {}
```

**After:**
```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")

-- JPass Events for special effects
local JPass = require(ReplicatedStorage.JamStudio.UpdateLoader.JPass)
local FireBlackHole = JPass.Event("FireBlackHole")

-- Track active effects to prevent overlaps
local activeEffects = {}
```

**Changes:**
- ✅ Added `ReplicatedStorage` service
- ✅ Required JPass module
- ✅ Created FireBlackHole event

---

#### 2. Updated Documentation (Lines 16-39)

**Added:**
```lua
SPECIAL EFFECTS:
  Rp. 1,000,000 (1 juta): BlackHole Effect

DEPENDENCIES:
  Services:
    - Players
    - ServerStorage (EffectsCharacter folder)
    - SoundService
    - ReplicatedStorage (JPass for special effects)  ← NEW
```

---

#### 3. Added BlackHole Logic (Lines 327-341)

**After level effects cleanup, added:**

```lua
-- ==================== SPECIAL EFFECTS FOR HIGH AMOUNTS ====================
-- BlackHole effect for 1 million rupiah (exact match)
if robuxEquivalent == 1000 then
    print("[SAWERIA EFFECT] Triggering BlackHole for Rp. 1,000,000!")
    FireBlackHole:FireAllClients("Saweria Donor", targetPlayer.Name, 1000000, 0)
    task.delay(120, function()
        activeEffects[targetPlayer.UserId] = nil
    end)
    return -- Exit early to prevent overlap
end

-- Reset activeEffects after standard effects
task.delay(1, function()
    activeEffects[targetPlayer.UserId] = nil
end)
```

**Logic Flow:**
1. Check if `robuxEquivalent == 1000` (which is Rp. 1,000,000)
2. Print log message
3. Fire BlackHole to all clients with parameters:
   - Donor name: "Saweria Donor"
   - Target name: `targetPlayer.Name`
   - Amount: `1000000` (for display)
   - UserId: `0` (placeholder)
4. Set cleanup timer for 120 seconds
5. Return early to prevent activeEffects reset

---

## 📊 Effect Comparison

| Platform | Amount | Effect Level | Special Effect | Duration |
|----------|--------|--------------|----------------|----------|
| **Robux** | R$ 10,000 | Level 6 | BlackHole | 120s |
| **Saweria** | Rp. 1,000,000 | Level 4 | BlackHole | 120s |
| **Robux** | R$ 1,000 | Level 4 | Fire Nuke | 90s |
| **Saweria** | Rp. 500,000 | Level 3 | None | 15s |

**Note:** Saweria Rp. 1,000,000 = 1,000 Robux equivalent, sehingga dapat Level 4, tapi mendapat bonus BlackHole effect yang biasanya untuk Level 6.

---

## 🎮 Expected Behavior

### When Someone Donates Rp. 1,000,000:

1. **Notification Popup** ✅
   - Shows: "Booooom Menyala"
   - Name: Donor name
   - Amount: "Rp. 1.000.000"
   - Message: Custom message

2. **Level 4 Effects** ✅
   - Particles from Level 4 VFX
   - Level 4 sound (looped for 15s)
   - Beams, lights from Level 4

3. **BlackHole Special Effect** 🌌
   - Massive BlackHole visual effect
   - Lasts for 120 seconds (2 minutes)
   - Visible to all players
   - Overrides level effects

4. **Cleanup** ✅
   - Level effects cleanup after 15s
   - BlackHole cleanup after 120s
   - activeEffects reset

---

## 🔍 Technical Details

### FireBlackHole Parameters

```lua
FireBlackHole:FireAllClients(donorName, recipientName, amount, donorUserId)
```

**For Saweria:**
```lua
FireBlackHole:FireAllClients(
    "Saweria Donor",           -- donorName (generic name)
    targetPlayer.Name,         -- recipientName (who gets the effect)
    1000000,                   -- amount (display amount)
    0                          -- donorUserId (placeholder, external donor)
)
```

**Why "Saweria Donor"?**
- External donations don't have Roblox UserId
- Generic name for all Saweria/BagiBagi donations
- Consistent with existing pattern

---

## 🧪 Testing Checklist

### Setup:
- [ ] Ensure JPass module exists in `ReplicatedStorage.JamStudio.UpdateLoader.JPass`
- [ ] Ensure FireBlackHole event is registered in JPass
- [ ] Ensure Level 4 VFX and Sound exist in ServerStorage

### Test Cases:

#### Test 1: Donation Rp. 1,000,000
- [ ] Send webhook with Rp. 1,000,000 donation
- [ ] Verify notification popup shows correctly
- [ ] Verify Level 4 effects play (particles, sound, beams)
- [ ] Verify BlackHole effect triggers after level effects
- [ ] Verify BlackHole lasts 120 seconds
- [ ] Verify effects cleanup properly
- [ ] Check console logs:
  ```
  [SAWERIA EFFECT] Triggering Level 4 effects (Robux equiv: 1000)
  [SAWERIA EFFECT] Applied X VFX effects from Level 4
  [SAWERIA EFFECT] Triggering BlackHole for Rp. 1,000,000!
  [SAWERIA EFFECT] Level 4 effects cleaned up
  ```

#### Test 2: Other Donation Amounts
- [ ] Test Rp. 500,000 → Should see Level 3 only, NO BlackHole
- [ ] Test Rp. 999,999 → Should see Level 3 only, NO BlackHole
- [ ] Test Rp. 1,000,001 → Should see Level 4 only, NO BlackHole
- [ ] Test Rp. 2,000,000 → Should see Level 4 only, NO BlackHole

#### Test 3: Multiple Donations
- [ ] Test rapid donations (prevent overlap)
- [ ] Test donation while BlackHole is active
- [ ] Verify activeEffects tracking works

---

## 📝 Code Pattern Comparison

### Robux BlackHole (R$ 10,000)
```lua
if donationAmount == 10000 then
    print("[ROBUX EFFECT] Triggering BlackHole for R$ 10000!")
    FireBlackHole:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
    task.delay(120, function()
        activeEffects[recipientPlayer.UserId] = nil
    end)
    return
end
```

### Saweria BlackHole (Rp. 1,000,000)
```lua
if robuxEquivalent == 1000 then
    print("[SAWERIA EFFECT] Triggering BlackHole for Rp. 1,000,000!")
    FireBlackHole:FireAllClients("Saweria Donor", targetPlayer.Name, 1000000, 0)
    task.delay(120, function()
        activeEffects[targetPlayer.UserId] = nil
    end)
    return
end
```

**Key Differences:**
| Aspect | Robux | Saweria |
|--------|-------|---------|
| Check | `donationAmount == 10000` | `robuxEquivalent == 1000` |
| Donor Name | `donatorPlayer.Name` | `"Saweria Donor"` |
| Amount | `donationAmount` (10000) | `1000000` (Rupiah) |
| Donor UserId | `donatorPlayer.UserId` | `0` (external) |

---

## 🎉 Summary

### What Was Added:
1. ✅ JPass integration for BlackHole effect
2. ✅ Special effect logic for Rp. 1,000,000
3. ✅ Updated documentation
4. ✅ Proper effect duration (120s)
5. ✅ ActiveEffects cleanup

### What Happens:
- **Donation Rp. 1,000,000** → Level 4 effects + BlackHole (120s)
- **Other amounts** → Regular level effects only

### Why This Amount:
- Rp. 1,000,000 ÷ 1,000 = 1,000 Robux equivalent
- Level 4 effects (1,000-4,999 range)
- Special bonus: BlackHole effect (usually Level 6)
- Makes 1 juta donation super special! 🌌

---

## 🚀 Next Steps

1. **Deploy** to Roblox Studio
2. **Test** with Rp. 1,000,000 webhook
3. **Verify** BlackHole effect triggers
4. **Monitor** console logs for confirmation
5. **Enjoy** the awesome BlackHole effect! 🎊

---

**File Modified:** `SaweriaDonationEffect.luau`  
**Lines Changed:** 52-58, 25-39, 327-341  
**Status:** ✅ Ready to Deploy
