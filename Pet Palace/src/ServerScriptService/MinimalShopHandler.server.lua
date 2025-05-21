-- Enhanced MinimalShopHandler.server.lua
-- Add the color system to your existing handler

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Import PlayerDataService
local PlayerDataService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))

-- Wait for RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local OpenShop = RemoteEvents:WaitForChild("OpenShop")
local OpenShopClient = RemoteEvents:WaitForChild("OpenShopClient")
local UpdateShopData = RemoteEvents:WaitForChild("UpdateShopData")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")
local BuyUpgrade = RemoteEvents:WaitForChild("BuyUpgrade")
local UnlockArea = RemoteEvents:WaitForChild("UnlockArea")
local SendNotification = RemoteEvents:WaitForChild("SendNotification")

-- Enhanced shop configuration with colors
local SHOP_CONFIG = {
	upgrades = {
		walkSpeed = {
			name = "Swift Steps", 
			baseCost = 100, 
			maxLevel = 10,
			colors = {
				primary = {70, 70, 70},
				secondary = {30, 144, 255},    -- Blue
				icon = {100, 200, 255},
				accent = {150, 200, 255}
			}
		},
		stamina = {
			name = "Extra Stamina", 
			baseCost = 150, 
			maxLevel = 5,
			colors = {
				primary = {70, 70, 70},
				secondary = {255, 69, 0},      -- Red-Orange
				icon = {255, 140, 100},
				accent = {255, 180, 150}
			}
		},
		collectRange = {
			name = "Extended Reach", 
			baseCost = 200, 
			maxLevel = 8,
			colors = {
				primary = {70, 70, 70},
				secondary = {50, 205, 50},     -- Lime Green
				icon = {120, 255, 120},
				accent = {170, 255, 170}
			}
		},
		collectSpeed = {
			name = "Quick Collection", 
			baseCost = 250, 
			maxLevel = 6,
			colors = {
				primary = {70, 70, 70},
				secondary = {255, 215, 0},     -- Gold
				icon = {255, 255, 150},
				accent = {255, 245, 200}
			}
		},
		petCapacity = {
			name = "Pet Capacity", 
			baseCost = 300, 
			maxLevel = 5,
			colors = {
				primary = {70, 70, 70},
				secondary = {138, 43, 226},    -- Purple
				icon = {200, 150, 255},
				accent = {220, 190, 255}
			}
		}
	},
	areas = {
		{name = "Mystic Forest", cost = 1000, currency = "coins"},
		{name = "Dragon's Lair", cost = 10000, currency = "coins"},
		{name = "Crystal Cave", cost = 500, currency = "gems"}
	}
}

-- Send enhanced shop data to client
function sendShopData(player)
	local data = PlayerDataService.GetPlayerData(player)
	if not data then return end

	local shopData = {
		Collecting = {},
		Areas = {},
		Premium = {}
	}

	-- Add upgrade data with colors
	for upgradeId, config in pairs(SHOP_CONFIG.upgrades) do
		local currentLevel = data.upgrades[upgradeId] or 1
		local cost = math.floor(config.baseCost * (1.5 ^ (currentLevel - 1)))

		table.insert(shopData.Collecting, {
			id = upgradeId,
			currentLevel = currentLevel,
			maxLevel = config.maxLevel,
			cost = cost,
			maxed = currentLevel >= config.maxLevel,
			colors = config.colors  -- Include color data
		})
	end

	-- Add area data
	for i, areaConfig in ipairs(SHOP_CONFIG.areas) do
		local isUnlocked = false
		for _, unlockedArea in ipairs(data.unlockedAreas) do
			if unlockedArea == areaConfig.name then
				isUnlocked = true
				break
			end
		end

		table.insert(shopData.Areas, {
			id = areaConfig.name,
			unlocked = isUnlocked,
			cost = areaConfig.cost,
			currency = areaConfig.currency
		})
	end

	UpdateShopData:FireClient(player, shopData)
end

-- Rest of your existing shop handler code...
-- (Keep all the existing functions: initializePlayer, upgrade purchases, etc.)

-- Initialize player when they join
local function initializePlayer(player)
	print("Initializing player:", player.Name)

	-- Load player data
	local data = PlayerDataService.LoadPlayerData(player)

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

	-- Send initial data to client
	spawn(function()
		wait(3) -- Give client time to load
		UpdatePlayerStats:FireClient(player, data)
		sendShopData(player)
	end)
end

-- Handle shop opening
OpenShop.OnServerEvent:Connect(function(player, tabName)
	print(player.Name .. " wants to open shop")
	sendShopData(player)
	OpenShopClient:FireClient(player, tabName or "Collecting")
end)

-- Handle upgrade purchases (existing code)
BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local data = PlayerDataService.GetPlayerData(player)
	local config = SHOP_CONFIG.upgrades[upgradeId]

	if not data or not config then return end

	local currentLevel = data.upgrades[upgradeId] or 1
	local cost = math.floor(config.baseCost * (1.5 ^ (currentLevel - 1)))

	if currentLevel >= config.maxLevel then
		SendNotification:FireClient(player, "Max Level", "This upgrade is already maxed!", "error")
		return
	end

	if data.coins >= cost then
		-- Deduct cost and increase level
		PlayerDataService.SpendCurrency(player, "coins", cost)
		PlayerDataService.UpgradeItem(player, upgradeId, currentLevel + 1)

		-- Send success notification
		SendNotification:FireClient(player, "Upgrade Purchased!", config.name .. " is now level " .. (currentLevel + 1), "success")

		-- Update client data
		UpdatePlayerStats:FireClient(player, PlayerDataService.GetPlayerData(player))
		sendShopData(player)  -- This will now include color data

		print(player.Name .. " bought upgrade:", config.name)
	else
		SendNotification:FireClient(player, "Not Enough Coins", "You need " .. cost .. " coins for this upgrade.", "error")
	end
end)

-- Rest of existing event handlers...
-- (Keep area unlocks, player events, etc.)

Players.PlayerAdded:Connect(initializePlayer)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.CleanupPlayer(player)
end)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		PlayerDataService.SavePlayerData(player)
	end
	wait(3)
end)

print("Enhanced Shop Handler with colors loaded!")