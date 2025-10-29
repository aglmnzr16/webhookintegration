# Display Name Feature

## 🎯 Overview

**New Feature:**
1. **Display Name Format**: Show `DisplayName (Username)` instead of just username
2. **Display Name Matching**: Donate with display name → Auto-detect to correct username

## 📊 Feature #1: Display Name Format

### Before (OLD):
```
Top Board:    moonzet16
Live Donation: moonzet16
```

### After (NEW):
```
Top Board:     PuffXDom (moonzet16)
Live Donation: PuffXDom (moonzet16)
```

**Format:**
- If display name ≠ username: `DisplayName (Username)`
- If display name = username: `Username` (no duplicate)

---

## 🔍 Feature #2: Display Name Matching

### Problem:
```
User Roblox profile:
  Username: moonzet16
  Display Name: PuffXDom

Donation via BagiBagi:
  Donor name: "puffxdom"
  
❌ OLD: Not matched (no matchedUsername)
✅ NEW: Auto-matched to username "moonzet16"
```

### Matching Strategy

**Priority Order:**

1. **Code Matching** (Highest Priority)
   ```
   Message: "Donate #ABC123"
   → Check registrations.json for code
   → Match to username
   ```

2. **Username Matching**
   ```
   Donor: "moonzet16"
   → Check if matches registered username
   → Exact or partial match
   ```

3. **Display Name Matching** (NEW!)
   ```
   Donor: "puffxdom" or "PuffXDom"
   → Check displaynames.json mapping
   → Match "PuffXDom" → username "moonzet16"
   ```

4. **Auto-Assume** (Fallback)
   ```
   Donor: "anyname"
   → Assume it's a Roblox username
   → matchedUsername = "anyname"
   ```

---

## 🚀 How to Use

### Step 1: Register Display Name

**API Endpoint:**
```
POST /api/roblox/register-displayname
```

**Request Body:**
```json
{
  "username": "moonzet16",
  "displayName": "PuffXDom"
}
```

**Response:**
```json
{
  "ok": true,
  "username": "moonzet16",
  "displayName": "PuffXDom",
  "message": "Display name registered successfully"
}
```

**Example (curl):**
```bash
curl -X POST https://webhook-integration-zeta.vercel.app/api/roblox/register-displayname \
  -H "Content-Type: application/json" \
  -d '{"username":"moonzet16","displayName":"PuffXDom"}'
```

---

### Step 2: Donate with Display Name

**Scenario:**
```
1. User registers:
   Username: moonzet16
   Display Name: PuffXDom

2. User donates via BagiBagi:
   Donor field: "puffxdom" (lowercase, from BagiBagi)

3. Webhook receives:
   donor: "puffxdom"

4. System matches:
   "puffxdom" → displaynames.json → "PuffXDom" → username: "moonzet16"

5. Result:
   matchedUsername: "moonzet16" ✅
   Displayed as: "PuffXDom (moonzet16)" ✅
```

---

## 📂 File Storage

### `displaynames.json`
```json
{
  "moonzet16": "PuffXDom",
  "player2": "CoolGamer99",
  "player3": "ProPlayer"
}
```

**Format:** `{ username: displayName }`

**Location:** Vercel blob storage (same as donations.json)

---

## 🔧 Technical Implementation

### Client-Side (Roblox)

#### Get Display Name:
```lua
function getDisplayName(username)
  local userId = Players:GetUserIdFromNameAsync(username)
  local displayName = Players:GetNameFromUserIdAsync(userId)
  return displayName
end
```

#### Format Name:
```lua
function formatPlayerName(username)
  local displayName = getDisplayName(username)
  
  if displayName:lower() == username:lower() then
    return username  -- Same, no need to show both
  else
    return displayName .. " (" .. username .. ")"
  end
end
```

#### Usage:
```lua
-- Top Board
usernameLabel.Text = formatPlayerName("moonzet16")
-- Result: "PuffXDom (moonzet16)"

-- Live Donation
donorName.Text = formatPlayerName(donation.robloxUsername)
-- Result: "PuffXDom (moonzet16)"
```

---

### Server-Side (API)

#### Matching Logic (webhook handler):
```typescript
// 1. Try username match
if (donor matches username in registrations) {
  matchedUsername = username;
}

// 2. Try display name match (NEW!)
if (!matchedUsername) {
  for (const [username, displayName] of displayNames) {
    if (donor matches displayName) {
      matchedUsername = username;
      break;
    }
  }
}

// 3. Fallback
if (!matchedUsername) {
  matchedUsername = donor;
}
```

---

## 📝 API Endpoints

### 1. Register Display Name

**POST** `/api/roblox/register-displayname`

**Body:**
```json
{
  "username": "moonzet16",
  "displayName": "PuffXDom"
}
```

**Response:**
```json
{
  "ok": true,
  "username": "moonzet16",
  "displayName": "PuffXDom",
  "message": "Display name registered successfully"
}
```

---

### 2. Get Display Name

**GET** `/api/roblox/register-displayname?username=moonzet16`

**Response:**
```json
{
  "ok": true,
  "username": "moonzet16",
  "displayName": "PuffXDom"
}
```

---

### 3. Get All Display Names

**GET** `/api/roblox/register-displayname`

**Response:**
```json
{
  "ok": true,
  "displayNames": {
    "moonzet16": "PuffXDom",
    "player2": "CoolGamer99"
  },
  "count": 2
}
```

---

## 🧪 Testing

### Test 1: Display Name Format

```
1. Register display name:
   POST /api/roblox/register-displayname
   Body: { username: "moonzet16", displayName: "PuffXDom" }

2. Join Roblox game

3. Make donation (any method)

4. Check Top Board:
   ✅ Shows: "PuffXDom (moonzet16)"

5. Check Live Donation:
   ✅ Shows: "PuffXDom (moonzet16)"
```

---

### Test 2: Display Name Matching

```
1. Register display name:
   POST /api/roblox/register-displayname
   Body: { username: "moonzet16", displayName: "PuffXDom" }

2. Donate via BagiBagi:
   Donor field: "puffxdom" (lowercase)
   Amount: 5000

3. Check webhook logs:
   ✅ "Display name matched: puffxdom → PuffXDom (username: moonzet16)"

4. Check API:
   GET /api/roblox/top-spenders
   ✅ Shows: { username: "moonzet16", totalAmount: 5000 }

5. Check in game:
   ✅ Top Board: "PuffXDom (moonzet16) - Rp. 5.000"
   ✅ Live Donation: "PuffXDom (moonzet16) - Rp. 5.000"
```

---

### Test 3: Same Display Name & Username

```
1. User profile:
   Username: "CoolPlayer"
   Display Name: "CoolPlayer" (same)

2. Make donation

3. Check display:
   ✅ Shows: "CoolPlayer" (not "CoolPlayer (CoolPlayer)")
```

---

## 📊 Webhook Flow

### Complete Flow with Display Name:

```
Donation Made
    ↓
Webhook Received
    ↓
Extract: donor = "puffxdom"
    ↓
Matching Process:
  1. Code match? ❌
  2. Username match? ❌ (not "moonzet16")
  3. Display name match? ✅
     "puffxdom" → "PuffXDom" → username: "moonzet16"
    ↓
Set: matchedUsername = "moonzet16"
    ↓
Save to donations.json:
  {
    donor: "puffxdom",
    matchedUsername: "moonzet16",
    amount: 5000
  }
    ↓
Roblox Game:
  - Fetch display name for "moonzet16"
  - Display name: "PuffXDom"
  - Show: "PuffXDom (moonzet16)"
```

---

## 🔍 Matching Examples

### Example 1: Exact Match
```
displaynames.json: { "moonzet16": "PuffXDom" }
Donor: "PuffXDom"
→ Match: "PuffXDom" = "PuffXDom" ✅
→ Result: moonzet16
```

### Example 2: Case-Insensitive
```
displaynames.json: { "moonzet16": "PuffXDom" }
Donor: "puffxdom"
→ Normalized: "puffxdom" = "puffxdom" ✅
→ Result: moonzet16
```

### Example 3: Partial Match
```
displaynames.json: { "moonzet16": "PuffXDom" }
Donor: "puff"
→ "puff" includes in "puffxdom" ✅
→ Result: moonzet16
```

### Example 4: No Match
```
displaynames.json: { "moonzet16": "PuffXDom" }
Donor: "randomguy"
→ No match ❌
→ Fallback to username matching
→ Result: "randomguy" (auto-assume)
```

---

## ✅ Benefits

| Feature | Benefit |
|---------|---------|
| **Better UX** | Shows recognizable display names |
| **Accurate Tracking** | Matches donations even with display names |
| **Flexible** | Works with username OR display name |
| **Auto-Detect** | No manual config needed after registration |
| **Fallback** | Still works without registration |

---

## 🆘 Troubleshooting

### Issue: Display Name Not Showing

**Check:**
1. Is display name registered?
   ```bash
   GET /api/roblox/register-displayname?username=moonzet16
   ```

2. Is API call working in Roblox?
   ```lua
   print(getDisplayName("moonzet16"))  -- Should print display name
   ```

3. Check client logs for errors

---

### Issue: Donation Not Matching Display Name

**Check:**
1. Is display name registered in `displaynames.json`?
   ```bash
   GET /api/roblox/register-displayname
   ```

2. Check webhook logs:
   ```
   Look for: "Display name matched: ..." or "No match found"
   ```

3. Verify donor name format matches display name

---

## 📋 Setup Checklist

- [ ] Register display name via API
- [ ] Verify registration: `GET /api/roblox/register-displayname`
- [ ] Update Roblox scripts (SaweriaTopBoard.luau, SaweriaLiveDonation.luau)
- [ ] Test display name format in game
- [ ] Test donation with display name
- [ ] Verify matching in webhook logs
- [ ] Confirm accumulation in Top Board

---

## 🎉 Summary

**New Capabilities:**
1. ✅ Display `PuffXDom (moonzet16)` instead of just `moonzet16`
2. ✅ Donate with "puffxdom" → Auto-matched to "moonzet16"
3. ✅ Works with username OR display name
4. ✅ Automatic display name detection via Roblox API
5. ✅ Fallback to username if no display name
6. ✅ Clean format when display name = username

**Perfect for:**
- Users with different display names
- Easier donor recognition
- Better user experience
- Accurate donation tracking
