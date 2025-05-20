-- PetSpawner.server.lua
-- Place in ServerScriptService to replace the existing PetSpawningSystem script

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Load the PetMovement module
-- Create it if it doesn't exist
if not ReplicatedStorage:FindFirstChild("PetMovement") then
	local moduleScript = Instance.new("ModuleScript")
	moduleScript.Name = "PetMovement"

	-- Insert the module source here (copy from PetMovement.lua)
	moduleScript.Source = [[
    -- PetMovement module implementation should go here
    -- Copy from the PetMovement.lua artifact
    ]]

	moduleScript.Parent = ReplicatedStorage
	print("Created PetMovement module in ReplicatedStorage")
end

local PetMovement = require(ReplicatedStorage:WaitForChild("PetMovement"))

-- DIAGNOSTIC FUNCTION
local function DEBUG_LOG(message)
	print("PET_SPAWNER: " .. message)
end

-- Make sure required folders exist
if not workspace:FindFirstChild("Areas") then
	DEBUG_LOG("Areas folder not found in workspace. Creating it.")
	local areasFolder = Instance.new("Folder")
	areasFolder.Name = "Areas"
	areasFolder.Parent = workspace
end

if not ReplicatedStorage:FindFirstChild("PetModels") then
	DEBUG_LOG("PetModels folder not found in ReplicatedStorage. Creating it.")
	local petModelsFolder = Instance.new("Folder")
	petModelsFolder.Name = "PetModels"
	petModelsFolder.Parent = ReplicatedStorage
end

-- Define pet types
local PetTypes = {
	{
		name = "Common Corgi",
		rarity = "Common",
		collectValue = 1,
		modelName = "Corgi",
		chance = 85
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
	}
}

-- Define areas and their spawn configurations
local Areas = {
	{
		name = "Starter Meadow",
		maxPets = 10, 
		petSpawnRate = 3, -- seconds
		availablePets = {"Common Corgi", "Rare RedPanda"}
	},
	{
		name = "Mystic Forest",
		maxPets = 10,
		petSpawnRate = 7,
		availablePets = {"Common Corgi", "Rare RedPanda", "Epic Corgi"}
	},
	{
		name = "Dragon's Lair",
		maxPets = 10,
		petSpawnRate = 10,
		availablePets = {"Rare RedPanda", "Epic Corgi", "Legendary RedPanda"}
	}
}

-- Create the area folders if they don't exist
for _, area in ipairs(Areas) do
	if not workspace.Areas:FindFirstChild(area.name) then
		DEBUG_LOG("Creating area: " .. area.name)
		local areaFolder = Instance.new("Folder")
		areaFolder.Name = area.name
		areaFolder.Parent = workspace.Areas

		-- Create Pets folder
		local petsFolder = Instance.new("Folder")
		petsFolder.Name = "Pets"
		petsFolder.Parent = areaFolder

		-- Create SpawnLocations folder
		local spawnLocationsFolder = Instance.new("Folder")
		spawnLocationsFolder.Name = "SpawnLocations"
		spawnLocationsFolder.Parent = areaFolder

		-- Create some default spawn locations
		for j = 1, 8 do
			local spawnPart = Instance.new("Part")
			spawnPart.Name = "SpawnLocation" .. j
			spawnPart.Anchored = true
			spawnPart.CanCollide = false
			spawnPart.Transparency = 0.8
			spawnPart.Size = Vector3.new(5, 0.5, 5)

			-- Calculate position in a circular pattern
			local angle = (j - 1) * (math.pi * 2 / 8)
			local radius = 20
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius

			spawnPart.Position = Vector3.new(x, 1, z)
			spawnPart.Parent = spawnLocationsFolder
		end
	end
end

-- Create pet models if they don't exist
for _, petType in ipairs(PetTypes) do
	local modelName = petType.modelName
	if not ReplicatedStorage.PetModels:FindFirstChild(modelName) then
		DEBUG_LOG("Creating model for " .. modelName)

		-- Create a basic model
		local model = CreateBasicPetModel(modelName, modelName, Vector3.new(0, 0, 0))
		model.Parent = ReplicatedStorage.PetModels
	end
end

-- Function to create a basic pet model (fallback)
function CreateBasicPetModel(name, modelType, position)
	DEBUG_LOG("Creating basic pet model: " .. name)

	local model = Instance.new("Model")
	model.Name = name

	-- Create a humanoid for animations
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	-- Create a humanoid root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Anchored = true
	rootPart.Position = position
	rootPart.Parent = model

	-- Create a head part for the billboard GUI
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Shape = modelType == "Corgi" and Enum.PartType.Block or Enum.PartType.Ball
	head.Position = position + Vector3.new(0, 1, 0)
	head.Anchored = true
	head.CanCollide = false

	-- Set color based on model type
	if modelType == "Corgi" then
		head.Color = Color3.fromRGB(240, 195, 137) -- Tan
	else -- RedPanda
		head.Color = Color3.fromRGB(188, 74, 60) -- Reddish
	end

	head.Parent = model

	-- Create a body part
	local body = Instance.new("Part")
	body.Name = "Torso"
	body.Size = Vector3.new(2, 2, 3)
	body.Position = position + Vector3.new(0, 0, 0)
	body.Anchored = true
	body.CanCollide = false

	-- Match the head color
	body.Color = head.Color
	body.Parent = model

	-- Create eyes
	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Shape = Enum.PartType.Ball
	rightEye.Size = Vector3.new(0.4, 0.4, 0.4)
	rightEye.Position = head.Position + Vector3.new(0.5, 0.3, -0.8)
	rightEye.Color = Color3.fromRGB(0, 0, 0) -- Black
	rightEye.Anchored = true
	rightEye.CanCollide = false
	rightEye.Parent = model

	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.4, 0.4, 0.4)
	leftEye.Position = head.Position + Vector3.new(-0.5, 0.3, -0.8)
	leftEye.Color = Color3.fromRGB(0, 0, 0) -- Black
	leftEye.Anchored = true
	leftEye.CanCollide = false
	leftEye.Parent = model

	-- Set the primary part
	model.PrimaryPart = rootPart

	-- Add click detector for the model
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = rootPart

	return model
end

-- Function to choose a random pet based on rarity
function ChooseRandomPet(availablePets)
	-- Filter to available pets
	local possiblePets = {}
	local totalChance = 0

	for _, petType in ipairs(PetTypes) do
		if table.find(availablePets, petType.name) then
			table.insert(possiblePets, petType)
			totalChance = totalChance + petType.chance
		end
	end

	-- Select based on rarity chance
	local randomValue = math.random(1, totalChance)
	local currentSum = 0

	for _, petType in ipairs(possiblePets) do
		currentSum = currentSum + petType.chance
		if randomValue <= currentSum then
			return petType
		end
	end

	-- Fallback
	return possiblePets[1]
end

-- Function to get a random spawn position
function GetRandomSpawnPosition(area)
	local areaFolder = workspace.Areas:FindFirstChild(area.name)
	if not areaFolder then
		DEBUG_LOG("Area folder not found: " .. area.name)
		return Vector3.new(0, 1, 0)
	end

	local spawnLocations = areaFolder:FindFirstChild("SpawnLocations")
	if not spawnLocations or #spawnLocations:GetChildren() == 0 then
		DEBUG_LOG("No spawn locations found for " .. area.name)
		return Vector3.new(math.random(-20, 20), 1, math.random(-20, 20))
	end

	-- Choose a random spawn location
	local spawnParts = spawnLocations:GetChildren()
	local randomPart = spawnParts[math.random(1, #spawnParts)]

	if randomPart:IsA("BasePart") then
		local size = randomPart.Size
		-- Add randomness within the spawn part's boundaries
		local randomOffsetX = (math.random() - 0.5) * (size.X * 0.8)
		local randomOffsetZ = (math.random() - 0.5) * (size.Z * 0.8)

		-- Return a position with random offset from the spawn part
		return randomPart.Position + Vector3.new(randomOffsetX, 1, randomOffsetZ)
	else
		return Vector3.new(math.random(-20, 20), 1, math.random(-20, 20))
	end
end


-- Function to add particles based on rarity
function AddParticlesBasedOnRarity(petModel, rarity)
	if not petModel or not petModel:FindFirstChild("HumanoidRootPart") then
		return
	end

	if rarity == "Epic" or rarity == "Legendary" then
		-- Create an attachment for the particles
		local attachment = Instance.new("Attachment")
		attachment.Parent = petModel.HumanoidRootPart

		-- Create particle emitter
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxassetid://6880496507" -- Star/sparkle texture
		particles.LightEmission = 0.5
		particles.Lifetime = NumberRange.new(0.5, 1.5)
		particles.Speed = NumberRange.new(0.5, 1)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.4),
			NumberSequenceKeypoint.new(1, 1)
		})

		-- Different settings based on rarity
		if rarity == "Epic" then
			particles.Color = ColorSequence.new(Color3.fromRGB(138, 43, 226)) -- Purple
			particles.Size = NumberSequence.new(0.15)
			particles.Rate = 10
			particles.Name = "EpicParticles"
		else -- Legendary
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Gold
			particles.Size = NumberSequence.new(0.25)
			particles.Rate = 20
			particles.Name = "LegendaryParticles"

			-- Add extra glow for legendary
			local pointLight = Instance.new("PointLight")
			pointLight.Color = Color3.fromRGB(255, 215, 0)
			pointLight.Range = 10
			pointLight.Brightness = 1
			pointLight.Parent = petModel.HumanoidRootPart
		end

		particles.Parent = attachment
	end
end

-- Function to scale pet based on rarity
function ScalePetBasedOnRarity(petModel, rarity)
	if not petModel then return end

	local scale = 1 -- Default scale for Common

	if rarity == "Rare" then
		scale = 1.2
	elseif rarity == "Epic" then
		scale = 1.4
	elseif rarity == "Legendary" then
		scale = 1.6
	end

	-- Scale each part individually
	for _, part in pairs(petModel:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Size = part.Size * scale
		end
	end

	-- Add scale attribute
	petModel:SetAttribute("Scale", scale)
end

-- Function to create a pet at a specific position
function SpawnPet(areaName, spawnPos)
	local areaFolder = workspace.Areas:FindFirstChild(areaName)
	if not areaFolder then
		DEBUG_LOG("Area folder not found: " .. areaName)
		return
	end

	local petsFolder = areaFolder:FindFirstChild("Pets")
	if not petsFolder then
		petsFolder = Instance.new("Folder")
		petsFolder.Name = "Pets"
		petsFolder.Parent = areaFolder
	end

	-- Find area config
	local areaConfig
	for _, area in ipairs(Areas) do
		if area.name == areaName then
			areaConfig = area
			break
		end
	end

	if not areaConfig then
		DEBUG_LOG("Area config not found: " .. areaName)
		return
	end

	-- Check if we've reached the max pets for this area
	if #petsFolder:GetChildren() >= areaConfig.maxPets then
		DEBUG_LOG("Maximum pets reached for " .. areaName)
		return
	end

	-- Choose a random pet type
	local petType = ChooseRandomPet(areaConfig.availablePets)

	-- Get the model template
	local petModel
	if ReplicatedStorage.PetModels:FindFirstChild(petType.modelName) then
		petModel = ReplicatedStorage.PetModels[petType.modelName]:Clone()
	else
		petModel = CreateBasicPetModel(petType.name, petType.modelName, spawnPos)
	end

	-- Add metadata
	petModel:SetAttribute("PetType", petType.name)
	petModel:SetAttribute("Rarity", petType.rarity)
	petModel:SetAttribute("Value", petType.collectValue)

	-- Position the model
	if petModel.PrimaryPart then
		petModel:SetPrimaryPartCFrame(CFrame.new(spawnPos))
	end

	-- Add visual enhancements
	AddParticlesBasedOnRarity(petModel, petType.rarity)
	ScalePetBasedOnRarity(petModel, petType.rarity)

	-- Set up click detector if not present
	if not petModel:FindFirstChild("ClickDetector") and petModel:FindFirstChild("HumanoidRootPart") then
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = petModel.HumanoidRootPart
	end

	-- Set up with the PetMovement module - randomly choose a movement type
	local movementTypes = {
		PetMovement.MovementTypes.IDLE,
		PetMovement.MovementTypes.WANDER,
		PetMovement.MovementTypes.ORBIT
	}

	-- Configure pet movement behavior based on rarity
	local moveConfig = {
		movementType = movementTypes[math.random(1, #movementTypes)],
		moveSpeed = 2 + (petType.rarity == "Legendary" and 1.5 or 
			petType.rarity == "Epic" and 1 or 
			petType.rarity == "Rare" and 0.5 or 0),
		wanderRadius = 5 + (petType.rarity == "Legendary" and 5 or 
			petType.rarity == "Epic" and 3 or 
			petType.rarity == "Rare" and 2 or 0)
	}

	PetMovement.initPet(petModel, moveConfig)

	-- Parent to the pets folder
	petModel.Parent = petsFolder

	DEBUG_LOG("Spawned " .. petType.name .. " in " .. areaName)
	return petModel
end

-- Main spawn loop for each area
for _, area in ipairs(Areas) do
	spawn(function()
		while wait(area.petSpawnRate) do
			local spawnPos = GetRandomSpawnPosition(area)
			SpawnPet(area.name, spawnPos)
		end
	end)
end

-- Handle existing areas that might have already been created
-- Initialize their spawn loops
for _, areaFolder in pairs(workspace.Areas:GetChildren()) do
	local areaExists = false
	for _, area in ipairs(Areas) do
		if area.name == areaFolder.Name then
			areaExists = true
			break
		end
	end

	if not areaExists then
		DEBUG_LOG("Found area not in configuration: " .. areaFolder.Name)

		-- Make sure it has the required folders
		if not areaFolder:FindFirstChild("Pets") then
			local petsFolder = Instance.new("Folder")
			petsFolder.Name = "Pets"
			petsFolder.Parent = areaFolder
		end

		if not areaFolder:FindFirstChild("SpawnLocations") then
			local spawnLocationsFolder = Instance.new("Folder")
			spawnLocationsFolder.Name = "SpawnLocations"
			spawnLocationsFolder.Parent = areaFolder

			-- Create a default spawn location
			local spawnPart = Instance.new("Part")
			spawnPart.Name = "SpawnLocation"
			spawnPart.Anchored = true
			spawnPart.CanCollide = false
			spawnPart.Transparency = 0.8
			spawnPart.Size = Vector3.new(5, 0.5, 5)
			spawnPart.Position = Vector3.new(0, 1, 0)
			spawnPart.Parent = spawnLocationsFolder
		end

		-- Create a default spawn loop for this area
		spawn(function()
			while wait(15) do -- Default 15 seconds
				local spawnPos = GetRandomSpawnPosition({name = areaFolder.Name})
				SpawnPet(areaFolder.Name, spawnPos)
			end
		end)
	end
end

-- Handle cleaning up pets that have been around too long
for _, area in ipairs(Areas) do
	spawn(function()
		while wait(60) do -- Check every minute
			local areaFolder = workspace.Areas:FindFirstChild(area.name)
			if areaFolder and areaFolder:FindFirstChild("Pets") then
				local petsFolder = areaFolder.Pets

				-- If we have too many pets, remove the oldest ones
				if #petsFolder:GetChildren() > area.maxPets then
					-- Sort pets by creation time (assumption: oldest were added first)
					local pets = petsFolder:GetChildren()
					while #pets > area.maxPets do
						pets[1]:Destroy() -- Remove oldest
						table.remove(pets, 1)
					end
				end
			end
		end
	end)
end

print("Pet Spawning System initialized")