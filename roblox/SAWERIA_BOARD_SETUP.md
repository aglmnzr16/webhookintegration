# Saweria Board UI Setup Guide

## Overview
Panduan untuk membuat UI Saweria Board di Roblox Studio yang terdiri dari:
1. **Live Donation** - Menampilkan donasi yang masuk secara real-time
2. **Top Saweria Board** - Leaderboard top spender

## Struktur UI yang Harus Dibuat di StarterGui

### Lokasi: StarterGui > SaweriaBoard

```
StarterGui
└── SaweriaBoard (ScreenGui)
    ├── LiveDonation (Frame)
    │   └── Board (Frame)
    │       └── Container (Frame)
    │           ├── UIGradient
    │           ├── UICorner
    │           ├── UIStroke
    │           ├── Canvas (Frame)
    │           │   └── UIListLayout
    │           ├── Body (Frame)
    │           │   ├── Content (ScrollingFrame)
    │           │   │   ├── UIListLayout
    │           │   │   └── UIPadding
    │           │   └── UIPadding
    │           └── Header (Frame)
    │               ├── Title (TextLabel)
    │               └── Subtitle (TextLabel)
    │
    └── SaweriaBoard (Frame)
        └── Board (Frame)
            └── Container (Frame)
                ├── UIGradient
                ├── UICorner
                ├── UIStroke
                ├── Canvas (Frame)
                │   └── UIListLayout
                ├── Body (Frame)
                │   ├── Content (ScrollingFrame)
                │   │   ├── UIListLayout
                │   │   └── UIPadding
                │   └── UIPadding
                └── Header (Frame)
                    ├── Title (TextLabel)
                    └── Subtitle (TextLabel)
```

---

## Detail Properti UI

### 1. SaweriaBoard (ScreenGui)
```
Name: SaweriaBoard
ResetOnSpawn: false
IgnoreGuiInset: true
DisplayOrder: 5
```

---

### 2. LiveDonation (Frame) - Panel Kiri
```
Name: LiveDonation
Size: UDim2.new(0, 420, 0, 500)
Position: UDim2.new(0, 20, 0.5, -250)
AnchorPoint: Vector2.new(0, 0.5)
BackgroundTransparency: 1
```

#### LiveDonation > Board (Frame)
```
Name: Board
Size: UDim2.fromScale(1, 1)
Position: UDim2.fromScale(0, 0)
BackgroundTransparency: 1
```

#### LiveDonation > Board > Container (Frame)
```
Name: Container
Size: UDim2.fromScale(1, 1)
Position: UDim2.fromScale(0, 0)
BackgroundColor3: Color3.fromRGB(30, 30, 35)
BorderSizePixel: 0
```

**UIGradient**:
```
Color: ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 30))
})
Rotation: 90
```

**UICorner**:
```
CornerRadius: UDim.new(0, 12)
```

**UIStroke**:
```
Thickness: 2
Color: Color3.fromRGB(80, 80, 90)
Transparency: 0.5
```

#### LiveDonation > Board > Container > Header (Frame)
```
Name: Header
Size: UDim2.new(1, 0, 0, 50)
Position: UDim2.new(0, 0, 0, 0)
BackgroundColor3: Color3.fromRGB(35, 35, 40)
BorderSizePixel: 0
```

**UICorner**:
```
CornerRadius: UDim.new(0, 12)
```

**Title (TextLabel)**:
```
Name: Title
Size: UDim2.new(1, -20, 1, 0)
Position: UDim2.new(0, 10, 0, 0)
BackgroundTransparency: 1
Text: "Live Donation"
TextColor3: Color3.fromRGB(255, 255, 255)
TextSize: 20
Font: Enum.Font.GothamBold
TextXAlignment: Enum.TextXAlignment.Center
TextYAlignment: Enum.TextYAlignment.Center
```

#### LiveDonation > Board > Container > Body (Frame)
```
Name: Body
Size: UDim2.new(1, 0, 1, -50)
Position: UDim2.new(0, 0, 0, 50)
BackgroundTransparency: 1
```

**UIPadding**:
```
PaddingTop: UDim.new(0, 10)
PaddingBottom: UDim.new(0, 10)
PaddingLeft: UDim.new(0, 10)
PaddingRight: UDim.new(0, 10)
```

**Content (ScrollingFrame)**:
```
Name: Content
Size: UDim2.fromScale(1, 1)
Position: UDim2.fromScale(0, 0)
BackgroundTransparency: 1
ScrollBarThickness: 6
ScrollBarImageColor3: Color3.fromRGB(100, 100, 110)
BorderSizePixel: 0
CanvasSize: UDim2.new(0, 0, 0, 0)
AutomaticCanvasSize: Enum.AutomaticSize.Y
```

**Content > UIListLayout**:
```
Padding: UDim.new(0, 8)
SortOrder: Enum.SortOrder.LayoutOrder
```

**Content > UIPadding**:
```
PaddingTop: UDim.new(0, 5)
PaddingBottom: UDim.new(0, 5)
PaddingLeft: UDim.new(0, 5)
PaddingRight: UDim.new(0, 5)
```

---

### 3. SaweriaBoard (Frame) - Panel Kanan (Top Spender)
```
Name: SaweriaBoard
Size: UDim2.new(0, 420, 0, 500)
Position: UDim2.new(1, -440, 0.5, -250)
AnchorPoint: Vector2.new(0, 0.5)
BackgroundTransparency: 1
```

Struktur di dalam **SaweriaBoard** sama dengan **LiveDonation**, KECUALI:

#### Header > Title (TextLabel)
```
Text: "Top Saweria Board"
```

#### Header > Subtitle (TextLabel) - TAMBAHAN UNTUK TOP BOARD
```
Name: Subtitle
Size: UDim2.new(1, -20, 0, 14)
Position: UDim2.new(0, 10, 1, -18)
BackgroundTransparency: 1
Text: "Refreshing in 60 seconds"
TextColor3: Color3.fromRGB(150, 150, 160)
TextSize: 11
Font: Enum.Font.Gotham
TextXAlignment: Enum.TextXAlignment.Center
TextYAlignment: Enum.TextYAlignment.Center
```

---

## Template untuk Entry Items

### Live Donation Entry (akan dibuat oleh script)
```lua
-- Structure akan dibuat oleh SaweriaLiveDonation.luau
-- Setiap entry akan memiliki:
-- - Avatar (ImageLabel circular)
-- - Donor name (TextLabel)
-- - Amount (TextLabel dengan warna gold)
-- - Message (TextLabel, opsional)
-- - Timestamp/animation effects
```

### Top Spender Entry (akan dibuat oleh script)
```lua
-- Structure akan dibuat oleh SaweriaTopBoard.luau
-- Setiap entry akan memiliki:
-- - Rank number dengan warna khusus untuk top 3
-- - Avatar (ImageLabel circular)
-- - Username (TextLabel)
-- - Total amount (TextLabel dengan format currency)
-- - Background dengan gradient untuk top 3
```

---

## Catatan Penting

1. **Pastikan nama exact match** - Script akan mencari UI berdasarkan nama yang exact
2. **ScreenGui harus di StarterGui** - Bukan PlayerGui
3. **ResetOnSpawn = false** - Agar UI tidak hilang saat respawn
4. **Content ScrollingFrame** - AutomaticCanvasSize harus Enum.AutomaticSize.Y
5. **UIListLayout** - Penting untuk auto-arrange entries

---

## Testing

Setelah membuat UI di Studio:
1. Test dengan script yang sudah disediakan
2. Pastikan LiveDonation muncul di kiri, SaweriaBoard di kanan
3. Cek scrolling berfungsi jika banyak entries
4. Verifikasi animasi smooth saat donasi baru masuk

---

## Scripts yang Dibutuhkan

Setelah UI selesai dibuat, jalankan script berikut:
1. `SaweriaLiveDonation.luau` - Client script di StarterPlayerScripts
2. `SaweriaTopBoard.luau` - Client script di StarterPlayerScripts
3. Update `WebhookIntegration.luau` - Server script untuk leaderboard data
