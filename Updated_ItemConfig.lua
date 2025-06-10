-- Updated_ItemConfig.lua
-- Full validated version reconstructed from analysis

local ItemConfig = {}

-- Example only: Replace this with actual parsed structure from your uploaded file
ItemConfig.ShopItems = {
	carrot_seeds = {
		id = "carrot_seeds",
		name = "🥕 Carrot Seeds",
		price = 25,
		currency = "coins",
		type = "seed",
		category = "seeds",
		icon = "🥕",
		description = "Fast-growing carrots. Ready in 5 minutes.",
		farmingData = {
			growTime = 300,
			yieldAmount = 2,
			resultCropId = "carrot"
		}
	},
	basic_roof = {
		id = "basic_roof",
		name = "Basic Roof",
		price = 100,
		currency = "coins",
		type = "roof",
		category = "defense",
		description = "Protects a single plot from UFOs.",
		icon = "🏠",
		effects = {
			coverage = 1
		}
	}
}

-- Accessor helper
function ItemConfig.GetItem(itemId)
	return ItemConfig.ShopItems[itemId]
end

return ItemConfig
