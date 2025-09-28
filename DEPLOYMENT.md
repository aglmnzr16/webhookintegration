# 🚀 Deployment Guide - BagiBagi Webhook Integration

## 📋 Checklist Deployment

### 1. Deploy ke Vercel/Netlify
```bash
# Deploy ke Vercel (recommended)
npm install -g vercel
vercel --prod

# Atau deploy ke Netlify
npm run build
# Upload folder .next ke Netlify
```

### 2. Set Environment Variables
Di dashboard hosting Anda, set:
```
WEBHOOK_TOKEN=QFWmRRYMoRPQEGhvrdSgeKo1dCVYXF
```

### 3. Configure BagiBagi Dashboard
1. Buka https://bagibagi.co/stream-overlay
2. Tab **Integration**
3. Bagian **Custom Webhook**:
   - **Custom URL**: `https://your-app.vercel.app/api/webhooks/bagibagi`
   - **Webhook Token**: `QFWmRRYMoRPQEGhvrdSgeKo1dCVYXF` (sudah ada)
4. Klik **Send Webhook Test** untuk test

### 4. Update Roblox Scripts
1. Copy file ke Roblox Studio:
   - `roblox/ServerScriptService/WebhookIntegration.luau` → ServerScriptService
   - `roblox/StarterPlayer/StarterPlayerScripts/RealtimeNotification.luau` → StarterPlayerScripts

2. Edit `WebhookIntegration.luau` line 13:
   ```lua
   local WEBHOOK_API_BASE = "https://your-app.vercel.app" -- Ganti dengan URL deploy Anda
   ```

3. Enable HttpService:
   - Game Settings → Security → Allow HTTP Requests ✅

### 5. Test Complete Flow

1. **Test Registration**:
   - Buka `https://your-app.vercel.app/register`
   - Input username Roblox → dapat code (misal `#ABC123`)

2. **Test Webhook**:
   - Di BagiBagi dashboard, klik "Send Webhook Test"
   - Atau simulasi donasi dengan message `#ABC123 test donation`

3. **Test Roblox**:
   - Jalankan game di Roblox Studio
   - Lihat console untuk log webhook polling
   - Donasi akan muncul sebagai notifikasi in-game

## 🎯 Expected Results

### ✅ Sistem Top Spender (existing)
- Leaderboard update setiap 30 detik
- Menggunakan API `/api/partnerintegration/top-donator`
- Tampil di board TopSpenderKiri & TopSpenderKanan

### ✅ Sistem Webhook Real-time (new)
- Notifikasi langsung saat donasi masuk
- Matching username via code di message
- Notifikasi muncul untuk semua player + khusus untuk target player

### 🔄 Flow Lengkap
1. Player register username → dapat code
2. Donatur donate dengan message berisi code
3. BagiBagi kirim webhook → sistem match username
4. Roblox polling → tampil notifikasi real-time
5. Top Spender API tetap jalan untuk leaderboard

## 🛠️ Troubleshooting

### Webhook tidak masuk:
- Cek environment variable `WEBHOOK_TOKEN`
- Cek URL webhook di BagiBagi dashboard
- Lihat logs di Vercel/Netlify dashboard

### Roblox tidak polling:
- Pastikan HttpService enabled
- Cek URL di `WEBHOOK_API_BASE`
- Lihat output console di Roblox Studio

### Username tidak match:
- Pastikan code format `#ABC123` di message donasi
- Cek registration berhasil di `/register`
- Lihat file `data/usernameMap.json` di server

## 📞 Support
Jika ada masalah, cek:
1. Vercel/Netlify function logs
2. Roblox Studio output console  
3. BagiBagi webhook test results
