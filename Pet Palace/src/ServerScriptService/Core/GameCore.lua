--[[
    UPDATED GameCore.lua - With FarmPlot Module Integration
    Place in: ServerScriptService/Core/GameCore.lua
    
    UPDATES:
    ✅ Added FarmPlot module loading from Modules folder
    ✅ Added farm plot integration methods
    ✅ Fixed module loading paths for all modules
]]

local GameCore = {}

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Load configuration
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- UPDATED: Module references - will be loaded from correct locations
local CropCreation = nil
local CropVisual = nil  
local FarmPlot = nil -- Added FarmPlot
local MutationSystem = nil
local CowCreationModule = nil
local CowMilkingModule = nil

-- Core state
GameCore.PlayerData = {}
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}
GameCore.SAVE_COOLDOWN = 30

-- ========== UPDATED MODULE LOADING ==========

function GameCore:LoadModules()
	print("GameCore: Loading modules from correct paths...")

	local modulesLoaded = 0

	-- Load cow modules from root ServerScriptService
	local cowCreationSuccess, cowCreationResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("CowCreationModule", 10)
		if not moduleScript then
			warn("CowCreationModule not found in ServerScriptService")
			return nil
		end
		return require(moduleScript)
	end)

	if cowCreationSuccess and cowCreationResult then
		CowCreationModule = cowCreationResult
		print("GameCore: ✅ CowCreationModule loaded from ServerScriptService")
		modulesLoaded = modulesLoaded + 1
	else
		warn("GameCore: ❌ Failed to load CowCreationModule: " .. tostring(cowCreationResult))
	end

	local cowMilkingSuccess, cowMilkingResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("CowMilkingModule", 10)
		if not moduleScript then
			warn("CowMilkingModule not found in ServerScriptService")
			return nil
		end
		return require(moduleScript)
	end)

	if cowMilkingSuccess and cowMilkingResult then
		CowMilkingModule = cowMilkingResult
		print("GameCore: ✅ CowMilkingModule loaded from ServerScriptService")
		modulesLoaded = modulesLoaded + 1
	else
		warn("GameCore: ❌ Failed to load CowMilkingModule: " .. tostring(cowMilkingResult))
	end

	-- ADDED: Load modules from Modules folder if it exists
	local modulesFolder = ServerScriptService:FindFirstChild("Modules")
	if modulesFolder then
		print("GameCore: Found Modules folder, loading farming modules...")

		-- Load FarmPlot module
		local farmPlotModule = modulesFolder:FindFirstChild("FarmPlot")
		if farmPlotModule then
			local success, result = pcall(function()
				return require(farmPlotModule)
			end)
			if success then
				FarmPlot = result
				print("GameCore: ✅ FarmPlot loaded from Modules folder")
				modulesLoaded = modulesLoaded + 1
			else
				warn("GameCore: ❌ Failed to load FarmPlot: " .. tostring(result))
			end
		else
			print("GameCore: FarmPlot module not found in Modules folder")
		end

		-- Load CropCreation if available
		local cropCreationModule = modulesFolder:FindFirstChild("CropCreation")
		if cropCreationModule then
			local success, result = pcall(function()
				return require(cropCreationModule)
			end)
			if success then
				CropCreation = result
				print("GameCore: ✅ CropCreation loaded from Modules folder")
				modulesLoaded = modulesLoaded + 1
			end
		end

		-- Load CropVisual if available
		local cropVisualModule = modulesFolder:FindFirstChild("CropVisual")
		if cropVisualModule then
			local success, result = pcall(function()
				return require(cropVisualModule)
			end)
			if success then
				CropVisual = result
				print("GameCore: ✅ CropVisual loaded from Modules folder")
				modulesLoaded = modulesLoaded + 1
			end
		end
	else
		print("GameCore: No Modules folder found, using available modules only")
	end

	print("GameCore: Module loading complete - " .. modulesLoaded .. " modules loaded")
	return modulesLoaded >= 1 -- At least one module required
end

function GameCore:InitializeLoadedModules()
	print("GameCore: Initializing loaded modules...")

	-- Initialize FarmPlot first (needed by other modules)
	if FarmPlot then
		print("GameCore: Initializing FarmPlot...")
		local success = pcall(function()
			return FarmPlot:Initialize(self)
		end)

		if success then
			print("GameCore: ✅ FarmPlot initialized")
			_G.FarmPlot = FarmPlot
		else
			warn("GameCore: ❌ FarmPlot initialization failed")
		end
	end

	-- Initialize CowCreationModule
	if CowCreationModule then
		print("GameCore: Initializing CowCreationModule...")
		local success = pcall(function()
			return CowCreationModule:Initialize(self, ItemConfig)
		end)

		if success then
			print("GameCore: ✅ CowCreationModule initialized")
			_G.CowCreationModule = CowCreationModule
		else
			warn("GameCore: ❌ CowCreationModule initialization failed")
		end
	end

	-- Initialize CowMilkingModule
	if CowMilkingModule then
		print("GameCore: Initializing CowMilkingModule...")
		local success = pcall(function()
			return CowMilkingModule:Initialize(self, CowCreationModule)
		end)

		if success then
			print("GameCore: ✅ CowMilkingModule initialized")
			_G.CowMilkingModule = CowMilkingModule
		else
			warn("GameCore: ❌ CowMilkingModule initialization failed")
		end
	end

	-- Initialize crop modules if available
	if CropCreation then
		local success = pcall(function()
			return CropCreation:Initialize(self, CropVisual, MutationSystem)
		end)
		if success then
			print("GameCore: ✅ CropCreation initialized")
		end
	end

	if CropVisual then
		local success = pcall(function()
			return CropVisual:Initialize(self, CropCreation)
		end)
		if success then
			print("GameCore: ✅ CropVisual initialized")
		end
	end
end

-- ========== ADDED: FARM PLOT INTEGRATION METHODS ==========

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

function GameCore:GetSimpleFarmPosition(player)
	if FarmPlot then
		return FarmPlot:GetSimpleFarmPosition(player)
	else
		warn("GameCore: FarmPlot module not available - using fallback position")
		-- Fallback position calculation
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

		local basePos = Vector3.new(-366.118, -2.793, 75.731)
		local playerOffset = Vector3.new(150, 0, 0) * playerIndex
		local finalPosition = basePos + playerOffset

		return CFrame.new(finalPosition)
	end
end

-- ========== CROP SYSTEM INTEGRATION ==========

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

-- ========== EXISTING METHODS (keeping the rest of the previous code) ==========

function GameCore:Initialize(shopSystem)
	print("GameCore: Starting UPDATED core initialization...")

	-- Initialize data store first
	self:InitializeDataStore()

	-- Load modules with correct paths
	local modulesSuccess = self:LoadModules()
	if not modulesSuccess then
		warn("GameCore: No modules loaded, but continuing with basic functionality")
	end

	-- Store ShopSystem reference if provided
	if shopSystem then
		self.ShopSystem = shopSystem
		print("GameCore: ShopSystem reference established")
	end

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Initialize modules in correct order
	self:InitializeLoadedModules()

	-- Setup event handlers
	self:SetupEventHandlers()

	-- Setup player handlers
	self:SetupPlayerHandlers()

	print("GameCore: ✅ UPDATED core initialization complete!")
	return true
end

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
				return nil
			end,
			SetAsync = function(self, key, data)
				print("GameCore: Mock DataStore save for " .. key .. " (Studio mode)")
				return true
			end
		}
		warn("GameCore: Using mock DataStore for Studio testing")
	end
end

-- ========== REMOTE EVENT SETUP ==========

-- REPLACE the SetupRemoteConnections method in your GameCore.lua with this fixed version:

function GameCore:SetupRemoteConnections()
	print("GameCore: Setting up remote connections...")

	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "GameRemotes"
		remotes.Parent = ReplicatedStorage
		print("GameCore: Created GameRemotes folder")
	end

	self.RemoteEvents = {}
	self.RemoteFunctions = {}

	-- FIXED: Removed shop events - let ShopSystem handle these
	local requiredRemoteEvents = {
		-- Core events
		"PlayerDataUpdated", "ShowNotification",
		-- Farm events
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		-- Cow milking events
		"ShowChairPrompt", "HideChairPrompt", 
		"StartMilkingSession", "StopMilkingSession", 
		"ContinueMilking", "MilkingSessionUpdate",
		-- Proximity events
		"OpenShop", "CloseShop"
		-- REMOVED: Shop purchase events (handled by ShopSystem)
	}

	-- FIXED: Removed shop functions - let ShopSystem handle these
	local requiredRemoteFunctions = {
		-- Core functions
		"GetPlayerData", "GetFarmingData"
		-- REMOVED: Shop functions (handled by ShopSystem)
	}

	-- Create/connect remote events
	for _, eventName in ipairs(requiredRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = remotes
			print("GameCore: Created RemoteEvent: " .. eventName)
		end
		self.RemoteEvents[eventName] = remote
	end

	-- Create/connect remote functions
	for _, funcName in ipairs(requiredRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if not remote then
			remote = Instance.new("RemoteFunction")
			remote.Name = funcName
			remote.Parent = remotes
			print("GameCore: Created RemoteFunction: " .. funcName)
		end
		self.RemoteFunctions[funcName] = remote
	end

	print("GameCore: ✅ Remote connections established (shop events handled by ShopSystem)")
	print("  RemoteEvents: " .. #requiredRemoteEvents)
	print("  RemoteFunctions: " .. #requiredRemoteFunctions)
end

function GameCore:SetupEventHandlers()
	print("GameCore: Setting up event handlers...")

	-- Core remote function handlers
	if self.RemoteFunctions.GetPlayerData then
		self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
			return self:GetPlayerData(player)
		end
	end

	if self.RemoteFunctions.GetFarmingData then
		self.RemoteFunctions.GetFarmingData.OnServerInvoke = function(player)
			local playerData = self:GetPlayerData(player)
			return playerData and playerData.farming or {}
		end
	end

	-- Farm system event handlers (delegate to modules)
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

	-- Cow milking event handlers (delegate to modules)
	if self.RemoteEvents.StartMilkingSession then
		self.RemoteEvents.StartMilkingSession.OnServerEvent:Connect(function(player, cowId)
			if CowMilkingModule and CowMilkingModule.HandleStartMilkingSession then
				CowMilkingModule:HandleStartMilkingSession(player, cowId)
			end
		end)
	end

	if self.RemoteEvents.StopMilkingSession then
		self.RemoteEvents.StopMilkingSession.OnServerEvent:Connect(function(player)
			if CowMilkingModule and CowMilkingModule.HandleStopMilkingSession then
				CowMilkingModule:HandleStopMilkingSession(player)
			end
		end)
	end

	if self.RemoteEvents.ContinueMilking then
		self.RemoteEvents.ContinueMilking.OnServerEvent:Connect(function(player)
			if CowMilkingModule and CowMilkingModule.HandleContinueMilking then
				CowMilkingModule:HandleContinueMilking(player)
			end
		end)
	end

	print("GameCore: ✅ Event handlers setup complete")
end

-- ========== FARM PLOT PURCHASE PROCESSING ==========

function GameCore:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	print("🌾 GameCore: Processing farm plot purchase for " .. player.Name)

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

		print("🌾 Created simple farm plot for " .. player.Name)
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

-- ========== PLAYER MANAGEMENT ==========

function GameCore:SetupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
		self:CreatePlayerLeaderstats(player)

		-- Ensure player has farm if they should
		spawn(function()
			wait(2) -- Wait for data to settle
			self:EnsurePlayerHasFarm(player)
		end)

		-- Give starter cow after delay if cow system available
		if CowCreationModule then
			spawn(function()
				wait(5)
				pcall(function()
					CowCreationModule:GiveStarterCow(player)
				end)
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if self.PlayerData[player.UserId] then
			self:SavePlayerData(player, true)
		end
	end)

	-- Handle server shutdown
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			if self.PlayerData[player.UserId] then
				pcall(function()
					self:SavePlayerData(player, true)
				end)
			end
		end
		wait(2)
	end)
end

-- ========== COW SYSTEM INTEGRATION ==========

function GameCore:HandleCowMilkCollection(player, cowId)
	if CowMilkingModule then
		return CowMilkingModule:HandleCowMilkCollection(player, cowId)
	end
	return false
end

function GameCore:CreateNewCowSafely(player, cowType, cowConfig)
	if CowCreationModule then
		return CowCreationModule:CreateNewCow(player, cowType, cowConfig)
	end
	return false
end

-- ========== DATA MANAGEMENT ==========

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
			cows = {}
		},
		stats = {
			coinsEarned = 100,
			cropsHarvested = 0,
			milkCollected = 0
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
			print("GameCore: Loaded data for " .. player.Name)
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

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	if self.PlayerDataStore then
		local success, error = pcall(function()
			return self.PlayerDataStore:SetAsync("Player_" .. player.UserId, playerData)
		end)

		if success then
			print("GameCore: Saved data for " .. player.Name)
		else
			warn("GameCore: Failed to save data for " .. player.Name .. ": " .. tostring(error))
		end
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
end

function GameCore:SendNotification(player, title, message, type)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, type)
	end
end

-- ========== DEBUG FUNCTIONS ==========

function GameCore:DebugStatus()
	print("=== UPDATED GAMECORE DEBUG STATUS ===")
	print("Modules loaded:")
	print("  FarmPlot: " .. (FarmPlot and "✅" or "❌"))
	print("  CowCreationModule: " .. (CowCreationModule and "✅" or "❌"))
	print("  CowMilkingModule: " .. (CowMilkingModule and "✅" or "❌"))
	print("  CropCreation: " .. (CropCreation and "✅" or "❌"))
	print("  CropVisual: " .. (CropVisual and "✅" or "❌"))
	print("Players: " .. #Players:GetPlayers())
	print("Data store: " .. (self.PlayerDataStore and "✅" or "❌"))
	print("Remote events: " .. (self.RemoteEvents and #self.RemoteEvents or 0))
	print("==============================")
end

-- Make globally available
_G.GameCore = GameCore

return GameCore