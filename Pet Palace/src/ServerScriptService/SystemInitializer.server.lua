--[[
    ENHANCED SystemInitializer.server.lua - Enhanced Inventory Integration
    Place in: ServerScriptService/SystemInitializer.server.lua
    
    ENHANCEMENTS:
    ✅ Added enhanced inventory system integration
    ✅ Enhanced remote event setup for inventory
    ✅ Updated GameCore initialization with inventory support
    ✅ Added inventory debug commands
    ✅ Better coordination with enhanced systems
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🚀 === Pet Palace ENHANCED System Coordinator Starting ===")

-- Enhanced system state tracking
local SystemState = {
	GameCoreLoaded = false,
	ShopSystemLoaded = false,
	ModulesInitialized = false,
	RemoteEventsReady = false,
	InventorySystemReady = false,
	SystemsConnected = false
}

-- ========== SAFE MODULE LOADING ==========

local function SafeRequire(moduleScript, moduleName)
	if not moduleScript then
		warn("❌ " .. moduleName .. " module script not found")
		return nil
	end

	local success, result = pcall(function()
		return require(moduleScript)
	end)

	if success then
		print("✅ " .. moduleName .. " loaded successfully")
		return result
	else
		warn("❌ " .. moduleName .. " failed to load: " .. tostring(result))
		return nil
	end
end

-- ========== STEP 1: LOAD GAMECORE WITH ENHANCED FEATURES ==========

local function LoadEnhancedGameCore()
	print("🎮 Loading Enhanced GameCore...")

	-- Check if GameCore is already loaded
	if _G.GameCore then
		print("✅ GameCore already loaded globally")
		SystemState.GameCoreLoaded = true
		return _G.GameCore
	end

	-- Load from Core folder
	local coreFolder = ServerScriptService:FindFirstChild("Core")
	if not coreFolder then
		error("❌ Core folder not found in ServerScriptService")
	end

	local gameCoreModule = coreFolder:FindFirstChild("GameCore")
	if not gameCoreModule then
		error("❌ GameCore module not found in Core folder")
	end

	local GameCore = SafeRequire(gameCoreModule, "GameCore")
	if GameCore then
		SystemState.GameCoreLoaded = true
		return GameCore
	else
		error("❌ GameCore failed to load")
	end
end

-- ========== STEP 2: ENHANCED REMOTE EVENT SETUP ==========

local function SetupEnhancedRemoteEvents()
	print("📡 Setting up enhanced remote events with inventory support...")

	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "GameRemotes"
		remotes.Parent = ReplicatedStorage
		print("Created GameRemotes folder")
	end

	-- ENHANCED: Remote events with inventory support
	local enhancedRemoteEvents = {
		-- Core events
		"PlayerDataUpdated", "ShowNotification",
		-- Farm events
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		-- ADDED: Enhanced inventory events
		"InventoryUpdated", "ItemSold", "ItemPurchased",
		-- Shop events
		"PurchaseItem", "SellItem", "OpenShop", "CloseShop",
		-- Cow milking events
		"ShowChairPrompt", "HideChairPrompt", 
		"StartMilkingSession", "StopMilkingSession", 
		"ContinueMilking", "MilkingSessionUpdate"
	}

	-- ENHANCED: Remote functions with inventory support
	local enhancedRemoteFunctions = {
		-- Core functions
		"GetPlayerData", "GetFarmingData",
		-- ADDED: Enhanced inventory functions
		"GetInventoryData", "GetMiningData", "GetCraftingData", "SellInventoryItem",
		-- Shop functions
		"GetShopItems", "GetShopItemsByCategory", 
		"GetShopCategories", "GetSellableItems"
	}

	-- Create remote events
	local eventsCreated = 0
	for _, eventName in ipairs(enhancedRemoteEvents) do
		if not remotes:FindFirstChild(eventName) then
			local newEvent = Instance.new("RemoteEvent")
			newEvent.Name = eventName
			newEvent.Parent = remotes
			eventsCreated = eventsCreated + 1
			print("Created RemoteEvent: " .. eventName)
		else
			print("Found existing RemoteEvent: " .. eventName)
		end
	end

	-- Create remote functions
	local functionsCreated = 0
	for _, funcName in ipairs(enhancedRemoteFunctions) do
		if not remotes:FindFirstChild(funcName) then
			local newFunc = Instance.new("RemoteFunction")
			newFunc.Name = funcName
			newFunc.Parent = remotes
			functionsCreated = functionsCreated + 1
			print("Created RemoteFunction: " .. funcName)
		else
			print("Found existing RemoteFunction: " .. funcName)
		end
	end

	print("📡 Enhanced remote setup complete:")
	print("  Events: " .. #enhancedRemoteEvents .. " (" .. eventsCreated .. " created)")
	print("  Functions: " .. #enhancedRemoteFunctions .. " (" .. functionsCreated .. " created)")

	SystemState.RemoteEventsReady = true
	return true
end

-- ========== STEP 3: INITIALIZE ENHANCED GAMECORE ==========

local function InitializeEnhancedGameCore(GameCore)
	print("🔧 Initializing Enhanced GameCore with inventory support...")

	if not GameCore.Initialize then
		error("❌ GameCore.Initialize method not found")
	end

	-- Initialize GameCore with enhanced features
	local success, result = pcall(function()
		return GameCore:Initialize()
	end)

	if success and result then
		print("✅ Enhanced GameCore initialized successfully")
		_G.GameCore = GameCore  -- Set global reference

		-- ADDED: Setup enhanced inventory handlers
		local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		if remotes and GameCore.RemoteFunctions then

			-- Enhanced inventory remote functions
			if GameCore.RemoteFunctions.GetInventoryData then
				GameCore.RemoteFunctions.GetInventoryData.OnServerInvoke = function(player, inventoryType)
					return GameCore:GetInventoryData(player, inventoryType)
				end
				print("✅ Connected GetInventoryData handler")
			end

			if GameCore.RemoteFunctions.GetMiningData then
				GameCore.RemoteFunctions.GetMiningData.OnServerInvoke = function(player)
					local playerData = GameCore:GetPlayerData(player)
					return playerData and playerData.mining or {
						inventory = {},
						tools = {},
						level = 1
					}
				end
				print("✅ Connected GetMiningData handler")
			end

			if GameCore.RemoteFunctions.GetCraftingData then
				GameCore.RemoteFunctions.GetCraftingData.OnServerInvoke = function(player)
					local playerData = GameCore:GetPlayerData(player)
					return playerData and playerData.crafting or {
						inventory = {},
						recipes = {},
						stations = {}
					}
				end
				print("✅ Connected GetCraftingData handler")
			end

			if GameCore.RemoteFunctions.SellInventoryItem then
				GameCore.RemoteFunctions.SellInventoryItem.OnServerInvoke = function(player, itemId, quantity)
					return GameCore:SellInventoryItem(player, itemId, quantity)
				end
				print("✅ Connected SellInventoryItem handler")
			end

			-- Enhanced inventory events
			if GameCore.RemoteEvents.SellItem then
				GameCore.RemoteEvents.SellItem.OnServerEvent:Connect(function(player, itemId, quantity)
					pcall(function()
						GameCore:SellInventoryItem(player, itemId, quantity or 1)
					end)
				end)
				print("✅ Connected SellItem event handler")
			end
		end

		SystemState.InventorySystemReady = true
		return true
	else
		error("❌ Enhanced GameCore initialization failed: " .. tostring(result))
	end
end

-- ========== STEP 4: LOAD AND INITIALIZE SHOP SYSTEM ==========

local function LoadAndInitializeShopSystem(GameCore)
	print("🛒 Loading and initializing ShopSystem...")

	local ShopSystem = nil
	local systemsFolder = ServerScriptService:FindFirstChild("Systems")
	if systemsFolder then
		local shopSystemModule = systemsFolder:FindFirstChild("ShopSystem")
		if shopSystemModule then
			local shopSuccess, shopResult = pcall(function()
				return require(shopSystemModule)
			end)
			if shopSuccess then
				ShopSystem = shopResult
				print("✅ ShopSystem loaded successfully")
			else
				warn("❌ ShopSystem failed to load: " .. tostring(shopResult))
				return false
			end
		else
			warn("❌ ShopSystem module not found in Systems folder")
			return false
		end
	else
		warn("❌ Systems folder not found")
		return false
	end

	-- Initialize ShopSystem
	if ShopSystem then
		print("🛒 Initializing ShopSystem...")
		local shopInitSuccess, shopInitError = pcall(function()
			return ShopSystem:Initialize(GameCore)
		end)

		if shopInitSuccess then
			print("✅ ShopSystem initialized successfully")
			_G.ShopSystem = ShopSystem

			-- Connect ShopSystem remote handlers
			if GameCore.RemoteFunctions then
				-- Shop data functions
				if GameCore.RemoteFunctions.GetShopItems then
					GameCore.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
						return ShopSystem:HandleGetShopItems(player)
					end
					print("✅ Connected GetShopItems handler")
				end

				if GameCore.RemoteFunctions.GetShopItemsByCategory then
					GameCore.RemoteFunctions.GetShopItemsByCategory.OnServerInvoke = function(player, category)
						return ShopSystem:HandleGetShopItemsByCategory(player, category)
					end
					print("✅ Connected GetShopItemsByCategory handler")
				end

				if GameCore.RemoteFunctions.GetShopCategories then
					GameCore.RemoteFunctions.GetShopCategories.OnServerInvoke = function(player)
						return ShopSystem:HandleGetShopCategories(player)
					end
					print("✅ Connected GetShopCategories handler")
				end

				if GameCore.RemoteFunctions.GetSellableItems then
					GameCore.RemoteFunctions.GetSellableItems.OnServerInvoke = function(player)
						return ShopSystem:HandleGetSellableItems(player)
					end
					print("✅ Connected GetSellableItems handler")
				end
			end

			-- Connect shop events
			if GameCore.RemoteEvents then
				if GameCore.RemoteEvents.PurchaseItem then
					GameCore.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
						ShopSystem:HandlePurchase(player, itemId, quantity or 1)
					end)
					print("✅ Connected PurchaseItem handler")
				end
			end

			SystemState.ShopSystemLoaded = true
			return true
		else
			warn("❌ ShopSystem initialization failed: " .. tostring(shopInitError))
			return false
		end
	end

	return false
end

-- ========== STEP 5: VERIFY MODULES AND SETUP ==========

local function VerifyEnhancedModules()
	print("🔍 Verifying enhanced module availability...")

	local modulesFound = {}
	local modulesAvailable = 0

	-- Check for cow modules
	local cowCreationModule = ServerScriptService:FindFirstChild("CowCreationModule")
	if cowCreationModule then
		modulesFound.CowCreationModule = true
		modulesAvailable = modulesAvailable + 1
		print("✅ CowCreationModule found")
	end

	local cowMilkingModule = ServerScriptService:FindFirstChild("CowMilkingModule")
	if cowMilkingModule then
		modulesFound.CowMilkingModule = true
		modulesAvailable = modulesAvailable + 1
		print("✅ CowMilkingModule found")
	end

	-- Check for crop modules
	local modulesFolder = ServerScriptService:FindFirstChild("Modules")
	if modulesFolder then
		local farmPlot = modulesFolder:FindFirstChild("FarmPlot")
		if farmPlot then
			modulesFound.FarmPlot = true
			modulesAvailable = modulesAvailable + 1
			print("✅ FarmPlot found")
		end

		local cropCreation = modulesFolder:FindFirstChild("CropCreation")
		if cropCreation then
			modulesFound.CropCreation = true
			modulesAvailable = modulesAvailable + 1
			print("✅ CropCreation found")
		end
	end

	print("📦 Total modules available: " .. modulesAvailable)
	SystemState.ModulesInitialized = modulesAvailable > 0
	return modulesFound, modulesAvailable
end

-- ========== STEP 6: WAIT FOR MODULE CONNECTIONS ==========

local function WaitForEnhancedConnections(timeout)
	timeout = timeout or 30
	local startTime = tick()

	print("⏳ Waiting for enhanced modules to connect...")

	while (tick() - startTime) < timeout do
		local cowCreationReady = _G.CowCreationModule ~= nil
		local cowMilkingReady = _G.CowMilkingModule ~= nil
		local farmPlotReady = _G.FarmPlot ~= nil

		if cowCreationReady and cowMilkingReady then
			print("✅ All essential modules connected successfully")
			SystemState.SystemsConnected = true
			return true
		end

		wait(1)
	end

	-- Check what we have after timeout
	local cowCreationReady = _G.CowCreationModule ~= nil
	local cowMilkingReady = _G.CowMilkingModule ~= nil
	local farmPlotReady = _G.FarmPlot ~= nil

	print("⚠️ Connection status after timeout:")
	print("  CowCreationModule: " .. (cowCreationReady and "✅" or "❌"))
	print("  CowMilkingModule: " .. (cowMilkingReady and "✅" or "❌"))
	print("  FarmPlot: " .. (farmPlotReady and "✅" or "❌"))

	if cowCreationReady or cowMilkingReady then
		SystemState.SystemsConnected = true
		return true
	end

	return false
end

-- ========== STEP 7: ENHANCED DEBUG COMMANDS ==========

local function SetupEnhancedDebugCommands()
	print("🔧 Setting up enhanced debug commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/enhancedsystemstatus" then
					print("=== ENHANCED SYSTEM STATUS ===")
					print("GameCore: " .. (SystemState.GameCoreLoaded and "✅" or "❌"))
					print("ShopSystem: " .. (SystemState.ShopSystemLoaded and "✅" or "❌"))
					print("Modules: " .. (SystemState.ModulesInitialized and "✅" or "❌"))
					print("Remote Events: " .. (SystemState.RemoteEventsReady and "✅" or "❌"))
					print("Inventory System: " .. (SystemState.InventorySystemReady and "✅" or "❌"))
					print("Systems Connected: " .. (SystemState.SystemsConnected and "✅" or "❌"))
					print("")
					print("Global references:")
					print("  _G.GameCore: " .. (_G.GameCore and "✅" or "❌"))
					print("  _G.ShopSystem: " .. (_G.ShopSystem and "✅" or "❌"))
					print("  _G.CowCreationModule: " .. (_G.CowCreationModule and "✅" or "❌"))
					print("  _G.CowMilkingModule: " .. (_G.CowMilkingModule and "✅" or "❌"))
					print("  _G.FarmPlot: " .. (_G.FarmPlot and "✅" or "❌"))
					print("")

					-- Enhanced debug info
					if _G.GameCore and _G.GameCore.DebugEnhancedStatus then
						_G.GameCore:DebugEnhancedStatus()
					end
					print("===============================")

				elseif command == "/testinventory" then
					print("🧪 Testing enhanced inventory system...")

					if _G.GameCore then
						-- Add test items to player
						local success1 = _G.GameCore:AddItemToInventory(player, "farming", "carrot_seeds", 5)
						local success2 = _G.GameCore:AddItemToInventory(player, "farming", "carrot", 3)
						local success3 = _G.GameCore:AddOreToInventory(player, "copper_ore", 4)
						local success4 = _G.GameCore:CollectMilk(player, 6)

						print("Inventory test results:")
						print("  Carrot seeds: " .. (success1 and "✅" or "❌"))
						print("  Carrots: " .. (success2 and "✅" or "❌"))
						print("  Copper ore: " .. (success3 and "✅" or "❌"))
						print("  Milk: " .. (success4 and "✅" or "❌"))

						-- Test selling
						wait(1)
						local sellSuccess = _G.GameCore:SellInventoryItem(player, "carrot", 1)
						print("  Sell test: " .. (sellSuccess and "✅" or "❌"))
					else
						print("❌ GameCore not available")
					end

				elseif command == "/testenhancedshop" then
					print("🛒 Testing enhanced shop system...")

					if _G.ShopSystem then
						-- Test shop functions
						local items = _G.ShopSystem:HandleGetShopItems(player)
						print("Shop items available: " .. (items and #items or 0))

						local categories = _G.ShopSystem:HandleGetShopCategories(player)
						print("Shop categories: " .. (categories and #categories or 0))

						local sellableItems = _G.ShopSystem:HandleGetSellableItems(player)
						print("Sellable items: " .. (sellableItems and #sellableItems or 0))
					else
						print("❌ ShopSystem not available")
					end

				elseif command == "/playerinventory" then
					if _G.GameCore then
						local playerData = _G.GameCore:GetPlayerData(player)
						if playerData then
							print("=== " .. player.Name .. "'S INVENTORY ===")
							print("Coins: " .. (playerData.coins or 0))
							print("Farm Tokens: " .. (playerData.farmTokens or 0))
							print("Milk: " .. (playerData.milk or 0))

							if playerData.farming and playerData.farming.inventory then
								print("Farming items:")
								for itemId, quantity in pairs(playerData.farming.inventory) do
									print("  " .. itemId .. ": " .. quantity)
								end
							end

							if playerData.mining and playerData.mining.inventory then
								print("Mining items:")
								for itemId, quantity in pairs(playerData.mining.inventory) do
									print("  " .. itemId .. ": " .. quantity)
								end
							end

							if playerData.crafting and playerData.crafting.inventory then
								print("Crafting items:")
								for itemId, quantity in pairs(playerData.crafting.inventory) do
									print("  " .. itemId .. ": " .. quantity)
								end
							end
							print("===============================")
						else
							print("❌ Player data not found")
						end
					else
						print("❌ GameCore not available")
					end

				elseif command == "/clearinventory" then
					if _G.GameCore then
						local playerData = _G.GameCore:GetPlayerData(player)
						if playerData then
							-- Clear inventories
							if playerData.farming then
								playerData.farming.inventory = {}
							end
							if playerData.mining then
								playerData.mining.inventory = {}
							end
							if playerData.crafting then
								playerData.crafting.inventory = {}
							end
							playerData.milk = 0

							_G.GameCore:UpdatePlayerData(player, playerData)
							print("✅ " .. player.Name .. "'s inventory cleared")
						end
					else
						print("❌ GameCore not available")
					end

					-- Include existing commands
				elseif command == "/systemstatus" then
					print("=== BASIC SYSTEM STATUS ===")
					print("GameCore loaded: " .. (SystemState.GameCoreLoaded and "✅" or "❌"))
					print("Modules initialized: " .. (SystemState.ModulesInitialized and "✅" or "❌"))
					print("Remote events ready: " .. (SystemState.RemoteEventsReady and "✅" or "❌"))
					print("Systems connected: " .. (SystemState.SystemsConnected and "✅" or "❌"))
					print("Active players: " .. #Players:GetPlayers())
					print("============================")

				elseif command == "/testcow" then
					if _G.CowCreationModule and _G.CowCreationModule.GiveStarterCow then
						local success = _G.CowCreationModule:GiveStarterCow(player)
						print("Give cow result: " .. tostring(success))
					else
						print("❌ CowCreationModule not available")
					end

				elseif command == "/testmilking" then
					if _G.CowMilkingModule and _G.CowMilkingModule.DebugStatus then
						_G.CowMilkingModule:DebugStatus()
					else
						print("❌ CowMilkingModule not available")
					end
				end
			end
		end)
	end)

	print("✅ Enhanced debug commands ready")
end

-- ========== MAIN ENHANCED COORDINATION FUNCTION ==========

local function CoordinateEnhancedSystemInitialization()
	print("🎯 Starting enhanced system coordination...")

	local success, errorMessage = pcall(function()
		-- Step 1: Setup enhanced remote events first
		SetupEnhancedRemoteEvents()

		-- Step 2: Load enhanced GameCore
		local GameCore = LoadEnhancedGameCore()

		-- Step 3: Verify modules exist
		local modulesFound, moduleCount = VerifyEnhancedModules()

		-- Step 4: Initialize enhanced GameCore with inventory support
		InitializeEnhancedGameCore(GameCore)

		-- Step 5: Load and initialize ShopSystem
		LoadAndInitializeShopSystem(GameCore)

		-- Step 6: Wait for modules to connect
		WaitForEnhancedConnections(15)

		-- Step 7: Setup enhanced debug commands
		SetupEnhancedDebugCommands()

		return true
	end)

	if success then
		print("🎉 Enhanced system coordination completed successfully!")
		print("")
		print("🔧 ENHANCED COORDINATION RESULTS:")
		print("  🎮 GameCore: " .. (SystemState.GameCoreLoaded and "✅" or "❌"))
		print("  🛒 ShopSystem: " .. (SystemState.ShopSystemLoaded and "✅" or "❌"))
		print("  📦 Modules: " .. (SystemState.ModulesInitialized and "✅" or "❌"))  
		print("  📡 Remote Events: " .. (SystemState.RemoteEventsReady and "✅" or "❌"))
		print("  📦 Inventory System: " .. (SystemState.InventorySystemReady and "✅" or "❌"))
		print("  🔗 Systems Connected: " .. (SystemState.SystemsConnected and "✅" or "❌"))
		print("")
		print("🎮 Enhanced Debug Commands:")
		print("  /enhancedsystemstatus - Show enhanced system status")
		print("  /testinventory - Test enhanced inventory system")
		print("  /testenhancedshop - Test enhanced shop system")
		print("  /playerinventory - Show player's inventory")
		print("  /clearinventory - Clear player's inventory")
		print("  /testcow - Test cow assignment")
		print("  /testmilking - Test milking system")
		return true
	else
		warn("💥 Enhanced system coordination failed: " .. tostring(errorMessage))
		return false
	end
end

-- ========== EXECUTE ENHANCED COORDINATION ==========

spawn(function()
	wait(2) -- Give scripts time to load

	print("🔧 Starting enhanced coordinated initialization in 2 seconds...")

	local success = CoordinateEnhancedSystemInitialization()

	if success then
		print("✅ All enhanced systems coordinated and ready!")
	else
		warn("❌ Enhanced system coordination incomplete - check debug commands")
	end
end)

-- ========== SHUTDOWN HANDLER ==========

game:BindToClose(function()
	print("🔄 Server shutting down, saving all enhanced player data...")

	if _G.GameCore and _G.GameCore.SavePlayerData then
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function()
				_G.GameCore:SavePlayerData(player, true)
			end)
		end
	end

	wait(3)
	print("✅ Enhanced shutdown complete")
end)

print("🔧 Enhanced System Coordinator loaded - coordination will begin in 2 seconds...")