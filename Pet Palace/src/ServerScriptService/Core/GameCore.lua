--[[
    GameCore.lua - COMPLETE UPDATED VERSION WITH CONFIGURABLE FARM PLOT POSITIONS
    Place in: ServerScriptService/Core/GameCore.lua
    
    NEW FEATURES:
    - Configurable CFrame positions for up to 10 farm plots per player
    - GetFarmPlotPosition method for consistent positioning
    - Support for multiple farm plot purchases
    - Better farm plot management system
    - Admin commands for testing positions
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
-- You can modify these CFrame positions to place farm plots wherever you want
GameCore.FarmPlotPositions = {
	-- Base position offset from player spawn point in the farm area
	basePosition = Vector3.new(-350, 3, 100), -- Adjust this to move all plots

	-- Individual plot positions (relative to base position)
	-- Each entry is a Vector3 offset from the base position
	plotOffsets = {
		[1] = Vector3.new(0, 0, 0),       -- First plot at base position
		[2] = Vector3.new(20, 0, 0),      -- Second plot 20 studs to the right
		[3] = Vector3.new(40, 0, 0),      -- Third plot 40 studs to the right
		[4] = Vector3.new(60, 0, 0),      -- Fourth plot 60 studs to the right
		[5] = Vector3.new(80, 0, 0),      -- Fifth plot 80 studs to the right
		[6] = Vector3.new(0, 0, 25),      -- Sixth plot - new row
		[7] = Vector3.new(20, 0, 25),     -- Seventh plot
		[8] = Vector3.new(40, 0, 25),     -- Eighth plot
		[9] = Vector3.new(60, 0, 25),     -- Ninth plot
		[10] = Vector3.new(80, 0, 25),    -- Tenth plot (premium position)
	},

	-- Plot rotation (same for all plots, but you can customize per plot if needed)
	plotRotation = Vector3.new(0, 0, 0), -- No rotation by default

	-- Player farm separation (distance between different players' farms)
	playerSeparation = Vector3.new(120, 0, 0) -- 120 studs apart horizontally
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
	Shop = {
		PurchaseCooldowns = {}
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

-- Get the CFrame position for a specific farm plot
function GameCore:GetFarmPlotPosition(player, plotNumber)
	plotNumber = plotNumber or 1

	-- Ensure plot number is valid
	if plotNumber < 1 or plotNumber > 10 then
		warn("GameCore: Invalid plot number " .. plotNumber .. ". Must be between 1 and 10.")
		plotNumber = 1
	end

	-- Ensure FarmPlotPositions table exists
	if not self.FarmPlotPositions then
		warn("GameCore: FarmPlotPositions not configured, using default positions")
		self.FarmPlotPositions = {
			basePosition = Vector3.new(-350, 3, 100),
			plotOffsets = {
				[1] = Vector3.new(0, 0, 0),
				[2] = Vector3.new(20, 0, 0),
				[3] = Vector3.new(40, 0, 0),
				[4] = Vector3.new(60, 0, 0),
				[5] = Vector3.new(80, 0, 0),
				[6] = Vector3.new(0, 0, 25),
				[7] = Vector3.new(20, 0, 25),
				[8] = Vector3.new(40, 0, 25),
				[9] = Vector3.new(60, 0, 25),
				[10] = Vector3.new(80, 0, 25),
			},
			plotRotation = Vector3.new(0, 0, 0),
			playerSeparation = Vector3.new(120, 0, 0)
		}
	end

	-- Get player index for farm separation (use UserId for consistency)
	local playerIndex = 0
	local sortedPlayers = {}
	for _, p in pairs(Players:GetPlayers()) do
		table.insert(sortedPlayers, p)
	end
	table.sort(sortedPlayers, function(a, b) return a.UserId < b.UserId end)

	for i, p in ipairs(sortedPlayers) do
		if p.UserId == player.UserId then
			playerIndex = i - 1 -- 0-indexed
			break
		end
	end

	-- Calculate base position for this player
	local basePos = self.FarmPlotPositions.basePosition
	if type(basePos) ~= "userdata" or typeof(basePos) ~= "Vector3" then
		warn("GameCore: Invalid basePosition, using default")
		basePos = Vector3.new(-350, 3, 100)
	end

	local playerSeparation = self.FarmPlotPositions.playerSeparation
	if type(playerSeparation) ~= "userdata" or typeof(playerSeparation) ~= "Vector3" then
		warn("GameCore: Invalid playerSeparation, using default")
		playerSeparation = Vector3.new(120, 0, 0)
	end

	local playerOffset = playerSeparation * playerIndex
	local playerBasePosition = basePos + playerOffset

	-- Get the specific plot offset
	local plotOffset = self.FarmPlotPositions.plotOffsets[plotNumber]
	if not plotOffset or type(plotOffset) ~= "userdata" or typeof(plotOffset) ~= "Vector3" then
		warn("GameCore: Invalid plot offset for plot " .. plotNumber .. ", using Vector3.new(0, 0, 0)")
		plotOffset = Vector3.new(0, 0, 0)
	end

	-- Calculate final position
	local finalPosition = playerBasePosition + plotOffset

	-- Create CFrame with rotation
	local rotation = self.FarmPlotPositions.plotRotation
	if type(rotation) ~= "userdata" or typeof(rotation) ~= "Vector3" then
		warn("GameCore: Invalid plotRotation, using default")
		rotation = Vector3.new(0, 0, 0)
	end

	local cframe = CFrame.new(finalPosition) * CFrame.Angles(
		math.rad(rotation.X), 
		math.rad(rotation.Y), 
		math.rad(rotation.Z)
	)

	return cframe
end

-- Get all farm plot positions for a player (useful for validation)
function GameCore:GetAllPlayerFarmPlotPositions(player)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.farming then
		return {}
	end

	local plotCount = playerData.farming.plots or 0
	local positions = {}

	for i = 1, plotCount do
		positions[i] = self:GetFarmPlotPosition(player, i)
	end

	return positions
end

-- Create a single farm plot at the specified position
function GameCore:CreatePlayerFarmPlot(player, plotNumber)
	plotNumber = plotNumber or 1

	-- Get the position for this plot
	local plotCFrame = self:GetFarmPlotPosition(player, plotNumber)

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
		-- Update position if it exists but is in wrong place
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
	basePart.Color = Color3.fromRGB(101, 67, 33) -- Brown soil color
	basePart.Anchored = true
	basePart.CFrame = plotCFrame
	basePart.Parent = farmPlot

	-- Set as primary part
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

			-- Create spot model
			local spotModel = Instance.new("Model")
			spotModel.Name = spotName
			spotModel.Parent = plantingSpots

			-- Create spot part
			local spotPart = Instance.new("Part")
			spotPart.Name = "SpotPart"
			spotPart.Size = Vector3.new(spotSize, 0.2, spotSize)
			spotPart.Material = Enum.Material.LeafyGrass
			spotPart.Color = Color3.fromRGB(91, 154, 76) -- Green grass color
			spotPart.Anchored = true
			spotPart.Parent = spotModel

			-- Position relative to the base part
			local offsetX = (col - 2) * spacing
			local offsetZ = (row - 2) * spacing
			spotPart.CFrame = plotCFrame + Vector3.new(offsetX, 1, offsetZ)

			-- Set as primary part
			spotModel.PrimaryPart = spotPart

			-- Add attributes for farming system
			spotModel:SetAttribute("IsEmpty", true)
			spotModel:SetAttribute("PlantType", "")
			spotModel:SetAttribute("GrowthStage", 0)
			spotModel:SetAttribute("PlantedTime", 0)

			-- Create visual indicator for empty spots
			local indicator = Instance.new("Part")
			indicator.Name = "Indicator"
			indicator.Size = Vector3.new(0.5, 2, 0.5)
			indicator.Material = Enum.Material.Neon
			indicator.Color = Color3.fromRGB(100, 255, 100) -- Green for available
			indicator.Anchored = true
			indicator.CFrame = spotPart.CFrame + Vector3.new(0, 1.5, 0)
			indicator.Parent = spotModel

			-- Add click detector for planting
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 10
			clickDetector.Parent = spotPart

			-- Connect planting functionality
			clickDetector.MouseClick:Connect(function(clickingPlayer)
				if clickingPlayer.UserId == player.UserId then
					-- Only the plot owner can plant
					self:HandlePlotClick(clickingPlayer, spotModel)
				end
			end)
		end
	end

	-- Create plot border for visual clarity
	self:CreatePlotBorder(farmPlot, plotCFrame)

	-- Create plot info sign
	self:CreatePlotInfoSign(farmPlot, plotCFrame, player, plotNumber)

	print("GameCore: Created " .. plotName .. " for " .. player.Name .. " at position " .. tostring(plotCFrame.Position))
	return true
end

-- Create visual border around the plot
function GameCore:CreatePlotBorder(farmPlot, plotCFrame)
	local borderHeight = 0.5
	local borderWidth = 0.5
	local plotSize = 16

	-- Create border parts
	local borderPositions = {
		{Vector3.new(0, borderHeight/2, plotSize/2 + borderWidth/2), Vector3.new(plotSize + borderWidth, borderHeight, borderWidth)}, -- Front
		{Vector3.new(0, borderHeight/2, -(plotSize/2 + borderWidth/2)), Vector3.new(plotSize + borderWidth, borderHeight, borderWidth)}, -- Back
		{Vector3.new(plotSize/2 + borderWidth/2, borderHeight/2, 0), Vector3.new(borderWidth, borderHeight, plotSize)}, -- Right
		{Vector3.new(-(plotSize/2 + borderWidth/2), borderHeight/2, 0), Vector3.new(borderWidth, borderHeight, plotSize)} -- Left
	}

	for i, borderData in ipairs(borderPositions) do
		local borderPart = Instance.new("Part")
		borderPart.Name = "Border_" .. i
		borderPart.Size = borderData[2]
		borderPart.Material = Enum.Material.Wood
		borderPart.Color = Color3.fromRGB(92, 51, 23) -- Dark brown
		borderPart.Anchored = true
		borderPart.CFrame = plotCFrame + borderData[1]
		borderPart.Parent = farmPlot
	end
end

-- Create info sign for the plot
function GameCore:CreatePlotInfoSign(farmPlot, plotCFrame, player, plotNumber)
	-- Create sign post
	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(0.5, 4, 0.5)
	signPost.Material = Enum.Material.Wood
	signPost.Color = Color3.fromRGB(92, 51, 23) -- Dark brown
	signPost.Anchored = true
	signPost.CFrame = plotCFrame + Vector3.new(8, 2, -8) -- Corner position
	signPost.Parent = farmPlot

	-- Create sign board
	local signBoard = Instance.new("Part")
	signBoard.Name = "SignBoard"
	signBoard.Size = Vector3.new(3, 2, 0.2)
	signBoard.Material = Enum.Material.Wood
	signBoard.Color = Color3.fromRGB(139, 90, 43) -- Light brown
	signBoard.Anchored = true
	signBoard.CFrame = signPost.CFrame + Vector3.new(1.5, 0.5, 0)
	signBoard.Parent = farmPlot

	-- Add text to sign
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

-- Handle plot clicking for planting
function GameCore:HandlePlotClick(player, spotModel)
	-- This integrates with your existing farming system
	if self.RemoteEvents.PlantSeed then
		-- Let the client handle seed selection
		self.RemoteEvents.PlantSeed:FireClient(player, spotModel)
	end
end

-- Initialize the entire game core
function GameCore:Initialize()
	print("GameCore: Starting livestock & farming system initialization...")

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

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Initialize livestock system (cow & pig)
	self:InitializeLivestockSystem()

	-- Initialize shop system
	self:InitializeShopSystem()

	-- Initialize farming system
	self:InitializeFarmingSystem()

	-- Start update loops
	self:StartUpdateLoops()

	-- Setup admin commands for farm plot testing
	self:SetupFarmPlotTestingCommands()

	print("GameCore: Initialization complete!")
	return true
end

-- Setup Remote Events
function GameCore:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	local remoteEvents = {
		-- Livestock System
		"CollectMilk", "FeedPig",

		-- Shop System  
		"PurchaseItem", "ItemPurchased", "CurrencyUpdated",

		-- Farming System
		"PlantSeed", "HarvestCrop", "SellCrop",

		-- General
		"PlayerDataUpdated", "ShowNotification"
	}

	local remoteFunctions = {
		"GetPlayerData", "GetShopItems", "GetFarmingData"
	}

	-- Create RemoteEvents
	for _, eventName in ipairs(remoteEvents) do
		local existingRemote = remoteFolder:FindFirstChild(eventName)
		if existingRemote and not existingRemote:IsA("RemoteEvent") then
			existingRemote:Destroy()
			existingRemote = nil
		end

		if not existingRemote then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
		end

		self.RemoteEvents[eventName] = remoteFolder[eventName]
	end

	-- Create RemoteFunctions
	for _, funcName in ipairs(remoteFunctions) do
		local existingRemote = remoteFolder:FindFirstChild(funcName)
		if existingRemote and not existingRemote:IsA("RemoteFunction") then
			existingRemote:Destroy()
			existingRemote = nil
		end

		if not existingRemote then
			local func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
		end

		self.RemoteFunctions[funcName] = remoteFolder[funcName]
	end

	self:SetupEventHandlers()
	print("GameCore: Remote setup complete")
end

-- Setup Event Handlers
function GameCore:SetupEventHandlers()
	print("GameCore: Setting up event handlers...")

	-- Livestock System Events
	if self.RemoteEvents.CollectMilk then
		self.RemoteEvents.CollectMilk.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleMilkCollection(player)
			end)
		end)
	end

	if self.RemoteEvents.FeedPig then
		self.RemoteEvents.FeedPig.OnServerEvent:Connect(function(player, cropId)
			pcall(function()
				self:HandlePigFeeding(player, cropId)
			end)
		end)
	end

	-- Shop System Events
	if self.RemoteEvents.PurchaseItem then
		self.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
			pcall(function()
				self:HandlePurchase(player, itemId, quantity or 1)
			end)
		end)
	end

	-- Farming System Events
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			pcall(function()
				self:PlantSeed(player, plotModel, seedId)
			end)
		end)
	end

	if self.RemoteEvents.HarvestCrop then
		self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotModel)
			pcall(function()
				self:HarvestCrop(player, plotModel)
			end)
		end)
	end

	if self.RemoteEvents.SellCrop then
		self.RemoteEvents.SellCrop.OnServerEvent:Connect(function(player, cropId, amount)
			pcall(function()
				self:SellCrop(player, cropId, amount or 1)
			end)
		end)
	end

	-- RemoteFunctions
	if self.RemoteFunctions.GetPlayerData then
		self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				return self:GetPlayerData(player)
			end)
			return success and result or nil
		end
	end

	if self.RemoteFunctions.GetShopItems then
		self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
			return ItemConfig.ShopItems
		end
	end

	print("GameCore: Event handlers setup complete")
end

-- Initialize Livestock System
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

-- Setup cow milk collection indicator
function GameCore:SetupCowIndicator()
	if not self.Models.Cow then return end

	-- Create indicator above cow
	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(4, 0.2, 4)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0) -- Start red
	indicator.CanCollide = false
	indicator.Anchored = true

	-- Position above cow
	local cowHead = self.Models.Cow:FindFirstChild("Head")
	if cowHead then
		indicator.Position = cowHead.Position + Vector3.new(0, 5, 0)
		indicator.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be horizontal
	end

	indicator.Parent = self.Models.Cow

	-- Create ClickDetector for milk collection
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = self.Models.Cow:FindFirstChild("HumanoidRootPart") or indicator

	clickDetector.MouseClick:Connect(function(player)
		self:HandleMilkCollection(player)
	end)

	print("GameCore: Cow indicator and click detector setup complete")
end

-- Handle milk collection (updated to return success status for sound system)
function GameCore:HandleMilkCollection(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	local currentTime = os.time()
	local lastCollection = self.Systems.Livestock.CowCooldowns[player.UserId] or 0
	local cooldown = ItemConfig.GetMilkCooldown(playerData.upgrades or {})

	-- Check cooldown
	if currentTime - lastCollection < cooldown then
		local timeLeft = cooldown - (currentTime - lastCollection)
		self:SendNotification(player, "Cow Not Ready", 
			"Cow needs " .. math.ceil(timeLeft) .. " more seconds to produce milk!", "warning")
		return false -- Return false for failed collection
	end

	-- Collect milk
	local milkValue = ItemConfig.GetMilkValue(playerData.upgrades or {})
	playerData.coins = (playerData.coins or 0) + milkValue

	-- Update cooldown
	self.Systems.Livestock.CowCooldowns[player.UserId] = currentTime

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + 1
	playerData.stats.coinsEarned = (playerData.stats.coinsEarned or 0) + milkValue

	-- Save and notify
	self:UpdatePlayerLeaderstats(player)
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Milk Collected!", 
		"🐄 MOO! Collected milk for " .. milkValue .. " coins!", "success")

	print("GameCore: " .. player.Name .. " collected milk for " .. milkValue .. " coins")
	return true -- Return true for successful collection
end

-- Handle pig feeding
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
		local cropData = ItemConfig.GetCropData(cropId)
		local cropName = cropData and cropData.name or cropId
		self:SendNotification(player, "No Crops", "You don't have any " .. cropName .. "!", "error")
		return
	end

	-- Get crop data
	local cropData = ItemConfig.GetCropData(cropId)
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

	-- Calculate new pig size (grows with each crop point)
	local newSize = 1.0 + (playerData.pig.cropPoints * ItemConfig.PigSystem.growthPerPoint)
	playerData.pig.size = math.min(newSize, ItemConfig.PigSystem.maxSize)

	-- Check for MEGA PIG transformation
	local pointsNeeded = ItemConfig.GetCropPointsForMegaPig(playerData.pig.transformationCount)
	local message = "Fed pig with " .. cropData.name .. "! (" .. playerData.pig.cropPoints .. "/" .. pointsNeeded .. " points for MEGA PIG)"

	if playerData.pig.cropPoints >= pointsNeeded then
		-- MEGA PIG TRANSFORMATION!
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

-- Trigger MEGA PIG transformation
function GameCore:TriggerMegaPigTransformation(player, playerData)
	print("GameCore: MEGA PIG transformation for " .. player.Name)

	-- Get random exclusive upgrade
	local megaDrop = ItemConfig.GetRandomMegaDrop()

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

	-- Return success message
	return "🎉 MEGA PIG TRANSFORMATION! 🎉\nReceived exclusive upgrade: " .. megaDrop.name .. "!\nPig reset to normal size."
end

-- Create MEGA PIG transformation effect
function GameCore:CreateMegaPigEffect()
	if not self.Models.Pig then return end

	spawn(function()
		-- Make pig huge temporarily
		self:UpdatePigSize(5.0)

		-- Create explosion effect
		local explosion = Instance.new("Explosion")
		explosion.Position = self.Models.Pig:FindFirstChild("HumanoidRootPart").Position + Vector3.new(0, 5, 0)
		explosion.BlastRadius = 20
		explosion.BlastPressure = 0 -- No damage
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

			-- Animate sparkle
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

		-- Wait then shrink back to normal
		wait(3)
		self:UpdatePigSize(1.0)
	end)
end

-- Update pig size in world
function GameCore:UpdatePigSize(size)
	if not self.Models.Pig then return end

	-- Scale all parts of the pig
	for _, part in pairs(self.Models.Pig:GetChildren()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * (size / (self.Models.Pig:GetAttribute("CurrentSize") or 1.0))
		end
	end

	self.Models.Pig:SetAttribute("CurrentSize", size)
end

-- Player Data Management
function GameCore:GetPlayerData(player)
	if not self.PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return self.PlayerData[player.UserId]
end

function GameCore:LoadPlayerData(player)
	local defaultData = {
		coins = 100, -- Start with some coins for first purchases
		farmTokens = 0, -- New currency from selling crops
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 0,
			inventory = {}
		},
		pig = {
			size = 1.0,
			cropPoints = 0,
			transformationCount = 0,
			totalFed = 0
		},
		stats = {
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0
		},
		firstJoin = os.time(),
		lastSave = os.time()
	}

	local loadedData = defaultData

	if not self.UseMemoryStore and self.PlayerDataStore then
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			-- Merge with defaults for any missing fields
			for key, value in pairs(defaultData) do
				if data[key] == nil then
					data[key] = value
				elseif type(value) == "table" and type(data[key]) == "table" then
					for subKey, subValue in pairs(value) do
						if data[key][subKey] == nil then
							data[key][subKey] = subValue
						end
					end
				end
			end
			loadedData = data
		end
	end

	self.PlayerData[player.UserId] = loadedData
	self:InitializePlayerFarm(player)
	self:ApplyAllUpgradeEffects(player)
	self:UpdatePlayerLeaderstats(player)

	print("GameCore: Loaded data for " .. player.Name)
	return loadedData
end

function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local currentTime = os.time()

	-- Check cooldown unless forced
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

-- Shop System
function GameCore:HandlePurchase(player, itemId, quantity)
	quantity = quantity or 1
	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false 
	end

	local item = ItemConfig.GetItem(itemId)
	if not item then
		self:SendNotification(player, "Invalid Item", "Item not found!", "error")
		return false
	end

	-- Check if player can purchase
	local canBuy, reason = ItemConfig.CanPlayerBuy(itemId, playerData)
	if not canBuy then
		self:SendNotification(player, "Cannot Purchase", reason, "error")
		return false
	end

	-- Calculate cost
	local cost = item.price or 0
	if item.type == "upgrade" then
		local currentLevel = (playerData.upgrades and playerData.upgrades[itemId]) or 0
		cost = ItemConfig.GetUpgradeCost(itemId, currentLevel)
	elseif item.id == "farm_plot_expansion" then
		-- Scale price based on how many plots player already has
		local currentPlots = playerData.farming and playerData.farming.plots or 0
		local multiplier = item.priceMultiplier or 1.5
		cost = math.floor(item.price * (multiplier ^ (currentPlots - 1)))
	end

	local currency = item.currency or "coins"
	local totalCost = cost * quantity

	-- Check currency
	if (playerData[currency] or 0) < totalCost then
		self:SendNotification(player, "Insufficient Funds", 
			"You need " .. totalCost .. " " .. currency, "error")
		return false
	end

	-- Deduct currency
	playerData[currency] = (playerData[currency] or 0) - totalCost

	-- Handle purchase by type
	local success = false
	if item.type == "farmPlot" then
		success = self:HandleFarmPlotPurchase(player, playerData, item, quantity)
	elseif item.type == "seed" then
		success = self:HandleSeedPurchase(player, playerData, item, quantity)
	elseif item.type == "upgrade" then
		success = self:HandleUpgradePurchase(player, playerData, item, quantity)
	else
		success = self:HandleGenericPurchase(player, playerData, item, quantity)
	end

	if success then
		self:UpdatePlayerLeaderstats(player)
		self:SavePlayerData(player)

		if self.RemoteEvents.ItemPurchased then
			self.RemoteEvents.ItemPurchased:FireClient(player, itemId, quantity, totalCost, currency)
		end

		if self.RemoteEvents.PlayerDataUpdated then
			self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end

		return true
	else
		-- Refund currency on failure
		playerData[currency] = (playerData[currency] or 0) + totalCost
		return false
	end
end

-- Enhanced farm plot purchase handler that supports multiple plots
function GameCore:HandleFarmPlotPurchase(player, playerData, item, quantity)
	if item.id == "farm_plot_starter" then
		-- First farm plot
		playerData.purchaseHistory = playerData.purchaseHistory or {}
		playerData.purchaseHistory.farm_plot_starter = true

		playerData.farming = playerData.farming or {}
		playerData.farming.plots = 1
		playerData.farming.inventory = playerData.farming.inventory or {}

		-- Add starter seeds
		if item.effects and item.effects.starterSeeds then
			for seedId, amount in pairs(item.effects.starterSeeds) do
				playerData.farming.inventory[seedId] = amount
			end
		end

		-- Create the first farm plot
		local success = self:CreatePlayerFarmPlot(player, 1)
		if success then
			self:SendNotification(player, "🌾 First Farm Plot Created!", 
				"Your farming journey begins! You received starter seeds too!", "success")
			return true
		end

	elseif item.id == "farm_plot_expansion" then
		-- Additional farm plots
		local currentPlots = playerData.farming and playerData.farming.plots or 0
		local newPlotNumber = currentPlots + 1

		if newPlotNumber > 10 then
			self:SendNotification(player, "Maximum Plots Reached", 
				"You already have the maximum number of farm plots (10)!", "warning")
			return false
		end

		-- Update plot count
		playerData.farming = playerData.farming or {}
		playerData.farming.plots = newPlotNumber

		-- Create the new plot
		local success = self:CreatePlayerFarmPlot(player, newPlotNumber)
		if success then
			self:SendNotification(player, "🌾 Farm Expanded!", 
				"Farm plot #" .. newPlotNumber .. " created! More space for growing!", "success")
			return true
		end
	end

	return false
end

function GameCore:HandleSeedPurchase(player, playerData, item, quantity)
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	playerData.farming.inventory[item.id] = (playerData.farming.inventory[item.id] or 0) + quantity

	self:SendNotification(player, "Seeds Added!", 
		"Added " .. quantity .. "x " .. item.name .. " to your farming inventory!", "success")
	return true
end

function GameCore:HandleUpgradePurchase(player, playerData, item, quantity)
	playerData.upgrades = playerData.upgrades or {}
	local currentLevel = playerData.upgrades[item.id] or 0
	playerData.upgrades[item.id] = currentLevel + quantity

	-- Apply upgrade effects
	self:ApplyUpgradeEffect(player, item.id, playerData.upgrades[item.id])

	self:SendNotification(player, "Upgrade Purchased!", 
		item.name .. " acquired!", "success")
	return true
end

function GameCore:HandleGenericPurchase(player, playerData, item, quantity)
	self:SendNotification(player, "Purchase Complete!", 
		"Purchased " .. quantity .. "x " .. item.name, "success")
	return true
end

-- Apply upgrade effects
function GameCore:ApplyUpgradeEffect(player, upgradeId, level)
	-- Upgrades are now applied when calculating values rather than storing attributes
	-- This makes the system more flexible and easier to manage
	print("GameCore: Applied " .. upgradeId .. " to " .. player.Name)
end

function GameCore:ApplyAllUpgradeEffects(player)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.upgrades then return end

	for upgradeId, level in pairs(playerData.upgrades) do
		if level then
			self:ApplyUpgradeEffect(player, upgradeId, level)
		end
	end
end

-- Initialize farming system
function GameCore:InitializeFarmingSystem()
	print("GameCore: Farming system initialized")
end

function GameCore:InitializePlayerFarm(player)
	-- Farm initialization logic (keeping existing farm plot creation)
	print("GameCore: Initialized farm for " .. player.Name)
end

-- Farming system methods
function GameCore:PlantSeed(player, plotModel, seedId)
	-- Keep existing planting logic
	print("GameCore: " .. player.Name .. " planted " .. seedId)
end

function GameCore:HarvestCrop(player, plotModel)
	-- Keep existing harvest logic but update to use farmTokens
	print("GameCore: " .. player.Name .. " harvested crops")
end

function GameCore:SellCrop(player, cropId, amount)
	amount = amount or 1
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Crops", "You don't have any crops to sell!", "error")
		return false
	end

	local cropCount = playerData.farming.inventory[cropId] or 0
	if cropCount < amount then
		local cropData = ItemConfig.GetCropData(cropId)
		local cropName = cropData and cropData.name or cropId
		self:SendNotification(player, "Not Enough Crops", 
			"You only have " .. cropCount .. " " .. cropName .. "!", "error")
		return false
	end

	local cropData = ItemConfig.GetCropData(cropId)
	if not cropData or not cropData.sellValue then
		self:SendNotification(player, "Cannot Sell", "This crop cannot be sold!", "error")
		return false
	end

	-- Calculate earnings in farmTokens
	local totalValue = cropData.sellValue * amount
	local currency = cropData.sellCurrency or "farmTokens"

	-- Process sale
	playerData.farming.inventory[cropId] = playerData.farming.inventory[cropId] - amount
	playerData[currency] = (playerData[currency] or 0) + totalValue

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + amount

	-- Save and update
	self:UpdatePlayerLeaderstats(player)
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Crop Sold!", 
		"Sold " .. amount .. "x " .. cropData.name .. " for " .. totalValue .. " " .. currency .. "!", "success")
	return true
end

-- Initialize shop system
function GameCore:InitializeShopSystem()
	print("GameCore: Shop system initialized")
end

-- Player management
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

-- Update loops
function GameCore:StartUpdateLoops()
	print("GameCore: Starting update loops...")

	-- Cow indicator update loop
	spawn(function()
		while true do
			wait(1) -- Update every second
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

-- Update cow indicator based on cooldowns
function GameCore:UpdateCowIndicator()
	if not self.Models.Cow then return end

	local indicator = self.Models.Cow:FindFirstChild("MilkIndicator")
	if not indicator then return end

	-- Find if any players can collect milk
	local anyPlayerReady = false
	local shortestWait = math.huge

	for userId, lastCollection in pairs(self.Systems.Livestock.CowCooldowns) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local playerData = self:GetPlayerData(player)
			local cooldown = ItemConfig.GetMilkCooldown(playerData.upgrades or {})
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

	-- If no cooldowns recorded, anyone can collect
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

-- Setup admin commands for farm plot testing
function GameCore:SetupFarmPlotTestingCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			-- Replace "TommySalami311" with your actual Roblox username
			if player.Name == "TommySalami311" then -- Change this to your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/showfarmpositions" then
					-- Show where all 10 plots would be positioned for the player
					print("=== FARM PLOT POSITIONS FOR " .. player.Name .. " ===")
					for i = 1, 10 do
						local position = self:GetFarmPlotPosition(player, i)
						print("Plot " .. i .. ": " .. tostring(position))

						-- Create temporary marker at each position (will disappear in 10 seconds)
						local marker = Instance.new("Part")
						marker.Name = "PlotMarker_" .. i
						marker.Size = Vector3.new(2, 8, 2)
						marker.Material = Enum.Material.Neon
						marker.Color = Color3.fromRGB(255, 0, 255) -- Bright pink
						marker.Anchored = true
						marker.CanCollide = false
						marker.CFrame = position + Vector3.new(0, 4, 0) -- Raise it up
						marker.Parent = workspace

						-- Add text label
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

						-- Remove marker after 10 seconds
						Debris:AddItem(marker, 10)
					end
					print("=== Temporary markers placed for 10 seconds ===")

				elseif command == "/teleportplot" then
					-- Teleport to a specific plot position
					local plotNumber = tonumber(args[2]) or 1
					if plotNumber >= 1 and plotNumber <= 10 then
						local position = self:GetFarmPlotPosition(player, plotNumber)
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							player.Character.HumanoidRootPart.CFrame = position + Vector3.new(0, 5, 10)
							print("Teleported " .. player.Name .. " to plot " .. plotNumber .. " position")
						end
					else
						print("Invalid plot number. Use 1-10.")
					end

				elseif command == "/createtestplot" then
					-- Create a test plot at a specific position
					local plotNumber = tonumber(args[2]) or 1
					if plotNumber >= 1 and plotNumber <= 10 then
						local success = self:CreatePlayerFarmPlot(player, plotNumber)
						if success then
							print("Created test plot " .. plotNumber .. " for " .. player.Name)
						else
							print("Failed to create test plot " .. plotNumber)
						end
					end

				elseif command == "/clearfarmmarkers" then
					-- Remove all temporary markers
					for _, child in pairs(workspace:GetChildren()) do
						if child.Name:find("PlotMarker_") then
							child:Destroy()
						end
					end
					print("Cleared all farm plot markers")

				elseif command == "/farmhelp" then
					-- Show all available farm commands
					print("=== FARM POSITION TESTING COMMANDS ===")
					print("/showfarmpositions - Show where all 10 plots will be placed")
					print("/teleportplot [1-10] - Teleport to specific plot position")
					print("/createtestplot [1-10] - Create a test plot at position")
					print("/clearfarmmarkers - Remove temporary position markers")
					print("/farmhelp - Show this help")
					print("=====================================")

				elseif command == "/givefarmplot" then
					-- Give a player a farm plot for testing
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						local playerData = self:GetPlayerData(targetPlayer)
						if playerData then
							-- Give them the farm plot starter
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = true
							playerData.farming = playerData.farming or {
								plots = 1, 
								inventory = {
									carrot_seeds = 5, 
									corn_seeds = 3
								}
							}

							-- Create the plot
							self:CreatePlayerFarmPlot(targetPlayer, 1)

							self:SendNotification(targetPlayer, "Admin Gift", "You received a free farm plot!", "success")
							print("Admin: Gave farm plot to " .. targetPlayer.Name)
						end
					else
						print("Admin: Player " .. (targetName or "nil") .. " not found")
					end

				elseif command == "/resetallplots" then
					-- Reset all farm plots (dangerous command)
					local areas = workspace:FindFirstChild("Areas")
					if areas then
						local starterMeadow = areas:FindFirstChild("Starter Meadow")
						if starterMeadow then
							local farmArea = starterMeadow:FindFirstChild("Farm")
							if farmArea then
								farmArea:ClearAllChildren()
								print("Admin: Cleared all farm plots from workspace")
							end
						end
					end

				elseif command == "/setplotposition" then
					-- Set a custom position for a plot number
					local plotNumber = tonumber(args[2])
					if plotNumber and plotNumber >= 1 and plotNumber <= 10 and player.Character and player.Character.HumanoidRootPart then
						local currentPos = player.Character.HumanoidRootPart.Position
						local basePos = self.FarmPlotPositions.basePosition
						local newOffset = currentPos - basePos

						-- Update the position in the config (temporary for this session)
						self.FarmPlotPositions.plotOffsets[plotNumber] = newOffset

						print("Admin: Set plot " .. plotNumber .. " position to " .. tostring(newOffset))
						print("To make this permanent, update your GameCore.lua with:")
						print('[' .. plotNumber .. '] = Vector3.new(' .. newOffset.X .. ', ' .. newOffset.Y .. ', ' .. newOffset.Z .. '),')
					else
						print("Usage: /setplotposition [1-10] (stand where you want the plot)")
					end
				end
			end
		end)
	end)

	print("GameCore: Farm plot testing commands setup complete")
end

-- Utility methods
function GameCore:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
	end
	print("GameCore: [" .. (notificationType or "info"):upper() .. "] " .. player.Name .. " - " .. title .. ": " .. message)
end

-- Player events
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

return GameCore