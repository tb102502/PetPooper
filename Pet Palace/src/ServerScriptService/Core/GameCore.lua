--[[
    UPDATED GameCore.lua - Modular System Integration
    Place in: ServerScriptService/Core/GameCore.lua
    
    FEATURES:
    ✅ Modular architecture with separate crop and farm systems
    ✅ Clean module integration and dependency injection
    ✅ Proper initialization order
    ✅ Enhanced error handling and fallbacks
    ✅ Maintained compatibility with existing systems
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
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GameRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Module references - will be loaded during initialization
local CropCreation = nil
local CropVisual = nil
local FarmPlot = nil
local MutationSystem = nil
local CowCreationModule = nil
local CowMilkingModule = nil

function GameCore:InitializeDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore("LivestockFarmData_v2")
	end)

	if success then
		self.PlayerDataStore = dataStore
		print("GameCore: DataStore connected (Live)")
	else
		-- Create mock DataStore for Studio testing
		self.PlayerDataStore = {
			GetAsync = function(self, key)
				warn("GameCore: Using mock DataStore for Studio - GetAsync(" .. key .. ")")
				return nil -- Return nil to use default data
			end,
			SetAsync = function(self, key, data)
				print("GameCore: Mock DataStore save for " .. key .. " (Studio mode)")
				return true
			end
		}
		warn("GameCore: Using mock DataStore for Studio testing")
	end
end
-- Enhanced save system properties
GameCore.SAVE_COOLDOWN = 30
GameCore.BATCH_SAVE_DELAY = 5
GameCore.DataStoreCooldowns = {}
GameCore.PendingSaves = {}
GameCore.DirtyPlayers = {}

-- Core Data Management
GameCore.PlayerData = {}
GameCore.DataStore = nil
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}

-- System States
GameCore.Systems = {
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {},
		RarityEffects = {}
	}
}

-- Reference to ShopSystem (will be injected)
GameCore.ShopSystem = nil

-- ========== MODULE LOADING ==========

function GameCore:LoadModules()
	print("GameCore: Loading modular systems...")

	local modulesLoaded = 0
	local totalModules = 3 -- CropCreation, CropVisual, FarmPlot

	-- Load CropVisual module first (no dependencies)
	local cropVisualSuccess, cropVisualResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("Modules"):WaitForChild("CropVisual", 10)
		if not moduleScript then
			error("CropVisual module not found in ServerScriptService/Modules")
		end
		return require(moduleScript)
	end)

	if cropVisualSuccess and cropVisualResult then
		CropVisual = cropVisualResult
		local initSuccess = CropVisual:Initialize(self, nil) -- CropCreation will be injected later
		if initSuccess then
			print("GameCore: ✅ CropVisual module loaded and initialized")
			modulesLoaded = modulesLoaded + 1
		else
			warn("GameCore: ❌ CropVisual initialization failed")
		end
	else
		warn("GameCore: ❌ Failed to load CropVisual: " .. tostring(cropVisualResult))
	end

	-- Load FarmPlot module (depends on GameCore only)
	local farmPlotSuccess, farmPlotResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("Modules"):WaitForChild("FarmPlot", 10)
		if not moduleScript then
			error("FarmPlot module not found in ServerScriptService/Modules")
		end
		return require(moduleScript)
	end)

	if farmPlotSuccess and farmPlotResult then
		FarmPlot = farmPlotResult
		local initSuccess = FarmPlot:Initialize(self)
		if initSuccess then
			print("GameCore: ✅ FarmPlot module loaded and initialized")
			modulesLoaded = modulesLoaded + 1
		else
			warn("GameCore: ❌ FarmPlot initialization failed")
		end
	else
		warn("GameCore: ❌ Failed to load FarmPlot: " .. tostring(farmPlotResult))
	end

	-- Load CropCreation module (depends on GameCore, CropVisual, and optionally MutationSystem)
	local cropCreationSuccess, cropCreationResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("Modules"):WaitForChild("CropCreation", 10)
		if not moduleScript then
			error("CropCreation module not found in ServerScriptService/Modules")
		end
		return require(moduleScript)
	end)

	if cropCreationSuccess and cropCreationResult then
		CropCreation = cropCreationResult

		-- Try to load MutationSystem if available
		local mutationSystem = self:LoadOptionalMutationSystem()

		local initSuccess = CropCreation:Initialize(self, CropVisual, mutationSystem)
		if initSuccess then
			print("GameCore: ✅ CropCreation module loaded and initialized")
			modulesLoaded = modulesLoaded + 1

			-- Update CropVisual with CropCreation reference
			if CropVisual then
				CropVisual.CropCreation = CropCreation
			end
		else
			warn("GameCore: ❌ CropCreation initialization failed")
		end
	else
		warn("GameCore: ❌ Failed to load CropCreation: " .. tostring(cropCreationResult))
	end

	-- Load optional cow modules
	self:LoadOptionalCowModules()

	print("GameCore: Module loading complete - " .. modulesLoaded .. "/" .. totalModules .. " core modules loaded")
	return modulesLoaded >= 2 -- At least CropVisual and FarmPlot required
end

function GameCore:LoadOptionalMutationSystem()
	print("GameCore: Attempting to load MutationSystem...")

	local success, result = pcall(function()
		local moduleScript = ServerScriptService:FindFirstChild("MutationSystem")
		if moduleScript then
			local mutationSystem = require(moduleScript)
			if mutationSystem.Initialize then
				local initSuccess = mutationSystem:Initialize(self, CropVisual)
				if initSuccess then
					return mutationSystem
				end
			end
		end
		return nil
	end)

	if success and result then
		MutationSystem = result
		print("GameCore: ✅ MutationSystem loaded successfully")
		return result
	else
		print("GameCore: ℹ️ MutationSystem not available (optional)")
		return nil
	end
end

function GameCore:LoadOptionalCowModules()
	print("GameCore: Loading optional cow management modules...")

	local success = true

	-- Load CowCreationModule
	local cowCreationSuccess, cowCreationResult = pcall(function()
		local moduleScript = ServerScriptService:FindFirstChild("CowCreationModule")
		if moduleScript then
			return require(moduleScript)
		end
		return nil
	end)

	if cowCreationSuccess and cowCreationResult then
		CowCreationModule = cowCreationResult
		if CowCreationModule.Initialize then
			local initSuccess = CowCreationModule:Initialize(self, ItemConfig)
			if initSuccess then
				print("GameCore: ✅ CowCreationModule loaded successfully")
			else
				warn("GameCore: ❌ CowCreationModule initialization failed")
				success = false
			end
		end
	else
		print("GameCore: ℹ️ CowCreationModule not available (optional)")
	end

	-- Load CowMilkingModule
	local cowMilkingSuccess, cowMilkingResult = pcall(function()
		local moduleScript = ServerScriptService:FindFirstChild("CowMilkingModule")
		if moduleScript then
			return require(moduleScript)
		end
		return nil
	end)

	if cowMilkingSuccess and cowMilkingResult then
		CowMilkingModule = cowMilkingResult
		if CowMilkingModule.Initialize then
			local initSuccess = CowMilkingModule:Initialize(self, CowCreationModule)
			if initSuccess then
				print("GameCore: ✅ CowMilkingModule loaded successfully")
			else
				warn("GameCore: ❌ CowMilkingModule initialization failed")
				success = false
			end
		end
	else
		print("GameCore: ℹ️ CowMilkingModule not available (optional)")
	end

	return success
end

-- ========== INITIALIZATION ==========

function GameCore:Initialize(shopSystem)
	print("GameCore: Starting MODULAR core game system initialization...")

	-- STEP 1: Load all modules first
	local modulesSuccess = self:LoadModules()
	if not modulesSuccess then
		warn("GameCore: Critical modules failed to load!")
		return false
	end

	-- STEP 2: Store ShopSystem reference
	if shopSystem then
		self.ShopSystem = shopSystem
		print("GameCore: ShopSystem reference established")
	end

	-- STEP 3: Initialize player data storage
	self:InitializeDataStore()

	-- STEP 4: Setup DataStore
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore("LivestockFarmData_v2")
	end)

	if success then
		self.PlayerDataStore = dataStore
		print("GameCore: DataStore connected")
	else
		warn("GameCore: Failed to connect to DataStore - running in local mode")
	end

	-- STEP 5: Setup remote connections
	self:SetupRemoteConnections()

	-- STEP 6: Setup event handlers
	self:SetupEventHandlers()

	-- STEP 7: Initialize game systems
	self:InitializeGameSystems()

	-- STEP 8: Setup debug commands
	self:AddDebugCommands()
	self:SetupAdminCommands()

	print("GameCore: ✅ MODULAR core game system initialization complete!")
	return true
end

function GameCore:InitializeGameSystems()
	print("GameCore: Initializing game systems...")

	-- Initialize crop event system for module communication
	self:InitializeCropEventSystem()

	-- Initialize player connection handlers
	self:SetupPlayerHandlers()

	print("GameCore: Game systems initialized")
end

function GameCore:InitializeCropEventSystem()
	print("GameCore: Initializing crop event system for module communication...")

	if not self.Events then
		self.Events = {}
	end

	-- Create bindable events for module communication
	self.Events.CropPlanted = Instance.new("BindableEvent")
	self.Events.CropGrowthStageChanged = Instance.new("BindableEvent")
	self.Events.CropHarvested = Instance.new("BindableEvent")

	print("GameCore: Crop event system initialized")
end

function GameCore:SetupPlayerHandlers()
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
		self:CreatePlayerLeaderstats(player)

		-- Ensure player has farm if they should
		spawn(function()
			wait(2) -- Wait for data to settle
			self:EnsurePlayerHasFarm(player)
		end)
	end)

	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		if self.PlayerData[player.UserId] then
			print("GameCore: Player " .. player.Name .. " leaving - forcing immediate save")
			self:SavePlayerData(player, true)
		end

		-- Clean up tracking data
		local userId = player.UserId
		self.DirtyPlayers[userId] = nil
		self.PendingSaves[userId] = nil
	end)
end

-- ========== MODULE INTEGRATION METHODS ==========

function GameCore:PlantSeed(player, plotModel, seedId, seedData)
	if CropCreation then
		return CropCreation:PlantSeed(player, plotModel, seedId, seedData)
	else
		warn("GameCore: CropCreation module not available")
		return false
	end
end

function GameCore:HarvestCrop(player, plotModel)
	if CropCreation then
		return CropCreation:HarvestCrop(player, plotModel)
	else
		warn("GameCore: CropCreation module not available")
		return false
	end
end

function GameCore:HarvestAllCrops(player)
	if CropCreation then
		return CropCreation:HarvestAllCrops(player)
	else
		warn("GameCore: CropCreation module not available")
		return false
	end
end

function GameCore:CreateSimpleFarmPlot(player)
	if FarmPlot then
		return FarmPlot:CreateSimpleFarmPlot(player)
	else
		warn("GameCore: FarmPlot module not available")
		return false
	end
end

function GameCore:CreateExpandableFarmPlot(player, level)
	if FarmPlot then
		return FarmPlot:CreateExpandableFarmPlot(player, level)
	else
		warn("GameCore: FarmPlot module not available")
		return false
	end
end

function GameCore:GetPlayerSimpleFarm(player)
	if FarmPlot then
		local farm, farmType = FarmPlot:GetPlayerFarm(player)
		return farm
	else
		warn("GameCore: FarmPlot module not available")
		return nil
	end
end

function GameCore:GetPlayerExpandableFarm(player)
	if FarmPlot then
		local farm, farmType = FarmPlot:GetPlayerFarm(player)
		if farmType == "expandable" then
			return farm
		end
	end
	return nil
end

function GameCore:FindPlotByName(player, plotName)
	if FarmPlot then
		return FarmPlot:FindPlotByName(player, plotName)
	else
		warn("GameCore: FarmPlot module not available")
		return nil
	end
end

function GameCore:GetPlotOwner(plotModel)
	if FarmPlot then
		return FarmPlot:GetPlotOwner(plotModel)
	else
		warn("GameCore: FarmPlot module not available")
		return nil
	end
end

function GameCore:EnsurePlayerHasFarm(player)
	if FarmPlot then
		return FarmPlot:EnsurePlayerHasFarm(player)
	else
		warn("GameCore: FarmPlot module not available")
		return false
	end
end

function GameCore:IsPlotActuallyEmpty(plotModel)
	if CropCreation then
		return CropCreation:IsPlotEmpty(plotModel)
	else
		-- Fallback implementation
		for _, child in pairs(plotModel:GetChildren()) do
			if child:IsA("Model") and child.Name == "CropModel" then
				return false
			end
		end
		return plotModel:GetAttribute("IsEmpty") ~= false
	end
end

function GameCore:ClearPlotProperly(plotModel)
	if CropCreation then
		return CropCreation:ClearPlot(plotModel)
	else
		-- Fallback implementation
		for _, child in pairs(plotModel:GetChildren()) do
			if child:IsA("Model") and child.Name == "CropModel" then
				child:Destroy()
			end
		end

		plotModel:SetAttribute("IsEmpty", true)
		plotModel:SetAttribute("PlantType", "")
		plotModel:SetAttribute("SeedType", "")
		plotModel:SetAttribute("GrowthStage", 0)
		plotModel:SetAttribute("PlantedTime", 0)
		plotModel:SetAttribute("Rarity", "common")

		return true
	end
end

-- ========== COW SYSTEM INTEGRATION ==========

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

-- ========== MUTATION SYSTEM INTEGRATION ==========

function GameCore:ProcessPotentialMutations(player, plotModel)
	if MutationSystem then
		return MutationSystem:ProcessPotentialMutations(player, plotModel)
	else
		-- Return no mutation
		return {mutated = false}
	end
end

function GameCore:CheckForImmediateMutation(player, plotModel, cropType)
	if MutationSystem then
		return MutationSystem:CheckForImmediateMutation(player, plotModel, cropType)
	else
		return false
	end
end

function GameCore:GetAdjacentPlots(player, centerPlot)
	if FarmPlot then
		-- This would need to be implemented in FarmPlot module
		-- For now, return empty array
		return {}
	else
		return {}
	end
end

-- ========== REMOTE EVENT SETUP ==========

function GameCore:SetupRemoteConnections()
	print("GameCore: Setting up modular remote connections...")

	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remotes then
		error("GameCore: GameRemotes folder not found after 10 seconds!")
	end

	self.RemoteEvents = {}
	self.RemoteFunctions = {}

	-- Core remote events
	local coreRemoteEvents = {
		"CollectMilk", "PlayerDataUpdated", "ShowNotification",
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		"PurchaseItem", "ItemPurchased", "SellItem", "ItemSold", "CurrencyUpdated",
		"OpenShop", "CloseShop"
	}

	-- Core remote functions
	local coreRemoteFunctions = {
		"GetPlayerData", "GetFarmingData",
		"GetShopItems", "GetShopItemsByCategory", "GetSellableItems"
	}

	-- Load/create remote events
	for _, eventName in ipairs(coreRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if remote and remote:IsA("RemoteEvent") then
			self.RemoteEvents[eventName] = remote
			print("GameCore: ✅ Connected RemoteEvent: " .. eventName)
		else
			local newRemote = Instance.new("RemoteEvent")
			newRemote.Name = eventName
			newRemote.Parent = remotes
			self.RemoteEvents[eventName] = newRemote
			print("GameCore: 📦 Created RemoteEvent: " .. eventName)
		end
	end

	-- Load/create remote functions
	for _, funcName in ipairs(coreRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if remote and remote:IsA("RemoteFunction") then
			self.RemoteFunctions[funcName] = remote
			print("GameCore: ✅ Connected RemoteFunction: " .. funcName)
		else
			local newRemote = Instance.new("RemoteFunction")
			newRemote.Name = funcName
			newRemote.Parent = remotes
			self.RemoteFunctions[funcName] = newRemote
			print("GameCore: 📦 Created RemoteFunction: " .. funcName)
		end
	end

	print("GameCore: Modular remote connections established")
end

function GameCore:SetupEventHandlers()
	print("GameCore: Setting up modular event handlers...")

	-- Farming System Events - delegate to modules
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			pcall(function()
				self:PlantSeed(player, plotModel, seedId)
			end)
		end)
		print("✅ Connected modular PlantSeed handler")
	end

	if self.RemoteEvents.HarvestCrop then
		self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotModel)
			pcall(function()
				self:HarvestCrop(player, plotModel)
			end)
		end)
		print("✅ Connected modular HarvestCrop handler")
	end

	if self.RemoteEvents.HarvestAllCrops then
		self.RemoteEvents.HarvestAllCrops.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HarvestAllCrops(player)
			end)
		end)
		print("✅ Connected modular HarvestAllCrops handler")
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

	print("GameCore: Modular event handlers setup complete!")
end

-- ========== FARM PLOT PURCHASE PROCESSING ==========

function GameCore:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	print("🌾 GameCore: Modular ProcessFarmPlotPurchase for " .. player.Name)

	-- Handle farm plot starter (first-time farm creation)
	if item.id == "farm_plot_starter" then
		print("🌾 Processing farm plot starter")

		-- Initialize farming data
		if not playerData.farming then
			playerData.farming = {
				plots = 1,
				inventory = {
					carrot_seeds = 5,
					corn_seeds = 3
				}
			}
		else
			playerData.farming.plots = (playerData.farming.plots or 0) + quantity
		end

		-- Create the physical farm plot using modular system
		local success = self:CreateSimpleFarmPlot(player)
		if not success then
			if playerData.farming.plots then
				playerData.farming.plots = playerData.farming.plots - quantity
			end
			return false
		end

		print("🌾 Created modular farm plot for " .. player.Name)
		return true
	end

	-- Handle farm expansions
	if item.id:find("farm_expansion") then
		local expansionLevel = tonumber(item.id:match("farm_expansion_(%d+)"))
		if expansionLevel and FarmPlot then
			print("🌾 Processing farm expansion to level " .. expansionLevel)

			playerData.farming = playerData.farming or {plots = 0, inventory = {}}
			playerData.farming.expansionLevel = expansionLevel

			local success = FarmPlot:ExpandFarm(player, expansionLevel)
			if not success then
				return false
			end

			print("🌾 Expanded farm to level " .. expansionLevel .. " for " .. player.Name)
			return true
		end
	end

	-- Regular farm plot purchase (fallback)
	if not playerData.farming then
		playerData.farming = {plots = 0, inventory = {}}
	end

	playerData.farming.plots = (playerData.farming.plots or 0) + quantity

	local success = self:CreateSimpleFarmPlot(player)
	if not success then
		playerData.farming.plots = playerData.farming.plots - quantity
		return false
	end

	print("🌾 Added " .. quantity .. " farm plot(s), total: " .. playerData.farming.plots)
	return true
end

-- ========== NOTIFICATION SYSTEM ==========

function GameCore:SendNotification(player, title, message, type)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, type)
	else
		print("[" .. title .. "] " .. message .. " (to " .. player.Name .. ")")
	end
end

-- ========== DEBUG COMMANDS ==========

function GameCore:AddDebugCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/debugmodules" then
					print("=== MODULE STATUS DEBUG ===")
					print("CropCreation: " .. (CropCreation and "✅ LOADED" or "❌ NOT LOADED"))
					print("CropVisual: " .. (CropVisual and "✅ LOADED" or "❌ NOT LOADED"))
					print("FarmPlot: " .. (FarmPlot and "✅ LOADED" or "❌ NOT LOADED"))
					print("MutationSystem: " .. (MutationSystem and "✅ LOADED" or "ℹ️ OPTIONAL"))
					print("CowCreationModule: " .. (CowCreationModule and "✅ LOADED" or "ℹ️ OPTIONAL"))
					print("CowMilkingModule: " .. (CowMilkingModule and "✅ LOADED" or "ℹ️ OPTIONAL"))
					print("============================")

				elseif command == "/testplanting" then
					print("Testing modular planting system...")
					local playerData = self:GetPlayerData(player)

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
					print("Now click on an unlocked plot to test modular planting")

				elseif command == "/testfarm" then
					print("Testing modular farm creation...")
					local success = self:CreateSimpleFarmPlot(player)
					if success then
						print("✅ Modular farm created successfully")
					else
						print("❌ Modular farm creation failed")
					end

				elseif command == "/farmstats" then
					if FarmPlot then
						local stats = FarmPlot:GetPlayerFarmStatistics(player)
						print("=== FARM STATISTICS ===")
						print("Farm exists: " .. tostring(stats.exists))
						print("Farm type: " .. tostring(stats.type))
						print("Total spots: " .. tostring(stats.totalSpots))
						print("Unlocked spots: " .. tostring(stats.unlockedSpots))
						print("Occupied spots: " .. tostring(stats.occupiedSpots))
						print("Empty spots: " .. tostring(stats.emptySpots))
						if stats.error then
							print("Error: " .. stats.error)
						end
						print("========================")
					else
						print("❌ FarmPlot module not available")
					end

				elseif command == "/reloadmodules" then
					print("Reloading modular systems...")
					local success = self:LoadModules()
					if success then
						print("✅ Modules reloaded successfully")
					else
						print("❌ Module reload failed")
					end
				end
			end
		end)
	end)
end

function GameCore:SetupAdminCommands()
	-- Add more admin commands here if needed
	print("GameCore: Admin commands ready")
end

-- ========== DATA MANAGEMENT (Existing methods kept for compatibility) ==========

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
		boosters = {},
		stats = {
			coinsEarned = 100,
			cropsHarvested = 0,
			rareCropsHarvested = 0,
			seedsPlanted = 0,
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
	local loadedData = defaultData

	if self.PlayerDataStore then
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
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

function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local currentTime = os.time()

	local playerData = self.PlayerData[userId]
	if not playerData then 
		warn("GameCore: No player data to save for " .. player.Name)
		return 
	end

	if forceImmediate then
		return self:PerformImmediateSave(player, playerData)
	end

	local lastSave = self.DataStoreCooldowns[userId] or 0
	if currentTime - lastSave < self.SAVE_COOLDOWN then
		self:MarkPlayerForDelayedSave(userId)
		return
	end

	self:ScheduleBatchedSave(userId)
end

function GameCore:MarkPlayerForDelayedSave(userId)
	self.DirtyPlayers[userId] = os.time()

	if not self.PendingSaves[userId] then
		self.PendingSaves[userId] = true

		spawn(function()
			wait(self.BATCH_SAVE_DELAY)

			if self.DirtyPlayers[userId] and Players:GetPlayerByUserId(userId) then
				self:PerformBatchedSave(userId)
			end

			self.PendingSaves[userId] = nil
		end)
	end
end

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

function GameCore:PerformBatchedSave(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player or not player.Parent then 
		self.DirtyPlayers[userId] = nil
		return 
	end

	local currentTime = os.time()
	local lastSave = self.DataStoreCooldowns[userId] or 0

	if currentTime - lastSave < self.SAVE_COOLDOWN then
		return
	end

	local playerData = self.PlayerData[userId]
	if not playerData then 
		self.DirtyPlayers[userId] = nil
		return 
	end

	local success = self:PerformActualSave(player, playerData, "batched")

	if success then
		self.DataStoreCooldowns[userId] = currentTime
		self.DirtyPlayers[userId] = nil
	end
end

function GameCore:PerformImmediateSave(player, playerData)
	print("GameCore: Performing immediate save for " .. player.Name)

	local success = self:PerformActualSave(player, playerData, "immediate")

	if success then
		local userId = player.UserId
		self.DataStoreCooldowns[userId] = os.time()
		self.DirtyPlayers[userId] = nil
	end

	return success
end

function GameCore:PerformActualSave(player, playerData, saveType)
	local userId = player.UserId

	if not self.PlayerDataStore then
		warn("GameCore: DataStore not available - cannot save data for " .. player.Name)
		return false
	end

	local safeData = self:CreateSafeDataForSaving(playerData)
	safeData.lastSave = os.time()
	safeData.saveType = saveType or "unknown"
	safeData.saveVersion = "2.0_modular"

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
				retryDelay = retryDelay * 2
			end
		end
	end

	return false
end

function GameCore:CreateSafeDataForSaving(playerData)
	return {
		coins = tonumber(playerData.coins) or 0,
		farmTokens = tonumber(playerData.farmTokens) or 0,
		farming = {
			plots = tonumber(playerData.farming and playerData.farming.plots) or 0,
			expansionLevel = tonumber(playerData.farming and playerData.farming.expansionLevel) or 1,
			inventory = self:SanitizeInventory(playerData.farming and playerData.farming.inventory or {})
		},
		stats = self:SanitizeStats(playerData.stats or {}),
		purchaseHistory = self:SanitizePurchaseHistory(playerData.purchaseHistory or {}),
		lastSave = os.time()
	}
end

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

-- ========== UTILITY FUNCTIONS ==========

function GameCore:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- Make globally available
_G.GameCore = GameCore

print("GameCore: ✅ MODULAR SYSTEM LOADED!")
print("🔧 MODULAR ARCHITECTURE:")
print("  📦 CropCreation - Handles planting, growth, and harvest logic")
print("  🎨 CropVisual - Handles visual effects and crop models")
print("  🌾 FarmPlot - Handles farm creation and plot management")
print("  🧬 MutationSystem - Optional mutation system integration")
print("  🐄 CowModules - Optional cow management integration")
print("")
print("✅ BENEFITS:")
print("  🔧 Clean separation of concerns")
print("  📈 Easy to extend and maintain")
print("  🐛 Better error isolation")
print("  🔄 Module hot-swapping capability")
print("  📊 Improved performance and organization")

return GameCore