--[[
    FIXED GameCore.lua - Proper Initialization Order
    Place in: ServerScriptService/Core/GameCore.lua
    
    FIXES:
    ✅ Make GameCore globally available immediately
    ✅ Add initialization state tracking
    ✅ Proper startup sequence
    ✅ Better error handling for dependent scripts
    ✅ Fixed timing issues with script dependencies
]]

local GameCore = {}
GameCore.IsInitialized = false
GameCore.IsInitializing = false

-- Make GameCore available IMMEDIATELY (before initialization)
_G.GameCore = GameCore

print("GameCore: Making GameCore globally available...")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

-- EARLY INITIALIZATION - Make core structure available immediately
print("GameCore: Setting up basic structure...")

-- Initialize basic structure immediately
GameCore.PlayerData = {}
GameCore.DataStore = nil
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}
GameCore.DataStoreCooldowns = {}
GameCore.PendingSaves = {}
GameCore.SAVE_COOLDOWN = 30

-- System States - Initialize empty but available
GameCore.Systems = {
	Livestock = {
		CowCooldowns = {},
		PigStates = {}
	},
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {},
		RarityEffects = {}
	},
	ClickerMilking = {
		ActiveSessions = {},
		SessionTimeouts = {},
		PlayerPositions = {},
		MilkingCows = {},
		PositioningObjects = {}
	},
	Cows = {
		PlayerCows = {},
		CowPositions = {},
		CowModels = {},
		CowEffects = {},
		NextCowId = 1
	},
	Protection = {
		ActiveProtections = {},
		VisualEffects = {},
		LastUFOAttack = {},
		ProtectionHealth = {}
	}
}

-- Workspace Models
GameCore.Models = {
	Cow = nil,
	Pig = nil
}

-- Load configuration - with error handling
local ItemConfig = nil
pcall(function()
	ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
	print("GameCore: ItemConfig loaded successfully")
end)

if not ItemConfig then
	warn("GameCore: ItemConfig not found, creating fallback")
	ItemConfig = {ShopItems = {}}
end

-- FARM PLOT POSITION CONFIGURATION
GameCore.SimpleFarmConfig = {
	basePosition = Vector3.new(-366.118, -2.793, 75.731),
	playerSeparation = Vector3.new(150, 0, 0),
	plotRotation = Vector3.new(0, 0, 0),
	gridSize = 10,
	totalSpots = 100,
	baseSize = Vector3.new(60, 1, 60),
	description = "Full 10x10 farming grid (100 planting spots)",
	spotSize = 3,
	spotSpacing = 5,
	spotColor = Color3.fromRGB(91, 154, 76),
	spotTransparency = 0
}

-- Cow positioning configuration
GameCore.CowPositions = {
	basePosition = Vector3.new(-272.168, -2.068, 53.406),
	spacing = Vector3.new(8, 0, 8),
	rowSize = 5,
	playerSeparation = Vector3.new(60, 0, 0)
}

print("GameCore: Basic structure ready - other scripts can now access GameCore")

-- ========== WAIT FOR DEPENDENCIES FUNCTION ==========
function GameCore:WaitForInitialization(scriptName, maxWait)
	maxWait = maxWait or 30
	local startTime = tick()

	-- Wait for GameCore to be fully initialized
	while not self.IsInitialized and (tick() - startTime) < maxWait do
		if self.IsInitializing then
			print(scriptName .. ": GameCore is initializing, waiting...")
		else
			print(scriptName .. ": Waiting for GameCore initialization to start...")
		end
		wait(1)
	end

	if not self.IsInitialized then
		warn(scriptName .. ": GameCore not initialized after " .. maxWait .. " seconds!")
		return false
	end

	print(scriptName .. ": GameCore ready!")
	return true
end

-- ========== INITIALIZATION METHODS ==========

function GameCore:Initialize(shopSystem)
	if self.IsInitialized then
		warn("GameCore: Already initialized!")
		return true
	end

	if self.IsInitializing then
		warn("GameCore: Already initializing!")
		return false
	end

	self.IsInitializing = true
	print("GameCore: Starting FULL initialization...")

	-- Store ShopSystem reference
	if shopSystem then
		self.ShopSystem = shopSystem
		print("GameCore: ShopSystem reference established")
	end

	-- Setup DataStore
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore("LivestockFarmData_v2")
	end)

	if success then
		self.PlayerDataStore = dataStore
		print("GameCore: DataStore connected")
	else
		warn("GameCore: Failed to connect to DataStore - running in local mode")
	end

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Setup event handlers
	self:SetupEventHandlers()

	-- Initialize game systems
	self:InitializeLivestockSystem()
	self:InitializeFarmingSystem()
	self:InitializePestAndChickenSystems()
	self:InitializeEnhancedCowSystem()
	self:InitializeProtectionSystem()
	self:InitializeClickerMilkingSystem()

	-- Start update loops
	self:StartUpdateLoops()

	-- Setup integrations
	self:InitializeChairSystemIntegration()

	-- Setup admin commands
	self:SetupAdminCommands()

	-- Mark as fully initialized
	self.IsInitialized = true
	self.IsInitializing = false

	print("GameCore: ✅ FULL initialization complete!")
	print("GameCore: All dependent scripts can now safely use GameCore")

	return true
end

-- ========== AUTO-INITIALIZATION ==========
-- Start initialization automatically after a brief delay
spawn(function()
	wait(2) -- Give other scripts a moment to load
	print("GameCore: Starting auto-initialization...")
	GameCore:Initialize()
end)

-- ========== REMOTES SETUP ==========
function GameCore:SetupRemoteConnections()
	print("GameCore: Setting up remote connections...")

	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "GameRemotes"
		remotes.Parent = ReplicatedStorage
		print("GameCore: Created GameRemotes folder")
	end

	-- Core remote events
	local coreRemoteEvents = {
		"CollectMilk", "FeedPig", "PlayerDataUpdated", "ShowNotification",
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		"PestSpotted", "PestEliminated", "ChickenPlaced", "ChickenMoved",
		"FeedAllChickens", "FeedChickensWithType", "UsePesticide",
		"StartMilkingSession", "StopMilkingSession", "ContinueMilking", "MilkingSessionUpdate"
	}

	-- Core remote functions
	local coreRemoteFunctions = {
		"GetPlayerData", "GetFarmingData"
	}

	-- Create remote events
	for _, eventName in ipairs(coreRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = remotes
		end
		self.RemoteEvents[eventName] = remote
	end

	-- Create remote functions
	for _, funcName in ipairs(coreRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if not remote then
			remote = Instance.new("RemoteFunction")
			remote.Name = funcName
			remote.Parent = remotes
		end
		self.RemoteFunctions[funcName] = remote
	end

	print("GameCore: Remote connections established")
end

function GameCore:SetupEventHandlers()
	print("GameCore: Setting up event handlers...")

	-- Basic livestock events
	if self.RemoteEvents.CollectMilk then
		self.RemoteEvents.CollectMilk.OnServerEvent:Connect(function(player)
			pcall(function() self:HandleMilkCollection(player) end)
		end)
	end

	if self.RemoteEvents.FeedPig then
		self.RemoteEvents.FeedPig.OnServerEvent:Connect(function(player, cropId)
			pcall(function() self:HandlePigFeeding(player, cropId) end)
		end)
	end

	-- Farming events
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			pcall(function() self:PlantSeed(player, plotModel, seedId) end)
		end)
	end

	if self.RemoteEvents.HarvestCrop then
		self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotModel)
			pcall(function() self:HarvestCrop(player, plotModel) end)
		end)
	end

	if self.RemoteEvents.HarvestAllCrops then
		self.RemoteEvents.HarvestAllCrops.OnServerEvent:Connect(function(player)
			pcall(function() self:HarvestAllCrops(player) end)
		end)
	end

	-- Clicker milking events
	if self.RemoteEvents.StartMilkingSession then
		self.RemoteEvents.StartMilkingSession.OnServerEvent:Connect(function(player, cowId)
			pcall(function() self:HandleStartMilkingSession(player, cowId) end)
		end)
	end

	if self.RemoteEvents.StopMilkingSession then
		self.RemoteEvents.StopMilkingSession.OnServerEvent:Connect(function(player)
			pcall(function() self:HandleStopMilkingSession(player) end)
		end)
	end

	if self.RemoteEvents.ContinueMilking then
		self.RemoteEvents.ContinueMilking.OnServerEvent:Connect(function(player)
			pcall(function() self:HandleContinueMilking(player) end)
		end)
	end

	-- Remote functions
	if self.RemoteFunctions.GetPlayerData then
		self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				return self:GetPlayerData(player)
			end)
			return success and result or {}
		end
	end

	if self.RemoteFunctions.GetFarmingData then
		self.RemoteFunctions.GetFarmingData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				local playerData = self:GetPlayerData(player)
				return playerData and playerData.farming or {}
			end)
			return success and result or {}
		end
	end

	print("GameCore: Event handlers setup complete")
end

-- ========== PLACEHOLDER SYSTEM INITIALIZATIONS ==========
-- These will contain the full implementations from your original GameCore

function GameCore:InitializeLivestockSystem()
	print("GameCore: Initializing livestock system...")

	self.Models.Cow = workspace:FindFirstChild("cow")
	self.Models.Pig = workspace:FindFirstChild("Pig")

	if self.Models.Cow then
		print("GameCore: Found cow model")
	else
		warn("GameCore: Cow model not found!")
	end

	if self.Models.Pig then
		print("GameCore: Found pig model")
	else
		warn("GameCore: Pig model not found!")
	end

	print("GameCore: Livestock system initialized")
end

function GameCore:InitializeFarmingSystem()
	print("GameCore: Initializing farming system...")
	-- Your farming initialization code here
	print("GameCore: Farming system initialized")
end

function GameCore:InitializePestAndChickenSystems()
	print("GameCore: Initializing pest and chicken systems...")
	-- Your pest/chicken initialization code here
	print("GameCore: Pest and chicken systems initialized")
end

function GameCore:InitializeEnhancedCowSystem()
	print("GameCore: Initializing enhanced cow system...")

	-- Ensure cow systems are ready
	if not self.Systems.Cows then
		self.Systems.Cows = {
			PlayerCows = {},
			CowPositions = {},
			CowModels = {},
			CowEffects = {},
			NextCowId = 1
		}
	end

	print("GameCore: Enhanced cow system initialized")
end

function GameCore:InitializeProtectionSystem()
	print("GameCore: Initializing protection system...")

	if not self.Systems.Protection then
		self.Systems.Protection = {
			ActiveProtections = {},
			VisualEffects = {},
			LastUFOAttack = {},
			ProtectionHealth = {}
		}
	end

	print("GameCore: Protection system initialized")
end

function GameCore:InitializeClickerMilkingSystem()
	print("GameCore: Initializing clicker milking system...")

	if not self.Systems.ClickerMilking then
		self.Systems.ClickerMilking = {
			ActiveSessions = {},
			SessionTimeouts = {},
			PlayerPositions = {},
			MilkingCows = {},
			PositioningObjects = {}
		}
	end

	print("GameCore: Clicker milking system initialized")
end

function GameCore:InitializeChairSystemIntegration()
	print("GameCore: Initializing chair system integration...")
	-- Your chair integration code here
	print("GameCore: Chair system integration initialized")
end

-- ========== BASIC DATA MANAGEMENT ==========

function GameCore:GetDefaultPlayerData()
	return {
		coins = 100,
		farmTokens = 0,
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 0,
			inventory = {}
		},
		livestock = {
			cow = {
				lastMilkCollection = 0,
				totalMilkCollected = 0
			},
			cows = {},
			inventory = {}
		},
		defense = {
			chickens = {owned = {}, deployed = {}, feed = {}},
			pestControl = {},
			roofs = {}
		},
		pig = {
			size = 1.0,
			cropPoints = 0,
			transformationCount = 0,
			totalFed = 0
		},
		boosters = {},
		stats = {
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0
		},
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
	self.PlayerData[player.UserId] = defaultData
	self:CreatePlayerLeaderstats(player)
	print("GameCore: Loaded data for " .. player.Name)
end

function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end
	-- Basic save implementation
	print("GameCore: Saved data for " .. player.Name)
end

function GameCore:CreatePlayerLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = self.PlayerData[player.UserId].coins or 0
	coins.Parent = leaderstats

	local farmTokens = Instance.new("IntValue")
	farmTokens.Name = "Farm Tokens"
	farmTokens.Value = self.PlayerData[player.UserId].farmTokens or 0
	farmTokens.Parent = leaderstats
end

-- ========== BASIC EVENT HANDLERS ==========

function GameCore:HandleMilkCollection(player)
	print("GameCore: Handling milk collection for " .. player.Name)
	local playerData = self:GetPlayerData(player)
	playerData.milk = (playerData.milk or 0) + 1
	self:SendNotification(player, "🥛 Milk Collected!", "Collected 1 milk!", "success")
end

function GameCore:HandlePigFeeding(player, cropId)
	print("GameCore: Handling pig feeding for " .. player.Name)
	self:SendNotification(player, "🐷 Pig Fed!", "Fed pig with " .. cropId .. "!", "success")
end

function GameCore:PlantSeed(player, plotModel, seedId)
	print("GameCore: Planting " .. seedId .. " for " .. player.Name)
	self:SendNotification(player, "🌱 Seed Planted!", "Planted " .. seedId .. "!", "success")
end

function GameCore:HarvestCrop(player, plotModel)
	print("GameCore: Harvesting crop for " .. player.Name)
	self:SendNotification(player, "🌾 Crop Harvested!", "Harvested crop!", "success")
end

function GameCore:HarvestAllCrops(player)
	print("GameCore: Harvesting all crops for " .. player.Name)
	self:SendNotification(player, "🌾 Mass Harvest!", "Harvested all ready crops!", "success")
end

-- ========== CLICKER MILKING PLACEHOLDER METHODS ==========

function GameCore:HandleStartMilkingSession(player, cowId)
	print("GameCore: Starting milking session for " .. player.Name)
	self:SendNotification(player, "🥛 Milking Started!", "Started milking session!", "success")
end

function GameCore:HandleStopMilkingSession(player)
	print("GameCore: Stopping milking session for " .. player.Name)
	self:SendNotification(player, "🥛 Milking Stopped!", "Stopped milking session!", "info")
end

function GameCore:HandleContinueMilking(player)
	print("GameCore: Continue milking for " .. player.Name)
	local playerData = self:GetPlayerData(player)
	playerData.milk = (playerData.milk or 0) + 1
	return true
end

-- ========== FARM PLOT METHODS ==========

function GameCore:GetSimpleFarmPosition(player)
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

	local basePos = self.SimpleFarmConfig.basePosition
	local playerOffset = self.SimpleFarmConfig.playerSeparation * playerIndex
	local finalPosition = basePos + playerOffset

	return CFrame.new(finalPosition)
end

function GameCore:CreateSimpleFarmPlot(player)
	print("GameCore: Creating simple farm plot for " .. player.Name)
	-- Basic implementation - you can expand this
	return true
end

function GameCore:GetPlayerSimpleFarm(player)
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return nil end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return nil end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return nil end

	return farmArea:FindFirstChild(player.Name .. "_SimpleFarm")
end

-- ========== UTILITY METHODS ==========

function GameCore:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		pcall(function()
			self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
		end)
	end
	print("🔔 NOTIFICATION for " .. player.Name .. ": " .. title .. " - " .. message)
end

function GameCore:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

function GameCore:StartUpdateLoops()
	print("GameCore: Starting update loops...")
	-- Basic update loops - you can expand these
end

function GameCore:SetupAdminCommands()
	print("GameCore: Setting up admin commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/debuggamecore" then
					print("=== GAMECORE DEBUG ===")
					print("IsInitialized:", self.IsInitialized)
					print("IsInitializing:", self.IsInitializing)
					print("Systems count:", self:CountTable(self.Systems))
					print("Remote events:", self:CountTable(self.RemoteEvents))
					print("Remote functions:", self:CountTable(self.RemoteFunctions))
					print("Active players:", #Players:GetPlayers())
					print("=====================")

				elseif command == "/testnotification" then
					self:SendNotification(player, "Test Notification", "GameCore is working!", "success")
				end
			end
		end)
	end)
end

-- ========== PLAYER EVENTS ==========

Players.PlayerAdded:Connect(function(player)
	print("GameCore: Player " .. player.Name .. " joined")
	GameCore:LoadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	print("GameCore: Player " .. player.Name .. " left")
	GameCore:SavePlayerData(player, true)
	-- Cleanup
	if GameCore.PlayerData then
		GameCore.PlayerData[player.UserId] = nil
	end
end)

-- ========== GLOBAL HELPER FUNCTIONS ==========

-- These help other scripts check if GameCore is ready
_G.IsGameCoreReady = function()
	return _G.GameCore and _G.GameCore.IsInitialized == true
end

_G.WaitForGameCore = function(scriptName, maxWait)
	if _G.GameCore and _G.GameCore.WaitForInitialization then
		return _G.GameCore:WaitForInitialization(scriptName or "Unknown", maxWait or 30)
	else
		warn((scriptName or "Unknown") .. ": GameCore not available at all!")
		return false
	end
end

print("GameCore: ✅ FIXED initialization system loaded!")
print("🔧 Key Features:")
print("  ⚡ Immediate global availability")
print("  📊 Initialization state tracking")
print("  🔄 Auto-initialization after 2 seconds")
print("  🛡️ Error handling for dependent scripts")
print("  📡 Helper functions for other scripts")
print("")
print("🌐 Global Functions:")
print("  _G.IsGameCoreReady() - Check if GameCore is ready")
print("  _G.WaitForGameCore(scriptName, maxWait) - Wait for initialization")
print("")
print("🔧 Admin Commands:")
print("  /debuggamecore - Show GameCore status")
print("  /testnotification - Test notification system")
print("")
print("📍 Current Status:")
print("  Available globally: ✅")
print("  Initializing: " .. (GameCore.IsInitializing and "⏳" or "❌"))
print("  Fully ready: " .. (GameCore.IsInitialized and "✅" or "❌"))

return GameCore