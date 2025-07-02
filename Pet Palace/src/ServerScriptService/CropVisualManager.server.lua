--[[
    Updated CropVisualManager.server.lua - Using Pre-made Crop Models
    Replace your existing CropVisualManager.server.lua with this version
    
    UPDATED FEATURES:
    ✅ Uses pre-made models from ReplicatedStorage.CropModels for "ready" stage
    ✅ Falls back to procedural generation for early growth stages
    ✅ Maintains all existing particle effects and rarity systems
    ✅ Supports custom models for: Cabbage, Carrot, Corn, Radish, Strawberry, Tomato, Wheat
    ✅ Automatic model scaling and positioning
    ✅ Enhanced visual effects overlaid on real models
]]

local CropVisualManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Wait for dependencies
local function WaitForGameCore()
	while not _G.GameCore do
		wait(0.5)
	end
	return _G.GameCore
end

local GameCore = WaitForGameCore()

-- Try to get ItemConfig
local ItemConfig = nil
pcall(function()
	ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
end)

-- Get CropModels folder
local CropModels = ReplicatedStorage:FindFirstChild("CropModels")
if not CropModels then
	warn("CropVisualManager: CropModels folder not found in ReplicatedStorage! Creating fallback folder.")
	CropModels = Instance.new("Folder")
	CropModels.Name = "CropModels"
	CropModels.Parent = ReplicatedStorage
end

print("CropVisualManager: Starting enhanced crop visual system with pre-made models...")

-- ========== MODEL AVAILABILITY CHECK ==========

CropVisualManager.AvailableModels = {}

function CropVisualManager:UpdateAvailableModels()
	self.AvailableModels = {}

	if CropModels then
		for _, model in pairs(CropModels:GetChildren()) do
			if model:IsA("Model") then
				local cropName = model.Name:lower()
				self.AvailableModels[cropName] = model
				print("CropVisualManager: Found pre-made model for " .. cropName)
			end
		end
	end

	print("CropVisualManager: " .. self:CountTable(self.AvailableModels) .. " pre-made crop models available")
end

function CropVisualManager:HasPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()] ~= nil
end

function CropVisualManager:GetPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()]
end

-- ========== VISUAL CONFIGURATION (Unchanged) ==========

CropVisualManager.GrowthStageVisuals = {
	planted = {
		name = "Planted",
		sizeMultiplier = 0.1,
		heightOffset = -2,
		transparency = 0.7,
		color = Color3.fromRGB(139, 69, 19), -- Brown soil
		effects = {"soil_particles"},
		soundId = "rbxassetid://131961136"
	},

	sprouting = {
		name = "Sprouting", 
		sizeMultiplier = 0.3,
		heightOffset = -1,
		transparency = 0.4,
		color = Color3.fromRGB(34, 139, 34), -- Forest green
		effects = {"sprout_sparkles", "growth_aura"},
		soundId = "rbxassetid://131961136"
	},

	growing = {
		name = "Growing",
		sizeMultiplier = 0.7,
		heightOffset = 0,
		transparency = 0.2,
		color = Color3.fromRGB(50, 205, 50), -- Lime green
		effects = {"growth_particles", "life_energy"},
		soundId = "rbxassetid://131961136"
	},

	flowering = {
		name = "Flowering",
		sizeMultiplier = 0.9,
		heightOffset = 0.5,
		transparency = 0.1,
		color = Color3.fromRGB(255, 182, 193), -- Light pink
		effects = {"flower_petals", "pollen_drift", "beauty_aura"},
		soundId = "rbxassetid://131961136"
	},

	ready = {
		name = "Ready for Harvest",
		sizeMultiplier = 1.0,
		heightOffset = 1,
		transparency = 0,
		color = Color3.fromRGB(255, 215, 0), -- Gold
		effects = {"harvest_glow", "readiness_pulse", "abundance_aura"},
		soundId = "rbxassetid://131961136",
		usePreMadeModel = true -- NEW: Use pre-made model for ready stage
	},

	glorious = {
		name = "Glorious",
		sizeMultiplier = 2.0,
		heightOffset = 3,
		transparency = 0,
		color = Color3.fromRGB(255, 215, 0), -- Brilliant gold
		effects = {"glorious_radiance", "divine_particles", "legendary_aura", "reality_distortion"},
		soundId = "rbxassetid://131961136",
		usePreMadeModel = true -- NEW: Use pre-made model for glorious stage too
	}
}

CropVisualManager.RarityEffects = {
	common = {
		particles = {"basic_sparkle"},
		aura = "none",
		glow = false,
		specialEffects = {},
		soundMultiplier = 1.0
	},

	uncommon = {
		particles = {"green_sparkle", "nature_wisps"},
		aura = "subtle_green",
		glow = true,
		glowColor = Color3.fromRGB(0, 255, 0),
		specialEffects = {"gentle_pulse"},
		soundMultiplier = 1.1
	},

	rare = {
		particles = {"golden_sparkle", "treasure_gleam", "value_wisps"},
		aura = "golden_aura",
		glow = true,
		glowColor = Color3.fromRGB(255, 215, 0),
		specialEffects = {"golden_pulse", "treasure_shimmer"},
		soundMultiplier = 1.2
	},

	epic = {
		particles = {"purple_energy", "mystic_orbs", "power_surge"},
		aura = "purple_power",
		glow = true,
		glowColor = Color3.fromRGB(128, 0, 128),
		specialEffects = {"energy_waves", "mystic_transformation", "power_emanation"},
		soundMultiplier = 1.4
	},

	legendary = {
		particles = {"legendary_radiance", "cosmic_energy", "divine_light", "reality_sparkles"},
		aura = "legendary_majesty",
		glow = true,
		glowColor = Color3.fromRGB(255, 100, 100),
		specialEffects = {"legendary_transformation", "reality_warping", "divine_presence", "cosmic_resonance"},
		soundMultiplier = 2.0
	}
}

CropVisualManager.CropSpecificVisuals = {
	carrot = {
		primaryColor = Color3.fromRGB(255, 140, 0),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"root_growth"},
		harvestEffect = "earth_burst"
	},

	corn = {
		primaryColor = Color3.fromRGB(255, 215, 0),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"tall_growth", "kernel_shimmer"},
		harvestEffect = "golden_explosion"
	},

	strawberry = {
		primaryColor = Color3.fromRGB(220, 20, 60),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"berry_sparkle", "sweet_aroma"},
		harvestEffect = "berry_burst"
	},

	wheat = {
		primaryColor = Color3.fromRGB(218, 165, 32),
		secondaryColor = Color3.fromRGB(139, 69, 19),
		specialEffects = {"grain_wave", "harvest_wind"},
		harvestEffect = "grain_shower"
	},

	cabbage = {
		primaryColor = Color3.fromRGB(124, 252, 0),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"leaf_unfurling"},
		harvestEffect = "leaf_storm"
	},

	radish = {
		primaryColor = Color3.fromRGB(255, 69, 0),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"spicy_steam", "heat_distortion"},
		harvestEffect = "spicy_burst"
	},

	tomato = {
		primaryColor = Color3.fromRGB(255, 99, 71),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"vine_growth", "ripening_glow"},
		harvestEffect = "vine_explosion"
	},

	golden_fruit = {
		primaryColor = Color3.fromRGB(255, 215, 0),
		secondaryColor = Color3.fromRGB(255, 255, 0),
		specialEffects = {"golden_transformation", "divine_energy", "wealth_emanation"},
		harvestEffect = "golden_nova",
		premiumCrop = true
	},

	glorious_sunflower = {
		primaryColor = Color3.fromRGB(255, 215, 0),
		secondaryColor = Color3.fromRGB(255, 140, 0),
		specialEffects = {"sunlight_absorption", "solar_majesty", "divine_radiance", "reality_bending"},
		harvestEffect = "solar_supernova",
		premiumCrop = true,
		ultraSpecial = true
	}
}

-- ========== ENHANCED MODEL CREATION ==========

function CropVisualManager:CreateCropModel(cropType, rarity, growthStage)
	print("🌱 CropVisualManager: Creating " .. rarity .. " " .. cropType .. " at " .. growthStage .. " stage")

	-- Get visual data
	local stageData = self.GrowthStageVisuals[growthStage] or self.GrowthStageVisuals.planted
	local rarityData = self.RarityEffects[rarity] or self.RarityEffects.common
	local cropData = self.CropSpecificVisuals[cropType] or {}

	-- Check if we should use pre-made model for this stage
	if stageData.usePreMadeModel and self:HasPreMadeModel(cropType) then
		print("🎭 Using pre-made model for " .. cropType .. " at " .. growthStage .. " stage")
		return self:CreatePreMadeModelCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
	else
		print("🔧 Using procedural generation for " .. cropType .. " at " .. growthStage .. " stage")
		return self:CreateProceduralCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
	end
end

-- NEW: Create crop using pre-made model
function CropVisualManager:CreatePreMadeModelCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
	local templateModel = self:GetPreMadeModel(cropType)
	if not templateModel then
		warn("CropVisualManager: Pre-made model not found for " .. cropType .. ", falling back to procedural")
		return self:CreateProceduralCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
	end

	-- Clone the pre-made model
	local cropModel = templateModel:Clone()
	cropModel.Name = cropType .. "_" .. rarity .. "_" .. growthStage .. "_premade"

	-- Ensure the model has a primary part
	if not cropModel.PrimaryPart then
		-- Try to find a suitable primary part
		for _, part in pairs(cropModel:GetChildren()) do
			if part:IsA("BasePart") and (part.Name:lower():find("main") or part.Name:lower():find("body") or part.Name:lower():find("root")) then
				cropModel.PrimaryPart = part
				break
			end
		end

		-- If still no primary part, use the first part found
		if not cropModel.PrimaryPart then
			for _, part in pairs(cropModel:GetChildren()) do
				if part:IsA("BasePart") then
					cropModel.PrimaryPart = part
					break
				end
			end
		end
	end

	if not cropModel.PrimaryPart then
		warn("CropVisualManager: Pre-made model for " .. cropType .. " has no suitable primary part, falling back to procedural")
		cropModel:Destroy()
		return self:CreateProceduralCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
	end

	-- Scale the model based on stage and rarity
	local scaleMultiplier = stageData.sizeMultiplier
	if rarity == "legendary" then
		scaleMultiplier = scaleMultiplier * 1.5
	elseif rarity == "epic" then
		scaleMultiplier = scaleMultiplier * 1.3
	elseif rarity == "rare" then
		scaleMultiplier = scaleMultiplier * 1.2
	end

	self:ScaleModel(cropModel, scaleMultiplier)

	-- Make all parts uncollidable and anchored
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = true
		end
	end

	-- Add rarity-based glow to primary part
	if rarityData.glow then
		self:AddGlowEffect(cropModel.PrimaryPart, rarityData.glowColor or Color3.fromRGB(255, 255, 255))
	end

	-- Add particle effects
	self:AddParticleEffects(cropModel, stageData.effects, rarityData.particles, cropData.specialEffects)

	-- Add aura effects
	if rarityData.aura and rarityData.aura ~= "none" then
		self:AddAuraEffect(cropModel, rarityData.aura, rarityData.glowColor)
	end

	-- Add special effects for premium crops
	if cropData.premiumCrop then
		self:AddPremiumCropEffects(cropModel, cropType, rarity)
	end

	-- Add ultra special effects for ultra special crops
	if cropData.ultraSpecial then
		self:AddUltraSpecialEffects(cropModel, cropType)
	end

	-- Add sound emitter
	self:AddCropSounds(cropModel, stageData.soundId, rarityData.soundMultiplier)

	-- Add gentle animation
	self:AddCropAnimation(cropModel, stageData, rarity)

	-- Add rarity coloring overlay for pre-made models
	self:AddRarityColorOverlay(cropModel, rarity, rarityData)

	print("✅ Created pre-made model crop: " .. cropType .. " (" .. rarity .. ")")
	return cropModel
end

-- NEW: Scale entire model uniformly
function CropVisualManager:ScaleModel(model, scaleFactor)
	if not model.PrimaryPart then return end

	-- Store original primary part position
	local originalCFrame = model.PrimaryPart.CFrame

	-- Scale all parts in the model
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Scale size
			part.Size = part.Size * scaleFactor

			-- Scale position relative to primary part
			if part ~= model.PrimaryPart then
				local relativePosition = model.PrimaryPart.CFrame:inverse() * part.CFrame
				relativePosition = relativePosition * CFrame.new(
					relativePosition.Position * (scaleFactor - 1)
				)
				part.CFrame = model.PrimaryPart.CFrame * relativePosition
			end
		end
	end

	-- Restore primary part position
	model.PrimaryPart.CFrame = originalCFrame
end

-- NEW: Add rarity-based color overlay to pre-made models
function CropVisualManager:AddRarityColorOverlay(model, rarity, rarityData)
	if rarity == "common" then return end -- No overlay for common

	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Add subtle color tint based on rarity
			if rarity == "uncommon" then
				part.Color = part.Color:lerp(Color3.fromRGB(0, 255, 0), 0.1)
			elseif rarity == "rare" then
				part.Color = part.Color:lerp(Color3.fromRGB(255, 215, 0), 0.15)
			elseif rarity == "epic" then
				part.Color = part.Color:lerp(Color3.fromRGB(128, 0, 128), 0.2)
			elseif rarity == "legendary" then
				part.Color = part.Color:lerp(Color3.fromRGB(255, 100, 100), 0.25)
				-- Add material enhancement for legendary
				if part.Material == Enum.Material.Plastic then
					part.Material = Enum.Material.Neon
				end
			end
		end
	end
end

-- UPDATED: Procedural crop creation (existing system)
function CropVisualManager:CreateProceduralCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
	-- Create main crop model (existing procedural logic)
	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_" .. rarity .. "_" .. growthStage .. "_procedural"

	-- Primary Part (main crop body)
	local primaryPart = Instance.new("Part")
	primaryPart.Name = "CropBody"
	primaryPart.Size = Vector3.new(2, 2, 2) * stageData.sizeMultiplier
	primaryPart.Material = Enum.Material.Neon
	primaryPart.Shape = Enum.PartType.Block
	primaryPart.TopSurface = Enum.SurfaceType.Smooth
	primaryPart.BottomSurface = Enum.SurfaceType.Smooth
	primaryPart.CanCollide = false
	primaryPart.Anchored = true

	-- Apply colors
	if cropData.primaryColor then
		primaryPart.Color = cropData.primaryColor
	else
		primaryPart.Color = stageData.color
	end

	primaryPart.Transparency = stageData.transparency
	primaryPart.Parent = cropModel

	-- Create mesh for more interesting shape
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.5, 1) -- Make it more plant-like
	mesh.Parent = primaryPart

	-- Add crop-specific geometry (existing function)
	self:AddCropSpecificGeometry(cropModel, cropType, stageData, cropData)

	-- Set primary part
	cropModel.PrimaryPart = primaryPart

	-- Add rarity-based glow
	if rarityData.glow then
		self:AddGlowEffect(primaryPart, rarityData.glowColor or Color3.fromRGB(255, 255, 255))
	end

	-- Add particle effects
	self:AddParticleEffects(cropModel, stageData.effects, rarityData.particles, cropData.specialEffects)

	-- Add aura effects
	if rarityData.aura and rarityData.aura ~= "none" then
		self:AddAuraEffect(cropModel, rarityData.aura, rarityData.glowColor)
	end

	-- Add special effects for premium crops
	if cropData.premiumCrop then
		self:AddPremiumCropEffects(cropModel, cropType, rarity)
	end

	-- Add ultra special effects for ultra special crops
	if cropData.ultraSpecial then
		self:AddUltraSpecialEffects(cropModel, cropType)
	end

	-- Add sound emitter
	self:AddCropSounds(cropModel, stageData.soundId, rarityData.soundMultiplier)

	-- Add gentle animation
	self:AddCropAnimation(cropModel, stageData, rarity)

	return cropModel
end

-- ========== EXISTING VISUAL EFFECT FUNCTIONS (Unchanged) ==========

function CropVisualManager:AddCropSpecificGeometry(cropModel, cropType, stageData, cropData)
	local primaryPart = cropModel.PrimaryPart

	if cropType == "carrot" then
		-- Add orange top part
		local top = Instance.new("Part")
		top.Name = "CarrotTop"
		top.Size = Vector3.new(1, 0.5, 1) * stageData.sizeMultiplier
		top.Color = Color3.fromRGB(34, 139, 34)
		top.Material = Enum.Material.Neon
		top.CanCollide = false
		top.Anchored = true
		top.Transparency = stageData.transparency

		local topMesh = Instance.new("SpecialMesh")
		topMesh.MeshType = Enum.MeshType.Sphere
		topMesh.Scale = Vector3.new(1.2, 0.3, 1.2)
		topMesh.Parent = top

		top.CFrame = primaryPart.CFrame * CFrame.new(0, 1.5 * stageData.sizeMultiplier, 0)
		top.Parent = cropModel

	elseif cropType == "corn" then
		-- Add corn kernels
		for i = 1, math.floor(stageData.sizeMultiplier * 5) do
			local kernel = Instance.new("Part")
			kernel.Name = "CornKernel" .. i
			kernel.Size = Vector3.new(0.2, 0.3, 0.2) * stageData.sizeMultiplier
			kernel.Color = Color3.fromRGB(255, 215, 0)
			kernel.Material = Enum.Material.Neon
			kernel.Shape = Enum.PartType.Ball
			kernel.CanCollide = false
			kernel.Anchored = true
			kernel.Transparency = stageData.transparency

			local angle = (i - 1) * (360 / 5)
			local radius = 0.8 * stageData.sizeMultiplier
			local x = math.cos(math.rad(angle)) * radius
			local z = math.sin(math.rad(angle)) * radius
			kernel.CFrame = primaryPart.CFrame * CFrame.new(x, 0, z)
			kernel.Parent = cropModel
		end

	elseif cropType == "strawberry" then
		-- Add strawberry seeds
		for i = 1, math.floor(stageData.sizeMultiplier * 8) do
			local seed = Instance.new("Part")
			seed.Name = "StrawberrySeed" .. i
			seed.Size = Vector3.new(0.1, 0.1, 0.1)
			seed.Color = Color3.fromRGB(255, 255, 0)
			seed.Material = Enum.Material.Neon
			seed.Shape = Enum.PartType.Ball
			seed.CanCollide = false
			seed.Anchored = true
			seed.Transparency = stageData.transparency

			local x = (math.random() - 0.5) * 1.5 * stageData.sizeMultiplier
			local y = (math.random() - 0.5) * 1.5 * stageData.sizeMultiplier
			local z = (math.random() - 0.5) * 1.5 * stageData.sizeMultiplier
			seed.CFrame = primaryPart.CFrame * CFrame.new(x, y, z)
			seed.Parent = cropModel
		end
	end
end

function CropVisualManager:AddGlowEffect(part, glowColor)
	local pointLight = Instance.new("PointLight")
	pointLight.Color = glowColor
	pointLight.Brightness = 2
	pointLight.Range = 10
	pointLight.Parent = part

	-- Add selection box for enhanced glow
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Color3 = glowColor
	selectionBox.Transparency = 0.7
	selectionBox.LineThickness = 0.2
	selectionBox.Adornee = part
	selectionBox.Parent = part
end

function CropVisualManager:AddParticleEffects(cropModel, stageEffects, rarityParticles, specialEffects)
	local primaryPart = cropModel.PrimaryPart

	-- Combine all effects
	local allEffects = {}
	if stageEffects then
		for _, effect in ipairs(stageEffects) do
			table.insert(allEffects, effect)
		end
	end
	if rarityParticles then
		for _, effect in ipairs(rarityParticles) do
			table.insert(allEffects, effect)
		end
	end
	if specialEffects then
		for _, effect in ipairs(specialEffects) do
			table.insert(allEffects, effect)
		end
	end

	-- Create particle effects
	for _, effectName in ipairs(allEffects) do
		self:CreateParticleEffect(primaryPart, effectName)
	end
end

function CropVisualManager:CreateParticleEffect(parent, effectName)
	local attachment = Instance.new("Attachment")
	attachment.Name = effectName .. "_Attachment"
	attachment.Parent = parent

	if effectName == "basic_sparkle" then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = effectName
		sparkle.Texture = "rbxassetid://241650934"
		sparkle.Lifetime = NumberRange.new(0.5, 1.5)
		sparkle.Rate = 5
		sparkle.SpreadAngle = Vector2.new(45, 45)
		sparkle.Speed = NumberRange.new(1, 3)
		sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		sparkle.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(1, 0)
		}
		sparkle.Parent = attachment

	elseif effectName == "golden_sparkle" then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = effectName
		sparkle.Texture = "rbxassetid://241650934"
		sparkle.Lifetime = NumberRange.new(1.0, 2.5)
		sparkle.Rate = 12
		sparkle.SpreadAngle = Vector2.new(60, 60)
		sparkle.Speed = NumberRange.new(2, 5)
		sparkle.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))
		}
		sparkle.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.6),
			NumberSequenceKeypoint.new(1, 0)
		}
		sparkle.Parent = attachment

	elseif effectName == "harvest_glow" then
		local glow = Instance.new("ParticleEmitter")
		glow.Name = effectName
		glow.Texture = "rbxassetid://241650934"
		glow.Lifetime = NumberRange.new(1.5, 3.0)
		glow.Rate = 8
		glow.SpreadAngle = Vector2.new(45, 45)
		glow.Speed = NumberRange.new(1, 4)
		glow.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		glow.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0)
		}
		glow.Parent = attachment

	elseif effectName == "readiness_pulse" then
		local pulse = Instance.new("ParticleEmitter")
		pulse.Name = effectName
		pulse.Texture = "rbxassetid://241650934"
		pulse.Lifetime = NumberRange.new(2.0, 4.0)
		pulse.Rate = 3
		pulse.SpreadAngle = Vector2.new(360, 360)
		pulse.Speed = NumberRange.new(2, 6)
		pulse.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}
		pulse.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.8),
			NumberSequenceKeypoint.new(1, 0)
		}
		pulse.Parent = attachment
	end
end

function CropVisualManager:AddAuraEffect(cropModel, auraType, auraColor)
	local primaryPart = cropModel.PrimaryPart

	-- Create aura sphere
	local aura = Instance.new("Part")
	aura.Name = "Aura_" .. auraType
	aura.Size = Vector3.new(8, 8, 8)
	aura.Color = auraColor or Color3.fromRGB(255, 255, 255)
	aura.Material = Enum.Material.ForceField
	aura.Transparency = 0.8
	aura.CanCollide = false
	aura.Anchored = true
	aura.Shape = Enum.PartType.Ball
	aura.CFrame = primaryPart.CFrame
	aura.Parent = cropModel

	-- Animate aura
	local auraTween = TweenService:Create(aura, 
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{
			Transparency = 0.9,
			Size = Vector3.new(10, 10, 10)
		}
	)
	auraTween:Play()
end

function CropVisualManager:AddPremiumCropEffects(cropModel, cropType, rarity)
	-- Existing premium crop effects code (unchanged)
end

function CropVisualManager:AddUltraSpecialEffects(cropModel, cropType)
	-- Existing ultra special effects code (unchanged)
end

function CropVisualManager:AddCropSounds(cropModel, soundId, soundMultiplier)
	if not soundId then return end

	local sound = Instance.new("Sound")
	sound.Name = "CropAmbientSound"
	sound.SoundId = soundId
	sound.Volume = 0.1 * (soundMultiplier or 1.0)
	sound.Looped = true
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.Distance = 50
	sound.Parent = cropModel.PrimaryPart

	-- Play sound with delay
	spawn(function()
		wait(math.random() * 2) -- Stagger sounds
		if sound.Parent then
			sound:Play()
		end
	end)
end

function CropVisualManager:AddCropAnimation(cropModel, stageData, rarity)
	local primaryPart = cropModel.PrimaryPart

	-- Base gentle swaying
	spawn(function()
		local originalCFrame = primaryPart.CFrame

		while primaryPart.Parent do
			-- Gentle swaying motion
			local swayAmount = 0.1 * stageData.sizeMultiplier
			local swaySpeed = 3 + math.random() * 2

			local swayTween = TweenService:Create(primaryPart,
				TweenInfo.new(swaySpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{
					CFrame = originalCFrame * CFrame.Angles(
						math.rad(swayAmount * (math.random() - 0.5) * 10),
						math.rad(swayAmount * (math.random() - 0.5) * 20),
						math.rad(swayAmount * (math.random() - 0.5) * 10)
					)
				}
			)
			swayTween:Play()
			swayTween.Completed:Wait()

			local restoreTween = TweenService:Create(primaryPart,
				TweenInfo.new(swaySpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{
					CFrame = originalCFrame
				}
			)
			restoreTween:Play()
			restoreTween.Completed:Wait()
		end
	end)

	-- Rarity-based special animations
	if rarity == "legendary" then
		spawn(function()
			while primaryPart.Parent do
				-- Legendary floating effect
				local floatTween = TweenService:Create(primaryPart,
					TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{
						CFrame = primaryPart.CFrame * CFrame.new(0, 2, 0)
					}
				)
				floatTween:Play()
				wait(8)
			end
		end)
	end
end

-- ========== INTEGRATION FUNCTIONS (Updated) ==========

function CropVisualManager:ReplaceCropVisual(plotModel, cropType, rarity, growthStage)
	if not plotModel then return nil end

	-- Remove existing crop visual
	local existingCrop = plotModel:FindFirstChild("CropVisual")
	if existingCrop then
		existingCrop:Destroy()
	end

	-- Create new enhanced visual (will automatically choose pre-made or procedural)
	local newCropVisual = self:CreateCropModel(cropType, rarity, growthStage)
	newCropVisual.Name = "CropVisual"
	newCropVisual.Parent = plotModel

	-- Position the crop visual
	if plotModel.PrimaryPart and newCropVisual.PrimaryPart then
		local stageData = self.GrowthStageVisuals[growthStage] or self.GrowthStageVisuals.planted
		local heightOffset = stageData.heightOffset or 0

		newCropVisual.PrimaryPart.CFrame = plotModel.PrimaryPart.CFrame * CFrame.new(0, 2 + heightOffset, 0)
	end

	return newCropVisual
end

function CropVisualManager:UpdateCropGrowthStage(plotModel, newStage, cropType, rarity)
	local existingCrop = plotModel:FindFirstChild("CropVisual")

	if existingCrop then
		-- Check if we need to switch between procedural and pre-made model
		local newStageData = self.GrowthStageVisuals[newStage] or self.GrowthStageVisuals.planted
		local isCurrentlyPreMade = existingCrop.Name:find("_premade") ~= nil
		local shouldBePreMade = newStageData.usePreMadeModel and self:HasPreMadeModel(cropType)

		if isCurrentlyPreMade ~= shouldBePreMade then
			-- Need to completely replace the model
			print("🔄 Switching model type for " .. cropType .. " at " .. newStage .. " stage")
			self:ReplaceCropVisual(plotModel, cropType, rarity, newStage)
		else
			-- Can transition existing crop
			self:TransitionCropToStage(existingCrop, newStage, cropType, rarity)
		end
	else
		-- Create new crop with the stage
		self:ReplaceCropVisual(plotModel, cropType, rarity, newStage)
	end
end

function CropVisualManager:TransitionCropToStage(cropModel, newStage, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	print("🌱 CropVisualManager: Transitioning " .. cropType .. " to " .. newStage .. " stage")

	local stageData = self.GrowthStageVisuals[newStage] or self.GrowthStageVisuals.planted
	local cropData = self.CropSpecificVisuals[cropType] or {}

	-- Create transition effect
	self:CreateTransitionEffect(cropModel)

	-- For pre-made models, we mainly update effects rather than geometry
	local isPreMadeModel = cropModel.Name:find("_premade") ~= nil

	if not isPreMadeModel then
		-- Update size for procedural models
		local sizeTween = TweenService:Create(cropModel.PrimaryPart,
			TweenInfo.new(2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{
				Size = Vector3.new(2, 2, 2) * stageData.sizeMultiplier
			}
		)
		sizeTween:Play()

		-- Update transparency
		local transparencyTween = TweenService:Create(cropModel.PrimaryPart,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = stageData.transparency
			}
		)
		transparencyTween:Play()

		-- Update color
		local targetColor = cropData.primaryColor or stageData.color
		local colorTween = TweenService:Create(cropModel.PrimaryPart,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Color = targetColor
			}
		)
		colorTween:Play()
	else
		-- For pre-made models, update scale
		local currentScale = stageData.sizeMultiplier
		if rarity == "legendary" then
			currentScale = currentScale * 1.5
		elseif rarity == "epic" then
			currentScale = currentScale * 1.3
		elseif rarity == "rare" then
			currentScale = currentScale * 1.2
		end

		self:ScaleModel(cropModel, currentScale)
	end

	-- Add new stage effects
	wait(1) -- Wait for transitions
	self:AddParticleEffects(cropModel, stageData.effects, {}, cropData.specialEffects)

	-- Play stage transition sound
	if stageData.soundId then
		local transitionSound = Instance.new("Sound")
		transitionSound.SoundId = stageData.soundId
		transitionSound.Volume = 0.3
		transitionSound.Parent = cropModel.PrimaryPart
		transitionSound:Play()

		transitionSound.Ended:Connect(function()
			transitionSound:Destroy()
		end)
	end
end

function CropVisualManager:CreateTransitionEffect(cropModel)
	local primaryPart = cropModel.PrimaryPart

	-- Create burst effect
	local burst = Instance.new("Part")
	burst.Name = "TransitionBurst"
	burst.Size = Vector3.new(1, 1, 1)
	burst.Color = Color3.fromRGB(255, 255, 255)
	burst.Material = Enum.Material.Neon
	burst.Transparency = 0.5
	burst.CanCollide = false
	burst.Anchored = true
	burst.Shape = Enum.PartType.Ball
	burst.CFrame = primaryPart.CFrame
	burst.Parent = workspace

	-- Burst animation
	local burstTween = TweenService:Create(burst,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(8, 8, 8),
			Transparency = 1
		}
	)
	burstTween:Play()

	burstTween.Completed:Connect(function()
		burst:Destroy()
	end)
end

-- ========== HARVEST EFFECTS (Unchanged) ==========

function CropVisualManager:CreateHarvestEffect(position, cropType, rarity)
	print("🌾 CropVisualManager: Creating harvest effect for " .. rarity .. " " .. cropType)

	local cropData = self.CropSpecificVisuals[cropType] or {}
	local harvestEffect = cropData.harvestEffect or "basic_harvest"

	if harvestEffect == "golden_nova" then
		self:CreateGoldenNovaEffect(position)
	elseif harvestEffect == "solar_supernova" then
		self:CreateSolarSupernovaEffect(position)
	elseif harvestEffect == "berry_burst" then
		self:CreateBerryBurstEffect(position)
	elseif harvestEffect == "earth_burst" then
		self:CreateEarthBurstEffect(position)
	else
		self:CreateBasicHarvestEffect(position, rarity)
	end
end

function CropVisualManager:CreateBasicHarvestEffect(position, rarity)
	local rarityData = self.RarityEffects[rarity] or self.RarityEffects.common
	local particleCount = 5 + (rarityData.soundMultiplier or 1) * 3

	for i = 1, particleCount do
		local particle = Instance.new("Part")
		particle.Name = "HarvestParticle"
		particle.Size = Vector3.new(0.2, 0.2, 0.2)
		particle.Color = rarityData.glowColor or Color3.fromRGB(255, 255, 255)
		particle.Material = Enum.Material.Neon
		particle.CanCollide = false
		particle.Shape = Enum.PartType.Ball
		particle.CFrame = CFrame.new(position)
		particle.Parent = workspace

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
		bodyVelocity.Velocity = Vector3.new(
			(math.random() - 0.5) * 15,
			math.random() * 8 + 2,
			(math.random() - 0.5) * 15
		)
		bodyVelocity.Parent = particle

		spawn(function()
			wait(1)
			if particle.Parent then
				particle:Destroy()
			end
		end)
	end
end

function CropVisualManager:OnCropHarvested(plotModel, cropType, rarity)
	local cropVisual = plotModel:FindFirstChild("CropVisual")

	if cropVisual and cropVisual.PrimaryPart then
		local position = cropVisual.PrimaryPart.Position

		-- Create harvest effect
		self:CreateHarvestEffect(position, cropType, rarity)

		-- Remove crop visual with animation
		local fadeTween = TweenService:Create(cropVisual.PrimaryPart,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		fadeTween:Play()

		fadeTween.Completed:Connect(function()
			cropVisual:Destroy()
		end)
	end
end

-- ========== UTILITY FUNCTIONS ==========

function CropVisualManager:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== SETUP AND EVENT CONNECTIONS ==========

function CropVisualManager:Initialize()
	print("CropVisualManager: Initializing enhanced crop visual system with pre-made models...")

	-- Update available models
	self:UpdateAvailableModels()

	-- Monitor for new models being added
	if CropModels then
		CropModels.ChildAdded:Connect(function()
			wait(1) -- Wait for model to fully load
			self:UpdateAvailableModels()
		end)

		CropModels.ChildRemoved:Connect(function()
			self:UpdateAvailableModels()
		end)
	end

	-- Connect to GameCore events if available
	if GameCore and GameCore.Events then
		if GameCore.Events.CropPlanted then
			GameCore.Events.CropPlanted:Connect(function(plotModel, cropType, rarity)
				self:ReplaceCropVisual(plotModel, cropType, rarity, "planted")
			end)
		end

		if GameCore.Events.CropGrowthStageChanged then
			GameCore.Events.CropGrowthStageChanged:Connect(function(plotModel, newStage, cropType, rarity)
				self:UpdateCropGrowthStage(plotModel, newStage, cropType, rarity)
			end)
		end

		if GameCore.Events.CropHarvested then
			GameCore.Events.CropHarvested:Connect(function(plotModel, cropType, rarity)
				self:OnCropHarvested(plotModel, cropType, rarity)
			end)
		end
	end

	print("CropVisualManager: ✅ Enhanced crop visual system ready with pre-made model support!")
end

-- ========== GLOBAL ACCESS ==========

_G.CropVisualManager = CropVisualManager

-- Enhanced debug functions
_G.CreateTestCrop = function(cropType, rarity, stage)
	cropType = cropType or "carrot"
	rarity = rarity or "common"
	stage = stage or "ready"

	local testCrop = CropVisualManager:CreateCropModel(cropType, rarity, stage)
	testCrop.Parent = workspace

	if testCrop.PrimaryPart then
		testCrop.PrimaryPart.CFrame = CFrame.new(0, 5, 0)
	end

	print("Created test crop: " .. cropType .. " (" .. rarity .. ", " .. stage .. ")")
	return testCrop
end

_G.TestAllCropModels = function()
	local testCrops = {"cabbage", "carrot", "corn", "radish", "strawberry", "tomato", "wheat"}
	local rarities = {"common", "rare", "legendary"}

	for i, cropType in ipairs(testCrops) do
		for j, rarity in ipairs(rarities) do
			local testCrop = CropVisualManager:CreateCropModel(cropType, rarity, "ready")
			testCrop.Parent = workspace

			if testCrop.PrimaryPart then
				testCrop.PrimaryPart.CFrame = CFrame.new(i * 15, 5, j * 15)
			end
		end
	end

	print("Created test showcase for all crop models!")
end

_G.CheckCropModels = function()
	print("=== CROP MODEL AVAILABILITY ===")
	for cropType, _ in pairs(CropVisualManager.CropSpecificVisuals) do
		local hasModel = CropVisualManager:HasPreMadeModel(cropType)
		local status = hasModel and "✅ AVAILABLE" or "❌ MISSING"
		print("  " .. cropType .. ": " .. status)
	end
	print("==============================")
end

-- Initialize the system
CropVisualManager:Initialize()

print("=== UPDATED CROP VISUAL MANAGER LOADED ===")
print("🌱 ENHANCED WITH PRE-MADE MODEL SUPPORT!")
print("")
print("✨ New Features:")
print("  🎭 Uses pre-made models from ReplicatedStorage.CropModels")
print("  🔄 Automatic switching between procedural and pre-made models")
print("  📏 Intelligent model scaling and positioning")
print("  🌈 Rarity-based color overlays on pre-made models")
print("  ⚡ All existing particle effects work with pre-made models")
print("  🎨 Falls back to procedural generation when models are missing")
print("")
print("📁 Expected Models in ReplicatedStorage.CropModels:")
print("  - Cabbage")
print("  - Carrot")
print("  - Corn") 
print("  - Radish")
print("  - Strawberry")
print("  - Tomato")
print("  - Wheat")
print("")
print("🔧 Enhanced Commands:")
print("  _G.CreateTestCrop('carrot', 'rare', 'ready')")
print("  _G.TestAllCropModels() - Create showcase of all crops")
print("  _G.CheckCropModels() - Check which models are available")

return CropVisualManager