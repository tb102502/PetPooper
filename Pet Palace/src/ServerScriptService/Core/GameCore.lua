--[[
    UPDATED GameCore.lua - Complete Farming System (Mutation Code Removed)
    Place in: ServerScriptService/Core/GameCore.lua
    
    FEATURES:
    ✅ All seeds from ItemConfig now work
    ✅ Rarity system fully implemented
    ✅ Proper crop appearance based on rarity
    ✅ Enhanced planting and harvesting
    ✅ Better error handling
    ✅ Debug commands for testing
    ✅ Mutation system integration via module
]]


local GameCore = {}

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
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

-- Module references
local MutationSystem = nil
local CowCreationModule = nil
local CowMilkingModule = nil

-- ========== MODULE LOADING ==========

function GameCore:LoadCowModules()
	print("GameCore: Loading cow management modules...")

	local success = true

	-- Load CowCreationModule
	local cowCreationSuccess, cowCreationResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("CowCreationModule", 10)
		if not moduleScript then
			error("CowCreationModule script not found in ServerScriptService")
		end
		return require(moduleScript)
	end)

	if cowCreationSuccess and cowCreationResult then
		CowCreationModule = cowCreationResult
		print("GameCore: ✅ CowCreationModule loaded successfully")
	else
		warn("GameCore: ❌ Failed to load CowCreationModule: " .. tostring(cowCreationResult))
		success = false
	end

	-- Load CowMilkingModule
	local cowMilkingSuccess, cowMilkingResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("CowMilkingModule", 10)
		if not moduleScript then
			error("CowMilkingModule script not found in ServerScriptService")
		end
		return require(moduleScript)
	end)

	if cowMilkingSuccess and cowMilkingResult then
		CowMilkingModule = cowMilkingResult
		print("GameCore: ✅ CowMilkingModule loaded successfully")
	else
		warn("GameCore: ❌ Failed to load CowMilkingModule: " .. tostring(cowMilkingResult))
		success = false
	end

	return success
end

function GameCore:LoadCropVisualManager()
	print("GameCore: Loading CropVisualManager module...")

	local success, result = pcall(function()
		local moduleScript = game.ServerScriptService:WaitForChild("CropVisualManager", 10)

		if not moduleScript then
			error("CropVisualManager script not found in ServerScriptService")
		end

		if not moduleScript:IsA("ModuleScript") then
			error("CropVisualManager is not a ModuleScript")
		end

		local cropManager = require(moduleScript)
		local initSuccess = cropManager:Initialize()
		if not initSuccess then
			error("CropVisualManager initialization failed")
		end

		return cropManager
	end)

	if success and result then
		CropVisualManager = result
		_G.CropVisualManager = result
		print("GameCore: ✅ CropVisualManager loaded and initialized successfully")
		local status = result:GetStatus()
		print("GameCore: CropVisualManager status: " .. status.modelsLoaded .. " models loaded")
		return true
	else
		warn("GameCore: ❌ Failed to load CropVisualManager: " .. tostring(result))
		CropVisualManager = nil
		_G.CropVisualManager = nil
		return false
	end
end

function GameCore:LoadMutationSystem()
	print("GameCore: Loading MutationSystem module...")

	local success, result = pcall(function()
		local moduleScript = game.ServerScriptService:WaitForChild("MutationSystem", 10)

		if not moduleScript then
			error("MutationSystem script not found in ServerScriptService")
		end

		if not moduleScript:IsA("ModuleScript") then
			error("MutationSystem is not a ModuleScript")
		end

		local mutationSystem = require(moduleScript)
		local initSuccess = mutationSystem:Initialize(self, CropVisualManager)

		if not initSuccess then
			error("MutationSystem initialization failed")
		end

		return mutationSystem
	end)

	if success and result then
		MutationSystem = result
		_G.MutationSystem = result
		print("GameCore: ✅ MutationSystem loaded and initialized successfully")
		return true
	else
		warn("GameCore: ❌ Failed to load MutationSystem: " .. tostring(result))
		MutationSystem = nil
		_G.MutationSystem = nil
		return false
	end
end

-- ========== INITIALIZATION ==========

function GameCore:Initialize(shopSystem)
	print("GameCore: Starting ENHANCED core game system initialization...")

	-- STEP 1: Load all modules
	local cropManagerLoaded = self:LoadCropVisualManager()
	if not cropManagerLoaded then
		warn("GameCore: CropVisualManager failed to load - will use fallback only")
	end

	local mutationSystemLoaded = self:LoadMutationSystem()
	if not mutationSystemLoaded then
		warn("GameCore: MutationSystem failed to load - mutations will be disabled")
	end

	-- STEP 2: Load cow modules
	local cowModulesLoaded = self:LoadCowModules()
	if not cowModulesLoaded then
		warn("GameCore: Some cow modules failed to load - cow functionality may be limited")
	end

	-- Store ShopSystem reference
	if shopSystem then
		self.ShopSystem = shopSystem
		print("GameCore: ShopSystem reference established")
	end

	-- Initialize player data storage
	self.PlayerData = {}

	-- Setup DataStore
	local success, dataStore = pcall(function()
		return game:GetService("DataStoreService"):GetDataStore("LivestockFarmData_v2")
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
	self:InitializeFarmingSystem()

	-- STEP 3: Initialize cow modules
	if CowCreationModule then
		local cowCreationSuccess = CowCreationModule:Initialize(self, ItemConfig)
		if cowCreationSuccess then
			print("GameCore: ✅ CowCreationModule initialized successfully")
		else
			warn("GameCore: ❌ CowCreationModule initialization failed")
		end
	end

	if CowMilkingModule then
		local cowMilkingSuccess = CowMilkingModule:Initialize(self, CowCreationModule)
		if cowMilkingSuccess then
			print("GameCore: ✅ CowMilkingModule initialized successfully")
		else
			warn("GameCore: ❌ CowMilkingModule initialization failed")
		end
	end

	-- Start update loops
	self:InitializeCropEventSystem()
	self:AddPlantingDebugCommands()
	self:AddCropDebugCommands()
	self:AddCropCreationDebugCommands()
	self:AddDataStoreDebugCommands()
	self:AddModuleDebugCommands()

	-- Setup admin commands
	self:SetupAdminCommands()

	print("GameCore: ✅ ENHANCED core game system initialization complete!")
	return true
end

-- ========== COW SYSTEM INTEGRATION ==========

-- Redirect cow-related methods to modules
function GameCore:PurchaseCow(player, cowType, upgradeFromCowId)
	if CowCreationModule then
		return CowCreationModule:PurchaseCow(player, cowType, upgradeFromCowId)
	else
		warn("GameCore: CowCreationModule not available")
		return false
	end
end

function GameCore:HandleCowMilkCollection(player, cowId)
	if CowMilkingModule then
		return CowMilkingModule:HandleCowMilkCollection(player, cowId)
	else
		warn("GameCore: CowMilkingModule not available")
		return false
	end
end

function GameCore:HandleStartMilkingSession(player, cowId)
	if CowMilkingModule then
		return CowMilkingModule:HandleStartMilkingSession(player, cowId)
	else
		warn("GameCore: CowMilkingModule not available")
		return false
	end
end

function GameCore:HandleStopMilkingSession(player)
	if CowMilkingModule then
		return CowMilkingModule:HandleStopMilkingSession(player)
	else
		warn("GameCore: CowMilkingModule not available")
		return false
	end
end

function GameCore:HandleContinueMilking(player)
	if CowMilkingModule then
		return CowMilkingModule:HandleContinueMilking(player)
	else
		warn("GameCore: CowMilkingModule not available")
		return false
	end
end

function GameCore:CreateNewCowSafely(player, cowType, cowConfig)
	if CowCreationModule then
		return CowCreationModule:CreateNewCow(player, cowType, cowConfig)
	else
		warn("GameCore: CowCreationModule not available")
		return false
	end
end

function GameCore:UpdateCowIndicator(cowModel, state)
	if CowMilkingModule then
		local cowId = cowModel:GetAttribute("CowId") or cowModel.Name
		return CowMilkingModule:UpdateCowIndicator(cowId, state)
	else
		warn("GameCore: CowMilkingModule not available for indicator update")
		return false
	end
end

-- Integration helper for external scripts
function GameCore:HandleCowMilkCollectionExternal(player, cowModel)
	if not cowModel then
		warn("GameCore: HandleCowMilkCollectionExternal called with nil cowModel")
		return false
	end

	local cowId = cowModel:GetAttribute("CowId") or cowModel.Name
	return self:HandleCowMilkCollection(player, cowId)
end

-- FARM PLOT POSITION CONFIGURATION
GameCore.SimpleFarmConfig = {
	basePosition = Vector3.new(-366.118, -2.793, 75.731),
	playerSeparation = Vector3.new(150, 0, 0),
	plotRotation = Vector3.new(0, 0, 0),

	-- Single configuration - always 10x10 grid
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
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {},
		RarityEffects = {} -- Track rarity effects for crops
	}
}

-- Reference to ShopSystem (will be injected)
GameCore.ShopSystem = nil

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
		"CollectMilk", "PlayerDataUpdated", "ShowNotification",
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		"PurchaseItem", "ItemPurchased", "SellItem", "ItemSold", "CurrencyUpdated",
		"OpenShop", "CloseShop"
	}

	-- Core remote functions (excluding shop-related ones)
	local coreRemoteFunctions = {
		"GetPlayerData", "GetFarmingData",
		"GetShopItems", "GetShopItemsByCategory", "GetSellableItems"
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

	-- Farming System Events
	if self.RemoteEvents.PlantSeed then
		-- Disconnect any existing connections
		if self.PlantSeedConnection then
			self.PlantSeedConnection:Disconnect()
		end

		-- Create new protected connection
		self.PlantSeedConnection = self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			local userId = player.UserId

			-- Debounce at the RemoteEvent level too
			if not self.RemoteEventCooldowns then
				self.RemoteEventCooldowns = {}
			end

			local currentTime = tick()
			local lastRemoteTime = self.RemoteEventCooldowns[userId .. "_PlantSeed"] or 0

			if currentTime - lastRemoteTime < 0.2 then -- 200ms debounce for remote events
				warn("🚨 REMOTE EVENT SPAM: PlantSeed called too rapidly by " .. player.Name)
				return
			end

			self.RemoteEventCooldowns[userId .. "_PlantSeed"] = currentTime

			pcall(function()
				self:PlantSeed(player, plotModel, seedId)
			end)
		end)
		print("✅ Connected protected PlantSeed handler")
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

function GameCore:WaitForCropVisualManager()
	print("GameCore: Waiting for CropVisualManager to load...")

	local attempts = 0
	local maxAttempts = 20 -- 10 seconds max

	while not _G.CropVisualManager and attempts < maxAttempts do
		wait(0.5)
		attempts = attempts + 1

		if attempts % 4 == 0 then -- Every 2 seconds
			print("GameCore: Still waiting for CropVisualManager... (attempt " .. attempts .. "/" .. maxAttempts .. ")")
		end
	end

	if _G.CropVisualManager then
		print("GameCore: ✅ CropVisualManager found successfully!")

		-- Verify the methods we need exist
		local requiredMethods = {
			"CreateCropModel",
			"HandleCropPlanted", 
			"PositionCropModel"
		}

		local missingMethods = {}
		for _, methodName in ipairs(requiredMethods) do
			if not _G.CropVisualManager[methodName] then
				table.insert(missingMethods, methodName)
			end
		end

		if #missingMethods > 0 then
			warn("GameCore: ⚠️ CropVisualManager missing methods: " .. table.concat(missingMethods, ", "))
			warn("GameCore: Will use fallback crop creation")
		else
			print("GameCore: ✅ All required CropVisualManager methods found")

			-- Test CropVisualManager integration
			self:TestCropVisualManagerIntegration()
		end
	else
		warn("GameCore: ❌ CropVisualManager not found after " .. (maxAttempts * 0.5) .. " seconds!")
		warn("GameCore: Will rely on fallback crop creation only")

		-- Disable CropVisualManager usage
		_G.DISABLE_CROPVISUALMANAGER = true
	end
end

-- ========== TEST CROPVISUALMANAGER INTEGRATION ==========

function GameCore:TestCropVisualManagerIntegration()
	print("GameCore: Testing CropVisualManager integration...")

	local testSuccess, testError = pcall(function()
		-- Test if we can call the main methods without errors
		if _G.CropVisualManager.CreateCropModel then
			print("GameCore: ✅ CreateCropModel method accessible")
		end

		if _G.CropVisualManager.HandleCropPlanted then
			print("GameCore: ✅ HandleCropPlanted method accessible")
		end

		return true
	end)

	if testSuccess then
		print("GameCore: ✅ CropVisualManager integration test passed")
	else
		warn("GameCore: ❌ CropVisualManager integration test failed: " .. tostring(testError))
		warn("GameCore: Disabling CropVisualManager usage")
		_G.DISABLE_CROPVISUALMANAGER = true
	end
end

-- ========== CROPVISUALMANAGER STATUS CHECK ==========

function GameCore:GetCropVisualManagerStatus()
	local status = {
		available = _G.CropVisualManager ~= nil,
		disabled = _G.DISABLE_CROPVISUALMANAGER == true,
		methods = {}
	}

	if status.available then
		local methods = {"CreateCropModel", "HandleCropPlanted", "PositionCropModel"}
		for _, method in ipairs(methods) do
			status.methods[method] = _G.CropVisualManager[method] ~= nil
		end
	end

	return status
end

function GameCore:InitializeCropEventSystem()
	print("GameCore: Initializing crop event system for CropVisualManager integration...")

	-- Create events that CropVisualManager can listen to
	if not self.Events then
		self.Events = {}
	end

	-- Create bindable events for crop system communication
	self.Events.CropPlanted = Instance.new("BindableEvent")
	self.Events.CropGrowthStageChanged = Instance.new("BindableEvent")
	self.Events.CropHarvested = Instance.new("BindableEvent")

	print("GameCore: Crop event system initialized")
end

print("GameCore: ✅ CROPVISUALMANAGER INTEGRATION COMPLETE!")
print("🌱 NEW CROP SYSTEM FEATURES:")
print("  🎨 Integrated with CropVisualManager for enhanced visuals")
print("  🏗️ Uses pre-made models from ReplicatedStorage.CropModels")
print("  🔄 Automatic fallback to procedural generation")
print("  ✨ Enhanced growth stage transitions")
print("  🌾 Visual harvest effects using pre-made models")
print("  🎯 Better click detection on crop models")
print("")
print("🔧 TECHNICAL IMPROVEMENTS:")
print("  📡 Event system for crop state changes")
print("  🎭 Smart model switching between growth stages")
print("  🌈 Enhanced rarity visual effects")
print("  🔗 Seamless integration with existing farming system")
print("")
print("📁 REQUIRED SETUP:")
print("  1. Place crop models in ReplicatedStorage.CropModels")
print("  2. Models should be named: Carrot, Corn, Strawberry, etc.")
print("  3. CropVisualManager will automatically detect and use them")
print("  4. Falls back to procedural generation if models missing")


-- ========== CLEANUP ON PLAYER LEAVE ==========
-- Enhanced save system properties
GameCore.SAVE_COOLDOWN = 30 -- Minimum 30 seconds between saves
GameCore.BATCH_SAVE_DELAY = 5 -- Wait 5 seconds before actually saving (allows batching)
GameCore.DataStoreCooldowns = {}
GameCore.PendingSaves = {}
GameCore.DirtyPlayers = {} -- Track which players need saving

-- IMPROVED: Save player data with proper batching and cooldowns
function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local currentTime = os.time()

	-- Check if player data exists
	local playerData = self.PlayerData[userId]
	if not playerData then 
		warn("GameCore: No player data to save for " .. player.Name)
		return 
	end

	-- Handle immediate saves (for critical situations like player leaving)
	if forceImmediate then
		return self:PerformImmediateSave(player, playerData)
	end

	-- Check cooldown (prevents spam saving)
	local lastSave = self.DataStoreCooldowns[userId] or 0
	if currentTime - lastSave < self.SAVE_COOLDOWN then
		-- Mark player as dirty for later saving
		self:MarkPlayerForDelayedSave(userId)
		return
	end

	-- Use batched save system
	self:ScheduleBatchedSave(userId)
end

-- NEW: Mark player for delayed saving
function GameCore:MarkPlayerForDelayedSave(userId)
	self.DirtyPlayers[userId] = os.time()

	-- Schedule a delayed save if not already scheduled
	if not self.PendingSaves[userId] then
		self.PendingSaves[userId] = true

		spawn(function()
			wait(self.BATCH_SAVE_DELAY)

			-- Check if player still needs saving
			if self.DirtyPlayers[userId] and Players:GetPlayerByUserId(userId) then
				self:PerformBatchedSave(userId)
			end

			self.PendingSaves[userId] = nil
		end)
	end
end

-- NEW: Schedule batched save
function GameCore:ScheduleBatchedSave(userId)
	self.DirtyPlayers[userId] = os.time()

	if not self.PendingSaves[userId] then
		self.PendingSaves[userId] = true

		spawn(function()
			wait(self.BATCH_SAVE_DELAY)
			self:PerformBatchedSave(userId)
			self.PendingSaves[userId] = nil
		end)
	end
end

-- NEW: Perform batched save with error handling
function GameCore:PerformBatchedSave(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player or not player.Parent then 
		self.DirtyPlayers[userId] = nil
		return 
	end

	local currentTime = os.time()
	local lastSave = self.DataStoreCooldowns[userId] or 0

	-- Double-check cooldown
	if currentTime - lastSave < self.SAVE_COOLDOWN then
		print("GameCore: Skipping save for " .. player.Name .. " - still in cooldown")
		return
	end

	local playerData = self.PlayerData[userId]
	if not playerData then 
		self.DirtyPlayers[userId] = nil
		return 
	end

	-- Perform the actual save
	local success = self:PerformActualSave(player, playerData, "batched")

	if success then
		self.DataStoreCooldowns[userId] = currentTime
		self.DirtyPlayers[userId] = nil
		print("GameCore: Batched save successful for " .. player.Name)
	else
		-- Keep player marked as dirty for retry
		print("GameCore: Batched save failed for " .. player.Name .. " - will retry later")
	end
end

-- NEW: Perform immediate save (for critical situations)
function GameCore:PerformImmediateSave(player, playerData)
	print("GameCore: Performing immediate save for " .. player.Name)

	local success = self:PerformActualSave(player, playerData, "immediate")

	if success then
		local userId = player.UserId
		self.DataStoreCooldowns[userId] = os.time()
		self.DirtyPlayers[userId] = nil
		print("GameCore: Immediate save successful for " .. player.Name)
	else
		warn("GameCore: Immediate save failed for " .. player.Name)
	end

	return success
end

-- IMPROVED: Actual save operation with better error handling
function GameCore:PerformActualSave(player, playerData, saveType)
	local userId = player.UserId

	if not self.PlayerDataStore then
		warn("GameCore: DataStore not available - cannot save data for " .. player.Name)
		return false
	end

	-- Create safe data structure (your existing sanitization code)
	local safeData = self:CreateSafeDataForSaving(playerData)

	-- Add save metadata
	safeData.lastSave = os.time()
	safeData.saveType = saveType or "unknown"
	safeData.saveVersion = "1.0"

	-- Perform the save with retry logic
	local maxRetries = 2
	local retryDelay = 1

	for attempt = 1, maxRetries do
		local success, errorMsg = pcall(function()
			return self.PlayerDataStore:SetAsync("Player_" .. userId, safeData)
		end)

		if success then
			return true
		else
			warn("GameCore: Save attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(errorMsg))

			if attempt < maxRetries then
				wait(retryDelay)
				retryDelay = retryDelay * 2 -- Exponential backoff
			end
		end
	end

	return false
end

-- NEW: Create safe data structure for saving
function GameCore:CreateSafeDataForSaving(playerData)
	-- Use your existing sanitization method or create a simplified version
	if self.SanitizeDataForSaving then
		return self:SanitizeDataForSaving(playerData)
	end

	-- Simplified safe data structure
	return {
		coins = tonumber(playerData.coins) or 0,
		farmTokens = tonumber(playerData.farmTokens) or 0,
		farming = {
			plots = tonumber(playerData.farming and playerData.farming.plots) or 0,
			inventory = self:SanitizeInventory(playerData.farming and playerData.farming.inventory or {})
		},
		stats = self:SanitizeStats(playerData.stats or {}),
		purchaseHistory = self:SanitizePurchaseHistory(playerData.purchaseHistory or {}),
		lastSave = os.time()
	}
end

-- Helper methods for data sanitization
function GameCore:SanitizeInventory(inventory)
	local clean = {}
	for item, amount in pairs(inventory) do
		if type(item) == "string" and type(amount) == "number" and amount >= 0 then
			clean[item] = math.floor(amount)
		end
	end
	return clean
end

function GameCore:SanitizeStats(stats)
	local clean = {}
	for stat, value in pairs(stats) do
		if type(stat) == "string" and type(value) == "number" and value >= 0 then
			clean[stat] = math.floor(value)
		end
	end
	return clean
end

function GameCore:SanitizePurchaseHistory(history)
	local clean = {}
	for item, purchased in pairs(history) do
		if type(item) == "string" and type(purchased) == "boolean" then
			clean[item] = purchased
		end
	end
	return clean
end

-- ADD this to your existing player removal handler:
Players.PlayerRemoving:Connect(function(player)
	-- Force immediate save when player leaves
	if GameCore.PlayerData[player.UserId] then
		print("GameCore: Player " .. player.Name .. " leaving - forcing immediate save")
		GameCore:SavePlayerData(player, true) -- Force immediate save
	end

	-- Clean up tracking data
	local userId = player.UserId
	GameCore.DirtyPlayers[userId] = nil
	GameCore.PendingSaves[userId] = nil
end)

print("GameCore: ✅ OPTIMIZED DATASTORE SYSTEM LOADED!")
print("🔧 OPTIMIZATIONS:")
print("  ⏱️ Batched saves with delays to prevent queue overflow")
print("  🔄 Proper cooldown system (30 seconds minimum)")
print("  📊 Dirty player tracking to avoid unnecessary saves")
print("  🚨 Immediate saves only for critical situations (player leaving)")
print("  🔁 Retry logic with exponential backoff")
print("  🧹 Automatic cleanup of old data")


-- ========== EXPANDABLE FARM PLOT SYSTEM ==========

function GameCore:GetSimpleFarmPosition(player)
	if not self.SimpleFarmConfig then
		warn("GameCore: SimpleFarmConfig not initialized!")
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

-- Create simple farm plot for player (always 10x10)
function GameCore:CreateSimpleFarmPlot(player)
	print("GameCore: Creating simple 10x10 farm plot for " .. player.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then
		warn("GameCore: No player data for " .. player.Name)
		return false
	end

	-- Initialize farming data if needed
	if not playerData.farming then
		playerData.farming = {
			inventory = {}
		}
	end

	local plotCFrame = self:GetSimpleFarmPosition(player)

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

	-- Create/update player-specific simple farm
	local playerFarmName = player.Name .. "_SimpleFarm"
	local playerFarm = farmArea:FindFirstChild(playerFarmName)

	if playerFarm then
		-- Farm already exists, just ensure it's correct
		print("GameCore: Farm already exists for " .. player.Name)
		return true
	else
		-- Create new simple farm
		return self:CreateNewSimpleFarmPlot(player, farmArea, playerFarmName, plotCFrame)
	end
end

-- Create new simple farm plot (always 10x10, all unlocked)
function GameCore:CreateNewSimpleFarmPlot(player, farmArea, farmName, plotCFrame)
	print("GameCore: Creating new simple farm for " .. player.Name)

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

	print("GameCore: Created simple farm for " .. player.Name .. " with " .. config.totalSpots .. " unlocked spots")
	return true
end

-- Create simple planting grid (10x10, all unlocked)
function GameCore:CreateSimplePlantingGrid(player, farmModel, plantingSpots, plotCFrame)
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

			local spotModel = Instance.new("Model")
			spotModel.Name = spotName
			spotModel.Parent = plantingSpots

			-- Position calculation (centered grid)
			local offsetX = (col - 1) * spacing - gridOffset
			local offsetZ = (row - 1) * spacing - gridOffset

			local spotPart = Instance.new("Part")
			spotPart.Name = "SpotPart"
			spotPart.Size = Vector3.new(spotSize, 0.2, spotSize)
			spotPart.Material = Enum.Material.LeafyGrass
			spotPart.Anchored = true
			spotPart.CFrame = plotCFrame + Vector3.new(offsetX, 1, offsetZ)
			spotPart.Parent = spotModel

			spotModel.PrimaryPart = spotPart

			-- Set spot attributes (all spots are unlocked and empty)
			spotModel:SetAttribute("IsEmpty", true)
			spotModel:SetAttribute("PlantType", "")
			spotModel:SetAttribute("SeedType", "")
			spotModel:SetAttribute("GrowthStage", 0)
			spotModel:SetAttribute("PlantedTime", 0)
			spotModel:SetAttribute("Rarity", "common")
			spotModel:SetAttribute("IsUnlocked", true)  -- All spots always unlocked
			spotModel:SetAttribute("GridRow", row)
			spotModel:SetAttribute("GridCol", col)

			-- All spots get unlocked styling
			spotPart.Color = config.spotColor
			spotPart.Transparency = config.spotTransparency

			-- Create interaction indicator for all spots
			local indicator = Instance.new("Part")
			indicator.Name = "Indicator"
			indicator.Size = Vector3.new(0.5, 2, 0.5)
			indicator.Material = Enum.Material.Neon
			indicator.Color = Color3.fromRGB(100, 255, 100)
			indicator.Anchored = true
			indicator.CFrame = spotPart.CFrame + Vector3.new(0, 1.5, 0)
			indicator.Parent = spotModel

			-- Add click detector for all spots
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 10
			clickDetector.Parent = spotPart

			clickDetector.MouseClick:Connect(function(clickingPlayer)
				if clickingPlayer.UserId == player.UserId then
					self:HandleSimplePlotClick(clickingPlayer, spotModel)
				end
			end)
		end
	end

	print("GameCore: Created " .. spotIndex .. " unlocked planting spots in 10x10 grid")
end

-- Create simple border
function GameCore:CreateSimpleBorder(farmModel, plotCFrame, config)
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

-- Create simple info sign
function GameCore:CreateSimpleInfoSign(farmModel, plotCFrame, player)
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

-- Get player's simple farm model
function GameCore:GetPlayerSimpleFarm(player)
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return nil end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return nil end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return nil end

	return farmArea:FindFirstChild(player.Name .. "_SimpleFarm")
end

-- Get simple plot owner
function GameCore:GetSimplePlotOwner(spotModel)
	local parent = spotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_SimpleFarm") then
			return parent.Name:gsub("_SimpleFarm", "")
		end

		parent = parent.Parent
	end

	warn("GameCore: Could not determine simple plot owner for " .. spotModel.Name)
	return nil
end


function GameCore:CreatePlayerFarmPlot(player, totalPlots)
	print("🌾 GameCore: Creating simple farm plot for " .. player.Name)
	return self:CreateSimpleFarmPlot(player)
end

-- ========== SIMPLIFIED FARM PLOT PURCHASE ==========

function GameCore:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	print("🌾 GameCore: Simplified ProcessFarmPlotPurchase for " .. player.Name)

	-- Handle farm plot starter (first-time farm creation)
	if item.id == "farm_plot_starter" then
		print("🌾 Processing farm plot starter")

		-- Initialize farming data
		if not playerData.farming then
			playerData.farming = {
				plots = 1,
				inventory = {
					-- Give starter seeds
					carrot_seeds = 5,
					corn_seeds = 3
				}
			}
		else
			playerData.farming.plots = (playerData.farming.plots or 0) + quantity
		end

		-- Create the physical simple farm plot
		local success = self:CreateSimpleFarmPlot(player)
		if not success then
			-- Revert changes on failure
			if playerData.farming.plots then
				playerData.farming.plots = playerData.farming.plots - quantity
			end
			return false
		end

		print("🌾 Created simple farm plot for " .. player.Name)
		return true
	end

	-- Regular farm plot purchase (legacy support)
	if not playerData.farming then
		playerData.farming = {plots = 0, inventory = {}}
	end

	playerData.farming.plots = (playerData.farming.plots or 0) + quantity

	-- Create the physical farm plot using simple system
	local success = self:CreateSimpleFarmPlot(player)
	if not success then
		playerData.farming.plots = playerData.farming.plots - quantity
		return false
	end

	print("🌾 Added " .. quantity .. " farm plot(s), total: " .. playerData.farming.plots)
	return true
end

-- ========== ENSURE PLAYER HAS SIMPLE FARM ==========

function GameCore:EnsurePlayerHasSimpleFarm(player)
	print("🌾 GameCore: Ensuring " .. player.Name .. " has simple farm")

	local playerData = self:GetPlayerData(player)
	if not playerData then
		return false
	end

	-- Check if player should have a farm
	local hasFarmItem = playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter
	local hasFarmingData = playerData.farming and playerData.farming.plots and playerData.farming.plots > 0

	if not hasFarmItem and not hasFarmingData then
		print("🌾 Player " .. player.Name .. " doesn't have farm access")
		return false
	end

	-- Ensure farming data is initialized
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			inventory = {}
		}
		self:SavePlayerData(player)
	end

	-- Check if physical farm exists
	local existingFarm = self:GetPlayerSimpleFarm(player)
	if not existingFarm then
		print("🌾 Creating missing simple farm for " .. player.Name)
		return self:CreateSimpleFarmPlot(player)
	end

	print("🌾 Player " .. player.Name .. " already has simple farm")
	return true
end

print("GameCore: ✅ SIMPLIFIED FARM SYSTEM LOADED!")
print("🌾 SIMPLE FARM FEATURES:")
print("  📏 Always 10x10 grid (100 planting spots)")
print("  🔓 All spots unlocked immediately")
print("  🚫 No expansion system or purchases needed")
print("  🎨 Clean, simple farm layout")
print("  ✨ No locked spots or expansion requirements")
print("  📊 Simplified farm management")
print("")
print("🔧 COMPATIBILITY:")
print("  ✅ Works with existing farming system")
print("  ✅ Works with existing crop growing")
print("  ✅ Works with existing seed planting")
print("  ✅ Works with existing harvest system")
print("  ✅ Replaces expandable farm methods")
-- ========== ENHANCED FARMING SYSTEM WITH RARITY ==========

function GameCore:InitializeFarmingSystem()
	print("GameCore: Initializing ENHANCED farming system with rarity...")
	self.Systems.Farming.RarityEffects = {}
	print("GameCore: Enhanced farming system initialized")
end
function GameCore:CreateCropOnPlotWithDebug(plotModel, seedId, seedData, cropRarity)
	print("🎨 GameCore: ENHANCED CreateCropOnPlotWithDebug starting...")
	print("🌱 Plot: " .. plotModel.Name .. " | Seed: " .. seedId .. " | Rarity: " .. cropRarity)

	local success, result = pcall(function()
		local spotPart = plotModel:FindFirstChild("SpotPart")
		if not spotPart then
			warn("❌ CROP CREATION FAIL: No SpotPart found in plot model")
			return false
		end
		print("✅ SpotPart found")

		-- Remove any existing crop (safety cleanup)
		local existingCrop = plotModel:FindFirstChild("CropModel")
		if existingCrop then
			print("🧹 Removing existing crop model")
			existingCrop:Destroy()
			wait(0.1) -- Give time for cleanup
		end

		local cropType = seedData.resultCropId
		local growthStage = "planted"

		-- METHOD 1: Try CropVisualManager module (IMPROVED)
		if self:IsCropVisualManagerAvailable() then
			print("🎨 Attempting CropVisualManager creation...")

			local vmSuccess, cropModel = pcall(function()
				return CropVisualManager:HandleCropPlanted(plotModel, cropType, cropRarity)
			end)

			if vmSuccess and cropModel then
				print("✅ CropVisualManager creation successful")

				-- Ensure click detection is setup (CropVisualManager should handle this, but double-check)
				local cropModelInPlot = plotModel:FindFirstChild("CropModel")
				if cropModelInPlot then
					local hasClickDetector = false
					for _, obj in pairs(cropModelInPlot:GetDescendants()) do
						if obj:IsA("ClickDetector") and obj.Name == "CropClickDetector" then
							hasClickDetector = true
							break
						end
					end

					if not hasClickDetector then
						print("🖱️ Adding missing click detection to CropVisualManager crop")
						self:SetupCropClickDetection(cropModelInPlot, plotModel)
					else
						print("✅ Click detection already present")
					end
				end

				return true
			else
				warn("⚠️ CropVisualManager creation failed: " .. tostring(cropModel))
			end
		else
			print("ℹ️ CropVisualManager not available, using fallback")
		end

		-- METHOD 2: Enhanced fallback crop creation
		print("🔧 Using enhanced fallback crop creation...")
		local fallbackCrop = self:CreateEnhancedFallbackCrop(plotModel, seedId, seedData, cropRarity)

		if not fallbackCrop then
			warn("❌ Enhanced fallback creation failed")
			-- Try basic fallback as last resort
			return self:CreateBasicFallbackCrop(plotModel, seedId, seedData, cropRarity)
		end

		print("✅ Crop creation completed successfully")
		return true
	end)

	if success then
		print("✅ CreateCropOnPlotWithDebug: SUCCESS")
		return result
	else
		warn("❌ CreateCropOnPlotWithDebug: FAILED - " .. tostring(result))
		-- Try basic fallback
		return self:CreateBasicFallbackCrop(plotModel, seedId, seedData, cropRarity)
	end
end
-- ADD this method to your GameCore.lua (it's referenced but missing)

function GameCore:GetAdjacentPlots(player, centerPlot)
	print("🧬 Getting adjacent plots for " .. centerPlot.Name)

	local adjacentPlots = {}

	-- Get plot grid position
	local plotRow = centerPlot:GetAttribute("GridRow")
	local plotCol = centerPlot:GetAttribute("GridCol")

	if not plotRow or not plotCol then
		warn("GameCore: Plot missing grid coordinates for " .. centerPlot.Name)
		return {}
	end

	print("🧬 Center plot at grid position: (" .. plotRow .. ", " .. plotCol .. ")")

	-- Find player's farm
	local farm = self:GetPlayerSimpleFarm(player)
	if not farm then 
		warn("GameCore: No farm found for " .. player.Name)
		return {} 
	end

	local plantingSpots = farm:FindFirstChild("PlantingSpots")
	if not plantingSpots then 
		warn("GameCore: No PlantingSpots folder found")
		return {} 
	end

	-- Check adjacent positions (up, down, left, right)
	local adjacentPositions = {
		{plotRow - 1, plotCol},     -- Up
		{plotRow + 1, plotCol},     -- Down
		{plotRow, plotCol - 1},     -- Left
		{plotRow, plotCol + 1}      -- Right
	}

	print("🧬 Checking " .. #adjacentPositions .. " adjacent positions...")

	for i, pos in ipairs(adjacentPositions) do
		local targetRow, targetCol = pos[1], pos[2]
		print("🧬 Looking for plot at (" .. targetRow .. ", " .. targetCol .. ")")

		-- Find plot at this position
		for _, spot in pairs(plantingSpots:GetChildren()) do
			if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
				local spotRow = spot:GetAttribute("GridRow")
				local spotCol = spot:GetAttribute("GridCol")

				if spotRow == targetRow and spotCol == targetCol then
					table.insert(adjacentPlots, spot)

					local plantType = spot:GetAttribute("PlantType") or "empty"
					local growthStage = spot:GetAttribute("GrowthStage") or 0
					print("🧬 Found adjacent plot: " .. spot.Name .. " with " .. plantType .. " (stage " .. growthStage .. ")")
					break
				end
			end
		end
	end

	print("🧬 Found " .. #adjacentPlots .. " adjacent plots to " .. centerPlot.Name)
	return adjacentPlots
end
-- UPDATED: Enhanced harvest method with module integration
function GameCore:HarvestCrop(player, plotModel)
	print("🌾 GameCore: ENHANCED harvest with mutation integration - " .. player.Name .. " for plot " .. plotModel.Name)

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

	-- Check if crop is ready
	local isActuallyEmpty = self:IsPlotActuallyEmpty(plotModel)
	if isActuallyEmpty then
		self:SendNotification(player, "Nothing to Harvest", "This plot doesn't have any crops to harvest!", "warning")
		return false
	end

	local growthStage = plotModel:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		local timeLeft = self:GetCropTimeRemaining(plotModel)
		self:SendNotification(player, "Not Ready", 
			"Crop is not ready for harvest yet! " .. math.ceil(timeLeft/60) .. " minutes remaining.", "warning")
		return false
	end
	
	local plantType = plotModel:GetAttribute("PlantType") or ""
	local seedType = plotModel:GetAttribute("SeedType") or ""
	local cropRarity = plotModel:GetAttribute("Rarity") or "common"
	-- 🧬 STEP: CHECK FOR MUTATIONS BEFORE HARVESTING (NEW!)
	print("🧬 Checking for mutations before harvest...")
	local mutationResult = self:ProcessPotentialMutations(player, plotModel)
	if mutationResult.mutated then
		print("🧬 MUTATION DETECTED: " .. mutationResult.mutationType)
		return self:HarvestMutatedCrop(player, plotModel, mutationResult)
	end
	print("🧬 No mutations detected, proceeding with normal harvest")
	-- 🧬 HANDLE MUTATION HARVEST (if this is a mature mutation)
	local isMutation = plotModel:GetAttribute("IsMutation")
	local mutationType = plotModel:GetAttribute("MutationType")

	if isMutation and mutationType and growthStage >= 4 then
		print("🧬 Harvesting mature mutation: " .. mutationType)
		return self:HarvestMatureMutation(player, plotModel, mutationType, cropRarity)
	end
	-- Notify CropVisualManager about harvest BEFORE clearing plot
	if self:IsCropVisualManagerAvailable() then
		CropVisualManager:OnCropHarvested(plotModel, plantType, cropRarity)
	end

	-- Continue with normal harvest logic...
	local cropData = ItemConfig.GetCropData(plantType)
	local seedData = ItemConfig.GetSeedData(seedType)

	if not cropData or not seedData then
		self:SendNotification(player, "Invalid Crop", "Crop data not found for " .. plantType, "error")
		return false
	end

	-- Calculate yield with rarity bonus
	local baseYield = seedData.yieldAmount or 1
	local rarityMultiplier = ItemConfig.RaritySystem[cropRarity] and ItemConfig.RaritySystem[cropRarity].valueMultiplier or 1.0
	local finalYield = math.floor(baseYield * rarityMultiplier)

	-- Add crops to inventory
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	local currentAmount = playerData.farming.inventory[plantType] or 0
	playerData.farming.inventory[plantType] = currentAmount + finalYield

	-- Clear plot AFTER visual effects have time to play
	spawn(function()
		wait(1.5) -- Give time for harvest effects
		self:ClearPlotProperly(plotModel)
	end)

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + finalYield
	if cropRarity ~= "common" then
		playerData.stats.rareCropsHarvested = (playerData.stats.rareCropsHarvested or 0) + 1
	end

	-- Use optimized save
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	local rarityName = ItemConfig.RaritySystem[cropRarity] and ItemConfig.RaritySystem[cropRarity].name or cropRarity
	local rarityEmoji = cropRarity == "legendary" and "👑" or 
		cropRarity == "epic" and "💜" or 
		cropRarity == "rare" and "✨" or 
		cropRarity == "uncommon" and "💚" or "⚪"

	self:SendNotification(player, "🌾 Crop Harvested!", 
		"Harvested " .. finalYield .. "x " .. rarityEmoji .. " " .. rarityName .. " " .. cropData.name .. "!", "success")

	print("🌾 GameCore: Successfully harvested " .. finalYield .. "x " .. plantType .. " (" .. cropRarity .. ") for " .. player.Name)
	return true
end
-- IMPROVED: Enhanced fallback crop creation
-- UPDATE your CreateEnhancedFallbackCrop method to include click detection
function GameCore:CreateEnhancedFallbackCrop(plotModel, seedId, seedData, cropRarity)
	print("🔧 Creating enhanced fallback crop...")

	local spotPart = plotModel:FindFirstChild("SpotPart")
	if not spotPart then 
		warn("❌ No SpotPart for fallback crop")
		return nil 
	end

	local cropType = seedData.resultCropId

	-- Create enhanced crop model
	local cropModel = Instance.new("Model")
	cropModel.Name = "CropModel"
	cropModel.Parent = plotModel

	-- Create primary crop part with better appearance
	local cropPart = Instance.new("Part")
	cropPart.Name = "CropBody"
	cropPart.Size = Vector3.new(2, 2, 2)
	cropPart.Material = Enum.Material.Grass
	cropPart.Color = self:GetCropColorForType(cropType, cropRarity)
	cropPart.Anchored = true
	cropPart.CanCollide = false
	cropPart.Parent = cropModel

	-- Position on the plot
	cropPart.Position = spotPart.Position + Vector3.new(0, 2, 0)

	-- Add mesh for better shape
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.2, 1)
	mesh.Parent = cropPart

	-- Set primary part
	cropModel.PrimaryPart = cropPart

	-- Add attributes for identification
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", cropRarity)
	cropModel:SetAttribute("GrowthStage", "planted")
	cropModel:SetAttribute("ModelType", "EnhancedFallback")
	cropModel:SetAttribute("CreatedBy", "GameCore")

	-- Add visual effects based on rarity
	self:AddFallbackRarityEffects(cropModel, cropRarity)

	-- IMPORTANT: Add click detection for harvesting
	self:SetupCropClickDetection(cropModel, plotModel)

	print("✅ Enhanced fallback crop created successfully with click detection: " .. cropModel.Name)
	return cropModel
end
-- NEW: Basic fallback for when everything else fails
function GameCore:CreateBasicFallbackCrop(plotModel, seedId, seedData, cropRarity)
	print("🔧 Creating BASIC fallback crop as last resort...")

	local spotPart = plotModel:FindFirstChild("SpotPart")
	if not spotPart then return false end

	local cropType = seedData.resultCropId

	-- Create the simplest possible crop
	local cropModel = Instance.new("Model")
	cropModel.Name = "CropModel"
	cropModel.Parent = plotModel

	local cropPart = Instance.new("Part")
	cropPart.Name = "BasicCrop"
	cropPart.Size = Vector3.new(1, 1, 1)
	cropPart.Material = Enum.Material.Grass
	cropPart.Color = Color3.fromRGB(100, 200, 100)
	cropPart.Anchored = true
	cropPart.CanCollide = false
	cropPart.Position = spotPart.Position + Vector3.new(0, 1, 0)
	cropPart.Parent = cropModel

	cropModel.PrimaryPart = cropPart

	-- Add basic attributes
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", cropRarity)
	cropModel:SetAttribute("ModelType", "BasicFallback")

	-- IMPORTANT: Add click detection even for basic fallback
	self:SetupCropClickDetection(cropModel, plotModel)

	print("✅ Basic fallback crop created with click detection")
	return true
end

-- IMPROVED: Position crop on plot
function GameCore:PositionCropOnPlot(cropModel, plotModel)
	if not cropModel or not cropModel.PrimaryPart then return end

	local spotPart = plotModel:FindFirstChild("SpotPart")
	if not spotPart then return end

	-- Position the crop above the plot
	cropModel.PrimaryPart.CFrame = CFrame.new(spotPart.Position + Vector3.new(0, 2, 0))
	cropModel.PrimaryPart.Anchored = true
	cropModel.PrimaryPart.CanCollide = false

	print("✅ Positioned crop on plot")
end

-- ADD: Rarity effects for fallback crops
function GameCore:AddFallbackRarityEffects(cropModel, rarity)
	local cropPart = cropModel.PrimaryPart
	if not cropPart then return end

	-- Add glow effect based on rarity
	if rarity ~= "common" then
		local pointLight = Instance.new("PointLight")
		pointLight.Parent = cropPart

		if rarity == "uncommon" then
			pointLight.Color = Color3.fromRGB(0, 255, 0)
			pointLight.Brightness = 1
			pointLight.Range = 8
		elseif rarity == "rare" then
			pointLight.Color = Color3.fromRGB(255, 215, 0)
			pointLight.Brightness = 1.5
			pointLight.Range = 10
			cropPart.Material = Enum.Material.Neon
		elseif rarity == "epic" then
			pointLight.Color = Color3.fromRGB(128, 0, 128)
			pointLight.Brightness = 2
			pointLight.Range = 12
			cropPart.Material = Enum.Material.Neon
		elseif rarity == "legendary" then
			pointLight.Color = Color3.fromRGB(255, 100, 100)
			pointLight.Brightness = 3
			pointLight.Range = 15
			cropPart.Material = Enum.Material.Neon
		end
	end
end

-- ADD: Get crop colors for different types
function GameCore:GetCropColorForType(cropType, rarity)
	local baseColors = {
		carrot = Color3.fromRGB(255, 140, 0),
		corn = Color3.fromRGB(255, 215, 0),
		strawberry = Color3.fromRGB(220, 20, 60),
		wheat = Color3.fromRGB(218, 165, 32),
		potato = Color3.fromRGB(160, 82, 45),
		cabbage = Color3.fromRGB(124, 252, 0),
		radish = Color3.fromRGB(255, 69, 0),
		broccoli = Color3.fromRGB(34, 139, 34),
		tomato = Color3.fromRGB(255, 99, 71),
	}

	local baseColor = baseColors[cropType] or Color3.fromRGB(100, 200, 100)

	-- Modify color based on rarity
	if rarity == "legendary" then
		return baseColor:lerp(Color3.fromRGB(255, 100, 100), 0.3)
	elseif rarity == "epic" then
		return baseColor:lerp(Color3.fromRGB(128, 0, 128), 0.2)
	elseif rarity == "rare" then
		return baseColor:lerp(Color3.fromRGB(255, 215, 0), 0.15)
	elseif rarity == "uncommon" then
		return baseColor:lerp(Color3.fromRGB(0, 255, 0), 0.1)
	else
		return baseColor
	end
end

-- ADD: Setup click detection for crops
function GameCore:SetupCropClickDetection(cropModel, plotModel)
	if not cropModel or not cropModel.PrimaryPart or not plotModel then
		warn("GameCore: Invalid parameters for crop click detection")
		return false
	end

	local cropType = plotModel:GetAttribute("PlantType") or "unknown"
	local rarity = plotModel:GetAttribute("Rarity") or "common"

	print("🖱️ GameCore: Setting up crop click detection for " .. cropType)

	-- Remove existing click detectors
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj:IsA("ClickDetector") then
			obj:Destroy()
		end
	end

	-- Find clickable parts
	local clickableParts = {cropModel.PrimaryPart}

	-- Add additional large parts
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") and part ~= cropModel.PrimaryPart then
			local volume = part.Size.X * part.Size.Y * part.Size.Z
			if volume > 2 then -- Only add reasonably sized parts
				table.insert(clickableParts, part)
			end
		end
	end

	-- Add click detectors to all clickable parts
	for _, part in pairs(clickableParts) do
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.Name = "CropClickDetector"
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = part

		-- Store references
		clickDetector:SetAttribute("PlotModelName", plotModel.Name)
		clickDetector:SetAttribute("CropType", cropType)
		clickDetector:SetAttribute("Rarity", rarity)

		-- Connect click event
		clickDetector.MouseClick:Connect(function(clickingPlayer)
			self:HandleCropClick(clickingPlayer, cropModel, plotModel, cropType, rarity)
		end)

		print("🖱️ Added click detector to " .. part.Name)
	end

	print("✅ Crop click detection setup for " .. cropType .. " with " .. #clickableParts .. " parts")
	return true
end
function GameCore:HandleCropClick(clickingPlayer, cropModel, plotModel, cropType, rarity)
	print("🖱️ GameCore: Crop clicked by " .. clickingPlayer.Name .. " - " .. cropType)

	-- Verify plot ownership
	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= clickingPlayer.Name then
		self:SendNotification(clickingPlayer, "Not Your Crop", "You can only harvest your own crops!", "error")
		return
	end

	-- Check growth stage
	local growthStage = plotModel:GetAttribute("GrowthStage") or 0
	local isMutation = plotModel:GetAttribute("IsMutation") or false

	if growthStage >= 4 then
		print("🌾 Crop is ready for harvest")

		-- Call appropriate harvest method
		if isMutation then
			local mutationType = plotModel:GetAttribute("MutationType")
			self:HarvestMatureMutation(clickingPlayer, plotModel, mutationType, rarity)
		else
			self:HarvestCrop(clickingPlayer, plotModel)
		end
	else
		-- Show crop status
		self:ShowCropGrowthStatus(clickingPlayer, plotModel, cropType, growthStage, isMutation)
	end
end

function GameCore:ShowCropGrowthStatus(player, plotModel, cropType, growthStage, isMutation)
	local stageNames = {"planted", "sprouting", "growing", "flowering", "ready"}
	local currentStageName = stageNames[growthStage + 1] or "unknown"

	local plantedTime = plotModel:GetAttribute("PlantedTime") or os.time()
	local timeElapsed = os.time() - plantedTime

	-- Calculate remaining time
	local totalGrowthTime
	if isMutation then
		local speedMultiplier = _G.MUTATION_GROWTH_SPEED or 1.0
		totalGrowthTime = 240 / speedMultiplier -- 4 minutes for mutations
	else
		-- Try to get actual seed data for accurate timing
		local seedType = plotModel:GetAttribute("SeedType") or ""
		if ItemConfig and ItemConfig.GetSeedData then
			local seedData = ItemConfig.GetSeedData(seedType)
			totalGrowthTime = seedData and seedData.growTime or 300
		else
			totalGrowthTime = 300 -- Default 5 minutes
		end
	end

	local timeRemaining = math.max(0, totalGrowthTime - timeElapsed)
	local minutesRemaining = math.ceil(timeRemaining / 60)

	-- Create status message
	local cropDisplayName = cropType:gsub("^%l", string.upper):gsub("_", " ")
	local statusEmoji = isMutation and "🧬" or "🌱"
	local stageEmoji = {
		planted = "🌱",
		sprouting = "🌿", 
		growing = "🍃",
		flowering = "🌸",
		ready = "✨"
	}

	local message
	if growthStage >= 4 then
		message = statusEmoji .. " " .. cropDisplayName .. " is ready to harvest! " .. (stageEmoji.ready or "✨")
	else
		local progressBar = self:CreateProgressBar(timeElapsed, totalGrowthTime)
		message = statusEmoji .. " " .. cropDisplayName .. " is " .. currentStageName .. " " .. (stageEmoji[currentStageName] or "🌱") ..
			"\n⏰ " .. minutesRemaining .. " minutes remaining\n" .. progressBar
	end

	self:SendNotification(player, "🌾 Crop Status", message, "info")
end

function GameCore:CreateProgressBar(elapsed, total)
	local progress = math.min(elapsed / total, 1)
	local barLength = 10
	local filledLength = math.floor(progress * barLength)

	local bar = "["
	for i = 1, barLength do
		if i <= filledLength then
			bar = bar .. "█"
		else
			bar = bar .. "░"
		end
	end
	bar = bar .. "] " .. math.floor(progress * 100) .. "%"

	return bar
end

-- ADD: Get remaining growth time
function GameCore:GetCropTimeRemaining(plotModel)
	local plantedTime = plotModel:GetAttribute("PlantedTime") or 0
	local currentTime = os.time()
	local growTime = 300 -- Default 5 minutes, adjust based on your seed data

	local elapsed = currentTime - plantedTime
	local remaining = math.max(0, growTime - elapsed)

	return remaining
end
-- ========== SAFE FALLBACK METHODS ==========
function GameCore:AddEnhancedFallbackEffects(cropModel, rarity)
	local cropPart = cropModel.PrimaryPart
	if not cropPart then return end

	-- Add glow effect based on rarity
	if rarity ~= "common" then
		local pointLight = Instance.new("PointLight")
		pointLight.Parent = cropPart

		if rarity == "uncommon" then
			pointLight.Color = Color3.fromRGB(0, 255, 0)
			pointLight.Brightness = 1
			pointLight.Range = 8
		elseif rarity == "rare" then
			pointLight.Color = Color3.fromRGB(255, 215, 0)
			pointLight.Brightness = 1.5
			pointLight.Range = 10
			cropPart.Material = Enum.Material.Neon
		elseif rarity == "epic" then
			pointLight.Color = Color3.fromRGB(128, 0, 128)
			pointLight.Brightness = 2
			pointLight.Range = 12
			cropPart.Material = Enum.Material.Neon
		elseif rarity == "legendary" then
			pointLight.Color = Color3.fromRGB(255, 100, 100)
			pointLight.Brightness = 3
			pointLight.Range = 15
			cropPart.Material = Enum.Material.Neon
		end
	end

	-- Add particle effects for higher rarities
	if rarity == "rare" or rarity == "epic" or rarity == "legendary" then
		local attachment = Instance.new("Attachment")
		attachment.Parent = cropPart

		local particles = Instance.new("ParticleEmitter")
		particles.Parent = attachment
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Rate = 10
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Speed = NumberRange.new(1, 3)

		if rarity == "legendary" then
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
			particles.Rate = 20
		elseif rarity == "epic" then
			particles.Color = ColorSequence.new(Color3.fromRGB(128, 0, 128))
			particles.Rate = 15
		else
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		end
	end
end

function GameCore:AddBasicRarityEffectsFallback(cropPart, cropRarity)
	if cropRarity == "common" then return end

	-- Add glow for higher rarities
	local light = Instance.new("PointLight")
	light.Parent = cropPart

	if cropRarity == "uncommon" then
		light.Color = Color3.fromRGB(0, 255, 0)
		light.Brightness = 1
	elseif cropRarity == "rare" then
		light.Color = Color3.fromRGB(255, 215, 0)
		light.Brightness = 1.5
		cropPart.Material = Enum.Material.Neon
	elseif cropRarity == "epic" then
		light.Color = Color3.fromRGB(128, 0, 128)
		light.Brightness = 2
		cropPart.Material = Enum.Material.Neon
	elseif cropRarity == "legendary" then
		light.Color = Color3.fromRGB(255, 100, 100)
		light.Brightness = 3
		cropPart.Material = Enum.Material.Neon
	end

	light.Range = 10
end

function GameCore:GetRaritySizeFallback(rarity)
	if rarity == "legendary" then
		return 1.5
	elseif rarity == "epic" then
		return 1.3
	elseif rarity == "rare" then
		return 1.2
	elseif rarity == "uncommon" then
		return 1.1
	else
		return 1.0
	end
end

-- ADD this method to get crop colors for fallback
function GameCore:GetCropColor(cropType, rarity)
	local baseColors = {
		carrot = Color3.fromRGB(255, 140, 0),
		corn = Color3.fromRGB(255, 255, 0),
		strawberry = Color3.fromRGB(220, 20, 60),
		golden_fruit = Color3.fromRGB(255, 215, 0),
		wheat = Color3.fromRGB(218, 165, 32),
		potato = Color3.fromRGB(160, 82, 45),
		cabbage = Color3.fromRGB(34, 139, 34),
		radish = Color3.fromRGB(220, 20, 60),
		broccoli = Color3.fromRGB(34, 139, 34),
		tomato = Color3.fromRGB(255, 99, 71),
		glorious_sunflower = Color3.fromRGB(255, 215, 0)
	}

	local baseColor = baseColors[cropType] or Color3.fromRGB(100, 200, 100)

	-- Modify color based on rarity
	if rarity == "legendary" then
		return baseColor:lerp(Color3.fromRGB(255, 100, 100), 0.3)
	elseif rarity == "epic" then
		return baseColor:lerp(Color3.fromRGB(128, 0, 128), 0.2)
	elseif rarity == "rare" then
		return baseColor:lerp(Color3.fromRGB(255, 215, 0), 0.15)
	elseif rarity == "uncommon" then
		return baseColor:lerp(Color3.fromRGB(0, 255, 0), 0.1)
	else
		return baseColor
	end
end


function GameCore:PlantSeed(player, plotModel, seedId, seedData)
	-- DEBUG: Track what's calling this function
	local stackTrace = debug.traceback()
	print("🌱 PLANTING CALLED BY:")
	local lines = string.split(stackTrace, "\n")
	for i = 2, math.min(5, #lines) do -- Show first few lines of stack trace
		print("  " .. lines[i])
	end
	print("🌱 GameCore: PlantSeed - " .. player.Name .. " wants to plant " .. seedId)

	-- PROTECTION: Prevent double-clicking/rapid planting
	local userId = player.UserId
	local plotId = tostring(plotModel)

	if not self.PlantingCooldowns then
		self.PlantingCooldowns = {}
	end

	local currentTime = tick()
	local cooldownKey = userId .. "_" .. plotId
	local lastPlantTime = self.PlantingCooldowns[cooldownKey] or 0
	local timeSinceLastAttempt = currentTime - lastPlantTime

	if timeSinceLastAttempt < 0.5 then
		warn("🌱 PLANTING BLOCKED: Too soon after last attempt (" .. math.round(timeSinceLastAttempt * 1000) .. "ms ago)")
		return false
	end

	self.PlantingCooldowns[cooldownKey] = currentTime

	-- [Steps 1-12 remain the same as your original code...]

	-- Step 1: Validate inputs
	if not player then
		warn("❌ PLANTING FAIL: No player provided")
		return false
	end

	if not plotModel then
		warn("❌ PLANTING FAIL: No plotModel provided")
		self:SendNotification(player, "Planting Error", "Invalid plot!", "error")
		return false
	end

	if not seedId then
		warn("❌ PLANTING FAIL: No seedId provided")
		self:SendNotification(player, "Planting Error", "No seed specified!", "error")
		return false
	end

	print("✅ Step 1: Input validation passed")

	-- Step 2: Get player data
	local playerData = self:GetPlayerData(player)
	if not playerData then 
		warn("❌ PLANTING FAIL: No player data found for " .. player.Name)
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end
	print("✅ Step 2: Player data retrieved")

	-- Step 3: Check farming data
	if not playerData.farming or not playerData.farming.inventory then
		warn("❌ PLANTING FAIL: No farming data for " .. player.Name)
		self:SendNotification(player, "No Farming Data", "You need to set up farming first!", "error")
		return false
	end
	print("✅ Step 3: Farming data exists")

	-- Step 4: Check seed inventory
	local seedCount = playerData.farming.inventory[seedId] or 0
	print("🌱 DEBUG: Player has " .. seedCount .. " of " .. seedId)

	if seedCount <= 0 then
		local seedInfo = ItemConfig and ItemConfig.ShopItems and ItemConfig.ShopItems[seedId]
		local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
		warn("❌ PLANTING FAIL: No seeds - player has " .. seedCount .. " " .. seedId)
		self:SendNotification(player, "No Seeds", "You don't have any " .. seedName .. "!", "error")
		return false
	end
	print("✅ Step 4: Seed inventory check passed")

	-- Step 5: Validate plot
	if not plotModel or not plotModel.Parent then
		warn("❌ PLANTING FAIL: Plot model invalid or destroyed")
		self:SendNotification(player, "Invalid Plot", "Plot not found or invalid!", "error")
		return false
	end
	print("✅ Step 5: Plot model validation passed")

	-- Step 6: Check plot status
	local isEmpty = self:IsPlotActuallyEmpty(plotModel)
	local isUnlocked = plotModel:GetAttribute("IsUnlocked")

	print("🌱 DEBUG: Plot status - isEmpty: " .. tostring(isEmpty) .. ", isUnlocked: " .. tostring(isUnlocked))

	if isUnlocked ~= nil and not isUnlocked then
		warn("❌ PLANTING FAIL: Plot is locked")
		self:SendNotification(player, "Locked Plot", "This plot area is locked! Purchase farm expansion to unlock it.", "error")
		return false
	end

	if not isEmpty then
		warn("❌ PLANTING FAIL: Plot is not empty")
		self:SendNotification(player, "Plot Occupied", "This plot already has a crop growing!", "error")
		return false
	end

	print("✅ Step 6: Plot status check passed")

	-- Step 7: Check plot ownership
	local plotOwner = self:GetPlotOwner(plotModel)
	print("🌱 DEBUG: Plot owner: " .. tostring(plotOwner) .. ", Player: " .. player.Name)

	if plotOwner ~= player.Name then
		warn("❌ PLANTING FAIL: Plot ownership mismatch")
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return false
	end
	print("✅ Step 7: Plot ownership check passed")

	-- Step 8: Get seed data
	local finalSeedData = seedData
	if not finalSeedData then
		if ItemConfig and ItemConfig.GetSeedData then
			finalSeedData = ItemConfig.GetSeedData(seedId)
		end
	end

	if not finalSeedData then
		warn("❌ PLANTING FAIL: Seed data not found for " .. seedId)
		self:SendNotification(player, "Invalid Seed", "Seed data not found for " .. seedId .. "!", "error")
		return false
	end
	print("✅ Step 8: Seed data retrieved")

	-- Step 9: Get crop type and rarity
	local cropType = finalSeedData.resultCropId
	if not cropType then
		warn("❌ PLANTING FAIL: No resultCropId in seed data")
		self:SendNotification(player, "Invalid Seed", "Seed has no crop result!", "error")
		return false
	end

	local playerBoosters = self:GetPlayerBoosters(playerData)
	local cropRarity = "common"

	if ItemConfig and ItemConfig.GetCropRarity then
		cropRarity = ItemConfig.GetCropRarity(seedId, playerBoosters)
	end
	print("✅ Step 9: Crop type and rarity determined - " .. cropType .. " (" .. cropRarity .. ")")

	-- Step 10: Create crop on plot
	print("🌱 DEBUG: Starting crop creation...")
	local success = self:CreateCropOnPlotWithDebug(plotModel, seedId, finalSeedData, cropRarity)

	if not success then
		warn("❌ PLANTING FAIL: Crop creation failed")
		self:SendNotification(player, "Planting Failed", "Could not create crop on plot!", "error")
		return false
	end
	print("✅ Step 10: Crop creation successful")

	-- Step 11: Remove seed from inventory
	playerData.farming.inventory[seedId] = playerData.farming.inventory[seedId] - 1
	print("✅ Step 11: Seed removed from inventory")

	-- Step 12: Update plot attributes
	plotModel:SetAttribute("IsEmpty", false)
	plotModel:SetAttribute("PlantType", cropType)
	plotModel:SetAttribute("SeedType", seedId)
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", os.time())
	plotModel:SetAttribute("Rarity", cropRarity)
	print("✅ Step 12: Plot attributes updated")

	-- Step 13: Start growth timer
	self:StartCropGrowthTimer(plotModel, finalSeedData, cropType, cropRarity)
	print("✅ Step 13: Growth timer started")

	-- 🧬 STEP 13.5: CHECK FOR IMMEDIATE MUTATIONS (NEW!)
	print("🧬 Step 13.5: Checking for IMMEDIATE mutations...")
	local mutationOccurred = self:CheckForImmediateMutation(player, plotModel, cropType)
	if mutationOccurred then
		print("🎉 IMMEDIATE MUTATION OCCURRED! Planting process redirected to mutation.")
		-- Note: Don't return here - the mutation system handles everything
		self:SendNotification(player, "🧬 MUTATION!", "An incredible mutation just occurred!", "success")
	end
	print("✅ Step 13.5: Immediate mutation check complete")

	-- Step 14: Update stats and save
	playerData.stats = playerData.stats or {}
	playerData.stats.seedsPlanted = (playerData.stats.seedsPlanted or 0) + 1

	self:SavePlayerData(player)
	print("✅ Step 14: Stats updated and data saved")

	-- Step 15: Send client update
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		print("✅ Step 15: Client data update sent")
	end

	-- Step 16: Success notification
	local seedInfo = ItemConfig and ItemConfig.ShopItems and ItemConfig.ShopItems[seedId]
	local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")

	local notificationText = "Successfully planted " .. seedName .. "!\n🌟 Rarity: " .. cropRarity .. "\n⏰ Ready in " .. math.floor(finalSeedData.growTime/60) .. " minutes."

	self:SendNotification(player, "🌱 Seed Planted!", notificationText, "success")
	print("✅ Step 16: Success notification sent")

	print("🎉 PLANTING SUCCESS: " .. seedId .. " (" .. cropRarity .. ") planted for " .. player.Name)
	return true
end

function GameCore:GetPlayerBoosters(playerData)
	local boosters = {}

	if playerData.boosters then
		if playerData.boosters.rarity_booster and playerData.boosters.rarity_booster > 0 then
			boosters.rarity_booster = true
		end
	end

	return boosters
end

-- ADD this helper method for growth timer
function GameCore:StartCropGrowthTimer(plotModel, seedData, cropType, cropRarity)
	spawn(function()
		local growTime = seedData.growTime or 300 -- Default 5 minutes
		local stages = {"planted", "sprouting", "growing", "flowering", "ready"}
		local stageTime = growTime / (#stages - 1)

		print("🌱 Starting growth timer for " .. cropType .. " (" .. growTime .. "s total)")

		for stage = 1, #stages - 1 do
			wait(stageTime)

			if plotModel and plotModel.Parent then
				local currentStage = plotModel:GetAttribute("GrowthStage") or 0
				if currentStage == stage - 1 then -- Only advance if still in expected stage
					local newStageIndex = stage
					local newStageName = stages[stage + 1]

					plotModel:SetAttribute("GrowthStage", newStageIndex)

					print("🌱 " .. cropType .. " advanced to stage " .. newStageIndex .. " (" .. newStageName .. ")")

					-- ENHANCED: Update crop visual for new stage
					local success = self:UpdateCropVisualForNewStage(plotModel, cropType, cropRarity, newStageName, newStageIndex)
					if not success then
						warn("Failed to update crop visual for stage " .. newStageName)
					end

					-- Fire event for CropVisualManager
					if self.Events and self.Events.CropGrowthStageChanged then
						self.Events.CropGrowthStageChanged:Fire(plotModel, cropType, cropRarity, newStageName, newStageIndex)
					end
				else
					print("🌱 Growth timer stopped - stage mismatch (expected " .. (stage - 1) .. ", got " .. currentStage .. ")")
					break
				end
			else
				print("🌱 Growth timer stopped - plot no longer exists")
				break
			end
		end

		-- Mark as fully grown
		if plotModel and plotModel.Parent then
			plotModel:SetAttribute("GrowthStage", 4)
			self:UpdateCropVisualForNewStage(plotModel, cropType, cropRarity, "ready", 4)
			print("🌱 " .. cropType .. " fully grown and ready for harvest!")
		end
	end)
end
-- ADD this helper method for visual updates
function GameCore:UpdateCropVisualForNewStage(plotModel, cropType, rarity, stageName, stageIndex)
	print("🎨 Updating crop visual: " .. cropType .. " to stage " .. stageName)

	local cropModel = plotModel:FindFirstChild("CropModel")
	if not cropModel then
		warn("No CropModel found to update")
		return false
	end

	-- Method 1: Try CropVisualManager update if available
	if self:IsCropVisualManagerAvailable() then
		local success = pcall(function()
			return CropVisualManager:UpdateCropStage(cropModel, plotModel, cropType, rarity, stageName, stageIndex)
		end)

		if success then
			print("✅ CropVisualManager updated crop stage")
			-- Re-setup click detection after visual update
			self:SetupCropClickDetection(cropModel, plotModel)
			return true
		else
			print("⚠️ CropVisualManager update failed, using fallback")
		end
	end

	-- Method 2: Enhanced fallback visual update
	local success = self:UpdateCropVisualFallback(cropModel, cropType, rarity, stageName, stageIndex)

	-- Re-setup click detection after fallback update
	if success then
		self:SetupCropClickDetection(cropModel, plotModel)
	end

	return success
end

-- ========== DISABLE PLOT CLICKING ==========

function GameCore:HandleSimplePlotClick(player, spotModel)
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
	local plotOwner = self:GetSimplePlotOwner(spotModel)
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

	-- Send to client for seed selection (this should trigger PlantSeed)
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed:FireClient(player, spotModel)
	end
end

function GameCore:UpdateCropVisualFallback(cropModel, cropType, cropRarity, stageName, stageIndex)
	if not cropModel or not cropModel.PrimaryPart then
		warn("Invalid crop model for visual update")
		return false
	end

	print("🔧 Using fallback visual update for " .. stageName)

	-- Calculate new scale based on growth stage
	local rarityScale = self:GetRaritySizeMultiplier(cropRarity)
	local growthScale = self:GetGrowthStageScale(stageName)
	local finalScale = rarityScale * growthScale

	-- Smooth transition to new size
	local currentMesh = cropModel.PrimaryPart:FindFirstChild("SpecialMesh")
	if currentMesh then
		local targetScale = Vector3.new(finalScale, finalScale * 0.75, finalScale)

		-- Create smooth tween
		local tween = TweenService:Create(currentMesh,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Scale = targetScale}
		)
		tween:Play()

		print("🎯 Scaling crop to " .. tostring(targetScale))
	end

	-- Update lighting effects based on stage
	self:UpdateCropLighting(cropModel, cropRarity, stageName)

	-- Add stage-specific effects
	self:AddStageSpecificEffects(cropModel, stageName, cropType)

	return true
end

function GameCore:GetGrowthStageScale(stageName)
	local scales = {
		planted = 0.3,
		sprouting = 0.5,
		growing = 0.7,
		flowering = 0.9,
		ready = 1.0
	}
	return scales[stageName] or 0.5
end

function GameCore:UpdateCropLighting(cropModel, rarity, stageName)
	-- Remove old lighting
	for _, light in pairs(cropModel.PrimaryPart:GetChildren()) do
		if light:IsA("PointLight") then
			light:Destroy()
		end
	end

	-- Add new lighting based on stage and rarity
	if stageName == "ready" or (stageName == "flowering" and rarity ~= "common") then
		local light = Instance.new("PointLight")
		light.Parent = cropModel.PrimaryPart

		local brightness = stageName == "ready" and 1.0 or 0.5

		if rarity == "uncommon" then
			light.Color = Color3.fromRGB(0, 255, 0)
			light.Brightness = brightness
			light.Range = 8
		elseif rarity == "rare" then
			light.Color = Color3.fromRGB(255, 215, 0)
			light.Brightness = brightness * 1.5
			light.Range = 10
		elseif rarity == "epic" then
			light.Color = Color3.fromRGB(128, 0, 128)
			light.Brightness = brightness * 2
			light.Range = 12
		elseif rarity == "legendary" then
			light.Color = Color3.fromRGB(255, 100, 100)
			light.Brightness = brightness * 3
			light.Range = 15
		end
	end
end

function GameCore:AddStageSpecificEffects(cropModel, stageName, cropType)
	-- Add visual effects for specific stages
	if stageName == "flowering" then
		-- Add flowering particles
		self:CreateFloweringEffect(cropModel)
	elseif stageName == "ready" then
		-- Add ready-to-harvest glow
		self:CreateReadyHarvestEffect(cropModel)
	end
end

function GameCore:CreateFloweringEffect(cropModel)
	if not cropModel.PrimaryPart then return end

	-- Create small flowering particles
	spawn(function()
		for i = 1, 3 do
			local flower = Instance.new("Part")
			flower.Name = "FlowerParticle"
			flower.Size = Vector3.new(0.1, 0.1, 0.1)
			flower.Shape = Enum.PartType.Ball
			flower.Material = Enum.Material.Neon
			flower.Color = Color3.fromRGB(255, 192, 203) -- Pink
			flower.CanCollide = false
			flower.Anchored = true

			local position = cropModel.PrimaryPart.Position + Vector3.new(
				math.random(-1, 1),
				math.random(1, 3),
				math.random(-1, 1)
			)
			flower.Position = position
			flower.Parent = cropModel

			-- Fade out after 2 seconds
			local tween = TweenService:Create(flower,
				TweenInfo.new(2, Enum.EasingStyle.Quad),
				{Transparency = 1}
			)
			tween:Play()
			tween.Completed:Connect(function()
				flower:Destroy()
			end)

			wait(0.5)
		end
	end)
end

function GameCore:CreateReadyHarvestEffect(cropModel)
	if not cropModel.PrimaryPart then return end

	-- Add a subtle pulsing effect to indicate readiness
	local originalTransparency = cropModel.PrimaryPart.Transparency

	spawn(function()
		while cropModel and cropModel.Parent do
			-- Pulse effect
			local pulseIn = TweenService:Create(cropModel.PrimaryPart,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = originalTransparency + 0.2}
			)
			local pulseOut = TweenService:Create(cropModel.PrimaryPart,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = originalTransparency}
			)

			pulseIn:Play()
			pulseIn.Completed:Wait()
			pulseOut:Play()
			pulseOut.Completed:Wait()
		end
	end)
end

-- ADD this helper method for rarity size multipliers
function GameCore:GetRaritySizeMultiplier(rarity)
	if rarity == "legendary" then
		return 1.5
	elseif rarity == "epic" then
		return 1.3
	elseif rarity == "rare" then
		return 1.2
	elseif rarity == "uncommon" then
		return 1.1
	else
		return 1.0
	end
end

-- ADD this method for basic harvest effects
function GameCore:CreateBasicHarvestEffect(position, rarity)
	local particleCount = rarity == "legendary" and 10 or rarity == "epic" and 7 or rarity == "rare" and 5 or 3

	for i = 1, particleCount do
		local particle = Instance.new("Part")
		particle.Name = "HarvestParticle"
		particle.Size = Vector3.new(0.2, 0.2, 0.2)
		particle.Color = ItemConfig.GetRarityColor(rarity)
		particle.Material = Enum.Material.Neon
		particle.CanCollide = false
		particle.Anchored = true
		particle.Shape = Enum.PartType.Ball
		particle.Position = position + Vector3.new(
			(math.random() - 0.5) * 4,
			math.random() * 2,
			(math.random() - 0.5) * 4
		)
		particle.Parent = workspace

		local tween = TweenService:Create(particle,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = particle.Position + Vector3.new(0, 8, 0),
				Transparency = 1,
				Size = Vector3.new(0.05, 0.05, 0.05)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			particle:Destroy()
		end)
	end
end

function GameCore:FindPlotByName(player, plotName)
	-- Search for the plot (case-insensitive)
	local farm = self:GetPlayerSimpleFarm(player)
	if not farm then 
		warn("No farm found for player: " .. player.Name)
		return nil 
	end

	local plantingSpots = farm:FindFirstChild("PlantingSpots")
	if not plantingSpots then 
		warn("No PlantingSpots folder found")
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
			print("Found plot with case-insensitive match: " .. spot.Name)
			return spot
		end
	end

	-- Try pattern matching for PlantingSpot_X format
	local plotNumber = plotName:match("(%d+)")
	if plotNumber then
		local standardName = "PlantingSpot_" .. plotNumber
		local standardMatch = plantingSpots:FindFirstChild(standardName)
		if standardMatch then
			print("Found plot using standard format: " .. standardName)
			return standardMatch
		end
	end

	warn("Plot not found: " .. plotName)
	return nil
end
function GameCore:ForceCreateTestCrop(plotModel, cropType, growthStage)
	if not plotModel then return false end

	-- Clear plot first
	self:ClearPlotProperly(plotModel)

	-- Create crop visual
	if _G.CropVisualManager then
		local cropVisual = _G.CropVisualManager:CreateCropModel(cropType, "common", growthStage)
		cropVisual.Name = "CropModel"
		cropVisual.Parent = plotModel

		-- Position it properly
		_G.CropVisualManager:PositionCropModel(cropVisual, plotModel, growthStage)
	end

	-- Update plot attributes
	plotModel:SetAttribute("IsEmpty", false)
	plotModel:SetAttribute("PlantType", cropType)
	plotModel:SetAttribute("GrowthStage", growthStage == "ready" and 4 or 3)
	plotModel:SetAttribute("Rarity", "common")
	plotModel:SetAttribute("PlantedTime", os.time())

	return true
end


-- ========== UTILITY FUNCTIONS ==========

function GameCore:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

function GameCore:IsPlotActuallyEmpty(plotModel)
	print("🔍 GameCore: Checking if plot is actually empty: " .. plotModel.Name)

	if not plotModel or not plotModel.Parent then
		warn("🔍 Invalid plot model")
		return false
	end

	-- Method 1: Check for physical crop models (most reliable)
	local cropModels = {}
	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			table.insert(cropModels, child)
		end
	end

	if #cropModels > 0 then
		print("🔍 Found " .. #cropModels .. " CropModel(s) - plot is OCCUPIED")
		return false
	end

	-- Method 2: Check IsEmpty attribute
	local isEmptyAttr = plotModel:GetAttribute("IsEmpty")
	if isEmptyAttr == false then
		print("🔍 IsEmpty attribute = false - plot is OCCUPIED")
		return false
	end

	-- Method 3: Check if there's a plant type set
	local plantType = plotModel:GetAttribute("PlantType")
	if plantType and plantType ~= "" then
		print("🔍 PlantType = '" .. plantType .. "' - plot is OCCUPIED")
		return false
	end

	-- Method 4: Check growth stage
	local growthStage = plotModel:GetAttribute("GrowthStage")
	if growthStage and growthStage > 0 then
		print("🔍 GrowthStage = " .. growthStage .. " - plot is OCCUPIED")
		return false
	end

	-- If all checks pass, plot is empty
	print("🔍 All checks passed - plot is EMPTY")
	return true
end

function GameCore:ClearPlotProperly(plotModel)
	print("🧹 GameCore: FORCE clearing plot: " .. plotModel.Name)

	if not plotModel or not plotModel.Parent then
		warn("🧹 Invalid plot model provided")
		return false
	end

	local removedCount = 0

	-- Method 1: Remove ALL CropModel instances
	local childrenToRemove = {}
	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			table.insert(childrenToRemove, child)
		end
	end

	for _, child in pairs(childrenToRemove) do
		removedCount = removedCount + 1
		print("🧹 Removed CropModel: " .. child.Name .. " (instance " .. removedCount .. ")")
		child:Destroy()
	end

	-- Method 2: Clear ALL crop-related attributes
	plotModel:SetAttribute("IsEmpty", true)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("SeedType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", 0)
	plotModel:SetAttribute("Rarity", "common")

	-- Method 3: Restore visual indicator
	local indicator = plotModel:FindFirstChild("Indicator")
	if indicator then
		indicator.Color = Color3.fromRGB(100, 255, 100)
		indicator.Transparency = 0.2
	end

	print("🧹 Plot cleared: removed " .. removedCount .. " items, reset all attributes")

	-- Verify the plot is actually empty
	wait(0.1) -- Small delay for cleanup
	local verification = self:IsPlotActuallyEmpty(plotModel)
	if verification then
		print("✅ Plot successfully verified as empty")
	else
		warn("❌ Plot cleanup verification failed!")
		-- Force attributes again
		plotModel:SetAttribute("IsEmpty", true)
		plotModel:SetAttribute("PlantType", "")
		plotModel:SetAttribute("GrowthStage", 0)
	end

	return verification
end
-- NEW: Verification method
function GameCore:VerifyPlotIsClean(plotModel)
	if not plotModel then return false end

	-- Check for any remaining crop models
	for _, child in pairs(plotModel:GetChildren()) do
		if child:IsA("Model") and (
			child.Name == "CropModel" or 
				child.Name == "CropVisual" or
				child:GetAttribute("CropType")
			) then
			warn("🚨 Plot not clean - found: " .. child.Name)
			return false
		end
	end

	-- Check attributes
	local isEmpty = plotModel:GetAttribute("IsEmpty")
	if isEmpty ~= true then
		warn("🚨 Plot not clean - IsEmpty = " .. tostring(isEmpty))
		return false
	end

	return true
end

function GameCore:HarvestAllCrops(player)
	print("🌾 GameCore: Enhanced harvest all request from " .. player.Name)

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
	local rarityStats = {common = 0, uncommon = 0, rare = 0, epic = 0, legendary = 0}

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
								local cropRarity = spot:GetAttribute("Rarity") or "common"
								local success = self:HarvestCrop(player, spot)
								if success then
									harvestedCount = harvestedCount + 1
									rarityStats[cropRarity] = (rarityStats[cropRarity] or 0) + 1
								end
								wait(0.1)
							end
						end
					end
				end
			end
		end
	end

	-- Send enhanced summary notification
	if harvestedCount > 0 then
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

		self:SendNotification(player, "🌾 Mass Harvest Complete!", 
			"Harvested " .. harvestedCount .. " crops!\n\n" .. rarityBreakdown ..
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

	print("🌾 GameCore: Enhanced harvest all complete for " .. player.Name .. " - harvested " .. harvestedCount .. "/" .. readyCrops .. " ready crops")
	return harvestedCount > 0
end

function GameCore:SanitizeDataForSaving(data)
	if type(data) ~= "table" then
		return self:SanitizeValue(data)
	end

	local sanitized = {}

	for key, value in pairs(data) do
		-- Sanitize the key
		local cleanKey = self:SanitizeValue(key)
		if cleanKey ~= nil and type(cleanKey) == "string" or type(cleanKey) == "number" then
			-- Sanitize the value
			local cleanValue = self:SanitizeValue(value)
			if cleanValue ~= nil then
				sanitized[cleanKey] = cleanValue
			end
		end
	end

	return sanitized
end

function GameCore:SanitizeValue(value)
	local valueType = type(value)

	if valueType == "string" then
		-- Remove non-UTF-8 characters and control characters
		local cleaned = string.gsub(value, "[%z\1-\31\127-\255]", "")
		return cleaned

	elseif valueType == "number" then
		-- Check for NaN or infinity
		if value ~= value or value == math.huge or value == -math.huge then
			return 0
		end
		return value

	elseif valueType == "boolean" then
		return value

	elseif valueType == "table" then
		-- Recursively sanitize tables, but prevent infinite recursion
		return self:SanitizeDataForSaving(value)

	else
		-- Remove functions, userdata, Instance references, etc.
		return nil
	end
end

function GameCore:ValidatePlayerDataForSaving(playerData)
	local issues = {}

	-- Check for common problematic data
	local function checkTable(tbl, path)
		for key, value in pairs(tbl) do
			local currentPath = path .. "." .. tostring(key)
			local valueType = type(value)

			if valueType == "function" then
				table.insert(issues, currentPath .. " contains a function")
			elseif valueType == "userdata" then
				table.insert(issues, currentPath .. " contains userdata")
			elseif valueType == "table" then
				-- Check if it's a Roblox Instance
				if typeof(value) ~= "table" then
					table.insert(issues, currentPath .. " contains Instance: " .. typeof(value))
				else
					checkTable(value, currentPath)
				end
			elseif valueType == "string" then
				-- Check for non-UTF-8 characters
				if not utf8.len(value) then
					table.insert(issues, currentPath .. " contains non-UTF-8 string")
				end
			end
		end
	end

	if type(playerData) == "table" then
		checkTable(playerData, "playerData")
	end

	return issues
end

function GameCore:EstimateDataSize(data)
	local json = game:GetService("HttpService"):JSONEncode(data)
	return #json .. " characters"
end

function GameCore:LoadPlayerData(player)
	local defaultData = self:GetDefaultPlayerData()
	local loadedData = defaultData

	if self.PlayerDataStore then
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			-- Deep merge and convert loaded data
			loadedData = self:DeepMerge(defaultData, data)

			print("GameCore: Loaded existing data for " .. player.Name)
		else
			print("GameCore: Using default data for " .. player.Name)
		end
	end

	self.PlayerData[player.UserId] = loadedData

	self:UpdatePlayerLeaderstats(player)

	return loadedData
end

-- Debug method to check data before saving
function GameCore:DebugPlayerDataForSaving(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then
		print("No player data found for " .. player.Name)
		return
	end

	print("=== DATA SAVE DEBUG FOR " .. player.Name .. " ===")

	local issues = self:ValidatePlayerDataForSaving(playerData)
	if #issues > 0 then
		print("❌ Validation issues found:")
		for _, issue in ipairs(issues) do
			print("  " .. issue)
		end
	else
		print("✅ No validation issues found")
	end

	local sanitized = self:SanitizeDataForSaving(playerData)
	print("📦 Sanitized data size: " .. self:EstimateDataSize(sanitized))

	print("🗂️ Data structure:")
	for key, value in pairs(sanitized) do
		if type(value) == "table" then
			local count = 0
			for _ in pairs(value) do count = count + 1 end
			print("  " .. key .. ": table with " .. count .. " items")
		else
			print("  " .. key .. ": " .. type(value) .. " = " .. tostring(value))
		end
	end

	print("=======================================")
end

print("GameCore: ✅ DataStore serialization fixes loaded!")
print("🔧 Debug Command: /debugsavedata - Check data before saving")


function GameCore:AddPlantingDebugCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/testplanting" then
					print("🧪 Testing planting system for " .. player.Name)

					-- Give test seeds
					local playerData = self:GetPlayerData(player)
					if playerData then
						playerData.farming = playerData.farming or {inventory = {}}
						playerData.farming.inventory = playerData.farming.inventory or {}
						playerData.farming.inventory.carrot_seeds = 10
						playerData.farming.inventory.corn_seeds = 5
						self:SavePlayerData(player)

						print("✅ Gave test seeds to " .. player.Name)
						self:SendNotification(player, "Test Seeds", "Added test seeds! Try planting on your farm.", "success")
					end

				elseif command == "/disablecropvm" then
					_G.DISABLE_CROPVISUALMANAGER = true
					print("🔧 Disabled CropVisualManager - using fallback only")
					self:SendNotification(player, "Debug", "CropVisualManager disabled, using fallback crops.", "info")

				elseif command == "/enablecropvm" then
					_G.DISABLE_CROPVISUALMANAGER = false
					print("🔧 Enabled CropVisualManager")
					self:SendNotification(player, "Debug", "CropVisualManager enabled.", "info")

				elseif command == "/forceplant" then
					local seedType = args[2] or "carrot_seeds"
					local plotName = args[3] or "PlantingSpot_1"

					-- Find the plot
					local plot = self:FindPlotByName(player, plotName)
					if plot then
						print("🔧 Force planting " .. seedType .. " on " .. plotName)
						self:PlantSeed(player, plot, seedType)
					else
						print("❌ Could not find plot: " .. plotName)
					end
				elseif command == "/cleanupplanting" then
					-- Clear any stuck planting states
					self.PlantingCooldowns = {}

					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									-- Remove duplicate CropModels if any exist
									local cropModels = {}
									for _, child in pairs(spot:GetChildren()) do
										if child:IsA("Model") and child.Name == "CropModel" then
											table.insert(cropModels, child)
										end
									end

									-- Keep only the first crop model, remove duplicates
									for i = 2, #cropModels do
										print("🗑️ Removing duplicate CropModel from " .. spot.Name)
										cropModels[i]:Destroy()
									end
								end
							end
						end
					end

					print("✅ Cleanup complete")
				elseif command == "/debugplot" then
					local plotName = args[2] or "PlantingSpot_1"
					local plot = self:FindPlotByName(player, plotName)

					if plot then
						print("=== PLOT DEBUG: " .. plotName .. " ===")
						print("IsEmpty:", plot:GetAttribute("IsEmpty"))
						print("PlantType:", plot:GetAttribute("PlantType"))
						print("IsUnlocked:", plot:GetAttribute("IsUnlocked"))
						print("Children:")
						for _, child in pairs(plot:GetChildren()) do
							print("  -", child.Name, "(" .. child.ClassName .. ")")
						end
						print("SpotPart exists:", plot:FindFirstChild("SpotPart") ~= nil)
						print("===============================")
					else
						print("❌ Plot not found: " .. plotName)
					end
				end
			end
		end)
	end)
end
function GameCore:AddCropCreationDebugCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/debugcropissue" then
					print("=== CROP CREATION DEBUG ===")

					-- Check CropVisualManager availability
					print("CropVisualManager Status:")
					print("  _G.CropVisualManager exists: " .. tostring(_G.CropVisualManager ~= nil))
					print("  DISABLE_CROPVISUALMANAGER: " .. tostring(_G.DISABLE_CROPVISUALMANAGER))

					if _G.CropVisualManager then
						print("  CreateCropModel method: " .. tostring(_G.CropVisualManager.CreateCropModel ~= nil))
						print("  PositionCropModel method: " .. tostring(_G.CropVisualManager.PositionCropModel ~= nil))
					end

					-- Check ReplicatedStorage.CropModels
					local cropModels = game:GetService("ReplicatedStorage"):FindFirstChild("CropModels")
					print("  CropModels folder: " .. tostring(cropModels ~= nil))
					if cropModels then
						print("  Models available: " .. #cropModels:GetChildren())
						for _, model in pairs(cropModels:GetChildren()) do
							if model:IsA("Model") then
								print("    - " .. model.Name)
							end
						end
					end

					-- Check player's farm
					local farm = self:GetPlayerSimpleFarm(player)
					print("  Player farm exists: " .. tostring(farm ~= nil))
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						print("  PlantingSpots folder: " .. tostring(plantingSpots ~= nil))
						if plantingSpots then
							local spotCount = 0
							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									spotCount = spotCount + 1
								end
							end
							print("  Total planting spots: " .. spotCount)
						end
					end

					print("========================")

				elseif command == "/testcropcreation" then
					local plotName = args[2] or "PlantingSpot_1"
					local cropType = args[3] or "carrot"

					print("🧪 Testing crop creation on " .. plotName .. " with " .. cropType)

					-- Find the plot
					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local targetSpot = plantingSpots:FindFirstChild(plotName)
							if targetSpot then
								print("✅ Found target plot: " .. targetSpot.Name)

								-- Clear the plot first
								self:ClearPlotProperly(targetSpot)
								wait(0.5)

								-- Create test seed data
								local testSeedData = {
									resultCropId = cropType,
									growTime = 300
								}

								-- Test crop creation
								local success = self:CreateCropOnPlotWithDebug(targetSpot, cropType .. "_seeds", testSeedData, "common")

								if success then
									print("✅ Crop creation test SUCCESSFUL")

									-- Check if crop visual exists
									wait(1)
									local cropModel = targetSpot:FindFirstChild("CropModel")
									if cropModel then
										print("✅ CropModel found in plot: " .. cropModel.Name)
										print("  Model type: " .. tostring(cropModel:GetAttribute("ModelType")))
										print("  Crop type: " .. tostring(cropModel:GetAttribute("CropType")))
										print("  Position: " .. tostring(cropModel.PrimaryPart and cropModel.PrimaryPart.Position or "No PrimaryPart"))
									else
										print("❌ No CropModel found after creation!")
									end
								else
									print("❌ Crop creation test FAILED")
								end
							else
								print("❌ Could not find plot: " .. plotName)
							end
						else
							print("❌ No PlantingSpots folder found")
						end
					else
						print("❌ No farm found for player")
					end

				elseif command == "/forcecropvisual" then
					local plotName = args[2] or "PlantingSpot_1"
					local cropType = args[3] or "carrot"

					print("🔧 Force creating crop visual...")

					-- Find the plot
					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local targetSpot = plantingSpots:FindFirstChild(plotName)
							if targetSpot then
								-- Force create using fallback method
								local success = self:CreateEnhancedFallbackCrop(targetSpot, cropType .. "_seeds", {resultCropId = cropType}, "common")

								if success then
									print("✅ Force crop creation successful")
								else
									print("❌ Force crop creation failed")
								end
							end
						end
					end

				elseif command == "/clearcrop" then
					local plotName = args[2] or "PlantingSpot_1"

					-- Find and clear the plot
					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local targetSpot = plantingSpots:FindFirstChild(plotName)
							if targetSpot then
								print("🧹 Clearing plot: " .. targetSpot.Name)
								self:ClearPlotProperly(targetSpot)
								print("✅ Plot cleared")
							end
						end
					end
					
				elseif command == "/cropstatus" then
					-- Show status of all crops on player's farm
					print("=== CROP STATUS ===")

					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local totalSpots = 0
							local occupiedSpots = 0
							local emptySpots = 0

							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									totalSpots = totalSpots + 1

									local isEmpty = spot:GetAttribute("IsEmpty")
									local cropModel = spot:FindFirstChild("CropModel")

									if isEmpty == false or cropModel then
										occupiedSpots = occupiedSpots + 1

										local cropType = spot:GetAttribute("PlantType") or "unknown"
										local growthStage = spot:GetAttribute("GrowthStage") or 0
										local hasVisual = cropModel and "✅" or "❌"

										print("  " .. spot.Name .. ": " .. cropType .. " (stage " .. growthStage .. ") " .. hasVisual)
									else
										emptySpots = emptySpots + 1
									end
								end
							end

							print("Total spots: " .. totalSpots)
							print("Occupied: " .. occupiedSpots)
							print("Empty: " .. emptySpots)
						end
					end
					print("==================")
				end
			end
		end)
	end)
end
function GameCore:DebugAvailablePlots(player)
	local farm = self:GetPlayerSimpleFarm(player)
	if farm then
		local plantingSpots = farm:FindFirstChild("PlantingSpots")
		if plantingSpots then
			for i, spot in pairs(plantingSpots:GetChildren()) do
				if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
					print("  " .. i .. ": " .. spot.Name)
				end
			end
		end
	end
end
-- Add this admin command to your existing admin commands:
function GameCore:SetupAdminCommands()
	-- ... your existing admin commands ...
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]
				if command == "/forceemptyplot" then
					local plotName = args[2] or "PlantingSpot_1"

					local plot = self:FindPlotByName(player, plotName)
					if plot then
						print("🔧 Force emptying plot: " .. plotName)

						-- Destroy ALL children that might be crops
						for _, child in pairs(plot:GetChildren()) do
							if child:IsA("Model") or (child:IsA("Part") and child.Name:find("Crop")) then
								child:Destroy()
							end
						end

						-- Force reset all attributes
						plot:SetAttribute("IsEmpty", true)
						plot:SetAttribute("PlantType", "")
						plot:SetAttribute("SeedType", "")
						plot:SetAttribute("GrowthStage", 0)
						plot:SetAttribute("PlantedTime", 0)
						plot:SetAttribute("Rarity", "common")

						wait(0.5)

						-- Verify
						local isEmpty = self:IsPlotActuallyEmpty(plot)
						print("✅ Force empty result: " .. tostring(isEmpty))

						self:SendNotification(player, "Debug", "Force emptied " .. plotName .. " - Result: " .. tostring(isEmpty), "info")
					else
						print("❌ Plot not found: " .. plotName)
					end

				elseif command == "/clearallplots" then
					print("🧹 Force clearing ALL plots for " .. player.Name)

					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local clearedCount = 0

							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									self:ClearPlotProperly(spot)
									clearedCount = clearedCount + 1
								end
							end

							print("✅ Cleared " .. clearedCount .. " plots")
							self:SendNotification(player, "Debug", "Cleared " .. clearedCount .. " plots", "success")
						end
					end
				
				-- FARMING DEBUG COMMANDS
				elseif command == "/debugplanting" then
					print("=== PLANTING SYSTEM DEBUG ===")
					local playerData = self:GetPlayerData(player)

					if playerData then
						print("Player farming data:")
						if playerData.farming then
							print("  Plots: " .. (playerData.farming.plots or 0))
							print("  Expansion Level: " .. (playerData.farming.expansionLevel or 1))
							print("  Inventory items:")
							if playerData.farming.inventory then
								for item, count in pairs(playerData.farming.inventory) do
									if item:find("seeds") then
										print("    " .. item .. ": " .. count)
									end
								end
							else
								print("    No farming inventory")
							end
						else
							print("  No farming data")
						end

						print("Purchase history:")
						if playerData.purchaseHistory then
							if playerData.purchaseHistory.farm_plot_starter then
								print("  ✅ Has farm_plot_starter")
							else
								print("  ❌ Missing farm_plot_starter")
							end
						else
							print("  No purchase history")
						end
					end

					-- Check physical farm
					local farm = self:GetPlayerExpandableFarm(player)
					if farm then
						print("Physical farm: ✅ EXISTS")
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
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

							print("Planting spots: " .. unlockedSpots .. " unlocked / " .. totalSpots .. " total")
							print("Occupied spots: " .. occupiedSpots)
						else
							print("❌ No PlantingSpots folder found")
						end
					else
						print("Physical farm: ❌ MISSING")
					end
					print("==============================")

				elseif command == "/testplanting" then
					print("Testing planting system...")
					local playerData = self:GetPlayerData(player)

					-- Give test seeds
					if not playerData.farming then
						playerData.farming = {inventory = {}}
					end
					if not playerData.farming.inventory then
						playerData.farming.inventory = {}
					end

					playerData.farming.inventory.carrot_seeds = 10
					playerData.farming.inventory.corn_seeds = 5
					self:SavePlayerData(player)

					print("✅ Gave test seeds to " .. player.Name)
					print("Now click on an unlocked plot to test planting")

				elseif command == "/fixfarm" then
					print("Fixing farm for " .. player.Name)
					local playerData = self:GetPlayerData(player)

					-- Ensure farming data
					if not playerData.farming then
						playerData.farming = {
							plots = 1,
							expansionLevel = 1,
							inventory = {
								carrot_seeds = 5,
								corn_seeds = 3
							}
						}
					end

					-- Ensure purchase history
					if not playerData.purchaseHistory then
						playerData.purchaseHistory = {}
					end
					playerData.purchaseHistory.farm_plot_starter = true

					-- Create/update farm
					local success = self:CreateExpandableFarmPlot(player)
					if success then
						self:SavePlayerData(player)
						print("✅ Farm fixed for " .. player.Name)
					else
						print("❌ Failed to fix farm")
					end

				elseif command == "/testexpansion" then
					local targetLevel = tonumber(args[2]) or 2
					if targetLevel < 1 or targetLevel > 5 then
						print("Usage: /testexpansion [level 1-5]")
						return
					end

					print("Testing expansion to level " .. targetLevel)
					local playerData = self:GetPlayerData(player)

					-- Ensure farming data
					if not playerData.farming then
						playerData.farming = {expansionLevel = 1}
					end

					-- Force expansion
					playerData.farming.expansionLevel = targetLevel
					local success = self:CreateExpandableFarmPlot(player)

					if success then
						self:SavePlayerData(player)
						local config = self:GetExpansionConfig(targetLevel)
						print("✅ Expanded to " .. config.name .. " (" .. config.totalSpots .. " spots)")
					else
						print("❌ Expansion failed")
					end

				elseif command == "/checkplotowner" then
					print("Testing plot owner detection...")
					local farm = self:GetPlayerExpandableFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local firstSpot = plantingSpots:FindFirstChild("PlantingSpot_1")
							if firstSpot then
								local owner = self:GetPlotOwner(firstSpot)
								print("First plot owner: " .. tostring(owner))
								print("Expected owner: " .. player.Name)
								print("Match: " .. tostring(owner == player.Name))
							else
								print("❌ No PlantingSpot_1 found")
							end
						else
							print("❌ No PlantingSpots found")
						end
					else
						print("❌ No farm found")
					end

				elseif command == "/givefarmstarter" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						local playerData = self:GetPlayerData(targetPlayer)
						if playerData then
							-- Give farm starter and basic setup
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = true

							playerData.farming = {
								plots = 1,
								expansionLevel = 1,
								inventory = {
									carrot_seeds = 10,
									corn_seeds = 5,
									potato_seeds = 3
								}
							}

							playerData.coins = (playerData.coins or 0) + 10000 -- Give coins for testing

							local success = self:CreateExpandableFarmPlot(targetPlayer)
							if success then
								self:SavePlayerData(targetPlayer)
								print("✅ Gave farm starter to " .. targetPlayer.Name)

								if self.RemoteEvents.PlayerDataUpdated then
									self.RemoteEvents.PlayerDataUpdated:FireClient(targetPlayer, playerData)
								end
							else
								print("❌ Failed to create farm for " .. targetPlayer.Name)
							end
						end
					else
						print("Player " .. targetName .. " not found")
					end
				elseif command == "/debugspecificplot" then
					local plotName = args[2] or "PlantingSpot_1"

					print("=== SPECIFIC PLOT DEBUG ===")
					print("Looking for plot: " .. plotName)

					-- First, let's see what plots actually exist
					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							print("Available plots:")
							local plotCount = 0
							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									plotCount = plotCount + 1
									print("  " .. plotCount .. ": " .. spot.Name)
								end
							end

							-- Now try to find the specific plot
							local plot = self:FindPlotByName(player, plotName)
							if plot then
								print("\n=== ANALYZING " .. plot.Name .. " ===")
								print("✅ Plot found successfully")
								print("Children:")

								for _, child in pairs(plot:GetChildren()) do
									print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
									if child:IsA("Model") and child.Name == "CropModel" then
										print("    ⚠️ THIS IS A CROP MODEL!")
									end
								end

								print("Attributes:")
								print("  IsEmpty: " .. tostring(plot:GetAttribute("IsEmpty")))
								print("  PlantType: " .. tostring(plot:GetAttribute("PlantType")))
								print("  GrowthStage: " .. tostring(plot:GetAttribute("GrowthStage")))
								print("  IsUnlocked: " .. tostring(plot:GetAttribute("IsUnlocked")))

								local isEmpty = self:IsPlotActuallyEmpty(plot)
								print("IsActuallyEmpty result: " .. tostring(isEmpty))
							else
								print("❌ Plot not found: " .. plotName)
								print("Try one of the available plots listed above")
							end
						else
							print("❌ No PlantingSpots folder found")
						end
					else
						print("❌ No farm found")
					end
					print("========================")

				elseif command == "/listallplots" then
					print("=== ALL PLOTS FOR " .. player.Name .. " ===")

					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local plotCount = 0

							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									plotCount = plotCount + 1
									local isEmpty = self:IsPlotActuallyEmpty(spot)
									local isUnlocked = spot:GetAttribute("IsUnlocked")
									local plantType = spot:GetAttribute("PlantType") or ""

									local status = ""
									if not isUnlocked then
										status = "🔒 LOCKED"
									elseif isEmpty then
										status = "🟫 EMPTY"
									else
										status = "🌱 " .. plantType:upper()
									end

									print("  " .. plotCount .. ": " .. spot.Name .. " - " .. status)
								end
							end

							print("Total plots: " .. plotCount)
						else
							print("❌ No PlantingSpots folder")
						end
					else
						print("❌ No farm found")
					end
					print("================================")

				elseif command == "/testplot" then
					local plotNumber = tonumber(args[2]) or 1
					local plotName = "PlantingSpot_" .. plotNumber

					print("🧪 TESTING PLOT: " .. plotName)

					local plot = self:FindPlotByName(player, plotName)
					if plot then
						print("✅ Found plot: " .. plot.Name)

						-- Test all the checks that PlantSeed does
						local plotOwner = self:GetPlotOwner(plot)
						print("Plot owner: " .. tostring(plotOwner) .. " (should be " .. player.Name .. ")")

						local isEmpty = self:IsPlotActuallyEmpty(plot)
						print("Is empty: " .. tostring(isEmpty))

						local isUnlocked = plot:GetAttribute("IsUnlocked")
						print("Is unlocked: " .. tostring(isUnlocked))

						-- Give the player a test seed
						local playerData = self:GetPlayerData(player)
						if playerData then
							playerData.farming = playerData.farming or {inventory = {}}
							playerData.farming.inventory = playerData.farming.inventory or {}
							playerData.farming.inventory.carrot_seeds = 5

							print("✅ Added test seeds")
						end

						-- Show final status
						if plotOwner == player.Name and isEmpty and isUnlocked then
							print("✅ ALL CHECKS PASS - Plot ready for planting!")
							print("Try clicking on " .. plot.Name .. " in-game to plant")
						else
							print("❌ SOME CHECKS FAIL:")
							if plotOwner ~= player.Name then print("  - Wrong owner") end
							if not isEmpty then print("  - Not empty") end
							if not isUnlocked then print("  - Not unlocked") end
						end
					else
						print("❌ Plot not found. Use /listallplots to see available plots")
					end

				elseif command == "/simulateplant" then
					local plotNumber = tonumber(args[2]) or 1
					local plotName = "PlantingSpot_" .. plotNumber

					print("🧪 SIMULATING PLANT on " .. plotName)

					local plot = self:FindPlotByName(player, plotName)
					if plot then
						print("✅ Found plot: " .. plot.Name)

						-- Ensure player has seeds
						local playerData = self:GetPlayerData(player)
						if playerData then
							playerData.farming = playerData.farming or {inventory = {}}
							playerData.farming.inventory = playerData.farming.inventory or {}
							playerData.farming.inventory.carrot_seeds = 5
						end

						-- Clear the plot first
						self:ClearPlotProperly(plot)
						wait(0.2)

						-- Try to call the actual planting function
						print("🔧 Attempting actual plant call...")
						local success = self:PlantSeed(player, plot, "carrot_seeds")
						print("Result: " .. tostring(success))

						if success then
							print("🎉 PLANTING SUCCESSFUL!")
						else
							print("❌ PLANTING FAILED - check the detailed output above")
						end
					else
						print("❌ Plot not found. Available plots:")
						self:DebugAvailablePlots(player)
					end
				elseif command == "/resetfarm" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						-- Remove physical farm
						local farm = self:GetPlayerExpandableFarm(targetPlayer)
						if farm then
							farm:Destroy()
						end

						-- Reset player data
						local playerData = self:GetPlayerData(targetPlayer)
						if playerData then
							playerData.farming = nil
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = nil
							self:SavePlayerData(targetPlayer)
						end

						print("✅ Reset farm for " .. targetPlayer.Name)
					end
				elseif command == "/debugremotes" then
					print("=== REMOTE EVENT DEBUG ===")

					if self.RemoteEvents.PlantSeed then
						print("✅ PlantSeed RemoteEvent exists")

						-- Check if there are multiple connections (this is tricky to detect directly)
						print("RemoteEvent name: " .. self.RemoteEvents.PlantSeed.Name)
						print("RemoteEvent parent: " .. tostring(self.RemoteEvents.PlantSeed.Parent.Name))

						-- Show recent cooldown data
						if self.RemoteEventCooldowns then
							print("Recent RemoteEvent calls:")
							local currentTime = tick()
							for key, time in pairs(self.RemoteEventCooldowns) do
								local age = currentTime - time
								if age < 10 then -- Show calls from last 10 seconds
									print("  " .. key .. ": " .. math.round(age * 1000) .. "ms ago")
								end
							end
						end

						-- Show planting cooldowns
						if self.PlantingCooldowns then
							print("Planting cooldowns:")
							local currentTime = tick()
							for key, time in pairs(self.PlantingCooldowns) do
								local age = currentTime - time
								if age < 10 then -- Show calls from last 10 seconds
									print("  " .. key .. ": " .. math.round(age * 1000) .. "ms ago")
								end
							end
						end

						-- Show rapid attempts
						if self.RapidAttempts then
							print("Rapid attempts:")
							for key, count in pairs(self.RapidAttempts) do
								if count > 0 then
									print("  " .. key .. ": " .. count .. " blocked attempts")
								end
							end
						end
					else
						print("❌ PlantSeed RemoteEvent not found")
					end
					print("========================")

				elseif command == "/clearplantcooldowns" then
					self.PlantingCooldowns = {}
					self.RemoteEventCooldowns = {}
					self.RapidAttempts = {}
					print("✅ Cleared all planting cooldowns")
					self:SendNotification(player, "Debug", "Cleared planting cooldowns", "success")

				elseif command == "/testremotespam" then
					-- Test if RemoteEvent is being called multiple times
					print("🧪 Testing RemoteEvent spam detection...")

					if self.RemoteEvents.PlantSeed then
						-- This would normally be done by the client, but for testing:
						spawn(function()
							for i = 1, 5 do
								print("Firing test PlantSeed event #" .. i)
								-- Simulate what would happen if client fired rapidly
								-- (Note: This is just for testing the cooldown system)
								wait(0.05) -- 50ms between calls
							end
						end)
					end
				elseif command == "/fixclickers" then
					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local fixedCount = 0

							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									-- Remove ALL click detectors from the spot
									local clickersRemoved = 0
									for _, descendant in pairs(spot:GetDescendants()) do
										if descendant:IsA("ClickDetector") then
											descendant:Destroy()
											clickersRemoved = clickersRemoved + 1
										end
									end

									-- Add back exactly ONE click detector
									local spotPart = spot:FindFirstChild("SpotPart")
									if spotPart then
										local clickDetector = Instance.new("ClickDetector")
										clickDetector.MaxActivationDistance = 10
										clickDetector.Parent = spotPart

										clickDetector.MouseClick:Connect(function(clickingPlayer)
											if clickingPlayer.UserId == player.UserId then
												self:HandleSimplePlotClick(clickingPlayer, spot)
											end
										end)

										if clickersRemoved > 1 then
											print("🔧 Fixed " .. spot.Name .. " (removed " .. clickersRemoved .. " extra clickers)")
											fixedCount = fixedCount + 1
										end
									end
								end
							end

							print("✅ Fixed " .. fixedCount .. " plots with multiple click detectors")
						end
					end
				elseif command == "/checkduplicates" then
					print("=== CHECKING FOR DUPLICATE CROPS ===")
					local duplicatesFound = 0

					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									local cropCount = 0
									for _, child in pairs(spot:GetChildren()) do
										if child:IsA("Model") and child.Name == "CropModel" then
											cropCount = cropCount + 1
										end
									end

									if cropCount > 1 then
										print("🚨 DUPLICATE FOUND: " .. spot.Name .. " has " .. cropCount .. " CropModels")
										duplicatesFound = duplicatesFound + 1

										-- List all duplicates
										for _, child in pairs(spot:GetChildren()) do
											if child:IsA("Model") and child.Name == "CropModel" then
												print("  - " .. child:GetDebugId() .. " (CropType: " .. tostring(child:GetAttribute("CropType")) .. ")")
											end
										end
									elseif cropCount == 1 then
										print("✅ " .. spot.Name .. " has correct single crop")
									end
								end
							end
						end
					end

					print("Total duplicates found: " .. duplicatesFound)
					print("=====================================")

				elseif command == "/cleanduplicates" then
					print("🧹 Cleaning duplicate crops...")
					local cleanedCount = 0

					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									local crops = {}

									-- Collect all CropModels
									for _, child in pairs(spot:GetChildren()) do
										if child:IsA("Model") and child.Name == "CropModel" then
											table.insert(crops, child)
										end
									end

									-- If more than one, remove extras
									if #crops > 1 then
										print("🧹 Cleaning " .. spot.Name .. " (" .. #crops .. " crops found)")

										-- Keep the first one, remove the rest
										for i = 2, #crops do
											crops[i]:Destroy()
											cleanedCount = cleanedCount + 1
										end
									end
								end
							end
						end
					end

					print("✅ Cleaned " .. cleanedCount .. " duplicate crops")

				elseif command == "/forcecleanplot" then
					local plotName = args[2] or "PlantingSpot_1"

					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local targetSpot = plantingSpots:FindFirstChild(plotName)
							if targetSpot then
								print("🔧 Force cleaning " .. plotName)
								self:ClearPlotProperly(targetSpot)

								-- Double check
								wait(0.5)
								local verification = self:VerifyPlotIsClean(targetSpot)
								print("Verification result: " .. tostring(verification))
							else
								print("❌ Plot " .. plotName .. " not found")
							end
						end
					end

					print("🌾 COMPLETE HARVEST FIX LOADED!")
					print("🔧 Enhanced Commands:")
					print("  /checkduplicates - Find plots with multiple crops")
					print("  /cleanduplicates - Remove duplicate crops") 
					print("  /forcecleanplot [name] - Force clean specific plot")
					print("  /debugharvest - Standard harvest debug")
				elseif command == "/debugcrops" then
					print("=== CROP MOVEMENT DEBUG ===")
					local cropsFound = 0

					for _, model in pairs(workspace:GetDescendants()) do
						if model:IsA("Model") and (model.Name:find("_premade") or model.Name:find("_procedural")) then
							cropsFound = cropsFound + 1
							local cropType = model:GetAttribute("CropType") or "unknown"
							local rarity = model:GetAttribute("Rarity") or "unknown"
							local isStable = model:GetAttribute("IsStable") or false

							print("Crop " .. cropsFound .. ": " .. cropType .. " (" .. rarity .. ")")
							print("  Model: " .. model.Name)
							print("  Stable: " .. tostring(isStable))

							if model.PrimaryPart then
								print("  Position: " .. tostring(model.PrimaryPart.Position))
								print("  Anchored: " .. tostring(model.PrimaryPart.Anchored))
								print("  Velocity: " .. tostring(model.PrimaryPart.AssemblyLinearVelocity.Magnitude))
							end
							print("")
						end
					end

					if cropsFound == 0 then
						print("No crops found in workspace")
					else
						print("Total crops found: " .. cropsFound)
					end
					print("============================")

				elseif command == "/fixmovingcrops" then
					print("🔧 Fixing all moving crops...")
					local fixedCount = 0

					for _, model in pairs(workspace:GetDescendants()) do
						if model:IsA("Model") and (model.Name:find("_premade") or model.Name:find("_procedural")) then
							-- Force re-anchor all parts
							for _, part in pairs(model:GetDescendants()) do
								if part:IsA("BasePart") then
									part.Anchored = true
									part.CanCollide = false
									part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
									part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
								end
							end

							model:SetAttribute("IsStable", true)
							fixedCount = fixedCount + 1
						end
					end

					print("✅ Fixed " .. fixedCount .. " crops")

				elseif command == "/testcropstability" then
					print("🧪 Testing crop stability...")

					-- Create a test crop
					if _G.CropVisualManager then
						local testCrop = _G.CropVisualManager:CreateCropModel("carrot", "common", "ready")
						testCrop.Name = "StabilityTestCrop"
						testCrop.Parent = workspace

						if testCrop.PrimaryPart then
							testCrop.PrimaryPart.CFrame = CFrame.new(0, 10, 0)
						end

						-- Monitor for 10 seconds
						spawn(function()
							local originalPos = testCrop.PrimaryPart.Position
							print("📍 Test crop created at: " .. tostring(originalPos))

							for i = 1, 10 do
								wait(1)
								if testCrop and testCrop.PrimaryPart then
									local currentPos = testCrop.PrimaryPart.Position
									local distance = (currentPos - originalPos).Magnitude
									print("Second " .. i .. ": Distance moved = " .. math.round(distance * 100) / 100 .. " studs")

									if distance > 0.5 then
										print("⚠️ MOVEMENT DETECTED at second " .. i)
									end
								else
									print("❌ Test crop was destroyed")
									break
								end
							end

							print("🧪 Stability test complete")
							if testCrop then
								testCrop:Destroy()
								print("🗑️ Test crop cleaned up")
							end
						end)
					else
						print("❌ CropVisualManager not found")
					end

				elseif command == "/monitorcrops" then
					print("👁️ Starting crop movement monitoring...")

					-- Monitor all existing crops for movement
					spawn(function()
						local monitoredCrops = {}

						-- Collect all current crops and their positions
						for _, model in pairs(workspace:GetDescendants()) do
							if model:IsA("Model") and (model.Name:find("_premade") or model.Name:find("_procedural")) then
								if model.PrimaryPart then
									monitoredCrops[model] = {
										originalPos = model.PrimaryPart.Position,
										name = model.Name,
										alertCount = 0
									}
								end
							end
						end

						print("📊 Monitoring " .. self:CountTable(monitoredCrops) .. " crops for movement...")

						-- Monitor for 30 seconds
						for i = 1, 30 do
							wait(1)

							for crop, data in pairs(monitoredCrops) do
								if crop and crop.Parent and crop.PrimaryPart then
									local currentPos = crop.PrimaryPart.Position
									local distance = (currentPos - data.originalPos).Magnitude

									if distance > 1 then -- Alert if moved more than 1 stud
										data.alertCount = data.alertCount + 1
										print("🚨 CROP MOVEMENT: " .. data.name .. " moved " .. math.round(distance * 100) / 100 .. " studs (Alert #" .. data.alertCount .. ")")

										-- Try to fix it
										crop.PrimaryPart.Anchored = true
										crop.PrimaryPart.CFrame = CFrame.new(data.originalPos)

										for _, part in pairs(crop:GetDescendants()) do
											if part:IsA("BasePart") then
												part.Anchored = true
												part.CanCollide = false
												part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
												part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
											end
										end
									end
								else
									-- Crop was destroyed or removed
									monitoredCrops[crop] = nil
								end
							end
						end

						print("👁️ Crop monitoring complete")
					end)

				elseif command == "/createstablecrop" then
					local cropType = args[2] or "carrot"
					local rarity = args[3] or "common"

					if _G.CropVisualManager then
						print("🌱 Creating stable " .. rarity .. " " .. cropType .. " crop...")
						local stableCrop = _G.CropVisualManager:CreateCropModel(cropType, rarity, "ready")
						stableCrop.Parent = workspace

						if stableCrop.PrimaryPart then
							stableCrop.PrimaryPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
						end

						-- Apply enhanced stability
						_G.CropVisualManager:EnsureModelIsProperlyAnchored(stableCrop)
						stableCrop:SetAttribute("IsStable", true)

						print("✅ Stable crop created: " .. stableCrop.Name)
					else
						print("❌ CropVisualManager not available")
					end
				

				print("🔧 CROP STABILITY DEBUG COMMANDS LOADED:")
				print("  /debugcrops - Show all crops and their status")
				print("  /fixmovingcrops - Force fix all moving crops")
				print("  /testcropstability - Create test crop and monitor for movement")
				print("  /monitorcrops - Monitor all crops for movement for 30 seconds")
					print("  /createstablecrop [type] [rarity] - Create a stable test crop")
				elseif command == "/debugharvest" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						print("=== HARVEST DEBUG FOR " .. targetPlayer.Name .. " ===")

						-- Find player's farm
						local farm = self:GetPlayerSimpleFarm(targetPlayer)
						if farm then
							print("✅ Found farm: " .. farm.Name)

							local plantingSpots = farm:FindFirstChild("PlantingSpots")
							if plantingSpots then
								for _, spot in pairs(plantingSpots:GetChildren()) do
									if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
										local isEmpty = spot:GetAttribute("IsEmpty")
										if not isEmpty then
											print("🌱 Found crop on " .. spot.Name)
											print("  PlantType: " .. tostring(spot:GetAttribute("PlantType")))
											print("  GrowthStage: " .. tostring(spot:GetAttribute("GrowthStage")))
											print("  Children:")
											for _, child in pairs(spot:GetChildren()) do
												print("    - " .. child.Name .. " (" .. child.ClassName .. ")")
											end
										end
									end
								end
							end
						else
							print("❌ No farm found")
						end
						print("=====================================")
					end

				elseif command == "/testharvest" then
					print("🧪 Testing harvest system...")

					-- Find a plot with a crop
					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									local isEmpty = spot:GetAttribute("IsEmpty")
									if not isEmpty then
										print("🌾 Testing harvest on " .. spot.Name)
										self:HarvestCrop(player, spot)
										break
									end
								end
							end
						end
					end

				elseif command == "/forceharvest" then
					local plotName = args[2] or "PlantingSpot_1"

					-- Find the specific plot
					local farm = self:GetPlayerSimpleFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local targetSpot = plantingSpots:FindFirstChild(plotName)
							if targetSpot then
								print("🔧 Force harvesting " .. plotName)

								-- Set it as ready and harvest
								targetSpot:SetAttribute("IsEmpty", false)
								targetSpot:SetAttribute("GrowthStage", 4)
								targetSpot:SetAttribute("PlantType", "carrot")
								targetSpot:SetAttribute("Rarity", "common")

								self:HarvestCrop(player, targetSpot)
							else
								print("❌ Plot " .. plotName .. " not found")
							end
						end
					end

					print("🌾 HARVEST FIX LOADED!")
					print("🔧 Debug Commands:")
					print("  /debugharvest [player] - Debug harvest system")
					print("  /testharvest - Test harvest on first available crop")
					print("  /forceharvest [plotName] - Force harvest specific plot")
					
				elseif command == "/inspectfarm" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						print("=== FARM INSPECTION FOR " .. targetPlayer.Name .. " ===")

						local farm = self:GetPlayerExpandableFarm(targetPlayer)
						if farm then
							print("✅ Physical farm exists: " .. farm.Name)
							print("Position: " .. tostring(farm.PrimaryPart and farm.PrimaryPart.Position or "NO PRIMARY PART"))

							local plantingSpots = farm:FindFirstChild("PlantingSpots")
							if plantingSpots then
								print("PlantingSpots folder exists")

								local spotsByStatus = {unlocked = 0, locked = 0, occupied = 0, empty = 0}

								for _, spot in pairs(plantingSpots:GetChildren()) do
									if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
										if spot:GetAttribute("IsUnlocked") then
											spotsByStatus.unlocked = spotsByStatus.unlocked + 1

											if spot:GetAttribute("IsEmpty") == false then
												spotsByStatus.occupied = spotsByStatus.occupied + 1
											else
												spotsByStatus.empty = spotsByStatus.empty + 1
											end
										else
											spotsByStatus.locked = spotsByStatus.locked + 1
										end
									end
								end

								print("Spot status:")
								print("  Unlocked: " .. spotsByStatus.unlocked)
								print("  Locked: " .. spotsByStatus.locked)
								print("  Occupied: " .. spotsByStatus.occupied)
								print("  Empty: " .. spotsByStatus.empty)
							else
								print("❌ No PlantingSpots folder")
							end
						else
							print("❌ No physical farm found")
						end

						print("=============================================")
					end
				end
			
						print("GameCore: ✅ ENHANCED DEBUG COMMANDS LOADED!")
						print("🔧 Available Debug Commands:")
						print("  /debugplanting - Show detailed planting system status")
						print("  /testplanting - Give test seeds for planting")
						print("  /fixfarm - Fix/create farm for player")
						print("  /testexpansion [level] - Test farm expansion to specific level")
						print("  /checkplotowner - Test plot owner detection")
						print("  /givefarmstarter [player] - Give farm starter to player")
						print("  /resetfarm [player] - Reset player's farm completely")
				print("  /inspectfarm [player] - Detailed farm inspection")
				
				
			end
		end)
	end)
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

		-- Boosters and Enhancements
		boosters = {},

		-- Statistics
		stats = {
			coinsEarned = 100,
			cropsHarvested = 0,
			rareCropsHarvested = 0,
			seedsPlanted = 0,
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


function GameCore:AddDataStoreDebugCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/datastatus" then
					print("=== DATASTORE STATUS ===")

					local currentTime = os.time()

					print("Save Cooldowns:")
					for userId, lastSave in pairs(self.DataStoreCooldowns) do
						local player = Players:GetPlayerByUserId(userId)
						local playerName = player and player.Name or "Unknown"
						local timeSince = currentTime - lastSave
						local canSave = timeSince >= self.SAVE_COOLDOWN

						print("  " .. playerName .. ": " .. timeSince .. "s ago " .. (canSave and "✅" or "❌"))
					end

					print("Dirty Players (need saving):")
					local dirtyCount = 0
					for userId, dirtyTime in pairs(self.DirtyPlayers) do
						local player = Players:GetPlayerByUserId(userId)
						local playerName = player and player.Name or "Unknown"
						local timeDirty = currentTime - dirtyTime

						print("  " .. playerName .. ": dirty for " .. timeDirty .. "s")
						dirtyCount = dirtyCount + 1
					end

					if dirtyCount == 0 then
						print("  No players need saving")
					end

					print("Pending Saves:")
					local pendingCount = 0
					for userId, _ in pairs(self.PendingSaves) do
						local player = Players:GetPlayerByUserId(userId)
						local playerName = player and player.Name or "Unknown"
						print("  " .. playerName .. ": save scheduled")
						pendingCount = pendingCount + 1
					end

					if pendingCount == 0 then
						print("  No pending saves")
					end

					print("Settings:")
					print("  Save Cooldown: " .. self.SAVE_COOLDOWN .. " seconds")
					print("  Batch Delay: " .. self.BATCH_SAVE_DELAY .. " seconds")
					print("========================")

				elseif command == "/forcesave" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						print("🔧 Force saving data for " .. targetPlayer.Name)
						local success = self:SavePlayerData(targetPlayer, true) -- Force immediate

						if success then
							print("✅ Force save successful")
						else
							print("❌ Force save failed")
						end
					else
						print("❌ Player not found: " .. targetName)
					end

				elseif command == "/saveall" then
					print("🔧 Force saving all player data...")

					local savedCount = 0
					local failedCount = 0

					for _, targetPlayer in pairs(Players:GetPlayers()) do
						if self.PlayerData[targetPlayer.UserId] then
							local success = self:SavePlayerData(targetPlayer, true)

							if success then
								savedCount = savedCount + 1
							else
								failedCount = failedCount + 1
							end

							wait(0.5) -- Delay between saves to prevent queue overflow
						end
					end

					print("✅ Save all complete: " .. savedCount .. " successful, " .. failedCount .. " failed")

				elseif command == "/cleandirty" then
					print("🧹 Cleaning dirty players list...")

					local cleanedCount = 0
					local currentTime = os.time()

					for userId, dirtyTime in pairs(self.DirtyPlayers) do
						local player = Players:GetPlayerByUserId(userId)

						if not player then
							self.DirtyPlayers[userId] = nil
							cleanedCount = cleanedCount + 1
						end
					end

					print("✅ Cleaned " .. cleanedCount .. " old dirty entries")

				elseif command == "/savecooldown" then
					local newCooldown = tonumber(args[2])

					if newCooldown and newCooldown >= 5 and newCooldown <= 300 then
						self.SAVE_COOLDOWN = newCooldown
						print("✅ Save cooldown set to " .. newCooldown .. " seconds")
					else
						print("❌ Invalid cooldown. Use: /savecooldown [5-300]")
						print("Current cooldown: " .. self.SAVE_COOLDOWN .. " seconds")
					end

				elseif command == "/datainfo" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						local userId = targetPlayer.UserId
						local currentTime = os.time()

						print("=== DATA INFO FOR " .. targetPlayer.Name .. " ===")

						local lastSave = self.DataStoreCooldowns[userId] or 0
						local timeSince = currentTime - lastSave

						print("Last save: " .. timeSince .. " seconds ago")
						print("Can save: " .. (timeSince >= self.SAVE_COOLDOWN and "✅ YES" or "❌ NO"))
						print("Is dirty: " .. (self.DirtyPlayers[userId] and "✅ YES" or "❌ NO"))
						print("Pending save: " .. (self.PendingSaves[userId] and "✅ YES" or "❌ NO"))

						if self.DirtyPlayers[userId] then
							local dirtyTime = currentTime - self.DirtyPlayers[userId]
							print("Dirty for: " .. dirtyTime .. " seconds")
						end

						local playerData = self.PlayerData[userId]
						if playerData then
							print("Data exists: ✅ YES")
							print("Coins: " .. (playerData.coins or 0))
							print("Farm plots: " .. (playerData.farming and playerData.farming.plots or 0))
						else
							print("Data exists: ❌ NO")
						end

						print("==========================================")
					else
						print("❌ Player not found: " .. targetName)
					end
				elseif command == "/testmodelcreation" then
					local cropType = args[2] or "carrot"
					local stage = args[3] or "planted"

					print("🧪 Testing model creation: " .. cropType .. " at stage " .. stage)

					if CropVisualManager then
						-- Test if model exists
						local hasModel = CropVisualManager:HasPreMadeModel(cropType)
						print("Pre-made model available: " .. tostring(hasModel))

						if hasModel then
							local model = CropVisualManager:GetPreMadeModel(cropType)
							print("Model found: " .. model.Name)
							print("Model location: " .. model.Parent.Name)
						end

						-- Test creating the crop
						local testCrop = CropVisualManager:CreateCropModel(cropType, "common", stage)
						if testCrop then
							testCrop.Parent = workspace
							testCrop.PrimaryPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)

							print("✅ Test crop created: " .. testCrop.Name)
							print("Model type: " .. tostring(testCrop:GetAttribute("ModelType")))

							-- Clean up after 10 seconds
							spawn(function()
								wait(10)
								if testCrop and testCrop.Parent then
									testCrop:Destroy()
									print("🗑️ Test crop cleaned up")
								end
							end)
						else
							print("❌ Failed to create test crop")
						end
					else
						print("❌ CropVisualManager not available")
					end

				elseif command == "/listmodels" then
					print("=== AVAILABLE CROP MODELS ===")

					local cropModels = game:GetService("ReplicatedStorage"):FindFirstChild("CropModels")
					if cropModels then
						print("CropModels folder found with " .. #cropModels:GetChildren() .. " items:")

						for i, model in pairs(cropModels:GetChildren()) do
							if model:IsA("Model") then
								print("  " .. i .. ": " .. model.Name)
							else
								print("  " .. i .. ": " .. model.Name .. " (" .. model.ClassName .. ") - NOT A MODEL")
							end
						end

						-- Test CropVisualManager's detection
						if CropVisualManager then
							print("\nCropVisualManager detection:")
							for _, model in pairs(cropModels:GetChildren()) do
								if model:IsA("Model") then
									local detected = CropVisualManager:HasPreMadeModel(model.Name)
									print("  " .. model.Name .. ": " .. (detected and "✅ DETECTED" or "❌ NOT DETECTED"))
								end
							end
						end
					else
						print("❌ CropModels folder not found in ReplicatedStorage")
						print("Current ReplicatedStorage children:")
						for _, child in pairs(game:GetService("ReplicatedStorage"):GetChildren()) do
							print("  - " .. child.Name)
						end
					end
					print("============================")
				elseif command == "/testgrowth" then
					local plotName = args[2] or "PlantingSpot_1"
					local cropType = args[3] or "carrot"

					print("🧪 Testing growth progression for " .. cropType)

					local plot = self:FindPlotByName(player, plotName)
					if plot then
						-- Clear plot and plant crop
						self:ClearPlotProperly(plot)
						wait(0.5)

						-- Force plant the crop
						local seedData = {resultCropId = cropType, growTime = 300}
						local success = self:CreateCropOnPlotWithDebug(plot, cropType .. "_seeds", seedData, "common")

						if success then
							plot:SetAttribute("IsEmpty", false)
							plot:SetAttribute("PlantType", cropType)
							plot:SetAttribute("GrowthStage", 0)
							plot:SetAttribute("PlantedTime", os.time())

							print("✅ Crop planted, starting accelerated growth test...")

							-- Test each growth stage with delays
							local stages = {"planted", "sprouting", "growing", "flowering", "ready"}

							spawn(function()
								for i = 1, #stages do
									wait(3) -- 3 seconds between stages for testing

									plot:SetAttribute("GrowthStage", i - 1)

									print("🌱 Testing stage " .. i .. ": " .. stages[i])
									self:UpdateCropVisualForNewStage(plot, cropType, "common", stages[i], i - 1)

									self:SendNotification(player, "Growth Test", "Stage " .. i .. ": " .. stages[i], "info")
								end

								print("🎉 Growth test complete!")
								self:SendNotification(player, "Growth Test", "All stages tested!", "success")
							end)
						else
							print("❌ Failed to plant test crop")
						end
					else
						print("❌ Plot not found: " .. plotName)
					end

				elseif command == "/accelerategrowth" then
					local plotName = args[2] or "PlantingSpot_1"

					local plot = self:FindPlotByName(player, plotName)
					if plot then
						local currentStage = plot:GetAttribute("GrowthStage") or 0
						local plantType = plot:GetAttribute("PlantType") or ""
						local rarity = plot:GetAttribute("Rarity") or "common"

						if plantType ~= "" and currentStage < 4 then
							local newStage = currentStage + 1
							local stageNames = {"planted", "sprouting", "growing", "flowering", "ready"}
							local stageName = stageNames[newStage + 1] or "ready"

							plot:SetAttribute("GrowthStage", newStage)

							self:UpdateCropVisualForNewStage(plot, plantType, rarity, stageName, newStage)

							print("🚀 Accelerated " .. plantType .. " to stage " .. newStage .. " (" .. stageName .. ")")
							self:SendNotification(player, "Growth Accelerated", plantType .. " advanced to " .. stageName, "success")
						else
							print("❌ No crop to accelerate or already fully grown")
						end
					else
						print("❌ Plot not found: " .. plotName)
					end
				elseif command == "/testplant" then
					-- Test planting without triggering multiple saves
					print("🧪 Testing optimized planting...")

					local oldCooldown = self.SAVE_COOLDOWN
					self.SAVE_COOLDOWN = 5 -- Temporarily reduce cooldown for testing

					-- Give test seeds
					local playerData = self:GetPlayerData(player)
					if playerData then
						playerData.farming = playerData.farming or {inventory = {}}
						playerData.farming.inventory = playerData.farming.inventory or {}
						playerData.farming.inventory.carrot_seeds = 5

						print("✅ Added test seeds")
						print("Now try planting normally - check output for DataStore messages")

						-- Restore original cooldown after 30 seconds
						spawn(function()
							wait(30)
							self.SAVE_COOLDOWN = oldCooldown
							print("🔧 Restored original save cooldown: " .. oldCooldown .. " seconds")
						end)
					end

				elseif command == "/queuestatus" then
					print("=== DATASTORE QUEUE STATUS ===")
					print("This is estimated based on recent activity:")

					local recentSaves = 0
					local currentTime = os.time()

					-- Count saves in the last minute
					for _, lastSave in pairs(self.DataStoreCooldowns) do
						if currentTime - lastSave <= 60 then
							recentSaves = recentSaves + 1
						end
					end

					local playerCount = #Players:GetPlayers()
					local maxRequestsPerMinute = 60 + (playerCount * 10)
					local queueUsage = (recentSaves / maxRequestsPerMinute) * 100

					print("Recent saves (last minute): " .. recentSaves)
					print("Max requests per minute: " .. maxRequestsPerMinute)
					print("Estimated queue usage: " .. math.floor(queueUsage) .. "%")

					if queueUsage > 80 then
						print("⚠️ HIGH USAGE - Risk of queue overflow")
					elseif queueUsage > 50 then
						print("⚠️ MODERATE USAGE - Monitor closely")
					else
						print("✅ LOW USAGE - Queue healthy")
					end

					print("==============================")
				end
			end
		end)
	end)
end
function GameCore:AddModuleDebugCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/cropmodulestatus" then
					print("=== CROPVISUALMANAGER MODULE STATUS ===")

					if CropVisualManager then
						print("✅ Module loaded: YES")
						print("✅ Available: " .. tostring(CropVisualManager:IsAvailable()))

						local status = CropVisualManager:GetStatus()
						print("✅ Models loaded: " .. status.modelsLoaded)
						print("✅ Initialized: " .. tostring(status.initialized))

						-- Test creation
						local testCrop = CropVisualManager:CreateCropModel("carrot", "common", "ready")
						if testCrop then
							print("✅ Test creation: SUCCESS")
							testCrop:Destroy()
						else
							print("❌ Test creation: FAILED")
						end
					else
						print("❌ Module loaded: NO")
						print("❌ CropVisualManager is nil")

						-- Try to reload
						print("🔧 Attempting to reload module...")
						self:LoadCropVisualManager()
					end

					print("========================================")

				elseif command == "/reloadcropmodule" then
					print("🔧 Reloading CropVisualManager module...")

					CropVisualManager = nil
					local success = self:LoadCropVisualManager()

					if success then
						print("✅ Module reloaded successfully")
					else
						print("❌ Module reload failed")
					end

				elseif command == "/testmodulecrop" then
					local cropType = args[2] or "carrot"
					local plotName = args[3] or "PlantingSpot_1"

					if CropVisualManager then
						print("🧪 Testing module crop creation: " .. cropType .. " on " .. plotName)

						local plot = self:FindPlotByName(player, plotName)
						if plot then
							local success = CropVisualManager:HandleCropPlanted(plot, cropType, "common")

							if success then
								print("✅ Module test successful")
							else
								print("❌ Module test failed")
							end
						else
							print("❌ Plot not found: " .. plotName)
						end
					else
						print("❌ CropVisualManager module not loaded")
					end
				end
			end
		end)
	end)
end

-- Make sure to call this in your Initialize method:
-- self:AddModuleDebugCommands()

print("GameCore: ✅ MODULE INTEGRATION LOADED!")
print("🔧 Key improvements:")
print("  ✅ Direct module loading - no race conditions")
print("  ✅ Proper initialization order")
print("  ✅ Better error handling")
print("  ✅ Module status checking")
print("  ✅ Reload capabilities")
print("")
print("🧪 Debug commands:")
print("  /cropmodulestatus - Check module status")
print("  /reloadcropmodule - Reload the module")
print("  /testmodulecrop [type] [plot] - Test module crop creation")
-- Call this in your GameCore:Initialize() method
-- self:AddDataStoreDebugCommands()
function GameCore:AddCropDebugCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/testcrop" then
					local cropType = args[2] or "carrot"
					local rarity = args[3] or "common"

					print("🧪 Admin testing crop creation: " .. cropType .. " (" .. rarity .. ")")

					-- Find first empty plot
					local testPlot = self:FindFirstEmptyPlot(player)
					if testPlot then
						local seedData = ItemConfig.GetSeedData(cropType .. "_seeds")
						if seedData then
							self:CreateCropOnPlotWithDebug(testPlot, cropType .. "_seeds", seedData, rarity)
							print("✅ Test crop creation attempted")
						else
							print("❌ No seed data found for " .. cropType)
						end
					else
						print("❌ No empty plot found for testing")
					end
				elseif command == "/checkclickers" then
					local plotNumber = tonumber(args[2]) or 1
					local plotName = "PlantingSpot_" .. plotNumber

					local plot = self:FindPlotByName(player, plotName)
					if plot then
						print("=== CLICK DETECTORS FOR " .. plotName .. " ===")

						local clickerCount = 0
						local function checkForClickers(obj, depth)
							local indent = string.rep("  ", depth or 0)

							for _, child in pairs(obj:GetChildren()) do
								if child:IsA("ClickDetector") then
									clickerCount = clickerCount + 1
									print(indent .. "🖱️ ClickDetector found in: " .. child.Parent.Name)
								elseif child:IsA("Model") or child:IsA("Folder") then
									print(indent .. "📁 " .. child.Name .. " (" .. child.ClassName .. ")")
									checkForClickers(child, (depth or 0) + 1)
								end
							end
						end

						checkForClickers(plot)
						print("Total ClickDetectors found: " .. clickerCount)
						print("========================================")
					else
						print("❌ Plot not found")
					end
				elseif command == "/forcecrop" then
					local plotName = args[2] or "PlantingSpot_1"
					local cropType = args[3] or "carrot"

					_G.ForceCropOnPlot(plotName, cropType)

				elseif command == "/listplots" then
					print("=== AVAILABLE PLOTS ===")
					local count = 0
					for _, area in pairs(workspace:GetDescendants()) do
						if area:IsA("Model") and area.Name:find("PlantingSpot") then
							count = count + 1
							local isEmpty = area:GetAttribute("IsEmpty")
							local status = isEmpty and "🟫 EMPTY" or "🌱 HAS CROP"
							print("  " .. status .. " " .. area.Name)
						end
					end
					print("Total plots: " .. count)
					print("=====================")
				end
			end
		end)
	end)
end
function GameCore:FindFirstEmptyPlot(player)
	local farm = self:GetPlayerSimpleFarm(player)
	if not farm then return nil end

	local plantingSpots = farm:FindFirstChild("PlantingSpots")
	if not plantingSpots then return nil end

	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			if self:IsPlotActuallyEmpty(spot) then
				return spot
			end
		end
	end

	return nil
end
function GameCore:AddCropSystemDebugCommand()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/debugcropsystem" then
					print("=== CROP SYSTEM DEBUG ===")

					local vmStatus = self:GetCropVisualManagerStatus()
					print("CropVisualManager Status:")
					print("  Available: " .. tostring(vmStatus.available))
					print("  Disabled: " .. tostring(vmStatus.disabled))

					if vmStatus.available then
						print("  Methods:")
						for method, exists in pairs(vmStatus.methods) do
							print("    " .. method .. ": " .. (exists and "✅" or "❌"))
						end
					end

					print("\nGameCore Crop Methods:")
					local gameCoreMethod = {
						"CreateCropOnPlotWithDebug",
						"CreateEnhancedFallbackCrop",
						"PlantSeed",
						"HarvestCrop"
					}

					for _, method in ipairs(gameCoreMethod) do
						local exists = type(self[method]) == "function"
						print("  " .. method .. ": " .. (exists and "✅" or "❌"))
					end

					print("\nRecommendations:")
					if not vmStatus.available then
						print("  📝 CropVisualManager not found - check if script is running")
					elseif vmStatus.disabled then
						print("  📝 CropVisualManager disabled - check for errors in script")
					else
						print("  ✅ System appears to be working correctly")
					end

					print("========================")

				elseif command == "/reloadcropsystem" then
					print("Admin: Reloading crop system...")

					-- Re-check CropVisualManager
					_G.DISABLE_CROPVISUALMANAGER = false
					self:WaitForCropVisualManager()

					print("Admin: Crop system reload complete")
				end
			end
		end)
	end)
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

-- ========== PLAYER EVENTS ==========

Players.PlayerAdded:Connect(function(player)
	GameCore:LoadPlayerData(player)
	GameCore:CreatePlayerLeaderstats(player)
end)


-- Make globally available
_G.GameCore = GameCore
spawn(function()
	wait(2) -- Wait for all scripts to load

	print("=== CROP SYSTEM LOAD VERIFICATION ===")

	local status = GameCore:GetCropVisualManagerStatus()

	if status.available and not status.disabled then
		print("✅ Crop system fully loaded and operational")

		-- Test with a simple crop creation if possible
		if _G.TestCropVisual then
			print("✅ Test functions available")
		end
	else
		warn("⚠️ Crop system has issues:")
		if not status.available then
			warn("  - CropVisualManager not found")
		end
		if status.disabled then
			warn("  - CropVisualManager disabled due to errors")
		end
		warn("  - Will use fallback crop creation only")
	end

	print("====================================")
end)

print("🌱 ✅ GAMECORE CROP CREATION FIX LOADED!")
print("🔧 Key fixes:")
print("  ✅ Better CropVisualManager integration")
print("  ✅ Enhanced fallback crop creation")
print("  ✅ Improved error handling and debugging")
print("  ✅ Consistent crop naming (CropModel)")
print("  ✅ Better visual effects for mutations")
print("")
print("🧪 Admin commands:")
print("  /testcrop [type] [rarity] - Test crop creation")
print("  /forcecrop [plot] [type] - Force create crop on plot")
print("  /listplots - List all available plots")
print("🔧 ✅ SCRIPT LOADING ORDER FIX LOADED!")
print("Features:")
print("  ✅ Waits for CropVisualManager before initialization")
print("  ✅ Tests integration before use")
print("  ✅ Automatic fallback on failure")
print("  ✅ Enhanced debugging commands")
print("  ✅ Load order verification")
print("")
print("🧪 Debug commands:")
print("  /debugcropsystem - Show detailed system status")
print("  /reloadcropsystem - Attempt to reload crop system")
print("GameCore: ✅ FIXED and ENHANCED core game system loaded successfully!")
print("🌟 NEW FEATURES:")
print("  🌱 Complete farming system with ALL seeds from ItemConfig")
print("  🎲 Full rarity system implementation (5 tiers)")
print("  ✨ Visual rarity effects (sparkles, glows, auras)")
print("  📏 Rarity-based size scaling for crops") 
print("  💰 Rarity-based value multipliers")
print("  🔍 Enhanced growth timers and indicators")
print("  🎮 Improved admin commands for testing")
print("  📊 Better statistics tracking")
print("")
print("🧪 ADMIN COMMANDS (ENHANCED):")
print("  /giveallseeds - Give ALL seed types")
print("  /testrarities - Visual rarity test")
print("  /checkshopitems - Debug shop items")
print("  (Plus all previous commands)")
print("GameCore: ✅ PLANTING DEBUG FIX LOADED!")
print("🔧 DEBUGGING FEATURES:")
print("  🌱 Step-by-step planting validation")
print("  🎨 CropVisualManager bypass option")
print("  🔧 Fallback crop creation system")
print("  📊 Enhanced error reporting")
print("  🧪 Admin testing commands")
print("")
print("🔧 Admin Commands:")
print("  /testplanting - Give test seeds")
print("  /disablecropvm - Disable CropVisualManager")
print("  /enablecropvm - Enable CropVisualManager")
print("  /forceplant [seed] [plot] - Force plant on specific plot")
print("  /debugplot [plot] - Debug specific plot status")
print("")
print("💡 TIP: If planting still fails, try /disablecropvm to use fallback crops")
return GameCore