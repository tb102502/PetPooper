-- Pet Collection Simulator
-- MainGameModule.lua - Core game data and player management
-- Place this as a ModuleScript in ServerScriptService

local module = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Make sure required folders exist
local function ensureFoldersExist()
	-- Create PlayerData folder in ServerStorage if it doesn't exist
	if not ServerStorage:FindFirstChild("PlayerData") then
		local playerDataFolder = Instance.new("Folder")
		playerDataFolder.Name = "PlayerData"
		playerDataFolder.Parent = ServerStorage
	end

	return ServerStorage:FindFirstChild("PlayerData")
end

local PlayerData = ensureFoldersExist()

-- Define pets with their properties
module.PetTypes = {
	{
		name = "Common Corgi",
		rarity = "Common",
		collectValue = 1,
		modelName = "Corgi",
		chance = 70
	},
	{
		name = "Rare RedPanda",
		rarity = "Rare",
		collectValue = 5,
		modelName = "RedPanda",
		chance = 20
	},
	{
		name = "Epic Corgi",
		rarity = "Epic",
		collectValue = 20,
		modelName = "Corgi",
		chance = 8
	},
	{
		name = "Legendary RedPanda",
		rarity = "Legendary",
		collectValue = 100,
		modelName = "RedPanda",
		chance = 2
	},
	{
		name = "Common Hamster",
		rarity = "Common",
		collectValue = 1,
		modelName = "Hamster",
		chance = 70
	},
	{
		name = "Rare Hamster",
		rarity = "Rare",
		collectValue = 5,
		modelName = "Hamster",
		chance = 20
	},
	{
		name = "Common Goat",
		rarity = "Common",
		collectValue = 1,
		modelName = "Goat",
		chance = 70
	},
	{
		name = "Common Panda",
		rarity = "Common",
		collectValue = 1,
		modelName = "Panda",
		chance = 70
	}
}

-- Define areas with their unlock requirements
module.Areas = {
	{
		name = "Starter Meadow",
		unlockCost = 0, -- Free starting area
		petSpawnRate = 3, -- Pets spawn every 15 seconds
		availablePets = {"Common Corgi", "Common Hamster"} -- Basic pets in starter area
	},
	{
		name = "Mystic Forest",
		unlockCost = 1000,
		petSpawnRate = 7,
		availablePets = {"Common Corgi", "Rare RedPanda", "Common Goat", "Common Panda"}
	},
	{
		name = "Dragon's Lair",
		unlockCost = 10000,
		petSpawnRate = 10,
		availablePets = {"Rare RedPanda", "Epic Corgi", "Legendary RedPanda", "Rare Hamster"}
	}
}

-- Define upgrades that players can purchase
module.Upgrades = {
	{
		name = "Collection Speed",
		description = "Collect pets faster",
		baseCost = 100,
		costMultiplier = 1.5, -- Each upgrade costs 1.5x more
		maxLevel = 10,
		effectPerLevel = 0.1 -- 10% faster per level
	},
	{
		name = "Pet Capacity",
		description = "Carry more pets at once",
		baseCost = 200,
		costMultiplier = 2,
		maxLevel = 5,
		effectPerLevel = 5 -- +5 capacity per level
	},
	{
		name = "Collection Value",
		description = "Increase the value of collected pets",
		baseCost = 500,
		costMultiplier = 2.5,
		maxLevel = 10,
		effectPerLevel = 0.2 -- +20% value per level
	}
}

-- Default player data
module.DefaultPlayerData = {
	pets = {}, -- Collection of pets
	coins = 0,
	gems = 0, -- Premium currency
	unlockedAreas = {"Starter Meadow"},
	upgrades = {
		["Collection Speed"] = 1, -- Start at level 1
		["Pet Capacity"] = 1,
		["Collection Value"] = 1
	},
	stats = {
		totalPetsCollected = 0,
		rareFound = 0,
		epicFound = 0,
		legendaryFound = 0,
		playtime = 0
	}
}

-- Player data management
module.PlayerDataCache = {}

-- Function to save player data
function module.SavePlayerData(player)
	if not player then return end

	local success, err = pcall(function()
		-- In a real game, you'd save to DataStore here
		print("Saving data for player: " .. player.Name)

		-- Debug: print pet information
		local playerData = module.PlayerDataCache[player.UserId]
		if playerData then
			print("Player has " .. #playerData.pets .. " pets:")
			for i, pet in ipairs(playerData.pets) do
				print("  - " .. i .. ": " .. pet.name .. " (" .. pet.rarity .. ")")
			end
		end
	end)

	if not success then
		warn("Failed to save data for " .. player.Name .. ": " .. err)
	end
end

-- Function to load player data
function module.LoadPlayerData(player)
	local success, data = pcall(function()
		-- In a real game, you'd load from DataStore here
		-- For testing, use a deep copy of default data
		local copy = {}
		for k, v in pairs(module.DefaultPlayerData) do
			if type(v) == "table" then
				copy[k] = table.clone(v)
			else
				copy[k] = v
			end
		end
		return copy
	end)

	if success then
		module.PlayerDataCache[player.UserId] = data
		print("Loaded data for player: " .. player.Name)
		return data
	else
		warn("Failed to load data for " .. player.Name .. ". Using default data.")
		module.PlayerDataCache[player.UserId] = table.clone(module.DefaultPlayerData)
		return module.PlayerDataCache[player.UserId]
	end
end

-- Function to get player data (used by remote functions and other scripts)
function module.GetPlayerData(player)
	if not player then return nil end

	if not module.PlayerDataCache[player.UserId] then
		return module.LoadPlayerData(player)
	else
		return module.PlayerDataCache[player.UserId]
	end
end

-- Function to add a pet to a player's collection
function module.AddPetToPlayer(player, petInfo)
	if not player or not petInfo then return false end

	local playerData = module.GetPlayerData(player)
	if not playerData then return false end

	-- Create the pet entry
	local newPet = {
		id = os.time() .. "-" .. math.random(1000, 9999),
		name = petInfo.name,
		rarity = petInfo.rarity,
		level = 1,
		modelName = petInfo.modelName
	}

	-- Add to collection
	table.insert(playerData.pets, newPet)

	-- Update stats
	playerData.stats.totalPetsCollected = playerData.stats.totalPetsCollected + 1

	if petInfo.rarity == "Rare" then
		playerData.stats.rareFound = playerData.stats.rareFound + 1
	elseif petInfo.rarity == "Epic" then
		playerData.stats.epicFound = playerData.stats.epicFound + 1
	elseif petInfo.rarity == "Legendary" then
		playerData.stats.legendaryFound = playerData.stats.legendaryFound + 1
	end

	-- Update the client
	local UpdatePlayerStats = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("UpdatePlayerStats")
	if UpdatePlayerStats then
		UpdatePlayerStats:FireClient(player, playerData)
	end

	return true
end

-- Function to buy an upgrade
function module.BuyUpgrade(player, upgradeName)
	if not player or not upgradeName then return false end

	local playerData = module.GetPlayerData(player)
	if not playerData then return false end

	-- Find the upgrade
	local upgradeInfo = nil
	for _, upgrade in ipairs(module.Upgrades) do
		if upgrade.name == upgradeName then
			upgradeInfo = upgrade
			break
		end
	end

	if not upgradeInfo then return false end -- Upgrade not found

	local currentLevel = playerData.upgrades[upgradeName]
	if not currentLevel then return false end

	-- Check if already at max level
	if currentLevel >= upgradeInfo.maxLevel then
		return false
	end

	-- Calculate cost
	local cost = upgradeInfo.baseCost * (upgradeInfo.costMultiplier ^ (currentLevel - 1))

	-- Check if player has enough coins
	if playerData.coins < cost then
		return false
	end

	-- Purchase upgrade
	playerData.coins = playerData.coins - cost
	playerData.upgrades[upgradeName] = currentLevel + 1

	-- Update the client
	local UpdatePlayerStats = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("UpdatePlayerStats")
	if UpdatePlayerStats then
		UpdatePlayerStats:FireClient(player, playerData)
	end

	return true
end

-- Function to unlock an area
function module.UnlockArea(player, areaName)
	if not player or not areaName then return false end

	local playerData = module.GetPlayerData(player)
	if not playerData then return false end

	-- Check if area is already unlocked
	for _, unlockedArea in ipairs(playerData.unlockedAreas) do
		if unlockedArea == areaName then
			return false -- Already unlocked
		end
	end

	-- Find the area
	local areaInfo = nil
	for _, area in ipairs(module.Areas) do
		if area.name == areaName then
			areaInfo = area
			break
		end
	end

	if not areaInfo then return false end -- Area not found

	-- Check if player has enough coins
	if playerData.coins < areaInfo.unlockCost then
		return false
	end

	-- Unlock area
	playerData.coins = playerData.coins - areaInfo.unlockCost
	table.insert(playerData.unlockedAreas, areaName)

	-- Update the client
	local UpdatePlayerStats = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("UpdatePlayerStats")
	if UpdatePlayerStats then
		UpdatePlayerStats:FireClient(player, playerData)
	end

	return true
end

-- NEW FUNCTION: Sell a single pet by ID
function module.SellPet(player, petId)
	if not player or not petId then return false, 0 end

	local playerData = module.GetPlayerData(player)
	if not playerData then return false, 0 end

	-- Find the pet in player's inventory
	local petIndex = nil
	local petValue = 0
	local petData = nil

	for i, pet in ipairs(playerData.pets) do
		if pet.id == petId then
			petIndex = i
			petData = pet
			break
		end
	end

	if not petIndex or not petData then
		return false, 0 -- Pet not found
	end

	-- Calculate value based on rarity
	if petData.rarity == "Common" then
		petValue = 1
	elseif petData.rarity == "Rare" then
		petValue = 5
	elseif petData.rarity == "Epic" then
		petValue = 20
	elseif petData.rarity == "Legendary" then
		petValue = 100
	end

	-- Apply any value multipliers from upgrades
	if playerData.upgrades and playerData.upgrades["Collection Value"] then
		local valueLevel = playerData.upgrades["Collection Value"]
		local multiplier = 1 + (valueLevel - 1) * 0.2 -- 20% increase per level
		petValue = math.floor(petValue * multiplier)
	end

	-- Remove the pet from inventory
	table.remove(playerData.pets, petIndex)

	-- Add coins to player
	if not playerData.coins then playerData.coins = 0 end
	playerData.coins = playerData.coins + petValue

	-- Update player stats
	module.SavePlayerData(player)

	-- Update the client
	local UpdatePlayerStats = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("UpdatePlayerStats")
	if UpdatePlayerStats then
		UpdatePlayerStats:FireClient(player, playerData)
	end

	-- Update leaderboard if it exists
	if player:FindFirstChild("leaderstats") then
		local coins = player.leaderstats:FindFirstChild("Coins")
		local pets = player.leaderstats:FindFirstChild("Pets")

		if coins then coins.Value = playerData.coins end
		if pets then pets.Value = #playerData.pets end
	end

	return true, petValue
end

-- NEW FUNCTION: Sell all pets of a specific type and rarity
function module.SellPetGroup(player, petName, petRarity)
	if not player or not petName or not petRarity then return false, 0 end

	local playerData = module.GetPlayerData(player)
	if not playerData then return false, 0 end

	-- Find all pets matching name and rarity
	local petsToRemove = {}
	local totalValue = 0

	-- Calculate base value based on rarity
	local baseValue = 0
	if petRarity == "Common" then
		baseValue = 1
	elseif petRarity == "Rare" then
		baseValue = 5
	elseif petRarity == "Epic" then
		baseValue = 20
	elseif petRarity == "Legendary" then
		baseValue = 100
	end

	-- Apply any value multipliers from upgrades
	if playerData.upgrades and playerData.upgrades["Collection Value"] then
		local valueLevel = playerData.upgrades["Collection Value"]
		local multiplier = 1 + (valueLevel - 1) * 0.2 -- 20% increase per level
		baseValue = baseValue * multiplier
	end

	-- Find all matching pets in reverse order (to safely remove them)
	for i = #playerData.pets, 1, -1 do
		local pet = playerData.pets[i]
		if pet.name == petName and pet.rarity == petRarity then
			table.remove(playerData.pets, i)
			totalValue = totalValue + baseValue
		end
	end

	if totalValue == 0 then
		return false, 0 -- No pets found to sell
	end

	-- Add coins to player
	if not playerData.coins then playerData.coins = 0 end
	playerData.coins = playerData.coins + math.floor(totalValue)

	-- Update player stats
	module.SavePlayerData(player)

	-- Update the client
	local UpdatePlayerStats = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("UpdatePlayerStats")
	if UpdatePlayerStats then
		UpdatePlayerStats:FireClient(player, playerData)
	end

	-- Update leaderboard if it exists
	if player:FindFirstChild("leaderstats") then
		local coins = player.leaderstats:FindFirstChild("Coins")
		local pets = player.leaderstats:FindFirstChild("Pets")

		if coins then coins.Value = playerData.coins end
		if pets then pets.Value = #playerData.pets end
	end

	return true, math.floor(totalValue)
end

-- NEW FUNCTION: Sell all pets
function module.SellAllPets(player)
	if not player then return false, 0 end

	local playerData = module.GetPlayerData(player)
	if not playerData or #playerData.pets == 0 then return false, 0 end

	local totalValue = 0

	-- Calculate value for each pet
	for _, pet in ipairs(playerData.pets) do
		local petValue = 0

		-- Calculate base value based on rarity
		if pet.rarity == "Common" then
			petValue = 1
		elseif pet.rarity == "Rare" then
			petValue = 5
		elseif pet.rarity == "Epic" then
			petValue = 20
		elseif pet.rarity == "Legendary" then
			petValue = 100
		end

		-- Apply any value multipliers from upgrades
		if playerData.upgrades and playerData.upgrades["Collection Value"] then
			local valueLevel = playerData.upgrades["Collection Value"]
			local multiplier = 1 + (valueLevel - 1) * 0.2 -- 20% increase per level
			petValue = petValue * multiplier
		end

		totalValue = totalValue + petValue
	end

	-- Clear pet inventory
	playerData.pets = {}

	-- Add coins to player
	if not playerData.coins then playerData.coins = 0 end
	playerData.coins = playerData.coins + math.floor(totalValue)

	-- Update player stats
	module.SavePlayerData(player)

	-- Update the client
	local UpdatePlayerStats = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("UpdatePlayerStats")
	if UpdatePlayerStats then
		UpdatePlayerStats:FireClient(player, playerData)
	end

	-- Update leaderboard if it exists
	if player:FindFirstChild("leaderstats") then
		local coins = player.leaderstats:FindFirstChild("Coins")
		local pets = player.leaderstats:FindFirstChild("Pets")

		if coins then coins.Value = playerData.coins end
		if pets then pets.Value = 0 end
	end

	return true, math.floor(totalValue)
end

-- Initialize the module when required
-- Initialize the module when required
local function initialize()
	-- Set up player connections
	Players.PlayerAdded:Connect(function(player)
		-- Load player data
		local playerData = module.LoadPlayerData(player)

		-- Create a leaderstats folder for the player
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		-- Create stats
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = playerData.coins
		coins.Parent = leaderstats

		local pets = Instance.new("IntValue")
		pets.Name = "Pets"
		pets.Value = #playerData.pets
		pets.Parent = leaderstats

		-- Send initial data to client
		local UpdatePlayerStats = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdatePlayerStats")
		UpdatePlayerStats:FireClient(player, playerData)
	end)

	Players.PlayerRemoving:Connect(function(player)
		module.SavePlayerData(player)
		module.PlayerDataCache[player.UserId] = nil
	end)

	print("Enhanced MainGameModule initialized")
end  -- Correct way to end the function

-- Set up pet models
local function setupPetModels()
	for _, petType in ipairs(module.PetTypes) do
		local modelName = petType.modelName
		if ReplicatedStorage:FindFirstChild("PetModels") and ReplicatedStorage.PetModels:FindFirstChild(modelName) then
			print("Model already exists for " .. modelName)
		end
	end
	print("Pet models setup complete!")
end

-- Run the initialization
setupPetModels()
initialize()

-- Return the module
return module