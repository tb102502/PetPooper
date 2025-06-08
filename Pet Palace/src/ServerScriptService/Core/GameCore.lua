--[[
    GameCore.lua - UPDATED WITH CONFIGURABLE FARM PLOT POSITIONS
    Place in: ServerScriptService/Core/GameCore.lua
    
    NEW FEATURES:
    - Configurable CFrame positions for up to 10 farm plots per player
    - GetFarmPlotPosition method for consistent positioning
    - Support for multiple farm plot purchases
    - Better farm plot management system
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

-- Ensure FarmPlotPositions is always initialized
if not GameCore.FarmPlotPositions then
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
end
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

	-- Check if FarmPlotPositions is properly initialized
	if not self.FarmPlotPositions then
		warn("GameCore: FarmPlotPositions not initialized!")
		return CFrame.new(0, 0, 0) -- Return default position to prevent nil errors
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
	local playerOffset = self.FarmPlotPositions.playerSeparation * playerIndex
	local playerBasePosition = basePos + playerOffset

	-- Get the specific plot offset
	local plotOffset = self.FarmPlotPositions.plotOffsets[plotNumber] or Vector3.new(0, 0, 0)

	-- Calculate final position
	local finalPosition = playerBasePosition + plotOffset

	-- Create CFrame with rotation
	local rotation = self.FarmPlotPositions.plotRotation
	local cframe = CFrame.new(finalPosition) * CFrame.Angles(
		math.rad(rotation.X), 
		math.rad(rotation.Y), 
		math.rad(rotation.Z)
	)

	return cframe
end

-- ADD this method to GameCore.lua (after GetFarmPlotPosition):

function GameCore:GetPlotOwner(plotModel)
	-- Navigate up to find the player farm folder
	local parent = plotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_Farm") then
			return parent.Name:gsub("_Farm", "")
		end

		-- Also check if parent name contains farm info
		if parent.Name:find("Farm") and parent.Parent and parent.Parent.Name:find("_Farm") then
			return parent.Parent.Name:gsub("_Farm", "")
		end

		parent = parent.Parent
	end

	warn("GameCore: Could not determine plot owner for " .. plotModel.Name)
	return nil
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

	-- Get the position for this plot (FIXED - uses self:)
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

-- ========== FIX #5: Add missing CreatePlotInfoSign method (GameCore.lua) ==========
-- ADD this method to GameCore.lua (after CreatePlotBorder):

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
-- REPLACE the HandlePlotClick function in GameCore.lua (around line 2650)

-- Handle plot clicking for planting (FIXED VERSION)
function GameCore:HandlePlotClick(player, spotModel)
	print("GameCore: Plot clicked by " .. player.Name .. " on " .. spotModel.Name)

	-- Check if plot is empty
	local isEmpty = spotModel:GetAttribute("IsEmpty")
	if not isEmpty then
		self:SendNotification(player, "Plot Occupied", "This plot already has something planted!", "warning")
		return
	end

	-- Check if this is the player's plot (security check)
	local plotOwner = self:GetPlotOwner(spotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return
	end

	-- Check if player has any seeds
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Farming Data", "You need to set up farming first! Visit the shop.", "warning")
		return
	end

	-- Count available seeds
	local hasSeeds = false
	for itemId, quantity in pairs(playerData.farming.inventory) do
		if itemId:find("_seeds") and quantity > 0 then
			hasSeeds = true
			break
		end
	end

	if not hasSeeds then
		self:SendNotification(player, "No Seeds", "You don't have any seeds! Buy some from the shop first.", "warning")
		return
	end

	-- 🌱 FIXED: Fire to client to show seed selection UI
	if self.RemoteEvents.PlantSeed then
		print("GameCore: Sending plot click to client for seed selection")
		self.RemoteEvents.PlantSeed:FireClient(player, spotModel)
	else
		warn("GameCore: PlantSeed remote event not available")
		self:SendNotification(player, "Error", "Planting system not available!", "error")
	end


-- VERIFY this PlantSeed server handler exists and is correct (around line 2580)
-- This should already be in your GameCore.lua, but make sure it's properly connected

	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			print("GameCore: Received plant request from " .. player.Name .. " for " .. seedId)
			pcall(function()
				self:PlantSeed(player, plotModel, seedId)
			end)
		end)
	end
end
-- ALSO ADD: Enhanced GetPlotOwner function if it doesn't exist


-- DEBUGGING: Add this function to help diagnose planting issues
function GameCore:DebugPlantingSystem(player)
	local playerData = self:GetPlayerData(player)

	print("=== PLANTING SYSTEM DEBUG FOR " .. player.Name .. " ===")
	print("Player data exists:", playerData ~= nil)

	if playerData then
		print("Has farming data:", playerData.farming ~= nil)
		if playerData.farming then
			print("Has inventory:", playerData.farming.inventory ~= nil)
			if playerData.farming.inventory then
				print("Seeds in inventory:")
				for itemId, quantity in pairs(playerData.farming.inventory) do
					if itemId:find("_seeds") then
						print("  " .. itemId .. ": " .. quantity)
					end
				end
			end
		end
	end

	-- Check remote events
	print("PlantSeed remote exists:", self.RemoteEvents.PlantSeed ~= nil)
	print("PlantSeed handler connected:", true) -- If this prints, handler is connected

	print("==========================================")
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
	self:InitializePestAndChickenSystems()

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
		"PlayerDataUpdated", "ShowNotification",
		
		-- Chicken System Events
		"PurchaseChicken", "FeedChicken", "CollectEgg",

		-- Pest Control Events  
		"UsePesticide", "ChickenPlaced", "ChickenMoved"
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
	self:SetupPestChickenEventHandlers()

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
function GameCore:SetupPestChickenEventHandlers()
	print("GameCore: Setting up pest and chicken event handlers...")

	-- Chicken purchase handler
	if self.RemoteEvents.PurchaseChicken then
		self.RemoteEvents.PurchaseChicken.OnServerEvent:Connect(function(player, chickenType, position)
			pcall(function()
				self:HandleChickenPurchase(player, chickenType, position)
			end)
		end)
	end

	-- Chicken feeding handler
	if self.RemoteEvents.FeedChicken then
		self.RemoteEvents.FeedChicken.OnServerEvent:Connect(function(player, chickenId, feedType)
			pcall(function()
				self:HandleChickenFeeding(player, chickenId, feedType)
			end)
		end)
	end

	-- Egg collection handler
	if self.RemoteEvents.CollectEgg then
		self.RemoteEvents.CollectEgg.OnServerEvent:Connect(function(player, chickenId)
			pcall(function()
				self:HandleEggCollection(player, chickenId)
			end)
		end)
	end

	-- Pesticide use handler
	if self.RemoteEvents.UsePesticide then
		self.RemoteEvents.UsePesticide.OnServerEvent:Connect(function(player, plotModel)
			pcall(function()
				self:HandlePesticideUse(player, plotModel)
			end)
		end)
	end

	print("GameCore: Pest and chicken event handlers setup complete")
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
function GameCore:GetDefaultPlayerData()
	return {
		-- Core Currency
		coins = 100,
		farmTokens = 0,

		-- Progression
		upgrades = {},
		purchaseHistory = {},

		-- Farming System (UNIFIED)
		farming = {
			plots = 0,
			inventory = {},
			activeCrops = {}, -- Track growing crops
			harvestHistory = {}
		},

		-- Livestock System (UNIFIED)
		livestock = {
			cow = {
				lastMilkCollection = 0,
				totalMilkCollected = 0
			},
			pig = {
				size = 1.0,
				cropPoints = 0,
				transformationCount = 0,
				totalFed = 0,
				lastFeedTime = 0
			}
		},

		-- NEW: Pest & Chicken System (UNIFIED)
		defense = {
			chickens = {
				owned = {},
				deployed = {},
				feed = {
					basic_feed = 0,
					premium_feed = 0,
					grain_feed = 0
				}
			},
			pestControl = {
				organic_pesticide = 0,
				pest_detector = false,
				pestsEliminated = 0
			},
			roofs = {} -- Roof protection systems
		},

		-- Statistics (COMPREHENSIVE)
		stats = {
			-- Existing
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0,
			-- NEW
			seedsPlanted = 0,
			pestsEncountered = 0,
			pestsEliminated = 0,
			chickensDeployed = 0,
			roofsBuilt = 0,
			farmTokensEarned = 0
		},

		-- Session Data
		firstJoin = os.time(),
		lastSave = os.time(),
		sessionData = {
			loginStreak = 1,
			dailyBonusClaimed = false
		}
	}
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
-- REPLACE LoadPlayerData method

function GameCore:LoadPlayerData(player)
	local defaultData = {
		coins = 100,
		farmTokens = 0,
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 0,
			inventory = {}
		},
		livestock = {
			pig = {
				size = 1.0,
				cropPoints = 0,
				transformationCount = 0,
				totalFed = 0
			}
		},
		defense = {
			chickens = {
				owned = {},
				feed = {
					basic_feed = 0,
					premium_feed = 0,
					grain_feed = 0
				}
			},
			pestControl = {
				organic_pesticide = 0,
				pest_detector = false
			},
			roofs = {}
		},
		stats = {
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0,
			seedsPlanted = 0,
			pestsEliminated = 0
		},
		firstJoin = os.time(),
		lastSave = os.time()
	}

	local loadedData = defaultData

	if self.PlayerDataStore then
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			-- Deep merge to ensure all fields exist
			for key, value in pairs(defaultData) do
				if data[key] == nil then
					data[key] = value
				elseif type(value) == "table" and type(data[key]) == "table" then
					for subKey, subValue in pairs(value) do
						if data[key][subKey] == nil then
							data[key][subKey] = subValue
						elseif type(subValue) == "table" and type(data[key][subKey]) == "table" then
							for subSubKey, subSubValue in pairs(subValue) do
								if data[key][subKey][subSubKey] == nil then
									data[key][subKey][subSubKey] = subSubValue
								end
							end
						end
					end
				end
			end
			loadedData = data
			print("GameCore: Loaded existing data for " .. player.Name)
		else
			print("GameCore: Using default data for " .. player.Name)
		end
	end

	self.PlayerData[player.UserId] = loadedData

	-- FIX: Use the correct method name
	self:InitializePlayerSystems(player, loadedData)
	self:UpdatePlayerLeaderstats(player)

	return loadedData
end


-- ADD deep merge utility
function GameCore:DeepMerge(default, loaded)
	local result = {}

	-- Start with default structure
	for key, value in pairs(default) do
		if type(value) == "table" then
			result[key] = self:DeepMerge(value, loaded[key] or {})
		else
			result[key] = loaded[key] ~= nil and loaded[key] or value
		end
	end

	-- Add any extra fields from loaded data
	for key, value in pairs(loaded) do
		if result[key] == nil then
			result[key] = value
		end
	end

	return result
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

function GameCore:InitializePestAndChickenSystems()
	print("GameCore: Initializing pest and chicken defense systems...")

	-- Initialize pest tracking in player data
	for _, player in pairs(Players:GetPlayers()) do
		local playerData = self:GetPlayerData(player)
		if playerData then
			-- Initialize chicken ownership tracking
			if not playerData.chickens then
				playerData.chickens = {
					owned = {},
					feed = {
						basic_feed = 0,
						premium_feed = 0,
						grain_feed = 0
					}
				}
			end

			-- Initialize pest control tools
			if not playerData.pestControl then
				playerData.pestControl = {
					organic_pesticide = 0,
					pest_detector = false
				}
			end
		end
	end

	print("GameCore: Pest and chicken systems initialized")
end
-- Player Data Management
function GameCore:GetPlayerData(player)
	if not self.PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return self.PlayerData[player.UserId]
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
-- ========== PURCHASE HANDLER FIX FOR GAMECORE.LUA ==========
-- Replace the HandlePurchase function in your GameCore.lua with this version


function GameCore:HandlePurchase(player, itemId, quantity)
	print("🛒 SERVER: Purchase request received")
	print("    Player: " .. player.Name)
	print("    Item: " .. itemId)
	print("    Quantity: " .. (quantity or 1))

	quantity = quantity or 1
	local playerData = self:GetPlayerData(player)

	if not playerData then 
		print("❌ SERVER: Player data not found for " .. player.Name)
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false 
	end

	print("✅ SERVER: Player data found")
	print("    Coins: " .. (playerData.coins or 0))
	print("    Farm Tokens: " .. (playerData.farmTokens or 0))

	local item = ItemConfig.GetItem(itemId)
	if not item then
		print("❌ SERVER: Item not found: " .. itemId)
		self:SendNotification(player, "Invalid Item", "Item not found!", "error")
		return false
	end

	print("✅ SERVER: Item found: " .. item.name)
	print("    Price: " .. item.price .. " " .. item.currency)

	-- Check if player can buy (using validation system)
	local canBuy = true
	local reason = "Can purchase"

	if ItemConfig.CanPlayerBuy then
		canBuy, reason = ItemConfig.CanPlayerBuy(itemId, playerData)
	end

	if not canBuy then
		print("❌ SERVER: Cannot buy - " .. reason)
		self:SendNotification(player, "Cannot Purchase", reason, "error")
		return false
	end

	-- Calculate cost
	local cost = item.price or 0
	local currency = item.currency or "coins"
	local totalCost = cost * quantity

	print("💰 SERVER: Cost calculation")
	print("    Total cost: " .. totalCost .. " " .. currency)
	print("    Player has: " .. (playerData[currency] or 0) .. " " .. currency)

	-- Deduct currency
	local oldAmount = playerData[currency] or 0
	playerData[currency] = oldAmount - totalCost

	print("💳 SERVER: Currency deducted")
	print("    Old amount: " .. oldAmount)
	print("    New amount: " .. playerData[currency])

	-- Handle purchase by type (UPDATED WITH ALL MISSING TYPES)
	local success = false
	print("🔧 SERVER: Processing purchase by type: " .. (item.type or "unknown"))

	if item.type == "farmPlot" or item.id == "farm_plot_starter" or item.id == "farm_plot_expansion" then
		print("🌾 SERVER: Processing farm plot purchase")
		success = self:HandleFarmPlotPurchase(player, playerData, item, quantity)

	elseif item.type == "seed" then
		print("🌱 SERVER: Processing seed purchase")
		success = self:HandleSeedPurchase(player, playerData, item, quantity)

	elseif item.type == "upgrade" then
		print("⬆️ SERVER: Processing upgrade purchase")
		success = self:HandleUpgradePurchase(player, playerData, item, quantity)

	elseif item.type == "chicken" then
		print("🐔 SERVER: Processing chicken purchase")
		success = self:HandleChickenItemPurchase(player, playerData, item, quantity)

	elseif item.type == "feed" then
		print("🌾 SERVER: Processing feed purchase")
		success = self:HandleFeedPurchase(player, playerData, item, quantity)

	elseif item.type == "tool" then
		print("🧪 SERVER: Processing tool purchase")
		success = self:HandlePestControlToolPurchase(player, playerData, item, quantity)

	elseif item.type == "roof" then  -- MISSING HANDLER ADDED
		print("🏠 SERVER: Processing roof purchase")
		success = self:HandleRoofPurchase(player, playerData, item, quantity)

	else
		print("📦 SERVER: Processing generic purchase")
		success = self:HandleGenericPurchase(player, playerData, item, quantity)
	end

	print("📋 SERVER: Purchase processing result: " .. tostring(success))

	if success then
		print("✅ SERVER: Purchase successful, updating player")

		-- Mark as purchased for single-purchase items
		if item.maxQuantity == 1 then
			playerData.purchaseHistory = playerData.purchaseHistory or {}
			playerData.purchaseHistory[itemId] = true
		end

		-- Update leaderstats
		self:UpdatePlayerLeaderstats(player)

		-- Save data
		self:SavePlayerData(player)

		-- Send confirmation events
		if self.RemoteEvents.ItemPurchased then
			print("📤 SERVER: Sending ItemPurchased event to client")
			self.RemoteEvents.ItemPurchased:FireClient(player, itemId, quantity, totalCost, currency)
		else
			print("❌ SERVER: ItemPurchased remote event not found!")
		end

		if self.RemoteEvents.PlayerDataUpdated then
			print("📤 SERVER: Sending PlayerDataUpdated event to client")
			self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		else
			print("❌ SERVER: PlayerDataUpdated remote event not found!")
		end

		print("🎉 SERVER: Purchase completed successfully!")
		return true
	else
		print("❌ SERVER: Purchase failed, refunding currency")
		-- Refund currency on failure
		playerData[currency] = oldAmount
		return false
	end
end

-- ========== ADD MISSING PURCHASE HANDLERS ==========

-- Enhanced roof purchase handler (ADD THIS IF MISSING)
function GameCore:HandleRoofPurchase(player, playerData, item, quantity)
	print("🏠 SERVER: Processing roof purchase: " .. item.id)

	-- Check if player has farm plots
	local plotCount = playerData.farming and playerData.farming.plots or 0
	if plotCount == 0 then
		self:SendNotification(player, "No Farm Plots", "You need farm plots before buying roof protection!", "error")
		return false
	end

	-- Initialize roof tracking
	if not playerData.defense then
		playerData.defense = {roofs = {}}
	end
	if not playerData.defense.roofs then
		playerData.defense.roofs = {}
	end

	-- Find available plot for roof installation
	local targetPlot = 1
	local roofName = item.id .. "_" .. targetPlot

	if item.id == "basic_roof" then
		-- Find first unprotected plot
		for i = 1, plotCount do
			if not self:IsPlotProtected(player, i) then
				targetPlot = i
				roofName = item.id .. "_" .. i
				break
			end
		end

	elseif item.id == "reinforced_roof" then
		-- Find space for 2x2 coverage
		for i = 1, math.max(1, plotCount - 3) do
			local canPlace = true
			for j = i, math.min(i + 3, plotCount) do
				if self:IsPlotProtected(player, j) then
					canPlace = false
					break
				end
			end
			if canPlace then
				targetPlot = i
				roofName = item.id .. "_" .. i
				break
			end
		end

	elseif item.id == "mega_dome" then
		-- Mega dome covers all plots
		targetPlot = 1
		roofName = item.id .. "_all"
	end

	-- Create the roof protection data
	playerData.defense.roofs[roofName] = {
		type = item.id,
		plotNumber = targetPlot,
		coverage = item.effects and item.effects.coverage or 1,
		installed = true,
		installTime = os.time()
	}

	-- Create the physical roof structure
	local success = self:CreateRoofProtection(player, item.id, targetPlot)
	if success then
		local coverageText = ""
		if item.id == "mega_dome" then
			coverageText = "entire farm"
		elseif item.id == "reinforced_roof" then
			coverageText = "4 plots"
		else
			coverageText = "1 plot"
		end

		self:SendNotification(player, "🏠 Roof Installed!", 
			item.name .. " protects " .. coverageText .. " from UFO attacks!", "success")

		print("🏠 SERVER: Successfully installed " .. item.id .. " for " .. player.Name)
		return true
	else
		-- Remove from data if physical creation failed
		playerData.defense.roofs[roofName] = nil
		self:SendNotification(player, "Installation Failed", 
			"Could not install roof. Make sure you have available space!", "error")
		return false
	end
end

-- Enhanced generic purchase handler (UPDATE THIS)
function GameCore:HandleGenericPurchase(player, playerData, item, quantity)
	-- Handle special items that don't have specific handlers

	if item.category == "premium" then
		self:SendNotification(player, "Premium Item Purchased!", 
			"Acquired " .. item.name .. "! Check your inventory for special benefits.", "success")
	else
		self:SendNotification(player, "Purchase Complete!", 
			"Purchased " .. quantity .. "x " .. item.name, "success")
	end

	print("📦 SERVER: Generic purchase completed for " .. item.id)
	return true
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
-- Handle chicken purchases from shop
function GameCore:HandleChickenItemPurchase(player, playerData, item, quantity)
	-- Check requirements
	if item.requiresPurchase then
		local hasRequirement = false
		for _, ownedChicken in pairs(playerData.chickens.owned) do
			if ownedChicken.type == item.requiresPurchase then
				hasRequirement = true
				break
			end
		end
		if not hasRequirement then
			self:SendNotification(player, "Requirements Not Met", 
				"You must own a " .. item.requiresPurchase .. " first!", "error")
			return false
		end
	end

	-- Check quantity limits
	local currentCount = 0
	for _, ownedChicken in pairs(playerData.chickens.owned) do
		if ownedChicken.type == item.id then
			currentCount = currentCount + 1
		end
	end

	if currentCount >= (item.maxQuantity or 10) then
		self:SendNotification(player, "Chicken Limit Reached", 
			"You already have the maximum number of " .. item.name .. "!", "error")
		return false
	end

	-- Add chicken ownership to player data (actual placement handled by client)
	if not playerData.chickens then
		playerData.chickens = {owned = {}, feed = {}}
	end

	local chickenId = game:GetService("HttpService"):GenerateGUID(false)
	playerData.chickens.owned[chickenId] = {
		type = item.id,
		purchaseTime = os.time(),
		status = "available" -- available, placed, deployed
	}

	self:SendNotification(player, "🐔 Chicken Purchased!", 
		item.name .. " added to your poultry collection! Use the farming interface to deploy it.", "success")

	print("GameCore: " .. player.Name .. " purchased " .. item.name)
	return true
end

-- Handle feed purchases
function GameCore:HandleFeedPurchase(player, playerData, item, quantity)
	-- Initialize feed storage
	if not playerData.chickens then
		playerData.chickens = {owned = {}, feed = {}}
	end
	if not playerData.chickens.feed then
		playerData.chickens.feed = {}
	end

	-- Add feed to inventory
	local currentAmount = playerData.chickens.feed[item.id] or 0
	playerData.chickens.feed[item.id] = currentAmount + quantity

	self:SendNotification(player, "🌾 Feed Purchased!", 
		"Added " .. quantity .. "x " .. item.name .. " to your feed storage!", "success")

	print("GameCore: " .. player.Name .. " purchased " .. quantity .. "x " .. item.name)
	return true
end

-- Handle pest control tool purchases
function GameCore:HandlePestControlToolPurchase(player, playerData, item, quantity)
	-- Initialize pest control inventory
	if not playerData.pestControl then
		playerData.pestControl = {}
	end

	if item.id == "pest_detector" then
		-- One-time purchase upgrade
		playerData.pestControl.pest_detector = true
		self:SendNotification(player, "📡 Pest Detector Installed!", 
			"You will now receive early warnings about pest infestations!", "success")
	else
		-- Consumable items
		local currentAmount = playerData.pestControl[item.id] or 0
		playerData.pestControl[item.id] = currentAmount + quantity

		self:SendNotification(player, "🧪 Pest Control Tool Purchased!", 
			"Added " .. quantity .. "x " .. item.name .. " to your pest control kit!", "success")
	end

	print("GameCore: " .. player.Name .. " purchased " .. item.name)
	return true
end

-- ========== NEW CHICKEN MANAGEMENT FUNCTIONS ==========

-- Handle chicken placement from inventory
function GameCore:HandleChickenPurchase(player, chickenType, position)
	if not _G.ChickenSystem then
		self:SendNotification(player, "System Error", "Chicken system not available!", "error")
		return
	end

	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.chickens then
		self:SendNotification(player, "No Chickens", "You don't own any chickens!", "error")
		return
	end

	-- Find available chicken of this type
	local availableChicken = nil
	for chickenId, chickenData in pairs(playerData.chickens.owned) do
		if chickenData.type == chickenType and chickenData.status == "available" then
			availableChicken = {id = chickenId, data = chickenData}
			break
		end
	end

	if not availableChicken then
		self:SendNotification(player, "No Available Chickens", 
			"You don't have any available " .. chickenType .. " to deploy!", "error")
		return
	end

	-- Deploy the chicken using ChickenSystem
	local success, message = _G.ChickenSystem:PurchaseChicken(player, chickenType, position)

	if success then
		-- Update chicken status
		availableChicken.data.status = "deployed"
		self:SavePlayerData(player)

		if self.RemoteEvents.PlayerDataUpdated then
			self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end
	else
		self:SendNotification(player, "Deployment Failed", message or "Could not deploy chicken", "error")
	end
end

-- Handle chicken feeding
function GameCore:HandleChickenFeeding(player, chickenId, feedType)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.chickens or not playerData.chickens.feed then
		self:SendNotification(player, "No Feed", "You don't have any chicken feed!", "error")
		return
	end

	local feedAmount = playerData.chickens.feed[feedType] or 0
	if feedAmount <= 0 then
		local feedInfo = ItemConfig.ChickenSystem.feedTypes[feedType]
		local feedName = feedInfo and feedInfo.name or feedType
		self:SendNotification(player, "No Feed", "You don't have any " .. feedName .. "!", "error")
		return
	end

	-- Use the feed
	playerData.chickens.feed[feedType] = feedAmount - 1

	-- Apply feed to chicken (this would integrate with ChickenSystem)
	if _G.ChickenSystem then
		-- Find the chicken and feed it
		-- This would require ChickenSystem to have a feed method
		self:SendNotification(player, "🐔 Chicken Fed!", 
			"Fed chicken with " .. feedType .. "!", "success")
	end

	self:SavePlayerData(player)
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end
end

-- Handle egg collection
function GameCore:HandleEggCollection(player, chickenId)
	-- This would integrate with ChickenSystem to collect eggs
	if not _G.ChickenSystem then
		self:SendNotification(player, "System Error", "Chicken system not available!", "error")
		return
	end

	-- Implementation would depend on ChickenSystem egg storage
	self:SendNotification(player, "🥚 Egg Collected!", 
		"Collected fresh eggs from your chicken!", "success")
end

-- Handle pesticide use
function GameCore:HandlePesticideUse(player, plotModel)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.pestControl then
		self:SendNotification(player, "No Pesticide", "You don't have any pesticide!", "error")
		return
	end

	local pesticideCount = playerData.pestControl.organic_pesticide or 0
	if pesticideCount <= 0 then
		self:SendNotification(player, "No Pesticide", "You don't have any organic pesticide!", "error")
		return
	end

	-- Use pesticide
	playerData.pestControl.organic_pesticide = pesticideCount - 1

	-- Apply pesticide effect (integrate with PestSystem)
	if _G.PestSystem then
		-- Remove pests from the plot
		local pestsRemoved = 0
		if _G.PestSystem.ActivePests[plotModel] then
			for pestType, _ in pairs(_G.PestSystem.ActivePests[plotModel]) do
				_G.PestSystem:RemovePest(plotModel, pestType, "pesticide_elimination")
				pestsRemoved = pestsRemoved + 1
			end
		end

		if pestsRemoved > 0 then
			self:SendNotification(player, "🧪 Pesticide Applied!", 
				"Eliminated " .. pestsRemoved .. " pest(s) from your crop!", "success")
		else
			self:SendNotification(player, "🧪 Pesticide Applied!", 
				"Applied pesticide - no pests found on this crop.", "info")
		end
	end

	self:SavePlayerData(player)
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end
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
					-- ADD these admin commands to GameCore.lua in the existing admin commands section

					-- In the player.Chatted:Connect section, add these commands:

				elseif command == "/debugplanting" then
					-- Debug the planting system
					GameCore:DebugPlantingSystem(player)

				elseif command == "/testplant" then
					-- Give player seeds and teleport to their farm for testing
					local playerData = GameCore:GetPlayerData(player)
					if playerData then
						-- Ensure farming setup
						if not playerData.farming then
							playerData.farming = {plots = 1, inventory = {}}
						end
						if not playerData.farming.inventory then
							playerData.farming.inventory = {}
						end

						-- Give test seeds
						playerData.farming.inventory.carrot_seeds = 5
						playerData.farming.inventory.corn_seeds = 3

						-- Ensure they have a farm plot
						if not playerData.purchaseHistory then
							playerData.purchaseHistory = {}
						end
						playerData.purchaseHistory.farm_plot_starter = true

						-- Create farm plot if needed
						GameCore:CreatePlayerFarmPlot(player, 1)

						-- Save and update
						GameCore:SavePlayerData(player)
						if GameCore.RemoteEvents.PlayerDataUpdated then
							GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
						end

						-- Teleport to farm
						local farmPos = GameCore:GetFarmPlotPosition(player, 1)
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							player.Character.HumanoidRootPart.CFrame = farmPos + Vector3.new(0, 5, 10)
						end

						GameCore:SendNotification(player, "Test Setup Complete", 
							"You have seeds and a farm plot! Click on the green planting spots to plant.", "success")
						print("Admin: Set up " .. player.Name .. " for planting test")
					end

				elseif command == "/forceplant" then
					-- Force plant a crop for testing
					local areas = workspace:FindFirstChild("Areas")
					if areas then
						local starterMeadow = areas:FindFirstChild("Starter Meadow")
						if starterMeadow then
							local farmArea = starterMeadow:FindFirstChild("Farm")
							if farmArea then
								local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
								if playerFarm then
									local plot = playerFarm:FindFirstChild("FarmPlot_1")
									if plot then
										local plantingSpots = plot:FindFirstChild("PlantingSpots")
										if plantingSpots then
											local spot = plantingSpots:FindFirstChild("PlantingSpot_1")
											if spot then
												local success = GameCore:PlantSeed(player, spot, "carrot_seeds")
												print("Admin: Force plant result:", success)
											end
										end
									end
								end
							end
						end
					end

				elseif command == "/checkremotes" then
					-- Check if remote events are properly set up
					print("=== REMOTE EVENTS CHECK ===")
					local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
					if remoteFolder then
						local plantSeedRemote = remoteFolder:FindFirstChild("PlantSeed")
						print("PlantSeed remote exists:", plantSeedRemote ~= nil)
						if plantSeedRemote then
							print("PlantSeed is a:", plantSeedRemote.ClassName)
						end
					else
						print("GameRemotes folder not found!")
					end
					print("GameCore PlantSeed event:", GameCore.RemoteEvents.PlantSeed ~= nil)
					print("==========================")

					-- ADD this to the client debug commands as well (in GameClient or a separate script):

				elseif command == "/testclient" then
					-- Test client-side farming functions
					if _G.GameClient then
						print("=== CLIENT FARMING TEST ===")
						print("GameClient exists:", true)
						print("RemoteEvents exists:", _G.GameClient.RemoteEvents ~= nil)
						if _G.GameClient.RemoteEvents then
							print("PlantSeed remote:", _G.GameClient.RemoteEvents.PlantSeed ~= nil)
						end
						print("PlayerData:", _G.GameClient:GetPlayerData() ~= nil)

						local playerData = _G.GameClient:GetPlayerData()
						if playerData and playerData.farming then
							print("Has farming data:", true)
							print("Has inventory:", playerData.farming.inventory ~= nil)
							if playerData.farming.inventory then
								local seedCount = 0
								for itemId, quantity in pairs(playerData.farming.inventory) do
									if itemId:find("_seeds") then
										seedCount = seedCount + quantity
									end
								end
								print("Total seeds:", seedCount)
							end
						end
						print("===========================")
					end
					
					-- ========== CLEAN DEBUG COMMANDS FOR GAMECORE.LUA ==========
					-- Add these to your existing admin commands section (replace the old ones)

				elseif command == "/debugshop" then
					-- Debug all shop items and categories
					print("=== SHOP DEBUG FOR " .. player.Name .. " ===")

					local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
					local playerData = GameCore:GetPlayerData(player)

					local categories = {"seeds", "farm", "defense", "tools", "premium"}
					local totalItems = 0

					for _, category in ipairs(categories) do
						print("CATEGORY: " .. category)
						local categoryCount = 0

						for itemId, item in pairs(ItemConfig.ShopItems) do
							if item.category == category then
								categoryCount = categoryCount + 1
								totalItems = totalItems + 1
								print("  " .. itemId .. " - " .. item.name .. " - " .. item.price .. " " .. item.currency)
							end
						end

						print("  Items in " .. category .. ": " .. categoryCount)
					end

					print("Total items: " .. totalItems)
					print("Player coins: " .. (playerData.coins or 0))
					print("Player farmTokens: " .. (playerData.farmTokens or 0))
					print("================================")

				elseif command == "/fixshop" then
					-- Give player everything needed to see all shop items
					local playerData = GameCore:GetPlayerData(player)
					if playerData then
						-- Give lots of currency
						playerData.coins = 50000
						playerData.farmTokens = 1000

						-- Give basic purchases to unlock higher tier items
						playerData.purchaseHistory = playerData.purchaseHistory or {}
						playerData.purchaseHistory.farm_plot_starter = true
						playerData.purchaseHistory.basic_chicken = true
						playerData.purchaseHistory.guinea_fowl = true
						playerData.purchaseHistory.basic_feed = true
						playerData.purchaseHistory.organic_pesticide = true
						playerData.purchaseHistory.basic_roof = true
						playerData.purchaseHistory.reinforced_roof = true
						playerData.purchaseHistory.milk_efficiency_1 = true

						-- Give farm plot
						playerData.farming = playerData.farming or {}
						playerData.farming.plots = 5
						playerData.farming.inventory = playerData.farming.inventory or {}

						GameCore:SavePlayerData(player)

						-- Force client update
						if GameCore.RemoteEvents.PlayerDataUpdated then
							GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
						end

						GameCore:SendNotification(player, "Shop Fixed", "You can now see all shop items!", "success")
						print("Admin: Fixed shop for " .. player.Name)
					end

				elseif command == "/listallitems" then
					-- List every single item in the shop system
					print("=== ALL SHOP ITEMS ===")

					local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
					local count = 0

					for itemId, item in pairs(ItemConfig.ShopItems) do
						count = count + 1
						print(count .. ". " .. itemId .. " (" .. item.name .. ") - " .. item.category)
					end

					print("Total items: " .. count)

				elseif command == "/testbuy" then
					-- Test purchasing a specific item
					local itemId = args[2] or "carrot_seeds"
					print("Testing purchase: " .. itemId)

					local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
					local item = ItemConfig.GetItem(itemId)

					if not item then
						print("Item not found: " .. itemId)
						return
					end

					local playerData = GameCore:GetPlayerData(player)

					-- Give player enough currency
					playerData[item.currency] = (playerData[item.currency] or 0) + item.price + 100

					-- Attempt purchase
					local success = GameCore:HandlePurchase(player, itemId, 1)
					print("Purchase result: " .. tostring(success))

				elseif command == "/checkitemconfig" then
					-- Check if ItemConfig is working properly
					local success, ItemConfig = pcall(function()
						return require(ReplicatedStorage:WaitForChild("ItemConfig"))
					end)

					if success then
						print("ItemConfig loaded successfully")

						local itemCount = 0
						for _ in pairs(ItemConfig.ShopItems) do
							itemCount = itemCount + 1
						end

						print("Items found: " .. itemCount)

						-- Test a few key functions
						local testItem = ItemConfig.GetItem("carrot_seeds")
						if testItem then
							print("GetItem function working: " .. testItem.name)
						else
							print("GetItem function failed")
						end

						if ItemConfig.CanPlayerBuy then
							print("CanPlayerBuy function exists")
						else
							print("CanPlayerBuy function missing")
						end

					else
						print("Failed to load ItemConfig: " .. tostring(ItemConfig))
					end
					
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
end)-- UPDATED: Enhanced seed purchase handler with proper inventory management
function GameCore:HandleSeedPurchase(player, playerData, item, quantity)
	print("🌱 SERVER: Processing seed purchase - " .. item.id .. " x" .. quantity .. " for " .. player.Name)

	-- Initialize farming data if it doesn't exist
	if not playerData.farming then
		print("🌱 SERVER: Initializing farming data for " .. player.Name)
		playerData.farming = {
			plots = 0,
			inventory = {}
		}
	end

	if not playerData.farming.inventory then
		print("🌱 SERVER: Initializing farming inventory for " .. player.Name)
		playerData.farming.inventory = {}
	end

	-- Add seeds to inventory
	local currentAmount = playerData.farming.inventory[item.id] or 0
	playerData.farming.inventory[item.id] = currentAmount + quantity

	print("🌱 SERVER: Added " .. quantity .. "x " .. item.id .. " to " .. player.Name .. "'s inventory")
	print("🌱 SERVER: " .. player.Name .. " now has " .. playerData.farming.inventory[item.id] .. "x " .. item.id)

	-- Send detailed notification
	self:SendNotification(player, "🌱 Seeds Added!", 
		"Added " .. quantity .. "x " .. item.name .. " to your farming inventory!\nOpen Farm menu (F key) to view and plant them!", "success")

	return true
end


-- UPDATED: Enhanced planting system with proper validation
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
		local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
		local seedInfo = ItemConfig.GetItem(seedId)
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

	-- Check if this is the player's plot (security check)
	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return false
	end

	-- Get seed data
	local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
	local seedData = ItemConfig.GetSeedData(seedId)
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

	local seedInfo = ItemConfig.GetItem(seedId)
	local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
	self:SendNotification(player, "🌱 Seed Planted!", 
		"Successfully planted " .. seedName .. "!\nIt will be ready in " .. math.floor(seedData.growTime/60) .. " minutes.", "success")

	print("GameCore: Successfully planted " .. seedId .. " for " .. player.Name)
	return true
end

-- NEW: Create crop visual on plot
function GameCore:CreateCropOnPlot(plotModel, seedId, seedData)
	local success, error = pcall(function()
		-- Find the planting spot part
		local spotPart = plotModel:FindFirstChild("SpotPart")
		if not spotPart then
			warn("GameCore: No SpotPart found in plot model")
			return false
		end

		-- Remove existing crop model if any
		local existingCrop = plotModel:FindFirstChild("CropModel")
		if existingCrop then
			existingCrop:Destroy()
		end

		-- Create crop model
		local cropModel = Instance.new("Model")
		cropModel.Name = "CropModel"
		cropModel.Parent = plotModel

		-- Get crop appearance data based on seed type
		local cropAppearance = self:GetCropAppearance(seedId)

		-- Create crop part with specific appearance
		local cropPart = Instance.new("Part")
		cropPart.Name = "Crop"
		cropPart.Size = Vector3.new(2, 1, 2) -- Start small, will grow
		cropPart.Material = cropAppearance.material
		cropPart.Color = cropAppearance.color
		cropPart.Anchored = true
		cropPart.CanCollide = false
		cropPart.CFrame = spotPart.CFrame + Vector3.new(0, 1, 0)
		cropPart.Parent = cropModel

		-- Add crop-specific visual elements
		if cropAppearance.shape == "corn" then
			-- Make corn taller and more cylindrical
			cropPart.Shape = Enum.PartType.Cylinder
			cropPart.Size = Vector3.new(0.5, 3, 0.5)
			cropPart.CFrame = spotPart.CFrame + Vector3.new(0, 1.5, 0)
			cropPart.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be vertical
		elseif cropAppearance.shape == "carrot" then
			-- Make carrots more triangular/cone-like
			cropPart.Shape = Enum.PartType.Block
			cropPart.Size = Vector3.new(1, 2, 1)
		elseif cropAppearance.shape == "strawberry" then
			-- Make strawberries smaller and rounder
			cropPart.Shape = Enum.PartType.Ball
			cropPart.Size = Vector3.new(1.5, 1.5, 1.5)
		elseif cropAppearance.shape == "golden" then
			-- Make golden fruit special and glowing
			cropPart.Shape = Enum.PartType.Ball
			cropPart.Material = Enum.Material.Neon
			cropPart.Size = Vector3.new(2, 2, 2)
		end

		-- Add crop-specific decorations
		if cropAppearance.decorations then
			for _, decoration in ipairs(cropAppearance.decorations) do
				local decorPart = Instance.new("Part")
				decorPart.Name = decoration.name
				decorPart.Size = decoration.size
				decorPart.Color = decoration.color
				decorPart.Material = decoration.material or Enum.Material.LeafyGrass
				decorPart.Anchored = true
				decorPart.CanCollide = false
				decorPart.CFrame = cropPart.CFrame + decoration.offset
				decorPart.Parent = cropModel

				if decoration.shape then
					decorPart.Shape = decoration.shape
				end
			end
		end

		-- Create crop indicator with crop-specific color
		local indicator = Instance.new("Part")
		indicator.Name = "GrowthIndicator"
		indicator.Size = Vector3.new(0.5, 3, 0.5)
		indicator.Material = Enum.Material.Neon
		indicator.Color = Color3.fromRGB(255, 100, 100) -- Red for growing
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
				if growthStage >= 3 then
					self:HarvestCrop(clickingPlayer, plotModel)
				else
					self:SendNotification(clickingPlayer, "Not Ready", "Crop is still growing!", "warning")
				end
			end
		end)

		-- Start growth timer with crop-specific appearance changes
		self:StartCropGrowthTimer(plotModel, seedData, cropAppearance)

		return true
	end)

	if not success then
		warn("GameCore: Failed to create crop on plot: " .. tostring(error))
		return false
	end

	return true
end

-- NEW FUNCTION: Get crop appearance data based on seed type
function GameCore:GetCropAppearance(seedId)
	local appearances = {
		carrot_seeds = {
			color = Color3.fromRGB(255, 140, 0), -- Orange
			material = Enum.Material.SmoothPlastic,
			shape = "carrot",
			decorations = {
				{
					name = "CarrotTop",
					size = Vector3.new(2, 1, 0.2),
					color = Color3.fromRGB(34, 139, 34), -- Green top
					material = Enum.Material.LeafyGrass,
					offset = Vector3.new(0, 1.5, 0),
					shape = Enum.PartType.Block
				}
			}
		},

		corn_seeds = {
			color = Color3.fromRGB(255, 255, 0), -- Yellow
			material = Enum.Material.SmoothPlastic,
			shape = "corn",
			decorations = {
				{
					name = "CornHusk",
					size = Vector3.new(0.8, 3.5, 0.8),
					color = Color3.fromRGB(124, 252, 0), -- Light green husk
					material = Enum.Material.LeafyGrass,
					offset = Vector3.new(0, 0, 0),
					shape = Enum.PartType.Cylinder
				}
			}
		},

		strawberry_seeds = {
			color = Color3.fromRGB(220, 20, 60), -- Crimson red
			material = Enum.Material.SmoothPlastic,
			shape = "strawberry",
			decorations = {
				{
					name = "StrawberryLeaves",
					size = Vector3.new(2, 0.5, 2),
					color = Color3.fromRGB(34, 139, 34), -- Green leaves
					material = Enum.Material.LeafyGrass,
					offset = Vector3.new(0, 1, 0),
					shape = Enum.PartType.Block
				}
			}
		},

		golden_seeds = {
			color = Color3.fromRGB(255, 215, 0), -- Gold
			material = Enum.Material.Neon,
			shape = "golden",
			decorations = {
				{
					name = "GoldenGlow",
					size = Vector3.new(3, 3, 3),
					color = Color3.fromRGB(255, 255, 0), -- Bright yellow glow
					material = Enum.Material.ForceField,
					offset = Vector3.new(0, 0, 0),
					shape = Enum.PartType.Ball
				}
			}
		}
	}

	-- Default appearance for unknown seeds
	return appearances[seedId] or {
		color = Color3.fromRGB(100, 200, 100),
		material = Enum.Material.LeafyGrass,
		shape = "default",
		decorations = {}
	}
end

-- UPDATED: Enhanced growth timer with crop-specific visual changes
function GameCore:StartCropGrowthTimer(plotModel, seedData, cropAppearance)
	spawn(function()
		local growTime = seedData.growTime
		local stageTime = growTime / 4 -- 4 growth stages

		for stage = 0, 3 do
			wait(stageTime)

			-- Check if plot still exists and has crop
			if plotModel and plotModel.Parent then
				local currentStage = plotModel:GetAttribute("GrowthStage") or 0
				if currentStage == stage then
					-- Update growth stage
					plotModel:SetAttribute("GrowthStage", stage + 1)

					-- Update visual indicator
					local cropModel = plotModel:FindFirstChild("CropModel")
					if cropModel then
						local indicator = cropModel:FindFirstChild("GrowthIndicator")
						if indicator then
							local colors = {
								Color3.fromRGB(255, 100, 100), -- Stage 0: Red
								Color3.fromRGB(255, 200, 100), -- Stage 1: Orange
								Color3.fromRGB(255, 255, 100), -- Stage 2: Yellow
								Color3.fromRGB(100, 255, 100)  -- Stage 3: Green (ready)
							}
							indicator.Color = colors[stage + 2] or colors[4]
						end

						-- Scale crop as it grows with crop-specific scaling
						local crop = cropModel:FindFirstChild("Crop")
						if crop then
							local baseScale = 0.3 + (stage + 1) * 0.425 -- 0.3 to 2.0 scale

							-- Apply crop-specific scaling
							if cropAppearance.shape == "corn" then
								crop.Size = Vector3.new(0.5 * baseScale, 3 * baseScale, 0.5 * baseScale)
							elseif cropAppearance.shape == "carrot" then
								crop.Size = Vector3.new(1 * baseScale, 2 * baseScale, 1 * baseScale)
							elseif cropAppearance.shape == "strawberry" then
								crop.Size = Vector3.new(1.5 * baseScale, 1.5 * baseScale, 1.5 * baseScale)
							elseif cropAppearance.shape == "golden" then
								crop.Size = Vector3.new(2 * baseScale, 2 * baseScale, 2 * baseScale)
								-- Add extra glow when fully grown
								if stage >= 3 then
									crop.Material = Enum.Material.Neon
									local glow = cropModel:FindFirstChild("GoldenGlow")
									if glow then
										glow.Transparency = 0.3
									end
								end
							else
								crop.Size = Vector3.new(2 * baseScale, 1 * baseScale, 2 * baseScale)
							end

							-- Scale decorations too
							for _, decoration in pairs(cropModel:GetChildren()) do
								if decoration.Name:find("Top") or decoration.Name:find("Husk") or 
									decoration.Name:find("Leaves") or decoration.Name:find("Glow") then
									local decorScale = 0.5 + (stage + 1) * 0.375
									-- Apply scaling based on decoration type
									if decoration.Name == "CornHusk" then
										decoration.Size = Vector3.new(0.8 * decorScale, 3.5 * decorScale, 0.8 * decorScale)
									elseif decoration.Name == "CarrotTop" then
										decoration.Size = Vector3.new(2 * decorScale, 1 * decorScale, 0.2 * decorScale)
									elseif decoration.Name == "StrawberryLeaves" then
										decoration.Size = Vector3.new(2 * decorScale, 0.5 * decorScale, 2 * decorScale)
									elseif decoration.Name == "GoldenGlow" then
										decoration.Size = Vector3.new(3 * decorScale, 3 * decorScale, 3 * decorScale)
									end
								end
							end
						end
					end

					print("GameCore: " .. (seedData.resultCropId or "Unknown") .. " crop grown to stage " .. (stage + 1) .. " in plot " .. plotModel.Name)
				end
			else
				break -- Plot was destroyed, stop timer
			end
		end
	end)
end


-- UPDATED: Enhanced harvest crop system
function GameCore:HarvestCrop(player, plotModel)
	print("GameCore: Harvest request from " .. player.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end


	-- Check if this is the player's plot
	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only harvest your own crops!", "error")
		return false
	end

	-- Check if crop is ready
	local growthStage = plotModel:GetAttribute("GrowthStage") or 0
	if growthStage < 3 then
		self:SendNotification(player, "Not Ready", "Crop is not ready for harvest yet!", "warning")
		return false
	end

	-- Get crop data
	local plantType = plotModel:GetAttribute("PlantType") or ""
	local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
	local cropData = ItemConfig.GetCropData(plantType)
	if not cropData then
		self:SendNotification(player, "Invalid Crop", "Crop data not found!", "error")
		return false
	end

	-- NEW: Calculate pest damage impact on yield
	local pestDamage = 0
	if _G.PestSystem and _G.PestSystem.ActivePests[plotModel] then
		for pestType, pestInstance in pairs(_G.PestSystem.ActivePests[plotModel]) do
			pestDamage = pestDamage + (pestInstance.damage or 0)
		end
	end

	-- Calculate final yield based on pest damage
	local baseYield = cropData.yieldAmount or 1
	local damageMultiplier = 1 - math.min(pestDamage, 0.8) -- Maximum 80% damage
	local finalYield = math.max(1, math.floor(baseYield * damageMultiplier))

	-- Initialize farming inventory if needed
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	-- Add crops to inventory
	local currentAmount = playerData.farming.inventory[plantType] or 0
	playerData.farming.inventory[plantType] = currentAmount + finalYield

	-- Clear any remaining pests when harvesting
	if _G.PestSystem and _G.PestSystem.ActivePests[plotModel] then
		for pestType, _ in pairs(_G.PestSystem.ActivePests[plotModel]) do
			_G.PestSystem:RemovePest(plotModel, pestType, "crop_harvested")
		end
	end

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

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + finalYield

	-- Save and notify
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	-- Create appropriate notification based on pest damage
	local notificationMessage = "Harvested " .. finalYield .. "x " .. cropData.name .. "!"
	local notificationType = "success"

	if pestDamage > 0.1 then -- 10% or more damage
		local damagePercent = math.floor(pestDamage * 100)
		notificationMessage = notificationMessage .. "\n⚠️ " .. damagePercent .. "% yield lost to pests!"
		notificationType = "warning"

		if pestDamage > 0.5 then -- 50% or more damage
			notificationMessage = notificationMessage .. "\nConsider deploying chickens for protection!"
		end
	end

	self:SendNotification(player, "🌾 Crop Harvested!", notificationMessage, notificationType)

	print("GameCore: Successfully harvested " .. plantType .. " for " .. player.Name .. " (yield: " .. finalYield .. ", damage: " .. math.floor(pestDamage * 100) .. "%)")
	return true
end

-- ADD THESE FUNCTIONS to GameCore.lua (after the farm plot creation functions):

-- ========== ROOF PROTECTION SYSTEM ==========

-- Create roof protection over farm plot(s)
function GameCore:CreateRoofProtection(player, roofType, plotNumber)
	plotNumber = plotNumber or 1

	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	-- Initialize roof tracking
	if not playerData.roofs then
		playerData.roofs = {}
	end

	local roofData = ItemConfig.GetItem(roofType)
	if not roofData then
		warn("GameCore: Invalid roof type: " .. roofType)
		return false
	end

	local coverage = roofData.effects.coverage or 1
	local roofName = roofType .. "_" .. plotNumber

	-- Check if roof already exists
	if playerData.roofs[roofName] then
		self:SendNotification(player, "Roof Exists", "This area already has roof protection!", "warning")
		return false
	end

	-- Get farm area structure
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return false end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return false end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return false end

	local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
	if not playerFarm then return false end

	-- Create roof structure based on type
	local roofModel = self:CreateRoofStructure(player, roofType, plotNumber, coverage)
	if not roofModel then return false end

	roofModel.Parent = playerFarm

	-- Track roof in player data
	playerData.roofs[roofName] = {
		type = roofType,
		plotNumber = plotNumber,
		coverage = coverage,
		installed = true
	}

	self:SavePlayerData(player)

	local roofName = roofData.name or roofType
	self:SendNotification(player, "🏠 Roof Installed!", 
		roofName .. " protects your crops from UFO attacks!", "success")

	print("GameCore: Created " .. roofType .. " for " .. player.Name .. " covering plot " .. plotNumber)
	return true
end

-- Create the actual roof structure
function GameCore:CreateRoofStructure(player, roofType, plotNumber, coverage)
	local roofModel = Instance.new("Model")
	roofModel.Name = "Roof_" .. roofType .. "_" .. plotNumber

	-- Get base position for the roof
	local basePlotCFrame = self:GetFarmPlotPosition(player, plotNumber)
	if not basePlotCFrame then return nil end

	if roofType == "basic_roof" then
		-- Simple roof over one plot
		roofModel = self:CreateBasicRoof(basePlotCFrame)

	elseif roofType == "reinforced_roof" then
		-- Larger roof covering 4 plots (2x2 grid)
		roofModel = self:CreateReinforcedRoof(player, plotNumber)

	elseif roofType == "mega_dome" then
		-- Dome covering entire farm
		roofModel = self:CreateMegaDome(player)
	end

	roofModel.Name = "Roof_" .. roofType .. "_" .. plotNumber
	return roofModel
end

-- Create basic roof (1 plot coverage)
function GameCore:CreateBasicRoof(plotCFrame)
	local roofModel = Instance.new("Model")
	roofModel.Name = "BasicRoof"

	-- Roof base
	local roofBase = Instance.new("Part")
	roofBase.Name = "RoofBase"
	roofBase.Size = Vector3.new(20, 0.5, 20) -- Covers plot + border
	roofBase.Material = Enum.Material.Wood
	roofBase.Color = Color3.fromRGB(139, 90, 43) -- Brown wood
	roofBase.Anchored = true
	roofBase.CFrame = plotCFrame + Vector3.new(0, 8, 0) -- 8 studs above plot
	roofBase.Parent = roofModel

	-- Support pillars
	local pillarPositions = {
		Vector3.new(-9, -4, -9),
		Vector3.new(9, -4, -9), 
		Vector3.new(-9, -4, 9),
		Vector3.new(9, -4, 9)
	}

	for i, offset in ipairs(pillarPositions) do
		local pillar = Instance.new("Part")
		pillar.Name = "SupportPillar" .. i
		pillar.Size = Vector3.new(1, 8, 1)
		pillar.Material = Enum.Material.Wood
		pillar.Color = Color3.fromRGB(101, 67, 33) -- Darker brown
		pillar.Anchored = true
		pillar.CFrame = roofBase.CFrame + offset
		pillar.Parent = roofModel
	end

	-- Roof indicator (shows protection is active)
	local indicator = Instance.new("Part")
	indicator.Name = "ProtectionIndicator"
	indicator.Size = Vector3.new(18, 0.2, 18)
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(0, 255, 0) -- Green protection field
	indicator.Transparency = 0.7
	indicator.Anchored = true
	indicator.CFrame = roofBase.CFrame + Vector3.new(0, -0.5, 0)
	indicator.Parent = roofModel

	-- Add pulsing effect to show it's active
	spawn(function()
		while indicator and indicator.Parent do
			TweenService:Create(indicator, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Transparency = 0.3
			}):Play()
			wait(0.1)
		end
	end)

	return roofModel
end

-- Create reinforced roof (4 plot coverage)
function GameCore:CreateReinforcedRoof(player, plotNumber)
	local roofModel = Instance.new("Model")
	roofModel.Name = "ReinforcedRoof"

	-- Get center position for 2x2 coverage
	local centerCFrame = self:GetFarmPlotPosition(player, plotNumber)

	-- Large reinforced roof
	local roofBase = Instance.new("Part")
	roofBase.Name = "ReinforcedRoofBase"
	roofBase.Size = Vector3.new(50, 1, 50) -- Covers 4 plots
	roofBase.Material = Enum.Material.Metal
	roofBase.Color = Color3.fromRGB(163, 162, 165) -- Silver metal
	roofBase.Anchored = true
	roofBase.CFrame = centerCFrame + Vector3.new(0, 10, 0) -- Higher up
	roofBase.Parent = roofModel

	-- Metal support beams
	local beamConfigs = {
		{size = Vector3.new(50, 0.5, 2), offset = Vector3.new(0, -0.5, -24)},
		{size = Vector3.new(50, 0.5, 2), offset = Vector3.new(0, -0.5, 24)},
		{size = Vector3.new(2, 0.5, 50), offset = Vector3.new(-24, -0.5, 0)},
		{size = Vector3.new(2, 0.5, 50), offset = Vector3.new(24, -0.5, 0)}
	}

	for i, config in ipairs(beamConfigs) do
		local beam = Instance.new("Part")
		beam.Name = "SupportBeam" .. i
		beam.Size = config.size
		beam.Material = Enum.Material.Metal
		beam.Color = Color3.fromRGB(105, 105, 105) -- Dark gray
		beam.Anchored = true
		beam.CFrame = roofBase.CFrame + config.offset
		beam.Parent = roofModel
	end

	-- Heavy duty pillars
	local pillarPositions = {
		Vector3.new(-20, -5, -20), Vector3.new(20, -5, -20),
		Vector3.new(-20, -5, 20), Vector3.new(20, -5, 20),
		Vector3.new(0, -5, -20), Vector3.new(0, -5, 20),
		Vector3.new(-20, -5, 0), Vector3.new(20, -5, 0)
	}

	for i, offset in ipairs(pillarPositions) do
		local pillar = Instance.new("Part")
		pillar.Name = "HeavyPillar" .. i
		pillar.Size = Vector3.new(2, 10, 2)
		pillar.Material = Enum.Material.Metal
		pillar.Color = Color3.fromRGB(105, 105, 105)
		pillar.Anchored = true
		pillar.CFrame = roofBase.CFrame + offset
		pillar.Parent = roofModel
	end

	-- Enhanced protection field
	local field = Instance.new("Part")
	field.Name = "ProtectionField"
	field.Size = Vector3.new(48, 0.3, 48)
	field.Material = Enum.Material.Neon
	field.Color = Color3.fromRGB(0, 150, 255) -- Blue protection field
	field.Transparency = 0.6
	field.Anchored = true
	field.CFrame = roofBase.CFrame + Vector3.new(0, -1, 0)
	field.Parent = roofModel

	return roofModel
end

-- Create mega dome (covers entire farm)
function GameCore:CreateMegaDome(player)
	local roofModel = Instance.new("Model")
	roofModel.Name = "MegaDome"

	-- Get center of player's farm
	local centerCFrame = self:GetFarmPlotPosition(player, 1)

	-- Massive dome structure
	local dome = Instance.new("Part")
	dome.Name = "DomeShell"
	dome.Size = Vector3.new(100, 50, 100)
	dome.Shape = Enum.PartType.Ball
	dome.Material = Enum.Material.ForceField
	dome.Color = Color3.fromRGB(100, 200, 255) -- Light blue
	dome.Transparency = 0.4
	dome.Anchored = true
	dome.CFrame = centerCFrame + Vector3.new(0, 25, 0)
	dome.Parent = roofModel

	-- Dome base ring
	local baseRing = Instance.new("Part")
	baseRing.Name = "DomeBase"
	baseRing.Size = Vector3.new(105, 3, 105)
	baseRing.Shape = Enum.PartType.Cylinder
	baseRing.Material = Enum.Material.Metal
	baseRing.Color = Color3.fromRGB(255, 215, 0) -- Gold base
	baseRing.Anchored = true
	baseRing.CFrame = centerCFrame + Vector3.new(0, 1.5, 0)
	baseRing.Orientation = Vector3.new(0, 0, 90)
	baseRing.Parent = roofModel

	-- Energy field effect
	local energyField = Instance.new("Part")
	energyField.Name = "EnergyField"
	energyField.Size = Vector3.new(98, 48, 98)
	energyField.Shape = Enum.PartType.Ball
	energyField.Material = Enum.Material.Neon
	energyField.Color = Color3.fromRGB(50, 255, 50) -- Bright green
	energyField.Transparency = 0.8
	energyField.Anchored = true
	energyField.CFrame = dome.CFrame
	energyField.Parent = roofModel

	-- Pulsing energy effect
	spawn(function()
		while energyField and energyField.Parent do
			TweenService:Create(energyField, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Transparency = 0.5,
				Size = Vector3.new(102, 52, 102)
			}):Play()
			wait(0.1)
		end
	end)

	return roofModel
end

-- Check if a farm plot has roof protection
function GameCore:IsPlotProtected(player, plotNumber)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.roofs then return false end

	-- Check for specific roof protection
	for roofName, roofInfo in pairs(playerData.roofs) do
		if roofInfo.installed then
			local coverage = roofInfo.coverage or 1
			local roofPlotNumber = roofInfo.plotNumber or 1

			-- Check if this plot is within coverage range
			if roofInfo.type == "mega_dome" then
				return true -- Mega dome protects all plots
			elseif roofInfo.type == "reinforced_roof" then
				-- Reinforced roof covers 2x2 grid starting from roofPlotNumber
				local startPlot = roofPlotNumber
				local endPlot = startPlot + 3 -- Covers 4 plots
				if plotNumber >= startPlot and plotNumber <= endPlot then
					return true
				end
			elseif roofInfo.type == "basic_roof" then
				-- Basic roof covers exactly one plot
				if plotNumber == roofPlotNumber then
					return true
				end
			end
		end
	end

	return false
end



-- Get pest damage for a specific plot (helper function)
function GameCore:GetPlotPestDamage(plotModel)
	if not _G.PestSystem or not _G.PestSystem.ActivePests[plotModel] then
		return 0
	end

	local totalDamage = 0
	for pestType, pestInstance in pairs(_G.PestSystem.ActivePests[plotModel]) do
		totalDamage = totalDamage + (pestInstance.damage or 0)
	end

	return math.min(totalDamage, 1.0) -- Cap at 100% damage
end

-- Check if player has pest protection (helper function)
function GameCore:HasPestProtection(player, plotModel)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	-- Check for pest detector
	if playerData.pestControl and playerData.pestControl.pest_detector then
		return true
	end

	-- Check for nearby chickens
	if _G.ChickenSystem then
		local nearbyChickens = _G.ChickenSystem:GetAvailableChickens(player.Name, "any")
		for _, chicken in ipairs(nearbyChickens) do
			local distance = (chicken.position - plotModel.PrimaryPart.Position).Magnitude
			if distance <= 10 then -- 10 studs protection range
				return true
			end
		end
	end

	return false
end

print("GameCore: Pest and chicken system integration ready!")
print("New purchase handlers added:")
print("  ✅ Chicken purchases and deployment")
print("  ✅ Feed purchases and management") 
print("  ✅ Pest control tool purchases")
print("  ✅ Pesticide usage system")
print("  ✅ Enhanced crop harvest with pest damage")
print("  ✅ Integration with PestSystem and ChickenSystem")
-- ADMIN COMMANDS: Add these to test seed system
game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/giveseeds" then
				-- Give all types of seeds for testing
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					if not playerData.farming then
						playerData.farming = {plots = 1, inventory = {}}
					end
					if not playerData.farming.inventory then
						playerData.farming.inventory = {}
					end

					-- Add seeds
					playerData.farming.inventory.carrot_seeds = 10
					playerData.farming.inventory.corn_seeds = 8
					playerData.farming.inventory.strawberry_seeds = 5
					playerData.farming.inventory.golden_seeds = 3

					GameCore:SavePlayerData(player)
					GameCore:SendNotification(player, "Admin: Seeds Given", 
						"Added all seed types to your inventory!", "success")

					-- Force update client
					if GameCore.RemoteEvents.PlayerDataUpdated then
						GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
					end
					print("Admin: Gave all seeds to " .. player.Name)
				end

			elseif command == "/checkseeds" then
				-- Check player's seed inventory
				local playerData = GameCore:GetPlayerData(player)
				if playerData and playerData.farming and playerData.farming.inventory then
					print("=== SEED INVENTORY FOR " .. player.Name .. " ===")
					for itemId, quantity in pairs(playerData.farming.inventory) do
						if itemId:find("_seeds") then
							print("  " .. itemId .. ": " .. quantity)
						end
					end
					print("=====================================")
				else
					print("Admin: " .. player.Name .. " has no farming inventory")
				end
			elseif command == "/giveroof" then
				-- Give player roof protection for testing
				local roofType = args[2] or "basic_roof"
				local plotNumber = tonumber(args[3]) or 1

				local success = GameCore:CreateRoofProtection(player, roofType, plotNumber)
				if success then
					print("Admin: Gave " .. roofType .. " to " .. player.Name .. " on plot " .. plotNumber)
				else
					print("Admin: Failed to give roof to " .. player.Name)
				end

			elseif command == "/checkroofs" then
				-- Check player's roof protection status
				local playerData = GameCore:GetPlayerData(player)
				print("=== ROOF PROTECTION STATUS FOR " .. player.Name .. " ===")

				if playerData and playerData.roofs then
					for roofName, roofInfo in pairs(playerData.roofs) do
						print("  " .. roofName .. ": " .. roofInfo.type .. " (coverage: " .. roofInfo.coverage .. ")")
					end

					-- Test protection for each plot
					local plotCount = playerData.farming and playerData.farming.plots or 0
					print("Plot protection status:")
					for i = 1, plotCount do
						local protected = GameCore:IsPlotProtected(player, i)
						print("  Plot " .. i .. ": " .. (protected and "PROTECTED" or "VULNERABLE"))
					end
				else
					print("  No roof protection installed")
				end
				print("==================================================")
			elseif command == "/debugshop" then
				-- Debug shop items and categories
				print("=== SHOP DEBUG FOR " .. player.Name .. " ===")

				local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
				local playerData = GameCore:GetPlayerData(player)

				print("Available shop items by category:")
				local categories = {"seeds", "farm", "premium"}

				for _, category in ipairs(categories) do
					print("  Category: " .. category)
					local found = false
					for itemId, item in pairs(ItemConfig.ShopItems) do
						if item.category == category then
							found = true
							local canBuy, reason = ItemConfig.CanPlayerBuy(itemId, playerData)
							print("    " .. itemId .. " (" .. item.name .. ") - Can buy: " .. tostring(canBuy) .. " (" .. reason .. ")")
						end
					end
					if not found then
						print("    No items found in this category")
					end
				end

				print("Roof-specific items:")
				local roofItems = {"basic_roof", "reinforced_roof", "mega_dome"}
				for _, roofId in ipairs(roofItems) do
					local item = ItemConfig.ShopItems[roofId]
					if item then
						local canBuy, reason = ItemConfig.CanPlayerBuy(roofId, playerData)
						print("  " .. roofId .. ": EXISTS - Category: " .. item.category .. " - Can buy: " .. tostring(canBuy) .. " (" .. reason .. ")")
					else
						print("  " .. roofId .. ": NOT FOUND")
					end
				end

				print("Player purchase history:")
				if playerData.purchaseHistory then
					for item, purchased in pairs(playerData.purchaseHistory) do
						print("  " .. item .. ": " .. tostring(purchased))
					end
				else
					print("  No purchase history")
				end

				print("=====================================")

			elseif command == "/forceshoprefresh" then
				-- Force refresh shop for player
				if GameCore.RemoteEvents.PlayerDataUpdated then
					local playerData = GameCore:GetPlayerData(player)
					GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
					print("Admin: Forced shop refresh for " .. player.Name)
					GameCore:SendNotification(player, "Shop Refreshed", "Shop data has been updated", "info")
				end
			elseif command == "/testpurchase" then
				-- Test a purchase directly
				local testItem = "carrot_seeds"
				print("🧪 ADMIN: Testing purchase of " .. testItem)

				local success = GameCore:HandlePurchase(player, testItem, 1)
				print("🧪 ADMIN: Purchase test result: " .. tostring(success))

				if success then
					print("🧪 ADMIN: Purchase test successful!")
				else
					print("🧪 ADMIN: Purchase test failed!")
				end
			elseif command == "/givefarmplot" then
				-- Give player farm plot to meet roof requirements
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					-- Give them the farm plot starter
					playerData.purchaseHistory = playerData.purchaseHistory or {}
					playerData.purchaseHistory.farm_plot_starter = true
					playerData.farming = playerData.farming or {
						plots = 1, 
						inventory = {}
					}

					-- Create the plot
					GameCore:CreatePlayerFarmPlot(player, 1)
					GameCore:SavePlayerData(player)

					-- Update client
					if GameCore.RemoteEvents.PlayerDataUpdated then
						GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
					end

					GameCore:SendNotification(player, "Farm Plot Given", "You now have a farm plot and can buy roof protection!", "success")
					print("Admin: Gave farm plot to " .. player.Name)
				end
			elseif command == "/testufoproof" then
				-- Test UFO protection for player's farm
				local playerData = GameCore:GetPlayerData(player)
				if playerData and playerData.farming then
					local plotCount = playerData.farming.plots or 0
					local protectedCount = 0

					for i = 1, plotCount do
						if GameCore:IsPlotProtected(player, i) then
							protectedCount = protectedCount + 1
						end
					end

					print("Admin: " .. player.Name .. " has " .. protectedCount .. "/" .. plotCount .. " plots protected from UFO")

					if protectedCount == plotCount then
						print("Admin: " .. player.Name .. "'s farm is completely UFO-proof!")
					elseif protectedCount > 0 then
						print("Admin: " .. player.Name .. "'s farm is partially protected")
					else
						print("Admin: " .. player.Name .. "'s farm is completely vulnerable to UFO attacks")
					end
				end

			elseif command == "/clearroofs" then
				-- Remove all roofs for testing
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					playerData.roofs = {}
					GameCore:SavePlayerData(player)

					-- Remove physical roof structures
					local areas = workspace:FindFirstChild("Areas")
					if areas then
						local starterMeadow = areas:FindFirstChild("Starter Meadow")
						if starterMeadow then
							local farmArea = starterMeadow:FindFirstChild("Farm")
							if farmArea then
								local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
								if playerFarm then
									for _, child in pairs(playerFarm:GetChildren()) do
										if child.Name:find("Roof_") then
											child:Destroy()
										end
									end
								end
							end
						end
					end

					print("Admin: Cleared all roofs for " .. player.Name)
					GameCore:SendNotification(player, "Roofs Cleared", "All roof protection removed for testing", "info")
				end
			elseif command == "/checkcrop" then
				-- Check player's crop inventory
				local playerData = GameCore:GetPlayerData(player)
				if playerData and playerData.farming and playerData.farming.inventory then
					print("=== CROP INVENTORY FOR " .. player.Name .. " ===")
					for itemId, quantity in pairs(playerData.farming.inventory) do
						if not itemId:find("_seeds") and quantity > 0 then
							print("  " .. itemId .. ": " .. quantity)
						end
					end
					print("====================================")
				else
					print("Admin: " .. player.Name .. " has no crop inventory")
				end

			elseif command == "/resetfarming" then
				-- Reset player's farming data
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					playerData.farming = {
						plots = 1,
						inventory = {}
					}
					GameCore:SavePlayerData(player)
					GameCore:SendNotification(player, "Admin: Farming Reset", 
						"Your farming data has been reset!", "info")

					if GameCore.RemoteEvents.PlayerDataUpdated then
						GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
					end
					print("Admin: Reset farming data for " .. player.Name)
				end

			elseif command == "/forceharvest" then
				-- Force all crops to be ready for harvest
				local areas = workspace:FindFirstChild("Areas")
				if areas then
					local starterMeadow = areas:FindFirstChild("Starter Meadow")
					if starterMeadow then
						local farmArea = starterMeadow:FindFirstChild("Farm")
						if farmArea then
							local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
							if playerFarm then
								local harvestedCount = 0
								for _, plot in pairs(playerFarm:GetChildren()) do
									if plot:IsA("Model") and plot.Name:find("FarmPlot") then
										local plantingSpots = plot:FindFirstChild("PlantingSpots")
										if plantingSpots then
											for _, spot in pairs(plantingSpots:GetChildren()) do
												local isEmpty = spot:GetAttribute("IsEmpty")
												if not isEmpty then
													spot:SetAttribute("GrowthStage", 4) -- Force ready
													harvestedCount = harvestedCount + 1

													-- Update visual
													local cropModel = spot:FindFirstChild("CropModel")
													if cropModel then
														local indicator = cropModel:FindFirstChild("GrowthIndicator")
														if indicator then
															indicator.Color = Color3.fromRGB(100, 255, 100)
														end
													end
												end
											end
										end
									end
								end
								print("Admin: Forced " .. harvestedCount .. " crops to be ready for " .. player.Name)
							end
						end
					end
				end

			elseif command == "/farmstatus" then
				-- Show detailed farming status
				local playerData = GameCore:GetPlayerData(player)
				print("=== FARMING STATUS FOR " .. player.Name .. " ===")
				if playerData then
					print("Has farming data:", playerData.farming ~= nil)
					if playerData.farming then
						print("Plots:", playerData.farming.plots or 0)
						print("Inventory exists:", playerData.farming.inventory ~= nil)
						if playerData.farming.inventory then
							local seedCount = 0
							local cropCount = 0
							for itemId, quantity in pairs(playerData.farming.inventory) do
								if itemId:find("_seeds") then
									seedCount = seedCount + quantity
								else
									cropCount = cropCount + quantity
								end
							end
							print("Total seeds:", seedCount)
							print("Total crops:", cropCount)
						end
					end
				else
					print("No player data found")
				end
				print("============================================")
			end
		end
	end)
end)

print("Server-Side Seed System: Enhanced seed purchase and planting system loaded!")
print("Admin Commands (CHAT):")
print("  /giveseeds - Give all seed types for testing")
print("  /checkseeds - Check player's seed inventory")
print("  /checkcrop - Check player's crop inventory") 
print("  /resetfarming - Reset player's farming data")
print("  /forceharvest - Force all crops to be ready")
print("  /farmstatus - Show detailed farming status")

return GameCore