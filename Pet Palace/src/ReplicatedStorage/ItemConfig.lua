--[[
    UPDATED ItemConfig.lua - Adjusted Progression System
    Place in: ReplicatedStorage/ItemConfig.lua
    
    PROGRESSION CHANGES:
    ✅ Garden (farm_plot_starter): 100 coins (unchanged)
    ✅ Added wheat field access: 10,000 coins
    ✅ Cave access: 250,000 coins (increased from 50,000)
    ✅ Wheat seeds and scythe now require wheat field access
]]

local ItemConfig = {}

-- ========== RARITY SYSTEM ==========
ItemConfig.RaritySystem = {
	common    = { name = "Common",    color = Color3.fromRGB(255,255,255), sizeMultiplier = 1.0, valueMultiplier = 1.0, dropChance = 0.5, effects = {}, tier = 1 },
	uncommon  = { name = "Uncommon",  color = Color3.fromRGB(0,255,0),   sizeMultiplier = 1.1, valueMultiplier = 1.2, dropChance = 0.25, effects = {"sparkle"}, tier = 2 },
	rare      = { name = "Rare",      color = Color3.fromRGB(255,215,0), sizeMultiplier = 1.2, valueMultiplier = 1.5, dropChance = 0.07, effects = {"golden_shine"}, tier = 3 },
	epic      = { name = "Epic",      color = Color3.fromRGB(128,0,128), sizeMultiplier = 1.8, valueMultiplier = 2.0, dropChance = 0.025, effects = {"purple_aura"}, tier = 4 },
	legendary = { name = "Legendary", color = Color3.fromRGB(255,100,100), sizeMultiplier = 2.0, valueMultiplier = 3.0, dropChance = 0.005, effects = {"legendary_glow"}, tier = 5 },
}

-- ========== MINING SYSTEM DATA ==========
ItemConfig.MiningSystem = {}

-- Mining Ores
ItemConfig.MiningSystem.ores = {
	copper_ore = {
		id = "copper_ore",
		name = "Copper Ore",
		description = "Basic copper ore found in shallow caves.",
		color = Color3.fromRGB(184, 115, 51),
		hardness = 3,
		sellValue = 25,
		sellCurrency = "coins",
		xpReward = 15,
		respawnTime = 60, -- 1 minute
		requiredLevel = 1,
		rarity = "common",
		icon = "🟤"
	},

	bronze_ore = {
		id = "bronze_ore", 
		name = "Bronze Ore",
		description = "Stronger bronze ore with metallic properties.",
		color = Color3.fromRGB(139, 90, 43),
		hardness = 4,
		sellValue = 40,
		sellCurrency = "coins",
		xpReward = 25,
		respawnTime = 90, -- 1.5 minutes
		requiredLevel = 2,
		rarity = "common",
		icon = "🟫"
	},

	silver_ore = {
		id = "silver_ore",
		name = "Silver Ore", 
		description = "Precious silver ore with high value.",
		color = Color3.fromRGB(192, 192, 192),
		hardness = 6,
		sellValue = 75,
		sellCurrency = "coins",
		xpReward = 40,
		respawnTime = 120, -- 2 minutes
		requiredLevel = 3,
		rarity = "uncommon",
		icon = "⚪"
	},

	gold_ore = {
		id = "gold_ore",
		name = "Gold Ore",
		description = "Valuable gold ore found in deep caverns.",
		color = Color3.fromRGB(255, 215, 0),
		hardness = 8,
		sellValue = 150,
		sellCurrency = "coins", 
		xpReward = 60,
		respawnTime = 180, -- 3 minutes
		requiredLevel = 5,
		rarity = "rare",
		icon = "🟡"
	},

	platinum_ore = {
		id = "platinum_ore",
		name = "Platinum Ore",
		description = "Extremely rare platinum ore with exceptional value.",
		color = Color3.fromRGB(132, 135, 137),
		hardness = 12,
		sellValue = 300,
		sellCurrency = "coins",
		xpReward = 100,
		respawnTime = 300, -- 5 minutes
		requiredLevel = 7,
		rarity = "epic",
		icon = "⚫"
	},

	obsidian_ore = {
		id = "obsidian_ore",
		name = "Obsidian Ore",
		description = "Mystical obsidian ore from the deepest caves.",
		color = Color3.fromRGB(28, 28, 28),
		hardness = 15,
		sellValue = 100,
		sellCurrency = "farmTokens",
		xpReward = 150,
		respawnTime = 450, -- 7.5 minutes
		requiredLevel = 10,
		rarity = "legendary",
		icon = "⬛"
	}
}

-- Mining Tools
ItemConfig.MiningSystem.tools = {
	wooden_pickaxe = {
		id = "wooden_pickaxe",
		name = "Wooden Pickaxe",
		description = "Basic wooden pickaxe for beginners.",
		speed = 1.0,
		durability = 50,
		canMine = {"copper_ore"},
		requiredLevel = 1,
		icon = "🪓"
	},

	basic_pickaxe = {
		id = "basic_pickaxe", 
		name = "Basic Pickaxe",
		description = "Essential tool for mining copper and bronze.",
		speed = 1.2,
		durability = 100,
		canMine = {"copper_ore", "bronze_ore"},
		requiredLevel = 1,
		icon = "⛏️"
	},

	stone_pickaxe = {
		id = "stone_pickaxe",
		name = "Stone Pickaxe", 
		description = "Improved pickaxe for mining harder ores.",
		speed = 1.5,
		durability = 150,
		canMine = {"copper_ore", "bronze_ore", "silver_ore"},
		requiredLevel = 2,
		icon = "🪨"
	},

	iron_pickaxe = {
		id = "iron_pickaxe",
		name = "Iron Pickaxe",
		description = "Professional grade pickaxe for serious miners.",
		speed = 2.0,
		durability = 250,
		canMine = {"copper_ore", "bronze_ore", "silver_ore", "gold_ore"},
		requiredLevel = 4,
		icon = "⚒️"
	},

	diamond_pickaxe = {
		id = "diamond_pickaxe",
		name = "Diamond Pickaxe",
		description = "Premium pickaxe for the most valuable ores.",
		speed = 3.0,
		durability = 500,
		canMine = {"copper_ore", "bronze_ore", "silver_ore", "gold_ore", "platinum_ore"},
		requiredLevel = 6,
		icon = "💎"
	},

	obsidian_pickaxe = {
		id = "obsidian_pickaxe",
		name = "Obsidian Pickaxe",
		description = "Legendary pickaxe capable of mining anything.",
		speed = 4.0,
		durability = 1000,
		canMine = {"copper_ore", "bronze_ore", "silver_ore", "gold_ore", "platinum_ore", "obsidian_ore"},
		requiredLevel = 8,
		icon = "⬛"
	}
}

-- ========== CROP DATA ==========
ItemConfig.Crops = {
	carrot = { 
		id = "carrot", name = "🥕 Carrot", type = "crop", category = "crops", 
		description = "Fresh orange carrot.", sellValue = 10, sellCurrency = "coins", 
		icon = "🥕", rarity = "common" 
	},
	potato = { 
		id = "potato", name = "🥔 Potato", type = "crop", category = "crops", 
		description = "Hearty potato.", sellValue = 15, sellCurrency = "coins", 
		icon = "🥔", rarity = "common" 
	},
	cabbage = { 
		id = "cabbage", name = "🥬 Cabbage", type = "crop", category = "crops", 
		description = "Fresh leafy cabbage.", sellValue = 20, sellCurrency = "coins", 
		icon = "🥬", rarity = "common" 
	},
	radish = { 
		id = "radish", name = "🌶️ Radish", type = "crop", category = "crops", 
		description = "Spicy radish.", sellValue = 25, sellCurrency = "coins", 
		icon = "🌶️", rarity = "common" 
	},

	broccoli = { 
		id = "broccoli", name = "🥦 Broccoli", type = "crop", category = "crops", 
		description = "Nutritious green broccoli.", sellValue = 30, sellCurrency = "coins", 
		icon = "🥦", rarity = "common" 
	},
	tomato = { 
		id = "tomato", name = "🍅 Tomato", type = "crop", category = "crops", 
		description = "Juicy red tomato.", sellValue = 35, sellCurrency = "coins", 
		icon = "🍅", rarity = "uncommon" 
	},
	strawberry = { 
		id = "strawberry", name = "🍓 Strawberry", type = "crop", category = "crops", 
		description = "Sweet red strawberry.", sellValue = 40, sellCurrency = "coins", 
		icon = "🍓", rarity = "uncommon" 
	},
	wheat = { 
		id = "wheat", name = "🌾 Wheat", type = "crop", category = "crops", 
		description = "Golden wheat grain.", sellValue = 5, sellCurrency = "coins", 
		icon = "🌾", rarity = "uncommon" 
	},
	corn = { 
		id = "corn", name = "🌽 Corn", type = "crop", category = "crops", 
		description = "Sweet yellow corn.", sellValue = 60, sellCurrency = "coins", 
		icon = "🌽", rarity = "uncommon" 
	},
	golden_fruit = { 
		id = "golden_fruit", name = "✨ Golden Fruit", type = "crop", category = "crops", 
		description = "Magical golden fruit.", sellValue = 400, sellCurrency = "coins", 
		icon = "✨", rarity = "legendary" 
	},
	glorious_sunflower = { 
		id = "glorious_sunflower", name = "🌻 Glorious Sunflower", type = "crop", category = "crops", 
		description = "🏆 LEGENDARY PREMIUM CROP 🏆", sellValue = 0, sellCurrency = "farmTokens", 
		icon = "🌻", rarity = "divine" 
	},
	broccarrot = {
		name = "Broccarrot",
		description = "A mysterious hybrid of broccoli and carrot with unique properties",
		sellPrice = 150, -- Higher value than parent crops
		rarity = "rare",
		harvestTime = 0, -- No growing time (only obtained through mutation)
		category = "mutation",
		parentCrops = {"broccoli", "carrot"},
		mutationTier = 1,
		emoji = "🥦🥕",
		specialProperties = {
			"hybrid_vigor", -- 25% chance for double harvest
			"nutrient_rich", -- Gives bonus nutrition when consumed
			"genetic_stability" -- Can be used as ingredient for advanced mutations
		}
	},
	broctato = {
		name = "Broctato",
		description = "A rare blend of broccoli and potato with earthy complexity",
		sellPrice = 200, -- Epic tier pricing
		rarity = "epic",
		harvestTime = 0,
		category = "mutation",
		parentCrops = {"broccoli", "potato"},
		mutationTier = 1,
		emoji = "🥦🥔",
		specialProperties = {
			"earth_energy", -- Improves soil quality of adjacent plots
			"storage_mastery", -- Never spoils in inventory
			"mutation_catalyst", -- Increases mutation chances when present
			"epic_growth" -- Can trigger rare mutation chains
		}
	},

	craddish = {
		name = "Craddish",
		description = "A spicy cross between carrot and radish with fiery kick",
		sellPrice = 250, -- Uncommon tier pricing
		rarity = "uncommon",
		harvestTime = 0,
		category = "mutation",
		parentCrops = {"carrot", "radish"},
		mutationTier = 1,
		emoji = "🥕🌶️",
		specialProperties = {
			"spicy_kick", -- Adds heat resistance to animals
			"quick_growth", -- Accelerates nearby crop growth
			"pest_deterrent", -- Natural pest resistance
			"common_starter" -- Easiest mutation to achieve
		}				
	},		

	brocmato = {
		name = "Brocmato",
		description = "An unusual fusion of broccoli and tomato with vibrant flavors",
		sellPrice = 300,
		rarity = "rare", 
		harvestTime = 0,
		category = "mutation",
		parentCrops = {"broccoli", "tomato"},
		mutationTier = 2,
		emoji = "🥦🍅",
		specialProperties = {
			"flavor_burst", -- Enhanced taste profile
			"antioxidant_boost", -- Extra health benefits
			"color_changing" -- Changes appearance based on conditions
		}
	},	

	cornmato = {
		name = "Cornmato",
		description = "A golden hybrid of corn and tomato with explosive flavor",
		sellPrice = 350, -- Epic tier pricing
		rarity = "epic",
		harvestTime = 0,
		category = "mutation",
		parentCrops = {"corn", "tomato"},
		mutationTier = 2,
		emoji = "🌽🍅",
		specialProperties = {
			"golden_essence", -- Increases coin rewards from other crops
			"flavor_explosion", -- Creates temporary taste enhancement field
			"solar_power", -- Grows faster in sunlight
			"premium_genetics" -- Unlocks advanced farming techniques
		}
	}
}
-- ========== UPDATED SHOP ITEMS WITH PROGRESSION SYSTEM ==========
ItemConfig.ShopItems = {

	-- ========== SEEDS CATEGORY (Beginner to Advanced) ==========

	carrot_seeds = {
		id = "carrot_seeds",
		name = "🥕 Carrot Seeds",
		description = "Perfect starter crop! Fast-growing and profitable.\n\n⏱️ Grow Time: 3 seconds\n💰 Sell Value: 10 coins each\n\n🎯 BEGINNER FRIENDLY - Start here!",
		price = 5,
		currency = "coins",
		category = "seeds",
		icon = "🥕",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 1, -- FIRST seed - perfect for beginners
		farmingData = {
			growTime = 3,
			yieldAmount = 1,
			resultCropId = "carrot",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	potato_seeds = {
		id = "potato_seeds",
		name = "🥔 Potato Seeds",
		description = "Another great starter crop! Quick growth with good value.\n\n⏱️ Grow Time: 5 seconds\n💰 Sell Value: 15 coins each\n\n🌱 Perfect second crop to try!",
		price = 10,
		currency = "coins",
		category = "seeds",
		icon = "🥔",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 2, -- Second seed option
		farmingData = {
			growTime = 5, 
			yieldAmount = 1,
			resultCropId = "potato",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	cabbage_seeds = {
		id = "cabbage_seeds",
		name = "🥬 Cabbage Seeds",
		description = "Step up your farming! Nutritious leafy greens.\n\n⏱️ Grow Time: 8 seconds\n💰 Sell Value: 20 coins each\n\n🥬 Great for learning crop timing!",
		price = 15,
		currency = "coins",
		category = "seeds",
		icon = "🥬",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 3, -- Third progression step
		farmingData = {
			growTime = 8,
			yieldAmount = 1,
			resultCropId = "cabbage",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	radish_seeds = {
		id = "radish_seeds",
		name = "🌶️ Radish Seeds",
		description = "Mid-tier crop with spicy flavor and good profits!\n\n⏱️ Grow Time: 10 seconds\n💰 Sell Value: 25 coins each\n\n🌶️ Ready for intermediate farming!",
		price = 20,
		currency = "coins",
		category = "seeds",
		icon = "🌶️",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 4, -- Mid-tier option
		farmingData = {
			growTime = 10,
			yieldAmount = 1,
			resultCropId = "radish",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},
	broccoli_seeds = {
		id = "broccoli_seeds",
		name = "🥦 Broccoli Seeds",
		description = "Nutritious green superfood! Takes patience but worth it.\n\n⏱️ Grow Time: 15 seconds\n💰 Sell Value: 30 coins each\n\n🥦",
		price = 25,
		currency = "coins",
		category = "seeds",
		icon = "🥦",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 5, -- Advanced farming
		farmingData = {
			growTime = 15,
			yieldAmount = 1,
			resultCropId = "broccoli",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},
	tomato_seeds = {
		id = "tomato_seeds",
		name = "🍅 Tomato Seeds",
		description = "Juicy cluster-growing tomatoes! Perfect for cooking.\n\n⏱️ Grow Time: 20 seconds\n💰 Sell Value: 35 coins each\n\n🍅 Multiple yield specialty crop!",
		price = 30,
		currency = "coins",
		category = "seeds",
		icon = "🍅",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 6, -- Advanced specialty crop
		farmingData = {
			growTime = 20,
			yieldAmount = 1,
			resultCropId = "tomato",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "🍓 Strawberry Seeds",
		description = "Premium berries with excellent value! Worth the investment.\n\n⏱️ Grow Time: 25 seconds\n💰 Sell Value: 40 coins each\n\n🍓 High-value crop for experienced farmers!",
		price = 35,
		currency = "coins",
		category = "seeds",
		icon = "🍓",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 7, -- Higher value option
		farmingData = {
			growTime = 25,
			yieldAmount = 1,
			resultCropId = "strawberry",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	-- UPDATED: Wheat seeds now require wheat field access
	wheat_seeds = {
		id = "wheat_seeds",
		name = "🌾 Wheat Seeds",
		description = "Essential grain crop for advanced farming operations.\n\n⏱️ Grow Time: 30 seconds\n💰 Sell Value: 45 coins each\n\n🌾 Multiple yield crop - great efficiency!\n\n⚠️ Requires Wheat Field Access",
		price = 40,
		currency = "coins",
		category = "seeds",
		icon = "🌾",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 8, -- Advanced farming
		requiresPurchase = "wheat_field_access", -- NEW: Requires wheat field
		farmingData = {
			growTime = 30,
			yieldAmount = 1,
			resultCropId = "wheat",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	corn_seeds = {
		id = "corn_seeds",
		name = "🌽 Corn Seeds",
		description = "High-value tall crop! Sweet corn that animals love.\n\n⏱️ Grow Time: 35 seconds\n💰 Sell Value: 60 coins each\n\n🌽 Premium regular crop with excellent returns!",
		price = 50,
		currency = "coins",
		category = "seeds",
		icon = "🌽",
		maxQuantity = 99,
		type = "seed",
		purchaseOrder = 9, -- Premium regular crop
		farmingData = {
			growTime = 35,
			yieldAmount = 1,
			resultCropId = "corn",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "✨ Golden Seeds",
		description = "🏆 PREMIUM FARM TOKEN CROP 🏆\nMagical seeds that produce golden fruit!\n\n⏱️ Grow Time: 60 seconds\n💰 Value: SPECIAL\n\n✨ Premium investment for serious farmers!",
		price = 250,
		currency = "farmTokens",
		category = "seeds",
		icon = "✨",
		maxQuantity = 25,
		type = "seed",
		purchaseOrder = 10, -- Premium farm token crop
		farmingData = {
			growTime = 60,
			yieldAmount = 1,
			resultCropId = "golden_fruit",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	glorious_sunflower_seeds = {
		id = "glorious_sunflower_seeds",
		name = "🌻 Glorious Sunflower Seeds",
		description = "🏆 ULTIMATE LEGENDARY SEED 🏆\nThe rarest and most magnificent crop! Massive size!\n\n⏱️ Grow Time: 8+ minutes\n💰 Value: PRICELESS\n\n🌻 THE ULTIMATE FARMING ACHIEVEMENT!",
		price = 999,
		currency = "farmTokens",
		category = "seeds",
		icon = "🌻",
		maxQuantity = 10,
		type = "seed",
		purchaseOrder = 11, -- Ultimate seed
		farmingData = {
			growTime = 3000,
			yieldAmount = 1,
			resultCropId = "glorious_sunflower",
			stages = {"planted", "sprouting", "growing", "flowering", "glorious"},
			rarityChances = {common = 0.0, uncommon = 0.9, rare = 0.08, epic = 0.01999, legendary = 0.00001},
			alwaysHighRarity = true
		}
	},

	-- Mutation crops (not purchasable)
	broccarrot = {
		id = "broccarrot",
		name = "🧬 Broccarrot",
		description = "A rare mutation crop - cannot be purchased, only created through genetic fusion",
		price = 999999, -- Extremely high price to discourage purchase
		currency = "farmTokens",
		category = "mutation",
		icon = "🥦🥕",
		purchasable = false, -- Cannot be bought
		sellable = true,
		sellPrice = 150,
		rarity = "uncommon"
	},

	broctato = {
		id = "broctato",
		name = "🧬 Broctato", 
		description = "An epic mutation crop - cannot be purchased, only created through genetic fusion",
		price = 999999,
		currency = "farmTokens",
		category = "mutation",
		icon = "🥦🥔",
		purchasable = false,
		sellable = true,
		sellPrice = 200,
		rarity = "uncommon"
	},
	craddish = {
		id = "craddish",
		name = "🧬 Craddish",
		description = "An uncommon mutation crop - cannot be purchased, only created through genetic fusion",
		price = 999999,
		currency = "farmTokens", 
		category = "mutation",
		icon = "🥕🌶️",
		purchasable = false,
		sellable = true,
		sellPrice = 250,
		rarity = "uncommon"
	},
	brocmato = {
		id = "brocmato", 
		name = "🧬 Brocmato",
		description = "A rare mutation crop - cannot be purchased, only created through genetic fusion",
		price = 999999,
		currency = "farmTokens",
		category = "mutation", 
		icon = "🥦🍅",
		purchasable = false,
		sellable = true,
		sellPrice = 250,
		rarity = "rare"
	},

	cornmato = {
		id = "cornmato",
		name = "🧬 Cornmato",
		description = "An epic mutation crop - cannot be purchased, only created through genetic fusion", 
		price = 999999,
		currency = "farmTokens",
		category = "mutation",
		icon = "🌽🍅",
		purchasable = false,
		sellable = true,
		sellPrice = 300,
		rarity = "epic"
	},


	-- ========== FARM CATEGORY (Core Infrastructure) ==========

	-- UNCHANGED: Garden remains at 100 coins
	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "🌾 Your Garden Plot",
		description = "🎯 ESSENTIAL PURCHASE! Start your farming journey!\n\n🎁 Get a complete 10x10 farming grid:\n• 100 planting spots (all unlocked!)\n• FREE starter package:\n  - 5x Carrot Seeds\n  - 3x Potato Seeds\n• Access to entire farming system\n\n🌾 This unlocks everything - buy this first!\n\n💰 Only 100 coins!",
		price = 100, -- PROGRESSION: 100 coins (unchanged)
		currency = "coins",
		category = "farm",
		icon = "🌾",
		maxQuantity = 1,
		type = "farmPlot",
		purchaseOrder = 1, -- FIRST farm purchase
		effects = {
			enableFarming = true,
			starterSeeds = {
				carrot_seeds = 5,
				potato_seeds = 3
			}
		}
	},

	-- NEW: Wheat Field Access at 10,000 coins
	wheat_field_access = {
		id = "wheat_field_access",
		name = "🌾 Wheat Field Access",
		description = "🏆 UNLOCK ADVANCED FARMING! 🏆\nGain access to the wheat field and advanced farming techniques!\n\n🌾 Wheat Field Benefits:\n• Unlock wheat seeds for planting\n• Access to scythe tool for harvesting\n• Higher profit margins with wheat crops\n• Large-scale farming operations\n• Bulk harvesting capabilities\n\n💰 Major farming expansion!\n\n⚠️ Requires significant investment: 10,000 coins",
		price = 10000, -- PROGRESSION: 10,000 coins
		currency = "coins",
		category = "farm",
		icon = "🌾",
		maxQuantity = 1,
		type = "access",
		purchaseOrder = 2, -- Second major progression step
		effects = {
			enableWheatFarming = true,
			unlockWheatSeeds = true,
			unlockScythe = true
		}
	},

	-- UPDATED: Scythe now requires wheat field access
	scythe_tool = {
		id = "scythe_tool",
		name = "🔪 Scythe",
		description = "🌾 WHEAT CUTTING TOOL 🌾\nPowerful tool for harvesting wheat efficiently!\n\n⚡ Features:\n• Cut wheat in large areas\n• Durable construction\n• Fast harvesting\n• Professional grade\n\n🔪 Essential for wheat farming!\n\n⚠️ Requires Wheat Field Access",
		price = 500,
		currency = "coins",
		category = "farm",
		icon = "🔪",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 15, -- Advanced farming tool
		requiresPurchase = "wheat_field_access", -- NEW: Requires wheat field
		toolData = {
			durability = 100,
			toolType = "scythe",
			cuttingRadius = 8,
			efficiency = 1.5
		}
	},

	milk_efficiency_1 = {
		id = "milk_efficiency_1",
		name = "🥛 Enhanced Milking I",
		description = "Improve your milking efficiency and output!\n\n🐄 Benefits:\n• Reduced cooldown\n• Enhanced milk production\n• Better cow happiness\n• Tier 1 upgrade\n\n🥛 Work smarter, not harder!",
		price = 100,
		currency = "coins",
		category = "farm",
		icon = "🥛",
		maxQuantity = 1,
		type = "upgrade",
		purchaseOrder = 4 -- First efficiency upgrade
	},

	milk_efficiency_2 = {
		id = "milk_efficiency_2",
		name = "🥛 Enhanced Milking II",
		description = "Further improve your milking operation!\n\n🐄 Enhanced Benefits:\n• Even better cooldown\n• More milk per collection\n• Premium cow care techniques\n• Tier 2 upgrade\n\n🥛 Professional dairy management!",
		price = 250,
		currency = "coins",
		category = "farm",
		icon = "🥛",
		maxQuantity = 1,
		type = "upgrade",
		purchaseOrder = 5 -- Second efficiency upgrade
	},

	milk_efficiency_3 = {
		id = "milk_efficiency_3",
		name = "🥛 Enhanced Milking III",
		description = "Maximum milking efficiency achieved!\n\n🐄 Maximum Benefits:\n• Best cooldown reduction\n• Maximum milk per collection\n• Expert cow management\n• Tier 3 upgrade\n\n🥛 Peak performance achieved!",
		price = 500,
		currency = "coins",
		category = "farm",
		icon = "🥛",
		maxQuantity = 1,
		type = "upgrade",
		purchaseOrder = 6 -- Final efficiency upgrade
	},

	milk_value_boost = {
		id = "milk_value_boost",
		name = "💰 Premium Milk Quality",
		description = "Increase the quality and market value of your milk!\n\n💰 Value Enhancement:\n• Better sell price per milk\n• Premium quality certification\n• Better market reputation\n• Permanent upgrade\n\n💰 Quality pays!",
		price = 300,
		currency = "coins",
		category = "farm",
		icon = "💰",
		maxQuantity = 1,
		type = "upgrade",
		purchaseOrder = 7 -- Value enhancement
	},

	silver_cow_upgrade = {
		id = "silver_cow_upgrade",
		name = "🥈 Silver Cow Upgrade",
		description = "Upgrade a basic cow to Silver tier!\n\n🥛 Silver Tier Benefits:\n• Better milk production\n• Beautiful metallic shine\n• Improved efficiency\n• Upgrades one existing cow\n\n🥈 First tier advancement!",
		price = 10000,
		currency = "coins",
		category = "farm",
		icon = "🥈",
		maxQuantity = 1,
		type = "cow_upgrade",
		purchaseOrder = 8, -- First upgrade tier
		cowData = {
			tier = "silver",
			milkAmount = 2,
			cooldown = 30,
			visualEffects = {"metallic_shine", "silver_particles"},
			upgradeFrom = "basic"
		}
	},

	gold_cow_upgrade = {
		id = "gold_cow_upgrade",
		name = "🥇 Gold Cow Upgrade",
		description = "Upgrade a silver cow to Gold tier!\n\n🥛 Gold Tier Benefits:\n• Excellent milk production\n• Brilliant golden glow effect\n• Premium tier efficiency\n• Prestigious appearance\n\n🥇 Elite cow status!",
		price = 25000,
		currency = "coins",
		category = "farm",
		icon = "🥇",
		maxQuantity = 1,
		type = "cow_upgrade",
		purchaseOrder = 9, -- Second upgrade tier
		cowData = {
			tier = "gold",
			milkAmount = 3,
			cooldown = 60,
			visualEffects = {"golden_glow", "gold_sparkles", "light_aura"},
			upgradeFrom = "silver"
		}
	},

	diamond_cow_upgrade = {
		id = "diamond_cow_upgrade", 
		name = "💎 Diamond Cow Upgrade",
		description = "Upgrade a gold cow to Diamond tier!\n\n🥛 Diamond Tier Benefits:\n• Superior milk production\n• Crystalline beauty with rainbow effects\n• Exceptional production efficiency\n• Absolutely stunning appearance\n\n💎 Luxury farming at its finest!",
		price = 500000,
		currency = "coins",
		category = "farm",
		icon = "💎",
		maxQuantity = 1,
		type = "cow_upgrade",
		purchaseOrder = 10, -- Third upgrade tier
		cowData = {
			tier = "diamond",
			milkAmount = 5,
			cooldown = 60,
			visualEffects = {"diamond_crystals", "rainbow_sparkles", "prismatic_aura"},
			upgradeFrom = "gold"
		}
	},

	rainbow_cow_upgrade = {
		id = "rainbow_cow_upgrade",
		name = "🌈 Rainbow Cow Upgrade", 
		description = "🏆 PREMIUM FARM TOKEN UPGRADE 🏆\nTransform a diamond cow into magical Rainbow tier!\n\n🥛 Rainbow Tier Benefits:\n• Amazing milk production\n• Shifting rainbow colors\n• Magical aura effects\n• Premium tier status\n\n🌈 Magic meets dairy farming!",
		price = 100,
		currency = "farmTokens",
		category = "farm",
		icon = "🌈",
		maxQuantity = 1,
		type = "cow_upgrade",
		purchaseOrder = 11, -- Premium upgrade
		cowData = {
			tier = "rainbow",
			milkAmount = 10,
			cooldown = 120,
			visualEffects = {"rainbow_cycle", "magical_aura", "color_trails", "star_particles"},
			upgradeFrom = "diamond"
		}
	},

	cosmic_cow_upgrade = {
		id = "cosmic_cow_upgrade",
		name = "🌌 Cosmic Cow Upgrade",
		description = "🏆 ULTIMATE PREMIUM UPGRADE 🏆\nThe pinnacle of cow evolution!\n\n🥛 Cosmic Tier Benefits:\n• Maximum milk production\n• Galaxy effects and cosmic energy\n• Ultimate production efficiency\n• Legendary status\n\n🌌 Transcend normal farming!",
		price = 750,
		currency = "farmTokens",
		category = "farm",
		icon = "🌌",
		maxQuantity = 1,
		type = "cow_upgrade",
		purchaseOrder = 12, -- Ultimate upgrade
		cowData = {
			tier = "cosmic",
			milkAmount = 25,
			cooldown = 5,
			visualEffects = {"galaxy_swirl", "cosmic_energy", "star_field", "nebula_clouds", "space_distortion"},
			upgradeFrom = "rainbow"
		}
	},

	-- ========== MINING CATEGORY ==========

	-- UPDATED: Cave access price increased to 250,000 coins
	cave_access_pass = {
		id = "cave_access_pass",
		name = "🕳️ Cave Access Pass",
		description = "🏆 UNLOCK MINING EMPIRE! 🏆\nGrants access to Cave 1 (Copper Mine) and the entire mining system!\n\n🗻 Mining Access Includes:\n• Cave 1: Copper Mine\n• Copper and bronze ore deposits\n• Mining tutorial area\n• New major income source\n• Path to advanced mining tools\n\n🕳️ Diversify your empire with mining!\n\n💰 Major investment required: 250,000 coins\n⚠️ This is a significant milestone - save up!",
		price = 250000, -- PROGRESSION: 250,000 coins (increased from 50,000)
		currency = "coins",
		category = "mining",
		icon = "🕳️",
		maxQuantity = 1,
		type = "access",
		purchaseOrder = 1 -- Mining access (third major milestone)
	},

	-- All mining tools now require cave access
	wooden_pickaxe = {
		id = "wooden_pickaxe",
		name = "🪓 Wooden Pickaxe",
		description = "Basic wooden pickaxe for absolute beginners!\n\n⛏️ Basic Mining:\n• Can mine copper ore only\n• 50 durability\n• Very basic tool\n• Cheapest mining option\n\n🪓 Start your mining journey!\n\n⚠️ Requires Cave Access Pass",
		price = 5000,
		currency = "coins",
		category = "mining",
		icon = "🪓",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 2, -- Beginner tool
		requiresPurchase = "cave_access_pass" -- Requires cave access
	},

	basic_pickaxe = {
		id = "basic_pickaxe",
		name = "⛏️ Basic Pickaxe",
		description = "Essential mining tool for resource gathering!\n\n⛏️ Mining Power:\n• Can mine copper and bronze ore\n• 100 durability\n• Entry-level mining tool\n• Opens mining gameplay\n\n⛏️ Start digging for treasure!\n\n⚠️ Requires Cave Access Pass",
		price = 10000,
		currency = "coins",
		category = "mining",
		icon = "⛏️",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 3, -- First proper mining tool
		requiresPurchase = "cave_access_pass" -- Requires cave access
	},

	stone_pickaxe = {
		id = "stone_pickaxe",
		name = "🪨 Stone Pickaxe",
		description = "Improved mining tool with better capabilities!\n\n⛏️ Enhanced Power:\n• Can mine up to silver ore\n• 150 durability\n• Faster mining speed\n• Sturdy construction\n\n🪨 Upgrade your mining game!\n\n⚠️ Requires Cave Access Pass",
		price = 15000,
		currency = "coins",
		category = "mining",
		icon = "🪨",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 4, -- Pickaxe upgrade
		requiresPurchase = "cave_access_pass" -- Requires cave access
	},

	iron_pickaxe = {
		id = "iron_pickaxe",
		name = "⚒️ Iron Pickaxe",
		description = "Professional mining tool for serious miners!\n\n⛏️ Professional Grade:\n• Can mine up to gold ore\n• 250 durability\n• Much faster mining speed\n• Professional quality\n\n⚒️ Professional mining power!\n\n⚠️ Requires Cave Access Pass",
		price = 20000,
		currency = "coins",
		category = "mining",
		icon = "⚒️",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 5, -- Advanced tool
		requiresPurchase = "cave_access_pass" -- Requires cave access
	},

	diamond_pickaxe = {
		id = "diamond_pickaxe",
		name = "💎 Diamond Pickaxe",
		description = "Premium mining tool for the most valuable ores!\n\n⛏️ Premium Power:\n• Can mine up to platinum ore\n• 500 durability\n• Very fast mining speed\n• Premium quality construction\n\n💎 Elite mining equipment!\n\n⚠️ Requires Cave Access Pass",
		price = 25000,
		currency = "coins",
		category = "mining",
		icon = "💎",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 6, -- Premium tool
		requiresPurchase = "cave_access_pass" -- Requires cave access
	},

	obsidian_pickaxe = {
		id = "obsidian_pickaxe",
		name = "⬛ Obsidian Pickaxe",
		description = "🏆 LEGENDARY MINING TOOL 🏆\nCan mine the rarest ores including mystical obsidian!\n\n⛏️ Legendary Power:\n• Can mine ALL ore types\n• 1000 durability\n• Extremely fast mining speed\n• Legendary quality\n\n⬛ The ultimate mining tool!\n\n⚠️ Requires Cave Access Pass",
		price = 50000,
		currency = "farmTokens",
		category = "mining",
		icon = "⬛",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 7, -- Ultimate tool
		requiresPurchase = "cave_access_pass" -- Requires cave access
	},

	-- ========== CRAFTING CATEGORY ==========

	basic_workbench = {
		id = "basic_workbench",
		name = "🔨 Basic Workbench",
		description = "🎯 UNLOCK CRAFTING! Essential crafting station!\n\n🔨 Crafting Options:\n• Basic tools and equipment\n• Simple wooden items\n• Entry-level recipes\n• New gameplay dimension\n\n🔨 Create your own tools!",
		price = 50000,
		currency = "coins",
		category = "crafting",
		icon = "🔨",
		maxQuantity = 1,
		type = "building",
		purchaseOrder = 1 -- Crafting access
	},

	forge = {
		id = "forge",
		name = "🔥 Advanced Forge",
		description = "Advanced metalworking station for powerful items!\n\n🔥 Advanced Crafting:\n• Metal tools and weapons\n• Advanced equipment\n• Ore processing capabilities\n• Professional recipes\n\n🔥 Master metalworking!",
		price = 100000,
		currency = "coins",
		category = "crafting",
		icon = "🔥",
		maxQuantity = 1,
		type = "building",
		purchaseOrder = 2 -- Advanced crafting
	},

	mystical_altar = {
		id = "mystical_altar",
		name = "🔮 Mystical Altar",
		description = "🏆 LEGENDARY CRAFTING STATION 🏆\nCraft the most powerful and mystical items!\n\n🔮 Mystical Powers:\n• Legendary item creation\n• Mystical equipment\n• Magical enhancements\n• Ultimate recipes\n\n🔮 Transcend normal crafting!",
		price = 500000,
		currency = "farmTokens",
		category = "crafting",
		icon = "🔮",
		maxQuantity = 1,
		type = "building",
		purchaseOrder = 3 -- Ultimate crafting
	},

	-- ========== PREMIUM CATEGORY ==========

	rarity_booster = {
		id = "rarity_booster",
		name = "✨ Rarity Booster",
		description = "🏆 PREMIUM ENHANCEMENT 🏆\nGuarantee better crop quality!\n\n✨ Rarity Benefits:\n• Guarantees at least Rare quality\n• Works for next 3 harvests\n• Massive value increase\n• Premium enhancement\n\n✨ Quality over quantity!",
		price = 99,
		currency = "farmTokens",
		category = "premium",
		icon = "✨",
		maxQuantity = 5,
		type = "enhancement",
		purchaseOrder = 1 -- First premium item
	},

	auto_harvester = {
		id = "auto_harvester",
		name = "🤖 Auto Harvester",
		description = "🏆 ULTIMATE FARMING AUTOMATION 🏆\nNever manually harvest again!\n\n🤖 Automation Features:\n• Harvests all ready crops\n• Works automatically\n• Regular intervals\n• No manual work needed\n\n🤖 The ultimate upgrade!",
		price = 300,
		currency = "farmTokens",
		category = "premium",
		icon = "🤖",
		maxQuantity = 1,
		type = "upgrade",
		purchaseOrder = 2 -- Ultimate automation
	},
}

-- ========== EXISTING FUNCTIONS (unchanged) ==========

function ItemConfig.GetCropRarity(seedId, playerBoosters)
	playerBoosters = playerBoosters or {}

	local seedData = ItemConfig.ShopItems[seedId]
	if not seedData or not seedData.farmingData or not seedData.farmingData.rarityChances then
		return "common"
	end

	local chances = seedData.farmingData.rarityChances
	local roll = math.random()

	-- Apply rarity booster if active
	if playerBoosters.rarity_booster then
		return "rare" -- Guaranteed rare or better
	end

	-- Check for always high rarity seeds
	if seedData.farmingData.alwaysHighRarity then
		if roll < chances.legendary then return "legendary"
		elseif roll < chances.legendary + chances.epic then return "epic"
		elseif roll < chances.legendary + chances.epic + chances.rare then return "rare"
		else return "rare" -- Minimum rare for special seeds
		end
	end

	-- Normal rarity roll
	if roll < chances.legendary then return "legendary"
	elseif roll < chances.legendary + chances.epic then return "epic"
	elseif roll < chances.legendary + chances.epic + chances.rare then return "rare"
	elseif roll < chances.legendary + chances.epic + chances.rare + chances.uncommon then return "uncommon"
	else return "common"
	end
end

function ItemConfig.ApplyRarityToValue(baseValue, rarity)
	local rarityData = ItemConfig.RaritySystem[rarity]
	if rarityData then
		return math.floor(baseValue * rarityData.valueMultiplier)
	end
	return baseValue
end

function ItemConfig.GetRarityColor(rarity)
	local rarityData = ItemConfig.RaritySystem[rarity]
	return rarityData and rarityData.color or Color3.fromRGB(255, 255, 255)
end

function ItemConfig.GetRaritySize(rarity)
	local rarityData = ItemConfig.RaritySystem[rarity]
	return rarityData and rarityData.sizeMultiplier or 1.0
end

function ItemConfig.GetSeedData(seedId)
	local seed = ItemConfig.ShopItems[seedId]
	if seed and seed.type == "seed" and seed.farmingData then
		return seed.farmingData
	end
	return nil
end

function ItemConfig.GetCropData(cropId)
	return ItemConfig.Crops[cropId]
end

function ItemConfig.GetSeedForCrop(cropId)
	-- Find the seed that produces this crop
	for seedId, seedData in pairs(ItemConfig.ShopItems) do
		if seedData.type == "seed" and seedData.farmingData and seedData.farmingData.resultCropId == cropId then
			return seedId
		end
	end
	return nil
end

function ItemConfig.GetOreData(oreId)
	return ItemConfig.MiningSystem.ores[oreId]
end

function ItemConfig.GetToolData(toolId)
	return ItemConfig.MiningSystem.tools[toolId]
end

function ItemConfig.CanToolMineOre(toolId, oreId)
	local toolData = ItemConfig.MiningSystem.tools[toolId]
	if not toolData or not toolData.canMine then
		return false
	end

	for _, mineable in ipairs(toolData.canMine) do
		if mineable == oreId then
			return true
		end
	end
	return false
end

function ItemConfig.IsItemSellable(itemId)
	-- Define which items can be sold
	local sellableTypes = {
		"crop", "material", "ore"
	}

	-- Check if it's a crop
	if ItemConfig.Crops[itemId] then
		return true
	end

	-- Check if it's milk or other sellable items
	local sellableItems = {
		"milk", "fresh_milk", "Broccoli", "Cabbage", "Carrot", "Corn", "Potato", "Radish", "Strawberry", "Tomato", "Wheat", "Broccarrot", "Broctato", "Craddish", "Brocmato", "Cornmato",
		"copper_ore", "bronze_ore", "silver_ore", "gold_ore", "platinum_ore", "obsidian_ore"
	}

	for _, sellableItem in ipairs(sellableItems) do
		if itemId == sellableItem then
			return true
		end
	end

	return false
end

function ItemConfig.GetItemSellPrice(itemId)
	-- Crop sell prices
	local cropData = ItemConfig.Crops[itemId]
	if cropData and cropData.sellValue then
		return cropData.sellValue
	end

	-- Other item sell prices
	local sellPrices = {
		-- Animal products
		milk = 2,

		-- Ores
		copper_ore = 30,
		bronze_ore = 45,
		silver_ore = 80,
		gold_ore = 150,
		platinum_ore = 300,
		obsidian_ore = 100, -- Sells for farmTokens

		-- Materials
		wood = 10,
		stone = 5
	}

	return sellPrices[itemId] or 0
end

function ItemConfig.ValidateShopItem(itemId)
	local item = ItemConfig.ShopItems[itemId]
	if not item then return false, "Item not found" end

	local required = {"name", "price", "currency", "category", "description", "icon"}
	for _, prop in ipairs(required) do
		if not item[prop] then
			return false, "Missing property: " .. prop
		end
	end

	return true, "Valid item"
end

function ItemConfig.GetAllShopItems()
	return ItemConfig.ShopItems
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

function ItemConfig.CountItemsByCategory()
	local counts = {}
	for itemId, item in pairs(ItemConfig.ShopItems) do
		local category = item.category or "unknown"
		counts[category] = (counts[category] or 0) + 1
	end
	return counts
end

function ItemConfig.CountOresByCategory()
	local count = 0
	for _ in pairs(ItemConfig.MiningSystem.ores) do
		count = count + 1
	end
	return count
end

function ItemConfig.CountToolsByCategory()
	local count = 0
	for _ in pairs(ItemConfig.MiningSystem.tools) do
		count = count + 1
	end
	return count
end

-- ========== [Keep all other existing functions unchanged] ==========

print("✅ PROGRESSION SYSTEM UPDATED!")
print("🎯 NEW PROGRESSION STRUCTURE:")
print("  1️⃣ Start: Milk cow (free) → sell milk for coins")
print("  2️⃣ Garden: 100 coins (unchanged)")
print("  3️⃣ Wheat Field: 10,000 coins (NEW)")
print("  4️⃣ Cave Access: 250,000 coins (increased from 50,000)")
print("")
print("🔧 CHANGES MADE:")
print("  ✅ Added wheat_field_access item (10,000 coins)")
print("  ✅ Wheat seeds now require wheat field access")
print("  ✅ Scythe tool now requires wheat field access")
print("  ✅ Cave access increased to 250,000 coins")
print("  ✅ All mining tools now require cave access")
print("  ✅ Updated descriptions to reflect progression")

return ItemConfig