--[[
    SystemInitializer.server.lua - FIXED VERSION
    Place in: ServerScriptService/SystemInitializer.server.lua
    
    CRITICAL FIXES:
    1. ✅ Fixed all syntax errors
    2. ✅ Proper error handling and recovery
    3. ✅ Better module loading sequence
    4. ✅ Immediate global availability of GameCore
    5. ✅ Comprehensive validation
]]

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
		print("SystemInitializer: GameClient not found in ReplicatedStorage")
		print("SystemInitializer: Make sure to place GameClient.lua in ReplicatedStorage manually")
	else
		print("SystemInitializer: Found existing GameClient module")
	end
end

-- Validate required folder structure
local function ValidateStructure()
	print("SystemInitializer: Validating server structure...")

	-- Check Core folder
	local coreFolder = ServerScriptService:FindFirstChild("Core")
	if not coreFolder then
		error("CRITICAL: Core folder not found in ServerScriptService")
	end

	-- Check GameCore module
	local gameCoreModule = coreFolder:FindFirstChild("GameCore")
	if not gameCoreModule then
		error("CRITICAL: GameCore module not found in ServerScriptService/Core")
	end

	-- Check Config folder
	local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
	if not ItemConfig then
		error("CRITICAL: Config folder not found in ServerScriptService")
	end

	-- Check ItemConfig
	local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))

	print("SystemInitializer: Structure validation passed")
	return true
end

-- Initialize everything
local function InitializeAllSystems()
	print("SystemInitializer: Starting comprehensive initialization...")

	-- Validate structure first
	ValidateStructure()

	-- Setup client module
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
	local readyEvent = ReplicatedStorage:FindFirstChild("GameCoreReady")
	if not readyEvent then
		readyEvent = Instance.new("BindableEvent")
		readyEvent.Name = "GameCoreReady" 
		readyEvent.Parent = ReplicatedStorage
	end

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

		if _G.GameCore and _G.GameCore.SavePlayerData then
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(function()
					_G.GameCore:SavePlayerData(player)
				end)
			end
		end

		wait(2) -- Give time for saves to complete
		print("SystemInitializer: Shutdown complete")
	end)
end

-- Setup development commands (if needed)
local function SetupDevCommands()
	-- Only enable in studio or for specific users
	if not RunService:IsStudio() then
		return
	end

	print("SystemInitializer: Setting up development commands...")

	-- Simple admin commands for development
	Players.PlayerAdded:Connect(function(player)
		-- Mark studio users as admin for testing
		if RunService:IsStudio() then
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
					local playerCount = 0
					for _ in pairs(_G.GameCore.PlayerData or {}) do
						playerCount = playerCount + 1
					end
					print("Players in data: " .. playerCount)

					local areaCount = 0
					for _ in pairs(_G.GameCore.Systems.Pets.SpawnAreas or {}) do
						areaCount = areaCount + 1
					end
					print("Spawn areas: " .. areaCount)
				else
					print("GameCore Status: NOT FOUND")
				end

			elseif command == "/clearpets" then
				-- Clear all pets from all areas
				if _G.GameCore then
					for areaName, areaData in pairs(_G.GameCore.Systems.Pets.SpawnAreas) do
						if areaData.container then
							areaData.container:ClearAllChildren()
						end
					end
					print("Cleared all pets from all areas")
				end

			elseif command == "/testshop" then
				-- Test shop purchase
				if _G.GameCore then
					_G.GameCore:HandlePurchase(player, "speed_upgrade", 1)
				end
			elseif command == "/testseeds" then
				-- Give test seeds for debugging
				if _G.GameCore then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData then
						if not playerData.farming then
							playerData.farming = {inventory = {}}
						end
						if not playerData.farming.inventory then
							playerData.farming.inventory = {}
						end

						playerData.farming.inventory.carrot_seeds = 10
						playerData.farming.inventory.corn_seeds = 5
						playerData.farming.inventory.strawberry_seeds = 3

						_G.GameCore:SavePlayerData(player)
						_G.GameCore:SendNotification(player, "Test Seeds Given", 
							"Added seeds to your farming inventory!", "success")

						-- Force update client
						if _G.GameCore.RemoteEvents.PlayerDataUpdated then
							_G.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
						end
					end
				end

			elseif command == "/debuginventory" then
				-- Debug farming inventory
				if _G.GameCore then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData and playerData.farming and playerData.farming.inventory then
						print("=== FARMING INVENTORY DEBUG ===")
						for seedId, quantity in pairs(playerData.farming.inventory) do
							print(seedId .. ": " .. quantity)
						end
						print("================================")
					else
						print("No farming inventory found for " .. player.Name)
					end
				end

			elseif command == "/maxupgrades" then
				-- Give max upgrades for testing
				if _G.GameCore then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData then
						playerData.upgrades = {
							speed_upgrade = 5,
							collection_radius_upgrade = 5,
							pet_magnet_upgrade = 5,
							farm_plot_upgrade = 3,
							pet_storage_upgrade = 5
						}
						_G.GameCore:ApplyAllUpgradeEffects(player)
						print("Applied max upgrades to " .. player.Name)
					end
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
			else
				-- Count active pets
				local totalPets = 0
				local totalConnections = 0

				if _G.GameCore.Systems and _G.GameCore.Systems.Pets then
					for _, areaData in pairs(_G.GameCore.Systems.Pets.SpawnAreas or {}) do
						if areaData.container then
							totalPets = totalPets + #areaData.container:GetChildren()
						end
					end

					for _ in pairs(_G.GameCore.Systems.Pets.BehaviorConnections or {}) do
						totalConnections = totalConnections + 1
					end
				end

				print(string.format("SystemInitializer: Game Stats - Pets: %d, Connections: %d", 
					totalPets, totalConnections))
			end

			-- Warn if memory usage is high
			if memoryUsage > 1000 then
				warn("SystemInitializer: High memory usage detected: " .. memoryUsage .. " MB")
			end
		end
	end)
end

-- Setup automatic error recovery
local function SetupErrorRecovery()
	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			-- Check if GameCore is still available
			if not _G.GameCore then
				warn("SystemInitializer: GameCore missing - attempting recovery...")

				local success, newGameCore = pcall(LoadGameCore)
				if success then
					_G.GameCore = newGameCore
					print("SystemInitializer: GameCore recovered successfully")
				else
					warn("SystemInitializer: Failed to recover GameCore: " .. tostring(newGameCore))
				end
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
	SetupErrorRecovery()

	print("=== Pet Palace System Initializer Complete ===")
	print("Game is ready for players!")
	print("GameCore Status: " .. (_G.GameCore and "ACTIVE" or "MISSING"))

	-- Print debug commands available
	if RunService:IsStudio() then
		print("\n=== DEBUG COMMANDS AVAILABLE ===")
		print("/givecoins [amount] - Give coins to player")
		print("/givegems [amount] - Give gems to player")
		print("/spawnpets [count] - Spawn pets in all areas")
		print("/reset - Reset player data (WARNING: Dangerous!)")
		print("/checkgamecore - Check GameCore status")
		print("/clearpets - Clear all pets from workspace")
		print("/testshop - Test shop purchase")
		print("/maxupgrades - Give max upgrades for testing")
		print("=================================")
	end

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
	local itemConfigExists = ReplicatedStorage:FindFirstChild("ItemConfig")

	warn("Core folder exists: " .. (coreExists and "Yes" or "No"))
	warn("GameCore module exists: " .. (gameCoreExists and "Yes" or "No"))
	warn("ItemConfig module exists: " .. (itemConfigExists and "Yes" or "No"))

	-- Try to provide solutions
	if not coreExists then
		warn("SOLUTION: Create ServerScriptService/Core/ folder and place GameCore.lua inside")
	
	end
	if not gameCoreExists then
		warn("SOLUTION: Place GameCore.lua in ServerScriptService/Core/")
	end
	if not itemConfigExists then
		warn("SOLUTION: Place ItemConfig.lua in ServerScriptService/Config/")
	end

	error("CRITICAL SYSTEM FAILURE: " .. tostring(initError))
else
	print("SystemInitializer: All systems operational")
	print("✅ GameCore successfully initialized and globally available")

	-- Final verification
	if _G.GameCore then
		print("✅ Global GameCore verification: SUCCESS")

		-- Test basic functionality
		if _G.GameCore.Systems then
			print("✅ GameCore systems initialized: SUCCESS")
		else
			warn("⚠️  GameCore systems not properly initialized")
		end

		if _G.GameCore.RemoteEvents then
			local eventCount = 0
			for _ in pairs(_G.GameCore.RemoteEvents) do
				eventCount = eventCount + 1
			end
			print("✅ Remote events created: " .. eventCount)
		else
			warn("⚠️  Remote events not properly created")
		end

	else
		error("❌ Global GameCore verification: FAILED")
	end
end