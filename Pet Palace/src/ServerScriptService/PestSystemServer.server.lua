--[[
    PestSystem.server.lua - PEST MANAGEMENT SYSTEM
    Place in: ServerScriptService/PestSystem.server.lua
    
    FEATURES:
    - Multiple pest types (Aphids, Locusts, Fungal Blight)
    - Dynamic pest spawning based on crop vulnerability
    - Pest damage over time to crops
    - Weather and seasonal influences
    - Integration with chicken defense system
    - Pig manure as pest deterrent
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

-- Wait for GameCore and ItemConfig
local GameCore = WaitForGameCore("PestSystem")
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

print("=== PEST MANAGEMENT SYSTEM STARTING ===")

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

-- Pest Configuration (from ItemConfig)
local PEST_CONFIG = ItemConfig.PestSystem

-- ========== CORE PEST MANAGEMENT ==========

-- Initialize the pest system
function PestSystem:Initialize()
	print("PestSystem: Initializing pest management system...")

	-- Initialize system state
	self.ActivePests = {}
	self.PestSpawnTimers = {}

	-- Start main update loops
	self:StartPestSpawnLoop()
	self:StartPestDamageLoop()
	self:StartWeatherSystem()

	-- Setup cleanup for disconnected players
	self:SetupPlayerCleanup()

	print("PestSystem: Pest management system fully initialized!")
end

-- ========== PEST SPAWNING SYSTEM ==========

-- Main pest spawning loop
function PestSystem:StartPestSpawnLoop()
	spawn(function()
		print("PestSystem: Starting pest spawn loop...")

		while true do
			-- Check for pest spawning every 30 seconds
			wait(30)

			local allCrops = self:GetAllActiveCrops()
			print("PestSystem: Checking " .. #allCrops .. " crops for pest spawning")

			for _, cropData in ipairs(allCrops) do
				self:CheckPestSpawning(cropData)
			end
		end
	end)
end

-- Check if a specific crop should spawn pests
function PestSystem:CheckPestSpawning(cropData)
	local crop = cropData.cropModel
	local player = cropData.player
	local plotModel = cropData.plotModel

	if not crop or not crop.Parent or not player then
		return
	end

	-- Get crop type and pest vulnerabilities
	local plantType = plotModel:GetAttribute("PlantType") or ""
	local seedData = ItemConfig.GetSeedData(plantType .. "_seeds")
	if not seedData or not seedData.pestVulnerability then
		return
	end

	-- Check each pest type for spawning
	for pestType, basePestData in pairs(PEST_CONFIG.pestData) do
		if self:ShouldSpawnPest(pestType, seedData, cropData) then
			self:SpawnPest(pestType, cropData)
		end
	end
end

-- Determine if a pest should spawn on a crop
function PestSystem:ShouldSpawnPest(pestType, seedData, cropData)
	local crop = cropData.cropModel
	local player = cropData.player
	local plotModel = cropData.plotModel

	-- Check if pest already exists on this crop
	if self:HasPestType(crop, pestType) then
		return false
	end

	-- Get base spawn rate
	local baseSpawnRate = PEST_CONFIG.spawnRates[pestType] or 0.05

	-- Apply crop vulnerability
	local vulnerability = seedData.pestVulnerability[pestType] or 1.0
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
	end

	-- Convert hourly rate to 30-second check rate
	local spawnChance = adjustedRate * (30 / 3600) -- 30 seconds / 3600 seconds per hour

	-- Roll for spawn
	local roll = math.random()
	return roll < spawnChance
end

-- Spawn a pest on a crop
function PestSystem:SpawnPest(pestType, cropData)
	local crop = cropData.cropModel
	local player = cropData.player
	local plotModel = cropData.plotModel

	print("PestSystem: Spawning " .. pestType .. " on " .. player.Name .. "'s crop")

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
end

-- ========== PEST DAMAGE SYSTEM ==========

-- Main pest damage loop
function PestSystem:StartPestDamageLoop()
	spawn(function()
		print("PestSystem: Starting pest damage loop...")

		while true do
			wait(60) -- Check damage every minute

			for userId, playerPests in pairs(self.ActivePests) do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					for pestId, pestInstance in pairs(playerPests) do
						self:ApplyPestDamage(pestInstance)
					end
				end
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

	print("PestSystem: " .. pestType .. " dealt damage to " .. player.Name .. "'s crop (total damage: " .. math.floor(newDamage * 100) .. "%)")
end

-- ========== PEST SPREAD SYSTEM ==========

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
	local nearbyCrops = self:GetNearbyCrops(pestInstance.cropModel.Position, pestData.spreadRadius or 1)

	for _, nearbyData in ipairs(nearbyCrops) do
		if math.random() < spreadChance then
			-- Check if target crop is suitable for this pest
			local targetPlantType = nearbyData.plotModel:GetAttribute("PlantType") or ""
			local targetSeedData = ItemConfig.GetSeedData(targetPlantType .. "_seeds")

			if targetSeedData and targetSeedData.pestVulnerability and targetSeedData.pestVulnerability[pestType] then
				if not self:HasPestType(nearbyData.cropModel, pestType) then
					print("PestSystem: " .. pestType .. " spread to nearby crop")
					self:SpawnPest(pestType, nearbyData)
					break -- Only spread to one crop per attempt
				end
			end
		end
	end

	-- Schedule next spread attempt
	spawn(function()
		wait(math.random(60, 180)) -- 1-3 minutes
		self:AttemptPestSpread(pestInstance)
	end)
end

-- ========== CHICKEN INTEGRATION ==========

-- Check if chickens can eliminate pests in an area
function PestSystem:CheckChickenPestControl(chickenData)
	if not chickenData or not chickenData.position then
		return
	end

	local huntRange = chickenData.huntRange or 3
	local huntSpeed = chickenData.huntSpeed or 2
	local huntEfficiency = chickenData.huntEfficiency or 0.8
	local pestTargets = chickenData.pestTargets or {}

	-- Find pests within hunt range
	local pestsInRange = self:GetPestsInRange(chickenData.position, huntRange, pestTargets)

	for _, pestInstance in ipairs(pestsInRange) do
		-- Check if chicken successfully eliminates pest
		if math.random() < huntEfficiency then
			print("PestSystem: Chicken eliminated " .. pestInstance.pestType .. " pest")
			self:RemovePest(pestInstance)

			-- Create elimination effect
			self:CreatePestEliminationEffect(pestInstance.cropModel.Position)

			-- Notify player
			if GameCore and GameCore.SendNotification then
				GameCore:SendNotification(pestInstance.player, "🐔 Pest Eliminated!", 
					"Your chicken eliminated a " .. pestInstance.pestType .. " pest!", "success")
			end
		end
	end
end

-- ========== WEATHER SYSTEM ==========

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

		print("PestSystem: Weather changed to " .. newWeather)

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

-- ========== UTILITY FUNCTIONS ==========

-- Get all active crops in the game
function PestSystem:GetAllActiveCrops()
	local crops = {}

	-- Check Areas > Starter Meadow > Farm for player farms
	local areas = workspace:FindFirstChild("Areas")
	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			if farmArea then
				for _, playerFarm in pairs(farmArea:GetChildren()) do
					if playerFarm:IsA("Folder") and playerFarm.Name:find("_Farm") then
						local playerName = playerFarm.Name:gsub("_Farm", "")
						local player = Players:FindFirstChild(playerName)

						if player then
							for _, plot in pairs(playerFarm:GetChildren()) do
								if plot:IsA("Model") and plot.Name:find("FarmPlot") then
									local plantingSpots = plot:FindFirstChild("PlantingSpots")
									if plantingSpots then
										for _, spot in pairs(plantingSpots:GetChildren()) do
											local isEmpty = spot:GetAttribute("IsEmpty")
											if not isEmpty then
												local cropModel = spot:FindFirstChild("CropModel")
												if cropModel then
													table.insert(crops, {
														cropModel = cropModel,
														plotModel = spot,
														player = player
													})
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
		end
	end

	return crops
end

-- Get nearby crops within a radius
function PestSystem:GetNearbyCrops(position, radius)
	local nearbyCrops = {}
	local allCrops = self:GetAllActiveCrops()

	for _, cropData in ipairs(allCrops) do
		if cropData.cropModel and cropData.cropModel:FindFirstChild("Crop") then
			local distance = (cropData.cropModel.Crop.Position - position).Magnitude
			if distance <= radius * 20 then -- Convert plot distance to studs
				table.insert(nearbyCrops, cropData)
			end
		end
	end

	return nearbyCrops
end

-- Check if a crop has a specific pest type
function PestSystem:HasPestType(cropModel, pestType)
	if not cropModel or not cropModel.Parent then return false end

	-- Check for pest visual indicator
	local pestIndicator = cropModel:FindFirstChild("Pest_" .. pestType)
	return pestIndicator ~= nil
end

-- Get pests within range of a position that match target types
function PestSystem:GetPestsInRange(position, range, targetTypes)
	local pestsInRange = {}

	for userId, playerPests in pairs(self.ActivePests) do
		for pestId, pestInstance in pairs(playerPests) do
			if pestInstance.cropModel and pestInstance.cropModel.Parent then
				-- Check if pest type is targetable
				for _, targetType in ipairs(targetTypes) do
					if pestInstance.pestType == targetType then
						local distance = (pestInstance.cropModel.Crop.Position - position).Magnitude
						if distance <= range * 20 then -- Convert to studs
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

-- Create visual representation of pest on crop
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
	local pestData = PEST_CONFIG.pestData[pestType]
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
end

-- Update crop visual based on pest damage
function PestSystem:UpdateCropDamageVisual(cropModel, damageLevel)
	local crop = cropModel:FindFirstChild("Crop")
	if not crop then return end

	-- Change crop color based on damage
	local healthColor = crop.Color
	local damageColor = Color3.fromRGB(100, 50, 0) -- Brown damage color

	-- Interpolate between healthy and damaged color
	crop.Color = healthColor:Lerp(damageColor, damageLevel)

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

	print("PestSystem: Removed " .. pestInstance.pestType .. " pest")
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
	print("PestSystem: Crop withered due to pest damage for " .. player.Name)

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

-- Helper functions
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
	-- This would be set by the pig feeding system when manure is used
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
		print("PestSystem: Cleaned up pests for " .. player.Name)
	end)
end

-- Admin commands for testing
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
				end

			elseif command == "/clearpests" then
				PestSystem.ActivePests = {}
				print("Admin: Cleared all pests")

			elseif command == "/weather" then
				local weatherType = args[2] or "normal"
				PestSystem.WeatherEffects.current = weatherType
				print("Admin: Set weather to " .. weatherType)

			elseif command == "/peststats" then
				local totalPests = 0
				for userId, playerPests in pairs(PestSystem.ActivePests) do
					local count = 0
					for _ in pairs(playerPests) do count = count + 1 end
					totalPests = totalPests + count
					local p = Players:GetPlayerByUserId(userId)
					if p then
						print(p.Name .. ": " .. count .. " pests")
					end
				end
				print("Total active pests: " .. totalPests)
				print("Current weather: " .. PestSystem.WeatherEffects.current)
			end
		end
	end)
end)

-- Initialize the system and make it globally available
PestSystem:Initialize()
_G.PestSystem = PestSystem

print("=== PEST MANAGEMENT SYSTEM ACTIVE ===")
print("Features:")
print("✅ Dynamic pest spawning based on crop vulnerability")
print("✅ Weather and seasonal influences")
print("✅ Pest damage over time")
print("✅ Pest spread mechanics")
print("✅ Integration with chicken defense system")
print("✅ Pig manure protection effects")
print("")
print("Pest Types:")
print("  🐛 Aphids - Common, slow damage, spreads easily")
print("  🦗 Locusts - Devastating swarms, weather dependent")
print("  🍄 Fungal Blight - Disease that spreads in wet conditions")
print("")
print("Admin Commands:")
print("  /spawnpest [type] - Spawn pest on random crop")
print("  /clearpests - Remove all pests")
print("  /weather [type] - Change weather")
print("  /peststats - Show pest statistics")

return PestSystem