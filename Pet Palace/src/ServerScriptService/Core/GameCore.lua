--[[
    GameCore.lua - UPDATED WITHOUT SHOP FUNCTIONS
    Place in: ServerScriptService/Core/GameCore.lua
    
    Shop functionality has been moved to ShopSystem.lua
    This version focuses on core game mechanics:
    - Livestock system (cow milking, pig feeding)
    - Farming system (planting, growing, harvesting)
    - Pest and chicken defense systems
    - Player data management
    - Farm plot creation and management
]]

local GameCore = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

-- Load configuration
local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GameRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- FARM PLOT POSITION CONFIGURATION
GameCore.FarmPlotPositions = {
	basePosition = Vector3.new(-366.118, -2.793, 75.731),
	plotOffsets = {
		[1] = Vector3.new(0, 0, 0),
		[2] = Vector3.new(-34.65, 0, 0),
		[3] = Vector3.new(0, 0, 33.8),
		[4] = Vector3.new(-34.65, 0, 33.65),
		[5] = Vector3.new(-34.65, 0, 66.95),
		[6] = Vector3.new(0, 0, 66.95),
		[7] = Vector3.new(0, 0, 100.75),
		[8] = Vector3.new(-34.65, 0, 100.6),
	},
	plotRotation = Vector3.new(0, 0, 0),
	playerSeparation = Vector3.new(120, 0, 0)
}

-- Core Data Management
GameCore.PlayerData = {}
GameCore.DataStore = nil
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}
GameCore.DataStoreCooldowns = {}
GameCore.PendingSaves = {}
GameCore.SAVE_COOLDOWN = 30

-- System States
GameCore.Systems = {
	Livestock = {
		CowCooldowns = {}, -- Track milk collection cooldowns per player
		PigStates = {} -- Track pig feeding states per player
	},
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {}
	}
}

-- Workspace Models
GameCore.Models = {
	Cow = nil,
	Pig = nil
}

-- Reference to ShopSystem (will be injected)
GameCore.ShopSystem = nil

-- ========== INITIALIZATION ==========

function GameCore:Initialize(shopSystem)
	print("GameCore: Starting core game system initialization...")

	-- Store ShopSystem reference
	if shopSystem then
		self.ShopSystem = shopSystem
		print("GameCore: ShopSystem reference established")
	end

	-- Initialize player data storage
	self.PlayerData = {}

	-- Setup DataStore
	local success, dataStore = pcall(function()
		return game:GetService("DataStoreService"):GetDataStore("LivestockFarmData_v1")
	end)

	if success then
		self.PlayerDataStore = dataStore
		print("GameCore: DataStore connected")
	else
		warn("GameCore: Failed to connect to DataStore - running in local mode")
	end

	-- Setup remote connections (excluding shop remotes)
	self:SetupRemoteConnections()

	-- Setup event handlers (excluding shop handlers)
	self:SetupEventHandlers()

	-- Initialize game systems
	self:InitializeLivestockSystem()
	self:InitializeFarmingSystem()
	self:InitializePestAndChickenSystems()

	-- Start update loops
	self:StartUpdateLoops()

	-- Setup admin commands
	self:SetupAdminCommands()

	print("GameCore: ✅ Core game system initialization complete!")
	return true
end

function GameCore:SetupRemoteConnections()
	print("GameCore: Setting up core remote connections...")

	-- Wait for GameRemotes folder to exist
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remotes then
		error("GameCore: GameRemotes folder not found after 10 seconds!")
	end

	-- Clear existing connections
	self.RemoteEvents = {}
	self.RemoteFunctions = {}

	-- Core remote events (excluding shop-related ones)
	local coreRemoteEvents = {
		"CollectMilk", "FeedPig", "PlayerDataUpdated", "ShowNotification",
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		"PestSpotted", "PestEliminated", "ChickenPlaced", "ChickenMoved",
		"FeedAllChickens", "FeedChickensWithType", "UsePesticide"
	}

	-- Core remote functions (excluding shop-related ones)
	local coreRemoteFunctions = {
		"GetPlayerData", "GetFarmingData"
	}

	-- Load core remote events
	for _, eventName in ipairs(coreRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if remote and remote:IsA("RemoteEvent") then
			self.RemoteEvents[eventName] = remote
			print("GameCore: ✅ Connected RemoteEvent: " .. eventName)
		else
			-- Create missing remotes
			local newRemote = Instance.new("RemoteEvent")
			newRemote.Name = eventName
			newRemote.Parent = remotes
			self.RemoteEvents[eventName] = newRemote
			print("GameCore: 📦 Created RemoteEvent: " .. eventName)
		end
	end

	-- Load core remote functions
	for _, funcName in ipairs(coreRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if remote and remote:IsA("RemoteFunction") then
			self.RemoteFunctions[funcName] = remote
			print("GameCore: ✅ Connected RemoteFunction: " .. funcName)
		else
			-- Create missing remotes
			local newRemote = Instance.new("RemoteFunction")
			newRemote.Name = funcName
			newRemote.Parent = remotes
			self.RemoteFunctions[funcName] = newRemote
			print("GameCore: 📦 Created RemoteFunction: " .. funcName)
		end
	end

	print("GameCore: Core remote connections established")
	print("  RemoteEvents: " .. self:CountTable(self.RemoteEvents))
	print("  RemoteFunctions: " .. self:CountTable(self.RemoteFunctions))
end

function GameCore:SetupEventHandlers()
	print("GameCore: Setting up core event handlers...")

	-- Livestock System Events
	if self.RemoteEvents.CollectMilk then
		self.RemoteEvents.CollectMilk.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleMilkCollection(player)
			end)
		end)
		print("✅ Connected CollectMilk handler")
	end

	if self.RemoteEvents.FeedPig then
		self.RemoteEvents.FeedPig.OnServerEvent:Connect(function(player, cropId)
			pcall(function()
				self:HandlePigFeeding(player, cropId)
			end)
		end)
		print("✅ Connected FeedPig handler")
	end

	-- Farming System Events
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			pcall(function()
				self:PlantSeed(player, plotModel, seedId)
			end)
		end)
		print("✅ Connected PlantSeed handler")
	end

	if self.RemoteEvents.HarvestCrop then
		self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotModel)
			pcall(function()
				self:HarvestCrop(player, plotModel)
			end)
		end)
		print("✅ Connected HarvestCrop handler")
	end

	if self.RemoteEvents.HarvestAllCrops then
		self.RemoteEvents.HarvestAllCrops.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HarvestAllCrops(player)
			end)
		end)
		print("✅ Connected HarvestAllCrops handler")
	end

	-- Chicken System Events
	if self.RemoteEvents.FeedAllChickens then
		self.RemoteEvents.FeedAllChickens.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleFeedAllChickens(player)
			end)
		end)
		print("✅ Connected FeedAllChickens handler")
	end

	if self.RemoteEvents.FeedChickensWithType then
		self.RemoteEvents.FeedChickensWithType.OnServerEvent:Connect(function(player, feedType)
			pcall(function()
				self:HandleFeedChickensWithType(player, feedType)
			end)
		end)
		print("✅ Connected FeedChickensWithType handler")
	end

	-- Core Remote Functions
	if self.RemoteFunctions.GetPlayerData then
		self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				return self:GetPlayerData(player)
			end)
			return success and result or nil
		end
		print("✅ Connected GetPlayerData function")
	end

	if self.RemoteFunctions.GetFarmingData then
		self.RemoteFunctions.GetFarmingData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				local playerData = self:GetPlayerData(player)
				return playerData and playerData.farming or {}
			end)
			return success and result or {}
		end
		print("✅ Connected GetFarmingData function")
	end

	print("GameCore: Core event handlers setup complete!")
end

-- ========== FARM PLOT MANAGEMENT ==========

function GameCore:GetFarmPlotPosition(player, plotNumber)
	plotNumber = plotNumber or 1

	if plotNumber < 1 or plotNumber > 10 then
		warn("GameCore: Invalid plot number " .. plotNumber .. ". Must be between 1 and 10.")
		plotNumber = 1
	end

	if not self.FarmPlotPositions then
		warn("GameCore: FarmPlotPositions not initialized!")
		return CFrame.new(0, 0, 0)
	end

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
	local basePos = self.FarmPlotPositions.basePosition
	local playerOffset = self.FarmPlotPositions.playerSeparation * playerIndex
	local playerBasePosition = basePos + playerOffset
	local plotOffset = self.FarmPlotPositions.plotOffsets[plotNumber] or Vector3.new(0, 0, 0)
	local finalPosition = playerBasePosition + plotOffset

	local rotation = self.FarmPlotPositions.plotRotation
	local cframe = CFrame.new(finalPosition) * CFrame.Angles(
		math.rad(rotation.X), 
		math.rad(rotation.Y), 
		math.rad(rotation.Z)
	)

	return cframe
end

function GameCore:CreatePlayerFarmPlot(player, plotNumber)
	plotNumber = plotNumber or 1

	local plotCFrame = self:GetFarmPlotPosition(player, plotNumber)
	if not plotCFrame then
		warn("GameCore: Could not get farm plot position for " .. player.Name .. " plot " .. plotNumber)
		return false
	end

	-- Find or create the farm area structure
	local areas = workspace:FindFirstChild("Areas")
	if not areas then
		areas = Instance.new("Folder")
		areas.Name = "Areas"
		areas.Parent = workspace
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

	-- Create player-specific farm folder
	local playerFarmName = player.Name .. "_Farm"
	local playerFarm = farmArea:FindFirstChild(playerFarmName)
	if not playerFarm then
		playerFarm = Instance.new("Folder")
		playerFarm.Name = playerFarmName
		playerFarm.Parent = farmArea
	end

	-- Check if plot already exists
	local plotName = "FarmPlot_" .. plotNumber
	local existingPlot = playerFarm:FindFirstChild(plotName)
	if existingPlot then
		if existingPlot.PrimaryPart then
			existingPlot:SetPrimaryPartCFrame(plotCFrame)
		end
		print("GameCore: Updated position for existing " .. plotName .. " for " .. player.Name)
		return true
	end

	-- Create the farm plot model
	local farmPlot = Instance.new("Model")
	farmPlot.Name = plotName
	farmPlot.Parent = playerFarm

	-- Create the base platform
	local basePart = Instance.new("Part")
	basePart.Name = "BasePart"
	basePart.Size = Vector3.new(16, 1, 16)
	basePart.Material = Enum.Material.Ground
	basePart.Color = Color3.fromRGB(101, 67, 33)
	basePart.Anchored = true
	basePart.CFrame = plotCFrame
	basePart.Parent = farmPlot

	farmPlot.PrimaryPart = basePart

	-- Create planting spots (3x3 grid)
	local plantingSpots = Instance.new("Folder")
	plantingSpots.Name = "PlantingSpots"
	plantingSpots.Parent = farmPlot

	local spotSize = 4
	local spacing = 5

	for row = 1, 3 do
		for col = 1, 3 do
			local spotIndex = (row - 1) * 3 + col
			local spotName = "PlantingSpot_" .. spotIndex

			local spotModel = Instance.new("Model")
			spotModel.Name = spotName
			spotModel.Parent = plantingSpots

			local spotPart = Instance.new("Part")
			spotPart.Name = "SpotPart"
			spotPart.Size = Vector3.new(spotSize, 0.2, spotSize)
			spotPart.Material = Enum.Material.LeafyGrass
			spotPart.Color = Color3.fromRGB(91, 154, 76)
			spotPart.Anchored = true
			spotPart.Parent = spotModel

			local offsetX = (col - 2) * spacing
			local offsetZ = (row - 2) * spacing
			spotPart.CFrame = plotCFrame + Vector3.new(offsetX, 1, offsetZ)

			spotModel.PrimaryPart = spotPart

			-- Add attributes for farming system
			spotModel:SetAttribute("IsEmpty", true)
			spotModel:SetAttribute("PlantType", "")
			spotModel:SetAttribute("GrowthStage", 0)
			spotModel:SetAttribute("PlantedTime", 0)

			-- Create visual indicator
			local indicator = Instance.new("Part")
			indicator.Name = "Indicator"
			indicator.Size = Vector3.new(0.5, 2, 0.5)
			indicator.Material = Enum.Material.Neon
			indicator.Color = Color3.fromRGB(100, 255, 100)
			indicator.Anchored = true
			indicator.CFrame = spotPart.CFrame + Vector3.new(0, 1.5, 0)
			indicator.Parent = spotModel

			-- Add click detector for planting
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 10
			clickDetector.Parent = spotPart

			clickDetector.MouseClick:Connect(function(clickingPlayer)
				if clickingPlayer.UserId == player.UserId then
					self:HandlePlotClick(clickingPlayer, spotModel)
				end
			end)
		end
	end

	-- Create plot border and info sign
	self:CreatePlotBorder(farmPlot, plotCFrame)
	self:CreatePlotInfoSign(farmPlot, plotCFrame, player, plotNumber)

	print("GameCore: Created " .. plotName .. " for " .. player.Name)
	return true
end

function GameCore:CreatePlotBorder(farmPlot, plotCFrame)
	local borderHeight = 0.5
	local borderWidth = 0.5
	local plotSize = 16

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
		borderPart.Parent = farmPlot
	end
end

function GameCore:CreatePlotInfoSign(farmPlot, plotCFrame, player, plotNumber)
	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(0.5, 4, 0.5)
	signPost.Material = Enum.Material.Wood
	signPost.Color = Color3.fromRGB(92, 51, 23)
	signPost.Anchored = true
	signPost.CFrame = plotCFrame + Vector3.new(8, 2, -8)
	signPost.Parent = farmPlot

	local signBoard = Instance.new("Part")
	signBoard.Name = "SignBoard"
	signBoard.Size = Vector3.new(3, 2, 0.2)
	signBoard.Material = Enum.Material.Wood
	signBoard.Color = Color3.fromRGB(139, 90, 43)
	signBoard.Anchored = true
	signBoard.CFrame = signPost.CFrame + Vector3.new(1.5, 0.5, 0)
	signBoard.Parent = farmPlot

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signBoard

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = player.Name .. "'s\nFarm Plot #" .. plotNumber
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = surfaceGui
end

function GameCore:HandlePlotClick(player, spotModel)
	local isEmpty = spotModel:GetAttribute("IsEmpty")
	if not isEmpty then
		self:SendNotification(player, "Plot Occupied", "This plot already has something planted!", "warning")
		return
	end

	local plotOwner = self:GetPlotOwner(spotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return
	end

	local playerData = self:GetPlayerData(player)
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

	-- Send to client for seed selection
	self.RemoteEvents.PlantSeed:FireClient(player, spotModel)
end

function GameCore:GetPlotOwner(plotModel)
	local parent = plotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_Farm") then
			return parent.Name:gsub("_Farm", "")
		end

		if parent.Name:find("Farm") and parent.Parent and parent.Parent.Name:find("_Farm") then
			return parent.Parent.Name:gsub("_Farm", "")
		end

		parent = parent.Parent
	end

	warn("GameCore: Could not determine plot owner for " .. plotModel.Name)
	return nil
end

-- ========== LIVESTOCK SYSTEM ==========

function GameCore:InitializeLivestockSystem()
	print("GameCore: Initializing livestock system...")

	-- Find cow model in workspace
	self.Models.Cow = workspace:FindFirstChild("cow")
	if not self.Models.Cow then
		warn("GameCore: Cow model not found in workspace!")
	else
		print("GameCore: Found cow model")
		self:SetupCowIndicator()
	end

	-- Find pig model in workspace  
	self.Models.Pig = workspace:FindFirstChild("Pig")
	if not self.Models.Pig then
		warn("GameCore: Pig model not found in workspace!")
	else
		print("GameCore: Found pig model")
	end

	-- Initialize player-specific livestock data
	self.Systems.Livestock.CowCooldowns = {}
	self.Systems.Livestock.PigStates = {}

	print("GameCore: Livestock system initialized")
end

function GameCore:SetupCowIndicator()
	if not self.Models.Cow then return end

	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(4, 0.2, 4)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0)
	indicator.CanCollide = false
	indicator.Anchored = true

	local cowHead = self.Models.Cow:FindFirstChild("Head")
	if cowHead then
		indicator.Position = cowHead.Position + Vector3.new(0, 5, 0)
		indicator.Orientation = Vector3.new(0, 0, 90)
	end

	indicator.Parent = self.Models.Cow

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = self.Models.Cow:FindFirstChild("HumanoidRootPart") or indicator

	clickDetector.MouseClick:Connect(function(player)
		self:HandleMilkCollection(player)
	end)

	print("GameCore: Cow indicator and click detector setup complete")
end

function GameCore:HandleMilkCollection(player)
	print("🥛 GameCore: Handling milk collection for", player.Name)

	local currentTime = os.time()
	local playerData = self:GetPlayerData(player)

	if not playerData then
		warn("🥛 GameCore: No player data found for", player.Name)
		return false
	end

	-- Initialize livestock data if missing
	if not playerData.livestock then
		playerData.livestock = {
			cow = {lastMilkCollection = 0, totalMilkCollected = 0},
			inventory = {}
		}
	end
	if not playerData.livestock.cow then
		playerData.livestock.cow = {lastMilkCollection = 0, totalMilkCollected = 0}
	end
	if not playerData.livestock.inventory then
		playerData.livestock.inventory = {}
	end

	-- Check cooldown
	local userId = player.UserId
	local lastCollection = 0

	if self.Systems.Livestock.CowCooldowns[userId] then
		lastCollection = math.max(lastCollection, self.Systems.Livestock.CowCooldowns[userId])
	end

	if playerData.livestock.cow.lastMilkCollection then
		lastCollection = math.max(lastCollection, playerData.livestock.cow.lastMilkCollection)
	end

	local cooldown = 60 -- Default 60 seconds

	-- Try to get cooldown from ItemConfig
	local success, upgradeCooldown = pcall(function()
		return ItemConfig.GetMilkCooldown and ItemConfig.GetMilkCooldown(playerData.upgrades or {})
	end)
	if success and type(upgradeCooldown) == "number" then
		cooldown = upgradeCooldown
	end

	local timeSinceCollection = currentTime - lastCollection
	if timeSinceCollection < cooldown then
		local timeLeft = cooldown - timeSinceCollection
		self:SendNotification(player, "🐄 Cow Resting", 
			"The cow needs " .. math.ceil(timeLeft) .. " more seconds to produce milk!", "warning")
		return false
	end

	-- Calculate milk amount
	local milkAmount = 2

	local success, upgradeMilkAmount = pcall(function()
		return ItemConfig.GetMilkAmount and ItemConfig.GetMilkAmount(playerData.upgrades or {})
	end)
	if success and type(upgradeMilkAmount) == "number" then
		milkAmount = upgradeMilkAmount
	end

	-- Store milk in inventory (compatible with shop system)
	playerData.milk = (playerData.milk or 0) + milkAmount
	playerData.livestock.inventory.milk = (playerData.livestock.inventory.milk or 0) + milkAmount

	-- Also store in farming inventory for compatibility
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end
	playerData.farming.inventory.milk = (playerData.farming.inventory.milk or 0) + milkAmount

	-- Update cow data
	playerData.livestock.cow.lastMilkCollection = currentTime
	playerData.livestock.cow.totalMilkCollected = (playerData.livestock.cow.totalMilkCollected or 0) + milkAmount

	-- Update cooldown tracking
	self.Systems.Livestock.CowCooldowns[userId] = currentTime

	-- Update stats
	if not playerData.stats then
		playerData.stats = {}
	end
	playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + milkAmount

	-- Save and update
	self:SavePlayerData(player)
	self:UpdatePlayerLeaderstats(player)

	-- Send player data update
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "🥛 Milk Collected!", 
		"Collected " .. milkAmount .. " fresh milk! Sell it in the shop for coins.", "success")

	print("🥛 GameCore: Successfully processed milk collection for", player.Name)
	return true
end

function GameCore:HandlePigFeeding(player, cropId)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Check if player has the crop
	if not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Crops", "You don't have any crops to feed!", "error")
		return
	end

	local cropCount = playerData.farming.inventory[cropId] or 0
	if cropCount <= 0 then
		local cropData = ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
		local cropName = cropData and cropData.name or cropId
		self:SendNotification(player, "No Crops", "You don't have any " .. cropName .. "!", "error")
		return
	end

	-- Get crop data
	local cropData = ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
	if not cropData or not cropData.cropPoints then
		self:SendNotification(player, "Invalid Crop", "This crop cannot be fed to the pig!", "error")
		return
	end

	-- Initialize pig data if needed
	if not playerData.pig then
		playerData.pig = {
			size = 1.0,
			cropPoints = 0,
			transformationCount = 0,
			totalFed = 0
		}
	end

	-- Feed the pig
	playerData.farming.inventory[cropId] = playerData.farming.inventory[cropId] - 1
	local cropPoints = cropData.cropPoints

	playerData.pig.cropPoints = playerData.pig.cropPoints + cropPoints
	playerData.pig.totalFed = playerData.pig.totalFed + 1

	-- Calculate new pig size
	local newSize = 1.0 + (playerData.pig.cropPoints * (ItemConfig.PigSystem and ItemConfig.PigSystem.growthPerPoint or 0.01))
	playerData.pig.size = math.min(newSize, (ItemConfig.PigSystem and ItemConfig.PigSystem.maxSize or 3.0))

	-- Check for MEGA PIG transformation
	local pointsNeeded = 100 + (playerData.pig.transformationCount * 50)
	local message = "Fed pig with " .. cropData.name .. "! (" .. playerData.pig.cropPoints .. "/" .. pointsNeeded .. " points for MEGA PIG)"

	if playerData.pig.cropPoints >= pointsNeeded then
		message = self:TriggerMegaPigTransformation(player, playerData)
	end

	-- Update pig size in world
	self:UpdatePigSize(playerData.pig.size)

	-- Save and notify
	self:SavePlayerData(player)
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Pig Fed!", message, "success")
end

function GameCore:TriggerMegaPigTransformation(player, playerData)
	print("GameCore: MEGA PIG transformation for " .. player.Name)

	-- Get random exclusive upgrade
	local megaDrop = ItemConfig.GetRandomMegaDrop and ItemConfig.GetRandomMegaDrop() or {
		id = "mega_milk_boost",
		name = "MEGA Milk Boost",
		description = "Milk collection gives +15 extra coins!"
	}

	-- Reset pig
	playerData.pig.cropPoints = 0
	playerData.pig.size = 1.0
	playerData.pig.transformationCount = playerData.pig.transformationCount + 1

	-- Grant the exclusive upgrade
	playerData.upgrades = playerData.upgrades or {}
	playerData.upgrades[megaDrop.id] = true

	-- Create spectacular effect
	self:CreateMegaPigEffect()

	-- Update pig size back to normal
	self:UpdatePigSize(1.0)

	return "🎉 MEGA PIG TRANSFORMATION! 🎉\nReceived exclusive upgrade: " .. megaDrop.name .. "!\nPig reset to normal size."
end

function GameCore:CreateMegaPigEffect()
	if not self.Models.Pig then return end

	spawn(function()
		-- Make pig huge temporarily
		self:UpdatePigSize(5.0)

		-- Create explosion effect
		local explosion = Instance.new("Explosion")
		explosion.Position = self.Models.Pig:FindFirstChild("HumanoidRootPart").Position + Vector3.new(0, 5, 0)
		explosion.BlastRadius = 20
		explosion.BlastPressure = 0
		explosion.Parent = workspace

		-- Create sparkles
		for i = 1, 20 do
			local sparkle = Instance.new("Part")
			sparkle.Size = Vector3.new(0.5, 0.5, 0.5)
			sparkle.Shape = Enum.PartType.Ball
			sparkle.Material = Enum.Material.Neon
			sparkle.Color = Color3.fromRGB(255, 215, 0)
			sparkle.CanCollide = false
			sparkle.Anchored = true
			sparkle.Position = self.Models.Pig:FindFirstChild("HumanoidRootPart").Position + Vector3.new(
				math.random(-10, 10),
				math.random(0, 15),
				math.random(-10, 10)
			)
			sparkle.Parent = workspace

			local tween = TweenService:Create(sparkle,
				TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = sparkle.Position + Vector3.new(0, 20, 0),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				sparkle:Destroy()
			end)
		end

		wait(3)
		self:UpdatePigSize(1.0)
	end)
end

function GameCore:UpdatePigSize(size)
	if not self.Models.Pig then return end

	for _, part in pairs(self.Models.Pig:GetChildren()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * (size / (self.Models.Pig:GetAttribute("CurrentSize") or 1.0))
		end
	end

	self.Models.Pig:SetAttribute("CurrentSize", size)
end

-- ========== FARMING SYSTEM ==========

function GameCore:InitializeFarmingSystem()
	print("GameCore: Farming system initialized")
end

function GameCore:PlantSeed(player, plotModel, seedId)
	print("GameCore: Plant seed request - " .. player.Name .. " wants to plant " .. seedId)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Check if player has farming data
	if not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Farming Data", "You need to set up farming first!", "error")
		return false
	end

	-- Check if player has the seed
	local seedCount = playerData.farming.inventory[seedId] or 0
	if seedCount <= 0 then
		local seedInfo = ItemConfig.GetItem and ItemConfig.GetItem(seedId)
		local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
		self:SendNotification(player, "No Seeds", "You don't have any " .. seedName .. "!", "error")
		return false
	end

	-- Validate the plot model
	if not plotModel or not plotModel.Parent then
		self:SendNotification(player, "Invalid Plot", "Plot not found or invalid!", "error")
		return false
	end

	-- Check if plot is empty
	local isEmpty = plotModel:GetAttribute("IsEmpty")
	if not isEmpty then
		self:SendNotification(player, "Plot Occupied", "This plot already has something planted!", "error")
		return false
	end

	-- Check if this is the player's plot
	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return false
	end

	-- Get seed data
	local seedData = ItemConfig.GetSeedData and ItemConfig.GetSeedData(seedId)
	if not seedData then
		self:SendNotification(player, "Invalid Seed", "Seed data not found!", "error")
		return false
	end

	-- Plant the seed
	local success = self:CreateCropOnPlot(plotModel, seedId, seedData)
	if not success then
		self:SendNotification(player, "Planting Failed", "Could not plant seed on plot!", "error")
		return false
	end

	-- Remove seed from inventory
	playerData.farming.inventory[seedId] = playerData.farming.inventory[seedId] - 1

	-- Update plot attributes
	plotModel:SetAttribute("IsEmpty", false)
	plotModel:SetAttribute("PlantType", seedData.resultCropId)
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", os.time())

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.seedsPlanted = (playerData.stats.seedsPlanted or 0) + 1

	-- Save and notify
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	local seedInfo = ItemConfig.GetItem and ItemConfig.GetItem(seedId)
	local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
	self:SendNotification(player, "🌱 Seed Planted!", 
		"Successfully planted " .. seedName .. "!\nIt will be ready in " .. math.floor(seedData.growTime/60) .. " minutes.", "success")

	print("GameCore: Successfully planted " .. seedId .. " for " .. player.Name)
	return true
end

function GameCore:CreateCropOnPlot(plotModel, seedId, seedData)
	local success, error = pcall(function()
		local spotPart = plotModel:FindFirstChild("SpotPart")
		if not spotPart then
			warn("GameCore: No SpotPart found in plot model")
			return false
		end

		local existingCrop = plotModel:FindFirstChild("CropModel")
		if existingCrop then
			existingCrop:Destroy()
		end

		-- Create crop model
		local cropModel = Instance.new("Model")
		cropModel.Name = "CropModel"
		cropModel.Parent = plotModel

		local cropAppearance = self:GetCropAppearance(seedId)

		-- Create crop part
		local cropPart = Instance.new("Part")
		cropPart.Name = "Crop"
		cropPart.Size = Vector3.new(2, 1, 2)
		cropPart.Material = cropAppearance.material
		cropPart.Color = cropAppearance.color
		cropPart.Anchored = true
		cropPart.CanCollide = false
		cropPart.CFrame = spotPart.CFrame + Vector3.new(0, 1, 0)
		cropPart.Parent = cropModel

		-- Apply crop-specific shape
		if cropAppearance.shape == "corn" then
			cropPart.Shape = Enum.PartType.Cylinder
			cropPart.Size = Vector3.new(0.5, 3, 0.5)
			cropPart.CFrame = spotPart.CFrame + Vector3.new(0, 1.5, 0)
			cropPart.Orientation = Vector3.new(0, 0, 90)
		elseif cropAppearance.shape == "strawberry" then
			cropPart.Shape = Enum.PartType.Ball
			cropPart.Size = Vector3.new(1.5, 1.5, 1.5)
		elseif cropAppearance.shape == "golden" then
			cropPart.Shape = Enum.PartType.Ball
			cropPart.Material = Enum.Material.Neon
			cropPart.Size = Vector3.new(2, 2, 2)
		end

		-- Create crop indicator
		local indicator = Instance.new("Part")
		indicator.Name = "GrowthIndicator"
		indicator.Size = Vector3.new(0.5, 3, 0.5)
		indicator.Material = Enum.Material.Neon
		indicator.Color = Color3.fromRGB(255, 100, 100)
		indicator.Anchored = true
		indicator.CanCollide = false
		indicator.CFrame = spotPart.CFrame + Vector3.new(2, 2, 0)
		indicator.Parent = cropModel

		-- Add click detector for harvesting
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 10
		clickDetector.Parent = cropPart

		clickDetector.MouseClick:Connect(function(clickingPlayer)
			local plotOwner = self:GetPlotOwner(plotModel)
			if clickingPlayer.Name == plotOwner then
				local growthStage = plotModel:GetAttribute("GrowthStage") or 0
				if growthStage >= 4 then
					self:HarvestCrop(clickingPlayer, plotModel)
				else
					self:SendNotification(clickingPlayer, "Not Ready", "Crop is still growing!", "warning")
				end
			end
		end)

		-- Start growth timer
		self:StartCropGrowthTimer(plotModel, seedData, cropAppearance)

		return true
	end)

	if not success then
		warn("GameCore: Failed to create crop on plot: " .. tostring(error))
		return false
	end

	return true
end

function GameCore:GetCropAppearance(seedId)
	local appearances = {
		carrot_seeds = {
			color = Color3.fromRGB(255, 140, 0),
			material = Enum.Material.SmoothPlastic,
			shape = "carrot"
		},
		corn_seeds = {
			color = Color3.fromRGB(255, 255, 0),
			material = Enum.Material.SmoothPlastic,
			shape = "corn"
		},
		strawberry_seeds = {
			color = Color3.fromRGB(220, 20, 60),
			material = Enum.Material.SmoothPlastic,
			shape = "strawberry"
		},
		golden_seeds = {
			color = Color3.fromRGB(255, 215, 0),
			material = Enum.Material.Neon,
			shape = "golden"
		}
	}

	return appearances[seedId] or {
		color = Color3.fromRGB(100, 200, 100),
		material = Enum.Material.LeafyGrass,
		shape = "default"
	}
end

function GameCore:StartCropGrowthTimer(plotModel, seedData, cropAppearance)
	spawn(function()
		local growTime = seedData.growTime
		local stageTime = growTime / 4

		for stage = 0, 3 do
			wait(stageTime)

			if plotModel and plotModel.Parent then
				local currentStage = plotModel:GetAttribute("GrowthStage") or 0
				if currentStage == stage then
					plotModel:SetAttribute("GrowthStage", stage + 1)

					local cropModel = plotModel:FindFirstChild("CropModel")
					if cropModel then
						local indicator = cropModel:FindFirstChild("GrowthIndicator")
						if indicator then
							local colors = {
								Color3.fromRGB(255, 100, 100),
								Color3.fromRGB(255, 200, 100),
								Color3.fromRGB(255, 255, 100),
								Color3.fromRGB(100, 255, 100)
							}
							indicator.Color = colors[stage + 2] or colors[4]
						end

						-- Scale crop as it grows
						local crop = cropModel:FindFirstChild("Crop")
						if crop then
							local baseScale = 0.3 + (stage + 1) * 0.425
							if cropAppearance.shape == "corn" then
								crop.Size = Vector3.new(0.5 * baseScale, 3 * baseScale, 0.5 * baseScale)
							elseif cropAppearance.shape == "strawberry" then
								crop.Size = Vector3.new(1.5 * baseScale, 1.5 * baseScale, 1.5 * baseScale)
							elseif cropAppearance.shape == "golden" then
								crop.Size = Vector3.new(2 * baseScale, 2 * baseScale, 2 * baseScale)
							else
								crop.Size = Vector3.new(2 * baseScale, 1 * baseScale, 2 * baseScale)
							end
						end
					end
				end
			else
				break
			end
		end
	end)
end

function GameCore:HarvestCrop(player, plotModel)
	print("GameCore: Harvest request from " .. player.Name .. " for plot " .. plotModel.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only harvest your own crops!", "error")
		return false
	end

	local growthStage = plotModel:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		self:SendNotification(player, "Not Ready", "Crop is not ready for harvest yet!", "warning")
		return false
	end

	-- Get crop data
	local plantType = plotModel:GetAttribute("PlantType") or ""
	local cropData = ItemConfig.GetCropData and ItemConfig.GetCropData(plantType)
	if not cropData then
		self:SendNotification(player, "Invalid Crop", "Crop data not found for " .. plantType, "error")
		return false
	end

	local baseYield = cropData.yieldAmount or 1

	-- Initialize farming inventory if needed
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	-- Add crops to inventory
	local currentAmount = playerData.farming.inventory[plantType] or 0
	playerData.farming.inventory[plantType] = currentAmount + baseYield

	-- Reset plot
	plotModel:SetAttribute("IsEmpty", true)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", 0)

	-- Remove crop model
	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel then
		cropModel:Destroy()
	end

	-- Restore visual indicator
	local indicator = plotModel:FindFirstChild("Indicator")
	if indicator then
		indicator.Color = Color3.fromRGB(100, 255, 100)
	end

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + baseYield

	-- Save and notify
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "🌾 Crop Harvested!", 
		"Harvested " .. baseYield .. "x " .. cropData.name .. "!", "success")

	print("GameCore: Successfully harvested " .. plantType .. " for " .. player.Name)
	return true
end

function GameCore:HarvestAllCrops(player)
	print("GameCore: Harvest all request from " .. player.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Find all player's farm plots
	local areas = workspace:FindFirstChild("Areas")
	if not areas then
		self:SendNotification(player, "No Farm", "Farm area not found!", "error")
		return false
	end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then
		self:SendNotification(player, "No Farm", "Starter Meadow not found!", "error")
		return false
	end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then
		self:SendNotification(player, "No Farm", "Farm area not found!", "error")
		return false
	end

	local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
	if not playerFarm then
		self:SendNotification(player, "No Farm", "You don't have a farm yet!", "error")
		return false
	end

	local harvestedCount = 0
	local readyCrops = 0
	local totalCrops = 0

	-- Go through all farm plots
	for _, plot in pairs(playerFarm:GetChildren()) do
		if plot:IsA("Model") and plot.Name:find("FarmPlot") then
			local plantingSpots = plot:FindFirstChild("PlantingSpots")
			if plantingSpots then
				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
						local isEmpty = spot:GetAttribute("IsEmpty")
						if not isEmpty then
							totalCrops = totalCrops + 1
							local growthStage = spot:GetAttribute("GrowthStage") or 0

							if growthStage >= 4 then
								readyCrops = readyCrops + 1
								local success = self:HarvestCrop(player, spot)
								if success then
									harvestedCount = harvestedCount + 1
								end
								wait(0.1)
							end
						end
					end
				end
			end
		end
	end

	-- Send summary notification
	if harvestedCount > 0 then
		self:SendNotification(player, "🌾 Mass Harvest Complete!", 
			"Harvested " .. harvestedCount .. " crops!\n" .. 
				(readyCrops - harvestedCount > 0 and (readyCrops - harvestedCount) .. " crops failed to harvest.\n" or "") ..
				(totalCrops - readyCrops > 0 and (totalCrops - readyCrops) .. " crops still growing." or ""), "success")
	else
		if totalCrops == 0 then
			self:SendNotification(player, "No Crops", "You don't have any crops planted!", "info")
		elseif readyCrops == 0 then
			self:SendNotification(player, "Crops Not Ready", "None of your " .. totalCrops .. " crops are ready for harvest yet!", "warning")
		else
			self:SendNotification(player, "Harvest Failed", "Found " .. readyCrops .. " ready crops but couldn't harvest any!", "error")
		end
	end

	print("GameCore: Harvest all complete for " .. player.Name .. " - harvested " .. harvestedCount .. "/" .. readyCrops .. " ready crops")
	return harvestedCount > 0
end

-- ========== PEST AND CHICKEN SYSTEMS ==========

function GameCore:InitializePestAndChickenSystems()
	print("GameCore: Initializing pest and chicken defense systems...")

	-- Initialize pest tracking in player data
	for _, player in pairs(Players:GetPlayers()) do
		local playerData = self:GetPlayerData(player)
		if playerData then
			if not playerData.defense then
				playerData.defense = {
					chickens = {owned = {}, deployed = {}, feed = {}},
					pestControl = {organic_pesticide = 0, pest_detector = false},
					roofs = {}
				}
			end
		end
	end

	print("GameCore: Pest and chicken systems initialized")
end

function GameCore:HandleFeedAllChickens(player)
	print("GameCore: Feed all chickens request from " .. player.Name)
	-- Implementation depends on ChickenSystem integration
	self:SendNotification(player, "🐔 Chickens Fed", "All chickens have been fed!", "success")
end

function GameCore:HandleFeedChickensWithType(player, feedType)
	print("GameCore: Feed chickens with " .. feedType .. " request from " .. player.Name)
	-- Implementation depends on ChickenSystem integration
	self:SendNotification(player, "🐔 Chickens Fed", "Fed chickens with " .. feedType .. "!", "success")
end

-- ========== DATA MANAGEMENT ==========

function GameCore:GetDefaultPlayerData()
	return {
		-- Core Currency
		coins = 100,
		farmTokens = 0,

		-- Progression
		upgrades = {},
		purchaseHistory = {},

		-- Farming System
		farming = {
			plots = 0,
			inventory = {}
		},

		-- Livestock System
		livestock = {
			cow = {
				lastMilkCollection = 0,
				totalMilkCollected = 0
			},
			pig = {
				size = 1.0,
				cropPoints = 0,
				transformationCount = 0,
				totalFed = 0
			},
			inventory = {}
		},

		-- Defense System (Pest & Chicken)
		defense = {
			chickens = {
				owned = {},
				deployed = {},
				feed = {}
			},
			pestControl = {
				organic_pesticide = 0,
				pest_detector = false
			},
			roofs = {}
		},

		-- Statistics
		stats = {
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0,
			seedsPlanted = 0,
			pestsEliminated = 0
		},

		-- Session Data
		firstJoin = os.time(),
		lastSave = os.time()
	}
end

function GameCore:GetPlayerData(player)
	if not self.PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return self.PlayerData[player.UserId]
end

function GameCore:LoadPlayerData(player)
	local defaultData = self:GetDefaultPlayerData()
	local loadedData = defaultData

	if self.PlayerDataStore then
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			-- Deep merge to ensure all fields exist
			loadedData = self:DeepMerge(defaultData, data)
			print("GameCore: Loaded existing data for " .. player.Name)
		else
			print("GameCore: Using default data for " .. player.Name)
		end
	end

	self.PlayerData[player.UserId] = loadedData
	self:InitializePlayerSystems(player, loadedData)
	self:UpdatePlayerLeaderstats(player)

	return loadedData
end

function GameCore:DeepMerge(default, loaded)
	local result = {}

	for key, value in pairs(default) do
		if type(value) == "table" then
			result[key] = self:DeepMerge(value, loaded[key] or {})
		else
			result[key] = loaded[key] ~= nil and loaded[key] or value
		end
	end

	for key, value in pairs(loaded) do
		if result[key] == nil then
			result[key] = value
		end
	end

	return result
end

function GameCore:InitializePlayerSystems(player, playerData)
	print("GameCore: Initializing player systems for " .. player.Name)

	-- Initialize farm if player has plots
	if playerData.farming and playerData.farming.plots and playerData.farming.plots > 0 then
		for plotNumber = 1, playerData.farming.plots do
			local success = pcall(function()
				self:CreatePlayerFarmPlot(player, plotNumber)
			end)
			if not success then
				warn("GameCore: Failed to create farm plot " .. plotNumber .. " for " .. player.Name)
			end
		end
	end

	-- Initialize livestock systems
	if not self.Systems.Livestock.CowCooldowns[player.UserId] then
		self.Systems.Livestock.CowCooldowns[player.UserId] = 0
	end

	if not self.Systems.Livestock.PigStates[player.UserId] then
		self.Systems.Livestock.PigStates[player.UserId] = {
			lastFeedTime = 0,
			currentSize = playerData.livestock and playerData.livestock.pig and playerData.livestock.pig.size or 1.0
		}
	end

	print("GameCore: Player systems initialized for " .. player.Name)
end

function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local currentTime = os.time()

	if not forceImmediate then
		local lastSave = self.DataStoreCooldowns[userId] or 0
		if currentTime - lastSave < self.SAVE_COOLDOWN then
			return
		end
	end

	local playerData = self.PlayerData[userId]
	if not playerData then return end

	local success, errorMsg = pcall(function()
		self.PlayerDataStore:SetAsync("Player_" .. userId, {
			coins = playerData.coins or 0,
			farmTokens = playerData.farmTokens or 0,
			upgrades = playerData.upgrades or {},
			stats = playerData.stats or {},
			purchaseHistory = playerData.purchaseHistory or {},
			farming = playerData.farming or {plots = 0, inventory = {}},
			livestock = playerData.livestock or {},
			defense = playerData.defense or {},
			pig = playerData.pig or {size = 1.0, cropPoints = 0, transformationCount = 0, totalFed = 0},
			lastSave = currentTime
		})
	end)

	if success then
		self.DataStoreCooldowns[userId] = currentTime
		print("GameCore: Successfully saved data for " .. player.Name)
	else
		warn("GameCore: Failed to save data for " .. player.Name .. ": " .. tostring(errorMsg))
	end
end

function GameCore:CreatePlayerLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = self.PlayerData[player.UserId].coins
	coins.Parent = leaderstats

	local farmTokens = Instance.new("IntValue")
	farmTokens.Name = "Farm Tokens"
	farmTokens.Value = self.PlayerData[player.UserId].farmTokens or 0
	farmTokens.Parent = leaderstats
end

function GameCore:UpdatePlayerLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then 
		self:CreatePlayerLeaderstats(player)
		return
	end

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then coins.Value = playerData.coins end

	local farmTokens = leaderstats:FindFirstChild("Farm Tokens")
	if farmTokens then farmTokens.Value = playerData.farmTokens or 0 end
end

-- ========== UPDATE LOOPS ==========

function GameCore:StartUpdateLoops()
	print("GameCore: Starting update loops...")

	-- Cow indicator update loop
	spawn(function()
		while true do
			wait(1)
			self:UpdateCowIndicator()
		end
	end)

	-- Auto-save loop
	spawn(function()
		while true do
			wait(300) -- Save every 5 minutes
			for _, player in ipairs(Players:GetPlayers()) do
				if player and player.Parent and self.PlayerData[player.UserId] then
					pcall(function()
						self:SavePlayerData(player)
					end)
				end
			end
		end
	end)
end

function GameCore:UpdateCowIndicator()
	if not self.Models.Cow then return end

	local indicator = self.Models.Cow:FindFirstChild("MilkIndicator")
	if not indicator then return end

	local anyPlayerReady = false
	local shortestWait = math.huge

	for userId, lastCollection in pairs(self.Systems.Livestock.CowCooldowns) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local playerData = self:GetPlayerData(player)
			local cooldown = 60 -- Default cooldown
			if ItemConfig.GetMilkCooldown then
				cooldown = ItemConfig.GetMilkCooldown(playerData.upgrades or {})
			end

			local timeSinceCollection = os.time() - lastCollection
			local timeLeft = cooldown - timeSinceCollection

			if timeLeft <= 0 then
				anyPlayerReady = true
				break
			else
				shortestWait = math.min(shortestWait, timeLeft)
			end
		end
	end

	if next(self.Systems.Livestock.CowCooldowns) == nil then
		anyPlayerReady = true
	end

	-- Update indicator color
	if anyPlayerReady then
		indicator.Color = Color3.fromRGB(0, 255, 0) -- Green - ready
	elseif shortestWait <= 10 then
		indicator.Color = Color3.fromRGB(255, 255, 0) -- Yellow - almost ready
	else
		indicator.Color = Color3.fromRGB(255, 0, 0) -- Red - not ready
	end
end

-- ========== UTILITY FUNCTIONS ==========

function GameCore:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

function GameCore:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		local success = pcall(function()
			self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
		end)
		if success then
			print("🔔 GameCore: Sent notification to", player.Name, "-", title)
			return
		end
	end

	print("🔔 NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
end

-- ========== ADMIN COMMANDS ==========

function GameCore:SetupAdminCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			-- Replace with your username
			if player.Name == "TommySalami311" then
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/showfarmpositions" then
					print("=== FARM PLOT POSITIONS FOR " .. player.Name .. " ===")
					for i = 1, 10 do
						local position = self:GetFarmPlotPosition(player, i)
						print("Plot " .. i .. ": " .. tostring(position))

						local marker = Instance.new("Part")
						marker.Name = "PlotMarker_" .. i
						marker.Size = Vector3.new(2, 8, 2)
						marker.Material = Enum.Material.Neon
						marker.Color = Color3.fromRGB(255, 0, 255)
						marker.Anchored = true
						marker.CanCollide = false
						marker.CFrame = position + Vector3.new(0, 4, 0)
						marker.Parent = workspace

						local billboardGui = Instance.new("BillboardGui")
						billboardGui.Size = UDim2.new(0, 100, 0, 50)
						billboardGui.Parent = marker

						local label = Instance.new("TextLabel")
						label.Size = UDim2.new(1, 0, 1, 0)
						label.BackgroundTransparency = 1
						label.Text = "Plot " .. i
						label.TextColor3 = Color3.new(1, 1, 1)
						label.TextScaled = true
						label.Font = Enum.Font.GothamBold
						label.Parent = billboardGui

						Debris:AddItem(marker, 10)
					end
					print("=== Temporary markers placed for 10 seconds ===")

				elseif command == "/giveseeds" then
					local playerData = self:GetPlayerData(player)
					if playerData then
						if not playerData.farming then
							playerData.farming = {plots = 1, inventory = {}}
						end
						if not playerData.farming.inventory then
							playerData.farming.inventory = {}
						end

						playerData.farming.inventory.carrot_seeds = 10
						playerData.farming.inventory.corn_seeds = 8
						playerData.farming.inventory.strawberry_seeds = 5
						playerData.farming.inventory.golden_seeds = 3

						self:SavePlayerData(player)
						self:SendNotification(player, "Admin: Seeds Given", 
							"Added all seed types to your inventory!", "success")

						if self.RemoteEvents.PlayerDataUpdated then
							self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
						end
						print("Admin: Gave all seeds to " .. player.Name)
					end

				elseif command == "/givefarmplot" then
					local playerData = self:GetPlayerData(player)
					if playerData then
						playerData.purchaseHistory = playerData.purchaseHistory or {}
						playerData.purchaseHistory.farm_plot_starter = true
						playerData.farming = playerData.farming or {
							plots = 1, 
							inventory = {
								carrot_seeds = 5, 
								corn_seeds = 3
							}
						}

						self:CreatePlayerFarmPlot(player, 1)
						self:SavePlayerData(player)

						if self.RemoteEvents.PlayerDataUpdated then
							self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
						end

						self:SendNotification(player, "Admin Gift", "You received a free farm plot!", "success")
						print("Admin: Gave farm plot to " .. player.Name)
					end

				elseif command == "/debugmilk" then
					self:DebugMilkSystem(player)

				elseif command == "/testmilk" then
					self:HandleMilkCollection(player)
				end
			end
		end)
	end)

	print("GameCore: Admin commands setup complete")
end

function GameCore:DebugMilkSystem(player)
	print("=== MILK SYSTEM DEBUG FOR " .. player.Name .. " ===")

	local playerData = self:GetPlayerData(player)
	if not playerData then
		print("❌ No player data found")
		return
	end

	print("Player data structure:")
	print("  Has livestock:", playerData.livestock ~= nil)
	if playerData.livestock then
		print("  Has cow data:", playerData.livestock.cow ~= nil)
		print("  Has livestock inventory:", playerData.livestock.inventory ~= nil)
		if playerData.livestock.cow then
			print("  Last collection:", playerData.livestock.cow.lastMilkCollection or 0)
			print("  Total collected:", playerData.livestock.cow.totalMilkCollected or 0)
		end
		if playerData.livestock.inventory then
			print("  Milk in livestock inventory:", playerData.livestock.inventory.milk or 0)
		end
	end

	print("Other milk storage:")
	print("  Direct milk property:", playerData.milk or 0)
	if playerData.farming and playerData.farming.inventory then
		print("  Milk in farming inventory:", playerData.farming.inventory.milk or 0)
	end

	print("============================================")
end

-- ========== PLAYER EVENTS ==========

Players.PlayerAdded:Connect(function(player)
	GameCore:LoadPlayerData(player)
	GameCore:CreatePlayerLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	GameCore:SavePlayerData(player, true)
	-- Clean up cooldowns
	GameCore.Systems.Livestock.CowCooldowns[player.UserId] = nil
	GameCore.Systems.Livestock.PigStates[player.UserId] = nil
end)

-- Make globally available
_G.GameCore = GameCore

print("GameCore: ✅ Core game system loaded successfully!")
print("Shop functionality is handled by separate ShopSystem module")
print("Features included:")
print("  🐄 Livestock system (cow milking, pig feeding)")
print("  🌾 Farming system (planting, growing, harvesting)")
print("  🛡️ Pest and chicken defense system integration")
print("  💾 Player data management")
print("  🏡 Farm plot creation and management")
print("  📊 Statistics and progression tracking")

return GameCore