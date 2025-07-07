--[[
    CropCreation.lua - Modular Crop Creation System
    Place in: ServerScriptService/Modules/CropCreation.lua
    
    RESPONSIBILITIES:
    ✅ Crop planting logic and validation
    ✅ Growth timer management
    ✅ Harvest logic and rewards
    ✅ Rarity system integration
    ✅ Mutation system integration
    ✅ Crop state management
]]

local CropCreation = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Dependencies
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Module references (will be injected)
local GameCore = nil
local CropVisual = nil
local MutationSystem = nil

-- Internal state
CropCreation.GrowthTimers = {}
CropCreation.PlantingCooldowns = {}
CropCreation.RemoteEventCooldowns = {}

-- ========== INITIALIZATION ==========

function CropCreation:Initialize(gameCoreRef, cropVisualRef, mutationSystemRef)
	print("CropCreation: Initializing crop creation system...")

	-- Store module references
	GameCore = gameCoreRef
	CropVisual = cropVisualRef
	MutationSystem = mutationSystemRef

	-- Initialize internal systems
	self:InitializeCooldownSystems()

	print("CropCreation: ✅ Crop creation system initialized successfully")
	return true
end

function CropCreation:InitializeCooldownSystems()
	self.PlantingCooldowns = {}
	self.RemoteEventCooldowns = {}
	self.SpamAttempts = {} -- ADD this line

	-- Enhanced cleanup every 60 seconds
	spawn(function()
		while true do
			wait(60)
			self:CleanupOldCooldowns()
		end
	end)
end

-- ADD this debug method to CropCreation:

function CropCreation:DebugCooldowns(player)
	local userId = player.UserId
	local currentTime = tick()

	print("=== COOLDOWN DEBUG FOR " .. player.Name .. " ===")

	-- Remote event cooldowns
	local remoteKey = userId .. "_PlantSeed"
	local lastRemoteTime = self.RemoteEventCooldowns[remoteKey] or 0
	local timeSinceRemote = currentTime - lastRemoteTime
	print("Remote cooldown: " .. math.round(timeSinceRemote * 1000) .. "ms ago")
	print("Spam attempts: " .. (self.SpamAttempts[remoteKey] or 0))

	-- Plot cooldowns
	print("Plot cooldowns:")
	for key, time in pairs(self.PlantingCooldowns) do
		if key:find(tostring(userId)) then
			local timeSince = currentTime - time
			print("  " .. key .. ": " .. math.round(timeSince * 1000) .. "ms ago")
		end
	end

	print("=====================================")
end

-- ========== CROP PLANTING ==========

function CropCreation:PlantSeed(player, plotModel, seedId, seedData)
	print("🌱 CropCreation: PlantSeed - " .. player.Name .. " wants to plant " .. seedId)

	-- Step 1: Validate inputs
	if not self:ValidatePlantingInputs(player, plotModel, seedId) then
		return false
	end

	-- Step 2: Check planting cooldowns
	if not self:CheckPlantingCooldowns(player, plotModel) then
		return false
	end

	-- Step 3: Validate player resources
	if not self:ValidatePlayerResources(player, seedId) then
		return false
	end

	-- Step 4: Validate plot state
	if not self:ValidatePlotState(player, plotModel) then
		return false
	end

	-- Step 5: Get/validate seed data
	local finalSeedData = seedData or ItemConfig.GetSeedData(seedId)
	if not finalSeedData then
		warn("❌ CropCreation: Seed data not found for " .. seedId)
		self:SendNotification(player, "Invalid Seed", "Seed data not found for " .. seedId .. "!", "error")
		return false
	end

	-- Step 6: Determine crop type and rarity
	local cropType = finalSeedData.resultCropId
	local playerBoosters = self:GetPlayerBoosters(player)
	local cropRarity = ItemConfig.GetCropRarity and ItemConfig.GetCropRarity(seedId, playerBoosters) or "common"

	-- Step 7: Create crop visual
	local cropCreateSuccess = self:CreateCropOnPlot(plotModel, seedId, finalSeedData, cropRarity)
	if not cropCreateSuccess then
		warn("❌ CropCreation: Crop visual creation failed")
		self:SendNotification(player, "Planting Failed", "Could not create crop on plot!", "error")
		return false
	end

	-- Step 8: Update player inventory
	self:ConsumePlayerSeed(player, seedId)

	-- Step 9: Update plot state
	self:UpdatePlotState(plotModel, cropType, seedId, cropRarity)

	-- Step 10: Start growth timer
	self:StartCropGrowthTimer(plotModel, finalSeedData, cropType, cropRarity)

	-- Step 11: Check for immediate mutations
	if MutationSystem then
		spawn(function()
			wait(0.5) -- Small delay to ensure plot is fully set up
			MutationSystem:CheckForImmediateMutation(player, plotModel, cropType)
		end)
	end

	-- Step 12: Update player stats and save
	self:UpdatePlayerStats(player, "seedsPlanted", 1)
	GameCore:SavePlayerData(player)

	-- Step 13: Send success notification
	self:SendPlantingSuccessNotification(player, seedId, finalSeedData, cropRarity)

	print("🎉 CropCreation: Successfully planted " .. seedId .. " (" .. cropRarity .. ") for " .. player.Name)
	return true
end

-- ========== PLANTING VALIDATION ==========

function CropCreation:ValidatePlantingInputs(player, plotModel, seedId)
	if not player then
		warn("❌ CropCreation: No player provided")
		return false
	end

	if not plotModel then
		warn("❌ CropCreation: No plotModel provided")
		self:SendNotification(player, "Planting Error", "Invalid plot!", "error")
		return false
	end

	if not seedId then
		warn("❌ CropCreation: No seedId provided")
		self:SendNotification(player, "Planting Error", "No seed specified!", "error")
		return false
	end

	return true
end

function CropCreation:CheckPlantingCooldowns(player, plotModel)
	local userId = player.UserId
	local plotId = tostring(plotModel)
	local currentTime = tick()

	-- Initialize cooldown tracking if needed
	if not self.RemoteEventCooldowns then
		self.RemoteEventCooldowns = {}
	end
	if not self.PlantingCooldowns then
		self.PlantingCooldowns = {}
	end
	if not self.SpamAttempts then
		self.SpamAttempts = {}
	end

	-- Check remote event cooldown (more lenient)
	local remoteKey = userId .. "_PlantSeed"
	local lastRemoteTime = self.RemoteEventCooldowns[remoteKey] or 0
	local timeSinceLastRemote = currentTime - lastRemoteTime

	-- FIXED: More reasonable remote event cooldown (500ms instead of 200ms)
	if timeSinceLastRemote < 0.5 then
		-- Track spam attempts
		self.SpamAttempts[remoteKey] = (self.SpamAttempts[remoteKey] or 0) + 1

		-- Only warn after multiple rapid attempts
		if self.SpamAttempts[remoteKey] > 2 then
			warn("🚨 CropCreation: Remote event spam detected for " .. player.Name .. 
				" (attempt " .. self.SpamAttempts[remoteKey] .. ", last: " .. 
				math.round(timeSinceLastRemote * 1000) .. "ms ago)")
		else
			print("⚠️ CropCreation: Rapid planting attempt " .. self.SpamAttempts[remoteKey] .. 
				" for " .. player.Name .. " (" .. math.round(timeSinceLastRemote * 1000) .. "ms ago)")
		end

		return false
	end

	-- Reset spam counter on successful timing
	self.SpamAttempts[remoteKey] = 0
	self.RemoteEventCooldowns[remoteKey] = currentTime

	-- Check plot-specific planting cooldown (more lenient)
	local plantingKey = userId .. "_" .. plotId
	local lastPlantTime = self.PlantingCooldowns[plantingKey] or 0
	local timeSinceLastPlant = currentTime - lastPlantTime

	-- FIXED: More reasonable plot cooldown (1 second instead of 0.5)
	if timeSinceLastPlant < 1.0 then
		print("⏱️ CropCreation: Plot cooldown active for " .. player.Name .. 
			" (" .. math.round(timeSinceLastPlant * 1000) .. "ms ago)")
		return false
	end

	self.PlantingCooldowns[plantingKey] = currentTime

	print("✅ CropCreation: Cooldown check passed for " .. player.Name)
	return true
end

-- ALSO ADD this enhanced cleanup method:

function CropCreation:CleanupOldCooldowns()
	local currentTime = tick()
	local cleanupThreshold = 300 -- 5 minutes
	local remoteThreshold = 60    -- 1 minute for remote events

	-- Clean up old planting cooldowns
	for key, time in pairs(self.PlantingCooldowns) do
		if currentTime - time > cleanupThreshold then
			self.PlantingCooldowns[key] = nil
		end
	end

	-- Clean up old remote event cooldowns
	for key, time in pairs(self.RemoteEventCooldowns) do
		if currentTime - time > remoteThreshold then
			self.RemoteEventCooldowns[key] = nil
			-- Also reset spam attempts
			if self.SpamAttempts then
				self.SpamAttempts[key] = nil
			end
		end
	end

	-- Clean up old spam attempt tracking
	if self.SpamAttempts then
		for key, attempts in pairs(self.SpamAttempts) do
			local baseKey = key:gsub("_PlantSeed", "")
			local lastRemoteTime = self.RemoteEventCooldowns[key] or 0
			if currentTime - lastRemoteTime > remoteThreshold then
				self.SpamAttempts[key] = nil
			end
		end
	end
end

function CropCreation:ValidatePlayerResources(player, seedId)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		warn("❌ CropCreation: No player data found for " .. player.Name)
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	if not playerData.farming or not playerData.farming.inventory then
		warn("❌ CropCreation: No farming data for " .. player.Name)
		self:SendNotification(player, "No Farming Data", "You need to set up farming first!", "error")
		return false
	end

	local seedCount = playerData.farming.inventory[seedId] or 0
	if seedCount <= 0 then
		local seedInfo = ItemConfig.ShopItems and ItemConfig.ShopItems[seedId]
		local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
		warn("❌ CropCreation: No seeds - player has " .. seedCount .. " " .. seedId)
		self:SendNotification(player, "No Seeds", "You don't have any " .. seedName .. "!", "error")
		return false
	end

	return true
end

function CropCreation:ValidatePlotState(player, plotModel)
	if not plotModel or not plotModel.Parent then
		warn("❌ CropCreation: Plot model invalid or destroyed")
		self:SendNotification(player, "Invalid Plot", "Plot not found or invalid!", "error")
		return false
	end

	local isEmpty = self:IsPlotEmpty(plotModel)
	local isUnlocked = plotModel:GetAttribute("IsUnlocked")

	if isUnlocked ~= nil and not isUnlocked then
		warn("❌ CropCreation: Plot is locked")
		self:SendNotification(player, "Locked Plot", "This plot area is locked! Purchase farm expansion to unlock it.", "error")
		return false
	end

	if not isEmpty then
		warn("❌ CropCreation: Plot is not empty")
		self:SendNotification(player, "Plot Occupied", "This plot already has a crop growing!", "error")
		return false
	end

	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		warn("❌ CropCreation: Plot ownership mismatch")
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return false
	end

	return true
end

-- ========== CROP VISUAL CREATION ==========

function CropCreation:CreateCropOnPlot(plotModel, seedId, seedData, cropRarity)
	print("🎨 CropCreation: Creating crop on plot...")

	if not CropVisual then
		warn("❌ CropCreation: CropVisual module not available")
		return false
	end

	local cropType = seedData.resultCropId

	-- Use CropVisual module to handle the visual creation
	local success = CropVisual:HandleCropPlanted(plotModel, cropType, cropRarity)

	if success then
		print("✅ CropCreation: Crop visual created successfully")
		return true
	else
		warn("❌ CropCreation: Crop visual creation failed")
		return false
	end
end

-- ========== GROWTH SYSTEM ==========

function CropCreation:StartCropGrowthTimer(plotModel, seedData, cropType, cropRarity)
	local plotId = tostring(plotModel)

	-- Cancel any existing timer for this plot
	if self.GrowthTimers[plotId] then
		self.GrowthTimers[plotId]:Disconnect()
	end

	local growTime = seedData.growTime or 300 -- Default 5 minutes
	local stages = {"planted", "sprouting", "growing", "flowering", "ready"}
	local stageTime = growTime / (#stages - 1)

	print("🌱 CropCreation: Starting growth timer for " .. cropType .. " (" .. growTime .. "s total)")

	-- Create growth coroutine
	self.GrowthTimers[plotId] = spawn(function()
		for stage = 1, #stages - 1 do
			wait(stageTime)

			if plotModel and plotModel.Parent then
				local currentStage = plotModel:GetAttribute("GrowthStage") or 0
				if currentStage == stage - 1 then -- Only advance if still in expected stage
					local newStageIndex = stage
					local newStageName = stages[stage + 1]

					plotModel:SetAttribute("GrowthStage", newStageIndex)

					print("🌱 " .. cropType .. " advanced to stage " .. newStageIndex .. " (" .. newStageName .. ")")

					-- Update visual through CropVisual module
					if CropVisual then
						CropVisual:UpdateCropStage(plotModel, cropType, cropRarity, newStageName, newStageIndex)
					end

					-- Fire growth event for other systems
					self:FireGrowthStageEvent(plotModel, cropType, cropRarity, newStageName, newStageIndex)
				else
					print("🌱 Growth timer stopped - stage mismatch")
					break
				end
			else
				print("🌱 Growth timer stopped - plot no longer exists")
				break
			end
		end

		-- Mark as fully grown
		if plotModel and plotModel.Parent then
			plotModel:SetAttribute("GrowthStage", 4)
			if CropVisual then
				CropVisual:UpdateCropStage(plotModel, cropType, cropRarity, "ready", 4)
			end
			print("🌱 " .. cropType .. " fully grown and ready for harvest!")
		end

		-- Clean up timer reference
		self.GrowthTimers[plotId] = nil
	end)
end

function CropCreation:FireGrowthStageEvent(plotModel, cropType, cropRarity, stageName, stageIndex)
	-- Fire event for other systems that need to know about growth changes
	if GameCore and GameCore.Events and GameCore.Events.CropGrowthStageChanged then
		GameCore.Events.CropGrowthStageChanged:Fire(plotModel, cropType, cropRarity, stageName, stageIndex)
	end
end

-- ========== HARVESTING ==========

function CropCreation:HarvestCrop(player, plotModel)
	print("🌾 CropCreation: Harvesting crop for " .. player.Name)

	-- Validate harvest conditions
	if not self:ValidateHarvestConditions(player, plotModel) then
		return false
	end

	-- Get crop information
	local cropInfo = self:GetCropInfo(plotModel)
	if not cropInfo then
		self:SendNotification(player, "Invalid Crop", "Crop data not found", "error")
		return false
	end

	-- Check for mutations before harvesting
	if MutationSystem then
		local mutationResult = MutationSystem:ProcessPotentialMutations(player, plotModel)
		if mutationResult and mutationResult.mutated then
			print("🧬 CropCreation: Mutation detected during harvest")
			return self:HarvestMutatedCrop(player, plotModel, mutationResult)
		end
	end

	-- Calculate harvest yield
	local harvestYield = self:CalculateHarvestYield(cropInfo)

	-- Give rewards to player
	self:GiveHarvestRewards(player, cropInfo, harvestYield)

	-- Create harvest effects
	if CropVisual then
		CropVisual:OnCropHarvested(plotModel, cropInfo.plantType, cropInfo.rarity)
	end

	-- Clear plot after effects
	spawn(function()
		wait(1.5) -- Give time for visual effects
		self:ClearPlot(plotModel)
	end)

	-- Update player stats
	self:UpdatePlayerStats(player, "cropsHarvested", harvestYield)
	if cropInfo.rarity ~= "common" then
		self:UpdatePlayerStats(player, "rareCropsHarvested", 1)
	end

	-- Save player data
	GameCore:SavePlayerData(player)

	-- Send success notification
	self:SendHarvestSuccessNotification(player, cropInfo, harvestYield)

	print("🌾 CropCreation: Successfully harvested " .. harvestYield .. "x " .. cropInfo.plantType .. " for " .. player.Name)
	return true
end

function CropCreation:ValidateHarvestConditions(player, plotModel)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only harvest your own crops!", "error")
		return false
	end

	if self:IsPlotEmpty(plotModel) then
		self:SendNotification(player, "Nothing to Harvest", "This plot doesn't have any crops to harvest!", "warning")
		return false
	end

	local growthStage = plotModel:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		local timeLeft = self:GetCropTimeRemaining(plotModel)
		self:SendNotification(player, "Not Ready", 
			"Crop is not ready for harvest yet! " .. math.ceil(timeLeft/60) .. " minutes remaining.", "warning")
		return false
	end

	return true
end

function CropCreation:GetCropInfo(plotModel)
	local plantType = plotModel:GetAttribute("PlantType")
	local seedType = plotModel:GetAttribute("SeedType")
	local cropRarity = plotModel:GetAttribute("Rarity") or "common"

	if not plantType or not seedType then
		return nil
	end

	local cropData = ItemConfig.GetCropData and ItemConfig.GetCropData(plantType)
	local seedData = ItemConfig.GetSeedData and ItemConfig.GetSeedData(seedType)

	if not cropData or not seedData then
		return nil
	end

	return {
		plantType = plantType,
		seedType = seedType,
		rarity = cropRarity,
		cropData = cropData,
		seedData = seedData
	}
end

function CropCreation:CalculateHarvestYield(cropInfo)
	local baseYield = cropInfo.seedData.yieldAmount or 1
	local rarityMultiplier = ItemConfig.RaritySystem and ItemConfig.RaritySystem[cropInfo.rarity] 
		and ItemConfig.RaritySystem[cropInfo.rarity].valueMultiplier or 1.0

	return math.floor(baseYield * rarityMultiplier)
end

function CropCreation:GiveHarvestRewards(player, cropInfo, yield)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	local currentAmount = playerData.farming.inventory[cropInfo.plantType] or 0
	playerData.farming.inventory[cropInfo.plantType] = currentAmount + yield
end

-- ========== UTILITY FUNCTIONS ==========

function CropCreation:IsPlotEmpty(plotModel)
	-- Check for physical crop models
	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			return false
		end
	end

	-- Check IsEmpty attribute
	local isEmptyAttr = plotModel:GetAttribute("IsEmpty")
	if isEmptyAttr == false then
		return false
	end

	-- Check if there's a plant type set
	local plantType = plotModel:GetAttribute("PlantType")
	if plantType and plantType ~= "" then
		return false
	end

	-- Check growth stage
	local growthStage = plotModel:GetAttribute("GrowthStage")
	if growthStage and growthStage > 0 then
		return false
	end

	return true
end

function CropCreation:ClearPlot(plotModel)
	print("🧹 CropCreation: Clearing plot: " .. plotModel.Name)

	-- Remove crop models
	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			child:Destroy()
		end
	end

	-- Reset attributes
	plotModel:SetAttribute("IsEmpty", true)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("SeedType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", 0)
	plotModel:SetAttribute("Rarity", "common")
	plotModel:SetAttribute("IsMutation", false)
	plotModel:SetAttribute("MutationType", "")

	-- Clean up growth timer
	local plotId = tostring(plotModel)
	if self.GrowthTimers[plotId] then
		self.GrowthTimers[plotId]:Disconnect()
		self.GrowthTimers[plotId] = nil
	end
end

function CropCreation:GetPlotOwner(plotModel)
	local parent = plotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_SimpleFarm") then
			return parent.Name:gsub("_SimpleFarm", "")
		end

		if parent.Name:find("_ExpandableFarm") then
			return parent.Name:gsub("_ExpandableFarm", "")
		end

		parent = parent.Parent
	end

	return nil
end

function CropCreation:GetCropTimeRemaining(plotModel)
	local plantedTime = plotModel:GetAttribute("PlantedTime") or 0
	local currentTime = os.time()
	local growTime = 300 -- Default 5 minutes

	local elapsed = currentTime - plantedTime
	local remaining = math.max(0, growTime - elapsed)

	return remaining
end

function CropCreation:GetPlayerBoosters(player)
	local playerData = GameCore:GetPlayerData(player)
	local boosters = {}

	if playerData and playerData.boosters then
		if playerData.boosters.rarity_booster and playerData.boosters.rarity_booster > 0 then
			boosters.rarity_booster = true
		end
	end

	return boosters
end

function CropCreation:ConsumePlayerSeed(player, seedId)
	local playerData = GameCore:GetPlayerData(player)
	playerData.farming.inventory[seedId] = playerData.farming.inventory[seedId] - 1
end

function CropCreation:UpdatePlotState(plotModel, cropType, seedId, cropRarity)
	plotModel:SetAttribute("IsEmpty", false)
	plotModel:SetAttribute("PlantType", cropType)
	plotModel:SetAttribute("SeedType", seedId)
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", os.time())
	plotModel:SetAttribute("Rarity", cropRarity)
end

function CropCreation:UpdatePlayerStats(player, statName, amount)
	local playerData = GameCore:GetPlayerData(player)
	playerData.stats = playerData.stats or {}
	playerData.stats[statName] = (playerData.stats[statName] or 0) + amount
end

-- ========== NOTIFICATION HELPERS ==========

function CropCreation:SendNotification(player, title, message, type)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, type)
	else
		print("[" .. title .. "] " .. message .. " (to " .. player.Name .. ")")
	end
end

function CropCreation:SendPlantingSuccessNotification(player, seedId, seedData, cropRarity)
	local seedInfo = ItemConfig.ShopItems and ItemConfig.ShopItems[seedId]
	local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")

	local message = "Successfully planted " .. seedName .. "!\n🌟 Rarity: " .. cropRarity .. 
		"\n⏰ Ready in " .. math.floor(seedData.growTime/60) .. " minutes."

	self:SendNotification(player, "🌱 Seed Planted!", message, "success")
end

function CropCreation:SendHarvestSuccessNotification(player, cropInfo, yield)
	local rarityName = ItemConfig.RaritySystem and ItemConfig.RaritySystem[cropInfo.rarity] 
		and ItemConfig.RaritySystem[cropInfo.rarity].name or cropInfo.rarity
	local rarityEmoji = cropInfo.rarity == "legendary" and "👑" or 
		cropInfo.rarity == "epic" and "💜" or 
		cropInfo.rarity == "rare" and "✨" or 
		cropInfo.rarity == "uncommon" and "💚" or "⚪"

	local message = "Harvested " .. yield .. "x " .. rarityEmoji .. " " .. rarityName .. " " .. cropInfo.cropData.name .. "!"
	self:SendNotification(player, "🌾 Crop Harvested!", message, "success")
end

-- ========== MUTATION INTEGRATION ==========

function CropCreation:HarvestMutatedCrop(player, plotModel, mutationResult)
	print("🧬 CropCreation: Harvesting mutated crop")
	-- Delegate to mutation system if available
	if MutationSystem and MutationSystem.HarvestMutation then
		return MutationSystem:HarvestMutation(player, plotModel, mutationResult)
	else
		-- Fallback to normal harvest
		return self:HarvestCrop(player, plotModel)
	end
end

function CropCreation:HarvestAllCrops(player)
	print("🌾 CropCreation: Mass harvest request from " .. player.Name)

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Find all player's farm plots
	local farm = self:GetPlayerFarm(player)
	if not farm then
		self:SendNotification(player, "No Farm", "You don't have a farm yet!", "error")
		return false
	end

	local harvestedCount = 0
	local readyCrops = 0
	local totalCrops = 0
	local rarityStats = {common = 0, uncommon = 0, rare = 0, epic = 0, legendary = 0}

	-- Find all planting spots in the farm
	local plantingSpots = farm:FindFirstChild("PlantingSpots")
	if plantingSpots then
		for _, spot in pairs(plantingSpots:GetChildren()) do
			if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
				local isEmpty = spot:GetAttribute("IsEmpty")
				if not isEmpty then
					totalCrops = totalCrops + 1
					local growthStage = spot:GetAttribute("GrowthStage") or 0

					if growthStage >= 4 then
						readyCrops = readyCrops + 1
						local cropRarity = spot:GetAttribute("Rarity") or "common"
						local success = self:HarvestCrop(player, spot)
						if success then
							harvestedCount = harvestedCount + 1
							rarityStats[cropRarity] = (rarityStats[cropRarity] or 0) + 1
						end
						wait(0.1) -- Small delay between harvests
					end
				end
			end
		end
	end

	-- Send summary notification
	self:SendMassHarvestNotification(player, harvestedCount, readyCrops, totalCrops, rarityStats)

	return harvestedCount > 0
end

function CropCreation:SendMassHarvestNotification(player, harvested, ready, total, rarityStats)
	if harvested > 0 then
		local rarityBreakdown = ""
		for rarity, count in pairs(rarityStats) do
			if count > 0 then
				local emoji = rarity == "legendary" and "👑" or 
					rarity == "epic" and "💜" or 
					rarity == "rare" and "✨" or 
					rarity == "uncommon" and "💚" or "⚪"
				rarityBreakdown = rarityBreakdown .. emoji .. " " .. rarity .. ": " .. count .. "\n"
			end
		end

		local message = "Harvested " .. harvested .. " crops!\n\n" .. rarityBreakdown
		if ready - harvested > 0 then
			message = message .. (ready - harvested) .. " crops failed to harvest.\n"
		end
		if total - ready > 0 then
			message = message .. (total - ready) .. " crops still growing."
		end

		self:SendNotification(player, "🌾 Mass Harvest Complete!", message, "success")
	else
		if total == 0 then
			self:SendNotification(player, "No Crops", "You don't have any crops planted!", "info")
		elseif ready == 0 then
			self:SendNotification(player, "Crops Not Ready", "None of your " .. total .. " crops are ready for harvest yet!", "warning")
		else
			self:SendNotification(player, "Harvest Failed", "Found " .. ready .. " ready crops but couldn't harvest any!", "error")
		end
	end
end

function CropCreation:GetPlayerFarm(player)
	-- This should delegate to the FarmPlot module when implemented
	if GameCore and GameCore.GetPlayerSimpleFarm then
		return GameCore:GetPlayerSimpleFarm(player)
	elseif GameCore and GameCore.GetPlayerExpandableFarm then
		return GameCore:GetPlayerExpandableFarm(player)
	end
	return nil
end

print("CropCreation: ✅ Module loaded successfully")

print("CropCreation: ✅ COOLDOWN FIX APPLIED!")
print("🔧 IMPROVEMENTS:")
print("  ⏱️ Remote event cooldown: 200ms → 500ms")
print("  📍 Plot cooldown: 500ms → 1000ms") 
print("  🎯 Spam detection: Only warns after 3+ rapid attempts")
print("  🧹 Better cleanup with spam attempt tracking")
print("  📊 Enhanced debugging information")
print("  📡 Network latency tolerance")
return CropCreation