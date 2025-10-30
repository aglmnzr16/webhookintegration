--[[
═══════════════════════════════════════════════════════════════════════════════
  ROBUX DONATION SYSTEM - Server Integration
═══════════════════════════════════════════════════════════════════════════════

SYSTEM: In-Game Donation (Developer Products)
TYPE: Server Script (ServerScriptService)
CURRENCY: Robux (R$)

PURPOSE:
  - Process in-game Robux donation purchases
  - Handle MarketplaceService transactions
  - Update Donation Board V3 DataStore
  - Send popup notifications to clients
  - Cache user info to prevent rate limiting

DEPENDENCIES:
  Services:
    - Players (user information)
    - MarketplaceService (purchase processing)
    - DataStoreService (donation tracking)
    - UserService (user info with caching!)
    - ReplicatedStorage (RemoteEvents)
    - RunService (environment detection)

REMOTE EVENTS CREATED:
  - NewDonationSystem/PurchaseNewDonation (Client → Server)
      Purpose: Initiate purchase request
  
  - NewDonationSystem/ShowNewDonationNotif (Server → All Clients)
      Purpose: Popup notifications

DEVELOPER PRODUCTS:
  - 100 Robux Donation   (ID: 3438213239)
  - 200 Robux Donation   (ID: 3438213399)
  - 500 Robux Donation   (ID: 3438213537)
  - 1000 Robux Donation  (ID: 3438213683)
  - 2000 Robux Donation  (ID: 3438213834)
  - 5000 Robux Donation  (ID: 3438213970)
  - 10000 Robux Donation (ID: 3438214109)

RATE LIMIT PROTECTION:
  - User info caching (5 minutes)
  - API call cooldown (1.5 seconds between calls)
  - Automatic fallback to player data

═══════════════════════════════════════════════════════════════════════════════
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

-- ============================================================================
-- DATASTORE CONFIGURATION - MENGGUNAKAN DONATION BOARD V3 DATASTORE
-- ============================================================================

-- DataStore untuk system baru (untuk tracking purchase saja)
local newDonationStore = DataStoreService:GetDataStore("NewDonationSystem")

-- ✅ DONATION BOARD V3 DATASTORE (INI YANG PENTING!)
local donationBoardDataStore = DataStoreService:GetDataStore("Donation Board // V3 - Data")

-- Check environment (Studio atau Experience)
local isStudio = RunService:IsStudio()

-- Create folder for new donation system
local newDonationFolder = Instance.new("Folder")
newDonationFolder.Name = "NewDonationSystem"
newDonationFolder.Parent = ReplicatedStorage

-- Create RemoteEvents
local purchaseNewDonation = Instance.new("RemoteEvent")
purchaseNewDonation.Name = "PurchaseNewDonation"
purchaseNewDonation.Parent = newDonationFolder

local showNewDonationNotif = Instance.new("RemoteEvent")
showNewDonationNotif.Name = "ShowNewDonationNotif"
showNewDonationNotif.Parent = newDonationFolder

-- Developer Products
local NEW_DONATION_PRODUCTS = {
	[3438213239] = {name = "100 Robux Donation", price = 100},
	[3438213399] = {name = "200 Robux Donation", price = 200},
	[3438213537] = {name = "500 Robux Donation", price = 500},
	[3438213683] = {name = "1000 Robux Donation", price = 1000},
	[3438213834] = {name = "2000 Robux Donation", price = 2000},
	[3438213970] = {name = "5000 Robux Donation", price = 5000},
	[3438214109] = {name = "10000 Robux Donation", price = 10000},
}

-- Store pending purchases with custom messages
local pendingPurchases = {}

-- ✅ USER INFO CACHE - PREVENT RATE LIMITING!
local userInfoCache = {}
local USER_CACHE_DURATION = 300 -- Cache for 5 minutes
local lastApiCallTime = 0
local API_CALL_COOLDOWN = 1.5 -- Minimum 1.5 seconds between API calls

local function getCachedUserInfo(userId, playerName, playerDisplayName)
	-- Check cache first
	local cached = userInfoCache[userId]
	if cached and (os.time() - cached.timestamp) < USER_CACHE_DURATION then
		print(`[NEW DONATION] ✅ Using cached user info for {userId}`)
		return cached.data
	end
	
	-- Rate limit protection: wait if last call was too recent
	local timeSinceLastCall = tick() - lastApiCallTime
	if timeSinceLastCall < API_CALL_COOLDOWN then
		local waitTime = API_CALL_COOLDOWN - timeSinceLastCall
		print(string.format("[NEW DONATION] ⏱️ Rate limit protection: waiting %.2fs before API call...", waitTime))
		task.wait(waitTime)
	end
	
	-- Try to fetch from API (with rate limit protection)
	local userInfo
	local success, err = pcall(function()
		lastApiCallTime = tick()  -- Mark API call time
		userInfo = UserService:GetUserInfosByUserIdsAsync({userId})[1]
	end)
	
	if success and userInfo then
		-- Cache the result
		userInfoCache[userId] = {
			data = userInfo,
			timestamp = os.time()
		}
		print(`[NEW DONATION] Fetched and cached user info for {userId}`)
		return userInfo
	else
		-- Fallback to player data (no API call needed!)
		warn(`[NEW DONATION] Failed to get user info from API: {err}`)
		userInfo = {
			Username = playerName,
			DisplayName = playerDisplayName,
			Id = userId
		}
		
		-- Cache the fallback too (short duration)
		userInfoCache[userId] = {
			data = userInfo,
			timestamp = os.time()
		}
		
		return userInfo
	end
end

-- Store pending purchases with custom messages
local pendingNewPurchases = {}
local processedPurchases = {}


-- ============================================================================
-- ✅ FUNCTION INTEGRASI KE DONATION BOARD V3 DATASTORE
-- ============================================================================

local function updateDonationBoardV3(userId, username, displayName, donationAmount)
	print(`[DONATION V3 INTEGRATION] Updating DataStore for {username}...`)

	local success, result = pcall(function()
		return donationBoardDataStore:UpdateAsync("Donations", function(pastData)
			pastData = pastData or {}

			-- Get atau create user data
			local userData = pastData[tostring(userId)] or {}

			-- Update user info
			userData["DisplayName"] = displayName
			userData["Name"] = username
			userData["UserId"] = userId

			-- Initialize donation values jika belum ada
			userData["Donated - Experience"] = userData["Donated - Experience"] or 0
			userData["Donated - Studio"] = userData["Donated - Studio"] or 0
			userData["History"] = userData["History"] or {}

			-- Add donation berdasarkan environment (Studio vs Experience)
			if isStudio then
				-- Di Studio, tambahkan ke "Donated - Studio"
				userData["Donated - Studio"] = userData["Donated - Studio"] + donationAmount
				pastData["Total - Studio"] = (pastData["Total - Studio"] or 0) + donationAmount
				print(`[DONATION V3 INTEGRATION] Added {donationAmount} to Studio donations`)
			else
				-- Di Experience, tambahkan ke "Donated - Experience"
				userData["Donated - Experience"] = userData["Donated - Experience"] + donationAmount
				pastData["Total - Experience"] = (pastData["Total - Experience"] or 0) + donationAmount
				print(`[DONATION V3 INTEGRATION] Added {donationAmount} to Experience donations`)
			end

			-- Add to history
			table.insert(userData["History"], {
				amount = donationAmount,
				timestamp = os.time(),
				environment = isStudio and "Studio" or "Experience",
				source = "NewDonationSystem"
			})

			-- Save user data
			pastData[tostring(userId)] = userData

			-- Update Users list
			pastData["Users"] = pastData["Users"] or {}
			if not table.find(pastData["Users"], tostring(userId)) then
				table.insert(pastData["Users"], tostring(userId))
			end

			return pastData
		end)
	end)

	if success then
		print(`[DONATION V3 INTEGRATION] ✅ Successfully saved to Donation Board V3 DataStore`)
		print(`  → User: {username}`)
		print(`  → Amount: {donationAmount} Robux`)
		print(`  → Environment: {isStudio and "Studio" or "Experience"}`)

		-- Update player attribute (untuk leaderstats dll)
		local player = Players:FindFirstChild(username)
		if player then
			local currentRobux = player:GetAttribute("Robux") or 0
			player:SetAttribute("Robux", currentRobux + donationAmount)
			print(`[DONATION V3 INTEGRATION] Updated player attribute: {currentRobux + donationAmount}`)
		end

		return true
	else
		warn(`[DONATION V3 INTEGRATION] ❌ Failed to save: {result}`)
		return false
	end
end


-- ============================================================================
-- HANDLE PURCHASE REQUEST
-- ============================================================================

purchaseNewDonation.OnServerEvent:Connect(function(player, productId, customMessage)
	print(`[NEW DONATION] {player.Name} requesting donation with product {productId}`)

	if NEW_DONATION_PRODUCTS[productId] then
		-- Store custom message for this player
		pendingNewPurchases[player.UserId] = {
			customMessage = customMessage or "",
			productId = productId,
			timestamp = os.time()
		}

		-- Prompt purchase
		local success, errorMessage = pcall(function()
			MarketplaceService:PromptProductPurchase(player, productId)
		end)

		if not success then
			warn(`[NEW DONATION] Failed to prompt purchase: {errorMessage}`)
			pendingNewPurchases[player.UserId] = nil
		end
	else
		warn(`[NEW DONATION] Invalid product ID: {productId}`)
	end
end)


-- ============================================================================
-- LISTEN FOR SUCCESSFUL PURCHASES
-- ============================================================================

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
	if not isPurchased then return end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	-- Check if this is our product and from our system
	local productInfo = NEW_DONATION_PRODUCTS[productId]
	local pendingPurchase = pendingNewPurchases[userId]

	if not productInfo then return end -- Not our product
	if not pendingPurchase or pendingPurchase.productId ~= productId then return end -- Not from our system

	-- Create unique purchase identifier
	local purchaseKey = `NewDonation_{userId}_{productId}_{os.time()}`

	-- Prevent duplicate processing
	if processedPurchases[purchaseKey] then return end
	processedPurchases[purchaseKey] = true

	local customMessage = pendingPurchase.customMessage or ""
	pendingNewPurchases[userId] = nil -- Clear pending

	print(`[NEW DONATION] Processing purchase: {player.Name} - {productInfo.price} Robux - "{customMessage}"`)

	-- ========================================================================
	-- ✅ GET USER INFO & SAVE TO DONATION BOARD V3 DATASTORE (WITH CACHING!)
	-- ========================================================================

	-- Use cached version to avoid rate limits!
	local userInfo = getCachedUserInfo(userId, player.Name, player.DisplayName)

	-- ✅ UPDATE DONATION BOARD V3 DATASTORE (INI YANG PENTING!)
	local saveSuccess = updateDonationBoardV3(
		userId,
		userInfo.Username,
		userInfo.DisplayName,
		productInfo.price
	)

	if not saveSuccess then
		warn(`[NEW DONATION] ❌ Failed to save to Donation Board V3 DataStore!`)
		-- Don't return here, still continue with other effects
	end

	-- ========================================================================
	-- SEND NOTIFICATION TO ALL CLIENTS
	-- ========================================================================

	showNewDonationNotif:FireAllClients({
		donatorName = player.Name,
		donatorDisplayName = player.DisplayName,
		donatorId = player.UserId,
		amount = productInfo.price,
		customMessage = customMessage,
		timestamp = os.time(),
		environment = isStudio and "Studio" or "Experience"
	})

	-- ========================================================================
	-- TRIGGER ROBUX DONATION EFFECTS (RobuxDonationEffect.luau)
	-- ========================================================================

	task.wait(0.1)
	if _G.TriggerRobuxDonationEffect then
		local effectSuccess = _G.TriggerRobuxDonationEffect(
			player,        -- Donator player
			player,        -- Recipient player (self donation)
			productInfo.price  -- Robux amount
		)

		if effectSuccess then
			print(`[NEW DONATION] ✅ Robux effects triggered: R$ {productInfo.price}`)
		else
			warn(`[NEW DONATION] ⚠️ Failed to trigger Robux effects`)
		end
	else
		warn(`[NEW DONATION] ⚠️ _G.TriggerRobuxDonationEffect not found! Effects won't play.`)
		warn(`[NEW DONATION] Make sure RobuxDonationEffect.luau is loaded in ServerScriptService`)
	end

	-- ========================================================================
	-- SAVE TO NEW DONATION SYSTEM DATASTORE (untuk tracking)
	-- ========================================================================

	pcall(function()
		newDonationStore:SetAsync(purchaseKey, {
			processed = true,
			timestamp = os.time(),
			productId = productId,
			price = productInfo.price,
			buyer = player.Name,
			customMessage = customMessage,
			fromNewSystem = true,
			savedToDonationBoardV3 = saveSuccess
		})
	end)

	print(`[NEW DONATION] ✅ Successfully processed donation: {productInfo.price} R$ from {player.Name}`)
	print(`[NEW DONATION] Saved to Donation Board V3: {saveSuccess and "YES" or "NO"}`)
end)


-- ============================================================================
-- LOAD PLAYER DONATION DATA SAAT JOIN
-- ============================================================================

local function loadPlayerDonationData(player)
	task.wait(2) -- Wait untuk player fully load

	local userId = player.UserId

	local success, data = pcall(function()
		return donationBoardDataStore:GetAsync("Donations")
	end)

	if success and data then
		local userData = data[tostring(userId)]
		if userData then
			local totalDonated = 0

			-- Calculate total berdasarkan environment
			if isStudio then
				totalDonated = (userData["Donated - Experience"] or 0) + (userData["Donated - Studio"] or 0)
			else
				totalDonated = userData["Donated - Experience"] or 0
			end

			player:SetAttribute("Robux", totalDonated)
			print(`[NEW DONATION] Loaded {totalDonated} Robux for {player.Name}`)
		else
			print(`[NEW DONATION] No previous donation data for {player.Name}`)
		end
	else
		warn(`[NEW DONATION] Failed to load donation data: {data}`)
	end
end

-- Auto-load saat player join
Players.PlayerAdded:Connect(function(player)
	loadPlayerDonationData(player)
end)

-- Load untuk players yang sudah ada
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayerDonationData, player)
end


-- ============================================================================
-- CLEANUP OLD DATA
-- ============================================================================

spawn(function()
	while true do
		task.wait(300) -- Every 5 minutes
		local currentTime = os.time()

		-- Clean pending purchases
		for userId, purchaseData in pairs(pendingNewPurchases) do
			if currentTime - purchaseData.timestamp > 300 then
				pendingNewPurchases[userId] = nil
				print(`[NEW DONATION] Cleaned up old pending purchase for user {userId}`)
			end
		end

		-- Clean processed purchases (keep for 1 hour to prevent duplicates)
		for purchaseKey, _ in pairs(processedPurchases) do
			local timestamp = tonumber(string.match(purchaseKey, "(%d+)$"))
			if timestamp and currentTime - timestamp > 3600 then
				processedPurchases[purchaseKey] = nil
			end
		end
	end
end)


-- ============================================================================
-- STARTUP MESSAGES
-- ============================================================================

print("═══════════════════════════════════════════════════════════════")
print("[NEW DONATION] ✅ Integrated Donation System loaded successfully!")
print("[NEW DONATION] Using PromptProductPurchaseFinished (NO ProcessReceipt override)")
print("[NEW DONATION] DataStore: 'Donation Board // V3 - Data'")
print(`[NEW DONATION] Environment: {isStudio and "STUDIO" or "EXPERIENCE"}`)
print("[NEW DONATION] Features:")
print("[NEW DONATION] - Custom messages")
print("[NEW DONATION] - Donation effects integration")
print("[NEW DONATION] - Saves to Donation Board V3 DataStore")
print("[NEW DONATION] - Real-time data sync")
print("═══════════════════════════════════════════════════════════════")