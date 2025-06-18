--[[
    FIXED ItemConfig.lua - Complete with MiningSystem Data
    Place in: ReplicatedStorage/ItemConfig.lua
    
    FIXES:
    ✅ Added missing MiningSystem.ores data
    ✅ Added missing MiningSystem.tools data  
    ✅ All shop items properly formatted
    ✅ Rarity system integrated for farming
    ✅ Complete item catalog with proper categories
    ✅ Seed-to-crop mapping fixed
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
		description = "Fresh orange carrot.", sellValue = 15, sellCurrency = "coins", 
		feedValue = 1, cropPoints = 1, icon = "🥕", rarity = "common" 
	},
	corn = { 
		id = "corn", name = "🌽 Corn", type = "crop", category = "crops", 
		description = "Sweet yellow corn.", sellValue = 25, sellCurrency = "coins", 
		feedValue = 2, cropPoints = 2, icon = "🌽", rarity = "common" 
	},
	strawberry = { 
		id = "strawberry", name = "🍓 Strawberry", type = "crop", category = "crops", 
		description = "Sweet red strawberry.", sellValue = 40, sellCurrency = "coins", 
		feedValue = 3, cropPoints = 3, icon = "🍓", rarity = "uncommon" 
	},
	golden_fruit = { 
		id = "golden_fruit", name = "✨ Golden Fruit", type = "crop", category = "crops", 
		description = "Magical golden fruit.", sellValue = 100, sellCurrency = "coins", 
		feedValue = 10, cropPoints = 10, icon = "✨", rarity = "legendary" 
	},
	wheat = { 
		id = "wheat", name = "🌾 Wheat", type = "crop", category = "crops", 
		description = "Golden wheat grain.", sellValue = 20, sellCurrency = "coins", 
		feedValue = 2, cropPoints = 2, icon = "🌾", rarity = "common" 
	},
	potato = { 
		id = "potato", name = "🥔 Potato", type = "crop", category = "crops", 
		description = "Hearty potato.", sellValue = 18, sellCurrency = "coins", 
		feedValue = 2, cropPoints = 2, icon = "🥔", rarity = "common" 
	},
	tomato = { 
		id = "tomato", name = "🍅 Tomato", type = "crop", category = "crops", 
		description = "Juicy red tomato.", sellValue = 30, sellCurrency = "coins", 
		feedValue = 3, cropPoints = 3, icon = "🍅", rarity = "uncommon" 
	},
	cabbage = { 
		id = "cabbage", name = "🥬 Cabbage", type = "crop", category = "crops", 
		description = "Fresh leafy cabbage.", sellValue = 22, sellCurrency = "coins", 
		feedValue = 3, cropPoints = 3, icon = "🥬", rarity = "common" 
	},
	radish = { 
		id = "radish", name = "🌶️ Radish", type = "crop", category = "crops", 
		description = "Spicy radish.", sellValue = 12, sellCurrency = "coins", 
		feedValue = 1, cropPoints = 1, icon = "🌶️", rarity = "common" 
	},
	broccoli = { 
		id = "broccoli", name = "🥦 Broccoli", type = "crop", category = "crops", 
		description = "Nutritious green broccoli.", sellValue = 35, sellCurrency = "coins", 
		feedValue = 4, cropPoints = 4, icon = "🥦", rarity = "uncommon" 
	},
	glorious_sunflower = { 
		id = "glorious_sunflower", name = "🌻 Glorious Sunflower", type = "crop", category = "crops", 
		description = "🏆 LEGENDARY PREMIUM CROP 🏆", sellValue = 500, sellCurrency = "farmTokens", 
		feedValue = 25, cropPoints = 25, icon = "🌻", rarity = "legendary" 
	}
}

-- ========== COMPLETE SHOP ITEMS ==========
ItemConfig.ShopItems = {
	-- ========== SEEDS CATEGORY ==========
	carrot_seeds = {
		id = "carrot_seeds",
		name = "🥕 Carrot Seeds",
		description = "Fast-growing orange carrots! Perfect for beginners.\n\n⏱️ Grow Time: 2 minutes\n💰 Sell Value: 15 coins each\n🐷 Pig Value: 1 crop point",
		price = 25,
		currency = "coins",
		category = "seeds",
		icon = "🥕",
		maxQuantity = 50,
		type = "seed",
		farmingData = {
			growTime = 120, -- 2 minutes
			yieldAmount = 2,
			resultCropId = "carrot",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.6, uncommon = 0.3, rare = 0.08, epic = 0.02, legendary = 0.001}
		}
	},

	corn_seeds = {
		id = "corn_seeds",
		name = "🌽 Corn Seeds",
		description = "Sweet corn that pigs love! Higher yield than carrots.\n\n⏱️ Grow Time: 3 minutes\n💰 Sell Value: 25 coins each\n🐷 Pig Value: 2 crop points",
		price = 50,
		currency = "coins",
		category = "seeds",
		icon = "🌽",
		maxQuantity = 50,
		type = "seed",
		farmingData = {
			growTime = 180, -- 3 minutes
			yieldAmount = 3,
			resultCropId = "corn",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.5, uncommon = 0.35, rare = 0.12, epic = 0.03, legendary = 0.001}
		}
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "🍓 Strawberry Seeds",
		description = "Delicious berries with premium value! Worth the wait.\n\n⏱️ Grow Time: 4 minutes\n💰 Sell Value: 40 coins each\n🐷 Pig Value: 3 crop points",
		price = 100,
		currency = "coins",
		category = "seeds",
		icon = "🍓",
		maxQuantity = 50,
		type = "seed",
		farmingData = {
			growTime = 240, -- 4 minutes
			yieldAmount = 2,
			resultCropId = "strawberry",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.4, uncommon = 0.4, rare = 0.15, epic = 0.05, legendary = 0.002}
		}
	},

	wheat_seeds = {
		id = "wheat_seeds",
		name = "🌾 Wheat Seeds",
		description = "Hardy wheat that grows in all conditions. Perfect for making bread!\n\n⏱️ Grow Time: 2.5 minutes\n💰 Sell Value: 20 coins each\n🐷 Pig Value: 2 crop points",
		price = 30,
		currency = "coins",
		category = "seeds",
		icon = "🌾",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 150, -- 2.5 minutes
			yieldAmount = 3,
			resultCropId = "wheat",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.55, uncommon = 0.3, rare = 0.12, epic = 0.03, legendary = 0.001}
		}
	},

	potato_seeds = {
		id = "potato_seeds",
		name = "🥔 Potato Seeds",
		description = "Versatile potatoes that grow underground. Great for cooking!\n\n⏱️ Grow Time: 3 minutes\n💰 Sell Value: 18 coins each\n🐷 Pig Value: 2 crop points",
		price = 40,
		currency = "coins",
		category = "seeds",
		icon = "🥔",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 180, -- 3 minutes
			yieldAmount = 4,
			resultCropId = "potato",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.6, uncommon = 0.25, rare = 0.12, epic = 0.03, legendary = 0.001}
		}
	},

	cabbage_seeds = {
		id = "cabbage_seeds",
		name = "🥬 Cabbage Seeds",
		description = "Leafy green cabbages packed with nutrients. Animals love them!\n\n⏱️ Grow Time: 3.5 minutes\n💰 Sell Value: 22 coins each\n🐷 Pig Value: 3 crop points",
		price = 35,
		currency = "coins",
		category = "seeds",
		icon = "🥬",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 210, -- 3.5 minutes
			yieldAmount = 2,
			resultCropId = "cabbage",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.5, uncommon = 0.35, rare = 0.12, epic = 0.03, legendary = 0.001}
		}
	},

	radish_seeds = {
		id = "radish_seeds",
		name = "🌶️ Radish Seeds",
		description = "Quick-growing spicy radishes. Ready in no time!\n\n⏱️ Grow Time: 1.5 minutes\n💰 Sell Value: 12 coins each\n🐷 Pig Value: 1 crop point",
		price = 25,
		currency = "coins",
		category = "seeds",
		icon = "🌶️",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 90, -- 1.5 minutes
			yieldAmount = 2,
			resultCropId = "radish",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.7, uncommon = 0.2, rare = 0.08, epic = 0.02, legendary = 0.001}
		}
	},

	broccoli_seeds = {
		id = "broccoli_seeds",
		name = "🥦 Broccoli Seeds",
		description = "Nutritious green broccoli. Takes time but worth the wait!\n\n⏱️ Grow Time: 4.5 minutes\n💰 Sell Value: 35 coins each\n🐷 Pig Value: 4 crop points",
		price = 45,
		currency = "coins",
		category = "seeds",
		icon = "🥦",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 270, -- 4.5 minutes
			yieldAmount = 2,
			resultCropId = "broccoli",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.4, uncommon = 0.4, rare = 0.15, epic = 0.05, legendary = 0.002}
		}
	},

	tomato_seeds = {
		id = "tomato_seeds",
		name = "🍅 Tomato Seeds",
		description = "Juicy red tomatoes perfect for cooking. High value crop!\n\n⏱️ Grow Time: 4 minutes\n💰 Sell Value: 30 coins each\n🐷 Pig Value: 3 crop points",
		price = 55,
		currency = "coins",
		category = "seeds",
		icon = "🍅",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 240, -- 4 minutes
			yieldAmount = 3,
			resultCropId = "tomato",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.45, uncommon = 0.35, rare = 0.15, epic = 0.05, legendary = 0.002}
		}
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "✨ Golden Seeds",
		description = "Magical seeds that produce golden fruit! Premium crop.\n\n⏱️ Grow Time: 6 minutes\n💰 Sell Value: 100 coins each\n🐷 Pig Value: 10 crop points",
		price = 50,
		currency = "farmTokens",
		category = "seeds",
		icon = "✨",
		maxQuantity = 25,
		type = "seed",
		farmingData = {
			growTime = 360, -- 6 minutes
			yieldAmount = 1,
			resultCropId = "golden_fruit",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.1, uncommon = 0.3, rare = 0.4, epic = 0.19, legendary = 0.01}
		}
	},

	glorious_sunflower_seeds = {
		id = "glorious_sunflower_seeds",
		name = "🌻 Glorious Sunflower Seeds",
		description = "🏆 PREMIUM LEGENDARY SEED 🏆\nThe rarest and most beautiful crop! Massive size with brilliant glow!\n\n⏱️ Grow Time: 8 minutes\n💰 Sell Value: 500 Farm Tokens\n🐷 Pig Value: 25 crop points",
		price = 150,
		currency = "farmTokens",
		category = "seeds",
		icon = "🌻",
		maxQuantity = 10,
		type = "seed",
		farmingData = {
			growTime = 480, -- 8 minutes
			yieldAmount = 1,
			resultCropId = "glorious_sunflower",
			stages = {"planted", "sprouting", "growing", "flowering", "glorious"},
			rarityChances = {common = 0.0, uncommon = 0.1, rare = 0.3, epic = 0.4, legendary = 0.2},
			alwaysHighRarity = true
		}
	},

	-- ========== FARM CATEGORY ==========
	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "🌾 Your First Farm Plot",
		description = "Purchase your first farming plot! Includes free starter seeds.\n\n🎁 Includes:\n• 5x Carrot Seeds\n• 3x Corn Seeds\n• Access to farming system",
		price = 100,
		currency = "coins",
		category = "farm",
		icon = "🌾",
		maxQuantity = 1,
		type = "farmPlot",
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
		description = "Add more farming space! Each expansion gives you another farm plot with 9 planting spots.\n\n📈 Benefits:\n• 9 more planting spots\n• Increase farming capacity\n• Supports up to 10 total plots",
		price = 500,
		currency = "coins",
		category = "farm",
		icon = "🚜",
		maxQuantity = 9,
		type = "farmPlot",
		requiresPurchase = "farm_plot_starter"
	},

	-- ========== DEFENSE CATEGORY ==========
	basic_chicken = {
		id = "basic_chicken",
		name = "🐔 Basic Chicken",
		description = "General purpose pest control. Eliminates aphids and lays eggs for steady income.\n\n🛡️ Protects Against:\n• Aphids\n• Small pests\n\n💰 Produces:\n• Eggs every 4 minutes\n• 5 coins per egg",
		price = 150,
		currency = "coins",
		category = "defense",
		icon = "🐔",
		maxQuantity = 20,
		type = "chicken",
		requiresPurchase = "farm_plot_starter"
	},

	guinea_fowl = {
		id = "guinea_fowl",
		name = "🦃 Guinea Fowl",
		description = "Anti-locust specialist. Provides early warning system and superior pest elimination.\n\n🛡️ Protects Against:\n• Locusts (specialist)\n• Aphids\n• Provides pest alerts\n\n💰 Produces:\n• Premium eggs every 6 minutes\n• 8 coins per egg",
		price = 300,
		currency = "coins",
		category = "defense",
		icon = "🦃",
		maxQuantity = 10,
		type = "chicken",
		requiresPurchase = "basic_chicken"
	},

	rooster = {
		id = "rooster",
		name = "🐓 Rooster",
		description = "Flock leader that boosts all nearby chickens and reduces pest spawn rates.\n\n🛡️ Special Abilities:\n• Boosts other chickens by 50%\n• Reduces pest spawns by 20%\n• Territory protection\n\n💰 Produces:\n• Premium eggs every 8 minutes\n• 12 coins per egg",
		price = 500,
		currency = "coins",
		category = "defense",
		icon = "🐓",
		maxQuantity = 3,
		type = "chicken",
		requiresPurchase = "guinea_fowl"
	},

	organic_pesticide = {
		id = "organic_pesticide",
		name = "🧪 Organic Pesticide",
		description = "Manually eliminate pests from crops. One-time use, affects 3x3 area around target crop.\n\n💪 Effectiveness:\n• Eliminates all pest types\n• 3x3 area of effect\n• Instant results\n• Eco-friendly formula",
		price = 50,
		currency = "coins",
		category = "defense",
		icon = "🧪",
		maxQuantity = 20,
		type = "tool"
	},

	pest_detector = {
		id = "pest_detector",
		name = "📡 Pest Detector",
		description = "Early warning system that alerts you to pest infestations before they cause major damage.\n\n🔍 Features:\n• Early pest detection\n• 20 stud detection range\n• Automatic alerts\n• One-time purchase",
		price = 200,
		currency = "coins",
		category = "defense",
		icon = "📡",
		maxQuantity = 1,
		type = "upgrade"
	},

	super_pesticide = {
		id = "super_pesticide",
		name = "💉 Super Pesticide",
		description = "🏆 PREMIUM PEST CONTROL 🏆\nIndustrial-grade pesticide that eliminates ALL pests from your entire farm instantly!\n\n💪 Ultimate Power:\n• Entire farm coverage\n• All pest types eliminated\n• Instant effect\n• Premium formula",
		price = 25,
		currency = "farmTokens",
		category = "defense",
		icon = "💉",
		maxQuantity = 5,
		type = "tool",
		requiresPurchase = "organic_pesticide"
	},
	-- Farm Plot Protection - Individual Roofs
	plot_roof_basic = {
		id = "plot_roof_basic",
		name = "🏠 Basic Plot Roof",
		description = "Protects ONE farm plot from UFO attacks and weather damage.\n\n🛡️ Protection:\n• Blocks UFO beam damage\n• Protects against weather\n• Covers 1 farm plot\n• Durable construction",
		price = 200,
		currency = "coins",
		category = "defense",
		icon = "🏠",
		maxQuantity = 10, -- Can buy one for each plot
		type = "protection",
		effects = {
			coverage = 1,
			ufoProtection = true,
			weatherProtection = true,
			plotSpecific = true
		}
	},

	plot_roof_reinforced = {
		id = "plot_roof_reinforced",
		name = "🏛️ Reinforced Plot Roof",
		description = "Enhanced protection for ONE farm plot with 99% damage reduction.\n\n🛡️ Enhanced Protection:\n• 99% UFO damage reduction\n• Weather immunity\n• Self-repairing materials\n• Covers 1 farm plot",
		price = 500,
		currency = "coins",
		category = "defense",
		icon = "🏛️",
		maxQuantity = 10,
		type = "protection",
		requiresPurchase = "plot_roof_basic",
		effects = {
			coverage = 1,
			ufoProtection = true,
			weatherProtection = true,
			damageReduction = 0.99,
			selfRepairing = true,
			plotSpecific = true
		}
	},

	-- Area Protection - Multiple Plots
	area_dome_small = {
		id = "area_dome_small",
		name = "🔘 Small Protection Dome",
		description = "Energy dome that protects up to 3 farm plots from all attacks.\n\n🛡️ Area Protection:\n• Protects 3 adjacent plots\n• 100% UFO immunity\n• Weather protection\n• Pest deterrent field",
		price = 1000,
		currency = "coins",
		category = "defense",
		icon = "🔘",
		maxQuantity = 3, -- Can have multiple small domes
		type = "protection",
		requiresPurchase = "plot_roof_reinforced",
		effects = {
			coverage = 3,
			ufoProtection = true,
			weatherProtection = true,
			pestDeterrent = true,
			areaEffect = true
		}
	},

	area_dome_large = {
		id = "area_dome_large",
		name = "🔵 Large Protection Dome", 
		description = "Advanced energy dome protecting up to 6 farm plots with enhanced features.\n\n🛡️ Large Area Protection:\n• Protects 6 adjacent plots\n• Complete immunity\n• Crop growth boost +10%\n• Auto-pest elimination",
		price = 2500,
		currency = "coins",
		category = "defense",
		icon = "🔵",
		maxQuantity = 2,
		type = "protection",
		requiresPurchase = "area_dome_small",
		effects = {
			coverage = 6,
			ufoProtection = true,
			weatherProtection = true,
			pestDeterrent = true,
			growthBoost = 0.1,
			autoPestElimination = true,
			areaEffect = true
		}
	},

	-- Ultimate Protection (Already exists as mega_dome, but let's enhance it)
	mega_dome_enhanced = {
		id = "mega_dome",
		name = "🛡️ Mega Protection Dome",
		description = "🏆 ULTIMATE PROTECTION 🏆\nDome covers ALL your farm plots and blocks UFO attacks completely!\n\n🛡️ Ultimate Defense:\n• Covers all farm plots\n• 100% UFO protection\n• Weather immunity\n• +25% crop growth\n• Auto-harvest alerts\n• Pest elimination field",
		price = 100,
		currency = "farmTokens",
		category = "defense", -- Changed from premium to defense
		icon = "🛡️",
		maxQuantity = 1,
		type = "protection",
		requiresPurchase = "area_dome_large",
		effects = {
			coverage = 999, -- Covers all plots
			ufoProtection = true,
			weatherProtection = true,
			pestDeterrent = true,
			growthBoost = 0.25,
			autoHarvestAlerts = true,
			ultimateProtection = true
		}
	},

	-- Weather Protection Variants
	weather_shield_basic = {
		id = "weather_shield_basic",
		name = "☔ Basic Weather Shield",
		description = "Protects crops from rain and wind damage on one plot.\n\n🌦️ Weather Protection:\n• Rain damage immunity\n• Wind protection\n• Covers 1 plot\n• Basic material",
		price = 150,
		currency = "coins",
		category = "defense",
		icon = "☔",
		maxQuantity = 10,
		type = "protection",
		effects = {
			coverage = 1,
			weatherProtection = true,
			rainProtection = true,
			windProtection = true
		}
	},

	weather_shield_advanced = {
		id = "weather_shield_advanced", 
		name = "🌪️ Advanced Weather Shield",
		description = "Complete weather immunity with growth bonuses for one plot.\n\n🌦️ Advanced Protection:\n• All weather immunity\n• +15% growth speed\n• Temperature regulation\n• UV enhancement",
		price = 400,
		currency = "coins",
		category = "defense",
		icon = "🌪️",
		maxQuantity = 10,
		type = "protection",
		requiresPurchase = "weather_shield_basic",
		effects = {
			coverage = 1,
			weatherProtection = true,
			growthBoost = 0.15,
			temperatureControl = true,
			uvEnhancement = true
		}
	},

	-- Pest Deterrent Systems
	pest_barrier_electronic = {
		id = "pest_barrier_electronic",
		name = "📡 Electronic Pest Barrier",
		description = "High-tech barrier that repels pests from one farm plot automatically.\n\n🔬 Electronic Defense:\n• Ultrasonic pest repelling\n• 90% pest reduction\n• Self-powered system\n• Covers 1 plot",
		price = 300,
		currency = "coins",
		category = "defense", 
		icon = "📡",
		maxQuantity = 10,
		type = "protection",
		requiresPurchase = "pest_detector",
		effects = {
			coverage = 1,
			pestDeterrent = true,
			pestReduction = 0.9,
			electronic = true,
			selfPowered = true
		}
	},

	pest_barrier_bio = {
		id = "pest_barrier_bio",
		name = "🌿 Bio Pest Barrier",
		description = "Natural plant-based pest deterrent system using companion planting.\n\n🌱 Biological Defense:\n• Natural pest repelling\n• Eco-friendly solution\n• Soil enhancement\n• Plant health boost +10%",
		price = 250,
		currency = "coins",
		category = "defense",
		icon = "🌿", 
		maxQuantity = 10,
		type = "protection",
		effects = {
			coverage = 1,
			pestDeterrent = true,
			pestReduction = 0.8,
			biological = true,
			soilEnhancement = true,
			healthBoost = 0.1
		}
	},

	-- Advanced Defense Systems
	defense_turret_auto = {
		id = "defense_turret_auto",
		name = "🚀 Auto-Defense Turret",
		description = "🏆 PREMIUM DEFENSE 🏆\nAutomated turret system that eliminates UFOs and pests automatically!\n\n🚀 Ultimate Defense:\n• Auto-targets UFOs\n• Eliminates pests on sight\n• 360° protection coverage\n• Self-repairing system",
		price = 150,
		currency = "farmTokens",
		category = "defense",
		icon = "🚀",
		maxQuantity = 3,
		type = "protection",
		requiresPurchase = "mega_dome",
		effects = {
			coverage = 5, -- Covers 5 plots in radius
			ufoProtection = true,
			pestDeterrent = true,
			autoTargeting = true,
			selfRepairing = true,
			ultimateDefense = true
		}
	},

	force_field_generator = {
		id = "force_field_generator",
		name = "⚡ Force Field Generator",
		description = "🏆 LEGENDARY DEFENSE 🏆\nCreates an impenetrable energy field around your entire farm!\n\n⚡ Force Field Power:\n• Blocks ALL damage\n• Energy barrier visible\n• Prevents all attacks\n• Legendary protection",
		price = 200,
		currency = "farmTokens",
		category = "defense",
		icon = "⚡",
		maxQuantity = 1,
		type = "protection",
		requiresPurchase = "defense_turret_auto",
		effects = {
			coverage = 999,
			ufoProtection = true,
			weatherProtection = true,
			pestDeterrent = true,
			forceField = true,
			legendary = true,
			absoluteProtection = true
		}
	},

	-- Maintenance and Repair Items
	protection_repair_kit = {
		id = "protection_repair_kit",
		name = "🔧 Protection Repair Kit",
		description = "Repair damaged protection systems and restore them to full strength.\n\n🔧 Repair Features:\n• Fixes all protection types\n• Restores full durability\n• Includes spare parts\n• Emergency repairs",
		price = 50,
		currency = "coins",
		category = "defense",
		icon = "🔧",
		maxQuantity = 20,
		type = "tool",
		effects = {
			repairAll = true,
			restoreDurability = true,
			emergencyUse = true
		}
	},

	protection_upgrade_kit = {
		id = "protection_upgrade_kit", 
		name = "⬆️ Protection Upgrade Kit",
		description = "Enhance existing protection systems with improved capabilities.\n\n⬆️ Upgrade Benefits:\n• +50% protection strength\n• Reduced maintenance\n• Enhanced features\n• Permanent improvement",
		price = 100,
		currency = "coins",
		category = "defense",
		icon = "⬆️",
		maxQuantity = 10,
		type = "upgrade",
		requiresPurchase = "protection_repair_kit",
		effects = {
			strengthBoost = 0.5,
			reducedMaintenance = true,
			enhancedFeatures = true,
			permanentUpgrade = true
		}
	},
	
	basic_feed = {
		id = "basic_feed",
		name = "🌾 Basic Chicken Feed",
		description = "Keeps chickens fed and working efficiently. Essential for chicken care.\n\n🐔 Benefits:\n• Feeds chickens for 6 hours\n• Maintains egg production\n• Keeps chickens healthy\n• Basic nutrition",
		price = 10,
		currency = "coins",
		category = "defense",
		icon = "🌾",
		maxQuantity = 100,
		type = "feed"
	},

	premium_feed = {
		id = "premium_feed",
		name = "⭐ Premium Chicken Feed",
		description = "High-quality feed that increases egg production and keeps chickens happy longer.\n\n🐔 Premium Benefits:\n• Feeds chickens for 12 hours\n• +20% egg production boost\n• Superior nutrition\n• Happy chickens work better",
		price = 25,
		currency = "coins",
		category = "defense",
		icon = "⭐",
		maxQuantity = 50,
		type = "feed",
		requiresPurchase = "basic_feed"
	},

	-- ========== MINING CATEGORY ==========
	basic_pickaxe = {
		id = "basic_pickaxe",
		name = "⛏️ Basic Pickaxe",
		description = "Essential tool for mining. Allows access to copper and bronze ore deposits.\n\n⛏️ Mining Power:\n• Can mine copper ore\n• Can mine bronze ore\n• 100 durability\n• Entry-level tool",
		price = 200,
		currency = "coins",
		category = "mining",
		icon = "⛏️",
		maxQuantity = 1,
		type = "tool"
	},

	stone_pickaxe = {
		id = "stone_pickaxe",
		name = "🪨 Stone Pickaxe",
		description = "Improved mining tool with better durability and mining power.\n\n⛏️ Enhanced Power:\n• Can mine up to silver ore\n• 150 durability\n• 20% faster mining\n• Sturdy construction",
		price = 350,
		currency = "coins",
		category = "mining",
		icon = "🪨",
		maxQuantity = 1,
		type = "tool",
		requiresPurchase = "basic_pickaxe"
	},

	iron_pickaxe = {
		id = "iron_pickaxe",
		name = "⚒️ Iron Pickaxe",
		description = "Professional mining tool that can handle tougher ores.\n\n⛏️ Professional Grade:\n• Can mine up to gold ore\n• 250 durability\n• 50% faster mining\n• Professional quality",
		price = 800,
		currency = "coins",
		category = "mining",
		icon = "⚒️",
		maxQuantity = 1,
		type = "tool",
		requiresPurchase = "stone_pickaxe"
	},

	diamond_pickaxe = {
		id = "diamond_pickaxe",
		name = "💎 Diamond Pickaxe",
		description = "Premium mining tool for the most valuable ores.\n\n⛏️ Premium Power:\n• Can mine up to platinum ore\n• 500 durability\n• 150% faster mining\n• Premium quality",
		price = 2500,
		currency = "coins",
		category = "mining",
		icon = "💎",
		maxQuantity = 1,
		type = "tool",
		requiresPurchase = "iron_pickaxe"
	},

	obsidian_pickaxe = {
		id = "obsidian_pickaxe",
		name = "⬛ Obsidian Pickaxe",
		description = "🏆 LEGENDARY MINING TOOL 🏆\nCan mine the rarest ores including mystical obsidian!\n\n⛏️ Legendary Power:\n• Can mine ALL ore types\n• 1000 durability\n• 250% faster mining\n• Legendary quality",
		price = 200,
		currency = "farmTokens",
		category = "mining",
		icon = "⬛",
		maxQuantity = 1,
		type = "tool",
		requiresPurchase = "diamond_pickaxe"
	},

	cave_access_pass = {
		id = "cave_access_pass",
		name = "🕳️ Cave Access Pass",
		description = "Grants access to Cave 1 (Copper Mine)! Start your mining journey!\n\n🗻 Access To:\n• Cave 1: Copper Mine\n• Copper ore deposits\n• Bronze ore deposits\n• Mining tutorial area",
		price = 200,
		currency = "coins",
		category = "mining",
		icon = "🕳️",
		maxQuantity = 1,
		type = "access"
	},

	-- ========== CRAFTING CATEGORY ==========
	basic_workbench = {
		id = "basic_workbench",
		name = "🔨 Basic Workbench",
		description = "Essential crafting station for making tools and equipment.\n\n🔨 Crafting Options:\n• Basic tools\n• Simple equipment\n• Wooden items\n• Entry-level recipes",
		price = 500,
		currency = "coins",
		category = "crafting",
		icon = "🔨",
		maxQuantity = 1,
		type = "building"
	},

	forge = {
		id = "forge",
		name = "🔥 Advanced Forge",
		description = "Advanced metalworking station for creating powerful tools and weapons.\n\n🔥 Advanced Crafting:\n• Metal tools\n• Advanced equipment\n• Ore processing\n• Professional recipes",
		price = 2000,
		currency = "coins",
		category = "crafting",
		icon = "🔥",
		maxQuantity = 1,
		type = "building",
		requiresPurchase = "basic_workbench"
	},

	mystical_altar = {
		id = "mystical_altar",
		name = "🔮 Mystical Altar",
		description = "🏆 LEGENDARY CRAFTING STATION 🏆\nCraft the most powerful and mystical items in the game!\n\n🔮 Mystical Powers:\n• Legendary items\n• Mystical equipment\n• Magical enhancements\n• Ultimate recipes",
		price = 100,
		currency = "farmTokens",
		category = "crafting",
		icon = "🔮",
		maxQuantity = 1,
		type = "building",
		requiresPurchase = "forge"
	},

	-- ========== PREMIUM CATEGORY ==========
	auto_harvester = {
		id = "auto_harvester",
		name = "🤖 Auto Harvester",
		description = "🏆 ULTIMATE FARMING UPGRADE 🏆\nAutomatically harvests ready crops every 30 seconds!\n\n🤖 Automation Features:\n• Harvests all ready crops\n• Works 24/7\n• 30-second intervals\n• No manual work needed",
		price = 150,
		currency = "farmTokens",
		category = "premium",
		icon = "🤖",
		maxQuantity = 1,
		type = "upgrade"
	},

	rarity_booster = {
		id = "rarity_booster",
		name = "✨ Rarity Booster",
		description = "🏆 PREMIUM ENHANCEMENT 🏆\nGuarantees at least Rare rarity for your next 3 harvests!\n\n✨ Rarity Benefits:\n• Minimum Rare quality\n• Works for 3 harvests\n• Massive value increase\n• Premium enhancement",
		price = 25,
		currency = "farmTokens",
		category = "premium",
		icon = "✨",
		maxQuantity = 5,
		type = "enhancement"
	},

	mega_dome = {
		id = "mega_dome",
		name = "🛡️ Mega Protection Dome",
		description = "🏆 ULTIMATE PROTECTION 🏆\nDome covers ALL your farm plots and blocks UFO attacks completely!\n\n🛡️ Ultimate Defense:\n• Covers all farm plots\n• 100% UFO protection\n• Weather protection\n• Permanent protection",
		price = 100,
		currency = "farmTokens",
		category = "premium",
		icon = "🛡️",
		maxQuantity = 1,
		type = "protection"
	},

	-- ========== MILK EFFICIENCY UPGRADES ==========
	milk_efficiency_1 = {
		id = "milk_efficiency_1",
		name = "🥛 Enhanced Milking I",
		description = "Improve your cow milking efficiency! Reduces cooldown and increases yield.\n\n🐄 Benefits:\n• -10 seconds cooldown\n• +1 milk per collection\n• Better cow happiness\n• Tier 1 upgrade",
		price = 100,
		currency = "coins",
		category = "farm",
		icon = "🥛",
		maxQuantity = 1,
		type = "upgrade"
	},

	milk_efficiency_2 = {
		id = "milk_efficiency_2",
		name = "🥛 Enhanced Milking II",
		description = "Further improve milking efficiency with advanced techniques.\n\n🐄 Enhanced Benefits:\n• -20 seconds total cooldown\n• +3 milk per collection total\n• Premium cow care\n• Tier 2 upgrade",
		price = 250,
		currency = "coins",
		category = "farm",
		icon = "🥛",
		maxQuantity = 1,
		type = "upgrade",
		requiresPurchase = "milk_efficiency_1"
	},

	milk_efficiency_3 = {
		id = "milk_efficiency_3",
		name = "🥛 Enhanced Milking III",
		description = "Maximum milking efficiency! Professional cow management.\n\n🐄 Maximum Benefits:\n• -30 seconds total cooldown\n• +5 milk per collection total\n• Expert cow care\n• Tier 3 upgrade",
		price = 500,
		currency = "coins",
		category = "farm",
		icon = "🥛",
		maxQuantity = 1,
		type = "upgrade",
		requiresPurchase = "milk_efficiency_2"
	},

	milk_value_boost = {
		id = "milk_value_boost",
		name = "💰 Premium Milk Quality",
		description = "Increase the quality and value of your milk production.\n\n💰 Value Enhancement:\n• +10 coins per milk sold\n• Premium quality milk\n• Better market value\n• One-time upgrade",
		price = 300,
		currency = "coins",
		category = "farm",
		icon = "💰",
		maxQuantity = 1,
		type = "upgrade"
	},
	
	-- ========== COW SYSTEM ITEMS ==========

	-- Basic Cow (First cow purchase)
	basic_cow = {
		id = "basic_cow",
		name = "🐄 Basic Cow",
		description = "Your first milk-producing cow! Produces 2 milk every 60 seconds.\n\n🥛 Production: 2 milk/minute\n⏰ Cooldown: 60 seconds\n💰 Sell Value: 75 coins each\n🎯 Perfect for starting your dairy empire!",
		price = 500,
		currency = "coins",
		category = "farm",
		icon = "🐄",
		maxQuantity = 1,
		type = "cow",
		cowData = {
			tier = "basic",
			milkAmount = 2,
			cooldown = 60,
			visualEffects = {},
			maxCows = 1
		}
	},

	-- Additional Basic Cows
	extra_basic_cow = {
		id = "extra_basic_cow",
		name = "🐄 Additional Basic Cow",
		description = "Add more basic cows to your farm! Each cow produces independently.\n\n🥛 Production: 2 milk/minute\n⏰ Cooldown: 60 seconds\n📈 Stack up to 5 basic cows total",
		price = 750,
		currency = "coins",
		category = "farm",
		icon = "🐄",
		maxQuantity = 4,
		type = "cow",
		requiresPurchase = "basic_cow",
		cowData = {
			tier = "basic",
			milkAmount = 2,
			cooldown = 60,
			visualEffects = {},
			maxCows = 5
		}
	},

	-- Silver Cow Upgrade
	silver_cow_upgrade = {
		id = "silver_cow_upgrade",
		name = "🥈 Silver Cow Upgrade",
		description = "Upgrade a basic cow to Silver tier! Shiny metallic appearance with improved production.\n\n🥛 Production: 4 milk/minute\n⏰ Cooldown: 45 seconds\n✨ Visual: Silver metallic shine\n🔧 Upgrades one existing cow",
		price = 1000,
		currency = "coins",
		category = "farm",
		icon = "🥈",
		maxQuantity = 5,
		type = "cow_upgrade",
		requiresPurchase = "basic_cow",
		cowData = {
			tier = "silver",
			milkAmount = 4,
			cooldown = 45,
			visualEffects = {"metallic_shine", "silver_particles"},
			upgradeFrom = "basic"
		}
	},

	-- Gold Cow Upgrade  
	gold_cow_upgrade = {
		id = "gold_cow_upgrade",
		name = "🥇 Gold Cow Upgrade",
		description = "Upgrade a silver cow to Gold tier! Brilliant golden glow with premium milk production.\n\n🥛 Production: 6 milk/minute\n⏰ Cooldown: 30 seconds\n✨ Visual: Golden glow + sparkles\n💎 Premium tier upgrade",
		price = 2500,
		currency = "coins",
		category = "farm",
		icon = "🥇",
		maxQuantity = 5,
		type = "cow_upgrade",
		requiresPurchase = "silver_cow_upgrade",
		cowData = {
			tier = "gold",
			milkAmount = 6,
			cooldown = 30,
			visualEffects = {"golden_glow", "gold_sparkles", "light_aura"},
			upgradeFrom = "silver"
		}
	},

	-- Diamond Cow Upgrade
	diamond_cow_upgrade = {
		id = "diamond_cow_upgrade", 
		name = "💎 Diamond Cow Upgrade",
		description = "Upgrade a gold cow to Diamond tier! Crystalline beauty with exceptional milk production.\n\n🥛 Production: 10 milk/minute\n⏰ Cooldown: 20 seconds\n✨ Visual: Diamond crystals + rainbow sparkles\n🏆 Elite tier upgrade",
		price = 5000,
		currency = "coins",
		category = "farm",
		icon = "💎",
		maxQuantity = 5,
		type = "cow_upgrade",
		requiresPurchase = "gold_cow_upgrade",
		cowData = {
			tier = "diamond",
			milkAmount = 10,
			cooldown = 20,
			visualEffects = {"diamond_crystals", "rainbow_sparkles", "prismatic_aura"},
			upgradeFrom = "gold"
		}
	},

	-- Rainbow Cow Upgrade
	rainbow_cow_upgrade = {
		id = "rainbow_cow_upgrade",
		name = "🌈 Rainbow Cow Upgrade", 
		description = "🏆 LEGENDARY UPGRADE 🏆\nTransform a diamond cow into a magical Rainbow Cow with incredible production!\n\n🥛 Production: 15 milk/minute\n⏰ Cooldown: 15 seconds\n✨ Visual: Shifting rainbow colors + magical aura\n🎉 Legendary tier!",
		price = 50,
		currency = "farmTokens",
		category = "farm",
		icon = "🌈",
		maxQuantity = 5,
		type = "cow_upgrade",
		requiresPurchase = "diamond_cow_upgrade",
		cowData = {
			tier = "rainbow",
			milkAmount = 15,
			cooldown = 15,
			visualEffects = {"rainbow_cycle", "magical_aura", "color_trails", "star_particles"},
			upgradeFrom = "diamond"
		}
	},

	-- Cosmic Cow Upgrade (Ultimate)
	cosmic_cow_upgrade = {
		id = "cosmic_cow_upgrade",
		name = "🌌 Cosmic Cow Upgrade",
		description = "🏆 ULTIMATE UPGRADE 🏆\nThe pinnacle of cow evolution! Cosmic powers with maximum milk production.\n\n🥛 Production: 25 milk/minute\n⏰ Cooldown: 10 seconds\n✨ Visual: Galaxy effects + cosmic energy\n👑 Ultimate tier - Maximum power!",
		price = 150,
		currency = "farmTokens", 
		category = "premium",
		icon = "🌌",
		maxQuantity = 3,
		type = "cow_upgrade",
		requiresPurchase = "rainbow_cow_upgrade",
		cowData = {
			tier = "cosmic",
			milkAmount = 25,
			cooldown = 10,
			visualEffects = {"galaxy_swirl", "cosmic_energy", "star_field", "nebula_clouds", "space_distortion"},
			upgradeFrom = "rainbow"
		}
	},

	-- Cow Management Tools
	cow_relocator = {
		id = "cow_relocator",
		name = "🚜 Cow Relocator",
		description = "Move your cows to better positions on your farm! Organize your dairy operation efficiently.\n\n🔧 Features:\n• Move any cow to new location\n• Reorganize farm layout\n• One-time use per cow\n• Works on all cow tiers",
		price = 100,
		currency = "coins",
		category = "farm",
		icon = "🚜",
		maxQuantity = 20,
		type = "tool"
	},

	cow_feed_premium = {
		id = "cow_feed_premium",
		name = "🌾 Premium Cow Feed",
		description = "High-quality feed that temporarily boosts milk production! Feed your cows for maximum efficiency.\n\n🚀 Benefits:\n• +50% milk production for 30 minutes\n• Works on all cow tiers\n• Stackable effect\n• One-time use",
		price = 50,
		currency = "coins",
		category = "farm",
		icon = "🌾",
		maxQuantity = 50,
		type = "enhancement"
	},

	auto_milker = {
		id = "auto_milker",
		name = "🤖 Auto Milker",
		description = "🏆 PREMIUM AUTOMATION 🏆\nAutomatically collects milk from ALL your cows every 30 seconds!\n\n🤖 Automation Features:\n• Collects from all cows automatically\n• Works 24/7\n• No manual clicking needed\n• Ultimate convenience upgrade",
		price = 200,
		currency = "farmTokens",
		category = "premium", 
		icon = "🤖",
		maxQuantity = 1,
		type = "automation"
	},

	-- Cow Capacity Upgrades
	pasture_expansion_1 = {
		id = "pasture_expansion_1",
		name = "🌿 Pasture Expansion I",
		description = "Expand your pasture to hold more cows! Increases maximum cow capacity.\n\n📈 Capacity: +2 cow slots\n🌿 Unlocks better grazing areas\n🏗️ Permanent upgrade\n📊 Total capacity: 7 cows",
		price = 2000,
		currency = "coins",
		category = "farm",
		icon = "🌿",
		maxQuantity = 1,
		type = "upgrade",
		effects = {
			maxCowIncrease = 2
		}
	},

	pasture_expansion_2 = {
		id = "pasture_expansion_2", 
		name = "🌿 Pasture Expansion II",
		description = "Further expand your dairy operation! Even more space for your growing herd.\n\n📈 Capacity: +3 cow slots\n🌿 Premium grazing areas\n🏗️ Permanent upgrade\n📊 Total capacity: 10 cows",
		price = 5000,
		currency = "coins",
		category = "farm",
		icon = "🌿",
		maxQuantity = 1,
		type = "upgrade",
		requiresPurchase = "pasture_expansion_1",
		effects = {
			maxCowIncrease = 3
		}
	},

	mega_pasture = {
		id = "mega_pasture",
		name = "🏆 Mega Pasture",
		description = "🏆 ULTIMATE EXPANSION 🏆\nThe largest possible dairy operation! Maximum cow capacity for serious farmers.\n\n📈 Capacity: +5 cow slots\n🌿 Luxury grazing areas\n🏗️ Permanent upgrade\n📊 Total capacity: 15 cows",
		price = 100,
		currency = "farmTokens",
		category = "premium",
		icon = "🏆", 
		maxQuantity = 1,
		type = "upgrade",
		requiresPurchase = "pasture_expansion_2",
		effects = {
			maxCowIncrease = 5
		}
	}
}


-- ========== RARITY FUNCTIONS ==========

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

-- ========== CROP AND SEED MAPPING ==========

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

-- ========== MINING SYSTEM HELPERS ==========

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

-- ========== VALIDATION ==========

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

-- ========== UTILITY ==========

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

print("✅ FIXED ItemConfig loaded with MINING SYSTEM DATA!")
print("📦 Total shop items: " .. (function() local count = 0; for _ in pairs(ItemConfig.ShopItems) do count = count + 1 end return count end)())
print("⛏️ Mining ores: " .. ItemConfig.CountOresByCategory())
print("🔨 Mining tools: " .. ItemConfig.CountToolsByCategory())
print("🎯 Categories:")
local counts = ItemConfig.CountItemsByCategory()
for category, count in pairs(counts) do
	print("  " .. category .. ": " .. count .. " items")
end
print("🌟 Rarity system: ACTIVE with 5 tiers")
print("🌱 Seed-to-crop mapping: COMPLETE")
print("⛏️ Mining system data: COMPLETE")

return ItemConfig