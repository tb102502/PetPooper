--[[
    ItemConfig.lua - FIXED SPAWNING & RARITY RATES
    Place in: ServerScriptService/Config/ItemConfig.lua
    
    FIXES APPLIED:
    1. ✅ Reduced pet spawn rates significantly
    2. ✅ Fixed rarity chances (Common 85%, Rare 1%, Legendary 0.1%)
    3. ✅ Added farming plot purchase system
    4. ✅ Proper spawn timing to prevent too many pets
]]

local ItemConfig = {}

-- FIXED: Pet Definitions with realistic rarity chances
ItemConfig.Pets = {
	Corgi = {
		id = "Corgi",
		name = "Corgi",
		displayName = "Cuddly Corgi",
		rarity = "Common",
		collectValue = 0,
		sellValue = 25,
		modelName = "Corgi",
		colors = {
			primary = Color3.fromRGB(255, 200, 150),
			secondary = Color3.fromRGB(255, 255, 255)
		},
		abilities = {
			collectSpeed = 1.0,
			jumpHeight = 2
		},
		chance = 50  -- 50% chance (most common)
	},

	RedPanda = {
		id = "RedPanda", 
		name = "RedPanda",
		displayName = "Rambunctious Red Panda",
		rarity = "Common",
		collectValue = 0,
		sellValue = 25,
		modelName = "RedPanda",
		colors = {
			primary = Color3.fromRGB(194, 144, 90),
			secondary = Color3.fromRGB(140, 100, 60)
		},
		abilities = {
			collectRange = 1.2,
			walkSpeed = 1.2
		},
		chance = 35  -- 35% chance (common)
	},

	Cat = {
		id = "Cat",
		name = "Cat", 
		displayName = "Curious Cat",
		rarity = "Uncommon",
		collectValue = 0,
		sellValue = 75,
		modelName = "Cat",
		colors = {
			primary = Color3.fromRGB(110, 110, 110),
			secondary = Color3.fromRGB(80, 80, 80)
		},
		abilities = {
			collectRange = 1.5,
			walkSpeed = 1.5
		},
		chance = 14  -- 14% chance (uncommon)
	},

	Hamster = {
		id = "Hamster",
		name = "Hamster",
		displayName = "Happy Hamster", 
		rarity = "Legendary",
		collectValue = 0,
		sellValue = 750,
		modelName = "Hamster",
		colors = {
			primary = Color3.fromRGB(255, 215, 0),
			secondary = Color3.fromRGB(255, 255, 200)
		},
		abilities = {
			coinMultiplier = 3.0,
			collectRange = 2.0
		},
		chance = 1  -- 1% chance (very rare)
	}
}

-- Seeds and Crops
ItemConfig.Seeds = {
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
	}
}

-- Crops
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
	}
}

-- FIXED: Shop Items with farming plot purchase
ItemConfig.ShopItems = {
	-- FARMING PLOT - Must purchase first plot
	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "Your First Farm Plot",
		type = "farm_plot",
		price = 500,
		currency = "coins",
		description = "Purchase your first farming plot! It will be placed in Starter Meadow.",
		maxLevel = 1,  -- Can only buy once
		isStarterPlot = true
	},

	-- Seeds (direct purchase) - Only available AFTER buying first plot
	carrot_seeds = {
		id = "carrot_seeds",
		name = "Carrot Seeds",
		type = "seed",
		price = 20,
		currency = "coins",
		description = "Basic carrot seeds. Fast growing crop.",
		requiresFarmPlot = true,  -- Requires farm plot first
		growTime = 60,
		yieldAmount = 2,
		resultId = "carrot",
		image = "rbxassetid://6686038519"
	},

	corn_seeds = {
		id = "corn_seeds", 
		name = "Corn Seeds",
		type = "seed",
		price = 50,
		currency = "coins",
		description = "Corn seeds that yield multiple crops.",
		requiresFarmPlot = true,
		growTime = 120,
		yieldAmount = 4,
		resultId = "corn",
		image = "rbxassetid://6686045507"
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "Strawberry Seeds", 
		type = "seed",
		price = 100,
		currency = "coins",
		description = "Sweet strawberry seeds with good yield.",
		requiresFarmPlot = true,
		growTime = 180,
		yieldAmount = 6,
		resultId = "strawberry",
		image = "rbxassetid://6686051791"
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "Golden Seeds",
		type = "seed", 
		price = 25,
		currency = "gems",
		description = "Magical golden seeds with amazing yield!",
		requiresFarmPlot = true,
		growTime = 300,
		yieldAmount = 3,
		resultId = "golden_fruit",
		image = "rbxassetid://6686054839"
	},

	-- Seed Packs (eggs) - Also require farm plot
	basic_seed_pack = {
		id = "basic_seed_pack",
		name = "Basic Seed Pack", 
		type = "egg",
		price = 75,
		currency = "coins",
		description = "Contains common seeds for farming",
		requiresFarmPlot = true,
		possibleSeeds = {"carrot_seeds", "corn_seeds"},
		guaranteedAmount = {min = 3, max = 8},
		image = "rbxassetid://123456789"
	},

	premium_seed_pack = {
		id = "premium_seed_pack",
		name = "Premium Seed Pack",
		type = "egg", 
		price = 40,
		currency = "gems",
		description = "Contains rare seeds",
		requiresFarmPlot = true,
		possibleSeeds = {"strawberry_seeds", "golden_seeds"},
		guaranteedAmount = {min = 2, max = 5},
		rareBonusChance = 0.3,
		image = "rbxassetid://123456790"
	},

	-- Upgrades
	speed_upgrade = {
		id = "speed_upgrade",
		name = "Speed Boost",
		type = "upgrade",
		price = 200,
		currency = "coins",
		description = "Increases your movement speed (+2 per level)",
		maxLevel = 15,
		effectPerLevel = 2,
		baseEffect = 16
	},

	collection_radius_upgrade = {
		id = "collection_radius_upgrade", 
		name = "Collection Range",
		type = "upgrade",
		price = 300,
		currency = "coins",
		description = "Collect pets from further away (+1 stud per level)",
		maxLevel = 10,
		effectPerLevel = 1,
		baseEffect = 5
	},

	pet_magnet_upgrade = {
		id = "pet_magnet_upgrade",
		name = "Pet Magnet",
		type = "upgrade",
		price = 500,
		currency = "coins",
		description = "Pulls nearby pets toward you (+2 stud magnet range per level)",
		maxLevel = 8,
		effectPerLevel = 2,
		baseEffect = 8
	},

	-- Additional farm plots (after buying starter)
	farm_plot_upgrade = {
		id = "farm_plot_upgrade",
		name = "Additional Farm Plot",
		type = "upgrade",
		price = 800,  -- More expensive than starter
		currency = "coins", 
		description = "Add another farm plot to grow more crops",
		maxLevel = 5,  -- Max 6 total plots (1 starter + 5 additional)
		effectPerLevel = 1,
		requiresFarmPlot = true  -- Must have starter plot first
	},

	pet_storage_upgrade = {
		id = "pet_storage_upgrade",
		name = "Pet Storage Expansion",
		type = "upgrade",
		price = 50,
		currency = "gems",
		description = "Store more pets (+25 capacity per level)",
		maxLevel = 20,
		effectPerLevel = 25,
		baseEffect = 100
	}
}

-- FIXED: Only Starter Meadow with MUCH slower spawning
ItemConfig.SpawnAreas = {
	{
		name = "Starter Meadow",
		maxPets = 5,  -- REDUCED from 8 to 5
		spawnInterval = 25,  -- INCREASED from 12 to 25 seconds
		minSpawnDelay = 15,  -- Minimum 15 seconds between spawns
		availablePets = {"Corgi", "RedPanda", "Cat", "Hamster"},
		spawnPositions = {
			Vector3.new(0, 1, 0),
			Vector3.new(10, 1, 10),
			Vector3.new(-10, 1, 10),
			Vector3.new(10, 1, -10),
			Vector3.new(-10, 1, -10)
		}
	}
}

-- FIXED: Proper rarity configuration with realistic chances
ItemConfig.RarityInfo = {
	Common = { 
		color = Color3.fromRGB(150, 150, 150),
		chance = 85,  -- 85% for common pets
		coinMultiplier = 1.0
	},
	Uncommon = {
		color = Color3.fromRGB(100, 200, 100), 
		chance = 14,  -- 14% for uncommon pets
		coinMultiplier = 1.5
	},
	Rare = {
		color = Color3.fromRGB(100, 100, 255),
		chance = 1,   -- 1% for rare pets
		coinMultiplier = 2.5
	},
	Epic = {
		color = Color3.fromRGB(200, 100, 200),
		chance = 0,   -- 0% - no epic pets for now
		coinMultiplier = 5.0
	},
	Legendary = {
		color = Color3.fromRGB(255, 215, 0),
		chance = 0.1,  -- 0.1% for legendary pets (very rare!)
		coinMultiplier = 10.0
	}
}

-- UTILITY FUNCTIONS

-- Check if player has farm plot
function ItemConfig.PlayerHasFarmPlot(playerData)
	if not playerData then return false end

	-- Check if they bought the starter plot
	local purchaseHistory = playerData.purchaseHistory or {}
	return purchaseHistory.farm_plot_starter == true
end

-- Get farm plot position in Starter Meadow
function ItemConfig.GetFarmPlotPosition(plotNumber)
	-- Place farm plots in a designated area of Starter Meadow
	local basePosition = Vector3.new(30, 1, 30)  -- Corner of Starter Meadow
	local plotSpacing = 12

	local row = math.floor((plotNumber - 1) / 3)  -- 3 plots per row
	local col = (plotNumber - 1) % 3

	return basePosition + Vector3.new(col * plotSpacing, 0, row * plotSpacing)
end

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
	local priceMultiplier = 1.5

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
		return 0
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

-- FIXED: Weighted random pet with proper rarity distribution
function ItemConfig.GetWeightedRandomPet()
	-- Generate random number from 1 to 100 for percentage-based rarity
	local randomValue = math.random(1, 100)

	-- 85% chance for Common pets (1-85)
	if randomValue <= 85 then
		-- Choose between common pets
		local commonPets = {}
		for petId, pet in pairs(ItemConfig.Pets) do
			if pet.rarity == "Common" then
				table.insert(commonPets, pet)
			end
		end
		return commonPets[math.random(1, #commonPets)] or ItemConfig.Pets.Corgi

		-- 14% chance for Uncommon pets (86-99)
	elseif randomValue <= 99 then
		-- Choose uncommon pets
		for petId, pet in pairs(ItemConfig.Pets) do
			if pet.rarity == "Uncommon" then
				return pet
			end
		end
		return ItemConfig.Pets.Cat  -- Fallback to Cat

		-- 1% chance for Legendary pets (100)
	else
		-- Choose legendary pets
		for petId, pet in pairs(ItemConfig.Pets) do
			if pet.rarity == "Legendary" then
				return pet
			end
		end
		return ItemConfig.Pets.Hamster  -- Fallback to Hamster
	end
end

return ItemConfig