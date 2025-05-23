-- ShopIntegration.server.lua  
-- Main integration script that ties everything together
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Load all required modules
local PlayerDataService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))
local GamePassConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GamePassConfig"))

-- Ensure folders exist
local function ensureFoldersExist()
	local folders = {
		{"ReplicatedStorage", "RemoteEvents"},
		{"ReplicatedStorage", "RemoteFunctions"}, 
		{"ReplicatedStorage", "Modules"},
		{"ServerStorage", "Modules"}
	}

	for _, folderPath in ipairs(folders) do
		local parent = game:GetService(folderPath[1])
		local folderName = folderPath[2]

		if not parent:FindFirstChild(folderName) then
			local folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = parent
			print("Created folder:", folderPath[1] .. "/" .. folderName)
		end
	end
end

-- Create required RemoteEvents
local function createRemoteEvents()
	local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local events = {
		"BuyUpgrade",
		"UnlockArea", 
		"BuyPremium",
		"UpdateShopData",
		"UpdatePlayerStats",
		"SendNotification",
		"EnableAutoCollect",
		"OpenShop"
	}

	for _, eventName in ipairs(events) do
		if not RemoteEvents:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = RemoteEvents
			print("Created RemoteEvent:", eventName)
		end
	end
end

-- Create required RemoteFunctions
local function createRemoteFunctions()
	local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	local functions = {
		"GetPlayerData",
		"CheckGamePassOwnership"
	}

	for _, funcName in ipairs(functions) do
		if not RemoteFunctions:FindFirstChild(funcName) then
			local func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = RemoteFunctions
			print("Created RemoteFunction:", funcName)
		end
	end
end

-- Initialize everything
local function initialize()
	print("Initializing Shop Integration System...")

	-- Create necessary folders and remotes
	ensureFoldersExist()
	createRemoteEvents()
	createRemoteFunctions()

	-- Wait for all systems to load
	wait(1)

	print("Shop Integration System ready!")
end

-- Handle player joining
local function onPlayerAdded(player)
	print("Setting up shop system for", player.Name)

	-- Load player data
	local data = PlayerDataService.LoadPlayerData(player)

	-- Apply GamePass effects
	GamePassConfig.ApplyGamePassEffects(player)

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.coins
	coins.Parent = leaderstats

	local gems = Instance.new("IntValue")
	gems.Name = "Gems" 
	gems.Value = data.gems
	gems.Parent = leaderstats

	local pets = Instance.new("IntValue")
	pets.Name = "Pets"
	pets.Value = #data.pets
	pets.Parent = leaderstats

	-- Wait for character to load
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Allow character to fully load

		-- Reapply GamePass effects
		GamePassConfig.ApplyGamePassEffects(player)

		-- Apply upgrades
		local data = PlayerDataService.GetPlayerData(player)
		if data and data.upgrades then
			-- Apply walk speed upgrade
			local walkSpeedLevel = data.upgrades.walkSpeed or 1
			if character:FindFirstChild("Humanoid") then
				character.Humanoid.WalkSpeed = 16 + ((walkSpeedLevel - 1) * 2)
			end
			player:SetAttribute("WalkSpeedLevel", walkSpeedLevel)

			-- Apply other upgrade attributes
			player:SetAttribute("StaminaLevel", data.upgrades.stamina or 1)
			player:SetAttribute("CollectionRange", 15 + ((data.upgrades.collectRange or 1) - 1) * 5)
			player:SetAttribute("CollectionSpeed", 1 + ((data.upgrades.collectSpeed or 1) - 1) * 0.25)
			player:SetAttribute("PetCapacity", 100 + ((data.upgrades.petCapacity or 1) - 1) * 25)
		end
	end)

	-- Send initial data to client after a delay
	spawn(function()
		wait(3) -- Give client time to load all scripts

		local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
		local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")
		local UpdateShopData = RemoteEvents:WaitForChild("UpdateShopData")

		-- Send player data
		UpdatePlayerStats:FireClient(player, data)

		-- Send shop data (this would normally be in EnhancedShopHandler)
		local shopData = {
			Collecting = {},
			Areas = {},
			Premium = {},
			
		}
		UpdateShopData:FireClient(player, shopData)

		print("Sent initial data to", player.Name)
	end)
end

-- Handle player leaving
local function onPlayerRemoving(player)
	PlayerDataService.CleanupPlayer(player)
	print("Cleaned up data for", player.Name)
end

-- Set up RemoteFunction handlers
local function setupRemoteFunctions()
	local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

	-- Get player data
	local GetPlayerData = RemoteFunctions:WaitForChild("GetPlayerData")
	GetPlayerData.OnServerInvoke = function(player)
		return PlayerDataService.GetPlayerData(player)
	end

	-- Check gamepass ownership
	local CheckGamePassOwnership = RemoteFunctions:WaitForChild("CheckGamePassOwnership")
	CheckGamePassOwnership.OnServerInvoke = function(player, gamePassName)
		-- Convert name to ID (you'd expand this based on your gamepasses)
		local gamePassIds = {
			["Auto-Collect"] = GamePassConfig.GAMEPASS_IDS.AUTO_COLLECT,
			["Unlimited-Stamina"] = GamePassConfig.GAMEPASS_IDS.UNLIMITED_STAMINA,
			["Double-XP"] = GamePassConfig.GAMEPASS_IDS.DOUBLE_XP
		}

		local gamePassId = gamePassIds[gamePassName]
		if gamePassId then
			return GamePassConfig.PlayerOwnsGamePass(player, gamePassId)
		end
		return false
	end
end

-- Game shutdown handler
game:BindToClose(function()
	print("Game shutting down, saving all player data...")

	for _, player in pairs(Players:GetPlayers()) do
		PlayerDataService.SavePlayerData(player)
	end

	wait(3) -- Give time for saves to complete
	print("All data saved!")
end)

-- Error handling wrapper
local function safeCall(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		warn("Error in shop system:", result)
	end
	return success, result
end

-- Connect events with error handling
Players.PlayerAdded:Connect(function(player)
	safeCall(onPlayerAdded, player)
end)

Players.PlayerRemoving:Connect(function(player)
	safeCall(onPlayerRemoving, player)
end)

-- Initialize the system
safeCall(initialize)
safeCall(setupRemoteFunctions)

-- Periodic save system
spawn(function()
	while true do
		wait(300) -- Save every 5 minutes

		for _, player in pairs(Players:GetPlayers()) do
			safeCall(PlayerDataService.SavePlayerData, player)
		end
	end
end)

-- Test commands for development
local function createTestCommands()
	if game:GetService("RunService"):IsStudio() then
		-- Add test commands for Studio testing
		local Commands = {}

		function Commands.giveCoins(player, amount)
			local data = PlayerDataService.GetPlayerData(player)
			if data then
				PlayerDataService.AddCurrency(player, "coins", amount or 1000)
				print("Gave", amount or 1000, "coins to", player.Name)
			end
		end

		function Commands.giveGems(player, amount)
			local data = PlayerDataService.GetPlayerData(player)
			if data then
				PlayerDataService.AddCurrency(player, "gems", amount or 100)
				print("Gave", amount or 100, "gems to", player.Name)
			end
		end

		function Commands.maxUpgrades(player)
			local data = PlayerDataService.GetPlayerData(player)
			if data then
				PlayerDataService.UpdatePlayerData(player, {
					upgrades = {
						walkSpeed = 10,
						stamina = 5,
						collectRange = 8,
						collectSpeed = 6,
						petCapacity = 5
					}
				})
				print("Maxed all upgrades for", player.Name)
			end
		end

		function Commands.unlockAllAreas(player)
			local data = PlayerDataService.GetPlayerData(player)
			if data then
				PlayerDataService.UpdatePlayerData(player, {
					unlockedAreas = {"Starter Meadow", "Mystic Forest", "Dragon's Lair", "Crystal Cave", "Shadow Realm"}
				})
				print("Unlocked all areas for", player.Name)
			end
		end

		-- Make commands globally available in Studio
		_G.ShopCommands = Commands
		print("Test commands loaded! Use _G.ShopCommands.giveCoins(player, amount)")
	end
end

createTestCommands()

print("Shop Integration System fully loaded!")