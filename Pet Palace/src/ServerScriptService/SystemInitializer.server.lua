--[[
    SystemInitializer.server.lua - FIXED VERSION
    Place in: ServerScriptService/SystemInitializer.server.lua
    
    FIXES:
    1. Fixed syntax error on line 219
    2. Proper error handling for GameCore initialization
    3. Better module loading sequence
    4. Immediate global availability of GameCore
]]

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("=== Pet Palace System Initializer Starting ===")

-- Load the consolidated core system with better error handling
local function LoadGameCore()
	local success, result = pcall(function()
		return require(ServerScriptService:WaitForChild("Core"):WaitForChild("GameCore"))
	end)

	if not success then
		error("CRITICAL: Failed to load GameCore module: " .. tostring(result))
	end

	if not result or type(result) ~= "table" then
		error("CRITICAL: GameCore module returned invalid data: " .. type(result))
	end

	if type(result.Initialize) ~= "function" then
		error("CRITICAL: GameCore is missing Initialize function")
	end

	return result
end

-- Setup client module in ReplicatedStorage
local function SetupClientModule()
	local existingClient = ReplicatedStorage:FindFirstChild("GameClient")

	if not existingClient then
		print("SystemInitializer: Creating GameClient module in ReplicatedStorage...")

		-- Try to get it from ServerScriptService first
		local clientTemplate = ServerScriptService:FindFirstChild("GameClient")
		if clientTemplate and clientTemplate:IsA("ModuleScript") then
			local clientModule = clientTemplate:Clone()
			clientModule.Parent = ReplicatedStorage
			print("SystemInitializer: Cloned GameClient from template")
		else
			warn("SystemInitializer: No GameClient template found - clients may not work properly")
		end
	end
end

-- Initialize everything
local function InitializeAllSystems()
	print("SystemInitializer: Starting comprehensive initialization...")

	-- Setup client module first
	SetupClientModule()

	-- Load GameCore module
	local GameCore = LoadGameCore()

	-- Make GameCore globally available BEFORE initialization
	_G.GameCore = GameCore
	print("SystemInitializer: GameCore made globally available")

	-- Initialize the core game system
	local initSuccess, errorMsg = pcall(function()
		return GameCore:Initialize()
	end)

	if not initSuccess then
		error("CRITICAL: GameCore initialization failed: " .. tostring(errorMsg))
	end

	-- Verify GameCore is still globally available
	if not _G.GameCore then
		error("CRITICAL: GameCore lost from global scope after initialization")
	end

	-- Create ready signal for clients
	local readyEvent = Instance.new("BindableEvent")
	readyEvent.Name = "GameCoreReady" 
	readyEvent.Parent = ReplicatedStorage

	-- Fire ready event
	spawn(function()
		wait(1) -- Small delay to ensure everything is set up
		readyEvent:Fire(GameCore)
	end)

	print("SystemInitializer: All systems initialized successfully!")
	print("SystemInitializer: GameCore is ready and available globally")

	return GameCore
end

-- Setup error handling for player connections
local function SetupErrorHandling()
	-- Global error handler for player-related operations
	Players.PlayerAdded:Connect(function(player)
		local success, err = pcall(function()
			-- Player initialization is handled by GameCore
			print("SystemInitializer: Player " .. player.Name .. " joined")
		end)

		if not success then
			warn("SystemInitializer: Error with player " .. player.Name .. ": " .. tostring(err))
		end
	end)

	-- Handle server shutdown gracefully
	game:BindToClose(function()
		print("SystemInitializer: Server shutting down, saving all player data...")

		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function()
				if _G.GameCore and _G.GameCore.SavePlayerData then
					_G.GameCore:SavePlayerData(player)
				end
			end)
		end

		wait(2) -- Give time for saves to complete
		print("SystemInitializer: Shutdown complete")
	end)
end

-- Setup development commands (if needed)
local function SetupDevCommands()
	-- Only enable in studio or for authorized users
	if not game:GetService("RunService"):IsStudio() then
		return
	end

	print("SystemInitializer: Setting up development commands...")

	-- Simple admin commands for development
	Players.PlayerAdded:Connect(function(player)
		-- Mark studio users as admin for testing
		if game:GetService("RunService"):IsStudio() then
			player:SetAttribute("Admin", true)
		end

		player.Chatted:Connect(function(message)
			if not player:GetAttribute("Admin") then return end

			local args = string.split(message, " ")
			local command = args[1]:lower()

			if command == "/givecoins" then
				local amount = tonumber(args[2]) or 1000
				if _G.GameCore and _G.GameCore.PlayerData then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData then
						playerData.coins = playerData.coins + amount
						_G.GameCore:UpdatePlayerLeaderstats(player)
						print("Gave " .. amount .. " coins to " .. player.Name)
					end
				end

			elseif command == "/givegems" then
				local amount = tonumber(args[2]) or 100
				if _G.GameCore and _G.GameCore.PlayerData then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData then
						playerData.gems = playerData.gems + amount
						_G.GameCore:UpdatePlayerLeaderstats(player)
						print("Gave " .. amount .. " gems to " .. player.Name)
					end
				end

			elseif command == "/spawnpets" then
				local count = tonumber(args[2]) or 1
				if _G.GameCore then
					for i = 1, count do
						for areaName, _ in pairs(_G.GameCore.Systems.Pets.SpawnAreas) do
							_G.GameCore:SpawnWildPet(areaName)
						end
						wait(0.1)
					end
					print("Spawned " .. count .. " pets in each area for " .. player.Name)
				end

			elseif command == "/reset" then
				-- Reset player data (dangerous!)
				if _G.GameCore and _G.GameCore.PlayerData then
					_G.GameCore.PlayerData[player.UserId] = nil
					player:Kick("Data reset - rejoin to continue")
				end

			elseif command == "/checkgamecore" then
				-- Debug command to check GameCore status
				if _G.GameCore then
					print("GameCore Status: ACTIVE")
					print("Players in data: " .. (#_G.GameCore.PlayerData or 0))
					print("Spawn areas: " .. (#_G.GameCore.Systems.Pets.SpawnAreas or 0))
				else
					print("GameCore Status: NOT FOUND")
				end
			end
		end)
	end)
end

-- Performance Monitoring
local function SetupPerformanceMonitoring()
	spawn(function()
		while true do
			wait(60) -- Check every minute

			local playerCount = #Players:GetPlayers()
			local memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()

			print(string.format("SystemInitializer: Performance - Players: %d, Memory: %.1f MB", 
				playerCount, memoryUsage))

			-- Check GameCore status
			if not _G.GameCore then
				warn("SystemInitializer: CRITICAL - GameCore lost from global scope!")
			end

			-- Warn if memory usage is high
			if memoryUsage > 1000 then
				warn("SystemInitializer: High memory usage detected: " .. memoryUsage .. " MB")
			end
		end
	end)
end

-- Main initialization sequence
local function Main()
	print("SystemInitializer: Starting main initialization sequence...")

	-- Initialize all systems
	local GameCore = InitializeAllSystems()

	-- Verify GameCore is available
	if not _G.GameCore then
		error("CRITICAL: GameCore not available in global scope after initialization")
	end

	-- Setup additional systems
	SetupErrorHandling()
	SetupDevCommands()
	SetupPerformanceMonitoring()

	print("=== Pet Palace System Initializer Complete ===")
	print("Game is ready for players!")
	print("GameCore Status: " .. (_G.GameCore and "ACTIVE" or "MISSING"))

	return GameCore
end

-- Run with comprehensive error handling
local initSuccess, initError = pcall(Main)

if not initSuccess then
	-- Print detailed error information
	warn("=== CRITICAL SYSTEM FAILURE ===")
	warn("Error: " .. tostring(initError))
	warn("GameCore Status: " .. (_G.GameCore and "Available" or "Not Available"))

	-- Try to provide helpful debug info
	local coreExists = ServerScriptService:FindFirstChild("Core")
	local gameCoreExists = coreExists and coreExists:FindFirstChild("GameCore")

	warn("Core folder exists: " .. (coreExists and "Yes" or "No"))
	warn("GameCore module exists: " .. (gameCoreExists and "Yes" or "No"))

	error("CRITICAL SYSTEM FAILURE: " .. tostring(initError))
else
	print("SystemInitializer: All systems operational")
	print("✅ GameCore successfully initialized and globally available")

	-- Final verification
	if _G.GameCore then
		print("✅ Global GameCore verification: SUCCESS")
	else
		error("❌ Global GameCore verification: FAILED")
	end
end