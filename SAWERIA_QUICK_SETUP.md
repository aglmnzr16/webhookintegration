# ⚡ Saweria Quick Setup (5 Menit)

## 🎯 Super Simple Setup - No Token Needed!

Saweria webhook lebih simple dari BagiBagi. **Tidak perlu token authentication!**

---

## 📋 Step-by-Step

### 1. Deploy API Anda

Pastikan API sudah deploy di Vercel/Railway:
```
https://your-domain.com
```

### 2. Buka Saweria Dashboard

1. Go to: **saweria.co/admin/integrations**
2. Klik menu **"Webhook"**

### 3. Konfigurasi Webhook

Isi form seperti di screenshot:

```
┌─────────────────────────────────────┐
│ Webhook                             │
├─────────────────────────────────────┤
│ Nyalakan: [✅ Toggle ke ON]         │
│                                     │
│ Webhook URL:                        │
│ https://your-domain.com/api/webhooks/saweria
│                                     │
│ Hitungan Gagal: 0                   │
│                                     │
│ [Simpan]                            │
└─────────────────────────────────────┘
```

**Yang Perlu Dilakukan:**
- ✅ **Toggle "Nyalakan"** ke posisi **ON** (penting!)
- ✅ **Webhook URL:** Copy-paste URL Anda:
  ```
  https://your-domain.com/api/webhooks/saweria
  ```
- ✅ **Klik "Simpan"**

**Tidak Perlu:**
- ❌ Token
- ❌ API Key
- ❌ Custom Headers
- ❌ Signature

---

## 🧪 Test Webhook

### Cara 1: Test dari Saweria Dashboard

Klik button **"Munculkan Notifikasi"** di dashboard Saweria.

**Expected Result:**
- ✅ Saweria sends test webhook
- ✅ Your API receives POST request
- ✅ Data saved to database
- ✅ Discord notification sent (if configured)

### Cara 2: Test dengan Curl

```bash
curl -X POST https://your-domain.com/api/webhooks/saweria \
  -H "Content-Type: application/json" \
  -d '{
    "donor": "TestUser",
    "amount": 50000,
    "message": "Test donation"
  }'
```

**Expected Response:**
```json
{
  "ok": true,
  "donation": {
    "id": "...",
    "donor": "TestUser",
    "amount": 50000
  }
}
```

---

## ✅ Verification Checklist

### Dashboard Check:
- [ ] Toggle "Nyalakan" is **ON** (biru/hijau)
- [ ] Webhook URL correct (https://...)
- [ ] "Hitungan Gagal" = **0** (zero failures)
- [ ] Button "Simpan" clicked

### API Check:
- [ ] Webhook endpoint exists: `/api/webhooks/saweria`
- [ ] API is deployed and accessible
- [ ] Database has `saweria_donations` table
- [ ] Database has `saweria_top_spenders` table

### Roblox Check:
- [ ] `SaweriaBoard` exists in Workspace
- [ ] Config: `Config.Saweria.Enabled = true`
- [ ] Client scripts loaded

---

## 🔍 Troubleshooting

### "Hitungan Gagal" > 0?

**Kemungkinan Penyebab:**
1. ❌ URL salah (typo)
2. ❌ API not deployed
3. ❌ API returns error (500)
4. ❌ HTTPS tidak accessible

**Solusi:**
```bash
# Check API logs
vercel logs
# atau
railway logs

# Test URL manually
curl https://your-domain.com/api/webhooks/saweria
# Should NOT return 404
```

### Webhook Tidak Diterima?

**Check:**
1. API deployed? `vercel ls` or `railway status`
2. URL correct? Copy dari deployment
3. Toggle ON? Re-check dashboard
4. Test dengan curl (see above)

### Database Tidak Update?

**Check:**
```bash
# Verify tables exist
npx prisma studio

# Check saweria_donations table
# Should see entries after webhook
```

---

## 📦 Payload yang Saweria Kirim

Saweria akan kirim POST request dengan JSON body:

```json
{
  "donor": "Nama Donor",
  "amount": 50000,
  "message": "Pesan donor (optional)",
  "created_at": "2024-01-01T12:00:00Z"
}
```

**Field names bisa berbeda:**
- `donor` atau `name` - Nama donor
- `amount` atau `nominal` - Jumlah rupiah
- `message` atau `note` - Pesan

**API kita handle semua variasi!** ✅

---

## 🎮 Roblox Integration

Setelah webhook setup, data otomatis masuk ke Roblox board:

```lua
-- In DonationConfig.luau
Config.Saweria = {
    Enabled = true,  -- ✅ Make sure this is true
    Board = {
        WorkspacePath = "SaweriaBoard",
    },
}
```

**Live Updates:**
- Saweria donation → API → Database → Roblox polling → SaweriaBoard

**Polling interval:** 5 seconds (real-time!)

---

## 🔐 Security

### Saweria Tidak Pakai Token?

**Benar!** Saweria tidak mengirim auth token di header.

**Bagaimana Aman?**
1. ✅ **IP Validation** - Log request IP
2. ✅ **Payload Validation** - Check required fields
3. ✅ **Database Validation** - Prevent duplicates
4. ✅ **Discord Logs** - Monitor all donations

**Optional:** Add IP whitelist jika Saweria provide static IPs.

---

## 📊 Monitoring

### Check Saweria Dashboard:

**"Hitungan Gagal" Counter:**
- ✅ **0** = Perfect! All webhooks successful
- ⚠️ **> 0** = Some webhooks failed (check logs)

### Check Database:

```sql
-- Count Saweria donations
SELECT COUNT(*) FROM saweria_donations;

-- Recent donations
SELECT * FROM saweria_donations 
ORDER BY created_at DESC 
LIMIT 10;

-- Top spenders
SELECT * FROM saweria_top_spenders 
ORDER BY total_amount DESC 
LIMIT 10;
```

### Check Roblox:

```lua
-- Print config status
local Config = require(ServerStorage.DonationConfig)
Config:PrintStatus()

-- Output should show:
-- Saweria: ✅ ENABLED
```

---

## 🎉 Complete Setup Example

### 1. Environment (.env.local):
```env
DATABASE_URL="postgresql://..."
DISCORD_WEBHOOK_URL="https://discord.com/..."
# SAWERIA_WEBHOOK_TOKEN not needed!
```

### 2. Saweria Dashboard:
```
Nyalakan: ✅ ON
Webhook URL: https://your-domain.com/api/webhooks/saweria
Hitungan Gagal: 0
```

### 3. Roblox (DonationConfig.luau):
```lua
Config.Saweria.Enabled = true
```

### 4. Test:
```bash
# Send test donation
curl -X POST https://your-domain.com/api/webhooks/saweria \
  -H "Content-Type: application/json" \
  -d '{"donor":"Test","amount":50000}'

# Check response
# Should return: {"ok":true,"donation":{...}}
```

---

## ✅ Success!

**If all checks pass:**
- ✅ Toggle ON
- ✅ Hitungan Gagal = 0
- ✅ Database has entries
- ✅ Roblox board shows donations

**You're done!** Saweria webhook is live! 🚀

---

## 🆘 Still Having Issues?

1. Check logs: `vercel logs` or `railway logs`
2. Review: `SAWERIA_VS_BAGIBAGI.md`
3. Test with curl command above
4. Check Discord for error notifications
5. Verify Roblox config enabled

**Saweria setup is the EASIEST!** Just URL, toggle ON, done! 🎊
