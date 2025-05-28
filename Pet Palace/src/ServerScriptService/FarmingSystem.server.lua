-- FarmingSystem.server.lua
-- Complete farming/crop growing system

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

	-- Create farming plots if they don't exist
	for i = 1, 20 do -- 20 farming plots
		local plotName = "Plot" .. i
		local plot = farmingArea:FindFirstChild(plotName)
		if not plot then
			plot = self:CreateFarmPlot(plotName, i)
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

-- Create a farming plot
function GameCore:CreateFarmPlot(plotNumber)
	-- FIXED: Ensure plotNumber is a valid number
	plotNumber = tonumber(plotNumber) or 1

	local plotModel = Instance.new("Model")
	plotModel.Name = "FarmPlot_" .. plotNumber

	-- Create soil base
	local soil = Instance.new("Part")
	soil.Name = "Soil"
	soil.Size = Vector3.new(8, 1, 8)

	-- FIXED: Better plot positioning logic
	local plotsPerRow = 5
	local plotSpacing = 12
	local row = math.floor((plotNumber - 1) / plotsPerRow)
	local col = (plotNumber - 1) % plotsPerRow

	-- Calculate position with safe defaults
	local xPos = col * plotSpacing
	local zPos = row * plotSpacing
	local yPos = 0.5

	soil.Position = Vector3.new(xPos, yPos, zPos)
	soil.Anchored = true
	soil.CanCollide = true
	soil.Material = Enum.Material.Ground
	soil.Color = Color3.fromRGB(101, 67, 33)
	soil.Parent = plotModel

	-- Add plot border
	local border = Instance.new("Part")
	border.Name = "Border"
	border.Size = Vector3.new(8.5, 0.2, 8.5)
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
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)
	plotModel:SetAttribute("TimeToGrow", 0)

	return plotModel
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

	local plot = farmingArea:FindFirstChild("Plot" .. plotNumber)
	if not plot then return end

	-- Check if plot is empty
	if not plot:GetAttribute("IsEmpty") then
		self:SendNotification(player, "Plot Occupied", "This plot already has a crop growing!", "warning")
		return
	end

	-- Get seed config
	local ItemConfig = require(script.Parent.Config.ItemConfig)
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

	-- Position on top of plot
	cropPart.Position = plot.Position + Vector3.new(0, plot.Size.Y/2 + cropPart.Size.Y/2, 0)

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

	local plot = farmingArea:FindFirstChild("Plot" .. plotNumber)
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