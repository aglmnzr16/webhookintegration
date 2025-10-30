--[[
═══════════════════════════════════════════════════════════════════════════════
  ROBUX DONATION EFFECTS - Visual & Audio Effects
═══════════════════════════════════════════════════════════════════════════════

SYSTEM: In-Game Robux Donations
TYPE: Server Script (ServerScriptService)
CURRENCY: Robux (R$)

PURPOSE:
  - Trigger visual and audio effects for Robux donations
  - Level-based effects (6 levels based on amount)
  - Particle effects, sounds, lights
  - Special JPass effects for specific amounts

EFFECT LEVELS:
  Level 0: < R$ 100 (No effects)
  Level 1: R$ 100-199
  Level 2: R$ 200-499
  Level 3: R$ 500-999
  Level 4: R$ 1,000-4,999
  Level 5: R$ 5,000-9,999
  Level 6: R$ 10,000+

SPECIAL EFFECTS:
  R$ 500: Fire Nuke
  R$ 1,000: Fire Nuke
  R$ 2,000: Mega Giant (FireSmite4)
  R$ 5,000: Nature Effect (FireSmite3)
  R$ 10,000: BlackHole

TRIGGERED BY:
  - DonationNew.luau via _G.TriggerRobuxDonationEffect

DEPENDENCIES:
  Services:
    - Players
    - ServerStorage (EffectsCharacter folder)
    - SoundService
    - ReplicatedStorage (JPass for special effects)

  Required Folders:
    ServerStorage/EffectsCharacter/
    ├── Sound/
    │   ├── DonationLevel1
    │   ├── DonationLevel2
    │   └── ... (up to Level6)
    └── VFX/
        ├── Level1 (Part with ParticleEmitters)
        ├── Level2
        └── ... (up to Level6)

═══════════════════════════════════════════════════════════════════════════════
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

-- DataStore for purchase history
local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

-- Track active effects to prevent overlaps
local activeEffects = {}

-- RemoteEvent for notifications
local donationNotif = ReplicatedStorage:WaitForChild("DonationNotif")

-- JPass Events for special effects
local JPass = require(ReplicatedStorage.JamStudio.UpdateLoader.JPass)
local FireSmite3 = JPass.Event("FireSmite3")
local FireSmite4 = JPass.Event("FireSmite4")
local FireNuke = JPass.Event("FireNuke")
local FireBlackHole = JPass.Event("FireBlackHole")

-- Developer Products Configuration
local DEVELOPER_PRODUCTS = {
	[3438213239] = {name = "100 Robux Donation", price = 100, level = 1, effectType = ""},
	[3438213399] = {name = "200 Robux Donation", price = 200, level = 2, effectType = ""},
	[3438213537] = {name = "500 Robux Donation", price = 500, level = 3, effectType = ""},
	[3438213683] = {name = "1000 Robux Donation", price = 1000, level = 4, effectType = ""},
	[3438213834] = {name = "2000 Robux Donation", price = 2000, level = 4, effectType = ""},
	[3438213970] = {name = "5000 Robux Donation", price = 5000, level = 5, effectType = ""},
	[3438214109] = {name = "10000 Robux Donation", price = 10000, level = 6, effectType = ""},
}

--═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
--═══════════════════════════════════════════════════════════════════════════

-- Determine donation level based on Robux amount
local function getDonationLevel(robuxAmount)
	if robuxAmount >= 10000 then
		return 6
	elseif robuxAmount >= 5000 then
		return 5
	elseif robuxAmount >= 1000 then
		return 4
	elseif robuxAmount >= 500 then
		return 3
	elseif robuxAmount >= 200 then
		return 2
	elseif robuxAmount >= 100 then
		return 1
	else
		return 0
	end
end

-- Play level-based sound effect (looped for duration)
local function playLevelSound(level, duration)
	local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
	if not effectsFolder then
		warn("[ROBUX EFFECT] EffectsCharacter folder not found!")
		return nil
	end

	local soundFolder = effectsFolder:FindFirstChild("Sound")
	if not soundFolder then
		warn("[ROBUX EFFECT] Sound folder not found!")
		return nil
	end

	local soundName = "DonationLevel" .. tostring(level)
	local soundEffect = soundFolder:FindFirstChild(soundName)

	if soundEffect and soundEffect:IsA("Sound") then
		local soundClone = soundEffect:Clone()
		soundClone.Parent = SoundService
		soundClone.Looped = true
		soundClone:Play()

		print(`[ROBUX EFFECT] Playing level {level} sound (looped for {duration}s)`)
		return soundClone
	else
		warn(`[ROBUX EFFECT] Sound {soundName} not found!`)
		return nil
	end
end

-- Apply level-based visual effects to character
local function applyLevelVFX(character, level, duration)
	local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
	if not effectsFolder then
		warn("[ROBUX EFFECT] EffectsCharacter folder not found!")
		return {}
	end

	local vfxFolder = effectsFolder:FindFirstChild("VFX")
	if not vfxFolder then
		warn("[ROBUX EFFECT] VFX folder not found!")
		return {}
	end

	local levelName = "Level" .. tostring(level)
	local levelPart = vfxFolder:FindFirstChild(levelName)

	if not levelPart or not levelPart:IsA("BasePart") then
		warn(`[ROBUX EFFECT] Level {level} VFX part not found!`)
		return {}
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("[ROBUX EFFECT] HumanoidRootPart not found!")
		return {}
	end

	local appliedEffects = {}

	-- Clone and apply all effects from the Part
	for _, effect in ipairs(levelPart:GetChildren()) do
		task.wait(0.05)

		if effect:IsA("ParticleEmitter") then
			local effectClone = effect:Clone()
			effectClone.Name = "RobuxEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true
			effectClone.Rate = effectClone.Rate > 0 and effectClone.Rate or 20
			effectClone.Parent = hrp

			task.wait()
			effectClone.Enabled = true

			table.insert(appliedEffects, effectClone)
			print(`[ROBUX EFFECT] Applied ParticleEmitter: {effect.Name}`)

		elseif effect:IsA("Beam") then
			local effectClone = effect:Clone()
			effectClone.Name = "RobuxEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true

			local attachment0 = Instance.new("Attachment")
			attachment0.Name = "RobuxBeamAttachment0"
			attachment0.Position = Vector3.new(0, 0, 0)
			attachment0.Parent = hrp

			local attachment1 = Instance.new("Attachment")
			attachment1.Name = "RobuxBeamAttachment1"
			attachment1.Position = Vector3.new(0, 5, 0)
			attachment1.Parent = hrp

			effectClone.Attachment0 = attachment0
			effectClone.Attachment1 = attachment1
			effectClone.Parent = hrp

			table.insert(appliedEffects, attachment0)
			table.insert(appliedEffects, attachment1)
			table.insert(appliedEffects, effectClone)
			print(`[ROBUX EFFECT] Applied Beam: {effect.Name}`)

		elseif effect:IsA("PointLight") or effect:IsA("SpotLight") then
			local effectClone = effect:Clone()
			effectClone.Name = "RobuxEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true
			effectClone.Parent = hrp
			table.insert(appliedEffects, effectClone)
			print(`[ROBUX EFFECT] Applied Light: {effect.Name}`)

		elseif effect:IsA("Attachment") then
			local attachmentClone = effect:Clone()
			attachmentClone.Name = "RobuxEffect_Level" .. level .. "_" .. effect.Name
			attachmentClone.Parent = hrp

			for _, child in ipairs(attachmentClone:GetChildren()) do
				if child:IsA("ParticleEmitter") then
					child.Enabled = true
					task.wait()
					child.Enabled = true
				end
			end

			table.insert(appliedEffects, attachmentClone)
			print(`[ROBUX EFFECT] Applied Attachment: {effect.Name}`)
		end
	end

	-- Final enable check
	task.wait(0.1)
	for _, effect in ipairs(appliedEffects) do
		if effect:IsA("ParticleEmitter") and effect.Parent then
			effect.Enabled = true
		end
	end

	print(`[ROBUX EFFECT] Applied {#appliedEffects} VFX effects from Level {level}`)
	return appliedEffects
end

--═══════════════════════════════════════════════════════════════════════════
-- MAIN EFFECT TRIGGER FUNCTION
--═══════════════════════════════════════════════════════════════════════════

local function TriggerRobuxEffects(donatorPlayer, recipientPlayer, donationAmount)
	if activeEffects[recipientPlayer.UserId] then
		print("[ROBUX EFFECT] Effects already active, skipping...")
		return
	end
	activeEffects[recipientPlayer.UserId] = true

	local character = recipientPlayer.Character
	if not character then
		print("[ROBUX EFFECT] Waiting for character...")
		character = recipientPlayer.CharacterAdded:Wait()
		task.wait(0.5)
	end

	if not character or not character.Parent then
		warn("[ROBUX EFFECT] Character invalid!")
		activeEffects[recipientPlayer.UserId] = nil
		return
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("[ROBUX EFFECT] HumanoidRootPart not found!")
		activeEffects[recipientPlayer.UserId] = nil
		return
	end

	-- Get donation level
	local donationLevel = getDonationLevel(donationAmount)

	if donationLevel > 0 then
		print(`[ROBUX EFFECT] Triggering Level {donationLevel} effects for R$ {donationAmount}`)

		-- Calculate duration
		local effectDuration = 10
		if donationLevel >= 5 then
			effectDuration = 20
		elseif donationLevel >= 3 then
			effectDuration = 15
		end

		-- Play sound
		local soundInstance = nil
		task.spawn(function()
			soundInstance = playLevelSound(donationLevel, effectDuration)
		end)

		-- Apply VFX
		task.wait(0.2)
		local appliedEffects = applyLevelVFX(character, donationLevel, effectDuration)

		-- Retry if failed
		if #appliedEffects == 0 then
			print("[ROBUX EFFECT] No effects applied, retrying...")
			task.wait(0.5)
			appliedEffects = applyLevelVFX(character, donationLevel, effectDuration)
		end

		-- Cleanup after duration
		task.delay(effectDuration, function()
			-- Stop sound
			if soundInstance and soundInstance.Parent then
				soundInstance:Stop()
				soundInstance:Destroy()
				print(`[ROBUX EFFECT] Level {donationLevel} sound stopped`)
			end

			-- Clean VFX
			for _, effect in ipairs(appliedEffects) do
				if effect and effect.Parent then
					if effect:IsA("ParticleEmitter") then
						effect.Enabled = false
					elseif effect:IsA("Attachment") then
						for _, child in ipairs(effect:GetChildren()) do
							if child:IsA("ParticleEmitter") then
								child.Enabled = false
							end
						end
					end

					task.wait(1)
					if effect.Parent then
						effect:Destroy()
					end
				end
			end

			activeEffects[recipientPlayer.UserId] = nil
			print(`[ROBUX EFFECT] Level {donationLevel} effects cleaned up`)
		end)
	else
		-- No level effects for donations under 100
		activeEffects[recipientPlayer.UserId] = nil
	end

	-- ==================== SPECIAL EFFECTS FOR HIGH AMOUNTS ====================
	-- Keep existing special effects for backwards compatibility
	if donationAmount == 500 then
		print("[ROBUX EFFECT] Triggering Fire Nuke for R$ 500!")
		FireNuke:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(90, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return -- Exit early to prevent overlap
	end

	if donationAmount == 1000 then
		print("[ROBUX EFFECT] Triggering Fire Nuke for R$ 1000!")
		FireNuke:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(90, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return
	end

	if donationAmount == 2000 then
		print("[ROBUX EFFECT] Triggering Mega Giant (FireSmite4) for R$ 2000!")
		FireSmite4:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(90, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return
	end

	if donationAmount == 5000 then
		print("[ROBUX EFFECT] Triggering Nature Effect (FireSmite3) for R$ 5000!")
		FireSmite3:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(90, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return
	end

	if donationAmount == 10000 then
		print("[ROBUX EFFECT] Triggering BlackHole for R$ 10000!")
		FireBlackHole:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(120, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return
	end

	-- Reset activeEffects after standard effects
	task.delay(1, function()
		activeEffects[recipientPlayer.UserId] = nil
	end)
end

--═══════════════════════════════════════════════════════════════════════════
-- PUBLIC BRIDGE FUNCTION (Called by DonationNew)
--═══════════════════════════════════════════════════════════════════════════

function TriggerRobuxDonationEffect(donatorPlayer, recipientPlayer, robuxAmount)
	print(string.format("[ROBUX EFFECT] Processing: %s → %s | R$ %d", 
		donatorPlayer.Name, recipientPlayer.Name, robuxAmount))

	TriggerRobuxEffects(donatorPlayer, recipientPlayer, robuxAmount)

	print(string.format("[ROBUX EFFECT] ✅ Effects triggered for %s (R$ %d)", 
		recipientPlayer.Name, robuxAmount))
	return true
end

--═══════════════════════════════════════════════════════════════════════════
-- PROCESS RECEIPT (MarketplaceService Integration)
--═══════════════════════════════════════════════════════════════════════════

local function MyProcessReceipt(receiptInfo)
	print("[ROBUX EFFECT] Developer Product purchased!")
	print("[ROBUX EFFECT] Product ID:", receiptInfo.ProductId)
	print("[ROBUX EFFECT] Player ID:", receiptInfo.PlayerId)
	print("[ROBUX EFFECT] Purchase ID:", receiptInfo.PurchaseId)

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		warn("[ROBUX EFFECT] Player not found!")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Anti-duplikasi check
	local purchaseKey = tostring(receiptInfo.PlayerId) .. "_" .. tostring(receiptInfo.PurchaseId)
	local success, alreadyProcessed = pcall(function()
		return purchaseHistoryStore:GetAsync(purchaseKey)
	end)

	if success and alreadyProcessed then
		print("[ROBUX EFFECT] Purchase already processed, skipping.")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Cek Product ID
	local productInfo = DEVELOPER_PRODUCTS[receiptInfo.ProductId]
	if not productInfo then
		print("[ROBUX EFFECT] Unknown Product ID, letting other scripts handle it:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("[ROBUX EFFECT] Product found:", productInfo.name, "- Price:", productInfo.price, "- Level:", productInfo.level or getDonationLevel(productInfo.price))

	-- Target recipient (default: buyer gets the effect)
	local recipientPlayer = player

	-- Trigger donation effects
	TriggerRobuxEffects(player, recipientPlayer, productInfo.price)

	-- Send notification to all clients
	if donationNotif then
		donationNotif:FireAllClients(player.Name, recipientPlayer.Name, productInfo.price)
	end

	-- Save to DataStore
	local saveSuccess = pcall(function()
		purchaseHistoryStore:SetAsync(purchaseKey, {
			processed = true,
			timestamp = os.time(),
			productId = receiptInfo.ProductId,
			price = productInfo.price,
			level = productInfo.level or getDonationLevel(productInfo.price),
			buyer = player.Name,
			recipient = recipientPlayer.Name
		})
	end)

	if not saveSuccess then
		warn("[ROBUX EFFECT] Failed to save purchase history!")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print(`[ROBUX EFFECT] Purchase processed successfully! {productInfo.price} R$ (Level {productInfo.level or getDonationLevel(productInfo.price)}) from {player.Name}`)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

--═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
--═══════════════════════════════════════════════════════════════════════════

-- Expose function for DonationNew
_G.TriggerRobuxDonationEffect = TriggerRobuxDonationEffect

-- Register ProcessReceipt with Donation Board V3 system
task.wait(1)

if shared.MarketplaceService then
	print("[ROBUX EFFECT] Registering with Donation Board V3 shared system...")
	shared.MarketplaceService.ProcessReceipt = MyProcessReceipt
	print("[ROBUX EFFECT] Successfully registered with Donation Board V3!")
else
	print("[ROBUX EFFECT] Donation Board V3 not found, using direct MarketplaceService...")
	MarketplaceService.ProcessReceipt = MyProcessReceipt
end

print("[ROBUX EFFECT] ✅ Robux donation effects system loaded!")
print("[ROBUX EFFECT] ✅ ProcessReceipt handler registered!")

-- Check required folders
print("[ROBUX EFFECT] Checking required folders...")
local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
if effectsFolder then
	print("[ROBUX EFFECT] ✅ EffectsCharacter folder found!")
	
	local soundFolder = effectsFolder:FindFirstChild("Sound")
	if soundFolder then
		print(`[ROBUX EFFECT] Found {#soundFolder:GetChildren()} sound effects`)
	else
		warn("[ROBUX EFFECT] ❌ Sound folder NOT FOUND!")
	end
	
	local vfxFolder = effectsFolder:FindFirstChild("VFX")
	if vfxFolder then
		print(`[ROBUX EFFECT] Found {#vfxFolder:GetChildren()} VFX levels`)
	else
		warn("[ROBUX EFFECT] ❌ VFX folder NOT FOUND!")
	end
else
	warn("[ROBUX EFFECT] ❌ EffectsCharacter folder NOT FOUND in ServerStorage!")
end
