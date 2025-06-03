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
		}
	},

	Crops = {
		{
			ID = "carrot",
			Name = "Carrot",
			ImageId = "rbxassetid://6686041557",
			Description = "A freshly grown carrot! Feed it to your pig.",
			FeedValue = 1,
			SellValue = 30
		},
		{
			ID = "corn",
			Name = "Corn",
			ImageId = "rbxassetid://6686047557",
			Description = "Fresh corn! Feed it to your pig.",
			FeedValue = 2,
			SellValue = 75
		},
		{
			ID = "strawberry",
			Name = "Strawberry",
			ImageId = "rbxassetid://6686052839",
			Description = "A juicy strawberry! Feed it to your pig.",
			FeedValue = 3,
			SellValue = 150
		},
		{
			ID = "golden_fruit",
			Name = "Golden Fruit",
			ImageId = "rbxassetid://6686056891",
			Description = "A magical golden fruit! Greatly increases your pig's growth!",
			FeedValue = 10,
			SellValue = 500
		}
	}
}