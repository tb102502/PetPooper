-- Updated PetSpawner.server.lua
-- Modified to use the centralized pet modules

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for modules to be available or create them if needed
local Modules = ReplicatedStorage:FindFirstChild("Modules")
if not Modules then
	Modules = Instance.new("Folder")
	Modules.Name = "Modules"
	Modules.Parent = ReplicatedStorage
	print("Created Modules folder in ReplicatedStorage")
end

-- Wait for PetInitializer 
local PetInitializer
spawn(function()
	while true do
		if ServerScriptService:FindFirstChild("PetInitializer") then
			PetInitializer = require(ServerScriptService.PetInitializer)
			break
		end
		wait(1)
		print("Waiting for PetInitializer...")
	end
end)

-- DIAGNOSTIC FUNCTION
local function DEBUG_LOG(message)
	print("PET_SPAWNER_DEBUG: " .. message)
end

-- Check if ReplicatedStorage.PetModels exists, if not, create it
if not ReplicatedStorage:FindFirstChild("PetModels") then
	DEBUG_LOG("PetModels folder not found in ReplicatedStorage. Creating it.")
	local petModelsFolder = Instance.new("Folder")
	petModelsFolder.Name = "PetModels"
	petModelsFolder.Parent = ReplicatedStorage
end

-- Verify workspace.Areas folder exists
if not workspace:FindFirstChild("Areas") then
	DEBUG_LOG("Areas folder not found in workspace. Creating it.")
	local areasFolder = Instance.new("Folder")
	areasFolder.Name = "Areas"
	areasFolder.Parent = workspace
end

-- Define pet types (would be in a module in a real game)
local PetTypes = {
	{
		name = "Common Corgi",
		rarity = "Common",
		collectValue = 1,
		modelName = "Corgi", -- This would be a model in ReplicatedStorage.PetModels
		chance = 40 -- percentage chance of getting this pet
	},
	{
		name = "Rare RedPanda",
		rarity = "Rare",
		collectValue = 5,
		modelName = "RedPanda",
		chance = 10
	},
	{
		name = "Epic Corgi",
		rarity = "Epic",
		collectValue = 20,
		modelName = "Corgi",
		chance = 4
	},
	{
		name = "Legendary RedPanda",
		rarity = "Legendary",
		collectValue = 100,
		modelName = "RedPanda",
		chance = 1
	},
	-- New pet types
	{
		name = "Common Hamster",
		rarity = "Common",
		collectValue = 2,
		modelName = "Hamster",
		chance = 35
	},
	{
		name = "Rare Hamster",
		rarity = "Rare",
		collectValue = 8,
		modelName = "Hamster",
		chance = 6
	},
	{
		name = "Common Goat",
		rarity = "Common",
		collectValue = 3,
		modelName = "Goat",
		chance = 30
	},
	{
		name = "Rare Goat",
		rarity = "Rare",
		collectValue = 12,
		modelName = "Goat",
		chance = 5
	},
	{
		name = "Epic Goat",
		rarity = "Epic",
		collectValue = 30,
		modelName = "Goat",
		chance = 2
	},
	{
		name = "Common Panda",
		rarity = "Common",
		collectValue = 4,
		modelName = "Panda",
		chance = 25
	},
	{
		name = "Rare Panda",
		rarity = "Rare",
		collectValue = 15,
		modelName = "Panda",
		chance = 5
	},
	{
		name = "Epic Panda",
		rarity = "Epic",
		collectValue = 40,
		modelName = "Panda",
		chance = 1.5
	},
	{
		name = "Legendary Panda",
		rarity = "Legendary",
		collectValue = 150,
		modelName = "Panda",
		chance = 0.5
	}
}

-- Create the area folders if they don't exist
local areaNames = {"Starter Meadow", "Mystic Forest", "Dragon's Lair"}
for _, areaName in ipairs(areaNames) do
	if not workspace.Areas:FindFirstChild(areaName) then
		DEBUG_LOG("Creating area: " .. areaName)
		local areaFolder = Instance.new("Folder")
		areaFolder.Name = areaName
		areaFolder.Parent = workspace.Areas
	end
end

-- Define areas with their spawn configurations
local Areas = {}
for i, areaName in ipairs(areaNames) do
	local availablePets
	local areaPosition
	local spawnRadius

	if i == 1 then -- Starter Meadow
		availablePets = {"Common Corgi", "Rare RedPanda", "Common Hamster", "Common Goat"}
		areaPosition = Vector3.new(-308.778, 59.051, 68.064) -- Exact position of Starter Meadow
		spawnRadius = 40 -- Adjust this to match the size of your area
	elseif i == 2 then -- Mystic Forest
		availablePets = {"Common Corgi", "Rare RedPanda", "Epic Corgi", "Rare Hamster", "Common Goat", "Rare Goat", "Common Panda", "Rare Panda"}
		areaPosition = Vector3.new(-300, 59, 200) -- Example position - replace with actual Mystic Forest position
		spawnRadius = 50
	else -- Dragon's Lair
		availablePets = {"Rare RedPanda", "Epic Corgi", "Legendary RedPanda", "Rare Hamster", "Rare Goat", "Epic Goat", "Rare Panda", "Epic Panda", "Legendary Panda"}
		areaPosition = Vector3.new(-400, 59, 300) -- Example position - replace with actual Dragon's Lair position
		spawnRadius = 60
	end

	local area = {
		name = areaName,
		petSpawnRate = 7 - (i * 2), -- Pets spawn every 5/3/1 seconds
		maxPets = 5 + (i * 2), -- 7/9/11 pets max
		availablePets = availablePets,
		areaPosition = areaPosition,
		spawnRadius = spawnRadius,
		spawnBounds = {
			min = Vector3.new(areaPosition.X - spawnRadius, areaPosition.Y - 5, areaPosition.Z - spawnRadius),
			max = Vector3.new(areaPosition.X + spawnRadius, areaPosition.Y + 10, areaPosition.Z + spawnRadius)
		}
	}

	DEBUG_LOG("Configured " .. areaName .. " at position " .. tostring(areaPosition))

	-- Create pets container if it doesn't exist
	if not workspace.Areas[areaName]:FindFirstChild("Pets") then
		local petsFolder = Instance.new("Folder")
		petsFolder.Name = "Pets"
		petsFolder.Parent = workspace.Areas[areaName]
		DEBUG_LOG("Created Pets folder for " .. areaName)
	end

	-- Create spawn locations folder if it doesn't exist
	if not workspace.Areas[areaName]:FindFirstChild("SpawnLocations") then
		local spawnLocationsFolder = Instance.new("Folder")
		spawnLocationsFolder.Name = "SpawnLocations"
		spawnLocationsFolder.Parent = workspace.Areas[areaName]

		-- Create some default spawn locations
		for j = 1, 12 do
			local spawnPart = Instance.new("Part")
			spawnPart.Name = "SpawnLocation" .. j
			spawnPart.Anchored = true
			spawnPart.CanCollide = false
			spawnPart.Transparency = 0.8
			spawnPart.Size = Vector3.new(5, 0.5, 5)

			-- Calculate position in a circular pattern
			local angle = (j - 1) * (math.pi * 2 / 12)
			local radius = spawnRadius * 0.7 -- Use 70% of the radius for a nice distribution
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius

			-- Position relative to area center
			spawnPart.Position = Vector3.new(
				areaPosition.X + x, 
				areaPosition.Y, 
				areaPosition.Z + z
			)
			spawnPart.Parent = spawnLocationsFolder
		end

		DEBUG_LOG("Created spawn locations for " .. areaName)
	end

	-- Set the spawnLocations reference
	area.spawnLocations = workspace.Areas[areaName].SpawnLocations

	table.insert(Areas, area)
end

-- Create a folder to keep track of active pets in each area
local ActivePets = {}
for _, area in ipairs(Areas) do
	ActivePets[area.name] = {}
end

-- Function to choose a random pet based on rarity chances
local function ChooseRandomPet(availablePets)
	-- Filter pet types to just the available ones for this area
	local possiblePets = {}
	local totalChance = 0

	for _, petType in ipairs(PetTypes) do
		if table.find(availablePets, petType.name) then
			table.insert(possiblePets, petType)
			totalChance = totalChance + petType.chance
		end
	end

	-- Choose a random pet based on chance
	local randomValue = math.random(1, totalChance)
	local currentSum = 0

	for _, petType in ipairs(possiblePets) do
		currentSum = currentSum + petType.chance
		if randomValue <= currentSum then
			return petType
		end
	end

	-- Fallback to the first pet if something goes wrong
	return possiblePets[1]
end

-- Function to get a random spawn position in an area
local function GetRandomSpawnPosition(area)
	DEBUG_LOG("Getting random spawn position for " .. area.name)

	-- Method 1: Use predefined spawn locations if available
	if area.spawnLocations and #area.spawnLocations:GetChildren() > 0 then
		local spawnParts = area.spawnLocations:GetChildren()
		DEBUG_LOG("Found " .. #spawnParts .. " spawn parts in " .. area.name)

		local randomPart = spawnParts[math.random(1, #spawnParts)]

		if randomPart:IsA("BasePart") then
			local size = randomPart.Size
			-- Add randomness within the spawn part's boundaries
			local randomOffsetX = (math.random() - 0.5) * (size.X * 0.8)
			local randomOffsetZ = (math.random() - 0.5) * (size.Z * 0.8)

			-- Return a position with random offset from the spawn part
			local spawnPos = randomPart.Position + Vector3.new(randomOffsetX, 1, randomOffsetZ)
			DEBUG_LOG("Using spawn part position: " .. tostring(spawnPos))
			return spawnPos
		else
			DEBUG_LOG("Spawn part is not a BasePart: " .. randomPart.ClassName)
			return randomPart.Position
		end
	else
		DEBUG_LOG("No spawn locations found for " .. area.name .. ", using random coordinates")
	end

	-- Method 2: Generate a completely random position within area boundaries
	local areaPos = area.areaPosition or Vector3.new(0, 0, 0)
	local bounds = area.spawnBounds or {
		min = Vector3.new(areaPos.X - 20, areaPos.Y, areaPos.Z - 20),
		max = Vector3.new(areaPos.X + 20, areaPos.Y + 5, areaPos.Z + 20)
	}

	-- Generate random coordinates within the boundaries
	local randomX = bounds.min.X + math.random() * (bounds.max.X - bounds.min.X)
	local randomY = bounds.min.Y + math.random() * (bounds.max.Y - bounds.min.Y)
	local randomZ = bounds.min.Z + math.random() * (bounds.max.Z - bounds.min.Z)

	local randomPosition = Vector3.new(randomX, randomY, randomZ)
	DEBUG_LOG("Using random position: " .. tostring(randomPosition) .. " for area at " .. tostring(areaPos))
	return randomPosition
end

-- Function to create a pet at a specific position
local function CreatePet(petType, spawnPosition, areaName)
	DEBUG_LOG("Creating pet: " .. petType.name .. " in " .. areaName)

	-- Wait for PetInitializer to be loaded
	while not PetInitializer do
		wait(0.5)
		DEBUG_LOG("Waiting for PetInitializer module...")
	end

	-- Get the model template
	local petModel = nil

	-- Check if model exists and clone properly
	if ReplicatedStorage.PetModels and ReplicatedStorage.PetModels:FindFirstChild(petType.modelName) then
		DEBUG_LOG("Found pet model in ReplicatedStorage: " .. petType.modelName)
		petModel = ReplicatedStorage.PetModels[petType.modelName]:Clone()

		-- Add debug for Corgi model specifically
		if petType.modelName == "Corgi" then
			DEBUG_LOG("Cloning Corgi model - checking structure:")
			for _, child in pairs(petModel:GetChildren()) do
				DEBUG_LOG("  - " .. child.Name .. " (" .. child.ClassName .. ")")
			end
		end
	else
		DEBUG_LOG("Pet model " .. petType.modelName .. " not found! Creating placeholder.")
		petModel = PetInitializer.CreateBasicPetModel(petType.name, petType.modelName, spawnPosition)
	end

	-- Make sure model has required attributes
	petModel:SetAttribute("PetType", petType.name)
	petModel:SetAttribute("Rarity", petType.rarity)
	petModel:SetAttribute("Value", petType.collectValue)

	-- Ensure PrimaryPart is set and model is positioned correctly
	if not petModel.PrimaryPart then
		for _, part in pairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				petModel.PrimaryPart = part
				DEBUG_LOG("Set " .. part.Name .. " as PrimaryPart for " .. petType.name)
				break
			end
		end
	end

	if petModel.PrimaryPart then
		petModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition))

		-- Use PetInitializer to setup behaviors
		PetInitializer.SetupPet(petModel)

		-- Add to the active pets table
		table.insert(ActivePets[areaName], petModel)

		-- Parent to the area's Pets folder
		petModel.Parent = workspace.Areas[areaName].Pets

		return petModel
	else
		DEBUG_LOG("CRITICAL ERROR: No PrimaryPart available for " .. petType.name)
		petModel:Destroy()
		return nil
	end
end

-- Function to clean up pets that have been around too long
local function CleanupOldPets(areaName, maxPets)
	if #ActivePets[areaName] > maxPets then
		DEBUG_LOG("Cleaning up old pets in " .. areaName)
		-- Remove oldest pets until we're under the limit
		while #ActivePets[areaName] > maxPets do
			local oldestPet = ActivePets[areaName][1]
			if oldestPet and oldestPet:IsA("Model") then
				oldestPet:Destroy()
			end
			table.remove(ActivePets[areaName], 1)
		end
	end
end

-- Spawn a pet for a specific area
local function SpawnPetForArea(areaIndex)
	local area = Areas[areaIndex]
	if not area then return end

	-- Check if we're at the max pets for this area
	local areaPetsFolder = workspace.Areas[area.name].Pets
	local currentPetCount = #areaPetsFolder:GetChildren()

	if currentPetCount >= area.maxPets then
		DEBUG_LOG(area.name .. " has reached max pets: " .. currentPetCount .. "/" .. area.maxPets)
		-- Clean up old pets if needed
		CleanupOldPets(area.name, area.maxPets - 1) -- Make room for one new pet
	end

	-- Choose a random pet type
	local petType = ChooseRandomPet(area.availablePets)

	-- Get a random spawn position
	local spawnPosition = GetRandomSpawnPosition(area)

	-- Create the pet
	DEBUG_LOG("Spawning " .. petType.name .. " in " .. area.name)
	local newPet = CreatePet(petType, spawnPosition, area.name)

	-- Debug: print information about spawned pet
	if newPet then
		DEBUG_LOG("Successfully spawned " .. petType.name .. " (" .. petType.rarity .. ") in " .. area.name)
	else
		DEBUG_LOG("Failed to spawn pet in " .. area.name)
	end
end

-- Spawn loop for all areas
local function StartSpawning()
	-- Initial spawn - populate all areas with some pets
	for i = 1, #Areas do
		-- Spawn multiple pets in each area
		for j = 1, math.random(2, Areas[i].maxPets) do
			SpawnPetForArea(i)
			wait(0.2) -- Small delay to prevent lag
		end
	end

	-- Continuous spawn loop
	while true do
		-- For each area
		for i, area in ipairs(Areas) do
			-- Check if area needs more pets
			local areaPetsFolder = workspace.Areas[area.name].Pets
			local currentPetCount = #areaPetsFolder:GetChildren()

			if currentPetCount < area.maxPets then
				-- Spawn a new pet
				SpawnPetForArea(i)
			else
				DEBUG_LOG(area.name .. " has reached max pets: " .. currentPetCount .. "/" .. area.maxPets)
			end

			-- Wait for the spawn rate time
			wait(area.petSpawnRate)
		end

		-- Additional wait to prevent excessive spawning
		wait(1)
	end
end

-- Create debug visualization in studio mode
if RunService:IsStudio() then
	-- Create markers at spawn points
	local debugMarkersFolder = workspace:FindFirstChild("DebugMarkers") or Instance.new("Folder")
	debugMarkersFolder.Name = "DebugMarkers"
	debugMarkersFolder.Parent = workspace

	for i, area in ipairs(Areas) do
		-- Create a marker at the area center
		local centerMarker = Instance.new("Part")
		centerMarker.Name = "AreaCenter_" .. area.name
		centerMarker.Shape = Enum.PartType.Ball
		centerMarker.Size = Vector3.new(5, 5, 5)
		centerMarker.Position = area.areaPosition
		centerMarker.Anchored = true
		centerMarker.CanCollide = false
		centerMarker.Material = Enum.Material.Neon

		-- Color based on area
		centerMarker.Color = Color3.fromRGB(
			50 + (i * 50), 
			150, 
			50 + ((3-i) * 50)
		)

		centerMarker.Transparency = 0.7
		centerMarker.Parent = debugMarkersFolder

		-- Visualize the spawn radius
		local radiusMarker = Instance.new("Part")
		radiusMarker.Name = "SpawnRadius_" .. area.name
		radiusMarker.Shape = Enum.PartType.Ball
		radiusMarker.Size = Vector3.new(area.spawnRadius * 2, 2, area.spawnRadius * 2)
		radiusMarker.Position = area.areaPosition
		radiusMarker.Anchored = true
		radiusMarker.CanCollide = false
		radiusMarker.Material = Enum.Material.ForceField
		radiusMarker.Color = centerMarker.Color
		radiusMarker.Transparency = 0.9
		radiusMarker.Parent = debugMarkersFolder
	end
end

-- Start the spawning system
DEBUG_LOG("Starting pet spawning system")
spawn(StartSpawning)

DEBUG_LOG("Pet spawning system initialized successfully with centralized behaviors")