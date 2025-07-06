--[[
    Enhanced CropVisualManager.server.lua - Better GameCore Integration
    
    ENHANCEMENTS:
    ✅ Improved GameCore integration and event handling
    ✅ Better model detection and validation
    ✅ Enhanced pre-made model positioning and scaling
    ✅ Improved fallback systems
    ✅ Better debug and monitoring tools
    ✅ Enhanced model caching and performance
]]
_G.CropVisualManager = _G.CropVisualManager or {}
local function WaitForGameCoreImproved()
    local attempts = 0
    local maxAttempts = 60 -- Wait up to 30 seconds
    
    while not _G.GameCore and attempts < maxAttempts do
        wait(0.5)
        attempts = attempts + 1
        
        if attempts % 10 == 0 then
            print("CropVisualManager: Still waiting for GameCore... (attempt " .. attempts .. "/" .. maxAttempts .. ")")
        end
    end

    if _G.GameCore then
        print("CropVisualManager: ✅ GameCore found after " .. (attempts * 0.5) .. " seconds")
        return _G.GameCore
    else
        warn("CropVisualManager: ❌ GameCore not found after " .. (maxAttempts * 0.5) .. " seconds!")
        return nil
    end
end

local CropVisualManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Wait for dependencies with better error handling
local function WaitForGameCore()
	local attempts = 0
	while not _G.GameCore and attempts < 30 do
		wait(0.5)
		attempts = attempts + 1
	end

	if not _G.GameCore then
		warn("CropVisualManager: GameCore not found after 15 seconds!")
		return nil
	end

	return _G.GameCore
end

local GameCore = WaitForGameCore()

-- Try to get ItemConfig with better error handling
local ItemConfig = nil
local function LoadItemConfig()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
	end)

	if success then
		ItemConfig = result
		print("CropVisualManager: ItemConfig loaded successfully")
	else
		warn("CropVisualManager: Failed to load ItemConfig: " .. tostring(result))
	end
end

LoadItemConfig()

-- Enhanced CropModels folder management
local CropModels = nil
local function InitializeCropModelsFolder()
	CropModels = ReplicatedStorage:FindFirstChild("CropModels")

	if not CropModels then
		warn("CropVisualManager: CropModels folder not found in ReplicatedStorage!")

		-- Try to create it
		local success, result = pcall(function()
			CropModels = Instance.new("Folder")
			CropModels.Name = "CropModels"
			CropModels.Parent = ReplicatedStorage
			return CropModels
		end)

		if success then
			print("CropVisualManager: Created CropModels folder in ReplicatedStorage")
		else
			warn("CropVisualManager: Failed to create CropModels folder: " .. tostring(result))
		end
	else
		print("CropVisualManager: Found CropModels folder with " .. #CropModels:GetChildren() .. " models")
	end

	return CropModels
end

InitializeCropModelsFolder()

print("CropVisualManager: Starting enhanced crop visual system with improved GameCore integration...")

-- ========== ENHANCED MODEL MANAGEMENT ==========

CropVisualManager.AvailableModels = {}
CropVisualManager.ModelCache = {}
CropVisualManager.ModelValidation = {}

function CropVisualManager:UpdateAvailableModels()
	self.AvailableModels = {}
	self.ModelValidation = {}

	if not CropModels then
		print("CropVisualManager: No CropModels folder available")
		return
	end

	local validModels = 0
	local invalidModels = 0

	for _, model in pairs(CropModels:GetChildren()) do
		if model:IsA("Model") then
			local cropName = model.Name:lower()
			local isValid, issues = self:ValidateModel(model)

			if isValid then
				self.AvailableModels[cropName] = model
				self.ModelValidation[cropName] = {valid = true, issues = {}}
				validModels = validModels + 1
				print("CropVisualManager: ✅ Validated model for " .. cropName)
			else
				self.ModelValidation[cropName] = {valid = false, issues = issues}
				invalidModels = invalidModels + 1
				warn("CropVisualManager: ❌ Invalid model for " .. cropName .. ": " .. table.concat(issues, ", "))
			end
		end
	end

	print("CropVisualManager: Model validation complete - " .. validModels .. " valid, " .. invalidModels .. " invalid")
end

function CropVisualManager:ValidateModel(model)
	local issues = {}

	-- Check if model has parts
	local hasBaseParts = false
	for _, child in pairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			hasBaseParts = true
			break
		end
	end

	if not hasBaseParts then
		table.insert(issues, "No BaseParts found")
	end

	-- Check if model has reasonable size
	local boundingBox = model:GetExtentsSize()
	if boundingBox.Magnitude < 1 or boundingBox.Magnitude > 50 then
		table.insert(issues, "Unusual model size: " .. tostring(boundingBox))
	end

	-- Try to determine if it has a suitable primary part or main part
	local hasMainPart = model.PrimaryPart ~= nil
	if not hasMainPart then
		-- Look for parts that could serve as primary part
		for _, part in pairs(model:GetChildren()) do
			if part:IsA("BasePart") and (
				part.Name:lower():find("main") or 
					part.Name:lower():find("body") or 
					part.Name:lower():find("root") or
					part.Name:lower():find("center")
				) then
				hasMainPart = true
				break
			end
		end
	end

	if not hasMainPart then
		table.insert(issues, "No suitable primary part found")
	end

	return #issues == 0, issues
end

function CropVisualManager:HasPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()] ~= nil
end

function CropVisualManager:GetPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()]
end

function CropVisualManager:GetModelValidationInfo(cropType)
	return self.ModelValidation[cropType:lower()]
end

-- ========== VISUAL CONFIGURATION (Enhanced) ==========

CropVisualManager.GrowthStageVisuals = {
	planted = {
		name = "Planted",
		sizeMultiplier = 0.1,
		heightOffset = -2,
		transparency = 0.7,
		color = Color3.fromRGB(139, 69, 19),
		effects = {"soil_particles"},
		soundId = "rbxassetid://131961136"
	},

	sprouting = {
		name = "Sprouting", 
		sizeMultiplier = 0.3,
		heightOffset = -1,
		transparency = 0.4,
		color = Color3.fromRGB(34, 139, 34),
		effects = {"sprout_sparkles", "growth_aura"},
		soundId = "rbxassetid://131961136"
	},

	growing = {
		name = "Growing",
		sizeMultiplier = 0.7,
		heightOffset = 0,
		transparency = 0.2,
		color = Color3.fromRGB(50, 205, 50),
		effects = {"growth_particles", "life_energy"},
		soundId = "rbxassetid://131961136"
	},

	flowering = {
		name = "Flowering",
		sizeMultiplier = 0.9,
		heightOffset = 0.5,
		transparency = 0.1,
		color = Color3.fromRGB(255, 182, 193),
		effects = {"flower_petals", "pollen_drift", "beauty_aura"},
		soundId = "rbxassetid://131961136"
	},

	ready = {
		name = "Ready for Harvest",
		sizeMultiplier = 1.0,
		heightOffset = 1,
		transparency = 0,
		color = Color3.fromRGB(255, 215, 0),
		effects = {"harvest_glow", "readiness_pulse", "abundance_aura"},
		soundId = "rbxassetid://131961136",
		usePreMadeModel = true,
		preferPreMadeModel = true -- NEW: Strongly prefer pre-made models for ready stage
	},

	glorious = {
		name = "Glorious",
		sizeMultiplier = 2.0,
		heightOffset = 3,
		transparency = 0,
		color = Color3.fromRGB(255, 215, 0),
		effects = {"glorious_radiance", "divine_particles", "legendary_aura", "reality_distortion"},
		soundId = "rbxassetid://131961136",
		usePreMadeModel = true,
		preferPreMadeModel = true
	}
}

-- Enhanced rarity effects (unchanged for brevity, but same as before)
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

-- Enhanced crop-specific visuals
CropVisualManager.CropSpecificVisuals = {
	carrot = {
		primaryColor = Color3.fromRGB(255, 140, 0),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"root_growth"},
		harvestEffect = "earth_burst",
		modelAliases = {"carrot", "carrots"} -- Support multiple names
	},
	corn = {
		primaryColor = Color3.fromRGB(255, 215, 0),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"tall_growth", "kernel_shimmer"},
		harvestEffect = "golden_explosion",
		modelAliases = {"corn", "maize"}
	},
	strawberry = {
		primaryColor = Color3.fromRGB(220, 20, 60),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"berry_sparkle", "sweet_aroma"},
		harvestEffect = "berry_burst",
		modelAliases = {"strawberry", "strawberries"}
	},
	wheat = {
		primaryColor = Color3.fromRGB(218, 165, 32),
		secondaryColor = Color3.fromRGB(139, 69, 19),
		specialEffects = {"grain_wave", "harvest_wind"},
		harvestEffect = "grain_shower",
		modelAliases = {"wheat", "grain"}
	},
	cabbage = {
		primaryColor = Color3.fromRGB(124, 252, 0),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"leaf_unfurling"},
		harvestEffect = "leaf_storm",
		modelAliases = {"cabbage", "lettuce"}
	},
	radish = {
		primaryColor = Color3.fromRGB(255, 69, 0),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"spicy_steam", "heat_distortion"},
		harvestEffect = "spicy_burst",
		modelAliases = {"radish", "radishes"}
	},
	tomato = {
		primaryColor = Color3.fromRGB(255, 99, 71),
		secondaryColor = Color3.fromRGB(34, 139, 34),
		specialEffects = {"vine_growth", "ripening_glow"},
		harvestEffect = "vine_explosion",
		modelAliases = {"tomato", "tomatoes"}
	},
	broccoli = {
		primaryColor = Color3.fromRGB(34, 139, 34),
		secondaryColor = Color3.fromRGB(124, 252, 0),
		specialEffects = {"nutrient_glow"},
		harvestEffect = "green_burst",
		modelAliases = {"broccoli"}
	},
	potato = {
		primaryColor = Color3.fromRGB(160, 82, 45),
		secondaryColor = Color3.fromRGB(139, 69, 19),
		specialEffects = {"underground_growth"},
		harvestEffect = "earth_shower",
		modelAliases = {"potato", "potatoes"}
	},
	golden_fruit = {
		primaryColor = Color3.fromRGB(255, 215, 0),
		secondaryColor = Color3.fromRGB(255, 255, 0),
		specialEffects = {"golden_transformation", "divine_energy", "wealth_emanation"},
		harvestEffect = "golden_nova",
		premiumCrop = true,
		modelAliases = {"golden_fruit", "goldenfruit"}
	},
	glorious_sunflower = {
		primaryColor = Color3.fromRGB(255, 215, 0),
		secondaryColor = Color3.fromRGB(255, 140, 0),
		specialEffects = {"sunlight_absorption", "solar_majesty", "divine_radiance", "reality_bending"},
		harvestEffect = "solar_supernova",
		premiumCrop = true,
		ultraSpecial = true,
		modelAliases = {"glorious_sunflower", "sunflower"}
	},
	broccarrot = {
		primaryColor = Color3.fromRGB(91, 154, 76), -- Broccoli green
		secondaryColor = Color3.fromRGB(255, 140, 0), -- Carrot orange
		specialEffects = {"hybrid_energy", "dual_nature", "mutation_pulse"},
		harvestEffect = "hybrid_burst",
		premiumCrop = true,
		isMutation = true,
		mutationTier = 1,
		parentCrops = {"broccoli", "carrot"},
		modelAliases = {"broccarrot", "broccoli_carrot", "carrot_broccoli"}
	},

	brocmato = {
		primaryColor = Color3.fromRGB(91, 154, 76), -- Broccoli green
		secondaryColor = Color3.fromRGB(255, 99, 71), -- Tomato red
		specialEffects = {"hybrid_energy", "dual_nature", "red_green_swirl"},
		harvestEffect = "fusion_explosion",
		premiumCrop = true,
		isMutation = true,
		mutationTier = 1,
		parentCrops = {"broccoli", "tomato"},
		modelAliases = {"brocmato", "broccoli_tomato", "tomato_broccoli"}
	},

	broctato = {
		primaryColor = Color3.fromRGB(91, 154, 76), -- Broccoli green
		secondaryColor = Color3.fromRGB(160, 82, 45), -- Potato brown
		specialEffects = {"hybrid_energy", "dual_nature", "earth_green_fusion", "rare_mutation_aura"},
		harvestEffect = "epic_mutation_burst",
		premiumCrop = true,
		ultraSpecial = true,
		isMutation = true,
		mutationTier = 2,
		parentCrops = {"broccoli", "potato"},
		modelAliases = {"broctato", "broccoli_potato", "potato_broccoli"}
	},

	cornmato = {
		primaryColor = Color3.fromRGB(255, 215, 0), -- Corn gold
		secondaryColor = Color3.fromRGB(255, 99, 71), -- Tomato red
		specialEffects = {"hybrid_energy", "dual_nature", "golden_red_spiral", "rare_mutation_aura"},
		harvestEffect = "epic_mutation_burst",
		premiumCrop = true,
		ultraSpecial = true,
		isMutation = true,
		mutationTier = 2,
		parentCrops = {"corn", "tomato"},
		modelAliases = {"cornmato", "corn_tomato", "tomato_corn"}
	},

	craddish = {
		primaryColor = Color3.fromRGB(255, 140, 0), -- Carrot orange
		secondaryColor = Color3.fromRGB(255, 69, 0), -- Radish red-orange
		specialEffects = {"hybrid_energy", "dual_nature", "spicy_glow"},
		harvestEffect = "spicy_burst",
		premiumCrop = true,
		isMutation = true,
		mutationTier = 1,
		parentCrops = {"carrot", "radish"},
		modelAliases = {"craddish", "carrot_radish", "radish_carrot"}
	}
}
	if not CropVisualManager.CropSpecificVisuals.broccarrot then
		CropVisualManager.CropSpecificVisuals.broccarrot = {
			primaryColor = Color3.fromRGB(91, 154, 76), -- Broccoli green
			secondaryColor = Color3.fromRGB(255, 140, 0), -- Carrot orange
			specialEffects = {"hybrid_energy", "dual_nature", "mutation_pulse"},
			harvestEffect = "hybrid_burst",
			premiumCrop = true,
			isMutation = true,
			mutationTier = 1,
			parentCrops = {"broccoli", "carrot"},
			modelAliases = {"broccarrot", "broccoli_carrot", "carrot_broccoli"}
		}

		CropVisualManager.CropSpecificVisuals.brocmato = {
			primaryColor = Color3.fromRGB(91, 154, 76), -- Broccoli green
			secondaryColor = Color3.fromRGB(255, 99, 71), -- Tomato red
			specialEffects = {"hybrid_energy", "dual_nature", "red_green_swirl"},
			harvestEffect = "fusion_explosion",
			premiumCrop = true,
			isMutation = true,
			mutationTier = 1,
			parentCrops = {"broccoli", "tomato"},
			modelAliases = {"brocmato", "broccoli_tomato", "tomato_broccoli"}
		}

		CropVisualManager.CropSpecificVisuals.broctato = {
			primaryColor = Color3.fromRGB(91, 154, 76), -- Broccoli green
			secondaryColor = Color3.fromRGB(160, 82, 45), -- Potato brown
			specialEffects = {"hybrid_energy", "dual_nature", "earth_green_fusion", "rare_mutation_aura"},
			harvestEffect = "epic_mutation_burst",
			premiumCrop = true,
			ultraSpecial = true,
			isMutation = true,
			mutationTier = 2,
			parentCrops = {"broccoli", "potato"},
			modelAliases = {"broctato", "broccoli_potato", "potato_broccoli"}
		}

		CropVisualManager.CropSpecificVisuals.cornmato = {
			primaryColor = Color3.fromRGB(255, 215, 0), -- Corn gold
			secondaryColor = Color3.fromRGB(255, 99, 71), -- Tomato red
			specialEffects = {"hybrid_energy", "dual_nature", "golden_red_spiral", "rare_mutation_aura"},
			harvestEffect = "epic_mutation_burst",
			premiumCrop = true,
			ultraSpecial = true,
			isMutation = true,
			mutationTier = 2,
			parentCrops = {"corn", "tomato"},
			modelAliases = {"cornmato", "corn_tomato", "tomato_corn"}
		}

		CropVisualManager.CropSpecificVisuals.craddish = {
			primaryColor = Color3.fromRGB(255, 140, 0), -- Carrot orange
			secondaryColor = Color3.fromRGB(255, 69, 0), -- Radish red-orange
			specialEffects = {"hybrid_energy", "dual_nature", "spicy_glow"},
			harvestEffect = "spicy_burst",
			premiumCrop = true,
			isMutation = true,
			mutationTier = 1,
			parentCrops = {"carrot", "radish"},
			modelAliases = {"craddish", "carrot_radish", "radish_carrot"}
		}

		print("CropVisualManager: ✅ Mutation crop definitions added")
	end


-- ========== ENHANCED MODEL CREATION ==========




function CropVisualManager:HasPreMadeModelWithAliases(cropType)
	-- Check direct match first
	if self:HasPreMadeModel(cropType) then
		return true
	end

	-- Check aliases
	local cropData = self.CropSpecificVisuals[cropType]
	if cropData and cropData.modelAliases then
		for _, alias in ipairs(cropData.modelAliases) do
			if self:HasPreMadeModel(alias) then
				return true
			end
		end
	end

	return false
end

function CropVisualManager:GetPreMadeModelWithAliases(cropType)
	-- Check direct match first
	local model = self:GetPreMadeModel(cropType)
	if model then
		return model, cropType
	end

	-- Check aliases
	local cropData = self.CropSpecificVisuals[cropType]
	if cropData and cropData.modelAliases then
		for _, alias in ipairs(cropData.modelAliases) do
			model = self:GetPreMadeModel(alias)
			if model then
				return model, alias
			end
		end
	end

	return nil, nil
end
function CropVisualManager:EnsureModelIsProperlyAnchored(cropModel)
	if not cropModel then 
		warn("CropVisualManager: No cropModel provided for anchoring")
		return 
	end

	print("🔒 Ensuring model is properly anchored: " .. cropModel.Name)

	-- First pass: Anchor all parts immediately
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end

	-- Second pass: Ensure PrimaryPart is anchored
	if cropModel.PrimaryPart then
		cropModel.PrimaryPart.Anchored = true
		cropModel.PrimaryPart.CanCollide = false
		cropModel.PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		cropModel.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end

	-- Third pass: Stop any existing motion
	wait(0.1) -- Small delay to ensure physics settle
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true -- Re-anchor to be absolutely sure
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end

	print("🔒 Model anchoring complete: " .. cropModel.Name)
end

-- NEW: Enhanced visual effects that don't cause movement
function CropVisualManager:AddEnhancedVisualEffectsStable(cropModel, cropType, stageData, rarityData, cropData, rarity)
	-- Add all visual effects EXCEPT animations that could cause movement

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

	-- Add rarity coloring overlay for pre-made models
	self:AddRarityColorOverlay(cropModel, rarity, rarityData)

	-- IMPORTANT: Add animations AFTER the model is positioned and stable
	spawn(function()
		wait(1) -- Wait for model to be positioned
		if cropModel and cropModel.Parent then
			self:AddCropAnimation(cropModel, stageData, rarity)
		end
	end)
end

-- NEW: Find the best primary part for a model
function CropVisualManager:FindBestPrimaryPart(model)
	-- First check if model already has a primary part
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	-- Look for parts with specific names that suggest they're main parts
	local preferredNames = {"main", "body", "root", "center", "base", "trunk", "stem", "default"}

	for _, preferredName in ipairs(preferredNames) do
		for _, part in pairs(model:GetChildren()) do
			if part:IsA("BasePart") and part.Name:lower():find(preferredName) then
				return part
			end
		end
	end

	-- If no preferred names found, find the largest part
	local largestPart = nil
	local largestVolume = 0

	for _, part in pairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			local volume = part.Size.X * part.Size.Y * part.Size.Z
			if volume > largestVolume then
				largestVolume = volume
				largestPart = part
			end
		end
	end

	return largestPart
end
function CropVisualManager:AddMutationEffects(cropModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	local cropData = self.CropSpecificVisuals[cropType]
	if not cropData or not cropData.isMutation then return end

	print("🧬 Adding mutation effects for " .. cropType)

	-- Add dual-color glow effect
	self:AddDualColorGlow(cropModel, cropData.primaryColor, cropData.secondaryColor)

	-- Add mutation-specific particle effects
	self:AddMutationParticles(cropModel, cropType, cropData)

	-- Add mutation pulse animation
	self:AddMutationPulseAnimation(cropModel, cropData.mutationTier)

	-- Add special mutation aura
	self:AddMutationAura(cropModel, cropType, cropData)

	-- Add genetic instability effect (optional visual flair)
	if cropData.mutationTier >= 2 then
		self:AddGeneticInstabilityEffect(cropModel)
	end
end

function CropVisualManager:AddDualColorGlow(cropModel, primaryColor, secondaryColor)
	local primaryPart = cropModel.PrimaryPart

	-- Create primary color glow
	local primaryLight = Instance.new("PointLight")
	primaryLight.Name = "PrimaryMutationGlow"
	primaryLight.Color = primaryColor
	primaryLight.Brightness = 2
	primaryLight.Range = 12
	primaryLight.Parent = primaryPart

	-- Create secondary color glow
	local secondaryLight = Instance.new("PointLight")
	secondaryLight.Name = "SecondaryMutationGlow"
	secondaryLight.Color = secondaryColor
	secondaryLight.Brightness = 1.5
	secondaryLight.Range = 8
	secondaryLight.Parent = primaryPart

	-- Animate the glows to pulse alternately
	spawn(function()
		while cropModel and cropModel.Parent do
			-- Primary glow pulse
			local primaryPulse = TweenService:Create(primaryLight,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Brightness = 3, Range = 15}
			)
			primaryPulse:Play()

			wait(1)

			-- Secondary glow pulse
			local secondaryPulse = TweenService:Create(secondaryLight,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Brightness = 2.5, Range = 12}
			)
			secondaryPulse:Play()

			wait(3)

			-- Return to base values
			local primaryReturn = TweenService:Create(primaryLight,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Brightness = 2, Range = 12}
			)
			primaryReturn:Play()

			local secondaryReturn = TweenService:Create(secondaryLight,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Brightness = 1.5, Range = 8}
			)
			secondaryReturn:Play()

			wait(2)
		end
	end)
end

function CropVisualManager:AddMutationParticles(cropModel, cropType, cropData)
	local primaryPart = cropModel.PrimaryPart

	-- Create attachment for particles
	local attachment = Instance.new("Attachment")
	attachment.Name = "MutationParticleAttachment"
	attachment.Parent = primaryPart

	-- Hybrid energy particles
	local hybridParticles = Instance.new("ParticleEmitter")
	hybridParticles.Name = "HybridEnergyParticles"
	hybridParticles.Parent = attachment

	-- Configure particle appearance
	hybridParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	hybridParticles.Rate = 30
	hybridParticles.Lifetime = NumberRange.new(2, 4)
	hybridParticles.Speed = NumberRange.new(3, 6)
	hybridParticles.SpreadAngle = Vector2.new(45, 45)

	-- Color sequence with both parent colors
	local colorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0, cropData.primaryColor),
		ColorSequenceKeypoint.new(0.5, cropData.secondaryColor),
		ColorSequenceKeypoint.new(1, cropData.primaryColor)
	})
	hybridParticles.Color = colorSequence

	-- Size animation
	hybridParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0.1)
	})

	-- Transparency animation
	hybridParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})

	-- Mutation-specific particles
	if cropType == "broccarrot" then
		self:AddSpecificMutationParticles(attachment, "green_orange_swirl")
	elseif cropType == "brocmato" then
		self:AddSpecificMutationParticles(attachment, "green_red_fusion")
	elseif cropType == "broctato" then
		self:AddSpecificMutationParticles(attachment, "earth_green_spiral")
	elseif cropType == "cornmato" then
		self:AddSpecificMutationParticles(attachment, "golden_red_burst")
	elseif cropType == "craddish" then
		self:AddSpecificMutationParticles(attachment, "spicy_orange_flare")
	end
end

function CropVisualManager:AddSpecificMutationParticles(attachment, effectType)
	local specificParticles = Instance.new("ParticleEmitter")
	specificParticles.Name = effectType .. "_Particles"
	specificParticles.Parent = attachment

	if effectType == "green_orange_swirl" then
		specificParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		specificParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 139, 34)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))
		})
		specificParticles.Rate = 15
		specificParticles.Speed = NumberRange.new(2, 5)

	elseif effectType == "green_red_fusion" then
		specificParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
		specificParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 139, 34)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 99, 71))
		})
		specificParticles.Rate = 20
		specificParticles.Speed = NumberRange.new(3, 7)

	elseif effectType == "earth_green_spiral" then
		specificParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
		specificParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 69, 19)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(34, 139, 34)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(124, 252, 0))
		})
		specificParticles.Rate = 25
		specificParticles.Speed = NumberRange.new(4, 8)

	elseif effectType == "golden_red_burst" then
		specificParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		specificParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 99, 71))
		})
		specificParticles.Rate = 30
		specificParticles.Speed = NumberRange.new(5, 10)

	elseif effectType == "spicy_orange_flare" then
		specificParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
		specificParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 69, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
		})
		specificParticles.Rate = 18
		specificParticles.Speed = NumberRange.new(2, 6)
	end

	-- Common properties for all specific particles
	specificParticles.Lifetime = NumberRange.new(1.5, 3)
	specificParticles.Size = NumberSequence.new(0.3, 0.8)
	specificParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
end

function CropVisualManager:AddMutationPulseAnimation(cropModel, mutationTier)
	local primaryPart = cropModel.PrimaryPart
	local originalSize = primaryPart.Size

	-- More intense pulsing for higher tier mutations
	local pulseMultiplier = 1 + (mutationTier * 0.1)
	local pulseSpeed = 3 - (mutationTier * 0.5) -- Faster for higher tiers

	spawn(function()
		while cropModel and cropModel.Parent do
			-- Pulse expansion
			local expandTween = TweenService:Create(primaryPart,
				TweenInfo.new(pulseSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = originalSize * pulseMultiplier}
			)
			expandTween:Play()
			expandTween.Completed:Wait()

			-- Pulse contraction
			local contractTween = TweenService:Create(primaryPart,
				TweenInfo.new(pulseSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Size = originalSize}
			)
			contractTween:Play()
			contractTween.Completed:Wait()

			wait(1) -- Pause between pulses
		end
	end)
end

function CropVisualManager:AddMutationAura(cropModel, cropType, cropData)
	local primaryPart = cropModel.PrimaryPart

	-- Create mutation aura sphere
	local aura = Instance.new("Part")
	aura.Name = "MutationAura"
	aura.Size = primaryPart.Size * 2
	aura.Shape = Enum.PartType.Ball
	aura.Material = Enum.Material.ForceField
	aura.CanCollide = false
	aura.Anchored = true
	aura.Transparency = 0.9
	aura.CFrame = primaryPart.CFrame
	aura.Parent = cropModel

	-- Color based on mutation type
	if cropData.mutationTier == 1 then
		aura.Color = Color3.fromRGB(100, 255, 100) -- Green for common mutations
	elseif cropData.mutationTier == 2 then
		aura.Color = Color3.fromRGB(255, 100, 255) -- Magenta for rare mutations
	else
		aura.Color = Color3.fromRGB(255, 255, 100) -- Yellow for special mutations
	end

	-- Animate aura
	spawn(function()
		while aura and aura.Parent do
			local rotateTween = TweenService:Create(aura,
				TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
				{Orientation = Vector3.new(0, 360, 0)}
			)
			rotateTween:Play()

			local alphaTween = TweenService:Create(aura,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.7}
			)
			alphaTween:Play()

			break -- Exit after starting animations
		end
	end)
end

function CropVisualManager:AddGeneticInstabilityEffect(cropModel)
	local primaryPart = cropModel.PrimaryPart

	-- Create reality distortion effect for epic mutations
	spawn(function()
		while cropModel and cropModel.Parent do
			-- Random color flashes
			local originalColor = primaryPart.Color

			for i = 1, 3 do
				wait(math.random(2, 5))

				-- Flash to random mutation color
				local randomColors = {
					Color3.fromRGB(255, 100, 255),
					Color3.fromRGB(100, 255, 255),
					Color3.fromRGB(255, 255, 100),
					Color3.fromRGB(255, 100, 100)
				}

				local flashColor = randomColors[math.random(#randomColors)]

				local flashTween = TweenService:Create(primaryPart,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Color = flashColor}
				)
				flashTween:Play()

				wait(0.3)

				local returnTween = TweenService:Create(primaryPart,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{Color = originalColor}
				)
				returnTween:Play()
			end

			wait(math.random(5, 10)) -- Wait before next instability episode
		end
	end)
end

-- NEW: Calculate scale multiplier with rarity bonuses
function CropVisualManager:CalculateScaleMultiplier(stageData, rarity)
	local baseScale = stageData.sizeMultiplier

	-- Apply rarity scaling
	if rarity == "legendary" then
		return baseScale * 1.5
	elseif rarity == "epic" then
		return baseScale * 1.3
	elseif rarity == "rare" then
		return baseScale * 1.2
	elseif rarity == "uncommon" then
		return baseScale * 1.1
	else
		return baseScale
	end
end
function CropVisualManager:IsMutationCrop(cropType)
	local cropData = self.CropSpecificVisuals[cropType]
	return cropData and cropData.isMutation == true
end


-- Fallback crop creation method
function CropVisualManager:CreateFallbackCropModel(cropType, rarity, growthStage)
	print("🔧 Creating fallback crop model for " .. cropType)

	-- Create simple procedural crop as fallback
	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_" .. rarity .. "_" .. growthStage .. "_fallback"

	-- Get crop data
	local cropData = self.CropSpecificVisuals[cropType] or {}
	local stageData = self.GrowthStageVisuals[growthStage] or self.GrowthStageVisuals.ready

	-- Create primary part
	local primaryPart = Instance.new("Part")
	primaryPart.Name = "CropBody"
	primaryPart.Size = Vector3.new(2, 2, 2) * (stageData.sizeMultiplier or 1)
	primaryPart.Material = Enum.Material.SmoothPlastic
	primaryPart.Shape = Enum.PartType.Block
	primaryPart.CanCollide = false
	primaryPart.Anchored = true

	-- Apply colors
	if cropData.primaryColor then
		primaryPart.Color = cropData.primaryColor
	else
		primaryPart.Color = Color3.fromRGB(100, 200, 100)
	end

	primaryPart.Transparency = stageData.transparency or 0
	primaryPart.Parent = cropModel

	-- Add mesh for better appearance
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.2, 1)
	mesh.Parent = primaryPart

	-- Set primary part
	cropModel.PrimaryPart = primaryPart

	-- Add attributes
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", rarity)
	cropModel:SetAttribute("GrowthStage", growthStage)
	cropModel:SetAttribute("ModelType", "Fallback")

	return cropModel
end
function CropVisualManager:EnsureModelIsProperlyAnchoredSafe(cropModel)
	if not cropModel then return end

	pcall(function()
		for _, part in pairs(cropModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end
	end)
end

-- Enhanced model scaling with safety checks
function CropVisualManager:ScaleModelSafely(model, scaleFactor)
	if not model.PrimaryPart then 
		return false
	end

	print("📏 Safely scaling model " .. model.Name .. " by factor " .. scaleFactor)

	local success, error = pcall(function()
		-- Store original primary part position to maintain it
		local originalCFrame = model.PrimaryPart.CFrame

		-- Ensure model is anchored before scaling
		self:EnsureModelIsProperlyAnchored(model)

		-- Get all parts before scaling
		local parts = {}
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				table.insert(parts, {
					part = part,
					originalSize = part.Size,
					originalCFrame = part.CFrame
				})
			end
		end

		-- Scale all parts while maintaining anchoring
		for _, partData in ipairs(parts) do
			local part = partData.part

			-- Ensure part is anchored during scaling
			part.Anchored = true
			part.CanCollide = false

			-- Scale size
			part.Size = partData.originalSize * scaleFactor

			-- Scale position relative to primary part if it's not the primary part
			if part ~= model.PrimaryPart then
				local relativePosition = model.PrimaryPart.CFrame:inverse() * partData.originalCFrame
				local scaledRelativePosition = CFrame.new(relativePosition.Position * scaleFactor) * relativePosition.Rotation
				part.CFrame = model.PrimaryPart.CFrame * scaledRelativePosition

				-- Re-anchor after positioning
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Restore primary part position and ensure it's anchored
		model.PrimaryPart.CFrame = originalCFrame
		model.PrimaryPart.Anchored = true
		model.PrimaryPart.CanCollide = false

		-- Final anchoring pass
		self:EnsureModelIsProperlyAnchored(model)
	end)

	if not success then
		warn("CropVisualManager: Model scaling failed: " .. tostring(error))
		return false
	end

	print("📏 Model scaling completed successfully")
	return true
end
function CropVisualManager:AddCropSpecificGeometry(cropModel, cropType, stageData, cropData)
	-- Add additional geometric elements based on crop type
	if not cropModel or not cropModel.PrimaryPart then return end

	local primaryPart = cropModel.PrimaryPart

	if cropType == "carrot" then
		-- Add carrot top (green leaves)
		local carrotTop = Instance.new("Part")
		carrotTop.Name = "CarrotTop"
		carrotTop.Size = Vector3.new(1, 0.5, 1) * stageData.sizeMultiplier
		carrotTop.Color = Color3.fromRGB(34, 139, 34)
		carrotTop.Material = Enum.Material.Grass
		carrotTop.CanCollide = false
		carrotTop.Anchored = true -- IMPORTANT: Anchor all parts
		carrotTop.CFrame = primaryPart.CFrame * CFrame.new(0, primaryPart.Size.Y/2 + carrotTop.Size.Y/2, 0)
		carrotTop.Parent = cropModel

	elseif cropType == "corn" then
		-- Add corn stalk
		local stalk = Instance.new("Part")
		stalk.Name = "CornStalk"
		stalk.Size = Vector3.new(0.3, 2, 0.3) * stageData.sizeMultiplier
		stalk.Color = Color3.fromRGB(34, 139, 34)
		stalk.Material = Enum.Material.Wood
		stalk.CanCollide = false
		stalk.Anchored = true -- IMPORTANT: Anchor all parts
		stalk.CFrame = primaryPart.CFrame * CFrame.new(0, -primaryPart.Size.Y/2 - stalk.Size.Y/2, 0)
		stalk.Parent = cropModel

	elseif cropType == "strawberry" then
		-- Add strawberry leaves
		for i = 1, 3 do
			local leaf = Instance.new("Part")
			leaf.Name = "StrawberryLeaf" .. i
			leaf.Size = Vector3.new(0.8, 0.1, 0.8) * stageData.sizeMultiplier
			leaf.Color = Color3.fromRGB(34, 139, 34)
			leaf.Material = Enum.Material.Grass
			leaf.CanCollide = false
			leaf.Anchored = true -- IMPORTANT: Anchor all parts

			local angle = (i - 1) * (math.pi * 2 / 3)
			local offset = Vector3.new(math.cos(angle) * 0.5, primaryPart.Size.Y/2, math.sin(angle) * 0.5)
			leaf.CFrame = primaryPart.CFrame * CFrame.new(offset)
			leaf.Parent = cropModel
		end

	elseif cropType == "tomato" then
		-- Add tomato vine
		local vine = Instance.new("Part")
		vine.Name = "TomatoVine"
		vine.Size = Vector3.new(0.2, 1.5, 0.2) * stageData.sizeMultiplier
		vine.Color = Color3.fromRGB(34, 139, 34)
		vine.Material = Enum.Material.Grass
		vine.CanCollide = false
		vine.Anchored = true -- IMPORTANT: Anchor all parts
		vine.CFrame = primaryPart.CFrame * CFrame.new(0, 0, 0)
		vine.Parent = cropModel
	end

	-- Ensure all newly created parts are anchored
	for _, part in pairs(cropModel:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
end
function CropVisualManager:AddGlowEffect(part, glowColor)
	if not part then return end

	local pointLight = Instance.new("PointLight")
	pointLight.Color = glowColor
	pointLight.Brightness = 2
	pointLight.Range = 10
	pointLight.Parent = part

	-- Add selection box for glow effect
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = part
	selectionBox.Color3 = glowColor
	selectionBox.LineThickness = 0.2
	selectionBox.Transparency = 0.5
	selectionBox.Parent = part
end

function CropVisualManager:AddParticleEffects(cropModel, stageEffects, rarityEffects, cropSpecificEffects)
	if not cropModel or not cropModel.PrimaryPart then return end

	local primaryPart = cropModel.PrimaryPart

	-- Combine all effects
	local allEffects = {}
	if stageEffects then
		for _, effect in ipairs(stageEffects) do
			table.insert(allEffects, effect)
		end
	end
	if rarityEffects then
		for _, effect in ipairs(rarityEffects) do
			table.insert(allEffects, effect)
		end
	end
	if cropSpecificEffects then
		for _, effect in ipairs(cropSpecificEffects) do
			table.insert(allEffects, effect)
		end
	end

	-- Create particle effects
	for _, effectName in ipairs(allEffects) do
		self:CreateParticleEffect(primaryPart, effectName)
	end
end

function CropVisualManager:CreateParticleEffect(part, effectName)
	if not part then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = effectName .. "_Attachment"
	attachment.Parent = part

	local particles = Instance.new("ParticleEmitter")
	particles.Name = effectName .. "_Particles"
	particles.Parent = attachment

	-- Configure based on effect type
	if effectName:find("sparkle") then
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		particles.Rate = 20
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Speed = NumberRange.new(2, 4)

	elseif effectName:find("glow") or effectName:find("radiance") then
		particles.Texture = "rbxasset://textures/particles/fire_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		particles.Rate = 15
		particles.Lifetime = NumberRange.new(2, 3)
		particles.Speed = NumberRange.new(1, 2)

	elseif effectName:find("energy") or effectName:find("aura") then
		particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(128, 0, 128))
		particles.Rate = 25
		particles.Lifetime = NumberRange.new(1.5, 2.5)
		particles.Speed = NumberRange.new(3, 5)

	else
		-- Default sparkle effect
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		particles.Rate = 10
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Speed = NumberRange.new(1, 3)
	end

	particles.Size = NumberSequence.new(0.5, 1)
	particles.Acceleration = Vector3.new(0, -10, 0)
end

function CropVisualManager:AddAuraEffect(cropModel, auraType, glowColor)
	if not cropModel or not cropModel.PrimaryPart then return end

	local primaryPart = cropModel.PrimaryPart

	-- Create aura part
	local aura = Instance.new("Part")
	aura.Name = "AuraEffect"
	aura.Size = primaryPart.Size * 1.5
	aura.Shape = Enum.PartType.Ball
	aura.Material = Enum.Material.ForceField
	aura.CanCollide = false
	aura.Anchored = true
	aura.Transparency = 0.8
	aura.Color = glowColor or Color3.fromRGB(255, 255, 255)
	aura.CFrame = primaryPart.CFrame
	aura.Parent = cropModel

	-- Animate aura
	local tween = TweenService:Create(aura,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Transparency = 0.95, Size = aura.Size * 1.2}
	)
	tween:Play()
end

function CropVisualManager:AddPremiumCropEffects(cropModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	-- Add golden glow
	self:AddGlowEffect(cropModel.PrimaryPart, Color3.fromRGB(255, 215, 0))

	-- Add premium particle effects
	self:CreateParticleEffect(cropModel.PrimaryPart, "golden_sparkle")
	self:CreateParticleEffect(cropModel.PrimaryPart, "wealth_emanation")
	local extraGlow = Instance.new("Part")
	extraGlow.Name = "PremiumGlow"
	extraGlow.Size = cropModel.PrimaryPart.Size * 1.3
	extraGlow.Shape = Enum.PartType.Ball
	extraGlow.Material = Enum.Material.Neon
	extraGlow.CanCollide = false
	extraGlow.Anchored = true
	extraGlow.Transparency = 0.9
	extraGlow.Color = Color3.fromRGB(255, 215, 0)
	extraGlow.CFrame = cropModel.PrimaryPart.CFrame
	extraGlow.Parent = cropModel

	local glowTween = TweenService:Create(extraGlow,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Transparency = 0.95}
	)
	glowTween:Play()
end

function CropVisualManager:AddUltraSpecialEffects(cropModel, cropType)
	if not cropModel or not cropModel.PrimaryPart then return end

	-- Add multiple color glows
	local colors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 0, 255),
		Color3.fromRGB(255, 215, 0)
	}

	for i, color in ipairs(colors) do
		spawn(function()
			wait(i * 0.5)
			self:AddGlowEffect(cropModel.PrimaryPart, color)
		end)
	end

	-- Add ultra special particles
	self:CreateParticleEffect(cropModel.PrimaryPart, "divine_radiance")
	self:CreateParticleEffect(cropModel.PrimaryPart, "reality_distortion")
end

function CropVisualManager:AddCropSounds(cropModel, soundId, soundMultiplier)
	if not cropModel or not cropModel.PrimaryPart or not soundId then return end

	local sound = Instance.new("Sound")
	sound.Name = "CropSound"
	sound.SoundId = soundId
	sound.Volume = 0.5 * (soundMultiplier or 1)
	sound.Looped = true
	sound.Parent = cropModel.PrimaryPart
	sound:Play()
end

function CropVisualManager:AddCropAnimation(cropModel, stageData, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	print("🎭 Adding SAFE crop animation to " .. cropModel.Name)

	-- Store original CFrame for animation reference
	local originalCFrame = cropModel.PrimaryPart.CFrame
	cropModel:SetAttribute("OriginalCFrame", originalCFrame)

	-- SAFE swaying animation that doesn't affect world position
	local function createSafeSwayAnimation()
		if not cropModel or not cropModel.Parent or not cropModel.PrimaryPart then 
			return 
		end

		-- Calculate sway offset from current position (not world position)
		local currentCFrame = cropModel.PrimaryPart.CFrame
		local swayOffset = CFrame.Angles(math.rad(2), 0, 0)
		local targetCFrame = currentCFrame * swayOffset

		local swayTween = TweenService:Create(cropModel.PrimaryPart,
			TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{CFrame = targetCFrame}
		)

		swayTween:Play()

		swayTween.Completed:Connect(function()
			-- Return to original position and create reverse sway
			if cropModel and cropModel.Parent and cropModel.PrimaryPart then
				local returnTween = TweenService:Create(cropModel.PrimaryPart,
					TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{CFrame = currentCFrame}
				)
				returnTween:Play()

				returnTween.Completed:Connect(function()
					-- Restart animation loop
					spawn(createSafeSwayAnimation)
				end)
			end
		end)
	end

	-- Start safe sway animation
	spawn(createSafeSwayAnimation)

	-- SAFE scale pulsing for higher rarities (doesn't affect position)
	if rarity == "legendary" or rarity == "epic" then
		local originalSize = cropModel.PrimaryPart.Size

		local function createSafePulseAnimation()
			if not cropModel or not cropModel.Parent or not cropModel.PrimaryPart then 
				return 
			end

			local pulseTween = TweenService:Create(cropModel.PrimaryPart,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{Size = originalSize * 1.1}
			)
			pulseTween:Play()

			pulseTween.Completed:Connect(function()
				if cropModel and cropModel.Parent and cropModel.PrimaryPart then
					local returnTween = TweenService:Create(cropModel.PrimaryPart,
						TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
						{Size = originalSize}
					)
					returnTween:Play()

					returnTween.Completed:Connect(function()
						spawn(createSafePulseAnimation)
					end)
				end
			end)
		end

		spawn(createSafePulseAnimation)
	end

	print("🎭 Safe animation setup complete for " .. cropModel.Name)
end


function CropVisualManager:AddRarityColorOverlay(cropModel, rarity, rarityData)
	if not cropModel then return end

	-- Add color overlay to all parts based on rarity
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") and part ~= cropModel.PrimaryPart then
			if rarityData.glowColor then
				-- Tint the part slightly with rarity color
				local originalColor = part.Color
				part.Color = originalColor:lerp(rarityData.glowColor, 0.2)
			end
		end
	end
end

function CropVisualManager:CreateTransitionEffect(model)
	if not model or not model.PrimaryPart then return end

	-- Create sparkle effect during transition
	local attachment = Instance.new("Attachment")
	attachment.Parent = model.PrimaryPart

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	particles.Rate = 50
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Speed = NumberRange.new(2, 5)
	particles.Parent = attachment

	-- Stop effect after 2 seconds
	spawn(function()
		wait(2)
		if particles then
			particles.Enabled = false
			game:GetService("Debris"):AddItem(particles, 2)
		end
		if attachment then
			game:GetService("Debris"):AddItem(attachment, 2)
		end
	end)
end

function CropVisualManager:PlayTransitionSound(cropModel, soundId)
	if not cropModel or not cropModel.PrimaryPart or not soundId then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.7
	sound.Parent = cropModel.PrimaryPart
	sound:Play()

	-- Clean up sound after playing
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- Enhanced visual effects application
function CropVisualManager:AddEnhancedVisualEffects(cropModel, cropType, stageData, rarityData, cropData, rarity)
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
end
-- Add the missing methods that GameCore is looking for
function CropVisualManager:CreateCropModelSafe(cropType, rarity, growthStage)
	print("🔧 CropVisualManager: CreateCropModelSafe called for " .. cropType)

	local success, cropModel = pcall(function()
		return self:CreateCropModel(cropType, rarity, growthStage)
	end)

	if success and cropModel then
		print("✅ CropVisualManager: Successfully created " .. cropModel.Name)
		return cropModel
	else
		warn("❌ CropVisualManager: Failed to create crop: " .. tostring(cropModel))
		return nil
	end
end

function CropVisualManager:PositionCropModelSafe(cropModel, plotModel, growthStage)
	print("🎯 CropVisualManager: PositionCropModelSafe called")

	local success, error = pcall(function()
		self:PositionCropModel(cropModel, plotModel, growthStage)
	end)

	if not success then
		warn("❌ CropVisualManager: Positioning failed: " .. tostring(error))

		-- Fallback positioning
		if cropModel and cropModel.PrimaryPart and plotModel then
			local plotPart = plotModel:FindFirstChild("SpotPart")
			if plotPart then
				cropModel.PrimaryPart.CFrame = CFrame.new(plotPart.Position + Vector3.new(0, 2, 0))
				cropModel.PrimaryPart.Anchored = true
				print("🔧 Used fallback positioning")
			end
		end
	end
end

-- ========== ENHANCED GAMECORE INTEGRATION ==========

-- Direct integration function that GameCore can call
function CropVisualManager:HandleCropPlanted(plotModel, cropType, rarity)
	print("🌱 CropVisualManager: SIMPLIFIED HandleCropPlanted - " .. cropType .. " (" .. rarity .. ")")

	if not plotModel then
		warn("❌ No plotModel provided")
		return false
	end

	local success, result = pcall(function()
		-- Clean existing crops first
		local existingCrop = plotModel:FindFirstChild("CropModel")
		if existingCrop then
			existingCrop:Destroy()
			wait(0.1)
		end

		-- Create the crop visual
		local cropModel = self:CreateSimplifiedCropModel(cropType, rarity, "planted")

		if cropModel then
			cropModel.Name = "CropModel" -- GameCore expects this name
			cropModel.Parent = plotModel

			-- Position the crop
			self:PositionCropSimple(cropModel, plotModel)

			print("✅ Simplified crop visual created successfully")
			return true
		else
			warn("❌ Failed to create simplified crop visual")
			return false
		end
	end)

	if success then
		return result
	else
		warn("CropVisualManager: Error in HandleCropPlanted: " .. tostring(result))
		return false
	end
end

-- ========== SIMPLIFIED CROP MODEL CREATION ==========

function CropVisualManager:CreateSimplifiedCropModel(cropType, rarity, growthStage)
	print("🔧 Creating simplified crop model for " .. cropType)

	-- Create the crop model
	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_" .. rarity .. "_simplified"

	-- Create the main crop part
	local cropPart = Instance.new("Part")
	cropPart.Name = "CropBody"
	cropPart.Size = Vector3.new(2, 2, 2)
	cropPart.Material = Enum.Material.Grass
	cropPart.Shape = Enum.PartType.Block
	cropPart.CanCollide = false
	cropPart.Anchored = true
	cropPart.Parent = cropModel

	-- Set crop color based on type
	local cropColors = {
		carrot = Color3.fromRGB(255, 140, 0),
		corn = Color3.fromRGB(255, 215, 0),
		strawberry = Color3.fromRGB(220, 20, 60),
		wheat = Color3.fromRGB(218, 165, 32),
		potato = Color3.fromRGB(160, 82, 45),
		cabbage = Color3.fromRGB(124, 252, 0),
		radish = Color3.fromRGB(255, 69, 0),
		broccoli = Color3.fromRGB(34, 139, 34),
		tomato = Color3.fromRGB(255, 99, 71)
	}

	cropPart.Color = cropColors[cropType] or Color3.fromRGB(100, 200, 100)

	-- Add a mesh for better appearance
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.2, 1)
	mesh.Parent = cropPart

	-- Set as primary part
	cropModel.PrimaryPart = cropPart

	-- Add rarity effects
	self:AddSimpleRarityEffects(cropPart, rarity)

	-- Add attributes
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", rarity)
	cropModel:SetAttribute("GrowthStage", growthStage)
	cropModel:SetAttribute("ModelType", "Simplified")
	cropModel:SetAttribute("CreatedBy", "CropVisualManager")

	return cropModel
end

-- ========== SIMPLIFIED POSITIONING ==========

function CropVisualManager:PositionCropSimple(cropModel, plotModel)
	if not cropModel or not cropModel.PrimaryPart then
		warn("CropVisualManager: Invalid crop model for positioning")
		return
	end

	local spotPart = plotModel:FindFirstChild("SpotPart")
	if not spotPart then
		warn("CropVisualManager: No SpotPart found for positioning")
		return
	end

	-- Position the crop above the plot
	local plotPosition = spotPart.Position
	local cropPosition = plotPosition + Vector3.new(0, 2, 0)

	cropModel.PrimaryPart.CFrame = CFrame.new(cropPosition)
	cropModel.PrimaryPart.Anchored = true
	cropModel.PrimaryPart.CanCollide = false

	print("🎯 Positioned crop at: " .. tostring(cropPosition))
end

-- ========== SIMPLIFIED RARITY EFFECTS ==========

function CropVisualManager:AddSimpleRarityEffects(cropPart, rarity)
	if rarity == "common" then return end

	-- Add a simple point light for non-common rarities
	local light = Instance.new("PointLight")
	light.Parent = cropPart

	if rarity == "uncommon" then
		light.Color = Color3.fromRGB(0, 255, 0)
		light.Brightness = 1
		light.Range = 8
	elseif rarity == "rare" then
		light.Color = Color3.fromRGB(255, 215, 0)
		light.Brightness = 1.5
		light.Range = 10
		cropPart.Material = Enum.Material.Neon
	elseif rarity == "epic" then
		light.Color = Color3.fromRGB(128, 0, 128)
		light.Brightness = 2
		light.Range = 12
		cropPart.Material = Enum.Material.Neon
	elseif rarity == "legendary" then
		light.Color = Color3.fromRGB(255, 100, 100)
		light.Brightness = 3
		light.Range = 15
		cropPart.Material = Enum.Material.Neon
	end
end

-- ========== ENSURE IMMEDIATE AVAILABILITY ==========

-- Set up the CropVisualManager global immediately
_G.CropVisualManager.HandleCropPlanted = function(plotModel, cropType, rarity)
	return CropVisualManager:HandleCropPlanted(plotModel, cropType, rarity)
end

_G.CropVisualManager.CreateCropModel = function(cropType, rarity, growthStage)
	return CropVisualManager:CreateSimplifiedCropModel(cropType, rarity, growthStage)
end

_G.CropVisualManager.PositionCropModel = function(cropModel, plotModel, growthStage)
	return CropVisualManager:PositionCropSimple(cropModel, plotModel)
end

-- ========== BACKWARDS COMPATIBILITY ==========

-- Add methods that GameCore might be looking for
CropVisualManager.CreateCropModelSafe = function(self, cropType, rarity, growthStage)
	return self:CreateSimplifiedCropModel(cropType, rarity, growthStage)
end

CropVisualManager.PositionCropModelSafe = function(self, cropModel, plotModel, growthStage)
	return self:PositionCropSimple(cropModel, plotModel)
end

-- ========== STATUS CHECK METHOD ==========

function CropVisualManager:IsCropVisualManagerAvailable()
	return true -- We're always available now
end

_G.CropVisualManager.IsCropVisualManagerAvailable = function()
	return true
end

-- ========== IMMEDIATE REGISTRATION WITH GAMECORE ==========

spawn(function()
	-- Try to register with GameCore immediately
	local attempts = 0
	while attempts < 10 do
		attempts = attempts + 1
		wait(0.5)

		if _G.GameCore then
			print("🔗 CropVisualManager: Connecting to GameCore (attempt " .. attempts .. ")...")

			-- Make ourselves available to GameCore
			_G.GameCore.CropVisualManager = CropVisualManager

			-- Also set up the global reference
			_G.CropVisualManager = CropVisualManager

			print("✅ CropVisualManager: Successfully connected to GameCore")
			break
		end
	end

	if not _G.GameCore then
		warn("⚠️ CropVisualManager: Could not connect to GameCore, but methods are still available globally")
	end

	-- Ensure we're in the global space regardless
	_G.CropVisualManager = CropVisualManager
	print("✅ CropVisualManager: Registered in global space")
end)

print("🔧 ✅ CROPVISUALMANAGER SIMPLIFIED INTEGRATION LOADED!")
print("Features:")
print("  ✅ Immediate global registration")
print("  ✅ Simplified crop creation methods")
print("  ✅ Better GameCore integration")
print("  ✅ Backwards compatibility")
print("  ✅ Fallback support")
-- ========== DIRECT GAMECORE HOOKUP ==========

-- Wait for GameCore and connect directly
spawn(function()
	local attempts = 0
	while not _G.GameCore and attempts < 20 do
		wait(0.5)
		attempts = attempts + 1
	end

	if _G.GameCore then
		print("🔗 CropVisualManager: Connecting to GameCore...")

		-- Make CropVisualManager available to GameCore
		_G.GameCore.CropVisualManager = CropVisualManager

		print("✅ CropVisualManager: Connected to GameCore")
	else
		warn("❌ CropVisualManager: Could not connect to GameCore")
	end
end)

-- ========== DEBUG FUNCTIONS ==========

-- Test crop creation function
_G.TestCropVisual = function(plotName, cropType, rarity, stage)
	plotName = plotName or "PlantingSpot_1"
	cropType = cropType or "carrot"
	rarity = rarity or "common"
	stage = stage or "ready"

	print("🧪 Testing crop visual creation...")

	-- Find the plot
	local plot = nil
	for _, area in pairs(workspace:GetDescendants()) do
		if area:IsA("Model") and area.Name == plotName then
			plot = area
			break
		end
	end

	if plot then
		print("✅ Found plot: " .. plot.Name)
		local success = CropVisualManager:HandleCropPlanted(plot, cropType, rarity)
		if success then
			print("✅ Test successful!")
		else
			print("❌ Test failed!")
		end
	else
		print("❌ Could not find plot: " .. plotName)
		print("Available plots:")
		for _, area in pairs(workspace:GetDescendants()) do
			if area:IsA("Model") and area.Name:find("PlantingSpot") then
				print("  - " .. area.Name)
			end
		end
	end
end

-- Force a crop on any plot
_G.ForceCropOnPlot = function(plotName, cropType)
	plotName = plotName or "PlantingSpot_1"
	cropType = cropType or "carrot"

	-- Find plot
	local plot = nil
	for _, area in pairs(workspace:GetDescendants()) do
		if area:IsA("Model") and area.Name == plotName then
			plot = area
			break
		end
	end

	if plot then
		-- Clear existing crops
		for _, child in pairs(plot:GetChildren()) do
			if child:IsA("Model") and child.Name == "CropModel" then
				child:Destroy()
			end
		end

		-- Create new crop
		local cropModel = CropVisualManager:CreateCropModel(cropType, "common", "ready")
		if cropModel then
			cropModel.Name = "CropModel"
			cropModel.Parent = plot
			CropVisualManager:PositionCropModel(cropModel, plot, "ready")
			print("✅ Force created crop on " .. plotName)
		else
			print("❌ Failed to force create crop")
		end
	else
		print("❌ Plot not found: " .. plotName)
	end
end

print("🔧 ✅ CROPVISUALMANAGER INTEGRATION FIX LOADED!")
print("🧪 Test commands:")
print("  _G.TestCropVisual('PlantingSpot_1', 'carrot', 'common', 'ready')")
print("  _G.ForceCropOnPlot('PlantingSpot_1', 'broccarrot')")
print("  _G.TestCropVisual() -- uses defaults")
function CropVisualManager:CreateCropModel(cropType, rarity, growthStage)
	print("🌱 CropVisualManager: Creating crop model - " .. cropType .. " (" .. rarity .. ", " .. growthStage .. ")")

	local success, cropModel = pcall(function()
		-- Get configuration data
		local stageData = self.GrowthStageVisuals[growthStage] or self.GrowthStageVisuals.ready
		local rarityData = self.RarityEffects[rarity] or self.RarityEffects.common
		local cropData = self.CropSpecificVisuals[cropType] or {}

		local finalCropModel = nil

		-- Determine which creation method to use
		local shouldUsePreMade = (stageData.usePreMadeModel or stageData.preferPreMadeModel) 
			and self:HasPreMadeModelWithAliases(cropType)

		if shouldUsePreMade then
			print("🎭 Using pre-made model for " .. cropType)
			finalCropModel = self:CreatePreMadeModelCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
		else
			print("🔧 Using procedural model for " .. cropType)
			finalCropModel = self:CreateProceduralCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
		end

		if not finalCropModel then
			warn("Failed to create crop model, trying fallback...")
			finalCropModel = self:CreateFallbackCropModel(cropType, rarity, growthStage)
		end

		-- Add mutation effects if applicable
		if finalCropModel and cropData.isMutation then
			print("🧬 Adding mutation effects to " .. cropType)
			self:AddMutationEffectsSafe(finalCropModel, cropType, rarity)

			-- Add mutation attributes
			finalCropModel:SetAttribute("IsMutation", true)
			finalCropModel:SetAttribute("MutationTier", cropData.mutationTier or 1)
			finalCropModel:SetAttribute("ParentCrops", table.concat(cropData.parentCrops or {}, ","))
		end

		-- Add standard attributes
		if finalCropModel then
			finalCropModel:SetAttribute("CropType", cropType)
			finalCropModel:SetAttribute("Rarity", rarity)
			finalCropModel:SetAttribute("GrowthStage", growthStage)
			finalCropModel:SetAttribute("CreatedTime", os.time())
		end

		return finalCropModel
	end)

	if success and cropModel then
		print("✅ Successfully created crop model: " .. cropModel.Name)
		return cropModel
	else
		warn("❌ Failed to create crop model: " .. tostring(cropModel))
		return self:CreateFallbackCropModel(cropType, rarity, growthStage)
	end
end

-- ========== SEPARATE CREATION METHODS (NO RECURSION) ==========

function CropVisualManager:CreatePreMadeModelCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
	local templateModel, actualModelName = self:GetPreMadeModelWithAliases(cropType)
	if not templateModel then
		warn("CropVisualManager: Pre-made model not found for " .. cropType)
		return nil
	end

	print("🎭 Creating pre-made model for " .. cropType)

	local success, cropModel = pcall(function()
		return templateModel:Clone()
	end)

	if not success then
		warn("CropVisualManager: Failed to clone model: " .. tostring(cropModel))
		return nil
	end

	cropModel.Name = cropType .. "_" .. rarity .. "_" .. growthStage .. "_premade"

	-- Ensure model stability
	self:EnsureModelIsProperlyAnchored(cropModel)

	-- Set primary part
	local primaryPart = self:FindBestPrimaryPart(cropModel)
	if primaryPart then
		cropModel.PrimaryPart = primaryPart
	end

	-- Scale based on stage and rarity
	local scaleMultiplier = self:CalculateScaleMultiplier(stageData, rarity)
	self:ScaleModelSafely(cropModel, scaleMultiplier)

	-- Add visual effects
	self:AddEnhancedVisualEffectsStable(cropModel, cropType, stageData, rarityData, cropData, rarity)

	-- Final anchoring
	self:EnsureModelIsProperlyAnchored(cropModel)

	cropModel:SetAttribute("ModelType", "PreMade")
	cropModel:SetAttribute("ModelSource", actualModelName)

	return cropModel
end

function CropVisualManager:CreateProceduralCrop(cropType, rarity, growthStage, stageData, rarityData, cropData)
	print("🔧 Creating procedural crop for " .. cropType)

	-- Create main crop model
	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_" .. rarity .. "_" .. growthStage .. "_procedural"

	-- Primary Part (main crop body)
	local primaryPart = Instance.new("Part")
	primaryPart.Name = "CropBody"
	primaryPart.Size = Vector3.new(2, 2, 2) * (stageData.sizeMultiplier or 1)
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
		primaryPart.Color = stageData.color or Color3.fromRGB(100, 200, 100)
	end

	primaryPart.Transparency = stageData.transparency or 0
	primaryPart.Parent = cropModel

	-- Create mesh for better appearance
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.5, 1)
	mesh.Parent = primaryPart

	-- Add crop-specific geometry
	self:AddCropSpecificGeometry(cropModel, cropType, stageData, cropData)

	-- Set primary part
	cropModel.PrimaryPart = primaryPart

	-- Add visual effects
	self:AddEnhancedVisualEffectsStable(cropModel, cropType, stageData, rarityData, cropData, rarity)

	-- Ensure stability
	self:EnsureModelIsProperlyAnchored(cropModel)

	cropModel:SetAttribute("ModelType", "Procedural")

	return cropModel
end
function CropVisualManager:AddMutationEffectsSafe(cropModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	local cropData = self.CropSpecificVisuals[cropType]
	if not cropData or not cropData.isMutation then return end

	print("🧬 Adding safe mutation effects for " .. cropType)

	local success, error = pcall(function()
		-- Add dual-color glow effect
		self:AddSafeDualColorGlow(cropModel, cropData.primaryColor, cropData.secondaryColor)

		-- Add mutation particles
		self:AddSafeMutationParticles(cropModel, cropType, cropData)

		-- Add mutation aura
		self:AddSafeMutationAura(cropModel, cropType, cropData)
	end)

	if not success then
		warn("CropVisualManager: Error adding mutation effects: " .. tostring(error))
	end
end

function CropVisualManager:AddSafeDualColorGlow(cropModel, primaryColor, secondaryColor)
	local primaryPart = cropModel.PrimaryPart
	if not primaryPart then return end

	-- Remove existing mutation lights to prevent duplicates
	for _, child in pairs(primaryPart:GetChildren()) do
		if child.Name:find("MutationGlow") then
			child:Destroy()
		end
	end

	-- Create primary color glow
	local primaryLight = Instance.new("PointLight")
	primaryLight.Name = "PrimaryMutationGlow"
	primaryLight.Color = primaryColor
	primaryLight.Brightness = 1.5
	primaryLight.Range = 8
	primaryLight.Parent = primaryPart

	-- Create secondary color glow
	local secondaryLight = Instance.new("PointLight")
	secondaryLight.Name = "SecondaryMutationGlow" 
	secondaryLight.Color = secondaryColor
	secondaryLight.Brightness = 1
	secondaryLight.Range = 6
	secondaryLight.Parent = primaryPart
end

function CropVisualManager:AddSafeMutationParticles(cropModel, cropType, cropData)
	local primaryPart = cropModel.PrimaryPart
	if not primaryPart then return end

	-- Create attachment for particles
	local attachment = Instance.new("Attachment")
	attachment.Name = "MutationParticleAttachment"
	attachment.Parent = primaryPart

	-- Create simple hybrid particles
	local hybridParticles = Instance.new("ParticleEmitter")
	hybridParticles.Name = "HybridEnergyParticles"
	hybridParticles.Parent = attachment

	-- Configure particle appearance
	hybridParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	hybridParticles.Rate = 15
	hybridParticles.Lifetime = NumberRange.new(2, 4)
	hybridParticles.Speed = NumberRange.new(2, 5)
	hybridParticles.SpreadAngle = Vector2.new(30, 30)

	-- Color sequence with both parent colors
	local colorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0, cropData.primaryColor),
		ColorSequenceKeypoint.new(0.5, cropData.secondaryColor),
		ColorSequenceKeypoint.new(1, cropData.primaryColor)
	})
	hybridParticles.Color = colorSequence

	hybridParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0.1)
	})

	hybridParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.7, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
end

function CropVisualManager:AddSafeMutationAura(cropModel, cropType, cropData)
	local primaryPart = cropModel.PrimaryPart
	if not primaryPart then return end

	-- Create mutation aura sphere
	local aura = Instance.new("Part")
	aura.Name = "MutationAura"
	aura.Size = primaryPart.Size * 1.5
	aura.Shape = Enum.PartType.Ball
	aura.Material = Enum.Material.ForceField
	aura.CanCollide = false
	aura.Anchored = true
	aura.Transparency = 0.9
	aura.CFrame = primaryPart.CFrame
	aura.Parent = cropModel

	-- Color based on mutation tier
	if cropData.mutationTier == 1 then
		aura.Color = Color3.fromRGB(100, 255, 100)
	elseif cropData.mutationTier == 2 then
		aura.Color = Color3.fromRGB(255, 100, 255)
	else
		aura.Color = Color3.fromRGB(255, 255, 100)
	end
end

-- ========== TESTING COMMANDS ==========

-- Safe test command for mutations
_G.TestMutationSafe = function(cropType)
	cropType = cropType or "broccarrot"

	print("🧪 Testing mutation creation: " .. cropType)

	local testCrop = CropVisualManager:CreateCropModel(cropType, "rare", "ready")
	if testCrop then
		testCrop.Parent = workspace
		if testCrop.PrimaryPart then
			testCrop.PrimaryPart.CFrame = CFrame.new(0, 5, 0)
		end
		print("✅ Mutation test successful: " .. testCrop.Name)
	else
		print("❌ Mutation test failed")
	end
end

-- Debug crop creation without recursion
_G.DebugCropCreation = function(cropType, rarity, stage)
	cropType = cropType or "carrot"
	rarity = rarity or "common"
	stage = stage or "ready"

	print("=== CROP CREATION DEBUG ===")
	print("Creating: " .. cropType .. " (" .. rarity .. ", " .. stage .. ")")

	local startTime = tick()
	local testCrop = CropVisualManager:CreateCropModel(cropType, rarity, stage)
	local endTime = tick()

	print("Creation time: " .. (endTime - startTime) .. " seconds")

	if testCrop then
		print("✅ Success: " .. testCrop.Name)
		testCrop.Parent = workspace
		if testCrop.PrimaryPart then
			testCrop.PrimaryPart.CFrame = CFrame.new(math.random(-10, 10), 5, math.random(-10, 10))
		end
	else
		print("❌ Failed to create crop")
	end
	print("===========================")
end

print("🔧 ✅ RECURSION BUG FIX LOADED!")
print("Key fixes:")
print("  ✅ Removed infinite recursion in CreateCropModel")
print("  ✅ Consolidated all crop creation into single function")
print("  ✅ Fixed mutation system integration")
print("  ✅ Added proper error handling")
print("")
print("🧪 Test commands:")
print("  _G.TestMutationSafe('broccarrot')")
print("  _G.DebugCropCreation('carrot', 'legendary', 'ready')")
function CropVisualManager:EnhanceProceduralMutationAppearance(cropModel, cropData)
	local primaryPart = cropModel.PrimaryPart

	-- Create dual-colored appearance for procedural mutations
	local secondaryPart = Instance.new("Part")
	secondaryPart.Name = "MutationSecondaryPart"
	secondaryPart.Size = primaryPart.Size * 0.8
	secondaryPart.Material = Enum.Material.Neon
	secondaryPart.Shape = Enum.PartType.Block
	secondaryPart.Color = cropData.secondaryColor
	secondaryPart.CanCollide = false
	secondaryPart.Anchored = true
	secondaryPart.Transparency = 0.3
	secondaryPart.CFrame = primaryPart.CFrame
	secondaryPart.Parent = cropModel

	-- Add special mesh
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(0.9, 1.2, 0.9)
	mesh.Parent = secondaryPart

	-- Animate secondary part
	spawn(function()
		while secondaryPart and secondaryPart.Parent do
			local rotateTween = TweenService:Create(secondaryPart,
				TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
				{Orientation = Vector3.new(0, 360, 0)}
			)
			rotateTween:Play()
			break
		end
	end)
end

-- ========== ENHANCED INTEGRATION FUNCTIONS ==========

function CropVisualManager:ReplaceCropVisual(plotModel, cropType, rarity, growthStage)
	if not plotModel then return nil end

	print("🔄 CropVisualManager: ENHANCED ReplaceCropVisual for " .. cropType .. " (" .. rarity .. ", " .. growthStage .. ")")

	-- STEP 1: COMPREHENSIVE cleanup of existing crops
	self:ForceCleanPlot(plotModel)

	-- STEP 2: Wait a moment to ensure cleanup completed
	wait(0.1)

	-- STEP 3: Verify plot is clean before creating new crop
	if not self:IsPlotActuallyEmpty(plotModel) then
		warn("🚨 Plot still has crops after cleanup - forcing additional cleanup")
		self:ForceCleanPlot(plotModel)
		wait(0.1)
	end

	-- STEP 4: Create new enhanced visual
	local newCropVisual = self:CreateCropModel(cropType, rarity, growthStage)

	-- IMPORTANT: Use consistent naming that GameCore expects
	newCropVisual.Name = "CropModel"

	-- Add detailed attributes for identification
	newCropVisual:SetAttribute("CropType", cropType)
	newCropVisual:SetAttribute("Rarity", rarity)
	newCropVisual:SetAttribute("GrowthStage", growthStage)
	newCropVisual:SetAttribute("DetailedName", cropType .. "_" .. rarity .. "_" .. growthStage)
	newCropVisual:SetAttribute("CreatedTime", os.time())
	newCropVisual:SetAttribute("CreatedBy", "CropVisualManager")

	newCropVisual.Parent = plotModel

	-- STEP 5: Enhanced positioning
	self:PositionCropModel(newCropVisual, plotModel, growthStage)
	self:EnsureModelIsProperlyAnchored(newCropVisual)

	-- STEP 6: Verify successful creation (SAFE VERSION)
	local verification = plotModel:FindFirstChild("CropModel")
	if verification then
		print("✅ Successfully created and verified CropModel: " .. self:GetObjectDescription(verification))
	else
		warn("❌ Failed to create CropModel - not found after creation!")
	end

	return newCropVisual
end
function CropVisualManager:GetSafeObjectId(object)
	if not object then return "nil" end

	local id = object.Name

	-- Add additional identifiers if available
	local cropType = object:GetAttribute("CropType")
	if cropType then
		id = id .. "_" .. cropType
	end

	local createdTime = object:GetAttribute("CreatedTime")
	if createdTime then
		id = id .. "_" .. createdTime
	end

	return id
end

function CropVisualManager:GetObjectDescription(object)
	if not object then return "nil object" end

	local desc = object.Name .. " (" .. object.ClassName .. ")"

	local cropType = object:GetAttribute("CropType")
	if cropType then
		desc = desc .. " [" .. cropType .. "]"
	end

	return desc
end

-- NEW: Force clean plot method
function CropVisualManager:ForceCleanPlot(plotModel)
	if not plotModel then return end

	print("🧽 CropVisualManager: Force cleaning plot " .. plotModel.Name)

	local removedCount = 0
	local children = plotModel:GetChildren()

	for _, child in pairs(children) do
		if child:IsA("Model") and child ~= plotModel and (
			child.Name == "CropModel" or
				child.Name == "CropVisual" or
				child.Name == "Crop" or
				child:GetAttribute("CropType") or
				child.Name:find("_premade") or 
				child.Name:find("_procedural") or
				child.Name:find("carrot") or child.Name:find("corn") or 
				child.Name:find("strawberry")
			) then
			print("🧽 Force removing: " .. self:GetObjectDescription(child))
			child:Destroy()
			removedCount = removedCount + 1
		end
	end

	print("🧽 Force cleanup removed " .. removedCount .. " items")
end
-- ENHANCED: Better empty plot detection
function CropVisualManager:IsPlotActuallyEmpty(plotModel)
	if not plotModel then return true end

	-- Check for any crop models
	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and (
			child.Name == "CropModel" or
				child.Name == "CropVisual" or
				child:GetAttribute("CropType")
			) then
			print("🔍 Plot not empty - found: " .. child.Name)
			return false
		end
	end

	print("🔍 Plot is empty")
	return true
end


-- NEW: Comprehensive method to find existing crop visuals
function CropVisualManager:FindExistingCropVisual(plotModel)
	if not plotModel then return nil end

	-- Try multiple possible names in order of preference
	local possibleNames = {
		"CropModel",    -- GameCore standard
		"CropVisual",   -- CropVisualManager standard  
		"Crop",         -- Generic name
		"Plant",        -- Alternative name
	}

	for _, name in ipairs(possibleNames) do
		local crop = plotModel:FindFirstChild(name)
		if crop and crop:IsA("Model") then
			print("🔍 Found existing crop with name: " .. name)
			return crop
		end
	end

	-- If no exact name match, look for any model with crop-like attributes
	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and (
			child:GetAttribute("CropType") or 
				child.Name:find("_premade") or 
				child.Name:find("_procedural") or
				child.Name:find("carrot") or child.Name:find("corn") or 
				child.Name:find("strawberry") or child.Name:find("wheat")
			) then
			print("🔍 Found crop by attributes/pattern: " .. child.Name)
			return child
		end
	end

	print("🔍 No existing crop found in plot " .. plotModel.Name)
	return nil
end


function CropVisualManager:PositionCropModel(cropModel, plotModel, growthStage)
	if not plotModel or not cropModel then
		warn("CropVisualManager: Missing plotModel or cropModel for positioning")
		return
	end

	print("🎯 STABLE positioning crop model: " .. cropModel.Name .. " on plot: " .. plotModel.Name)

	-- STEP 1: Ensure model is anchored BEFORE positioning
	self:EnsureModelIsProperlyAnchored(cropModel)

	-- STEP 2: Find the plot's main part
	local plotPart = plotModel:FindFirstChild("SpotPart") 
		or plotModel:FindFirstChild("Base") 
		or plotModel:FindFirstChild("Plot")
		or plotModel.PrimaryPart

	if not plotPart then
		warn("CropVisualManager: Cannot find plot part for positioning")
		return
	end

	if not cropModel.PrimaryPart then
		warn("CropVisualManager: Crop model has no primary part for positioning")
		return
	end

	-- STEP 3: Calculate stable position
	local stageData = self.GrowthStageVisuals[growthStage] or self.GrowthStageVisuals.planted
	local heightOffset = stageData.heightOffset or 0

	local plotPosition = plotPart.Position
	local plotSize = plotPart.Size

	-- Position crop on the center of the plot, slightly above surface
	local cropPosition = Vector3.new(
		plotPosition.X,
		plotPosition.Y + (plotSize.Y / 2) + 0.5 + heightOffset,
		plotPosition.Z
	)

	-- STEP 4: Position with physics disabled
	cropModel.PrimaryPart.Anchored = true -- Ensure anchored before moving
	cropModel.PrimaryPart.CFrame = CFrame.new(cropPosition)

	-- STEP 5: Final anchoring pass after positioning
	spawn(function()
		wait(0.1) -- Allow position to settle
		self:EnsureModelIsProperlyAnchored(cropModel)

		-- Add stable monitoring to prevent movement
		self:AddStabilityMonitoring(cropModel, cropPosition)
	end)

	print("🎯 Stable positioning complete for " .. cropModel.Name .. " at " .. tostring(cropPosition))
end
function CropVisualManager:AddStabilityMonitoring(cropModel, originalPosition)
	if not cropModel or not cropModel.PrimaryPart then return end

	-- Store original position for monitoring
	cropModel:SetAttribute("OriginalPosition", originalPosition.X .. "," .. originalPosition.Y .. "," .. originalPosition.Z)
	cropModel:SetAttribute("StabilityMonitored", true)

	-- Monitor for unwanted movement every few seconds
	spawn(function()
		local monitorCount = 0
		while cropModel and cropModel.Parent and monitorCount < 10 do -- Monitor for 30 seconds max
			wait(3)
			monitorCount = monitorCount + 1

			if cropModel.PrimaryPart then
				local currentPos = cropModel.PrimaryPart.Position
				local distance = (currentPos - originalPosition).Magnitude

				if distance > 2 then -- If moved more than 2 studs
					warn("🚨 Crop movement detected! Repositioning " .. cropModel.Name)

					-- Force reposition
					cropModel.PrimaryPart.Anchored = true
					cropModel.PrimaryPart.CFrame = CFrame.new(originalPosition)
					self:EnsureModelIsProperlyAnchored(cropModel)
				end
			end
		end
	end)
end
function CropVisualManager:UpdateCropGrowthStage(plotModel, newStage, cropType, rarity)
	print("🌱 CropVisualManager: Updating " .. cropType .. " to " .. newStage .. " stage")

	local existingCrop = plotModel:FindFirstChild("CropVisual") or plotModel:FindFirstChild("CropModel")

	if existingCrop then
		-- Check if we need to switch between procedural and pre-made model
		local newStageData = self.GrowthStageVisuals[newStage] or self.GrowthStageVisuals.planted
		local isCurrentlyPreMade = existingCrop:GetAttribute("ModelType") == "PreMade"
		local shouldBePreMade = newStageData.usePreMadeModel and self:HasPreMadeModelWithAliases(cropType)

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
		self:EnsureModelIsProperlyAnchored(cropType)
	end
end

function CropVisualManager:TransitionCropToStage(cropModel, newStage, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	print("🌱 CropVisualManager: Transitioning " .. cropType .. " to " .. newStage .. " stage")

	local stageData = self.GrowthStageVisuals[newStage] or self.GrowthStageVisuals.planted
	local cropData = self.CropSpecificVisuals[cropType] or {}

	-- Create transition effect
	self:CreateTransitionEffect(cropModel)

	-- Update attributes
	cropModel:SetAttribute("GrowthStage", newStage)

	local isPreMadeModel = cropModel:GetAttribute("ModelType") == "PreMade"

	if not isPreMadeModel then
		-- Update procedural model properties
		local sizeTween = TweenService:Create(cropModel.PrimaryPart,
			TweenInfo.new(2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{
				Size = Vector3.new(2, 2, 2) * stageData.sizeMultiplier
			}
		)
		sizeTween:Play()

		local transparencyTween = TweenService:Create(cropModel.PrimaryPart,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = stageData.transparency
			}
		)
		transparencyTween:Play()

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
		local scaleMultiplier = self:CalculateScaleMultiplier(stageData, rarity)
		self:ScaleModelSafely(cropModel, scaleMultiplier)
	end

	-- Add new stage effects after transition
	spawn(function()
		wait(1)
		if cropModel and cropModel.Parent then
			self:AddParticleEffects(cropModel, stageData.effects, {}, cropData.specialEffects)
		end
	end)

	-- Play stage transition sound
	if stageData.soundId then
		self:PlayTransitionSound(cropModel, stageData.soundId)
	end
end

-- [Rest of the visual effects methods remain the same as in the original...]
-- [Including: AddGlowEffect, AddParticleEffects, CreateParticleEffect, AddAuraEffect, etc.]

-- ========== ENHANCED EVENT SYSTEM ==========

function CropVisualManager:SetupGameCoreIntegration()
	print("CropVisualManager: Setting up simplified GameCore integration...")

	if not GameCore then
		warn("CropVisualManager: GameCore not available for integration")
		return
	end

	-- Debug what's available
	self:DebugGameCore()

	-- Try multiple integration patterns
	local connected = false

	-- Pattern 1: Direct events in GameCore
	if self:TryDirectEventIntegration() then
		connected = true
	end

	-- Pattern 2: Events table
	if not connected and self:TryEventsTableIntegration() then
		connected = true
	end

	-- Pattern 3: Signals table
	if not connected and self:TrySignalsIntegration() then
		connected = true
	end

	-- Pattern 4: RemoteEvents integration
	if not connected and self:TryRemoteEventsIntegration() then
		connected = true
	end

	-- Don't set up automatic monitoring - just rely on manual commands for now
	if connected then
		print("CropVisualManager: ✅ GameCore integration established")
	else
		print("CropVisualManager: ⚠️ No automatic events found - using manual mode")
		print("CropVisualManager: Use _G.ForceCrop() and _G.ForceHarvest() to test")
	end
end

-- Simple manual monitoring (optional - only enable if needed)
function CropVisualManager:EnableSimpleMonitoring()
	print("CropVisualManager: Enabling simple monitoring system...")

	-- Simple plot states without complex IDs
	self.SimplePlotStates = {}

	-- Monitor plot changes every few seconds
	spawn(function()
		while true do
			wait(3) -- Check every 3 seconds
			self:SimpleMonitorPlots()
		end
	end)

	print("CropVisualManager: ✅ Simple monitoring system active")
end

function CropVisualManager:SimpleMonitorPlots()
	-- Very simple monitoring - just look for changes in plot children
	for _, area in pairs(workspace:GetChildren()) do
		if area.Name == "Areas" then
			for _, plot in pairs(area:GetDescendants()) do
				if plot:IsA("Model") and plot.Name:find("Plot") then
					self:CheckPlotSimple(plot)
				end
			end
		end
	end
end

function CropVisualManager:CheckPlotSimple(plotModel)
	if not plotModel then return end

	-- Simple check: does plot have a crop visual?
	local hasCropVisual = plotModel:FindFirstChild("CropVisual") 
		or plotModel:FindFirstChild("CropModel") 
		or plotModel:FindFirstChild("Crop")

	-- Simple state: just track if plot has visual or not
	local plotName = plotModel.Name
	local hadCropBefore = self.SimplePlotStates[plotName]

	if hasCropVisual and not hadCropBefore then
		-- Crop visual appeared - but we didn't create it, so something else did
		print("🌱 Detected new crop visual on " .. plotName .. " (created by GameCore)")
		self.SimplePlotStates[plotName] = true
	elseif not hasCropVisual and hadCropBefore then
		-- Crop visual disappeared - might have been harvested
		print("🌾 Crop visual removed from " .. plotName)
		self.SimplePlotStates[plotName] = false
	end
end

-- ========== ENHANCED MANUAL COMMANDS ==========

-- Find plot by name with better search
function CropVisualManager:FindPlotByName(plotName)
	-- Search in multiple locations
	local searchLocations = {
		workspace,
		workspace:FindFirstChild("Areas"),
		workspace:FindFirstChild("Plots"),
		workspace:FindFirstChild("Farm")
	}

	for _, location in ipairs(searchLocations) do
		if location then
			-- Search in location and its descendants
			for _, child in pairs(location:GetDescendants()) do
				if child:IsA("Model") and child.Name == plotName then
					return child
				end
			end
		end
	end

	return nil
end

-- Enhanced force crop creation
function CropVisualManager:ForceCreateCropEnhanced(plotName, cropType, rarity, stage)
	local plot = self:FindPlotByName(plotName)

	if not plot then
		print("❌ Could not find plot: " .. plotName)
		print("Available plots:")
		self:ListAllPlots()
		return
	end

	print("🔧 Force creating " .. cropType .. " (" .. rarity .. ", " .. stage .. ") on " .. plot.Name)
	self:ReplaceCropVisual(plot, cropType, rarity, stage)

	-- Update simple state if monitoring is enabled
	if self.SimplePlotStates then
		self.SimplePlotStates[plot.Name] = true
	end
end

-- Enhanced force harvest
function CropVisualManager:ForceHarvestCropEnhanced(plotName)
	local plot = self:FindPlotByName(plotName)

	if not plot then
		print("❌ Could not find plot: " .. plotName)
		return
	end

	print("🔧 Force harvesting crop on " .. plot.Name)
	self:OnCropHarvested(plot, "unknown", "common")

	-- Update simple state if monitoring is enabled
	if self.SimplePlotStates then
		self.SimplePlotStates[plot.Name] = false
	end
end

-- List all available plots
function CropVisualManager:ListAllPlots()
	print("=== AVAILABLE PLOTS ===")
	local count = 0

	for _, area in pairs(workspace:GetChildren()) do
		if area.Name == "Areas" or area.Name == "Plots" or area.Name == "Farm" then
			for _, child in pairs(area:GetDescendants()) do
				if child:IsA("Model") and (child.Name:find("Plot") or child:FindFirstChild("SpotPart")) then
					count = count + 1
					local hasCrop = child:FindFirstChild("CropVisual") and "🌱" or "🟫"
					print("  " .. hasCrop .. " " .. child.Name .. " (" .. child:GetFullName() .. ")")
				end
			end
		end
	end

	if count == 0 then
		print("  No plots found!")
	else
		print("Total: " .. count .. " plots")
	end
	print("=====================")
end

-- ========== UPDATED DEBUG COMMANDS ==========

-- Enhanced debug commands
_G.ForceCrop = function(plotName, cropType, rarity, stage)
	plotName = plotName or "Plot1"
	cropType = cropType or "carrot"
	rarity = rarity or "common"
	stage = stage or "ready"

	CropVisualManager:ForceCreateCropEnhanced(plotName, cropType, rarity, stage)
end

_G.ForceHarvest = function(plotName)
	plotName = plotName or "Plot1"
	CropVisualManager:ForceHarvestCropEnhanced(plotName)
end

_G.ListPlots = function()
	CropVisualManager:ListAllPlots()
end

_G.EnableMonitoring = function()
	CropVisualManager:EnableSimpleMonitoring()
end

_G.TestCropSystem = function()
	print("🧪 Testing crop visual system...")

	-- List available plots
	CropVisualManager:ListAllPlots()

	-- Try to create crops on first few plots
	local testCrops = {
		{plot = "Plot1", crop = "carrot", rarity = "common"},
		{plot = "Plot2", crop = "corn", rarity = "rare"},
		{plot = "Plot3", crop = "strawberry", rarity = "legendary"}
	}

	for i, test in ipairs(testCrops) do
		spawn(function()
			wait(i * 2) -- Stagger the creations
			print("Creating test crop " .. i .. "...")
			CropVisualManager:ForceCreateCropEnhanced(test.plot, test.crop, test.rarity, "ready")
		end)
	end

	-- Schedule harvest tests
	spawn(function()
		wait(10)
		print("Testing harvest...")
		for i, test in ipairs(testCrops) do
			spawn(function()
				wait(i * 1)
				CropVisualManager:ForceHarvestCropEnhanced(test.plot)
			end)
		end
	end)

	print("🧪 Test sequence started! Watch for 10 seconds...")
end

-- Try direct events in GameCore root
function CropVisualManager:TryDirectEventIntegration()
	local connected = false

	-- Look for events directly in GameCore
	if GameCore.CropPlanted and GameCore.CropPlanted.Event then
		GameCore.CropPlanted.Event:Connect(function(plotModel, cropType, rarity)
			self:ReplaceCropVisual(plotModel, cropType, rarity, "planted")
		end)
		print("CropVisualManager: ✅ Connected to GameCore.CropPlanted")
		connected = true
	end

	if GameCore.CropGrowthStageChanged and GameCore.CropGrowthStageChanged.Event then
		GameCore.CropGrowthStageChanged.Event:Connect(function(plotModel, newStage, cropType, rarity)
			self:UpdateCropGrowthStage(plotModel, newStage, cropType, rarity)
		end)
		print("CropVisualManager: ✅ Connected to GameCore.CropGrowthStageChanged")
		connected = true
	end

	if GameCore.CropHarvested and GameCore.CropHarvested.Event then
		GameCore.CropHarvested.Event:Connect(function(plotModel, cropType, rarity)
			self:OnCropHarvested(plotModel, cropType, rarity)
		end)
		print("CropVisualManager: ✅ Connected to GameCore.CropHarvested")
		connected = true
	end

	return connected
end

-- Try Events table integration
function CropVisualManager:TryEventsTableIntegration()
	if not GameCore.Events then return false end

	local connected = false

	if GameCore.Events.CropPlanted then
		GameCore.Events.CropPlanted.Event:Connect(function(plotModel, cropType, rarity)
			self:ReplaceCropVisual(plotModel, cropType, rarity, "planted")
		end)
		print("CropVisualManager: ✅ Connected to GameCore.Events.CropPlanted")
		connected = true
	end

	if GameCore.Events.CropGrowthStageChanged then
		GameCore.Events.CropGrowthStageChanged.Event:Connect(function(plotModel, newStage, cropType, rarity)
			self:UpdateCropGrowthStage(plotModel, newStage, cropType, rarity)
		end)
		print("CropVisualManager: ✅ Connected to GameCore.Events.CropGrowthStageChanged")
		connected = true
	end

	if GameCore.Events.CropHarvested then
		GameCore.Events.CropHarvested.Event:Connect(function(plotModel, cropType, rarity)
			self:OnCropHarvested(plotModel, cropType, rarity)
		end)
		print("CropVisualManager: ✅ Connected to GameCore.Events.CropHarvested")
		connected = true
	end

	return connected
end

-- Try Signals integration
function CropVisualManager:TrySignalsIntegration()
	if not GameCore.Signals then return false end

	local connected = false

	if GameCore.Signals.CropPlanted then
		GameCore.Signals.CropPlanted:Connect(function(plotModel, cropType, rarity)
			self:ReplaceCropVisual(plotModel, cropType, rarity, "planted")
		end)
		print("CropVisualManager: ✅ Connected to GameCore.Signals.CropPlanted")
		connected = true
	end

	if GameCore.Signals.CropHarvested then
		GameCore.Signals.CropHarvested:Connect(function(plotModel, cropType, rarity)
			self:OnCropHarvested(plotModel, cropType, rarity)
		end)
		print("CropVisualManager: ✅ Connected to GameCore.Signals.CropHarvested")
		connected = true
	end

	return connected
end

-- Try RemoteEvents integration
function CropVisualManager:TryRemoteEventsIntegration()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return false end

	local connected = false

	local cropPlantedRemote = remoteEvents:FindFirstChild("CropPlanted")
	if cropPlantedRemote then
		cropPlantedRemote.OnServerEvent:Connect(function(player, plotModel, cropType, rarity)
			self:ReplaceCropVisual(plotModel, cropType, rarity, "planted")
		end)
		print("CropVisualManager: ✅ Connected to RemoteEvents.CropPlanted")
		connected = true
	end

	local cropHarvestedRemote = remoteEvents:FindFirstChild("CropHarvested")
	if cropHarvestedRemote then
		cropHarvestedRemote.OnServerEvent:Connect(function(player, plotModel, cropType, rarity)
			self:OnCropHarvested(plotModel, cropType, rarity)
		end)
		print("CropVisualManager: ✅ Connected to RemoteEvents.CropHarvested")
		connected = true
	end

	return connected
end

-- ========== MANUAL MONITORING SYSTEM ==========

function CropVisualManager:SetupManualMonitoring()
	print("CropVisualManager: Setting up manual plot monitoring system...")

	-- Store plot states for comparison
	self.PlotStates = {}

	-- Monitor plot changes every few seconds
	spawn(function()
		while true do
			wait(2) -- Check every 2 seconds
			self:ScanPlotsForChanges()
		end
	end)

	print("CropVisualManager: ✅ Manual monitoring system active")
end

function CropVisualManager:ScanPlotsForChanges()
	-- Find all areas and plots
	for _, area in pairs(workspace:GetChildren()) do
		if area.Name == "Areas" then
			for _, plot in pairs(area:GetDescendants()) do
				if plot:IsA("Model") and (plot.Name:find("Plot") or plot:FindFirstChild("SpotPart")) then
					self:CheckPlotState(plot)
				end
			end
		end
	end
end

function CropVisualManager:CheckPlotState(plotModel)
	if not plotModel then return end

	local plotId = tostring(plotModel) -- Unique identifier
	local currentState = self:GetPlotCurrentState(plotModel)
	local previousState = self.PlotStates[plotId]

	-- If state changed, handle the change
	if not previousState then
		-- First time seeing this plot
		self.PlotStates[plotId] = currentState
		if currentState.hasCrop then
			print("🌱 New crop detected on " .. plotModel.Name .. ": " .. currentState.cropType)
			self:ReplaceCropVisual(plotModel, currentState.cropType, currentState.rarity, currentState.stage)
		end
	elseif currentState.hasCrop ~= previousState.hasCrop then
		-- Crop added or removed
		if currentState.hasCrop then
			print("🌱 Crop planted on " .. plotModel.Name .. ": " .. currentState.cropType)
			self:ReplaceCropVisual(plotModel, currentState.cropType, currentState.rarity, currentState.stage)
		else
			print("🌾 Crop harvested from " .. plotModel.Name)
			self:OnCropHarvested(plotModel, previousState.cropType, previousState.rarity)
		end
		self.PlotStates[plotId] = currentState
	elseif currentState.hasCrop and (currentState.stage ~= previousState.stage) then
		-- Growth stage changed
		print("🌱 Growth stage changed on " .. plotModel.Name .. ": " .. currentState.stage)
		self:UpdateCropGrowthStage(plotModel, currentState.stage, currentState.cropType, currentState.rarity)
		self.PlotStates[plotId] = currentState
	end
end

function CropVisualManager:GetPlotCurrentState(plotModel)
	-- This function needs to read the actual crop data from your GameCore system
	-- You'll need to adapt this based on how your GameCore stores crop information

	local state = {
		hasCrop = false,
		cropType = nil,
		rarity = nil,
		stage = nil
	}

	-- Try to read crop data from plot attributes or GameCore
	if plotModel:GetAttribute("CropType") then
		state.hasCrop = true
		state.cropType = plotModel:GetAttribute("CropType")
		state.rarity = plotModel:GetAttribute("CropRarity") or "common"
		state.stage = plotModel:GetAttribute("CropStage") or "planted"
	elseif GameCore and GameCore.GetPlotData then
		-- If GameCore has a function to get plot data
		local plotData = GameCore.GetPlotData(plotModel)
		if plotData and plotData.crop then
			state.hasCrop = true
			state.cropType = plotData.crop.type
			state.rarity = plotData.crop.rarity or "common"
			state.stage = plotData.crop.stage or "planted"
		end
	end

	return state
end

-- ========== MANUAL CONTROL FUNCTIONS ==========

-- Force harvest crop
function CropVisualManager:ForceHarvestCrop(plotModel)
	if not plotModel then
		warn("CropVisualManager: No plot model provided")
		return
	end

	print("🔧 Force harvesting crop on " .. plotModel.Name)
	self:OnCropHarvested(plotModel, "unknown", "common")
end

-- ========== ENHANCED DEBUG COMMANDS ==========

-- Debug GameCore structure
_G.DebugGameCore = function()
	if CropVisualManager then
		CropVisualManager:DebugGameCore()
	else
		print("❌ CropVisualManager not found")
	end
end

-- Manually create crop on a plot
_G.ForceCrop = function(plotName, cropType, rarity, stage)
	plotName = plotName or "Plot1"
	cropType = cropType or "carrot"
	rarity = rarity or "common"
	stage = stage or "ready"

	-- Find the plot
	local plot = nil
	for _, area in pairs(workspace:GetChildren()) do
		if area.Name == "Areas" then
			for _, child in pairs(area:GetDescendants()) do
				if child.Name == plotName and child:IsA("Model") then
					plot = child
					break
				end
			end
		end
	end

	if plot then
		CropVisualManager:ForceCreateCropEnhanced(plot, cropType, rarity, stage)
	else
		print("❌ Could not find plot: " .. plotName)
	end
end

-- Manually harvest crop from a plot
_G.ForceHarvest = function(plotName)
	plotName = plotName or "Plot1"

	-- Find the plot
	local plot = nil
	for _, area in pairs(workspace:GetChildren()) do
		if area.Name == "Areas" then
			for _, child in pairs(area:GetDescendants()) do
				if child.Name == plotName and child:IsA("Model") then
					plot = child
					break
				end
			end
		end
	end

	if plot then
		CropVisualManager:ForceHarvestCrop(plot)
	else
		print("❌ Could not find plot: " .. plotName)
	end
end

-- Enhanced harvest function with better cleanup
function CropVisualManager:OnCropHarvested(plotModel, cropType, rarity)
	print("🌾 CropVisualManager: ENHANCED OnCropHarvested for " .. tostring(cropType) .. " on plot " .. tostring(plotModel and plotModel.Name or "unknown"))

	if not plotModel then 
		warn("CropVisualManager: No plotModel provided for harvest")
		return false
	end

	-- Find the crop visual with comprehensive search
	local existingCrop = self:FindExistingCropVisual(plotModel)

	if existingCrop then
		print("🌾 Found crop visual to harvest: " .. existingCrop.Name)
		print("🌾 Crop details: " .. tostring(existingCrop:GetAttribute("DetailedName") or "no details"))

		-- Create enhanced harvest effect
		self:CreateEnhancedHarvestEffect(existingCrop, cropType, rarity)

		-- Play harvest sound
		self:PlayHarvestSound(existingCrop, cropType)

		-- Remove crop visual after effect with delay
		spawn(function()
			wait(1) -- Give time for harvest effects
			if existingCrop and existingCrop.Parent then
				print("🌾 Destroying crop visual: " .. existingCrop.Name)
				existingCrop:Destroy()

				-- Verify removal
				wait(0.1)
				local stillExists = self:FindExistingCropVisual(plotModel)
				if stillExists then
					warn("🚨 Crop visual still exists after harvest! Force removing...")
					stillExists:Destroy()
				end
			end
		end)

		return true
	else
		warn("CropVisualManager: No crop visual found to harvest on plot " .. plotModel.Name)

		-- Enhanced debugging
		print("🔍 Plot contents for debugging:")
		for _, child in pairs(plotModel:GetChildren()) do
			print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
			if child:IsA("Model") then
				print("    Attributes: CropType=" .. tostring(child:GetAttribute("CropType")))
			end
		end

		return false
	end
end

function CropVisualManager:CreateEnhancedHarvestEffect(cropModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	print("🎆 Creating enhanced harvest effect for " .. tostring(cropType) .. " (" .. tostring(rarity) .. ")")

	local position = cropModel.PrimaryPart.Position
	local cropData = self.CropSpecificVisuals[cropType] or {}

	-- Create multiple burst effects based on rarity
	local effectCount = 1
	if rarity == "uncommon" then effectCount = 2
	elseif rarity == "rare" then effectCount = 3
	elseif rarity == "epic" then effectCount = 4
	elseif rarity == "legendary" then effectCount = 5
	end

	for i = 1, effectCount do
		spawn(function()
			wait(i * 0.1) -- Stagger effects

			local attachment = Instance.new("Attachment")
			attachment.Parent = cropModel.PrimaryPart

			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"

			-- Color based on crop type and rarity
			if cropData.primaryColor then
				particles.Color = ColorSequence.new(cropData.primaryColor)
			else
				particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
			end

			particles.Rate = 50 * effectCount
			particles.Lifetime = NumberRange.new(1, 3)
			particles.Speed = NumberRange.new(5, 15)
			particles.SpreadAngle = Vector2.new(360, 360)
			particles.Parent = attachment

			-- Burst effect
			spawn(function()
				wait(0.3)
				if particles then
					particles.Enabled = false
					game:GetService("Debris"):AddItem(particles, 3)
				end
				if attachment then
					game:GetService("Debris"):AddItem(attachment, 3)
				end
			end)
		end)
	end

	-- Create floating text effect
	self:CreateHarvestTextEffect(position, cropType, rarity)
end

-- NEW: Harvest text effect
function CropVisualManager:CreateHarvestTextEffect(position, cropType, rarity)
	local textPart = Instance.new("Part")
	textPart.Name = "HarvestText"
	textPart.Size = Vector3.new(4, 1, 0.1)
	textPart.Material = Enum.Material.ForceField
	textPart.CanCollide = false
	textPart.Anchored = true
	textPart.Position = position + Vector3.new(0, 3, 0)
	textPart.Parent = workspace

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Parent = textPart

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = "+" .. (cropType or "crop"):upper() .. "!"
	textLabel.Parent = surfaceGui

	-- Color based on rarity
	if rarity == "legendary" then
		textLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	elseif rarity == "epic" then
		textLabel.TextColor3 = Color3.fromRGB(128, 0, 128)
	elseif rarity == "rare" then
		textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	elseif rarity == "uncommon" then
		textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	end

	-- Animate text
	local moveTween = TweenService:Create(textPart,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = position + Vector3.new(0, 8, 0), Transparency = 1}
	)
	moveTween:Play()

	moveTween.Completed:Connect(function()
		textPart:Destroy()
	end)
end

-- NEW: Play harvest sound
function CropVisualManager:PlayHarvestSound(cropModel, cropType)
	if not cropModel or not cropModel.PrimaryPart then return end

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://131961136" -- Default harvest sound
	sound.Volume = 0.8
	sound.Parent = cropModel.PrimaryPart
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- ========== FIX 3: Enhanced GameCore integration ==========
-- ADD this to your GameCore.lua to improve harvest detection:

function GameCore:ClearPlotProperly(plotModel)
	print("🧹 GameCore: ENHANCED clearing plot: " .. plotModel.Name)

	-- Try multiple approaches to find and remove the crop
	local cropRemoved = false

	-- Method 1: Standard CropModel lookup
	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel then
		print("🧹 Found CropModel - removing")
		cropModel:Destroy()
		cropRemoved = true
	end

	if cropRemoved then
		print("🧹 Successfully removed crop visual")
	else
		warn("🧹 No crop visual found to remove")
		print("🧹 Plot contents:")
		for _, child in pairs(plotModel:GetChildren()) do
			print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
		end
	end

	-- Clear all crop-related attributes
	plotModel:SetAttribute("IsEmpty", true)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("SeedType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", 0)
	plotModel:SetAttribute("Rarity", "common")

	-- Restore green indicator if it exists
	local indicator = plotModel:FindFirstChild("Indicator")
	if indicator then
		indicator.Color = Color3.fromRGB(100, 255, 100)
	end

	print("🧹 Plot clearing complete")
end

-- ========== MANUAL HARVEST TESTING FUNCTION ==========

-- Add this for testing harvest functionality
_G.TestHarvest = function(plotName)
	plotName = plotName or "Plot1"

	-- Find the plot
	local plot = nil
	for _, area in pairs(workspace:GetChildren()) do
		if area.Name == "Areas" then
			for _, child in pairs(area:GetDescendants()) do
				if child.Name == plotName and child:IsA("Model") then
					plot = child
					break
				end
			end
		end
	end

	if plot then
		print("🧪 Testing harvest on " .. plot.Name)
		CropVisualManager:OnCropHarvested(plot, "carrot", "common")
	else
		print("❌ Could not find plot: " .. plotName)
	end
end

-- Add this for testing positioning
_G.TestCropPosition = function(cropType, plotName)
	cropType = cropType or "carrot"
	plotName = plotName or "Plot1"

	-- Find the plot
	local plot = nil
	for _, area in pairs(workspace:GetChildren()) do
		if area.Name == "Areas" then
			for _, child in pairs(area:GetDescendants()) do
				if child.Name == plotName and child:IsA("Model") then
					plot = child
					break
				end
			end
		end
	end

	if plot then
		print("🧪 Testing crop position for " .. cropType .. " on " .. plot.Name)
		CropVisualManager:ReplaceCropVisual(plot, cropType, "common", "ready")
	else
		print("❌ Could not find plot: " .. plotName)
	end
end
-- ========== MONITORING AND MAINTENANCE ==========

function CropVisualManager:StartModelMonitoring()
	print("CropVisualManager: Starting model monitoring system...")

	-- Monitor CropModels folder for changes
	if CropModels then
		CropModels.ChildAdded:Connect(function(child)
			wait(1) -- Wait for model to fully load
			print("CropVisualManager: New model detected: " .. child.Name)
			self:UpdateAvailableModels()
		end)

		CropModels.ChildRemoved:Connect(function(child)
			print("CropVisualManager: Model removed: " .. child.Name)
			self:UpdateAvailableModels()
		end)
	end

	-- Periodic health check
	spawn(function()
		while true do
			wait(300) -- Every 5 minutes
			self:PerformHealthCheck()
		end
	end)
end

function CropVisualManager:PerformHealthCheck()
	print("CropVisualManager: Performing health check...")

	-- Re-validate models
	self:UpdateAvailableModels()

	-- Clean up any orphaned crop visuals
	local cleanedCount = 0
	for _, area in pairs(workspace:GetChildren()) do
		if area.Name == "Areas" then
			for _, model in pairs(area:GetDescendants()) do
				if model:IsA("Model") and (model.Name:find("_premade") or model.Name:find("_procedural")) then
					-- Check if this crop visual has a valid parent plot
					local plotModel = model.Parent
					if not plotModel or not plotModel:FindFirstChild("SpotPart") then
						print("CropVisualManager: Cleaning up orphaned crop visual: " .. model.Name)
						model:Destroy()
						cleanedCount = cleanedCount + 1
					end
				end
			end
		end
	end

	if cleanedCount > 0 then
		print("CropVisualManager: Cleaned up " .. cleanedCount .. " orphaned crop visuals")
	end
end

-- ========== ENHANCED DEBUG FUNCTIONS ==========
function CropVisualManager:DebugGameCore()
	print("=== GAMECORE DEBUG ANALYSIS ===")

	if not GameCore then
		print("❌ GameCore is nil or not found")
		return
	end

	print("✅ GameCore found, analyzing structure...")
	print("GameCore type: " .. type(GameCore))

	-- Print all top-level properties
	print("\n📋 Top-level GameCore properties:")
	for key, value in pairs(GameCore) do
		local valueType = type(value)
		print("  " .. key .. ": " .. valueType)

		-- If it's a table, show some of its contents
		if valueType == "table" then
			local count = 0
			for subKey, subValue in pairs(value) do
				if count < 3 then -- Show first 3 items
					print("    - " .. subKey .. ": " .. type(subValue))
				end
				count = count + 1
			end
			if count > 3 then
				print("    - ... and " .. (count - 3) .. " more items")
			end
		end
	end

	-- Look for event-related properties
	print("\n🔍 Looking for event-related properties:")
	local eventKeywords = {"event", "signal", "harvest", "crop", "plant", "grow", "remote"}

	for key, value in pairs(GameCore) do
		local keyLower = key:lower()
		for _, keyword in ipairs(eventKeywords) do
			if keyLower:find(keyword) then
				print("  🎯 Found potential event: " .. key .. " (" .. type(value) .. ")")
			end
		end
	end

	-- Check for BindableEvents or RemoteEvents
	print("\n📡 Scanning for BindableEvents and RemoteEvents:")
	local function scanForEvents(obj, path)
		if not obj or type(obj) ~= "table" then return end

		for key, value in pairs(obj) do
			local fullPath = path .. "." .. key

			if type(value) == "userdata" then
				if value.ClassName == "BindableEvent" then
					print("  📡 BindableEvent: " .. fullPath)
				elseif value.ClassName == "RemoteEvent" then
					print("  📡 RemoteEvent: " .. fullPath)
				end
			elseif type(value) == "table" and not fullPath:find("%.") then -- Only go one level deep
				scanForEvents(value, fullPath)
			end
		end
	end

	scanForEvents(GameCore, "GameCore")

	print("================================")
end

function CropVisualManager:DebugModelAvailability()
	print("=== ENHANCED CROP MODEL DEBUG ===")

	print("CropModels folder status:")
	if CropModels then
		print("  ✅ Found at: " .. CropModels:GetFullName())
		print("  📁 Contains " .. #CropModels:GetChildren() .. " children")
	else
		print("  ❌ CropModels folder not found")
	end

	print("\nExpected crop types and model availability:")
	for cropType, cropData in pairs(self.CropSpecificVisuals) do
		local hasModel = self:HasPreMadeModelWithAliases(cropType)
		local validationInfo = self:GetModelValidationInfo(cropType)

		print("  " .. cropType .. ":")
		print("    Available: " .. (hasModel and "✅ YES" or "❌ NO"))

		if cropData.modelAliases then
			print("    Aliases: " .. table.concat(cropData.modelAliases, ", "))
		end

		if validationInfo then
			if validationInfo.valid then
				print("    Validation: ✅ PASSED")
			else
				print("    Validation: ❌ FAILED - " .. table.concat(validationInfo.issues, ", "))
			end
		end
	end

	print("\nActual models in CropModels folder:")
	if CropModels then
		for _, model in pairs(CropModels:GetChildren()) do
			if model:IsA("Model") then
				local validationInfo = self:GetModelValidationInfo(model.Name:lower())
				local status = validationInfo and (validationInfo.valid and "✅" or "❌") or "❓"
				print("  " .. status .. " " .. model.Name)
			end
		end
	end

	print("=================================")
end

-- ========== INITIALIZATION ==========

function CropVisualManager:Initialize()
	print("CropVisualManager: Initializing enhanced crop visual system...")

	-- Update available models
	self:UpdateAvailableModels()

	-- Setup GameCore integration
	self:SetupGameCoreIntegration()

	-- Start monitoring systems
	self:StartModelMonitoring()

	print("CropVisualManager: ✅ Enhanced crop visual system ready!")
	print("🎯 Features:")
	print("  🎭 Pre-made model support with validation")
	print("  🔄 Intelligent model switching between stages")
	print("  📏 Enhanced scaling and positioning")
	print("  🌈 Advanced rarity visual effects")
	print("  🔗 Deep GameCore integration")
	print("  🔍 Model monitoring and health checks")
	print("  🐛 Enhanced debugging tools")
end
function CropVisualManager:DebugCropStability(cropModel)
	if not cropModel then
		print("❌ No crop model provided for stability debug")
		return
	end

	print("=== CROP STABILITY DEBUG: " .. cropModel.Name .. " ===")

	print("Model attributes:")
	for _, attrName in ipairs({"CropType", "Rarity", "GrowthStage", "ModelType", "IsStable"}) do
		local value = cropModel:GetAttribute(attrName)
		print("  " .. attrName .. ": " .. tostring(value))
	end

	print("Primary part status:")
	if cropModel.PrimaryPart then
		print("  Position: " .. tostring(cropModel.PrimaryPart.Position))
		print("  Anchored: " .. tostring(cropModel.PrimaryPart.Anchored))
		print("  CanCollide: " .. tostring(cropModel.PrimaryPart.CanCollide))
		print("  Velocity: " .. tostring(cropModel.PrimaryPart.AssemblyLinearVelocity))
	else
		print("  ❌ No PrimaryPart found")
	end

	print("All parts status:")
	local anchoredCount = 0
	local totalParts = 0

	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			totalParts = totalParts + 1
			if part.Anchored then
				anchoredCount = anchoredCount + 1
			else
				print("  ⚠️ Unanchored part: " .. part.Name)
			end
		end
	end

	print("  Anchored parts: " .. anchoredCount .. "/" .. totalParts)
	print("==========================================")
end

-- Global debug function
_G.DebugCropStability = function(cropName)
	for _, model in pairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model.Name:find(cropName or "") then
			CropVisualManager:DebugCropStability(model)
			break
		end
	end
end

print("🔒 CROP STABILITY FIXES LOADED!")
print("✅ Enhanced anchoring system")
print("✅ Stable positioning logic") 
print("✅ Safe animation system")
print("✅ Movement monitoring")
print("✅ Debug tools: _G.DebugCropStability('cropName')")
-- ========== GLOBAL ACCESS AND DEBUG ==========

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
	local testCrops = {"cabbage", "carrot", "corn", "radish", "strawberry", "tomato", "wheat", "broccoli", "potato"}
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

	print("Created enhanced test showcase for all crop models!")
end

_G.DebugCropModels = function()
	CropVisualManager:DebugModelAvailability()
end

_G.RefreshCropModels = function()
	CropVisualManager:UpdateAvailableModels()
	print("Refreshed crop model availability")
end

_G.TestModelValidation = function()
	print("=== MODEL VALIDATION TEST ===")
	if CropModels then
		for _, model in pairs(CropModels:GetChildren()) do
			if model:IsA("Model") then
				local isValid, issues = CropVisualManager:ValidateModel(model)
				print(model.Name .. ": " .. (isValid and "✅ VALID" or "❌ INVALID"))
				if not isValid then
					for _, issue in ipairs(issues) do
						print("  - " .. issue)
					end
				end
			end
		end
	end
	print("============================")
end

-- Initialize the enhanced system
CropVisualManager:Initialize()

print("=== ENHANCED CROP VISUAL MANAGER LOADED ===")
print("🌱 MAJOR ENHANCEMENTS:")
print("  🎭 Intelligent pre-made model detection with aliases")
print("  ✅ Model validation and health monitoring")
print("  🔄 Seamless model type switching between growth stages")
print("  📏 Advanced scaling with safety checks")
print("  🎯 Enhanced positioning and primary part detection")
print("  🔗 Deep GameCore integration with event system")
print("  🐛 Comprehensive debugging and monitoring tools")
print("")
print("🔧 Enhanced Commands:")
print("  _G.DebugCropModels() - Show detailed model availability")
print("  _G.TestModelValidation() - Validate all models")
print("  _G.RefreshCropModels() - Refresh model cache")
print("  _G.CreateTestCrop('carrot', 'legendary', 'ready')")
print("  _G.TestAllCropModels() - Create showcase with validation")

return CropVisualManager