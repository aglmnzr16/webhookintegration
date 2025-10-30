-- DONATION EFFECT REAL WITH LEVEL SYSTEM

-- ✅ Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local SoundService = game:GetService("SoundService")

-- ✅ DataStore dan Variables
local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")
local activeEffects = {}

-- ✅ RemoteEvents
local donationNotif = ReplicatedStorage:WaitForChild("DonationNotif")

-- ✅ JPass Events (untuk efek besar)
local JPass = require(ReplicatedStorage.JamStudio.UpdateLoader.JPass)
local FireSmite3 = JPass.Event("FireSmite3")
local FireSmite4 = JPass.Event("FireSmite4")
local FireNuke = JPass.Event("FireNuke")
local FireBlackHole = JPass.Event("FireBlackHole")

-- ✅ Developer Products Configuration with Levels
local DEVELOPER_PRODUCTS = {
	[3438213239] = {name = "100 Robux Donation", price = 100, level = 1, effectType = ""},
	[3438213399] = {name = "200 Robux Donation", price = 200, level = 2, effectType = ""},
	[3438213537] = {name = "500 Robux Donation", price = 500, level = 3, effectType = ""},
	[3438213683] = {name = "1000 Robux Donation", price = 1000, level = 4, effectType = ""},
	[3438213834] = {name = "2000 Robux Donation", price = 2000, level = 4, effectType = ""},
	[3438213970] = {name = "5000 Robux Donation", price = 5000, level = 5, effectType = ""},
	[3438214109] = {name = "10000 Robux Donation", price = 10000, level = 6, effectType = ""},
}

-- ✅ Function to determine donation level based on amount
local function getDonationLevel(amount)
	if amount >= 10000 then
		return 6
	elseif amount >= 5000 then
		return 5
	elseif amount >= 1000 then
		return 4
	elseif amount >= 500 then
		return 3
	elseif amount >= 200 then
		return 2
	elseif amount >= 100 then
		return 1
	else
		return 0 -- No level effects for donations under 100
	end
end

-- ✅ Function to play level-based sound effects (returns sound instance for control)
local function playLevelSound(level, duration)
	local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
	if not effectsFolder then
		warn("[SERVER] EffectsCharacter folder not found in ServerStorage!")
		return nil
	end

	local soundFolder = effectsFolder:FindFirstChild("Sound")
	if not soundFolder then
		warn("[SERVER] Sound folder not found!")
		return nil
	end

	local soundName = "DonationLevel" .. tostring(level)
	local soundEffect = soundFolder:FindFirstChild(soundName)

	if soundEffect and soundEffect:IsA("Sound") then
		-- Clone sound to SoundService for global playback
		local soundClone = soundEffect:Clone()
		soundClone.Parent = SoundService
		soundClone.Looped = true -- Make it loop so it plays continuously
		soundClone:Play()

		print(`[SERVER] Playing level {level} sound effect (looped for {duration} seconds)`)

		-- Return the sound instance so we can control it later
		return soundClone
	else
		warn(`[SERVER] Sound effect {soundName} not found!`)
		return nil
	end
end

-- ✅ Function to apply level-based VFX
local function applyLevelVFX(character, level, duration)
	local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
	if not effectsFolder then
		warn("[SERVER] EffectsCharacter folder not found in ServerStorage!")
		return {}
	end

	local vfxFolder = effectsFolder:FindFirstChild("VFX")
	if not vfxFolder then
		warn("[SERVER] VFX folder not found!")
		return {}
	end

	local levelName = "Level" .. tostring(level)
	local levelPart = vfxFolder:FindFirstChild(levelName)

	if not levelPart then
		warn(`[SERVER] Level {level} VFX part not found!`)
		return {}
	end

	-- Check if it's actually a Part
	if not levelPart:IsA("BasePart") then
		warn(`[SERVER] Level {level} is not a Part! It's a {levelPart.ClassName}`)
		return {}
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("[SERVER] HumanoidRootPart not found after 5 seconds!")
		return {}
	end

	local appliedEffects = {}

	-- Clone and apply all effects from inside the Part
	for _, effect in ipairs(levelPart:GetChildren()) do
		-- Small delay between applying each effect untuk menghindari overload
		task.wait(0.05)

		if effect:IsA("ParticleEmitter") then
			local effectClone = effect:Clone()
			effectClone.Name = "DonationEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true

			-- Force refresh rate untuk memastikan particle muncul
			effectClone.Rate = effectClone.Rate > 0 and effectClone.Rate or 20
			effectClone.Parent = hrp

			-- Double check enabled setelah parenting
			task.wait()
			effectClone.Enabled = true

			table.insert(appliedEffects, effectClone)
			print(`[SERVER] Applied ParticleEmitter: {effect.Name} from Level {level} Part`)

		elseif effect:IsA("Beam") then
			local effectClone = effect:Clone()
			effectClone.Name = "DonationEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true

			-- Beam needs attachments
			local attachment0 = Instance.new("Attachment")
			attachment0.Name = "BeamAttachment0"
			attachment0.Position = Vector3.new(0, 0, 0)
			attachment0.Parent = hrp

			local attachment1 = Instance.new("Attachment")
			attachment1.Name = "BeamAttachment1"
			attachment1.Position = Vector3.new(0, 5, 0)
			attachment1.Parent = hrp

			effectClone.Attachment0 = attachment0
			effectClone.Attachment1 = attachment1
			effectClone.Parent = hrp

			table.insert(appliedEffects, attachment0)
			table.insert(appliedEffects, attachment1)
			table.insert(appliedEffects, effectClone)
			print(`[SERVER] Applied Beam: {effect.Name} from Level {level} Part`)

		elseif effect:IsA("PointLight") or effect:IsA("SpotLight") then
			local effectClone = effect:Clone()
			effectClone.Name = "DonationEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true
			effectClone.Parent = hrp
			table.insert(appliedEffects, effectClone)
			print(`[SERVER] Applied Light: {effect.Name} from Level {level} Part`)

		elseif effect:IsA("Attachment") then
			-- Handle attachments with their children
			local attachmentClone = effect:Clone()
			attachmentClone.Name = "DonationEffect_Level" .. level .. "_" .. effect.Name
			attachmentClone.Parent = hrp

			-- Enable any ParticleEmitters in the attachment
			for _, child in ipairs(attachmentClone:GetChildren()) do
				if child:IsA("ParticleEmitter") then
					child.Enabled = true
					-- Force refresh
					task.wait()
					child.Enabled = true
				end
			end

			table.insert(appliedEffects, attachmentClone)
			print(`[SERVER] Applied attachment VFX: {effect.Name} from Level {level} Part`)
		end
	end

	-- Final check untuk memastikan semua ParticleEmitter enabled
	task.wait(0.1)
	for _, effect in ipairs(appliedEffects) do
		if effect:IsA("ParticleEmitter") and effect.Parent then
			effect.Enabled = true
		end
	end

	print(`[SERVER] Total {#appliedEffects} VFX effects applied from Level {level} Part`)
	return appliedEffects
end

-- ✅ Fungsi: Efek Donasi dengan Level System
local function TriggerDonationEffects(donatorPlayer, recipientPlayer, donationAmount)
	if activeEffects[recipientPlayer.UserId] then 
		print("[SERVER] Effects already active for this player, skipping...")
		return 
	end
	activeEffects[recipientPlayer.UserId] = true

	-- Wait untuk memastikan character fully loaded
	local character = recipientPlayer.Character
	if not character then
		print("[SERVER] Waiting for character to load...")
		character = recipientPlayer.CharacterAdded:Wait()
		task.wait(0.5) -- Extra delay untuk memastikan character fully loaded
	end

	-- Double check character masih ada
	if not character or not character.Parent then
		warn("[SERVER] Character tidak valid!")
		activeEffects[recipientPlayer.UserId] = nil
		return
	end

	-- Wait untuk HumanoidRootPart
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("[SERVER] HumanoidRootPart tidak ditemukan setelah 5 detik!")
		activeEffects[recipientPlayer.UserId] = nil
		return
	end

	-- Get donation level
	local donationLevel = getDonationLevel(donationAmount)

	-- Apply level-based effects if level > 0
	if donationLevel > 0 then
		print(`[SERVER] Triggering Level {donationLevel} effects for {donationAmount} Robux donation!`)

		-- Calculate effect duration first
		local effectDuration = 10 -- Default duration

		-- Increase duration based on level
		if donationLevel >= 5 then
			effectDuration = 20
		elseif donationLevel >= 3 then
			effectDuration = 15
		end

		-- Play level-based sound with same duration as effects
		local soundInstance = nil
		task.spawn(function()
			soundInstance = playLevelSound(donationLevel, effectDuration)
		end)

		-- Apply level-based VFX with small delay to ensure character is ready
		task.wait(0.2) -- Small delay untuk memastikan character sudah siap

		local appliedEffects = applyLevelVFX(character, donationLevel, effectDuration)

		-- Jika tidak ada effects yang berhasil di-apply, coba sekali lagi
		if #appliedEffects == 0 then
			print("[SERVER] No effects applied, retrying in 0.5 seconds...")
			task.wait(0.5)
			appliedEffects = applyLevelVFX(character, donationLevel, effectDuration)
		end

		-- Cleanup after duration (VFX and Sound together)
		task.delay(effectDuration, function()
			-- Stop and clean up sound first
			if soundInstance and soundInstance.Parent then
				soundInstance:Stop()
				soundInstance:Destroy()
				print(`[SERVER] Level {donationLevel} sound stopped`)
			end

			-- Then clean up VFX effects
			for _, effect in ipairs(appliedEffects) do
				if effect and effect.Parent then
					-- Disable ParticleEmitters first
					if effect:IsA("ParticleEmitter") then
						effect.Enabled = false
					elseif effect:IsA("Attachment") then
						for _, child in ipairs(effect:GetChildren()) do
							if child:IsA("ParticleEmitter") then
								child.Enabled = false
							end
						end
					end

					-- Wait for particles to fade
					task.wait(1)

					-- Destroy the effect
					if effect.Parent then
						effect:Destroy()
					end
				end
			end

			-- Reset activeEffects flag SETELAH cleanup
			activeEffects[recipientPlayer.UserId] = nil
			print(`[SERVER] Level {donationLevel} VFX effects and sound cleaned up`)
		end)
	else
		-- No level effects for donations under 100
		activeEffects[recipientPlayer.UserId] = nil
	end

	-- ==================== SPECIAL EFFECTS FOR HIGH AMOUNTS ====================
	-- Keep existing special effects for backwards compatibility
	if donationAmount == 500 then
		print("[EFFECTS] Triggering Fire Nuke for 500R$!")
		FireNuke:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(90, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return -- Exit early to prevent overlap
	end

	if donationAmount == 1000 then
		print("[EFFECTS] Triggering Fire Nuke for 1000R$!")
		FireNuke:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(90, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return
	end

	if donationAmount == 2000 then
		print("[EFFECTS] Triggering Mega Giant (FireSmite4) for 2000R$!")
		FireSmite4:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(90, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return
	end

	if donationAmount == 5000 then
		print("[EFFECTS] Triggering Nature Effect (FireSmite3) for 5000R$!")
		FireSmite3:FireAllClients(donatorPlayer.Name, recipientPlayer.Name, donationAmount, donatorPlayer.UserId)
		task.delay(90, function()
			activeEffects[recipientPlayer.UserId] = nil
		end)
		return
	end

	if donationAmount == 10000 then
		print("[EFFECTS] Triggering BlackHole for 10000R$!")
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

-- ✅ ProcessReceipt yang kompatibel dengan Donation Board V3
local function MyProcessReceipt(receiptInfo)
	print("[CUSTOM] Developer Product purchased!")
	print("Product ID:", receiptInfo.ProductId)
	print("Player ID:", receiptInfo.PlayerId)
	print("Purchase ID:", receiptInfo.PurchaseId)

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		warn("Player not found!")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Anti-duplikasi check
	local purchaseKey = tostring(receiptInfo.PlayerId) .. "_" .. tostring(receiptInfo.PurchaseId)
	local success, alreadyProcessed = pcall(function()
		return purchaseHistoryStore:GetAsync(purchaseKey)
	end)

	if success and alreadyProcessed then
		print("[CUSTOM] Purchase already processed, skipping.")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Cek Product ID
	local productInfo = DEVELOPER_PRODUCTS[receiptInfo.ProductId]
	if not productInfo then
		print("[CUSTOM] Unknown Product ID, letting other scripts handle it:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("[CUSTOM] Product found:", productInfo.name, "- Price:", productInfo.price, "- Level:", productInfo.level or getDonationLevel(productInfo.price))

	-- Target recipient (default: buyer gets the effect)
	local recipientPlayer = player

	-- Trigger donation effects
	TriggerDonationEffects(player, recipientPlayer, productInfo.price)

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
		warn("Failed to save purchase history!")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print(`[CUSTOM] Developer Product purchase processed successfully! {productInfo.price} R$ (Level {productInfo.level or getDonationLevel(productInfo.price)}) from {player.Name}`)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ✅ BRIDGE FUNCTION untuk BagiBagi Webhook Integration
local function TriggerBagiBagiDonationEffect(donorName, targetPlayerName, rupiahAmount, message)
	print(string.format("[BAGIBAGI] Processing donation: %s → %s | Rp.%d | %s", 
		donorName, targetPlayerName, rupiahAmount, message or "No message"))

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		warn("[BAGIBAGI] Target player not found:", targetPlayerName)
		return false
	end

	-- Convert Rupiah to Robux equivalent for effects (1000 Rupiah ≈ 1 Robux)
	local robuxEquivalent = math.floor(rupiahAmount / 1000)
	print(string.format("[BAGIBAGI] Converting Rp.%d → %d Robux equivalent", rupiahAmount, robuxEquivalent))

	-- Create fake donor player object
	local fakeDonorPlayer = {
		Name = donorName,
		UserId = 999999 -- Special ID for external donors
	}

	-- Use the level system for BagiBagi donations
	local effectAmount = math.max(robuxEquivalent, 100) -- Minimum 100 for Level 1
	local donationLevel = getDonationLevel(effectAmount)

	print(string.format("[BAGIBAGI] Triggering Level %d effects with amount: %d (original: %d)", 
		donationLevel, effectAmount, robuxEquivalent))

	TriggerDonationEffects(fakeDonorPlayer, targetPlayer, effectAmount)

	-- Send notification using existing system
	if donationNotif then
		donationNotif:FireAllClients(donorName, targetPlayerName, effectAmount)
	end

	print(string.format("[BAGIBAGI] ✅ Level %d effects triggered for %s (Rp.%d → %d Robux equivalent)", 
		donationLevel, targetPlayerName, rupiahAmount, effectAmount))
	return true
end

-- ✅ REGISTRASI DENGAN DONATION BOARD V3 SYSTEM
task.wait(1)

if shared.MarketplaceService then
	print("[CUSTOM] Registering with Donation Board V3 shared system...")
	shared.MarketplaceService.ProcessReceipt = MyProcessReceipt
	print("[CUSTOM] Successfully registered with Donation Board V3!")
else
	print("[CUSTOM] Donation Board V3 not found, using direct MarketplaceService...")
	game:GetService("MarketplaceService").ProcessReceipt = MyProcessReceipt
end

-- ✅ Expose function untuk WebhookIntegration
_G.TriggerBagiBagiDonationEffect = TriggerBagiBagiDonationEffect

print("[CUSTOM] Level-based donation effects system loaded successfully!")
print("[CUSTOM] BagiBagi bridge function registered!")

-- ✅ Check for required folders on startup
print("[CUSTOM] Checking for required folders...")
local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
if effectsFolder then
	print("[CUSTOM] ✅ EffectsCharacter folder detected!")

	local soundFolder = effectsFolder:FindFirstChild("Sound")
	if soundFolder then
		local soundChildren = soundFolder:GetChildren()
		print(`[CUSTOM] Found {#soundChildren} sound effects:`)
		for _, child in ipairs(soundChildren) do
			print(`[CUSTOM] - {child.Name} ({child.ClassName})`)
		end
	else
		warn("[CUSTOM] ❌ Sound folder NOT FOUND!")
	end

	local vfxFolder = effectsFolder:FindFirstChild("VFX")
	if vfxFolder then
		local vfxChildren = vfxFolder:GetChildren()
		print(`[CUSTOM] Found {#vfxChildren} VFX levels:`)
		for _, child in ipairs(vfxChildren) do
			print(`[CUSTOM] - {child.Name} ({child.ClassName})`)
			if child:IsA("BasePart") then
				local effectCount = #child:GetChildren()
				print(`[CUSTOM]   Part contains {effectCount} effects`)
			end
		end
	else
		warn("[CUSTOM] ❌ VFX folder NOT FOUND!")
	end
else
	warn("[CUSTOM] ❌ EffectsCharacter folder NOT FOUND in ServerStorage!")
end