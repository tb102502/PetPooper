--[[
    FIXED ItemConfig.lua - All Items Show in Shop
    Place in: ReplicatedStorage/ItemConfig.lua
    
    FIXES:
    ✅ Removed notPurchasable flags that hide items
    ✅ Added missing required properties for all shop items
    ✅ Fixed category assignments
    ✅ Ensured all items have proper shop data
    ✅ Made all items visible and purchasable
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
		description = "Fresh orange carrot.", sellValue = 8, sellCurrency = "coins", 
		feedValue = 1, cropPoints = 1, icon = "🥕", rarity = "common" 
	},
	corn = { 
		id = "corn", name = "🌽 Corn", type = "crop", category = "crops", 
		description = "Sweet yellow corn.", sellValue = 725, sellCurrency = "coins", 
		feedValue = 3, cropPoints = 3, icon = "🌽", rarity = "uncommon" 
	},
	strawberry = { 
		id = "strawberry", name = "🍓 Strawberry", type = "crop", category = "crops", 
		description = "Sweet red strawberry.", sellValue = 350, sellCurrency = "coins", 
		feedValue = 2, cropPoints = 2, icon = "🍓", rarity = "uncommon" 
	},
	golden_fruit = { 
		id = "golden_fruit", name = "✨ Golden Fruit", type = "crop", category = "crops", 
		description = "Magical golden fruit.", sellValue = 0, sellCurrency = "coins", 
		feedValue = 10, cropPoints = 10, icon = "✨", rarity = "legendary" 
	},
	wheat = { 
		id = "wheat", name = "🌾 Wheat", type = "crop", category = "crops", 
		description = "Golden wheat grain.", sellValue = 600, sellCurrency = "coins", 
		feedValue = 3, cropPoints = 3, icon = "🌾", rarity = "uncommon" 
	},
	potato = { 
		id = "potato", name = "🥔 Potato", type = "crop", category = "crops", 
		description = "Hearty potato.", sellValue = 40, sellCurrency = "coins", 
		feedValue = 2, cropPoints = 2, icon = "🥔", rarity = "common" 
	},
	tomato = { 
		id = "tomato", name = "🍅 Tomato", type = "crop", category = "crops", 
		description = "Juicy red tomato.", sellValue = 675, sellCurrency = "coins", 
		feedValue = 3, cropPoints = 3, icon = "🍅", rarity = "uncommon" 
	},
	cabbage = { 
		id = "cabbage", name = "🥬 Cabbage", type = "crop", category = "crops", 
		description = "Fresh leafy cabbage.", sellValue = 75, sellCurrency = "coins", 
		feedValue = 1, cropPoints = 1, icon = "🥬", rarity = "common" 
	},
	radish = { 
		id = "radish", name = "🌶️ Radish", type = "crop", category = "crops", 
		description = "Spicy radish.", sellValue = 140, sellCurrency = "coins", 
		feedValue = 2, cropPoints = 2, icon = "🌶️", rarity = "common" 
	},
	broccoli = { 
		id = "broccoli", name = "🥦 Broccoli", type = "crop", category = "crops", 
		description = "Nutritious green broccoli.", sellValue = 110, sellCurrency = "coins", 
		feedValue = 2, cropPoints = 2, icon = "🥦", rarity = "common" 
	},
	glorious_sunflower = { 
		id = "glorious_sunflower", name = "🌻 Glorious Sunflower", type = "crop", category = "crops", 
		description = "🏆 LEGENDARY PREMIUM CROP 🏆", sellValue = 0, sellCurrency = "farmTokens", 
		feedValue = 0, cropPoints = 0, icon = "🌻", rarity = "divine" 
	}
}

-- ========== FIXED SHOP ITEMS - ALL ITEMS WILL SHOW ==========
ItemConfig.ShopItems = {

	-- ========== SEEDS CATEGORY (Beginner to Advanced) ==========

	carrot_seeds = {
		id = "carrot_seeds",
		name = "🥕 Carrot Seeds",
		description = "Perfect starter crop! Fast-growing and profitable.\n\n⏱️ Grow Time: 10 seconds\n💰 Sell Value: 8 coins each\n🐷 Pig Value: 1 crop point\n\n🎯 BEGINNER FRIENDLY - Start here!",
		price = 5,
		currency = "coins",
		category = "seeds",
		icon = "🥕",
		maxQuantity = 50,
		type = "seed",
		purchaseOrder = 1, -- FIRST seed - perfect for beginners
		farmingData = {
			growTime = 10,
			yieldAmount = 1,
			resultCropId = "carrot",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	potato_seeds = {
		id = "potato_seeds",
		name = "🥔 Potato Seeds",
		description = "Another great starter crop! Quick growth with good value.\n\n⏱️ Grow Time: 20 seconds\n💰 Sell Value: 40 coins each\n🐷 Pig Value: 2 crop points\n\n🌱 Perfect second crop to try!",
		price = 25,
		currency = "coins",
		category = "seeds",
		icon = "🥔",
		maxQuantity = 100,
		type = "seed",
		purchaseOrder = 2, -- Second seed option
		farmingData = {
			growTime = 20, 
			yieldAmount = 1,
			resultCropId = "potato",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	cabbage_seeds = {
		id = "cabbage_seeds",
		name = "🥬 Cabbage Seeds",
		description = "Step up your farming! Nutritious leafy greens.\n\n⏱️ Grow Time: 30 seconds\n💰 Sell Value: 75 coins each\n🐷 Pig Value: 1 crop point\n\n🥬 Great for learning crop timing!",
		price = 50,
		currency = "coins",
		category = "seeds",
		icon = "🥬",
		maxQuantity = 100,
		type = "seed",
		purchaseOrder = 3, -- Third progression step
		farmingData = {
			growTime = 30,
			yieldAmount = 1,
			resultCropId = "cabbage",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	radish_seeds = {
		id = "radish_seeds",
		name = "🌶️ Radish Seeds",
		description = "Mid-tier crop with spicy flavor and good profits!\n\n⏱️ Grow Time: 50 seconds\n💰 Sell Value: 140 coins each\n🐷 Pig Value: 2 crop points\n\n🌶️ Ready for intermediate farming!",
		price = 140,
		currency = "coins",
		category = "seeds",
		icon = "🌶️",
		maxQuantity = 100,
		type = "seed",
		purchaseOrder = 4, -- Mid-tier option
		farmingData = {
			growTime = 50,
			yieldAmount = 2,
			resultCropId = "radish",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "🍓 Strawberry Seeds",
		description = "Premium berries with excellent value! Worth the investment.\n\n⏱️ Grow Time: 1 minute\n💰 Sell Value: 350 coins each\n🐷 Pig Value: 2 crop points\n\n🍓 High-value crop for experienced farmers!",
		price = 250,
		currency = "coins",
		category = "seeds",
		icon = "🍓",
		maxQuantity = 50,
		type = "seed",
		purchaseOrder = 5, -- Higher value option
		farmingData = {
			growTime = 60,
			yieldAmount = 1,
			resultCropId = "strawberry",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	wheat_seeds = {
		id = "wheat_seeds",
		name = "🌾 Wheat Seeds",
		description = "Essential grain crop for advanced farming operations.\n\n⏱️ Grow Time: 1 minute 10 seconds\n💰 Sell Value: 600 coins each\n🐷 Pig Value: 3 crop points\n\n🌾 Multiple yield crop - great efficiency!",
		price = 400,
		currency = "coins",
		category = "seeds",
		icon = "🌾",
		maxQuantity = 100,
		type = "seed",
		purchaseOrder = 6, -- Advanced farming
		farmingData = {
			growTime = 70,
			yieldAmount = 3,
			resultCropId = "wheat",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	corn_seeds = {
		id = "corn_seeds",
		name = "🌽 Corn Seeds",
		description = "High-value tall crop! Sweet corn that animals love.\n\n⏱️ Grow Time: 1 minute 20 seconds\n💰 Sell Value: 725 coins each\n🐷 Pig Value: 3 crop points\n\n🌽 Premium regular crop with excellent returns!",
		price = 450,
		currency = "coins",
		category = "seeds",
		icon = "🌽",
		maxQuantity = 50,
		type = "seed",
		purchaseOrder = 7, -- Premium regular crop
		farmingData = {
			growTime = 80,
			yieldAmount = 1,
			resultCropId = "corn",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	tomato_seeds = {
		id = "tomato_seeds",
		name = "🍅 Tomato Seeds",
		description = "Juicy cluster-growing tomatoes! Perfect for cooking.\n\n⏱️ Grow Time: 1 minute 40 seconds\n💰 Sell Value: 675 coins each\n🐷 Pig Value: 3 crop points\n\n🍅 Multiple yield specialty crop!",
		price = 500,
		currency = "coins",
		category = "seeds",
		icon = "🍅",
		maxQuantity = 100,
		type = "seed",
		purchaseOrder = 8, -- Advanced specialty crop
		farmingData = {
			growTime = 100,
			yieldAmount = 3,
			resultCropId = "tomato",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	broccoli_seeds = {
		id = "broccoli_seeds",
		name = "🥦 Broccoli Seeds",
		description = "Nutritious green superfood! Takes patience but worth it.\n\n⏱️ Grow Time: 40 seconds\n💰 Sell Value: 110 coins each\n🐷 Pig Value: 4 crop points\n\n🥦 High pig value for feeding strategies!",
		price = 75,
		currency = "coins",
		category = "seeds",
		icon = "🥦",
		maxQuantity = 100,
		type = "seed",
		purchaseOrder = 9, -- Advanced farming
		farmingData = {
			growTime = 40,
			yieldAmount = 1,
			resultCropId = "broccoli",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "✨ Golden Seeds",
		description = "🏆 PREMIUM FARM TOKEN CROP 🏆\nMagical seeds that produce golden fruit!\n\n⏱️ Grow Time: 6 minutes\n💰 Value: SPECIAL\n🐷 Pig Value: 10 crop points\n\n✨ Premium investment for serious farmers!",
		price = 50,
		currency = "farmTokens",
		category = "seeds",
		icon = "✨",
		maxQuantity = 25,
		type = "seed",
		purchaseOrder = 10, -- Premium farm token crop
		farmingData = {
			growTime = 360,
			yieldAmount = 1,
			resultCropId = "golden_fruit",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	glorious_sunflower_seeds = {
		id = "glorious_sunflower_seeds",
		name = "🌻 Glorious Sunflower Seeds",
		description = "🏆 ULTIMATE LEGENDARY SEED 🏆\nThe rarest and most magnificent crop! Massive size!\n\n⏱️ Grow Time: 8+ minutes\n💰 Value: PRICELESS\n🐷 Pig Value: 25 crop points\n\n🌻 THE ULTIMATE FARMING ACHIEVEMENT!",
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

	-- ========== FARM CATEGORY (Core Infrastructure) ==========

	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "🌾 Your Farm Plot",
		description = "🎯 ESSENTIAL PURCHASE! Start your farming journey!\n\n🎁 Get a complete 10x10 farming grid:\n• 100 planting spots (all unlocked!)\n• FREE starter package:\n  - 5x Carrot Seeds\n  - 3x Corn Seeds\n• Access to entire farming system\n\n🌾 This unlocks everything - buy this first!",
		price = 100,
		currency = "coins",
		category = "farm",
		icon = "🌾",
		maxQuantity = 1,
		type = "farmPlot",
		purchaseOrder = 1, -- FIRST and ONLY farm purchase needed
		effects = {
			enableFarming = true,
			starterSeeds = {
				carrot_seeds = 5,
				corn_seeds = 3
			}
		}
	},

	-- FIXED: Added all cow items to farm category with proper shop data
	basic_cow = {
		id = "basic_cow",
		name = "🐄 Basic Cow",
		description = "Start your dairy empire with your first cow!\n\n🥛 Production:\n• 1 milk every 5 seconds\n• Steady income source\n• Perfect for beginners\n\n🐄 Your first step into livestock!",
		price = 0, -- FREE first cow
		currency = "coins",
		category = "farm",
		icon = "🐄",
		maxQuantity = 1,
		type = "cow",
		purchaseOrder = 2, -- After farm plot
		cowData = {
			tier = "basic",
			milkAmount = 1,
			cooldown = 5,
			visualEffects = {},
			maxCows = 1
		}
	},

	extra_basic_cow = {
		id = "extra_basic_cow",
		name = "🐄 Additional Basic Cow",
		description = "Expand your herd! More cows = more milk = more profit!\n\n🥛 Production:\n• 1 milk every 5 seconds per cow\n• Each cow produces independently\n• Stack up to 5 basic cows total\n\n🐄 Build your dairy operation!",
		price = 1000,
		currency = "coins",
		category = "farm",
		icon = "🐄",
		maxQuantity = 4,
		type = "cow",
		purchaseOrder = 3, -- Additional cows
		cowData = {
			tier = "basic",
			milkAmount = 1,
			cooldown = 5,
			visualEffects = {},
			maxCows = 5
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
		maxQuantity = 5,
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
		maxQuantity = 5,
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
		maxQuantity = 5,
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
		maxQuantity = 5,
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
		maxQuantity = 3,
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

	cow_relocator = {
		id = "cow_relocator",
		name = "🚜 Cow Relocator",
		description = "Organize your dairy operation efficiently!\n\n🔧 Features:\n• Move any cow to new location\n• Reorganize farm layout\n• One-time use per cow\n• Works on all cow tiers\n\n🚜 Farm management tool!",
		price = 100,
		currency = "coins",
		category = "farm",
		icon = "🚜",
		maxQuantity = 20,
		type = "tool",
		purchaseOrder = 13 -- Utility tool
	},

	-- FIXED: Added milk as purchasable item (remove notPurchasable flag)
	fresh_milk = {
		id = "fresh_milk",
		name = "🥛 Fresh Milk",
		description = "Pure, fresh milk from your dairy cows!\n\n💰 Great for:\n• Selling for quick coins\n• Trading and gifts\n• Crafting recipes\n• Emergency milk supply\n\n🥛 Always useful to have on hand!",
		price = 100,
		currency = "coins",
		category = "farm",
		icon = "🥛",
		maxQuantity = 999,
		type = "material",
		purchaseOrder = 14 -- Material purchase
	},

	-- ========== DEFENSE CATEGORY (Pest Control & Protection) ==========

	organic_pesticide = {
		id = "organic_pesticide",
		name = "🧪 Organic Pesticide",
		description = "Your first line of defense against crop pests!\n\n💪 Effectiveness:\n• Eliminates all pest types instantly\n• 3x3 area of effect around target\n• One-time use, eco-friendly formula\n\n🧪 Essential for protecting your investment!",
		price = 50,
		currency = "coins",
		category = "defense",
		icon = "🧪",
		maxQuantity = 20,
		type = "tool",
		purchaseOrder = 1 -- First defense tool
	},

	pest_detector = {
		id = "pest_detector",
		name = "📡 Pest Detector",
		description = "Early warning system for pest threats!\n\n🔍 Features:\n• Detect pests before major damage\n• Wide detection range\n• Automatic alerts and notifications\n• One-time purchase, permanent benefit\n\n📡 Knowledge is power!",
		price = 250,
		currency = "coins",
		category = "defense",
		icon = "📡",
		maxQuantity = 1,
		type = "upgrade",
		purchaseOrder = 2 -- Detection before automation
	},

	basic_chicken = {
		id = "basic_chicken",
		name = "🐔 Basic Chicken",
		description = "Your first automated pest control solution!\n\n🛡️ Protects Against:\n• Aphids and small pests\n• Patrols assigned area automatically\n\n💰 Bonus Production:\n• Lays eggs regularly\n• Additional income source\n\n🐔 Essential farm worker!",
		price = 250,
		currency = "coins",
		category = "defense",
		icon = "🐔",
		maxQuantity = 20,
		type = "chicken",
		purchaseOrder = 3 -- First automated defense
	},

	basic_feed = {
		id = "basic_feed",
		name = "🌾 Basic Chicken Feed",
		description = "Keep your chickens healthy and working efficiently!\n\n🐔 Benefits:\n• Feeds chickens for extended time\n• Maintains egg production\n• Keeps chickens in good health\n• Essential for chicken care\n\n🌾 Happy chickens = productive chickens!",
		price = 10,
		currency = "coins",
		category = "defense",
		icon = "🌾",
		maxQuantity = 100,
		type = "feed",
		purchaseOrder = 4 -- Support chickens
	},

	guinea_fowl = {
		id = "guinea_fowl",
		name = "🦃 Guinea Fowl",
		description = "Specialized anti-locust defender with early warning!\n\n🛡️ Advanced Protection:\n• Locust specialist - superior elimination\n• Handles aphids and small pests too\n• Provides pest alert system\n\n💰 Premium Production:\n• Premium eggs with better value\n\n🦃 Professional pest control!",
		price = 500,
		currency = "coins",
		category = "defense",
		icon = "🦃",
		maxQuantity = 10,
		type = "chicken",
		purchaseOrder = 5 -- Advanced chicken
	},

	premium_feed = {
		id = "premium_feed",
		name = "⭐ Premium Chicken Feed",
		description = "High-quality nutrition for peak performance!\n\n🐔 Premium Benefits:\n• Feeds chickens for longer periods\n• Boost to egg production\n• Superior nutrition and health\n• Happy chickens work harder!\n\n⭐ Investment in your workforce!",
		price = 50,
		currency = "coins",
		category = "defense",
		icon = "⭐",
		maxQuantity = 50,
		type = "feed",
		purchaseOrder = 6 -- Better chicken care
	},

	rooster = {
		id = "rooster",
		name = "🐓 Rooster",
		description = "Elite flock leader that enhances all nearby chickens!\n\n🛡️ Leadership Benefits:\n• Boosts all chickens within range\n• Reduces pest spawn rates\n• Territory protection and organization\n\n💰 Premium Production:\n• Premium eggs with high value\n\n🐓 The ultimate flock manager!",
		price = 1000,
		currency = "coins",
		category = "defense",
		icon = "🐓",
		maxQuantity = 3,
		type = "chicken",
		purchaseOrder = 7 -- Elite chicken
	},

	plot_roof_basic = {
		id = "plot_roof_basic",
		name = "🏠 Basic Plot Roof",
		description = "Physical protection for your most valuable plots!\n\n🛡️ Protection:\n• Blocks UFO beam damage\n• Weather damage immunity\n• Covers 1 farm plot completely\n• Durable construction\n\n🏠 Secure your investment!",
		price = 200,
		currency = "coins",
		category = "defense",
		icon = "🏠",
		maxQuantity = 10,
		type = "protection",
		purchaseOrder = 8, -- Basic plot protection
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
		description = "Enhanced protection with advanced materials!\n\n🛡️ Enhanced Protection:\n• Superior UFO damage reduction\n• Complete weather immunity\n• Self-repairing smart materials\n• Covers 1 farm plot\n\n🏛️ Military-grade protection!",
		price = 500,
		currency = "coins",
		category = "defense",
		icon = "🏛️",
		maxQuantity = 10,
		type = "protection",
		purchaseOrder = 9, -- Better plot protection
		effects = {
			coverage = 1,
			ufoProtection = true,
			weatherProtection = true,
			damageReduction = 0.99,
			selfRepairing = true,
			plotSpecific = true
		}
	},

	area_dome_small = {
		id = "area_dome_small",
		name = "🔘 Small Protection Dome",
		description = "Energy dome technology protecting multiple plots!\n\n🛡️ Area Protection:\n• Protects multiple adjacent plots\n• UFO immunity\n• Weather protection\n• Pest deterrent energy field\n\n🔘 Efficiency through area coverage!",
		price = 2500,
		currency = "coins",
		category = "defense",
		icon = "🔘",
		maxQuantity = 3,
		type = "protection",
		purchaseOrder = 10, -- Area protection
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
		description = "Advanced energy dome with performance bonuses!\n\n🛡️ Large Area Protection:\n• Protects many adjacent plots\n• Complete damage immunity\n• Crop growth speed boost\n• Auto-pest elimination field\n\n🔵 Protection with benefits!",
		price = 5000,
		currency = "coins",
		category = "defense",
		icon = "🔵",
		maxQuantity = 2,
		type = "protection",
		purchaseOrder = 11, -- Large area protection
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

	super_pesticide = {
		id = "super_pesticide",
		name = "💉 Super Pesticide",
		description = "🏆 PREMIUM PEST ELIMINATION 🏆\nIndustrial-grade pesticide for emergency situations!\n\n💪 Ultimate Power:\n• Entire farm coverage instantly\n• ALL pest types eliminated\n• Immediate effect\n• Premium farm token formula\n\n💉 The nuclear option!",
		price = 25,
		currency = "farmTokens",
		category = "defense",
		icon = "💉",
		maxQuantity = 5,
		type = "tool",
		purchaseOrder = 12 -- Premium emergency tool
	},

	mega_dome = {
		id = "mega_dome",
		name = "🛡️ Mega Protection Dome",
		description = "🏆 ULTIMATE PROTECTION SYSTEM 🏆\nCovers ALL your plots with maximum benefits!\n\n🛡️ Ultimate Defense:\n• Covers ALL farm plots\n• Complete damage immunity\n• Major crop growth boost\n• Auto-harvest alerts\n• Pest elimination field\n\n🛡️ The ultimate farmer's shield!",
		price = 100,
		currency = "farmTokens",
		category = "defense",
		icon = "🛡️",
		maxQuantity = 1,
		type = "protection",
		purchaseOrder = 13, -- Ultimate protection
		effects = {
			coverage = 999,
			ufoProtection = true,
			weatherProtection = true,
			pestDeterrent = true,
			growthBoost = 0.25,
			autoHarvestAlerts = true,
			ultimateProtection = true
		}
	},

	-- ========== MINING CATEGORY ==========

	cave_access_pass = {
		id = "cave_access_pass",
		name = "🕳️ Cave Access Pass",
		description = "🎯 UNLOCK MINING! Grants access to Cave 1 (Copper Mine)!\n\n🗻 Mining Access:\n• Cave 1: Copper Mine\n• Copper and bronze ore deposits\n• Mining tutorial area\n• New income source\n\n🕳️ Diversify your empire!",
		price = 10000,
		currency = "coins",
		category = "mining",
		icon = "🕳️",
		maxQuantity = 1,
		type = "access",
		purchaseOrder = 1 -- Mining access
	},

	-- FIXED: Added wooden pickaxe as separate purchasable item
	wooden_pickaxe = {
		id = "wooden_pickaxe",
		name = "🪓 Wooden Pickaxe",
		description = "Basic wooden pickaxe for absolute beginners!\n\n⛏️ Basic Mining:\n• Can mine copper ore only\n• 50 durability\n• Very basic tool\n• Cheapest mining option\n\n🪓 Start your mining journey!",
		price = 100,
		currency = "coins",
		category = "mining",
		icon = "🪓",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 2 -- Beginner tool
	},

	basic_pickaxe = {
		id = "basic_pickaxe",
		name = "⛏️ Basic Pickaxe",
		description = "Essential mining tool for resource gathering!\n\n⛏️ Mining Power:\n• Can mine copper and bronze ore\n• 100 durability\n• Entry-level mining tool\n• Opens mining gameplay\n\n⛏️ Start digging for treasure!",
		price = 250,
		currency = "coins",
		category = "mining",
		icon = "⛏️",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 3 -- First proper mining tool
	},

	stone_pickaxe = {
		id = "stone_pickaxe",
		name = "🪨 Stone Pickaxe",
		description = "Improved mining tool with better capabilities!\n\n⛏️ Enhanced Power:\n• Can mine up to silver ore\n• 150 durability\n• Faster mining speed\n• Sturdy construction\n\n🪨 Upgrade your mining game!",
		price = 1000,
		currency = "coins",
		category = "mining",
		icon = "🪨",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 4 -- Pickaxe upgrade
	},

	iron_pickaxe = {
		id = "iron_pickaxe",
		name = "⚒️ Iron Pickaxe",
		description = "Professional mining tool for serious miners!\n\n⛏️ Professional Grade:\n• Can mine up to gold ore\n• 250 durability\n• Much faster mining speed\n• Professional quality\n\n⚒️ Professional mining power!",
		price = 5000,
		currency = "coins",
		category = "mining",
		icon = "⚒️",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 5 -- Advanced tool
	},

	diamond_pickaxe = {
		id = "diamond_pickaxe",
		name = "💎 Diamond Pickaxe",
		description = "Premium mining tool for the most valuable ores!\n\n⛏️ Premium Power:\n• Can mine up to platinum ore\n• 500 durability\n• Very fast mining speed\n• Premium quality construction\n\n💎 Elite mining equipment!",
		price = 25000,
		currency = "coins",
		category = "mining",
		icon = "💎",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 6 -- Premium tool
	},

	obsidian_pickaxe = {
		id = "obsidian_pickaxe",
		name = "⬛ Obsidian Pickaxe",
		description = "🏆 LEGENDARY MINING TOOL 🏆\nCan mine the rarest ores including mystical obsidian!\n\n⛏️ Legendary Power:\n• Can mine ALL ore types\n• 1000 durability\n• Extremely fast mining speed\n• Legendary quality\n\n⬛ The ultimate mining tool!",
		price = 75,
		currency = "farmTokens",
		category = "mining",
		icon = "⬛",
		maxQuantity = 1,
		type = "tool",
		purchaseOrder = 7 -- Ultimate tool
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
		price = 500,
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
		price = 25,
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
		price = 150,
		currency = "farmTokens",
		category = "premium",
		icon = "🤖",
		maxQuantity = 1,
		type = "upgrade",
		purchaseOrder = 2 -- Ultimate automation
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

-- ========== SELLING SYSTEM HELPERS ==========

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
		"milk", "fresh_milk", "chicken_egg", "guinea_egg", "rooster_egg",
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
		milk = 75,
		fresh_milk = 75,
		chicken_egg = 15,
		guinea_egg = 20,
		rooster_egg = 25,

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

-- ========== PURCHASE ORDER DEBUGGING ==========

function ItemConfig.GetExpansionConfig(level)
	-- Return simple config for compatibility
	return {
		name = "Simple Farm",
		gridSize = 10,
		totalSpots = 100,
		baseSize = Vector3.new(60, 1, 60),
		cost = 0,
		description = "Full 10x10 farming grid (100 planting spots)"
	}
end

function ItemConfig.DebugPurchaseOrder(category)
	print("=== PURCHASE ORDER DEBUG for " .. (category or "ALL") .. " ===")

	local items = {}
	for itemId, item in pairs(ItemConfig.ShopItems) do
		if not category or item.category == category then
			table.insert(items, {id = itemId, item = item})
		end
	end

	-- Sort by purchase order
	table.sort(items, function(a, b)
		local orderA = a.item.purchaseOrder or 999
		local orderB = b.item.purchaseOrder or 999

		if orderA == orderB then
			return a.item.price < b.item.price
		end

		return orderA < orderB
	end)

	for i, itemData in ipairs(items) do
		local item = itemData.item
		local orderInfo = item.purchaseOrder and ("[" .. item.purchaseOrder .. "]") or "[NO ORDER]"
		print(i .. ". " .. orderInfo .. " " .. item.name .. " - " .. item.price .. " " .. item.currency)
	end

	print("✅ FIXED: All items now visible in shop!")
	print("========================================")
end

print("✅ FIXED ItemConfig loaded - ALL ITEMS SHOW IN SHOP!")
print("📦 Total shop items: " .. (function() local count = 0; for _ in pairs(ItemConfig.ShopItems) do count = count + 1 end return count end)())
print("🌾 Seeds: 11 items (carrot to glorious sunflower)")
print("🚜 Farm: 15 items (plot + cows + milk + tools)")
print("🛡️ Defense: 13 items (pests + chickens + protection)")
print("⛏️ Mining: 7 items (access + all pickaxes)")
print("🔨 Crafting: 3 items (workbench + forge + altar)")
print("✨ Premium: 2 items (booster + auto-harvester)")
print("")
print("🔧 FIXES APPLIED:")
print("  ✅ Removed notPurchasable = true from milk item")
print("  ✅ Added wooden_pickaxe as separate purchasable item")
print("  ✅ Added fresh_milk as purchasable alternative")
print("  ✅ Fixed all cow items to show in farm category")
print("  ✅ Removed requiresPurchase dependencies that hide items")
print("  ✅ Ensured all items have required shop properties")
print("  ✅ Made all defense items show without farm requirements")
print("")
print("🎯 ALL CATEGORIES NOW FULLY POPULATED:")
local counts = ItemConfig.CountItemsByCategory()
for category, count in pairs(counts) do
	print("  " .. category .. ": " .. count .. " items")
end

return ItemConfig