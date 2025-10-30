# Multi-Currency Support - Robux & Rupiah

## 🎯 Overview

Sistem notification sekarang support **2 currency types**:
1. **Robux (R$)** - Existing in-game donation system
2. **Rupiah (Rp.)** - BagiBagi/Saweria system (NEW)

File `DonationNotif.luau` digunakan untuk **KEDUA sistem** dengan auto-detection currency!

---

## 💰 Currency Types

### Currency 1: Robux (R$)

**Source:** In-game Roblox donation system (existing)

**Format:**
```
Donation: R$ 1,000
```

**Data Structure:**
```lua
{
    donatorName = "moonzet16",
    donatorDisplayName = "PuffXDom",
    donatorId = 123456789,
    amount = 1000,
    customMessage = "Thank you!",
    currencyType = nil  -- Default ke Robux
}
```

---

### Currency 2: Rupiah (Rp.)

**Source:** BagiBagi/Saweria webhook system (NEW)

**Format:**
```
Donation: Rp. 5.000
```

**Data Structure:**
```lua
{
    donatorName = "moonzet16",
    donatorDisplayName = "PuffXDom",
    donatorId = 123456789,
    amount = 5000,
    customMessage = "Thank you!",
    currencyType = "IDR"  -- 🆕 Rupiah
}
```

---

## 🔧 How It Works

### Auto-Detection Logic:

```lua
-- In DonationNotif.luau
local currencySymbol = "R$ " -- Default: Robux

if payload.currencyType == "IDR" then
    currencySymbol = "Rp. " -- Rupiah
end

row2.Text = ("Donation: "..currencySymbol..fmt(payload.amount))
```

**Result:**
- `currencyType = nil` or missing → Shows "**R$ 1,000**"
- `currencyType = "IDR"` → Shows "**Rp. 5.000**"

---

## 📊 Visual Comparison

### Robux Donation:

```
┌──────────────────────────────────────────┐
│                                          │
│  ┌────┐   Booooom Menyala               │
│  │ 🧑 │                                  │
│  │    │   PuffXDom (@moonzet16)         │
│  └────┘   Donation: R$ 1,000            │  ← Robux format
│           Message: Thank you!            │
│                                          │
└──────────────────────────────────────────┘
```

### Rupiah Donation:

```
┌──────────────────────────────────────────┐
│                                          │
│  ┌────┐   Booooom Menyala               │
│  │ 🧑 │                                  │
│  │    │   PuffXDom (@moonzet16)         │
│  └────┘   Donation: Rp. 5.000           │  ← Rupiah format
│           Message: Terima kasih!         │
│                                          │
└──────────────────────────────────────────┘
```

---

## 🎮 Usage Examples

### Example 1: Robux Donation (Existing System)

**Trigger:**
```lua
-- Your existing Robux donation system
local popupData = {
    donatorName = "moonzet16",
    donatorDisplayName = "PuffXDom",
    donatorId = 123456789,
    amount = 1000,
    customMessage = "Great game!"
    -- NO currencyType field (defaults to Robux)
}

ShowNewDonationNotif:FireAllClients(popupData)
```

**Result:**
- Popup shows: "**Donation: R$ 1,000**"
- Uses comma separator
- Robux format maintained

---

### Example 2: Rupiah Donation (Saweria/BagiBagi)

**Trigger:**
```lua
-- WebhookIntegration.luau (automatic)
local popupData = {
    donatorName = "moonzet16",
    donatorDisplayName = "PuffXDom",
    donatorId = 123456789,
    amount = 5000,
    customMessage = "Semangat!",
    currencyType = "IDR"  -- 🆕 Rupiah flag
}

ShowNewDonationNotif:FireAllClients(popupData)
```

**Result:**
- Popup shows: "**Donation: Rp. 5.000**"
- Uses dot (titik) separator
- Rupiah format applied

---

## 📝 Implementation Details

### Server Side (WebhookIntegration.luau):

```lua
-- When BagiBagi/Saweria donation received
local popupData = {
    donatorName = donation.matchedUsername,
    donatorDisplayName = displayName or donation.matchedUsername,
    donatorId = userId,
    amount = donation.amount,
    customMessage = donation.message or "No message",
    currencyType = "IDR" -- 🆕 Always set for Rupiah donations
}

ShowNewDonationNotif:FireAllClients(popupData)
```

### Client Side (DonationNotif.luau):

```lua
-- Multi-currency detection
local currencySymbol = "R$ " -- Default: Robux

if payload.currencyType == "IDR" then
    currencySymbol = "Rp. " -- Rupiah
end

-- Display with correct symbol
row2.Text = ("Donation: "..currencySymbol..fmt(payload.amount))
```

---

## 🔍 Console Logs

### Robux Donation:

```
[NEW DONATION NOTIF] Received: moonzet16 - 1000 Robux - "Great game!"
[NEW DONATION NOTIF] DonatorId: 123456789
[NEW DONATION NOTIF] Currency: ROBUX
[DONATION NOTIF] Showing for 6 seconds
```

### Rupiah Donation:

```
[NEW DONATION NOTIF] Received: moonzet16 - 5000 Rupiah - "Terima kasih!"
[NEW DONATION NOTIF] DonatorId: 123456789
[NEW DONATION NOTIF] Currency: IDR
[DONATION NOTIF] Showing for 9 seconds
```

---

## 🧪 Testing

### Test 1: Robux Donation

**Setup:**
```lua
-- Trigger from your existing Robux donation system
local data = {
    donatorName = "testuser",
    donatorDisplayName = "TestUser",
    donatorId = 12345,
    amount = 500
}

ShowNewDonationNotif:FireAllClients(data)
```

**Expected:**
- ✅ Popup shows
- ✅ Amount: "**R$ 500**" (comma separator)
- ✅ Robux format maintained

---

### Test 2: Rupiah Donation

**Setup:**
```bash
# Make donation via BagiBagi
# Amount: 2000
# Message: "Test Rupiah"
```

**Expected:**
- ✅ Server logs: "Triggering Saweria notification..."
- ✅ Client logs: "Currency: IDR"
- ✅ Popup shows: "**Rp. 2.000**" (dot separator)

---

### Test 3: Mixed Donations

**Scenario:**
1. Donate 100 Robux (in-game)
2. Donate Rp. 3.000 (BagiBagi)
3. Donate 500 Robux (in-game)

**Expected:**
- ✅ First popup: "R$ 100"
- ✅ Second popup: "Rp. 3.000"
- ✅ Third popup: "R$ 500"
- ✅ Queue system works correctly
- ✅ No currency mixing

---

## ⚙️ Configuration

### Add New Currency Type:

```lua
-- In DonationNotif.luau
local currencySymbol = "R$ " -- Default

if payload.currencyType == "IDR" then
    currencySymbol = "Rp. "
elseif payload.currencyType == "USD" then  -- NEW!
    currencySymbol = "$ "
elseif payload.currencyType == "EUR" then  -- NEW!
    currencySymbol = "€ "
end
```

### Custom Separator:

```lua
-- Robux: comma (1,000)
-- Rupiah: dot (1.000)
-- Custom: space (1 000)

-- Modify fmt() function for custom separator
if payload.currencyType == "IDR" then
    result = "." .. result  -- Dot
else
    result = "," .. result  -- Comma
end
```

---

## 📋 Data Structure Reference

### Complete Payload:

```lua
{
    -- Required fields
    donatorName = "moonzet16",           -- Roblox username
    donatorDisplayName = "PuffXDom",     -- Display name
    amount = 5000,                       -- Donation amount
    
    -- Optional fields
    donatorId = 123456789,               -- UserId (for avatar)
    customMessage = "Thank you!",        -- Message text
    currencyType = "IDR",                -- Currency: nil/"ROBUX"/"IDR"
}
```

### Currency Type Values:

| Value | Display | Format Example |
|-------|---------|----------------|
| `nil` | R$ | R$ 1,000 |
| `"ROBUX"` | R$ | R$ 1,000 |
| `"IDR"` | Rp. | Rp. 5.000 |

---

## ✅ Benefits

| Feature | Status |
|---------|--------|
| **Backward Compatible** | ✅ Existing Robux system tetap works |
| **Multi-Currency** | ✅ Support Robux + Rupiah |
| **Auto-Detection** | ✅ No manual config needed |
| **Separate Format** | ✅ R$ 1,000 vs Rp. 5.000 |
| **Same UI** | ✅ One notification system for all |
| **Extensible** | ✅ Easy to add more currencies |

---

## 🎯 Summary

**Solution:**
1. ✅ Added `currencyType` field to payload
2. ✅ Auto-detection dalam DonationNotif.luau
3. ✅ **Robux:** Default behavior (no breaking changes)
4. ✅ **Rupiah:** Set `currencyType = "IDR"`
5. ✅ Same notification UI for both

**Result:**
- ✅ Existing Robux donations: **TETAP WORKS!**
- ✅ New Saweria donations: **AUTO-DETECTED!**
- ✅ No duplicate code needed
- ✅ One system, multiple currencies!

**Perfect solution for multi-source donations!** 🎉

---

## 🔧 Migration Guide

### For Existing Robux System:

**No changes needed!** Existing code continues to work:

```lua
-- Your existing Robux donation trigger
ShowNewDonationNotif:FireAllClients({
    donatorName = username,
    donatorDisplayName = displayName,
    donatorId = userId,
    amount = amount,
    customMessage = message
    -- NO currencyType = defaults to Robux ✅
})
```

### For New Saweria/BagiBagi System:

**Just add `currencyType = "IDR"`:**

```lua
-- WebhookIntegration.luau (already done!)
ShowNewDonationNotif:FireAllClients({
    donatorName = username,
    donatorDisplayName = displayName,
    donatorId = userId,
    amount = amount,
    customMessage = message,
    currencyType = "IDR" -- 🆕 This identifies it as Rupiah
})
```

---

## 🎉 Conclusion

**One notification system, multiple currencies!**

- ✅ No breaking changes
- ✅ No duplicate files
- ✅ Automatic detection
- ✅ Clean separation
- ✅ Easy to extend

**Works perfectly for:**
- 💎 In-game Robux donations
- 💰 External Rupiah donations (Saweria/BagiBagi)
- 🌍 Future: Any currency you want to add!

All systems integrated and working! 🚀✨
