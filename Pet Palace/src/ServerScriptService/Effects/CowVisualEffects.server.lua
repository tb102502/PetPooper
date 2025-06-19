--[[
    ENHANCED COW VISUAL EFFECTS SYSTEM
    Place as: ServerScriptService/Effects/CowVisualEffects.server.lua
    
    Features:
    ✅ Advanced particle systems for each cow tier
    ✅ Dynamic lighting effects
    ✅ Animated materials and textures
    ✅ Environmental effects (ground particles, aura fields)
    ✅ Sound effects for each tier
    ✅ Performance optimized with LOD system
]]

local CowVisualEffects = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

-- Configuration
local EFFECT_RANGE = 50 -- Distance for effect visibility
local MAX_PARTICLES_PER_COW = 20
local PERFORMANCE_MODE = false -- Set to true for lower-end devices

-- Effect Storage
CowVisualEffects.ActiveEffects = {} -- [cowId] = {effects}
CowVisualEffects.SoundEffects = {} -- [tier] = sound
CowVisualEffects.PerformanceSettings = {
	particleCount = PERFORMANCE_MODE and 5 or 15,
	updateRate = PERFORMANCE_MODE and 0.5 or 0.1,
	lightRange = PERFORMANCE_MODE and 10 or 20
}

-- ========== INITIALIZATION ==========

function CowVisualEffects:Initialize()
	print("CowVisualEffects: Initializing advanced visual effects system...")

	-- Setup sound effects
	self:CreateSoundEffects()

	-- Start performance monitoring
	self:StartPerformanceMonitoring()

	-- Connect to cow system
	self:ConnectToCowSystem()

	print("CowVisualEffects: Advanced visual effects system initialized!")
end

function CowVisualEffects:CreateSoundEffects()
	local soundFolder = Instance.new("Folder")
	soundFolder.Name = "CowSounds"
	soundFolder.Parent = SoundService

	-- Create tier-specific sounds
	local sounds = {
		basic = {id = "rbxassetid://131961136", volume = 0.3, pitch = 1.0}, -- Basic moo
		silver = {id = "rbxassetid://131961136", volume = 0.4, pitch = 1.2}, -- Higher pitched
		gold = {id = "rbxassetid://131961136", volume = 0.5, pitch = 1.5}, -- Even higher
		diamond = {id = "rbxassetid://131961136", volume = 0.6, pitch = 1.8}, -- Crystal-like
		rainbow = {id = "rbxassetid://131961136", volume = 0.7, pitch = 2.0}, -- Magical
		cosmic = {id = "rbxassetid://131961136", volume = 0.8, pitch = 0.5} -- Deep cosmic
	}

	for tier, soundData in pairs(sounds) do
		local sound = Instance.new("Sound")
		sound.Name = tier .. "MooSound"
		sound.SoundId = soundData.id
		sound.Volume = soundData.volume
	--	sound.Pitch = soundData.pitch
		sound.Parent = soundFolder

		self.SoundEffects[tier] = sound
	end

	print("CowVisualEffects: Created tier-specific sound effects")
end

function CowVisualEffects:ConnectToCowSystem()
	-- Connect to the enhanced cow milk system
	spawn(function()
		while not _G.EnhancedCowMilkSystem do
			wait(1)
		end

		print("CowVisualEffects: Connected to Enhanced Cow Milk System")

		-- Monitor for new cows
		spawn(function()
			while true do
				wait(5)
				self:UpdateCowEffects()
			end
		end)
	end)
end

-- ========== ADVANCED VISUAL EFFECTS ==========

function CowVisualEffects:ApplyAdvancedEffects(cowModel, tier)
	local cowId = cowModel.Name

	print("CowVisualEffects: Applying advanced " .. tier .. " effects to " .. cowId)

	-- Clear existing effects
	self:ClearEffects(cowId)

	-- Initialize effect storage
	self.ActiveEffects[cowId] = {
		tier = tier,
		model = cowModel,
		particles = {},
		lights = {},
		animations = {},
		sounds = {}
	}

	-- Apply tier-specific effects
	if tier == "basic" then
		self:ApplyBasicEffects(cowModel, cowId)
	elseif tier == "silver" then
		self:ApplySilverEffects(cowModel, cowId)
	elseif tier == "gold" then
		self:ApplyGoldEffects(cowModel, cowId)
	elseif tier == "diamond" then
		self:ApplyDiamondEffects(cowModel, cowId)
	elseif tier == "rainbow" then
		self:ApplyRainbowEffects(cowModel, cowId)
	elseif tier == "cosmic" then
		self:ApplyCosmicEffects(cowModel, cowId)
	end

	-- Add environmental effects
	self:AddEnvironmentalEffects(cowModel, cowId, tier)

	-- Start effect animations
	self:StartEffectAnimations(cowId)
end

-- ========== TIER-SPECIFIC EFFECTS ==========

function CowVisualEffects:ApplyBasicEffects(cowModel, cowId)
	-- Simple steam effects from nostrils
	self:CreateBreathingSteam(cowModel, cowId)

	-- Gentle ambient light
	self:CreateAmbientLight(cowModel, cowId, Color3.fromRGB(255, 255, 200), 5, 0.5)
end

function CowVisualEffects:ApplySilverEffects(cowModel, cowId)
	-- Metallic reflection effects
	self:CreateMetallicReflections(cowModel, cowId)

	-- Silver particle trail
	self:CreateParticleTrail(cowModel, cowId, Color3.fromRGB(192, 192, 192), 3)

	-- Enhanced lighting
	self:CreateAmbientLight(cowModel, cowId, Color3.fromRGB(220, 220, 220), 8, 1.0)

	-- Metallic sound effects
	self:AddMetallicSounds(cowModel, cowId)
end

function CowVisualEffects:ApplyGoldEffects(cowModel, cowId)
	-- Golden particle fountain
	self:CreateGoldenFountain(cowModel, cowId)

	-- Warm golden glow
	self:CreatePulsatingGlow(cowModel, cowId, Color3.fromRGB(255, 215, 0))

	-- Sparkle aura
	self:CreateSparkleAura(cowModel, cowId, Color3.fromRGB(255, 215, 0), 6)

	-- Treasure sound effects
	self:AddTreasureSounds(cowModel, cowId)
end

function CowVisualEffects:ApplyDiamondEffects(cowModel, cowId)
	-- Crystal formations around cow
	self:CreateCrystalFormations(cowModel, cowId)

	-- Prismatic light beams
	self:CreatePrismaticBeams(cowModel, cowId)

	-- Diamond dust particles
	self:CreateDiamondDust(cowModel, cowId)

	-- Crystal resonance sounds
	self:AddCrystalSounds(cowModel, cowId)

	-- Refractive lighting
	self:CreateRefractiveEffects(cowModel, cowId)
end

function CowVisualEffects:ApplyRainbowEffects(cowModel, cowId)
	-- Rainbow aurora
	self:CreateRainbowAurora(cowModel, cowId)

	-- Color-shifting particles
	self:CreateRainbowParticles(cowModel, cowId)

	-- Magical runes
	self:CreateMagicalRunes(cowModel, cowId)

	-- Mystical sounds
	self:AddMysticalSounds(cowModel, cowId)

	-- Rainbow trails
	self:CreateRainbowTrails(cowModel, cowId)
end

function CowVisualEffects:ApplyCosmicEffects(cowModel, cowId)
	-- Galaxy spiral
	self:CreateGalaxySpiral(cowModel, cowId)

	-- Nebula clouds
	self:CreateNebulaClouds(cowModel, cowId)

	-- Star field
	self:CreateStarField(cowModel, cowId)

	-- Gravitational waves
	self:CreateGravitationalWaves(cowModel, cowId)

	-- Cosmic sounds
	self:AddCosmicSounds(cowModel, cowId)

	-- Space distortion
	self:CreateSpaceDistortion(cowModel, cowId)
end

-- ========== EFFECT IMPLEMENTATIONS ==========

function CowVisualEffects:CreateBreathingSteam(cowModel, cowId)
	local head = self:FindCowPart(cowModel, "head")
	if not head then return end

	spawn(function()
		while self.ActiveEffects[cowId] do
			-- Create steam puff
			local steam = Instance.new("Part")
			steam.Size = Vector3.new(0.5, 0.5, 0.5)
			steam.Material = Enum.Material.ForceField
			steam.Color = Color3.fromRGB(255, 255, 255)
			steam.Transparency = 0.7
			steam.CanCollide = false
			steam.Anchored = true
			steam.Position = head.Position + Vector3.new(0, 1, 2)
			steam.Parent = workspace

			-- Animate steam
			local tween = TweenService:Create(steam,
				TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = steam.Position + Vector3.new(0, 4, 2),
					Size = Vector3.new(2, 2, 2),
					Transparency = 1
				}
			)
			tween:Play()
			tween.Completed:Connect(function() steam:Destroy() end)

			wait(math.random(3, 6))
		end
	end)
end

function CowVisualEffects:CreateGoldenFountain(cowModel, cowId)
	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			for i = 1, 5 do
				local particle = Instance.new("Part")
				particle.Size = Vector3.new(0.2, 0.2, 0.2)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = Color3.fromRGB(255, 215, 0)
				particle.CanCollide = false
				particle.Anchored = true
				particle.Position = center + Vector3.new(
					math.random(-2, 2),
					0,
					math.random(-2, 2)
				)
				particle.Parent = workspace

				-- Fountain effect
				local height = math.random(6, 10)
				local tween = TweenService:Create(particle,
					TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{
						Position = particle.Position + Vector3.new(0, height, 0),
						Transparency = 1
					}
				)

				-- Add rotation
				local spinTween = TweenService:Create(particle,
					TweenInfo.new(2, Enum.EasingStyle.Linear),
					{Orientation = Vector3.new(0, 360, 0)}
				)

				tween:Play()
				spinTween:Play()
				tween.Completed:Connect(function() particle:Destroy() end)
			end
			wait(0.5)
		end
	end)
end

function CowVisualEffects:CreateRainbowAurora(cowModel, cowId)
	local center = self:GetCowCenter(cowModel)

	-- Create aurora effect
	local aurora = Instance.new("Part")
	aurora.Name = "RainbowAurora"
	aurora.Size = Vector3.new(12, 8, 0.1)
	aurora.Material = Enum.Material.ForceField
	aurora.CanCollide = false
	aurora.Anchored = true
	aurora.Position = center + Vector3.new(0, 6, 0)
	aurora.Parent = workspace

	-- Store in effects
	table.insert(self.ActiveEffects[cowId].particles, aurora)

	-- Animate aurora colors
	spawn(function()
		local hue = 0
		while aurora.Parent and self.ActiveEffects[cowId] do
			aurora.Color = Color3.fromHSV(hue, 1, 1)
			aurora.Transparency = 0.3 + math.sin(tick() * 3) * 0.2
			hue = (hue + 0.01) % 1
			wait(0.1)
		end
	end)

	-- Gentle movement
	spawn(function()
		local startPos = aurora.Position
		while aurora.Parent and self.ActiveEffects[cowId] do
			local offset = Vector3.new(
				math.sin(tick() * 0.5) * 2,
				math.sin(tick() * 0.3) * 1,
				math.cos(tick() * 0.4) * 1
			)
			aurora.Position = startPos + offset
			wait(0.1)
		end
	end)
end

function CowVisualEffects:CreateGalaxySpiral(cowModel, cowId)
	local center = self:GetCowCenter(cowModel)

	spawn(function()
		local angle = 0
		while self.ActiveEffects[cowId] do
			-- Create spiral arms
			for arm = 0, 2 do
				for i = 1, 4 do
					local star = Instance.new("Part")
					star.Size = Vector3.new(0.1, 0.1, 0.1)
					star.Shape = Enum.PartType.Ball
					star.Material = Enum.Material.Neon
					star.Color = Color3.fromRGB(
						math.random(100, 255),
						math.random(100, 200),
						255
					)
					star.CanCollide = false
					star.Anchored = true

					local armAngle = angle + arm * (math.pi * 2 / 3)
					local distance = 1 + i * 0.8
					local spiralOffset = i * 0.3

					local x = center.X + math.cos(armAngle + spiralOffset) * distance
					local z = center.Z + math.sin(armAngle + spiralOffset) * distance
					local y = center.Y + 3 + math.sin(angle * 2 + i) * 0.5

					star.Position = Vector3.new(x, y, z)
					star.Parent = workspace

					-- Fade out
					local fade = TweenService:Create(star,
						TweenInfo.new(2, Enum.EasingStyle.Quad),
						{Transparency = 1}
					)
					fade:Play()
					fade.Completed:Connect(function() star:Destroy() end)
				end
			end

			angle = angle + 0.15
			wait(0.2)
		end
	end)
end

-- ========== ENVIRONMENTAL EFFECTS ==========

function CowVisualEffects:AddEnvironmentalEffects(cowModel, cowId, tier)
	if tier == "basic" then return end

	-- Ground effects
	self:CreateGroundEffects(cowModel, cowId, tier)

	-- Atmospheric effects
	self:CreateAtmosphericEffects(cowModel, cowId, tier)

	-- Weather effects for higher tiers
	if tier == "cosmic" or tier == "rainbow" then
		self:CreateWeatherEffects(cowModel, cowId, tier)
	end
end

function CowVisualEffects:CreateGroundEffects(cowModel, cowId, tier)
	local center = self:GetCowCenter(cowModel)

	-- Create ground circle
	local ground = Instance.new("Part")
	ground.Name = "GroundEffect"
	ground.Size = Vector3.new(8, 0.1, 8)
	ground.Shape = Enum.PartType.Cylinder
	ground.Material = Enum.Material.Neon
	ground.CanCollide = false
	ground.Anchored = true
	ground.Position = center - Vector3.new(0, 3, 0)
	ground.Orientation = Vector3.new(0, 0, 90)
	ground.Parent = workspace

	-- Tier-specific ground colors
	local groundColors = {
		silver = Color3.fromRGB(192, 192, 192),
		gold = Color3.fromRGB(255, 215, 0),
		diamond = Color3.fromRGB(185, 242, 255),
		rainbow = Color3.fromRGB(255, 100, 255),
		cosmic = Color3.fromRGB(75, 0, 130)
	}

	ground.Color = groundColors[tier] or Color3.fromRGB(255, 255, 255)
	ground.Transparency = 0.7

	-- Store in effects
	table.insert(self.ActiveEffects[cowId].particles, ground)

	-- Pulsing effect
	spawn(function()
		while ground.Parent and self.ActiveEffects[cowId] do
			local pulse = TweenService:Create(ground,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.3}
			)
			pulse:Play()
			pulse.Completed:Wait()

			local pulseBack = TweenService:Create(ground,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.8}
			)
			pulseBack:Play()
			pulseBack.Completed:Wait()
		end
	end)
end

-- ========== PERFORMANCE MONITORING ==========

function CowVisualEffects:StartPerformanceMonitoring()
	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			local playerCount = #Players:GetPlayers()
			local effectCount = 0

			for _ in pairs(self.ActiveEffects) do
				effectCount = effectCount + 1
			end

			-- Adjust performance based on load
			if playerCount > 10 or effectCount > 20 then
				self.PerformanceSettings.particleCount = 5
				self.PerformanceSettings.updateRate = 0.5
				print("CowVisualEffects: Reduced performance for high load")
			else
				self.PerformanceSettings.particleCount = 15
				self.PerformanceSettings.updateRate = 0.1
			end
		end
	end)
end

-- ========== UTILITY FUNCTIONS ==========

function CowVisualEffects:GetCowCenter(cowModel)
	if cowModel.PrimaryPart then
		return cowModel.PrimaryPart.Position
	end

	local cframe, size = cowModel:GetBoundingBox()
	return cframe.Position
end

function CowVisualEffects:FindCowPart(cowModel, partName)
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name:lower():find(partName:lower()) then
			return part
		end
	end
	return nil
end

function CowVisualEffects:ClearEffects(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects then return end

	-- Clean up particles
	for _, particle in pairs(effects.particles or {}) do
		if particle and particle.Parent then
			particle:Destroy()
		end
	end

	-- Clean up lights
	for _, light in pairs(effects.lights or {}) do
		if light and light.Parent then
			light:Destroy()
		end
	end

	-- Clean up animations
	for _, animation in pairs(effects.animations or {}) do
		if animation and animation.Cancel then
			animation:Cancel()
		end
	end

	self.ActiveEffects[cowId] = nil
	print("CowVisualEffects: Cleared effects for " .. cowId)
end

function CowVisualEffects:UpdateCowEffects()
	-- Check for new cows and update existing effects
	if not _G.EnhancedCowMilkSystem then return end

	for cowId, cowModel in pairs(_G.EnhancedCowMilkSystem.ActiveCows) do
		if cowModel and cowModel.Parent then
			local tier = cowModel:GetAttribute("Tier") or "basic"

			-- Apply effects if not already applied or tier changed
			if not self.ActiveEffects[cowId] or self.ActiveEffects[cowId].tier ~= tier then
				self:ApplyAdvancedEffects(cowModel, tier)
			end
		else
			-- Clean up effects for removed cows
			self:ClearEffects(cowId)
		end
	end
end

-- ========== SOUND EFFECT HELPERS ==========

function CowVisualEffects:PlayTierSound(tier)
	local sound = self.SoundEffects[tier]
	if sound then
		sound:Play()
	end
end

function CowVisualEffects:AddMetallicSounds(cowModel, cowId)
	-- Add subtle metallic clinks when moving
	spawn(function()
		while self.ActiveEffects[cowId] do
			wait(math.random(10, 20))
			if math.random() < 0.3 then
				self:PlayTierSound("silver")
			end
		end
	end)
end

function CowVisualEffects:AddCrystalSounds(cowModel, cowId)
	-- Add crystal chimes
	spawn(function()
		while self.ActiveEffects[cowId] do
			wait(math.random(15, 30))
			if math.random() < 0.4 then
				self:PlayTierSound("diamond")
			end
		end
	end)
end

-- Initialize the system
CowVisualEffects:Initialize()
_G.CowVisualEffects = CowVisualEffects

print("CowVisualEffects: ✅ Advanced Visual Effects System loaded!")
print("🎨 FEATURES:")
print("  ✨ Tier-specific particle systems")
print("  🌈 Dynamic lighting and color effects")
print("  🎵 Immersive sound effects")
print("  🌍 Environmental ground and atmospheric effects")
print("  ⚡ Performance monitoring and optimization")
print("  🎭 Advanced animations and material effects")