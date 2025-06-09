--[[
    ItemConfig.lua - FIXED VERSION WITH ALL SHOP ITEMS
    Place in: ReplicatedStorage/ItemConfig.lua
    
    FIXES:
    ✅ Fixed syntax errors in ShopItems table
    ✅ Added all missing items (roofs, chickens, pesticides, etc.)
    ✅ Proper categorization for shop display
    ✅ Consistent item structure
    ✅ Added all chicken and pest control items
]]

local ItemConfig = {}

-- ========== LIVESTOCK SYSTEM (EXISTING) ==========

-- Cow milk collection system
ItemConfig.CowSystem = {
	baseCooldown = 3,
	milkValue = 10,
	maxUpgradeLevel = 10,
	cooldownReduction = {
		[1] = 2, [2] = 3, [3] = 4, [4] = 5, [5] = 6,
		[6] = 7, [7] = 8, [8] = 9, [9] = 10, [10] = 12
	}
}

-- Pig feeding system
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
	-- Pest spawn rates (chance per hour per unprotected crop)
	spawnRates = {
		aphids = 0.15,     -- 15% chance per hour per crop
		locusts = 0.05,    -- 5% chance per hour (but affects multiple crops)
		fungal_blight = 0.03 -- 3% chance per hour (spreads to nearby crops)
	},

	-- Pest damage rates
	damageRates = {
		aphids = 0.1,      -- 10% crop value loss per hour
		locusts = 0.25,    -- 25% crop value loss per hour  
		fungal_blight = 0.15 -- 15% crop value loss per hour, spreads
	},

	-- Pest behavior
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
	-- Chicken types and their capabilities
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

	-- Feeding system
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
	},

	-- ========== MILK PRODUCTS ==========
	fresh_milk = {
		id = "fresh_milk",
		name = "🥛 Fresh Milk",
		type = "product",
		category = "livestock", 
		description = "Fresh milk from your cow. Nutritious and valuable!",
		sellValue = 15, -- Better price than old direct system (was 10)
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
		recipe = {fresh_milk = 2} -- 2 fresh milk = 1 processed milk
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
		recipe = {fresh_milk = 5} -- 5 fresh milk = 1 cheese
	}
}
-- ========== CURRENCY SYSTEM ==========

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

-- ========== SHOP ITEMS (COMPLETE AND FIXED) ==========

ItemConfig.ShopItems = {

	-- ========== SEEDS CATEGORY ==========
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
			growTime = 300,
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
			growTime = 480,
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
			growTime = 600,
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

	-- ========== FARM UPGRADES CATEGORY ==========
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
		maxQuantity = 9, -- Can expand up to 10 total plots
		requiresPurchase = "farm_plot_starter"
	},

	-- ========== ROOF PROTECTION CATEGORY ==========
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
			coverage = 999, -- Covers all plots
			ufoProtection = true,
			ultimate = true
		}
	},

	-- ========== CHICKEN DEFENSE CATEGORY ==========
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

	-- ========== CHICKEN FEED CATEGORY ==========
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

	-- ========== PEST CONTROL TOOLS CATEGORY ==========
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
			area = 999, -- Entire farm
			instant = true
		}
	},

	-- ========== LIVESTOCK UPGRADES ==========
	-- ========== UPDATED LIVESTOCK UPGRADES ==========

	-- UPDATE the existing milk upgrades to give milk yield instead of just value:

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
			milkYieldBonus = 1 -- ADDED
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
			milkYieldBonus = 2 -- ADDED (total +3 with first upgrade)
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
			milkValueBonus = 5 -- Increases sell price from 15 to 20 coins
		}
	},

	-- ========== CROP PRODUCTS (FOR REFERENCE) ==========
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
		pestDamageMultiplier = 0.5 -- Resistant to pest damage
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
	-- ADD dairy building shop items (future expansion):

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
			processingCapacity = 3 -- Can process 3 recipes simultaneously
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
ItemConfig.ProcessingRecipes = {
	processed_milk = {
		ingredients = {fresh_milk = 2},
		result = "processed_milk",
		quantity = 1,
		processingTime = 300, -- 5 minutes
		requiredBuilding = "dairy_processor"
	},

	cheese = {
		ingredients = {fresh_milk = 5},
		result = "cheese", 
		quantity = 1,
		processingTime = 1800, -- 30 minutes
		requiredBuilding = "cheese_maker"
	}
}
-- ========== UTILITY FUNCTIONS ==========

-- Get item by ID
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
-- Get pest data
function ItemConfig.GetPestData(pestType)
	return ItemConfig.PestSystem.pestData[pestType]
end

-- Get chicken data
function ItemConfig.GetChickenData(chickenType)
	return ItemConfig.ChickenSystem.chickenTypes[chickenType]
end

-- Calculate pest damage to crop value
function ItemConfig.CalculatePestDamage(cropId, pestDamageLevel)
	local crop = ItemConfig.ShopItems[cropId]
	if not crop then return 0 end

	local baseSellValue = crop.sellValue or 0
	local damageMultiplier = crop.pestDamageMultiplier or 1.0

	local damageReduction = pestDamageLevel * damageMultiplier
	local finalValue = baseSellValue * (1 - damageReduction)

	return math.max(0, math.floor(finalValue))
end

-- Check if chicken can target specific pest
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

-- Enhanced farming data for a seed
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

-- Calculate milk collection cooldown based on upgrades
function ItemConfig.GetMilkCooldown(playerUpgrades)
	local baseCooldown = ItemConfig.CowSystem.baseCooldown
	local reduction = 0

	for i = 1, 3 do
		local upgradeId = "milk_efficiency_" .. i
		if playerUpgrades[upgradeId] then
			local upgrade = ItemConfig.ShopItems[upgradeId]
			if upgrade and upgrade.effects and upgrade.effects.cooldownReduction then
				reduction = reduction + upgrade.effects.cooldownReduction
			end
		end
	end

	if playerUpgrades.mega_efficiency then
		local remaining = baseCooldown - reduction
		reduction = reduction + (remaining * 0.25)
	end

	return math.max(5, baseCooldown - reduction)
end

-- Calculate milk value based on upgrades
function ItemConfig.GetMilkSellValue(playerUpgrades)
	local baseValue = 15 -- Base sell value for fresh milk
	local bonus = 0

	if playerUpgrades and playerUpgrades.milk_value_boost then
		local upgrade = ItemConfig.ShopItems.milk_value_boost
		if upgrade and upgrade.effects and upgrade.effects.milkValueBonus then
			bonus = bonus + upgrade.effects.milkValueBonus
		end
	end

	if playerUpgrades and playerUpgrades.mega_milk_boost then
		bonus = bonus + 10 -- Mega upgrade adds +10 to sell value
	end

	return baseValue + bonus
end


-- Check if player can buy an item
function ItemConfig.CanPlayerBuy(itemId, playerData)
	local item = ItemConfig.ShopItems[itemId]
	if not item then
		return false, "Item not found"
	end

	-- Check if player data exists
	if not playerData then
		return false, "No player data"
	end

	-- Check if player has required currency
	local playerCurrency = playerData[item.currency] or 0
	if playerCurrency < item.price then
		return false, "Insufficient " .. item.currency
	end

	-- Check quantity limits
	if item.maxQuantity and item.maxQuantity == 1 then
		if playerData.purchaseHistory and playerData.purchaseHistory[itemId] then
			return false, "Already purchased"
		end
	end

	-- Check requirements
	if item.requiresPurchase then
		if not playerData.purchaseHistory or not playerData.purchaseHistory[item.requiresPurchase] then
			local reqItem = ItemConfig.ShopItems[item.requiresPurchase]
			local reqName = reqItem and reqItem.name or item.requiresPurchase
			return false, "Requires: " .. reqName
		end
	end

	-- Special requirement checks
	if item.requiresFarmPlot then
		if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
			return false, "Requires farm plot"
		end
	end

	return true, "Can purchase"
end

-- NEW: Get random mega drop for pig transformation
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

-- NEW: Get crop points needed for mega pig transformation
function ItemConfig.GetCropPointsForMegaPig(transformationCount)
	return 100 + (transformationCount * 50)
end

print("ItemConfig: ✅ Complete shop system loaded with all items!")
print("Categories available:")
print("  🌱 Seeds: carrot_seeds, corn_seeds, strawberry_seeds, golden_seeds")
print("  🚜 Farm: farm_plot_starter, farm_plot_expansion, roofs, milk_upgrades")
print("  🐔 Defense: basic_chicken, guinea_fowl, rooster, chicken_feeds")
print("  🧪 Tools: organic_pesticide, pest_detector, super_pesticide")
print("  🏆 Premium: golden_seeds, mega_dome")
print("ItemConfig: ✅ Added milk products and processing system!")
print("New Items:")
print("  🥛 Fresh Milk - Base product from cow milking")
print("  🧈 Processed Milk - Crafted from 2 fresh milk")
print("  🧀 Artisan Cheese - Crafted from 5 fresh milk")
print("  🏭 Dairy Processor - Building for milk processing")
print("  🧀 Cheese Maker - Specialized cheese production")
print("")
print("Updated Features:")
print("  💰 Better milk sell prices (15 coins vs old 10)")
print("  📈 Upgrades affect milk yield instead of just cooldown")
print("  🏪 Processing recipes for value-added products")
return ItemConfig