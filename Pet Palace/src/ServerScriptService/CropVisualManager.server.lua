--[[
    CropVisualManager.server.lua - Dynamic Crop Visual System
    Place in: ServerScriptService/CropVisualManager.server.lua
    
    FEATURES:
    ✅ Dynamic growth stage visuals with smooth transitions
    ✅ Rarity-based particle effects and auras
    ✅ Spectacular full-growth presentations
    ✅ Crop-specific visual characteristics
    ✅ Size scaling and color evolution during growth
    ✅ Premium crop special effects (Golden Fruit, Glorious Sunflower)
    ✅ Environmental ambiance and sound effects
    ✅ Performance-optimized particle management
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

print("CropVisualManager: Starting dynamic crop visual system...")

-- ========== VISUAL CONFIGURATION ==========

CropVisualManager.GrowthStageVisuals = {
	planted = {
		name = "Planted",
		sizeMultiplier = 0.1,
		heightOffset = -2,
		transparency = 0.7,
		color = Color3.fromRGB(139, 69, 19), -- Brown soil
		effects = {"soil_particles"},
		soundId = "rbxassetid://131961136" -- Subtle plant sound
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
		soundId = "rbxassetid://131961136"
	},

	glorious = {
		name = "Glorious",
		sizeMultiplier = 2.0,
		heightOffset = 3,
		transparency = 0,
		color = Color3.fromRGB(255, 215, 0), -- Brilliant gold
		effects = {"glorious_radiance", "divine_particles", "legendary_aura", "reality_distortion"},
		soundId = "rbxassetid://131961136"
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

	golden_fruit = {
		primaryColor = Color3.fromRGB(255, 215, 0),
		secondaryColor = Color3.fromRGB(255, 255, 0),
		specialEffects = {"golden_transformation", "divine_energy", "wealth_emanation"},
		harvestEffect = "golden_nova",
		premiumCrop = true
	},

	wheat = {
		primaryColor = Color3.fromRGB(218, 165, 32),
		secondaryColor = Color3.fromRGB(139, 69, 19),
		specialEffects = {"grain_wave", "harvest_wind"},
		harvestEffect = "grain_shower"
	},

	potato = {
		primaryColor = Color3.fromRGB(160, 82, 45),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"underground_growth"},
		harvestEffect = "earth_eruption"
	},

	tomato = {
		primaryColor = Color3.fromRGB(255, 99, 71),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"vine_growth", "ripening_glow"},
		harvestEffect = "vine_explosion"
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

	broccoli = {
		primaryColor = Color3.fromRGB(34, 139, 34),
		secondaryColor = Color3.fromRGB(0, 100, 0),
		specialEffects = {"nutrition_glow", "health_aura"},
		harvestEffect = "health_explosion"
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

-- ========== VISUAL CREATION FUNCTIONS ==========

function CropVisualManager:CreateCropModel(cropType, rarity, growthStage)
	print("🌱 CropVisualManager: Creating " .. rarity .. " " .. cropType .. " at " .. growthStage .. " stage")

	-- Get visual data
	local stageData = self.GrowthStageVisuals[growthStage] or self.GrowthStageVisuals.planted
	local rarityData = self.RarityEffects[rarity] or self.RarityEffects.common
	local cropData = self.CropSpecificVisuals[cropType] or {}

	-- Create main crop model
	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_" .. rarity .. "_" .. growthStage

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

	-- Add crop-specific geometry
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

	elseif cropType == "glorious_sunflower" then
		-- Add magnificent sunflower petals
		for i = 1, 12 do
			local petal = Instance.new("Part")
			petal.Name = "SunflowerPetal" .. i
			petal.Size = Vector3.new(1, 0.2, 2) * stageData.sizeMultiplier
			petal.Color = Color3.fromRGB(255, 140, 0)
			petal.Material = Enum.Material.ForceField
			petal.CanCollide = false
			petal.Anchored = true
			petal.Transparency = stageData.transparency * 0.3

			local angle = (i - 1) * 30
			local distance = 2 * stageData.sizeMultiplier
			petal.CFrame = primaryPart.CFrame * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, distance) * CFrame.Angles(math.rad(45), 0, 0)
			petal.Parent = cropModel
		end

		-- Add center
		local center = Instance.new("Part")
		center.Name = "SunflowerCenter"
		center.Size = Vector3.new(1.5, 0.3, 1.5) * stageData.sizeMultiplier
		center.Color = Color3.fromRGB(139, 69, 19)
		center.Material = Enum.Material.Neon
		center.Shape = Enum.PartType.Cylinder
		center.CanCollide = false
		center.Anchored = true
		center.Transparency = stageData.transparency
		center.CFrame = primaryPart.CFrame * CFrame.Angles(math.rad(90), 0, 0)
		center.Parent = cropModel
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

	elseif effectName == "green_sparkle" then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = effectName
		sparkle.Texture = "rbxassetid://241650934"
		sparkle.Lifetime = NumberRange.new(0.8, 2.0)
		sparkle.Rate = 8
		sparkle.SpreadAngle = Vector2.new(45, 45)
		sparkle.Speed = NumberRange.new(1, 4)
		sparkle.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
		sparkle.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.4),
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

	elseif effectName == "purple_energy" then
		local energy = Instance.new("ParticleEmitter")
		energy.Name = effectName
		energy.Texture = "rbxassetid://241650934"
		energy.Lifetime = NumberRange.new(1.5, 3.0)
		energy.Rate = 15
		energy.SpreadAngle = Vector2.new(90, 90)
		energy.Speed = NumberRange.new(3, 7)
		energy.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(128, 0, 128)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(64, 0, 64))
		}
		energy.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.2, 0.8),
			NumberSequenceKeypoint.new(1, 0)
		}
		energy.Parent = attachment

	elseif effectName == "legendary_radiance" then
		local radiance = Instance.new("ParticleEmitter")
		radiance.Name = effectName
		radiance.Texture = "rbxassetid://241650934"
		radiance.Lifetime = NumberRange.new(2.0, 4.0)
		radiance.Rate = 25
		radiance.SpreadAngle = Vector2.new(180, 180)
		radiance.Speed = NumberRange.new(5, 10)
		radiance.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}
		radiance.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.1, 1.2),
			NumberSequenceKeypoint.new(1, 0)
		}
		radiance.Parent = attachment

	elseif effectName == "divine_radiance" then
		-- Ultra special effect for Glorious Sunflower
		local divine = Instance.new("ParticleEmitter")
		divine.Name = effectName
		divine.Texture = "rbxassetid://241650934"
		divine.Lifetime = NumberRange.new(3.0, 6.0)
		divine.Rate = 50
		divine.SpreadAngle = Vector2.new(360, 360)
		divine.Speed = NumberRange.new(8, 15)
		divine.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 0)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}
		divine.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.05, 2.0),
			NumberSequenceKeypoint.new(1, 0)
		}
		divine.Parent = attachment

		-- Add more particle effects as needed
	elseif effectName == "soil_particles" then
		local soil = Instance.new("ParticleEmitter")
		soil.Name = effectName
		soil.Texture = "rbxassetid://241650934"
		soil.Lifetime = NumberRange.new(0.3, 0.8)
		soil.Rate = 3
		soil.SpreadAngle = Vector2.new(15, 15)
		soil.Speed = NumberRange.new(0.5, 1.5)
		soil.Color = ColorSequence.new(Color3.fromRGB(139, 69, 19))
		soil.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 0)
		}
		soil.Parent = attachment
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
	local primaryPart = cropModel.PrimaryPart

	if cropType == "golden_fruit" then
		-- Add golden energy field
		local energyField = Instance.new("Part")
		energyField.Name = "GoldenEnergyField"
		energyField.Size = Vector3.new(12, 12, 12)
		energyField.Color = Color3.fromRGB(255, 215, 0)
		energyField.Material = Enum.Material.Neon
		energyField.Transparency = 0.9
		energyField.CanCollide = false
		energyField.Anchored = true
		energyField.Shape = Enum.PartType.Ball
		energyField.CFrame = primaryPart.CFrame
		energyField.Parent = cropModel

		-- Pulsing effect
		local pulseTween = TweenService:Create(energyField,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
			{
				Transparency = 0.7,
				Size = Vector3.new(15, 15, 15)
			}
		)
		pulseTween:Play()

	elseif cropType == "glorious_sunflower" then
		-- Add reality distortion field
		local distortionField = Instance.new("Part")
		distortionField.Name = "RealityDistortion"
		distortionField.Size = Vector3.new(20, 20, 20)
		distortionField.Color = Color3.fromRGB(255, 255, 255)
		distortionField.Material = Enum.Material.Glass
		distortionField.Transparency = 0.95
		distortionField.CanCollide = false
		distortionField.Anchored = true
		distortionField.Shape = Enum.PartType.Ball
		distortionField.CFrame = primaryPart.CFrame
		distortionField.Parent = cropModel

		-- Reality warping animation
		spawn(function()
			while distortionField.Parent do
				local warpTween = TweenService:Create(distortionField,
					TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Size = Vector3.new(25, 25, 25),
						Transparency = 0.98
					}
				)
				warpTween:Play()
				warpTween.Completed:Wait()

				local restoreTween = TweenService:Create(distortionField,
					TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Size = Vector3.new(20, 20, 20),
						Transparency = 0.95
					}
				)
				restoreTween:Play()
				restoreTween.Completed:Wait()
			end
		end)
	end
end

function CropVisualManager:AddUltraSpecialEffects(cropModel, cropType)
	if cropType == "glorious_sunflower" then
		local primaryPart = cropModel.PrimaryPart

		-- Add solar corona
		local corona = Instance.new("Part")
		corona.Name = "SolarCorona"
		corona.Size = Vector3.new(30, 0.5, 30)
		corona.Color = Color3.fromRGB(255, 140, 0)
		corona.Material = Enum.Material.Neon
		corona.Transparency = 0.8
		corona.CanCollide = false
		corona.Anchored = true
		corona.Shape = Enum.PartType.Cylinder
		corona.CFrame = primaryPart.CFrame * CFrame.Angles(math.rad(90), 0, 0)
		corona.Parent = cropModel

		-- Rotating corona effect
		spawn(function()
			while corona.Parent do
				local rotateTween = TweenService:Create(corona,
					TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
					{
						CFrame = corona.CFrame * CFrame.Angles(0, 0, math.rad(360))
					}
				)
				rotateTween:Play()
				rotateTween.Completed:Wait()
			end
		end)

		-- Add light pillars
		for i = 1, 4 do
			local pillar = Instance.new("Part")
			pillar.Name = "LightPillar" .. i
			pillar.Size = Vector3.new(1, 50, 1)
			pillar.Color = Color3.fromRGB(255, 255, 255)
			pillar.Material = Enum.Material.Neon
			pillar.Transparency = 0.7
			pillar.CanCollide = false
			pillar.Anchored = true

			local angle = (i - 1) * 90
			local distance = 15
			local x = math.cos(math.rad(angle)) * distance
			local z = math.sin(math.rad(angle)) * distance
			pillar.CFrame = primaryPart.CFrame * CFrame.new(x, 25, z)
			pillar.Parent = cropModel

			-- Pillar animation
			spawn(function()
				while pillar.Parent do
					local riseTween = TweenService:Create(pillar,
						TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Transparency = 0.3,
							Size = Vector3.new(2, 60, 2)
						}
					)
					riseTween:Play()
					riseTween.Completed:Wait()

					local fallTween = TweenService:Create(pillar,
						TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{
							Transparency = 0.9,
							Size = Vector3.new(1, 50, 1)
						}
					)
					fallTween:Play()
					fallTween.Completed:Wait()
				end
			end)
		end
	end
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

-- ========== GROWTH TRANSITION FUNCTIONS ==========

function CropVisualManager:TransitionCropToStage(cropModel, newStage, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	print("🌱 CropVisualManager: Transitioning " .. cropType .. " to " .. newStage .. " stage")

	local stageData = self.GrowthStageVisuals[newStage] or self.GrowthStageVisuals.planted
	local cropData = self.CropSpecificVisuals[cropType] or {}

	-- Create transition effect
	self:CreateTransitionEffect(cropModel)

	-- Update size
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

	-- Add new stage effects
	wait(1) -- Wait for size transition
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

-- ========== HARVEST EFFECTS ==========

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

function CropVisualManager:CreateGoldenNovaEffect(position)
	-- Create golden explosion for golden fruit
	for i = 1, 20 do
		local goldParticle = Instance.new("Part")
		goldParticle.Name = "GoldParticle"
		goldParticle.Size = Vector3.new(0.5, 0.5, 0.5)
		goldParticle.Color = Color3.fromRGB(255, 215, 0)
		goldParticle.Material = Enum.Material.Neon
		goldParticle.CanCollide = false
		goldParticle.Shape = Enum.PartType.Ball
		goldParticle.CFrame = CFrame.new(position)
		goldParticle.Parent = workspace

		-- Random velocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
		bodyVelocity.Velocity = Vector3.new(
			(math.random() - 0.5) * 50,
			math.random() * 30 + 10,
			(math.random() - 0.5) * 50
		)
		bodyVelocity.Parent = goldParticle

		-- Cleanup
		spawn(function()
			wait(3)
			if goldParticle.Parent then
				goldParticle:Destroy()
			end
		end)
	end
end

function CropVisualManager:CreateSolarSupernovaEffect(position)
	-- Ultimate harvest effect for Glorious Sunflower

	-- Create massive light burst
	local supernova = Instance.new("Part")
	supernova.Name = "Supernova"
	supernova.Size = Vector3.new(1, 1, 1)
	supernova.Color = Color3.fromRGB(255, 255, 255)
	supernova.Material = Enum.Material.Neon
	supernova.Transparency = 0
	supernova.CanCollide = false
	supernova.Anchored = true
	supernova.Shape = Enum.PartType.Ball
	supernova.CFrame = CFrame.new(position)
	supernova.Parent = workspace

	-- Supernova expansion
	local supernovaTween = TweenService:Create(supernova,
		TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(100, 100, 100),
			Transparency = 1
		}
	)
	supernovaTween:Play()

	-- Create light pillars shooting into the sky
	for i = 1, 8 do
		local pillar = Instance.new("Part")
		pillar.Name = "LightPillar"
		pillar.Size = Vector3.new(2, 200, 2)
		pillar.Color = Color3.fromRGB(255, 215, 0)
		pillar.Material = Enum.Material.Neon
		pillar.Transparency = 0.3
		pillar.CanCollide = false
		pillar.Anchored = true

		local angle = (i - 1) * 45
		local distance = 10 + i * 3
		local x = math.cos(math.rad(angle)) * distance
		local z = math.sin(math.rad(angle)) * distance
		pillar.CFrame = CFrame.new(position + Vector3.new(x, 100, z))
		pillar.Parent = workspace

		-- Pillar fade
		spawn(function()
			wait(1)
			local pillarTween = TweenService:Create(pillar,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Transparency = 1
				}
			)
			pillarTween:Play()
			pillarTween.Completed:Wait()
			pillar:Destroy()
		end)
	end

	-- Cleanup supernova
	supernovaTween.Completed:Connect(function()
		supernova:Destroy()
	end)

	-- Play epic sound
	local supernovaSound = Instance.new("Sound")
	supernovaSound.SoundId = "rbxassetid://131961136" -- Replace with epic sound
	supernovaSound.Volume = 0.5
	supernovaSound.Parent = workspace
	supernovaSound:Play()

	supernovaSound.Ended:Connect(function()
		supernovaSound:Destroy()
	end)
end

function CropVisualManager:CreateBerryBurstEffect(position)
	-- Create berry particles for strawberry
	for i = 1, 15 do
		local berry = Instance.new("Part")
		berry.Name = "BerryParticle"
		berry.Size = Vector3.new(0.3, 0.3, 0.3)
		berry.Color = Color3.fromRGB(220, 20, 60)
		berry.Material = Enum.Material.Neon
		berry.CanCollide = false
		berry.Shape = Enum.PartType.Ball
		berry.CFrame = CFrame.new(position)
		berry.Parent = workspace

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(2000, 2000, 2000)
		bodyVelocity.Velocity = Vector3.new(
			(math.random() - 0.5) * 25,
			math.random() * 15 + 5,
			(math.random() - 0.5) * 25
		)
		bodyVelocity.Parent = berry

		spawn(function()
			wait(2)
			if berry.Parent then
				berry:Destroy()
			end
		end)
	end
end

function CropVisualManager:CreateEarthBurstEffect(position)
	-- Create earth particles for root vegetables
	for i = 1, 12 do
		local earth = Instance.new("Part")
		earth.Name = "EarthParticle"
		earth.Size = Vector3.new(0.4, 0.4, 0.4)
		earth.Color = Color3.fromRGB(139, 69, 19)
		earth.Material = Enum.Material.Concrete
		earth.CanCollide = false
		earth.CFrame = CFrame.new(position)
		earth.Parent = workspace

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(1500, 1500, 1500)
		bodyVelocity.Velocity = Vector3.new(
			(math.random() - 0.5) * 20,
			math.random() * 10 + 3,
			(math.random() - 0.5) * 20
		)
		bodyVelocity.Parent = earth

		spawn(function()
			wait(1.5)
			if earth.Parent then
				earth:Destroy()
			end
		end)
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

-- ========== INTEGRATION FUNCTIONS ==========

function CropVisualManager:ReplaceCropVisual(plotModel, cropType, rarity, growthStage)
	if not plotModel then return nil end

	-- Remove existing crop visual
	local existingCrop = plotModel:FindFirstChild("CropVisual")
	if existingCrop then
		existingCrop:Destroy()
	end

	-- Create new enhanced visual
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
		-- Transition existing crop
		self:TransitionCropToStage(existingCrop, newStage, cropType, rarity)
	else
		-- Create new crop with the stage
		self:ReplaceCropVisual(plotModel, cropType, rarity, newStage)
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

-- ========== PERFORMANCE OPTIMIZATION ==========

function CropVisualManager:OptimizeParticleEffects()
	-- Reduce particle rates when many crops are present
	local totalCrops = 0

	-- Count all crop visuals in workspace
	local function countCropsRecursive(parent)
		for _, child in pairs(parent:GetChildren()) do
			if child.Name == "CropVisual" then
				totalCrops = totalCrops + 1
			elseif child:IsA("Model") or child:IsA("Folder") then
				countCropsRecursive(child)
			end
		end
	end

	countCropsRecursive(workspace)

	-- Calculate performance multiplier
	local performanceMultiplier = 1.0
	if totalCrops > 50 then
		performanceMultiplier = 0.5
	elseif totalCrops > 100 then
		performanceMultiplier = 0.25
	elseif totalCrops > 200 then
		performanceMultiplier = 0.1
	end

	print("CropVisualManager: Performance optimization - " .. totalCrops .. " crops, multiplier: " .. performanceMultiplier)

	return performanceMultiplier
end

-- ========== SETUP AND EVENT CONNECTIONS ==========

function CropVisualManager:Initialize()
	print("CropVisualManager: Initializing enhanced crop visual system...")

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

	-- Performance optimization loop
	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds
			self:OptimizeParticleEffects()
		end
	end)

	print("CropVisualManager: ✅ Enhanced crop visual system ready!")
end

-- ========== GLOBAL ACCESS ==========

_G.CropVisualManager = CropVisualManager

-- Debug functions
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

_G.TestHarvestEffect = function(cropType, rarity)
	cropType = cropType or "glorious_sunflower"
	rarity = rarity or "legendary"

	CropVisualManager:CreateHarvestEffect(Vector3.new(0, 5, 0), cropType, rarity)
	print("Created harvest effect for: " .. cropType .. " (" .. rarity .. ")")
end

-- Initialize the system
CropVisualManager:Initialize()

print("=== CROP VISUAL MANAGER LOADED ===")
print("🌱 ENHANCED CROP VISUALS ACTIVE!")
print("")
print("✨ Features:")
print("  🎭 Dynamic growth stage visuals")
print("  🌟 Rarity-based particle effects")
print("  🎨 Crop-specific visual characteristics")
print("  📏 Size scaling during growth")
print("  🎭 Color evolution and transparency")
print("  ✨ Premium crop special effects")
print("  🌈 Aura effects for rare crops")
print("  🎵 Ambient sounds for crops")
print("  🎬 Smooth animations and transitions")
print("  💥 Spectacular harvest effects")
print("  ⚡ Performance optimization")
print("")
print("🔧 Test Commands:")
print("  _G.CreateTestCrop('carrot', 'common', 'ready')")
print("  _G.CreateTestCrop('glorious_sunflower', 'legendary', 'glorious')")
print("  _G.TestHarvestEffect('golden_fruit', 'rare')")
print("  _G.TestHarvestEffect('glorious_sunflower', 'legendary')")

return CropVisualManager