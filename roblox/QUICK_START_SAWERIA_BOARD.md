# 🚀 Quick Start - Saweria Board Setup

## Yang Sudah Dibuat ✅

1. ✅ **API Endpoint** - `/api/roblox/top-spenders` untuk leaderboard
2. ✅ **Server Script** - `WebhookIntegration.luau` sudah diupdate dengan GetTopSpenders
3. ✅ **Client Scripts**:
   - `SaweriaLiveDonation.luau` - Menampilkan live donation feed
   - `SaweriaTopBoard.luau` - Menampilkan top spender leaderboard

## Yang Perlu Anda Lakukan di Roblox Studio 🎮

### Step 1: Buat ScreenGui di StarterGui

1. Buka **Roblox Studio**
2. Di **Explorer**, cari **StarterGui**
3. Klik kanan **StarterGui** → Insert Object → **ScreenGui**
4. Rename ScreenGui menjadi **"SaweriaBoard"**
5. Set properties:
   - `ResetOnSpawn` = **false**
   - `IgnoreGuiInset` = **true**
   - `DisplayOrder` = **5**

### Step 2: Buat Live Donation Panel (Kiri)

Di dalam **SaweriaBoard**, buat struktur ini:

```
SaweriaBoard (ScreenGui)
└── LiveDonation (Frame)
    └── Board (Frame)
        └── Container (Frame)
            ├── UIGradient
            ├── UICorner
            ├── UIStroke
            ├── Header (Frame)
            │   └── Title (TextLabel)
            └── Body (Frame)
                ├── UIPadding
                └── Content (ScrollingFrame)
                    ├── UIListLayout
                    └── UIPadding
```

#### Cara Cepat Buat UI:

**A. LiveDonation (Frame)**
- Klik kanan **SaweriaBoard** → Insert Object → **Frame**
- Rename: `LiveDonation`
- Properties:
  - Size: `{0, 420}, {0, 500}`
  - Position: `{0, 20}, {0.5, -250}`
  - AnchorPoint: `0.5, 0.5` (ubah Y ke 0.5)
  - BackgroundTransparency: `1`

**B. Board (Frame)**
- Klik kanan **LiveDonation** → Insert Object → **Frame**
- Rename: `Board`
- Size: `{1, 0}, {1, 0}` (scale 1, 1)
- BackgroundTransparency: `1`

**C. Container (Frame)**
- Klik kanan **Board** → Insert Object → **Frame**
- Rename: `Container`
- Size: `{1, 0}, {1, 0}`
- BackgroundColor3: `RGB(30, 30, 35)`
- BorderSizePixel: `0`

**Tambahkan ke Container:**
1. **UIGradient**:
   - Color: Pilih 2 warna (dari `RGB(40, 40, 45)` ke `RGB(25, 25, 30)`)
   - Rotation: `90`

2. **UICorner**:
   - CornerRadius: `0, 12`

3. **UIStroke**:
   - Thickness: `2`
   - Color: `RGB(80, 80, 90)`
   - Transparency: `0.5`

**D. Header (Frame)**
- Klik kanan **Container** → Insert Object → **Frame**
- Rename: `Header`
- Size: `{1, 0}, {0, 50}`
- Position: `{0, 0}, {0, 0}`
- BackgroundColor3: `RGB(35, 35, 40)`
- Tambahkan **UICorner** dengan CornerRadius `0, 12`

**E. Title (TextLabel) di dalam Header**
- Insert **TextLabel** ke dalam **Header**
- Rename: `Title`
- Size: `{1, -20}, {1, 0}`
- Position: `{0, 10}, {0, 0}`
- BackgroundTransparency: `1`
- Text: `"Live Donation"`
- TextColor3: `RGB(255, 255, 255)`
- TextSize: `20`
- Font: `GothamBold`
- TextXAlignment: `Center`
- TextYAlignment: `Center`

**F. Body (Frame)**
- Klik kanan **Container** → Insert Object → **Frame**
- Rename: `Body`
- Size: `{1, 0}, {1, -50}`
- Position: `{0, 0}, {0, 50}`
- BackgroundTransparency: `1`

**Tambahkan UIPadding ke Body:**
- PaddingTop: `0, 10`
- PaddingBottom: `0, 10`
- PaddingLeft: `0, 10`
- PaddingRight: `0, 10`

**G. Content (ScrollingFrame) di dalam Body**
- Insert **ScrollingFrame** ke dalam **Body**
- Rename: `Content`
- Size: `{1, 0}, {1, 0}`
- Position: `{0, 0}, {0, 0}`
- BackgroundTransparency: `1`
- ScrollBarThickness: `6`
- ScrollBarImageColor3: `RGB(100, 100, 110)`
- BorderSizePixel: `0`
- CanvasSize: `{0, 0}, {0, 0}` (akan auto adjust)
- **AutomaticCanvasSize**: `Y` ⚠️ PENTING!

**Tambahkan ke Content:**
1. **UIListLayout**:
   - Padding: `0, 8`
   - SortOrder: `LayoutOrder`

2. **UIPadding**:
   - PaddingTop: `0, 5`
   - PaddingBottom: `0, 5`
   - PaddingLeft: `0, 5`
   - PaddingRight: `0, 5`

---

### Step 3: Buat Top Saweria Board Panel (Kanan)

**COPY-PASTE LiveDonation!** Cara mudah:

1. Di Explorer, klik kanan **LiveDonation** → **Duplicate**
2. Rename duplicate menjadi **"SaweriaBoard"**
3. Ubah properties **SaweriaBoard (Frame)**:
   - Position: `{1, -440}, {0.5, -250}` (pindah ke kanan)

4. Ubah **Title** di dalam Header:
   - Text: `"Top Saweria Board"`

5. **TAMBAHAN**: Di dalam **Header**, buat **Subtitle**:
   - Insert **TextLabel** baru
   - Rename: `Subtitle`
   - Size: `{1, -20}, {0, 14}`
   - Position: `{0, 10}, {1, -18}`
   - BackgroundTransparency: `1`
   - Text: `"Refreshing in 60 seconds"`
   - TextColor3: `RGB(150, 150, 160)`
   - TextSize: `11`
   - Font: `Gotham`
   - TextXAlignment: `Center`

---

### Step 4: Copy Scripts ke Roblox Studio

1. Buka folder `roblox/StarterPlayer/StarterPlayerScripts/`
2. Copy file-file ini ke **StarterPlayer > StarterPlayerScripts** di Roblox Studio:
   - `SaweriaLiveDonation.luau`
   - `SaweriaTopBoard.luau`

3. Pastikan **WebhookIntegration.luau** di **ServerScriptService** sudah ter-update

---

### Step 5: Test! 🎉

1. **Play** game di Studio
2. Coba trigger donasi dari webhook
3. Pastikan:
   - ✅ Live Donation muncul di panel kiri
   - ✅ Top Saweria Board muncul di panel kanan
   - ✅ Donasi baru muncul dengan animasi
   - ✅ Leaderboard refresh setiap 60 detik

---

## Troubleshooting 🔧

### UI tidak muncul?
- Pastikan **SaweriaBoard** ada di **StarterGui** (bukan PlayerGui)
- Cek nama exact match (case sensitive!)
- Pastikan `ResetOnSpawn = false`

### Script error di Output?
- Cek console Output di Roblox Studio
- Pastikan HttpService enabled: `Game Settings → Security → Allow HTTP Requests = ON`
- Pastikan API URL benar di WebhookIntegration.luau

### Leaderboard kosong?
- Cek apakah ada donasi dengan `matchedUsername` di database
- Test API endpoint: `https://your-url.vercel.app/api/roblox/top-spenders?limit=10`

### Live Donation tidak update?
- Pastikan WebhookIntegration.luau berjalan di ServerScriptService
- Cek RemoteEvent "RealtimeDonation" ada di ReplicatedStorage

---

## Tips 💡

1. **Posisi UI**: Sesuaikan posisi panel sesuai layout game Anda
2. **Warna**: Customize warna gradient dan text sesuai tema game
3. **Ukuran**: Ubah size panel jika terlalu besar/kecil
4. **Max Entries**: Edit `MAX_ENTRIES` di script jika perlu lebih banyak/sedikit

---

## Next Steps 🎯

- [ ] Customize tampilan UI sesuai tema game
- [ ] Tambah sound effects untuk donasi besar
- [ ] Buat special effects untuk top 1 spender
- [ ] Tambah filter/category untuk leaderboard

---

**Need help?** Check `SAWERIA_BOARD_SETUP.md` untuk detail lengkap semua properties!
