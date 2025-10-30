# Donation Popup Notification System

## 🎉 Overview

Beautiful popup notification system yang muncul di atas screen setiap ada donation baru!

**Features:**
- ✅ Animated popup dengan avatar, nama, amount, dan message
- ✅ Display name support: "PuffXDom (@moonzet16)"
- ✅ Thousand separator format: "Rp. 5.000"
- ✅ Dynamic duration based on amount & message length
- ✅ Sound effects
- ✅ Queue system (multiple notifications)
- ✅ Responsive design (mobile & desktop)

---

## 📊 How It Works

### Complete Flow:

```
[Step 1] Donation Made via BagiBagi
    ↓
[Step 2] Webhook receives → API saves to donations.json
    ↓
[Step 3] Roblox Server polls API (every 3 seconds)
    ↓
[Step 4] Server receives new donation
    ↓
[Step 5] Server fetches display name + userId
    ↓
[Step 6] Server fires ShowNewDonationNotif:FireAllClients()
    ↓
[Step 7] Client (DonationNotif.luau) receives notification
    ↓
[Step 8] 🎉 POPUP APPEARS!
    - Avatar loads
    - Display name shows: "PuffXDom (@moonzet16)"
    - Amount shows: "Donation: Rp. 5.000"
    - Message shows: "Message: Thank you!"
    - Sound plays
    ↓
[Step 9] Popup stays for 5-15 seconds (dynamic)
    ↓
[Step 10] Popup animates out and closes
```

---

## 🎨 Popup Design

### Visual Layout:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌────┐    Booooom Menyala                        │
│  │    │                                             │
│  │ 🧑 │    PuffXDom (@moonzet16)                   │
│  │    │    Donation: Rp. 5.000                     │
│  └────┘    Message: Thank you so much!             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Elements:**
1. **Avatar** - Player headshot (circular)
2. **Title** - "Booooom Menyala" (customizable)
3. **Name** - Display name + username format
4. **Amount** - "Donation: Rp. X.XXX"
5. **Message** - Donation message

---

## 🔧 File Structure

### Server-Side:
**`WebhookIntegration.luau`**
```lua
-- Creates RemoteEvent structure
NewDonationSystem (Folder)
└── ShowNewDonationNotif (RemoteEvent)

-- Fires notification with data:
ShowNewDonationNotif:FireAllClients({
    donatorName = "moonzet16",           -- Username
    donatorDisplayName = "PuffXDom",     -- Display name
    donatorId = 123456789,               -- UserId for avatar
    amount = 5000,                       -- Donation amount
    customMessage = "Thank you!"         -- Message
})
```

### Client-Side:
**`DonationNotif.luau`**
```lua
-- Listens for notifications
showNewDonationNotif.OnClientEvent:Connect(function(donationData)
    -- Add to queue
    table.insert(notificationQueue, donationData)
    pump() -- Process queue
end)

-- Creates and shows popup
makeGui(payload)
```

---

## 📝 Data Format

### Input (from server):

```lua
{
    donatorName = "moonzet16",           -- Required: Roblox username
    donatorDisplayName = "PuffXDom",     -- Required: Display name
    donatorId = 123456789,               -- Optional: UserId for avatar
    amount = 5000,                       -- Required: Donation amount
    customMessage = "Thank you!"         -- Optional: Message (default: "No message")
}
```

### Display Format:

```
Title:   "Booooom Menyala"
Name:    "PuffXDom (@moonzet16)"
Amount:  "Donation: Rp. 5.000"
Message: "Message: Thank you!"
```

---

## ⏱️ Dynamic Duration

**Base Duration:** 5 seconds

**Extra Time - Amount:**
- Rp. 10.000+  → +4 seconds
- Rp. 5.000+   → +3 seconds  
- Rp. 2.000+   → +2 seconds
- Rp. 1.000+   → +1 second

**Extra Time - Message:**
- +1 second per 15 characters

**Examples:**
```
Rp. 500, no message        → 5 seconds
Rp. 2.000, no message      → 7 seconds (5+2)
Rp. 5.000, "Thank you!"    → 9 seconds (5+3+1)
Rp. 10.000, long message   → 13+ seconds
```

---

## 🎵 Sound Effects

**Location:** `workspace.Donors.Sounds.Donation`

**Fallback:** Any sound in `workspace.Donors.Sounds` folder

**Setup:**
1. Create folder: `workspace.Donors.Sounds`
2. Add Sound object named "Donation"
3. Configure sound properties (volume, pitch, etc.)

**If no sound found:**
- Notification still works
- Just no audio feedback

---

## 🎯 Examples

### Example 1: Player with Display Name

**Donation:**
- Username: moonzet16
- Display Name: PuffXDom
- Amount: Rp. 5.000
- Message: "Terima kasih!"

**Server Logs:**
```
🎉 [POPUP NOTIF] Triggering notification popup for: PuffXDom ( moonzet16 )
[AVATAR] Attempting to load avatar for userId: 123456789
```

**Popup Shows:**
```
Title:   Booooom Menyala
Name:    PuffXDom (@moonzet16)
Amount:  Donation: Rp. 5.000
Message: Message: Terima kasih!
Duration: 9 seconds
```

---

### Example 2: Player Same Display Name

**Donation:**
- Username: TestPlayer
- Display Name: TestPlayer (same)
- Amount: Rp. 2.000
- Message: ""

**Popup Shows:**
```
Title:   Booooom Menyala
Name:    TestPlayer (@TestPlayer)
Amount:  Donation: Rp. 2.000
Message: Message: No message
Duration: 7 seconds
```

---

### Example 3: No Matched Username

**Donation:**
- Donor: "Anonymous Donor"
- No Roblox username matched
- Amount: Rp. 1.000
- Message: "Keep it up!"

**Popup Shows:**
```
Title:   Booooom Menyala
Name:    Anonymous Donor (@Anonymous Donor)
Amount:  Donation: Rp. 1.000
Message: Message: Keep it up!
Duration: 7 seconds (5+1+1)
```

---

## 🎨 Customization

### Change Title Text:

```lua
-- In DonationNotif.luau line ~170
title.Text = "Booooom Menyala"  -- Change this!

-- Examples:
title.Text = "New Donation!"
title.Text = "🎉 Thank You! 🎉"
title.Text = "Support Received"
```

### Change Colors:

```lua
-- Background
root.BackgroundColor3 = Color3.fromRGB(24, 7, 3)

-- Stroke (border)
stroke.Color = Color3.fromRGB(255, 128, 38)

-- Text colors
row1.TextColor3 = Color3.fromRGB(230, 230, 255)  -- Name
row2.TextColor3 = Color3.fromRGB(255, 144, 32)   -- Amount
row3.TextColor3 = Color3.fromRGB(255, 138, 21)   -- Message
```

### Change Duration Formula:

```lua
-- In DonationNotif.luau line ~264
local baseDuration = 5  -- Change base time

-- Amount thresholds
if payload.amount >= 10000 then
    extraDuration = extraDuration + 4  -- Adjust bonus time
```

---

## 🧪 Testing

### Test 1: Basic Notification

**Steps:**
1. Start game
2. Make donation via BagiBagi
   - Donor: Your Roblox username
   - Amount: 5000
   - Message: "Test notification"
3. Wait 3-5 seconds
4. Check for popup appearance

**Expected:**
- ✅ Popup slides in from top
- ✅ Avatar loads
- ✅ Name shows with display name format
- ✅ Amount shows: "Rp. 5.000"
- ✅ Message shows
- ✅ Sound plays
- ✅ Popup stays ~9 seconds
- ✅ Popup slides out

---

### Test 2: Multiple Notifications (Queue)

**Steps:**
1. Simulate 3 quick donations
2. Use `/api/test/simulate-donation` endpoint 3 times rapidly

**Expected:**
- ✅ First notification shows
- ✅ Second notification queued
- ✅ After first completes, second shows
- ✅ Then third shows
- ✅ No overlapping popups
- ✅ Clean transitions

---

### Test 3: Long Message

**Steps:**
1. Donate with very long message (100+ characters)

**Expected:**
- ✅ Message displays (may truncate if too long)
- ✅ Duration increases (base + message length bonus)
- ✅ Popup stays longer to allow reading

---

### Test 4: No Avatar (Invalid Username)

**Steps:**
1. Donate with invalid Roblox username

**Expected:**
- ✅ Popup still shows
- ✅ Placeholder avatar shows
- ✅ Name displays as-is
- ✅ Amount and message work normally

---

## 📊 Console Logs

### Server Logs:

```
🎉 Donasi baru: moonzet16 donated 5000 | Roblox: moonzet16
🎉 [POPUP NOTIF] Triggering notification popup for: PuffXDom ( moonzet16 )
```

### Client Logs:

```
[NEW DONATION NOTIF] Received: moonzet16 - 5000 Robux - "Thank you!"
[NEW DONATION NOTIF] DonatorId: 123456789
[NEW DONATION NOTIF] Full data: {...}
[AVATAR] Attempting to load avatar for userId: 123456789
[AVATAR] Successfully got avatar URL: rbxthumb://...
[DONATION NOTIF] Showing for 9 seconds
```

---

## 🆘 Troubleshooting

### Issue: Popup Not Appearing

**Check:**
1. ✅ `DonationNotif.luau` in StarterPlayerScripts?
2. ✅ Console shows "[NEW DONATION NOTIF] Received"?
3. ✅ Server shows "[POPUP NOTIF] Triggering"?
4. ✅ Check for script errors in Output

**Debug:**
```lua
-- Add at top of DonationNotif.luau
print("[NOTIF] Script loaded successfully!")

-- Check if RemoteEvent exists
print("[NOTIF] Waiting for NewDonationSystem...")
local newDonationSystem = ReplicatedStorage:WaitForChild("NewDonationSystem", 10)
if not newDonationSystem then
    warn("[NOTIF] NewDonationSystem not found!")
end
```

---

### Issue: Avatar Not Loading

**Check:**
1. ✅ UserId is valid number?
2. ✅ Console shows avatar loading attempt?
3. ✅ Network requests not blocked?

**Debug:**
```lua
-- Check userId
print("[DEBUG] DonatorId type:", type(payload.donatorId))
print("[DEBUG] DonatorId value:", payload.donatorId)
```

**Fallback:**
- Popup still works with placeholder avatar
- Orange circle with default icon

---

### Issue: Sound Not Playing

**Check:**
1. ✅ `workspace.Donors.Sounds.Donation` exists?
2. ✅ Sound object configured correctly?
3. ✅ Volume > 0?
4. ✅ SoundService not muted?

**Setup Sound:**
```
1. Create structure:
   workspace
   └── Donors (Folder)
       └── Sounds (Folder)
           └── Donation (Sound)

2. Configure Sound:
   - SoundId: rbxassetid://XXXXX
   - Volume: 0.5-1.0
   - PlaybackSpeed: 1.0
```

---

### Issue: Popup Too Fast/Slow

**Adjust Duration:**
```lua
-- In DonationNotif.luau
local baseDuration = 5  -- Increase for longer display

-- Or adjust amount bonuses
if payload.amount >= 5000 then
    extraDuration = extraDuration + 5  -- More bonus time
```

---

## ✅ Setup Checklist

Server Setup:
- [x] `WebhookIntegration.luau` updated
- [x] NewDonationSystem folder created
- [x] ShowNewDonationNotif RemoteEvent created
- [x] getPlayerInfo() function added
- [x] Notification trigger added to polling

Client Setup:
- [x] `DonationNotif.luau` in StarterPlayerScripts
- [x] Amount format uses "Rp." with thousand separator
- [x] Display name format: "DisplayName (@Username)"
- [x] Sound effects configured (optional)

---

## 🎉 Summary

**What You Get:**
1. ✅ Beautiful animated popup notification
2. ✅ Avatar + Display name + Amount + Message
3. ✅ Format: "PuffXDom (@moonzet16)" + "Rp. 5.000"
4. ✅ Dynamic duration (5-15+ seconds)
5. ✅ Sound effects support
6. ✅ Queue system for multiple donations
7. ✅ Responsive design (mobile + desktop)
8. ✅ Automatic + No manual work needed!

**Perfect for:**
- 🎥 Live streaming
- 🎮 In-game events
- 💰 Donation campaigns
- 👥 Community engagement

**All systems ready to go!** 🚀✨

Test dengan donate dan lihat popup notification yang keren! 🎊
