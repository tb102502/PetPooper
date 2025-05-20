-- Corrected Server Shop Open Handler
-- Add this to your EnhancedShopHandler.server.lua

-- Make sure these are defined at the top of your script:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Import PlayerDataService (adjust path as needed)
local PlayerDataService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))

-- Get RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateShopData = RemoteEvents:WaitForChild("UpdateShopData")

-- Shop configuration (this should already be in your EnhancedShopHandler.server.lua)
local SHOP_CONFIG = {
	Collecting = {
		walkSpeed = {
			name = "Swift Steps",
			baseCost = 100,
			costMultiplier = 1.5,
			maxLevel = 10
		},
		stamina = {
			name = "Extra Stamina",
			baseCost = 150,
			costMultiplier = 1.8,
			maxLevel = 5
		},
		collectRange = {
			name = "Extended Reach",
			baseCost = 200,
			costMultiplier = 2.0,
			maxLevel = 8
		},
		collectSpeed = {
			name = "Quick Collection",
			baseCost = 250,
			costMultiplier = 1.7,
			maxLevel = 6
		},
		petCapacity = {
			name = "Pet Capacity",
			baseCost = 300,
			costMultiplier = 2.2,
			maxLevel = 5
		}
	},
	Areas = {
		mysticForest = {
			name = "Mystic Forest",
			cost = 1000,
			currency = "coins",
			requiredLevel = 5
		},
		dragonLair = {
			name = "Dragon's Lair",
			cost = 10000,
			currency = "coins",
			requiredLevel = 15
		},
		crystalCave = {
			name = "Crystal Cave", 
			cost = 500,
			currency = "gems",
			requiredLevel = 10
		}
	},
	Premium = {
		unlimitedStamina = {
			name = "Unlimited Stamina",
			cost = 199,
			gamePassId = 123456789
		},
		doubleXP = {
			name = "Double Pet XP",
			cost = 149,
			gamePassId = 123456790
		},
		autoCollect = {
			name = "Auto Collector",
			cost = 299,
			gamePassId = 123456791
		}
	}
}

-- Function to calculate upgrade cost
local function calculateUpgradeCost(upgradeId, currentLevel)
	local config = SHOP_CONFIG.Collecting[upgradeId]
	if config then
		return math.floor(config.baseCost * (config.costMultiplier ^ (currentLevel - 1)))
	end
	return 0
end

-- Function to calculate player level
local function calculatePlayerLevel(data)
	local totalXP = data.statistics.totalPetsCollected * 10 + data.statistics.totalCoinsEarned / 100
	return math.floor(totalXP / 1000) + 1
end

-- Function to send shop data to client
local function sendShopDataToClient(player)
	local data = PlayerDataService.GetPlayerData(player)
	if not data then 
		warn("No player data found for", player.Name)
		return 
	end

	local shopData = {
		Collecting = {},
		Areas = {},
		Premium = {}
	}

	local playerLevel = calculatePlayerLevel(data)

	-- Collecting upgrades
	for upgradeId, config in pairs(SHOP_CONFIG.Collecting) do
		local currentLevel = data.upgrades[upgradeId] or 1
		local cost = calculateUpgradeCost(upgradeId, currentLevel)

		table.insert(shopData.Collecting, {
			id = upgradeId,
			currentLevel = currentLevel,
			maxLevel = config.maxLevel,
			cost = cost,
			maxed = currentLevel >= config.maxLevel
		})
	end

	-- Areas
	for areaId, config in pairs(SHOP_CONFIG.Areas) do
		local isUnlocked = false
		for _, area in ipairs(data.unlockedAreas) do
			if area == config.name then
				isUnlocked = true
				break
			end
		end

		table.insert(shopData.Areas, {
			id = areaId,
			unlocked = isUnlocked,
			cost = config.cost,
			currency = config.currency,
			requiredLevel = config.requiredLevel,
			canUnlock = playerLevel >= config.requiredLevel
		})
	end

	-- Premium items
	for premiumId, config in pairs(SHOP_CONFIG.Premium) do
		table.insert(shopData.Premium, {
			id = premiumId,
			owned = data.premiumOwned[premiumId] or false,
			cost = config.cost
		})
	end

	UpdateShopData:FireClient(player, shopData)
end

-- Handle shop opening from client
local OpenShop = RemoteEvents:WaitForChild("OpenShop")

OpenShop.OnServerEvent:Connect(function(player, tabName)
	print(player.Name .. " requested to open shop with tab:", tabName)

	-- Validate the tab name
	local validTabs = {
		["Collecting"] = true,
		["Areas"] = true,
		["Premium"] = true
	}

	if not validTabs[tabName] then
		tabName = "Collecting" -- Default fallback
		warn("Invalid tab name provided, defaulting to Collecting")
	end

	-- Send shop data to client
	local data = PlayerDataService.GetPlayerData(player)
	if data then
		sendShopDataToClient(player)

		-- Send additional data to specify which tab to open
		local OpenShopClient = RemoteEvents:FindFirstChild("OpenShopClient")
		if OpenShopClient then
			OpenShopClient:FireClient(player, tabName)
		end

		print("Sent shop data to", player.Name, "for tab:", tabName)
	else
		warn("Could not get player data for", player.Name)
	end
end)