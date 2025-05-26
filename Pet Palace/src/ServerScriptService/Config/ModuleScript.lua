--[[
    ItemConfig.lua - ALL GAME ITEMS AND CONTENT
    Place in: ServerScriptService/Config/ItemConfig.lua
    
    This consolidates: PetRegistry, ShopData, FarmingSeeds, and other item configs
]]

local ItemConfig = {}

-- Pet Definitions
ItemConfig.Pets = {
	bunny = {
		id = "bunny",
		name = "Bunny",
		displayName = "Fluffy Bunny",
		rarity = "Common",
		collectValue = 1,
		modelName = "Bunny",
		colors = {
			primary = Color3.fromRGB(255, 255, 255),
			secondary = Color3.fromRGB(230, 230, 230)
		},
		abilities = {
			collectSpeed = 1.0,
			jumpHeight = 2
		},
		chance = 30
	},

	puppy = {
		id = "puppy", 
		name = "Puppy",
		displayName = "Playful Puppy",
		rarity = "Common",
		collectValue = 1,
		modelName = "Puppy",
		colors = {
			primary = Color3.fromRGB(194, 144, 90),
			secondary = Color3.fromRGB(140, 100, 60)
		},
		abilities = {
			collectRange = 1.2,
			walkSpeed = 1.2
		},
		chance = 25
	},

	cat = {
		id = "cat",
		name = "Cat", 
		displayName = "Curious Cat",
		rarity = "Uncommon",
		collectValue = 3,
		modelName = "Cat",
		colors = {
			primary = Color3.fromRGB(110, 110, 110),
			secondary = Color3.fromRGB(80, 80, 80)
		},
		abilities = {
			collectRange = 1.5,
			walkSpeed = 1.5
		},
		chance = 15
	},

	dragon = {
		id = "dragon",
		name = "Dragon",
		displayName = "Baby Dragon", 
		rarity = "Legendary",
		collectValue = 50,
		modelName = "Dragon",
		colors = {
			primary = Color3.fromRGB(255, 0, 0),
			secondary = Color3.fromRGB(255, 200, 0)
		},
		abilities = {
			coinMultiplier = 5.0,
			collectRange = 4.0
		},
		chance = 1
	}
}

-- Seeds and Crops
ItemConfig.Seeds = {
	carrot_seeds = {
		id = "carrot_seeds",
		name = "Carrot Seeds",
		type = "seed",
		price = 20,
		currency = "coins",
		description = "Plant these to grow carrots! Grows in 60 seconds.",
		growTime = 60,
		yieldAmount = 1,
		resultId = "carrot",
		coinReward = 30,
		image = "rbxassetid://6686038519"
	},

	corn_seeds = {
		id = "corn_seeds", 
		name = "Corn Seeds",
		type = "seed",
		price = 50,
		currency = "coins",
		description = "Plant these to grow corn! Grows in 120 seconds.",
		growTime = 120,
		yieldAmount = 3,
		resultId = "corn",
		coinReward = 75,
		image = "rbxassetid://6686045507"
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "Strawberry Seeds", 
		type = "seed",
		price = 100,
		currency = "coins",
		description = "Plant these to grow strawberries! Grows in 180 seconds.",
		growTime = 180,
		yieldAmount = 5,
		resultId = "strawberry",
		coinReward = 150,
		image = "rbxassetid://6686051791"
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "Golden Seeds",
		type = "seed", 
		price = 25,
		currency = "gems",
		description = "Rare seeds that grow magical fruit! Grows in 300 seconds.",
		growTime = 300,
		yieldAmount = 1,
		resultId = "golden_fruit",
		coinReward = 500,
		image = "rbxassetid://6686054839"
	}
}

-- Crops
ItemConfig.Crops = {
	carrot = {
		id = "carrot",
		name = "Carrot",
		feedValue = 1,
		sellValue = 30,
		image = "rbxassetid://6686041557"
	},

	corn = {
		id = "corn", 
		name = "Corn",
		feedValue = 2,
		sellValue = 75,
		image = "rbxassetid://6686047557"
	},

	strawberry = {
		id = "strawberry",
		name = "Strawberry",
		feedValue = 3,
		sellValue = 150,
		image = "rbxassetid://6686052839"
	},

	golden_fruit = {
		id = "golden_fruit",
		name = "Golden Fruit",
		feedValue = 10,
		sellValue = 500,
		image = "rbxassetid://6686056891"
	}
}

-- Shop Items (Consolidated)
ItemConfig.ShopItems = {
	-- Seeds
	carrot_seeds = ItemConfig.Seeds.carrot_seeds,
	corn_seeds = ItemConfig.Seeds.corn_seeds,
	strawberry_seeds = ItemConfig.Seeds.strawberry_seeds,
	golden_seeds = ItemConfig.Seeds.golden_seeds,

	-- Pets (direct purchase)
	basic_pet_egg = {
		id = "basic_pet_egg",
		name = "Basic Pet Egg", 
		type = "egg",
		price = 100,
		currency = "coins",
		description = "A basic egg containing common pets",
		possiblePets = {"bunny", "puppy"},
		image = "rbxassetid://123456789"
	},

	rare_pet_egg = {
		id = "rare_pet_egg",
		name = "Rare Pet Egg",
		type = "egg", 
		price = 50,
		currency = "gems",
		description = "A rare egg with better pets",
		possiblePets = {"cat", "bunny", "puppy"},
		image = "rbxassetid://123456790"
	},

	-- Upgrades
	speed_upgrade = {
		id = "speed_upgrade",
		name = "Speed Upgrade",
		type = "upgrade",
		price = 250,
		currency = "coins",
		description = "Increases your movement speed",
		maxLevel = 10,
		effectPerLevel = 2
	},

	collection_upgrade = {
		id = "collection_upgrade", 
		name = "Collection Speed",
		type = "upgrade",
		price = 300,
		currency = "coins",
		description = "Collect pets faster",
		maxLevel = 10,
		effectPerLevel = 0.1
	},

	farm_plot_upgrade = {
		id = "farm_plot_upgrade",
		name = "Extra Farm Plot",
		type = "upgrade",
		price = 500,
		currency = "coins", 
		description = "Unlock an additional farm plot",
		maxLevel = 7
	},

	-- Boosters
	coin_booster = {
		id = "coin_booster",
		name = "2x Coins Booster",
		type = "booster",
		price = 25,
		currency = "gems",
		description = "Double coins for 30 minutes",
		duration = 1800,
		boostType = "coins",
		multiplier = 2
	}
}

-- Spawn Areas
ItemConfig.SpawnAreas = {
	{
		name = "Starter Meadow",
		maxPets = 15,
		spawnInterval = 5,
		availablePets = {"bunny", "puppy"},
		spawnPositions = {
			Vector3.new(0, 1, 0),
			Vector3.new(10, 1, 10),
			Vector3.new(-10, 1, 10),
			Vector3.new(10, 1, -10),
			Vector3.new(-10, 1, -10)
		}
	},

	{
		name = "Mystic Forest",
		maxPets = 12,
		spawnInterval = 8,
		availablePets = {"bunny", "puppy", "cat"},
		spawnPositions = {
			Vector3.new(50, 1, 0),
			Vector3.new(60, 1, 10),
			Vector3.new(40, 1, 10)
		}
	},

	{
		name = "Dragon's Lair",
		maxPets = 8,
		spawnInterval = 12,
		availablePets = {"cat", "dragon"},
		spawnPositions = {
			Vector3.new(100, 1, 0),
			Vector3.new(110, 1, 10)
		}
	}
}

-- Developer Products (for Robux purchases)
ItemConfig.DeveloperProducts = {
	[1234567] = {
		id = 1234567,
		name = "Small Gem Pack",
		currencyType = "gems",
		amount = 100,
		robuxCost = 50
	},

	[1234568] = {
		id = 1234568,
		name = "Medium Gem Pack", 
		currencyType = "gems",
		amount = 500,
		robuxCost = 200
	},

	[1234569] = {
		id = 1234569,
		name = "Large Gem Pack",
		currencyType = "gems",
		amount = 1000,
		robuxCost = 400
	},

	[1234570] = {
		id = 1234570,
		name = "Coin Pack",
		currencyType = "coins", 
		amount = 10000,
		robuxCost = 100
	}
}

-- Game Passes
ItemConfig.GamePasses = {
	[2345678] = {
		id = 2345678,
		name = "VIP Pass",
		description = "2x coins, exclusive pets, and special perks",
		effects = {
			coinMultiplier = 2,
			exclusivePets = true,
			chatTag = "VIP"
		}
	},

	[2345679] = {
		id = 2345679,
		name = "Auto Collect Pass",
		description = "Automatically collect nearby pets",
		effects = {
			autoCollect = true
		}
	},

	[2345680] = {
		id = 2345680,
		name = "Pet Storage Pass",
		description = "Store up to 500 pets instead of 100",
		effects = {
			petStorage = 500
		}
	}
}

-- Achievements
ItemConfig.Achievements = {
	first_pet = {
		id = "first_pet",
		name = "First Friend",
		description = "Collect your first pet",
		coinReward = 50,
		condition = function(stats) return stats.totalPetsCollected >= 1 end
	},

	ten_pets = {
		id = "ten_pets",
		name = "Pet Enthusiast", 
		description = "Collect 10 pets",
		coinReward = 200,
		condition = function(stats) return stats.totalPetsCollected >= 10 end
	},

	first_harvest = {
		id = "first_harvest",
		name = "Green Thumb",
		description = "Harvest your first crop",
		coinReward = 100,
		condition = function(stats) return stats.cropsHarvested >= 1 end
	},

	hundred_pets = {
		id = "hundred_pets",
		name = "Pet Master",
		description = "Collect 100 pets",
		coinReward = 1000,
		condition = function(stats) return stats.totalPetsCollected >= 100 end
	},

	first_legendary = {
		id = "first_legendary",
		name = "Legend Hunter",
		description = "Collect your first legendary pet",
		coinReward = 500,
		condition = function(stats) return stats.legendaryPetsFound >= 1 end
	},

	millionaire = {
		id = "millionaire",
		name = "Millionaire",
		description = "Earn 1,000,000 coins total",
		coinReward = 10000,
		condition = function(stats) return stats.coinsEarned >= 1000000 end
	}
}

-- Rarity Configuration
ItemConfig.RarityInfo = {
	Common = { 
		color = Color3.fromRGB(150, 150, 150),
		chance = 70,
		coinMultiplier = 1.0
	},
	Uncommon = {
		color = Color3.fromRGB(100, 200, 100), 
		chance = 20,
		coinMultiplier = 1.5
	},
	Rare = {
		color = Color3.fromRGB(100, 100, 255),
		chance = 7,
		coinMultiplier = 3.0
	},
	Epic = {
		color = Color3.fromRGB(200, 100, 200),
		chance = 2.5,
		coinMultiplier = 10.0
	},
	Legendary = {
		color = Color3.fromRGB(255, 215, 0),
		chance = 0.5,
		coinMultiplier = 50.0
	}
}

-- Utility Functions
function ItemConfig.GetPetsByRarity(rarity)
	local pets = {}
	for _, pet in pairs(ItemConfig.Pets) do
		if pet.rarity == rarity then
			table.insert(pets, pet)
		end
	end
	return pets
end

function ItemConfig.GetRandomPetByRarity(rarity)
	local pets = ItemConfig.GetPetsByRarity(rarity)
	if #pets > 0 then
		return pets[math.random(1, #pets)]
	end
	return nil
end

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

	-- Fallback to first pet
	for _, pet in pairs(ItemConfig.Pets) do
		return pet
	end
end

function ItemConfig.ValidateItemId(itemId)
	return ItemConfig.ShopItems[itemId] ~= nil
end

function ItemConfig.GetItemPrice(itemId)
	local item = ItemConfig.ShopItems[itemId]
	return item and item.price or 0
end

function ItemConfig.GetItemCurrency(itemId)
	local item = ItemConfig.ShopItems[itemId]
	return item and item.currency or "coins"
end

return ItemConfig