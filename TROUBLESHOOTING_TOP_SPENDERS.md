# Troubleshooting: Top Spenders Amount Issues

## Masalah: Amount Tidak Akumulasi dengan Benar

Jika Anda melihat amount yang **lebih kecil dari yang seharusnya** di Top Spender board (misalnya 2000 padahal sudah donate banyak), ini kemungkinan penyebabnya:

### 1. **Donations Lama Tidak Punya `matchedUsername`**

**Gejala:**
- DataStore menunjukkan amount kecil (contoh: 2000)
- Sudah banyak donate tapi tidak terakumulasi

**Penyebab:**
- Donations yang ter-record sebelum sistem matching username aktif tidak punya field `matchedUsername`
- Top spenders API **hanya menghitung donations yang punya `matchedUsername`**

**Solusi:**
1. Check donations data via debug endpoint:
   ```
   https://your-app.vercel.app/api/debug/donations
   ```

2. Lihat di response:
   - `withMatchedUsername`: Berapa donations yang punya username
   - `withoutMatchedUsername`: Berapa yang tidak punya
   - `topSpenders`: Data yang dihitung

3. Jika banyak donations tanpa `matchedUsername`, ada 2 opsi:
   - **Option A (Recommended)**: Biarkan donations lama, system akan akumulasi donations baru
   - **Option B**: Hapus `donations.json` dan mulai fresh (data lama hilang)

### 2. **DataStore Cache Belum Refresh**

**Gejala:**
- API menunjukkan data correct tapi board di game masih lama

**Penyebab:**
- DataStore cache di Roblox server belum diupdate
- Auto-refresh interval belum trigger (default: 60 detik)

**Solusi:**
1. **Tunggu 60 detik** untuk auto-refresh
2. Atau **restart server** di Roblox Studio untuk force reload
3. Check di Output console:
   ```
   🔄 Updating top spenders cache...
   📊 Fetched data sample:
     [1] username1 - 50000
     [2] username2 - 30000
   ✅ Top spenders cache updated: 2 entries
   ```

### 3. **Donor Name Tidak Match dengan Roblox Username**

**Gejala:**
- Donate dengan nama berbeda tapi tidak terakumulasi ke username yang sama

**Penyebab:**
- System matching hanya work jika:
  - Donor name di BagiBagi = Roblox username (exact atau partial match)
  - ATAU ada code di message (format: `#XXXXXX`)
  - ATAU sudah registered via `/register` command

**Solusi:**
1. **Gunakan nama yang sama** saat donate (nama di BagiBagi = Roblox username)
2. **Atau gunakan registration system** (recommended):
   ```
   POST /api/roblox/register
   Body: { "username": "RobloxName", "code": "ABC123" }
   ```
3. Saat donate, tulis code di message: `Halo! #ABC123`

## Format Amount: Rp. 2.000

**Update Terbaru:**
- ❌ Format lama: `2K`, `1.5M` 
- ✅ Format baru: `Rp. 2.000`, `Rp. 50.000`, `Rp. 1.000.000`
- Menggunakan separator titik (.) setiap 3 digit
- Format: `Rp. [amount dengan separator]`

## Cara Debug

### 1. Check Raw Donations Data

**Browser:**
```
https://webhook-integration-zeta.vercel.app/api/debug/donations?limit=20
```

**Response akan menunjukkan:**
```json
{
  "ok": true,
  "stats": {
    "total": 15,
    "withMatchedUsername": 10,
    "withoutMatchedUsername": 5,
    "uniqueSpenders": 3
  },
  "topSpenders": [
    {
      "username": "moonzet16",
      "totalAmount": 12000,
      "donationCount": 5
    }
  ],
  "latestDonations": [...]
}
```

### 2. Check Top Spenders API

**Browser:**
```
https://webhook-integration-zeta.vercel.app/api/roblox/top-spenders?limit=10
```

**Response:**
```json
{
  "ok": true,
  "topSpenders": [
    {
      "username": "moonzet16",
      "totalAmount": 12000
    }
  ],
  "count": 1
}
```

### 3. Check Roblox Server Output

**Di Roblox Studio Output console:**
```
[Server] ✅ Fetched 3 top spenders from API
[Server] 📊 Fetched data sample:
[Server]   [1] username1 - 50000
[Server]   [2] username2 - 30000
[Server]   [3] username3 - 10000
[Server] ✅ Top spenders cache updated: 3 entries
```

**Di Client Output console:**
```
[Client] 🔄 [TOP BOARD] Updating top spender leaderboard...
[Client] 📊 [TOP BOARD] Received 3 top spenders
[Client]   [1] username1 - 50000
[Client]   [2] username2 - 30000
[Client]   [3] username3 - 10000
[Client] ✅ [TOP BOARD] Leaderboard updated with 3 entries
```

## Quick Fixes

### Fix 1: Force Refresh DataStore
```lua
-- Di Roblox Studio Command Bar:
game:GetService("ReplicatedStorage").GetTopSpenders:InvokeServer(10)
```

### Fix 2: Clear DataStore (DANGER: Hapus cache)
```lua
-- Di Roblox Studio Command Bar:
local DataStoreService = game:GetService("DataStoreService")
local TopSpendersStore = DataStoreService:GetDataStore("TopSpendersCache")
TopSpendersStore:RemoveAsync("CurrentTopSpenders")
print("✅ DataStore cleared")
```

### Fix 3: Test dengan Dummy Data
```lua
-- Di Roblox Studio Command Bar (test client):
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetTopSpenders = ReplicatedStorage:WaitForChild("GetTopSpenders")

local testData = {
    { username = "TestUser1", totalAmount = 100000 },
    { username = "TestUser2", totalAmount = 50000 },
    { username = "TestUser3", totalAmount = 25000 }
}

-- This would need to be done from server side
print(testData)
```

## Best Practices

1. **Consistent Naming**: Gunakan nama yang sama di BagiBagi dan Roblox
2. **Use Registration**: Register username dengan code untuk tracking lebih akurat
3. **Monitor Logs**: Check server output dan API responses secara berkala
4. **Wait for Refresh**: System refresh otomatis setiap 60 detik
5. **Test Endpoint**: Gunakan `/api/debug/donations` untuk verify data

## Contact & Support

Jika masih ada issue:
1. Check Output console (Server & Client tabs)
2. Test API endpoints via browser
3. Verify donations punya `matchedUsername`
4. Wait 60s untuk auto-refresh atau restart server
