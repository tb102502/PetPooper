-- ADD this comprehensive debug script to ServerScriptService
-- Place as: ServerScriptService/GrowthDebugComprehensive.server.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("=== COMPREHENSIVE GROWTH DEBUGGER ACTIVE ===")

local function ForceCompleteCrop(playerName, spotName)
	print("🔧 Force completing crop for " .. playerName .. " in " .. (spotName or "first spot"))
	
	local garden = workspace:FindFirstChild("Garden")
	if not garden then
		print("❌ Garden not found")
		return false
	end
	
	local region = garden:FindFirstChild(playerName .. "_GardenRegion")
	if not region then
		print("❌ Garden region not found for " .. playerName)
		return false
	end
	
	local plantingSpots = region:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		print("❌ PlantingSpots not found")
		return false
	end
	
	-- Find the spot
	local targetSpot = nil
	if spotName then
		targetSpot = plantingSpots:FindFirstChild(spotName)
	else
		-- Find first non-empty spot
		for _, spot in pairs(plantingSpots:GetChildren()) do
			if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
				local isEmpty = spot:GetAttribute("IsEmpty")
				if not isEmpty then
					targetSpot = spot
					break
				end
			end
		end
	end
	
	if not targetSpot then
		print("❌ No target spot found")
		return false
	end
	
	-- Force complete the crop
	local cropType = targetSpot:GetAttribute("PlantType") or "unknown"
	local currentStage = targetSpot:GetAttribute("GrowthStage") or 0
	
	print("🔧 Force completing " .. cropType .. " in " .. targetSpot.Name)
	print("  Current stage: " .. currentStage)
	
	-- Set to ready stage
	targetSpot:SetAttribute("GrowthStage", 4)
	
	-- Update visual if possible
	if _G.CropVisual then
		local success, error = pcall(function()
			local rarity = targetSpot:GetAttribute("Rarity") or "common"
			return _G.CropVisual:UpdateCropStage(targetSpot, cropType, rarity, "ready", 4)
		end)
		
		if success then
			print("✅ Visual updated successfully")
		else
			print("❌ Visual update failed: " .. tostring(error))
		end
	end
	
	-- FIXED: Clean up any existing timer using safe method
	if _G.CropCreation and _G.CropCreation.CleanupGrowthTimer then
		local success = pcall(function()
			_G.CropCreation:CleanupGrowthTimer(targetSpot)
		end)
		
		if success then
			print("✅ Timer cleaned up safely")
		else
			print("⚠️ Timer cleanup had issues, but continuing")
		end
	end
	
	print("✅ Crop force completed - should now be harvestable")
	return true
end

-- ALSO ADD this safe ID generator function to any debug script that needs it:

local function GenerateSafeSpotId(gardenSpotModel)
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

-- REPLACE any monitoring function that checks timers:

local function MonitorAllCrops()
	spawn(function()
		while true do
			wait(2) -- Check every 2 seconds
			
			local garden = workspace:FindFirstChild("Garden")
			if garden then
				for _, region in pairs(garden:GetChildren()) do
					if region:IsA("Model") and region.Name:find("_GardenRegion") then
						local playerName = region.Name:gsub("_GardenRegion", "")
						local plantingSpots = region:FindFirstChild("PlantingSpots")
						
						if plantingSpots then
							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									local isEmpty = spot:GetAttribute("IsEmpty")
									if not isEmpty then
										-- Found a growing crop - debug it
										local cropType = spot:GetAttribute("PlantType") or "unknown"
										local seedType = spot:GetAttribute("SeedType") or "unknown"
										local growthStage = spot:GetAttribute("GrowthStage") or 0
										local plantedTime = spot:GetAttribute("PlantedTime") or 0
										local rarity = spot:GetAttribute("Rarity") or "common"
										
										local age = os.time() - plantedTime
										
										-- Get expected grow time
										local expectedGrowTime = 300 -- default
										if _G.ItemConfig and _G.ItemConfig.ShopItems[seedType] then
											local seedData = _G.ItemConfig.ShopItems[seedType]
											if seedData.farmingData and seedData.farmingData.growTime then
												expectedGrowTime = seedData.farmingData.growTime
											end
										end
										
										-- Check if it should be ready
										local shouldBeReady = age >= expectedGrowTime
										local isReady = growthStage >= 4
										
										-- Only log if there's an issue or if it just became ready
										if shouldBeReady and not isReady then
											print("🚨 STUCK CROP DETECTED:")
											print("  Player: " .. playerName)
											print("  Spot: " .. spot.Name)
											print("  Crop: " .. cropType .. " (" .. seedType .. ")")
											print("  Age: " .. age .. "s (expected: " .. expectedGrowTime .. "s)")
											print("  Growth Stage: " .. growthStage .. " (should be 4+)")
											print("  Rarity: " .. rarity)
											
											-- FIXED: Check if timer still exists using safe method
											if _G.CropCreation and _G.CropCreation.GrowthTimers then
												local spotId = GenerateSafeSpotId(spot)
												local hasTimer = _G.CropCreation.GrowthTimers[spotId] ~= nil
												print("  Has Timer: " .. tostring(hasTimer))
											end
											
											-- Check for crop model
											local cropModel = spot:FindFirstChild("CropModel")
											print("  Has CropModel: " .. tostring(cropModel ~= nil))
											
											print("  ---")
										elseif isReady and age >= expectedGrowTime then
											-- Crop is ready - this is good (only log occasionally)
											if math.random() < 0.1 then -- 10% chance to log ready crops
												print("✅ READY CROP: " .. playerName .. "'s " .. cropType .. " in " .. spot.Name .. " (age: " .. age .. "s)")
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
	end)
end
-- Detailed crop analysis
local function AnalyzeCrop(playerName, spotName)
	print("🔍 DETAILED CROP ANALYSIS")
	print("Player: " .. playerName)
	print("Spot: " .. (spotName or "first growing spot"))

	local garden = workspace:FindFirstChild("Garden")
	if not garden then
		print("❌ Garden not found")
		return
	end

	local region = garden:FindFirstChild(playerName .. "_GardenRegion")
	if not region then
		print("❌ Garden region not found")
		return
	end

	local plantingSpots = region:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		print("❌ PlantingSpots not found")
		return
	end

	-- Find the spot
	local targetSpot = nil
	if spotName then
		targetSpot = plantingSpots:FindFirstChild(spotName)
	else
		-- Find first non-empty spot
		for _, spot in pairs(plantingSpots:GetChildren()) do
			if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
				local isEmpty = spot:GetAttribute("IsEmpty")
				if not isEmpty then
					targetSpot = spot
					break
				end
			end
		end
	end

	if not targetSpot then
		print("❌ No target spot found")
		return
	end

	print("\n=== SPOT ANALYSIS ===")
	print("Spot Name: " .. targetSpot.Name)
	print("Model exists: " .. tostring(targetSpot ~= nil))
	print("Parent exists: " .. tostring(targetSpot.Parent ~= nil))

	-- Check all attributes
	print("\n=== ATTRIBUTES ===")
	local attributes = {
		"IsEmpty", "PlantType", "SeedType", "GrowthStage", 
		"PlantedTime", "Rarity", "IsMutation", "MutationType"
	}

	for _, attr in ipairs(attributes) do
		local value = targetSpot:GetAttribute(attr)
		print(attr .. ": " .. tostring(value))
	end

	-- Calculate expected vs actual
	local plantedTime = targetSpot:GetAttribute("PlantedTime") or 0
	local currentTime = os.time()
	local age = currentTime - plantedTime
	local seedType = targetSpot:GetAttribute("SeedType")

	print("\n=== TIME ANALYSIS ===")
	print("Planted time: " .. plantedTime)
	print("Current time: " .. currentTime)
	print("Age: " .. age .. " seconds")

	-- Get expected grow time
	local expectedGrowTime = 300
	if seedType and _G.ItemConfig then
		local seedData = _G.ItemConfig.ShopItems[seedType]
		if seedData and seedData.farmingData then
			expectedGrowTime = seedData.farmingData.growTime or 300
		end
	end

	print("Expected grow time: " .. expectedGrowTime .. " seconds")
	print("Should be ready: " .. tostring(age >= expectedGrowTime))

	-- Check timer status
	print("\n=== TIMER STATUS ===")
	if _G.CropCreation and _G.CropCreation.GrowthTimers then
		local spotId = targetSpot:GetDebugId() or tostring(targetSpot)
		local timer = _G.CropCreation.GrowthTimers[spotId]
		print("Timer exists: " .. tostring(timer ~= nil))
		print("Spot ID: " .. spotId)

		-- Count total active timers
		local totalTimers = 0
		for id, t in pairs(_G.CropCreation.GrowthTimers) do
			if t then
				totalTimers = totalTimers + 1
			end
		end
		print("Total active timers: " .. totalTimers)
	else
		print("CropCreation or GrowthTimers not available")
	end

	-- Check visual model
	print("\n=== VISUAL MODEL ===")
	local cropModel = targetSpot:FindFirstChild("CropModel")
	if cropModel then
		print("CropModel exists: true")
		print("CropModel name: " .. cropModel.Name)
		print("PrimaryPart exists: " .. tostring(cropModel.PrimaryPart ~= nil))

		-- Check click detectors
		local clickDetectors = 0
		for _, obj in pairs(cropModel:GetDescendants()) do
			if obj:IsA("ClickDetector") then
				clickDetectors = clickDetectors + 1
			end
		end
		print("Click detectors: " .. clickDetectors)
	else
		print("CropModel exists: false")
	end

	print("\n=== MODULE STATUS ===")
	print("CropCreation available: " .. tostring(_G.CropCreation ~= nil))
	print("CropVisual available: " .. tostring(_G.CropVisual ~= nil))
	print("GameCore available: " .. tostring(_G.GameCore ~= nil))
	print("ItemConfig available: " .. tostring(_G.ItemConfig ~= nil))

	print("\n===============================")
end

-- Global debug functions
_G.MonitorCrops = MonitorAllCrops
_G.ForceComplete = ForceCompleteCrop
_G.AnalyzeCrop = AnalyzeCrop

_G.FixStuckCrops = function(playerName)
	print("🔧 Attempting to fix all stuck crops for " .. playerName)

	local garden = workspace:FindFirstChild("Garden")
	if not garden then return end

	local region = garden:FindFirstChild(playerName .. "_GardenRegion")
	if not region then return end

	local plantingSpots = region:FindFirstChild("PlantingSpots")
	if not plantingSpots then return end

	local fixedCount = 0

	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			local isEmpty = spot:GetAttribute("IsEmpty")
			if not isEmpty then
				local plantedTime = spot:GetAttribute("PlantedTime") or 0
				local age = os.time() - plantedTime
				local seedType = spot:GetAttribute("SeedType")

				-- Get expected grow time
				local expectedGrowTime = 300
				if seedType and _G.ItemConfig and _G.ItemConfig.ShopItems[seedType] then
					local seedData = _G.ItemConfig.ShopItems[seedType]
					if seedData.farmingData then
						expectedGrowTime = seedData.farmingData.growTime or 300
					end
				end

				-- If crop should be ready but isn't
				local growthStage = spot:GetAttribute("GrowthStage") or 0
				if age >= expectedGrowTime and growthStage < 4 then
					print("🔧 Fixing stuck crop in " .. spot.Name)
					ForceCompleteCrop(playerName, spot.Name)
					fixedCount = fixedCount + 1
				end
			end
		end
	end

	print("✅ Fixed " .. fixedCount .. " stuck crops")
end

-- Admin commands
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/analyzecrop" then
				local targetPlayer = args[2] or player.Name
				local spotName = args[3]
				AnalyzeCrop(targetPlayer, spotName)

			elseif command == "/forcecomplete" then
				local targetPlayer = args[2] or player.Name
				local spotName = args[3]
				ForceCompleteCrop(targetPlayer, spotName)

			elseif command == "/fixstuck" then
				local targetPlayer = args[2] or player.Name
				_G.FixStuckCrops(targetPlayer)

			elseif command == "/startmonitor" then
				MonitorAllCrops()
				print("✅ Started continuous crop monitoring")

			elseif command == "/debughelp" then
				print("🔧 COMPREHENSIVE DEBUG COMMANDS:")
				print("  /analyzecrop [player] [spot] - Detailed crop analysis")
				print("  /forcecomplete [player] [spot] - Force complete a crop")
				print("  /fixstuck [player] - Fix all stuck crops for player")
				print("  /startmonitor - Start continuous monitoring")
				print("  /debughelp - Show this help")
			end
		end
	end)
end)

-- Start monitoring automatically
MonitorAllCrops()

print("🔧 Comprehensive Growth Debugger loaded!")
print("Available commands: /analyzecrop, /forcecomplete, /fixstuck, /startmonitor, /debughelp")