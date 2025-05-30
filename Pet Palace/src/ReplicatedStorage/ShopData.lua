-- ShopData.lua
-- Module for storing all shop item data
local ShopData = {
	General = {
		{
			ID = "basic_egg",
			Name = "Basic Egg",
			Price = 100,
			Currency = "Coins",
			Type = "Egg",
			ImageId = "rbxassetid://123456789",
			Description = "A common egg with a chance to hatch into a basic pet.",
			Contents = {"Corgi", "Kitten", "Bunny"}
		},
		{
			ID = "speed_boost",
			Name = "Speed Boost",
			Price = 250,
			Currency = "Coins",
			Type = "Upgrade",
			ImageId = "rbxassetid://123456790",
			Description = "Increases your walk speed.",
			MaxLevel = 10,
			EffectPerLevel = 2
		}
	},

	Premium = {
		{
			ID = "rare_egg",
			Name = "Rare Egg",
			Price = 50,
			Currency = "Gems",
			Type = "Egg",
			ImageId = "rbxassetid://123456791",
			Description = "A rare egg with better chances for epic pets.",
			Contents = {"RedPanda", "Fox", "Owl"}
		},
		{
			ID = "vip_pass",
			Name = "VIP Pass",
			Price = 99,
			Currency = "Robux",
			Type = "Gamepass",
			ImageId = "rbxassetid://123456792",
			Description = "Grants VIP status with 2x coins and special perks.",
			GamepassID = 12345
		}
	},

	Areas = {
		{
			ID = "mystic_forest",
			Name = "Mystic Forest",
			Price = 500,
			Currency = "Coins",
			Type = "Area",
			ImageId = "rbxassetid://123456793",
			Description = "Unlock the Mystic Forest area with unique pets.",
			RequiredLevel = 5
		},
		{
			ID = "dragon_lair",
			Name = "Dragon's Lair",
			Price = 2000,
			Currency = "Coins",
			Type = "Area",
			ImageId = "rbxassetid://123456794",
			Description = "Unlock the Dragon's Lair with legendary pets.",
			RequiredLevel = 10
		}
	},

	-- Add this to your existing ShopData.lua in ReplicatedStorage
	-- This adds farming items to your shop system

	-- Add this to your ShopData table:
	Farming = {
		{
			ID = "carrot_seeds",
			Name = "Carrot Seeds",
			Price = 20,
			Currency = "Coins",
			Type = "Seed",
			ImageId = "rbxassetid://6686038519",
			Description = "Plant these to grow carrots! Grows in 60 seconds.",
			GrowTime = 60,
			YieldAmount = 1,
			ResultID = "carrot",
			FeedValue = 1
		},
		{
			ID = "corn_seeds",
			Name = "Corn Seeds",
			Price = 50,
			Currency = "Coins",
			Type = "Seed",
			ImageId = "rbxassetid://6686045507",
			Description = "Plant these to grow corn! Grows in 120 seconds.",
			GrowTime = 120,
			YieldAmount = 3,
			ResultID = "corn",
			FeedValue = 2
		},
		{
			ID = "strawberry_seeds",
			Name = "Strawberry Seeds",
			Price = 100,
			Currency = "Coins",
			Type = "Seed",
			ImageId = "rbxassetid://6686051791",
			Description = "Plant these to grow strawberries! Grows in 180 seconds.",
			GrowTime = 180,
			YieldAmount = 5,
			ResultID = "strawberry",
			FeedValue = 3
		},
		{
			ID = "golden_seeds",
			Name = "Golden Seeds",
			Price = 25,
			Currency = "Gems",
			Type = "Seed",
			ImageId = "rbxassetid://6686054839",
			Description = "Rare seeds that grow magical fruit! Grows in 300 seconds.",
			GrowTime = 300,
			YieldAmount = 1,
			ResultID = "golden_fruit",
			FeedValue = 10
		},
		{
			ID = "farm_plot_upgrade",
			Name = "Extra Farm Plot",
			Price = 500,
			Currency = "Coins",
			Type = "Upgrade",
			ImageId = "rbxassetid://6686060000",
			Description = "Unlock an additional farm plot to grow more crops!",
			MaxLevel = 7 -- Players can have up to 10 total plots (3 base + 7 upgrades)
		}
	},

	-- Farming tools category
	FarmingTools = {
		{
			ID = "watering_can",
			Name = "Watering Can",
			Price = 200,
			Currency = "Coins",
			Type = "Tool",
			ImageId = "rbxassetid://6686070000",
			Description = "Waters all your plants at once, reducing growth time by 10%.",
			Cooldown = 300,  -- 5 minutes cooldown
			Effect = 0.1     -- 10% reduction in growth time
		},
		{
			ID = "golden_shovel",
			Name = "Golden Shovel",
			Price = 40,
			Currency = "Gems",
			Type = "Tool",
			ImageId = "rbxassetid://6686075000",
			Description = "Premium tool that increases crop yield by 50%.",
			YieldBonus = 0.5  -- 50% more crops per harvest
		},
		{
			ID = "harvester",
			Name = "Auto-Harvester",
			Price = 1500,
			Currency = "Coins",
			Type = "Tool",
			ImageId = "rbxassetid://6686080000",
			Description = "Automatically harvests fully grown crops.",
			Duration = 86400  -- Lasts for 24 hours (in seconds)
		}
	}
}

return ShopData