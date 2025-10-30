-- SaweriaLiveDonation.luau
-- Client script untuk menampilkan live donation feed di Saweria board

--[[
═══════════════════════════════════════════════════════════════════════════════
  SAWERIA LIVE DONATION FEED - Client Display
═══════════════════════════════════════════════════════════════════════════════

SYSTEM: Saweria Live Feed
TYPE: LocalScript (StarterPlayerScripts)
CURRENCY: Rupiah (Rp.)

PURPOSE:
  - Display live donation feed in real-time for Saweria donations
  - Show recent donations with animations
  - Format: "DisplayName (username) - Rp. X.XXX"
  - Avatar display for matched Roblox users
  - Auto-cleanup when server empty

FEATURES:
  - Real-time updates via RealtimeDonation RemoteEvent
  - Display name support (fetches from Roblox API)
  - Avatar thumbnails for matched users
  - Smooth entry animations
  - Max 50 entries with auto-cleanup
  - Persists while players in server
  - Amount formatting with dot separator (5.000)

REMOTE EVENTS LISTENED TO:
  - SaweriaRealtimeDonation (Server → Client)
      Data: { donor, amount, message, robloxUsername, timestamp }

DEPENDENCIES:
  Services:
    - Players (display names, avatars)
    - TweenService (animations)
    - ReplicatedStorage (RemoteEvents)
  
  UI Elements:
    - workspace.SaweriaBoard.SaweriaBoard (SurfaceGui)
    - Live Donation board panel

CONFIGURATION:
  - MAX_ENTRIES: 50 donations
  - Display name format: "PuffXDom (moonzet16)"
  - Amount format: "Rp. 5.000" (dot separator)

═══════════════════════════════════════════════════════════════════════════════
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for UI in Workspace (SurfaceGui)
local saweriaBoard = workspace:WaitForChild("SaweriaBoard", 10)
if not saweriaBoard then
	warn("❌ SaweriaBoard tidak ditemukan di Workspace!")
	return
end

local liveDonation = saweriaBoard:WaitForChild("LiveDonation", 5)
if not liveDonation then
	warn("❌ LiveDonation Frame tidak ditemukan!")
	return
end

local board = liveDonation:WaitForChild("Board")
local container = board:WaitForChild("Container")
local canvas = container:WaitForChild("Canvas")
local body = canvas:WaitForChild("Body")
local content = body:WaitForChild("Content")

print("[DEBUG SAWERIA LIVE] UI Structure found:")
print("  - Content:", content.Name, "| Class:", content.ClassName)
print("  - Content Size:", content.Size)
print("  - Content AbsoluteSize:", content.AbsoluteSize)

-- Wait for RemoteEvent
local SaweriaRealtimeDonation = ReplicatedStorage:WaitForChild("SaweriaRealtimeDonation")

-- Settings
local MAX_ENTRIES = 50
local ANIMATION_DURATION = 0.5

-- Utilities
local function formatAmount(amount)
	local num = tonumber(amount) or 0
	local formatted = tostring(math.floor(num))

	-- Add thousand separators (titik)
	local result = ""
	local count = 0

	-- Reverse iterate untuk add separator setiap 3 digit
	for i = #formatted, 1, -1 do
		if count > 0 and count % 3 == 0 then
			result = "." .. result
		end
		result = formatted:sub(i, i) .. result
		count = count + 1
	end

	return "Rp. " .. result
end

-- Get display name for a username (with error handling)
local function getDisplayName(username)
	if not username or username == "" then
		return username or "Unknown"
	end

	-- Method 1: Check if player is currently in-game (fastest!)
	local player = Players:FindFirstChild(username)
	if player then
		print("[SAWERIA LIVE] Found player online, display name:", player.DisplayName)
		return player.DisplayName
	end

	-- Method 2: Fetch via API if player not online
	local success, result = pcall(function()
		local userId = Players:GetUserIdFromNameAsync(username)

		-- Use HumanoidDescription to get display name
		local humanoidDesc = Players:GetHumanoidDescriptionFromUserId(userId)
		return humanoidDesc.DisplayName or username
	end)

	if success and result and result ~= "" then
		print("[SAWERIA LIVE] Fetched display name from API:", result)
		return result
	else
		warn("⚠️ [SAWERIA LIVE] Failed to get display name for:", username, "Error:", result)
		return username -- Fallback to username
	end
end

-- Format display: "DisplayName (Username)" or just "Username" if same
local function formatPlayerName(username)
	if not username or username == "" then
		return "Anonymous"
	end

	-- Validate username first
	local isValid = pcall(function()
		Players:GetUserIdFromNameAsync(username)
	end)

	if not isValid then
		-- Invalid username - just show it as-is
		warn("⚠️ [SAWERIA LIVE] Invalid username:", username)
		return username
	end

	local displayName = getDisplayName(username)

	-- If display name same as username, just show username
	if displayName:lower() == username:lower() then
		return username
	else
		-- Show: DisplayName (Username)
		return string.format("%s (%s)", displayName, username)
	end
end

local function getAvatarUrl(userId)
	if not userId then return nil end

	local success, result = pcall(function()
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size150x150
		local url, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
		return url
	end)

	if success then
		return result
	else
		return "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

-- Create entry UI
local function createEntry(donationData, index)
	-- Wrapper CanvasGroup untuk GroupTransparency support
	local wrapper = Instance.new("CanvasGroup")
	wrapper.Name = "Entry_" .. (donationData.timestamp or tick())
	wrapper.Size = UDim2.new(1, 0, 0, 130)
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel = 0
	wrapper.LayoutOrder = index or 0

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4.3
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0
	stroke.Parent = wrapper

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 33, 237)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(43, 234, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 255, 131))
	})
	gradient.Rotation = 0
	gradient.Parent = stroke

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = wrapper

	local entry = Instance.new("Frame")
	entry.Name = "Content"
	entry.Size = UDim2.new(1, 0, 1, 0)
	entry.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	entry.BorderSizePixel = 0
	entry.ClipsDescendants = true
	entry.Parent = wrapper

	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = entry

	-- Gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 55)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 45))
	})
	gradient.Rotation = 135
	gradient.Parent = entry

	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 18)
	padding.PaddingBottom = UDim.new(0, 18)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = entry

	-- Avatar
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, 85, 0, 85)
	avatar.Position = UDim2.new(0, 0, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	avatar.Parent = entry

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar

	-- Try to load actual avatar
	if donationData.robloxUsername then
		task.spawn(function()
			local userId = Players:GetUserIdFromNameAsync(donationData.robloxUsername)
			if userId then
				local url = getAvatarUrl(userId)
				if url then
					avatar.Image = url
				end
			end
		end)
	end

	-- Content Frame (for text)
	local textContent = Instance.new("Frame")
	textContent.Name = "TextContent"
	textContent.Size = UDim2.new(1, -100, 1, 0)
	textContent.Position = UDim2.new(0, 100, 0, 0)
	textContent.BackgroundTransparency = 1
	textContent.Parent = entry

	-- Donor Name
	local donorName = Instance.new("TextLabel")
	donorName.Name = "DonorName"
	donorName.Size = UDim2.new(1, 0, 0, 28)
	donorName.Position = UDim2.new(0, 0, 0, 8)
	donorName.BackgroundTransparency = 1
	-- Show matched Roblox username dengan display name, or fallback to donor name
	local displayText = donationData.donor or "Anonymous"
	if donationData.robloxUsername then
		displayText = donationData.robloxUsername -- Temporary, will update async
	end
	donorName.Text = displayText
	donorName.TextColor3 = Color3.fromRGB(255, 255, 255)
	donorName.TextSize = 35
	donorName.Font = Enum.Font.GothamBold
	donorName.TextXAlignment = Enum.TextXAlignment.Left
	donorName.TextTruncate = Enum.TextTruncate.AtEnd
	donorName.Parent = textContent

	-- Update dengan display name format asynchronously (if Roblox username matched)
	if donationData.robloxUsername then
		task.spawn(function()
			print("[SAWERIA LIVE] Formatting name for:", donationData.robloxUsername)
			local formattedName = formatPlayerName(donationData.robloxUsername)
			print("[SAWERIA LIVE] Formatted result:", formattedName)
			donorName.Text = formattedName
		end)
	else
		print("[SAWERIA LIVE] No robloxUsername, showing donor name:", donationData.donor)
	end

	-- Amount
	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Size = UDim2.new(1, 0, 0, 32)
	amount.Position = UDim2.new(0, 0, 0, 40)
	amount.BackgroundTransparency = 1
	amount.Text = formatAmount(donationData.amount or 0)
	amount.TextColor3 = Color3.fromRGB(255, 215, 0)
	amount.TextSize = 35
	amount.Font = Enum.Font.GothamBold
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.Parent = textContent

	-- Message or Target
	local messageText = ""
	if donationData.message and donationData.message ~= "" then
		messageText = donationData.message
	elseif donationData.robloxUsername then
		messageText = "🎮 untuk " .. donationData.robloxUsername
	end

	if messageText ~= "" then
		local message = Instance.new("TextLabel")
		message.Name = "Message"
		message.Size = UDim2.new(1, 0, 0, 22)
		message.Position = UDim2.new(0, 0, 0, 76)
		message.BackgroundTransparency = 1
		message.Text = messageText
		message.TextColor3 = Color3.fromRGB(180, 180, 200)
		message.TextSize = 35
		message.Font = Enum.Font.Gotham
		message.TextXAlignment = Enum.TextXAlignment.Left
		message.TextTruncate = Enum.TextTruncate.AtEnd
		message.FontFace.Bold = true
		message.FontFace.Style = Enum.FontStyle.Italic
		message.Parent = textContent
	end

	-- Timestamp indicator (small dot animation)
	local timeIndicator = Instance.new("Frame")
	timeIndicator.Name = "TimeIndicator"
	timeIndicator.Size = UDim2.new(0, 8, 0, 8)
	timeIndicator.Position = UDim2.new(1, -8, 0, 8)
	timeIndicator.AnchorPoint = Vector2.new(1, 0)
	timeIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
	timeIndicator.BorderSizePixel = 0
	timeIndicator.Parent = entry

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = timeIndicator

	-- Pulse animation for new entries
	local pulseTween = TweenService:Create(timeIndicator,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{BackgroundColor3 = Color3.fromRGB(0, 200, 100)}
	)
	pulseTween:Play()

	-- Set initial state (important for SurfaceGui visibility)
	wrapper.Position = UDim2.new(0, 0, 0, 0)
	wrapper.GroupTransparency = 0
	wrapper.Visible = true

	-- Store creation time
	wrapper:SetAttribute("CreationTime", os.time())

	print(string.format("[DEBUG SAWERIA LIVE] Created entry for: %s - %s", donationData.donor or "Unknown", formatAmount(donationData.amount)))

	return wrapper
end

-- Add donation to feed
local function addDonation(donationData)
	-- Create new entry with highest priority (LayoutOrder = 0 for newest on top)
	local entry = createEntry(donationData, -os.time())
	entry.Parent = content

	-- Clean up old entries if exceeds max
	local entries = content:GetChildren()
	local entryCount = 0
	for _, child in ipairs(entries) do
		if child:IsA("CanvasGroup") and child.Name:match("^Entry_") then
			entryCount = entryCount + 1
		end
	end

	if entryCount > MAX_ENTRIES then
		-- Remove oldest entry
		local oldestEntry = nil
		local oldestTime = math.huge

		for _, child in ipairs(entries) do
			if child:IsA("CanvasGroup") and child.Name:match("^Entry_") then
				local creationTime = child:GetAttribute("CreationTime") or 0
				if creationTime < oldestTime then
					oldestTime = creationTime
					oldestEntry = child
				end
			end
		end

		if oldestEntry then
			-- Fade out animation
			local fadeOut = TweenService:Create(oldestEntry,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{GroupTransparency = 1}
			)
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				oldestEntry:Destroy()
			end)
		end
	end

	local playerCount = #Players:GetPlayers()
	print("✅ Saweria donation added to live feed:", donationData.donor, formatAmount(donationData.amount))
	print(string.format("   Total entries: %d/%d | Players in server: %d", entryCount, MAX_ENTRIES, playerCount))
end

-- Auto cleanup - ONLY when server is empty (no players)
task.spawn(function()
	while true do
		task.wait(5) -- Check every 5 seconds

		local playerCount = #Players:GetPlayers()

		-- Only clear entries if NO players in server
		if playerCount == 0 then
			local entries = content:GetChildren()
			local hasEntries = false

			for _, child in ipairs(entries) do
				if child:IsA("CanvasGroup") and child.Name:match("^Entry_") then
					hasEntries = true
					break
				end
			end

			if hasEntries then
				print("🧹 Server empty (0 players), clearing Saweria live donation entries...")

				for _, child in ipairs(entries) do
					if child:IsA("CanvasGroup") and child.Name:match("^Entry_") then
						-- Fade out entry
						local fadeOut = TweenService:Create(child,
							TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
							{GroupTransparency = 1}
						)
						fadeOut:Play()
						fadeOut.Completed:Connect(function()
							child:Destroy()
						end)
					end
				end
			end
		else
			-- Players in server - keep all entries
			-- No auto-deletion based on time!
		end
	end
end)

-- Listen for new donations
SaweriaRealtimeDonation.OnClientEvent:Connect(function(donationData)
	print("🎉 Saweria Live Donation received:", donationData.donor, donationData.amount)
	addDonation(donationData)
end)

print("✅ Saweria Live Donation system ready!")
