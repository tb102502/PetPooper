--[[
    ENHANCED ClientLoader.client.lua - Enhanced Inventory Integration
    Place in: StarterPlayer/StarterPlayerScripts/ClientLoader.client.lua
    
    ENHANCEMENTS:
    ✅ Enhanced UIManager with inventory menus integration
    ✅ Enhanced GameClient with inventory features
    ✅ Enhanced remote event handling for inventory
    ✅ Added inventory debug commands
    ✅ Better coordination with enhanced systems
]]

print("🚀 ClientLoader: Starting ENHANCED client coordination with inventory support...")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Get local player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Enhanced client system state
local ClientState = {
	UIManagerLoaded = false,
	GameClientLoaded = false,
	SystemsConnected = false,
	MilkingSystemReady = false,
	InventorySystemReady = false,
	RemoteEventsReady = false,
	RetryCount = 0,
	MaxRetries = 5
}

-- ========== SAFE MODULE LOADING ==========

local function SafeWaitForModule(name, parent, timeout)
	timeout = timeout or 30
	local startTime = tick()

	print("⏳ Waiting for " .. name .. "...")

	while not parent:FindFirstChild(name) and (tick() - startTime) < timeout do
		wait(0.1)
	end

	if parent:FindFirstChild(name) then
		print("✅ Found " .. name)
		return parent:FindFirstChild(name)
	else
		warn("❌ " .. name .. " not found after " .. timeout .. " seconds")
		return nil
	end
end

local function SafeRequireModule(moduleScript, moduleName)
	if not moduleScript then
		warn("❌ " .. moduleName .. " module script not found")
		return nil
	end

	local success, result = pcall(function()
		return require(moduleScript)
	end)

	if success and result then
		print("✅ " .. moduleName .. " loaded successfully")
		return result
	else
		warn("❌ " .. moduleName .. " failed to load: " .. tostring(result))
		return nil
	end
end

-- ========== STEP 1: WAIT FOR ENHANCED REMOTE EVENTS ==========

local function WaitForEnhancedRemoteEvents()
	print("📡 Waiting for enhanced remote events with inventory support...")

	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
	if not gameRemotes then
		warn("❌ GameRemotes folder not found")
		return false
	end

	-- Enhanced remote events for inventory system
	local enhancedEvents = {
		-- Core events
		"PlayerDataUpdated", "ShowNotification",
		-- Inventory events
		"InventoryUpdated", "ItemSold", "ItemPurchased",
		-- Shop events
		"OpenShop", "CloseShop",
		-- Milking events
		"ShowChairPrompt", "HideChairPrompt",
		"StartMilkingSession", "StopMilkingSession", 
		"ContinueMilking", "MilkingSessionUpdate"
	}

	local eventsReady = 0
	for _, eventName in ipairs(enhancedEvents) do
		local event = gameRemotes:WaitForChild(eventName, 10)
		if event then
			eventsReady = eventsReady + 1
			print("✅ " .. eventName .. " ready")
		else
			print("⚠️ " .. eventName .. " not ready")
		end
	end

	ClientState.RemoteEventsReady = eventsReady >= (math.ceil(#enhancedEvents * 0.75)) -- 75% must be ready
	print("📡 Enhanced remote events status: " .. eventsReady .. "/" .. #enhancedEvents .. " ready")
	return ClientState.RemoteEventsReady
end

-- ========== STEP 2: LOAD ENHANCED MODULES ==========

local function LoadEnhancedModules()
	print("📱 Loading enhanced client modules with inventory support...")

	-- Load Enhanced UIManager
	local uiManagerModule = SafeWaitForModule("UIManager", ReplicatedStorage, 15)
	local UIManager = SafeRequireModule(uiManagerModule, "Enhanced UIManager")

	if not UIManager then
		error("❌ Enhanced UIManager is required but failed to load")
	end

	-- Load Enhanced GameClient
	local gameClientModule = SafeWaitForModule("GameClient", ReplicatedStorage, 15)
	local GameClient = SafeRequireModule(gameClientModule, "Enhanced GameClient")

	if not GameClient then
		error("❌ Enhanced GameClient is required but failed to load")
	end

	ClientState.UIManagerLoaded = UIManager ~= nil
	ClientState.GameClientLoaded = GameClient ~= nil

	return UIManager, GameClient
end

-- ========== STEP 3: INITIALIZE ENHANCED SYSTEMS ==========

local function InitializeEnhancedSystemsInOrder(UIManager, GameClient)
	print("🔧 Initializing enhanced client systems with inventory support...")

	-- Step 3a: Initialize Enhanced UIManager first
	print("🔧 Initializing Enhanced UIManager...")
	local uiSuccess, uiError = pcall(function()
		return UIManager:Initialize()
	end)

	if not uiSuccess then
		error("❌ Enhanced UIManager initialization failed: " .. tostring(uiError))
	end
	print("✅ Enhanced UIManager initialized with inventory menus")

	-- Step 3b: Initialize Enhanced GameClient with UIManager reference
	print("🔧 Initializing Enhanced GameClient...")
	local clientSuccess, clientError = pcall(function()
		return GameClient:Initialize(UIManager)
	end)

	if not clientSuccess then
		error("❌ Enhanced GameClient initialization failed: " .. tostring(clientError))
	end
	print("✅ Enhanced GameClient initialized with inventory integration")

	-- Step 3c: Cross-link the enhanced systems
	UIManager:SetGameClient(GameClient)
	print("🔗 Enhanced systems cross-linked")

	-- Step 3d: Set global references for other scripts
	_G.UIManager = UIManager
	_G.GameClient = GameClient

	ClientState.SystemsConnected = true
	ClientState.InventorySystemReady = true
	return true
end
local function ValidateClientGardenReferences()
	print("🌱 Validating client-side garden references...")

	local garden = workspace:FindFirstChild("Garden")
	local soil = garden and garden:FindFirstChild("Soil")

	print("Client Garden Status:")
	print("  Garden found: " .. (garden and "✅" or "❌"))
	print("  Soil found: " .. (soil and "✅" or "❌"))

	return garden ~= nil and soil ~= nil
end

-- Add this to your client initialization
spawn(function()
	wait(3) -- Wait for workspace to fully load
	ValidateClientGardenReferences()
end)

-- ========== STEP 4: SETUP ENHANCED MILKING SYSTEM ==========

local function SetupEnhancedMilkingSystem()
	print("🥛 Setting up enhanced milking system integration...")

	-- Wait for ChairMilkingGUI to be available
	local chairGUIReady = false
	local attempts = 0

	while not chairGUIReady and attempts < 10 do
		wait(1)
		attempts = attempts + 1

		if _G.ChairMilkingGUI then
			chairGUIReady = true
			print("✅ ChairMilkingGUI detected")
		else
			print("⏳ Waiting for ChairMilkingGUI... (attempt " .. attempts .. ")")
		end
	end

	if not chairGUIReady then
		warn("⚠️ ChairMilkingGUI not detected - milking GUI may be limited")
	end

	-- Setup unified click handling (prevents conflicts)
	local function SetupEnhancedClickHandling()
		print("🖱️ Setting up enhanced unified click handling...")

		local isInMilkingSession = false
		local lastClickTime = 0
		local clickCooldown = 0.05

		-- Enhanced click handler for milking with inventory integration
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end

			-- Check if we're in a milking session
			if _G.ChairMilkingGUI and _G.ChairMilkingGUI.State then
				isInMilkingSession = (_G.ChairMilkingGUI.State.guiType == "milking" and 
					_G.ChairMilkingGUI.State.isVisible)
			end

			-- Fallback check for milking GUI
			if not isInMilkingSession then
				local milkingGUI = PlayerGui:FindFirstChild("ChairMilkingGUI") or 
					PlayerGui:FindFirstChild("MilkingGUI")
				isInMilkingSession = milkingGUI ~= nil
			end

			if isInMilkingSession then
				local currentTime = tick()

				-- Check cooldown
				if (currentTime - lastClickTime) < clickCooldown then
					return
				end

				local isClick = (input.UserInputType == Enum.UserInputType.MouseButton1) or 
					(input.UserInputType == Enum.UserInputType.Touch) or
					(input.KeyCode == Enum.KeyCode.Space)

				if isClick then
					lastClickTime = currentTime

					-- Send to server
					local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
					if gameRemotes then
						local continueMilking = gameRemotes:FindFirstChild("ContinueMilking")
						if continueMilking then
							continueMilking:FireServer()
							print("🖱️ Enhanced click sent to server")
						end
					end
				end
			end
		end)

		print("✅ Enhanced unified click handling setup")
	end

	SetupEnhancedClickHandling()
	ClientState.MilkingSystemReady = true
	return true
end

-- ========== STEP 5: SETUP INVENTORY EVENT HANDLERS ==========

local function SetupInventoryEventHandlers()
	print("📦 Setting up enhanced inventory event handlers...")

	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not gameRemotes then
		warn("❌ GameRemotes not found for inventory handlers")
		return false
	end

	-- Enhanced inventory event handlers
	local inventoryEvents = {
		InventoryUpdated = function(inventoryType, newInventory)
			print("📦 Inventory updated: " .. inventoryType)
			if _G.GameClient and _G.GameClient.HandleInventoryUpdate then
				_G.GameClient:HandleInventoryUpdate(inventoryType, newInventory)
			end
		end,

		ItemSold = function(itemId, quantity, totalValue)
			print("💰 Item sold: " .. itemId .. " x" .. quantity .. " for " .. totalValue)
			if _G.GameClient and _G.GameClient.HandleItemSold then
				_G.GameClient:HandleItemSold(itemId, quantity, totalValue)
			end
		end,

		ItemPurchased = function(itemId, quantity, cost, currency)
			print("🛒 Item purchased: " .. itemId .. " x" .. quantity)
			if _G.GameClient and _G.GameClient.HandleItemPurchased then
				_G.GameClient:HandleItemPurchased(itemId, quantity, cost, currency)
			end
		end,

		PlayerDataUpdated = function(newData)
			print("📊 Player data updated with enhanced inventory")
			if _G.GameClient and _G.GameClient.HandlePlayerDataUpdate then
				_G.GameClient:HandlePlayerDataUpdate(newData)
			end
		end
	}

	-- Connect inventory event handlers
	local handlersConnected = 0
	for eventName, handler in pairs(inventoryEvents) do
		local event = gameRemotes:FindFirstChild(eventName)
		if event and event:IsA("RemoteEvent") then
			event.OnClientEvent:Connect(handler)
			handlersConnected = handlersConnected + 1
			print("✅ Connected " .. eventName .. " inventory handler")
		else
			print("⚠️ " .. eventName .. " not found or wrong type")
		end
	end

	print("📦 Inventory handlers connected: " .. handlersConnected .. "/" .. #inventoryEvents)
	return handlersConnected > 0
end

-- ========== STEP 6: ENHANCED VERIFICATION ==========

local function VerifyEnhancedSystemIntegration()
	print("🔍 Verifying enhanced system integration...")

	-- Check enhanced UI elements exist
	local mainUI = PlayerGui:FindFirstChild("MainGameUI")
	local topMenuUI = PlayerGui:FindFirstChild("TopMenuUI")

	print("Enhanced UI Elements:")
	print("  Main UI: " .. (mainUI and "✅" or "❌"))
	print("  Top Menu UI: " .. (topMenuUI and "✅" or "❌"))

	-- Check for currency display with milk
	if mainUI then
		local currencyDisplay = mainUI:FindFirstChild("CurrencyDisplay")
		if currencyDisplay then
			local milkLabel = currencyDisplay:FindFirstChild("MilkLabel")
			print("  Currency with Milk: " .. (milkLabel and "✅" or "❌"))
		end
	end

	-- Check enhanced global references
	print("Enhanced Global References:")
	print("  _G.UIManager: " .. (_G.UIManager and "✅" or "❌"))
	print("  _G.GameClient: " .. (_G.GameClient and "✅" or "❌"))
	print("  _G.ChairMilkingGUI: " .. (_G.ChairMilkingGUI and "✅" or "❌"))

	-- Check enhanced methods
	local hasInventoryMethods = false
	if _G.GameClient then
		hasInventoryMethods = (_G.GameClient.GetInventoryData ~= nil) and
			(_G.GameClient.GetFarmingData ~= nil) and
			(_G.GameClient.GetMiningData ~= nil) and
			(_G.GameClient.GetCraftingData ~= nil)
	end
	print("  Enhanced Inventory Methods: " .. (hasInventoryMethods and "✅" or "❌"))

	-- Check enhanced remote connections
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		local inventoryRemotes = {
			"InventoryUpdated", "ItemSold", "ItemPurchased",
			"GetInventoryData", "GetMiningData", "GetCraftingData", "SellInventoryItem"
		}

		local remoteCount = 0
		for _, remoteName in ipairs(inventoryRemotes) do
			if gameRemotes:FindFirstChild(remoteName) then
				remoteCount = remoteCount + 1
			end
		end

		print("Enhanced Remote Connections: " .. remoteCount .. "/" .. #inventoryRemotes .. " (" .. 
			(remoteCount >= math.ceil(#inventoryRemotes * 0.75) and "✅" or "❌") .. ")")
	else
		print("❌ GameRemotes not found")
	end

	-- Test enhanced functionality
	local enhancedFunctionsWork = true

	if _G.UIManager and _G.UIManager.ShowNotification then
		pcall(function()
			_G.UIManager:ShowNotification("Enhanced System Test", "Enhanced client systems with inventory loaded successfully!", "success")
		end)
	else
		enhancedFunctionsWork = false
	end

	print("Enhanced Functions: " .. (enhancedFunctionsWork and "✅" or "❌"))
	return enhancedFunctionsWork
end

-- ========== STEP 7: ENHANCED DEBUG COMMANDS ==========

local function SetupEnhancedClientDebugCommands()
	print("🔧 Setting up enhanced client debug commands...")

	LocalPlayer.Chatted:Connect(function(message)
		local command = message:lower()

		if command == "/enhancedclientstatus" then
			print("=== ENHANCED CLIENT SYSTEM STATUS ===")
			print("UIManager loaded: " .. (ClientState.UIManagerLoaded and "✅" or "❌"))
			print("GameClient loaded: " .. (ClientState.GameClientLoaded and "✅" or "❌"))
			print("Systems connected: " .. (ClientState.SystemsConnected and "✅" or "❌"))
			print("Inventory system ready: " .. (ClientState.InventorySystemReady and "✅" or "❌"))
			print("Milking system ready: " .. (ClientState.MilkingSystemReady and "✅" or "❌"))
			print("Remote events ready: " .. (ClientState.RemoteEventsReady and "✅" or "❌"))
			print("Retry count: " .. ClientState.RetryCount)
			print("")
			VerifyEnhancedSystemIntegration()
			print("=========================================")

		elseif command == "/testinventoryui" then
			if _G.UIManager then
				print("Testing enhanced inventory UI...")
				_G.UIManager:ShowNotification("Inventory Test", "Enhanced inventory system is working!", "success")

				-- Try opening inventory menus
				spawn(function()
					wait(1)
					print("Opening Farm menu...")
					_G.UIManager:OpenMenu("Farm")
					wait(3)
					print("Opening Mining menu...")
					_G.UIManager:OpenMenu("Mining")
					wait(3)
					print("Opening Crafting menu...")
					_G.UIManager:OpenMenu("Crafting")
					wait(2)
					_G.UIManager:CloseActiveMenus()
				end)
			else
				print("❌ Enhanced UIManager not available")
			end

		elseif command == "/testinventorydata" then
			if _G.GameClient then
				print("Testing enhanced inventory data...")

				local farmingData = _G.GameClient:GetFarmingData()
				local miningData = _G.GameClient:GetMiningData()
				local craftingData = _G.GameClient:GetCraftingData()

				print("Farming inventory items: " .. (farmingData.inventory and #farmingData.inventory or 0))
				print("Mining inventory items: " .. (miningData.inventory and #miningData.inventory or 0))
				print("Crafting inventory items: " .. (craftingData.inventory and #craftingData.inventory or 0))

				-- Test getting player data
				local playerData = _G.GameClient:GetPlayerData()
				if playerData then
					print("Player coins: " .. (playerData.coins or 0))
					print("Player milk: " .. (playerData.milk or 0))
				end
			else
				print("❌ Enhanced GameClient not available")
			end

		elseif command == "/testinventorysell" then
			print("Testing inventory sell functionality...")

			local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
			if gameRemotes then
				local sellEvent = gameRemotes:FindFirstChild("SellItem")
				if sellEvent then
					-- Try to sell a test item
					sellEvent:FireServer("carrot", 1)
					print("✅ Test sell request sent")
				else
					print("❌ SellItem remote not found")
				end
			else
				print("❌ GameRemotes not found")
			end

		elseif command == "/currencytest" then
			if _G.UIManager and _G.GameClient then
				print("Testing enhanced currency display...")

				local playerData = _G.GameClient:GetPlayerData()
				if playerData then
					print("Current currency:")
					print("  Coins: " .. (playerData.coins or 0))
					print("  Farm Tokens: " .. (playerData.farmTokens or 0))
					print("  Milk: " .. (playerData.milk or 0))

					-- Force update currency display
					_G.UIManager:UpdateCurrencyDisplay(playerData)
					print("✅ Currency display updated")
				end
			else
				print("❌ Enhanced systems not available")
			end

			-- Include existing debug commands
		elseif command == "/clientstatus" then
			print("=== BASIC CLIENT SYSTEM STATUS ===")
			print("UIManager loaded: " .. (ClientState.UIManagerLoaded and "✅" or "❌"))
			print("GameClient loaded: " .. (ClientState.GameClientLoaded and "✅" or "❌"))
			print("Systems connected: " .. (ClientState.SystemsConnected and "✅" or "❌"))
			print("Milking system ready: " .. (ClientState.MilkingSystemReady and "✅" or "❌"))
			print("Remote events ready: " .. (ClientState.RemoteEventsReady and "✅" or "❌"))
			print("===================================")

		elseif command == "/testui" then
			if _G.UIManager then
				print("Testing basic UI system...")
				_G.UIManager:ShowNotification("UI Test", "UI system is working!", "success")

				-- Try opening shop
				spawn(function()
					wait(2)
					_G.UIManager:OpenMenu("Shop")
				end)
			else
				print("❌ UIManager not available")
			end

		elseif command == "/testmilkclick" then
			print("Testing milking click...")
			local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
			if gameRemotes then
				local continueMilking = gameRemotes:FindFirstChild("ContinueMilking")
				if continueMilking then
					continueMilking:FireServer()
					print("✅ Test click sent")
				else
					print("❌ ContinueMilking remote not found")
				end
			else
				print("❌ GameRemotes not found")
			end

		elseif command == "/recreateclient" then
			print("🔄 Recreating enhanced client systems...")

			ClientState.RetryCount = 0
			local success = AttemptEnhancedClientInitialization()

			if success then
				print("✅ Enhanced client systems recreated")
			else
				print("❌ Enhanced client recreation failed")
			end

		elseif command == "/clearguis" then
			print("🧹 Cleaning up old GUIs...")

			local guisToClean = {
				"MainGameUI", "TopMenuUI", "ChairMilkingGUI", 
				"MilkingGUI", "ChairProximityGUI"
			}

			for _, guiName in ipairs(guisToClean) do
				local gui = PlayerGui:FindFirstChild(guiName)
				if gui then
					gui:Destroy()
					print("🗑️ Removed " .. guiName)
				end
			end

		elseif command == "/inventoryhelp" then
			print("🎮 ENHANCED INVENTORY COMMANDS:")
			print("  /enhancedclientstatus - Show enhanced system status")
			print("  /testinventoryui - Test inventory UI menus")
			print("  /testinventorydata - Test inventory data access")
			print("  /testinventorysell - Test inventory sell functionality")
			print("  /currencytest - Test enhanced currency display")
			print("  /clientstatus - Show basic system status")
			print("  /testui - Test basic UI system")
			print("  /testmilkclick - Test milking click")
			print("  /recreateclient - Recreate client systems")
			print("  /clearguis - Clean up old GUIs")
			print("")
			print("🎯 ENHANCED HOTKEYS:")
			print("  F = Farm Menu (Seeds, Crops, Livestock, Upgrades)")
			print("  M = Mining Menu (Ores, Tools, Progress)")
			print("  C = Crafting Menu (Stations, Materials, Recipes)")
			print("  H = Harvest All / Shop")
			print("  I = Toggle Inventory")
			print("  ESC = Close all menus")
		end
	end)

	print("✅ Enhanced client debug commands ready")
end

-- ========== MAIN ENHANCED CLIENT INITIALIZATION ==========

function AttemptEnhancedClientInitialization()
	print("🔧 Attempting enhanced client initialization (Attempt " .. (ClientState.RetryCount + 1) .. ")...")

	ClientState.RetryCount = ClientState.RetryCount + 1

	local success, errorMessage = pcall(function()
		-- Step 1: Wait for enhanced remote events
		if not WaitForEnhancedRemoteEvents() then
			warn("⚠️ Some enhanced remote events missing - continuing anyway")
		end

		-- Step 2: Load enhanced modules
		local UIManager, GameClient = LoadEnhancedModules()

		-- Step 3: Initialize enhanced systems in order
		InitializeEnhancedSystemsInOrder(UIManager, GameClient)

		-- Step 4: Setup enhanced milking integration
		SetupEnhancedMilkingSystem()

		-- Step 5: Setup inventory event handlers
		SetupInventoryEventHandlers()

		-- Step 6: Verify enhanced integration
		VerifyEnhancedSystemIntegration()

		-- Step 7: Setup enhanced debug commands
		SetupEnhancedClientDebugCommands()

		return true
	end)

	if success then
		print("🎉 Enhanced client initialization successful!")
		print("")
		print("🎮 ENHANCED CLIENT SYSTEMS READY:")
		print("  📱 Enhanced UIManager: " .. (ClientState.UIManagerLoaded and "✅" or "❌"))
		print("  🎮 Enhanced GameClient: " .. (ClientState.GameClientLoaded and "✅" or "❌"))
		print("  🔗 Systems Connected: " .. (ClientState.SystemsConnected and "✅" or "❌"))
		print("  📦 Inventory System: " .. (ClientState.InventorySystemReady and "✅" or "❌"))
		print("  🥛 Milking System: " .. (ClientState.MilkingSystemReady and "✅" or "❌"))
		print("")
		print("🎮 Enhanced Debug Commands:")
		print("  /enhancedclientstatus - Enhanced system status")
		print("  /testinventoryui - Test inventory menus")
		print("  /testinventorydata - Test inventory data")
		print("  /inventoryhelp - Show all inventory commands")
		print("")
		print("🎯 ENHANCED FEATURES READY:")
		print("  💰 Currency with milk count")
		print("  🌾 Farm menu with real inventory")
		print("  ⛏️ Mining menu with ores and tools")
		print("  🔨 Crafting menu with materials")
		print("  🌱 Plant seeds from inventory")
		print("  💰 Sell items from inventory")
		print("  🔄 Real-time inventory updates")
		return true
	else
		warn("💥 Enhanced client initialization failed: " .. tostring(errorMessage))

		if ClientState.RetryCount < ClientState.MaxRetries then
			print("🔄 Retrying enhanced initialization in 3 seconds...")
			wait(3)
			return AttemptEnhancedClientInitialization()
		else
			warn("❌ Enhanced client initialization failed after " .. ClientState.MaxRetries .. " attempts")
			-- Still setup debug commands for troubleshooting
			SetupEnhancedClientDebugCommands()
			return false
		end
	end
end

-- ========== EXECUTE ENHANCED CLIENT INITIALIZATION ==========

spawn(function()
	wait(2) -- Give ReplicatedStorage time to populate

	print("🚀 Starting ENHANCED client initialization with inventory support...")

	local success = AttemptEnhancedClientInitialization()

	if success then
		print("✅ All enhanced client systems with inventory support ready!")
	else
		warn("❌ Enhanced client initialization incomplete - debug commands available")
	end
end)

print("🔧 Enhanced ClientLoader ready - initialization starting in 2 seconds...")