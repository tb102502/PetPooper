--[[
    ItemConfig.lua - UPDATED FOR PEST & CHICKEN DEFENSE SYSTEM
    Place in: ReplicatedStorage/ItemConfig.lua
    
    Changes:
    - Added pest system configuration
    - Added chicken types and management
    - Added chicken feed and related items
    - Enhanced shop with pest defense items
]]

local ItemConfig = {}

-- ========== LIVESTOCK SYSTEM (EXISTING) ==========

-- Cow milk collection system
ItemConfig.CowSystem = {
	baseCooldown = 30,
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

-- ========== NEW: PEST SYSTEM ==========

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
			spreadChance = 0.1, -- 10% chance to spread to adjacent crops
			weatherPreference = "any",
			seasonMultiplier = 1.0
		},

		locusts = {
			name = "Locust Swarm", 
			icon = "🦗",
			description = "Devastating swarms that attack multiple crops",
			maxPerCrop = 1, -- But affects 3x3 area
			spreadChance = 0.3, -- 30% chance to expand swarm
			weatherPreference = "dry",
			seasonMultiplier = 1.5, -- More common in summer
			swarmRadius = 2 -- Affects crops within 2 plots
		},

		fungal_blight = {
			name = "Fungal Blight",
			icon = "🍄",
			description = "Disease that spreads between crops in wet conditions",
			maxPerCrop = 1,
			spreadChance = 0.25, -- 25% chance to spread
			weatherPreference = "wet", 
			seasonMultiplier = 1.3, -- More common in spring/fall
			spreadRadius = 1 -- Spreads to adjacent crops
		}
	}
}

-- ========== NEW: CHICKEN DEFENSE SYSTEM ==========

ItemConfig.ChickenSystem = {
	-- Chicken types and their capabilities
	chickenTypes = {
		basic_chicken = {
			name = "Basic Chicken",
			icon = "🐔",
			description = "General purpose pest control and egg laying",
			price = 150,
			currency = "coins",

			-- Combat stats
			pestTargets = {"aphids"}, -- What pests they can eliminate
			huntRange = 3, -- How far they patrol from their home
			huntSpeed = 2, -- Pests eliminated per minute when hunting
			huntEfficiency = 0.8, -- 80% success rate per hunt attempt

			-- Production stats
			eggProductionTime = 240, -- 4 minutes per egg
			eggValue = 5, -- Coins per egg

			-- Maintenance
			feedConsumption = 1, -- Feed units per hour
			maxHunger = 24, -- Hours before chicken stops working
			lifespan = 2880 -- 48 hours of gameplay time
		},

		guinea_fowl = {
			name = "Guinea Fowl",
			icon = "🦃", 
			description = "Specialized anti-locust defense with alarm calls",
			price = 300,
			currency = "coins",

			-- Combat stats  
			pestTargets = {"locusts", "aphids"},
			huntRange = 5, -- Larger patrol range
			huntSpeed = 4, -- Very effective against target pests
			huntEfficiency = 0.95, -- 95% success rate vs locusts

			-- Special abilities
			alarmSystem = true, -- Warns of incoming locust swarms
			swarmDetection = 8, -- Can detect swarms 8 plots away

			-- Production stats
			eggProductionTime = 360, -- 6 minutes per egg (slower)
			eggValue = 8, -- More valuable eggs

			-- Maintenance
			feedConsumption = 1.5, -- Eats more
			maxHunger = 20,
			lifespan = 3600 -- 60 hours (longer lived)
		},

		rooster = {
			name = "Rooster",
			icon = "🐓",
			description = "Provides area protection boost and flock coordination",
			price = 500,
			currency = "coins",

			-- Combat stats
			pestTargets = {"aphids", "fungal_blight"},
			huntRange = 4,
			huntSpeed = 3,
			huntEfficiency = 0.85,

			-- Special abilities
			areaBoost = true, -- Boosts other chickens in 6-plot radius
			boostRadius = 6,
			boostMultiplier = 1.5, -- 50% boost to other chickens' effectiveness
			intimidationFactor = 0.2, -- 20% reduced pest spawn rate in area

			-- Production stats
			eggProductionTime = 480, -- 8 minutes per egg
			eggValue = 12, -- Premium eggs

			-- Maintenance  
			feedConsumption = 2, -- High maintenance
			maxHunger = 18,
			lifespan = 4320 -- 72 hours (very long lived)
		}
	},

	-- Feeding system
	feedTypes = {
		basic_feed = {
			name = "Basic Chicken Feed",
			feedValue = 6, -- Hours of feeding per unit
			price = 10,
			currency = "coins"
		},

		premium_feed = {
			name = "Premium Chicken Feed", 
			feedValue = 12, -- More efficient
			eggBonus = 1.2, -- 20% more egg production
			price = 25,
			currency = "coins"
		},

		grain_feed = {
			name = "Grain Feed", -- Can be made from crops
			feedValue = 8,
			healthBonus = 1.1, -- 10% longer lifespan
			craftable = true,
			recipe = {corn = 2, wheat = 1} -- Made from player crops
		}
	}
}

-- ========== CURRENCY SYSTEM (EXISTING) ==========

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

-- ========== SHOP ITEMS (UPDATED WITH PEST/CHICKEN ITEMS) ==========

ItemConfig.ShopItems = {
	-- ========== EXISTING LIVESTOCK UPGRADES ==========
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
		effects = { cooldownReduction = 2 }
	},

	-- ========== NEW: CHICKEN DEFENSE ITEMS ==========

	-- Chickens
	basic_chicken = {
		id = "basic_chicken",
		name = "🐔 Basic Chicken",
		type = "chicken",
		category = "defense",
		price = 150,
		currency = "coins",
		description = "General purpose pest control. Eliminates aphids and lays eggs for steady income.",
		icon = "🐔",
		maxQuantity = 20, -- Can own up to 20 chickens
		effects = {
			pestControl = {"aphids"},
			eggProduction = 5 -- Coins per egg
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
		requiresPurchase = "basic_chicken", -- Must have basic chicken first
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
		maxQuantity = 3, -- Limited quantity
		requiresPurchase = "guinea_fowl",
		effects = {
			areaBoost = 1.5,
			pestReduction = 0.2
		}
	},

	-- Chicken Feed
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

	-- Pest Control Tools
	organic_pesticide = {
		id = "organic_pesticide",
		name = "🧪 Organic Pesticide",
		type = "tool",
		category = "defense",
		price = 50,
		currency = "coins", 
		description = "Manually eliminate pests from crops. One-time use, affects 3x3 area.",
		icon = "🧪",
		maxQuantity = 20,
		effects = {
			pestElimination = "all",
			area = 9 -- 3x3 area
		}
	},

	pest_detector = {
		id = "pest_detector",
		name = "📡 Pest Detector",
		type = "upgrade",
		category = "defense",
		price = 200,
		currency = "coins",
		description = "Early warning system that alerts you to pest infestations before they cause damage.",
		icon = "📡",
		maxQuantity = 1,
		effects = {
			earlyWarning = true,
			detectionRange = 20 -- Plots
		}
	},

	-- ========== EXISTING FARMING SYSTEM ==========
	farm_plot_starter = {
		id = "farm_plot_starter",
		name = "🌾 Your First Farm Plot",
		type = "farmPlot",
		category = "farm",
		price = 50,
		currency = "coins",
		description = "Purchase your first farming plot for 200 coins! Includes free starter seeds.",
		maxQuantity = 1,
		icon = "🌾",
		effects = {
			enableFarming = true,
			starterSeeds = {
				carrot_seeds = 0,
				corn_seeds = 0
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
			growTime = 300,
			yieldAmount = 2,
			resultCropId = "carrot",
			cropPoints = 1,
			stages = {"planted", "sprouting", "growing", "ready"},
			pestVulnerability = {
				aphids = 1.0, -- Normal vulnerability
				locusts = 0.8, -- Slightly resistant 
				fungal_blight = 1.2 -- More vulnerable
			}
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
			growTime = 480,
			yieldAmount = 3,
			resultCropId = "corn",
			cropPoints = 2,
			stages = {"planted", "sprouting", "growing", "ready"},
			pestVulnerability = {
				aphids = 0.7, -- More resistant to aphids
				locusts = 1.5, -- Very vulnerable to locusts
				fungal_blight = 0.9
			}
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
		icon = "🥕",
		-- NEW: Pest damage affects sell value
		pestDamageMultiplier = 1.0 -- 100% damage = 0% sell value
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
		icon = "🌽",
		pestDamageMultiplier = 1.0
	},

	-- NEW: Chicken Eggs as tradeable items
	chicken_egg = {
		id = "chicken_egg",
		name = "Chicken Egg",
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
		name = "Guinea Fowl Egg",
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
		name = "Premium Rooster Egg", 
		type = "product",
		category = "livestock",
		description = "Rare premium eggs. Highly valuable and used in special recipes.",
		sellValue = 12,
		sellCurrency = "coins",
		icon = "🥚",
		stackable = true,
		maxStack = 25
	}
}

-- ========== UTILITY FUNCTIONS (ENHANCED) ==========
-- ADD to ItemConfig.lua - Validation System
ItemConfig.Validation = {}

-- Validate item configuration
function ItemConfig.Validation.ValidateItem(itemId, itemData)
	local errors = {}

	-- Required fields
	local required = {"id", "name", "type", "category", "price", "currency"}
	for _, field in ipairs(required) do
		if not itemData[field] then
			table.insert(errors, "Missing required field: " .. field)
		end
	end

	-- Type-specific validation
	if itemData.type == "seed" and itemData.farmingData then
		local farming = itemData.farmingData
		if not farming.growTime or farming.growTime <= 0 then
			table.insert(errors, "Invalid grow time for seed: " .. itemId)
		end
		if not farming.resultCropId then
			table.insert(errors, "Missing resultCropId for seed: " .. itemId)
		end
	end

	if itemData.type == "chicken" then
		local chicken = ItemConfig.ChickenSystem.chickenTypes[itemId]
		if chicken then
			if not chicken.pestTargets or #chicken.pestTargets == 0 then
				table.insert(errors, "Chicken has no pest targets: " .. itemId)
			end
			if not chicken.huntRange or chicken.huntRange <= 0 then
				table.insert(errors, "Invalid hunt range for chicken: " .. itemId)
			end
		end
	end

	return #errors == 0, errors
end

-- Validate all items on load
function ItemConfig.Validation.ValidateAllItems()
	local totalErrors = {}
	local validItems = 0

	for itemId, itemData in pairs(ItemConfig.ShopItems) do
		local isValid, errors = ItemConfig.Validation.ValidateItem(itemId, itemData)
		if isValid then
			validItems = validItems + 1
		else
			totalErrors[itemId] = errors
		end
	end

	print("ItemConfig Validation Results:")
	print("  Valid Items: " .. validItems)
	print("  Invalid Items: " .. (#ItemConfig.ShopItems - validItems))

	if next(totalErrors) then
		print("  Errors found:")
		for itemId, errors in pairs(totalErrors) do
			print("    " .. itemId .. ":")
			for _, error in ipairs(errors) do
				print("      - " .. error)
			end
		end
	end

	return #totalErrors == 0
end

-- FIXED: Balance Configuration
ItemConfig.Balance = {
	-- Pest spawn rates (per hour per unprotected crop)
	pestSpawnRates = {
		aphids = 0.1,       -- Reduced from 0.15 - too frequent
		locusts = 0.03,     -- Reduced from 0.05 - very destructive
		fungal_blight = 0.02 -- Reduced from 0.03 - spreads too fast
	},

	-- Chicken effectiveness vs pests (success rate)
	chickenEffectiveness = {
		basic_chicken = {
			aphids = 0.8,           -- 80% success vs aphids
			locusts = 0.2,          -- 20% vs locusts (not specialized)
			fungal_blight = 0.1     -- 10% vs blight (ineffective)
		},
		guinea_fowl = {
			aphids = 0.6,           -- 60% vs aphids
			locusts = 0.95,         -- 95% vs locusts (specialized)
			fungal_blight = 0.3     -- 30% vs blight
		},
		rooster = {
			aphids = 0.7,           -- 70% vs aphids
			locusts = 0.4,          -- 40% vs locusts
			fungal_blight = 0.8     -- 80% vs blight (area boost)
		}
	},

	-- Economic balance
	economy = {
		-- Seed to crop value ratio (profit margin)
		seedProfitMargin = 2.5,  -- Crops should sell for 2.5x seed cost

		-- Chicken ROI (days to pay for itself through eggs)
		chickenROIDays = {
			basic_chicken = 7,      -- 7 days to break even
			guinea_fowl = 10,       -- 10 days (more expensive)
			rooster = 15            -- 15 days (expensive but boosts others)
		},

		-- Pest damage economic impact
		pestDamageThresholds = {
			minor = 0.1,    -- 10% damage - warning
			moderate = 0.3, -- 30% damage - concern
			severe = 0.6    -- 60% damage - urgent action needed
		}
	}
}

-- OPTIMIZED: Price calculation system
function ItemConfig.CalculateOptimalPrice(itemType, baseValue, marketFactors)
	local multipliers = {
		seed = 0.4,      -- Seeds cost 40% of crop value
		chicken = 30,    -- Chickens cost 30x their hourly egg value
		feed = 0.8,      -- Feed costs 80% of basic crop value
		tool = 5,        -- Tools cost 5x their usage value
		upgrade = 2      -- Upgrades cost 2x their benefit value
	}

	local basePrice = baseValue * (multipliers[itemType] or 1)

	-- Apply market factors
	if marketFactors then
		if marketFactors.rarity then
			basePrice = basePrice * marketFactors.rarity
		end
		if marketFactors.demand then
			basePrice = basePrice * marketFactors.demand
		end
	end

	return math.floor(basePrice)
end

-- IMPROVED: Integration checks
function ItemConfig.ValidateSystemIntegration()
	local issues = {}

	-- Check pest-chicken relationships
	for pestType, pestData in pairs(ItemConfig.PestSystem.pestData) do
		local hasCounter = false
		for chickenType, chickenData in pairs(ItemConfig.ChickenSystem.chickenTypes) do
			for _, targetPest in ipairs(chickenData.pestTargets) do
				if targetPest == pestType then
					hasCounter = true
					break
				end
			end
			if hasCounter then break end
		end

		if not hasCounter then
			table.insert(issues, "Pest '" .. pestType .. "' has no chicken counter")
		end
	end

	-- Check crop-pest vulnerability balance
	for itemId, item in pairs(ItemConfig.ShopItems) do
		if item.type == "seed" and item.farmingData and item.farmingData.pestVulnerability then
			local vulnerability = item.farmingData.pestVulnerability
			local totalVuln = 0
			for _, vuln in pairs(vulnerability) do
				totalVuln = totalVuln + vuln
			end

			if totalVuln > 4 then -- Average > 1.33
				table.insert(issues, "Crop '" .. itemId .. "' is overly vulnerable to pests")
			elseif totalVuln < 2 then -- Average < 0.67
				table.insert(issues, "Crop '" .. itemId .. "' is too resistant to pests")
			end
		end
	end

	return issues
end

-- Auto-validate on load
spawn(function()
	wait(1) -- Allow other systems to load
	local valid = ItemConfig.Validation.ValidateAllItems()
	if valid then
		print("✅ All ItemConfig items are valid")
	else
		warn("❌ ItemConfig validation failed - check console for details")
	end

	local integrationIssues = ItemConfig.ValidateSystemIntegration()
	if #integrationIssues == 0 then
		print("✅ System integration validated")
	else
		warn("❌ System integration issues:")
		for _, issue in ipairs(integrationIssues) do
			warn("  - " .. issue)
		end
	end
end)
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

-- NEW: Get pest data
function ItemConfig.GetPestData(pestType)
	return ItemConfig.PestSystem.pestData[pestType]
end

-- NEW: Get chicken data
function ItemConfig.GetChickenData(chickenType)
	return ItemConfig.ChickenSystem.chickenTypes[chickenType]
end

-- NEW: Calculate pest damage to crop value
function ItemConfig.CalculatePestDamage(cropId, pestDamageLevel)
	local crop = ItemConfig.ShopItems[cropId]
	if not crop then return 0 end

	local baseSellValue = crop.sellValue or 0
	local damageMultiplier = crop.pestDamageMultiplier or 1.0

	-- Pest damage reduces sell value
	local damageReduction = pestDamageLevel * damageMultiplier
	local finalValue = baseSellValue * (1 - damageReduction)

	return math.max(0, math.floor(finalValue))
end

-- NEW: Check if chicken can target specific pest
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

-- Calculate milk collection cooldown based on upgrades (existing)
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

-- Calculate milk value based on upgrades (existing)
function ItemConfig.GetMilkValue(playerUpgrades)
	local baseValue = ItemConfig.CowSystem.milkValue
	local bonus = 0

	local milkValueLevel = playerUpgrades.milk_value_boost or 0
	bonus = bonus + (milkValueLevel * 5)

	if playerUpgrades.mega_milk_boost then
		bonus = bonus + 15
	end

	return baseValue + bonus
end

return ItemConfig