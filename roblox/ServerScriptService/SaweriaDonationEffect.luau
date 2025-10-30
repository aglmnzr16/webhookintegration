--[[
═══════════════════════════════════════════════════════════════════════════════
  SAWERIA DONATION EFFECTS - Visual & Audio Effects
═══════════════════════════════════════════════════════════════════════════════

SYSTEM: Saweria/BagiBagi External Donations
TYPE: Server Script (ServerScriptService)
CURRENCY: Rupiah (Rp.)

PURPOSE:
  - Trigger visual and audio effects for Saweria donations
  - Level-based effects (6 levels based on amount)
  - Particle effects, sounds, lights
  - Convert Rupiah to Robux equivalent for effect scaling

EFFECT LEVELS:
  Level 0: < Rp. 100,000 (No effects)
  Level 1: Rp. 100,000 - 199,999
  Level 2: Rp. 200,000 - 499,999
  Level 3: Rp. 500,000 - 999,999
  Level 4: Rp. 1,000,000 - 4,999,999
  Level 5: Rp. 5,000,000 - 9,999,999
  Level 6: Rp. 10,000,000+

SPECIAL EFFECTS:
  Rp. 1,000,000 (1 juta): BlackHole Effect

CONVERSION:
  Rp. 1,000 ≈ 1 Robux equivalent (for effect scaling)

TRIGGERED BY:
  - WebhookIntegration.luau via _G.TriggerSaweriaDonationEffect

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

-- JPass Events for special effects
local JPass = require(ReplicatedStorage.JamStudio.UpdateLoader.JPass)
local FireBlackHole = JPass.Event("FireBlackHole")

-- Track active effects to prevent overlaps
local activeEffects = {}

--═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
--═══════════════════════════════════════════════════════════════════════════

-- Determine donation level based on Robux equivalent amount
local function getDonationLevel(robuxEquivalent)
	if robuxEquivalent >= 10000 then
		return 6
	elseif robuxEquivalent >= 5000 then
		return 5
	elseif robuxEquivalent >= 1000 then
		return 4
	elseif robuxEquivalent >= 500 then
		return 3
	elseif robuxEquivalent >= 200 then
		return 2
	elseif robuxEquivalent >= 100 then
		return 1
	else
		return 0
	end
end

-- Play level-based sound effect (looped for duration)
local function playLevelSound(level, duration)
	local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
	if not effectsFolder then
		warn("[SAWERIA EFFECT] EffectsCharacter folder not found!")
		return nil
	end

	local soundFolder = effectsFolder:FindFirstChild("Sound")
	if not soundFolder then
		warn("[SAWERIA EFFECT] Sound folder not found!")
		return nil
	end

	local soundName = "DonationLevel" .. tostring(level)
	local soundEffect = soundFolder:FindFirstChild(soundName)

	if soundEffect and soundEffect:IsA("Sound") then
		local soundClone = soundEffect:Clone()
		soundClone.Parent = SoundService
		soundClone.Looped = true
		soundClone:Play()

		print(`[SAWERIA EFFECT] Playing level {level} sound (looped for {duration}s)`)
		return soundClone
	else
		warn(`[SAWERIA EFFECT] Sound {soundName} not found!`)
		return nil
	end
end

-- Apply level-based visual effects to character
local function applyLevelVFX(character, level, duration)
	local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
	if not effectsFolder then
		warn("[SAWERIA EFFECT] EffectsCharacter folder not found!")
		return {}
	end

	local vfxFolder = effectsFolder:FindFirstChild("VFX")
	if not vfxFolder then
		warn("[SAWERIA EFFECT] VFX folder not found!")
		return {}
	end

	local levelName = "Level" .. tostring(level)
	local levelPart = vfxFolder:FindFirstChild(levelName)

	if not levelPart or not levelPart:IsA("BasePart") then
		warn(`[SAWERIA EFFECT] Level {level} VFX part not found!`)
		return {}
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("[SAWERIA EFFECT] HumanoidRootPart not found!")
		return {}
	end

	local appliedEffects = {}

	-- Clone and apply all effects from the Part
	for _, effect in ipairs(levelPart:GetChildren()) do
		task.wait(0.05)

		if effect:IsA("ParticleEmitter") then
			local effectClone = effect:Clone()
			effectClone.Name = "SaweriaEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true
			effectClone.Rate = effectClone.Rate > 0 and effectClone.Rate or 20
			effectClone.Parent = hrp

			task.wait()
			effectClone.Enabled = true

			table.insert(appliedEffects, effectClone)
			print(`[SAWERIA EFFECT] Applied ParticleEmitter: {effect.Name}`)

		elseif effect:IsA("Beam") then
			local effectClone = effect:Clone()
			effectClone.Name = "SaweriaEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true

			local attachment0 = Instance.new("Attachment")
			attachment0.Name = "SaweriaBeamAttachment0"
			attachment0.Position = Vector3.new(0, 0, 0)
			attachment0.Parent = hrp

			local attachment1 = Instance.new("Attachment")
			attachment1.Name = "SaweriaBeamAttachment1"
			attachment1.Position = Vector3.new(0, 5, 0)
			attachment1.Parent = hrp

			effectClone.Attachment0 = attachment0
			effectClone.Attachment1 = attachment1
			effectClone.Parent = hrp

			table.insert(appliedEffects, attachment0)
			table.insert(appliedEffects, attachment1)
			table.insert(appliedEffects, effectClone)
			print(`[SAWERIA EFFECT] Applied Beam: {effect.Name}`)

		elseif effect:IsA("PointLight") or effect:IsA("SpotLight") then
			local effectClone = effect:Clone()
			effectClone.Name = "SaweriaEffect_Level" .. level .. "_" .. effect.Name
			effectClone.Enabled = true
			effectClone.Parent = hrp
			table.insert(appliedEffects, effectClone)
			print(`[SAWERIA EFFECT] Applied Light: {effect.Name}`)

		elseif effect:IsA("Attachment") then
			local attachmentClone = effect:Clone()
			attachmentClone.Name = "SaweriaEffect_Level" .. level .. "_" .. effect.Name
			attachmentClone.Parent = hrp

			for _, child in ipairs(attachmentClone:GetChildren()) do
				if child:IsA("ParticleEmitter") then
					child.Enabled = true
					task.wait()
					child.Enabled = true
				end
			end

			table.insert(appliedEffects, attachmentClone)
			print(`[SAWERIA EFFECT] Applied Attachment: {effect.Name}`)
		end
	end

	-- Final enable check
	task.wait(0.1)
	for _, effect in ipairs(appliedEffects) do
		if effect:IsA("ParticleEmitter") and effect.Parent then
			effect.Enabled = true
		end
	end

	print(`[SAWERIA EFFECT] Applied {#appliedEffects} VFX effects from Level {level}`)
	return appliedEffects
end

--═══════════════════════════════════════════════════════════════════════════
-- MAIN EFFECT TRIGGER FUNCTION
--═══════════════════════════════════════════════════════════════════════════

local function TriggerSaweriaEffects(targetPlayer, robuxEquivalent)
	if activeEffects[targetPlayer.UserId] then
		print("[SAWERIA EFFECT] Effects already active, skipping...")
		return
	end
	activeEffects[targetPlayer.UserId] = true

	local character = targetPlayer.Character
	if not character then
		print("[SAWERIA EFFECT] Waiting for character...")
		character = targetPlayer.CharacterAdded:Wait()
		task.wait(0.5)
	end

	if not character or not character.Parent then
		warn("[SAWERIA EFFECT] Character invalid!")
		activeEffects[targetPlayer.UserId] = nil
		return
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("[SAWERIA EFFECT] HumanoidRootPart not found!")
		activeEffects[targetPlayer.UserId] = nil
		return
	end

	local donationLevel = getDonationLevel(robuxEquivalent)

	if donationLevel > 0 then
		print(`[SAWERIA EFFECT] Triggering Level {donationLevel} effects (Robux equiv: {robuxEquivalent})`)

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
			print("[SAWERIA EFFECT] No effects applied, retrying...")
			task.wait(0.5)
			appliedEffects = applyLevelVFX(character, donationLevel, effectDuration)
		end

		-- Cleanup after duration
		task.delay(effectDuration, function()
			-- Stop sound
			if soundInstance and soundInstance.Parent then
				soundInstance:Stop()
				soundInstance:Destroy()
				print(`[SAWERIA EFFECT] Level {donationLevel} sound stopped`)
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

			activeEffects[targetPlayer.UserId] = nil
			print(`[SAWERIA EFFECT] Level {donationLevel} effects cleaned up`)
		end)
	else
		-- No level effects for donations under 100k
		activeEffects[targetPlayer.UserId] = nil
	end

	-- ==================== SPECIAL EFFECTS FOR HIGH AMOUNTS ====================
	-- BlackHole effect for 1 million rupiah (exact match)
	if robuxEquivalent == 1000 then
		print("[SAWERIA EFFECT] Triggering BlackHole for Rp. 1,000,000!")
		FireBlackHole:FireAllClients("Saweria Donor", targetPlayer.Name, 1000000, 0)
		task.delay(120, function()
			activeEffects[targetPlayer.UserId] = nil
		end)
		return -- Exit early to prevent overlap
	end

	-- Reset activeEffects after standard effects
	task.delay(1, function()
		activeEffects[targetPlayer.UserId] = nil
	end)
end

--═══════════════════════════════════════════════════════════════════════════
-- PUBLIC BRIDGE FUNCTION (Called by WebhookIntegration)
--═══════════════════════════════════════════════════════════════════════════

function TriggerSaweriaDonationEffect(donorName, targetPlayerName, rupiahAmount, message)
	print(string.format("[SAWERIA EFFECT] Processing: %s → %s | Rp.%s | %s", 
		donorName, targetPlayerName, tostring(rupiahAmount), message or "No message"))

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		warn("[SAWERIA EFFECT] Target player not found:", targetPlayerName)
		return false
	end

	-- Convert Rupiah to Robux equivalent (1000 Rupiah ≈ 1 Robux)
	local robuxEquivalent = math.floor(rupiahAmount / 1000)
	print(string.format("[SAWERIA EFFECT] Converting Rp.%d → %d Robux equivalent", rupiahAmount, robuxEquivalent))

	-- Minimum 100 for Level 1
	local effectAmount = math.max(robuxEquivalent, 100)
	local donationLevel = getDonationLevel(effectAmount)

	print(string.format("[SAWERIA EFFECT] Triggering Level %d effects (amount: %d)", 
		donationLevel, effectAmount))

	TriggerSaweriaEffects(targetPlayer, effectAmount)

	print(string.format("[SAWERIA EFFECT] ✅ Level %d triggered for %s (Rp.%d)", 
		donationLevel, targetPlayerName, rupiahAmount))
	return true
end

--═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
--═══════════════════════════════════════════════════════════════════════════

-- Expose function for WebhookIntegration
_G.TriggerSaweriaDonationEffect = TriggerSaweriaDonationEffect

print("[SAWERIA EFFECT] ✅ Saweria donation effects system loaded!")

-- Check required folders
print("[SAWERIA EFFECT] Checking required folders...")
local effectsFolder = ServerStorage:FindFirstChild("EffectsCharacter")
if effectsFolder then
	print("[SAWERIA EFFECT] ✅ EffectsCharacter folder found!")
	
	local soundFolder = effectsFolder:FindFirstChild("Sound")
	if soundFolder then
		print(`[SAWERIA EFFECT] Found {#soundFolder:GetChildren()} sound effects`)
	else
		warn("[SAWERIA EFFECT] ❌ Sound folder NOT FOUND!")
	end
	
	local vfxFolder = effectsFolder:FindFirstChild("VFX")
	if vfxFolder then
		print(`[SAWERIA EFFECT] Found {#vfxFolder:GetChildren()} VFX levels`)
	else
		warn("[SAWERIA EFFECT] ❌ VFX folder NOT FOUND!")
	end
else
	warn("[SAWERIA EFFECT] ❌ EffectsCharacter folder NOT FOUND in ServerStorage!")
end
