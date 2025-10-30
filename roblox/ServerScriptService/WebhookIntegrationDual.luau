--[[
═══════════════════════════════════════════════════════════════════════════════
  DUAL PLATFORM DONATION SYSTEM - BagiBagi & Saweria
═══════════════════════════════════════════════════════════════════════════════

SYSTEM: External Donation (BagiBagi & Saweria)
TYPE: Server Script (ServerScriptService)
CURRENCY: Rupiah (Rp.)

PURPOSE:
  - Poll separate API endpoints for BagiBagi and Saweria
  - Respect DonationConfig for enable/disable per platform
  - Fire to separate RemoteEvents per platform
  - Independent top spenders per platform

PLATFORMS:
  BagiBagi:
    - API: /api/roblox/donations?source=bagibagi
    - RemoteEvent: RealtimeDonation
    - Notification: ShowBagiBagiDonationNotif
    
  Saweria:
    - API: /api/roblox/donations?source=saweria
    - RemoteEvent: SaweriaRealtimeDonation
    - Notification: ShowSaweriaDonationNotif

CONFIGURATION:
  - Uses DonationConfig.luau from ServerStorage
  - Config.BagiBagi.Enabled = true/false
  - Config.Saweria.Enabled = true/false

═══════════════════════════════════════════════════════════════════════════════
]]--

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Load DonationConfig
local DonationConfig = require(ServerStorage:WaitForChild("DonationConfig"))

print("🎮 ========== DUAL PLATFORM DONATION SYSTEM ==========")
DonationConfig:PrintStatus()

-- =============================================================================
-- REMOTE EVENTS SETUP
-- =============================================================================

-- BagiBagi RemoteEvents
local BagiBagiRealtimeDonation = Instance.new("RemoteEvent")
BagiBagiRealtimeDonation.Name = "RealtimeDonation"
BagiBagiRealtimeDonation.Parent = ReplicatedStorage

local BagiBagiSystem = Instance.new("Folder")
BagiBagiSystem.Name = "BagiBagiDonationSystem"
BagiBagiSystem.Parent = ReplicatedStorage

local ShowBagiBagiNotif = Instance.new("RemoteEvent")
ShowBagiBagiNotif.Name = "ShowBagiBagiDonationNotif"
ShowBagiBagiNotif.Parent = BagiBagiSystem

-- Saweria RemoteEvents
local SaweriaRealtimeDonation = Instance.new("RemoteEvent")
SaweriaRealtimeDonation.Name = "SaweriaRealtimeDonation"
SaweriaRealtimeDonation.Parent = ReplicatedStorage

local SaweriaSystem = Instance.new("Folder")
SaweriaSystem.Name = "SaweriaDonationSystem"
SaweriaSystem.Parent = ReplicatedStorage

local ShowSaweriaNotif = Instance.new("RemoteEvent")
ShowSaweriaNotif.Name = "ShowSaweriaDonationNotif"
ShowSaweriaNotif.Parent = SaweriaSystem

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

local WEBHOOK_API_BASE = "https://webhook-integration-zeta.vercel.app/"
local POLL_INTERVAL = 5 -- Poll every 5 seconds

-- Separate tracking per platform
local bagiBagiLastPoll = 0
local saweriaLastPoll = 0
local processedBagiBagi = {}
local processedSaweria = {}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

local function getPlayerInfo(username)
	if not username or username == "" then
		return nil, nil
	end
	
	local success, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)
	
	if not success or not userId then
		return nil, nil
	end
	
	local displaySuccess, result = pcall(function()
		local humanoidDesc = Players:GetHumanoidDescriptionFromUserId(userId)
		return humanoidDesc.DisplayName
	end)
	
	local displayName = (displaySuccess and result) or username
	return displayName, userId
end

-- =============================================================================
-- BAGIBAGI POLLING
-- =============================================================================

local function pollBagiBagiDonations()
	if not DonationConfig:IsBagiBagiEnabled() then
		return  -- Skip if disabled
	end
	
	local currentTime = os.time() * 1000
	local url = string.format("%s%s&since=%d&limit=10", 
		WEBHOOK_API_BASE, 
		DonationConfig.BagiBagi.API.Endpoint,
		bagiBagiLastPoll
	)
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)
	
	if success then
		local parseSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)
		
		if parseSuccess and data.ok then
			print("🔄 [BAGIBAGI] Poll successful, donations:", #(data.donations or {}))
			
			for _, donation in ipairs(data.donations or {}) do
				if not processedBagiBagi[donation.id] then
					processedBagiBagi[donation.id] = true
					
					local notifData = {
						donor = donation.donor,
						amount = donation.amount,
						message = donation.message,
						robloxUsername = donation.matchedUsername,
						timestamp = donation.ts
					}
					
					print(string.format("💰 [BAGIBAGI] %s → %d | Matched: %s", 
						donation.donor, donation.amount, donation.matchedUsername or "None"))
					
					-- Fire to BagiBagi live feed
					BagiBagiRealtimeDonation:FireAllClients(notifData)
					
					-- Fire popup notification
					if donation.matchedUsername then
						local displayName, userId = getPlayerInfo(donation.matchedUsername)
						local popupData = {
							donatorName = donation.matchedUsername,
							donatorDisplayName = displayName or donation.matchedUsername,
							donatorId = userId,
							amount = donation.amount,
							customMessage = donation.message or "No message",
							currencyType = "IDR"
						}
						ShowBagiBagiNotif:FireAllClients(popupData)
					end
					
					-- Trigger effects
					if donation.matchedUsername and _G.TriggerSaweriaDonationEffect then
						_G.TriggerSaweriaDonationEffect(
							donation.donor,
							donation.matchedUsername,
							donation.amount,
							donation.message
						)
					end
				end
			end
			
			bagiBagiLastPoll = currentTime
		end
	else
		warn("❌ [BAGIBAGI] Poll failed:", response)
	end
end

-- =============================================================================
-- SAWERIA POLLING
-- =============================================================================

local function pollSaweriaDonations()
	if not DonationConfig:IsSaweriaEnabled() then
		return  -- Skip if disabled
	end
	
	local currentTime = os.time() * 1000
	local url = string.format("%s%s&since=%d&limit=10", 
		WEBHOOK_API_BASE, 
		DonationConfig.Saweria.API.Endpoint,
		saweriaLastPoll
	)
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)
	
	if success then
		local parseSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)
		
		if parseSuccess and data.ok then
			print("🔄 [SAWERIA] Poll successful, donations:", #(data.donations or {}))
			
			for _, donation in ipairs(data.donations or {}) do
				if not processedSaweria[donation.id] then
					processedSaweria[donation.id] = true
					
					local notifData = {
						donor = donation.donor,
						amount = donation.amount,
						message = donation.message,
						robloxUsername = donation.matchedUsername,
						timestamp = donation.ts
					}
					
					print(string.format("💰 [SAWERIA] %s → %d | Matched: %s", 
						donation.donor, donation.amount, donation.matchedUsername or "None"))
					
					-- Fire to Saweria live feed
					SaweriaRealtimeDonation:FireAllClients(notifData)
					
					-- Fire popup notification
					if donation.matchedUsername then
						local displayName, userId = getPlayerInfo(donation.matchedUsername)
						local popupData = {
							donatorName = donation.matchedUsername,
							donatorDisplayName = displayName or donation.matchedUsername,
							donatorId = userId,
							amount = donation.amount,
							customMessage = donation.message or "No message",
							currencyType = "IDR"
						}
						ShowSaweriaNotif:FireAllClients(popupData)
					end
					
					-- Trigger effects (including BlackHole for 1M)
					if donation.matchedUsername and _G.TriggerSaweriaDonationEffect then
						_G.TriggerSaweriaDonationEffect(
							donation.donor,
							donation.matchedUsername,
							donation.amount,
							donation.message
						)
					end
				end
			end
			
			saweriaLastPoll = currentTime
		end
	else
		warn("❌ [SAWERIA] Poll failed:", response)
	end
end

-- =============================================================================
-- TOP SPENDERS FUNCTIONS
-- =============================================================================

local DataStoreService = game:GetService("DataStoreService")
local BagiBagiTopStore = DataStoreService:GetDataStore("BagiBagiTopSpenders")
local SaweriaTopStore = DataStoreService:GetDataStore("SaweriaTopSpenders")

local cachedBagiBagiTop = {}
local cachedSaweriaTop = {}
local lastBagiBagiTopUpdate = 0
local lastSaweriaTopUpdate = 0
local TOP_CACHE_MAX_AGE = 30 -- 30 seconds

-- Fetch BagiBagi top spenders from API
local function fetchBagiBagiTopSpenders(limit)
	limit = limit or 10
	local url = string.format("%s/api/roblox/top-spenders?source=bagibagi&limit=%d", 
		WEBHOOK_API_BASE, limit)
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)
	
	if success then
		local parseSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)
		
		if parseSuccess and data.ok then
			print("✅ [BAGIBAGI TOP] Fetched", #(data.topSpenders or {}), "top spenders")
			return data.topSpenders or {}
		end
	end
	
	warn("❌ [BAGIBAGI TOP] Failed to fetch from API")
	return {}
end

-- Fetch Saweria top spenders from API
local function fetchSaweriaTopSpenders(limit)
	limit = limit or 10
	local url = string.format("%s/api/roblox/top-spenders?source=saweria&limit=%d", 
		WEBHOOK_API_BASE, limit)
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)
	
	if success then
		local parseSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)
		
		if parseSuccess and data.ok then
			print("✅ [SAWERIA TOP] Fetched", #(data.topSpenders or {}), "top spenders")
			return data.topSpenders or {}
		end
	end
	
	warn("❌ [SAWERIA TOP] Failed to fetch from API")
	return {}
end

-- Update BagiBagi top spenders cache
local function updateBagiBagiTopCache()
	if not DonationConfig:IsBagiBagiEnabled() then return end
	
	local data = fetchBagiBagiTopSpenders(50)
	if #data > 0 then
		cachedBagiBagiTop = data
		lastBagiBagiTopUpdate = os.time()
		
		pcall(function()
			BagiBagiTopStore:SetAsync("Cache", {
				data = data,
				timestamp = lastBagiBagiTopUpdate
			})
		end)
		
		print("✅ [BAGIBAGI TOP] Cache updated:", #data, "entries")
	end
end

-- Update Saweria top spenders cache
local function updateSaweriaTopCache()
	if not DonationConfig:IsSaweriaEnabled() then return end
	
	local data = fetchSaweriaTopSpenders(50)
	if #data > 0 then
		cachedSaweriaTop = data
		lastSaweriaTopUpdate = os.time()
		
		pcall(function()
			SaweriaTopStore:SetAsync("Cache", {
				data = data,
				timestamp = lastSaweriaTopUpdate
			})
		end)
		
		print("✅ [SAWERIA TOP] Cache updated:", #data, "entries")
	end
end

-- Get BagiBagi top spenders (from cache)
local function getBagiBagiTopSpenders(limit, forceRefresh)
	if not DonationConfig:IsBagiBagiEnabled() then
		return {}
	end
	
	limit = limit or 10
	local cacheAge = os.time() - lastBagiBagiTopUpdate
	
	if forceRefresh or #cachedBagiBagiTop == 0 or cacheAge > TOP_CACHE_MAX_AGE then
		print("🔄 [BAGIBAGI TOP] Refreshing cache...")
		updateBagiBagiTopCache()
	end
	
	local result = {}
	for i = 1, math.min(limit, #cachedBagiBagiTop) do
		table.insert(result, cachedBagiBagiTop[i])
	end
	
	return result
end

-- Get Saweria top spenders (from cache)
local function getSaweriaTopSpenders(limit, forceRefresh)
	if not DonationConfig:IsSaweriaEnabled() then
		return {}
	end
	
	limit = limit or 10
	local cacheAge = os.time() - lastSaweriaTopUpdate
	
	if forceRefresh or #cachedSaweriaTop == 0 or cacheAge > TOP_CACHE_MAX_AGE then
		print("🔄 [SAWERIA TOP] Refreshing cache...")
		updateSaweriaTopCache()
	end
	
	local result = {}
	for i = 1, math.min(limit, #cachedSaweriaTop) do
		table.insert(result, cachedSaweriaTop[i])
	end
	
	return result
end

-- Create RemoteFunction for BagiBagi top spenders
local GetBagiBagiTopSpenders = Instance.new("RemoteFunction")
GetBagiBagiTopSpenders.Name = "GetTopSpenders"  -- Keep same name for compatibility
GetBagiBagiTopSpenders.Parent = ReplicatedStorage

GetBagiBagiTopSpenders.OnServerInvoke = function(player, limit, forceRefresh)
	return getBagiBagiTopSpenders(limit or 10, forceRefresh or false)
end

-- Create RemoteFunction for Saweria top spenders
local GetSaweriaTopSpenders = Instance.new("RemoteFunction")
GetSaweriaTopSpenders.Name = "GetSaweriaTopSpenders"
GetSaweriaTopSpenders.Parent = ReplicatedStorage

GetSaweriaTopSpenders.OnServerInvoke = function(player, limit, forceRefresh)
	return getSaweriaTopSpenders(limit or 10, forceRefresh or false)
end

-- Initialize top spenders caches
task.spawn(function()
	task.wait(2) -- Wait for server to be ready
	
	if DonationConfig:IsBagiBagiEnabled() then
		print("📊 [BAGIBAGI] Initializing top spenders cache...")
		updateBagiBagiTopCache()
	end
	
	if DonationConfig:IsSaweriaEnabled() then
		print("📊 [SAWERIA] Initializing top spenders cache...")
		updateSaweriaTopCache()
	end
end)

-- Auto-refresh top spenders every 30 seconds
task.spawn(function()
	task.wait(10)
	while true do
		task.wait(30)
		
		if DonationConfig:IsBagiBagiEnabled() then
			updateBagiBagiTopCache()
		end
		
		if DonationConfig:IsSaweriaEnabled() then
			updateSaweriaTopCache()
		end
	end
end)

-- =============================================================================
-- MAIN POLLING LOOPS
-- =============================================================================

-- BagiBagi polling loop
if DonationConfig:IsBagiBagiEnabled() then
	task.spawn(function()
		print("🚀 [BAGIBAGI] Polling started!")
		bagiBagiLastPoll = os.time() * 1000
		
		while true do
			if DonationConfig:IsBagiBagiEnabled() then
				pollBagiBagiDonations()
			end
			task.wait(POLL_INTERVAL)
		end
	end)
else
	print("⏸️ [BAGIBAGI] Disabled in config, skipping polling")
end

-- Saweria polling loop
if DonationConfig:IsSaweriaEnabled() then
	task.spawn(function()
		print("🚀 [SAWERIA] Polling started!")
		saweriaLastPoll = os.time() * 1000
		
		while true do
			if DonationConfig:IsSaweriaEnabled() then
				pollSaweriaDonations()
			end
			task.wait(POLL_INTERVAL)
		end
	end)
else
	print("⏸️ [SAWERIA] Disabled in config, skipping polling")
end

-- Cleanup old processed donations
task.spawn(function()
	while true do
		task.wait(600) -- Every 10 minutes
		
		local currentTime = os.time() * 1000
		local cutoffTime = currentTime - (30 * 60 * 1000) -- 30 minutes ago
		
		-- Cleanup BagiBagi
		local cleanedBB = 0
		for donationId, _ in pairs(processedBagiBagi) do
			local idTimestamp = tonumber(string.match(donationId, "^(%d+)"))
			if idTimestamp and idTimestamp < cutoffTime then
				processedBagiBagi[donationId] = nil
				cleanedBB = cleanedBB + 1
			end
		end
		
		-- Cleanup Saweria
		local cleanedSW = 0
		for donationId, _ in pairs(processedSaweria) do
			local idTimestamp = tonumber(string.match(donationId, "^(%d+)"))
			if idTimestamp and idTimestamp < cutoffTime then
				processedSaweria[donationId] = nil
				cleanedSW = cleanedSW + 1
			end
		end
		
		if cleanedBB > 0 or cleanedSW > 0 then
			print(string.format("🧹 Cleaned old donations: BagiBagi=%d, Saweria=%d", cleanedBB, cleanedSW))
		end
	end
end)

print("✅ Dual Platform Donation System ready!")
print("   - BagiBagi:", DonationConfig:IsBagiBagiEnabled() and "ENABLED ✅" or "DISABLED ⏸️")
print("   - Saweria:", DonationConfig:IsSaweriaEnabled() and "ENABLED ✅" or "DISABLED ⏸️")
