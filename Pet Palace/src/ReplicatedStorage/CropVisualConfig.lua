--[[
    CropVisualConfig.lua - Visual Effects Configuration
    Place in: ReplicatedStorage/CropVisualConfig.lua
    
    PURPOSE:
    ✅ Easy customization of all visual effects
    ✅ Non-technical users can modify visual settings
    ✅ Performance tuning options
    ✅ Custom crop visual definitions
    ✅ Particle effect presets
]]

local CropVisualConfig = {}

-- ========== PERFORMANCE SETTINGS ==========

CropVisualConfig.Performance = {
	-- Maximum particle rate per crop (reduces automatically with many crops)
	maxParticleRate = 20,

	-- Distance at which crop visuals are simplified
	simplificationDistance = 100,

	-- Maximum number of crops before performance optimization kicks in
	optimizationThreshold = 50,

	-- Enable/disable specific effect types for performance
	enableParticles = true,
	enableAuras = true,
	enableSounds = true,
	enableAnimations = true,
	enableSpecialEffects = true,

	-- Update frequencies (in seconds)
	growthCheckInterval = 5,
	performanceCheckInterval = 30,
	animationUpdateRate = 0.1
}

-- ========== EASY VISUAL PRESETS ==========

CropVisualConfig.VisualPresets = {
	-- Simple preset with minimal effects
	simple = {
		particleMultiplier = 0.3,
		glowIntensity = 0.5,
		animationSpeed = 0.7,
		soundVolume = 0.2,
		effectComplexity = "low"
	},

	-- Standard preset (default)
	standard = {
		particleMultiplier = 1.0,
		glowIntensity = 1.0,
		animationSpeed = 1.0,
		soundVolume = 0.3,
		effectComplexity = "medium"
	},

	-- Spectacular preset with maximum effects
	spectacular = {
		particleMultiplier = 2.0,
		glowIntensity = 1.5,
		animationSpeed = 1.3,
		soundVolume = 0.5,
		effectComplexity = "high"
	},

	-- Ultra preset for special events
	ultra = {
		particleMultiplier = 3.0,
		glowIntensity = 2.0,
		animationSpeed = 1.5,
		soundVolume = 0.7,
		effectComplexity = "maximum"
	}
}

-- ========== CUSTOM CROP VISUAL DEFINITIONS ==========

CropVisualConfig.CustomCropVisuals = {
	-- Add your own custom crop visuals here

	-- Example: Special holiday crop
	candy_cane_crop = {
		primaryColor = Color3.fromRGB(255, 0, 0),
		secondaryColor = Color3.fromRGB(255, 255, 255),
		specialEffects = {"sparkle_trail", "minty_aroma", "holiday_magic"},
		harvestEffect = "candy_explosion",
		premiumCrop = true,

		-- Custom geometry function
		customGeometry = function(cropModel, stageData)
			-- Add candy cane stripes
			local primaryPart = cropModel.PrimaryPart
			for i = 1, 5 do
				local stripe = Instance.new("Part")
				stripe.Name = "CandyStripe" .. i
				stripe.Size = Vector3.new(2.2, 0.2, 2.2) * stageData.sizeMultiplier
				stripe.Color = i % 2 == 0 and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
				stripe.Material = Enum.Material.Neon
				stripe.CanCollide = false
				stripe.Anchored = true
				stripe.Transparency = stageData.transparency
				stripe.Shape = Enum.PartType.Cylinder
				stripe.CFrame = primaryPart.CFrame * CFrame.new(0, -1 + i * 0.4, 0) * CFrame.Angles(math.rad(90), 0, 0)
				stripe.Parent = cropModel
			end
		end
	},

	-- Example: Magic mushroom
	magic_mushroom = {
		primaryColor = Color3.fromRGB(128, 0, 128),
		secondaryColor = Color3.fromRGB(255, 255, 255),
		specialEffects = {"mystic_spores", "reality_shimmer", "magic_pulse"},
		harvestEffect = "magic_explosion",
		premiumCrop = true,

		customGeometry = function(cropModel, stageData)
			-- Add mushroom cap spots
			local primaryPart = cropModel.PrimaryPart
			for i = 1, 8 do
				local spot = Instance.new("Part")
				spot.Name = "MushroomSpot" .. i
				spot.Size = Vector3.new(0.3, 0.3, 0.3) * stageData.sizeMultiplier
				spot.Color = Color3.fromRGB(255, 255, 255)
				spot.Material = Enum.Material.Neon
				spot.CanCollide = false
				spot.Anchored = true
				spot.Transparency = stageData.transparency
				spot.Shape = Enum.PartType.Ball

				local angle = (i - 1) * 45
				local radius = 0.8 * stageData.sizeMultiplier
				local x = math.cos(math.rad(angle)) * radius
				local z = math.sin(math.rad(angle)) * radius
				spot.CFrame = primaryPart.CFrame * CFrame.new(x, 0.5, z)
				spot.Parent = cropModel
			end
		end
	}
}

-- ========== PARTICLE EFFECT PRESETS ==========

CropVisualConfig.ParticlePresets = {
	-- Gentle nature effects
	gentle_sparkle = {
		texture = "rbxassetid://241650934",
		lifetime = NumberRange.new(1.0, 2.0),
		rate = 3,
		speed = NumberRange.new(1, 3),
		spreadAngle = Vector2.new(30, 30),
		colors = {Color3.fromRGB(200, 255, 200)},
		sizes = {0, 0.2, 0}
	},

	-- Magical effects
	magic_sparkle = {
		texture = "rbxassetid://241650934",
		lifetime = NumberRange.new(1.5, 3.0),
		rate = 8,
		speed = NumberRange.new(2, 5),
		spreadAngle = Vector2.new(60, 60),
		colors = {
			Color3.fromRGB(255, 0, 255),
			Color3.fromRGB(128, 0, 128),
			Color3.fromRGB(255, 255, 255)
		},
		sizes = {0, 0.5, 0}
	},

	-- Epic energy effects
	energy_burst = {
		texture = "rbxassetid://241650934",
		lifetime = NumberRange.new(2.0, 4.0),
		rate = 15,
		speed = NumberRange.new(5, 10),
		spreadAngle = Vector2.new(90, 90),
		colors = {
			Color3.fromRGB(255, 215, 0),
			Color3.fromRGB(255, 140, 0),
			Color3.fromRGB(255, 0, 0)
		},
		sizes = {0, 0.8, 0}
	},

	-- Legendary divine effects
	divine_radiance = {
		texture = "rbxassetid://241650934",
		lifetime = NumberRange.new(3.0, 6.0),
		rate = 25,
		speed = NumberRange.new(8, 15),
		spreadAngle = Vector2.new(180, 180),
		colors = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(255, 215, 0),
			Color3.fromRGB(255, 100, 100),
			Color3.fromRGB(255, 0, 255)
		},
		sizes = {0, 1.2, 0}
	}
}

-- ========== HARVEST EFFECT CONFIGURATIONS ==========

CropVisualConfig.HarvestEffects = {
	-- Simple harvest burst
	basic_harvest = {
		particleCount = 8,
		particleSize = Vector3.new(0.2, 0.2, 0.2),
		velocityRange = 15,
		upwardForce = 5,
		lifetime = 1.0,
		colors = {Color3.fromRGB(255, 255, 255)}
	},

	-- Golden explosion
	golden_explosion = {
		particleCount = 20,
		particleSize = Vector3.new(0.3, 0.3, 0.3),
		velocityRange = 25,
		upwardForce = 15,
		lifetime = 2.0,
		colors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0)}
	},

	-- Rainbow burst
	rainbow_burst = {
		particleCount = 30,
		particleSize = Vector3.new(0.4, 0.4, 0.4),
		velocityRange = 35,
		upwardForce = 20,
		lifetime = 3.0,
		colors = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 127, 0),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(75, 0, 130),
			Color3.fromRGB(148, 0, 211)
		}
	},

	-- Divine supernova
	divine_supernova = {
		particleCount = 50,
		particleSize = Vector3.new(0.5, 0.5, 0.5),
		velocityRange = 50,
		upwardForce = 30,
		lifetime = 5.0,
		colors = {Color3.fromRGB(255, 255, 255)},
		specialEffects = {
			lightPillars = true,
			shockwave = true,
			screenShake = true,
			soundEffect = "epic_explosion"
		}
	}
}

-- ========== SOUND EFFECT CONFIGURATIONS ==========

CropVisualConfig.SoundEffects = {
	-- Growth stage sounds
	plant_sound = {
		soundId = "rbxassetid://131961136",
		volume = 0.1,
		pitch = 1.0
	},

	sprout_sound = {
		soundId = "rbxassetid://131961136",
		volume = 0.15,
		pitch = 1.2
	},

	grow_sound = {
		soundId = "rbxassetid://131961136",
		volume = 0.2,
		pitch = 1.1
	},

	ready_sound = {
		soundId = "rbxassetid://131961136",
		volume = 0.25,
		pitch = 1.3
	},

	-- Harvest sounds
	basic_harvest_sound = {
		soundId = "rbxassetid://131961136",
		volume = 0.3,
		pitch = 1.0
	},

	rare_harvest_sound = {
		soundId = "rbxassetid://131961136",
		volume = 0.4,
		pitch = 1.2
	},

	legendary_harvest_sound = {
		soundId = "rbxassetid://131961136",
		volume = 0.6,
		pitch = 1.5
	},

	epic_explosion = {
		soundId = "rbxassetid://131961136",
		volume = 0.8,
		pitch = 0.8
	}
}

-- ========== ANIMATION CONFIGURATIONS ==========

CropVisualConfig.Animations = {
	-- Gentle swaying for most crops
	gentle_sway = {
		rotationAmount = 5, -- degrees
		swaySpeed = 3, -- seconds per cycle
		randomness = 0.3 -- variation factor
	},

	-- Energetic movement for rare crops
	energetic_sway = {
		rotationAmount = 10,
		swaySpeed = 2,
		randomness = 0.5
	},

	-- Magical floating for legendary crops
	magical_float = {
		floatHeight = 2, -- studs
		floatSpeed = 4, -- seconds per cycle
		rotationSpeed = 8 -- degrees per second
	},

	-- Pulsing effect for special crops
	divine_pulse = {
		sizeVariation = 0.2, -- percentage
		pulseSpeed = 2, -- seconds per cycle
		glowVariation = 0.5 -- glow intensity variation
	}
}

-- ========== RARITY CONFIGURATIONS ==========

CropVisualConfig.RaritySettings = {
	common = {
		sizeMultiplier = 1.0,
		glowIntensity = 0.0,
		particleIntensity = 0.3,
		animationType = "gentle_sway",
		specialEffects = false
	},

	uncommon = {
		sizeMultiplier = 1.1,
		glowIntensity = 0.5,
		particleIntensity = 0.6,
		animationType = "gentle_sway",
		specialEffects = false
	},

	rare = {
		sizeMultiplier = 1.2,
		glowIntensity = 0.8,
		particleIntensity = 1.0,
		animationType = "energetic_sway",
		specialEffects = true
	},

	epic = {
		sizeMultiplier = 1.5,
		glowIntensity = 1.2,
		particleIntensity = 1.5,
		animationType = "energetic_sway",
		specialEffects = true
	},

	legendary = {
		sizeMultiplier = 2.0,
		glowIntensity = 2.0,
		particleIntensity = 2.5,
		animationType = "magical_float",
		specialEffects = true
	}
}

-- ========== SEASONAL THEMES ==========

CropVisualConfig.SeasonalThemes = {
	spring = {
		particleColors = {Color3.fromRGB(144, 238, 144), Color3.fromRGB(255, 192, 203)},
		ambientSounds = "birds_chirping",
		specialEffects = {"flower_petals", "fresh_breeze"}
	},

	summer = {
		particleColors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0)},
		ambientSounds = "summer_breeze",
		specialEffects = {"sun_rays", "heat_shimmer"}
	},

	autumn = {
		particleColors = {Color3.fromRGB(255, 140, 0), Color3.fromRGB(165, 42, 42)},
		ambientSounds = "wind_rustling",
		specialEffects = {"falling_leaves", "harvest_glow"}
	},

	winter = {
		particleColors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(173, 216, 230)},
		ambientSounds = "wind_howling",
		specialEffects = {"snowflakes", "frost_crystals"}
	}
}

-- ========== UTILITY FUNCTIONS ==========

function CropVisualConfig.GetCurrentPreset()
	return "standard" -- Change this to switch global preset
end

function CropVisualConfig.GetPresetSettings(presetName)
	return CropVisualConfig.VisualPresets[presetName] or CropVisualConfig.VisualPresets.standard
end

function CropVisualConfig.GetParticlePreset(presetName)
	return CropVisualConfig.ParticlePresets[presetName]
end

function CropVisualConfig.GetHarvestEffect(effectName)
	return CropVisualConfig.HarvestEffects[effectName] or CropVisualConfig.HarvestEffects.basic_harvest
end

function CropVisualConfig.GetSoundEffect(soundName)
	return CropVisualConfig.SoundEffects[soundName]
end

function CropVisualConfig.GetAnimation(animationName)
	return CropVisualConfig.Animations[animationName] or CropVisualConfig.Animations.gentle_sway
end

function CropVisualConfig.GetRaritySettings(rarity)
	return CropVisualConfig.RaritySettings[rarity] or CropVisualConfig.RaritySettings.common
end

function CropVisualConfig.GetSeasonalTheme(season)
	return CropVisualConfig.SeasonalThemes[season] or CropVisualConfig.SeasonalThemes.spring
end

-- ========== CUSTOM CONFIGURATION LOADER ==========

function CropVisualConfig.LoadCustomConfiguration()
	-- This function can be used to load custom configurations
	-- from external sources like datastores or HTTP requests

	print("CropVisualConfig: Loading custom visual configurations...")

	-- Example: Load seasonal theme based on current date
	local currentMonth = tonumber(os.date("%m"))
	local currentSeason = "spring"

	if currentMonth >= 3 and currentMonth <= 5 then
		currentSeason = "spring"
	elseif currentMonth >= 6 and currentMonth <= 8 then
		currentSeason = "summer"
	elseif currentMonth >= 9 and currentMonth <= 11 then
		currentSeason = "autumn"
	else
		currentSeason = "winter"
	end

	CropVisualConfig.ActiveSeason = currentSeason
	print("CropVisualConfig: Set active season to " .. currentSeason)
end

-- ========== PERFORMANCE OPTIMIZATION ==========

function CropVisualConfig.GetOptimizedSettings(cropCount)
	local settings = CropVisualConfig.GetPresetSettings(CropVisualConfig.GetCurrentPreset())

	-- Reduce effects based on crop count
	if cropCount > 100 then
		settings.particleMultiplier = settings.particleMultiplier * 0.5
		settings.effectComplexity = "low"
	elseif cropCount > 200 then
		settings.particleMultiplier = settings.particleMultiplier * 0.25
		settings.effectComplexity = "minimal"
	end

	return settings
end

-- ========== VALIDATION ==========

function CropVisualConfig.ValidateConfiguration()
	print("CropVisualConfig: Validating configuration...")

	local errors = {}

	-- Check that all presets exist
	for presetName, _ in pairs(CropVisualConfig.VisualPresets) do
		if type(presetName) ~= "string" then
			table.insert(errors, "Invalid preset name: " .. tostring(presetName))
		end
	end

	-- Check rarity settings
	local requiredRarities = {"common", "uncommon", "rare", "epic", "legendary"}
	for _, rarity in ipairs(requiredRarities) do
		if not CropVisualConfig.RaritySettings[rarity] then
			table.insert(errors, "Missing rarity configuration: " .. rarity)
		end
	end

	if #errors > 0 then
		warn("CropVisualConfig: Configuration errors found:")
		for _, error in ipairs(errors) do
			warn("  " .. error)
		end
		return false
	end

	print("CropVisualConfig: ✅ Configuration valid!")
	return true
end

-- ========== INITIALIZATION ==========

function CropVisualConfig.Initialize()
	print("CropVisualConfig: Initializing visual configuration system...")

	-- Load custom configurations
	CropVisualConfig.LoadCustomConfiguration()

	-- Validate configuration
	CropVisualConfig.ValidateConfiguration()

	print("CropVisualConfig: ✅ Configuration system ready!")
end

-- Auto-initialize
CropVisualConfig.Initialize()

-- ========== GLOBAL ACCESS ==========

_G.CropVisualConfig = CropVisualConfig

-- Debug functions
_G.SetVisualPreset = function(presetName)
	if CropVisualConfig.VisualPresets[presetName] then
		CropVisualConfig.CurrentPreset = presetName
		print("Set visual preset to: " .. presetName)
		return true
	else
		warn("Unknown preset: " .. presetName)
		return false
	end
end

_G.GetVisualPresets = function()
	print("Available visual presets:")
	for presetName, settings in pairs(CropVisualConfig.VisualPresets) do
		print("  " .. presetName .. ": " .. settings.effectComplexity .. " complexity")
	end
end

print("=== CROP VISUAL CONFIG LOADED ===")
print("⚙️ CONFIGURATION FEATURES:")
print("  🎛️ Easy visual effect presets")
print("  🎨 Custom crop visual definitions")
print("  ⚡ Performance optimization settings")
print("  🎵 Sound effect configurations")
print("  🎬 Animation settings")
print("  🌈 Rarity-based visual scaling")
print("  🌍 Seasonal theme support")
print("  📊 Automatic performance adjustment")
print("")
print("🔧 Available Presets:")
for presetName, settings in pairs(CropVisualConfig.VisualPresets) do
	print("  " .. presetName .. ": " .. settings.effectComplexity .. " complexity")
end
print("")
print("🎮 Commands:")
print("  _G.SetVisualPreset('spectacular') - Change preset")
print("  _G.GetVisualPresets() - List all presets")

return CropVisualConfig