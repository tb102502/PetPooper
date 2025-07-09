--[[
    FIXED SystemInitializer.server.lua - Works with Existing Models
    Place in: ServerScriptService/SystemInitializer.server.lua
    
    FIXES:
    ✅ Updated for working with existing cow and chair models
    ✅ Proper module loading order
    ✅ Better error handling
    ✅ Debug commands for troubleshooting
    ✅ No model creation - only detection and setup
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🚀 === Pet Palace FIXED Initializer Starting ===")

-- ========== SAFE MODULE LOADING ==========

local function SafeRequire(moduleScript, moduleName)
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

local function LoadGameCore()
	print("🎮 Loading GameCore...")

	local coreFolder = ServerScriptService:FindFirstChild("Core")
	if not coreFolder then
		error("❌ Core folder not found in ServerScriptService")
	end

	local gameCoreModule = coreFolder:FindFirstChild("GameCore")
	if not gameCoreModule then
		error("❌ GameCore module not found in Core folder")
	end

	return SafeRequire(gameCoreModule, "GameCore")
end

local function LoadOptionalModule(path, name)
	local module = ServerScriptService:FindFirstChild(path)
	if module then
		return SafeRequire(module, name)
	else
		print("ℹ️ " .. name .. " not found (optional)")
		return nil
	end
end

-- ========== MAIN INITIALIZATION ==========

local function InitializeSystem()
	print("🔧 Starting FIXED system initialization...")

	-- Load required modules
	local GameCore = LoadGameCore()
	if not GameCore then
		error("❌ GameCore is required but failed to load")
	end

	-- Load cow modules (now working with existing models)
	local CowCreationModule = LoadOptionalModule("CowCreationModule", "CowCreationModule")
	local CowMilkingModule = LoadOptionalModule("CowMilkingModule", "CowMilkingModule")

	-- Initialize GameCore first
	print("🔧 Initializing GameCore...")
	local gameCoreSuccess = false

	if GameCore.Initialize then
		gameCoreSuccess = GameCore:Initialize()
	else
		warn("❌ GameCore.Initialize function not found")
	end

	if gameCoreSuccess then
		print("✅ GameCore initialized successfully")
		_G.GameCore = GameCore
	else
		error("❌ GameCore initialization failed")
	end

	-- Initialize CowCreationModule if available
	if CowCreationModule then
		print("🔧 Initializing CowCreationModule (existing model detection)...")

		local ItemConfig = nil
		local itemConfigModule = ReplicatedStorage:FindFirstChild("ItemConfig")
		if itemConfigModule then
			ItemConfig = SafeRequire(itemConfigModule, "ItemConfig")
		end

		if CowCreationModule.Initialize then
			local cowCreationSuccess = CowCreationModule:Initialize(GameCore, ItemConfig)
			if cowCreationSuccess then
				print("✅ CowCreationModule initialized successfully")
				print("🐄 Existing cow models detected and setup")
				_G.CowCreationModule = CowCreationModule
			else
				warn("⚠️ CowCreationModule initialization failed")
			end
		end
	end

	-- Initialize CowMilkingModule if available
	if CowMilkingModule then
		print("🔧 Initializing CowMilkingModule (10-click system)...")

		if CowMilkingModule.Initialize then
			local milkingSuccess = CowMilkingModule:Initialize(GameCore, CowCreationModule)
			if milkingSuccess then
				print("✅ CowMilkingModule initialized successfully")
				print("🖱️ 10-click milking system ready")
				print("🪑 Existing MilkingChair models detected")
				_G.CowMilkingModule = CowMilkingModule
			else
				warn("⚠️ CowMilkingModule initialization failed")
			end
		end
	end

	print("🎉 FIXED system initialization complete!")
	return true
end

-- ========== PLAYER HANDLERS ==========

local function SetupPlayerHandlers()
	print("👥 Setting up player handlers...")

	Players.PlayerAdded:Connect(function(player)
		print("👋 Player " .. player.Name .. " joined")

		-- Give starter cow after delay (assigns existing cow to player)
		spawn(function()
			wait(5) -- Give time for everything to load

			if _G.CowCreationModule and _G.CowCreationModule.GiveStarterCow then
				local success = pcall(function()
					return _G.CowCreationModule:GiveStarterCow(player)
				end)

				if success then
					print("✅ Starter cow assigned to " .. player.Name)
				else
					print("ℹ️ Starter cow assignment skipped for " .. player.Name .. " (may already have cow)")
				end
			end
		end)
	end)

	-- Handle server shutdown
	game:BindToClose(function()
		print("🔄 Server shutting down...")

		if _G.GameCore and _G.GameCore.SavePlayerData then
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(function() 
					_G.GameCore:SavePlayerData(player, true)
				end)
			end
		end

		wait(2)
		print("✅ Shutdown complete")
	end)

	print("✅ Player handlers setup complete")
end

-- ========== DEBUG COMMANDS ==========

local function SetupDebugCommands()
	print("🔧 Setting up debug commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/status" then
					print("=== FIXED SYSTEM STATUS ===")
					print("GameCore: " .. (_G.GameCore and "✅" or "❌"))
					print("CowCreationModule: " .. (_G.CowCreationModule and "✅" or "❌"))
					print("CowMilkingModule: " .. (_G.CowMilkingModule and "✅" or "❌"))
					print("Player count: " .. #Players:GetPlayers())

					-- Check existing models in workspace
					local cowCount = 0
					local chairCount = 0
					for _, obj in pairs(workspace:GetChildren()) do
						if obj.Name == "cow" or obj.Name:lower():find("cow") then
							cowCount = cowCount + 1
						end
						if obj.Name == "MilkingChair" then
							chairCount = chairCount + 1
						end
					end
					print("Existing cows in workspace: " .. cowCount)
					print("Existing chairs in workspace: " .. chairCount)

					if _G.CowMilkingModule and _G.CowMilkingModule.GetSystemStatus then
						local status = _G.CowMilkingModule:GetSystemStatus()
						print("Milking sessions: " .. status.activeSessions.count)
						print("Detected chairs: " .. status.chairs.count)
						print("Clicks per milk: " .. status.config.clicksPerMilk)
					end

					if _G.CowCreationModule then
						print("Active cows tracked: " .. (_G.CowCreationModule.CountTable and _G.CowCreationModule:CountTable(_G.CowCreationModule.ActiveCows) or "Unknown"))
					end
					print("============================")

				elseif command == "/givecow" then
					if _G.CowCreationModule and _G.CowCreationModule.ForceGiveStarterCow then
						local success = _G.CowCreationModule:ForceGiveStarterCow(player)
						print("Give cow result: " .. tostring(success))
					end

				elseif command == "/testmilking" then
					print("Testing milking system...")
					if _G.CowMilkingModule then
						print("CowMilkingModule available - check for working chairs and cows")
						if _G.CowMilkingModule.DebugStatus then
							_G.CowMilkingModule:DebugStatus()
						end
					end

				elseif command == "/chairs" then
					print("=== CHAIR DEBUG ===")
					local workspaceChairs = 0
					for _, obj in pairs(workspace:GetChildren()) do
						if obj.Name == "MilkingChair" then
							workspaceChairs = workspaceChairs + 1
							print("Found MilkingChair at: " .. tostring(obj.Position))
						end
					end
					print("Chairs in workspace: " .. workspaceChairs)

					if _G.CowMilkingModule and _G.CowMilkingModule.MilkingChairs then
						local trackedChairs = 0
						for chairId, seatPart in pairs(_G.CowMilkingModule.MilkingChairs) do
							trackedChairs = trackedChairs + 1
							print("Tracked chair: " .. chairId .. " at " .. tostring(seatPart.Position))
						end
						print("Tracked chairs: " .. trackedChairs)
					end
					print("===================")

				elseif command == "/cows" then
					print("=== COW DEBUG ===")
					local workspaceCows = 0
					for _, obj in pairs(workspace:GetChildren()) do
						if obj.Name == "cow" or obj.Name:lower():find("cow") then
							workspaceCows = workspaceCows + 1
							print("Found cow: " .. obj.Name .. " at " .. tostring(obj:GetPivot().Position))
							print("  Owner: " .. (obj:GetAttribute("Owner") or "Unowned"))
							print("  Setup: " .. (obj:GetAttribute("IsSetup") and "Yes" or "No"))
						end
					end
					print("Cows in workspace: " .. workspaceCows)

					if _G.CowCreationModule and _G.CowCreationModule.ActiveCows then
						local trackedCows = 0
						for cowId, cowModel in pairs(_G.CowCreationModule.ActiveCows) do
							trackedCows = trackedCows + 1
							print("Tracked cow: " .. cowId)
							print("  Position: " .. tostring(cowModel:GetPivot().Position))
							print("  Owner: " .. (cowModel:GetAttribute("Owner") or "Unowned"))
						end
						print("Tracked cows: " .. trackedCows)
					end
					print("=================")

				elseif command == "/rescan" then
					print("🔄 Rescanning existing models...")

					if _G.CowCreationModule and _G.CowCreationModule.DetectExistingCows then
						_G.CowCreationModule:DetectExistingCows()
						print("✅ Cow rescan complete")
					end

					if _G.CowMilkingModule and _G.CowMilkingModule.DetectExistingChairs then
						_G.CowMilkingModule:DetectExistingChairs()
						print("✅ Chair rescan complete")
					end

				elseif command == "/proximity" then
					if _G.CowMilkingModule and _G.CowMilkingModule.UpdatePlayerProximityState then
						_G.CowMilkingModule:UpdatePlayerProximityState(player)
						print("✅ Updated proximity state for " .. player.Name)
					end

				elseif command == "/debugcow" then
					if _G.DebugCowCreation then
						_G.DebugCowCreation()
					end

				elseif command == "/debugmilking" then
					if _G.DebugMilking then
						_G.DebugMilking()
					end

				elseif command == "/resetdata" then
					if _G.GameCore and _G.GameCore.GetPlayerData then
						local playerData = _G.GameCore:GetPlayerData(player)
						if playerData then
							playerData.livestock = nil
							_G.GameCore:SavePlayerData(player)
							print("✅ Reset livestock data for " .. player.Name)
						end
					end
				end
			end
		end)
	end)

	print("✅ Debug commands ready")
end

-- ========== WORKSPACE MODEL VERIFICATION ==========

local function VerifyWorkspaceModels()
	print("🔍 Verifying workspace models...")

	local cowsFound = 0
	local chairsFound = 0

	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == "cow" or obj.Name:lower():find("cow") then
			cowsFound = cowsFound + 1
			print("📍 Found cow: " .. obj.Name .. " at " .. tostring(obj:GetPivot().Position))
		end

		if obj.Name == "MilkingChair" then
			chairsFound = chairsFound + 1
			print("📍 Found chair: " .. obj.Name .. " at " .. tostring(obj.Position))
		end
	end

	print("🐄 Total cows found: " .. cowsFound)
	print("🪑 Total chairs found: " .. chairsFound)

	if cowsFound == 0 then
		warn("⚠️ No cow models found in workspace! Please add a model named 'cow'")
	end

	if chairsFound == 0 then
		warn("⚠️ No MilkingChair models found in workspace! Please add a model named 'MilkingChair'")
	end

	return cowsFound > 0 and chairsFound > 0
end

-- ========== MAIN EXECUTION ==========

local function Main()
	local success, errorMessage = pcall(function()
		-- Verify required models exist
		local modelsExist = VerifyWorkspaceModels()
		if not modelsExist then
			warn("⚠️ Required models missing - system will still initialize but may not function properly")
		end

		InitializeSystem()
		SetupPlayerHandlers()
		SetupDebugCommands()
	end)

	if success then
		print("🎉 Pet Palace FIXED system is ready!")
		print("")
		print("🐄 COW SYSTEM FEATURES:")
		print("  📍 Works with existing 'cow' models in workspace")
		print("  👤 Automatic cow ownership assignment")
		print("  🖱️ 10-click milking system (10 clicks = 1 milk)")
		print("  📊 Real-time progress tracking")
		print("  🪑 Works with existing 'MilkingChair' models")
		print("")
		print("🎮 Debug Commands:")
		print("  /status - System status")
		print("  /givecow - Give starter cow")
		print("  /testmilking - Test milking system")
		print("  /chairs - List chairs")
		print("  /cows - List cows")
		print("  /rescan - Rescan for models")
		print("  /proximity - Update proximity")
		print("  /debugcow - Debug cow system")
		print("  /debugmilking - Debug milking system")
		print("  /resetdata - Reset livestock data")
		print("")
		print("🔧 HOW IT WORKS:")
		print("  1. Player approaches their cow")
		print("  2. Proximity message appears")
		print("  3. Player sits in MilkingChair")
		print("  4. 10-click milking session starts")
		print("  5. Progress bar shows clicks (0-10)")
		print("  6. Every 10 clicks = 1 milk collected")
		return true
	else
		warn("💥 Initialization failed: " .. tostring(errorMessage))
		return false
	end
end

-- Execute with error protection
spawn(function()
	wait(1) -- Give other scripts time to load

	local success, err = pcall(Main)

	if not success then
		warn("🚨 CRITICAL ERROR: " .. tostring(err))
		warn("🔄 Attempting minimal fallback...")

		-- Try just GameCore as fallback
		pcall(function()
			local GameCore = LoadGameCore()
			if GameCore and GameCore.Initialize then
				GameCore:Initialize()
				_G.GameCore = GameCore
				print("⚠️ Running in minimal mode - only GameCore loaded")
			end
		end)
	end
end)

print("🔧 FIXED initializer loaded, starting in 1 second...")