--[[
═══════════════════════════════════════════════════════════════════════════════
  SAWERIA/BAGIBAGI DONATION SYSTEM - Server Integration
═══════════════════════════════════════════════════════════════════════════════

SYSTEM: External Donation (Saweria/BagiBagi)
TYPE: Server Script (ServerScriptService)
CURRENCY: Rupiah (Rp.)

PURPOSE:
  - Poll webhook API for new external donations
  - Match donor names to Roblox usernames  
  - Send real-time notifications to clients
  - Update top spenders leaderboard
  - Trigger visual/audio donation effects

DEPENDENCIES:
  Services:
    - HttpService (API calls to webhook)
    - ReplicatedStorage (RemoteEvents)
    - Players (username matching)
    - DataStoreService (caching)
  
  External:
    - Webhook API (Vercel deployment)
    - DonationEffect.luau (particle/sound effects)

REMOTE EVENTS CREATED:
  - RealtimeDonation (Server → All Clients)
      Purpose: Live donation feed updates
  
  - SaweriaDonationSystem/ShowSaweriaDonationNotif (Server → All Clients)
      Purpose: Popup notifications

REMOTE FUNCTIONS CREATED:
  - GetTopSpenders (Client ← Server)
      Purpose: Fetch top spenders list with caching

CONFIGURATION:
  - POLL_INTERVAL: 3 seconds (webhook polling)
  - TOP_SPENDERS_REFRESH_INTERVAL: 30 seconds
  - TOP_SPENDERS_CACHE_MAX_AGE: 30 seconds

═══════════════════════════════════════════════════════════════════════════════
]]--

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

-- Load DonationConfig
local DonationConfig = require(ServerStorage:WaitForChild("DonationConfig"))

-- =============================================================================
-- BAGIBAGI REMOTE EVENTS
-- =============================================================================
local BagiBagiRealtimeDonation = Instance.new("RemoteEvent")
BagiBagiRealtimeDonation.Name = "RealtimeDonation"  -- For BagiBagi live feed
BagiBagiRealtimeDonation.Parent = ReplicatedStorage

-- BagiBagi notification system
local BagiBagiDonationSystem = Instance.new("Folder")
BagiBagiDonationSystem.Name = "BagiBagiDonationSystem"
BagiBagiDonationSystem.Parent = ReplicatedStorage

local ShowBagiBagiDonationNotif = Instance.new("RemoteEvent")
ShowBagiBagiDonationNotif.Name = "ShowBagiBagiDonationNotif"
ShowBagiBagiDonationNotif.Parent = BagiBagiDonationSystem

-- =============================================================================
-- SAWERIA REMOTE EVENTS
-- =============================================================================
local SaweriaRealtimeDonation = Instance.new("RemoteEvent")
SaweriaRealtimeDonation.Name = "SaweriaRealtimeDonation"  -- For Saweria live feed
SaweriaRealtimeDonation.Parent = ReplicatedStorage

-- Saweria notification system
local SaweriaDonationSystem = Instance.new("Folder")
SaweriaDonationSystem.Name = "SaweriaDonationSystem"
SaweriaDonationSystem.Parent = ReplicatedStorage

local ShowSaweriaDonationNotif = Instance.new("RemoteEvent")
ShowSaweriaDonationNotif.Name = "ShowSaweriaDonationNotif"
ShowSaweriaDonationNotif.Parent = SaweriaDonationSystem

-- Configuration
local WEBHOOK_API_BASE = "https://webhook-integration-zeta.vercel.app/" -- Ganti dengan URL deploy Anda
local POLL_INTERVAL = 3 -- Poll setiap 3 detik untuk real-time
local TOP_SPENDERS_REFRESH_INTERVAL = 30 -- Refresh top spenders setiap 30 detik - BALANCED!
local TOP_SPENDERS_CACHE_MAX_AGE = 30 -- Cache dianggap expired setelah 30 detik - BALANCED!

-- Separate tracking per platform
local bagiBagiLastPollTime = 0
local saweriaLastPollTime = 0
local processedBagiBagiDonations = {}
local processedSaweriaDonations = {}

-- DataStore untuk top spenders cache
local TopSpendersStore = DataStoreService:GetDataStore("TopSpendersCache")
local cachedTopSpenders = {}
local lastTopSpendersUpdate = 0

-- Helper function untuk get display name and userId
local function getPlayerInfo(username)
	if not username or username == "" then
		return nil, nil
	end
	
	-- Try to get userId
	local success, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)
	
	if not success or not userId then
		warn("[NOTIF] Failed to get userId for:", username)
		return nil, nil
	end
	
	-- Try to get display name
	local displaySuccess, result = pcall(function()
		local humanoidDesc = Players:GetHumanoidDescriptionFromUserId(userId)
		return humanoidDesc.DisplayName
	end)
	
	local displayName = (displaySuccess and result) or username
	
	return displayName, userId
end

-- Function untuk polling donations dari webhook API
local function pollRealtimeDonations()
	local currentTime = os.time() * 1000 -- Convert to milliseconds

	-- Hanya ambil donasi sejak poll terakhir
	local url = string.format("%s/api/roblox/donations?since=%d&limit=10", WEBHOOK_API_BASE, lastPollTime)

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		local parseSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)

		if parseSuccess and data.ok then
			print("🔄 Webhook poll berhasil, donasi baru:", #(data.donations or {}))

			-- DEBUG: Print raw donations data
			if #(data.donations or {}) > 0 then
				print("📦 Raw donations data:")
				for i, donation in ipairs(data.donations or {}) do
					print(string.format("  [%d] ID: %s", i, donation.id or "nil"))
					print(string.format("  [%d] Donor: %s", i, donation.donor or "nil"))
					print(string.format("  [%d] Amount: %s", i, tostring(donation.amount or "nil")))
					print(string.format("  [%d] Message: %s", i, donation.message or "nil"))
					print(string.format("  [%d] MatchedUsername: %s", i, donation.matchedUsername or "nil"))
					print("  ---")
				end
			end

			for _, donation in ipairs(data.donations or {}) do
				-- Cek apakah donasi sudah diproses
				if not processedDonations[donation.id] then
					processedDonations[donation.id] = true

					-- Format data untuk notifikasi
					local notificationData = {
						donor = donation.donor,
						amount = donation.amount,
						message = donation.message,
						robloxUsername = donation.matchedUsername,
						timestamp = donation.ts
					}

					print(string.format("🎉 Donasi baru: %s donated %d | Roblox: %s", 
						donation.donor, 
						donation.amount, 
						donation.matchedUsername or "Tidak diketahui"
						))

					-- Kirim notifikasi ke semua client (Live Donation Board)
					RealtimeDonation:FireAllClients(notificationData)
					
					-- 🎉 TRIGGER POPUP NOTIFICATION (SAWERIA/BAGIBAGI)
					if donation.matchedUsername then
						print("🔔 [POPUP] Starting popup notification process...")
						print("🔔 [POPUP] Matched username:", donation.matchedUsername)
						
						-- Get display name and userId for notification
						local displayName, userId = getPlayerInfo(donation.matchedUsername)
						print("🔔 [POPUP] Display name:", displayName, "| UserId:", userId)
						
						local popupData = {
							donatorName = donation.matchedUsername, -- Username
							donatorDisplayName = displayName or donation.matchedUsername, -- Display name
							donatorId = userId, -- For avatar
							amount = donation.amount,
							customMessage = donation.message or "No message",
							currencyType = "IDR" -- 🆕 Rupiah currency
						}
						
						print("🔔 [POPUP] Popup data prepared:", HttpService:JSONEncode(popupData))
						print("🎉 [POPUP NOTIF] Triggering Saweria notification popup for:", displayName, "(", donation.matchedUsername, ")")
						print("🔔 [POPUP] Firing ShowSaweriaDonationNotif to all clients...")
						ShowSaweriaDonationNotif:FireAllClients(popupData)
						print("🔔 [POPUP] ShowSaweriaDonationNotif fired successfully!")
					else
						-- No matched username, show generic notification
						local popupData = {
							donatorName = donation.donor or "Anonymous",
							donatorDisplayName = donation.donor or "Anonymous",
							donatorId = nil, -- No userId available
							amount = donation.amount,
							customMessage = donation.message or "No message",
							currencyType = "IDR" -- 🆕 Rupiah currency
						}
						
						print("🎉 [POPUP NOTIF] Triggering generic Saweria notification for:", donation.donor)
						ShowSaweriaDonationNotif:FireAllClients(popupData)
					end
					
					-- 🔄 IMMEDIATE UPDATE: Invalidate cache (but KEEP DataStore for historical data)
					if donation.matchedUsername then
						print("🔄 [CACHE] ========== CACHE INVALIDATION ==========")
						print("🔄 [CACHE] Before - lastTopSpendersUpdate:", lastTopSpendersUpdate)
						print("🔄 [CACHE] Before - cachedTopSpenders count:", #cachedTopSpenders)
						print("🔄 [CACHE] Invalidating cache for user:", donation.matchedUsername)
						
						-- Force cache to expire immediately
						lastTopSpendersUpdate = 0
						
						-- Clear memory cache to force fresh fetch on next request
						cachedTopSpenders = {}
						
						-- ⚠️ IMPORTANT: Do NOT clear DataStore! Keep historical data!
						-- Only invalidate memory cache, API will be fetched on next refresh
						
						print("🔄 [CACHE] After - lastTopSpendersUpdate:", lastTopSpendersUpdate)
						print("🔄 [CACHE] After - cachedTopSpenders cleared:", #cachedTopSpenders)
						print("🔄 [CACHE] ✅ Memory cache invalidated! DataStore preserved.")
						print("🔄 [CACHE] ⏱️ Client will auto-refresh within 30 seconds...")
						print("🔄 [CACHE] ⏱️ Or type /refreshboard for instant update")
						print("🔄 [CACHE] ========== END ==========")
					end

					-- INTEGRASI DENGAN SAWERIA DONATION EFFECTS
					if donation.matchedUsername then
						print("🎯 [SAWERIA] Attempting to trigger effects for:", donation.matchedUsername)

						-- Wait for SaweriaDonationEffect.luau to load and expose the bridge function
						local maxWait = 50 -- 5 seconds max wait
						local waitCount = 0
						while not _G.TriggerSaweriaDonationEffect and waitCount < maxWait do
							task.wait(0.1)
							waitCount = waitCount + 1
						end

						if _G.TriggerSaweriaDonationEffect then
							local success = _G.TriggerSaweriaDonationEffect(
								donation.donor,
								donation.matchedUsername,
								donation.amount,
								donation.message
							)

							if success then
								print("✅ [SAWERIA] Donation effects triggered successfully!")
							else
								print("⚠️ [SAWERIA] Donation effects failed or amount too small")
							end
						else
							warn("❌ [SAWERIA] SaweriaDonationEffect bridge function not available")
						end
					else
						print("ℹ️ [SAWERIA] Donasi tanpa matched username, hanya notifikasi umum")
					end
				end
			end

			-- Update last poll time
			lastPollTime = currentTime
		else
			warn("❌ Gagal parse response webhook API:", response)
		end
	else
		warn("❌ Gagal polling webhook API:", response)
	end
end

-- Function untuk mendapatkan semua donasi untuk username tertentu
local function getDonationsForPlayer(robloxUsername)
	local url = string.format("%s/api/roblox/donations?username=%s&limit=50", 
		WEBHOOK_API_BASE, 
		HttpService:UrlEncode(robloxUsername)
	)

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		local parseSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)

		if parseSuccess and data.ok then
			return data.donations or {}
		end
	end

	return {}
end

-- RemoteFunction untuk client request donations
local GetPlayerDonations = Instance.new("RemoteFunction")
GetPlayerDonations.Name = "GetPlayerDonations"
GetPlayerDonations.Parent = ReplicatedStorage

GetPlayerDonations.OnServerInvoke = function(player, targetUsername)
	-- Gunakan player.Name jika tidak ada targetUsername
	local username = targetUsername or player.Name
	return getDonationsForPlayer(username)
end

-- Function untuk fetch top spenders dari API
local function fetchTopSpendersFromAPI(limit)
	limit = limit or 10
	local url = string.format("%s/api/roblox/top-spenders?limit=%d", 
		WEBHOOK_API_BASE, 
		limit
	)

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		local parseSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)

		if parseSuccess and data.ok then
			print("✅ Fetched", #(data.topSpenders or {}), "top spenders from API")
			return data.topSpenders or {}
		else
			warn("❌ Failed to parse top spenders response")
		end
	else
		warn("❌ Failed to fetch top spenders from API:", response)
	end

	return {}
end

-- Function untuk merge top spenders data (API + DataStore)
local function mergeTopSpendersData(apiData, datastoreData)
	local merged = {}
	local userMap = {}
	local apiUsernames = {}
	
	-- Track which usernames exist in API
	for _, spender in ipairs(apiData) do
		if spender.username then
			apiUsernames[spender.username] = true
		end
	end
	
	-- Add data dari DataStore (preserve historical data)
	-- ONLY if username masih exists di API atau amount lebih besar
	for _, spender in ipairs(datastoreData) do
		if spender.username and spender.totalAmount then
			-- Keep if exists in API OR if API has no data yet
			if apiUsernames[spender.username] or #apiData == 0 then
				userMap[spender.username] = spender.totalAmount
			else
				print("🗑️ [MERGE] Removing stale entry:", spender.username, "(not in API)")
			end
		end
	end
	
	-- Merge dengan data dari API
	for _, spender in ipairs(apiData) do
		if spender.username and spender.totalAmount then
			local existing = userMap[spender.username] or 0
			
			-- ⚠️ TEMPORARY FIX: If API doesn't accumulate, we take max
			-- TODO: Backend should return accumulated totalAmount!
			-- For now, trust API value (assume it's accumulated)
			local newAmount = spender.totalAmount
			
			-- If DataStore has higher value, keep it (data integrity)
			if existing > newAmount then
				print("⚠️ [MERGE]", spender.username, "- DataStore has higher value:", existing, "(API:", newAmount .. ")")
				newAmount = existing
			end
			
			userMap[spender.username] = newAmount
		end
	end
	
	-- Convert back to array
	for username, totalAmount in pairs(userMap) do
		table.insert(merged, {
			username = username,
			totalAmount = totalAmount
		})
	end
	
	-- Sort by totalAmount descending
	table.sort(merged, function(a, b)
		return a.totalAmount > b.totalAmount
	end)
	
	return merged
end

-- Function untuk update top spenders cache
local function updateTopSpendersCache()
	print("🔄 Updating top spenders cache...")
	
	-- Fetch dari API
	local apiData = fetchTopSpendersFromAPI(50) -- Ambil top 50
	
	-- Load data yang ada di DataStore
	local datastoreData = cachedTopSpenders or {}
	
	-- MERGE data (jangan overwrite!)
	local mergedData = mergeTopSpendersData(apiData, datastoreData)
	
	if #mergedData > 0 then
		print("📊 Merged data sample:")
		for i = 1, math.min(3, #mergedData) do
			local spender = mergedData[i]
			print(string.format("  [%d] %s - %d", i, spender.username or "nil", spender.totalAmount or 0))
		end
		
		-- Update cache di memory
		cachedTopSpenders = mergedData
		lastTopSpendersUpdate = os.time()
		
		-- Save ke DataStore (PERSISTENT!)
		local success, err = pcall(function()
			TopSpendersStore:SetAsync("CurrentTopSpenders", {
				data = mergedData,
				timestamp = lastTopSpendersUpdate
			})
		end)
		
		if success then
			print("✅ Top spenders cache updated:", #mergedData, "entries (saved to DataStore)")
		else
			warn("⚠️ Failed to save to DataStore:", err)
		end
	else
		warn("⚠️ No top spenders data received from API")
	end
end

-- Function untuk load top spenders cache dari DataStore
local function loadTopSpendersCacheFromDataStore()
	print("📦 Loading top spenders from DataStore...")
	
	local success, result = pcall(function()
		return TopSpendersStore:GetAsync("CurrentTopSpenders")
	end)
	
	if success and result then
		cachedTopSpenders = result.data or {}
		lastTopSpendersUpdate = result.timestamp or 0
		print("✅ Loaded", #cachedTopSpenders, "top spenders from DataStore")
		return true
	else
		warn("⚠️ No cached data in DataStore, will fetch from API")
		return false
	end
end

-- Function untuk get top spenders (dari cache)
local function getTopSpenders(limit)
	limit = limit or 10
	
	-- Return dari cache
	local result = {}
	for i = 1, math.min(limit, #cachedTopSpenders) do
		table.insert(result, cachedTopSpenders[i])
	end
	
	return result
end

-- RemoteFunction untuk client request top spenders
local GetTopSpenders = Instance.new("RemoteFunction")
GetTopSpenders.Name = "GetTopSpenders"
GetTopSpenders.Parent = ReplicatedStorage

GetTopSpenders.OnServerInvoke = function(player, limit, forceRefresh)
	limit = limit or 10
	forceRefresh = forceRefresh or false
	
	-- ALWAYS check cache age setiap request
	local currentTime = os.time()
	local cacheAge = currentTime - lastTopSpendersUpdate
	
	print(string.format("📊 Cache age: %d seconds (max: %d) | Force refresh: %s", 
		cacheAge, TOP_SPENDERS_CACHE_MAX_AGE, tostring(forceRefresh)))
	
	-- Fetch new data jika cache expired, kosong, atau force refresh
	if forceRefresh or #cachedTopSpenders == 0 or cacheAge > TOP_SPENDERS_CACHE_MAX_AGE then
		print(string.format("⚠️ %s, fetching fresh data...", 
			forceRefresh and "Force refresh requested" or
			(#cachedTopSpenders == 0 and "Cache empty" or "Cache expired")))
		updateTopSpendersCache()
	else
		print(string.format("✅ Using cached data (%d entries, %d seconds old)", 
			#cachedTopSpenders, cacheAge))
	end
	
	return getTopSpenders(limit)
end

-- Initialize top spenders cache saat server start
spawn(function()
	print("📊 Initializing top spenders cache...")
	print("🔍 DataStore = Source of Truth (data will be preserved across server restarts)")
	
	-- ALWAYS load dari DataStore dulu (preserve historical data)
	local loaded = loadTopSpendersCacheFromDataStore()
	
	if loaded and #cachedTopSpenders > 0 then
		print("✅ Loaded", #cachedTopSpenders, "entries from DataStore (preserved data)")
		print("🔄 Will merge with API data on next update...")
	else
		print("⚠️ No DataStore cache found, will fetch from API and create new cache")
	end
	
	-- Kemudian fetch dari API dan MERGE (bukan replace!)
	task.wait(2) -- Wait 2 detik sebelum first API call
	updateTopSpendersCache()
end)

-- Background loop untuk update top spenders cache setiap interval
spawn(function()
	task.wait(10) -- Wait 10 detik sebelum mulai loop
	
	print("🔄 Starting top spenders auto-refresh loop (every", TOP_SPENDERS_REFRESH_INTERVAL, "seconds)")
	
	while true do
		task.wait(TOP_SPENDERS_REFRESH_INTERVAL)
		updateTopSpendersCache()
	end
end)

-- Main polling loop
spawn(function()
	print("🚀 Webhook integration dimulai!")
	print("📡 API Base:", WEBHOOK_API_BASE)
	print("⏱️ Poll interval:", POLL_INTERVAL, "detik")

	-- Set initial poll time ke sekarang
	lastPollTime = os.time() * 1000

	while true do
		pollRealtimeDonations()
		task.wait(POLL_INTERVAL)
	end
end)

-- Cleanup processed donations setiap 10 menit untuk mencegah memory leak
spawn(function()
	while true do
		task.wait(600) -- 10 menit

		local currentTime = os.time() * 1000
		local cutoffTime = currentTime - (30 * 60 * 1000) -- 30 menit yang lalu

		local cleaned = 0
		for donationId, _ in pairs(processedDonations) do
			-- Asumsi donation ID mengandung timestamp
			local idTimestamp = tonumber(string.match(donationId, "^(%d+)"))
			if idTimestamp and idTimestamp < cutoffTime then
				processedDonations[donationId] = nil
				cleaned = cleaned + 1
			end
		end

		if cleaned > 0 then
			print("🧹 Cleaned", cleaned, "old donation records")
		end
	end
end)
