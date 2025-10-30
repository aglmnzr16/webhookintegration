--[[
═══════════════════════════════════════════════════════════════════════════════
  SAWERIA TOP SPENDERS BOARD - Client Display
═══════════════════════════════════════════════════════════════════════════════

SYSTEM: Saweria Top Spenders Leaderboard
TYPE: LocalScript (StarterPlayerScripts)
CURRENCY: Rupiah (Rp.)

PURPOSE:
  - Display top 10 donors leaderboard for Saweria
  - Show total donation amounts
  - Rank indicators (🥇🥈🥉)
  - Display name format with username
  - Auto-refresh every 30 seconds

FEATURES:
  - Fetches from server cache (API + DataStore merge)
  - Display name format: "PuffXDom (moonzet16)"
  - Avatar thumbnails
  - Rank-based colors (Gold/Silver/Bronze)
  - Amount formatting: "Rp. 5.000" (dot separator)
  - Force refresh command: /refreshboard

REMOTE FUNCTIONS USED:
  - GetTopSpenders (Client → Server)
      Returns: Array of { username, totalAmount }

DEPENDENCIES:
  Services:
    - Players (display names, avatars)
    - TweenService (animations)
    - ReplicatedStorage (RemoteFunction)
  
  UI Elements:
    - workspace.SaweriaBoard.SaweriaBoard (SurfaceGui)
    - Top Board panel

CONFIGURATION:
  - REFRESH_INTERVAL: 30 seconds
  - TOP_COUNT: 10 donors
  - Cache on server: 30 seconds

═══════════════════════════════════════════════════════════════════════════════
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- Wait for UI in Workspace (SurfaceGui)
local saweriaBoard = workspace:WaitForChild("SaweriaBoard", 10)
if not saweriaBoard then
	warn("❌ SaweriaBoard tidak ditemukan di Workspace!")
	return
end

local topBoard = saweriaBoard:WaitForChild("SaweriaBoard", 5)
if not topBoard then
	warn("❌ SaweriaBoard Frame tidak ditemukan!")
	return
end

local board = topBoard:WaitForChild("Board")
local container = board:WaitForChild("Container")
local canvas = container:WaitForChild("Canvas")
local header = canvas:WaitForChild("Header")
local subtitle = header:FindFirstChild("Title")
local body = canvas:WaitForChild("Body")
local content = body:WaitForChild("Content")

print("[DEBUG SAWERIA] UI Structure found:")
print("  - Board:", board.Name)
print("  - Container:", container.Name)
print("  - Canvas:", canvas.Name)
print("  - Body:", body.Name)
print("  - Content:", content.Name, "| Class:", content.ClassName)
print("  - Content Size:", content.Size)
print("  - Content AbsoluteSize:", content.AbsoluteSize)

-- Wait for RemoteFunction (Saweria specific)
local GetTopSpenders = ReplicatedStorage:WaitForChild("GetSaweriaTopSpenders", 10)

if not GetTopSpenders then
	warn("❌ [SAWERIA TOP] GetSaweriaTopSpenders RemoteFunction not found!")
	warn("   Make sure WebhookIntegrationDual.luau is running on server!")
	return
end

-- Settings
local REFRESH_INTERVAL = 30 -- Refresh every 30 seconds
local TOP_COUNT = 10 -- Show top 10
local ANIMATION_DURATION = 0.6

-- Top rank colors
local RANK_COLORS = {
	[1] = {
		bg = Color3.fromRGB(255, 215, 0), -- Gold
		text = Color3.fromRGB(139, 69, 0),
		gradient = {
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 223, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(218, 165, 32))
		}
	},
	[2] = {
		bg = Color3.fromRGB(192, 192, 192), -- Silver
		text = Color3.fromRGB(70, 70, 70),
		gradient = {
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 220, 220)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(192, 192, 192)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(169, 169, 169))
		}
	},
	[3] = {
		bg = Color3.fromRGB(205, 127, 50), -- Bronze
		text = Color3.fromRGB(101, 67, 33),
		gradient = {
			ColorSequenceKeypoint.new(0, Color3.fromRGB(214, 137, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(205, 127, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 100, 40))
		}
	}
}

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
		print("[SAWERIA TOP] Found player online, display name:", player.DisplayName)
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
		print("[SAWERIA TOP] Fetched display name from API:", result)
		return result
	else
		warn("⚠️ [SAWERIA TOP] Failed to get display name for:", username, "Error:", result)
		return username -- Fallback to username
	end
end

-- Format display: "DisplayName (Username)" or just "Username" if same
local function formatPlayerName(username)
	if not username or username == "" then
		return "Unknown"
	end

	-- Validate username first
	local isValid = pcall(function()
		Players:GetUserIdFromNameAsync(username)
	end)

	if not isValid then
		-- Invalid username - just show it as-is
		warn("⚠️ [SAWERIA TOP] Invalid username:", username)
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

local function getAvatarUrl(username)
	local success, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)

	if not success or not userId then
		return "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end

	local thumbSuccess, url = pcall(function()
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size150x150
		local thumbUrl, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
		return thumbUrl
	end)

	if thumbSuccess then
		return url
	else
		return "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

-- Create leaderboard entry
local function createEntry(rank, username, totalAmount)
	-- Wrapper CanvasGroup untuk GroupTransparency support
	local wrapper = Instance.new("CanvasGroup")
	wrapper.Name = "Entry_" .. rank
	wrapper.Size = UDim2.new(1, 0, 0, 130)
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel = 0
	wrapper.LayoutOrder = rank

	-- Gradient stroke on wrapper (same as Live Donation)
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

	local wrapperCorner = Instance.new("UICorner")
	wrapperCorner.CornerRadius = UDim.new(0, 12)
	wrapperCorner.Parent = wrapper

	local entry = Instance.new("Frame")
	entry.Name = "Content"
	entry.Size = UDim2.new(1, 0, 1, 0)
	entry.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	entry.BorderSizePixel = 0
	entry.Parent = wrapper

	-- Special styling for top 3
	local isTop3 = rank <= 3
	local rankColor = RANK_COLORS[rank]

	if isTop3 and rankColor then
		entry.BackgroundColor3 = Color3.fromRGB(50, 45, 40)

		-- Gradient for top 3
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(rankColor.gradient)
		gradient.Rotation = 90
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(1, 0.85)
		})
		gradient.Parent = entry
	else
		-- Regular gradient for others
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 55)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 45))
		})
		gradient.Rotation = 135
		gradient.Parent = entry
	end

	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = entry

	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 18)
	padding.PaddingBottom = UDim.new(0, 18)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = entry

	-- Rank badge
	local rankBadge = Instance.new("TextLabel")
	rankBadge.Name = "RankBadge"
	rankBadge.Size = UDim2.new(0, 60, 0, 60)
	rankBadge.Position = UDim2.new(0, 0, 0.5, 0)
	rankBadge.AnchorPoint = Vector2.new(0, 0.5)
	rankBadge.BackgroundColor3 = isTop3 and rankColor.bg or Color3.fromRGB(60, 60, 70)
	rankBadge.BorderSizePixel = 0
	rankBadge.Text = tostring(rank)
	rankBadge.TextColor3 = isTop3 and rankColor.text or Color3.fromRGB(200, 200, 200)
	rankBadge.TextSize = 28
	rankBadge.Font = Enum.Font.GothamBold
	rankBadge.Parent = entry

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(1, 0)
	badgeCorner.Parent = rankBadge

	-- Special icon for top 3
	if isTop3 then
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.fromScale(1, 1)
		icon.BackgroundTransparency = 1
		icon.Text = rank == 1 and "👑" or (rank == 2 and "🥈" or "🥉")
		icon.TextSize = 30
		icon.Parent = rankBadge
	end

	-- Avatar
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, 85, 0, 85)
	avatar.Position = UDim2.new(0, 70, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	avatar.Parent = entry

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar

	-- Username Label
	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name = "Username"
	usernameLabel.Size = UDim2.new(1, -240, 0, 40)
	usernameLabel.Position = UDim2.new(0, 165, 0, 10)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = username -- Temporary, will update with display name
	usernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	usernameLabel.TextSize = 35
	usernameLabel.Font = Enum.Font.GothamBold
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.Parent = entry

	-- Load avatar and display name asynchronously
	task.spawn(function()
		avatar.Image = getAvatarUrl(username)
		-- Update dengan format: DisplayName (Username)
		print("[SAWERIA TOP] Formatting name for:", username)
		local formattedName = formatPlayerName(username)
		print("[SAWERIA TOP] Formatted result:", formattedName)
		usernameLabel.Text = formattedName
	end)

	-- Amount
	local amountLabel = Instance.new("TextLabel")
	amountLabel.Name = "Amount"
	amountLabel.Size = UDim2.new(1, -240, 0, 40)
	amountLabel.Position = UDim2.new(0, 165, 0, 54)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = formatAmount(totalAmount)
	amountLabel.TextColor3 = isTop3 and rankColor.bg or Color3.fromRGB(255, 215, 0)
	amountLabel.TextSize = 35
	amountLabel.Font = Enum.Font.GothamBold
	amountLabel.TextXAlignment = Enum.TextXAlignment.Left
	amountLabel.Parent = entry

	-- Trophy/medal icon for top 3
	if isTop3 then
		local trophy = Instance.new("TextLabel")
		trophy.Size = UDim2.new(0, 45, 0, 45)
		trophy.Position = UDim2.new(1, -45, 0.5, 0)
		trophy.AnchorPoint = Vector2.new(0, 0.5)
		trophy.BackgroundTransparency = 1
		trophy.Text = "🏆"
		trophy.TextSize = 38
		trophy.Parent = entry

		-- Pulse animation for rank 1
		if rank == 1 then
			local pulse = TweenService:Create(trophy,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{TextSize = 42}
			)
			pulse:Play()
		end
	end

	-- Set initial state (important for SurfaceGui visibility)
	wrapper.Position = UDim2.new(0, 0, 0, 0)
	wrapper.GroupTransparency = 0
	wrapper.Visible = true

	print(string.format("[DEBUG SAWERIA] Created entry for rank %d: %s", rank, username))

	return wrapper
end

-- Clear all entries
local function clearEntries()
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("CanvasGroup") and child.Name:match("^Entry_") then
			child:Destroy()
		end
	end
end

-- Update leaderboard
local function updateLeaderboard()
	print("🔄 [SAWERIA TOP] Updating top spender leaderboard...")

	-- Request top spenders from server
	local success, result = pcall(function()
		return GetTopSpenders:InvokeServer(TOP_COUNT)
	end)

	if not success then
		warn("❌ [SAWERIA TOP] Error calling GetTopSpenders:", result)
		return
	end

	if not result then
		warn("❌ [SAWERIA TOP] GetTopSpenders returned nil")
		return
	end

	local topSpenders = result
	print("📊 [SAWERIA TOP] Received", #topSpenders, "top spenders")

	-- Debug: Print first 3 entries
	if #topSpenders > 0 then
		for i = 1, math.min(3, #topSpenders) do
			local spender = topSpenders[i]
			print(string.format("  [%d] %s - %d", i, spender.username or "nil", spender.totalAmount or 0))
		end
	else
		warn("⚠️ [SAWERIA TOP] No top spenders data received!")
		return
	end

	-- Clear existing entries
	clearEntries()

	-- Create new entries
	for rank, spenderData in ipairs(topSpenders) do
		if spenderData.username and spenderData.totalAmount then
			local entry = createEntry(rank, spenderData.username, spenderData.totalAmount)
			entry.Parent = content
			print(string.format("[DEBUG SAWERIA] Entry %d parented to content. Visible: %s", rank, tostring(entry.Visible)))
		else
			warn("⚠️ [SAWERIA TOP] Invalid spender data at rank", rank)
		end
	end

	print("✅ [SAWERIA TOP] Leaderboard updated with", #topSpenders, "entries")

	-- Update subtitle with next refresh time
	if subtitle then
		local countdown = REFRESH_INTERVAL
		task.spawn(function()
			while countdown > 0 and subtitle.Parent do
				subtitle.Text = string.format("Refreshing in %d seconds", countdown)
				task.wait(1)
				countdown = countdown - 1
			end
		end)
	end
end

-- Auto refresh loop
task.spawn(function()
	while true do
		updateLeaderboard()
		task.wait(REFRESH_INTERVAL)
	end
end)

-- Initial update
task.wait(2) -- Wait for server to be ready
updateLeaderboard()

-- Force refresh command (untuk testing)
-- Ketik di chat: /refreshboard
local localPlayer = Players.LocalPlayer

localPlayer.Chatted:Connect(function(message)
	if message:lower() == "/refreshboard" or message:lower() == "/refresh" then
		print("🔄 Force refreshing Saweria board from API...")

		-- Call with force refresh flag
		local success, result = pcall(function()
			return GetTopSpenders:InvokeServer(TOP_COUNT, true) -- true = force refresh
		end)

		if success and result then
			print("✅ Force refresh successful!")
			clearEntries()

			-- Update with fresh data
			for i, spender in ipairs(result) do
				local entry = createEntry(i, spender.username, spender.totalAmount)
				entry.Parent = content
			end
		else
			warn("❌ Force refresh failed:", result)
		end
	end
end)

print("✅ Saweria Top Board system ready!")
