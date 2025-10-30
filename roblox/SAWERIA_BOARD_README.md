# 📊 Saweria Board - Live Donation & Top Spender System

Sistem board untuk menampilkan donasi live dan leaderboard top spender di Roblox game Anda.

![Preview](https://via.placeholder.com/800x400/2a2a35/ffffff?text=Live+Donation+%26+Top+Saweria+Board)

## ✨ Fitur

### 1. Live Donation Feed (Panel Kiri)
- ✅ Menampilkan donasi yang masuk secara real-time
- ✅ Animasi slide-in smooth untuk setiap donasi baru
- ✅ Menampilkan avatar donor, nama, jumlah, dan pesan
- ✅ Auto-scroll dengan batas maksimal entries
- ✅ Auto-cleanup untuk donasi lama (60 detik)
- ✅ Highlight khusus untuk donasi yang ditujukan ke player tertentu

### 2. Top Saweria Board (Panel Kanan)
- ✅ Leaderboard top spender dengan ranking
- ✅ Special styling untuk top 3 (Gold 🥇, Silver 🥈, Bronze 🥉)
- ✅ Avatar dan username setiap spender
- ✅ Total donasi dengan format yang mudah dibaca (K, M)
- ✅ Auto-refresh setiap 60 detik
- ✅ Countdown timer untuk refresh berikutnya
- ✅ Animasi smooth saat update leaderboard

## 📁 File Structure

```
roblox/
├── ServerScriptService/
│   └── WebhookIntegration.luau          # Updated dengan GetTopSpenders
│
├── StarterPlayer/
│   └── StarterPlayerScripts/
│       ├── SaweriaLiveDonation.luau     # Client script untuk Live Donation
│       ├── SaweriaTopBoard.luau         # Client script untuk Top Board
│       ├── RealtimeNotification.luau    # Popup notification (sudah ada)
│       └── DonationNotif.luau           # Alternative notification (sudah ada)
│
└── Docs/
    ├── SAWERIA_BOARD_README.md          # File ini
    ├── QUICK_START_SAWERIA_BOARD.md     # Panduan setup cepat
    └── SAWERIA_BOARD_SETUP.md           # Dokumentasi detail properti UI

app/api/roblox/
└── top-spenders/
    └── route.ts                          # API endpoint untuk leaderboard
```

## 🚀 Setup

### Prerequisites

1. ✅ Webhook integration sudah berjalan
2. ✅ `WebhookIntegration.luau` sudah ter-deploy di ServerScriptService
3. ✅ HttpService enabled di game settings
4. ✅ Donations data sudah tersimpan di `donations.json`

### Installation

**Lihat panduan lengkap di:** [`QUICK_START_SAWERIA_BOARD.md`](./QUICK_START_SAWERIA_BOARD.md)

#### Ringkasan Steps:

1. **Buat UI di Roblox Studio**
   - Buat ScreenGui "SaweriaBoard" di StarterGui
   - Buat structure untuk LiveDonation panel (kiri)
   - Duplicate dan modifikasi untuk SaweriaBoard panel (kanan)

2. **Copy Scripts**
   - Copy `SaweriaLiveDonation.luau` ke StarterPlayerScripts
   - Copy `SaweriaTopBoard.luau` ke StarterPlayerScripts
   - Update `WebhookIntegration.luau` di ServerScriptService

3. **Deploy API**
   - API endpoint `/api/roblox/top-spenders` sudah tersedia
   - Vercel akan auto-deploy saat push ke repository

4. **Test**
   - Play game di Studio
   - Trigger donasi untuk test
   - Verifikasi kedua panel muncul dan berfungsi

## 🎨 Customization

### Mengubah Posisi Panel

Edit di properties Frame:

```lua
-- Live Donation (Kiri)
Position = UDim2.new(0, 20, 0.5, -250)  -- Ubah sesuai kebutuhan

-- Top Saweria Board (Kanan)  
Position = UDim2.new(1, -440, 0.5, -250)  -- Ubah sesuai kebutuhan
```

### Mengubah Ukuran Panel

```lua
Size = UDim2.new(0, 420, 0, 500)  -- Width, Height
```

### Mengubah Warna Tema

Edit di script atau UIGradient:

```lua
-- Background colors
BackgroundColor3 = Color3.fromRGB(30, 30, 35)

-- Gradient colors (Container)
Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 30))
})
```

### Mengubah Settings

Edit di script masing-masing:

**SaweriaLiveDonation.luau:**
```lua
local MAX_ENTRIES = 20          -- Maksimal entries
local ENTRY_LIFETIME = 60       -- Seconds before fade out
local ANIMATION_DURATION = 0.5  -- Animasi duration
```

**SaweriaTopBoard.luau:**
```lua
local REFRESH_INTERVAL = 60     -- Refresh interval (seconds)
local TOP_COUNT = 10            -- Jumlah top spender
local ANIMATION_DURATION = 0.6  -- Animasi duration
```

## 🎯 API Endpoints

### Get Top Spenders

```
GET /api/roblox/top-spenders?limit=10
```

Response:
```json
{
  "ok": true,
  "topSpenders": [
    {
      "username": "PlayerName",
      "totalAmount": 150000
    }
  ],
  "count": 10
}
```

### Get Donations (existing)

```
GET /api/roblox/donations?since=<timestamp>&limit=10
```

## 🔧 Troubleshooting

### Panel tidak muncul
- ✅ Cek nama ScreenGui harus "SaweriaBoard" (exact match)
- ✅ Pastikan di **StarterGui**, bukan PlayerGui
- ✅ Set `ResetOnSpawn = false`
- ✅ Set `Enabled = true`

### Leaderboard kosong
- ✅ Pastikan ada donasi dengan `matchedUsername` di database
- ✅ Test API: `https://your-url/api/roblox/top-spenders`
- ✅ Cek HttpService enabled
- ✅ Cek WEBHOOK_API_BASE di WebhookIntegration.luau

### Live Feed tidak update
- ✅ Pastikan WebhookIntegration.luau berjalan
- ✅ Cek RemoteEvent "RealtimeDonation" di ReplicatedStorage
- ✅ Trigger test donation dan cek Output console

### Script errors
- ✅ Cek Output console di Roblox Studio
- ✅ Pastikan semua nama UI exact match dengan script
- ✅ Pastikan AutomaticCanvasSize = Y di ScrollingFrame

## 📊 Performance

- **Memory**: Ringan (~5-10 MB per client)
- **Network**: Minimal (polling setiap 3s untuk live, 60s untuk leaderboard)
- **CPU**: Efisien dengan cleanup otomatis
- **Scalability**: Support ratusan donasi dengan auto-cleanup

## 🎓 Technical Details

### Architecture

```
Server (WebhookIntegration.luau)
    ↓ Polling API every 3s
    ↓ Fire RemoteEvent
Client (SaweriaLiveDonation.luau)
    ↓ Receive donation data
    ↓ Create & animate entry
    ↓ Add to ScrollingFrame
    ↓ Auto cleanup old entries

Client (SaweriaTopBoard.luau)
    ↓ Invoke RemoteFunction every 60s
    ↑ Request top spenders
Server (WebhookIntegration.luau)
    ↓ Fetch from API
    ↓ Return data
Client (SaweriaTopBoard.luau)
    ↓ Clear old entries
    ↓ Create new entries with animation
    ↓ Update leaderboard
```

### Data Flow

1. Webhook menerima donasi baru
2. Server script polling API
3. Server fire RemoteEvent ke semua clients
4. Client Live Donation menerima dan display
5. Client Top Board request update setiap 60s
6. Server fetch dari API dan return
7. Client update leaderboard

## 🎉 Features Coming Soon

- [ ] Special effects untuk donasi besar (>100K)
- [ ] Filter leaderboard by timeframe (day/week/month/all-time)
- [ ] Personal stats panel untuk player
- [ ] Donation goal tracker
- [ ] Animated transitions saat ranking berubah
- [ ] Sound effects untuk top 3 changes

## 📝 Notes

- UI structure harus dibuat manual di Roblox Studio (tidak bisa via script)
- Pastikan nama exact match dengan dokumentasi
- ScrollingFrame harus set `AutomaticCanvasSize = Y`
- RemoteEvent/Function akan auto-create oleh server script

## 🤝 Support

Jika ada masalah atau pertanyaan:
1. Cek Output console di Roblox Studio
2. Verifikasi API endpoint: `https://your-url/api/roblox/top-spenders`
3. Review file `QUICK_START_SAWERIA_BOARD.md` untuk step-by-step
4. Review file `SAWERIA_BOARD_SETUP.md` untuk detail properti UI

---

**Created for:** Live Donation & Top Spender System  
**Version:** 1.0  
**Last Updated:** 2025-01-29
