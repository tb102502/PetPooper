--[[
    Main Initialization Script
    Place in: StarterPlayerScripts/MainGameInit
    
    This script initializes and connects all the enhanced systems:
    ✅ Enhanced UIManager with inventory menus
    ✅ Enhanced GameClient with inventory integration
    ✅ Proper initialization order
    ✅ Error handling and recovery
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ========== WAIT FOR REQUIRED MODULES ==========

print("MainGameInit: Waiting for required modules...")

-- Wait for UIManager
local UIManager = nil
local uiManagerSuccess, uiManagerError = pcall(function()
	UIManager = require(ReplicatedStorage:WaitForChild("UIManager", 30))
end)

if not uiManagerSuccess then
	error("MainGameInit: Failed to load UIManager: " .. tostring(uiManagerError))
end

-- Wait for GameClient  
local GameClient = nil
local gameClientSuccess, gameClientError = pcall(function()
	GameClient = require(ReplicatedStorage:WaitForChild("GameClient", 30))
end)

if not gameClientSuccess then
	error("MainGameInit: Failed to load GameClient: " .. tostring(gameClientError))
end

print("MainGameInit: ✅ Core modules loaded successfully")

-- ========== INITIALIZATION SEQUENCE ==========

local function initializeGame()
	print("MainGameInit: Starting enhanced game initialization...")

	-- Step 1: Initialize UIManager first
	local uiSuccess, uiError = pcall(function()
		return UIManager:Initialize()
	end)

	if not uiSuccess then
		error("MainGameInit: UIManager initialization failed: " .. tostring(uiError))
	end
	print("MainGameInit: ✅ UIManager initialized with inventory support")

	-- Step 2: Initialize GameClient with UIManager reference
	local clientSuccess, clientError = pcall(function()
		return GameClient:Initialize(UIManager)
	end)

	if not clientSuccess then
		error("MainGameInit: GameClient initialization failed: " .. tostring(clientError))
	end
	print("MainGameInit: ✅ GameClient initialized with inventory integration")

	-- Step 3: Setup cross-references
	UIManager:SetGameClient(GameClient)
	print("MainGameInit: ✅ Cross-references established")

	-- Step 4: Wait for player data and update currency display
	spawn(function()
		local attempts = 0
		local maxAttempts = 10

		while attempts < maxAttempts do
			attempts = attempts + 1
			local playerData = GameClient:GetPlayerData()

			if playerData and playerData.coins then
				print("MainGameInit: Player data loaded, updating currency display")
				UIManager:UpdateCurrencyDisplay(playerData)
				break
			else
				print("MainGameInit: Waiting for player data... (attempt " .. attempts .. "/" .. maxAttempts .. ")")
				wait(1)
			end
		end

		if attempts >= maxAttempts then
			warn("MainGameInit: Player data not loaded after " .. maxAttempts .. " attempts")
		end
	end)

	-- Step 5: Setup debug commands
	setupDebugCommands()

	print("MainGameInit: 🎉 Enhanced game initialization complete!")
	print("")
	print("🎮 AVAILABLE FEATURES:")
	print("  🌾 F = Farm Menu (Seeds, Crops, Livestock, Upgrades)")
	print("  ⛏️ M = Mining Menu (Ores, Tools, Progress)")
	print("  🔨 C = Crafting Menu (Stations, Materials, Recipes)")
	print("  🛒 H = Harvest All / Manual Shop Access")
	print("  📦 I = Toggle Inventory (Farm menu)")
	print("  ❌ ESC = Close all menus")
	print("  🛒 Shop = Step on shop area (proximity-based)")
	print("")
	print("💰 CURRENCY DISPLAY:")
	print("  💰 Coins | 🎫 Farm Tokens | 🥛 Milk")
	print("")
	print("🧪 DEBUG COMMANDS:")
	print("  /debug - Show system status")
	print("  /testinv - Add test inventory items")
	print("  /resetui - Reset UI state")

	return true
end

-- ========== DEBUG COMMANDS ==========

function setupDebugCommands()
	print("MainGameInit: Setting up debug commands...")

	LocalPlayer.Chatted:Connect(function(message)
		local command = message:lower()

		if command == "/debug" then
			print("=== ENHANCED GAME DEBUG STATUS ===")

			if GameClient and GameClient.DebugStatus then
				GameClient:DebugStatus()
			end

			if UIManager and UIManager.GetState then
				local uiState = UIManager:GetState()
				print("UI State:")
				print("  Current Page:", uiState.CurrentPage)
				print("  Active Menus:", #uiState.ActiveMenus)
				print("  Is Transitioning:", uiState.IsTransitioning)
			end

			print("===================================")

		elseif command == "/testinv" then
			print("🧪 Requesting test inventory items...")

			-- Request test items from server (if available)
			if game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes") then
				local testEvent = game:GetService("ReplicatedStorage").GameRemotes:FindFirstChild("AddTestItems")
				if testEvent then
					testEvent:FireServer()
					print("Test inventory request sent to server")
				else
					print("AddTestItems remote event not available")
				end
			end

		elseif command == "/resetui" then
			print("🔧 Resetting UI state...")

			if UIManager and UIManager.RecoverFromStuckState then
				UIManager:RecoverFromStuckState()
				print("UI state reset complete")
			end

		elseif command == "/inventory" then
			print("📦 Opening inventory (Farm menu)...")
			if GameClient and GameClient.OpenMenu then
				GameClient:OpenMenu("Farm")
			end

		elseif command == "/farm" then
			if GameClient and GameClient.OpenMenu then
				GameClient:OpenMenu("Farm")
			end

		elseif command == "/mining" then
			if GameClient and GameClient.OpenMenu then
				GameClient:OpenMenu("Mining")
			end

		elseif command == "/crafting" then
			if GameClient and GameClient.OpenMenu then
				GameClient:OpenMenu("Crafting")
			end

		elseif command == "/closemenus" then
			if UIManager and UIManager.CloseActiveMenus then
				UIManager:CloseActiveMenus()
			end

		elseif command == "/plant" then
			print("🌱 Opening farm menu for planting...")
			if GameClient and GameClient.OpenMenu then
				GameClient:OpenMenu("Farm")
			end

		elseif command == "/currency" then
			if GameClient and GameClient.GetPlayerData then
				local playerData = GameClient:GetPlayerData()
				if playerData then
					print("💰 Currency Status:")
					print("  Coins:", playerData.coins or 0)
					print("  Farm Tokens:", playerData.farmTokens or 0)
					print("  Milk:", playerData.milk or 0)
				else
					print("Player data not available")
				end
			end

		elseif command == "/help" then
			print("🎮 AVAILABLE COMMANDS:")
			print("  /debug - Show system debug info")
			print("  /testinv - Request test inventory items")
			print("  /resetui - Reset UI state")
			print("  /inventory - Open farm menu")
			print("  /farm - Open farm menu")
			print("  /mining - Open mining menu")
			print("  /crafting - Open crafting menu")
			print("  /closemenus - Close all menus")
			print("  /plant - Open farm for planting")
			print("  /currency - Show currency status")
			print("  /help - Show this help")
		end
	end)
end

-- ========== ERROR RECOVERY ==========

local function setupErrorRecovery()
	-- Global error handler for UI issues
	_G.RecoverGame = function()
		print("🚨 EMERGENCY GAME RECOVERY")

		-- Reset UI state
		if UIManager and UIManager.RecoverFromStuckState then
			UIManager:RecoverFromStuckState()
		end

		-- Reset GameClient state if needed
		if GameClient and GameClient.Cache then
			GameClient.Cache.LastDataUpdate = 0
			GameClient.Cache.LastInventoryUpdate = 0
		end

		-- Request fresh data
		if GameClient and GameClient.RequestInitialData then
			GameClient:RequestInitialData()
		end

		print("Recovery attempt completed")
		return true
	end

	_G.ForceRefreshInventory = function()
		print("🔄 Force refreshing inventory...")

		if GameClient and GameClient.RefreshInventoryDisplays then
			GameClient:RefreshInventoryDisplays()
		end

		if UIManager then
			local currentPage = UIManager:GetCurrentPage()
			if currentPage == "Farm" or currentPage == "Mining" or currentPage == "Crafting" then
				UIManager:RefreshMenuContent(currentPage)
			end
		end

		print("Inventory refresh completed")
	end

	_G.ShowInventory = function()
		if GameClient and GameClient.OpenMenu then
			GameClient:OpenMenu("Farm")
			return true
		end
		return false
	end
end

-- ========== PERIODIC HEALTH CHECKS ==========

local function setupHealthChecks()
	spawn(function()
		while true do
			wait(60) -- Check every minute

			-- Check if systems are responsive
			local uiHealthy = UIManager and UIManager.GetState and true or false
			local clientHealthy = GameClient and GameClient.GetPlayerData and true or false

			if not uiHealthy then
				warn("MainGameInit: UIManager health check failed")
			end

			if not clientHealthy then
				warn("MainGameInit: GameClient health check failed")
			end

			-- Refresh inventory data periodically
			if clientHealthy and GameClient.RefreshInventoryDisplays then
				GameClient:RefreshInventoryDisplays()
			end
		end
	end)
end

-- ========== MAIN EXECUTION ==========

local function main()
	print("MainGameInit: Starting enhanced Pet Palace initialization...")

	-- Wait for character to load
	if not LocalPlayer.Character then
		LocalPlayer.CharacterAdded:Wait()
	end

	-- Small delay to ensure everything is ready
	wait(1)

	-- Initialize the game systems
	local success, error = pcall(initializeGame)

	if not success then
		warn("MainGameInit: Initialization failed: " .. tostring(error))
		-- Try recovery
		wait(2)
		print("MainGameInit: Attempting recovery...")
		pcall(initializeGame)
	end

	-- Setup error recovery and health checks
	setupErrorRecovery()
	setupHealthChecks()

	-- Global access for debugging
	_G.UIManager = UIManager
	_G.GameClient = GameClient
	_G.InitializeGame = initializeGame

	print("MainGameInit: ✅ Enhanced initialization sequence complete!")
end

-- ========== EXECUTION ==========

-- Run main initialization
spawn(main)

-- Backup initialization in case of issues
spawn(function()
	wait(10) -- Wait 10 seconds

	-- Check if initialization was successful
	if not _G.UIManager or not _G.GameClient then
		print("MainGameInit: Backup initialization triggered")
		pcall(main)
	end
end)