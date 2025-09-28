-- BagiBagi Donation Display Script for Roblox
-- Place this in ServerScriptService as a ServerScript

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Configuration
local API_BASE = "https://your-deployed-app.vercel.app" -- Replace with your deployed URL
local POLL_INTERVAL = 5 -- seconds

-- Per-player tracking
local playerLastTs = {}

-- Function to show donation notification (customize this for your game)
local function showDonationNotification(player, donation)
    print(string.format("[DONATION] %s donated %d to %s | Message: %s", 
        donation.donor, 
        donation.amount, 
        player.Name, 
        donation.message or "No message"
    ))
    
    -- TODO: Replace with your custom UI/notification system
    -- Examples:
    -- - Create a GUI notification
    -- - Play a sound effect
    -- - Show particle effects
    -- - Display in chat
end

-- Function to fetch donations for a specific player
local function fetchDonationsForPlayer(player)
    local username = player.Name
    local lastTs = playerLastTs[player.UserId] or 0
    
    local url = string.format("%s/api/roblox/donations?username=%s&since=%d", 
        API_BASE, 
        HttpService:UrlEncode(username), 
        lastTs
    )
    
    local success, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    
    if not success then
        warn("Failed to fetch donations for " .. username .. ":", response)
        return
    end
    
    local data = HttpService:JSONDecode(response)
    if not data or not data.ok then
        return
    end
    
    -- Process new donations
    for _, donation in ipairs(data.donations or {}) do
        showDonationNotification(player, donation)
        
        -- Update last timestamp
        if donation.ts and donation.ts > lastTs then
            playerLastTs[player.UserId] = donation.ts
        end
    end
end

-- Function to poll donations for all players
local function pollAllDonations()
    for _, player in pairs(Players:GetPlayers()) do
        fetchDonationsForPlayer(player)
    end
end

-- Initialize tracking for new players
Players.PlayerAdded:Connect(function(player)
    playerLastTs[player.UserId] = os.time() * 1000 -- Start from current time
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    playerLastTs[player.UserId] = nil
end)

-- Main polling loop
spawn(function()
    while true do
        pollAllDonations()
        wait(POLL_INTERVAL)
    end
end)

print("BagiBagi donation system initialized!")
print("API Base:", API_BASE)
print("Poll Interval:", POLL_INTERVAL, "seconds")
