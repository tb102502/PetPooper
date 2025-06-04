--[[
    ItemConfig.lua - CONSOLIDATED VERSION
    Place in: ReplicatedStorage/ItemConfig.lua
    
    This replaces:
    - FarmingSeeds.lua
    - ShopData.lua
    - Any other item configuration files
]]

local ItemConfig = {}

-- ========== STANDARDIZED DATA STRUCTURES ==========

-- Pet Definitions with standardized structure
ItemConfig.Pets = {
	Corgi = {
		id = "Corgi",
		name = "Corgi",
		displayName = "Cuddly Corgi",
		rarity = "Common",
		sellValue = 25,
		modelName = "Corgi",
		spawnWeight = 50, -- Higher = more common
		colors = {
			primary = Color3.fromRGB(255, 200, 150),
			secondary = Color3.fromRGB(255, 255, 255)
		}
	},

	RedPanda = {
		id = "RedPanda",
		name = "Red Panda",
		displayName = "Rambunctious Red Panda",
		rarity = "Common",
		sellValue = 25,
		modelName = "RedPanda",
		spawnWeight = 35,
		colors = {
			primary = Color3.fromRGB(194, 144, 90),
			secondary = Color3.fromRGB(140, 100, 60)
		}
	},

	Cat = {
		id = "Cat",
		name = "Cat",
		displayName = "Curious Cat",
		rarity = "Uncommon",
		sellValue = 75,
		modelName = "Cat",
		spawnWeight = 14,
		colors = {
			primary = Color3.fromRGB(110, 110, 110),
			secondary = Color3.fromRGB(80, 80, 80)
		}
	},

	Hamster = {
		id = "Hamster",
		name = "Hamster",
		displayName = "Happy Hamster",
		rarity = "Legendary",
		sellValue = 750,
		modelName = "Hamster",
		spawnWeight = 1,
		colors = {
			primary = Color3.fromRGB(255, 215, 0),
			secondary = Color3.fromRGB(255, 255, 200)
		}
	}
}

-- Shop Items - ALL ITEMS IN ONE PLACE
ItemConfig.ShopItems = {
	-- ========== FARMING SYSTEM ==========
	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "🌾 Your First Farm Plot",
		type = "farmPlot",
		category = "farming",
		price = 100,
		currency = "coins",
		description = "Purchase your first farming plot for 100 coins! Includes free starter seeds and automatic placement in Starter Meadow.",
		maxQuantity = 1,
		icon = "🌾",
		effects = {
			enableFarming = true,
			starterSeeds = {
				carrot_seeds = 5,
				corn_seeds = 3,
				strawberry_seeds = 1
			}
		}
	},

	farm_plot_upgrade = {
		id = "farm_plot_upgrade",
		name = "Additional Farm Plot",
		type = "upgrade",
		category = "farming",
		price = 500,
		currency = "coins",
		description = "Add another farm plot. Price increases with each purchase.",
		maxLevel = 7,
		priceMultiplier = 1.3,
		requiresFarmPlot = true,
		icon = "🚜"
	},

	-- ========== SEEDS ==========
	carrot_seeds = {
		id = "carrot_seeds",
		name = "Carrot Seeds",
		type = "seed",
		category = "seeds",
		price = 20,
		currency = "coins",
		description = "Fast-growing carrots. Ready in 5 minutes.",
		requiresFarmPlot = true,
		icon = "🥕",
		farmingData = {
			growTime = 300, -- 5 minutes
			yieldAmount = 2,
			resultCropId = "carrot",
			stages = {"planted", "sprouting", "growing", "ready"}
		}
	},

	corn_seeds = {
		id = "corn_seeds",
		name = "Corn Seeds",
		type = "seed",
		category = "seeds",
		price = 50,
		currency = "coins",
		description = "High-yield corn. Ready in 10 minutes.",
		requiresFarmPlot = true,
		icon = "🌽",
		farmingData = {
			growTime = 600, -- 10 minutes
			yieldAmount = 4,
			resultCropId = "corn",
			stages = {"planted", "sprouting", "growing", "ready"}
		}
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "Strawberry Seeds",
		type = "seed",
		category = "seeds",
		price = 100,
		currency = "coins",
		description = "Sweet strawberries. Ready in 7.5 minutes.",
		requiresFarmPlot = true,
		icon = "🍓",
		farmingData = {
			growTime = 450, -- 7.5 minutes
			yieldAmount = 6,
			resultCropId = "strawberry",
			stages = {"planted", "sprouting", "growing", "ready"}
		}
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "Golden Seeds",
		type = "seed",
		category = "seeds",
		price = 25,
		currency = "gems",
		description = "Magical golden fruit with high pig feeding value! Ready in 15 minutes.",
		requiresFarmPlot = true,
		icon = "✨",
		farmingData = {
			growTime = 900, -- 15 minutes
			yieldAmount = 3,
			resultCropId = "golden_fruit",
			stages = {"planted", "sprouting", "growing", "ready"}
		}
	},

	-- ========== CROPS (Results of farming) ==========
	carrot = {
		id = "carrot",
		name = "Carrot",
		type = "crop",
		category = "crops",
		description = "Fresh carrot. Feed to your pig or sell for coins.",
		sellValue = 30,
		feedValue = 1,
		icon = "🥕"
	},

	corn = {
		id = "corn",
		name = "Corn",
		type = "crop",
		category = "crops",
		description = "Fresh corn. Feed to your pig or sell for coins.",
		sellValue = 75,
		feedValue = 2,
		icon = "🌽"
	},

	strawberry = {
		id = "strawberry",
		name = "Strawberry",
		type = "crop",
		category = "crops",
		description = "Sweet strawberry. Feed to your pig or sell for coins.",
		sellValue = 150,
		feedValue = 3,
		icon = "🍓"
	},

	golden_fruit = {
		id = "golden_fruit",
		name = "Golden Fruit",
		type = "crop",
		category = "crops",
		description = "Magical golden fruit. Greatly boosts pig growth!",
		sellValue = 500,
		feedValue = 10,
		icon = "✨"
	},

	-- ========== UPGRADES ==========
	speed_upgrade = {
		id = "speed_upgrade",
		name = "Speed Boost",
		type = "upgrade",
		category = "player",
		price = 200,
		currency = "coins",
		description = "Increases movement speed (+2 per level).",
		maxLevel = 15,
		effectPerLevel = 2,
		baseEffect = 16,
		icon = "💨"
	},

	collection_radius_upgrade = {
		id = "collection_radius_upgrade",
		name = "Collection Range",
		type = "upgrade",
		category = "player",
		price = 300,
		currency = "coins",
		description = "Collect pets from further away (+1 stud per level).",
		maxLevel = 10,
		effectPerLevel = 1,
		baseEffect = 5,
		icon = "🎯"
	},

	pet_magnet_upgrade = {
		id = "pet_magnet_upgrade",
		name = "Pet Magnet",
		type = "upgrade",
		category = "player",
		price = 500,
		currency = "coins",
		description = "Pulls nearby pets toward you (+2 stud range per level).",
		maxLevel = 8,
		effectPerLevel = 2,
		baseEffect = 8,
		icon = "🧲"
	},

	pet_storage_upgrade = {
		id = "pet_storage_upgrade",
		name = "Pet Storage Expansion",
		type = "upgrade",
		category = "player",
		price = 50,
		currency = "gems",
		description = "Store more pets (+25 capacity per level).",
		maxLevel = 20,
		effectPerLevel = 25,
		baseEffect = 100,
		icon = "📦"
	},

	farming_speed_boost = {
		id = "farming_speed_boost",
		name = "Growth Accelerator",
		type = "upgrade",
		category = "farming",
		price = 400,
		currency = "coins",
		description = "Reduces crop growth time by 10% per level.",
		maxLevel = 5,
		effectPerLevel = 0.1,
		requiresFarmPlot = true,
		icon = "⚡"
	},

	auto_harvest = {
		id = "auto_harvest",
		name = "Auto-Harvester",
		type = "upgrade",
		category = "farming",
		price = 100,
		currency = "gems",
		description = "Automatically harvests ready crops.",
		maxLevel = 1,
		requiresFarmPlot = true,
		icon = "🤖"
	},

	-- ========== SEED PACKS ==========
	basic_seed_pack = {
		id = "basic_seed_pack",
		name = "Basic Seed Pack",
		type = "pack",
		category = "packs",
		price = 75,
		currency = "coins",
		description = "Contains 3-8 common seeds. Great value!",
		requiresFarmPlot = true,
		icon = "📦",
		packContents = {
			possibleItems = {"carrot_seeds", "corn_seeds"},
			minAmount = 3,
			maxAmount = 8
		}
	},

	premium_seed_pack = {
		id = "premium_seed_pack",
		name = "Premium Seed Pack",
		type = "pack",
		category = "packs",
		price = 40,
		currency = "gems",
		description = "Contains rare and valuable seeds with bonus chance.",
		requiresFarmPlot = true,
		icon = "🎁",
		packContents = {
			possibleItems = {"strawberry_seeds", "golden_seeds"},
			minAmount = 2,
			maxAmount = 5,
			bonusChance = 0.3
		}
	}
}

-- ========== SPAWN AREAS ==========
ItemConfig.SpawnAreas = {
	{
		name = "Starter Meadow",
		maxPets = 6,
		spawnInterval = 45,
		minSpawnDelay = 30,
		availablePets = {"Corgi", "RedPanda", "Cat", "Hamster"},
		spawnPositions = {
			Vector3.new(0, 1, 0),
			Vector3.new(10, 1, 10),
			Vector3.new(-10, 1, 10),
			Vector3.new(10, 1, -10),
			Vector3.new(-10, 1, -10),
			Vector3.new(15, 1, 0),
			Vector3.new(-15, 1, 0),
			Vector3.new(0, 1, 15)
		}
	}
}

-- ========== UTILITY FUNCTIONS ==========

-- Get item by ID with fallback
function ItemConfig.GetItem(itemId)
	return ItemConfig.ShopItems[itemId]
end

-- Get items by category
function ItemConfig.GetItemsByCategory(category)
	local items = {}
	for itemId, item in pairs(ItemConfig.ShopItems) do
		if item.category == category then
			items[itemId] = item
		end
	end
	return items
end

-- Get farming data for a seed
function ItemConfig.GetSeedData(seedId)
	local seed = ItemConfig.ShopItems[seedId]
	if seed and seed.type == "seed" and seed.farmingData then
		return seed.farmingData
	end
	return nil
end

-- Get crop data
function ItemConfig.GetCropData(cropId)
	local crop = ItemConfig.ShopItems[cropId]
	if crop and crop.type == "crop" then
		return crop
	end
	return nil
end

-- Calculate upgrade cost
function ItemConfig.GetUpgradeCost(upgradeId, currentLevel)
	local upgrade = ItemConfig.ShopItems[upgradeId]
	if not upgrade or upgrade.type ~= "upgrade" then return 0 end

	if currentLevel >= (upgrade.maxLevel or 1) then return 0 end

	local basePrice = upgrade.price or 0
	local multiplier = upgrade.priceMultiplier or 1.5

	-- Special handling for farm plot upgrades
	if upgradeId == "farm_plot_upgrade" then
		return math.floor(basePrice * (multiplier ^ currentLevel))
	else
		return math.floor(basePrice * (multiplier ^ currentLevel))
	end
end

-- Check if player can buy item
function ItemConfig.CanPlayerBuy(itemId, playerData)
	local item = ItemConfig.ShopItems[itemId]
	if not item then return false, "Item not found" end

	-- Check farm plot requirement
	if item.requiresFarmPlot then
		local hasFarmPlot = playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter
		if not hasFarmPlot then
			return false, "Requires farm plot"
		end
	end

	-- Check currency
	local currency = item.currency or "coins"
	local playerCurrency = playerData[currency] or 0
	local cost = item.price or 0

	if item.type == "upgrade" then
		local currentLevel = (playerData.upgrades and playerData.upgrades[itemId]) or 0
		cost = ItemConfig.GetUpgradeCost(itemId, currentLevel)

		if currentLevel >= (item.maxLevel or 1) then
			return false, "Max level reached"
		end
	end

	if playerCurrency < cost then
		return false, "Insufficient " .. currency
	end

	return true, "Can purchase"
end

-- Get weighted random pet for spawning
function ItemConfig.GetWeightedRandomPet()
	local totalWeight = 0
	local pets = {}

	-- Build weighted list
	for petId, pet in pairs(ItemConfig.Pets) do
		totalWeight = totalWeight + (pet.spawnWeight or 1)
		table.insert(pets, {id = petId, data = pet, weight = pet.spawnWeight or 1})
	end

	-- Select random pet based on weight
	local randomValue = math.random(1, totalWeight)
	local currentWeight = 0

	for _, pet in ipairs(pets) do
		currentWeight = currentWeight + pet.weight
		if randomValue <= currentWeight then
			return pet.data
		end
	end

	-- Fallback to first pet
	return pets[1] and pets[1].data or ItemConfig.Pets.Corgi
end

-- Open seed pack
function ItemConfig.OpenPack(packId)
	local pack = ItemConfig.ShopItems[packId]
	if not pack or pack.type ~= "pack" or not pack.packContents then
		return {}
	end

	local contents = pack.packContents
	local results = {}

	-- Determine amount
	local amount = math.random(contents.minAmount or 1, contents.maxAmount or 3)

	-- Add random items
	for i = 1, amount do
		local randomItem = contents.possibleItems[math.random(1, #contents.possibleItems)]
		results[randomItem] = (results[randomItem] or 0) + 1
	end

	-- Bonus chance
	if contents.bonusChance and math.random() < contents.bonusChance then
		local bonusItem = contents.possibleItems[math.random(1, #contents.possibleItems)]
		local bonusAmount = math.random(1, 3)
		results[bonusItem] = (results[bonusItem] or 0) + bonusAmount
	end

	return results
end

return ItemConfig