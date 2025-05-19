-- ShopData.lua
-- Module for storing all shop item data
return {
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
	}
}