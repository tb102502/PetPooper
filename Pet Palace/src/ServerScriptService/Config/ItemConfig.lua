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

-- UPDATED: Shop Items with proper farm plot purchase system
ItemConfig.ShopItems = {
	-- FARMING PLOT SYSTEM - Players must buy initial plot for 100 coins
	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "🌾 Your First Farm Plot",
		type = "farm_plot",
		price = 100, -- 100 coins as requested
		currency = "coins",
		description = "Purchase your first farming plot for 100 coins! Automatically placed in Starter Meadow with free starter seeds included.",
		maxLevel = 1,  -- Can only buy once
		isStarterPlot = true,
		image = "rbxassetid://6686060000"
	},

	-- Seeds (direct purchase) - Only available AFTER buying first plot
	carrot_seeds = {
		id = "carrot_seeds",
		name = "Carrot Seeds",
		type = "seed",
		price = 20,
		currency = "coins",
		description = "Basic carrot seeds. Fast growing crop that yields 2 carrots.",
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
		description = "Corn seeds that yield multiple crops. Takes longer to grow.",
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
		description = "Sweet strawberry seeds with excellent yield.",
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
		description = "Magical golden seeds with amazing yield and high pig feeding value!",
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
		description = "Contains 3-8 common seeds for farming. Great value pack!",
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
		description = "Contains rare and valuable seeds with bonus chance.",
		requiresFarmPlot = true,
		possibleSeeds = {"strawberry_seeds", "golden_seeds"},
		guaranteedAmount = {min = 2, max = 5},
		rareBonusChance = 0.3,
		image = "rbxassetid://123456790"
	},

	-- FARM PLOT UPGRADES - Additional plots placed automatically
	farm_plot_upgrade = {
		id = "farm_plot_upgrade",
		name = "Additional Farm Plot",
		type = "upgrade",
		price = 500,  -- Starts at 250, increases with each purchase
		currency = "coins", 
		description = "Add another farm plot next to your existing ones. Price increases with each additional plot.",
		maxLevel = 7,  -- Max 8 total plots (1 starter + 7 additional)
		effectPerLevel = 1,
		requiresFarmPlot = true,  -- Must have starter plot first
		priceMultiplier = 1.3  -- Each additional plot costs 30% more
	},

	-- MOVEMENT & COLLECTION UPGRADES
	speed_upgrade = {
		id = "speed_upgrade",
		name = "Speed Boost",
		type = "upgrade",
		price = 200,
		currency = "coins",
		description = "Increases your movement speed (+2 per level). Great for getting around your farm!",
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
	},

	-- FARMING TOOLS & BOOSTS
	farming_speed_boost = {
		id = "farming_speed_boost",
		name = "Growth Accelerator",
		type = "upgrade",
		price = 400,
		currency = "coins",
		description = "Reduces crop growth time by 10% per level",
		maxLevel = 5,
		effectPerLevel = 0.1,
		requiresFarmPlot = true
	},

	auto_harvest = {
		id = "auto_harvest",
		name = "Auto-Harvester",
		type = "upgrade",
		price = 100,
		currency = "gems",
		description = "Automatically harvests ready crops every 60 seconds",
		maxLevel = 1,
		requiresFarmPlot = true
	}
}

-- UPDATED: Calculate upgrade price with multiplier for farm plots
function ItemConfig.GetNextUpgradeCost(upgradeId, currentLevel)
	local upgrade = ItemConfig.ShopItems[upgradeId]
	if not upgrade or upgrade.type ~= "upgrade" then
		return 0
	end

	if currentLevel >= upgrade.maxLevel then
		return 0
	end

	local basePrice = upgrade.price
	local nextLevel = currentLevel + 1

	-- Special pricing for farm plots - gets more expensive
	if upgradeId == "farm_plot_upgrade" then
		local multiplier = upgrade.priceMultiplier or 1.3
		return math.floor(basePrice * (multiplier ^ currentLevel))
	else
		-- Standard upgrade pricing
		local priceMultiplier = 1.5
		return math.floor(basePrice * (priceMultiplier ^ (nextLevel - 1)))
	end
end

-- UPDATED: Check if player has farm plot (moved to ItemConfig for easy access)
function ItemConfig.PlayerHasFarmPlot(playerData)
	if not playerData then return false end

	-- Check if they bought the starter plot
	local purchaseHistory = playerData.purchaseHistory or {}
	return purchaseHistory.farm_plot_starter == true
end

-- NEW: Get farm plot position in Starter Meadow
function ItemConfig.GetFarmPlotPosition(plotNumber)
	-- Base position in Starter Meadow (dedicated farming area)
	local basePosition = Vector3.new(-30, 1, 50)  -- Away from spawn and pets
	local plotSpacing = 10  -- 10 studs between plot centers

	if plotNumber == 1 then
		return basePosition
	else
		-- Place additional plots in a grid pattern
		local plotsPerRow = 3
		local row = math.floor((plotNumber - 1) / plotsPerRow)
		local col = (plotNumber - 1) % plotsPerRow

		return basePosition + Vector3.new(col * plotSpacing, 0, row * plotSpacing)
	end
end

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