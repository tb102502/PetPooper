--[[
    FarmPlot.lua - Modular Farm Plot Management System
    Place in: ServerScriptService/Modules/FarmPlot.lua
    
    RESPONSIBILITIES:
    ✅ Farm plot creation and layout management
    ✅ Plot validation and repair systems
    ✅ Plot ownership and access control
    ✅ Farm positioning and spacing
    ✅ Plot state management
    ✅ Farm expansion systems (optional)
]]

local FarmPlot = {}

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references (will be injected)
local GameCore = nil

-- Farm Configuration
FarmPlot.SimpleFarmConfig = {
	basePosition = Vector3.new(-366.118, -2.793, 75.731),
	playerSeparation = Vector3.new(150, 0, 0),
	plotRotation = Vector3.new(0, 0, 0),

	-- Simple farm settings
	gridSize = 10,      -- 10x10 grid = 100 spots
	totalSpots = 100,
	baseSize = Vector3.new(60, 1, 60),
	description = "Full 10x10 farming grid (100 planting spots)",

	-- Visual settings
	spotSize = 3,
	spotSpacing = 5,
	spotColor = Color3.fromRGB(91, 154, 76),
	spotTransparency = 0
}

-- Expandable farm configurations (for future use)
FarmPlot.ExpandableFarmConfigs = {
	[1] = {
		name = "Starter Plot",
		gridSize = 3,
		totalSpots = 9,
		unlockedSpots = 9,
		baseSize = Vector3.new(20, 1, 20)
	},
	[2] = {
		name = "Small Farm",
		gridSize = 5,
		totalSpots = 25,
		unlockedSpots = 25,
		baseSize = Vector3.new(30, 1, 30)
	},
	[3] = {
		name = "Medium Farm", 
		gridSize = 7,
		totalSpots = 49,
		unlockedSpots = 49,
		baseSize = Vector3.new(40, 1, 40)
	},
	[4] = {
		name = "Large Farm",
		gridSize = 9,
		totalSpots = 81,
		unlockedSpots = 81,
		baseSize = Vector3.new(50, 1, 50)
	},
	[5] = {
		name = "Mega Farm",
		gridSize = 10,
		totalSpots = 100,
		unlockedSpots = 100,
		baseSize = Vector3.new(60, 1, 60)
	}
}

-- Internal state
FarmPlot.ActiveFarms = {}
FarmPlot.FarmValidationQueue = {}

-- ========== INITIALIZATION ==========

function FarmPlot:Initialize(gameCoreRef)
	print("FarmPlot: Initializing farm plot management system...")

	-- Store module references
	GameCore = gameCoreRef

	-- Initialize farm tracking
	self.ActiveFarms = {}
	self.FarmValidationQueue = {}

	-- Setup workspace structure
	self:EnsureWorkspaceStructure()

	-- Initialize validation system
	self:InitializeValidationSystem()

	-- Initialize monitoring
	self:InitializeFarmMonitoring()

	print("FarmPlot: ✅ Farm plot management system initialized successfully")
	return true
end

function FarmPlot:EnsureWorkspaceStructure()
	-- Create necessary workspace structure
	local areas = Workspace:FindFirstChild("Areas")
	if not areas then
		areas = Instance.new("Folder")
		areas.Name = "Areas"
		areas.Parent = Workspace
	end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then
		starterMeadow = Instance.new("Model")
		starterMeadow.Name = "Starter Meadow"
		starterMeadow.Parent = areas
	end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then
		farmArea = Instance.new("Folder")
		farmArea.Name = "Farm"
		farmArea.Parent = starterMeadow
	end

	print("FarmPlot: Workspace structure ensured")
end

function FarmPlot:InitializeValidationSystem()
	-- Queue-based validation to prevent lag
	spawn(function()
		while true do
			wait(1) -- Process validation queue every second
			self:ProcessValidationQueue()
		end
	end)
end

function FarmPlot:InitializeFarmMonitoring()
	-- Monitor farm health every 5 minutes
	spawn(function()
		while true do
			wait(300) -- 5 minutes
			self:MonitorFarmHealth()
		end
	end)
end

-- ========== SIMPLE FARM CREATION ==========

function FarmPlot:CreateSimpleFarmPlot(player)
	print("FarmPlot: Creating simple 10x10 farm plot for " .. player.Name)

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		warn("FarmPlot: No player data for " .. player.Name)
		return false
	end

	-- Initialize farming data if needed
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			inventory = {}
		}
	end

	local plotCFrame = self:GetSimpleFarmPosition(player)

	-- Find farm area
	local farmArea = self:GetFarmArea()
	if not farmArea then
		warn("FarmPlot: Could not find farm area")
		return false
	end

	-- Create/update player-specific simple farm
	local playerFarmName = player.Name .. "_SimpleFarm"
	local existingFarm = farmArea:FindFirstChild(playerFarmName)

	if existingFarm then
		print("FarmPlot: Updating existing farm for " .. player.Name)
		return self:UpdateSimpleFarmPlot(player, existingFarm, plotCFrame)
	else
		print("FarmPlot: Creating new simple farm for " .. player.Name)
		return self:CreateNewSimpleFarmPlot(player, farmArea, playerFarmName, plotCFrame)
	end
end

function FarmPlot:GetSimpleFarmPosition(player)
	-- Get player index for farm separation
	local playerIndex = 0
	local sortedPlayers = {}
	for _, p in pairs(Players:GetPlayers()) do
		table.insert(sortedPlayers, p)
	end
	table.sort(sortedPlayers, function(a, b) return a.UserId < b.UserId end)

	for i, p in ipairs(sortedPlayers) do
		if p.UserId == player.UserId then
			playerIndex = i - 1
			break
		end
	end

	-- Calculate position
	local basePos = self.SimpleFarmConfig.basePosition
	local playerOffset = self.SimpleFarmConfig.playerSeparation * playerIndex
	local finalPosition = basePos + playerOffset

	local rotation = self.SimpleFarmConfig.plotRotation
	local cframe = CFrame.new(finalPosition) * CFrame.Angles(
		math.rad(rotation.X), 
		math.rad(rotation.Y), 
		math.rad(rotation.Z)
	)

	return cframe
end

function FarmPlot:CreateNewSimpleFarmPlot(player, farmArea, farmName, plotCFrame)
	print("FarmPlot: Creating new simple farm for " .. player.Name)

	local config = self.SimpleFarmConfig

	-- Create the simple farm model
	local simpleFarm = Instance.new("Model")
	simpleFarm.Name = farmName
	simpleFarm.Parent = farmArea

	-- Create the main base platform
	local basePart = Instance.new("Part")
	basePart.Name = "BasePart"
	basePart.Size = config.baseSize
	basePart.Material = Enum.Material.Ground
	basePart.Color = Color3.fromRGB(101, 67, 33)
	basePart.Anchored = true
	basePart.CFrame = plotCFrame
	basePart.Parent = simpleFarm

	simpleFarm.PrimaryPart = basePart

	-- Create all planting spots (10x10 grid, all unlocked)
	local plantingSpots = Instance.new("Folder")
	plantingSpots.Name = "PlantingSpots"
	plantingSpots.Parent = simpleFarm

	self:CreateSimplePlantingGrid(player, simpleFarm, plantingSpots, plotCFrame)

	-- Create border and info sign
	self:CreateSimpleBorder(simpleFarm, plotCFrame, config)
	self:CreateSimpleInfoSign(simpleFarm, plotCFrame, player)

	-- Track active farm
	self:TrackActiveFarm(player, simpleFarm)

	print("FarmPlot: Created simple farm for " .. player.Name .. " with " .. config.totalSpots .. " unlocked spots")
	return true
end

function FarmPlot:UpdateSimpleFarmPlot(player, existingFarm, plotCFrame)
	print("FarmPlot: Updating simple farm for " .. player.Name)

	-- Update position if needed
	if existingFarm.PrimaryPart then
		local currentPosition = existingFarm.PrimaryPart.Position
		local expectedPosition = plotCFrame.Position
		local distance = (currentPosition - expectedPosition).Magnitude

		if distance > 10 then
			existingFarm:SetPrimaryPartCFrame(plotCFrame)
			print("FarmPlot: Updated farm position for " .. player.Name)
		end
	end

	-- Validate plot count and structure
	self:QueueFarmValidation(player, existingFarm)

	return true
end

function FarmPlot:CreateSimplePlantingGrid(player, farmModel, plantingSpots, plotCFrame)
	local config = self.SimpleFarmConfig
	local gridSize = config.gridSize
	local spotSize = config.spotSize
	local spacing = config.spotSpacing

	-- Calculate grid offset to center it
	local gridOffset = (gridSize - 1) * spacing / 2

	local spotIndex = 0
	for row = 1, gridSize do
		for col = 1, gridSize do
			spotIndex = spotIndex + 1
			local spotName = "PlantingSpot_" .. spotIndex

			local spotModel = self:CreatePlantingSpot(
				spotName, 
				plotCFrame, 
				row, col, 
				spacing, 
				gridOffset, 
				config,
				true -- All spots unlocked in simple farm
			)

			spotModel.Parent = plantingSpots

			-- Setup click detection
			self:SetupPlotClickDetection(spotModel, player)
		end
	end

	print("FarmPlot: Created " .. spotIndex .. " unlocked planting spots in 10x10 grid")
end

function FarmPlot:CreatePlantingSpot(spotName, plotCFrame, row, col, spacing, gridOffset, config, isUnlocked)
	local spotModel = Instance.new("Model")
	spotModel.Name = spotName

	-- Position calculation (centered grid)
	local offsetX = (col - 1) * spacing - gridOffset
	local offsetZ = (row - 1) * spacing - gridOffset

	local spotPart = Instance.new("Part")
	spotPart.Name = "SpotPart"
	spotPart.Size = Vector3.new(config.spotSize, 0.2, config.spotSize)
	spotPart.Material = Enum.Material.LeafyGrass
	spotPart.Anchored = true
	spotPart.CFrame = plotCFrame + Vector3.new(offsetX, 1, offsetZ)
	spotPart.Parent = spotModel

	spotModel.PrimaryPart = spotPart

	-- Set spot attributes
	spotModel:SetAttribute("IsEmpty", true)
	spotModel:SetAttribute("PlantType", "")
	spotModel:SetAttribute("SeedType", "")
	spotModel:SetAttribute("GrowthStage", 0)
	spotModel:SetAttribute("PlantedTime", 0)
	spotModel:SetAttribute("Rarity", "common")
	spotModel:SetAttribute("IsUnlocked", isUnlocked)
	spotModel:SetAttribute("GridRow", row)
	spotModel:SetAttribute("GridCol", col)

	-- Visual styling based on unlock status
	if isUnlocked then
		spotPart.Color = config.spotColor
		spotPart.Transparency = config.spotTransparency

		-- Create interaction indicator
		local indicator = Instance.new("Part")
		indicator.Name = "Indicator"
		indicator.Size = Vector3.new(0.5, 2, 0.5)
		indicator.Material = Enum.Material.Neon
		indicator.Color = Color3.fromRGB(100, 255, 100)
		indicator.Anchored = true
		indicator.CFrame = spotPart.CFrame + Vector3.new(0, 1.5, 0)
		indicator.Parent = spotModel
	else
		spotPart.Color = Color3.fromRGB(80, 80, 80)
		spotPart.Transparency = 0.5

		-- Create lock indicator
		local lockIndicator = Instance.new("Part")
		lockIndicator.Name = "LockIndicator"
		lockIndicator.Size = Vector3.new(1, 1, 1)
		lockIndicator.Material = Enum.Material.Neon
		lockIndicator.Color = Color3.fromRGB(255, 0, 0)
		lockIndicator.Anchored = true
		lockIndicator.CFrame = spotPart.CFrame + Vector3.new(0, 1, 0)
		lockIndicator.Parent = spotModel
	end

	return spotModel
end

function FarmPlot:SetupPlotClickDetection(spotModel, player)
	local spotPart = spotModel:FindFirstChild("SpotPart")
	if not spotPart then return end

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = spotPart

	clickDetector.MouseClick:Connect(function(clickingPlayer)
		if clickingPlayer.UserId == player.UserId then
			self:HandlePlotClick(clickingPlayer, spotModel)
		end
	end)
end

-- ========== EXPANDABLE FARM CREATION ==========

function FarmPlot:CreateExpandableFarmPlot(player, expansionLevel)
	print("FarmPlot: Creating expandable farm plot (Level " .. expansionLevel .. ") for " .. player.Name)

	expansionLevel = expansionLevel or 1
	local config = self.ExpandableFarmConfigs[expansionLevel]
	if not config then
		warn("FarmPlot: Invalid expansion level: " .. expansionLevel)
		return false
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		warn("FarmPlot: No player data for " .. player.Name)
		return false
	end

	-- Initialize farming data
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			expansionLevel = expansionLevel,
			inventory = {}
		}
	else
		playerData.farming.expansionLevel = expansionLevel
	end

	local plotCFrame = self:GetSimpleFarmPosition(player) -- Reuse positioning logic

	-- Find farm area
	local farmArea = self:GetFarmArea()
	if not farmArea then
		warn("FarmPlot: Could not find farm area")
		return false
	end

	-- Create/update expandable farm
	local playerFarmName = player.Name .. "_ExpandableFarm"
	local existingFarm = farmArea:FindFirstChild(playerFarmName)

	if existingFarm then
		existingFarm:Destroy() -- Remove old farm to recreate with new level
	end

	return self:CreateNewExpandableFarmPlot(player, farmArea, playerFarmName, plotCFrame, config)
end

function FarmPlot:CreateNewExpandableFarmPlot(player, farmArea, farmName, plotCFrame, config)
	print("FarmPlot: Creating new expandable farm: " .. config.name)

	-- Create the farm model
	local expandableFarm = Instance.new("Model")
	expandableFarm.Name = farmName
	expandableFarm.Parent = farmArea

	-- Create base platform
	local basePart = Instance.new("Part")
	basePart.Name = "BasePart"
	basePart.Size = config.baseSize
	basePart.Material = Enum.Material.Ground
	basePart.Color = Color3.fromRGB(101, 67, 33)
	basePart.Anchored = true
	basePart.CFrame = plotCFrame
	basePart.Parent = expandableFarm

	expandableFarm.PrimaryPart = basePart

	-- Create planting spots
	local plantingSpots = Instance.new("Folder")
	plantingSpots.Name = "PlantingSpots"
	plantingSpots.Parent = expandableFarm

	self:CreateExpandablePlantingGrid(player, expandableFarm, plantingSpots, plotCFrame, config)

	-- Create border and info sign
	self:CreateExpandableBorder(expandableFarm, plotCFrame, config)
	self:CreateExpandableInfoSign(expandableFarm, plotCFrame, player, config)

	-- Track active farm
	self:TrackActiveFarm(player, expandableFarm)

	print("FarmPlot: Created " .. config.name .. " for " .. player.Name .. " with " .. config.unlockedSpots .. "/" .. config.totalSpots .. " spots")
	return true
end

function FarmPlot:CreateExpandablePlantingGrid(player, farmModel, plantingSpots, plotCFrame, config)
	local gridSize = config.gridSize
	local spacing = 5 -- Fixed spacing for expandable farms
	local spotSize = 3 -- Fixed spot size

	local gridOffset = (gridSize - 1) * spacing / 2

	local spotIndex = 0
	for row = 1, gridSize do
		for col = 1, gridSize do
			spotIndex = spotIndex + 1
			local spotName = "PlantingSpot_" .. spotIndex

			-- Determine if spot should be unlocked
			local isUnlocked = spotIndex <= config.unlockedSpots

			local spotModel = self:CreatePlantingSpot(
				spotName,
				plotCFrame,
				row, col,
				spacing,
				gridOffset,
				{spotSize = spotSize, spotColor = Color3.fromRGB(91, 154, 76), spotTransparency = 0},
				isUnlocked
			)

			spotModel.Parent = plantingSpots

			-- Setup click detection
			self:SetupPlotClickDetection(spotModel, player)
		end
	end

	print("FarmPlot: Created " .. config.unlockedSpots .. " unlocked spots out of " .. config.totalSpots .. " total")
end

-- ========== FARM ACCESSORIES ==========

function FarmPlot:CreateSimpleBorder(farmModel, plotCFrame, config)
	local borderContainer = Instance.new("Model")
	borderContainer.Name = "SimpleBorder"
	borderContainer.Parent = farmModel

	local borderHeight = 1
	local borderWidth = 0.5
	local plotSize = config.baseSize.X

	local borderPositions = {
		{Vector3.new(0, borderHeight/2, plotSize/2 + borderWidth/2), Vector3.new(plotSize + borderWidth, borderHeight, borderWidth)},
		{Vector3.new(0, borderHeight/2, -(plotSize/2 + borderWidth/2)), Vector3.new(plotSize + borderWidth, borderHeight, borderWidth)},
		{Vector3.new(plotSize/2 + borderWidth/2, borderHeight/2, 0), Vector3.new(borderWidth, borderHeight, plotSize)},
		{Vector3.new(-(plotSize/2 + borderWidth/2), borderHeight/2, 0), Vector3.new(borderWidth, borderHeight, plotSize)}
	}

	for i, borderData in ipairs(borderPositions) do
		local borderPart = Instance.new("Part")
		borderPart.Name = "Border_" .. i
		borderPart.Size = borderData[2]
		borderPart.Material = Enum.Material.Wood
		borderPart.Color = Color3.fromRGB(92, 51, 23)
		borderPart.Anchored = true
		borderPart.CFrame = plotCFrame + borderData[1]
		borderPart.Parent = borderContainer
	end
end

function FarmPlot:CreateExpandableBorder(farmModel, plotCFrame, config)
	-- Similar to simple border but uses config.baseSize
	self:CreateSimpleBorder(farmModel, plotCFrame, config)
end

function FarmPlot:CreateSimpleInfoSign(farmModel, plotCFrame, player)
	local config = self.SimpleFarmConfig

	local signContainer = Instance.new("Model")
	signContainer.Name = "InfoSign"
	signContainer.Parent = farmModel

	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(0.5, 4, 0.5)
	signPost.Material = Enum.Material.Wood
	signPost.Color = Color3.fromRGB(92, 51, 23)
	signPost.Anchored = true
	signPost.CFrame = plotCFrame + Vector3.new(config.baseSize.X/2 + 5, 2, -config.baseSize.Z/2 - 5)
	signPost.Parent = signContainer

	local signBoard = Instance.new("Part")
	signBoard.Name = "SignBoard"
	signBoard.Size = Vector3.new(4, 3, 0.2)
	signBoard.Material = Enum.Material.Wood
	signBoard.Color = Color3.fromRGB(139, 90, 43)
	signBoard.Anchored = true
	signBoard.CFrame = signPost.CFrame + Vector3.new(2, 0.5, 0)
	signBoard.Parent = signContainer

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signBoard

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = player.Name .. "'s Farm\n" .. 
		config.gridSize .. "x" .. config.gridSize .. " Grid\n" .. 
		config.totalSpots .. " Total Spots\n" .. 
		"All Unlocked!"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = surfaceGui
end

function FarmPlot:CreateExpandableInfoSign(farmModel, plotCFrame, player, config)
	local signContainer = Instance.new("Model")
	signContainer.Name = "InfoSign"
	signContainer.Parent = farmModel

	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(0.5, 4, 0.5)
	signPost.Material = Enum.Material.Wood
	signPost.Color = Color3.fromRGB(92, 51, 23)
	signPost.Anchored = true
	signPost.CFrame = plotCFrame + Vector3.new(config.baseSize.X/2 + 5, 2, -config.baseSize.Z/2 - 5)
	signPost.Parent = signContainer

	local signBoard = Instance.new("Part")
	signBoard.Name = "SignBoard"
	signBoard.Size = Vector3.new(4, 3, 0.2)
	signBoard.Material = Enum.Material.Wood
	signBoard.Color = Color3.fromRGB(139, 90, 43)
	signBoard.Anchored = true
	signBoard.CFrame = signPost.CFrame + Vector3.new(2, 0.5, 0)
	signBoard.Parent = signContainer

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signBoard

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = player.Name .. "'s " .. config.name .. "\n" .. 
		config.gridSize .. "x" .. config.gridSize .. " Grid\n" .. 
		config.unlockedSpots .. " / " .. config.totalSpots .. " Unlocked"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = surfaceGui
end

-- ========== FARM MANAGEMENT ==========

function FarmPlot:GetPlayerFarm(player)
	local farmArea = self:GetFarmArea()
	if not farmArea then return nil end

	-- Try simple farm first
	local simpleFarm = farmArea:FindFirstChild(player.Name .. "_SimpleFarm")
	if simpleFarm then
		return simpleFarm, "simple"
	end

	-- Try expandable farm
	local expandableFarm = farmArea:FindFirstChild(player.Name .. "_ExpandableFarm")
	if expandableFarm then
		return expandableFarm, "expandable"
	end

	return nil, nil
end

function FarmPlot:GetFarmArea()
	local areas = Workspace:FindFirstChild("Areas")
	if not areas then return nil end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return nil end

	return starterMeadow:FindFirstChild("Farm")
end

function FarmPlot:GetPlotOwner(plotModel)
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

	warn("FarmPlot: Could not determine plot owner for " .. plotModel.Name)
	return nil
end

function FarmPlot:FindPlotByName(player, plotName)
	local farm, farmType = self:GetPlayerFarm(player)
	if not farm then
		warn("FarmPlot: No farm found for player: " .. player.Name)
		return nil
	end

	local plantingSpots = farm:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		warn("FarmPlot: No PlantingSpots folder found")
		return nil
	end

	-- Try exact match first
	local exactMatch = plantingSpots:FindFirstChild(plotName)
	if exactMatch then
		return exactMatch
	end

	-- Try case-insensitive search
	local lowerPlotName = plotName:lower()
	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:lower() == lowerPlotName then
			return spot
		end
	end

	-- Try pattern matching for PlantingSpot_X format
	local plotNumber = plotName:match("(%d+)")
	if plotNumber then
		local standardName = "PlantingSpot_" .. plotNumber
		local standardMatch = plantingSpots:FindFirstChild(standardName)
		if standardMatch then
			return standardMatch
		end
	end

	warn("FarmPlot: Plot not found: " .. plotName)
	return nil
end

-- ========== PLOT INTERACTION ==========

function FarmPlot:HandlePlotClick(player, spotModel)
	-- Check if plot is empty - if so, handle planting
	local isEmpty = spotModel:GetAttribute("IsEmpty")
	local isUnlocked = spotModel:GetAttribute("IsUnlocked")

	if not isUnlocked then
		self:SendNotification(player, "Locked Plot", "This plot area is locked! Purchase farm expansion to unlock it.", "error")
		return
	end

	if not isEmpty then
		-- Plot has a crop - tell player to click the crop instead
		self:SendNotification(player, "Click the Crop", "Click on the crop itself to harvest it, not the plot!", "info")
		return
	end

	-- Plot is empty - handle seed planting
	local plotOwner = self:GetPlotOwner(spotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Farming Data", "You need to set up farming first! Visit the shop.", "warning")
		return
	end

	local hasSeeds = false
	for itemId, qty in pairs(playerData.farming.inventory) do
		if itemId:find("_seeds") and qty > 0 then
			hasSeeds = true
			break
		end
	end

	if not hasSeeds then
		self:SendNotification(player, "No Seeds", "You don't have any seeds! Buy some from the shop first.", "warning")
		return
	end

	-- Trigger planting interface (this would be handled by the UI system)
	if GameCore and GameCore.RemoteEvents and GameCore.RemoteEvents.PlantSeed then
		GameCore.RemoteEvents.PlantSeed:FireClient(player, spotModel)
	end
end

-- ========== VALIDATION SYSTEM ==========

function FarmPlot:QueueFarmValidation(player, farm)
	table.insert(self.FarmValidationQueue, {
		player = player,
		farm = farm,
		timestamp = tick()
	})
end

function FarmPlot:ProcessValidationQueue()
	if #self.FarmValidationQueue == 0 then return end

	-- Process one item per frame to prevent lag
	local item = table.remove(self.FarmValidationQueue, 1)

	if item and item.player and item.player.Parent and item.farm and item.farm.Parent then
		self:ValidateFarmStructure(item.player, item.farm)
	end
end

function FarmPlot:ValidateFarmStructure(player, farmModel)
	print("FarmPlot: Validating farm structure for " .. player.Name)

	local plantingSpots = farmModel:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		print("FarmPlot: Missing planting spots folder, recreating farm")
		self:RecreatePlayerFarm(player)
		return
	end

	-- Count spots and validate structure
	local totalSpots = 0
	local unlockedSpots = 0
	local expectedSpots = 100 -- Default to simple farm expectation

	-- Determine expected spots based on farm type
	if farmModel.Name:find("_SimpleFarm") then
		expectedSpots = self.SimpleFarmConfig.totalSpots
	elseif farmModel.Name:find("_ExpandableFarm") then
		local playerData = GameCore:GetPlayerData(player)
		if playerData and playerData.farming and playerData.farming.expansionLevel then
			local config = self.ExpandableFarmConfigs[playerData.farming.expansionLevel]
			expectedSpots = config and config.totalSpots or 100
		end
	end

	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			totalSpots = totalSpots + 1
			local isUnlocked = spot:GetAttribute("IsUnlocked")
			if isUnlocked then
				unlockedSpots = unlockedSpots + 1
			end
		end
	end

	print("FarmPlot: Found " .. unlockedSpots .. " unlocked spots out of " .. totalSpots .. " total spots")
	print("FarmPlot: Expected " .. expectedSpots .. " spots")

	-- Validate and repair if necessary
	if totalSpots ~= expectedSpots then
		print("FarmPlot: Spot count mismatch, recreating farm")
		self:RecreatePlayerFarm(player)
	else
		print("FarmPlot: Farm validation passed for " .. player.Name)
	end
end

function FarmPlot:RecreatePlayerFarm(player)
	print("FarmPlot: Recreating farm for " .. player.Name)

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then return end

	-- Remove existing farm
	local farm, farmType = self:GetPlayerFarm(player)
	if farm then
		farm:Destroy()
	end

	-- Recreate based on player's farming data
	if playerData.farming then
		if playerData.farming.expansionLevel and playerData.farming.expansionLevel > 1 then
			self:CreateExpandableFarmPlot(player, playerData.farming.expansionLevel)
		else
			self:CreateSimpleFarmPlot(player)
		end
	else
		-- Default to simple farm
		self:CreateSimpleFarmPlot(player)
	end
end

-- ========== FARM MONITORING ==========

function FarmPlot:TrackActiveFarm(player, farm)
	self.ActiveFarms[player.UserId] = {
		player = player,
		farm = farm,
		created = tick(),
		lastValidated = tick()
	}
end

function FarmPlot:MonitorFarmHealth()
	print("FarmPlot: Running farm health check...")

	local totalFarms = 0
	local healthyFarms = 0
	local problemFarms = 0

	for userId, farmData in pairs(self.ActiveFarms) do
		totalFarms = totalFarms + 1

		local player = farmData.player
		local farm = farmData.farm

		-- Check if player still exists
		if not player or not player.Parent then
			self.ActiveFarms[userId] = nil
			if farm and farm.Parent then
				farm:Destroy()
				print("FarmPlot: Cleaned up abandoned farm for disconnected player")
			end
			-- Check if farm still exists
		elseif not farm or not farm.Parent then
			print("FarmPlot: Farm missing for " .. player.Name .. ", recreating...")
			self:RecreatePlayerFarm(player)
			problemFarms = problemFarms + 1
		else
			-- Farm exists, queue for validation if it's been a while
			if tick() - farmData.lastValidated > 300 then -- 5 minutes
				self:QueueFarmValidation(player, farm)
				farmData.lastValidated = tick()
			end
			healthyFarms = healthyFarms + 1
		end
	end

	print("FarmPlot: Health check complete - " .. healthyFarms .. " healthy, " .. problemFarms .. " problems out of " .. totalFarms .. " total")
end

function FarmPlot:CleanupAbandonedFarms()
	print("FarmPlot: Cleaning up abandoned farms...")

	local farmArea = self:GetFarmArea()
	if not farmArea then return end

	local cleanedCount = 0

	for _, farm in pairs(farmArea:GetChildren()) do
		if farm:IsA("Model") and (farm.Name:find("_SimpleFarm") or farm.Name:find("_ExpandableFarm")) then
			local playerName = farm.Name:gsub("_SimpleFarm", ""):gsub("_ExpandableFarm", "")
			local player = Players:FindFirstChild(playerName)

			-- If player doesn't exist, clean up their farm
			if not player then
				print("FarmPlot: Cleaning up abandoned farm for " .. playerName)
				farm:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	if cleanedCount > 0 then
		print("FarmPlot: Cleaned up " .. cleanedCount .. " abandoned farms")
	end
end

-- ========== FARM EXPANSION ==========

function FarmPlot:ExpandFarm(player, newLevel)
	print("FarmPlot: Expanding farm to level " .. newLevel .. " for " .. player.Name)

	local config = self.ExpandableFarmConfigs[newLevel]
	if not config then
		warn("FarmPlot: Invalid expansion level: " .. newLevel)
		return false
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		warn("FarmPlot: No player data for expansion")
		return false
	end

	-- Update player data
	playerData.farming = playerData.farming or {}
	playerData.farming.expansionLevel = newLevel

	-- Create new farm at the expansion level
	local success = self:CreateExpandableFarmPlot(player, newLevel)

	if success then
		GameCore:SavePlayerData(player)
		self:SendNotification(player, "Farm Expanded!", 
			"Your farm has been expanded to " .. config.name .. "!\n" ..
				config.unlockedSpots .. " spots available.", "success")
	end

	return success
end

function FarmPlot:GetExpansionConfig(level)
	return self.ExpandableFarmConfigs[level]
end

function FarmPlot:GetMaxExpansionLevel()
	local maxLevel = 0
	for level, _ in pairs(self.ExpandableFarmConfigs) do
		if level > maxLevel then
			maxLevel = level
		end
	end
	return maxLevel
end

-- ========== UTILITY FUNCTIONS ==========

function FarmPlot:SendNotification(player, title, message, type)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, type)
	else
		print("[" .. title .. "] " .. message .. " (to " .. player.Name .. ")")
	end
end

function FarmPlot:GetPlayerFarmStatistics(player)
	local farm, farmType = self:GetPlayerFarm(player)
	if not farm then
		return {
			exists = false,
			type = "none",
			totalSpots = 0,
			unlockedSpots = 0,
			occupiedSpots = 0
		}
	end

	local plantingSpots = farm:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		return {
			exists = true,
			type = farmType,
			totalSpots = 0,
			unlockedSpots = 0,
			occupiedSpots = 0,
			error = "No planting spots folder"
		}
	end

	local totalSpots = 0
	local unlockedSpots = 0
	local occupiedSpots = 0

	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			totalSpots = totalSpots + 1

			if spot:GetAttribute("IsUnlocked") then
				unlockedSpots = unlockedSpots + 1
			end

			if not spot:GetAttribute("IsEmpty") then
				occupiedSpots = occupiedSpots + 1
			end
		end
	end

	return {
		exists = true,
		type = farmType,
		totalSpots = totalSpots,
		unlockedSpots = unlockedSpots,
		occupiedSpots = occupiedSpots,
		emptySpots = unlockedSpots - occupiedSpots
	}
end

function FarmPlot:ValidatePlayerFarmAccess(player)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then return false end

	-- Check if player has purchased farm access
	local hasFarmStarter = playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter
	local hasFarmingData = playerData.farming and playerData.farming.plots and playerData.farming.plots > 0

	return hasFarmStarter or hasFarmingData
end

function FarmPlot:EnsurePlayerHasFarm(player)
	if not self:ValidatePlayerFarmAccess(player) then
		return false
	end

	local farm, farmType = self:GetPlayerFarm(player)
	if not farm then
		print("FarmPlot: Creating missing farm for " .. player.Name)
		return self:CreateSimpleFarmPlot(player)
	end

	return true
end

print("FarmPlot: ✅ Farm plot management module loaded successfully")

return FarmPlot