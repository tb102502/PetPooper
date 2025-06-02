-- FarmingSystem.server.lua
-- Complete farming/crop growing system with custom plot positioning

local function WaitForGameCore(scriptName, maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	print(scriptName .. ": Waiting for GameCore...")

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	if not _G.GameCore then
		error(scriptName .. ": GameCore not found after " .. maxWaitTime .. " seconds! Check SystemInitializer.")
	end

	print(scriptName .. ": GameCore found successfully!")
	return _G.GameCore
end

-- Usage in your scripts:
local GameCore = WaitForGameCore("FarmingSystem") -- Replace with actual script name

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

print("=== FARMING SYSTEM STARTING ===")

-- CUSTOM PLOT POSITIONS CONFIGURATION
-- Add or modify positions as needed for each plot
local PLOT_POSITIONS = {
	[1] = Vector3.new(-366.118, -1.593, 75.731),      -- Plot 1 position
	[2] = Vector3.new(-400.768, -1.593, 75.731),     -- Plot 2 position
	[3] = Vector3.new(-366.118, -1.593, 109.531),     -- Plot 3 position
	[4] = Vector3.new(-400.768, -1.593, 109.381),     -- Plot 4 position
	[5] = Vector3.new(-400.768, -1.593, 142.681),     -- Plot 5 position
	[6] = Vector3.new(-366.118, -1.593, 142.681),     -- Plot 6 position
	[7] = Vector3.new(-366.118, -1.593, 176.481),    -- Plot 7 position
	[8] = Vector3.new(-400.768, -1.593, 176.331),    -- Plot 8 position
	[9] = Vector3.new(45, 0.5, 15),    -- Plot 9 position
	[10] = Vector3.new(60, 0.5, 15),   -- Plot 10 position
	[11] = Vector3.new(0, 0.5, 30),    -- Plot 11 position
	[12] = Vector3.new(15, 0.5, 30),   -- Plot 12 position
	[13] = Vector3.new(30, 0.5, 30),   -- Plot 13 position
	[14] = Vector3.new(45, 0.5, 30),   -- Plot 14 position
	[15] = Vector3.new(60, 0.5, 30),   -- Plot 15 position
	[16] = Vector3.new(0, 0.5, 45),    -- Plot 16 position
	[17] = Vector3.new(15, 0.5, 45),   -- Plot 17 position
	[18] = Vector3.new(30, 0.5, 45),   -- Plot 18 position
	[19] = Vector3.new(45, 0.5, 45),   -- Plot 19 position
	[20] = Vector3.new(60, 0.5, 45),   -- Plot 20 position
}

-- Enhanced farming system for GameCore
function GameCore:InitializeFarmingSystem()
	print("GameCore: Initializing farming system...")

	-- Setup farm areas in workspace
	local workspace = game:GetService("Workspace")
	local farmingArea = workspace:FindFirstChild("FarmingArea")
	if not farmingArea then
		farmingArea = Instance.new("Folder")
		farmingArea.Name = "FarmingArea"
		farmingArea.Parent = workspace
	end

	-- Create farming plots with custom positions
	for plotNumber, position in pairs(PLOT_POSITIONS) do
		local plotName = "Plot" .. plotNumber
		local plot = farmingArea:FindFirstChild(plotName)
		if not plot then
			plot = self:CreateFarmPlot(plotNumber, position)
			plot.Parent = farmingArea
		end
	end

	-- Setup farming remote events
	self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotNumber, seedType)
		self:PlantSeed(player, plotNumber, seedType)
	end)

	self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotNumber)
		self:HarvestCrop(player, plotNumber)
	end)

	print("GameCore: Farming system initialized with crop growing!")
end

-- Create a farming plot at a specific position
function GameCore:CreateFarmPlot(plotNumber, customPosition)
	-- FIXED: Ensure plotNumber is a valid number
	plotNumber = tonumber(plotNumber) or 1

	local plotModel = Instance.new("Model")
	plotModel.Name = "FarmPlot_" .. plotNumber

	-- Create soil base
	local soil = Instance.new("Part")
	soil.Name = "Soil"
	soil.Size = Vector3.new(34.375, 1, 32.975)

	-- Use custom position if provided, otherwise use default positioning
	if customPosition then
		soil.Position = customPosition
		print("GameCore: Creating Plot " .. plotNumber .. " at custom position: " .. tostring(customPosition))
	else
		-- Fallback to automatic grid positioning if no custom position provided
		local plotsPerRow = 5
		local plotSpacing = 12
		local row = math.floor((plotNumber - 1) / plotsPerRow)
		local col = (plotNumber - 1) % plotsPerRow

		local xPos = col * plotSpacing
		local zPos = row * plotSpacing
		local yPos = 0.5

		soil.Position = Vector3.new(xPos, yPos, zPos)
		print("GameCore: Creating Plot " .. plotNumber .. " at default position: " .. tostring(soil.Position))
	end

	soil.Anchored = true
	soil.CanCollide = true
	soil.Material = Enum.Material.Ground
	soil.Color = Color3.fromRGB(101, 67, 33)
	soil.Parent = plotModel

	-- Add plot border
	local border = Instance.new("Part")
	border.Name = "Border"
	border.Size = Vector3.new(2, 1, 2)
	border.Position = soil.Position + Vector3.new(0, 0.6, 0)
	border.Anchored = true
	border.CanCollide = false
	border.Material = Enum.Material.Wood
	border.Color = Color3.fromRGB(160, 100, 50)
	border.Parent = plotModel

	-- Add plot label
	local plotGui = Instance.new("SurfaceGui")
	plotGui.Face = Enum.NormalId.Top
	plotGui.Parent = soil

	local plotLabel = Instance.new("TextLabel")
	plotLabel.Size = UDim2.new(1, 0, 1, 0)
	plotLabel.BackgroundTransparency = 1
	plotLabel.Text = "Plot " .. plotNumber
	plotLabel.TextColor3 = Color3.new(1, 1, 1)
	plotLabel.TextScaled = true
	plotLabel.Font = Enum.Font.GothamBold
	plotLabel.TextStrokeTransparency = 0
	plotLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	plotLabel.Parent = plotGui

	plotModel.PrimaryPart = soil

	-- Set plot attributes with safe defaults
	plotModel:SetAttribute("PlotID", plotNumber)
	plotModel:SetAttribute("PlotNumber", plotNumber) -- Added for consistency
	plotModel:SetAttribute("IsEmpty", true) -- Changed to match the logic used elsewhere
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("CropType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)
	plotModel:SetAttribute("TimeToGrow", 0)

	return plotModel
end

-- Function to easily add or update plot positions
function GameCore:SetPlotPosition(plotNumber, newPosition)
	PLOT_POSITIONS[plotNumber] = newPosition
	print("GameCore: Updated Plot " .. plotNumber .. " position to: " .. tostring(newPosition))

	-- If the plot already exists, update its position
	local farmingArea = workspace:FindFirstChild("FarmingArea")
	if farmingArea then
		local existingPlot = farmingArea:FindFirstChild("FarmPlot_" .. plotNumber)
		if existingPlot then
			local soil = existingPlot:FindFirstChild("Soil")
			local border = existingPlot:FindFirstChild("Border")

			if soil then
				soil.Position = newPosition
				if border then
					border.Position = newPosition + Vector3.new(0, 0.6, 0)
				end

				-- Update crop position if there's a crop
				local cropModel = existingPlot:FindFirstChild("CropModel")
				if cropModel then
					local crop = cropModel:FindFirstChild("Crop")
					if crop then
						crop.Position = newPosition + Vector3.new(0, soil.Size.Y/2 + crop.Size.Y/2, 0)
					end
				end
			end
		end
	end
end

-- Function to get current plot positions (for debugging/reference)
function GameCore:GetPlotPositions()
	return PLOT_POSITIONS
end

-- Plant a seed
function GameCore:PlantSeed(player, plotNumber, seedType)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Check if player has the seed
	local seedInventory = playerData.farming.inventory[seedType .. "_seeds"]
	if not seedInventory or seedInventory <= 0 then
		self:SendNotification(player, "No Seeds", "You don't have any " .. seedType .. " seeds!", "error")
		return
	end

	-- Find the plot
	local farmingArea = workspace:FindFirstChild("FarmingArea")
	if not farmingArea then return end

	local plot = farmingArea:FindFirstChild("FarmPlot_" .. plotNumber)
	if not plot then return end

	-- Check if plot is empty
	if not plot:GetAttribute("IsEmpty") then
		self:SendNotification(player, "Plot Occupied", "This plot already has a crop growing!", "warning")
		return
	end

	-- Get seed config
	local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
	local seedConfig = ItemConfig.Seeds[seedType .. "_seeds"]
	if not seedConfig then return end

	-- Plant the seed
	playerData.farming.inventory[seedType .. "_seeds"] = playerData.farming.inventory[seedType .. "_seeds"] - 1

	plot:SetAttribute("IsEmpty", false)
	plot:SetAttribute("CropType", seedType)
	plot:SetAttribute("PlantTime", os.time())
	plot:SetAttribute("GrowthStage", 1)
	plot:SetAttribute("GrowTime", seedConfig.growTime)

	-- Create crop model
	self:CreateCropModel(plot, seedType, 1)

	-- Start growth timer
	self:StartCropGrowth(plot, seedConfig.growTime)

	self:SendNotification(player, "Seed Planted!", "Planted " .. seedConfig.name .. " in Plot " .. plotNumber, "success")

	-- Update player data
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("GameCore: " .. player.Name .. " planted " .. seedType .. " in plot " .. plotNumber)
end

-- Create crop model based on growth stage
function GameCore:CreateCropModel(plot, cropType, stage)
	-- Remove existing crop model
	local existingCrop = plot:FindFirstChild("CropModel")
	if existingCrop then
		existingCrop:Destroy()
	end

	local cropModel = Instance.new("Model")
	cropModel.Name = "CropModel"
	cropModel.Parent = plot

	-- Create crop based on type and stage
	local cropPart = Instance.new("Part")
	cropPart.Name = "Crop"
	cropPart.Anchored = true
	cropPart.CanCollide = false

	-- Crop grows larger as it matures
	local sizeMultiplier = stage / 4
	cropPart.Size = Vector3.new(2 * sizeMultiplier, 3 * sizeMultiplier, 2 * sizeMultiplier)

	-- Position on top of plot soil
	local soil = plot:FindFirstChild("Soil")
	if soil then
		cropPart.Position = soil.Position + Vector3.new(0, soil.Size.Y/2 + cropPart.Size.Y/2, 0)
	end

	-- Set crop appearance based on type
	if cropType == "carrot" then
		cropPart.Color = Color3.fromRGB(255, 165, 0) -- Orange
		cropPart.Shape = Enum.PartType.Cylinder
	elseif cropType == "corn" then
		cropPart.Color = Color3.fromRGB(255, 255, 0) -- Yellow
		cropPart.Shape = Enum.PartType.Block
	elseif cropType == "strawberry" then
		cropPart.Color = Color3.fromRGB(255, 0, 0) -- Red
		cropPart.Shape = Enum.PartType.Ball
	elseif cropType == "golden_fruit" then
		cropPart.Color = Color3.fromRGB(255, 215, 0) -- Gold
		cropPart.Material = Enum.Material.Neon
		cropPart.Shape = Enum.PartType.Ball
	else
		cropPart.Color = Color3.fromRGB(0, 255, 0) -- Green default
	end

	cropPart.Parent = cropModel

	-- Add growth stage indicator
	if stage >= 4 then
		-- Fully grown - add harvest hint
		local harvestGui = Instance.new("BillboardGui")
		harvestGui.Size = UDim2.new(2, 0, 1, 0)
		harvestGui.StudsOffset = Vector3.new(0, 2, 0)
		harvestGui.Parent = cropPart

		local harvestLabel = Instance.new("TextLabel")
		harvestLabel.Size = UDim2.new(1, 0, 1, 0)
		harvestLabel.BackgroundTransparency = 1
		harvestLabel.Text = "🌾 Ready to Harvest!"
		harvestLabel.TextColor3 = Color3.new(0, 1, 0)
		harvestLabel.TextScaled = true
		harvestLabel.Font = Enum.Font.SourceSansBold
		harvestLabel.Parent = harvestGui

		-- Add glow effect
		cropPart.Material = Enum.Material.Neon

		-- Make it clickable for harvest
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = cropPart

		clickDetector.MouseClick:Connect(function(player)
			local plotNumber = plot:GetAttribute("PlotNumber")
			self:HarvestCrop(player, plotNumber)
		end)
	end
end

-- Start crop growth process
function GameCore:StartCropGrowth(plot, totalGrowTime)
	local plotNumber = plot:GetAttribute("PlotNumber")
	local cropType = plot:GetAttribute("CropType")

	-- Growth stages: 1=planted, 2=sprouting, 3=growing, 4=ready
	local stageTime = totalGrowTime / 4

	spawn(function()
		for stage = 2, 4 do
			wait(stageTime)

			-- Check if plot still exists and has the same crop
			if plot and plot.Parent and plot:GetAttribute("CropType") == cropType then
				plot:SetAttribute("GrowthStage", stage)
				self:CreateCropModel(plot, cropType, stage)
				print("FarmingSystem: Plot " .. plotNumber .. " " .. cropType .. " reached stage " .. stage)
			else
				break
			end
		end
	end)
end

-- Harvest a crop
function GameCore:HarvestCrop(player, plotNumber)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Find the plot
	local farmingArea = workspace:FindFirstChild("FarmingArea")
	if not farmingArea then return end

	local plot = farmingArea:FindFirstChild("FarmPlot_" .. plotNumber)
	if not plot then return end

	-- Check if plot has a fully grown crop
	local growthStage = plot:GetAttribute("GrowthStage")
	local cropType = plot:GetAttribute("CropType")

	if plot:GetAttribute("IsEmpty") or growthStage < 4 then
		self:SendNotification(player, "Not Ready", "This crop isn't ready for harvest yet!", "warning")
		return
	end

	-- Get crop config
	local ItemConfig = require(script.Parent.Config.ItemConfig)
	local cropConfig = ItemConfig.Crops[cropType]
	local seedConfig = ItemConfig.Seeds[cropType .. "_seeds"]

	if not cropConfig or not seedConfig then return end

	-- Give rewards
	local yieldAmount = seedConfig.yieldAmount or 1
	local coinReward = seedConfig.coinReward or 0

	-- Add crops to inventory
	if not playerData.farming.inventory[cropType] then
		playerData.farming.inventory[cropType] = 0
	end
	playerData.farming.inventory[cropType] = playerData.farming.inventory[cropType] + yieldAmount

	-- Add coins
	playerData.coins = playerData.coins + coinReward
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + coinReward
	playerData.stats.cropsHarvested = playerData.stats.cropsHarvested + 1

	-- Clear the plot
	plot:SetAttribute("IsEmpty", true)
	plot:SetAttribute("CropType", "")
	plot:SetAttribute("PlantTime", 0)
	plot:SetAttribute("GrowthStage", 0)

	-- Remove crop model
	local cropModel = plot:FindFirstChild("CropModel")
	if cropModel then
		cropModel:Destroy()
	end

	-- Update leaderstats
	self:UpdatePlayerLeaderstats(player)

	self:SendNotification(player, "Crop Harvested!", 
		"Harvested " .. yieldAmount .. "x " .. cropConfig.name .. " (+" .. coinReward .. " coins)", "success")

	-- Update player data
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("GameCore: " .. player.Name .. " harvested " .. cropType .. " from plot " .. plotNumber)
end

-- Initialize the system
GameCore:InitializeFarmingSystem()

print("=== FARMING SYSTEM READY ===")