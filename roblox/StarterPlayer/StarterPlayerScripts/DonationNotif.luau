--[[
═══════════════════════════════════════════════════════════════════════════════
  UNIFIED DONATION NOTIFICATION SYSTEM - Client Display
═══════════════════════════════════════════════════════════════════════════════

SYSTEM: Shared Notification Display (Both Robux & Saweria)
TYPE: LocalScript (StarterPlayerScripts)
CURRENCY: Multi-currency (R$ and Rp.)

PURPOSE:
  - Display beautiful popup notifications for ALL donations
  - Handle notifications from both Robux and Saweria systems
  - Animated popup with avatar, name, amount, message
  - Queue system to prevent overlapping notifications
  - Auto-detect currency type and format correctly

FEATURES:
  - Multi-currency support (R$ comma format, Rp. dot format)
  - Display name format: "DisplayName (@username)"
  - Avatar loading from UserId
  - Sound effects (optional)
  - Dynamic duration based on amount and message length
  - Smooth animations (slide in/out)
  - Queue management for multiple rapid donations

REMOTE EVENTS LISTENED TO:
  - SaweriaDonationSystem/ShowSaweriaDonationNotif (Saweria donations)
  - NewDonationSystem/ShowNewDonationNotif (Robux donations)

DEPENDENCIES:
  Services:
    - Players (avatar loading)
    - TweenService (animations)
    - SoundService (notification sounds)
    - ReplicatedStorage (RemoteEvents)

NOTIFICATION DATA FORMAT:
  {
    donatorName: string        -- Roblox username
    donatorDisplayName: string -- Display name
    donatorId: number         -- UserId for avatar
    amount: number            -- Donation amount
    customMessage: string     -- Message text
    currencyType: string      -- "ROBUX" or "IDR"
  }

DISPLAY DURATION:
  - Base: 5 seconds
  - +1-4 seconds based on amount (larger = longer)
  - +1 second per 15 characters in message

═══════════════════════════════════════════════════════════════════════════════
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for BOTH donation systems (Saweria AND Robux)
-- Saweria system
local saweriaDonationSystem = ReplicatedStorage:WaitForChild("SaweriaDonationSystem", 5)
local showSaweriaDonationNotif = saweriaDonationSystem and saweriaDonationSystem:WaitForChild("ShowSaweriaDonationNotif", 5)

-- Robux system (separate)
local robuxDonationSystem = ReplicatedStorage:WaitForChild("NewDonationSystem", 5)
local showRobuxDonationNotif = robuxDonationSystem and robuxDonationSystem:WaitForChild("ShowNewDonationNotif", 5)

-- Notification queue and state
local notificationQueue = {}
local isShowingNotification = false

-- Helper functions from reference
local function pickSound()
	local donors = workspace:FindFirstChild("Donors")
	if not donors then return nil end
	local sounds = donors:FindFirstChild("Sounds")
	if not sounds then return nil end
	local preferred = sounds:FindFirstChild("Donation")
	if preferred and preferred:IsA("Sound") then return preferred end
	for _, ch in ipairs(sounds:GetChildren()) do
		if ch:IsA("Sound") then return ch end
	end
	return nil
end

local function playSfx()
	local src = pickSound()
	if not src then return end
	local s = src:Clone()
	s.Parent = SoundService
	s:Play()
	game:GetService("Debris"):AddItem(s, (s.TimeLength > 0 and s.TimeLength or 4) + 1)
end

local function fmt(n: number?): string
	local v = tonumber(n or 0) or 0
	local s = tostring(math.floor(v))
	
	-- Reverse string untuk mudah insert separator
	local reversed = s:reverse()
	local result = ""
	local count = 0
	
	for i = 1, #reversed do
		if count > 0 and count % 3 == 0 then
			result = "." .. result  -- Pakai titik sebagai separator
		end
		result = reversed:sub(i, i) .. result
		count = count + 1
	end
	
	return result
end

local function computeTarget(vp: Vector2)
	local isNarrow = vp.X < 900
	local wPct = isNarrow and 0.9 or 0.6
	local w = math.clamp(math.floor(vp.X * wPct), 360, 820)
	local h = math.clamp(math.floor(vp.Y * 0.17), 130, 210)
	local posY = isNarrow and 0.08 or 0.1
	return w, h, posY
end

local function sizeText(label: TextLabel, minSize: number, maxSize: number)
	label.TextScaled = true
	local c = Instance.new("UITextSizeConstraint")
	c.MinTextSize = minSize
	c.MaxTextSize = maxSize
	c.Parent = label
end

local function setAvatar(img: ImageLabel, userId: number?)
	if not userId then 
		print("[AVATAR] No userId provided")
		return 
	end

	print(`[AVATAR] Attempting to load avatar for userId: {userId}`)

	local ok, url, ready = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
	if ok and url then
		print(`[AVATAR] Successfully got avatar URL: {url}`)
		img.Image = url
		if not ready then
			print("[AVATAR] Image not ready, retrying in 0.25 seconds...")
			task.delay(0.25, function()
				local ok2, url2, ready2 = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
				if ok2 and url2 then 
					print(`[AVATAR] Retry successful: {url2}`)
					img.Image = url2 
				else
					print("[AVATAR] Retry failed")
				end
			end)
		end
	else
		print(`[AVATAR] Failed to get avatar: {url}`)
		-- Set a default avatar or placeholder
		img.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

-- Create notification matching reference design
local function makeGui(payload)
	local gui = Instance.new("ScreenGui")
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.Name = "DonationPopup"
	gui.Parent = playerGui

	local root = Instance.new("Frame")
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.BackgroundColor3 = Color3.fromRGB(24, 7, 3)
	root.BackgroundTransparency = 0.15
	root.ClipsDescendants = true
	root.Parent = gui

	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 16); corner.Parent = root
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Transparency = 0.2; stroke.Color = Color3.fromRGB(255, 128, 38); stroke.Parent = root

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 18)
	pad.PaddingRight = UDim.new(0, 18)
	pad.Parent = root

	-- container isi
	local content = Instance.new("Frame")
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.Parent = root

	-- avatar kiri
	local avatarWrap = Instance.new("Frame")
	avatarWrap.Name = "AvatarWrap"
	avatarWrap.AnchorPoint = Vector2.new(0, 0.5)
	avatarWrap.BackgroundTransparency = 1
	avatarWrap.Position = UDim2.new(0, 0, 0.5, 0)
	avatarWrap.Size = UDim2.fromOffset(112, 112)
	avatarWrap.Parent = content

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.BackgroundTransparency = 1
	avatar.Size = UDim2.fromScale(1, 1)
	avatar.Parent = avatarWrap
	local avCorner = Instance.new("UICorner"); avCorner.CornerRadius = UDim.new(1, 0); avCorner.Parent = avatar

	-- panel kanan untuk teks
	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.Position = UDim2.new(0, 112 + 14, 0, 0)
	right.Size = UDim2.new(1, -(112 + 14), 1, 0)
	right.Parent = content

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Name = "Title"
	title.Text = "Booooom Menyala"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Size = UDim2.new(1, 0, 0.34, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.Parent = right
	sizeText(title, 18, 42)

	local row1 = Instance.new("TextLabel")
	row1.BackgroundTransparency = 1
	row1.Name = "DonationName"
	row1.TextXAlignment = Enum.TextXAlignment.Left
	row1.Font = Enum.Font.Michroma
	row1.TextColor3 = Color3.fromRGB(230,230,255)
	row1.Size = UDim2.new(1, 0, 0.22, 0)
	row1.Position = UDim2.new(0, 0, 0.34, 0)
	row1.Text = string.format("%s (@%s)", tostring(payload.donatorDisplayName or ""), tostring(payload.donatorName or ""))
	row1.Parent = right
	sizeText(row1, 16, 36)

	local row2 = Instance.new("TextLabel")
	row2.BackgroundTransparency = 1
	row2.Name = "DonationAmount"
	row2.TextXAlignment = Enum.TextXAlignment.Left
	row2.Font = Enum.Font.GothamBold
	row2.TextColor3 = Color3.fromRGB(255, 144, 32)
	row2.Size = UDim2.new(1, 0, 0.22, 0)
	row2.Position = UDim2.new(0, 0, 0.56, 0)
	-- 🆕 Multi-currency support
	local currencySymbol = "R$ " -- Default: Robux
	if payload.currencyType == "IDR" then
		currencySymbol = "Rp. " -- Rupiah untuk Saweria/BagiBagi
	end
	row2.Text = ("Donation: "..currencySymbol..fmt(payload.amount))
	row2.Parent = right
	sizeText(row2, 16, 36)

	local row3 = Instance.new("TextLabel")
	row3.BackgroundTransparency = 1
	row3.Name = "DonationMessage"
	row3.TextXAlignment = Enum.TextXAlignment.Left
	row3.Font = Enum.Font.GothamBold
	row3.TextColor3 = Color3.fromRGB(255, 138, 21)
	row3.Size = UDim2.new(1, 0, 0.22, 0)
	row3.Position = UDim2.new(0, 0, 0.78, 0)
	row3.Text = ("Message: "..(payload.customMessage or "No message"))
	row3.Parent = right
	sizeText(row3, 16, 36)

	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1440, 900)
	local targetW, targetH, posY = computeTarget(vp)
	root.Position = UDim2.new(0.5, 0, posY, 0)

	local function layout()
		local h = root.AbsoluteSize.Y
		local size = math.clamp(math.floor(h - 28), 84, 140)
		avatarWrap.Size = UDim2.fromOffset(size, size)
		right.Position = UDim2.new(0, size + 14, 0, 0)
		right.Size = UDim2.new(1, -(size + 14), 1, 0)
	end

	local function applyLayout(vpv: Vector2)
		local w, h, py = computeTarget(vpv)
		root.Position = UDim2.new(0.5, 0, py, 0)
		root.Size = UDim2.fromOffset(w, h)
		task.defer(layout)
	end

	applyLayout(vp)

	local connCam
	if cam then
		connCam = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if root.Parent then
				applyLayout(cam.ViewportSize)
			end
		end)
	end
	local connAbs = root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)

	local openW, openH = targetW, targetH
	root.Size = UDim2.fromOffset(openW, 0)
	root.BackgroundTransparency = 1
	stroke.Transparency = 1

	local tweenIn1 = TweenService:Create(root, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(openW, openH), BackgroundTransparency = 0.15})
	local tweenIn2 = TweenService:Create(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.2})
	tweenIn1:Play(); tweenIn2:Play()

	-- load avatar headshot (use donatorId if available)
	if payload.donatorId then
		setAvatar(avatar, tonumber(payload.donatorId))
	end

	playSfx()

	-- Calculate display duration based on donation amount and message
	local baseDuration = 5 -- Base 5 seconds (increased from 3)
	local extraDuration = 0

	-- Extra time based on amount
	if payload.amount >= 10000 then
		extraDuration = extraDuration + 4
	elseif payload.amount >= 5000 then
		extraDuration = extraDuration + 3
	elseif payload.amount >= 2000 then
		extraDuration = extraDuration + 2
	elseif payload.amount >= 1000 then
		extraDuration = extraDuration + 1
	end

	-- Extra time based on message length
	if payload.customMessage and payload.customMessage ~= "" then
		local messageLength = string.len(payload.customMessage)
		extraDuration = extraDuration + math.ceil(messageLength / 15) -- Reading speed
	end

	local totalDuration = baseDuration + extraDuration
	print(`[DONATION NOTIF] Showing for {totalDuration} seconds`)

	task.wait(totalDuration)

	local tweenOut1 = TweenService:Create(root, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromOffset(openW, 0), BackgroundTransparency = 1})
	local tweenOut2 = TweenService:Create(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1})
	tweenOut1:Play(); tweenOut2:Play()
	tweenOut1.Completed:Wait()

	if connCam then connCam:Disconnect() end
	if connAbs then connAbs:Disconnect() end
	gui:Destroy()
end

local function pump()
	if isShowingNotification then return end
	isShowingNotification = true
	while #notificationQueue > 0 do
		print("test isi dari notification queue", notificationQueue)
		makeGui(table.remove(notificationQueue, 1))
	end
	isShowingNotification = false
end

-- Helper function to process notification (shared by both systems)
local function processNotification(donationData, source)
	print(`🔔 [NOTIF CLIENT] ========== RECEIVED {source} DONATION ==========`)
	print("🔔 [NOTIF CLIENT] Raw data received!")
	
	-- Auto-detect currency if not specified
	if not donationData.currencyType then
		donationData.currencyType = "ROBUX"  -- Default for Robux system
	end
	
	local currencyLabel = "Robux" -- Default
	if donationData.currencyType == "IDR" then
		currencyLabel = "Rupiah"
	end
	
	print(`[DONATION NOTIF] Received: {donationData.donatorName} - {donationData.amount} {currencyLabel} - "{donationData.customMessage}"`)
	print(`[DONATION NOTIF] DonatorId: {donationData.donatorId}`)
	print(`[DONATION NOTIF] Currency: {donationData.currencyType}`)
	print("[DONATION NOTIF] Source:", source)
	
	print("🔔 [NOTIF CLIENT] Adding to queue...")
	table.insert(notificationQueue, donationData or {})
	print("🔔 [NOTIF CLIENT] Queue size:", #notificationQueue)
	
	print("🔔 [NOTIF CLIENT] Calling pump()...")
	pump()
	print("🔔 [NOTIF CLIENT] ========== END ==========")
end

-- Listen for SAWERIA donation notifications
if showSaweriaDonationNotif then
	print("🔔 [NOTIF CLIENT] Setting up Saweria listener...")
	showSaweriaDonationNotif.OnClientEvent:Connect(function(donationData)
		processNotification(donationData, "SAWERIA")
	end)
	print("🔔 [NOTIF CLIENT] ✅ Saweria listener ready!")
else
	warn("⚠️ [NOTIF CLIENT] Saweria donation system not found!")
end

-- Listen for ROBUX donation notifications
if showRobuxDonationNotif then
	print("🔔 [NOTIF CLIENT] Setting up Robux listener...")
	showRobuxDonationNotif.OnClientEvent:Connect(function(donationData)
		processNotification(donationData, "ROBUX")
	end)
	print("🔔 [NOTIF CLIENT] ✅ Robux listener ready!")
else
	warn("⚠️ [NOTIF CLIENT] Robux donation system not found!")
end

print("🔔 [NOTIF CLIENT] All listeners setup complete!")

print("[NEW DONATION NOTIFICATIONS] Loaded successfully! Ready to display beautiful notifications.")