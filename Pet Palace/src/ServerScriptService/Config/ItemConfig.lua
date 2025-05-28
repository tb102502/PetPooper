--[[
    ItemConfig.lua - FIXED & UPDATED CONFIGURATION
    Place in: ServerScriptService/Config/ItemConfig.lua
    
    FIXES & UPDATES:
    1. Custom pet models only (no basic fallbacks)
    2. Eggs now contain seeds instead of pets
    3. Updated upgrade system: Speed, Collection Radius, Pet Magnet
    4. Removed coin booster and collection upgrade
    5. Fixed shop pricing and currency handling
]]

local ItemConfig = {}

-- Pet Definitions - ONLY YOUR CUSTOM MODELS
ItemConfig.Pets = {
	Corgi = {
		id = "Corgi",
		name = "Corgi",
		displayName = "Cuddly Corgi",
		rarity = "Common",
		collectValue = 25,
		modelName = "Corgi", -- Must exist in ReplicatedStorage/PetModels
		colors = {
			primary = Color3.fromRGB(255, 200, 150),
			secondary = Color3.fromRGB(255, 255, 255)
		},
		abilities = {
			collectSpeed = 1.0,
			jumpHeight = 2
		},
		chance = 40,
		sellValue = 50
	},

	RedPanda = {
		id = "RedPanda", 
		name = "RedPanda",
		displayName = "Rambunctious Red Panda",
		rarity = "Common",
		collectValue = 30,
		modelName = "RedPanda", -- Must exist in ReplicatedStorage/PetModels
		colors = {
			primary = Color3.fromRGB(194, 144, 90),
			secondary = Color3.fromRGB(140, 100, 60)
		},
		abilities = {
			collectRange = 1.2,
			walkSpeed = 1.2
		},
		chance = 35,
		sellValue = 60
	},

	Cat = {
		id = "Cat",
		name = "Cat", 
		displayName = "Curious Cat",
		rarity = "Uncommon",
		collectValue = 75,
		modelName = "Cat", -- Must exist in ReplicatedStorage/PetModels
		colors = {
			primary = Color3.fromRGB(110, 110, 110),
			secondary = Color3.fromRGB(80, 80, 80)
		},
		abilities = {
			collectRange = 1.5,
			walkSpeed = 1.5
		},
		chance = 20,
		sellValue = 150
	},

	Hamster = {
		id = "Hamster",
		name = "Hamster",
		displayName = "Happy Hamster", 
		rarity = "Legendary",
		collectValue = 200,
		modelName = "Hamster", -- Must exist in ReplicatedStorage/PetModels
		colors = {
			primary = Color3.fromRGB(255, 215, 0),
			secondary = Color3.fromRGB(255, 255, 200)
		},
		abilities = {
			coinMultiplier = 3.0,
			collectRange = 2.0
		},
		chance = 5,
		sellValue = 500
	}
}

-- Seeds and Crops - UPDATED FOR EGG HATCHING
ItemConfig.Seeds = {
	-- Basic Seeds
	carrot_seeds = {
		id = "carrot_seeds",
		name = "Carrot Seeds",
		type = "seed",
		rarity = "Common",
		price = 20,
		currency = "coins",
		description = "Basic carrot seeds. Fast growing crop.",
		growTime = 60,
		yieldAmount = 2,
		resultId = "carrot",
		coinReward = 35,
		image = "rbxassetid://6686038519"
	},

	corn_seeds = {
		id = "corn_seeds", 
		name = "Corn Seeds",
		type = "seed",
		rarity = "Common",
		price = 50,
		currency = "coins",
		description = "Corn seeds that yield multiple crops.",
		growTime = 120,
		yieldAmount = 4,
		resultId = "corn",
		coinReward = 80,
		image = "rbxassetid://6686045507"
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "Strawberry Seeds", 
		type = "seed",
		rarity = "Uncommon",
		price = 100,
		currency = "coins",
		description = "Sweet strawberry seeds with good yield.",
		growTime = 180,
		yieldAmount = 6,
		resultId = "strawberry",
		coinReward = 160,
		image = "rbxassetid://6686051791"
	},

	-- Premium Seeds
	golden_seeds = {
		id = "golden_seeds",
		name = "Golden Seeds",
		type = "seed", 
		rarity = "Rare",
		price = 25,
		currency = "gems",
		description = "Magical golden seeds with amazing yield!",
		growTime = 300,
		yieldAmount = 3,
		resultId = "golden_fruit",
		coinReward = 600,
		image = "rbxassetid://6686054839"
	},

	-- NEW: Epic and Legendary Seeds
	mystic_seeds = {
		id = "mystic_seeds",
		name = "Mystic Seeds",
		type = "seed",
		rarity = "Epic",
		price = 50,
		currency = "gems",
		description = "Rare mystic seeds that grow mystical crops.",
		growTime = 480,
		yieldAmount = 5,
		resultId = "mystic_fruit",
		coinReward = 1200,
		image = "rbxassetid://6686054839"
	},

	dragon_seeds = {
		id = "dragon_seeds",
		name = "Dragon Seeds",
		type = "seed",
		rarity = "Legendary",
		price = 100,
		currency = "gems",
		description = "Legendary dragon seeds - ultimate farming prize!",
		growTime = 600,
		yieldAmount = 8,
		resultId = "dragon_fruit",
		coinReward = 2500,
		image = "rbxassetid://6686054839"
	}
}

-- Updated Crops
ItemConfig.Crops = {
	carrot = {
		id = "carrot",
		name = "Carrot",
		feedValue = 1,
		sellValue = 35,
		image = "rbxassetid://6686041557"
	},

	corn = {
		id = "corn", 
		name = "Corn",
		feedValue = 2,
		sellValue = 80,
		image = "rbxassetid://6686047557"
	},

	strawberry = {
		id = "strawberry",
		name = "Strawberry",
		feedValue = 3,
		sellValue = 160,
		image = "rbxassetid://6686052839"
	},

	golden_fruit = {
		id = "golden_fruit",
		name = "Golden Fruit",
		feedValue = 10,
		sellValue = 600,
		image = "rbxassetid://6686056891"
	},

	mystic_fruit = {
		id = "mystic_fruit",
		name = "Mystic Fruit",
		feedValue = 15,
		sellValue = 1200,
		image = "rbxassetid://6686056891"
	},

	dragon_fruit = {
		id = "dragon_fruit",
		name = "Dragon Fruit",
		feedValue = 25,
		sellValue = 2500,
		image = "rbxassetid://6686056891"
	}
}

-- UPDATED: Shop Items with new upgrade system and seed eggs
ItemConfig.ShopItems = {
	-- Seeds (direct purchase)
	carrot_seeds = ItemConfig.Seeds.carrot_seeds,
	corn_seeds = ItemConfig.Seeds.corn_seeds,
	strawberry_seeds = ItemConfig.Seeds.strawberry_seeds,

	-- UPDATED: Eggs now contain seeds instead of pets
	basic_seed_egg = {
		id = "basic_seed_egg",
		name = "Basic Seed Pouch", 
		type = "egg",
		price = 75,
		currency = "coins",
		description = "Contains common seeds for farming",
		possibleSeeds = {"carrot_seeds", "corn_seeds"},
		guaranteedAmount = {min = 3, max = 8},
		image = "rbxassetid://123456789"
	},

	premium_seed_egg = {
		id = "premium_seed_egg",
		name = "Premium Seed Pouch",
		type = "egg", 
		price = 40,
		currency = "gems",
		description = "Contains rare and epic seeds",
		possibleSeeds = {"strawberry_seeds", "golden_seeds", "mystic_seeds"},
		guaranteedAmount = {min = 2, max = 5},
		rareBonusChance = 0.3, -- 30% chance for bonus seeds
		image = "rbxassetid://123456790"
	},

	legendary_seed_egg = {
		id = "legendary_seed_egg",
		name = "Dragon Seed Chest",
		type = "egg",
		price = 100,
		currency = "gems",
		description = "Guaranteed legendary dragon seeds!",
		possibleSeeds = {"dragon_seeds", "mystic_seeds", "golden_seeds"},
		guaranteedAmount = {min = 1, max = 3},
		rareBonusChance = 0.5,
		image = "rbxassetid://123456791"
	},

	-- UPDATED: New upgrade system
	speed_upgrade = {
		id = "speed_upgrade",
		name = "Speed Boost",
		type = "upgrade",
		price = 200,
		currency = "coins",
		description = "Increases your movement speed (+2 per level)",
		maxLevel = 15,
		effectPerLevel = 2, -- +2 speed per level
		baseEffect = 16 -- Starting speed
	},

	collection_radius_upgrade = {
		id = "collection_radius_upgrade", 
		name = "Collection Range",
		type = "upgrade",
		price = 300,
		currency = "coins",
		description = "Collect pets from further away (+1 stud per level)",
		maxLevel = 10,
		effectPerLevel = 1, -- +1 stud per level
		baseEffect = 5 -- Starting range
	},

	pet_magnet_upgrade = {
		id = "pet_magnet_upgrade",
		name = "Pet Magnet",
		type = "upgrade",
		price = 500,
		currency = "coins",
		description = "Pulls nearby pets toward you (+2 stud magnet range per level)",
		maxLevel = 8,
		effectPerLevel = 2, -- +2 stud magnet range per level
		baseEffect = 8 -- Starting magnet range
	},

	-- Farming upgrades
	farm_plot_upgrade = {
		id = "farm_plot_upgrade",
		name = "Extra Farm Plot",
		type = "upgrade",
		price = 400,
		currency = "coins", 
		description = "Unlock an additional farm plot",
		maxLevel = 7, -- Max 10 total plots (3 base + 7 upgrades)
		effectPerLevel = 1
	},

	-- Premium items
	pet_storage_upgrade = {
		id = "pet_storage_upgrade",
		name = "Pet Storage Expansion",
		type = "upgrade",
		price = 50,
		currency = "gems",
		description = "Store more pets (+25 capacity per level)",
		maxLevel = 20,
		effectPerLevel = 25,
		baseEffect = 100 -- Starting capacity
	}
}

-- FIXED: Spawn Areas - only custom pets
ItemConfig.SpawnAreas = {
	{
		name = "Starter Meadow",
		maxPets = 15,
		spawnInterval = 8,
		availablePets = {"Corgi", "RedPanda"}, -- Only custom pets
		spawnPositions = {
			Vector3.new(0, 1, 0),
			Vector3.new(10, 1, 10),
			Vector3.new(-10, 1, 10),
			Vector3.new(10, 1, -10),
			Vector3.new(-10, 1, -10),
			Vector3.new(15, 1, 0),
			Vector3.new(-15, 1, 0),
			Vector3.new(0, 1, 15),
			Vector3.new(0, 1, -15)
		}
	},

	{
		name = "Mystic Forest",
		maxPets = 12,
		spawnInterval = 10,
		availablePets = {"Corgi", "RedPanda", "Cat"}, -- Only custom pets
		spawnPositions = {
			Vector3.new(50, 1, 0),
			Vector3.new(60, 1, 10),
			Vector3.new(40, 1, 10),
			Vector3.new(55, 1, -10),
			Vector3.new(45, 1, -5),
			Vector3.new(65, 1, 5)
		}
	},

	{
		name = "Dragon's Lair",
		maxPets = 8,
		spawnInterval = 15,
		availablePets = {"Cat", "Hamster"}, -- Only custom pets
		spawnPositions = {
			Vector3.new(100, 1, 0),
			Vector3.new(110, 1, 10),
			Vector3.new(90, 1, 10),
			Vector3.new(105, 1, -10)
		}
	}
}

-- Updated rarity configuration
ItemConfig.RarityInfo = {
	Common = { 
		color = Color3.fromRGB(150, 150, 150),
		chance = 60,
		coinMultiplier = 1.0
	},
	Uncommon = {
		color = Color3.fromRGB(100, 200, 100), 
		chance = 25,
		coinMultiplier = 1.5
	},
	Rare = {
		color = Color3.fromRGB(100, 100, 255),
		chance = 10,
		coinMultiplier = 2.5
	},
	Epic = {
		color = Color3.fromRGB(200, 100, 200),
		chance = 4,
		coinMultiplier = 5.0
	},
	Legendary = {
		color = Color3.fromRGB(255, 215, 0),
		chance = 1,
		coinMultiplier = 10.0
	}
}

-- UTILITY FUNCTIONS

-- Get upgrade effect for player
function ItemConfig.GetUpgradeEffect(upgradeId, level)
	local upgrade = ItemConfig.ShopItems[upgradeId]
	if not upgrade or upgrade.type ~= "upgrade" then
		return 0
	end

	local baseEffect = upgrade.baseEffect or 0
	local effectPerLevel = upgrade.effectPerLevel or 1
	local actualLevel = math.min(level or 0, upgrade.maxLevel or 10)

	return baseEffect + (actualLevel * effectPerLevel)
end

-- Calculate upgrade price for specific level
function ItemConfig.GetUpgradePrice(upgradeId, targetLevel)
	local upgrade = ItemConfig.ShopItems[upgradeId]
	if not upgrade or upgrade.type ~= "upgrade" then
		return 0
	end

	local basePrice = upgrade.price
	local priceMultiplier = 1.5 -- Price increases by 50% each level

	-- Calculate total cost to reach target level
	local totalCost = 0
	for level = 1, targetLevel do
		totalCost = totalCost + math.floor(basePrice * (priceMultiplier ^ (level - 1)))
	end

	return totalCost
end

-- Get next level upgrade cost
function ItemConfig.GetNextUpgradeCost(upgradeId, currentLevel)
	local upgrade = ItemConfig.ShopItems[upgradeId]
	if not upgrade or upgrade.type ~= "upgrade" then
		return 0
	end

	if currentLevel >= upgrade.maxLevel then
		return 0 -- Max level reached
	end

	local basePrice = upgrade.price
	local priceMultiplier = 1.5
	local nextLevel = currentLevel + 1

	return math.floor(basePrice * (priceMultiplier ^ (nextLevel - 1)))
end

-- Egg hatching function
function ItemConfig.HatchEgg(eggId)
	local egg = ItemConfig.ShopItems[eggId]
	if not egg or egg.type ~= "egg" then
		return {}
	end

	local results = {}
	local possibleSeeds = egg.possibleSeeds or {}
	local minAmount = egg.guaranteedAmount.min or 1
	local maxAmount = egg.guaranteedAmount.max or 3
	local bonusChance = egg.rareBonusChance or 0

	-- Guaranteed seeds
	local seedCount = math.random(minAmount, maxAmount)
	for i = 1, seedCount do
		local randomSeed = possibleSeeds[math.random(1, #possibleSeeds)]
		results[randomSeed] = (results[randomSeed] or 0) + 1
	end

	-- Bonus seeds chance
	if math.random() < bonusChance then
		local bonusSeed = possibleSeeds[math.random(1, #possibleSeeds)]
		local bonusAmount = math.random(1, 3)
		results[bonusSeed] = (results[bonusSeed] or 0) + bonusAmount
	end

	return results
end

-- Pet model validation function
function ItemConfig.ValidatePetModelsExist()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")

	if not petModelsFolder then
		error("ItemConfig: PetModels folder not found in ReplicatedStorage!")
	end

	local missingModels = {}
	for petId, petConfig in pairs(ItemConfig.Pets) do
		local model = petModelsFolder:FindFirstChild(petConfig.modelName)
		if not model then
			table.insert(missingModels, petConfig.modelName)
		end
	end

	if #missingModels > 0 then
		error("ItemConfig: Missing pet models: " .. table.concat(missingModels, ", "))
	end

	print("ItemConfig: All custom pet models validated successfully")
	return true
end

-- Get pets by rarity
function ItemConfig.GetPetsByRarity(rarity)
	local pets = {}
	for _, pet in pairs(ItemConfig.Pets) do
		if pet.rarity == rarity then
			table.insert(pets, pet)
		end
	end
	return pets
end

-- Get weighted random pet (only custom models)
function ItemConfig.GetWeightedRandomPet()
	local totalChance = 0
	for _, pet in pairs(ItemConfig.Pets) do
		totalChance = totalChance + pet.chance
	end

	local randomValue = math.random() * totalChance
	local currentTotal = 0

	for _, pet in pairs(ItemConfig.Pets) do
		currentTotal = currentTotal + pet.chance
		if randomValue <= currentTotal then
			return pet
		end
	end

	-- Fallback to first custom pet
	return ItemConfig.Pets.Corgi
end

return ItemConfig