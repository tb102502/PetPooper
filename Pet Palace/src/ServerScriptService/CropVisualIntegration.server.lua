--[[
    CropVisualIntegration.server.lua - Visual System Integration
    Place in: ServerScriptService/CropVisualIntegration.server.lua
    
    PURPOSE:
    ✅ Integrates CropVisualManager with existing farming system
    ✅ Provides simple API for other scripts to use
    ✅ Handles existing crop conversion to new visual system
    ✅ Manages visual updates during farming operations
    ✅ Easy-to-use functions for GameCore integration
]]

local CropVisualIntegration = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Wait for dependencies
local function WaitForDependencies()
	while not _G.GameCore do
		wait(0.5)
	end

	while not _G.CropVisualManager do
		wait(0.5)
	end

	return _G.GameCore, _G.CropVisualManager
end

local GameCore, CropVisualManager = WaitForDependencies()

print("CropVisualIntegration: Starting integration with existing farming system...")

-- ========== INTEGRATION API ==========

-- Easy function to plant a crop with visuals
function CropVisualIntegration:PlantCropWithVisuals(plotModel, seedId, rarity, playerData)
	rarity = rarity or "common"

	-- Get crop type from seed
	local cropType = seedId:gsub("_seeds", "")

	print("🌱 PlantCropWithVisuals: " .. cropType .. " (" .. rarity .. ")")

	-- Create the visual immediately
	local cropVisual = CropVisualManager:ReplaceCropVisual(plotModel, cropType, rarity, "planted")

	-- Store crop data on the plot
	if plotModel then
		plotModel:SetAttribute("CropType", cropType)
		plotModel:SetAttribute("CropRarity", rarity)
		plotModel:SetAttribute("GrowthStage", "planted")
		plotModel:SetAttribute("PlantedTime", tick())
		plotModel:SetAttribute("SeedId", seedId)
	end

	return cropVisual
end

-- Update crop growth stage with visuals
function CropVisualIntegration:UpdateCropGrowthStage(plotModel, newStage)
	if not plotModel then return end

	local cropType = plotModel:GetAttribute("CropType")
	local rarity = plotModel:GetAttribute("CropRarity") or "common"

	if cropType then
		print("🌿 UpdateCropGrowthStage: " .. cropType .. " -> " .. newStage)

		-- Update visual
		CropVisualManager:UpdateCropGrowthStage(plotModel, newStage, cropType, rarity)

		-- Update stored data
		plotModel:SetAttribute("GrowthStage", newStage)
		plotModel:SetAttribute("LastGrowthUpdate", tick())
	end
end

-- Harvest crop with visual effects
function CropVisualIntegration:HarvestCropWithVisuals(plotModel)
	if not plotModel then return nil end

	local cropType = plotModel:GetAttribute("CropType")
	local rarity = plotModel:GetAttribute("CropRarity") or "common"
	local growthStage = plotModel:GetAttribute("GrowthStage")

	if not cropType then return nil end

	print("🌾 HarvestCropWithVisuals: " .. cropType .. " (" .. rarity .. ")")

	-- Create harvest effect
	CropVisualManager:OnCropHarvested(plotModel, cropType, rarity)

	-- Clear crop data
	plotModel:SetAttribute("CropType", nil)
	plotModel:SetAttribute("CropRarity", nil)
	plotModel:SetAttribute("GrowthStage", nil)
	plotModel:SetAttribute("PlantedTime", nil)
	plotModel:SetAttribute("SeedId", nil)

	-- Return harvest data for processing
	return {
		cropType = cropType,
		rarity = rarity,
		stage = growthStage
	}
end

-- Convert existing crops to new visual system
function CropVisualIntegration:ConvertExistingCropsToNewVisuals()
	print("CropVisualIntegration: Converting existing crops to new visual system...")

	local convertedCount = 0

	-- Find all farming areas
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return convertedCount end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return convertedCount end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return convertedCount end

	-- Process each player's farm
	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Model") and playerFarm.Name:find("SimpleFarm") then
			local plantingSpots = playerFarm:FindFirstChild("PlantingSpots")
			if plantingSpots then
				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
						self:ConvertSinglePlot(spot)
						convertedCount = convertedCount + 1
					end
				end
			end
		end
	end

	print("CropVisualIntegration: Converted " .. convertedCount .. " plots to new visual system")
	return convertedCount
end

-- Convert a single plot to new visual system
function CropVisualIntegration:ConvertSinglePlot(plotModel)
	if not plotModel then return end

	-- Check if plot has existing crop
	local cropId = plotModel:GetAttribute("CropId")
	local growthStage = plotModel:GetAttribute("GrowthStage")
	local rarity = plotModel:GetAttribute("Rarity") or "common"

	if cropId and growthStage then
		print("Converting plot with " .. cropId .. " (" .. growthStage .. ")")

		-- Remove old visual if exists
		local oldVisual = plotModel:FindFirstChild("CropVisual")
		if oldVisual then
			oldVisual:Destroy()
		end

		-- Create new enhanced visual
		local newVisual = CropVisualManager:ReplaceCropVisual(plotModel, cropId, rarity, growthStage)

		-- Update attributes to new system
		plotModel:SetAttribute("CropType", cropId)
		plotModel:SetAttribute("CropRarity", rarity)
	end
end

-- ========== GROWTH MONITORING SYSTEM ==========

function CropVisualIntegration:StartGrowthMonitoring()
	print("CropVisualIntegration: Starting growth monitoring system...")

	spawn(function()
		while true do
			wait(5) -- Check every 5 seconds
			self:CheckAndUpdateGrowingCrops()
		end
	end)
end

function CropVisualIntegration:CheckAndUpdateGrowingCrops()
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	local currentTime = tick()
	local updatedCrops = 0

	-- Check all farming plots
	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Model") and playerFarm.Name:find("SimpleFarm") then
			local plantingSpots = playerFarm:FindFirstChild("PlantingSpots")
			if plantingSpots then
				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
						if self:CheckCropGrowthProgress(spot, currentTime) then
							updatedCrops = updatedCrops + 1
						end
					end
				end
			end
		end
	end

	if updatedCrops > 0 then
		print("CropVisualIntegration: Updated " .. updatedCrops .. " growing crops")
	end
end

function CropVisualIntegration:CheckCropGrowthProgress(plotModel, currentTime)
	local cropType = plotModel:GetAttribute("CropType")
	local currentStage = plotModel:GetAttribute("GrowthStage")
	local plantedTime = plotModel:GetAttribute("PlantedTime")
	local seedId = plotModel:GetAttribute("SeedId")

	if not cropType or not currentStage or not plantedTime or not seedId then
		return false
	end

	-- Get growth data from ItemConfig
	local ItemConfig = nil
	pcall(function()
		ItemConfig = require(ReplicatedStorage:FindFirstChild("ItemConfig"))
	end)

	if not ItemConfig or not ItemConfig.ShopItems[seedId] then
		return false
	end

	local seedData = ItemConfig.ShopItems[seedId]
	local farmingData = seedData.farmingData
	if not farmingData or not farmingData.stages then
		return false
	end

	local elapsedTime = currentTime - plantedTime
	local growTime = farmingData.growTime or 60
	local stages = farmingData.stages

	-- Calculate which stage the crop should be in
	local progressPercent = elapsedTime / growTime
	local stageIndex = 1

	if progressPercent >= 1.0 then
		stageIndex = #stages -- Fully grown
	else
		stageIndex = math.floor(progressPercent * #stages) + 1
		stageIndex = math.min(stageIndex, #stages)
	end

	local targetStage = stages[stageIndex]

	-- Update visual if stage changed
	if targetStage ~= currentStage then
		print("Growth update: " .. cropType .. " " .. currentStage .. " -> " .. targetStage)
		self:UpdateCropGrowthStage(plotModel, targetStage)
		return true
	end

	return false
end

-- ========== RARITY SYSTEM INTEGRATION ==========

function CropVisualIntegration:DetermineRandomRarity(seedId, playerBoosters)
	-- Use ItemConfig rarity system if available
	local ItemConfig = nil
	pcall(function()
		ItemConfig = require(ReplicatedStorage:FindFirstChild("ItemConfig"))
	end)

	if ItemConfig and ItemConfig.GetCropRarity then
		return ItemConfig.GetCropRarity(seedId, playerBoosters)
	end

	-- Fallback random system
	local roll = math.random()

	if playerBoosters and playerBoosters.rarity_booster then
		return "rare" -- Guaranteed rare with booster
	end

	if roll < 0.001 then return "legendary"
	elseif roll < 0.01 then return "epic"
	elseif roll < 0.05 then return "rare"
	elseif roll < 0.25 then return "uncommon"
	else return "common"
	end
end

-- ========== GAMECORE INTEGRATION HOOKS ==========

function CropVisualIntegration:IntegrateWithGameCore()
	print("CropVisualIntegration: Integrating with GameCore...")

	-- Override GameCore planting function if it exists
	if GameCore.PlantSeed then
		local originalPlantSeed = GameCore.PlantSeed

		GameCore.PlantSeed = function(self, player, plotModel, seedId)
			print("Enhanced PlantSeed called for " .. seedId)

			-- Get player data for rarity boosters
			local playerData = GameCore:GetPlayerData(player)
			local boosters = playerData and playerData.activeBoosters or {}

			-- Determine rarity
			local rarity = CropVisualIntegration:DetermineRandomRarity(seedId, boosters)

			-- Call original function
			local success = originalPlantSeed(self, player, plotModel, seedId)

			if success then
				-- Add enhanced visuals
				CropVisualIntegration:PlantCropWithVisuals(plotModel, seedId, rarity, playerData)

				-- Notify player about rarity
				if rarity ~= "common" and GameCore.SendNotification then
					local rarityText = rarity:sub(1,1):upper() .. rarity:sub(2)
					GameCore:SendNotification(player, "🌟 " .. rarityText .. " Crop!", 
						"You planted a " .. rarityText .. " " .. seedId:gsub("_", " ") .. "!", "success")
				end
			end

			return success
		end

		print("CropVisualIntegration: PlantSeed function enhanced!")
	end

	-- Override GameCore harvest function if it exists
	if GameCore.HarvestCrop then
		local originalHarvestCrop = GameCore.HarvestCrop

		GameCore.HarvestCrop = function(self, player, plotModel)
			print("Enhanced HarvestCrop called")

			-- Get harvest data with visuals
			local harvestData = CropVisualIntegration:HarvestCropWithVisuals(plotModel)

			-- Call original function
			local success, rewards = originalHarvestCrop(self, player, plotModel)

			if success and harvestData then
				-- Enhance rewards based on rarity
				if harvestData.rarity ~= "common" then
					local rarityMultiplier = {
						uncommon = 1.2,
						rare = 1.5,
						epic = 2.0,
						legendary = 3.0
					}

					local multiplier = rarityMultiplier[harvestData.rarity] or 1.0
					if rewards and rewards.quantity then
						rewards.quantity = math.floor(rewards.quantity * multiplier)
					end

					-- Notify about rarity bonus
					if GameCore.SendNotification then
						local rarityText = harvestData.rarity:sub(1,1):upper() .. harvestData.rarity:sub(2)
						GameCore:SendNotification(player, "🌟 " .. rarityText .. " Harvest!", 
							"Rarity bonus: +" .. math.floor((multiplier - 1) * 100) .. "% yield!", "success")
					end
				end
			end

			return success, rewards
		end

		print("CropVisualIntegration: HarvestCrop function enhanced!")
	end
end

-- ========== ADMIN COMMANDS ==========

function CropVisualIntegration:SetupAdminCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			-- Replace with your admin username
			if player.Name == "TommySalami311" then
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/convertallfarms" then
					local converted = self:ConvertExistingCropsToNewVisuals()
					print("Admin: Converted " .. converted .. " crops to new visual system")

				elseif command == "/testcropvisuals" then
					-- Create test crops
					local testCrops = {
						{type = "carrot", rarity = "common", stage = "ready"},
						{type = "strawberry", rarity = "rare", stage = "ready"},
						{type = "golden_fruit", rarity = "epic", stage = "ready"},
						{type = "glorious_sunflower", rarity = "legendary", stage = "glorious"}
					}

					for i, crop in ipairs(testCrops) do
						local testCrop = _G.CreateTestCrop(crop.type, crop.rarity, crop.stage)
						if testCrop.PrimaryPart then
							testCrop.PrimaryPart.CFrame = CFrame.new(i * 10, 5, 0)
						end
					end
					print("Admin: Created test crop visuals")

				elseif command == "/testharvest" then
					_G.TestHarvestEffect("glorious_sunflower", "legendary")
					print("Admin: Triggered harvest effect")

				elseif command == "/clearvisuals" then
					-- Remove all test crops
					for _, obj in pairs(workspace:GetChildren()) do
						if obj:IsA("Model") and (obj.Name:find("carrot_") or obj.Name:find("strawberry_") or 
							obj.Name:find("golden_fruit_") or obj.Name:find("glorious_sunflower_")) then
							obj:Destroy()
						end
					end
					print("Admin: Cleared test visuals")

				elseif command == "/forcegrowth" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						-- Force all their crops to ready stage
						local areas = workspace:FindFirstChild("Areas")
						if areas then
							local starterMeadow = areas:FindFirstChild("Starter Meadow")
							if starterMeadow then
								local farmArea = starterMeadow:FindFirstChild("Farm")
								if farmArea then
									local playerFarm = farmArea:FindFirstChild(targetPlayer.Name .. "_SimpleFarm")
									if playerFarm then
										local plantingSpots = playerFarm:FindFirstChild("PlantingSpots")
										if plantingSpots then
											local updatedCount = 0
											for _, spot in pairs(plantingSpots:GetChildren()) do
												if spot:IsA("Model") and spot:GetAttribute("CropType") then
													self:UpdateCropGrowthStage(spot, "ready")
													updatedCount = updatedCount + 1
												end
											end
											print("Admin: Force-grew " .. updatedCount .. " crops for " .. targetPlayer.Name)
										end
									end
								end
							end
						end
					end

				elseif command == "/debugcropvisuals" then
					local areas = workspace:FindFirstChild("Areas")
					if areas then
						local starterMeadow = areas:FindFirstChild("Starter Meadow")
						if starterMeadow then
							local farmArea = starterMeadow:FindFirstChild("Farm")
							if farmArea then
								local totalCrops = 0
								local totalVisuals = 0

								for _, playerFarm in pairs(farmArea:GetChildren()) do
									if playerFarm:IsA("Model") and playerFarm.Name:find("SimpleFarm") then
										local plantingSpots = playerFarm:FindFirstChild("PlantingSpots")
										if plantingSpots then
											for _, spot in pairs(plantingSpots:GetChildren()) do
												if spot:IsA("Model") and spot:GetAttribute("CropType") then
													totalCrops = totalCrops + 1
													if spot:FindFirstChild("CropVisual") then
														totalVisuals = totalVisuals + 1
													end
												end
											end
										end
									end
								end

								print("=== CROP VISUAL DEBUG ===")
								print("Total crops with data: " .. totalCrops)
								print("Total crops with visuals: " .. totalVisuals)
								print("Missing visuals: " .. (totalCrops - totalVisuals))
								print("========================")
							end
						end
					end
				end
			end
		end)
	end)
end

-- ========== INITIALIZATION ==========

function CropVisualIntegration:Initialize()
	print("CropVisualIntegration: Initializing integration system...")

	-- Set up admin commands
	self:SetupAdminCommands()

	-- Start growth monitoring
	self:StartGrowthMonitoring()

	-- Integrate with GameCore
	self:IntegrateWithGameCore()

	-- Convert existing crops after a delay
	spawn(function()
		wait(5) -- Wait for system to stabilize
		self:ConvertExistingCropsToNewVisuals()
	end)

	print("CropVisualIntegration: ✅ Integration system ready!")
end

-- ========== GLOBAL ACCESS ==========

_G.CropVisualIntegration = CropVisualIntegration

-- Convenient global functions
_G.PlantWithVisuals = function(plotModel, seedId, rarity)
	return CropVisualIntegration:PlantCropWithVisuals(plotModel, seedId, rarity)
end

_G.HarvestWithVisuals = function(plotModel)
	return CropVisualIntegration:HarvestCropWithVisuals(plotModel)
end

_G.UpdateGrowthStage = function(plotModel, stage)
	return CropVisualIntegration:UpdateCropGrowthStage(plotModel, stage)
end

-- Initialize the system
CropVisualIntegration:Initialize()

print("=== CROP VISUAL INTEGRATION LOADED ===")
print("🔌 INTEGRATION FEATURES:")
print("  🌱 Enhanced planting with visual effects")
print("  📈 Automatic growth stage monitoring")
print("  🌾 Enhanced harvesting with spectacular effects")
print("  🎨 Automatic conversion of existing crops")
print("  🎯 Rarity system integration")
print("  ⚡ GameCore function enhancement")
print("  🛠️ Admin commands for testing")
print("")
print("🔧 Admin Commands (TYPE IN CHAT):")
print("  /convertallfarms - Convert all existing crops")
print("  /testcropvisuals - Create test crop showcase")
print("  /testharvest - Test harvest effects")
print("  /clearvisuals - Remove test visuals")
print("  /forcegrowth [player] - Force crops to ready")
print("  /debugcropvisuals - Show visual system stats")
print("")
print("📝 Global Functions:")
print("  _G.PlantWithVisuals(plot, seedId, rarity)")
print("  _G.HarvestWithVisuals(plot)")
print("  _G.UpdateGrowthStage(plot, stage)")

return CropVisualIntegration