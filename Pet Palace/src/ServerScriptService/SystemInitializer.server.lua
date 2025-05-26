--[[
    SystemInitializer.server.lua - SINGLE SYSTEM INITIALIZER
    Place in: ServerScriptService/SystemInitializer.server.lua
    
    This replaces ALL individual system initializers:
    - PetSystemInitializer
    - ShopSystemInitializer  
    - FarmingServer
    - Various other init scripts
    
    Single point of initialization for the entire game
]]

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("=== Pet Palace System Initializer Starting ===")

-- Load the consolidated core system
local GameCore
local success, result = pcall(function()
	return require(ServerScriptService:WaitForChild("Core"):WaitForChild("GameCore"))
end)

if not success then
	error("CRITICAL: Failed to load GameCore: " .. tostring(result))
end

GameCore = result

-- Validate GameCore structure
if not GameCore or typeof(GameCore.Initialize) ~= "function" then
	error("CRITICAL: GameCore is missing or malformed")
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

	-- Initialize the core game system
	local initSuccess, errorMsg = pcall(function()
		return GameCore:Initialize()
	end)

	if not initSuccess then
		error("CRITICAL: GameCore initialization failed: " .. tostring(errorMsg))
	end

	-- Make GameCore globally available
	_G.GameCore = GameCore

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

	return true
end

-- Setup error handling for player connections
local function SetupErrorHandling()
	-- Global error handler for player-related operations
	Players.PlayerAdded:Connect(function(player)
		local success, err = pcall(function()
			-- Player initialization is handled by GameCore
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
				if GameCore and GameCore.SavePlayerData then
					GameCore:SavePlayerData(player)
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
				if GameCore and GameCore.AddCurrency then
					GameCore:AddCurrency(player, "coins", amount)
					print("Gave " .. amount .. " coins to " .. player.Name)
				end

			elseif command == "/givegems" then
				local amount = tonumber(args[2]) or 100
				if GameCore and GameCore.AddCurrency then
					GameCore:AddCurrency(player, "gems", amount)
					print("Gave " .. amount .. " gems to " .. player.Name)
				end

			elseif command == "/spawnpet" then
				local petType = args[2] or "bunny"
				if GameCore and GameCore.AdminSpawnPet then
					local character = player.Character
					if character and character:FindFirstChild("HumanoidRootPart") then
						local position = character.HumanoidRootPart.Position + Vector3.new(5, 0, 0)
						GameCore:AdminSpawnPet(player, petType, position)
						print("Spawned " .. petType .. " for " .. player.Name)
					end
				end

			elseif command == "/reset" then
				-- Reset player data (dangerous!)
				if GameCore and GameCore.PlayerData then
					GameCore.PlayerData[player.UserId] = nil
					player:Kick("Data reset - rejoin to continue")
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
	InitializeAllSystems()

	-- Setup additional systems
	SetupErrorHandling()
	SetupDevCommands()
	SetupPerformanceMonitoring()

	print("=== Pet Palace System Initializer Complete ===")
	print("Game is ready for players!")
end

-- Run with error handling
local success, error = pcall(Main)

if not success then
	error("CRITICAL SYSTEM FAILURE: " .. tostring(error))
else
	print("SystemInitializer: All systems operational")
end