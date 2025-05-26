-- Create this as ShopConfig in ServerScriptService.Modules
local ShopConfig = {
	-- Default currency types
	CurrencyTypes = {
		"Coins",
		"Gems" 
	},

	-- Initial currency for new players
	StartingCurrency = {
		Coins = 100,
		Gems = 10
	},

	-- Shop items (examples)
	Items = {
		-- Eggs
		{
			id = "basic_egg",
			name = "Basic Egg",
			description = "A basic egg with common pets",
			price = 100,
			currency = "Coins",
			category = "Eggs",
			image = "rbxassetid://6031302950"
		},
		-- Add more items as needed
	}
}

return ShopConfig