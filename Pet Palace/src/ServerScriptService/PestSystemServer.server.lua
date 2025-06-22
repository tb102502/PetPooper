--[[
    FIXED PestSystem.server.lua - PEST MANAGEMENT SYSTEM
    Place in: ServerScriptService/PestSystem.server.lua
    
    FIXES:
    - Enhanced debugging and error handling
    - Fallback configuration if ItemConfig is missing
    - Better crop detection
    - Adjustable spawn rates for testing
    - More robust pest spawning logic
]]

local function WaitForGameCore(scriptName, maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	print(scriptName .. ": Waiting for GameCore...")

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	if not _G.GameCore then
		error(scriptName .. ": GameCore not found after " .. maxWaitTime .. " seconds!")
	end

	print(scriptName .. ": GameCore found successfully!")
	return _G.GameCore
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Wait for GameCore
local GameCore = WaitForGameCore("PestSystem")

-- Try to get ItemConfig, but use fallback if not available
local ItemConfig = nil
local PEST_CONFIG = nil

local success, result = pcall(function()
	return require(ReplicatedStorage:WaitForChild("ItemConfig", 5))
end)

if success and result then
	ItemConfig = result
	PEST_CONFIG = ItemConfig.PestSystem
	print("PestSystem: Using ItemConfig for pest configuration")
else
	warn("PestSystem: ItemConfig not found, using fallback configuration")
end

-- FALLBACK PEST CONFIGURATION
if not PEST_CONFIG then
	PEST_CONFIG = {
		pestData = {
			aphids = {
				name = "Aphids",
				description = "Small green insects that suck plant juices",
				spreadChance = 0.3,
				spreadRadius = 2,
				icon = "🐛"
			},
			locusts = {
				name = "Locusts",
				description = "Devastating swarms that devour crops",
				spreadChance = 0.15,
				spreadRadius = 3,
				icon = "🦗"
			},
			fungal_blight = {
				name = "Fungal Blight",
				description = "Disease that rots crops from within",
				spreadChance = 0.25,
				spreadRadius = 1.5,
				icon = "🍄"
			}
		},
		spawnRates = {
			aphids = 0.2,     -- 20% chance per check (increased for testing)
			locusts = 0.1,    -- 10% chance per check
			fungal_blight = 0.15 -- 15% chance per check
		},
		damageRates = {
			aphids = 0.05,    -- 5% damage per minute
			locusts = 0.15,   -- 15% damage per minute
			fungal_blight = 0.08 -- 8% damage per minute
		}
	}
	print("PestSystem: Using fallback pest configuration")
end

print("=== ENHANCED PEST MANAGEMENT SYSTEM STARTING ===")

local PestSystem = {}

-- System State
PestSystem.ActivePests = {} -- Track all active pest infestations
PestSystem.PestSpawnTimers = {} -- Track spawn cooldowns per crop
PestSystem.WeatherEffects = {
	current = "normal", -- normal, wet, dry, stormy
	lastChange = os.time()
}
PestSystem.SeasonalMultipliers = {
	spring = {aphids = 1.2, locusts = 0.8, fungal_blight = 1.4},
	summer = {aphids = 1.5, locusts = 1.8, fungal_blight = 0.7},
	fall = {aphids = 1.0, locusts = 1.2, fungal_blight = 1.3},
	winter = {aphids = 0.3, locusts = 0.2, fungal_blight = 0.5}
}

-- Debug settings
PestSystem.DebugMode = true
PestSystem.TestMode = false -- Set to true for rapid pest spawning

-- ========== CORE PEST MANAGEMENT ==========

-- Initialize the pest system
function PestSystem:Initialize()
	print("PestSystem: Initializing enhanced pest management system...")

	-- Initialize system state
	self.ActivePests = {}
	self.PestSpawnTimers = {}

	-- Start main update loops
	self:StartPestSpawnLoop()
	self:StartPestDamageLoop()
	self:StartWeatherSystem()

	-- Setup cleanup for disconnected players
	self:SetupPlayerCleanup()

	print("PestSystem: Enhanced pest management system fully initialized!")
	print("Debug Mode: " .. tostring(self.DebugMode))
	print("Test Mode: " .. tostring(self.TestMode))
end

-- ========== ENHANCED CROP DETECTION ==========

-- Get all active crops in the game (ENHANCED VERSION)
function PestSystem:GetAllActiveCrops()
	local crops = {}
	local debugInfo = {
		totalPlots = 0,
		activeCrops = 0,
		playersChecked = 0
	}

	if self.DebugMode then
		print("PestSystem: Starting enhanced crop scan...")
	end

	-- Method 1: Check Areas > Starter Meadow > Farm structure
	local areas = workspace:FindFirstChild("Areas")
	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			if farmArea then
				if self.DebugMode then
					print("PestSystem: Found farm area structure")
				end

				for _, playerFarm in pairs(farmArea:GetChildren()) do
					if playerFarm:IsA("Folder") and playerFarm.Name:find("_Farm") then
						local playerName = playerFarm.Name:gsub("_Farm", "")
						local player = Players:FindFirstChild(playerName)

						if player then
							debugInfo.playersChecked = debugInfo.playersChecked + 1
							if self.DebugMode then
								print("PestSystem: Checking " .. playerName .. "'s farm")
							end

							for _, plot in pairs(playerFarm:GetChildren()) do
								if plot:IsA("Model") and plot.Name:find("FarmPlot") then
									debugInfo.totalPlots = debugInfo.totalPlots + 1

									local plantingSpots = plot:FindFirstChild("PlantingSpots")
									if plantingSpots then
										for _, spot in pairs(plantingSpots:GetChildren()) do
											if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
												local isEmpty = spot:GetAttribute("IsEmpty")
												if not isEmpty then
													local cropModel = spot:FindFirstChild("CropModel")
													if cropModel and cropModel:FindFirstChild("Crop") then
														table.insert(crops, {
															cropModel = cropModel,
															plotModel = spot,
															player = player,
															plantType = spot:GetAttribute("PlantType") or "unknown"
														})
														debugInfo.activeCrops = debugInfo.activeCrops + 1
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			else
				if self.DebugMode then
					print("PestSystem: Farm area not found in Starter Meadow")
				end
			end
		else
			if self.DebugMode then
				print("PestSystem: Starter Meadow not found in Areas")
			end
		end
	else
		if self.DebugMode then
			print("PestSystem: Areas folder not found")
		end
	end

	-- Method 2: Direct workspace search for crops (fallback)
	if #crops == 0 then
		if self.DebugMode then
			print("PestSystem: No crops found via farm structure, trying direct search...")
		end

		for _, obj in pairs(workspace:GetDescendants()) do
			if obj.Name == "Crop" and obj:IsA("BasePart") and obj.Parent then
				local cropModel = obj.Parent
				if cropModel.Name == "CropModel" then
					-- Try to find associated player and plot
					local player = self:FindCropOwner(cropModel)
					if player then
						table.insert(crops, {
							cropModel = cropModel,
							plotModel = cropModel.Parent, -- May not be accurate
							player = player,
							plantType = "unknown"
						})
						debugInfo.activeCrops = debugInfo.activeCrops + 1
					end
				end
			end
		end
	end

	if self.DebugMode then
		print("PestSystem: Crop scan complete!")
		print("  Players checked: " .. debugInfo.playersChecked)
		print("  Total plots: " .. debugInfo.totalPlots)
		print("  Active crops found: " .. debugInfo.activeCrops)
	end

	return crops
end

-- Try to find the owner of a crop (fallback method)
function PestSystem:FindCropOwner(cropModel)
	-- Navigate up the parent hierarchy to find player indicators
	local current = cropModel
	for i = 1, 10 do -- Limit depth
		if not current or not current.Parent then break end

		-- Look for player name in parent names
		local parentName = current.Parent.Name
		if parentName:find("_Farm") then
			local playerName = parentName:gsub("_Farm", "")
			return Players:FindFirstChild(playerName)
		end

		current = current.Parent
	end

	-- Fallback: assign to first player for testing
	local players = Players:GetPlayers()
	return players[1]
end

-- ========== ENHANCED PEST SPAWNING SYSTEM ==========

-- Main pest spawning loop (ENHANCED)
function PestSystem:StartPestSpawnLoop()
	spawn(function()
		print("PestSystem: Starting enhanced pest spawn loop...")

		while true do
			-- Check interval based on mode
			local checkInterval = self.TestMode and 10 or 30 -- 10 seconds in test mode, 30 in normal
			wait(checkInterval)

			local allCrops = self:GetAllActiveCrops()

			if self.DebugMode then
				print("PestSystem: Checking " .. #allCrops .. " crops for pest spawning")
			end

			if #allCrops == 0 then
				if self.DebugMode then
					print("PestSystem: No crops found for pest spawning")
				end
				continue
			end

			local pestsSpawned = 0
			for _, cropData in ipairs(allCrops) do
				if self:CheckPestSpawning(cropData) then
					pestsSpawned = pestsSpawned + 1
				end
			end

			if self.DebugMode and pestsSpawned > 0 then
				print("PestSystem: Spawned " .. pestsSpawned .. " pests this round")
			end
		end
	end)
end

-- Check if a specific crop should spawn pests (ENHANCED)
function PestSystem:CheckPestSpawning(cropData)
	local crop = cropData.cropModel
	local player = cropData.player
	local plotModel = cropData.plotModel

	if not crop or not crop.Parent or not player then
		return false
	end

	-- Get plant type with fallback
	local plantType = cropData.plantType
	if plantType == "unknown" or not plantType then
		plantType = plotModel and plotModel:GetAttribute("PlantType") or "wheat" -- Default fallback
	end

	local pestsSpawned = false

	-- Check each pest type for spawning
	for pestType, pestData in pairs(PEST_CONFIG.pestData) do
		if self:ShouldSpawnPest(pestType, plantType, cropData) then
			self:SpawnPest(pestType, cropData)
			pestsSpawned = true
		end
	end

	return pestsSpawned
end

-- Determine if a pest should spawn on a crop (ENHANCED)
function PestSystem:ShouldSpawnPest(pestType, plantType, cropData)
	local crop = cropData.cropModel
	local player = cropData.player
	local plotModel = cropData.plotModel

	-- Check if pest already exists on this crop
	if self:HasPestType(crop, pestType) then
		return false
	end

	-- Get base spawn rate
	local baseSpawnRate = PEST_CONFIG.spawnRates[pestType] or 0.05

	-- In test mode, increase spawn rates dramatically
	if self.TestMode then
		baseSpawnRate = baseSpawnRate * 10 -- 10x spawn rate for testing
	end

	-- Get crop vulnerability (with fallback)
	local vulnerability = self:GetCropVulnerability(plantType, pestType)
	local adjustedRate = baseSpawnRate * vulnerability

	-- Apply seasonal multipliers
	local season = self:GetCurrentSeason()
	local seasonalMultiplier = self.SeasonalMultipliers[season][pestType] or 1.0
	adjustedRate = adjustedRate * seasonalMultiplier

	-- Apply weather effects
	local weatherMultiplier = self:GetWeatherMultiplier(pestType)
	adjustedRate = adjustedRate * weatherMultiplier

	-- Check for pig manure protection
	if self:HasPigManureProtection(player, plotModel) then
		adjustedRate = adjustedRate * 0.3 -- 70% reduction with manure
		if self.DebugMode then
			print("PestSystem: Pig manure protection reducing pest spawn rate")
		end
	end

	-- Convert hourly rate to check interval rate
	local checkInterval = self.TestMode and 10 or 30
	local spawnChance = adjustedRate * (checkInterval / 3600)

	-- Roll for spawn
	local roll = math.random()
	local shouldSpawn = roll < spawnChance

	if self.DebugMode and shouldSpawn then
		print("PestSystem: " .. pestType .. " spawn check passed (chance: " .. math.floor(spawnChance * 100) .. "%, roll: " .. math.floor(roll * 100) .. "%)")
	end

	return shouldSpawn
end

-- Get crop vulnerability to pest type (with fallbacks)
function PestSystem:GetCropVulnerability(plantType, pestType)
	-- Try to get from ItemConfig first
	if ItemConfig and ItemConfig.GetSeedData then
		local seedData = ItemConfig.GetSeedData(plantType .. "_seeds")
		if seedData and seedData.pestVulnerability and seedData.pestVulnerability[pestType] then
			return seedData.pestVulnerability[pestType]
		end
	end

	-- Fallback vulnerability data
	local fallbackVulnerabilities = {
		wheat = {aphids = 1.2, locusts = 0.8, fungal_blight = 1.0},
		corn = {aphids = 0.9, locusts = 1.5, fungal_blight = 0.7},
		tomato = {aphids = 1.4, locusts = 0.6, fungal_blight = 1.3},
		carrot = {aphids = 1.0, locusts = 1.0, fungal_blight = 0.8},
		potato = {aphids = 0.8, locusts = 0.9, fungal_blight = 1.4}
	}

	-- Remove "_seeds" suffix if present
	local cleanPlantType = plantType:gsub("_seeds$", "")

	if fallbackVulnerabilities[cleanPlantType] then
		return fallbackVulnerabilities[cleanPlantType][pestType] or 1.0
	end

	-- Ultimate fallback
	return 1.0
end

-- Spawn a pest on a crop (ENHANCED)
function PestSystem:SpawnPest(pestType, cropData)
	local crop = cropData.cropModel
	local player = cropData.player
	local plotModel = cropData.plotModel

	if self.DebugMode then
		print("PestSystem: Spawning " .. pestType .. " on " .. player.Name .. "'s " .. (cropData.plantType or "unknown") .. " crop")
	end

	-- Create pest instance
	local pestInstance = {
		pestType = pestType,
		cropModel = crop,
		plotModel = plotModel,
		player = player,
		spawnTime = os.time(),
		damageDealt = 0,
		spreadAttempts = 0,
		pestId = self:GeneratePestId()
	}

	-- Store in active pests
	if not self.ActivePests[player.UserId] then
		self.ActivePests[player.UserId] = {}
	end
	self.ActivePests[player.UserId][pestInstance.pestId] = pestInstance

	-- Create visual pest representation
	self:CreatePestVisual(pestInstance)

	-- Notify player
	if GameCore and GameCore.SendNotification then
		local pestData = PEST_CONFIG.pestData[pestType]
		GameCore:SendNotification(player, "🐛 Pest Infestation!", 
			pestData.name .. " detected on your crops! " .. pestData.description, "warning")
	end

	-- Check for pest spread
	spawn(function()
		wait(math.random(30, 90)) -- Random delay before first spread attempt
		self:AttemptPestSpread(pestInstance)
	end)

	return true
end

-- ========== PEST DAMAGE SYSTEM (SAME AS BEFORE) ==========

-- Main pest damage loop
function PestSystem:StartPestDamageLoop()
	spawn(function()
		print("PestSystem: Starting pest damage loop...")

		while true do
			wait(60) -- Check damage every minute

			local totalPests = 0
			local totalDamage = 0

			for userId, playerPests in pairs(self.ActivePests) do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					for pestId, pestInstance in pairs(playerPests) do
						self:ApplyPestDamage(pestInstance)
						totalPests = totalPests + 1
						totalDamage = totalDamage + pestInstance.damageDealt
					end
				end
			end

			if self.DebugMode and totalPests > 0 then
				print("PestSystem: Processed damage for " .. totalPests .. " pests (total damage dealt: " .. math.floor(totalDamage * 100) .. "%)")
			end
		end
	end)
end

-- Apply damage from a pest to its crop
function PestSystem:ApplyPestDamage(pestInstance)
	local crop = pestInstance.cropModel
	local plotModel = pestInstance.plotModel
	local player = pestInstance.player

	if not crop or not crop.Parent or not plotModel or not plotModel.Parent then
		-- Crop no longer exists, remove pest
		self:RemovePest(pestInstance)
		return
	end

	local pestType = pestInstance.pestType
	local damageRate = PEST_CONFIG.damageRates[pestType] or 0.1

	-- Apply damage to crop (stored as attribute)
	local currentDamage = plotModel:GetAttribute("PestDamage") or 0
	local newDamage = math.min(1.0, currentDamage + (damageRate / 60)) -- Per minute damage
	plotModel:SetAttribute("PestDamage", newDamage)

	-- Track total damage dealt by this pest
	pestInstance.damageDealt = pestInstance.damageDealt + (damageRate / 60)

	-- Update crop visual based on damage
	self:UpdateCropDamageVisual(crop, newDamage)

	-- If crop is severely damaged, may wither
	if newDamage >= 0.8 then
		-- 10% chance per minute to kill the crop if 80%+ damaged
		if math.random() < 0.1 then
			self:WitherCrop(plotModel, player)
			return
		end
	end

	if self.DebugMode then
		print("PestSystem: " .. pestType .. " dealt damage to " .. player.Name .. "'s crop (total damage: " .. math.floor(newDamage * 100) .. "%)")
	end
end

-- ========== PEST SPREAD SYSTEM (ENHANCED) ==========

-- Attempt to spread pest to nearby crops
function PestSystem:AttemptPestSpread(pestInstance)
	if not pestInstance or not pestInstance.cropModel or not pestInstance.cropModel.Parent then
		return
	end

	local pestType = pestInstance.pestType
	local pestData = PEST_CONFIG.pestData[pestType]
	local spreadChance = pestData.spreadChance or 0.1

	-- Limit spread attempts
	pestInstance.spreadAttempts = pestInstance.spreadAttempts + 1
	if pestInstance.spreadAttempts > 3 then
		return -- Max 3 spread attempts per pest
	end

	-- Find nearby crops
	local cropPosition = pestInstance.cropModel:FindFirstChild("Crop")
	if not cropPosition then return end

	local nearbyCrops = self:GetNearbyCrops(cropPosition.Position, pestData.spreadRadius or 1)

	if self.DebugMode then
		print("PestSystem: " .. pestType .. " attempting to spread (found " .. #nearbyCrops .. " nearby crops)")
	end

	for _, nearbyData in ipairs(nearbyCrops) do
		if math.random() < spreadChance then
			-- Check if target crop is suitable for this pest
			local targetPlantType = nearbyData.plantType or "wheat"
			local vulnerability = self:GetCropVulnerability(targetPlantType, pestType)

			if vulnerability > 0 and not self:HasPestType(nearbyData.cropModel, pestType) then
				if self.DebugMode then
					print("PestSystem: " .. pestType .. " spread to nearby " .. targetPlantType .. " crop")
				end
				self:SpawnPest(pestType, nearbyData)
				break -- Only spread to one crop per attempt
			end
		end
	end

	-- Schedule next spread attempt
	spawn(function()
		wait(math.random(60, 180)) -- 1-3 minutes
		self:AttemptPestSpread(pestInstance)
	end)
end

-- Get nearby crops within a radius (ENHANCED)
function PestSystem:GetNearbyCrops(position, radius)
	local nearbyCrops = {}
	local allCrops = self:GetAllActiveCrops()

	for _, cropData in ipairs(allCrops) do
		if cropData.cropModel and cropData.cropModel:FindFirstChild("Crop") then
			local distance = (cropData.cropModel.Crop.Position - position).Magnitude
			if distance <= radius * 20 and distance > 0 then -- Convert plot distance to studs, exclude self
				table.insert(nearbyCrops, cropData)
			end
		end
	end

	return nearbyCrops
end

-- ========== CHICKEN INTEGRATION (ENHANCED) ==========

-- Check if chickens can eliminate pests in an area
function PestSystem:CheckChickenPestControl(chickenData)
	if not chickenData or not chickenData.position then
		return
	end

	local huntRange = chickenData.huntRange or 30 -- Increased range
	local huntEfficiency = chickenData.huntEfficiency or 0.8
	local pestTargets = chickenData.pestTargets or {"aphids", "locusts", "fungal_blight"}

	-- Find pests within hunt range
	local pestsInRange = self:GetPestsInRange(chickenData.position, huntRange, pestTargets)

	if self.DebugMode and #pestsInRange > 0 then
		print("PestSystem: Chicken found " .. #pestsInRange .. " pests in range")
	end

	for _, pestInstance in ipairs(pestsInRange) do
		-- Check if chicken successfully eliminates pest
		if math.random() < huntEfficiency then
			if self.DebugMode then
				print("PestSystem: Chicken eliminated " .. pestInstance.pestType .. " pest")
			end

			self:RemovePest(pestInstance)

			-- Create elimination effect
			self:CreatePestEliminationEffect(pestInstance.cropModel.Crop.Position)

			-- Notify player
			if GameCore and GameCore.SendNotification then
				GameCore:SendNotification(pestInstance.player, "🐔 Pest Eliminated!", 
					"Your chicken eliminated a " .. pestInstance.pestType .. " pest!", "success")
			end
		end
	end
end

-- Get pests within range of a position that match target types (ENHANCED)
function PestSystem:GetPestsInRange(position, range, targetTypes)
	local pestsInRange = {}

	for userId, playerPests in pairs(self.ActivePests) do
		for pestId, pestInstance in pairs(playerPests) do
			if pestInstance.cropModel and pestInstance.cropModel.Parent and pestInstance.cropModel:FindFirstChild("Crop") then
				-- Check if pest type is targetable
				for _, targetType in ipairs(targetTypes) do
					if pestInstance.pestType == targetType then
						local distance = (pestInstance.cropModel.Crop.Position - position).Magnitude
						if distance <= range then -- Range already in studs
							table.insert(pestsInRange, pestInstance)
						end
						break
					end
				end
			end
		end
	end

	return pestsInRange
end

-- ========== WEATHER SYSTEM (SAME AS BEFORE) ==========

-- Start weather system for pest influences
function PestSystem:StartWeatherSystem()
	spawn(function()
		print("PestSystem: Starting weather system...")

		while true do
			-- Change weather every 10-20 minutes
			wait(math.random(600, 1200))
			self:ChangeWeather()
		end
	end)
end

-- Change weather conditions
function PestSystem:ChangeWeather()
	local weatherTypes = {"normal", "wet", "dry", "stormy"}
	local weights = {50, 25, 20, 5} -- Normal weather is most common

	local newWeather = self:WeightedRandomChoice(weatherTypes, weights)

	if newWeather ~= self.WeatherEffects.current then
		self.WeatherEffects.current = newWeather
		self.WeatherEffects.lastChange = os.time()

		if self.DebugMode then
			print("PestSystem: Weather changed to " .. newWeather)
		end

		-- Notify all players of weather change
		for _, player in ipairs(Players:GetPlayers()) do
			if GameCore and GameCore.SendNotification then
				local weatherMessages = {
					wet = "🌧️ Rainy weather increases fungal disease risk!",
					dry = "☀️ Dry weather perfect for locust activity!",
					stormy = "⛈️ Stormy weather stresses all crops!",
					normal = "🌤️ Pleasant weather returns to the farm!"
				}
				GameCore:SendNotification(player, "Weather Update", 
					weatherMessages[newWeather], "info")
			end
		end
	end
end

-- ========== VISUAL AND UTILITY FUNCTIONS ==========

-- Check if a crop has a specific pest type
function PestSystem:HasPestType(cropModel, pestType)
	if not cropModel or not cropModel.Parent then return false end

	-- Check for pest visual indicator
	local pestIndicator = cropModel:FindFirstChild("Pest_" .. pestType)
	return pestIndicator ~= nil
end

-- Create visual representation of pest on crop (ENHANCED)
function PestSystem:CreatePestVisual(pestInstance)
	local crop = pestInstance.cropModel
	local pestType = pestInstance.pestType

	if not crop or not crop:FindFirstChild("Crop") then return end

	-- Remove existing pest visual if any
	local existing = crop:FindFirstChild("Pest_" .. pestType)
	if existing then existing:Destroy() end

	-- Create pest indicator
	local pestVisual = Instance.new("Part")
	pestVisual.Name = "Pest_" .. pestType
	pestVisual.Size = Vector3.new(0.5, 0.5, 0.5)
	pestVisual.Material = Enum.Material.Neon
	pestVisual.CanCollide = false
	pestVisual.Anchored = true
	pestVisual.Parent = crop

	-- Position around the crop
	local cropPart = crop:FindFirstChild("Crop")
	if cropPart then
		pestVisual.CFrame = cropPart.CFrame + Vector3.new(
			math.random(-2, 2),
			math.random(1, 3),
			math.random(-2, 2)
		)
	end

	-- Pest-specific appearance
	if pestType == "aphids" then
		pestVisual.Color = Color3.fromRGB(100, 200, 100) -- Green
		pestVisual.Shape = Enum.PartType.Ball
	elseif pestType == "locusts" then
		pestVisual.Color = Color3.fromRGB(200, 150, 100) -- Brown
		pestVisual.Shape = Enum.PartType.Block
		pestVisual.Size = Vector3.new(0.8, 0.3, 0.8)
	elseif pestType == "fungal_blight" then
		pestVisual.Color = Color3.fromRGB(150, 100, 150) -- Purple
		pestVisual.Shape = Enum.PartType.Ball
		pestVisual.Material = Enum.Material.ForceField
	end

	-- Add floating animation
	spawn(function()
		while pestVisual and pestVisual.Parent do
			local originalCFrame = pestVisual.CFrame
			TweenService:Create(pestVisual, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				CFrame = originalCFrame + Vector3.new(0, 1, 0)
			}):Play()
			wait(0.1)
		end
	end)

	if self.DebugMode then
		print("PestSystem: Created visual for " .. pestType .. " pest")
	end
end

-- Update crop visual based on pest damage
function PestSystem:UpdateCropDamageVisual(cropModel, damageLevel)
	local crop = cropModel:FindFirstChild("Crop")
	if not crop then return end

	-- Store original color if not already stored
	if not crop:GetAttribute("OriginalColor") then
		crop:SetAttribute("OriginalColor", tostring(crop.Color))
	end

	-- Get original color
	local originalColorStr = crop:GetAttribute("OriginalColor")
	local r, g, b = originalColorStr:match("([%d%.]+), ([%d%.]+), ([%d%.]+)")
	local originalColor = Color3.fromRGB(tonumber(r) * 255, tonumber(g) * 255, tonumber(b) * 255)

	-- Change crop color based on damage
	local damageColor = Color3.fromRGB(100, 50, 0) -- Brown damage color

	-- Interpolate between healthy and damaged color
	crop.Color = originalColor:Lerp(damageColor, damageLevel)

	-- Add transparency as damage increases
	crop.Transparency = damageLevel * 0.3 -- Max 30% transparency
end

-- Remove a pest from the system
function PestSystem:RemovePest(pestInstance)
	if not pestInstance then return end

	-- Remove visual
	if pestInstance.cropModel then
		local pestVisual = pestInstance.cropModel:FindFirstChild("Pest_" .. pestInstance.pestType)
		if pestVisual then
			pestVisual:Destroy()
		end
	end

	-- Remove from tracking
	if pestInstance.player and self.ActivePests[pestInstance.player.UserId] then
		self.ActivePests[pestInstance.player.UserId][pestInstance.pestId] = nil
	end

	if self.DebugMode then
		print("PestSystem: Removed " .. pestInstance.pestType .. " pest")
	end
end

-- Create visual effect when pest is eliminated
function PestSystem:CreatePestEliminationEffect(position)
	-- Create elimination sparkles
	for i = 1, 5 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.3, 0.3, 0.3)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 255, 0) -- Yellow sparkles
		sparkle.Anchored = true
		sparkle.CanCollide = false
		sparkle.Position = position + Vector3.new(
			math.random(-2, 2),
			math.random(1, 3),
			math.random(-2, 2)
		)
		sparkle.Parent = workspace

		-- Animate sparkle
		TweenService:Create(sparkle, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = sparkle.Position + Vector3.new(0, 5, 0),
			Transparency = 1,
			Size = Vector3.new(0.1, 0.1, 0.1)
		}):Play()

		-- Clean up
		Debris:AddItem(sparkle, 1.5)
	end
end

-- Wither a crop due to severe pest damage
function PestSystem:WitherCrop(plotModel, player)
	if self.DebugMode then
		print("PestSystem: Crop withered due to pest damage for " .. player.Name)
	end

	-- Reset plot to empty
	plotModel:SetAttribute("IsEmpty", true)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PestDamage", 0)

	-- Remove crop model
	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel then
		-- Create withering effect
		local crop = cropModel:FindFirstChild("Crop")
		if crop then
			TweenService:Create(crop, TweenInfo.new(2), {
				Color = Color3.fromRGB(100, 50, 0),
				Size = crop.Size * 0.1,
				Transparency = 1
			}):Play()
		end

		-- Destroy after effect
		Debris:AddItem(cropModel, 2)
	end

	-- Remove any pests on this crop
	if self.ActivePests[player.UserId] then
		for pestId, pestInstance in pairs(self.ActivePests[player.UserId]) do
			if pestInstance.plotModel == plotModel then
				self:RemovePest(pestInstance)
			end
		end
	end

	-- Notify player
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, "💀 Crop Withered!", 
			"Severe pest damage killed your crop! Plant new seeds and consider pest protection.", "error")
	end
end

-- ========== UTILITY FUNCTIONS ==========

function PestSystem:GeneratePestId()
	return "pest_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function PestSystem:GetCurrentSeason()
	-- Simple season calculation based on time
	local month = tonumber(os.date("%m"))
	if month >= 3 and month <= 5 then return "spring"
	elseif month >= 6 and month <= 8 then return "summer"
	elseif month >= 9 and month <= 11 then return "fall"
	else return "winter" end
end

function PestSystem:GetWeatherMultiplier(pestType)
	local weather = self.WeatherEffects.current
	local multipliers = {
		normal = 1.0,
		wet = {aphids = 0.8, locusts = 0.6, fungal_blight = 1.5},
		dry = {aphids = 1.2, locusts = 1.8, fungal_blight = 0.5},
		stormy = {aphids = 1.5, locusts = 0.3, fungal_blight = 1.2}
	}

	if type(multipliers[weather]) == "table" then
		return multipliers[weather][pestType] or 1.0
	else
		return multipliers[weather] or 1.0
	end
end

function PestSystem:HasPigManureProtection(player, plotModel)
	-- Check if player has applied pig manure to this plot
	if not plotModel then return false end
	return plotModel:GetAttribute("PigManureProtection") == true
end

function PestSystem:WeightedRandomChoice(choices, weights)
	local totalWeight = 0
	for _, weight in ipairs(weights) do
		totalWeight = totalWeight + weight
	end

	local random = math.random() * totalWeight
	local currentWeight = 0

	for i, choice in ipairs(choices) do
		currentWeight = currentWeight + weights[i]
		if random <= currentWeight then
			return choice
		end
	end

	return choices[1] -- Fallback
end

-- Setup player cleanup
function PestSystem:SetupPlayerCleanup()
	Players.PlayerRemoving:Connect(function(player)
		-- Clean up player's pests when they leave
		if self.ActivePests[player.UserId] then
			self.ActivePests[player.UserId] = nil
		end
		if self.DebugMode then
			print("PestSystem: Cleaned up pests for " .. player.Name)
		end
	end)
end

-- ========== ENHANCED ADMIN COMMANDS ==========

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/spawnpest" then
				local pestType = args[2] or "aphids"
				local allCrops = PestSystem:GetAllActiveCrops()
				if #allCrops > 0 then
					local randomCrop = allCrops[math.random(1, #allCrops)]
					PestSystem:SpawnPest(pestType, randomCrop)
					print("Admin: Spawned " .. pestType .. " on random crop")
				else
					print("Admin: No crops found to spawn pests on")
				end

			elseif command == "/forcespawnpest" then
				-- Force spawn on all crops for testing
				local pestType = args[2] or "aphids"
				local allCrops = PestSystem:GetAllActiveCrops()
				local spawned = 0
				for _, cropData in ipairs(allCrops) do
					PestSystem:SpawnPest(pestType, cropData)
					spawned = spawned + 1
				end
				print("Admin: Force spawned " .. pestType .. " on " .. spawned .. " crops")

			elseif command == "/clearpests" then
				local totalCleared = 0
				for userId, playerPests in pairs(PestSystem.ActivePests) do
					for pestId, pestInstance in pairs(playerPests) do
						PestSystem:RemovePest(pestInstance)
						totalCleared = totalCleared + 1
					end
				end
				PestSystem.ActivePests = {}
				print("Admin: Cleared " .. totalCleared .. " pests")

			elseif command == "/weather" then
				local weatherType = args[2] or "normal"
				PestSystem.WeatherEffects.current = weatherType
				print("Admin: Set weather to " .. weatherType)

			elseif command == "/testmode" then
				PestSystem.TestMode = not PestSystem.TestMode
				print("Admin: Test mode " .. (PestSystem.TestMode and "enabled" or "disabled"))

			elseif command == "/debugmode" then
				PestSystem.DebugMode = not PestSystem.DebugMode
				print("Admin: Debug mode " .. (PestSystem.DebugMode and "enabled" or "disabled"))

			elseif command == "/cropcount" then
				local allCrops = PestSystem:GetAllActiveCrops()
				print("Admin: Found " .. #allCrops .. " active crops")
				for i, cropData in ipairs(allCrops) do
					print("  " .. i .. ": " .. cropData.player.Name .. "'s " .. (cropData.plantType or "unknown"))
				end

			elseif command == "/peststats" then
				local totalPests = 0
				print("=== PEST SYSTEM STATISTICS ===")
				for userId, playerPests in pairs(PestSystem.ActivePests) do
					local count = 0
					local pestBreakdown = {}
					for pestId, pestInstance in pairs(playerPests) do
						count = count + 1
						pestBreakdown[pestInstance.pestType] = (pestBreakdown[pestInstance.pestType] or 0) + 1
					end
					totalPests = totalPests + count
					local p = Players:GetPlayerByUserId(userId)
					if p then
						print(p.Name .. ": " .. count .. " pests")
						for pestType, pestCount in pairs(pestBreakdown) do
							print("  " .. pestType .. ": " .. pestCount)
						end
					end
				end
				print("Total active pests: " .. totalPests)
				print("Current weather: " .. PestSystem.WeatherEffects.current)
				print("Debug mode: " .. tostring(PestSystem.DebugMode))
				print("Test mode: " .. tostring(PestSystem.TestMode))
				print("===============================")

			elseif command == "/checkcrops" then
				print("=== CROP SCAN DEBUG ===")
				PestSystem:GetAllActiveCrops() -- This will print debug info
				print("=======================")
			end
		end
	end)
end)

-- Initialize the system and make it globally available
PestSystem:Initialize()
_G.PestSystem = PestSystem

print("=== ENHANCED PEST MANAGEMENT SYSTEM ACTIVE ===")
print("Features:")
print("✅ Enhanced crop detection with fallbacks")
print("✅ Robust pest spawning with debugging")
print("✅ Fallback configuration if ItemConfig missing")
print("✅ Test mode for rapid pest spawning")
print("✅ Comprehensive debugging output")
print("✅ Better error handling")
print("")
print("Pest Types:")
print("  🐛 Aphids - Common, slow damage, spreads easily")
print("  🦗 Locusts - Devastating swarms, weather dependent")
print("  🍄 Fungal Blight - Disease that spreads in wet conditions")
print("")
print("Enhanced Admin Commands:")
print("  /spawnpest [type] - Spawn pest on random crop")
print("  /forcespawnpest [type] - Spawn pest on ALL crops")
print("  /clearpests - Remove all pests")
print("  /weather [type] - Change weather")
print("  /testmode - Toggle rapid spawning mode")
print("  /debugmode - Toggle debug output")
print("  /cropcount - Show all detected crops")
print("  /peststats - Show detailed pest statistics")
print("  /checkcrops - Debug crop detection")

return PestSystem