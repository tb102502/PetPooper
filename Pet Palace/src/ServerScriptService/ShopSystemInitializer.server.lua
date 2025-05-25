--[[
    ShopSystemInitializer.server.lua
    Initializes the consolidated ShopSystem
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
]]

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load the core module
local ShopSystemCore

-- Set up the remote events and functions first
local function SetupRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("ShopSystem")

	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "ShopSystem"
		remoteFolder.Parent = ReplicatedStorage
		print("ShopSystemInitializer: Created ShopSystem folder in ReplicatedStorage")
	end

	-- Set up remote events
	local events = {
		"PurchaseItem",
		"CurrencyUpdated",
		"ItemPurchased",
		"PremiumPurchased",
		"BoosterActivated",
		"BoosterExpired"
	}

	for _, eventName in ipairs(events) do
		if not remoteFolder:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
			print("ShopSystemInitializer: Created remote event: " .. eventName)
		end
	end

	-- Set up remote functions
	local functions = {
		"GetShopItems",
		"GetPlayerCurrency",
		"GetActiveBoosts"
	}

	for _, funcName in ipairs(functions) do
		if not remoteFolder:FindFirstChild(funcName) then
			local func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
			print("ShopSystemInitializer: Created remote function: " .. funcName)
		end
	end

	return remoteFolder
end

-- Try loading the core module
print("ShopSystemInitializer: Setting up remotes first...")
local remotesFolder = SetupRemotes()

print("ShopSystemInitializer: Attempting to load ShopSystemCore...")
local success, errorMsg = pcall(function()
	ShopSystemCore = require(ServerScriptService.Modules.ShopSystemCore)
end)

if not success then
	warn("ShopSystemInitializer: Failed to load ShopSystemCore: " .. tostring(errorMsg))
	return
end

-- Set up connections to other systems
local function ConnectToExistingEvents()
	-- Connect to PetSystem if available
	local petSystem = _G.PetSystemCore

	if petSystem then
		print("ShopSystemInitializer: PetSystem found, connecting events")

		-- Example: Connect pet purchase events to add currency when pets are collected
		if petSystem.Remotes and petSystem.Remotes.Events and petSystem.Remotes.Events.PetAdded then
			petSystem.Remotes.Events.PetAdded.OnServerEvent:Connect(function(player, petId, petData)
				-- Award coins for getting a new pet
				ShopSystemCore:AddCurrency(player, "Coins", 10)
			end)
		end
	else
		print("ShopSystemInitializer: PetSystem not found")
	end

	-- Other system connections could be added here
end

-- Set up any additional UI elements
local function SetupShopUI()
	-- Create shop button in StarterGui if needed
	local StarterGui = game:GetService("StarterGui")
	local existingUI = StarterGui:FindFirstChild("ShopButton")

	if not existingUI then
		-- This is just a placeholder for where you might add UI setup code
		-- Typically you'd have separate UI scripts rather than creating UI here
		print("ShopSystemInitializer: Shop UI setup would go here")
	end
end

-- Connect to currency earning events in the game
local function SetupCurrencyEvents()
	-- Example: Award coins for playtime
	spawn(function()
		while true do
			wait(300) -- 5 minutes
			for _, player in ipairs(Players:GetPlayers()) do
				ShopSystemCore:AddCurrency(player, "Coins", 50)
				print("ShopSystemInitializer: Awarded 50 Coins to " .. player.Name .. " for playtime")
			end
		end
	end)

	-- Example: Award coins for joining the game
	Players.PlayerAdded:Connect(function(player)
		-- Give a small welcome bonus
		wait(5) -- Wait for player data to load
		ShopSystemCore:AddCurrency(player, "Coins", 25)
		print("ShopSystemInitializer: Awarded 25 Coins to " .. player.Name .. " for joining")
	end)
end

-- Share the ShopSystem with other scripts
_G.ShopSystemCore = ShopSystemCore

-- Initialize the shop system
print("ShopSystemInitializer: Starting initialization...")
ShopSystemCore:Initialize()
ConnectToExistingEvents()
SetupCurrencyEvents()
print("ShopSystemInitializer: Initialization complete")