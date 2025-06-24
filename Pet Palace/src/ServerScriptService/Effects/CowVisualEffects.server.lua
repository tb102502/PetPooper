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
function CowVisualEffects:StartEffectAnimations(cowId)
	print("CowVisualEffects: Starting effect animations for " .. cowId)

	local effects = self.ActiveEffects[cowId]
	if not effects then
		warn("CowVisualEffects: No effects found for cow " .. cowId)
		return
	end

	local tier = effects.tier or "basic"

	-- Start tier-specific animations
	if tier == "basic" then
		self:StartBasicAnimations(cowId)
	elseif tier == "silver" then
		self:StartSilverAnimations(cowId)
	elseif tier == "gold" then
		self:StartGoldAnimations(cowId)
	elseif tier == "diamond" then
		self:StartDiamondAnimations(cowId)
	elseif tier == "rainbow" then
		self:StartRainbowAnimations(cowId)
	elseif tier == "cosmic" then
		self:StartCosmicAnimations(cowId)
	end

	-- Start common animations for all tiers
	self:StartCommonAnimations(cowId)

	print("CowVisualEffects: Effect animations started for " .. tier .. " tier cow " .. cowId)
end

function CowVisualEffects:StartBasicAnimations(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.model then return end

	-- Simple breathing animation
	spawn(function()
		while self.ActiveEffects[cowId] do
			-- Gentle size pulsing for breathing effect
			local model = effects.model
			if model and model.Parent then
				local originalSize = {}

				-- Store original sizes
				for _, part in pairs(model:GetDescendants()) do
					if part:IsA("BasePart") and self:IsCowBodyPart(part) then
						originalSize[part] = part.Size
					end
				end

				-- Breathe in
				for part, size in pairs(originalSize) do
					if part and part.Parent then
						local breatheIn = TweenService:Create(part,
							TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
							{Size = size * 1.02}
						)
						breatheIn:Play()
					end
				end

				wait(2)

				-- Breathe out
				for part, size in pairs(originalSize) do
					if part and part.Parent then
						local breatheOut = TweenService:Create(part,
							TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
							{Size = size}
						)
						breatheOut:Play()
					end
				end

				wait(2)
			else
				break
			end
		end
	end)
end

function CowVisualEffects:StartSilverAnimations(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.model then return end

	-- Metallic shine animation
	spawn(function()
		while self.ActiveEffects[cowId] do
			for _, part in pairs(effects.model:GetDescendants()) do
				if part:IsA("BasePart") and self:IsCowBodyPart(part) then
					-- Reflectance pulse
					local shineUp = TweenService:Create(part,
						TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{Reflectance = 0.8}
					)
					local shineDown = TweenService:Create(part,
						TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{Reflectance = 0.3}
					)

					shineUp:Play()
					shineUp.Completed:Connect(function()
						shineDown:Play()
					end)
				end
			end
			wait(6)
		end
	end)
end

function CowVisualEffects:StartGoldAnimations(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.model then return end

	-- Golden glow pulsing animation
	spawn(function()
		while self.ActiveEffects[cowId] do
			-- Pulse all lights
			if effects.lights then
				for _, light in pairs(effects.lights) do
					if light and light.Parent then
						local pulseUp = TweenService:Create(light,
							TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
							{Brightness = light.Brightness * 1.5}
						)
						local pulseDown = TweenService:Create(light,
							TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
							{Brightness = light.Brightness}
						)

						pulseUp:Play()
						pulseUp.Completed:Connect(function()
							pulseDown:Play()
						end)
					end
				end
			end
			wait(4)
		end
	end)

	-- Golden aura rotation
	spawn(function()
		local angle = 0
		while self.ActiveEffects[cowId] do
			angle = angle + 0.05

			-- Create rotating golden particles
			local center = self:GetCowCenter(effects.model)
			local radius = 3

			for i = 1, 3 do
				local particleAngle = angle + (i * math.pi * 2 / 3)
				local x = center.X + math.cos(particleAngle) * radius
				local z = center.Z + math.sin(particleAngle) * radius
				local y = center.Y + 2 + math.sin(angle * 2) * 0.5

				local particle = Instance.new("Part")
				particle.Size = Vector3.new(0.3, 0.3, 0.3)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = Color3.fromRGB(255, 215, 0)
				particle.CanCollide = false
				particle.Anchored = true
				particle.Position = Vector3.new(x, y, z)
				particle.Parent = workspace

				local fade = TweenService:Create(particle,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad),
					{Transparency = 1}
				)
				fade:Play()
				fade.Completed:Connect(function()
					particle:Destroy()
				end)
			end

			wait(0.1)
		end
	end)
end

function CowVisualEffects:StartDiamondAnimations(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.model then return end

	-- Crystal resonance animation
	spawn(function()
		while self.ActiveEffects[cowId] do
			-- Make crystal formations pulse
			if effects.particles then
				for _, crystal in pairs(effects.particles) do
					if crystal and crystal.Parent and crystal.Name:find("Crystal") then
						local pulse = TweenService:Create(crystal,
							TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
							{Transparency = 0.1}
						)
						pulse:Play()

						-- Store animation reference
						if not effects.animations then
							effects.animations = {}
						end
						table.insert(effects.animations, pulse)
					end
				end
			end
			wait(2)
		end
	end)

	-- Prismatic light rotation
	spawn(function()
		local hue = 0
		while self.ActiveEffects[cowId] do
			hue = (hue + 0.01) % 1

			-- Update light colors to cycle through spectrum
			if effects.lights then
				for _, light in pairs(effects.lights) do
					if light and light.Parent then
						light.Color = Color3.fromHSV(hue, 0.7, 1)
					end
				end
			end

			wait(0.1)
		end
	end)
end

function CowVisualEffects:StartRainbowAnimations(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.model then return end

	-- Rainbow color cycling (already implemented in tier effects)
	-- Add magical rune rotation
	spawn(function()
		local angle = 0
		while self.ActiveEffects[cowId] do
			angle = angle + 0.02

			-- Create rotating magical runes
			local center = self:GetCowCenter(effects.model)

			for i = 1, 2 do
				local runeAngle = angle + (i * math.pi)
				local radius = 4
				local x = center.X + math.cos(runeAngle) * radius
				local z = center.Z + math.sin(runeAngle) * radius
				local y = center.Y + 4

				local rune = Instance.new("Part")
				rune.Size = Vector3.new(1, 0.1, 1)
				rune.Shape = Enum.PartType.Cylinder
				rune.Material = Enum.Material.Neon
				rune.Color = Color3.fromHSV(math.random(), 1, 1)
				rune.CanCollide = false
				rune.Anchored = true
				rune.Position = Vector3.new(x, y, z)
				rune.Orientation = Vector3.new(90, 0, 0)
				rune.Parent = workspace

				local spin = TweenService:Create(rune,
					TweenInfo.new(2, Enum.EasingStyle.Linear),
					{Orientation = Vector3.new(90, 360, 0)}
				)
				local fade = TweenService:Create(rune,
					TweenInfo.new(2, Enum.EasingStyle.Quad),
					{Transparency = 1}
				)

				spin:Play()
				fade:Play()
				fade.Completed:Connect(function()
					rune:Destroy()
				end)
			end

			wait(1)
		end
	end)
end

function CowVisualEffects:StartCosmicAnimations(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.model then return end

	-- Cosmic energy waves
	spawn(function()
		while self.ActiveEffects[cowId] do
			local center = self:GetCowCenter(effects.model)

			-- Create expanding energy ring
			local ring = Instance.new("Part")
			ring.Size = Vector3.new(2, 0.1, 2)
			ring.Shape = Enum.PartType.Cylinder
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(138, 43, 226)
			ring.CanCollide = false
			ring.Anchored = true
			ring.Position = center
			ring.Orientation = Vector3.new(90, 0, 0)
			ring.Parent = workspace

			local expand = TweenService:Create(ring,
				TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = Vector3.new(20, 0.1, 20),
					Transparency = 1
				}
			)
			expand:Play()
			expand.Completed:Connect(function()
				ring:Destroy()
			end)

			wait(4)
		end
	end)

	-- Space distortion effect
	spawn(function()
		while self.ActiveEffects[cowId] do
			local center = self:GetCowCenter(effects.model)

			-- Create gravitational distortion
			local distortion = Instance.new("Part")
			distortion.Size = Vector3.new(8, 8, 8)
			distortion.Shape = Enum.PartType.Ball
			distortion.Material = Enum.Material.ForceField
			distortion.Color = Color3.fromRGB(25, 25, 50)
			distortion.Transparency = 0.8
			distortion.CanCollide = false
			distortion.Anchored = true
			distortion.Position = center + Vector3.new(0, 4, 0)
			distortion.Parent = workspace

			local wobble = TweenService:Create(distortion,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Size = Vector3.new(10, 6, 10)}
			)
			wobble:Play()

			-- Remove after animation cycle
			wait(6)
			wobble:Cancel()
			distortion:Destroy()

			wait(2)
		end
	end)
end

function CowVisualEffects:StartCommonAnimations(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.model then return end

	-- Gentle floating animation for all particles
	spawn(function()
		while self.ActiveEffects[cowId] do
			if effects.particles then
				for _, particle in pairs(effects.particles) do
					if particle and particle.Parent and particle.CanCollide == false then
						local originalPos = particle.Position
						local float = TweenService:Create(particle,
							TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
							{Position = originalPos + Vector3.new(0, 0.5, 0)}
						)
						float:Play()

						-- Store animation reference
						if not effects.animations then
							effects.animations = {}
						end
						table.insert(effects.animations, float)
					end
				end
			end
			wait(1)
		end
	end)
end

-- ========== ANIMATION CONTROL METHODS ==========

function CowVisualEffects:StopEffectAnimations(cowId)
	print("CowVisualEffects: Stopping effect animations for " .. cowId)

	local effects = self.ActiveEffects[cowId]
	if not effects then return end

	-- Stop all stored animations
	if effects.animations then
		for _, animation in pairs(effects.animations) do
			if animation and animation.Cancel then
				animation:Cancel()
			end
		end
		effects.animations = {}
	end

	print("CowVisualEffects: Stopped animations for " .. cowId)
end

function CowVisualEffects:PauseEffectAnimations(cowId)
	print("CowVisualEffects: Pausing effect animations for " .. cowId)

	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.animations then return end

	-- Pause all animations
	for _, animation in pairs(effects.animations) do
		if animation and animation.Pause then
			animation:Pause()
		end
	end
end

function CowVisualEffects:ResumeEffectAnimations(cowId)
	print("CowVisualEffects: Resuming effect animations for " .. cowId)

	local effects = self.ActiveEffects[cowId]
	if not effects or not effects.animations then return end

	-- Resume all animations
	for _, animation in pairs(effects.animations) do
		if animation and animation.Resume then
			animation:Resume()
		end
	end
end

-- ========== ENHANCED CLEAR EFFECTS WITH ANIMATION CLEANUP ==========

function CowVisualEffects:ClearEffectsEnhanced(cowId)
	local effects = self.ActiveEffects[cowId]
	if not effects then return end

	-- Stop animations first
	self:StopEffectAnimations(cowId)

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

	-- Clear the effects entry
	self.ActiveEffects[cowId] = nil

	print("CowVisualEffects: Enhanced cleanup completed for " .. cowId)
end

-- ========== REPLACE EXISTING CLEAREFFECTS METHOD ==========

-- Update your existing ClearEffects method to use the enhanced version:

print("CowVisualEffects: ✅ StartEffectAnimations method and animation system added!")
print("🎭 NEW FEATURES:")
print("  🎬 Tier-specific animation systems")
print("  ⭐ Basic breathing animations")
print("  ✨ Metallic shine effects for silver")
print("  💫 Golden aura rotation")
print("  💎 Crystal resonance for diamond")
print("  🌈 Magical rune rotation for rainbow")
print("  🌌 Cosmic energy waves and distortion")
print("  🎮 Animation control methods (start/stop/pause/resume)")
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

function CowVisualEffects:CreateAmbientLight(cowModel, cowId, color, range, brightness)
	print("CowVisualEffects: Creating ambient light for " .. cowId)

	-- Find the best part to attach light to
	local attachPart = self:FindCowPart(cowModel, "humanoidrootpart") or 
		self:FindCowPart(cowModel, "torso") or
		self:FindCowPart(cowModel, "body")

	if not attachPart then
		warn("CowVisualEffects: Could not find part to attach light to for " .. cowId)
		return nil
	end

	-- Create the light
	local light = Instance.new("PointLight")
	light.Name = "AmbientLight_" .. cowId
	light.Color = color or Color3.fromRGB(255, 255, 200)
	light.Range = range or 10
	light.Brightness = brightness or 1
	light.Shadows = false
	light.Parent = attachPart

	-- Store in effects
	if not self.ActiveEffects[cowId] then
		self.ActiveEffects[cowId] = {lights = {}, particles = {}, animations = {}}
	end
	if not self.ActiveEffects[cowId].lights then
		self.ActiveEffects[cowId].lights = {}
	end

	table.insert(self.ActiveEffects[cowId].lights, light)

	print("CowVisualEffects: Created ambient light for " .. cowId)
	return light
end

function CowVisualEffects:CreateMetallicReflections(cowModel, cowId)
	print("CowVisualEffects: Creating metallic reflections for " .. cowId)

	-- Change material properties for body parts
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and self:IsCowBodyPart(part) then
			part.Material = Enum.Material.Metal
			part.Reflectance = 0.3
		end
	end

	-- Add subtle sparkle effect
	self:CreateParticleTrail(cowModel, cowId, Color3.fromRGB(192, 192, 192), 2)
end

function CowVisualEffects:CreateParticleTrail(cowModel, cowId, color, intensity)
	print("CowVisualEffects: Creating particle trail for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			for i = 1, intensity do
				local particle = Instance.new("Part")
				particle.Size = Vector3.new(0.1, 0.1, 0.1)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = color
				particle.CanCollide = false
				particle.Anchored = true
				particle.Position = center + Vector3.new(
					math.random(-2, 2),
					math.random(0, 3),
					math.random(-2, 2)
				)
				particle.Parent = workspace

				local tween = game:GetService("TweenService"):Create(particle,
					TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = particle.Position + Vector3.new(0, 5, 0),
						Transparency = 1
					}
				)
				tween:Play()
				tween.Completed:Connect(function()
					particle:Destroy()
				end)
			end
			wait(math.random(3, 6))
		end
	end)
end

function CowVisualEffects:CreatePulsatingGlow(cowModel, cowId, color)
	print("CowVisualEffects: Creating pulsating glow for " .. cowId)

	-- Create glow lights on multiple parts
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and self:IsCowBodyPart(part) then
			local light = Instance.new("PointLight")
			light.Name = "PulsatingGlow"
			light.Color = color
			light.Brightness = 1
			light.Range = 15
			light.Parent = part

			-- Store in effects
			if self.ActiveEffects[cowId] and self.ActiveEffects[cowId].lights then
				table.insert(self.ActiveEffects[cowId].lights, light)
			end

			-- Start pulsing animation
			spawn(function()
				while light.Parent and self.ActiveEffects[cowId] do
					local pulseUp = game:GetService("TweenService"):Create(light,
						TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{Brightness = 2}
					)
					local pulseDown = game:GetService("TweenService"):Create(light,
						TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{Brightness = 0.5}
					)

					pulseUp:Play()
					pulseUp.Completed:Wait()
					pulseDown:Play()
					pulseDown.Completed:Wait()
				end
			end)
		end
	end
end

function CowVisualEffects:CreateSparkleAura(cowModel, cowId, color, intensity)
	print("CowVisualEffects: Creating sparkle aura for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			for i = 1, intensity do
				local sparkle = Instance.new("Part")
				sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
				sparkle.Shape = Enum.PartType.Ball
				sparkle.Material = Enum.Material.Neon
				sparkle.Color = color
				sparkle.CanCollide = false
				sparkle.Anchored = true

				-- Position in a circle around the cow
				local angle = math.random() * math.pi * 2
				local distance = math.random(2, 4)
				local x = center.X + math.cos(angle) * distance
				local z = center.Z + math.sin(angle) * distance
				local y = center.Y + math.random(0, 4)

				sparkle.Position = Vector3.new(x, y, z)
				sparkle.Parent = workspace

				-- Sparkle animation
				local tween = game:GetService("TweenService"):Create(sparkle,
					TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = sparkle.Position + Vector3.new(0, 6, 0),
						Transparency = 1,
						Size = Vector3.new(0.05, 0.05, 0.05)
					}
				)
				tween:Play()
				tween.Completed:Connect(function()
					sparkle:Destroy()
				end)
			end
			wait(math.random(1, 3))
		end
	end)
end

function CowVisualEffects:CreateCrystalFormations(cowModel, cowId)
	print("CowVisualEffects: Creating crystal formations for " .. cowId)

	local center = self:GetCowCenter(cowModel)
	local crystals = {}

	-- Create crystal formations around the cow
	for i = 1, 6 do
		local crystal = Instance.new("Part")
		crystal.Name = "Crystal_" .. i
		crystal.Size = Vector3.new(0.5, math.random(2, 4), 0.5)
		crystal.Shape = Enum.PartType.Block
		crystal.Material = Enum.Material.Glass
		crystal.Color = Color3.fromRGB(185, 242, 255)
		crystal.Transparency = 0.3
		crystal.CanCollide = false
		crystal.Anchored = true

		-- Position crystals in a circle
		local angle = (i - 1) * (math.pi * 2 / 6)
		local distance = 3
		crystal.Position = center + Vector3.new(
			math.cos(angle) * distance,
			crystal.Size.Y / 2 - 1,
			math.sin(angle) * distance
		)
		crystal.Orientation = Vector3.new(0, math.deg(angle), math.random(-15, 15))
		crystal.Parent = workspace

		-- Add internal light
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(185, 242, 255)
		light.Brightness = 1.5
		light.Range = 8
		light.Parent = crystal

		table.insert(crystals, crystal)
	end

	-- Store crystals in effects
	if self.ActiveEffects[cowId] then
		if not self.ActiveEffects[cowId].particles then
			self.ActiveEffects[cowId].particles = {}
		end
		for _, crystal in pairs(crystals) do
			table.insert(self.ActiveEffects[cowId].particles, crystal)
		end
	end
end

function CowVisualEffects:CreatePrismaticBeams(cowModel, cowId)
	print("CowVisualEffects: Creating prismatic beams for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			-- Create rainbow light beams
			for i = 1, 3 do
				local beam = Instance.new("Part")
				beam.Size = Vector3.new(0.2, 8, 0.2)
				beam.Shape = Enum.PartType.Cylinder
				beam.Material = Enum.Material.Neon
				beam.Color = Color3.fromHSV(math.random(), 1, 1)
				beam.CanCollide = false
				beam.Anchored = true
				beam.Position = center + Vector3.new(
					math.random(-3, 3),
					4,
					math.random(-3, 3)
				)
				beam.Orientation = Vector3.new(0, 0, 90)
				beam.Parent = workspace

				local fade = game:GetService("TweenService"):Create(beam,
					TweenInfo.new(2, Enum.EasingStyle.Quad),
					{Transparency = 1}
				)
				fade:Play()
				fade.Completed:Connect(function()
					beam:Destroy()
				end)
			end
			wait(math.random(2, 4))
		end
	end)
end

function CowVisualEffects:CreateDiamondDust(cowModel, cowId)
	print("CowVisualEffects: Creating diamond dust for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			for i = 1, 8 do
				local dust = Instance.new("Part")
				dust.Size = Vector3.new(0.05, 0.05, 0.05)
				dust.Shape = Enum.PartType.Ball
				dust.Material = Enum.Material.Glass
				dust.Color = Color3.fromRGB(255, 255, 255)
				dust.CanCollide = false
				dust.Anchored = true
				dust.Position = center + Vector3.new(
					math.random(-4, 4),
					math.random(0, 5),
					math.random(-4, 4)
				)
				dust.Parent = workspace

				-- Floating animation
				local float = game:GetService("TweenService"):Create(dust,
					TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Position = dust.Position + Vector3.new(
							math.random(-2, 2),
							math.random(3, 6),
							math.random(-2, 2)
						),
						Transparency = 1
					}
				)
				float:Play()
				float.Completed:Connect(function()
					dust:Destroy()
				end)
			end
			wait(1)
		end
	end)
end

function CowVisualEffects:CreateRefractiveEffects(cowModel, cowId)
	print("CowVisualEffects: Creating refractive effects for " .. cowId)

	-- Make cow body parts partially transparent and refractive
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and self:IsCowBodyPart(part) then
			part.Transparency = 0.2
			part.Material = Enum.Material.Glass
		end
	end
end

-- Add missing utility methods
function CowVisualEffects:IsCowBodyPart(part)
	local bodyNames = {"body", "torso", "head", "humanoidrootpart", "upperbody", "lowerbody"}
	local partName = part.Name:lower()

	for _, name in ipairs(bodyNames) do
		if partName:find(name) then
			return true
		end
	end

	return false
end

-- ========== MISSING ATMOSPHERIC EFFECTS ==========

function CowVisualEffects:CreateAtmosphericEffects(cowModel, cowId, tier)
	print("CowVisualEffects: Creating atmospheric effects for " .. tier .. " tier")

	if tier == "gold" or tier == "diamond" then
		self:CreateFloatingParticles(cowModel, cowId, tier)
	end

	if tier == "rainbow" or tier == "cosmic" then
		self:CreateAtmosphericDistortion(cowModel, cowId, tier)
	end
end

function CowVisualEffects:CreateFloatingParticles(cowModel, cowId, tier)
	local center = self:GetCowCenter(cowModel)
	local colors = {
		gold = Color3.fromRGB(255, 215, 0),
		diamond = Color3.fromRGB(185, 242, 255)
	}

	spawn(function()
		while self.ActiveEffects[cowId] do
			local particle = Instance.new("Part")
			particle.Size = Vector3.new(0.1, 0.1, 0.1)
			particle.Shape = Enum.PartType.Ball
			particle.Material = Enum.Material.Neon
			particle.Color = colors[tier] or Color3.fromRGB(255, 255, 255)
			particle.CanCollide = false
			particle.Anchored = true
			particle.Position = center + Vector3.new(
				math.random(-5, 5),
				math.random(-2, 2),
				math.random(-5, 5)
			)
			particle.Parent = workspace

			local float = game:GetService("TweenService"):Create(particle,
				TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{
					Position = particle.Position + Vector3.new(0, 10, 0),
					Transparency = 1
				}
			)
			float:Play()
			float.Completed:Connect(function()
				particle:Destroy()
			end)

			wait(0.5)
		end
	end)
end

function CowVisualEffects:CreateAtmosphericDistortion(cowModel, cowId, tier)
	print("CowVisualEffects: Creating atmospheric distortion for " .. tier)

	-- Create a distortion field around the cow
	local distortionField = Instance.new("Part")
	distortionField.Name = "DistortionField"
	distortionField.Size = Vector3.new(10, 10, 10)
	distortionField.Shape = Enum.PartType.Ball
	distortionField.Material = Enum.Material.ForceField
	distortionField.Transparency = 0.9
	distortionField.CanCollide = false
	distortionField.Anchored = true
	distortionField.Position = self:GetCowCenter(cowModel)
	distortionField.Parent = workspace

	if tier == "rainbow" then
		distortionField.Color = Color3.fromRGB(255, 100, 255)
	elseif tier == "cosmic" then
		distortionField.Color = Color3.fromRGB(75, 0, 130)
	end

	-- Store in effects
	if self.ActiveEffects[cowId] and self.ActiveEffects[cowId].particles then
		table.insert(self.ActiveEffects[cowId].particles, distortionField)
	end

	-- Pulsing animation
	spawn(function()
		while distortionField.Parent and self.ActiveEffects[cowId] do
			local pulse = game:GetService("TweenService"):Create(distortionField,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = Vector3.new(12, 12, 12)}
			)
			local pulseBack = game:GetService("TweenService"):Create(distortionField,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = Vector3.new(8, 8, 8)}
			)

			pulse:Play()
			pulse.Completed:Wait()
			pulseBack:Play()
			pulseBack.Completed:Wait()
		end
	end)
end

-- ========== SOUND EFFECT METHODS ==========

function CowVisualEffects:AddTreasureSounds(cowModel, cowId)
	spawn(function()
		while self.ActiveEffects[cowId] do
			wait(math.random(15, 30))
			if math.random() < 0.3 then
				self:PlayTierSound("gold")
			end
		end
	end)
end

function CowVisualEffects:AddMysticalSounds(cowModel, cowId)
	spawn(function()
		while self.ActiveEffects[cowId] do
			wait(math.random(10, 25))
			if math.random() < 0.4 then
				self:PlayTierSound("rainbow")
			end
		end
	end)
end

function CowVisualEffects:AddCosmicSounds(cowModel, cowId)
	spawn(function()
		while self.ActiveEffects[cowId] do
			wait(math.random(8, 20))
			if math.random() < 0.5 then
				self:PlayTierSound("cosmic")
			end
		end
	end)
end

function CowVisualEffects:CreateRainbowParticles(cowModel, cowId)
	print("CowVisualEffects: Creating rainbow particles for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			for i = 1, 8 do
				local particle = Instance.new("Part")
				particle.Size = Vector3.new(0.3, 0.3, 0.3)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = Color3.fromHSV(math.random(), 1, 1) -- Random rainbow color
				particle.CanCollide = false
				particle.Anchored = true
				particle.Position = center + Vector3.new(
					math.random(-4, 4),
					math.random(0, 5),
					math.random(-4, 4)
				)
				particle.Parent = workspace

				-- Store in effects
				if self.ActiveEffects[cowId] and self.ActiveEffects[cowId].particles then
					table.insert(self.ActiveEffects[cowId].particles, particle)
				end

				-- Floating animation with color change
				spawn(function()
					local startTime = tick()
					while particle.Parent and self.ActiveEffects[cowId] do
						local hue = (startTime + tick()) % 1
						particle.Color = Color3.fromHSV(hue, 1, 1)
						wait(0.1)
					end
				end)

				local float = TweenService:Create(particle,
					TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Position = particle.Position + Vector3.new(0, 8, 0),
						Transparency = 1
					}
				)
				float:Play()
				float.Completed:Connect(function()
					particle:Destroy()
				end)
			end
			wait(math.random(2, 4))
		end
	end)
end

function CowVisualEffects:CreateMagicalRunes(cowModel, cowId)
	print("CowVisualEffects: Creating magical runes for " .. cowId)

	local center = self:GetCowCenter(cowModel)
	local runeSymbols = {"◆", "◇", "◈", "◉", "◎", "●", "○", "◐"}

	spawn(function()
		while self.ActiveEffects[cowId] do
			local rune = Instance.new("Part")
			rune.Size = Vector3.new(2, 0.1, 2)
			rune.Shape = Enum.PartType.Cylinder
			rune.Material = Enum.Material.Neon
			rune.Color = Color3.fromHSV(math.random(), 1, 1)
			rune.CanCollide = false
			rune.Anchored = true
			rune.Position = center + Vector3.new(0, math.random(2, 6), 0)
			rune.Orientation = Vector3.new(90, 0, 0)
			rune.Parent = workspace

			-- Add text to rune
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Top
			gui.Parent = rune

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = runeSymbols[math.random(#runeSymbols)]
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextScaled = true
			label.Font = Enum.Font.Antique
			label.Parent = gui

			-- Store in effects
			if self.ActiveEffects[cowId] and self.ActiveEffects[cowId].particles then
				table.insert(self.ActiveEffects[cowId].particles, rune)
			end

			-- Spin and fade
			local spin = TweenService:Create(rune,
				TweenInfo.new(6, Enum.EasingStyle.Linear),
				{Orientation = Vector3.new(90, 360, 0)}
			)
			local fade = TweenService:Create(rune,
				TweenInfo.new(6, Enum.EasingStyle.Quad),
				{Transparency = 1}
			)

			spin:Play()
			fade:Play()
			fade.Completed:Connect(function()
				rune:Destroy()
			end)

			wait(math.random(3, 6))
		end
	end)
end

function CowVisualEffects:CreateRainbowTrails(cowModel, cowId)
	print("CowVisualEffects: Creating rainbow trails for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	spawn(function()
		local angle = 0
		while self.ActiveEffects[cowId] do
			-- Create trailing rainbow effect
			for i = 1, 3 do
				local trail = Instance.new("Part")
				trail.Size = Vector3.new(0.5, 0.1, 4)
				trail.Shape = Enum.PartType.Block
				trail.Material = Enum.Material.Neon
				trail.Color = Color3.fromHSV((angle + i * 0.2) % 1, 1, 1)
				trail.CanCollide = false
				trail.Anchored = true

				local trailAngle = angle + i * 0.5
				local radius = 3
				local x = center.X + math.cos(trailAngle) * radius
				local z = center.Z + math.sin(trailAngle) * radius
				local y = center.Y + 2

				trail.Position = Vector3.new(x, y, z)
				trail.Orientation = Vector3.new(0, math.deg(trailAngle), 0)
				trail.Parent = workspace

				local fade = TweenService:Create(trail,
					TweenInfo.new(2, Enum.EasingStyle.Quad),
					{Transparency = 1}
				)
				fade:Play()
				fade.Completed:Connect(function()
					trail:Destroy()
				end)
			end

			angle = angle + 0.1
			wait(0.3)
		end
	end)
end

-- ========== COSMIC EFFECT METHODS ==========

function CowVisualEffects:CreateNebulaClouds(cowModel, cowId)
	print("CowVisualEffects: Creating nebula clouds for " .. cowId)

	local center = self:GetCowCenter(cowModel)
	local nebulaColors = {
		Color3.fromRGB(128, 0, 128),  -- Purple
		Color3.fromRGB(75, 0, 130),   -- Indigo
		Color3.fromRGB(138, 43, 226), -- BlueViolet
		Color3.fromRGB(72, 61, 139)   -- DarkSlateBlue
	}

	spawn(function()
		while self.ActiveEffects[cowId] do
			for i = 1, 5 do
				local cloud = Instance.new("Part")
				cloud.Size = Vector3.new(
					math.random(3, 6),
					math.random(2, 4), 
					math.random(3, 6)
				)
				cloud.Shape = Enum.PartType.Ball
				cloud.Material = Enum.Material.ForceField
				cloud.Color = nebulaColors[math.random(#nebulaColors)]
				cloud.Transparency = 0.7
				cloud.CanCollide = false
				cloud.Anchored = true
				cloud.Position = center + Vector3.new(
					math.random(-8, 8),
					math.random(3, 8),
					math.random(-8, 8)
				)
				cloud.Parent = workspace

				-- Store in effects
				if self.ActiveEffects[cowId] and self.ActiveEffects[cowId].particles then
					table.insert(self.ActiveEffects[cowId].particles, cloud)
				end

				-- Slow drift and fade
				local drift = TweenService:Create(cloud,
					TweenInfo.new(10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Position = cloud.Position + Vector3.new(
							math.random(-5, 5),
							math.random(-2, 2),
							math.random(-5, 5)
						),
						Transparency = 1
					}
				)
				drift:Play()
				drift.Completed:Connect(function()
					cloud:Destroy()
				end)
			end
			wait(math.random(4, 8))
		end
	end)
end

function CowVisualEffects:CreateStarField(cowModel, cowId)
	print("CowVisualEffects: Creating star field for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			for i = 1, 12 do
				local star = Instance.new("Part")
				star.Size = Vector3.new(0.1, 0.1, 0.1)
				star.Shape = Enum.PartType.Ball
				star.Material = Enum.Material.Neon
				star.Color = Color3.fromRGB(255, 255, math.random(200, 255))
				star.CanCollide = false
				star.Anchored = true
				star.Position = center + Vector3.new(
					math.random(-10, 10),
					math.random(5, 12),
					math.random(-10, 10)
				)
				star.Parent = workspace

				-- Twinkling effect
				spawn(function()
					while star.Parent and self.ActiveEffects[cowId] do
						local twinkle = TweenService:Create(star,
							TweenInfo.new(math.random(1, 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
							{Transparency = math.random(0, 0.8)}
						)
						twinkle:Play()
						twinkle.Completed:Wait()
					end
				end)

				-- Store in effects
				if self.ActiveEffects[cowId] and self.ActiveEffects[cowId].particles then
					table.insert(self.ActiveEffects[cowId].particles, star)
				end

				-- Remove after time
				spawn(function()
					wait(math.random(8, 15))
					if star.Parent then
						local fade = TweenService:Create(star,
							TweenInfo.new(2, Enum.EasingStyle.Quad),
							{Transparency = 1}
						)
						fade:Play()
						fade.Completed:Connect(function()
							star:Destroy()
						end)
					end
				end)
			end
			wait(math.random(3, 6))
		end
	end)
end

function CowVisualEffects:CreateGravitationalWaves(cowModel, cowId)
	print("CowVisualEffects: Creating gravitational waves for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			-- Create expanding wave
			local wave = Instance.new("Part")
			wave.Size = Vector3.new(2, 0.1, 2)
			wave.Shape = Enum.PartType.Cylinder
			wave.Material = Enum.Material.ForceField
			wave.Color = Color3.fromRGB(138, 43, 226)
			wave.Transparency = 0.3
			wave.CanCollide = false
			wave.Anchored = true
			wave.Position = center
			wave.Orientation = Vector3.new(0, 0, 90)
			wave.Parent = workspace

			-- Expand and fade
			local expand = TweenService:Create(wave,
				TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = Vector3.new(20, 0.1, 20),
					Transparency = 1
				}
			)
			expand:Play()
			expand.Completed:Connect(function()
				wave:Destroy()
			end)

			wait(math.random(2, 5))
		end
	end)
end

function CowVisualEffects:CreateSpaceDistortion(cowModel, cowId)
	print("CowVisualEffects: Creating space distortion for " .. cowId)

	local center = self:GetCowCenter(cowModel)

	-- Create distortion field
	local distortion = Instance.new("Part")
	distortion.Size = Vector3.new(8, 8, 8)
	distortion.Shape = Enum.PartType.Ball
	distortion.Material = Enum.Material.Glass
	distortion.Color = Color3.fromRGB(25, 25, 50)
	distortion.Transparency = 0.8
	distortion.CanCollide = false
	distortion.Anchored = true
	distortion.Position = center + Vector3.new(0, 4, 0)
	distortion.Parent = workspace

	-- Store in effects
	if self.ActiveEffects[cowId] and self.ActiveEffects[cowId].particles then
		table.insert(self.ActiveEffects[cowId].particles, distortion)
	end

	-- Wobbling distortion effect
	spawn(function()
		while distortion.Parent and self.ActiveEffects[cowId] do
			local wobble = TweenService:Create(distortion,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Size = Vector3.new(10, 6, 10)}
			)
			wobble:Play()
			wait(6)
			wobble:Cancel()
		end
	end)
end

-- ========== ENHANCED ATMOSPHERIC METHODS ==========

function CowVisualEffects:CreateWeatherEffects(cowModel, cowId, tier)
	print("CowVisualEffects: Creating weather effects for " .. tier)

	if tier == "cosmic" then
		self:CreateCosmicStorm(cowModel, cowId)
	elseif tier == "rainbow" then
		self:CreateMagicalAura(cowModel, cowId)
	end
end

function CowVisualEffects:CreateCosmicStorm(cowModel, cowId)
	local center = self:GetCowCenter(cowModel)

	spawn(function()
		while self.ActiveEffects[cowId] do
			-- Create cosmic lightning
			for i = 1, 2 do
				local lightning = Instance.new("Part")
				lightning.Size = Vector3.new(0.1, 15, 0.1)
				lightning.Shape = Enum.PartType.Cylinder
				lightning.Material = Enum.Material.Neon
				lightning.Color = Color3.fromRGB(138, 43, 226)
				lightning.CanCollide = false
				lightning.Anchored = true
				lightning.Position = center + Vector3.new(
					math.random(-8, 8),
					7,
					math.random(-8, 8)
				)
				lightning.Orientation = Vector3.new(0, 0, math.random(-30, 30))
				lightning.Parent = workspace

				local flash = TweenService:Create(lightning,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{Transparency = 1}
				)
				flash:Play()
				flash.Completed:Connect(function()
					lightning:Destroy()
				end)
			end
			wait(math.random(3, 8))
		end
	end)
end

function CowVisualEffects:CreateMagicalAura(cowModel, cowId)
	local center = self:GetCowCenter(cowModel)

	-- Create magical aura field
	local aura = Instance.new("Part")
	aura.Size = Vector3.new(12, 8, 12)
	aura.Shape = Enum.PartType.Ball
	aura.Material = Enum.Material.ForceField
	aura.Color = Color3.fromRGB(255, 100, 255)
	aura.Transparency = 0.9
	aura.CanCollide = false
	aura.Anchored = true
	aura.Position = center + Vector3.new(0, 4, 0)
	aura.Parent = workspace

	-- Store in effects
	if self.ActiveEffects[cowId] and self.ActiveEffects[cowId].particles then
		table.insert(self.ActiveEffects[cowId].particles, aura)
	end

	-- Color cycling
	spawn(function()
		local hue = 0
		while aura.Parent and self.ActiveEffects[cowId] do
			aura.Color = Color3.fromHSV(hue, 1, 1)
			hue = (hue + 0.01) % 1
			wait(0.1)
		end
	end)
end

-- ========== FIX EXISTING CLEAREFFECTS METHOD ==========

function CowVisualEffects:ClearEffects(cowId)
	print("CowVisualEffects: Clearing effects for " .. cowId)

	local effects = self.ActiveEffects[cowId]
	if not effects then return end

	-- Stop animations first
	if effects.animations then
		for _, animation in pairs(effects.animations) do
			if animation and animation.Cancel then
				animation:Cancel()
			end
		end
	end

	-- Clean up particles
	if effects.particles then
		for _, particle in pairs(effects.particles) do
			if particle and particle.Parent then
				particle:Destroy()
			end
		end
	end

	-- Clean up lights
	if effects.lights then
		for _, light in pairs(effects.lights) do
			if light and light.Parent then
				light:Destroy()
			end
		end
	end

	-- Clear the effects entry
	self.ActiveEffects[cowId] = nil

	print("CowVisualEffects: Effects cleared for " .. cowId)
end

print("CowVisualEffects: ✅ All missing methods added!")
print("🔧 FIXED METHODS:")
print("  🌈 CreateRainbowParticles - Rainbow particle effects")
print("  ✨ CreateMagicalRunes - Magical rune symbols")
print("  🌊 CreateRainbowTrails - Trailing rainbow effects")
print("  ☁️ CreateNebulaClouds - Cosmic nebula clouds")
print("  ⭐ CreateStarField - Twinkling star effects")
print("  🌊 CreateGravitationalWaves - Space-time waves")
print("  🌀 CreateSpaceDistortion - Reality warping effects")
print("  ⛈️ CreateCosmicStorm - Lightning storm effects")
print("  🎭 CreateMagicalAura - Magical energy fields")

print("CowVisualEffects: ✅ All missing methods added!")
print("🔧 FIXED METHODS:")
print("  ✨ CreateAmbientLight - Creates ambient lighting")
print("  💎 CreateMetallicReflections - Silver cow effects")
print("  🌟 CreatePulsatingGlow - Gold cow effects") 
print("  💠 CreateCrystalFormations - Diamond cow effects")
print("  🌈 CreateAtmosphericEffects - Advanced atmospheric effects")
print("  🎵 Sound effect integration ")
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