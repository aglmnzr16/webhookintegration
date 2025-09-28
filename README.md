## BagiBagi.co Webhook + Roblox Integration

This Next.js app receives donation webhooks from BagiBagi, matches them to Roblox usernames, and exposes a simple API for your Roblox game to fetch recent donations and show in‑game notifications.

### Features
- **Username registration**: page `GET /register` where users enter their Roblox username and receive a short code (e.g. `#ABCD12`).
- **Webhook receiver**: `POST /api/webhooks/bagibagi` stores donations, tries to match the donation to a Roblox username by reading `#CODE` inside the donor message, or by `roblox_username` inside the payload if provided.
- **Roblox polling API**: `GET /api/roblox/donations?username=<name>&since=<ms>` returns recent donations for a username.

---

## 1) Local setup

```bash
npm install
npm run dev
# App runs at http://localhost:3000
```

Create a `.env.local` (optional but recommended):

```
WEBHOOK_TOKEN=your-secret-token
```

If `WEBHOOK_TOKEN` is set, the webhook endpoint expects either header `x-webhook-token: your-secret-token` or `Authorization: Bearer your-secret-token`.

Data is stored on disk under `data/` as JSON files: `usernameMap.json` and `donations.json`.

---

## 2) User flow
1. Player opens `http://<your-host>/register`, inputs Roblox username, and gets a code like `#ABCD12`.
2. Player includes that code in the BagiBagi donation message: e.g., `#ABCD12 semangat!`.
3. When the webhook is delivered, the backend matches the donation and records it with `matchedUsername`.

---

## 3) Configure BagiBagi webhook

Berdasarkan dashboard BagiBagi Anda, ikuti langkah berikut:

1. **Deploy aplikasi ini** ke Vercel/Netlify terlebih dahulu
2. **Di BagiBagi dashboard** (bagian Integration):
   - **Custom URL**: Masukan `https://<your-deployed-url>/api/webhooks/bagibagi`
   - **Webhook Token**: Sudah ada `QFWmRRYMoRPQEGhvrdSgeKo1dCVYXF` (gunakan ini)

3. **Set environment variable** di hosting Anda:
{{ ... }}
   WEBHOOK_TOKEN=QFWmRRYMoRPQEGhvrdSgeKo1dCVYXF
   ```

4. **Test webhook** dengan tombol "Send Webhook Test" di dashboard BagiBagi

> **Catatan**: Sistem ini kompatibel dengan sistem Top Spender yang sudah ada. Webhook akan memberikan notifikasi real-time, sedangkan Top Spender API tetap untuk leaderboard.

---

## 4) Discord Logging Setup (Optional)

Untuk monitoring donasi real-time di Discord:

1. **Buat Discord Webhook**:
   - Buka Discord server → Server Settings → Integrations → Webhooks
   - Klik "New Webhook" → Pilih channel untuk notifikasi
   - Copy webhook URL

2. **Set Environment Variable**:
   ```bash
   DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
   ```

3. **Test Discord Integration**:
   ```bash
   curl https://your-app.vercel.app/api/discord/log
   ```

### Discord Features:
- 🎉 **Real-time donation notifications** dengan embed yang cantik
- 📊 **Statistik donasi** (hourly, daily, weekly, monthly)
- 🎯 **Match rate tracking** untuk monitoring efektivitas
- 🏆 **Top donors & recipients** leaderboard
- ⚠️ **System alerts** untuk monitoring uptime

---

## 5) Endpoints

- `POST /api/webhooks/bagibagi`
  - Body: JSON from BagiBagi.
  - Optional Auth: `x-webhook-token` or `Authorization: Bearer ...`.
  - Stores a donation record and returns `{ ok: true, donation }`.

- `POST /api/register`
  - Body JSON: `{ "username": "RobloxName" }`
  - Returns: `{ ok: true, code, username }`

- `GET /api/roblox/donations?username=<name>`
  - Returns donations for specific Roblox player
  - Used by Roblox server to poll for new donations

- `GET /api/discord/log`
  - Test Discord webhook integration
  - Sends test message to Discord

- `POST /api/discord/log`
  - Manual Discord logging
  - Body: `{ "type": "info|success|warning|error", "title": "Title", "description": "Description" }`

- `GET /api/discord/stats?period=1h|24h|7d|30d`
  - Send donation statistics to Discord
  - Default period: 24h

- `GET /api/roblox/donations?username=<name>&since=<ms>&limit=<n>`
  - Returns newest first: `{ ok: true, donations: [...] }`

---

## 5) Test locally

Register a username:

```bash
curl -s -X POST http://localhost:3000/api/register \
  -H 'content-type: application/json' \
  -d '{"username":"YourRobloxName"}'
```

Send a fake webhook:

```bash
curl -s -X POST http://localhost:3000/api/webhooks/bagibagi \
  -H 'content-type: application/json' \
  -d '{"donor":"Tester","amount":10000,"message":"#ABCD12 support!"}'
```

Fetch for Roblox:

```bash
curl -s "http://localhost:3000/api/roblox/donations?username=YourRobloxName"
```

---

## 6) Roblox example (ServerScript)

```lua
-- Services
local HttpService = game:GetService("HttpService")

local API_BASE = "https://<your-host>" -- e.g. http://localhost:3000 if using local tunnel
local USERNAME = "YourRobloxName"       -- or fetch from player.Name per-player

local lastTs = 0

local function fetchDonations()
    local url = string.format("%s/api/roblox/donations?username=%s&since=%d", API_BASE, HttpService:UrlEncode(USERNAME), lastTs)
    local ok, res = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not ok then
        warn("Fetch donations failed:", res)
        return
    end
    local data = HttpService:JSONDecode(res)
    if not data or not data.ok then return end
    for _, d in ipairs(data.donations or {}) do
        -- Show your UI/notification here
        print(string.format("DONATION: %s donated %d | msg: %s", d.donor, d.amount, d.message or ""))
        if d.ts and d.ts > lastTs then
            lastTs = d.ts
        end
    end
end

-- Poll every 5 seconds
while true do
    fetchDonations()
    task.wait(5)
end
```

Tip: For per-player polling, replace `USERNAME` with the player’s `Name` and call the API when they join.

---

## 7) Integrasi dengan sistem Roblox yang sudah ada

Anda sudah memiliki sistem Top Spender yang bagus. Untuk menambahkan notifikasi real-time:

1. **Copy file baru ke Roblox Studio**:
   - `roblox/ServerScriptService/WebhookIntegration.luau` → ServerScriptService
   - `roblox/StarterPlayer/StarterPlayerScripts/RealtimeNotification.luau` → StarterPlayerScripts

2. **Update URL di WebhookIntegration.luau**:
   ```lua
   local WEBHOOK_API_BASE = "https://your-deployed-app.vercel.app"
   ```

3. **Sistem akan berjalan bersamaan**:
   - **Top Spender** (existing): Leaderboard yang update setiap 30 detik
   - **Webhook Real-time**: Notifikasi langsung saat ada donasi baru

4. **Enable HttpService** di Roblox Studio:
   - Game Settings → Security → Allow HTTP Requests ✅

---

## 8) Notes
- Runtime for API routes is Node.js (`export const runtime = 'nodejs'`) because we use filesystem storage.
- Files are stored under `data/`. On serverless hosting, consider using a database (e.g., SQLite/Prisma, Supabase) instead.
- Sistem kompatibel dengan Top Spender API yang sudah ada - tidak akan konflik.

