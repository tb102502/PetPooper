-- UpgradeSystem.lua
-- Place this as a ModuleScript in ReplicatedStorage
-- This module defines all available upgrades and their functionality

local UpgradeSystem = {}

-- Define all upgrades available in the shop
UpgradeSystem.Upgrades = {
	-- Existing upgrades (improved)
	{
		id = "collection_speed",
		name = "Collection Speed",
		description = "Collect pets faster by {value}%",
		icon = "rbxassetid://7736833019", -- Speed icon
		baseCost = 100,
		costMultiplier = 1.5,
		maxLevel = 10,
		effectPerLevel = 10, -- 10% faster per level
		formatValue = function(level) return level * 10 end, -- Shows +10%, +20%, etc.
		category = "Collecting"
	},
	{
		id = "pet_capacity",
		name = "Pet Capacity",
		description = "Carry {value} more pets at once",
		icon = "rbxassetid://7734042650", -- Backpack icon
		baseCost = 200,
		costMultiplier = 2,
		maxLevel = 5,
		effectPerLevel = 5, -- +5 capacity per level
		formatValue = function(level) return level * 5 end, -- Shows +5, +10, etc.
		category = "Inventory"
	},
	{
		id = "collection_value",
		name = "Collection Value",
		description = "Pets are worth {value}% more coins",
		icon = "rbxassetid://7734058348", -- Money icon
		baseCost = 500,
		costMultiplier = 2.5,
		maxLevel = 10,
		effectPerLevel = 20, -- +20% value per level
		formatValue = function(level) return level * 20 end, -- Shows +20%, +40%, etc.
		category = "Collecting"
	},

	-- New upgrades
	{
		id = "pet_luck",
		name = "Pet Luck",
		description = "Increase rare pet chance by {value}%",
		icon = "rbxassetid://7743873339", -- Lucky clover icon
		baseCost = 750,
		costMultiplier = 3,
		maxLevel = 10,
		effectPerLevel = 5, -- +5% chance per level
		formatValue = function(level) return level * 5 end,
		category = "Collecting"
	},
	{
		id = "auto_collect_radius",
		name = "Auto-Collect Radius",
		description = "Collect pets from {value} studs away",
		icon = "rbxassetid://7734040283", -- Magnet icon
		baseCost = 1000,
		costMultiplier = 2.5,
		maxLevel = 8,
		effectPerLevel = 3, -- +3 studs per level
		formatValue = function(level) return 10 + (level * 3) end, -- Starts at 10 studs
		locked = true, -- Requires game pass to unlock
		gamePassRequired = "Auto-Collect",
		category = "Collecting"
	},
	{
		id = "pet_experience",
		name = "Pet Experience",
		description = "Pets gain {value}% more experience",
		icon = "rbxassetid://7733673307", -- Star icon
		baseCost = 600,
		costMultiplier = 2,
		maxLevel = 10,
		effectPerLevel = 10, -- +10% exp per level
		formatValue = function(level) return level * 10 end,
		category = "Pets"
	},
	{
		id = "coin_magnet",
		name = "Coin Magnet",
		description = "Collect coins from {value} studs away",
		icon = "rbxassetid://7734040283", -- Magnet icon
		baseCost = 450,
		costMultiplier = 2,
		maxLevel = 8,
		effectPerLevel = 2, -- +2 studs per level
		formatValue = function(level) return 5 + (level * 2) end, -- Starts at 5 studs
		category = "Collecting"
	},
	{
		id = "inventory_slots",
		name = "Inventory Size",
		description = "Add {value} pet inventory slots",
		icon = "rbxassetid://7743877596", -- Inventory icon
		baseCost = 800,
		costMultiplier = 3,
		maxLevel = 5,
		effectPerLevel = 10, -- +10 slots per level
		formatValue = function(level) return level * 10 end,
		category = "Inventory"
	},
	{
		id = "pet_speed",
		name = "Pet Speed",
		description = "Pets move {value}% faster",
		icon = "rbxassetid://7743878958", -- Speed icon
		baseCost = 350,
		costMultiplier = 1.8,
		maxLevel = 10,
		effectPerLevel = 15, -- +15% speed per level
		formatValue = function(level) return level * 15 end,
		category = "Pets"
	},
	{
		id = "rebirth_coins",
		name = "Rebirth Bonus",
		description = "Gain {value}% more coins after rebirth",
		icon = "rbxassetid://7734110840", -- Rebirth icon
		baseCost = 5000,
		costMultiplier = 5,
		maxLevel = 5,
		effectPerLevel = 20, -- +20% bonus per level
		formatValue = function(level) return level * 20 end,
		locked = true, -- Requires reaching a certain point in the game
		unlockCondition = function(playerData) return (playerData.rebirths or 0) > 0 end,
		category = "Advanced"
	}
}

-- Sort upgrades into categories
UpgradeSystem.Categories = {
	"Collecting",
	"Inventory",
	"Pets",
	"Advanced"
}

-- Get all upgrades in a category
function UpgradeSystem.GetUpgradesByCategory(category)
	local categoryUpgrades = {}
	for _, upgrade in ipairs(UpgradeSystem.Upgrades) do
		if upgrade.category == category then
			table.insert(categoryUpgrades, upgrade)
		end
	end
	return categoryUpgrades
end

-- Get an upgrade by its ID
function UpgradeSystem.GetUpgradeById(id)
	for _, upgrade in ipairs(UpgradeSystem.Upgrades) do
		if upgrade.id == id then
			return upgrade
		end
	end
	return nil
end

-- Calculate the cost of the next level
function UpgradeSystem.CalculateUpgradeCost(upgrade, currentLevel)
	if currentLevel >= upgrade.maxLevel then
		return nil -- Max level reached
	end

	local cost = upgrade.baseCost * (upgrade.costMultiplier ^ currentLevel)
	return math.floor(cost)
end

-- Get the effect value for display
function UpgradeSystem.GetUpgradeEffect(upgrade, level)
	if upgrade.formatValue then
		return upgrade.formatValue(level)
	else
		return level * upgrade.effectPerLevel
	end
end

-- Format description with actual values
function UpgradeSystem.FormatDescription(upgrade, level)
	local value = UpgradeSystem.GetUpgradeEffect(upgrade, level)
	return upgrade.description:gsub("{value}", tostring(value))
end

-- Check if an upgrade is unlocked for a player
function UpgradeSystem.IsUpgradeUnlocked(upgrade, playerData)
	if not upgrade.locked then
		return true -- Not locked, always available
	end

	if upgrade.gamePassRequired then
		-- Check if player owns the required game pass
		return (playerData.ownedGamePasses and 
			playerData.ownedGamePasses[upgrade.gamePassRequired]) or false
	end

	if upgrade.unlockCondition then
		-- Run the unlock condition function
		return upgrade.unlockCondition(playerData)
	end

	return false -- Default to locked if we can't determine
end

-- Apply upgrade effects to player stats (for client-side calculations)
function UpgradeSystem.ApplyUpgradeEffects(playerData)
	local stats = {}

	-- Initialize base stats
	stats.collectionSpeed = 1 -- Multiplier
	stats.petCapacity = 100 -- Base capacity
	stats.collectionValue = 1 -- Multiplier
	stats.petLuck = 1 -- Multiplier
	stats.autoCollectRadius = 10 -- Studs
	stats.petExperience = 1 -- Multiplier
	stats.coinMagnetRadius = 0 -- Studs
	stats.inventorySize = 100 -- Slots
	stats.petSpeed = 1 -- Multiplier
	stats.rebirthBonus = 1 -- Multiplier

	-- Check if player data exists
	if not playerData or not playerData.upgrades then
		return stats
	end

	-- Apply each upgrade effect
	for upgradeId, level in pairs(playerData.upgrades) do
		local upgrade = UpgradeSystem.GetUpgradeById(upgradeId)
		if upgrade and level > 0 then
			if upgradeId == "collection_speed" then
				stats.collectionSpeed = 1 + (level * upgrade.effectPerLevel / 100)
			elseif upgradeId == "pet_capacity" then
				stats.petCapacity = 100 + (level * upgrade.effectPerLevel)
			elseif upgradeId == "collection_value" then
				stats.collectionValue = 1 + (level * upgrade.effectPerLevel / 100)
			elseif upgradeId == "pet_luck" then
				stats.petLuck = 1 + (level * upgrade.effectPerLevel / 100)
			elseif upgradeId == "auto_collect_radius" then
				stats.autoCollectRadius = 10 + (level * upgrade.effectPerLevel)
			elseif upgradeId == "pet_experience" then
				stats.petExperience = 1 + (level * upgrade.effectPerLevel / 100)
			elseif upgradeId == "coin_magnet" then
				stats.coinMagnetRadius = 5 + (level * upgrade.effectPerLevel)
			elseif upgradeId == "inventory_slots" then
				stats.inventorySize = 100 + (level * upgrade.effectPerLevel)
			elseif upgradeId == "pet_speed" then
				stats.petSpeed = 1 + (level * upgrade.effectPerLevel / 100)
			elseif upgradeId == "rebirth_coins" then
				stats.rebirthBonus = 1 + (level * upgrade.effectPerLevel / 100)
			end
		end
	end

	return stats
end

return UpgradeSystem