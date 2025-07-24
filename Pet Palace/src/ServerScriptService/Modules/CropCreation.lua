--[[
    Modified CropCreation.lua - Garden Integration
    Place in: ServerScriptService/Modules/CropCreation.lua
    
    MODIFICATIONS:
    ✅ Adapted plot validation for Garden system
    ✅ Updated owner detection for garden regions
    ✅ Enhanced crop positioning for garden spots
    ✅ Maintains all existing planting and harvest logic
]]

local CropCreation = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Dependencies
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Module references (will be injected)
local GameCore = nil
local CropVisual = nil
local MutationSystem = nil

-- Garden references
local GardenModel = nil
local SoilPart = nil

-- Internal state
CropCreation.GrowthTimers = {}
CropCreation.PlantingCooldowns = {}
CropCreation.RemoteEventCooldowns = {}

-- ========== INITIALIZATION ==========
-- ADD this method to the top of your CropCreation.lua module (after the local variables):

-- ========== SAFE ID GENERATION ==========

function CropCreation:GenerateSafeSpotId(gardenSpotModel)
	if not gardenSpotModel then
		return "unknown_" .. tostring(math.random(1000000, 9999999))
	end

	-- Try to create a consistent ID based on the spot's properties
	local spotName = gardenSpotModel.Name or "UnknownSpot"
	local parentName = (gardenSpotModel.Parent and gardenSpotModel.Parent.Name) or "UnknownParent"

	-- Get position-based ID for consistency
	local positionId = ""
	if gardenSpotModel.PrimaryPart then
		local pos = gardenSpotModel.PrimaryPart.Position
		positionId = math.floor(pos.X) .. "_" .. math.floor(pos.Y) .. "_" .. math.floor(pos.Z)
	elseif gardenSpotModel:FindFirstChild("SpotPart") then
		local pos = gardenSpotModel.SpotPart.Position
		positionId = math.floor(pos.X) .. "_" .. math.floor(pos.Y) .. "_" .. math.floor(pos.Z)
	else
		positionId = tostring(math.random(100000, 999999))
	end

	-- Create a safe, consistent ID
	local safeId = parentName .. "_" .. spotName .. "_" .. positionId

	-- Clean up the ID to remove any problematic characters
	safeId = safeId:gsub("[^%w_]", "_")

	return safeId
end

-- ========== REPLACE ALL INSTANCES ==========

-- REPLACE the StartCropGrowthTimer method with this version that uses safe ID generation:

function CropCreation:StartCropGrowthTimer(gardenSpotModel, seedData, cropType, cropRarity)
	if not gardenSpotModel or not gardenSpotModel.Parent then
		warn("❌ CropCreation: Invalid garden spot for growth timer")
		return false
	end

	-- FIXED: Use safe ID generation instead of GetDebugId()
	local spotId = self:GenerateSafeSpotId(gardenSpotModel)

	-- Cancel any existing timer for this spot
	if self.GrowthTimers[spotId] then
		self.GrowthTimers[spotId]:Disconnect()
		self.GrowthTimers[spotId] = nil
		print("🔄 Cancelled existing growth timer for spot: " .. spotId)
	end

	-- Get the actual growth time from seed data
	local growTime = seedData.growTime or 300
	local stages = {"planted", "sprouting", "growing", "flowering", "ready"}
	local stageTime = growTime / (#stages - 1) -- Time per stage transition

	print("🌱 CropCreation: Starting SAFE growth timer for garden " .. cropType)
	print("  📊 Total grow time: " .. growTime .. " seconds")
	print("  🎯 Safe Spot ID: " .. spotId)

	-- Store timer reference
	local connection
	connection = spawn(function()
		for stage = 1, #stages - 1 do -- 1 to 4 (planted starts at 0, so we go to ready at 4)
			print("⏰ " .. cropType .. " Stage " .. stage .. " - Waiting " .. stageTime .. "s for " .. stages[stage + 1])

			-- Wait for the stage time
			wait(stageTime)

			-- CRITICAL: Validate garden spot still exists and hasn't been harvested
			if not gardenSpotModel or not gardenSpotModel.Parent then
				print("❌ Garden growth timer stopped - spot destroyed at stage " .. stage)
				self.GrowthTimers[spotId] = nil
				return
			end

			-- Check if spot was harvested or replanted
			local isEmpty = gardenSpotModel:GetAttribute("IsEmpty")
			if isEmpty then
				print("❌ Garden growth timer stopped - spot became empty (harvested) at stage " .. stage)
				self.GrowthTimers[spotId] = nil
				return
			end

			-- Check if this is still the same crop
			local currentCropType = gardenSpotModel:GetAttribute("PlantType")
			if currentCropType ~= cropType then
				print("❌ Garden growth timer stopped - crop type changed at stage " .. stage)
				self.GrowthTimers[spotId] = nil
				return
			end

			-- Advance to next stage
			local newStageIndex = stage
			local newStageName = stages[stage + 1]

			gardenSpotModel:SetAttribute("GrowthStage", newStageIndex)

			print("🌱✅ Garden " .. cropType .. " advanced to stage " .. newStageIndex .. " (" .. newStageName .. ")")

			-- Update visual through CropVisual module with robust error handling
			if CropVisual then
				local success, error = pcall(function()
					return CropVisual:UpdateCropStage(gardenSpotModel, cropType, cropRarity, newStageName, newStageIndex)
				end)

				if success then
					print("✅ CropVisual updated successfully for stage " .. newStageName)
				else
					warn("❌ CropVisual update failed for stage " .. newStageName .. ": " .. tostring(error))
					-- DON'T stop the timer - continue growing even if visual fails
					print("🔄 Continuing growth timer despite visual error")
				end
			else
				warn("❌ CropVisual module not available for stage update")
			end

			-- Fire growth event for other systems (with error protection)
			pcall(function()
				self:FireGrowthStageEvent(gardenSpotModel, cropType, cropRarity, newStageName, newStageIndex)
			end)
		end

		-- Final stage: Mark as fully grown (stage 4 = ready)
		if gardenSpotModel and gardenSpotModel.Parent then
			-- Double-check it's still the right crop
			local isEmpty = gardenSpotModel:GetAttribute("IsEmpty")
			local currentCropType = gardenSpotModel:GetAttribute("PlantType")

			if not isEmpty and currentCropType == cropType then
				gardenSpotModel:SetAttribute("GrowthStage", 4)
				print("🌱🎉 Garden " .. cropType .. " FULLY GROWN after " .. growTime .. " seconds - ready for harvest!")

				-- Final visual update (with error protection)
				if CropVisual then
					local success, error = pcall(function()
						return CropVisual:UpdateCropStage(gardenSpotModel, cropType, cropRarity, "ready", 4)
					end)

					if not success then
						warn("❌ Final CropVisual update failed: " .. tostring(error))
						-- Create a basic "ready" indicator even if visual fails
						self:CreateBasicReadyIndicator(gardenSpotModel, cropType)
					else
						print("✅ Final CropVisual update successful - " .. cropType .. " crop ready!")
					end
				else
					-- No CropVisual available, create basic ready indicator
					self:CreateBasicReadyIndicator(gardenSpotModel, cropType)
				end

				-- Add harvest-ready effects (with error protection)
				pcall(function()
					self:CreateHarvestReadyEffects(gardenSpotModel, cropType, cropRarity)
				end)
			else
				print("❌ Crop was harvested or changed before completion")
			end
		else
			print("❌ Garden spot destroyed before completion")
		end

		-- Clean up timer reference
		self.GrowthTimers[spotId] = nil
		print("🧹 Cleaned up growth timer for " .. cropType .. " after " .. growTime .. "s")
	end)

	-- Store the connection
	self.GrowthTimers[spotId] = connection

	print("✅ Safe growth timer started successfully for " .. cropType)
	return true
end

-- REPLACE the CleanupGrowthTimer method with this safe version:

function CropCreation:CleanupGrowthTimer(gardenSpotModel)
	if not gardenSpotModel then return end

	-- FIXED: Use safe ID generation instead of GetDebugId()
	local spotId = self:GenerateSafeSpotId(gardenSpotModel)

	if self.GrowthTimers[spotId] then
		self.GrowthTimers[spotId]:Disconnect()
		self.GrowthTimers[spotId] = nil
		print("🧹 Cleaned up growth timer for spot: " .. spotId)
	end
end

-- ALSO UPDATE the ClearGardenSpot method to use safe ID:

function CropCreation:ClearGardenSpot(gardenSpotModel)
	print("🧹 CropCreation: Clearing garden spot: " .. gardenSpotModel.Name)

	-- Clean up growth timer FIRST using safe ID
	self:CleanupGrowthTimer(gardenSpotModel)

	-- Remove crop models
	for _, child in pairs(gardenSpotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			child:Destroy()
		end
	end

	-- Reset attributes
	gardenSpotModel:SetAttribute("IsEmpty", true)
	gardenSpotModel:SetAttribute("PlantType", "")
	gardenSpotModel:SetAttribute("SeedType", "")
	gardenSpotModel:SetAttribute("GrowthStage", 0)
	gardenSpotModel:SetAttribute("PlantedTime", 0)
	gardenSpotModel:SetAttribute("Rarity", "common")
	gardenSpotModel:SetAttribute("IsMutation", false)
	gardenSpotModel:SetAttribute("MutationType", "")

	print("✅ Garden spot cleared and timer cleaned up safely")
end
function CropCreation:Initialize(gameCoreRef, cropVisualRef, mutationSystemRef)
	print("CropCreation: Initializing Garden-based crop creation system...")

	-- Store module references
	GameCore = gameCoreRef
	CropVisual = cropVisualRef
	MutationSystem = mutationSystemRef

	-- Initialize garden references
	self:InitializeGardenReferences()

	-- Initialize internal systems
	self:InitializeCooldownSystems()

	print("CropCreation: ✅ Garden-based crop creation system initialized successfully")
	return true
end

function CropCreation:InitializeGardenReferences()
	-- Find Garden model and Soil part
	GardenModel = Workspace:FindFirstChild("Garden")
	if GardenModel then
		SoilPart = GardenModel:FindFirstChild("Soil")
		if SoilPart then
			print("CropCreation: ✅ Garden references established")
			print("  Garden: " .. GardenModel.Name)
			print("  Soil: " .. SoilPart.Name)
		else
			warn("CropCreation: ⚠️ Soil part not found in Garden")
		end
	else
		warn("CropCreation: ⚠️ Garden model not found in workspace")
	end
end

function CropCreation:InitializeCooldownSystems()
	self.PlantingCooldowns = {}
	self.RemoteEventCooldowns = {}
	self.SpamAttempts = {}

	-- Enhanced cleanup every 60 seconds
	spawn(function()
		while true do
			wait(60)
			self:CleanupOldCooldowns()
		end
	end)
end

-- ========== GARDEN CROP PLANTING ==========

-- REPLACE the PlantSeed method in CropCreation.lua with this enhanced version:

function CropCreation:PlantSeed(player, gardenSpotModel, seedId, seedData)
	print("🌱 CropCreation: PlantSeed on Garden - " .. player.Name .. " wants to plant " .. seedId)

	-- Step 1: Validate inputs
	if not self:ValidateGardenPlantingInputs(player, gardenSpotModel, seedId) then
		return false
	end

	-- Step 2: Check planting cooldowns
	if not self:CheckPlantingCooldowns(player, gardenSpotModel) then
		return false
	end

	-- Step 3: Validate player resources
	if not self:ValidatePlayerResources(player, seedId) then
		return false
	end

	-- Step 4: Validate garden spot state
	if not self:ValidateGardenSpotState(player, gardenSpotModel) then
		return false
	end

	-- Step 5: Get seed data from ItemConfig with proper growth time
	local finalSeedData = self:GetEnhancedSeedData(seedId, seedData)
	if not finalSeedData then
		warn("❌ CropCreation: Seed data not found for " .. seedId)
		self:SendNotification(player, "Invalid Seed", "Seed data not found for " .. seedId .. "!", "error")
		return false
	end

	-- Step 6: Determine crop type and rarity
	local cropType = finalSeedData.resultCropId
	local playerBoosters = self:GetPlayerBoosters(player)
	local cropRarity = ItemConfig.GetCropRarity and ItemConfig.GetCropRarity(seedId, playerBoosters) or "common"

	-- Step 7: Create crop visual on garden
	local cropCreateSuccess = self:CreateCropOnGarden(gardenSpotModel, seedId, finalSeedData, cropRarity)
	if not cropCreateSuccess then
		warn("❌ CropCreation: Garden crop visual creation failed")
		self:SendNotification(player, "Planting Failed", "Could not create crop on garden spot!", "error")
		return false
	end

	-- Step 8: Update player inventory
	self:ConsumePlayerSeed(player, seedId)

	-- Step 9: Update garden spot state
	self:UpdateGardenSpotState(gardenSpotModel, cropType, seedId, cropRarity)

	-- Step 10: Start growth timer with correct time from ItemConfig
	self:StartCropGrowthTimer(gardenSpotModel, finalSeedData, cropType, cropRarity)

	-- Step 11: Check for immediate mutations
	if MutationSystem then
		spawn(function()
			wait(0.5)
			MutationSystem:CheckForImmediateMutation(player, gardenSpotModel, cropType)
		end)
	end

	-- Step 12: Update player stats and save
	self:UpdatePlayerStats(player, "seedsPlanted", 1)
	GameCore:SavePlayerData(player)

	-- Step 13: Send success notification with actual grow time
	self:SendGardenPlantingSuccessNotification(player, seedId, finalSeedData, cropRarity)

	print("🎉 CropCreation: Successfully planted " .. seedId .. " (" .. cropRarity .. ") with " .. finalSeedData.growTime .. "s grow time")
	return true
end

-- ADD this new method to get enhanced seed data with correct growth times:
function CropCreation:GetEnhancedSeedData(seedId, providedSeedData)
	-- First try to get from ItemConfig
	local itemConfigSeed = ItemConfig.ShopItems[seedId]
	if itemConfigSeed and itemConfigSeed.farmingData then
		local seedData = {}

		-- Copy all farming data from ItemConfig
		for key, value in pairs(itemConfigSeed.farmingData) do
			seedData[key] = value
		end

		-- Ensure we have the correct grow time
		if not seedData.growTime then
			warn("⚠️ CropCreation: No growTime in ItemConfig for " .. seedId .. ", using default")
			seedData.growTime = 300 -- 5 minute default
		end

		print("📊 CropCreation: Using ItemConfig data for " .. seedId .. " (growTime: " .. seedData.growTime .. "s)")
		return seedData
	end

	-- Fallback to provided data
	if providedSeedData then
		if not providedSeedData.growTime then
			providedSeedData.growTime = 300 -- Default fallback
		end
		print("📊 CropCreation: Using provided data for " .. seedId .. " (growTime: " .. providedSeedData.growTime .. "s)")
		return providedSeedData
	end

	-- Final fallback - construct basic seed data
	warn("⚠️ CropCreation: No seed data found for " .. seedId .. ", creating fallback")
	return {
		growTime = 300,
		yieldAmount = 1,
		resultCropId = seedId:gsub("_seeds", ""),
		stages = {"planted", "sprouting", "growing", "flowering", "ready"}
	}
end

-- ADD this fallback method for when CropVisual fails:
function CropCreation:CreateBasicReadyIndicator(gardenSpotModel, cropType)
	print("🔧 Creating basic ready indicator for " .. cropType)

	-- Find the crop model
	local cropModel = gardenSpotModel:FindFirstChild("CropModel")
	if not cropModel or not cropModel.PrimaryPart then
		return
	end

	-- Add a simple glow effect to indicate readiness
	local existingLight = cropModel.PrimaryPart:FindFirstChild("ReadyGlow")
	if not existingLight then
		local readyGlow = Instance.new("PointLight")
		readyGlow.Name = "ReadyGlow"
		readyGlow.Color = Color3.fromRGB(255, 215, 0) -- Golden glow
		readyGlow.Brightness = 1.5
		readyGlow.Range = 8
		readyGlow.Parent = cropModel.PrimaryPart

		print("✅ Added basic ready glow to " .. cropType)
	end
end

-- ENHANCE the existing CreateHarvestReadyEffects method:
function CropCreation:CreateHarvestReadyEffects(gardenSpotModel, cropType, cropRarity)
	print("✨ Creating harvest-ready effects for " .. cropType)

	-- Find the crop model
	local cropModel = gardenSpotModel:FindFirstChild("CropModel")
	if not cropModel or not cropModel.PrimaryPart then
		print("⚠️ No crop model found for ready effects")
		return
	end

	-- Create enhanced ready particles
	for i = 1, 5 do
		local particle = Instance.new("Part")
		particle.Name = "HarvestReadyParticle"
		particle.Size = Vector3.new(0.3, 0.3, 0.3)
		particle.Material = Enum.Material.Neon
		particle.Color = Color3.fromRGB(255, 215, 0) -- Golden color
		particle.CanCollide = false
		particle.Anchored = true
		particle.Shape = Enum.PartType.Ball

		local position = cropModel.PrimaryPart.Position + Vector3.new(
			math.random(-3, 3),
			math.random(2, 5),
			math.random(-3, 3)
		)
		particle.Position = position
		particle.Parent = workspace

		-- Animate the particle
		spawn(function()
			-- Float upward with sparkling effect
			for j = 1, 30 do
				if particle and particle.Parent then
					particle.Position = particle.Position + Vector3.new(0, 0.1, 0)
					particle.Transparency = j / 30
					wait(0.1)
				else
					break
				end
			end

			-- Clean up
			if particle and particle.Parent then
				particle:Destroy()
			end
		end)

		wait(0.1) -- Small delay between particles
	end

	print("✨ Harvest-ready effects created for " .. cropType)
end

-- ADD this method to verify timer completion:
function CropCreation:VerifyTimerCompletion(gardenSpotModel, expectedCropType)
	if not gardenSpotModel or not gardenSpotModel.Parent then
		return false
	end

	local growthStage = gardenSpotModel:GetAttribute("GrowthStage") or 0
	local plantType = gardenSpotModel:GetAttribute("PlantType") or ""
	local isEmpty = gardenSpotModel:GetAttribute("IsEmpty")

	local isReady = growthStage >= 4 and not isEmpty and plantType == expectedCropType

	print("🔍 Timer completion verification:")
	print("  Growth Stage: " .. growthStage .. " (ready if >= 4)")
	print("  Plant Type: " .. plantType .. " (expected: " .. expectedCropType .. ")")
	print("  Is Empty: " .. tostring(isEmpty))
	print("  Is Ready: " .. tostring(isReady))

	return isReady
end

-- ENHANCE the SendGardenPlantingSuccessNotification to show actual grow time:
function CropCreation:SendGardenPlantingSuccessNotification(player, seedId, seedData, cropRarity)
	local seedInfo = ItemConfig.ShopItems and ItemConfig.ShopItems[seedId]
	local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")

	local growTime = seedData.growTime or 300
	local minutes = math.floor(growTime / 60)
	local seconds = growTime % 60

	local timeText
	if minutes > 0 then
		if seconds > 0 then
			timeText = minutes .. "m " .. seconds .. "s"
		else
			timeText = minutes .. " minutes"
		end
	else
		timeText = seconds .. " seconds"
	end

	local message = "Successfully planted " .. seedName .. " in your garden!\n🌟 Rarity: " .. cropRarity .. 
		"\n⏰ Ready in " .. timeText

	self:SendNotification(player, "🌱 Garden Seed Planted!", message, "success")
end
-- ========== GARDEN VALIDATION ==========

function CropCreation:ValidateGardenPlantingInputs(player, gardenSpotModel, seedId)
	if not player then
		warn("❌ CropCreation: No player provided")
		return false
	end

	if not gardenSpotModel then
		warn("❌ CropCreation: No garden spot model provided")
		self:SendNotification(player, "Planting Error", "Invalid garden spot!", "error")
		return false
	end

	if not seedId then
		warn("❌ CropCreation: No seedId provided")
		self:SendNotification(player, "Planting Error", "No seed specified!", "error")
		return false
	end

	-- Validate this is actually a garden spot
	local isGardenSpot = gardenSpotModel:GetAttribute("IsGardenSpot")
	if not isGardenSpot then
		warn("❌ CropCreation: Not a valid garden spot")
		self:SendNotification(player, "Invalid Spot", "This is not a valid garden planting spot!", "error")
		return false
	end

	return true
end

function CropCreation:ValidateGardenSpotState(player, gardenSpotModel)
	if not gardenSpotModel or not gardenSpotModel.Parent then
		warn("❌ CropCreation: Garden spot model invalid or destroyed")
		self:SendNotification(player, "Invalid Spot", "Garden spot not found or invalid!", "error")
		return false
	end

	local isEmpty = self:IsGardenSpotEmpty(gardenSpotModel)
	local isUnlocked = gardenSpotModel:GetAttribute("IsUnlocked")

	if isUnlocked ~= nil and not isUnlocked then
		warn("❌ CropCreation: Garden spot is locked")
		self:SendNotification(player, "Locked Spot", "This garden spot is locked! Purchase upgrades to unlock it.", "error")
		return false
	end

	if not isEmpty then
		warn("❌ CropCreation: Garden spot is not empty")
		self:SendNotification(player, "Spot Occupied", "This garden spot already has a crop growing!", "error")
		return false
	end

	local spotOwner = self:GetGardenSpotOwner(gardenSpotModel)
	if spotOwner ~= player.Name then
		warn("❌ CropCreation: Garden spot ownership mismatch")
		self:SendNotification(player, "Not Your Garden", "You can only plant in your own garden region!", "error")
		return false
	end

	return true
end

function CropCreation:IsGardenSpotEmpty(gardenSpotModel)
	-- Check for physical crop models
	for _, child in pairs(gardenSpotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			return false
		end
	end

	-- Check IsEmpty attribute
	local isEmptyAttr = gardenSpotModel:GetAttribute("IsEmpty")
	if isEmptyAttr == false then
		return false
	end

	-- Check if there's a plant type set
	local plantType = gardenSpotModel:GetAttribute("PlantType")
	if plantType and plantType ~= "" then
		return false
	end

	-- Check growth stage
	local growthStage = gardenSpotModel:GetAttribute("GrowthStage")
	if growthStage and growthStage > 0 then
		return false
	end

	return true
end

function CropCreation:GetGardenSpotOwner(gardenSpotModel)
	-- Traverse up to find the garden region
	local parent = gardenSpotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_GardenRegion") then
			return parent.Name:gsub("_GardenRegion", "")
		end

		parent = parent.Parent
	end

	return nil
end

-- ========== GARDEN CROP VISUAL CREATION ==========

function CropCreation:CreateCropOnGarden(gardenSpotModel, seedId, seedData, cropRarity)
	print("🎨 CropCreation: Creating crop on garden spot...")

	if not CropVisual then
		warn("❌ CropCreation: CropVisual module not available")
		return false
	end

	local cropType = seedData.resultCropId

	-- Use CropVisual module to handle the garden visual creation
	local success = CropVisual:HandleCropPlanted(gardenSpotModel, cropType, cropRarity)

	if success then
		print("✅ CropCreation: Garden crop visual created successfully")
		return true
	else
		warn("❌ CropCreation: Garden crop visual creation failed")
		return false
	end
end

-- ========== GARDEN STATE MANAGEMENT ==========

function CropCreation:UpdateGardenSpotState(gardenSpotModel, cropType, seedId, cropRarity)
	gardenSpotModel:SetAttribute("IsEmpty", false)
	gardenSpotModel:SetAttribute("PlantType", cropType)
	gardenSpotModel:SetAttribute("SeedType", seedId)
	gardenSpotModel:SetAttribute("GrowthStage", 0)
	gardenSpotModel:SetAttribute("PlantedTime", os.time())
	gardenSpotModel:SetAttribute("Rarity", cropRarity)
	gardenSpotModel:SetAttribute("IsGardenCrop", true)
end

-- REPLACE the existing FireGrowthStageEvent method with this enhanced version:
function CropCreation:FireGrowthStageEvent(gardenSpotModel, cropType, cropRarity, stageName, stageIndex)
	-- Fire event for other systems that need to know about growth changes
	if GameCore and GameCore.Events and GameCore.Events.CropGrowthStageChanged then
		pcall(function()
			GameCore.Events.CropGrowthStageChanged:Fire(gardenSpotModel, cropType, cropRarity, stageName, stageIndex)
		end)
	end

	-- Debug print for tracking
	print("📡 Growth stage event fired: " .. cropType .. " -> " .. stageName .. " (stage " .. stageIndex .. ")")
end

-- ADD this debug method to check timer status:
function CropCreation:DebugGrowthTimers()
	print("=== GROWTH TIMER DEBUG ===")
	local activeCount = 0
	for spotId, timer in pairs(self.GrowthTimers) do
		if timer then
			activeCount = activeCount + 1
			print("  Active timer: " .. spotId)
		end
	end
	print("Total active timers: " .. activeCount)
	print("========================")
end

function CropCreation:HarvestCrop(player, gardenSpotModel)
	print("🌾 CropCreation: Harvesting garden crop for " .. player.Name)

	-- Validate harvest conditions
	if not self:ValidateGardenHarvestConditions(player, gardenSpotModel) then
		return false
	end

	-- Get crop information
	local cropInfo = self:GetGardenCropInfo(gardenSpotModel)
	if not cropInfo then
		self:SendNotification(player, "Invalid Crop", "Garden crop data not found", "error")
		return false
	end

	-- Check for mutations before harvesting
	if MutationSystem then
		local mutationResult = MutationSystem:ProcessPotentialMutations(player, gardenSpotModel)
		if mutationResult and mutationResult.mutated then
			print("🧬 CropCreation: Garden mutation detected during harvest")
			return self:HarvestMutatedGardenCrop(player, gardenSpotModel, mutationResult)
		end
	end

	-- Calculate harvest yield
	local harvestYield = self:CalculateHarvestYield(cropInfo)

	-- Give rewards to player
	self:GiveHarvestRewards(player, cropInfo, harvestYield)

	-- Create harvest effects
	if CropVisual then
		CropVisual:OnCropHarvested(gardenSpotModel, cropInfo.plantType, cropInfo.rarity)
	end

	-- Clear garden spot after effects
	spawn(function()
		wait(1.5) -- Give time for visual effects
		self:ClearGardenSpot(gardenSpotModel)
	end)

	-- Update player stats
	self:UpdatePlayerStats(player, "cropsHarvested", harvestYield)
	if cropInfo.rarity ~= "common" then
		self:UpdatePlayerStats(player, "rareCropsHarvested", 1)
	end

	-- Save player data
	GameCore:SavePlayerData(player)

	-- Send success notification
	self:SendGardenHarvestSuccessNotification(player, cropInfo, harvestYield)

	print("🌾 CropCreation: Successfully harvested " .. harvestYield .. "x " .. cropInfo.plantType .. " from garden for " .. player.Name)
	return true
end

function CropCreation:ValidateGardenHarvestConditions(player, gardenSpotModel)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	local spotOwner = self:GetGardenSpotOwner(gardenSpotModel)
	if spotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Garden", "You can only harvest from your own garden!", "error")
		return false
	end

	if self:IsGardenSpotEmpty(gardenSpotModel) then
		self:SendNotification(player, "Nothing to Harvest", "This garden spot doesn't have any crops to harvest!", "warning")
		return false
	end

	local growthStage = gardenSpotModel:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		local timeLeft = self:GetGardenCropTimeRemaining(gardenSpotModel)
		self:SendNotification(player, "Not Ready", 
			"Garden crop is not ready for harvest yet! " .. math.ceil(timeLeft/60) .. " minutes remaining.", "warning")
		return false
	end

	return true
end

function CropCreation:GetGardenCropInfo(gardenSpotModel)
	local plantType = gardenSpotModel:GetAttribute("PlantType")
	local seedType = gardenSpotModel:GetAttribute("SeedType")
	local cropRarity = gardenSpotModel:GetAttribute("Rarity") or "common"

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
		seedData = seedData,
		isGardenCrop = true
	}
end

function CropCreation:GetGardenCropTimeRemaining(gardenSpotModel)
	local plantedTime = gardenSpotModel:GetAttribute("PlantedTime") or 0
	local currentTime = os.time()
	local growTime = 300 -- Default 5 minutes

	local elapsed = currentTime - plantedTime
	local remaining = math.max(0, growTime - elapsed)

	return remaining
end

-- ========== GARDEN HARVEST ALL ==========

function CropCreation:HarvestAllCrops(player)
	print("🌾 CropCreation: Garden mass harvest request from " .. player.Name)

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Find player's garden region
	local gardenRegion = self:GetPlayerGardenRegion(player)
	if not gardenRegion then
		self:SendNotification(player, "No Garden", "You don't have a garden region yet!", "error")
		return false
	end

	local harvestedCount = 0
	local readyCrops = 0
	local totalCrops = 0
	local rarityStats = {common = 0, uncommon = 0, rare = 0, epic = 0, legendary = 0}

	-- Find all planting spots in the garden region
	local plantingSpots = gardenRegion:FindFirstChild("PlantingSpots")
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
	self:SendGardenMassHarvestNotification(player, harvestedCount, readyCrops, totalCrops, rarityStats)

	return harvestedCount > 0
end

function CropCreation:GetPlayerGardenRegion(player)
	if not GardenModel then return nil end

	local regionName = player.Name .. "_GardenRegion"
	return GardenModel:FindFirstChild(regionName)
end

function CropCreation:SendGardenMassHarvestNotification(player, harvested, ready, total, rarityStats)
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

		local message = "Harvested " .. harvested .. " crops from your garden!\n\n" .. rarityBreakdown
		if ready - harvested > 0 then
			message = message .. (ready - harvested) .. " crops failed to harvest.\n"
		end
		if total - ready > 0 then
			message = message .. (total - ready) .. " crops still growing."
		end

		self:SendNotification(player, "🌾 Garden Mass Harvest Complete!", message, "success")
	else
		if total == 0 then
			self:SendNotification(player, "No Garden Crops", "You don't have any crops planted in your garden!", "info")
		elseif ready == 0 then
			self:SendNotification(player, "Garden Crops Not Ready", "None of your " .. total .. " garden crops are ready for harvest yet!", "warning")
		else
			self:SendNotification(player, "Garden Harvest Failed", "Found " .. ready .. " ready crops but couldn't harvest any from your garden!", "error")
		end
	end
end

-- ========== GARDEN MUTATION INTEGRATION ==========

function CropCreation:HarvestMutatedGardenCrop(player, gardenSpotModel, mutationResult)
	print("🧬 CropCreation: Harvesting mutated garden crop")
	-- Delegate to mutation system if available
	if MutationSystem and MutationSystem.HarvestMutation then
		return MutationSystem:HarvestMutation(player, gardenSpotModel, mutationResult)
	else
		-- Fallback to normal harvest
		return self:HarvestCrop(player, gardenSpotModel)
	end
end

-- ========== EXISTING METHODS (keeping all original functionality) ==========

-- Include all the existing methods from the original CropCreation.lua
-- These are the same as before, just updated for garden compatibility

function CropCreation:CheckPlantingCooldowns(player, gardenSpotModel)
	local userId = player.UserId
	local spotId = tostring(gardenSpotModel)
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

	-- More reasonable remote event cooldown (500ms)
	if timeSinceLastRemote < 0.5 then
		-- Track spam attempts
		self.SpamAttempts[remoteKey] = (self.SpamAttempts[remoteKey] or 0) + 1

		-- Only warn after multiple rapid attempts
		if self.SpamAttempts[remoteKey] > 2 then
			warn("🚨 CropCreation: Garden planting spam detected for " .. player.Name .. 
				" (attempt " .. self.SpamAttempts[remoteKey] .. ", last: " .. 
				math.round(timeSinceLastRemote * 1000) .. "ms ago)")
		else
			print("⚠️ CropCreation: Rapid garden planting attempt " .. self.SpamAttempts[remoteKey] .. 
				" for " .. player.Name .. " (" .. math.round(timeSinceLastRemote * 1000) .. "ms ago)")
		end

		return false
	end

	-- Reset spam counter on successful timing
	self.SpamAttempts[remoteKey] = 0
	self.RemoteEventCooldowns[remoteKey] = currentTime

	-- Check spot-specific planting cooldown
	local plantingKey = userId .. "_" .. spotId
	local lastPlantTime = self.PlantingCooldowns[plantingKey] or 0
	local timeSinceLastPlant = currentTime - lastPlantTime

	-- More reasonable spot cooldown (1 second)
	if timeSinceLastPlant < 1.0 then
		print("⏱️ CropCreation: Garden spot cooldown active for " .. player.Name .. 
			" (" .. math.round(timeSinceLastPlant * 1000) .. "ms ago)")
		return false
	end

	self.PlantingCooldowns[plantingKey] = currentTime

	print("✅ CropCreation: Garden cooldown check passed for " .. player.Name)
	return true
end

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

function CropCreation:SendGardenHarvestSuccessNotification(player, cropInfo, yield)
	local rarityName = ItemConfig.RaritySystem and ItemConfig.RaritySystem[cropInfo.rarity] 
		and ItemConfig.RaritySystem[cropInfo.rarity].name or cropInfo.rarity
	local rarityEmoji = cropInfo.rarity == "legendary" and "👑" or 
		cropInfo.rarity == "epic" and "💜" or 
		cropInfo.rarity == "rare" and "✨" or 
		cropInfo.rarity == "uncommon" and "💚" or "⚪"

	local message = "Harvested " .. yield .. "x " .. rarityEmoji .. " " .. rarityName .. " " .. cropInfo.cropData.name .. " from your garden!"
	self:SendNotification(player, "🌾 Garden Crop Harvested!", message, "success")
end

-- ========== LEGACY COMPATIBILITY ==========

-- These functions maintain compatibility with existing code that expects plot-based methods
function CropCreation:IsPlotEmpty(plotModel)
	-- Check if this is a garden spot
	local isGardenSpot = plotModel:GetAttribute("IsGardenSpot")
	if isGardenSpot then
		return self:IsGardenSpotEmpty(plotModel)
	end

	-- Legacy plot logic (for backward compatibility)
	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			return false
		end
	end

	local isEmptyAttr = plotModel:GetAttribute("IsEmpty")
	if isEmptyAttr == false then
		return false
	end

	local plantType = plotModel:GetAttribute("PlantType")
	if plantType and plantType ~= "" then
		return false
	end

	local growthStage = plotModel:GetAttribute("GrowthStage")
	if growthStage and growthStage > 0 then
		return false
	end

	return true
end

function CropCreation:ClearPlot(plotModel)
	-- Check if this is a garden spot
	local isGardenSpot = plotModel:GetAttribute("IsGardenSpot")
	if isGardenSpot then
		return self:ClearGardenSpot(plotModel)
	end

	-- Legacy plot clearing logic
	print("🧹 CropCreation: Clearing legacy plot: " .. plotModel.Name)

	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			child:Destroy()
		end
	end

	plotModel:SetAttribute("IsEmpty", true)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("SeedType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", 0)
	plotModel:SetAttribute("Rarity", "common")
	plotModel:SetAttribute("IsMutation", false)
	plotModel:SetAttribute("MutationType", "")

	local plotId = tostring(plotModel)
	if self.GrowthTimers[plotId] then
		self.GrowthTimers[plotId]:Disconnect()
		self.GrowthTimers[plotId] = nil
	end
end

function CropCreation:GetPlotOwner(plotModel)
	-- Check if this is a garden spot
	local isGardenSpot = plotModel:GetAttribute("IsGardenSpot")
	if isGardenSpot then
		return self:GetGardenSpotOwner(plotModel)
	end

	-- Legacy plot owner logic
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

print("CropCreation: ✅ Garden-integrated crop creation module loaded successfully")

return CropCreation