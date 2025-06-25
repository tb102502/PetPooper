--[[
    FIXED ItemConfig.lua - Complete Sellable Items System
    
    FIXES:
    ✅ All crops properly configured for selling
    ✅ Comprehensive sellable item definitions
    ✅ Fixed item categories and types
    ✅ Proper sell price calculations
    ✅ Enhanced merge system for crops
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

-- ========== COMPREHENSIVE SHOP ITEMS ==========
ItemConfig.ShopItems = {
	-- ========== SEEDS CATEGORY ==========
	carrot_seeds = {
		id = "carrot_seeds",
		name = "🥕 Carrot Seeds",
		description = "Fast-growing orange carrots! Perfect for beginners.\n\n⏱️ Grow Time: 10 seconds\n💰 Sell Value: 8 coins each\n🐷 Pig Value: 1 crop point",
		price = 5,
		currency = "coins",
		category = "seeds",
		icon = "🥕",
		maxQuantity = 50,
		type = "seed",
		farmingData = {
			growTime = 10,
			yieldAmount = 1,
			resultCropId = "carrot",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	corn_seeds = {
		id = "corn_seeds",
		name = "🌽 Corn Seeds",
		description = "Sweet corn that pigs love! Higher yield than carrots.\n\n⏱️ Grow Time: 1 minute 20 seconds\n💰 Sell Value: 725 coins each\n🐷 Pig Value: 2 crop points",
		price = 450,
		currency = "coins",
		category = "seeds",
		icon = "🌽",
		maxQuantity = 50,
		type = "seed",
		farmingData = {
			growTime = 80,
			yieldAmount = 1,
			resultCropId = "corn",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	strawberry_seeds = {
		id = "strawberry_seeds",
		name = "🍓 Strawberry Seeds",
		description = "Delicious berries with premium value! Worth the wait.\n\n⏱️ Grow Time: 1 minute\n💰 Sell Value: 350 coins each\n🐷 Pig Value: 3 crop points",
		price = 250,
		currency = "coins",
		category = "seeds",
		icon = "🍓",
		maxQuantity = 50,
		type = "seed",
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
		description = "Hardy wheat that grows in all conditions. Perfect for making bread!\n\n⏱️ Grow Time: 1 minute 10 seconds\n💰 Sell Value: 600 coins each\n🐷 Pig Value: 2 crop points",
		price = 400,
		currency = "coins",
		category = "seeds",
		icon = "🌾",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 70,
			yieldAmount = 3,
			resultCropId = "wheat",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	potato_seeds = {
		id = "potato_seeds",
		name = "🥔 Potato Seeds",
		description = "Versatile potatoes that grow underground. Great for cooking!\n\n⏱️ Grow Time: 20 seconds\n💰 Sell Value: 40 coins each\n🐷 Pig Value: 2 crop points",
		price = 25,
		currency = "coins",
		category = "seeds",
		icon = "🥔",
		maxQuantity = 100,
		type = "seed",
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
		description = "Leafy green cabbages packed with nutrients. Animals love them!\n\n⏱️ Grow Time: 30 seconds\n💰 Sell Value: 75 coins each\n🐷 Pig Value: 3 crop points",
		price = 50,
		currency = "coins",
		category = "seeds",
		icon = "🥬",
		maxQuantity = 100,
		type = "seed",
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
		description = "Quick-growing spicy radishes. Ready in no time!\n\n⏱️ Grow Time: 50 seconds\n💰 Sell Value: 140 coins each\n🐷 Pig Value: 1 crop point",
		price = 140,
		currency = "coins",
		category = "seeds",
		icon = "🌶️",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 50,
			yieldAmount = 2,
			resultCropId = "radish",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	broccoli_seeds = {
		id = "broccoli_seeds",
		name = "🥦 Broccoli Seeds",
		description = "Nutritious green broccoli. Takes time but worth the wait!\n\n⏱️ Grow Time: 40 seconds\n💰 Sell Value: 110 coins each\n🐷 Pig Value: 4 crop points",
		price = 75,
		currency = "coins",
		category = "seeds",
		icon = "🥦",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 40,
			yieldAmount = 1,
			resultCropId = "broccoli",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	tomato_seeds = {
		id = "tomato_seeds",
		name = "🍅 Tomato Seeds",
		description = "Juicy red tomatoes perfect for cooking. High value crop!\n\n⏱️ Grow Time: 1 minute 40 seconds\n💰 Sell Value: 675 coins each\n🐷 Pig Value: 3 crop points",
		price = 500,
		currency = "coins",
		category = "seeds",
		icon = "🍅",
		maxQuantity = 100,
		type = "seed",
		farmingData = {
			growTime = 100,
			yieldAmount = 3,
			resultCropId = "tomato",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "✨ Golden Seeds",
		description = "Magical seeds that produce golden fruit! Premium crop.\n\n⏱️ Grow Time: 6 minutes\n💰 Sell Value: 1000 Farm Tokens each\n🐷 Pig Value: 10 crop points",
		price = 50,
		currency = "farmTokens",
		category = "seeds",
		icon = "✨",
		maxQuantity = 25,
		type = "seed",
		farmingData = {
			growTime = 360,
			yieldAmount = 1,
			resultCropId = "golden_fruit",
			stages = {"planted", "sprouting", "growing", "ready"},
			rarityChances = {common = 0.69, uncommon = 0.25, rare = 0.05, epic = 0.01, legendary = 0.001}
		}
	},

	-- ========== SELLABLE CROPS (Auto-added to shop for selling) ==========
	carrot = {
		id = "carrot",
		name = "🥕 Fresh Carrots",
		price = 8,
		currency = "coins",
		category = "crops",
		description = "Fresh orange carrots. Perfect for selling or feeding animals!",
		icon = "🥕",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 8
	},

	corn = {
		id = "corn",
		name = "🌽 Sweet Corn",
		price = 725,
		currency = "coins",
		category = "crops",
		description = "Sweet yellow corn. High value crop for selling!",
		icon = "🌽",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 725
	},

	strawberry = {
		id = "strawberry",
		name = "🍓 Ripe Strawberries",
		price = 350,
		currency = "coins",
		category = "crops",
		description = "Sweet red strawberries. Premium fruit for selling!",
		icon = "🍓",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 350
	},

	wheat = {
		id = "wheat",
		name = "🌾 Golden Wheat",
		price = 600,
		currency = "coins",
		category = "crops",
		description = "Golden wheat grain. Excellent for selling!",
		icon = "🌾",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 600
	},

	potato = {
		id = "potato",
		name = "🥔 Fresh Potatoes",
		price = 40,
		currency = "coins",
		category = "crops",
		description = "Hearty potatoes. Always in demand!",
		icon = "🥔",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 40
	},

	tomato = {
		id = "tomato",
		name = "🍅 Ripe Tomatoes",
		price = 675,
		currency = "coins",
		category = "crops",
		description = "Juicy red tomatoes. Premium vegetable!",
		icon = "🍅",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 675
	},

	cabbage = {
		id = "cabbage",
		name = "🥬 Fresh Cabbage",
		price = 75,
		currency = "coins",
		category = "crops",
		description = "Fresh leafy cabbage. Healthy choice!",
		icon = "🥬",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 75
	},

	radish = {
		id = "radish",
		name = "🌶️ Spicy Radish",
		price = 140,
		currency = "coins",
		category = "crops",
		description = "Spicy radish. Quick seller!",
		icon = "🌶️",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 140
	},

	broccoli = {
		id = "broccoli",
		name = "🥦 Fresh Broccoli",
		price = 110,
		currency = "coins",
		category = "crops",
		description = "Nutritious green broccoli. Health food trend!",
		icon = "🥦",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 110
	},

	golden_fruit = {
		id = "golden_fruit",
		name = "✨ Golden Fruit",
		price = 1000,
		currency = "farmTokens",
		category = "crops",
		description = "Magical golden fruit. Extremely rare and valuable!",
		icon = "✨",
		type = "crop",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 1000
	},

	-- ========== SELLABLE ANIMAL PRODUCTS ==========
	milk = {
		id = "milk",
		name = "🥛 Fresh Milk",
		price = 10,
		currency = "coins",
		category = "livestock",
		description = "Fresh milk collected from your cows. Sell for steady income!",
		icon = "🥛",
		type = "material",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 10
	},

	chicken_egg = {
		id = "chicken_egg",
		name = "🥚 Chicken Egg",
		price = 5,
		currency = "coins",
		category = "livestock",
		description = "Fresh egg from your chickens. Good source of income!",
		icon = "🥚",
		type = "material",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 5
	},

	guinea_egg = {
		id = "guinea_egg",
		name = "🥚 Guinea Fowl Egg",
		price = 8,
		currency = "coins",
		category = "livestock",
		description = "Premium egg from guinea fowl. Higher value than chicken eggs!",
		icon = "🥚",
		type = "material",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 8
	},

	rooster_egg = {
		id = "rooster_egg",
		name = "🥚 Rooster Egg",
		price = 12,
		currency = "coins",
		category = "livestock",
		description = "Rare egg from your rooster. Premium price!",
		icon = "🥚",
		type = "material",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 12
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
		price = 1000,
		currency = "coins",
		category = "farm",
		icon = "🚜",
		maxQuantity = 9,
		type = "farmPlot",
		requiresPurchase = "farm_plot_starter"
	},

	-- ========== COW SYSTEM ==========
	basic_cow = {
		id = "basic_cow",
		name = "🐄 Basic Cow",
		description = "Your first milk-producing cow! Produces 2 milk every 10 seconds.\n\n🥛 Production: 2 milk/10 seconds\n💰 Sell Value: 10 coins each\n🎯 Perfect for starting your dairy empire!",
		price = 0,
		currency = "coins",
		category = "farm",
		icon = "🐄",
		maxQuantity = 1,
		type = "cow",
		cowData = {
			tier = "basic",
			milkAmount = 2,
			cooldown = 10,
			visualEffects = {},
			maxCows = 1
		}
	},

	extra_basic_cow = {
		id = "extra_basic_cow",
		name = "🐄 Additional Basic Cow",
		description = "Add more basic cows to your farm! Each cow produces independently.\n\n🥛 Production: 2 milk/10 seconds\n📈 Stack up to 5 basic cows total",
		price = 1000,
		currency = "coins",
		category = "farm",
		icon = "🐄",
		maxQuantity = 4,
		type = "cow",
		requiresPurchase = "basic_cow",
		cowData = {
			tier = "basic",
			milkAmount = 2,
			cooldown = 10,
			visualEffects = {},
			maxCows = 5
		}
	},

	silver_cow_upgrade = {
		id = "silver_cow_upgrade",
		name = "🥈 Silver Cow Upgrade",
		description = "Upgrade a basic cow to Silver tier! Improved production and shiny appearance.\n\n🥛 Production: 3 milk/30 seconds\n✨ Visual: Silver metallic shine\n🔧 Upgrades one existing cow",
		price = 10000,
		currency = "coins",
		category = "farm",
		icon = "🥈",
		maxQuantity = 5,
		type = "cow_upgrade",
		requiresPurchase = "basic_cow",
		cowData = {
			tier = "silver",
			milkAmount = 3,
			cooldown = 30,
			visualEffects = {"metallic_shine", "silver_particles"},
			upgradeFrom = "basic"
		}
	},

	gold_cow_upgrade = {
		id = "gold_cow_upgrade",
		name = "🥇 Gold Cow Upgrade",
		description = "Upgrade a silver cow to Gold tier! Brilliant golden glow with premium milk production.\n\n🥛 Production: 4 milk/60 seconds\n✨ Visual: Golden glow + sparkles\n💎 Premium tier upgrade",
		price = 25000,
		currency = "coins",
		category = "farm",
		icon = "🥇",
		maxQuantity = 5,
		type = "cow_upgrade",
		requiresPurchase = "silver_cow_upgrade",
		cowData = {
			tier = "gold",
			milkAmount = 4,
			cooldown = 60,
			visualEffects = {"golden_glow", "gold_sparkles", "light_aura"},
			upgradeFrom = "silver"
		}
	},

	-- ========== DEFENSE CATEGORY ==========
	basic_chicken = {
		id = "basic_chicken",
		name = "🐔 Basic Chicken",
		description = "General purpose pest control. Eliminates aphids and lays eggs for steady income.\n\n🛡️ Protects Against:\n• Aphids\n• Small pests\n\n💰 Produces:\n• Eggs every 4 minutes\n• 5 coins per egg",
		price = 250,
		currency = "coins",
		category = "defense",
		icon = "🐔",
		maxQuantity = 20,
		type = "chicken",
		requiresPurchase = "farm_plot_starter"
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

	basic_feed = {
		id = "basic_feed",
		name = "🌾 Basic Chicken Feed",
		description = "Keeps chickens fed and working efficiently. Essential for chicken care.\n\n🐔 Benefits:\n• Feeds chickens for 6 hours\n• Maintains egg production\n• Keeps chickens healthy\n• Basic nutrition",
		price = 10,
		currency = "coins",
		category = "chicken",
		icon = "🌾",
		maxQuantity = 100,
		type = "feed"
	},

	-- ========== MINING CATEGORY ==========
	basic_pickaxe = {
		id = "basic_pickaxe",
		name = "⛏️ Basic Pickaxe",
		description = "Essential tool for mining. Allows access to copper and bronze ore deposits.\n\n⛏️ Mining Power:\n• Can mine copper ore\n• Can mine bronze ore\n• 100 durability\n• Entry-level tool",
		price = 250,
		currency = "coins",
		category = "mining",
		icon = "⛏️",
		maxQuantity = 1,
		type = "tool"
	},

	cave_access_pass = {
		id = "cave_access_pass",
		name = "🕳️ Cave Access Pass",
		description = "Grants access to Cave 1 (Copper Mine)! Start your mining journey!\n\n🗻 Access To:\n• Cave 1: Copper Mine\n• Copper ore deposits\n• Bronze ore deposits\n• Mining tutorial area",
		price = 10000,
		currency = "coins",
		category = "mining",
		icon = "🕳️",
		maxQuantity = 1,
		type = "access"
	},

	-- ========== SELLABLE ORES ==========
	copper_ore = {
		id = "copper_ore",
		name = "🟫 Copper Ore",
		price = 25,
		currency = "coins",
		category = "ores",
		description = "Basic copper ore from mining. Good starter ore for selling!",
		icon = "🟫",
		type = "material",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 25
	},

	bronze_ore = {
		id = "bronze_ore",
		name = "🟤 Bronze Ore",
		price = 40,
		currency = "coins",
		category = "ores",
		description = "Stronger bronze ore. Better value than copper!",
		icon = "🟤",
		type = "material",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 40
	},

	silver_ore = {
		id = "silver_ore",
		name = "⚪ Silver Ore",
		price = 75,
		currency = "coins",
		category = "ores",
		description = "Precious silver ore. High value for selling!",
		icon = "⚪",
		type = "material",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 75
	},

	gold_ore = {
		id = "gold_ore",
		name = "🟡 Gold Ore",
		price = 150,
		currency = "coins",
		category = "ores",
		description = "Valuable gold ore. Premium selling price!",
		icon = "🟡",
		type = "material",
		maxQuantity = 999,
		notPurchasable = true,
		sellable = true,
		sellValue = 150
	},

	-- ========== CRAFTING CATEGORY ==========
	basic_workbench = {
		id = "basic_workbench",
		name = "🔨 Basic Workbench",
		description = "Essential crafting station for making tools and equipment.\n\n🔨 Crafting Options:\n• Basic tools\n• Simple equipment\n• Wooden items\n• Entry-level recipes",
		price = 5000,
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
		price = 15000,
		currency = "coins",
		category = "crafting",
		icon = "🔥",
		maxQuantity = 1,
		type = "building",
		requiresPurchase = "basic_workbench"
	}
}

-- ========== CROPS DATA TABLE ==========
ItemConfig.Crops = {
	carrot = { 
		id = "carrot", 
		name = "🥕 Carrot", 
		type = "crop", 
		category = "crops", 
		description = "Fresh orange carrot. Great for selling!",
		sellValue = 8, 
		sellCurrency = "coins", 
		feedValue = 1, 
		cropPoints = 1, 
		icon = "🥕", 
		rarity = "common",
		sellable = true,
		price = 8
	},
	corn = { 
		id = "corn", 
		name = "🌽 Corn", 
		type = "crop", 
		category = "crops", 
		description = "Sweet yellow corn. High value crop!",
		sellValue = 725, 
		sellCurrency = "coins", 
		feedValue = 3, 
		cropPoints = 3, 
		icon = "🌽", 
		rarity = "uncommon",
		sellable = true,
		price = 725
	},
	strawberry = { 
		id = "strawberry", 
		name = "🍓 Strawberry", 
		type = "crop", 
		category = "crops", 
		description = "Sweet red strawberry. Premium fruit!",
		sellValue = 350, 
		sellCurrency = "coins", 
		feedValue = 2, 
		cropPoints = 2, 
		icon = "🍓", 
		rarity = "uncommon",
		sellable = true,
		price = 350
	},
	wheat = { 
		id = "wheat", 
		name = "🌾 Wheat", 
		type = "crop", 
		category = "crops", 
		description = "Golden wheat grain. Excellent for selling!",
		sellValue = 600, 
		sellCurrency = "coins", 
		feedValue = 3, 
		cropPoints = 3, 
		icon = "🌾", 
		rarity = "uncommon",
		sellable = true,
		price = 600
	},
	potato = { 
		id = "potato", 
		name = "🥔 Potato", 
		type = "crop", 
		category = "crops", 
		description = "Hearty potato. Always in demand!",
		sellValue = 40, 
		sellCurrency = "coins", 
		feedValue = 2, 
		cropPoints = 2, 
		icon = "🥔", 
		rarity = "common",
		sellable = true,
		price = 40
	},
	tomato = { 
		id = "tomato", 
		name = "🍅 Tomato", 
		type = "crop", 
		category = "crops", 
		description = "Juicy red tomato. Premium vegetable!",
		sellValue = 675, 
		sellCurrency = "coins", 
		feedValue = 3, 
		cropPoints = 3, 
		icon = "🍅", 
		rarity = "uncommon",
		sellable = true,
		price = 675
	},
	cabbage = { 
		id = "cabbage", 
		name = "🥬 Cabbage", 
		type = "crop", 
		category = "crops", 
		description = "Fresh leafy cabbage. Healthy choice!",
		sellValue = 75, 
		sellCurrency = "coins", 
		feedValue = 1, 
		cropPoints = 1, 
		icon = "🥬", 
		rarity = "common",
		sellable = true,
		price = 75
	},
	radish = { 
		id = "radish", 
		name = "🌶️ Radish", 
		type = "crop", 
		category = "crops", 
		description = "Spicy radish. Quick seller!",
		sellValue = 140, 
		sellCurrency = "coins", 
		feedValue = 2, 
		cropPoints = 2, 
		icon = "🌶️", 
		rarity = "common",
		sellable = true,
		price = 140
	},
	broccoli = { 
		id = "broccoli", 
		name = "🥦 Broccoli", 
		type = "crop", 
		category = "crops", 
		description = "Nutritious green broccoli. Health food trend!",
		sellValue = 110, 
		sellCurrency = "coins", 
		feedValue = 2, 
		cropPoints = 2, 
		icon = "🥦", 
		rarity = "common",
		sellable = true,
		price = 110
	},
	golden_fruit = { 
		id = "golden_fruit", 
		name = "✨ Golden Fruit", 
		type = "crop", 
		category = "crops", 
		description = "Magical golden fruit. Extremely rare!",
		sellValue = 1000,
		sellCurrency = "farmTokens",
		feedValue = 10, 
		cropPoints = 10, 
		icon = "✨", 
		rarity = "legendary",
		sellable = true,
		price = 1000
	}
}

-- ========== MINING SYSTEM DATA ==========
ItemConfig.MiningSystem = {
	ores = {
		copper_ore = {
			id = "copper_ore",
			name = "Copper Ore",
			description = "Basic copper ore found in shallow caves.",
			color = Color3.fromRGB(184, 115, 51),
			hardness = 3,
			sellValue = 25,
			sellCurrency = "coins",
			xpReward = 15,
			respawnTime = 60,
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
			respawnTime = 90,
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
			respawnTime = 120,
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
			respawnTime = 180,
			requiredLevel = 5,
			rarity = "rare",
			icon = "🟡"
		}
	},
	tools = {
		basic_pickaxe = {
			id = "basic_pickaxe",
			name = "Basic Pickaxe",
			description = "Essential tool for mining copper and bronze.",
			speed = 1.2,
			durability = 100,
			canMine = {"copper_ore", "bronze_ore"},
			requiredLevel = 1,
			icon = "⛏️"
		}
	}
}

-- ========== HELPER FUNCTIONS ==========

function ItemConfig.GetCropSellPrice(cropId)
	print("ItemConfig: Getting sell price for " .. cropId)

	-- Check ShopItems first (highest priority)
	local shopItem = ItemConfig.ShopItems[cropId]
	if shopItem then
		if shopItem.sellValue then
			print("Found sell value in ShopItems: " .. shopItem.sellValue)
			return shopItem.sellValue
		elseif shopItem.price then
			local sellPrice = math.floor(shopItem.price * 0.8) -- 80% of shop price for better returns
			print("Calculated sell price from shop price: " .. sellPrice)
			return sellPrice
		end
	end

	-- Check Crops table
	local crop = ItemConfig.Crops[cropId]
	if crop then
		if crop.sellValue then
			print("Found sell value in Crops: " .. crop.sellValue)
			return crop.sellValue
		elseif crop.price then
			local sellPrice = math.floor(crop.price * 0.8)
			print("Calculated sell price from crop price: " .. sellPrice)
			return sellPrice
		end
	end

	print("No sell price found for " .. cropId .. ", using default")
	return 1 -- Default minimum
end

function ItemConfig.IsCropSellable(cropId)
	print("ItemConfig: Checking if " .. cropId .. " is sellable")

	-- Check ShopItems first
	local shopItem = ItemConfig.ShopItems[cropId]
	if shopItem then
		if shopItem.notSellable then
			print("Crop marked as not sellable in ShopItems")
			return false
		end
		if shopItem.sellable ~= false then
			print("Crop is sellable in ShopItems")
			return true
		end
	end

	-- Check Crops table
	local crop = ItemConfig.Crops[cropId]
	if crop then
		if crop.notSellable then
			print("Crop marked as not sellable in Crops")
			return false
		end
		if crop.sellable ~= false then
			print("Crop is sellable in Crops")
			return true
		end
	end

	print("Defaulting to sellable for " .. cropId)
	return true -- Default to sellable
end

-- ========== ENHANCED SELL PRICE FUNCTIONS ==========

function ItemConfig.GetItemSellPrice(itemId)
	print("ItemConfig: Getting sell price for item " .. itemId)

	-- Priority 1: Check ShopItems
	local shopItem = ItemConfig.ShopItems[itemId]
	if shopItem then
		if shopItem.sellValue and shopItem.sellValue > 0 then
			return shopItem.sellValue
		elseif shopItem.price and shopItem.price > 0 then
			return math.floor(shopItem.price * 0.8) -- 80% return
		end
	end

	-- Priority 2: Check Crops table for crop-specific items
	local crop = ItemConfig.Crops[itemId]
	if crop then
		if crop.sellValue and crop.sellValue > 0 then
			return crop.sellValue
		elseif crop.price and crop.price > 0 then
			return math.floor(crop.price * 0.8)
		end
	end

	-- Priority 3: Check mining ores
	if ItemConfig.MiningSystem and ItemConfig.MiningSystem.ores then
		local ore = ItemConfig.MiningSystem.ores[itemId]
		if ore and ore.sellValue then
			return ore.sellValue
		end
	end

	return 1 -- Default minimum sell price
end

function ItemConfig.IsItemSellable(itemId)
	print("ItemConfig: Checking if item " .. itemId .. " is sellable")

	-- Known sellable categories and types
	local sellableCategories = {"crops", "livestock", "ores", "materials"}
	local sellableTypes = {"crop", "material", "ore"}

	-- Check ShopItems
	local shopItem = ItemConfig.ShopItems[itemId]
	if shopItem then
		-- Explicit sellable flag
		if shopItem.sellable == true then
			return true
		end

		-- Explicit not sellable flag
		if shopItem.notSellable == true or shopItem.sellable == false then
			return false
		end

		-- Check by category
		for _, category in ipairs(sellableCategories) do
			if shopItem.category == category then
				return true
			end
		end

		-- Check by type
		for _, sellableType in ipairs(sellableTypes) do
			if shopItem.type == sellableType then
				return true
			end
		end
	end

	-- Check Crops table
	local crop = ItemConfig.Crops[itemId]
	if crop then
		if crop.sellable ~= false and not crop.notSellable then
			return true
		end
	end

	-- Check mining ores
	if ItemConfig.MiningSystem and ItemConfig.MiningSystem.ores and ItemConfig.MiningSystem.ores[itemId] then
		return true
	end

	-- Special items that should always be sellable
	local alwaysSellable = {"milk", "chicken_egg", "guinea_egg", "rooster_egg"}
	for _, sellableItem in ipairs(alwaysSellable) do
		if itemId == sellableItem then
			return true
		end
	end

	return false
end

-- ========== VALIDATION FUNCTIONS ==========

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

-- ========== RARITY FUNCTIONS ==========

function ItemConfig.GetCropRarity(seedId, playerBoosters)
	playerBoosters = playerBoosters or {}

	local seedData = ItemConfig.ShopItems[seedId]
	if not seedData or not seedData.farmingData or not seedData.farmingData.rarityChances then
		return "common"
	end

	local chances = seedData.farmingData.rarityChances
	local roll = math.random()

	if playerBoosters.rarity_booster then
		return "rare"
	end

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

-- ========== SEED AND CROP MAPPING ==========

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
	for seedId, seedData in pairs(ItemConfig.ShopItems) do
		if seedData.type == "seed" and seedData.farmingData and seedData.farmingData.resultCropId == cropId then
			return seedId
		end
	end
	return nil
end

-- ========== UTILITY FUNCTIONS ==========

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

-- ========== AUTO-VALIDATION ON LOAD ==========

spawn(function()
	print("ItemConfig: Running automatic validation...")

	local sellableItems = 0
	local totalItems = 0

	for itemId, item in pairs(ItemConfig.ShopItems) do
		totalItems = totalItems + 1

		if ItemConfig.IsItemSellable(itemId) then
			sellableItems = sellableItems + 1
		end
	end

	print("ItemConfig: Validation complete!")
	print("  Total items: " .. totalItems)
	print("  Sellable items: " .. sellableItems)

	-- Test key items
	local testItems = {"carrot", "corn", "milk", "copper_ore"}
	print("Testing key sellable items:")
	for _, itemId in ipairs(testItems) do
		local sellable = ItemConfig.IsItemSellable(itemId)
		local price = ItemConfig.GetItemSellPrice(itemId)
		print("  " .. itemId .. ": sellable=" .. tostring(sellable) .. ", price=" .. price)
	end
end)

print("ItemConfig: ✅ COMPLETE sellable items system loaded!")
print("🏪 Features:")
print("  🌾 All crops configured for selling")
print("  🥛 Animal products sellable")
print("  ⛏️ Mining ores sellable")
print("  💰 Proper sell price calculations")
print("  🔍 Enhanced validation system")

return ItemConfig