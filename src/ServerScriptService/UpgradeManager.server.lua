-- UpgradeManager.server.lua
-- Place this in ServerScriptService
-- Handles server-side upgrade management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Get or create the module
local UpgradeSystem
if ReplicatedStorage:FindFirstChild("UpgradeSystem") then
	UpgradeSystem = require(ReplicatedStorage.UpgradeSystem)
else
	-- Create the module if it doesn't exist
	local moduleScript = Instance.new("ModuleScript")
	moduleScript.Name = "UpgradeSystem"
	moduleScript.Parent = ReplicatedStorage
	warn("UpgradeSystem module not found in ReplicatedStorage. Created an empty one.")
	-- You should copy the module code into this script
end

-- Load the MainGameModule (assuming it exists)
local MainGameModule = script.Parent:FindFirstChild("MainGameModule") and 
	require(script.Parent.MainGameModule) or nil

if not MainGameModule then
	warn("MainGameModule not found! Upgrade functionality will be limited.")
end

-- Ensure RemoteEvents folder exists
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

-- Create or get BuyUpgrade remote event
local BuyUpgrade = RemoteEvents:FindFirstChild("BuyUpgrade")
if not BuyUpgrade then
	BuyUpgrade = Instance.new("RemoteEvent")
	BuyUpgrade.Name = "BuyUpgrade"
	BuyUpgrade.Parent = RemoteEvents
end

-- Create or get UpdatePlayerStats remote event
local UpdatePlayerStats = RemoteEvents:FindFirstChild("UpdatePlayerStats")
if not UpdatePlayerStats then
	UpdatePlayerStats = Instance.new("RemoteEvent")
	UpdatePlayerStats.Name = "UpdatePlayerStats"
	UpdatePlayerStats.Parent = RemoteEvents
end

-- Function to buy an upgrade
local function PurchaseUpgrade(player, upgradeId)
	-- Get player data
	local playerData
	if MainGameModule then
		playerData = MainGameModule.GetPlayerData(player)
	else
		-- Fallback implementation if MainGameModule doesn't exist
		-- This would need to be adapted to your game's data structure
		warn("Using fallback player data implementation")
		if not _G.PlayerData then _G.PlayerData = {} end
		if not _G.PlayerData[player.UserId] then
			_G.PlayerData[player.UserId] = {
				coins = 1000,
				upgrades = {}
			}
		end
		playerData = _G.PlayerData[player.UserId]
	end

	if not playerData then
		warn("Failed to get player data for " .. player.Name)
		return false
	end

	-- Initialize upgrades table if it doesn't exist
	if not playerData.upgrades then
		playerData.upgrades = {}
	end

	-- Get the upgrade info
	local upgradeInfo = UpgradeSystem.GetUpgradeById(upgradeId)
	if not upgradeInfo then
		warn("Invalid upgrade ID: " .. upgradeId)
		return false
	end

	-- Get current level (default to 0 if not upgraded yet)
	local currentLevel = playerData.upgrades[upgradeId] or 0

	-- Check if already at max level
	if currentLevel >= upgradeInfo.maxLevel then
		warn("Upgrade already at max level: " .. upgradeId)
		return false
	end

	-- Check if upgrade is locked
	if upgradeInfo.locked and not UpgradeSystem.IsUpgradeUnlocked(upgradeInfo, playerData) then
		warn("Upgrade is locked: " .. upgradeId)
		return false
	end

	-- Calculate cost
	local cost = UpgradeSystem.CalculateUpgradeCost(upgradeInfo, currentLevel)
	if not cost then
		warn("Failed to calculate cost for upgrade: " .. upgradeId)
		return false
	end

	-- Check if player has enough coins
	if playerData.coins < cost then
		warn("Not enough coins to purchase upgrade")
		return false
	end

	-- Process the purchase
	playerData.coins = playerData.coins - cost
	playerData.upgrades[upgradeId] = currentLevel + 1

	-- Save data
	if MainGameModule then
		MainGameModule.SavePlayerData(player)
	else
		-- Fallback save implementation
		_G.PlayerData[player.UserId] = playerData
	end

	-- Update player's game state
	UpdateStats(player, playerData)

	print(player.Name .. " purchased " .. upgradeInfo.name .. " (Level " .. (currentLevel + 1) .. ")")
	return true
end

-- Function to update player's stats
function UpdateStats(player, playerData)
	-- Update leaderstats if they exist
	if player:FindFirstChild("leaderstats") then
		local coins = player.leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = playerData.coins
		end
	end

	-- Update client with new data
	UpdatePlayerStats:FireClient(player, playerData)
end

-- Listen for upgrade purchase requests
BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	PurchaseUpgrade(player, upgradeId)
end)

-- Initialize players when they join
Players.PlayerAdded:Connect(function(player)
	local playerData

	-- Get player data
	if MainGameModule then
		playerData = MainGameModule.GetPlayerData(player)
	else
		-- Fallback implementation
		if not _G.PlayerData then _G.PlayerData = {} end
		if not _G.PlayerData[player.UserId] then
			_G.PlayerData[player.UserId] = {
				coins = 1000,
				upgrades = {}
			}
		end
		playerData = _G.PlayerData[player.UserId]
	end

	-- Initialize upgrades if needed
	if not playerData.upgrades then
		playerData.upgrades = {}

		-- Initialize default upgrade levels
		playerData.upgrades["collection_speed"] = 1 -- Start at level 1
		playerData.upgrades["pet_capacity"] = 1
		playerData.upgrades["collection_value"] = 1

		-- Save the initialized data
		if MainGameModule then
			MainGameModule.SavePlayerData(player)
		else
			-- Fallback save
			_G.PlayerData[player.UserId] = playerData
		end
	end

	-- Send initial data to client
	UpdatePlayerStats:FireClient(player, playerData)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	if MainGameModule then
		MainGameModule.SavePlayerData(player)
	end
	-- Fallback cleanup if needed
	if _G.PlayerData and _G.PlayerData[player.UserId] then
		-- Keep the data in memory or save it elsewhere if needed
	end
end)

print("Upgrade Manager initialized")