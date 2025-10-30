local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TopSpender = ReplicatedStorage:WaitForChild("TopSpender")
local bit32 = bit32


local merchantCode = "bagibagi-0007"
local secretKey = "bagibagi-aK7mQ2zR9tW5yL0pX3Vd"
local endpoint = "/api/partnerintegration/top-donator"
local UPDATE_INTERVAL = 30


local BOARD_WIDTH = 20
local BOARD_HEIGHT = 25
local BOARD_DEPTH = 2
local BOARD_POSITION = Vector3.new(699, 16.5, 256)


local PART_KIRI  = Workspace:WaitForChild("TopSpenderKiri")
local PART_KANAN = Workspace:WaitForChild("TopSpenderKanan")

-- COLOR SCHEME: Purple, White, Black only
local COLOR_PURPLE = Color3.fromRGB(138, 43, 226)  -- Purple utama
local COLOR_PURPLE_DARK = Color3.fromRGB(75, 0, 130)  -- Purple gelap
local COLOR_PURPLE_LIGHT = Color3.fromRGB(186, 85, 211)  -- Purple terang
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)  -- Putih
local COLOR_BLACK = Color3.fromRGB(0, 0, 0)  -- Hitam


local md5 = {}
local function leftrotate(x,c) return bit32.bor(bit32.lshift(x,c), bit32.rshift(x,32-c)) % 2^32 end
local function tohex(num)
	local t = {}
	for i=1,4 do
		table.insert(t,string.format("%02x", bit32.band(num,0xFF)))
		num = bit32.rshift(num,8)
	end
	return table.concat(t)
end
function md5:Hash(msg)
	local msg_len = #msg
	local bit_len = msg_len*8
	msg = msg..string.char(0x80)
	while (#msg % 64) ~= 56 do msg = msg..string.char(0) end
	for i=1,8 do
		msg = msg..string.char(bit32.band(bit_len,0xFF))
		bit_len = bit32.rshift(bit_len,8)
	end

	local a0,b0,c0,d0 = 0x67452301,0xEFCDAB89,0x98BADCFE,0x10325476
	local s = {7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,
		5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
		4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,
		6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21}
	local K = {}
	for i=0,63 do K[i+1] = math.floor(math.abs(math.sin(i+1))*2^32) end

	local function F(x,y,z) return bit32.bor(bit32.band(x,y), bit32.band(bit32.bnot(x),z)) end
	local function G(x,y,z) return bit32.bor(bit32.band(x,z), bit32.band(y,bit32.bnot(z))) end
	local function H(x,y,z) return bit32.bxor(x,y,z) end
	local function I(x,y,z) return bit32.bxor(y,bit32.bor(x,bit32.bnot(z))) end

	for chunk_start=1,#msg,64 do
		local M={}
		for i=0,15 do
			local j = chunk_start+i*4
			M[i+1] = msg:byte(j)+(msg:byte(j+1)*256)+(msg:byte(j+2)*65536)+(msg:byte(j+3)*16777216)
		end
		local A,B,C,D = a0,b0,c0,d0
		for i=1,64 do
			local F_val,g
			if i<=16 then F_val=F(B,C,D); g=i-1
			elseif i<=32 then F_val=G(B,C,D); g=(5*(i-1)+1)%16
			elseif i<=48 then F_val=H(B,C,D); g=(3*(i-1)+5)%16
			else F_val=I(B,C,D); g=(7*(i-1))%16 end
			local temp=D
			D=C
			C=B
			B=(B+leftrotate((A+F_val+K[i]+M[g+1])%2^32, s[i]))%2^32
			A=temp
		end
		a0=(a0+A)%2^32
		b0=(b0+B)%2^32
		c0=(c0+C)%2^32
		d0=(d0+D)%2^32
	end
	return tohex(a0)..tohex(b0)..tohex(c0)..tohex(d0)
end

local function generateToken()
	return md5:Hash(merchantCode..secretKey..endpoint)
end

local function getTopDonators()
	local token = generateToken()
	local url = "https://bagibagi.co"..endpoint.."?merchantCode="..merchantCode.."&token="..token

	print("🔗 Memanggil URL:", url)
	print("🔑 Token yang digunakan:", token)

	local success, response = pcall(function() 
		return HttpService:GetAsync(url) 
	end)

	if success then
		print("✅ Response berhasil diterima:")
		print("📄 Raw Response:", response)

		local parseSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)

		if parseSuccess then
			print("✅ JSON berhasil di-parse:")
			print("📊 Data lengkap:", data)
			print("👥 Jumlah donator:", #(data.data or {}))

			for i, donator in ipairs(data.data or {}) do
				print(string.format("🏆 #%d: %s - Rp.%s", i, donator.userName, donator.amount))
			end

			return data.data or {}
		else
			warn("❌ Gagal parse JSON:", data)
			return {}
		end
	else
		warn("❌ Gagal ambil data:", response)
		print("🔍 Kemungkinan masalah:")
		print("   - Internet connection")
		print("   - URL salah")
		print("   - Token tidak valid")
		print("   - Server API down")
		return {}
	end
end

local function buatDataBoard(topDonators, parentPart)
	if not parentPart then return end

	local targetFace = Enum.NormalId.Front
	local anyDecal = parentPart:FindFirstChildOfClass("Decal")
	if anyDecal and anyDecal.Face then targetFace = anyDecal.Face end

	local surfaceGui = parentPart:FindFirstChild("BoardGui")
	if not surfaceGui then
		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "BoardGui"
		surfaceGui.AlwaysOnTop = false
		surfaceGui.Adornee = parentPart
		surfaceGui.Face = targetFace
		surfaceGui.CanvasSize = Vector2.new(800, 1000)
		surfaceGui.LightInfluence = 1
		surfaceGui.Parent = parentPart

		-- Background Frame - BLACK
		local bgFrame = Instance.new("Frame")
		bgFrame.Name = "Bg"
		bgFrame.Size = UDim2.new(1, 0, 1, 0)
		bgFrame.Position = UDim2.new(0, 0, 0, 0)
		bgFrame.Transparency = 0
		bgFrame.BackgroundColor3 = COLOR_BLACK
		bgFrame.BorderSizePixel = 0
		bgFrame.Parent = surfaceGui

		-- Background Gradient - Black to Dark Purple
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLOR_BLACK),
			ColorSequenceKeypoint.new(0.5, COLOR_PURPLE_DARK),
			ColorSequenceKeypoint.new(1, COLOR_BLACK)
		})
		gradient.Rotation = 45
		gradient.Parent = bgFrame

		-- Animasi rotating gradient
		local gradientInfo = TweenInfo.new(
			10,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut,
			-1,
			false
		)

		local gradientTween = game:GetService("TweenService"):Create(
			gradient,
			gradientInfo,
			{Rotation = 405}
		)
		gradientTween:Play()

		-- Border - PURPLE dengan animasi glow
		local border = Instance.new("UIStroke")
		border.Thickness = 8
		border.Color = COLOR_PURPLE
		border.Transparency = 0.2
		border.Parent = bgFrame

		-- Animasi border glow
		local borderInfo = TweenInfo.new(
			4,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		)

		local borderTween = game:GetService("TweenService"):Create(
			border,
			borderInfo,
			{Transparency = 0.6}
		)
		borderTween:Play()

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 20)
		corner.Parent = bgFrame

		-- Header Section
		local header = Instance.new("Frame")
		header.Name = "Header"
		header.Size = UDim2.new(0.96, 0, 0.12, 0)
		header.Position = UDim2.new(0.02, 0, 0.01, 0)
		header.BackgroundTransparency = 1
		header.Parent = bgFrame

		-- Mini Header
		local MiniHeader = Instance.new("Frame")
		MiniHeader.Name = "bagibagi"
		MiniHeader.Size = UDim2.new(0.96, 0, 0.12, 0)
		MiniHeader.Position = UDim2.new(0.02, 0, 0.85, 0)
		MiniHeader.BackgroundTransparency = 1
		MiniHeader.Parent = bgFrame

		-- Title - PURPLE dengan stroke BLACK
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "BoardTitle"
		titleLabel.Size = UDim2.new(1, 0, 1, 0)
		titleLabel.Position = UDim2.new(0, 0, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "TOP SPENDER YINYANG"
		titleLabel.TextColor3 = COLOR_PURPLE
		titleLabel.TextScaled = true
		titleLabel.TextSize = 14
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextStrokeTransparency = 0
		titleLabel.TextStrokeColor3 = COLOR_BLACK
		titleLabel.TextWrapped = true
		titleLabel.Parent = header

		-- Bagibagi title - WHITE dengan stroke BLACK
		local bagibagiTitle = Instance.new("TextLabel")
		bagibagiTitle.Name = "bagibagiTitle"
		bagibagiTitle.Size = UDim2.new(1, 0, 1, 0)
		bagibagiTitle.Position = UDim2.new(0, 0, 0, 0)
		bagibagiTitle.BackgroundTransparency = 1
		bagibagiTitle.Text = "bagibagi.co/fngstudio"
		bagibagiTitle.TextColor3 = COLOR_WHITE
		bagibagiTitle.TextScaled = true
		bagibagiTitle.TextSize = 14
		bagibagiTitle.Font = Enum.Font.GothamBold
		bagibagiTitle.TextStrokeTransparency = 0
		bagibagiTitle.TextStrokeColor3 = COLOR_BLACK
		bagibagiTitle.TextWrapped = true
		bagibagiTitle.Parent = MiniHeader

		-- Glow effect untuk title - PURPLE LIGHT
		local titleGlow = Instance.new("UIStroke")
		titleGlow.Thickness = 4
		titleGlow.Color = COLOR_PURPLE_LIGHT
		titleGlow.Transparency = 0.3
		titleGlow.Parent = titleLabel

		-- Animasi glow pulsing untuk title
		local titleGlowInfo = TweenInfo.new(
			3,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		)

		local titleGlowTween = game:GetService("TweenService"):Create(
			titleGlow,
			titleGlowInfo,
			{Transparency = 0.8}
		)
		titleGlowTween:Play()

		-- SCROLLING FRAME
		local scrollContainer = Instance.new("ScrollingFrame")
		scrollContainer.Name = "ScrollContainer"
		scrollContainer.Size = UDim2.new(0.96, 0, 0.86, 0)
		scrollContainer.Position = UDim2.new(0.02, 0, 0.14, 0)
		scrollContainer.BackgroundTransparency = 1
		scrollContainer.ScrollBarThickness = 8
		scrollContainer.ScrollBarImageColor3 = COLOR_PURPLE
		scrollContainer.ScrollBarImageTransparency = 0.3
		scrollContainer.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		scrollContainer.ScrollingDirection = Enum.ScrollingDirection.Y
		scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		scrollContainer.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		scrollContainer.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		scrollContainer.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		scrollContainer.ScrollingEnabled = true
		scrollContainer.Parent = bgFrame

		-- List Layout untuk scroll container
		local listLayout = Instance.new("UIListLayout")
		listLayout.Name = "ScrollListLayout"
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 5)
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.Parent = scrollContainer

		-- Auto-update canvas size ketika content berubah
		listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local totalHeight = listLayout.AbsoluteContentSize.Y + 20
			scrollContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
		end)
	end

	-- Update face and adornee
	surfaceGui.Face = targetFace
	surfaceGui.Adornee = parentPart

	-- Get scroll container
	local scrollContainer = surfaceGui:FindFirstChild("ScrollContainer", true)
	if not scrollContainer then
		warn("ScrollContainer tidak ditemukan")
		return
	end

	-- Clear existing entries
	for _, child in ipairs(scrollContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("DonatorEntry") then
			child:Destroy()
		end
	end

	-- Create entries for all donators
	local ENTRY_HEIGHT = 65

	for i = 1, #topDonators do
		local donator = topDonators[i]

		local entryFrame = Instance.new("Frame")
		entryFrame.Name = "DonatorEntry" .. i
		entryFrame.Size = UDim2.new(1, -15, 0, ENTRY_HEIGHT)
		entryFrame.BackgroundTransparency = 1
		entryFrame.LayoutOrder = i
		entryFrame.Parent = scrollContainer

		-- Entry Background - BLACK dengan gradient PURPLE
		local entryBg = Instance.new("Frame")
		entryBg.Size = UDim2.new(1, 0, 1, 0)
		entryBg.Position = UDim2.new(0, 0, 0, 0)
		entryBg.BorderSizePixel = 0
		entryBg.BackgroundColor3 = COLOR_BLACK
		entryBg.Parent = entryFrame

		-- Gradient purple untuk entry
		local entryGradient = Instance.new("UIGradient")
		entryGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLOR_PURPLE_DARK),
			ColorSequenceKeypoint.new(0.5, COLOR_BLACK),
			ColorSequenceKeypoint.new(1, COLOR_PURPLE_DARK)
		})
		entryGradient.Parent = entryBg

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 8)
		entryCorner.Parent = entryBg

		-- Animasi slide-in
		entryFrame.Position = UDim2.new(-1, 0, 0, 0)
		entryFrame.BackgroundTransparency = 1

		local tweenInfo = TweenInfo.new(
			0.8,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out,
			0,
			false,
			i * 0.1
		)

		local slideIn = game:GetService("TweenService"):Create(
			entryFrame,
			tweenInfo,
			{Position = UDim2.new(0, 0, 0, 0)}
		)
		slideIn:Play()

		-- Rank Label - WHITE dengan stroke BLACK
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "RankLabel"
		rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
		rankLabel.Position = UDim2.new(0.02, 0, 0, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = "#" .. i
		rankLabel.TextColor3 = COLOR_WHITE
		rankLabel.TextScaled = true
		rankLabel.TextSize = 14
		rankLabel.Font = Enum.Font.GothamBlack
		rankLabel.TextStrokeTransparency = 0
		rankLabel.TextStrokeColor3 = COLOR_BLACK
		rankLabel.TextWrapped = true
		rankLabel.Parent = entryFrame

		-- Name Label - WHITE dengan stroke BLACK
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(0.38, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.18, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = string.upper(donator.userName)
		nameLabel.TextColor3 = COLOR_WHITE
		nameLabel.TextScaled = true
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.TextWrapped = true
		nameLabel.TextStrokeTransparency = 0
		nameLabel.TextStrokeColor3 = COLOR_BLACK
		nameLabel.Parent = entryFrame

		-- Amount Label - WHITE dengan stroke BLACK
		local amountLabel = Instance.new("TextLabel")
		amountLabel.Name = "AmountLabel"
		amountLabel.Size = UDim2.new(0.38, 0, 1, 0)
		amountLabel.Position = UDim2.new(0.60, 0, 0, 0)
		amountLabel.BackgroundTransparency = 1
		local formattedAmount = "Rp. " .. tostring(donator.amount):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
		amountLabel.Text = formattedAmount
		amountLabel.TextColor3 = COLOR_WHITE
		amountLabel.TextScaled = true
		amountLabel.TextSize = 14
		amountLabel.Font = Enum.Font.GothamBlack
		amountLabel.TextXAlignment = Enum.TextXAlignment.Right
		amountLabel.TextWrapped = true
		amountLabel.TextStrokeTransparency = 0
		amountLabel.TextStrokeColor3 = COLOR_BLACK
		amountLabel.Parent = entryFrame
	end
end


local jumlahSebelumnya = {}

while true do
	local topDonators = getTopDonators()

	buatDataBoard(topDonators, PART_KIRI)
	buatDataBoard(topDonators, PART_KANAN)

	for _, donator in ipairs(topDonators) do
		local userKey = donator.userName
		local amount = donator.amount

		if (not jumlahSebelumnya[userKey]) or amount > jumlahSebelumnya[userKey] then
			local diff = amount - (jumlahSebelumnya[userKey] or 0)
			if diff > 0 then
				TopSpender:FireAllClients({
					userName = donator.userName,
					amount = diff
				})
			end
			jumlahSebelumnya[userKey] = amount
		end
	end

	task.wait(UPDATE_INTERVAL)
end