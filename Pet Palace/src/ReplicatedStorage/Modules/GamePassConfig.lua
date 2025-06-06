-- GamePassConfig.lua
-- ModuleScript to store all GamePass IDs and configurations
-- Place in ReplicatedStorage/Modules/GamePassConfig.lua

local GamePassConfig = {}

-- IMPORTANT: Replace these with your actual GamePass IDs from Roblox
GamePassConfig.GAMEPASS_IDS = {
	-- Premium Shop Items
	UNLIMITED_STAMINA = 123456789,  -- Replace with actual ID
	DOUBLE_XP = 123456790,          -- Replace with actual ID
	AUTO_COLLECT = 123456791,       -- Replace with actual ID  
	EXTRA_PET_SLOTS = 123456792,    -- Replace with actual ID
	INSTANT_RESPAWN = 123456793,    -- Replace with actual ID
	VIP_STATUS = 123456794,         -- Replace with actual ID

	-- Additional GamePasses you might want
	STARTER_PACK = 123456795,       -- Gives starting pets and coins
	PREMIUM_AREAS = 123456796,      -- Access to VIP-only areas
	PET_STORAGE = 123456797,        -- Increased pet storage
	SPEED_BOOST = 123456798,        -- Permanent speed boost
}

-- GamePass benefits and effects
GamePassConfig.BENEFITS = {
	[GamePassConfig.GAMEPASS_IDS.UNLIMITED_STAMINA] = {
		name = "Unlimited Stamina",
		description = "Never run out of stamina while sprinting!",
		effects = {"unlimited_stamina"}
	},

	[GamePassConfig.GAMEPASS_IDS.DOUBLE_XP] = {
		name = "Double Pet XP", 
		description = "All pets gain double experience points!",
		effects = {"double_xp"}
	},

	[GamePassConfig.GAMEPASS_IDS.AUTO_COLLECT] = {
		name = "Auto Collector",
		description = "Automatically collect nearby pets while walking!",
		effects = {"auto_collect"}
	},

	[GamePassConfig.GAMEPASS_IDS.EXTRA_PET_SLOTS] = {
		name = "Extra Pet Slots",
		description = "Carry 50% more pets in your inventory!",
		effects = {"extra_pet_slots"}
	},

	[GamePassConfig.GAMEPASS_IDS.INSTANT_RESPAWN] = {
		name = "Instant Respawn",
		description = "Respawn instantly without any delay!",
		effects = {"instant_respawn"}
	},

	[GamePassConfig.GAMEPASS_IDS.VIP_STATUS] = {
		name = "VIP Status",
		description = "Get VIP perks: 2x coins, special chat tag, exclusive areas!",
		effects = {"vip_status", "coin_multiplier", "vip_areas", "chat_tag"}
	},

	[GamePassConfig.GAMEPASS_IDS.STARTER_PACK] = {
		name = "Starter Pack",
		description = "Get 1000 coins, 100 gems, and 3 rare pets to start!",
		effects = {"starter_pack"}
	},

	[GamePassConfig.GAMEPASS_IDS.PREMIUM_AREAS] = {
		name = "Premium Areas Access",
		description = "Access exclusive VIP-only areas with ultra-rare pets!",
		effects = {"premium_areas"}
	},

	[GamePassConfig.GAMEPASS_IDS.PET_STORAGE] = {
		name = "Expanded Storage",
		description = "Store up to 500 pets instead of the normal 100!",
		effects = {"expanded_storage"}
	},

	[GamePassConfig.GAMEPASS_IDS.SPEED_BOOST] = {
		name = "Speed Boost",
		description = "Permanent +50% walk and run speed!",
		effects = {"speed_boost"}
	}
}

-- Developer Product IDs (for consumable purchases like coins/gems)
GamePassConfig.DEVELOPER_PRODUCTS = {
	COINS_SMALL = 234567890,     -- 1,000 coins for 50 Robux
	COINS_MEDIUM = 234567891,    -- 5,000 coins for 200 Robux  
	COINS_LARGE = 234567892,     -- 15,000 coins for 500 Robux
	COINS_HUGE = 234567893,      -- 50,000 coins for 1,500 Robux

	GEMS_SMALL = 234567894,      -- 100 gems for 100 Robux
	GEMS_MEDIUM = 234567895,     -- 500 gems for 400 Robux
	GEMS_LARGE = 234567896,      -- 1,500 gems for 1,000 Robux

	MYSTERY_BOX = 234567897,     -- Mystery box with random pets
	RARE_PET_BOX = 234567898,    -- Guaranteed rare+ pet
	LEGENDARY_PET_BOX = 234567899, -- Guaranteed legendary pet
}

-- Developer Product configurations
GamePassConfig.PRODUCT_INFO = {
	[GamePassConfig.DEVELOPER_PRODUCTS.COINS_SMALL] = {
		name = "Small Coin Pack",
		amount = 1000,
		currency = "coins",
		bonus = 0
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.COINS_MEDIUM] = {
		name = "Medium Coin Pack", 
		amount = 5000,
		currency = "coins", 
		bonus = 500 -- 10% bonus
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.COINS_LARGE] = {
		name = "Large Coin Pack",
		amount = 15000,
		currency = "coins",
		bonus = 3000 -- 20% bonus
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.COINS_HUGE] = {
		name = "Huge Coin Pack",
		amount = 50000, 
		currency = "coins",
		bonus = 15000 -- 30% bonus
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.GEMS_SMALL] = {
		name = "Small Gem Pack",
		amount = 100,
		currency = "gems",
		bonus = 0
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.GEMS_MEDIUM] = {
		name = "Medium Gem Pack",
		amount = 500,
		currency = "gems", 
		bonus = 50 -- 10% bonus
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.GEMS_LARGE] = {
		name = "Large Gem Pack",
		amount = 1500,
		currency = "gems",
		bonus = 300 -- 20% bonus
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.MYSTERY_BOX] = {
		name = "Mystery Pet Box",
		type = "pet_box",
		rarity_chances = {
			Common = 50,
			Rare = 30,
			Epic = 15,
			Legendary = 5
		}
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.RARE_PET_BOX] = {
		name = "Rare Pet Box",
		type = "pet_box",
		rarity_chances = {
			Rare = 60,
			Epic = 30,
			Legendary = 10
		}
	},

	[GamePassConfig.DEVELOPER_PRODUCTS.LEGENDARY_PET_BOX] = {
		name = "Legendary Pet Box",
		type = "pet_box",
		rarity_chances = {
			Epic = 40,
			Legendary = 60
		}
	}
}

-- Check if player owns a gamepass
function GamePassConfig.PlayerOwnsGamePass(player, gamePassId)
	local MarketplaceService = game:GetService("MarketplaceService")

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
	end)

	return success and owns
end

-- Get all gamepasses owned by player
function GamePassConfig.GetOwnedGamePasses(player)
	local owned = {}

	for gamePassId, benefits in pairs(GamePassConfig.BENEFITS) do
		if GamePassConfig.PlayerOwnsGamePass(player, gamePassId) then
			owned[gamePassId] = benefits
		end
	end

	return owned
end

-- Get all effects player has from gamepasses
function GamePassConfig.GetPlayerEffects(player)
	local effects = {}
	local owned = GamePassConfig.GetOwnedGamePasses(player)

	for gamePassId, benefits in pairs(owned) do
		for _, effect in ipairs(benefits.effects) do
			effects[effect] = true
		end
	end

	return effects
end

-- Apply gamepass effects to player
function GamePassConfig.ApplyGamePassEffects(player)
	local effects = GamePassConfig.GetPlayerEffects(player)

	-- Apply unlimited stamina
	if effects.unlimited_stamina then
		player:SetAttribute("UnlimitedStamina", true)
	end

	-- Apply double XP
	if effects.double_xp then
		player:SetAttribute("DoubleXP", true)
	end

	-- Apply auto collect
	if effects.auto_collect then
		player:SetAttribute("AutoCollect", true)
	end

	-- Apply extra pet slots
	if effects.extra_pet_slots then
		player:SetAttribute("ExtraPetSlots", true)
	end

	-- Apply instant respawn
	if effects.instant_respawn then
		player:SetAttribute("InstantRespawn", true)
	end

	-- Apply VIP status
	if effects.vip_status then
		player:SetAttribute("VIP", true)
	end

	-- Apply coin multiplier
	if effects.coin_multiplier then
		player:SetAttribute("CoinMultiplier", 2)
	end

	-- Apply speed boost
	if effects.speed_boost then
		local currentWalkSpeed = player:GetAttribute("WalkSpeedLevel") or 1
		player:SetAttribute("WalkSpeedLevel", currentWalkSpeed + 3) -- Equivalent to 3 levels
	end

	-- Apply premium areas access
	if effects.premium_areas then
		player:SetAttribute("PremiumAreasAccess", true)
	end

	-- Apply expanded storage
	if effects.expanded_storage then
		player:SetAttribute("PetCapacity", 500)
	end

	print("Applied GamePass effects for", player.Name, "Effects:", effects)
end

return GamePassConfig