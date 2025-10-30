-- RealtimeNotification.luau
-- Client script untuk menampilkan notifikasi donasi real-time dari webhook

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Import Utils
local Maid = require(ReplicatedStorage.Utils.Maid)
local PlayerManager = require(ReplicatedStorage.Utils.PlayerManager)

local player = Players.LocalPlayer
local RealtimeDonation = ReplicatedStorage:WaitForChild("RealtimeDonation")

-- Queue untuk notifikasi agar tidak overlap
local notificationQueue = {}
local isShowingNotification = false

-- Maid untuk resource cleanup
local notificationMaid = Maid.new()

-- Sound effects (opsional)
local donationSound = Instance.new("Sound")
donationSound.SoundId = "rbxassetid://8982092797" -- Coin sound
donationSound.Volume = 0.5
donationSound.Parent = SoundService

local function formatAmount(amount)
	local formatted = tostring(amount):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
	return "Rp. " .. formatted
end

local function showRealtimeNotification(donationData)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Buat ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RealtimeDonationNotification"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Main Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 0, 0, 0) -- Start dari 0 untuk animasi
	frame.Position = UDim2.new(0.5, 0, 0.15, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 35, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 25, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 15, 40))
	})
	gradient.Rotation = 45
	gradient.Parent = frame

	-- Corner dan stroke
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(177, 42, 255)
	stroke.Transparency = 0.3
	stroke.Parent = frame

	-- Icon donasi
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0, 15, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://112365870750906" -- BagiBagi logo atau coin icon
	icon.Parent = frame

	-- Title label dengan custom message untuk target player
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -70, 0, 25)
	titleLabel.Position = UDim2.new(0, 65, 0, 8)
	titleLabel.BackgroundTransparency = 1

	-- Custom message jika donasi untuk player tertentu
	if donationData.robloxUsername and donationData.robloxUsername == player.Name then
		titleLabel.Text = "🔥 MENYALA BOSSKU " .. string.upper(player.Name) .. "!"
		titleLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red untuk personal
	else
		titleLabel.Text = "💰 DONASI BARU!"
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold untuk umum
	end

	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.Parent = frame

	-- Donor name
	local donorLabel = Instance.new("TextLabel")
	donorLabel.Size = UDim2.new(1, -70, 0, 20)
	donorLabel.Position = UDim2.new(0, 65, 0, 28)
	donorLabel.BackgroundTransparency = 1
	donorLabel.Text = "Dari: " .. (donationData.donor or "Anonymous")
	donorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	donorLabel.TextSize = 14
	donorLabel.Font = Enum.Font.Gotham
	donorLabel.TextXAlignment = Enum.TextXAlignment.Left
	donorLabel.TextStrokeTransparency = 0.5
	donorLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	donorLabel.Parent = frame

	-- Amount
	local amountLabel = Instance.new("TextLabel")
	amountLabel.Size = UDim2.new(1, -70, 0, 20)
	amountLabel.Position = UDim2.new(0, 65, 0, 48)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = formatAmount(donationData.amount or 0)
	amountLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
	amountLabel.TextSize = 16
	amountLabel.Font = Enum.Font.GothamBold
	amountLabel.TextXAlignment = Enum.TextXAlignment.Left
	amountLabel.TextStrokeTransparency = 0
	amountLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	amountLabel.Parent = frame

	-- Message (jika ada)
	local messageLabel
	if donationData.message and donationData.message ~= "" then
		messageLabel = Instance.new("TextLabel")
		messageLabel.Size = UDim2.new(1, -70, 0, 18)
		messageLabel.Position = UDim2.new(0, 65, 0, 68)
		messageLabel.BackgroundTransparency = 1
		messageLabel.Text = "💬 " .. donationData.message
		messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		messageLabel.TextSize = 12
		messageLabel.Font = Enum.Font.Gotham
		messageLabel.TextXAlignment = Enum.TextXAlignment.Left
		messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
		messageLabel.TextStrokeTransparency = 0.7
		messageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		messageLabel.Parent = frame
	end

	-- Tentukan ukuran frame berdasarkan konten
	local frameHeight = messageLabel and 95 or 75
	local targetSize = UDim2.new(0, 350, 0, frameHeight)

	-- Play sound
	donationSound:Play()

	-- Animasi masuk
	local tweenIn = TweenService:Create(frame, 
		TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
		{Size = targetSize}
	)
	tweenIn:Play()

	-- Glow effect animation dengan Maid management
	local glowTween = TweenService:Create(stroke,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Transparency = 0.8}
	)
	glowTween:Play()

	-- Store tween in maid for cleanup
	notificationMaid["GlowTween_" .. tick()] = glowTween

	-- Wait dan animasi keluar
	tweenIn.Completed:Wait()
	task.wait(10) -- Tampilkan selama 5 detik

	local tweenOut = TweenService:Create(frame,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = UDim2.new(0.5, 0, -0.2, 0),
			Size = UDim2.new(0, 0, 0, 0)
		}
	)
	tweenOut:Play()

	tweenOut.Completed:Wait()
	screenGui:Destroy()
end

local function processNotificationQueue()
	if isShowingNotification or #notificationQueue == 0 then
		return
	end

	isShowingNotification = true
	local nextNotification = table.remove(notificationQueue, 1)

	showRealtimeNotification(nextNotification)

	isShowingNotification = false

	-- Process next in queue
	if #notificationQueue > 0 then
		task.wait(0.5) -- Small delay between notifications
		processNotificationQueue()
	end
end

-- Event handler untuk donasi real-time dengan Maid management
notificationMaid.DonationEvent = RealtimeDonation.OnClientEvent:Connect(function(donationData)
	print("🎉 Client menerima notifikasi donasi:", donationData.donor, donationData.amount)

	-- Tambah ke queue
	table.insert(notificationQueue, donationData)

	-- Process queue
	processNotificationQueue()
end)

-- Character respawn handling dengan PlayerManager
PlayerManager.onCharacterAdded("RealtimeNotification", function(character, playerObj)
	if playerObj == player then
		print("🔄 Character respawned - notification system ready")
		-- Clear queue on respawn to avoid stale notifications
		notificationQueue = {}
		isShowingNotification = false
	end
end)

print("🎮 Realtime donation notification system ready!")
