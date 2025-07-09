--[[
    FIXED SystemInitializer.server.lua - Proper System Coordination
    Place in: ServerScriptService/SystemInitializer.server.lua
    
    FIXES:
    ✅ Proper initialization order
    ✅ Avoids duplicate module loading
    ✅ Better error handling and recovery
    ✅ Coordinates all systems properly
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🚀 === Pet Palace FIXED System Coordinator Starting ===")

-- System state tracking
local SystemState = {
	GameCoreLoaded = false,
	ModulesInitialized = false,
	RemoteEventsReady = false,
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

-- ========== STEP 1: LOAD GAMECORE ==========

local function LoadGameCore()
	print("🎮 Loading GameCore...")

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

-- ========== STEP 2: VERIFY MODULES EXIST ==========

local function VerifyModulesExist()
	print("🔍 Verifying module availability...")

	local modulesFound = {}
	local modulesAvailable = 0

	-- Check for cow modules in root ServerScriptService
	local cowCreationModule = ServerScriptService:FindFirstChild("CowCreationModule")
	if cowCreationModule then
		modulesFound.CowCreationModule = true
		modulesAvailable = modulesAvailable + 1
		print("✅ CowCreationModule found")
	else
		print("⚠️ CowCreationModule not found")
	end

	local cowMilkingModule = ServerScriptService:FindFirstChild("CowMilkingModule")
	if cowMilkingModule then
		modulesFound.CowMilkingModule = true
		modulesAvailable = modulesAvailable + 1
		print("✅ CowMilkingModule found")
	else
		print("⚠️ CowMilkingModule not found")
	end

	-- Check for crop modules in Modules folder (optional)
	local modulesFolder = ServerScriptService:FindFirstChild("Modules")
	if modulesFolder then
		print("✅ Modules folder found, checking for crop modules...")

		local cropCreation = modulesFolder:FindFirstChild("CropCreation")
		if cropCreation then
			modulesFound.CropCreation = true
			modulesAvailable = modulesAvailable + 1
			print("✅ CropCreation found")
		end

		local farmPlot = modulesFolder:FindFirstChild("FarmPlot") 
		if farmPlot then
			modulesFound.FarmPlot = true
			modulesAvailable = modulesAvailable + 1
			print("✅ FarmPlot found")
		end
	else
		print("ℹ️ No Modules folder found (optional)")
	end

	print("📦 Total modules available: " .. modulesAvailable)
	SystemState.ModulesInitialized = modulesAvailable > 0
	return modulesFound, modulesAvailable
end

-- ========== STEP 3: VERIFY WORKSPACE MODELS ==========

local function VerifyWorkspaceModels()
	print("🔍 Verifying workspace models...")

	local cowsFound = 0
	local chairsFound = 0

	-- Search for cows and chairs
	for _, obj in pairs(workspace:GetChildren()) do
		local name = obj.Name:lower()

		if name == "cow" or name:find("cow") then
			cowsFound = cowsFound + 1
			print("📍 Found cow: " .. obj.Name)
		end

		if name == "milkingchair" or name:find("chair") then
			chairsFound = chairsFound + 1
			print("📍 Found chair: " .. obj.Name)
		end
	end

	print("🐄 Total cows found: " .. cowsFound)
	print("🪑 Total chairs found: " .. chairsFound)

	if cowsFound == 0 then
		warn("⚠️ No cow models found! Add a model named 'cow' to workspace")
	end

	if chairsFound == 0 then
		warn("⚠️ No chair models found! Add a model named 'MilkingChair' to workspace")
	end

	return cowsFound > 0 and chairsFound > 0
end

-- ========== STEP 4: INITIALIZE GAMECORE ==========

local function InitializeGameCore(GameCore)
	print("🔧 Initializing GameCore...")

	if not GameCore.Initialize then
		error("❌ GameCore.Initialize method not found")
	end

	local success, result = pcall(function()
		return GameCore:Initialize()
	end)

	if success and result then
		print("✅ GameCore initialized successfully")
		_G.GameCore = GameCore  -- Set global reference
		return true
	else
		error("❌ GameCore initialization failed: " .. tostring(result))
	end
end

-- ========== STEP 5: WAIT FOR MODULES TO CONNECT ==========

local function WaitForModuleConnections(timeout)
	timeout = timeout or 30
	local startTime = tick()

	print("⏳ Waiting for modules to connect to GameCore...")

	while (tick() - startTime) < timeout do
		local cowCreationReady = _G.CowCreationModule ~= nil
		local cowMilkingReady = _G.CowMilkingModule ~= nil

		if cowCreationReady and cowMilkingReady then
			print("✅ All cow modules connected successfully")
			SystemState.SystemsConnected = true
			return true
		elseif cowCreationReady or cowMilkingReady then
			print("⏳ Some modules connected, waiting for all...")
		end

		wait(1)
	end

	-- Check what we have after timeout
	local cowCreationReady = _G.CowCreationModule ~= nil
	local cowMilkingReady = _G.CowMilkingModule ~= nil

	if cowCreationReady or cowMilkingReady then
		print("⚠️ Partial module connection after timeout")
		print("  CowCreationModule: " .. (cowCreationReady and "✅" or "❌"))
		print("  CowMilkingModule: " .. (cowMilkingReady and "✅" or "❌"))
		SystemState.SystemsConnected = true
		return true
	else
		warn("❌ No modules connected after " .. timeout .. " seconds")
		return false
	end
end

-- ========== STEP 6: VERIFY REMOTE EVENTS ==========

local function VerifyRemoteEvents()
	print("📡 Verifying remote events...")

	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not gameRemotes then
		warn("❌ GameRemotes folder not found")
		return false
	end

	local requiredEvents = {
		"ShowChairPrompt", "HideChairPrompt",
		"StartMilkingSession", "StopMilkingSession", 
		"ContinueMilking", "MilkingSessionUpdate",
		"PlayerDataUpdated", "ShowNotification"
	}

	local eventsFound = 0
	for _, eventName in ipairs(requiredEvents) do
		local event = gameRemotes:FindFirstChild(eventName)
		if event then
			eventsFound = eventsFound + 1
			print("✅ Found event: " .. eventName)
		else
			print("⚠️ Missing event: " .. eventName)
		end
	end

	print("📡 Remote events ready: " .. eventsFound .. "/" .. #requiredEvents)
	SystemState.RemoteEventsReady = eventsFound >= (#requiredEvents - 2) -- Allow some missing
	return SystemState.RemoteEventsReady
end

-- ========== STEP 7: SETUP DEBUG COMMANDS ==========

local function SetupSystemDebugCommands()
	print("🔧 Setting up system debug commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/systemstatus" then
					print("=== FIXED SYSTEM STATUS ===")
					print("GameCore loaded: " .. (SystemState.GameCoreLoaded and "✅" or "❌"))
					print("Modules initialized: " .. (SystemState.ModulesInitialized and "✅" or "❌"))
					print("Remote events ready: " .. (SystemState.RemoteEventsReady and "✅" or "❌"))
					print("Systems connected: " .. (SystemState.SystemsConnected and "✅" or "❌"))
					print("")
					print("Global references:")
					print("  _G.GameCore: " .. (_G.GameCore and "✅" or "❌"))
					print("  _G.CowCreationModule: " .. (_G.CowCreationModule and "✅" or "❌"))
					print("  _G.CowMilkingModule: " .. (_G.CowMilkingModule and "✅" or "❌"))
					print("")
					print("Active players: " .. #Players:GetPlayers())

					-- Check workspace models
					local cowCount, chairCount = 0, 0
					for _, obj in pairs(workspace:GetChildren()) do
						if obj.Name:lower():find("cow") then cowCount = cowCount + 1 end
						if obj.Name:lower():find("chair") then chairCount = chairCount + 1 end
					end
					print("Workspace: " .. cowCount .. " cows, " .. chairCount .. " chairs")
					print("============================")

				elseif command == "/reconnect" then
					print("🔄 Attempting system reconnection...")

					-- Re-verify and reconnect
					local success = pcall(function()
						VerifyRemoteEvents()
						WaitForModuleConnections(10)
					end)

					if success then
						print("✅ Reconnection attempt complete")
					else
						print("❌ Reconnection failed")
					end

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

				elseif command == "/forcerescan" then
					print("🔄 Force rescanning systems...")

					if _G.CowCreationModule and _G.CowCreationModule.DetectExistingCows then
						_G.CowCreationModule:DetectExistingCows()
					end

					if _G.CowMilkingModule and _G.CowMilkingModule.DetectExistingChairs then
						_G.CowMilkingModule:DetectExistingChairs()
					end

					print("✅ Rescan complete")
				end
			end
		end)
	end)

	print("✅ System debug commands ready")
end

-- ========== MAIN COORDINATION FUNCTION ==========

local function CoordinateSystemInitialization()
	print("🎯 Starting system coordination...")

	local success, errorMessage = pcall(function()
		-- Step 1: Load GameCore
		local GameCore = LoadGameCore()

		-- Step 2: Verify modules exist
		local modulesFound, moduleCount = VerifyModulesExist()

		-- Step 3: Verify workspace models
		local modelsExist = VerifyWorkspaceModels()

		-- Step 4: Initialize GameCore (this will load and initialize modules)
		InitializeGameCore(GameCore)

		-- Step 5: Wait for modules to connect
		WaitForModuleConnections(15)

		-- Step 6: Verify remote events are ready
		VerifyRemoteEvents()

		-- Step 7: Setup debug commands
		SetupSystemDebugCommands()

		return true
	end)

	if success then
		print("🎉 System coordination completed successfully!")
		print("")
		print("🔧 COORDINATION RESULTS:")
		print("  🎮 GameCore: " .. (SystemState.GameCoreLoaded and "✅" or "❌"))
		print("  📦 Modules: " .. (SystemState.ModulesInitialized and "✅" or "❌"))  
		print("  📡 Remote Events: " .. (SystemState.RemoteEventsReady and "✅" or "❌"))
		print("  🔗 Systems Connected: " .. (SystemState.SystemsConnected and "✅" or "❌"))
		print("")
		print("🎮 Debug Commands:")
		print("  /systemstatus - Show system status")
		print("  /reconnect - Attempt reconnection") 
		print("  /testcow - Test cow assignment")
		print("  /testmilking - Test milking system")
		print("  /forcerescan - Force rescan models")
		return true
	else
		warn("💥 System coordination failed: " .. tostring(errorMessage))
		print("🔄 Attempting minimal fallback...")

		-- Try minimal fallback
		pcall(function()
			local GameCore = LoadGameCore()
			if GameCore then
				InitializeGameCore(GameCore)
				print("⚠️ Running in minimal mode - only GameCore loaded")
			end
		end)
		return false
	end
end

-- ========== EXECUTE COORDINATION ==========

spawn(function()
	wait(2) -- Give scripts time to load

	print("🔧 Starting coordinated initialization in 2 seconds...")

	local success = CoordinateSystemInitialization()

	if success then
		print("✅ All systems coordinated and ready!")
	else
		warn("❌ System coordination incomplete - check debug commands")
	end
end)

-- ========== SHUTDOWN HANDLER ==========

game:BindToClose(function()
	print("🔄 Server shutting down, saving all player data...")

	if _G.GameCore and _G.GameCore.SavePlayerData then
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function()
				_G.GameCore:SavePlayerData(player, true)
			end)
		end
	end

	wait(3)
	print("✅ Shutdown complete")
end)

print("🔧 System Coordinator loaded - coordination will begin in 2 seconds...")