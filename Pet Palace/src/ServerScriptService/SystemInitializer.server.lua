--[[
    Simple SystemInitializer.server.lua - Robust and Error-Safe
    Place in: ServerScriptService/SystemInitializer.server.lua
    
    This version focuses on stability and proper error handling
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🚀 === Pet Palace Simple Initializer Starting ===")

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
	print("🔧 Starting system initialization...")

	-- Load required modules
	local GameCore = LoadGameCore()
	if not GameCore then
		error("❌ GameCore is required but failed to load")
	end

	-- Load optional modules
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
		print("🔧 Initializing CowCreationModule...")

		local ItemConfig = nil
		local itemConfigModule = ReplicatedStorage:FindFirstChild("ItemConfig")
		if itemConfigModule then
			ItemConfig = SafeRequire(itemConfigModule, "ItemConfig")
		end

		if CowCreationModule.Initialize then
			local cowCreationSuccess = CowCreationModule:Initialize(GameCore, ItemConfig)
			if cowCreationSuccess then
				print("✅ CowCreationModule initialized successfully")
				_G.CowCreationModule = CowCreationModule
			else
				warn("⚠️ CowCreationModule initialization failed")
			end
		end
	end

	-- Initialize CowMilkingModule if available
	if CowMilkingModule then
		print("🔧 Initializing CowMilkingModule...")

		if CowMilkingModule.Initialize then
			local milkingSuccess = CowMilkingModule:Initialize(GameCore, CowCreationModule)
			if milkingSuccess then
				print("✅ CowMilkingModule initialized successfully")
				_G.CowMilkingModule = CowMilkingModule
			else
				warn("⚠️ CowMilkingModule initialization failed")
			end
		end
	end

	print("🎉 System initialization complete!")
	return true
end

-- ========== PLAYER HANDLERS ==========

local function SetupPlayerHandlers()
	print("👥 Setting up player handlers...")

	Players.PlayerAdded:Connect(function(player)
		print("👋 Player " .. player.Name .. " joined")

		-- Give starter cow after delay
		spawn(function()
			wait(5) -- Give time for everything to load

			if _G.CowCreationModule and _G.CowCreationModule.GiveStarterCow then
				local success = pcall(function()
					return _G.CowCreationModule:GiveStarterCow(player)
				end)

				if success then
					print("✅ Starter cow process initiated for " .. player.Name)
				else
					print("ℹ️ Starter cow skipped for " .. player.Name .. " (may already have cow)")
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
					print("=== SYSTEM STATUS ===")
					print("GameCore: " .. (_G.GameCore and "✅" or "❌"))
					print("CowCreationModule: " .. (_G.CowCreationModule and "✅" or "❌"))
					print("CowMilkingModule: " .. (_G.CowMilkingModule and "✅" or "❌"))
					print("Player count: " .. #Players:GetPlayers())

					if _G.CowMilkingModule and _G.CowMilkingModule.GetSystemStatus then
						local status = _G.CowMilkingModule:GetSystemStatus()
						print("Milking sessions: " .. status.activeSessions.count)
						print("Milking chairs: " .. status.chairs.count)
					end
					print("====================")

				elseif command == "/givecow" then
					if _G.CowCreationModule and _G.CowCreationModule.ForceGiveStarterCow then
						local success = _G.CowCreationModule:ForceGiveStarterCow(player)
						print("Give cow result: " .. tostring(success))
					end

				elseif command == "/testmilking" then
					if _G.CowMilkingModule and _G.CowMilkingModule.ForceStartMilkingForDebug then
						local success = _G.CowMilkingModule:ForceStartMilkingForDebug(player, "test_cow_" .. player.UserId)
						print("Test milking result: " .. tostring(success))
					end

				elseif command == "/chairs" then
					if _G.CowMilkingModule and _G.CowMilkingModule.MilkingChairs then
						local chairCount = 0
						for chairId, seatPart in pairs(_G.CowMilkingModule.MilkingChairs) do
							chairCount = chairCount + 1
							print("Chair " .. chairCount .. ": " .. chairId .. " at " .. tostring(seatPart.Position))
						end
						print("Total chairs: " .. chairCount)
					end

				elseif command == "/debugchairs" then
					if _G.CowMilkingModule and _G.CowMilkingModule.DebugExistingChairs then
						_G.CowMilkingModule:DebugExistingChairs()
					end

				elseif command == "/rescanchairs" then
					if _G.CowMilkingModule and _G.CowMilkingModule.ForceRescanChairs then
						local found = _G.CowMilkingModule:ForceRescanChairs()
						print("✅ Rescanned chairs - found: " .. found)
					end
				end
			end
		end)
	end)

	print("✅ Debug commands ready")
end

-- ========== MAIN EXECUTION ==========

local function Main()
	local success, errorMessage = pcall(function()
		InitializeSystem()
		SetupPlayerHandlers()
		SetupDebugCommands()
	end)

	if success then
		print("🎉 Pet Palace is ready!")
		print("")
		print("🎮 Debug Commands:")
		print("  /status - System status")
		print("  /givecow - Give starter cow")
		print("  /testmilking - Test milking")
		print("  /chairs - List chairs")
		print("  /debugchairs - Debug existing chairs")
		print("  /rescanchairs - Rescan for chairs")
		print("")
		print("🐄 Cow system should be working!")
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

print("🔧 Simple initializer loaded, starting in 1 second...")