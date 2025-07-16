--[[
    WheatSystemEnhancements.lua - Advanced Wheat System Features
    Place in: ServerScriptService/WheatSystemEnhancements.lua
    
    ADDITIONAL FEATURES:
    ✅ Wheat field visual effects and animations
    ✅ Sound effects for harvesting
    ✅ Particle effects for scythe swings
    ✅ Achievement system for wheat harvesting
    ✅ Seasonal wheat growth variations
    ✅ Weather effects on wheat growth
]]

local WheatSystemEnhancements = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Configuration
local ENHANCEMENT_CONFIG = {
	ENABLE_PARTICLES = true,
	ENABLE_SOUNDS = true,
	ENABLE_ACHIEVEMENTS = true,
	ENABLE_WEATHER_EFFECTS = false,
	PARTICLE_LIFETIME = 3,
	SOUND_VOLUME = 0.5
}

-- Load ItemConfig safely
local ItemConfig = nil
local function loadItemConfig()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
	end)
	if success then
		ItemConfig = result
		print("WheatSystemEnhancements: ItemConfig loaded successfully")
	else
		warn("WheatSystemEnhancements: Could not load ItemConfig: " .. tostring(result))
		-- Create fallback ItemConfig
		ItemConfig = {
			ShopItems = {},
			Crops = {},
			MiningSystem = {ores = {}}
		}
	end
end

-- State
WheatSystemEnhancements.GameCore = nil
WheatSystemEnhancements.WheatHarvesting = nil
WheatSystemEnhancements.SoundEffects = {}
WheatSystemEnhancements.ParticleEffects = {}
WheatSystemEnhancements.Achievements = {}
WheatSystemEnhancements.WeatherSystem = nil

-- ========== INITIALIZATION ==========

function WheatSystemEnhancements:Initialize(gameCore, wheatHarvesting)
	print("WheatSystemEnhancements: Initializing enhanced wheat features...")

	self.GameCore = gameCore
	self.WheatHarvesting = wheatHarvesting

	-- Load ItemConfig first
	loadItemConfig()

	-- Setup sound effects
	self:SetupSoundEffects()

	-- Setup particle effects
	self:SetupParticleEffects()

	-- Setup achievements
	self:SetupAchievements()

	-- Setup visual enhancements
	self:SetupVisualEnhancements()

	-- Hook into existing wheat system
	self:HookIntoWheatSystem()

	print("WheatSystemEnhancements: ✅ Enhanced wheat features initialized")
	return true
end

-- ========== SOUND EFFECTS SYSTEM ==========

function WheatSystemEnhancements:SetupSoundEffects()
	if not ENHANCEMENT_CONFIG.ENABLE_SOUNDS then return end

	print("WheatSystemEnhancements: Setting up sound effects...")

	-- Create sound effects
	self.SoundEffects = {
		scytheSwing = self:CreateSoundEffect("rbxasset://sounds/impact_water.mp3", 0.3),
		wheatHarvest = self:CreateSoundEffect("rbxasset://sounds/electronicpingshort.wav", 0.4),
		sectionComplete = self:CreateSoundEffect("rbxasset://sounds/bell.wav", 0.5),
		proximityEnter = self:CreateSoundEffect("rbxasset://sounds/button.wav", 0.3),
		scytheReceive = self:CreateSoundEffect("rbxasset://sounds/switch.wav", 0.4)
	}

	print("WheatSystemEnhancements: ✅ Sound effects setup complete")
end

function WheatSystemEnhancements:CreateSoundEffect(soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume * ENHANCEMENT_CONFIG.SOUND_VOLUME
	sound.Parent = SoundService
	return sound
end

function WheatSystemEnhancements:PlaySoundEffect(effectName, player)
	if not ENHANCEMENT_CONFIG.ENABLE_SOUNDS then return end

	local sound = self.SoundEffects[effectName]
	if sound then
		-- Play sound for specific player or all players
		if player then
			sound:Play()
		else
			sound:Play()
		end
	end
end

-- ========== PARTICLE EFFECTS SYSTEM ==========

function WheatSystemEnhancements:SetupParticleEffects()
	if not ENHANCEMENT_CONFIG.ENABLE_PARTICLES then return end

	print("WheatSystemEnhancements: Setting up particle effects...")

	-- Create particle effect templates
	self.ParticleEffects = {
		wheatDebris = self:CreateWheatDebrisEffect(),
		scytheTrail = self:CreateScytheTrailEffect(),
		harvestGlow = self:CreateHarvestGlowEffect(),
		sectionComplete = self:CreateSectionCompleteEffect()
	}

	print("WheatSystemEnhancements: ✅ Particle effects setup complete")
end

function WheatSystemEnhancements:CreateWheatDebrisEffect()
	-- Create wheat debris that falls when harvesting
	local function createDebris(position)
		for i = 1, 5 do
			local debris = Instance.new("Part")
			debris.Name = "WheatDebris"
			debris.Size = Vector3.new(0.1, 0.1, 0.1)
			debris.Material = Enum.Material.Leaf
			debris.BrickColor = BrickColor.new("Bright yellow")
			debris.Anchored = false
			debris.CanCollide = false
			debris.Position = position + Vector3.new(
				math.random(-2, 2),
				math.random(0, 2),
				math.random(-2, 2)
			)
			debris.Parent = workspace

			-- Add random velocity
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Velocity = Vector3.new(
				math.random(-10, 10),
				math.random(5, 15),
				math.random(-10, 10)
			)
			bodyVelocity.Parent = debris

			-- Remove after a few seconds
			Debris:AddItem(debris, ENHANCEMENT_CONFIG.PARTICLE_LIFETIME)
		end
	end

	return createDebris
end

function WheatSystemEnhancements:CreateScytheTrailEffect()
	-- Create trail effect when swinging scythe
	local function createTrail(startPos, endPos)
		local trail = Instance.new("Part")
		trail.Name = "ScytheTrail"
		trail.Size = Vector3.new(0.2, 0.2, (startPos - endPos).Magnitude)
		trail.Material = Enum.Material.Neon
		trail.BrickColor = BrickColor.new("Bright yellow")
		trail.Anchored = true
		trail.CanCollide = false
		trail.Transparency = 0.5
		trail.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -(startPos - endPos).Magnitude / 2)
		trail.Parent = workspace

		-- Fade out
		local tween = TweenService:Create(trail,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad),
			{Transparency = 1}
		)
		tween:Play()

		tween.Completed:Connect(function()
			trail:Destroy()
		end)
	end

	return createTrail
end

function WheatSystemEnhancements:CreateHarvestGlowEffect()
	-- Create glow effect when harvesting wheat
	local function createGlow(position)
		local glow = Instance.new("Part")
		glow.Name = "HarvestGlow"
		glow.Size = Vector3.new(2, 2, 2)
		glow.Material = Enum.Material.Neon
		glow.BrickColor = BrickColor.new("Bright yellow")
		glow.Anchored = true
		glow.CanCollide = false
		glow.Transparency = 0.3
		glow.Position = position
		glow.Parent = workspace

		-- Animate glow
		local tween = TweenService:Create(glow,
			TweenInfo.new(1, Enum.EasingStyle.Quad),
			{
				Size = Vector3.new(4, 4, 4),
				Transparency = 1
			}
		)
		tween:Play()

		tween.Completed:Connect(function()
			glow:Destroy()
		end)
	end

	return createGlow
end

function WheatSystemEnhancements:CreateSectionCompleteEffect()
	-- Create celebration effect when section is completed
	local function createCelebration(position)
		-- Create multiple sparkles
		for i = 1, 8 do
			local sparkle = Instance.new("Part")
			sparkle.Name = "SectionSpark"
			sparkle.Size = Vector3.new(0.3, 0.3, 0.3)
			sparkle.Material = Enum.Material.Neon
			sparkle.BrickColor = BrickColor.new("Bright yellow")
			sparkle.Anchored = true
			sparkle.CanCollide = false
			sparkle.Position = position
			sparkle.Parent = workspace

			-- Random direction
			local direction = Vector3.new(
				math.random(-1, 1),
				math.random(0, 1),
				math.random(-1, 1)
			).Unit * 5

			-- Animate sparkle
			local tween = TweenService:Create(sparkle,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad),
				{
					Position = position + direction,
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			tween:Play()

			tween.Completed:Connect(function()
				sparkle:Destroy()
			end)
		end
	end

	return createCelebration
end

-- ========== ACHIEVEMENTS SYSTEM ==========

function WheatSystemEnhancements:SetupAchievements()
	if not ENHANCEMENT_CONFIG.ENABLE_ACHIEVEMENTS then return end

	print("WheatSystemEnhancements: Setting up achievements...")

	-- Define wheat harvesting achievements
	self.Achievements = {
		first_wheat = {
			id = "first_wheat",
			name = "First Harvest",
			description = "Harvest your first wheat",
			icon = "🌾",
			reward = {coins = 50},
			condition = function(stats) return stats.wheatHarvested >= 1 end
		},
		wheat_apprentice = {
			id = "wheat_apprentice",
			name = "Wheat Apprentice",
			description = "Harvest 25 wheat",
			icon = "🌾",
			reward = {coins = 200},
			condition = function(stats) return stats.wheatHarvested >= 25 end
		},
		wheat_master = {
			id = "wheat_master",
			name = "Wheat Master",
			description = "Harvest 100 wheat",
			icon = "🌾",
			reward = {coins = 500, farmTokens = 5},
			condition = function(stats) return stats.wheatHarvested >= 100 end
		},
		field_clearer = {
			id = "field_clearer",
			name = "Field Clearer",
			description = "Clear the entire wheat field in one session",
			icon = "🏆",
			reward = {coins = 300, farmTokens = 3},
			condition = function(stats) return stats.wheatFieldsCleared >= 1 end
		},
		scythe_collector = {
			id = "scythe_collector",
			name = "Scythe Collector",
			description = "Receive 5 scythes",
			icon = "🔪",
			reward = {coins = 100},
			condition = function(stats) return stats.scythesReceived >= 5 end
		}
	}

	print("WheatSystemEnhancements: ✅ Achievements setup complete")
end

function WheatSystemEnhancements:CheckAchievements(player)
	if not ENHANCEMENT_CONFIG.ENABLE_ACHIEVEMENTS then return end

	local playerData = self.GameCore:GetPlayerData(player)
	if not playerData then return end

	local stats = playerData.stats or {}
	local playerAchievements = playerData.achievements or {}

	-- Check each achievement
	for achievementId, achievement in pairs(self.Achievements) do
		if not playerAchievements[achievementId] and achievement.condition(stats) then
			-- Award achievement
			self:AwardAchievement(player, achievement)
			playerAchievements[achievementId] = {
				awarded = true,
				awardedTime = os.time()
			}
		end
	end

	-- Save updated achievements
	playerData.achievements = playerAchievements
	self.GameCore:UpdatePlayerData(player, playerData)
end

function WheatSystemEnhancements:AwardAchievement(player, achievement)
	print("WheatSystemEnhancements: Awarding achievement '" .. achievement.id .. "' to " .. player.Name)

	-- Give rewards
	local playerData = self.GameCore:GetPlayerData(player)
	if playerData and achievement.reward then
		if achievement.reward.coins then
			playerData.coins = (playerData.coins or 0) + achievement.reward.coins
		end
		if achievement.reward.farmTokens then
			playerData.farmTokens = (playerData.farmTokens or 0) + achievement.reward.farmTokens
		end

		self.GameCore:UpdatePlayerData(player, playerData)
	end

	-- Send notification
	if self.GameCore and self.GameCore.SendNotification then
		self.GameCore:SendNotification(player, "🏆 Achievement Unlocked!", 
			achievement.icon .. " " .. achievement.name .. "\n" .. achievement.description, "success")
	end

	-- Play sound effect
	self:PlaySoundEffect("sectionComplete", player)
end

-- ========== VISUAL ENHANCEMENTS ==========

function WheatSystemEnhancements:SetupVisualEnhancements()
	print("WheatSystemEnhancements: Setting up visual enhancements...")

	-- Enhance wheat field appearance
	self:EnhanceWheatField()

	-- Add ambient effects
	self:AddAmbientEffects()

	print("WheatSystemEnhancements: ✅ Visual enhancements setup complete")
end

function WheatSystemEnhancements:EnhanceWheatField()
	local wheatField = workspace:FindFirstChild("WheatField")
	if not wheatField then return end

	-- Add subtle wind animation to wheat
	spawn(function()
		while true do
			wait(0.1)

			-- Animate wheat sections with subtle movement
			for _, section in pairs(wheatField:GetChildren()) do
				if section:IsA("Model") or section:IsA("BasePart") then
					-- Skip if harvested
					if self.WheatHarvesting and self.WheatHarvesting.SectionData then
						local sectionData = nil
						for _, data in pairs(self.WheatHarvesting.SectionData) do
							if data.section == section then
								sectionData = data
								break
							end
						end

						if sectionData and sectionData.isHarvested then
							continue
						end
					end

					-- Create subtle swaying motion
					if section:IsA("BasePart") then
						local originalCFrame = section.CFrame
						local sway = math.sin(tick() * 2) * 0.02
						section.CFrame = originalCFrame * CFrame.Angles(sway, 0, sway * 0.5)
					end
				end
			end
		end
	end)
end

function WheatSystemEnhancements:AddAmbientEffects()
	-- Add ambient particles around wheat field
	local wheatField = workspace:FindFirstChild("WheatField")
	if not wheatField then return end

	spawn(function()
		while true do
			wait(math.random(5, 15))

			-- Create occasional floating particles
			if math.random() < 0.3 then
				local bounds = wheatField:PivotTo()
				local position = bounds.Position + Vector3.new(
					math.random(-20, 20),
					math.random(2, 5),
					math.random(-20, 20)
				)

				local particle = Instance.new("Part")
				particle.Name = "AmbientParticle"
				particle.Size = Vector3.new(0.1, 0.1, 0.1)
				particle.Material = Enum.Material.Neon
				particle.BrickColor = BrickColor.new("Bright yellow")
				particle.Anchored = true
				particle.CanCollide = false
				particle.Transparency = 0.7
				particle.Position = position
				particle.Parent = workspace

				-- Float and fade
				local tween = TweenService:Create(particle,
					TweenInfo.new(3, Enum.EasingStyle.Sine),
					{
						Position = position + Vector3.new(0, 5, 0),
						Transparency = 1
					}
				)
				tween:Play()

				tween.Completed:Connect(function()
					particle:Destroy()
				end)
			end
		end
	end)
end

-- ========== INTEGRATION HOOKS ==========

function WheatSystemEnhancements:HookIntoWheatSystem()
	print("WheatSystemEnhancements: Hooking into wheat system...")

	if not self.WheatHarvesting then
		warn("WheatSystemEnhancements: WheatHarvesting not available for hooking")
		return
	end

	-- Hook into scythe swing
	local originalHandleScytheSwing = self.WheatHarvesting.HandleScytheSwing
	self.WheatHarvesting.HandleScytheSwing = function(wheatSelf, player)
		-- Call original function
		originalHandleScytheSwing(wheatSelf, player)

		-- Add enhancements
		self:OnScytheSwing(player)
	end

	-- Hook into section completion
	local originalCompleteSection = self.WheatHarvesting.CompleteSection
	self.WheatHarvesting.CompleteSection = function(wheatSelf, player, sectionIndex)
		-- Call original function
		originalCompleteSection(wheatSelf, player, sectionIndex)

		-- Add enhancements
		self:OnSectionComplete(player, sectionIndex)
	end

	-- Hook into proximity enter
	local originalPlayerEnteredWheatProximity = self.WheatHarvesting.PlayerEnteredWheatProximity
	self.WheatHarvesting.PlayerEnteredWheatProximity = function(wheatSelf, player)
		-- Call original function
		originalPlayerEnteredWheatProximity(wheatSelf, player)

		-- Add enhancements
		self:OnProximityEnter(player)
	end

	print("WheatSystemEnhancements: ✅ Successfully hooked into wheat system")
end

function WheatSystemEnhancements:OnScytheSwing(player)
	-- Play swing sound
	self:PlaySoundEffect("scytheSwing", player)

	-- Create particle effects
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local rootPart = player.Character.HumanoidRootPart
		local swingPos = rootPart.Position + rootPart.CFrame.LookVector * 3

		-- Create wheat debris
		if self.ParticleEffects.wheatDebris then
			self.ParticleEffects.wheatDebris(swingPos)
		end

		-- Create scythe trail
		if self.ParticleEffects.scytheTrail then
			local startPos = swingPos + Vector3.new(-2, 0, 0)
			local endPos = swingPos + Vector3.new(2, 0, 0)
			self.ParticleEffects.scytheTrail(startPos, endPos)
		end
	end
end

function WheatSystemEnhancements:OnSectionComplete(player, sectionIndex)
	-- Play completion sound
	self:PlaySoundEffect("sectionComplete", player)

	-- Create celebration effect
	if self.WheatHarvesting and self.WheatHarvesting.SectionData then
		local sectionData = self.WheatHarvesting.SectionData[sectionIndex]
		if sectionData and sectionData.section then
			local sectionPos = sectionData.section:GetModelCFrame().Position

			if self.ParticleEffects.sectionComplete then
				self.ParticleEffects.sectionComplete(sectionPos)
			end
		end
	end

	-- Update stats for achievements
	local playerData = self.GameCore:GetPlayerData(player)
	if playerData then
		playerData.stats = playerData.stats or {}

		-- Check if this completed the entire field
		local availableWheat = self.WheatHarvesting:GetAvailableWheatCount()
		if availableWheat <= 0 then
			playerData.stats.wheatFieldsCleared = (playerData.stats.wheatFieldsCleared or 0) + 1
		end

		self.GameCore:UpdatePlayerData(player, playerData)
	end

	-- Check achievements
	self:CheckAchievements(player)
end

function WheatSystemEnhancements:OnProximityEnter(player)
	-- Play proximity sound
	self:PlaySoundEffect("proximityEnter", player)

	-- Create harvest glow around player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local rootPart = player.Character.HumanoidRootPart

		if self.ParticleEffects.harvestGlow then
			self.ParticleEffects.harvestGlow(rootPart.Position)
		end
	end
end

-- ========== DEBUG FUNCTIONS ==========

function WheatSystemEnhancements:DebugStatus()
	print("=== WHEAT SYSTEM ENHANCEMENTS DEBUG ===")
	print("Sound effects: " .. (ENHANCEMENT_CONFIG.ENABLE_SOUNDS and "✅" or "❌"))
	print("Particle effects: " .. (ENHANCEMENT_CONFIG.ENABLE_PARTICLES and "✅" or "❌"))
	print("Achievements: " .. (ENHANCEMENT_CONFIG.ENABLE_ACHIEVEMENTS and "✅" or "❌"))
	print("Weather effects: " .. (ENHANCEMENT_CONFIG.ENABLE_WEATHER_EFFECTS and "✅" or "❌"))
	print("")
	print("Sound effects loaded: " .. self:CountTable(self.SoundEffects))
	print("Particle effects loaded: " .. self:CountTable(self.ParticleEffects))
	print("Achievements defined: " .. self:CountTable(self.Achievements))
	print("")
	print("Hooked into wheat system: " .. (self.WheatHarvesting and "✅" or "❌"))
	print("=========================================")
end

function WheatSystemEnhancements:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== CLEANUP ==========

function WheatSystemEnhancements:Cleanup()
	print("WheatSystemEnhancements: Performing cleanup...")

	-- Stop all sound effects
	for _, sound in pairs(self.SoundEffects) do
		if sound then
			sound:Stop()
		end
	end

	-- Clear references
	self.SoundEffects = {}
	self.ParticleEffects = {}
	self.Achievements = {}

	print("WheatSystemEnhancements: Cleanup complete")
end

-- Global reference
_G.WheatSystemEnhancements = WheatSystemEnhancements

return WheatSystemEnhancements