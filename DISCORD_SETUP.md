# 🔔 Discord Logging Setup Guide

## 📋 Overview

Sistem Discord logging memberikan monitoring real-time untuk:
- 🎉 **Notifikasi donasi** dengan embed yang cantik
- 📊 **Statistik donasi** (hourly, daily, weekly, monthly)
- 🎯 **Match rate tracking** untuk efektivitas sistem
- 🏆 **Top donors & recipients** leaderboard
- ⚠️ **System alerts** untuk monitoring

## 🚀 Quick Setup

### 1. Buat Discord Webhook

1. **Buka Discord Server** yang ingin digunakan untuk monitoring
2. **Server Settings** → **Integrations** → **Webhooks**
3. **Create Webhook** atau **New Webhook**
4. **Pilih Channel** untuk notifikasi (misal: `#donations` atau `#logs`)
5. **Copy Webhook URL** (format: `https://discord.com/api/webhooks/ID/TOKEN`)

### 2. Set Environment Variable

Di Vercel dashboard atau `.env.local`:

```bash
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
```

### 3. Test Integration

```bash
# Test Discord webhook
curl https://webhook-integration-zeta.vercel.app/api/discord/log

# Test dengan custom message
curl -X POST https://webhook-integration-zeta.vercel.app/api/discord/log \
  -H "Content-Type: application/json" \
  -d '{"type":"success","title":"Test","description":"Discord integration working!"}'
```

## 📊 Available Endpoints

### 1. Test Discord Connection
```
GET /api/discord/log
```
Mengirim test message ke Discord untuk verifikasi koneksi.

### 2. Manual Logging
```
POST /api/discord/log
Content-Type: application/json

{
  "type": "info|success|warning|error",
  "title": "Log Title",
  "description": "Log description"
}
```

### 3. Donation Statistics
```
GET /api/discord/stats?period=1h|24h|7d|30d
```

Contoh response statistics:
- **Total Donasi**: Jumlah dan nilai total
- **Match Rate**: Persentase donasi yang berhasil di-match
- **Top Donors**: 5 donor terbesar
- **Top Recipients**: 5 penerima terbesar
- **Trend**: Status aktivitas donasi

## 🎨 Discord Embed Examples

### Donation Notification (Matched)
```
🎉 DONASI BARU - MATCHED!
TestDonor mendonasi untuk moonzet16!

💵 Jumlah: Rp 100.000
👤 Donor: TestDonor  
🎮 Target Roblox: moonzet16
💬 Pesan: Semangat streaming!

BagiBagi Webhook Integration
```

### Donation Notification (Unmatched)
```
💰 DONASI BARU
TestDonor mendonasi tanpa target spesifik

💵 Jumlah: Rp 50.000
👤 Donor: TestDonor
💬 Pesan: Support untuk semua!

BagiBagi Webhook Integration
```

### Statistics Report
```
📊 STATISTIK DONASI - 24 JAM TERAKHIR

💰 Total Donasi: 15 donasi - Rp 1.500.000
🎯 Match Rate: 12/15 (80%)
⭐ Rata-rata: Rp 100.000

🏆 Top Donors:
**TestDonor**: Rp 300.000
**Supporter1**: Rp 200.000
**Fan123**: Rp 150.000

🎮 Top Recipients:
**moonzet16**: Rp 500.000
**player2**: Rp 200.000
**streamer3**: Rp 100.000

📈 Trend: 📈 Aktif

BagiBagi Analytics
```

## 🔧 Advanced Configuration

### Custom Webhook Settings

Anda bisa customize Discord webhook dengan mengedit `/lib/discord.ts`:

```typescript
// Custom avatar dan username
await sendDiscordLog({
  embeds: [embed],
  username: 'BagiBagi Monitor',
  avatar_url: 'https://your-logo.png',
});
```

### Notification Filters

Untuk filter notifikasi berdasarkan amount:

```typescript
// Hanya kirim ke Discord jika donasi >= 50k
if (donation.amount >= 50000) {
  await sendDiscordLog({...});
}
```

### Multiple Discord Channels

Setup multiple webhooks untuk berbagai jenis notifikasi:

```bash
DISCORD_WEBHOOK_DONATIONS=https://discord.com/api/webhooks/.../...
DISCORD_WEBHOOK_STATS=https://discord.com/api/webhooks/.../...
DISCORD_WEBHOOK_ALERTS=https://discord.com/api/webhooks/.../...
```

## 🚨 Troubleshooting

### Common Issues

1. **"Discord webhook URL not configured"**
   - Pastikan `DISCORD_WEBHOOK_URL` sudah di-set di environment variables
   - Redeploy setelah menambahkan env var

2. **"Discord webhook failed: 404"**
   - Webhook URL salah atau sudah dihapus
   - Buat webhook baru di Discord

3. **"Discord webhook failed: 429"**
   - Rate limit Discord (30 requests per minute)
   - Sistem akan retry otomatis

4. **Embed tidak muncul**
   - Check format JSON embed
   - Pastikan field tidak melebihi limit Discord

### Discord Limits

- **Message length**: 2000 characters
- **Embed title**: 256 characters  
- **Embed description**: 4096 characters
- **Field value**: 1024 characters
- **Rate limit**: 30 requests per minute

## 📱 Mobile Discord Setup

1. **Buka Discord Mobile App**
2. **Long press channel** → **Edit Channel**
3. **Integrations** → **Webhooks** → **Create Webhook**
4. **Copy URL** dan paste ke environment variable

## 🎯 Best Practices

1. **Dedicated Channel**: Buat channel khusus untuk notifikasi donasi
2. **Role Mentions**: Setup role ping untuk donasi besar
3. **Channel Permissions**: Limit akses channel monitoring
4. **Backup Webhooks**: Siapkan webhook backup jika primary gagal
5. **Log Retention**: Archive log lama secara berkala

## 📈 Monitoring Dashboard

Untuk monitoring yang lebih advanced, pertimbangkan:
- **Grafana** untuk visualisasi data
- **Discord Bot** untuk command interaktif  
- **Webhook Analytics** untuk tracking performance
- **Alert System** untuk downtime detection

---

**Setup selesai! Sekarang Anda akan mendapat notifikasi real-time setiap ada donasi BagiBagi! 🎉**
