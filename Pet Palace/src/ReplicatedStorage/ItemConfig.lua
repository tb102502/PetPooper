--[[
    ItemConfig.lua - UPDATED FOR FARMING & LIVESTOCK SYSTEM
    Place in: ReplicatedStorage/ItemConfig.lua
    
    Changes:
    - Removed pet system entirely
    - Added milk collection system
    - Updated crop point values
    - Added pig feeding upgrades
    - New currency system (coins from milk, farmTokens from crops)
]]

local ItemConfig = {}

-- ========== LIVESTOCK SYSTEM ==========

-- Cow milk collection system
ItemConfig.CowSystem = {
	baseCooldown = 30, -- 30 seconds base cooldown
	milkValue = 10, -- Base coins per milk collection
	maxUpgradeLevel = 10,

	-- Upgrade effects (cooldown reduction per level)
	cooldownReduction = {
		[1] = 2,   -- Level 1: -2 seconds
		[2] = 3,   -- Level 2: -3 seconds  
		[3] = 4,   -- Level 3: -4 seconds
		[4] = 5,   -- Level 4: -5 seconds
		[5] = 6,   -- Level 5: -6 seconds
		[6] = 7,   -- Level 6: -7 seconds
		[7] = 8,   -- Level 7: -8 seconds
		[8] = 9,   -- Level 8: -9 seconds
		[9] = 10,  -- Level 9: -10 seconds
		[10] = 12  -- Level 10: -12 seconds (minimum 18 second cooldown)
	}
}

-- Pig feeding system
ItemConfig.PigSystem = {
	baseCropPointsNeeded = 100, -- Base crop points for MEGA PIG
	growthPerPoint = 0.01, -- Size increase per crop point
	maxSize = 3.0, -- Maximum pig size before MEGA transformation

	-- Escalating cost for MEGA PIG transformations
	getCropPointsNeeded = function(transformationCount)
		return 100 + (transformationCount * 50) -- 100, 150, 200, 250, etc.
	end,

	-- Possible MEGA PIG drops (exclusive upgrades)
	megaDrops = {
		"mega_milk_boost",     -- Increases milk value permanently
		"mega_growth_speed",   -- Crops grow faster
		"mega_crop_multiplier", -- Crops yield more
		"mega_efficiency",     -- All cooldowns reduced
		"mega_golden_touch"    -- Chance for golden crops
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

-- ========== SHOP ITEMS ==========

ItemConfig.ShopItems = {
	-- ========== LIVESTOCK UPGRADES ==========
	milk_efficiency_1 = {
		id = "milk_efficiency_1",
		name = "Faster Milking I",
		type = "upgrade",
		category = "livestock",
		price = 100,
		currency = "coins",
		description = "Reduce milk collection cooldown by 2 seconds.",
		maxLevel = 1,
		icon = "🥛",
		effects = {
			cooldownReduction = 2
		}
	},

	milk_efficiency_2 = {
		id = "milk_efficiency_2",
		name = "Faster Milking II",
		type = "upgrade", 
		category = "livestock",
		price = 250,
		currency = "coins",
		description = "Reduce milk collection cooldown by 3 seconds.",
		maxLevel = 1,
		requiresUpgrade = "milk_efficiency_1",
		icon = "🥛",
		effects = {
			cooldownReduction = 3
		}
	},

	milk_efficiency_3 = {
		id = "milk_efficiency_3",
		name = "Faster Milking III",
		type = "upgrade",
		category = "livestock", 
		price = 500,
		currency = "coins",
		description = "Reduce milk collection cooldown by 4 seconds.",
		maxLevel = 1,
		requiresUpgrade = "milk_efficiency_2",
		icon = "🥛",
		effects = {
			cooldownReduction = 4
		}
	},

	milk_value_boost = {
		id = "milk_value_boost",
		name = "Premium Milk",
		type = "upgrade",
		category = "livestock",
		price = 300,
		currency = "coins", 
		description = "Increase milk value by 5 coins per collection.",
		maxLevel = 5,
		priceMultiplier = 1.5,
		icon = "💰",
		effects = {
			milkValueIncrease = 5
		}
	},

	-- ========== FARMING SYSTEM ==========
	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "🌾 Your First Farm Plot",
		type = "farmPlot",
		category = "farming",
		price = 200,
		currency = "coins",
		description = "Purchase your first farming plot for 200 coins! Includes free starter seeds.",
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

	-- ========== SEEDS ==========
	carrot_seeds = {
		id = "carrot_seeds",
		name = "Carrot Seeds",
		type = "seed",
		category = "seeds",
		price = 25,
		currency = "coins",
		description = "Fast-growing carrots. Ready in 5 minutes. Worth 1 crop point when fed to pig.",
		requiresFarmPlot = true,
		icon = "🥕",
		farmingData = {
			growTime = 300, -- 5 minutes
			yieldAmount = 2,
			resultCropId = "carrot",
			cropPoints = 1,
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
		description = "High-yield corn. Ready in 8 minutes. Worth 2 crop points when fed to pig.",
		requiresFarmPlot = true,
		icon = "🌽",
		farmingData = {
			growTime = 480, -- 8 minutes
			yieldAmount = 3,
			resultCropId = "corn",
			cropPoints = 2,
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
		description = "Sweet strawberries. Ready in 10 minutes. Worth 3 crop points when fed to pig.",
		requiresFarmPlot = true,
		icon = "🍓",
		farmingData = {
			growTime = 600, -- 10 minutes
			yieldAmount = 4,
			resultCropId = "strawberry",
			cropPoints = 3,
			stages = {"planted", "sprouting", "growing", "ready"}
		}
	},

	golden_seeds = {
		id = "golden_seeds",
		name = "Golden Seeds",
		type = "seed", 
		category = "seeds",
		price = 50,
		currency = "farmTokens",
		description = "Magical golden fruit! Ready in 15 minutes. Worth 10 crop points when fed to pig!",
		requiresFarmPlot = true,
		icon = "✨",
		farmingData = {
			growTime = 900, -- 15 minutes
			yieldAmount = 2,
			resultCropId = "golden_fruit",
			cropPoints = 10,
			stages = {"planted", "sprouting", "growing", "ready"}
		}
	},

	-- ========== CROPS ==========
	carrot = {
		id = "carrot",
		name = "Carrot",
		type = "crop",
		category = "crops",
		description = "Fresh carrot. Sells for 5 Farm Tokens or feed to pig for 1 crop point.",
		sellValue = 5,
		sellCurrency = "farmTokens",
		feedValue = 1,
		cropPoints = 1,
		icon = "🥕"
	},

	corn = {
		id = "corn",
		name = "Corn",
		type = "crop", 
		category = "crops",
		description = "Fresh corn. Sells for 12 Farm Tokens or feed to pig for 2 crop points.",
		sellValue = 12,
		sellCurrency = "farmTokens", 
		feedValue = 2,
		cropPoints = 2,
		icon = "🌽"
	},

	strawberry = {
		id = "strawberry",
		name = "Strawberry",
		type = "crop",
		category = "crops", 
		description = "Sweet strawberry. Sells for 20 Farm Tokens or feed to pig for 3 crop points.",
		sellValue = 20,
		sellCurrency = "farmTokens",
		feedValue = 3,
		cropPoints = 3,
		icon = "🍓"
	},

	golden_fruit = {
		id = "golden_fruit", 
		name = "Golden Fruit",
		type = "crop",
		category = "crops",
		description = "Magical golden fruit! Sells for 100 Farm Tokens or feed to pig for 10 crop points!",
		sellValue = 100,
		sellCurrency = "farmTokens",
		feedValue = 10,
		cropPoints = 10,
		icon = "✨"
	},

	-- ========== MEGA PIG EXCLUSIVE UPGRADES ==========
	mega_milk_boost = {
		id = "mega_milk_boost",
		name = "Mega Milk Boost",
		type = "mega_upgrade",
		category = "exclusive",
		description = "MEGA PIG EXCLUSIVE! Permanently increases milk value by 15 coins.",
		source = "mega_pig_drop",
		icon = "🥛✨",
		effects = {
			milkValueIncrease = 15
		}
	},

	mega_growth_speed = {
		id = "mega_growth_speed", 
		name = "Mega Growth Speed",
		type = "mega_upgrade",
		category = "exclusive",
		description = "MEGA PIG EXCLUSIVE! All crops grow 50% faster permanently.",
		source = "mega_pig_drop",
		icon = "⚡🌱",
		effects = {
			growthSpeedMultiplier = 0.5
		}
	},

	mega_crop_multiplier = {
		id = "mega_crop_multiplier",
		name = "Mega Crop Multiplier", 
		type = "mega_upgrade",
		category = "exclusive",
		description = "MEGA PIG EXCLUSIVE! All crops yield +1 extra when harvested.",
		source = "mega_pig_drop",
		icon = "🌾✨",
		effects = {
			yieldBonus = 1
		}
	},

	mega_efficiency = {
		id = "mega_efficiency",
		name = "Mega Efficiency",
		type = "mega_upgrade", 
		category = "exclusive",
		description = "MEGA PIG EXCLUSIVE! All cooldowns reduced by 25% permanently.",
		source = "mega_pig_drop",
		icon = "⚡✨",
		effects = {
			cooldownMultiplier = 0.75
		}
	},

	mega_golden_touch = {
		id = "mega_golden_touch",
		name = "Mega Golden Touch",
		type = "mega_upgrade",
		category = "exclusive", 
		description = "MEGA PIG EXCLUSIVE! 10% chance for any crop to become golden when harvested!",
		source = "mega_pig_drop",
		icon = "✨👑",
		effects = {
			goldenCropChance = 0.1
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

-- Calculate milk collection cooldown based on upgrades
function ItemConfig.GetMilkCooldown(playerUpgrades)
	local baseCooldown = ItemConfig.CowSystem.baseCooldown
	local reduction = 0

	-- Add up all milk efficiency upgrades
	for i = 1, 3 do
		local upgradeId = "milk_efficiency_" .. i
		if playerUpgrades[upgradeId] then
			local upgrade = ItemConfig.ShopItems[upgradeId]
			if upgrade and upgrade.effects and upgrade.effects.cooldownReduction then
				reduction = reduction + upgrade.effects.cooldownReduction
			end
		end
	end

	-- Apply mega efficiency if owned
	if playerUpgrades.mega_efficiency then
		local remaining = baseCooldown - reduction
		reduction = reduction + (remaining * 0.25) -- Additional 25% reduction
	end

	return math.max(5, baseCooldown - reduction) -- Minimum 5 seconds
end

-- Calculate milk value based on upgrades
function ItemConfig.GetMilkValue(playerUpgrades)
	local baseValue = ItemConfig.CowSystem.milkValue
	local bonus = 0

	-- Regular milk value upgrades
	local milkValueLevel = playerUpgrades.milk_value_boost or 0
	bonus = bonus + (milkValueLevel * 5)

	-- Mega milk boost
	if playerUpgrades.mega_milk_boost then
		bonus = bonus + 15
	end

	return baseValue + bonus
end

-- Calculate crop points needed for MEGA PIG
function ItemConfig.GetCropPointsForMegaPig(transformationCount)
	return ItemConfig.PigSystem.getCropPointsNeeded(transformationCount or 0)
end

-- Get random MEGA PIG drop
function ItemConfig.GetRandomMegaDrop()
	local drops = ItemConfig.PigSystem.megaDrops
	local randomDrop = drops[math.random(1, #drops)]
	return ItemConfig.ShopItems[randomDrop]
end

-- Calculate upgrade cost with scaling
function ItemConfig.GetUpgradeCost(upgradeId, currentLevel)
	local upgrade = ItemConfig.ShopItems[upgradeId]
	if not upgrade or upgrade.type ~= "upgrade" then return 0 end

	if currentLevel >= (upgrade.maxLevel or 1) then return 0 end

	local basePrice = upgrade.price or 0
	local multiplier = upgrade.priceMultiplier or 1.5

	return math.floor(basePrice * (multiplier ^ currentLevel))
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

	-- Check upgrade requirements
	if item.requiresUpgrade then
		if not playerData.upgrades or not playerData.upgrades[item.requiresUpgrade] then
			return false, "Requires " .. item.requiresUpgrade
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

return ItemConfig