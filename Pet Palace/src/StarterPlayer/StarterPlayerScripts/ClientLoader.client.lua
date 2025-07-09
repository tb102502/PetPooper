--[[
    FIXED ClientLoader.client.lua - Proper Client System Coordination
    Place in: StarterPlayer/StarterPlayerScripts/ClientLoader.client.lua
    
    FIXES:
    ✅ Proper module loading and initialization order
    ✅ Better error handling and retry logic
    ✅ Eliminates duplicate milking click handlers
    ✅ Coordinates all client systems properly
]]

print("🚀 ClientLoader: Starting FIXED client coordination...")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Get local player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Client system state
local ClientState = {
	UIManagerLoaded = false,
	GameClientLoaded = false,
	SystemsConnected = false,
	MilkingSystemReady = false,
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

-- ========== STEP 1: WAIT FOR REMOTE EVENTS ==========

local function WaitForRemoteEvents()
	print("📡 Waiting for remote events...")

	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
	if not gameRemotes then
		warn("❌ GameRemotes folder not found")
		return false
	end

	-- Essential remote events for client
	local essentialEvents = {
		"ShowChairPrompt", "HideChairPrompt",
		"StartMilkingSession", "StopMilkingSession", 
		"ContinueMilking", "MilkingSessionUpdate",
		"PlayerDataUpdated", "ShowNotification"
	}

	local eventsReady = 0
	for _, eventName in ipairs(essentialEvents) do
		local event = gameRemotes:WaitForChild(eventName, 10)
		if event then
			eventsReady = eventsReady + 1
			print("✅ " .. eventName .. " ready")
		else
			print("⚠️ " .. eventName .. " not ready")
		end
	end

	ClientState.RemoteEventsReady = eventsReady >= (math.ceil(#essentialEvents * 0.75)) -- 75% must be ready
	print("📡 Remote events status: " .. eventsReady .. "/" .. #essentialEvents .. " ready")
	return ClientState.RemoteEventsReady
end

-- ========== STEP 2: LOAD CORE MODULES ==========

local function LoadCoreModules()
	print("📱 Loading core client modules...")

	-- Load UIManager
	local uiManagerModule = SafeWaitForModule("UIManager", ReplicatedStorage, 15)
	local UIManager = SafeRequireModule(uiManagerModule, "UIManager")

	if not UIManager then
		error("❌ UIManager is required but failed to load")
	end

	-- Load GameClient
	local gameClientModule = SafeWaitForModule("GameClient", ReplicatedStorage, 15)
	local GameClient = SafeRequireModule(gameClientModule, "GameClient")

	if not GameClient then
		error("❌ GameClient is required but failed to load")
	end

	ClientState.UIManagerLoaded = UIManager ~= nil
	ClientState.GameClientLoaded = GameClient ~= nil

	return UIManager, GameClient
end

-- ========== STEP 3: INITIALIZE SYSTEMS ==========

local function InitializeCoreSystemsInOrder(UIManager, GameClient)
	print("🔧 Initializing client systems in proper order...")

	-- Step 3a: Initialize UIManager first
	print("🔧 Initializing UIManager...")
	local uiSuccess, uiError = pcall(function()
		return UIManager:Initialize()
	end)

	if not uiSuccess then
		error("❌ UIManager initialization failed: " .. tostring(uiError))
	end
	print("✅ UIManager initialized")

	-- Step 3b: Initialize GameClient with UIManager reference
	print("🔧 Initializing GameClient...")
	local clientSuccess, clientError = pcall(function()
		return GameClient:Initialize(UIManager)
	end)

	if not clientSuccess then
		error("❌ GameClient initialization failed: " .. tostring(clientError))
	end
	print("✅ GameClient initialized")

	-- Step 3c: Cross-link the systems
	UIManager:SetGameClient(GameClient)
	print("🔗 Systems cross-linked")

	-- Step 3d: Set global references for other scripts
	_G.UIManager = UIManager
	_G.GameClient = GameClient

	ClientState.SystemsConnected = true
	return true
end

-- ========== STEP 4: SETUP MILKING SYSTEM INTEGRATION ==========

local function SetupMilkingSystemIntegration()
	print("🥛 Setting up milking system integration...")

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
	local function SetupUnifiedClickHandling()
		print("🖱️ Setting up unified click handling...")

		local isInMilkingSession = false
		local lastClickTime = 0
		local clickCooldown = 0.05

		-- Single click handler for milking
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
							print("🖱️ Click sent to server")
						end
					end
				end
			end
		end)

		print("✅ Unified click handling setup")
	end

	SetupUnifiedClickHandling()
	ClientState.MilkingSystemReady = true
	return true
end

-- ========== STEP 5: VERIFICATION AND DIAGNOSTICS ==========

local function VerifySystemIntegration()
	print("🔍 Verifying system integration...")

	-- Check UI elements exist
	local mainUI = PlayerGui:FindFirstChild("MainGameUI")
	local topMenuUI = PlayerGui:FindFirstChild("TopMenuUI")

	print("UI Elements:")
	print("  Main UI: " .. (mainUI and "✅" or "❌"))
	print("  Top Menu UI: " .. (topMenuUI and "✅" or "❌"))

	-- Check global references
	print("Global References:")
	print("  _G.UIManager: " .. (_G.UIManager and "✅" or "❌"))
	print("  _G.GameClient: " .. (_G.GameClient and "✅" or "❌"))
	print("  _G.ChairMilkingGUI: " .. (_G.ChairMilkingGUI and "✅" or "❌"))

	-- Check remote connections
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		local openShop = gameRemotes:FindFirstChild("OpenShop")
		local continueMilking = gameRemotes:FindFirstChild("ContinueMilking")

		print("Remote Connections:")
		print("  OpenShop: " .. (openShop and "✅" or "❌"))
		print("  ContinueMilking: " .. (continueMilking and "✅" or "❌"))
	else
		print("❌ GameRemotes not found")
	end

	-- Test basic functionality
	local basicFunctionsWork = true

	if _G.UIManager and _G.UIManager.ShowNotification then
		pcall(function()
			_G.UIManager:ShowNotification("System Test", "Client systems loaded successfully!", "success")
		end)
	else
		basicFunctionsWork = false
	end

	print("Basic Functions: " .. (basicFunctionsWork and "✅" or "❌"))
	return basicFunctionsWork
end

-- ========== STEP 6: SETUP DEBUG COMMANDS ==========

local function SetupClientDebugCommands()
	print("🔧 Setting up client debug commands...")

	LocalPlayer.Chatted:Connect(function(message)
		local command = message:lower()

		if command == "/clientstatus" then
			print("=== CLIENT SYSTEM STATUS ===")
			print("UIManager loaded: " .. (ClientState.UIManagerLoaded and "✅" or "❌"))
			print("GameClient loaded: " .. (ClientState.GameClientLoaded and "✅" or "❌"))
			print("Systems connected: " .. (ClientState.SystemsConnected and "✅" or "❌"))
			print("Milking system ready: " .. (ClientState.MilkingSystemReady and "✅" or "❌"))
			print("Remote events ready: " .. (ClientState.RemoteEventsReady and "✅" or "❌"))
			print("Retry count: " .. ClientState.RetryCount)
			print("")
			VerifySystemIntegration()
			print("============================")

		elseif command == "/testui" then
			if _G.UIManager then
				print("Testing UI system...")
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
			print("🔄 Recreating client systems...")

			ClientState.RetryCount = 0
			local success = AttemptClientInitialization()

			if success then
				print("✅ Client systems recreated")
			else
				print("❌ Client recreation failed")
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
		end
	end)

	print("✅ Client debug commands ready")
end

-- ========== MAIN CLIENT INITIALIZATION ==========

function AttemptClientInitialization()
	print("🔧 Attempting client initialization (Attempt " .. (ClientState.RetryCount + 1) .. ")...")

	ClientState.RetryCount = ClientState.RetryCount + 1

	local success, errorMessage = pcall(function()
		-- Step 1: Wait for remote events
		if not WaitForRemoteEvents() then
			warn("⚠️ Some remote events missing - continuing anyway")
		end

		-- Step 2: Load core modules
		local UIManager, GameClient = LoadCoreModules()

		-- Step 3: Initialize systems in order
		InitializeCoreSystemsInOrder(UIManager, GameClient)

		-- Step 4: Setup milking integration
		SetupMilkingSystemIntegration()

		-- Step 5: Verify everything works
		VerifySystemIntegration()

		-- Step 6: Setup debug commands
		SetupClientDebugCommands()

		return true
	end)

	if success then
		print("🎉 Client initialization successful!")
		print("")
		print("🎮 CLIENT SYSTEMS READY:")
		print("  📱 UIManager: " .. (ClientState.UIManagerLoaded and "✅" or "❌"))
		print("  🎮 GameClient: " .. (ClientState.GameClientLoaded and "✅" or "❌"))
		print("  🔗 Connected: " .. (ClientState.SystemsConnected and "✅" or "❌"))
		print("  🥛 Milking: " .. (ClientState.MilkingSystemReady and "✅" or "❌"))
		print("")
		print("🎮 Debug Commands:")
		print("  /clientstatus - Show client status")
		print("  /testui - Test UI system")
		print("  /testmilkclick - Test milking click")
		print("  /recreateclient - Recreate client systems")
		print("  /clearguis - Clean up old GUIs")
		return true
	else
		warn("💥 Client initialization failed: " .. tostring(errorMessage))

		if ClientState.RetryCount < ClientState.MaxRetries then
			print("🔄 Retrying in 3 seconds...")
			wait(3)
			return AttemptClientInitialization()
		else
			warn("❌ Client initialization failed after " .. ClientState.MaxRetries .. " attempts")
			-- Still setup debug commands for troubleshooting
			SetupClientDebugCommands()
			return false
		end
	end
end

-- ========== EXECUTE CLIENT INITIALIZATION ==========

spawn(function()
	wait(2) -- Give ReplicatedStorage time to populate

	print("🚀 Starting FIXED client initialization...")

	local success = AttemptClientInitialization()

	if success then
		print("✅ All client systems ready!")
	else
		warn("❌ Client initialization incomplete - debug commands available")
	end
end)

print("🔧 Fixed ClientLoader ready - initialization starting in 2 seconds...")