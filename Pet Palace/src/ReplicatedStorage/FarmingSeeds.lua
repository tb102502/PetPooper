-- FarmingSeeds.lua
-- Place in ReplicatedStorage
return {
	Seeds = {
		{
			ID = "carrot_seeds",
			Name = "Carrot Seeds",
			Price = 20,
			Currency = "Coins",
			Type = "Seed",
			ImageId = "rbxassetid://6686038519", -- Replace with appropriate asset ID
			Description = "Plant these to grow carrots! Grows in 60 seconds.",
			GrowTime = 60, -- Time in seconds
			YieldAmount = 1, -- How many crops per harvest
			ResultID = "carrot",
			FeedValue = 1 -- Pet feeding value
		},
		{
			ID = "corn_seeds",
			Name = "Corn Seeds",
			Price = 50,
			Currency = "Coins",
			Type = "Seed",
			ImageId = "rbxassetid://6686045507", -- Replace with appropriate asset ID
			Description = "Plant these to grow corn! Grows in 120 seconds.",
			GrowTime = 120, -- Time in seconds
			YieldAmount = 3, -- How many crops per harvest
			ResultID = "corn",
			FeedValue = 2 -- Pet feeding value
		},
		{
			ID = "strawberry_seeds",
			Name = "Strawberry Seeds",
			Price = 100,
			Currency = "Coins",
			Type = "Seed",
			ImageId = "rbxassetid://6686051791", -- Replace with appropriate asset ID
			Description = "Plant these to grow strawberries! Grows in 180 seconds.",
			GrowTime = 180, -- Time in seconds
			YieldAmount = 5, -- How many crops per harvest
			ResultID = "strawberry",
			FeedValue = 3 -- Pet feeding value
		},
		{
			ID = "golden_seeds",
			Name = "Golden Seeds",
			Price = 25,
			Currency = "Gems",
			Type = "Seed",
			ImageId = "rbxassetid://6686054839", -- Replace with appropriate asset ID
			Description = "Rare seeds that grow magical fruit! Grows in 300 seconds.",
			GrowTime = 300, -- Time in seconds
			YieldAmount = 1, -- How many crops per harvest
			ResultID = "golden_fruit",
			FeedValue = 10 -- Pet feeding value
		}
	},

	-- Define corresponding harvested crops
	Crops = {
		{
			ID = "carrot",
			Name = "Carrot",
			ImageId = "rbxassetid://6686041557", -- Replace with appropriate asset ID
			Description = "A freshly grown carrot! Feed it to your pet.",
			FeedValue = 1, -- Pet feeding value
			SellValue = 30 -- Coins earned if sold
		},
		{
			ID = "corn",
			Name = "Corn",
			ImageId = "rbxassetid://6686047557", -- Replace with appropriate asset ID
			Description = "Fresh corn! Feed it to your pet.",
			FeedValue = 2, -- Pet feeding value
			SellValue = 75 -- Coins earned if sold
		},
		{
			ID = "strawberry",
			Name = "Strawberry",
			ImageId = "rbxassetid://6686052839", -- Replace with appropriate asset ID
			Description = "A juicy strawberry! Feed it to your pet.",
			FeedValue = 3, -- Pet feeding value
			SellValue = 150 -- Coins earned if sold
		},
		{
			ID = "golden_fruit",
			Name = "Golden Fruit",
			ImageId = "rbxassetid://6686056891", -- Replace with appropriate asset ID
			Description = "A magical golden fruit! Greatly increases your pet's growth!",
			FeedValue = 10, -- Pet feeding value
			SellValue = 500 -- Coins earned if sold
		}
	}
}