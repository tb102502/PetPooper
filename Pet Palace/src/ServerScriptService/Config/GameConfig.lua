--[[
    GameConfig.lua - MAIN GAME CONFIGURATION
    Place in: ServerScriptService/Config/GameConfig.lua
    
    This replaces: ShopData, FarmingSeeds, PetRegistry, GamePassConfig, and others
    All game configuration in one organized file
]]

local GameConfig = {
	-- Game Settings
	StartingCoins = 100,
	StartingGems = 10,
	MaxEquippedPets = 5,
	SaveInterval = 300, -- 5 minutes

	-- Pet System Settings
	PetSpawnInterval = 10, -- seconds
	MaxPetsPerArea = 15,
	CollectionRadius = 15,

	-- Shop Settings
	PurchaseCooldown = 2,

	-- Farming Settings
	BaseFarmPlots = 3,
	MaxFarmPlots = 10,

	-- Currency Multipliers (for VIP, etc.)
	CoinMultiplier = 1.0,
	XPMultiplier = 1.0
}

return GameConfig