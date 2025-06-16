--[[
    FIXED ItemConfig.lua - All Shop Items + Rarity System
    Place in: ReplicatedStorage/ItemConfig.lua
    
    FIXES:
    ✅ All items properly formatted for shop display
    ✅ Rarity system integrated for farming
    ✅ Complete item catalog with proper categories
    ✅ Seed-to-crop mapping fixed
    ✅ All missing items added
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
		description = "Essential tool for mining. Allows access to copper and bronze ore deposits.\n\n⛏️ Mining Power:\n• Can mine copper ore\n• Can mine bronze ore\n• 50 durability\n• Entry-level tool",
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
		description = "Improved mining tool with better durability and mining power.\n\n⛏️ Enhanced Power:\n• Can mine up to iron ore\n• 100 durability\n• 20% faster mining\n• Sturdy construction",
		price = 150,
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
		description = "Professional mining tool that can handle tougher ores.\n\n⛏️ Professional Grade:\n• Can mine up to silver ore\n• 200 durability\n• 50% faster mining\n• Professional quality",
		price = 500,
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
		description = "Premium mining tool for the most valuable ores.\n\n⛏️ Premium Power:\n• Can mine all common ores\n• Can mine gold and diamonds\n• 500 durability\n• 150% faster mining",
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
		description = "🏆 LEGENDARY MINING TOOL 🏆\nCan mine the rarest ores including mystical obsidian!\n\n⛏️ Legendary Power:\n• Can mine ALL ore types\n• Can mine obsidian\n• 1000 durability\n• 250% faster mining",
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

print("✅ FIXED ItemConfig loaded with complete shop catalog!")
print("📦 Total shop items: " .. (function() local count = 0; for _ in pairs(ItemConfig.ShopItems) do count = count + 1 end return count end)())
print("🎯 Categories:")
local counts = ItemConfig.CountItemsByCategory()
for category, count in pairs(counts) do
	print("  " .. category .. ": " .. count .. " items")
end
print("🌟 Rarity system: ACTIVE with 5 tiers")
print("🌱 Seed-to-crop mapping: COMPLETE")

return ItemConfig