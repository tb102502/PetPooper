-- PlayerDataService.lua
-- Place in ServerStorage/Modules/PlayerDataService.lua

local PlayerDataService = {}

-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")

-- Default player data
local DEFAULT_DATA = {
	coins = 100,
	gems = 0,
	pets = {},
	unlockedAreas = {"Starter Meadow"},
	upgrades = {
		walkSpeed = 1,
		stamina = 1,
		collectRange = 1,
		collectSpeed = 1,
		petCapacity = 1
	},
	premiumOwned = {},
	statistics = {
		totalPetsCollected = 0,
		totalCoinsEarned = 100,
		totalGemsEarned = 0,
		playTime = 0,
		lastLogin = 0
	},
	settings = {
		autoSave = true,
		notifications = true
	}
}

-- Cache for loaded player data
local loadedData = {}

-- Data validation
local function validateData(data)
	if type(data) ~= "table" then
		return false, "Data is not a table"
	end

	-- Ensure all required fields exist
	for key, value in pairs(DEFAULT_DATA) do
		if data[key] == nil then
			if type(value) == "table" then
				data[key] = {}
				for subKey, subValue in pairs(value) do
					data[key][subKey] = subValue
				end
			else
				data[key] = value
			end
		end
	end

	-- Validate specific fields
	if type(data.coins) ~= "number" or data.coins < 0 then
		data.coins = 0
	end

	if type(data.gems) ~= "number" or data.gems < 0 then
		data.gems = 0
	end

	if type(data.pets) ~= "table" then
		data.pets = {}
	end

	if type(data.unlockedAreas) ~= "table" then
		data.unlockedAreas = {"Starter Meadow"}
	end

	if type(data.upgrades) ~= "table" then
		data.upgrades = {
			walkSpeed = 1,
			stamina = 1,
			collectRange = 1,
			collectSpeed = 1,
			petCapacity = 1
		}
	end

	if type(data.statistics) ~= "table" then
		data.statistics = {
			totalPetsCollected = 0,
			totalCoinsEarned = 100,
			totalGemsEarned = 0,
			playTime = 0,
			lastLogin = 0
		}
	end

	return true, "Data valid"
end

-- Load player data
function PlayerDataService.LoadPlayerData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	-- Check if already loaded
	if loadedData[userId] then
		return loadedData[userId]
	end

	local success, result = pcall(function()
		return playerDataStore:GetAsync(key)
	end)

	local data
	if success and result then
		-- Validate and clean data
		data = result
		validateData(data)
		print("Loaded data for", player.Name)
	else
		-- Failed to load or no data exists
		print("No saved data found for", player.Name, "- creating new data")
		data = {}
		for key, value in pairs(DEFAULT_DATA) do
			if type(value) == "table" then
				data[key] = {}
				for subKey, subValue in pairs(value) do
					data[key][subKey] = subValue
				end
			else
				data[key] = value
			end
		end
	end

	-- Update last login time
	data.statistics.lastLogin = os.time()

	-- Cache the data
	loadedData[userId] = data

	return data
end

-- Save player data
function PlayerDataService.SavePlayerData(player, data)
	local userId = player.UserId
	local key = "Player_" .. userId

	if not data then
		data = loadedData[userId]
	end

	if not data then
		warn("No data to save for", player.Name)
		return false
	end

	-- Validate before saving
	local isValid, message = validateData(data)
	if not isValid then
		warn("Cannot save invalid data for", player.Name, ":", message)
		return false
	end

	local success, result = pcall(function()
		return playerDataStore:SetAsync(key, data)
	end)

	if success then
		print("Saved data for", player.Name)
		return true
	else
		warn("Failed to save data for", player.Name, ":", result)
		return false
	end
end

-- Get cached player data
function PlayerDataService.GetPlayerData(player)
	return loadedData[player.UserId]
end

-- Update player data
function PlayerDataService.UpdatePlayerData(player, updates)
	local data = loadedData[player.UserId]
	if not data then
		warn("No loaded data for", player.Name)
		return false
	end

	-- Apply updates
	for key, value in pairs(updates) do
		if key == "upgrades" and type(value) == "table" then
			-- Merge upgrade data
			for upgradeKey, upgradeValue in pairs(value) do
				data.upgrades[upgradeKey] = upgradeValue
			end
		elseif key == "statistics" and type(value) == "table" then
			-- Merge statistics
			for statKey, statValue in pairs(value) do
				data.statistics[statKey] = statValue
			end
		else
			data[key] = value
		end
	end

	-- Update cache
	loadedData[player.UserId] = data

	return true
end

-- Add currency
function PlayerDataService.AddCurrency(player, currencyType, amount)
	local data = loadedData[player.UserId]
	if not data then return false end

	if currencyType == "coins" then
		data.coins = data.coins + amount
		data.statistics.totalCoinsEarned = data.statistics.totalCoinsEarned + amount
	elseif currencyType == "gems" then
		data.gems = data.gems + amount
		data.statistics.totalGemsEarned = data.statistics.totalGemsEarned + amount
	else
		return false
	end

	loadedData[player.UserId] = data

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local currency = leaderstats:FindFirstChild(currencyType:gsub("^%l", string.upper))
		if currency then
			currency.Value = data[currencyType]
		end
	end

	return true
end

-- Spend currency
function PlayerDataService.SpendCurrency(player, currencyType, amount)
	local data = loadedData[player.UserId]
	if not data then return false end

	local currentAmount = data[currencyType]
	if not currentAmount or currentAmount < amount then
		return false -- Not enough currency
	end

	data[currencyType] = currentAmount - amount
	loadedData[player.UserId] = data

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local currency = leaderstats:FindFirstChild(currencyType:gsub("^%l", string.upper))
		if currency then
			currency.Value = data[currencyType]
		end
	end

	return true
end

-- Unlock area
function PlayerDataService.UnlockArea(player, areaName)
	local data = loadedData[player.UserId]
	if not data then return false end

	-- Check if already unlocked
	for _, area in ipairs(data.unlockedAreas) do
		if area == areaName then
			return false -- Already unlocked
		end
	end

	table.insert(data.unlockedAreas, areaName)
	loadedData[player.UserId] = data

	return true
end

-- Upgrade item
function PlayerDataService.UpgradeItem(player, upgradeId, newLevel)
	local data = loadedData[player.UserId]
	if not data then return false end

	data.upgrades[upgradeId] = newLevel
	loadedData[player.UserId] = data

	return true
end

-- Grant premium
function PlayerDataService.GrantPremium(player, premiumId)
	local data = loadedData[player.UserId]
	if not data then return false end

	data.premiumOwned[premiumId] = true
	loadedData[player.UserId] = data

	return true
end

-- Cleanup when player leaves
function PlayerDataService.CleanupPlayer(player)
	local userId = player.UserId

	-- Save data
	PlayerDataService.SavePlayerData(player)

	-- Clear from cache
	loadedData[userId] = nil
end

return PlayerDataService