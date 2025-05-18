-- Pet Collection Simulator
-- Pet Spawning System (Script in ServerScriptService)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- ServerScriptService/PetSpawner.lua

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local CollectionService  = game:GetService("CollectionService")


-- Animation system - make sure to create this as a ModuleScript named "PetAnimationSystem" in the same folder
local PetAnimationSystem = {}

-- Standard animation IDs that are tested and work with quadruped rigs
PetAnimationSystem.AnimationIDs = {
	-- Idle animations - work well for quadrupeds
	Idle = {
		"rbxassetid://4087747788", -- Patrol Idle
		"rbxassetid://4087756747", -- Idle Animation
		"rbxassetid://3695333486", -- Standing Idle
		"rbxassetid://5319906402", -- Pet Crouch Idle 
		"rbxassetid://4585652680"  -- Creature Idle
	},

	-- Animations by pet type
	Corgi = {
		Idle = {
			"rbxassetid://5319906402", -- Dog Idle
			"rbxassetid://4585652680", -- Creature Idle
			"rbxassetid://3695333486"  -- Standing Idle
		}
	},

	RedPanda = {
		Idle = {
			"rbxassetid://4585652680", -- Creature Idle
			"rbxassetid://3695333486", -- Standing Idle
			"rbxassetid://5318918932"  -- Small Creature Idle
		}
	},

	Panda = {
		Idle = {
			"rbxassetid://4585652680", -- Creature Idle
			"rbxassetid://3695333486", -- Standing Idle
			"rbxassetid://5318918932"  -- Small Creature Idle
		}
	},

	Goat = {
		Idle = {
			"rbxassetid://4585652680", -- Creature Idle
			"rbxassetid://3695333486", -- Standing Idle
			"rbxassetid://5318918932"  -- Small Creature Idle
		}
	},

	Hamster = {
		Idle = {
			"rbxassetid://5318918932", -- Small Creature Idle
			"rbxassetid://4585652680", -- Creature Idle
			"rbxassetid://5319906402"  -- Pet Crouch Idle
		}
	}
}

-- Predefined animations for rarity types
PetAnimationSystem.RarityAnimations = {
	Common = {
		speed = 0.8,
		priority = Enum.AnimationPriority.Core
	},
	Rare = {
		speed = 0.75,
		priority = Enum.AnimationPriority.Action
	},
	Epic = {
		speed = 0.7,
		priority = Enum.AnimationPriority.Action2
	},
	Legendary = {
		speed = 0.65,
		priority = Enum.AnimationPriority.Action3
	}
}

-- Fallback function to create a CFrame animation - use this if standard animations don't work
function PetAnimationSystem.CreateCFrameAnimation(petModel)
	-- Ensure we have a model to animate
	if not petModel or not petModel:IsA("Model") or not petModel.PrimaryPart then
		return nil
	end

	-- Set up a heartbeat connection for animation
	local connection
	local startTime = tick()
	local originalCFrame = petModel:GetPrimaryPartCFrame()

	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not petModel or not petModel.Parent or not petModel.PrimaryPart then
			if connection then
				connection:Disconnect()
			end
			return
		end

		-- Calculate animation time
		local time = tick() - startTime

		-- Idle animation with slight bobbing motion
		local verticalOffset = math.sin(time * 2) * 0.1
		local rotationOffset = math.sin(time * 1.5) * 0.05

		-- Apply animation
		local newCFrame = originalCFrame * 
			CFrame.new(0, verticalOffset, 0) * 
			CFrame.Angles(rotationOffset, math.sin(time) * 0.1, 0)

		petModel:SetPrimaryPartCFrame(newCFrame)
	end)

	-- Store the connection on the model so we can disconnect it later
	local animationValue = Instance.new("ObjectValue")
	animationValue.Name = "AnimationConnection"
	animationValue.Value = connection
	animationValue.Parent = petModel

	return connection
end

-- DIAGNOSTIC FUNCTION
local function DEBUG_LOG(message)
	print("PET_SPAWNER_DEBUG: " .. message)
end

-- COMPATIBILITY FUNCTION - Use instead of FindFirstDescendant
local function FindDescendantByName(parent, name)
	-- Check direct children first
	local directChild = parent:FindFirstChild(name)
	if directChild then
		return directChild
	end

	-- Check descendants recursively
	for _, child in pairs(parent:GetChildren()) do
		local found = FindDescendantByName(child, name)
		if found then
			return found
		end
	end

	return nil
end

-- COMPATIBILITY FUNCTION - Use instead of FindFirstChildWhichIsA
local function FindChildOfClass(parent, className)
	for _, child in pairs(parent:GetChildren()) do
		if child.ClassName == className then
			return child
		end
	end

	return nil
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
		petSpawnRate = 3 - (i * 2), -- Pets spawn every 15/13/11 seconds
		maxPets = 5 + (i * 2), -- 4/6/8 pets max
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

			-- Calculate position in a circular pattern within the area
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

-- Function to choose a random pet type based on rarity chances
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

-- SIMPLIFIED PET MODEL CREATION - Defined at module level
-- This function creates a basic pet model with proper parts
local function CreateBasicPetModel(name, modelType, position)
	DEBUG_LOG("Creating basic pet model: " .. name .. " at " .. tostring(position))

	local model = Instance.new("Model")
	model.Name = name

	-- Create a humanoid for animations
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	-- Create a humanoid root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 0.5 -- Make partially visible for debugging
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
	elseif modelType == "RedPanda" then
		head.Color = Color3.fromRGB(188, 74, 60) -- Reddish
	elseif modelType == "Panda" then
		head.Color = Color3.fromRGB(240, 240, 240) -- White with black
	elseif modelType == "Goat" then
		head.Color = Color3.fromRGB(180, 180, 180) -- Light gray
	elseif modelType == "Hamster" then
		head.Color = Color3.fromRGB(220, 180, 130) -- Light brown
	else
		head.Color = Color3.fromRGB(188, 74, 60) -- Reddish (default)
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

	-- Explicitly set the primary part to HumanoidRootPart
	model.PrimaryPart = rootPart
	DEBUG_LOG("Set PrimaryPart to " .. rootPart.Name)

	-- Add a ClickDetector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = rootPart

	return model
end

-- Function to add particles based on rarity
local function AddParticlesBasedOnRarity(petModel, rarity)
	DEBUG_LOG("Adding particles for " .. rarity .. " pet")

	if not petModel or not petModel:FindFirstChild("HumanoidRootPart") then
		DEBUG_LOG("Cannot add particles - model or HumanoidRootPart missing")
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
local function ScalePetBasedOnRarity(petModel, rarity)
	DEBUG_LOG("Scaling pet based on rarity: " .. rarity)

	if not petModel then
		DEBUG_LOG("Model is nil, cannot scale")
		return
	end

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

	-- Add scale attribute to keep track
	petModel:SetAttribute("Scale", scale)
end

-- Function to add idle animation
function PetAnimationSystem.AddIdleAnimation(petModel)
	local debug = true -- Set to true for verbose logging

	local function DebugLog(message)
		if debug then
			DEBUG_LOG("ANIM: " .. message)
		end
	end

	DebugLog("Adding idle animation to " .. petModel.Name)

	-- Get the humanoid
	local humanoid = petModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		DebugLog("No humanoid found, creating one")
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = petModel
	end

	-- Make sure there's an animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		DebugLog("Creating animator")
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Extract pet type and rarity
	local petType = string.match(petModel.Name, "(%a+)") or "Corgi" -- Default to Corgi if no match
	local rarity = petModel:GetAttribute("Rarity") or "Common"

	DebugLog("Pet type: " .. petType .. ", Rarity: " .. rarity)

	-- Get appropriate animations
	local animationIds = PetAnimationSystem.AnimationIDs[petType] and 
		PetAnimationSystem.AnimationIDs[petType].Idle or 
		PetAnimationSystem.AnimationIDs.Idle

	-- Pick a random animation
	local animationId = animationIds[math.random(1, #animationIds)]
	DebugLog("Selected animation ID: " .. animationId)

	-- Create and load the animation
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local success, animTrack = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if success and animTrack then
		-- Get rarity settings
		local raritySettings = PetAnimationSystem.RarityAnimations[rarity] or PetAnimationSystem.RarityAnimations.Common

		-- Apply rarity-specific adjustments
		animTrack:AdjustSpeed(raritySettings.speed)
		animTrack.Priority = raritySettings.priority
		animTrack.Looped = true

		-- Play with slight delay to prevent synchronization
		local delayTime = math.random() * 0.5
		DebugLog("Playing animation with " .. delayTime .. "s delay")

		delay(delayTime, function()
			if animTrack and petModel.Parent then
				animTrack:Play(0.5) -- Fade in over 0.5 seconds
				DebugLog("Animation playing")
			end
		end)

		-- Store the track on the model for reference
		local trackValue = Instance.new("ObjectValue")
		trackValue.Name = "AnimationTrack"
		trackValue.Value = animTrack
		trackValue.Parent = petModel

		return animTrack
	else
		DebugLog("Animation failed to load: " .. tostring(animTrack) .. " - Falling back to CFrame animation")
		-- Fallback to CFrame animation if regular animation fails
		return PetAnimationSystem.CreateCFrameAnimation(petModel)
	end
end

-- Create or find pet models
for _, petType in ipairs(PetTypes) do
	local modelName = petType.modelName
	if not ReplicatedStorage.PetModels:FindFirstChild(modelName) then
		DEBUG_LOG("Creating model for " .. modelName)

		-- Create a basic model
		local model = CreateBasicPetModel(modelName, modelName, Vector3.new(0, 0, 0))
		model.Parent = ReplicatedStorage.PetModels
	else
		DEBUG_LOG("Model already exists for " .. modelName)
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

-- Function to find a ClickDetector in a model (compatibility)
local function FindClickDetector(model)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("ClickDetector") then
			return child
		end

		if #child:GetChildren() > 0 then
			local foundInChild = FindClickDetector(child)
			if foundInChild then
				return foundInChild
			end
		end
	end

	return nil
end

-- Function to find a ProximityPrompt in a model (compatibility)
local function FindProximityPrompt(model)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("ProximityPrompt") then
			return child
		end

		if #child:GetChildren() > 0 then
			local foundInChild = FindProximityPrompt(child)
			if foundInChild then
				return foundInChild
			end
		end
	end

	return nil
end

-- Function to create a pet at a specific position
local function CreatePet(petType, spawnPosition, areaName)
	DEBUG_LOG("Creating pet: " .. petType.name .. " in " .. areaName)

	-- Get the model template
	local petModel = nil

	-- Try to find the model in ReplicatedStorage
	if ReplicatedStorage.PetModels and ReplicatedStorage.PetModels:FindFirstChild(petType.modelName) then
		DEBUG_LOG("Found pet model in ReplicatedStorage: " .. petType.modelName)
		petModel = ReplicatedStorage.PetModels[petType.modelName]:Clone()
	else
		DEBUG_LOG("Pet model " .. petType.modelName .. " not found! Creating placeholder.")
		petModel = CreateBasicPetModel(petType.name, petType.modelName, spawnPosition)
	end

	-- Add metadata
	petModel:SetAttribute("PetType", petType.name)
	petModel:SetAttribute("Rarity", petType.rarity)
	petModel:SetAttribute("Value", petType.collectValue)

	-- Position the model at the spawn position
	if petModel then
		-- Check if PrimaryPart is set
		if not petModel.PrimaryPart then
			DEBUG_LOG("PrimaryPart not set on " .. petModel.Name .. ", looking for a suitable part")

			-- Try HumanoidRootPart first
			local hrp = petModel:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				DEBUG_LOG("Using HumanoidRootPart as PrimaryPart")
				petModel.PrimaryPart = hrp
			else
				-- Try Head
				local head = petModel:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					DEBUG_LOG("Using Head as PrimaryPart")
					petModel.PrimaryPart = head
				else
					-- Try any BasePart
					for _, part in pairs(petModel:GetChildren()) do
						if part:IsA("BasePart") then
							DEBUG_LOG("Using " .. part.Name .. " as PrimaryPart")
							petModel.PrimaryPart = part
							break
						end
					end
				end
			end
		end

		-- Double-check if PrimaryPart is set now
		if not petModel.PrimaryPart then
			DEBUG_LOG("WARNING: Could not set PrimaryPart for " .. petModel.Name)

			-- Create an emergency part if needed
			local emergencyPart = Instance.new("Part")
			emergencyPart.Name = "EmergencyPrimaryPart"
			emergencyPart.Size = Vector3.new(2, 2, 2)
			emergencyPart.Transparency = 0.7
			emergencyPart.CanCollide = false
			emergencyPart.Anchored = true
			emergencyPart.Position = spawnPosition
			emergencyPart.Parent = petModel

			petModel.PrimaryPart = emergencyPart
			DEBUG_LOG("Created emergency PrimaryPart")
		end
	end

	-- Create a ClickDetector for the pet
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20 -- Allow clicks from 20 studs away

	-- Find the best part to parent the ClickDetector to
	local targetPart = petModel.PrimaryPart
	clickDetector.Parent = targetPart

	-- When positioning the model, use CFrame for better results
	if petModel.PrimaryPart then
		petModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
		DEBUG_LOG("Positioned pet at " .. tostring(spawnPosition) .. " using PrimaryPart")

		-- Add rarity-based effects
		AddParticlesBasedOnRarity(petModel, petType.rarity)

		-- Scale the pet based on rarity
		ScalePetBasedOnRarity(petModel, petType.rarity)

		-- Add idle animation
		PetAnimationSystem.AddIdleAnimation(petModel)

		-- Add to the active pets table
		table.insert(ActivePets[areaName], petModel)

		-- Parent to the area's Pets folder
		petModel.Parent = workspace.Areas[areaName].Pets

		return petModel
	else
		DEBUG_LOG("CRITICAL ERROR: No PrimaryPart to position model!")
		return nil
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

-- Start the pet spawning system
DEBUG_LOG("Starting pet spawning system")

-- Debug visualization function - creates visible markers at spawn points
local function VisualizeSpawnPoints()
	DEBUG_LOG("Creating visualization for spawn points")

	-- For each area
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
		if i == 1 then -- Starter Meadow
			centerMarker.Color = Color3.fromRGB(0, 255, 0) -- Green
		elseif i == 2 then -- Mystic Forest
			centerMarker.Color = Color3.fromRGB(0, 0, 255) -- Blue
		else -- Dragon's Lair
			centerMarker.Color = Color3.fromRGB(255, 0, 0) -- Red
		end

		centerMarker.Transparency = 0.7
		centerMarker.Parent = workspace.DebugMarkers

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
		radiusMarker.Parent = workspace.DebugMarkers

		DEBUG_LOG("Created visualization markers for " .. area.name)
	end
end

-- Create debug markers folder if it doesn't exist
if not workspace:FindFirstChild("DebugMarkers") then
	local markersFolder = Instance.new("Folder")
	markersFolder.Name = "DebugMarkers"
	markersFolder.Parent = workspace
	DEBUG_LOG("Created DebugMarkers folder in workspace")
end

-- Visualize spawn points (only in development/studio)
if RunService:IsStudio() then
	VisualizeSpawnPoints()
end

spawn(StartSpawning)

DEBUG_LOG("Pet spawning system initialized successfully")