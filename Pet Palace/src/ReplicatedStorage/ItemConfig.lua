--[[
    ItemConfig.lua - COMPLETE VERSION WITH ALL MISSING ITEMS
    Place in: ReplicatedStorage/ItemConfig.lua
    
    ADDED:
    ✅ Missing mining ores (bronze, platinum)
    ✅ Complete milk efficiency upgrade chain
    ✅ All mega upgrades from pig system
    ✅ Missing cave unlock items
    ✅ Complete tool upgrade chain
    ✅ Fixed ore definitions in MiningSystem
]]

local ItemConfig = {}

ItemConfig.RaritySystem = {
	common    = { name = "Common",    color = Color3.fromRGB(255,255,255), sizeMultiplier = 1.0, valueMultiplier = 1.0, dropChance = 0.5, effects = {}, tier = 1 },
	uncommon  = { name = "Uncommon",  color = Color3.fromRGB(0,255,0),   sizeMultiplier = 1.1, valueMultiplier = 1.2, dropChance = 0.25, effects = {"sparkle"}, tier = 2 },
	rare      = { name = "Rare",      color = Color3.fromRGB(255,215,0), sizeMultiplier = 1.2, valueMultiplier = 1.5, dropChance = 0.07, effects = {"golden_shine"}, tier = 3 },
	epic      = { name = "Epic",      color = Color3.fromRGB(128,0,128), sizeMultiplier = 1.8, valueMultiplier = 2.0, dropChance = 0.025, effects = {"purple_aura"}, tier = 4 },
	legendary = { name = "Legendary", color = Color3.fromRGB(255,100,100), sizeMultiplier = 2.0, valueMultiplier = 3.0, dropChance = 0.005, effects = {"legendary_glow"}, tier = 5 },
}

ItemConfig.Crops = {
	cabbage = { id = "cabbage", name = "🥬 Cabbage", type = "crop", category = "crops", description = "Fresh leafy cabbage.", sellValue = 12, sellCurrency = "farmTokens", feedValue = 3, cropPoints = 3, icon = "🥬", craftingMaterial = true },
	radish  = { id = "radish",  name = "🌶️ Radish",  type = "crop", category = "crops", description = "Spicy radish.",      sellValue = 15, sellCurrency = "farmTokens", feedValue = 4, cropPoints = 4, icon = "🌶️", craftingMaterial = true },
}

-- ========== LIVESTOCK SYSTEM ==========

ItemConfig.CowSystem = {
	baseCooldown = 3,
	milkValue = 10,
	maxUpgradeLevel = 10,
	cooldownReduction = {
		[1] = 2, [2] = 3, [3] = 4, [4] = 5, [5] = 6,
		[6] = 7, [7] = 8, [8] = 9, [9] = 10, [10] = 12
	}
}

ItemConfig.PigSystem = {
	baseCropPointsNeeded = 100,
	growthPerPoint = 0.01,
	maxSize = 3.0,
	getCropPointsNeeded = function(transformationCount)
		return 100 + (transformationCount * 50)
	end,
	megaDrops = {
		"mega_milk_boost", "mega_growth_speed", "mega_crop_multiplier", 
		"mega_efficiency", "mega_golden_touch"
	}
}

-- ========== PEST SYSTEM ==========

ItemConfig.PestSystem = {
	spawnRates = {
		aphids = 0.15,
		locusts = 0.05,
		fungal_blight = 0.03
	},
	damageRates = {
		aphids = 0.1,
		locusts = 0.25,
		fungal_blight = 0.15
	},
	pestData = {
		aphids = {
			name = "Aphids",
			icon = "🐛",
			description = "Small bugs that slowly drain crop health",
			maxPerCrop = 3,
			spreadChance = 0.1,
			weatherPreference = "any",
			seasonMultiplier = 1.0
		},
		locusts = {
			name = "Locust Swarm", 
			icon = "🦗",
			description = "Devastating swarms that attack multiple crops",
			maxPerCrop = 1,
			spreadChance = 0.3,
			weatherPreference = "dry",
			seasonMultiplier = 1.5,
			swarmRadius = 2
		},
		fungal_blight = {
			name = "Fungal Blight",
			icon = "🍄",
			description = "Disease that spreads between crops in wet conditions",
			maxPerCrop = 1,
			spreadChance = 0.25,
			weatherPreference = "wet", 
			seasonMultiplier = 1.3,
			spreadRadius = 1
		}
	}
}

-- ========== CHICKEN DEFENSE SYSTEM ==========

ItemConfig.ChickenSystem = {
	chickenTypes = {
		basic_chicken = {
			name = "Basic Chicken",
			icon = "🐔",
			description = "Auto-deploys to your farm! Eliminates aphids and lays eggs for steady income.",
			price = 150,
			currency = "coins",
			pestTargets = {"aphids"},
			huntRange = 3,
			huntSpeed = 2,
			huntEfficiency = 0.8,
			eggProductionTime = 240,
			eggValue = 5,
			feedConsumption = 1,
			maxHunger = 24,
			lifespan = 2880
		},
		guinea_fowl = {
			name = "Guinea Fowl",
			icon = "🦃", 
			description = "Specialized anti-locust defense with alarm calls",
			price = 300,
			currency = "coins",
			pestTargets = {"locusts", "aphids"},
			huntRange = 5,
			huntSpeed = 4,
			huntEfficiency = 0.95,
			alarmSystem = true,
			swarmDetection = 8,
			eggProductionTime = 360,
			eggValue = 8,
			feedConsumption = 1.5,
			maxHunger = 20,
			lifespan = 3600
		},
		rooster = {
			name = "Rooster",
			icon = "🐓",
			description = "Provides area protection boost and flock coordination",
			price = 500,
			currency = "coins",
			pestTargets = {"aphids", "fungal_blight"},
			huntRange = 4,
			huntSpeed = 3,
			huntEfficiency = 0.85,
			areaBoost = true,
			boostRadius = 6,
			boostMultiplier = 1.5,
			intimidationFactor = 0.2,
			eggProductionTime = 480,
			eggValue = 12,
			feedConsumption = 2,
			maxHunger = 18,
			lifespan = 4320
		}
	},
	feedTypes = {
		basic_feed = {
			name = "Basic Chicken Feed",
			feedValue = 6,
			price = 10,
			currency = "coins"
		},
		premium_feed = {
			name = "Premium Chicken Feed", 
			feedValue = 12,
			eggBonus = 1.2,
			price = 25,
			currency = "coins"
		},
		grain_feed = {
			name = "Grain Feed",
			feedValue = 8,
			healthBonus = 1.1,
			craftable = true,
			recipe = {corn = 2, wheat = 1}
		}
	}
}

-- ========== CURRENCIES ==========

ItemConfig.Currencies = {
	coins = {
		name = "Coins",
		icon = "💰",
		source = "Milk collection from cow",
		color = Color3.fromRGB(255, 215, 0)
	},
	farmTokens = {
		name = "Farm Tokens", 
		icon = "🌾",
		source = "Selling crops",
		color = Color3.fromRGB(34, 139, 34)
	}
}

-- ========== FIXED MINING SYSTEM (Added Missing Ores) ==========

ItemConfig.MiningSystem = {
	skillLevels = {
		{level = 1, xpRequired = 0, name = "Novice Miner"},
		{level = 2, xpRequired = 100, name = "Apprentice Miner"},
		{level = 3, xpRequired = 250, name = "Skilled Miner"},
		{level = 4, xpRequired = 500, name = "Expert Miner"},
		{level = 5, xpRequired = 1000, name = "Master Miner"},
		{level = 6, xpRequired = 2000, name = "Legendary Miner"},
		{level = 7, xpRequired = 3500, name = "Cave Explorer"},
		{level = 8, xpRequired = 5500, name = "Deep Miner"},
		{level = 9, xpRequired = 8000, name = "Ore Master"},
		{level = 10, xpRequired = 12000, name = "Mining Legend"}
	},

	-- FIXED: Added all missing ore types referenced by MiningSystem
	ores = {
		copper_ore = {
			name = "Copper Ore",
			icon = "🟤",
			color = Color3.fromRGB(184, 115, 51),
			hardness = 1,
			xpReward = 10,
			respawnTime = 60,
			sellValue = 5,
			requiredLevel = 1,
			spawnChance = 0.4
		},
		bronze_ore = {
			name = "Bronze Ore",
			icon = "🟫", 
			color = Color3.fromRGB(205, 127, 50),
			hardness = 1.5,
			xpReward = 12,
			respawnTime = 75,
			sellValue = 8,
			requiredLevel = 2,
			spawnChance = 0.35
		},
		iron_ore = {
			name = "Iron Ore", 
			icon = "⚫",
			color = Color3.fromRGB(105, 105, 105),
			hardness = 2,
			xpReward = 15,
			respawnTime = 90,
			sellValue = 10,
			requiredLevel = 2,
			spawnChance = 0.3
		},
		silver_ore = {
			name = "Silver Ore",
			icon = "⚪",
			color = Color3.fromRGB(192, 192, 192),
			hardness = 3,
			xpReward = 25,
			respawnTime = 120,
			sellValue = 20,
			requiredLevel = 3,
			spawnChance = 0.2
		},
		gold_ore = {
			name = "Gold Ore",
			icon = "🟡",
			color = Color3.fromRGB(255, 215, 0),
			hardness = 4,
			xpReward = 40,
			respawnTime = 180,
			sellValue = 40,
			requiredLevel = 4,
			spawnChance = 0.08
		},
		platinum_ore = {
			name = "Platinum Ore",
			icon = "⚪",
			color = Color3.fromRGB(229, 228, 226),
			hardness = 5,
			xpReward = 60,
			respawnTime = 240,
			sellValue = 75,
			requiredLevel = 6,
			spawnChance = 0.05
		},
		diamond_ore = {
			name = "Diamond Ore",
			icon = "💎",
			color = Color3.fromRGB(185, 242, 255),
			hardness = 5,
			xpReward = 75,
			respawnTime = 300,
			sellValue = 100,
			requiredLevel = 5,
			spawnChance = 0.02
		},
		obsidian_ore = {
			name = "Obsidian Ore",
			icon = "⬛",
			color = Color3.fromRGB(20, 20, 20),
			hardness = 6,
			xpReward = 150,
			respawnTime = 600,
			sellValue = 250,
			requiredLevel = 8,
			spawnChance = 0.005
		}
	},

	-- FIXED: Added missing tools
	tools = {
		wooden_pickaxe = {
			name = "Wooden Pickaxe",
			power = 1,
			durability = 50,
			speed = 1.0,
			canMine = {"copper_ore"}
		},
		stone_pickaxe = {
			name = "Stone Pickaxe",
			power = 2,
			durability = 100, 
			speed = 1.2,
			canMine = {"copper_ore", "bronze_ore", "iron_ore"}
		},
		iron_pickaxe = {
			name = "Iron Pickaxe",
			power = 3,
			durability = 200,
			speed = 1.5,
			canMine = {"copper_ore", "bronze_ore", "iron_ore", "silver_ore"}
		},
		gold_pickaxe = {
			name = "Gold Pickaxe",
			power = 4,
			durability = 150,
			speed = 2.0,
			canMine = {"copper_ore", "bronze_ore", "iron_ore", "silver_ore", "gold_ore"}
		},
		diamond_pickaxe = {
			name = "Diamond Pickaxe",
			power = 5,
			durability = 500,
			speed = 2.5,
			canMine = {"copper_ore", "bronze_ore", "iron_ore", "silver_ore", "gold_ore", "diamond_ore"}
		},
		platinum_pickaxe = {
			name = "Platinum Pickaxe",
			power = 6,
			durability = 750,
			speed = 3.0,
			canMine = {"copper_ore", "bronze_ore", "iron_ore", "silver_ore", "gold_ore", "platinum_ore", "diamond_ore"}
		},
		obsidian_pickaxe = {
			name = "Obsidian Pickaxe",
			power = 7,
			durability = 1000,
			speed = 3.5,
			canMine = {"copper_ore", "bronze_ore", "iron_ore", "silver_ore", "gold_ore", "platinum_ore", "diamond_ore", "obsidian_ore"}
		}
	}
}

-- ========== COMPLETE SHOP ITEMS (Added All Missing Items) ==========

ItemConfig.ShopItems = {
	-- ========== MINING TOOLS & ACCESS ==========
	wooden_pickaxe = {
		id = "wooden_pickaxe",
		name = "⛏️ Wooden Pickaxe",
		type = "tool",
		category = "mining",
		price = 50,
		currency = "coins",
		description = "Basic mining tool. Can mine copper and bronze ore.",
		icon = "⛏️",
		maxQuantity = 1,
		toolData = {
			power = 1,
			durability = 50,
			speed = 1.0,
			canMine = {"copper_ore", "bronze_ore"}
		}
	},

	stone_pickaxe = {
		id = "stone_pickaxe",
		name = "🪨 Stone Pickaxe",
		type = "tool",
		category = "mining",
		price = 150,
		currency = "coins",
		description = "Improved mining tool. Can mine up to iron ore.",
		icon = "🪨",
		maxQuantity = 1,
		requiresPurchase = "wooden_pickaxe",
		toolData = {
			power = 2,
			durability = 100,
			speed = 1.2,
			canMine = {"copper_ore", "bronze_ore", "iron_ore"}
		}
	},

	iron_pickaxe = {
		id = "iron_pickaxe",
		name = "⚒️ Iron Pickaxe",
		type = "tool",
		category = "mining",
		price = 500,
		currency = "coins",
		description = "Professional mining tool. Can mine up to silver ore.",
		icon = "⚒️",
		maxQuantity = 1,
		requiresPurchase = "stone_pickaxe",
		toolData = {
			power = 3,
			durability = 200,
			speed = 1.5,
			canMine = {"copper_ore", "bronze_ore", "iron_ore", "silver_ore"}
		}
	},

	diamond_pickaxe = {
		id = "diamond_pickaxe",
		name = "💎 Diamond Pickaxe",
		type = "tool",
		category = "mining",
		price = 2500,
		currency = "coins",
		description = "Premium mining tool. Can mine all common ores including gold and diamonds.",
		icon = "💎",
		maxQuantity = 1,
		requiresPurchase = "iron_pickaxe",
		toolData = {
			power = 5,
			durability = 500,
			speed = 2.5,
			canMine = {"copper_ore", "bronze_ore", "iron_ore", "silver_ore", "gold_ore", "diamond_ore"}
		}
	},

	obsidian_pickaxe = {
		id = "obsidian_pickaxe",
		name = "⬛ Obsidian Pickaxe",
		type = "tool",
		category = "premium",
		price = 200,
		currency = "farmTokens",
		description = "🏆 LEGENDARY MINING TOOL 🏆\nCan mine all ores including rare obsidian!",
		icon = "⬛",
		maxQuantity = 1,
		requiresPurchase = "diamond_pickaxe",
		toolData = {
			power = 7,
			durability = 1000,
			speed = 3.5,
			canMine = {"copper_ore", "bronze_ore", "iron_ore", "silver_ore", "gold_ore", "platinum_ore", "diamond_ore", "obsidian_ore"}
		}
	},

	cave_access_pass = {
		id = "cave_access_pass",
		name = "🕳️ Cave Access Pass",
		type = "access",
		category = "mining", 
		price = 200,
		currency = "coins",
		description = "Grants access to Cave 1 (Copper Mine)! Start your mining journey!",
		icon = "🕳️",
		maxQuantity = 1,
		effects = {
			unlockArea = "mining_caves",
			unlocksCave = 1
		}
	},

	-- CAVE UNLOCK ITEMS (Added these - they were missing!)
	cave_2_unlock = {
		id = "cave_2_unlock",
		name = "🏔️ Bronze & Silver Mine Access",
		type = "access",
		category = "mining",
		price = 1000,
		currency = "coins",
		description = "Unlock access to Cave 2: Bronze & Silver Mine with better ore types!",
		icon = "🏔️",
		maxQuantity = 1,
		requiresPurchase = "cave_access_pass",
		effects = {
			unlocksCave = 2
		}
	},

	cave_3_unlock = {
		id = "cave_3_unlock",
		name = "⛰️ Gold Mine Access",
		type = "access",
		category = "mining",
		price = 5000,
		currency = "coins",
		description = "Unlock access to Cave 3: Gold Mine with precious metal deposits!",
		icon = "⛰️",
		maxQuantity = 1,
		requiresPurchase = "cave_2_unlock",
		effects = {
			unlocksCave = 3
		}
	},

	cave_4_unlock = {
		id = "cave_4_unlock",
		name = "🏔️ Platinum Mine Access",
		type = "access",
		category = "mining",
		price = 15000,
		currency = "coins",
		description = "Unlock access to Cave 4: Rare platinum deposits in deep chambers!",
		icon = "🏔️",
		maxQuantity = 1,
		requiresPurchase = "cave_3_unlock",
		effects = {
			unlocksCave = 4
		}
	},

	cave_5_unlock = {
		id = "cave_5_unlock",
		name = "🌋 Obsidian Depths Access",
		type = "access",
		category = "premium",
		price = 100,
		currency = "farmTokens",
		description = "🏆 LEGENDARY CAVE ACCESS 🏆\nUnlock the deepest cave with mystical obsidian!",
		icon = "🌋",
		maxQuantity = 1,
		requiresPurchase = "cave_4_unlock",
		effects = {
			unlocksCave = 5
		}
	},

	-- ========== CRAFTING STATIONS ==========
	workbench = {
		id = "workbench",
		name = "🔨 Workbench",
		type = "building",
		category = "crafting",
		price = 500,
		currency = "coins",
		description = "Basic crafting station for making tools and equipment.",
		icon = "🔨",
		maxQuantity = 1,
		buildingData = {
			size = Vector3.new(6, 4, 6),
			craftingType = "workbench"
		}
	},

	forge = {
		id = "forge",
		name = "🔥 Forge",
		type = "building", 
		category = "crafting",
		price = 2000,
		currency = "coins",
		description = "Advanced metalworking station for creating powerful tools.",
		icon = "🔥",
		maxQuantity = 1,
		requiresPurchase = "workbench",
		buildingData = {
			size = Vector3.new(8, 6, 8),
			craftingType = "forge"
		}
	},

	mystical_altar = {
		id = "mystical_altar",
		name = "🔮 Mystical Altar",
		type = "building",
		category = "premium",
		price = 100,
		currency = "farmTokens",
		description = "🏆 LEGENDARY CRAFTING STATION 🏆\nCraft the most powerful items in the game!",
		icon = "🔮",
		maxQuantity = 1,
		requiresPurchase = "forge"
	},

	-- ========== CROP ENHANCEMENT ==========
	super_fertilizer = {
		id = "super_fertilizer",
		name = "🌱 Super Fertilizer",
		type = "enhancement",
		category = "farming",
		price = 100,
		currency = "coins",
		description = "Increases crop rarity chance by 20% for next harvest!",
		icon = "🌱",
		maxQuantity = 10,
		effects = {
			rarityBoost = 0.20,
			duration = 600
		}
	},

	rarity_booster = {
		id = "rarity_booster", 
		name = "✨ Rarity Booster",
		type = "enhancement",
		category = "premium",
		price = 25,
		currency = "farmTokens",
		description = "🏆 PREMIUM ITEM 🏆\nGuarantees at least Rare rarity for next 3 harvests!",
		icon = "✨",
		maxQuantity = 5,
		effects = {
			guaranteedRarity = "rare",
			uses = 3
		}
	},

	-- ========== SEEDS ==========
	carrot_seeds = {
		id = "carrot_seeds",
		name = "🥕 Carrot Seeds",
		type = "seed",
		category = "seeds",
		price = 25,
		currency = "coins",
		description = "Fast-growing carrots. Ready in 5 minutes. Worth 1 crop point when fed to pig.",
		requiresFarmPlot = true,
		icon = "🥕",
		maxQuantity = 50,
		farmingData = {
			growTime = 10,
			yieldAmount = 2,
			resultCropId = "carrot",
			cropPoints = 1,
			stages = {"planted", "sprouting", "growing", "ready"},
			pestVulnerability = {
				aphids = 1.0,
				locusts = 0.8,
				fungal_blight = 1.2
			}
		}
	},

	corn_seeds = {
		id = "corn_seeds", 
		name = "🌽 Corn Seeds",
		type = "seed",
		category = "seeds",
		price = 50,
		currency = "coins",
		description = "High-yield corn. Ready in 8 minutes. Worth 2 crop points when fed to pig.",
		requiresFarmPlot = true,
		icon = "🌽",
		maxQuantity = 50,
		farmingData = {
			growTime = 20,
			yieldAmount = 3,
			resultCropId = "corn",
			cropPoints = 2,
			stages = {"planted", "sprouting", "growing", "ready"},
			pestVulnerability = {
				aphids = 0.7,
				locusts = 1.5,
				fungal_blight = 0.9
			}
		}
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "🍓 Strawberry Seeds", 
		type = "seed",
		category = "seeds",
		price = 100,
		currency = "coins",
		description = "Sweet strawberries. Ready in 10 minutes. Worth 3 crop points when fed to pig.",
		icon = "🍓",
		maxQuantity = 50,
		requiresFarmPlot = true,
		farmingData = {
			growTime = 60,
			yieldAmount = 2,
			resultCropId = "strawberry",
			cropPoints = 3,
			stages = {"planted", "sprouting", "growing", "ready"},
			pestVulnerability = {
				aphids = 1.3,
				locusts = 0.9,
				fungal_blight = 1.1
			}
		}
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "✨ Golden Seeds",
		type = "seed",
		category = "premium",
		price = 50,
		currency = "farmTokens",
		description = "Magical golden fruit! Ready in 15 minutes. Worth 10 crop points when fed to pig!",
		icon = "✨",
		maxQuantity = 25,
		requiresFarmPlot = true,
		farmingData = {
			growTime = 900,
			yieldAmount = 1,
			resultCropId = "golden_fruit",
			cropPoints = 10,
			stages = {"planted", "sprouting", "growing", "ready"},
			pestVulnerability = {
				aphids = 0.3,
				locusts = 0.2,
				fungal_blight = 0.1
			}
		}
	},

	wheat_seeds = {
		id = "wheat_seeds",
		name = "🌾 Wheat Seeds",
		type = "seed",
		category = "seeds",
		price = 30,
		currency = "coins",
		description = "Hardy wheat that grows in all conditions. Perfect for making bread!",
		requiresFarmPlot = true,
		icon = "🌾",
		maxQuantity = 100,
		farmingData = {
			growTime = 45,
			baseYieldAmount = 3,
			resultCropId = "wheat",
			cropPoints = 2,
			stages = {"planted", "sprouting", "growing", "ready"},
			naturalColor = Color3.fromRGB(218, 165, 32),
			pestVulnerability = {
				aphids = 0.8,
				locusts = 1.2,
				fungal_blight = 0.9
			}
		}
	},

	potato_seeds = {
		id = "potato_seeds",
		name = "🥔 Potato Seeds",
		type = "seed", 
		category = "seeds",
		price = 40,
		currency = "coins",
		description = "Versatile potatoes that grow underground. Great for cooking!",
		requiresFarmPlot = true,
		icon = "🥔",
		maxQuantity = 100,
		farmingData = {
			growTime = 60,
			baseYieldAmount = 4,
			resultCropId = "potato",
			cropPoints = 2,
			stages = {"planted", "sprouting", "growing", "ready"},
			naturalColor = Color3.fromRGB(160, 82, 45),
			pestVulnerability = {
				aphids = 0.6,
				locusts = 0.7,
				fungal_blight = 1.4
			}
		}
	},

	cabbage_seeds = {
		id = "cabbage_seeds",
		name = "🥬 Cabbage Seeds", 
		type = "seed",
		category = "seeds",
		price = 35,
		currency = "coins",
		description = "Leafy green cabbages packed with nutrients. Animals love them!",
		requiresFarmPlot = true,
		icon = "🥬",
		maxQuantity = 100,
		farmingData = {
			growTime = 50,
			baseYieldAmount = 2,
			resultCropId = "cabbage",
			cropPoints = 3,
			stages = {"planted", "sprouting", "growing", "ready"},
			naturalColor = Color3.fromRGB(34, 139, 34),
			pestVulnerability = {
				aphids = 1.3,
				locusts = 1.1,
				fungal_blight = 0.8
			}
		}
	},

	radish_seeds = {
		id = "radish_seeds",
		name = "🌶️ Radish Seeds",
		type = "seed",
		category = "seeds", 
		price = 25,
		currency = "coins",
		description = "Quick-growing spicy radishes. Ready in no time!",
		requiresFarmPlot = true,
		icon = "🌶️",
		maxQuantity = 100,
		farmingData = {
			growTime = 30,
			baseYieldAmount = 2,
			resultCropId = "radish",
			cropPoints = 1,
			stages = {"planted", "sprouting", "growing", "ready"},
			naturalColor = Color3.fromRGB(220, 20, 60),
			pestVulnerability = {
				aphids = 0.9,
				locusts = 0.8,
				fungal_blight = 1.0
			}
		}
	},

	broccoli_seeds = {
		id = "broccoli_seeds",
		name = "🥦 Broccoli Seeds",
		type = "seed",
		category = "seeds",
		price = 45,
		currency = "coins", 
		description = "Nutritious green broccoli. Takes time but worth the wait!",
		requiresFarmPlot = true,
		icon = "🥦",
		maxQuantity = 100,
		farmingData = {
			growTime = 75,
			baseYieldAmount = 2,
			resultCropId = "broccoli", 
			cropPoints = 4,
			stages = {"planted", "sprouting", "growing", "ready"},
			naturalColor = Color3.fromRGB(34, 139, 34),
			pestVulnerability = {
				aphids = 1.1,
				locusts = 0.9,
				fungal_blight = 1.2
			}
		}
	},

	tomato_seeds = {
		id = "tomato_seeds",
		name = "🍅 Tomato Seeds",
		type = "seed",
		category = "seeds",
		price = 55,
		currency = "coins",
		description = "Juicy red tomatoes perfect for cooking. High value crop!",
		requiresFarmPlot = true,
		icon = "🍅", 
		maxQuantity = 100,
		farmingData = {
			growTime = 90,
			baseYieldAmount = 3,
			resultCropId = "tomato",
			cropPoints = 5,
			stages = {"planted", "sprouting", "growing", "ready"},
			naturalColor = Color3.fromRGB(255, 99, 71),
			pestVulnerability = {
				aphids = 1.2,
				locusts = 1.0,
				fungal_blight = 1.3
			}
		}
	},

	glorious_sunflower_seeds = {
		id = "glorious_sunflower_seeds",
		name = "🌻 Glorious Sunflower Seeds",
		type = "seed",
		category = "premium",
		price = 150,
		currency = "farmTokens",
		description = "🏆 PREMIUM LEGENDARY SEED 🏆\nThe rarest and most beautiful crop! Massive size with brilliant glow!",
		requiresFarmPlot = true,
		icon = "🌻",
		maxQuantity = 10,
		isPremium = true,
		farmingData = {
			growTime = 180,
			baseYieldAmount = 1,
			resultCropId = "glorious_sunflower",
			cropPoints = 25,
			stages = {"planted", "sprouting", "growing", "flowering", "glorious"},
			naturalColor = Color3.fromRGB(255, 215, 0),
			sizeMultiplier = 4.0,
			alwaysLegendary = true,
			specialEffects = {
				"sunflower_rays", "golden_particles", "divine_glow"
			},
			pestVulnerability = {
				aphids = 0.1,
				locusts = 0.1,
				fungal_blight = 0.1
			}
		}
	},

	-- ========== FARM UPGRADES ==========
	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "🌾 Your First Farm Plot",
		type = "farmPlot",
		category = "farm",
		price = 100,
		currency = "coins",
		description = "Purchase your first farming plot! Includes free starter seeds.",
		maxQuantity = 1,
		icon = "🌾",
		effects = {
			enableFarming = true,
			starterSeeds = {
				carrot_seeds = 5,
				corn_seeds = 3
			}
		}
	},

	farm_plot_expansion = {
		id = "farm_plot_expansion",
		name = "🚜 Farm Plot Expansion",
		type = "farmPlot",
		category = "farm",
		price = 500,
		currency = "coins",
		description = "Add more farming space! Each expansion gives you another farm plot.",
		icon = "🚜",
		maxQuantity = 9,
		requiresPurchase = "farm_plot_starter"
	},

	-- ========== ROOF PROTECTION ==========
	basic_roof = {
		id = "basic_roof",
		name = "🏠 Basic Roof Protection",
		type = "roof",
		category = "farm",
		price = 500,
		currency = "coins",
		description = "Protect your crops from UFO attacks! Basic roof covers 1 farm plot.",
		icon = "🏠",
		maxQuantity = 10,
		requiresPurchase = "farm_plot_starter",
		effects = {
			coverage = 1,
			ufoProtection = true
		}
	},

	reinforced_roof = {
		id = "reinforced_roof", 
		name = "🏘️ Reinforced Roof Protection",
		type = "roof",
		category = "farm",
		price = 1500,
		currency = "coins",
		description = "Heavy-duty roof protection! Covers 4 plots and is UFO-proof.",
		icon = "🏘️",
		maxQuantity = 3,
		requiresPurchase = "basic_roof",
		effects = {
			coverage = 4,
			ufoProtection = true,
			enhanced = true
		}
	},

	mega_dome = {
		id = "mega_dome",
		name = "🛡️ Mega Protection Dome", 
		type = "roof",
		category = "premium",
		price = 100,
		currency = "farmTokens",
		description = "Ultimate protection! Dome covers ALL your farm plots and blocks UFO attacks completely.",
		icon = "🛡️",
		maxQuantity = 1,
		requiresPurchase = "reinforced_roof",
		effects = {
			coverage = 999,
			ufoProtection = true,
			ultimate = true
		}
	},

	-- ========== CHICKEN DEFENSE ==========
	basic_chicken = {
		id = "basic_chicken",
		name = "🐔 Basic Chicken",
		type = "chicken",
		category = "defense",
		price = 150,
		currency = "coins",
		description = "Auto-deploys to your farm! Eliminates aphids and lays eggs for steady income.",
		icon = "🐔",
		maxQuantity = 20,
		effects = {
			pestControl = {"aphids"},
			eggProduction = 5
		}
	},

	guinea_fowl = {
		id = "guinea_fowl", 
		name = "🦃 Guinea Fowl",
		type = "chicken",
		category = "defense",
		price = 300,
		currency = "coins",
		description = "Anti-locust specialist. Provides early warning system and superior pest elimination.",
		icon = "🦃",
		maxQuantity = 10,
		requiresPurchase = "basic_chicken",
		effects = {
			pestControl = {"locusts", "aphids"},
			alarmSystem = true
		}
	},

	rooster = {
		id = "rooster",
		name = "🐓 Rooster", 
		type = "chicken",
		category = "defense",
		price = 500,
		currency = "coins",
		description = "Flock leader that boosts all nearby chickens and reduces pest spawn rates.",
		icon = "🐓",
		maxQuantity = 3,
		requiresPurchase = "guinea_fowl",
		effects = {
			areaBoost = 1.5,
			pestReduction = 0.2
		}
	},

	-- ========== CHICKEN FEED ==========
	basic_feed = {
		id = "basic_feed",
		name = "🌾 Basic Chicken Feed",
		type = "feed",
		category = "defense", 
		price = 10,
		currency = "coins",
		description = "Keeps chickens fed and working. Each unit provides 6 hours of feeding.",
		icon = "🌾",
		maxQuantity = 100,
		effects = {
			feedValue = 6
		}
	},

	premium_feed = {
		id = "premium_feed",
		name = "⭐ Premium Chicken Feed",
		type = "feed", 
		category = "defense",
		price = 25,
		currency = "coins",
		description = "High-quality feed that increases egg production by 20% and lasts 12 hours.",
		icon = "⭐",
		maxQuantity = 50,
		requiresPurchase = "basic_feed",
		effects = {
			feedValue = 12,
			eggBonus = 1.2
		}
	},

	-- ========== PEST CONTROL TOOLS ==========
	organic_pesticide = {
		id = "organic_pesticide",
		name = "🧪 Organic Pesticide",
		type = "tool",
		category = "tools",
		price = 50,
		currency = "coins", 
		description = "Manually eliminate pests from crops. One-time use, affects 3x3 area around target crop.",
		icon = "🧪",
		maxQuantity = 20,
		effects = {
			pestElimination = "all",
			area = 9
		}
	},

	pest_detector = {
		id = "pest_detector",
		name = "📡 Pest Detector",
		type = "upgrade",
		category = "tools",
		price = 200,
		currency = "coins",
		description = "Early warning system that alerts you to pest infestations before they cause major damage.",
		icon = "📡",
		maxQuantity = 1,
		effects = {
			earlyWarning = true,
			detectionRange = 20
		}
	},

	super_pesticide = {
		id = "super_pesticide",
		name = "💉 Super Pesticide",
		type = "tool",
		category = "tools",
		price = 25,
		currency = "farmTokens",
		description = "Industrial-grade pesticide that eliminates ALL pests from your entire farm instantly!",
		icon = "💉",
		maxQuantity = 5,
		requiresPurchase = "organic_pesticide",
		effects = {
			pestElimination = "all",
			area = 999,
			instant = true
		}
	},

	-- ========== COMPLETE MILK EFFICIENCY UPGRADES (Fixed Missing Ones) ==========
	milk_efficiency_1 = {
		id = "milk_efficiency_1",
		name = "🥛 Enhanced Milking I",
		type = "upgrade",
		category = "farm",
		price = 100,
		currency = "coins",
		description = "Reduce milk collection cooldown by 2 seconds and +1 milk per collection.",
		maxQuantity = 1,
		icon = "🥛",
		effects = { 
			cooldownReduction = 2,
			milkYieldBonus = 1
		}
	},

	milk_efficiency_2 = {
		id = "milk_efficiency_2",
		name = "🥛 Enhanced Milking II",
		type = "upgrade",
		category = "farm",
		price = 250,
		currency = "coins",
		description = "Reduce milk collection cooldown by 5 seconds total and +3 milk per collection.",
		maxQuantity = 1,
		requiresPurchase = "milk_efficiency_1",
		icon = "🥛",
		effects = { 
			cooldownReduction = 3,
			milkYieldBonus = 2
		}
	},

	-- FIXED: Added missing milk_efficiency_3
	milk_efficiency_3 = {
		id = "milk_efficiency_3",
		name = "🥛 Enhanced Milking III",
		type = "upgrade",
		category = "farm",
		price = 500,
		currency = "coins",
		description = "Maximum milking efficiency! Reduce cooldown by 8 seconds total and +5 milk per collection.",
		maxQuantity = 1,
		requiresPurchase = "milk_efficiency_2",
		icon = "🥛",
		effects = { 
			cooldownReduction = 3,
			milkYieldBonus = 2
		}
	},

	milk_value_boost = {
		id = "milk_value_boost", 
		name = "💰 Premium Milk Quality",
		type = "upgrade",
		category = "farm",
		price = 300,
		currency = "coins",
		description = "Increase milk sell value by 5 coins per milk.",
		maxQuantity = 1,
		icon = "💰",
		effects = { 
			milkValueBonus = 5
		}
	},

	-- ========== MEGA UPGRADES (Fixed - These Were Missing!) ==========
	mega_milk_boost = {
		id = "mega_milk_boost",
		name = "🏆 MEGA Milk Boost",
		type = "megaUpgrade",
		category = "premium",
		price = 0, -- Obtained from pig transformation
		currency = "coins",
		description = "🌟 EXCLUSIVE PIG REWARD 🌟\nMilk collection gives +15 extra coins per milk!",
		icon = "🏆",
		maxQuantity = 1,
		isPigReward = true,
		effects = {
			milkBonusCoins = 15
		}
	},

	mega_growth_speed = {
		id = "mega_growth_speed",
		name = "🏆 MEGA Growth Speed",
		type = "megaUpgrade",
		category = "premium",
		price = 0,
		currency = "coins",
		description = "🌟 EXCLUSIVE PIG REWARD 🌟\nAll crops grow 50% faster!",
		icon = "🏆",
		maxQuantity = 1,
		isPigReward = true,
		effects = {
			cropGrowthMultiplier = 1.5
		}
	},

	mega_crop_multiplier = {
		id = "mega_crop_multiplier",
		name = "🏆 MEGA Crop Multiplier",
		type = "megaUpgrade",
		category = "premium",
		price = 0,
		currency = "coins",
		description = "🌟 EXCLUSIVE PIG REWARD 🌟\nHarvest yields are doubled!",
		icon = "🏆",
		maxQuantity = 1,
		isPigReward = true,
		effects = {
			harvestMultiplier = 2.0
		}
	},

	mega_efficiency = {
		id = "mega_efficiency",
		name = "🏆 MEGA Efficiency",
		type = "megaUpgrade",
		category = "premium",
		price = 0,
		currency = "coins",
		description = "🌟 EXCLUSIVE PIG REWARD 🌟\nMilk cooldown reduced by 25%!",
		icon = "🏆",
		maxQuantity = 1,
		isPigReward = true,
		effects = {
			cooldownReductionPercent = 0.25
		}
	},

	mega_golden_touch = {
		id = "mega_golden_touch",
		name = "🏆 MEGA Golden Touch",
		type = "megaUpgrade",
		category = "premium",
		price = 0,
		currency = "coins",
		description = "🌟 EXCLUSIVE PIG REWARD 🌟\n10% chance for golden crops with 5x value!",
		icon = "🏆",
		maxQuantity = 1,
		isPigReward = true,
		effects = {
			goldenCropChance = 0.10,
			goldenCropMultiplier = 5.0
		}
	},

	-- ========== MILK PRODUCTS ==========
	fresh_milk = {
		id = "fresh_milk",
		name = "🥛 Fresh Milk",
		type = "product",
		category = "livestock", 
		description = "Fresh milk from your cow. Nutritious and valuable!",
		sellValue = 15,
		sellCurrency = "coins",
		icon = "🥛",
		stackable = true,
		maxStack = 100,
		source = "cow_milking"
	},

	processed_milk = {
		id = "processed_milk",
		name = "🧈 Processed Milk",
		type = "product", 
		category = "livestock",
		description = "Processed milk products. Worth more than fresh milk!",
		sellValue = 25,
		sellCurrency = "coins",
		icon = "🧈",
		stackable = true,
		maxStack = 50,
		craftable = true,
		recipe = {fresh_milk = 2}
	},

	cheese = {
		id = "cheese",
		name = "🧀 Artisan Cheese", 
		type = "product",
		category = "livestock",
		description = "High-quality cheese made from fresh milk. Premium product!",
		sellValue = 50,
		sellCurrency = "coins", 
		icon = "🧀",
		stackable = true,
		maxStack = 25,
		craftable = true,
		recipe = {fresh_milk = 5}
	},

	-- ========== CROP PRODUCTS ==========
	carrot = {
		id = "carrot",
		name = "🥕 Carrot",
		type = "crop",
		category = "crops",
		description = "Fresh carrot. Sells for 5 Farm Tokens or feed to pig for 1 crop point.",
		sellValue = 5,
		sellCurrency = "farmTokens",
		feedValue = 1,
		cropPoints = 1,
		icon = "🥕",
		pestDamageMultiplier = 1.0
	},

	corn = {
		id = "corn",
		name = "🌽 Corn",
		type = "crop", 
		category = "crops",
		description = "Fresh corn. Sells for 12 Farm Tokens or feed to pig for 2 crop points.",
		sellValue = 12,
		sellCurrency = "farmTokens", 
		feedValue = 2,
		cropPoints = 2,
		icon = "🌽",
		pestDamageMultiplier = 1.0
	},

	strawberry = {
		id = "strawberry",
		name = "🍓 Strawberry",
		type = "crop", 
		category = "crops",
		description = "Sweet strawberry. Sells for 25 Farm Tokens or feed to pig for 3 crop points.",
		sellValue = 25,
		sellCurrency = "farmTokens", 
		feedValue = 3,
		cropPoints = 3,
		icon = "🍓",
		pestDamageMultiplier = 1.0
	},

	wheat = {
		id = "wheat",
		name = "🌾 Wheat",
		type = "crop",
		category = "crops",
		description = "Golden wheat grain. Essential for baking and crafting.",
		sellValue = 8,
		sellCurrency = "farmTokens",
		feedValue = 2,
		cropPoints = 2,
		icon = "🌾",
		craftingMaterial = true
	},

	potato = {
		id = "potato",
		name = "🥔 Potato",
		type = "crop",
		category = "crops", 
		description = "Hearty potato. Great for cooking and long-term storage.",
		sellValue = 10,
		sellCurrency = "farmTokens",
		feedValue = 2,
		cropPoints = 2,
		icon = "🥔",
		craftingMaterial = true
	},

	broccoli = {
		id = "broccoli",
		name = "🥦 Broccoli",
		type = "crop",
		category = "crops",
		description = "Nutritious green broccoli. High value and nutrition.",
		sellValue = 18,
		sellCurrency = "farmTokens",
		feedValue = 4,
		cropPoints = 4,
		icon = "🥦",
		craftingMaterial = true
	},

	tomato = {
		id = "tomato",
		name = "🍅 Tomato",
		type = "crop", 
		category = "crops",
		description = "Juicy ripe tomato. Perfect for cooking and high value sales.",
		sellValue = 25,
		sellCurrency = "farmTokens",
		feedValue = 5,
		cropPoints = 5,
		icon = "🍅",
		craftingMaterial = true
	},

	glorious_sunflower = {
		id = "glorious_sunflower",
		name = "🌻 Glorious Sunflower",
		type = "crop",
		category = "premium",
		description = "🏆 LEGENDARY PREMIUM CROP 🏆\nThe most valuable and beautiful crop in existence!",
		sellValue = 500,
		sellCurrency = "farmTokens",
		feedValue = 25,
		cropPoints = 25,
		icon = "🌻",
		isPremium = true,
		specialEffects = true
	},

	golden_fruit = {
		id = "golden_fruit",
		name = "✨ Golden Fruit",
		type = "crop", 
		category = "crops",
		description = "Magical golden fruit. Sells for 100 Farm Tokens or feed to pig for 10 crop points!",
		sellValue = 100,
		sellCurrency = "farmTokens", 
		feedValue = 10,
		cropPoints = 10,
		icon = "✨",
		pestDamageMultiplier = 0.5
	},

	-- ========== CHICKEN PRODUCTS ==========
	chicken_egg = {
		id = "chicken_egg",
		name = "🥚 Chicken Egg",
		type = "product",
		category = "livestock",
		description = "Fresh eggs from chickens. Can be sold for coins or used in recipes.",
		sellValue = 5,
		sellCurrency = "coins",
		icon = "🥚",
		stackable = true,
		maxStack = 50
	},

	guinea_egg = {
		id = "guinea_egg", 
		name = "🥚 Guinea Fowl Egg",
		type = "product",
		category = "livestock",
		description = "Premium eggs from guinea fowl. Higher value than regular eggs.",
		sellValue = 8,
		sellCurrency = "coins", 
		icon = "🥚",
		stackable = true,
		maxStack = 50
	},

	rooster_egg = {
		id = "rooster_egg",
		name = "🥚 Premium Rooster Egg", 
		type = "product",
		category = "livestock",
		description = "Rare premium eggs. Highly valuable and used in special recipes.",
		sellValue = 12,
		sellCurrency = "coins",
		icon = "🥚",
		stackable = true,
		maxStack = 25
	},

	-- ========== DAIRY BUILDINGS ==========
	dairy_processor = {
		id = "dairy_processor",
		name = "🏭 Dairy Processor",
		type = "building", 
		category = "farm",
		price = 1000,
		currency = "coins",
		description = "Process fresh milk into more valuable products!",
		icon = "🏭",
		maxQuantity = 1,
		requiresPurchase = "farm_plot_starter",
		buildingData = {
			size = Vector3.new(8, 6, 8),
			processingCapacity = 3
		}
	},

	cheese_maker = {
		id = "cheese_maker", 
		name = "🧀 Artisan Cheese Maker",
		type = "building",
		category = "farm", 
		price = 2500,
		currency = "coins",
		description = "Create premium cheese from fresh milk for high profits!",
		icon = "🧀",
		maxQuantity = 1,
		requiresPurchase = "dairy_processor",
		buildingData = {
			size = Vector3.new(6, 8, 6),
			processingCapacity = 1,
			specialtyProduct = "cheese"
		}
	}
}

-- ========== PROCESSING RECIPES ==========

ItemConfig.ProcessingRecipes = {
	processed_milk = {
		ingredients = {fresh_milk = 2},
		result = "processed_milk",
		quantity = 1,
		processingTime = 300,
		requiredBuilding = "dairy_processor"
	},

	cheese = {
		ingredients = {fresh_milk = 5},
		result = "cheese", 
		quantity = 1,
		processingTime = 1800,
		requiredBuilding = "cheese_maker"
	}
}

-- ========== CRAFTING SYSTEM ==========

ItemConfig.CraftingSystem = {
	stations = {
		workbench = {
			name = "Workbench",
			description = "Basic crafting station for tools and equipment",
			recipes = {"wooden_pickaxe", "stone_pickaxe", "farming_tools"}
		},

		forge = {
			name = "Forge", 
			description = "Advanced metalworking station for metal tools",
			recipes = {"iron_pickaxe", "diamond_pickaxe", "metal_tools"}
		},

		mystical_altar = {
			name = "Mystical Altar",
			description = "Legendary crafting station for the most powerful items",
			recipes = {"obsidian_pickaxe", "legendary_tools", "magical_items"}
		}
	},

	recipes = {
		wooden_pickaxe = {
			station = "workbench",
			ingredients = {
				{id = "wood", amount = 5},
				{id = "stone", amount = 2}
			},
			result = {id = "wooden_pickaxe", amount = 1},
			craftTime = 30,
			requiredLevel = 1
		},

		stone_pickaxe = {
			station = "workbench", 
			ingredients = {
				{id = "stone", amount = 8},
				{id = "wood", amount = 3}
			},
			result = {id = "stone_pickaxe", amount = 1},
			craftTime = 45,
			requiredLevel = 1
		},

		iron_pickaxe = {
			station = "forge",
			ingredients = {
				{id = "iron_ore", amount = 5},
				{id = "wood", amount = 2},
				{id = "coal", amount = 3}
			},
			result = {id = "iron_pickaxe", amount = 1},
			craftTime = 90,
			requiredLevel = 2
		},

		diamond_pickaxe = {
			station = "forge",
			ingredients = {
				{id = "diamond_ore", amount = 3},
				{id = "iron_ore", amount = 5},
				{id = "wood", amount = 2}
			},
			result = {id = "diamond_pickaxe", amount = 1},
			craftTime = 180,
			requiredLevel = 4
		},

		obsidian_pickaxe = {
			station = "mystical_altar",
			ingredients = {
				{id = "obsidian_ore", amount = 5},
				{id = "diamond_ore", amount = 3},
				{id = "magical_essence", amount = 1}
			},
			result = {id = "obsidian_pickaxe", amount = 1},
			craftTime = 300,
			requiredLevel = 6
		}
	}
}

-- ========== UTILITY FUNCTIONS ==========

function ItemConfig.GetPestData(pestType)
	return ItemConfig.PestSystem.pestData[pestType]
end

function ItemConfig.GetChickenData(chickenType)
	return ItemConfig.ChickenSystem.chickenTypes[chickenType]
end

function ItemConfig.CalculatePestDamage(cropId, pestDamageLevel)
	local crop = ItemConfig.ShopItems[cropId]
	if not crop then return 0 end

	local baseSellValue = crop.sellValue or 0
	local damageMultiplier = crop.pestDamageMultiplier or 1.0

	local damageReduction = pestDamageLevel * damageMultiplier
	local finalValue = baseSellValue * (1 - damageReduction)

	return math.max(0, math.floor(finalValue))
end

function ItemConfig.CanChickenTargetPest(chickenType, pestType)
	local chickenData = ItemConfig.ChickenSystem.chickenTypes[chickenType]
	if not chickenData then return false end

	for _, targetPest in ipairs(chickenData.pestTargets) do
		if targetPest == pestType then
			return true
		end
	end
	return false
end

function ItemConfig.GetSeedData(seedId)
	local seed = ItemConfig.ShopItems[seedId]
	if seed and seed.type == "seed" and seed.farmingData then
		return seed.farmingData
	end
	return nil
end

function ItemConfig.GetCropData(cropId)
	local crop = ItemConfig.ShopItems[cropId]
	if crop and crop.type == "crop" then
		return crop
	end
	return nil
end

function ItemConfig.GetMilkCooldown(playerUpgrades)
	local baseCooldown = ItemConfig.CowSystem.baseCooldown
	local reduction = 0

	-- Apply regular upgrades
	if playerUpgrades.milk_efficiency_1 then
		reduction = reduction + 2
	end
	if playerUpgrades.milk_efficiency_2 then
		reduction = reduction + 3
	end
	if playerUpgrades.milk_efficiency_3 then
		reduction = reduction + 3
	end

	-- Apply mega efficiency upgrade
	if playerUpgrades.mega_efficiency then
		local remaining = baseCooldown - reduction
		reduction = reduction + (remaining * 0.25)
	end

	return math.max(1, baseCooldown - reduction)
end

function ItemConfig.GetMilkSellValue(playerUpgrades)
	local baseValue = 15
	local bonus = 0

	if playerUpgrades and playerUpgrades.milk_value_boost then
		bonus = bonus + 5
	end

	if playerUpgrades and playerUpgrades.mega_milk_boost then
		bonus = bonus + 15
	end

	return baseValue + bonus
end

function ItemConfig.CanPlayerBuy(itemId, playerData)
	local item = ItemConfig.ShopItems[itemId]
	if not item then
		return false, "Item not found"
	end

	if not playerData then
		return false, "No player data"
	end

	local playerCurrency = playerData[item.currency] or 0
	if playerCurrency < item.price then
		return false, "Insufficient " .. item.currency
	end

	if item.maxQuantity and item.maxQuantity == 1 then
		if playerData.purchaseHistory and playerData.purchaseHistory[itemId] then
			return false, "Already purchased"
		end
	end

	if item.requiresPurchase then
		if not playerData.purchaseHistory or not playerData.purchaseHistory[item.requiresPurchase] then
			local reqItem = ItemConfig.ShopItems[item.requiresPurchase]
			local reqName = reqItem and reqItem.name or item.requiresPurchase
			return false, "Requires: " .. reqName
		end
	end

	if item.requiresFarmPlot then
		if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
			return false, "Requires farm plot"
		end
	end

	return true, "Can purchase"
end

function ItemConfig.GetRandomMegaDrop()
	local megaDrops = {
		{
			id = "mega_milk_boost",
			name = "MEGA Milk Boost",
			description = "Milk collection gives +15 extra coins!"
		},
		{
			id = "mega_growth_speed",
			name = "MEGA Growth Speed",
			description = "All crops grow 50% faster!"
		},
		{
			id = "mega_crop_multiplier",
			name = "MEGA Crop Multiplier", 
			description = "Harvest yields are doubled!"
		},
		{
			id = "mega_efficiency",
			name = "MEGA Efficiency",
			description = "Milk cooldown reduced by 25%!"
		},
		{
			id = "mega_golden_touch",
			name = "MEGA Golden Touch",
			description = "10% chance for golden crops!"
		}
	}

	return megaDrops[math.random(1, #megaDrops)]
end

function ItemConfig.GetCropPointsForMegaPig(transformationCount)
	return 100 + (transformationCount * 50)
end

function ItemConfig.GetItem(itemId)
	return ItemConfig.ShopItems[itemId]
end

function ItemConfig.GetItemsByCategory(category)
	local items = {}
	for itemId, item in pairs(ItemConfig.ShopItems) do
		if item.category == category then
			items[itemId] = item
		end
	end
	return items
end

function ItemConfig.ValidateItem(itemId)
	local item = ItemConfig.ShopItems[itemId]
	if not item then return false, "Item not found" end

	local required = {"name", "price", "currency", "category"}
	for _, prop in ipairs(required) do
		if not item[prop] then
			return false, "Missing property: " .. prop
		end
	end

	return true, "Valid item"
end

print("✅ Complete ItemConfig loaded!")
print("📦 Total shop items: " .. (function() local count = 0; for _ in pairs(ItemConfig.ShopItems) do count = count + 1 end return count end)())
print("🔧 Added missing items:")
print("  ⛏️ Complete mining tool chain (7 pickaxes)")
print("  🗻 Cave unlock items (5 caves)")
print("  🥛 Complete milk efficiency upgrades (3 levels)")
print("  🏆 All mega upgrades from pig system")
print("  🟤 Fixed mining ores (added bronze, platinum)")
print("  ✨ All referenced items from GameCore")

return ItemConfig