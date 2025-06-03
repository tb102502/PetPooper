local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Wait for GameClient to be available
local function waitForGameClient()
	local maxWait = 30
	local waited = 0

	while waited < maxWait do
		if _G.GameClient then
			return _G.GameClient
		end
		wait(1)
		waited = waited + 1
	end

	return nil
end

-- Get GameClient
local GameClient = waitForGameClient()

if not GameClient then
	-- Create minimal fallback GameClient
	GameClient = {}
	GameClient.UI = {}
	GameClient.RemoteEvents = {}
	GameClient.FarmingState = {}

	function GameClient:GetPlayerData()
		return nil
	end

	function GameClient:ShowNotification(title, message, type)
		print("[" .. (title or "Notification") .. "] " .. (message or ""))
	end

	warn("SeedPlantingSystem: Running with fallback GameClient")
else
	print("SeedPlantingSystem: Successfully connected to GameClient")
end

-- Safely get ItemConfig
local ItemConfig = nil
local success, result = pcall(function()
	return require(ReplicatedStorage:WaitForChild("ItemConfig", 5))
end)

if success and result then
	ItemConfig = result
else
	-- Create fallback ItemConfig
	ItemConfig = {
		Seeds = {
			carrot_seeds = {name = "Carrot Seeds", growTime = 300},
			corn_seeds = {name = "Corn Seeds", growTime = 600},
			strawberry_seeds = {name = "Strawberry Seeds", growTime = 450},
			golden_seeds = {name = "Golden Seeds", growTime = 900}
		}
	}
	warn("SeedPlantingSystem: Using fallback ItemConfig")
end

-- Initialize GameClient farming if it exists
if GameClient and type(GameClient) == "table" then
	-- Initialize farming state
	if not GameClient.FarmingState then
		GameClient.FarmingState = {
			selectedSeed = nil,
			isPlantingMode = false,
			seedInventory = {}
		}
	end

	-- Initialize PlantingSpots if missing
	if not GameClient.PlantingSpots then
		GameClient.PlantingSpots = {
			activeSpots = {},
			glowTweens = {},
			selectedSpot = nil
		}
	end

	print("SeedPlantingSystem: Farming state initialized")
end