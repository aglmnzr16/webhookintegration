--[[
═══════════════════════════════════════════════════════════════════════════════
  DONATION SYSTEM CONFIGURATION
═══════════════════════════════════════════════════════════════════════════════

PURPOSE:
  - Central configuration for donation platforms (BagiBagi & Saweria)
  - Enable/disable platforms individually
  - Control which boards are active in the game
  - Easy toggle untuk testing atau deployment

USAGE:
  local DonationConfig = require(ServerStorage.DonationConfig)
  
  if DonationConfig.BagiBagi.Enabled then
      -- Initialize BagiBagi system
  end
  
  if DonationConfig.Saweria.Enabled then
      -- Initialize Saweria system
  end

DEPLOYMENT:
  - Production: Enable both platforms
  - Testing: Enable only one platform for isolated testing
  - Maintenance: Disable all platforms

═══════════════════════════════════════════════════════════════════════════════
]]--

local Config = {}

--═══════════════════════════════════════════════════════════════════════════
-- PLATFORM CONFIGURATION
--═══════════════════════════════════════════════════════════════════════════

Config.BagiBagi = {
	-- Enable/disable BagiBagi donation platform
	Enabled = true,  -- ✅ SET TO true TO ENABLE BAGIBAGI
	
	-- Board configuration
	Board = {
		WorkspacePath = "BagibagiBoard",  -- Workspace.BagibagiBoard
		LiveDonationEnabled = true,        -- Show live donation feed
		TopBoardEnabled = true,            -- Show top spenders leaderboard
	},
	
	-- API configuration
	API = {
		PollInterval = 5,                  -- Poll every 5 seconds for live donations
		TopBoardRefresh = 30,              -- Refresh top board every 30 seconds
		Endpoint = "/api/roblox/donations?source=bagibagi",
		TopSpendersEndpoint = "/api/roblox/top-spenders?source=bagibagi",
	},
	
	-- Notification configuration
	Notifications = {
		Enabled = true,                    -- Show popup notifications
		ScriptName = "RupiahNotification", -- Client script name
	},
	
	-- Effects configuration
	Effects = {
		Enabled = true,                    -- Trigger visual effects
		ScriptName = "SaweriaDonationEffect",  -- Server script name (reused for BagiBagi)
	},
}

Config.Saweria = {
	-- Enable/disable Saweria donation platform
	Enabled = true,  -- ✅ SET TO true TO ENABLE SAWERIA
	
	-- Board configuration
	Board = {
		WorkspacePath = "SaweriaBoard",    -- Workspace.SaweriaBoard
		LiveDonationEnabled = true,        -- Show live donation feed
		TopBoardEnabled = true,            -- Show top spenders leaderboard
	},
	
	-- API configuration
	API = {
		PollInterval = 5,                  -- Poll every 5 seconds for live donations
		TopBoardRefresh = 30,              -- Refresh top board every 30 seconds
		Endpoint = "/api/roblox/donations?source=saweria",
		TopSpendersEndpoint = "/api/roblox/top-spenders?source=saweria",
	},
	
	-- Notification configuration
	Notifications = {
		Enabled = true,                    -- Show popup notifications
		ScriptName = "SaweriaNotification", -- Client script name
	},
	
	-- Effects configuration
	Effects = {
		Enabled = true,                    -- Trigger visual effects
		ScriptName = "SaweriaDonationEffect", -- Server script name
		BlackHoleAmount = 1000000,         -- Rp. 1,000,000 triggers BlackHole
	},
}

--═══════════════════════════════════════════════════════════════════════════
-- GLOBAL CONFIGURATION
--═══════════════════════════════════════════════════════════════════════════

Config.Global = {
	-- API base URL (auto-detect from HttpService or manual override)
	APIBaseURL = nil,  -- nil = auto-detect, or set to "https://your-domain.com"
	
	-- Debug mode (extra console logs)
	DebugMode = false,
	
	-- Minimum donation amount to trigger effects (Rupiah)
	MinEffectAmount = 100000,  -- Rp. 100,000
	
	-- User matching methods (priority order)
	MatchingMethods = {
		"code",         -- #ABC123 code in message
		"username",     -- Direct username match
		"displayname",  -- Display name match
		"auto",         -- Auto-assume donor name = Roblox username
	},
}

--═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
--═══════════════════════════════════════════════════════════════════════════

-- Check if BagiBagi is enabled
function Config:IsBagiBagiEnabled()
	return self.BagiBagi.Enabled == true
end

-- Check if Saweria is enabled
function Config:IsSaweriaEnabled()
	return self.Saweria.Enabled == true
end

-- Check if ANY platform is enabled
function Config:IsAnyPlatformEnabled()
	return self:IsBagiBagiEnabled() or self:IsSaweriaEnabled()
end

-- Get enabled platforms list
function Config:GetEnabledPlatforms()
	local platforms = {}
	if self:IsBagiBagiEnabled() then
		table.insert(platforms, "BagiBagi")
	end
	if self:IsSaweriaEnabled() then
		table.insert(platforms, "Saweria")
	end
	return platforms
end

-- Get platform configuration by name
function Config:GetPlatformConfig(platformName)
	if platformName == "BagiBagi" or platformName == "bagibagi" then
		return self.BagiBagi
	elseif platformName == "Saweria" or platformName == "saweria" then
		return self.Saweria
	else
		return nil
	end
end

-- Print configuration status
function Config:PrintStatus()
	print("🔧 ========== DONATION SYSTEM CONFIGURATION ==========")
	print(string.format("BagiBagi: %s", self:IsBagiBagiEnabled() and "✅ ENABLED" or "❌ DISABLED"))
	print(string.format("Saweria:  %s", self:IsSaweriaEnabled() and "✅ ENABLED" or "❌ DISABLED"))
	print(string.format("Platforms Active: %d", #self:GetEnabledPlatforms()))
	print("🔧 ===================================================")
end

--═══════════════════════════════════════════════════════════════════════════
-- VALIDATION
--═══════════════════════════════════════════════════════════════════════════

-- Validate configuration on load
function Config:Validate()
	local warnings = {}
	
	-- Check if at least one platform is enabled
	if not self:IsAnyPlatformEnabled() then
		table.insert(warnings, "⚠️ No donation platforms enabled! Set BagiBagi.Enabled or Saweria.Enabled to true")
	end
	
	-- Check BagiBagi board exists if enabled
	if self:IsBagiBagiEnabled() then
		local board = workspace:FindFirstChild(self.BagiBagi.Board.WorkspacePath)
		if not board then
			table.insert(warnings, string.format("⚠️ BagiBagi board not found: Workspace.%s", self.BagiBagi.Board.WorkspacePath))
		end
	end
	
	-- Check Saweria board exists if enabled
	if self:IsSaweriaEnabled() then
		local board = workspace:FindFirstChild(self.Saweria.Board.WorkspacePath)
		if not board then
			table.insert(warnings, string.format("⚠️ Saweria board not found: Workspace.%s", self.Saweria.Board.WorkspacePath))
		end
	end
	
	-- Print warnings
	if #warnings > 0 then
		warn("🔧 DONATION CONFIG WARNINGS:")
		for _, warning in ipairs(warnings) do
			warn(warning)
		end
	else
		print("✅ Donation configuration validated successfully!")
	end
	
	return #warnings == 0
end

--═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
--═══════════════════════════════════════════════════════════════════════════

-- Auto-validate on require
task.defer(function()
	Config:PrintStatus()
	Config:Validate()
end)

return Config
