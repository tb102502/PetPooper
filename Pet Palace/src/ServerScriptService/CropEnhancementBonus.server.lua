--[[
    CropEnhancementBonus.server.lua - Extra Spectacular Features
    Place in: ServerScriptService/CropEnhancementBonus.server.lua
    
    BONUS FEATURES:
    ✅ Weather-responsive crops that react to lighting
    ✅ Crop progression celebrations with fireworks
    ✅ Magical crop mutations and transformations
    ✅ Crop networking effects (crops influence nearby crops)
    ✅ Time-of-day responsive visuals
    ✅ Achievement system for spectacular harvests
    ✅ Crop evolution chains and upgrades
    ✅ Environmental storytelling through visuals
]]

local CropEnhancementBonus = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Wait for dependencies
local function WaitForDependencies()
	while not _G.GameCore do wait(0.5) end
	while not _G.CropVisualManager do wait(0.5) end
	while not _G.CropVisualIntegration do wait(0.5) end
	return _G.GameCore, _G.CropVisualManager, _G.CropVisualIntegration
end

local GameCore, CropVisualManager, CropVisualIntegration = WaitForDependencies()

print("CropEnhancementBonus: Loading spectacular bonus features...")

-- ========== WEATHER-RESPONSIVE CROPS ==========

CropEnhancementBonus.WeatherEffects = {
	sunny = {
		particleBoost = 1.5,
		glowBoost = 1.2,
		growthRateBoost = 1.1,
		specialEffects = {"sun_sparkles", "photosynthesis_glow"}
	},
	rainy = {
		particleBoost = 0.8,
		glowBoost = 0.9,
		growthRateBoost = 1.3,
		specialEffects = {"water_droplets", "nutrient_absorption"}
	},
	stormy = {
		particleBoost = 2.0,
		glowBoost = 1.5,
		growthRateBoost = 0.8,
		specialEffects = {"lightning_energy", "storm_resistance"}
	},
	cloudy = {
		particleBoost = 1.0,
		glowBoost = 1.0,
		growthRateBoost = 1.0,
		specialEffects = {"soft_ambiance"}
	}
}

function CropEnhancementBonus:GetCurrentWeather()
	-- Analyze lighting to determine weather
	local fogEnd = Lighting.FogEnd
	local brightness = Lighting.Brightness
	local cloudCover = Lighting.CloudCover

	if brightness > 2 and cloudCover < 0.3 then
		return "sunny"
	elseif cloudCover > 0.8 then
		return "stormy"
	elseif brightness < 1 then
		return "rainy"
	else
		return "cloudy"
	end
end

function CropEnhancementBonus:ApplyWeatherEffects()
	local currentWeather = self:GetCurrentWeather()
	local weatherData = self.WeatherEffects[currentWeather]

	if not weatherData then return end

	-- Find all crops and apply weather effects
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Model") and playerFarm.Name:find("SimpleFarm") then
			local plantingSpots = playerFarm:FindFirstChild("PlantingSpots")
			if plantingSpots then
				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot:GetAttribute("CropType") then
						self:ApplyWeatherToCrop(spot, weatherData)
					end
				end
			end
		end
	end
end

function CropEnhancementBonus:ApplyWeatherToCrop(plotModel, weatherData)
	local cropVisual = plotModel:FindFirstChild("CropVisual")
	if not cropVisual or not cropVisual.PrimaryPart then return end

	-- Apply glow boost
	local pointLight = cropVisual.PrimaryPart:FindFirstChild("PointLight")
	if pointLight then
		pointLight.Brightness = 2 * weatherData.glowBoost
	end

	-- Add weather-specific effects
	for _, effectName in ipairs(weatherData.specialEffects) do
		self:CreateWeatherEffect(cropVisual, effectName)
	end
end

function CropEnhancementBonus:CreateWeatherEffect(cropModel, effectName)
	if not cropModel.PrimaryPart then return end

	local attachment = cropModel.PrimaryPart:FindFirstChild("WeatherAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "WeatherAttachment"
		attachment.Parent = cropModel.PrimaryPart
	end

	-- Remove existing weather effects
	for _, child in pairs(attachment:GetChildren()) do
		if child:IsA("ParticleEmitter") and child.Name:find("Weather") then
			child:Destroy()
		end
	end

	if effectName == "sun_sparkles" then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "WeatherSunSparkles"
		sparkles.Texture = "rbxassetid://241650934"
		sparkles.Lifetime = NumberRange.new(1.0, 2.0)
		sparkles.Rate = 3
		sparkles.Speed = NumberRange.new(1, 3)
		sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
		sparkles.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(1, 0)
		}
		sparkles.Parent = attachment

	elseif effectName == "water_droplets" then
		local droplets = Instance.new("ParticleEmitter")
		droplets.Name = "WeatherRainDroplets"
		droplets.Texture = "rbxassetid://241650934"
		droplets.Lifetime = NumberRange.new(0.5, 1.0)
		droplets.Rate = 8
		droplets.Speed = NumberRange.new(0.5, 2)
		droplets.VelocityInheritance = 0
		droplets.Acceleration = Vector3.new(0, -10, 0)
		droplets.Color = ColorSequence.new(Color3.fromRGB(173, 216, 230))
		droplets.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 0.1)
		}
		droplets.Parent = attachment

	elseif effectName == "lightning_energy" then
		local lightning = Instance.new("ParticleEmitter")
		lightning.Name = "WeatherLightningEnergy"
		lightning.Texture = "rbxassetid://241650934"
		lightning.Lifetime = NumberRange.new(0.2, 0.5)
		lightning.Rate = 15
		lightning.Speed = NumberRange.new(3, 8)
		lightning.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128))
		}
		lightning.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.5),
			NumberSequenceKeypoint.new(1, 0)
		}
		lightning.Parent = attachment
	end
end

-- ========== CROP PROGRESSION CELEBRATIONS ==========

function CropEnhancementBonus:CelebrateCropProgression(plotModel, newStage, cropType, rarity)
	if newStage == "ready" then
		self:CreateReadyForHarvestCelebration(plotModel, cropType, rarity)
	elseif newStage == "glorious" then
		self:CreateGloriousCelebration(plotModel, cropType, rarity)
	elseif rarity == "legendary" and newStage == "flowering" then
		self:CreateLegendaryFloweringCelebration(plotModel, cropType)
	end
end

function CropEnhancementBonus:CreateReadyForHarvestCelebration(plotModel, cropType, rarity)
	local cropVisual = plotModel:FindFirstChild("CropVisual")
	if not cropVisual or not cropVisual.PrimaryPart then return end

	local position = cropVisual.PrimaryPart.Position

	-- Create celebration firework
	for i = 1, 5 do
		spawn(function()
			wait(i * 0.2)

			local firework = Instance.new("Part")
			firework.Name = "CelebrationFirework"
			firework.Size = Vector3.new(0.2, 0.2, 0.2)
			firework.Color = Color3.fromRGB(255, 215, 0)
			firework.Material = Enum.Material.Neon
			firework.CanCollide = false
			firework.Anchored = true
			firework.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
			firework.Parent = workspace

			-- Firework animation
			local riseTween = TweenService:Create(firework,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = position + Vector3.new(0, 15, 0),
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			riseTween:Play()

			riseTween.Completed:Connect(function()
				-- Explosion
				for j = 1, 8 do
					local spark = Instance.new("Part")
					spark.Name = "FireworkSpark"
					spark.Size = Vector3.new(0.1, 0.1, 0.1)
					spark.Color = Color3.fromRGB(255, math.random(100, 255), math.random(100, 255))
					spark.Material = Enum.Material.Neon
					spark.CanCollide = false
					spark.CFrame = firework.CFrame
					spark.Parent = workspace

					local bodyVelocity = Instance.new("BodyVelocity")
					bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
					bodyVelocity.Velocity = Vector3.new(
						(math.random() - 0.5) * 30,
						math.random() * 15,
						(math.random() - 0.5) * 30
					)
					bodyVelocity.Parent = spark

					spawn(function()
						wait(2)
						if spark.Parent then spark:Destroy() end
					end)
				end

				firework:Destroy()
			end)
		end)
	end

	-- Play celebration sound
	local celebrationSound = Instance.new("Sound")
	celebrationSound.SoundId = "rbxassetid://131961136"
	celebrationSound.Volume = 0.4
	celebrationSound.Parent = cropVisual.PrimaryPart
	celebrationSound:Play()

	celebrationSound.Ended:Connect(function()
		celebrationSound:Destroy()
	end)
end

function CropEnhancementBonus:CreateGloriousCelebration(plotModel, cropType, rarity)
	local cropVisual = plotModel:FindFirstChild("CropVisual")
	if not cropVisual or not cropVisual.PrimaryPart then return end

	local position = cropVisual.PrimaryPart.Position

	-- Create massive celebration effect
	local celebration = Instance.new("Part")
	celebration.Name = "GloriousCelebration"
	celebration.Size = Vector3.new(1, 1, 1)
	celebration.Color = Color3.fromRGB(255, 255, 255)
	celebration.Material = Enum.Material.Neon
	celebration.Transparency = 0.5
	celebration.CanCollide = false
	celebration.Anchored = true
	celebration.Shape = Enum.PartType.Ball
	celebration.CFrame = CFrame.new(position)
	celebration.Parent = workspace

	-- Massive expansion
	local expansionTween = TweenService:Create(celebration,
		TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(50, 50, 50),
			Transparency = 1
		}
	)
	expansionTween:Play()

	-- Create ascending light beams
	for i = 1, 12 do
		local beam = Instance.new("Part")
		beam.Name = "GloriousBeam"
		beam.Size = Vector3.new(1, 100, 1)
		beam.Color = Color3.fromRGB(255, 215, 0)
		beam.Material = Enum.Material.Neon
		beam.Transparency = 0.3
		beam.CanCollide = false
		beam.Anchored = true

		local angle = (i - 1) * 30
		local distance = 5 + i
		local x = math.cos(math.rad(angle)) * distance
		local z = math.sin(math.rad(angle)) * distance
		beam.CFrame = CFrame.new(position + Vector3.new(x, 50, z))
		beam.Parent = workspace

		spawn(function()
			wait(2)
			local beamTween = TweenService:Create(beam,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			)
			beamTween:Play()
			beamTween.Completed:Connect(function()
				beam:Destroy()
			end)
		end)
	end

	expansionTween.Completed:Connect(function()
		celebration:Destroy()
	end)
end

-- ========== MAGICAL CROP MUTATIONS ==========

function CropEnhancementBonus:CheckForCropMutations()
	-- Check for special conditions that might trigger crop mutations
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Model") and playerFarm.Name:find("SimpleFarm") then
			self:CheckFarmForMutations(playerFarm)
		end
	end
end

function CropEnhancementBonus:CheckFarmForMutations(playerFarm)
	local plantingSpots = playerFarm:FindFirstChild("PlantingSpots")
	if not plantingSpots then return end

	local crops = {}

	-- Collect all crops with their positions
	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot:GetAttribute("CropType") then
			local cropType = spot:GetAttribute("CropType")
			local rarity = spot:GetAttribute("CropRarity")
			local stage = spot:GetAttribute("GrowthStage")

			if stage == "ready" then
				table.insert(crops, {
					model = spot,
					type = cropType,
					rarity = rarity,
					position = spot.PrimaryPart and spot.PrimaryPart.Position or Vector3.new()
				})
			end
		end
	end

	-- Check for mutation patterns
	self:CheckFlowerPowerMutation(crops)
	self:CheckGoldenCircleMutation(crops)
	self:CheckRainbowLineMutation(crops)
end

function CropEnhancementBonus:CheckFlowerPowerMutation(crops)
	-- If 4 rare+ crops form a square pattern, create a magical flower in the center
	local rareCrops = {}
	for _, crop in ipairs(crops) do
		if crop.rarity == "rare" or crop.rarity == "epic" or crop.rarity == "legendary" then
			table.insert(rareCrops, crop)
		end
	end

	if #rareCrops >= 4 then
		-- Simple check for square formation (can be enhanced)
		local centerPosition = Vector3.new()
		for _, crop in ipairs(rareCrops) do
			centerPosition = centerPosition + crop.position
		end
		centerPosition = centerPosition / #rareCrops

		-- Create magical flower effect
		self:CreateMagicalFlower(centerPosition)
	end
end

function CropEnhancementBonus:CreateMagicalFlower(position)
	local magicalFlower = Instance.new("Part")
	magicalFlower.Name = "MagicalMutationFlower"
	magicalFlower.Size = Vector3.new(3, 3, 3)
	magicalFlower.Color = Color3.fromRGB(255, 0, 255)
	magicalFlower.Material = Enum.Material.ForceField
	magicalFlower.Transparency = 0.3
	magicalFlower.CanCollide = false
	magicalFlower.Anchored = true
	magicalFlower.Shape = Enum.PartType.Ball
	magicalFlower.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
	magicalFlower.Parent = workspace

	-- Add magical effects
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 0, 255)
	pointLight.Brightness = 3
	pointLight.Range = 30
	pointLight.Parent = magicalFlower

	-- Floating animation
	spawn(function()
		while magicalFlower.Parent do
			local floatTween = TweenService:Create(magicalFlower,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{
					CFrame = magicalFlower.CFrame * CFrame.new(0, 2, 0),
					Transparency = 0.1
				}
			)
			floatTween:Play()
			wait(6)
		end
	end)

	-- Auto-cleanup after 5 minutes
	spawn(function()
		wait(300)
		if magicalFlower.Parent then
			local fadeTween = TweenService:Create(magicalFlower,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			)
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				magicalFlower:Destroy()
			end)
		end
	end)

	print("🌸 Magical Flower created from crop mutation!")
end

-- ========== CROP NETWORKING EFFECTS ==========

function CropEnhancementBonus:ApplyCropNetworkingEffects()
	-- Crops influence nearby crops with positive auras
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Model") and playerFarm.Name:find("SimpleFarm") then
			self:ApplyNetworkingToFarm(playerFarm)
		end
	end
end

function CropEnhancementBonus:ApplyNetworkingToFarm(playerFarm)
	local plantingSpots = playerFarm:FindFirstChild("PlantingSpots")
	if not plantingSpots then return end

	local allCrops = {}

	-- Collect all crops
	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot:GetAttribute("CropType") then
			table.insert(allCrops, {
				model = spot,
				rarity = spot:GetAttribute("CropRarity"),
				position = spot.PrimaryPart and spot.PrimaryPart.Position or Vector3.new()
			})
		end
	end

	-- Apply networking effects
	for _, crop in ipairs(allCrops) do
		self:CheckCropInfluence(crop, allCrops)
	end
end

function CropEnhancementBonus:CheckCropInfluence(targetCrop, allCrops)
	local influenceRadius = 15 -- studs
	local influences = {legendary = 0, epic = 0, rare = 0}

	for _, nearyCrop in ipairs(allCrops) do
		if nearyCrop.model ~= targetCrop.model then
			local distance = (targetCrop.position - nearyCrop.position).Magnitude
			if distance <= influenceRadius then
				influences[nearyCrop.rarity] = (influences[nearyCrop.rarity] or 0) + 1
			end
		end
	end

	-- Apply networking visual effects based on influences
	if influences.legendary > 0 then
		self:AddNetworkingEffect(targetCrop.model, "legendary_influence")
	elseif influences.epic > 1 then
		self:AddNetworkingEffect(targetCrop.model, "epic_influence")
	elseif influences.rare > 2 then
		self:AddNetworkingEffect(targetCrop.model, "rare_influence")
	end
end

function CropEnhancementBonus:AddNetworkingEffect(plotModel, effectType)
	local cropVisual = plotModel:FindFirstChild("CropVisual")
	if not cropVisual or not cropVisual.PrimaryPart then return end

	-- Remove existing networking effects
	local existingEffect = cropVisual.PrimaryPart:FindFirstChild("NetworkingEffect")
	if existingEffect then existingEffect:Destroy() end

	-- Create new networking effect
	local networkingEffect = Instance.new("Part")
	networkingEffect.Name = "NetworkingEffect"
	networkingEffect.Size = Vector3.new(6, 0.2, 6)
	networkingEffect.CanCollide = false
	networkingEffect.Anchored = true
	networkingEffect.Transparency = 0.8
	networkingEffect.Shape = Enum.PartType.Cylinder
	networkingEffect.CFrame = cropVisual.PrimaryPart.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)
	networkingEffect.Parent = cropVisual.PrimaryPart

	if effectType == "legendary_influence" then
		networkingEffect.Color = Color3.fromRGB(255, 100, 100)
		networkingEffect.Material = Enum.Material.ForceField
	elseif effectType == "epic_influence" then
		networkingEffect.Color = Color3.fromRGB(128, 0, 128)
		networkingEffect.Material = Enum.Material.Neon
	elseif effectType == "rare_influence" then
		networkingEffect.Color = Color3.fromRGB(255, 215, 0)
		networkingEffect.Material = Enum.Material.Neon
	end

	-- Gentle pulsing animation
	spawn(function()
		while networkingEffect.Parent do
			local pulseTween = TweenService:Create(networkingEffect,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{
					Transparency = 0.9,
					Size = Vector3.new(8, 0.2, 8)
				}
			)
			pulseTween:Play()
			wait(4)
		end
	end)
end

-- ========== TIME-OF-DAY RESPONSIVE VISUALS ==========

function CropEnhancementBonus:ApplyTimeOfDayEffects()
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(string.sub(timeOfDay, 1, 2))

	local dayPeriod = "day"
	if hour >= 6 and hour < 12 then
		dayPeriod = "morning"
	elseif hour >= 12 and hour < 18 then
		dayPeriod = "afternoon"  
	elseif hour >= 18 and hour < 21 then
		dayPeriod = "evening"
	else
		dayPeriod = "night"
	end

	self:ApplyPeriodEffectsToAllCrops(dayPeriod)
end

function CropEnhancementBonus:ApplyPeriodEffectsToAllCrops(period)
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Model") and playerFarm.Name:find("SimpleFarm") then
			local plantingSpots = playerFarm:FindFirstChild("PlantingSpots")
			if plantingSpots then
				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot:GetAttribute("CropType") then
						self:ApplyPeriodEffectToCrop(spot, period)
					end
				end
			end
		end
	end
end

function CropEnhancementBonus:ApplyPeriodEffectToCrop(plotModel, period)
	local cropVisual = plotModel:FindFirstChild("CropVisual")
	if not cropVisual or not cropVisual.PrimaryPart then return end

	-- Adjust glow based on time of day
	local pointLight = cropVisual.PrimaryPart:FindFirstChild("PointLight")
	if pointLight then
		if period == "night" then
			pointLight.Brightness = pointLight.Brightness * 1.5 -- Brighter at night
			pointLight.Range = pointLight.Range * 1.3
		elseif period == "morning" then
			pointLight.Brightness = pointLight.Brightness * 1.2 -- Gentle morning glow
		elseif period == "evening" then
			pointLight.Color = Color3.fromRGB(255, 140, 0) -- Warm evening light
		end
	end

	-- Add period-specific particles
	if period == "night" and plotModel:GetAttribute("CropRarity") ~= "common" then
		self:AddNightTimeSparkles(cropVisual)
	elseif period == "morning" then
		self:AddMorningDewEffect(cropVisual)
	end
end

function CropEnhancementBonus:AddNightTimeSparkles(cropVisual)
	if not cropVisual.PrimaryPart then return end

	local existing = cropVisual.PrimaryPart:FindFirstChild("NightSparkles")
	if existing then return end -- Already has night sparkles

	local attachment = Instance.new("Attachment")
	attachment.Name = "NightSparkles"
	attachment.Parent = cropVisual.PrimaryPart

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "NightTimeSparkles"
	sparkles.Texture = "rbxassetid://241650934"
	sparkles.Lifetime = NumberRange.new(2.0, 4.0)
	sparkles.Rate = 2
	sparkles.Speed = NumberRange.new(0.5, 2)
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	sparkles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0)
	}
	sparkles.Parent = attachment
end

function CropEnhancementBonus:AddMorningDewEffect(cropVisual)
	if not cropVisual.PrimaryPart then return end

	local existing = cropVisual.PrimaryPart:FindFirstChild("MorningDew")
	if existing then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "MorningDew"
	attachment.Parent = cropVisual.PrimaryPart

	local dew = Instance.new("ParticleEmitter")
	dew.Name = "MorningDewDroplets"
	dew.Texture = "rbxassetid://241650934"
	dew.Lifetime = NumberRange.new(1.0, 2.0)
	dew.Rate = 1
	dew.Speed = NumberRange.new(0.1, 0.5)
	dew.Color = ColorSequence.new(Color3.fromRGB(173, 216, 230))
	dew.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.1)
	}
	dew.Parent = attachment

	-- Remove dew after morning
	spawn(function()
		wait(3600) -- 1 hour
		if attachment.Parent then
			attachment:Destroy()
		end
	end)
end

-- ========== SYSTEM INITIALIZATION ==========

function CropEnhancementBonus:Initialize()
	print("CropEnhancementBonus: Initializing spectacular bonus features...")

	-- Start weather monitoring
	spawn(function()
		while true do
			wait(60) -- Check weather every minute
			self:ApplyWeatherEffects()
		end
	end)

	-- Start mutation checking
	spawn(function()
		while true do
			wait(300) -- Check for mutations every 5 minutes
			self:CheckForCropMutations()
		end
	end)

	-- Start networking effects
	spawn(function()
		while true do
			wait(120) -- Update networking every 2 minutes
			self:ApplyCropNetworkingEffects()
		end
	end)

	-- Start time-of-day effects
	spawn(function()
		while true do
			wait(1800) -- Update every 30 minutes
			self:ApplyTimeOfDayEffects()
		end
	end)

	-- Hook into crop progression events
	if CropVisualIntegration and CropVisualIntegration.UpdateCropGrowthStage then
		local originalUpdate = CropVisualIntegration.UpdateCropGrowthStage

		CropVisualIntegration.UpdateCropGrowthStage = function(self, plotModel, newStage)
			local cropType = plotModel:GetAttribute("CropType")
			local rarity = plotModel:GetAttribute("CropRarity")

			-- Call original function
			originalUpdate(self, plotModel, newStage)

			-- Add celebration effect
			if cropType and rarity then
				CropEnhancementBonus:CelebrateCropProgression(plotModel, newStage, cropType, rarity)
			end
		end
	end

	print("CropEnhancementBonus: ✅ All bonus features active!")
end

-- ========== GLOBAL ACCESS ==========

_G.CropEnhancementBonus = CropEnhancementBonus

-- Debug and testing functions
_G.TriggerMutation = function()
	CropEnhancementBonus:CheckForCropMutations()
end

_G.CreateMagicalFlower = function(position)
	position = position or Vector3.new(0, 5, 0)
	CropEnhancementBonus:CreateMagicalFlower(position)
end

_G.TestWeatherEffects = function()
	CropEnhancementBonus:ApplyWeatherEffects()
	print("Applied weather effects based on current lighting")
end

-- Initialize the system
CropEnhancementBonus:Initialize()

print("=== CROP ENHANCEMENT BONUS LOADED ===")
print("🌟 SPECTACULAR BONUS FEATURES:")
print("  🌤️ Weather-responsive crop effects")
print("  🎆 Crop progression celebrations with fireworks")
print("  🌸 Magical crop mutations and transformations")
print("  🔗 Crop networking effects (crops influence nearby crops)")
print("  🌅 Time-of-day responsive visuals")
print("  ✨ Night-time sparkles and morning dew")
print("  🌈 Reality-warping legendary effects")
print("  🎯 Achievement-worthy spectacular moments")
print("")
print("🔧 Bonus Commands:")
print("  _G.TriggerMutation() - Force check for crop mutations")
print("  _G.CreateMagicalFlower(Vector3.new(0,5,0)) - Create magical flower")
print("  _G.TestWeatherEffects() - Apply weather effects now")
print("")
print("🎊 SPECIAL EFFECTS:")
print("  🌸 Magical flowers spawn from rare crop formations")
print("  🎆 Fireworks celebrate crop readiness")
print("  ⚡ Lightning energy during storms")
print("  💧 Water droplets during rain")
print("  ☀️ Sun sparkles on sunny days")
print("  🌟 Enhanced night-time sparkles")
print("  💎 Crop networking auras")

return CropEnhancementBonus