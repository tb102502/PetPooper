-- Create this as a ModuleScript in ServerScriptService.Modules
local PetConfig = {
	-- Default pet types
	PetTypes = {
		"Corgi",
		"Cat",
		"RedPanda",
		"Hamster",
		"Panda"
	},

	-- Rarity configuration
	Rarities = {
		{name = "common", chance = 70, color = Color3.fromRGB(150, 150, 150)},
		{name = "uncommon", chance = 20, color = Color3.fromRGB(100, 200, 100)},
		{name = "rare", chance = 7, color = Color3.fromRGB(100, 100, 255)},
		{name = "epic", chance = 2.5, color = Color3.fromRGB(200, 100, 200)},
		{name = "legendary", chance = 0.5, color = Color3.fromRGB(255, 215, 0)}
	},

	-- Pet definitions
	Pets = {
		Corgi = {
			name = "Corgi",
			image = "rbxassetid://6031302950",
			model = "Corgi",
			baseStats = {
				speed = 5,
				strength = 3,
				health = 10
			}
		},
		Cat = {
			name = "Cat",
			image = "rbxassetid://6031302950",
			model = "Cat",
			baseStats = {
				speed = 7,
				strength = 2,
				health = 8
			}
		},
		RedPanda = {
			name = "RedPanda",
			image = "rbxassetid://6031302950",
			model = "RedPanda",
			baseStats = {
				speed = 8,
				strength = 1,
				health = 6
			}
		},
		Hamster = {
			name = "Hamster",
			image = "rbxassetid://6031302950",
			model = "Hamster",
			baseStats = {
				speed = 6,
				strength = 8,
				health = 15
			}
		},
		Panda = {
			name = "Panda",
			image = "rbxassetid://6031302950",
			model = "Panda",
			baseStats = {
				speed = 9,
				strength = 5,
				health = 12
			}
		}
	},

	-- Egg hatching configuration
	Eggs = {
		basic_egg = {
			name = "Basic Egg",
			image = "rbxassetid://6031302950",
			hatchTime = 5, -- seconds to hatch
			possiblePets = {"Corgi", "Cat", "RedPanda"},
			rarityWeights = {
				common = 80,
				uncommon = 15,
				rare = 5,
				epic = 0,
				legendary = 0
			}
		},
		rare_egg = {
			name = "Rare Egg",
			image = "rbxassetid://6031302950",
			hatchTime = 8,
			possiblePets = {"Corgi", "Cat", "RedPanda", "Hamster"},
			rarityWeights = {
				common = 40,
				uncommon = 30,
				rare = 20,
				epic = 8,
				legendary = 2
			}
		},
		legendary_egg = {
			name = "Legendary Egg",
			image = "rbxassetid://6031302950",
			hatchTime = 12,
				possiblePets = {"Corgi", "Cat", "RedPanda", "Hamster", "Panda"},
			rarityWeights = {
				common = 10,
				uncommon = 25,
				rare = 40,
				epic = 15,
				legendary = 10
			}
		}
	}
}

return PetConfig