
-- PetRegistry.lua
-- Centralized registry of all available pets in the game
-- Author: tb102502
-- Date: 2025-05-23 22:45:00

local PetRegistry = {}

-- Complete pet catalog with all information needed for both shop and spawning
PetRegistry.Pets = {
	-- Common Pets
	{
		id = "bunny",
		name = "Bunny",
		displayName = "Fluffy Bunny",
		description = "A cute little bunny that hops around collecting coins.",
		rarity = "Common",
		price = 100,
		modelName = "Bunny", -- Name of the model in ReplicatedStorage.PetModels
		chance = 30, -- Spawn chance weight
		abilities = {
			collectSpeed = 1.0,
			jumpHeight = 2
		},
		colors = {
			primary = Color3.fromRGB(255, 255, 255),
			secondary = Color3.fromRGB(230, 230, 230)
		},
		thumbnail = "rbxassetid://12345678", -- Optional thumbnail for shop display
		animation = "hop"
	},
	{
		id = "puppy",
		name = "Puppy",
		displayName = "Playful Puppy",
		description = "A loyal puppy that follows you everywhere.",
		rarity = "Common",
		price = 150,
		modelName = "Puppy",
		chance = 25,
		abilities = {
			collectRange = 1.2,
			walkSpeed = 1.2
		},
		colors = {
			primary = Color3.fromRGB(194, 144, 90),
			secondary = Color3.fromRGB(140, 100, 60)
		},
		animation = "walk"
	},

	-- Uncommon Pets
	{
		id = "cat",
		name = "Cat",
		displayName = "Curious Cat",
		description = "A nimble cat that can find hidden treasures.",
		rarity = "Uncommon",
		price = 300,
		modelName = "Cat",
		chance = 15,
		abilities = {
			collectRange = 1.5,
			walkSpeed = 1.5
		},
		colors = {
			primary = Color3.fromRGB(110, 110, 110),
			secondary = Color3.fromRGB(80, 80, 80)
		},
		animation = "prowl"
	},
	{
		id = "duck",
		name = "Duck",
		displayName = "Dapper Duck",
		description = "A waddling duck that brings good fortune.",
		rarity = "Uncommon",
		price = 350,
		modelName = "Duck",
		chance = 12,
		abilities = {
			coinMultiplier = 1.2,
			walkSpeed = 0.9
		},
		colors = {
			primary = Color3.fromRGB(255, 235, 100),
			secondary = Color3.fromRGB(255, 170, 0)
		},
		animation = "waddle"
	},

	-- Rare Pets
	{
		id = "fox",
		name = "Fox",
		displayName = "Clever Fox",
		description = "A sly fox that finds rare coins and gems.",
		rarity = "Rare",
		price = 750,
		modelName = "Fox",
		chance = 8,
		abilities = {
			gemChance = 1.3,
			collectRange = 1.8
		},
		colors = {
			primary = Color3.fromRGB(255, 128, 0),
			secondary = Color3.fromRGB(255, 255, 255)
		},
		animation = "trot"
	},
	{
		id = "raccoon",
		name = "Raccoon",
		displayName = "Sneaky Raccoon",
		description = "A treasure hunter that can find rare items.",
		rarity = "Rare",
		price = 850,
		modelName = "Raccoon",
		chance = 7,
		abilities = {
			coinMultiplier = 1.4,
			collectSpeed = 1.5
		},
		colors = {
			primary = Color3.fromRGB(100, 100, 100),
			secondary = Color3.fromRGB(50, 50, 50)
		},
		animation = "scamper"
	},

	-- Epic Pets
	{
		id = "dragon",
		name = "Dragon",
		displayName = "Baby Dragon",
		description = "A magical dragon that breathes golden flames.",
		rarity = "Epic",
		price = 2000,
		modelName = "Dragon",
		chance = 3,
		abilities = {
			coinMultiplier = 2.0,
			collectRange = 2.5,
			gemChance = 1.5
		},
		colors = {
			primary = Color3.fromRGB(255, 0, 0),
			secondary = Color3.fromRGB(255, 200, 0)
		},
		effects = {
			trail = true,
			particles = "fire"
		},
		animation = "fly"
	},
	{
		id = "unicorn",
		name = "Unicorn",
		displayName = "Majestic Unicorn",
		description = "A magical unicorn that turns everything to gold.",
		rarity = "Epic",
		price = 2500,
		modelName = "Unicorn",
		chance = 2,
		abilities = {
			coinMultiplier = 2.2,
			gemChance = 2.0
		},
		colors = {
			primary = Color3.fromRGB(255, 255, 255),
			secondary = Color3.fromRGB(200, 170, 255)
		},
		effects = {
			trail = true,
			particles = "sparkle"
		},
		animation = "gallop"
	},

	-- Legendary Pets
	{
		id = "phoenix",
		name = "Phoenix",
		displayName = "Fiery Phoenix",
		description = "A legendary bird of fire that brings enormous fortune.",
		rarity = "Legendary",
		price = 10000,
		modelName = "Phoenix",
		chance = 0.5,
		abilities = {
			coinMultiplier = 5.0,
			gemChance = 3.0,
			collectRange = 4.0,
			collectSpeed = 3.0
		},
		colors = {
			primary = Color3.fromRGB(255, 100, 0),
			secondary = Color3.fromRGB(255, 255, 0)
		},
		effects = {
			trail = true,
			particles = "fire",
			glow = true
		},
		animation = "soar"
	},
	{
		id = "robot",
		name = "Robot",
		displayName = "Quantum Robot",
		description = "An advanced robot with coin-collecting technology.",
		rarity = "Legendary",
		price = 12000,
		modelName = "Robot",
		chance = 0.3,
		abilities = {
			coinMultiplier = 6.0,
			collectRange = 5.0,
			walkSpeed = 2.0
		},
		colors = {
			primary = Color3.fromRGB(100, 100, 255),
			secondary = Color3.fromRGB(200, 200, 255)
		},
		effects = {
			trail = true,
			particles = "tech",
			glow = true
		},
		animation = "hover"
	}
}

-- Indexed versions for quick lookup
PetRegistry.PetsById = {}
PetRegistry.PetsByRarity = {
	Common = {},
	Uncommon = {},
	Rare = {},
	Epic = {},
	Legendary = {}
}

-- Initialize the lookup tables
for _, pet in ipairs(PetRegistry.Pets) do
	PetRegistry.PetsById[pet.id] = pet
	table.insert(PetRegistry.PetsByRarity[pet.rarity], pet)
end

-- Get a pet by its ID
function PetRegistry.GetPetById(petId)
	return PetRegistry.PetsById[petId]
end

-- Get all pets of a specific rarity
function PetRegistry.GetPetsByRarity(rarity)
	return PetRegistry.PetsByRarity[rarity] or {}
end

-- Get pet by model name
function PetRegistry.GetPetByModelName(modelName)
	for _, pet in ipairs(PetRegistry.Pets) do
		if pet.modelName == modelName then
			return pet
		end
	end
	return nil
end

-- Get random pet by rarity (for spawning)
function PetRegistry.GetRandomPetByRarity(rarity)
	local pets = PetRegistry.PetsByRarity[rarity]
	if not pets or #pets == 0 then
		return nil
	end

	-- Choose a random pet of the specified rarity
	return pets[math.random(1, #pets)]
end

-- Get weighted random pet based on chance (for egg hatching)
function PetRegistry.GetWeightedRandomPet()
	local totalChance = 0
	for _, pet in ipairs(PetRegistry.Pets) do
		totalChance = totalChance + (pet.chance or 1)
	end

	local randomValue = math.random() * totalChance
	local currentTotal = 0

	for _, pet in ipairs(PetRegistry.Pets) do
		currentTotal = currentTotal + (pet.chance or 1)
		if randomValue <= currentTotal then
			return pet
		end
	end

	-- Fallback
	return PetRegistry.Pets[1]
end

return PetRegistry