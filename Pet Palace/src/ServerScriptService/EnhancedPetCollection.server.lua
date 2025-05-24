-- EnhancedPetCollection.server.lua
-- Server-side handling for the enhanced pet collection system
-- Author: tb102502

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectPet = RemoteEvents:WaitForChild("CollectPet")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")

-- Main game module
local MainGameModule = require(game:GetService("ServerScriptService"):WaitForChild("MainGameModule"))
local UpgradeSystem = require(ReplicatedStorage:WaitForChild("UpgradeSystem"))

-- Pet collection cache to prevent duplicate collections
local collectionCache = {}
local rarityValueBoosts = {
	Common = 1,
	Rare = 2.5,
	Epic = 8,
	Legendary = 25
}

-- Function to get rarity boost from the pet's rarity
local function getRarityBoost(rarity)
	return rarityValueBoosts[rarity] or 1
end

-- Function to handle pet collection
local function onPetCollected(player, petModel)
	if not petModel or not player then return end

	-- Generate a unique ID for this collection attempt
	local collectionId = player.UserId .. "-" .. tostring(petModel) .. "-" .. os.time()

	-- Check if already being collected (prevent multiple collections)
	if collectionCache[tostring(petModel)] then
		return false
	end

	-- Add to cache briefly
	collectionCache[tostring(petModel)] = os.time()

	-- Clear cache after 3 seconds
	task.spawn(function()
		task.wait(3)
		collectionCache[tostring(petModel)] = nil
	end)

	-- Get player data
	local playerData = MainGameModule.GetPlayerData(player)
	if not playerData then 
		warn("Failed to get player data for", player.Name)
		return false 
	end

	-- Get pet type info from model attributes
	local petType = petModel:GetAttribute("PetType") or "Unknown Pet"
	local petRarity = petModel:GetAttribute("Rarity") or "Common"
	local petValue = petModel:GetAttribute("Value") or 1

	-- Create pet type data object
	local petTypeData = {
		name = petType,
		rarity = petRarity,
		collectValue = petValue,
		modelName = petModel:GetAttribute("ModelName") or petModel.Name
	}

	-- Make sure pets table exists in player data
	if not playerData.pets then
		playerData.pets = {}
	end

	-- Check if player has room for more pets
	local maxPets = 100 -- Base capacity

	-- Add capacity from upgrades
	if playerData.upgrades and playerData.upgrades["pet_capacity"] then
		local upgrade = UpgradeSystem.GetUpgradeById("pet_capacity")
		if upgrade then
			maxPets = maxPets + (playerData.upgrades["pet_capacity"] * upgrade.effectPerLevel)
		end
	end

	-- Check if player has the extra storage pass
	if playerData.ownedGamePasses and playerData.ownedGamePasses["Extra Storage Pass"] then
		maxPets = maxPets + 200
	end

	-- If inventory is full, notify player instead of collecting
	if #playerData.pets >= maxPets then
		-- Notify player their inventory is full
		RemoteEvents.SendNotification:FireClient(
			player,
			"Inventory Full!",
			"Sell some pets before collecting more.",
			"warning"
		)
		return false
	end

	-- Calculate bonus chance for better pets based on upgrades
	local rarityBoost = 0
	if playerData.upgrades and playerData.upgrades["pet_luck"] then
		local upgrade = UpgradeSystem.GetUpgradeById("pet_luck")
		if upgrade then
			rarityBoost = playerData.upgrades["pet_luck"] * upgrade.effectPerLevel
		end
	end

	-- Add the pet to player's inventory
	local newPet = {
		id = os.time() .. "-" .. math.random(1000, 9999),
		name = petTypeData.name,
		rarity = petTypeData.rarity,
		level = 1,
		modelName = petTypeData.modelName  
	}

	table.insert(playerData.pets, newPet)

	-- Initialize player stats if needed
	if not playerData.stats then
		playerData.stats = {
			totalPetsCollected = 0,
			rareFound = 0,
			epicFound = 0,
			legendaryFound = 0,
			comboRecord = 0
		}
	end

	-- Update stats
	playerData.stats.totalPetsCollected = playerData.stats.totalPetsCollected + 1

	-- Track special rarity pets
	if petTypeData.rarity == "Rare" then
		playerData.stats.rareFound = playerData.stats.rareFound + 1
	elseif petTypeData.rarity == "Epic" then
		playerData.stats.epicFound = playerData.stats.epicFound + 1
	elseif petTypeData.rarity == "Legendary" then
		playerData.stats.legendaryFound = playerData.stats.legendaryFound + 1
	end

	-- Save player data
	MainGameModule.SavePlayerData(player)

	-- Update leaderboard values if they exist
	if player:FindFirstChild("leaderstats") then
		local pets = player.leaderstats:FindFirstChild("Pets")
		if pets then
			pets.Value = #playerData.pets
		end
	end

	-- Update the client with new data
	UpdatePlayerStats:FireClient(player, playerData)

	-- Also fire specific collection effect event
	CollectPet:FireClient(player, petModel, petTypeData)

	-- Server-side pet removal after a delay
	task.spawn(function()
		task.wait(0.5) -- Wait for client effects to finish

		-- Remove the pet from the server if it still exists
		if petModel and petModel:IsDescendantOf(game) then
			petModel:Destroy()
		end
	end)

	return true
end

-- Handle pet collection event from client
CollectPet.OnServerEvent:Connect(onPetCollected)

-- Initialize pet respawn system
local function setupPetRespawnSystem()
	-- Configure respawn times for different areas
	local areaRespawnConfig = {
		["StarterArea"] = {
			minTime = 5, -- Minimum seconds between respawns
			maxTime = 10, -- Maximum seconds between respawns
			maxPets = 15 -- Maximum number of pets in this area
		},
		["MysticForest"] = {
			minTime = 8,
			maxTime = 15,
			maxPets = 20
		},
		["DragonLair"] = {
			minTime = 12,
			maxTime = 20,
			maxPets = 25
		}
	}

	-- Default configuration for unspecified areas
	local defaultConfig = {
		minTime = 10,
		maxTime = 20,
		maxPets = 15
	}

	-- Get reference to pet templates - FIXED: Look in ReplicatedStorage instead of ServerStorage
	local petTemplates = ReplicatedStorage:FindFirstChild("PetModels")
	if not petTemplates then
		warn("Pet templates not found in ReplicatedStorage! Attempting to create folder.")
		-- Try to create the folder
		petTemplates = Instance.new("Folder")
		petTemplates.Name = "PetModels"
		petTemplates.Parent = ReplicatedStorage

		-- Create basic models as fallback
		local function CreateBasicPetModel(name, color)
			local model = Instance.new("Model")
			model.Name = name

			-- Create humanoid
			local humanoid = Instance.new("Humanoid")
			humanoid.Parent = model

			-- Create root part
			local rootPart = Instance.new("Part")
			rootPart.Name = "HumanoidRootPart"
			rootPart.Size = Vector3.new(2, 2, 1)
			rootPart.Transparency = 1
			rootPart.CanCollide = false
			rootPart.Parent = model

			-- Create body
			local body = Instance.new("Part")
			body.Name = "Body"
			body.Size = Vector3.new(2, 1, 3)
			body.Color = color or Color3.fromRGB(255, 200, 100)
			body.Position = rootPart.Position
			body.Parent = model

			-- Set primary part
			model.PrimaryPart = rootPart

			return model
		end

		-- Create basic models
		local corgi = CreateBasicPetModel("Corgi", Color3.fromRGB(240, 195, 137))
		corgi.Parent = petTemplates

		local redPanda = CreateBasicPetModel("RedPanda", Color3.fromRGB(188, 74, 60))
		redPanda.Parent = petTemplates

		print("Created basic pet models in ReplicatedStorage.PetModels")
		

		-- Function to spawn a pet at a specific spawn location
local function spawnPetAtLocation(spawnPoint, areaName)
	-- Get all available pet types
	local petTypes = MainGameModule.PetTypes
	if not petTypes or #petTypes == 0 then
		warn("No pet types defined in MainGameModule!")
		return
	end

	-- Weight selection by rarity
	local totalWeight = 0
	local weights = {}

	for i, petType in ipairs(petTypes) do
		local weight = 100 / (petType.chance or 1)
		weights[i] = weight
		totalWeight = totalWeight + weight
	end

	-- Select random pet type based on weights
	local randomValue = math.random() * totalWeight
	local cumulativeWeight = 0
	local selectedType

	for i, weight in pairs(weights) do
		cumulativeWeight = cumulativeWeight + weight
		if randomValue <= cumulativeWeight then
			selectedType = petTypes[i]
			break
		end
	end

	-- If no pet selected, use first one
	if not selectedType then
		selectedType = petTypes[1]
	end

	-- Get the pet model template
	local modelName = selectedType.modelName or "Bunny" -- Default fallback
	local petTemplate = petTemplates:FindFirstChild(modelName)

	-- If template not found, try a default
	if not petTemplate then
		warn("Pet template not found:", modelName)
		petTemplate = petTemplates:GetChildren()[1]

		-- If still no template, abort
		if not petTemplate then
			warn("No pet templates available!")
			return
		end
	end

	-- Clone the pet model
	local newPet = petTemplate:Clone()

	-- Position at spawn point
	local spawnPosition = spawnPoint.Position + Vector3.new(0, newPet:GetExtentsSize().Y/2 + 0.5, 0)

	if newPet:IsA("Model") and newPet.PrimaryPart then
		newPet:SetPrimaryPartCFrame(
			CFrame.new(spawnPosition) * 
				CFrame.Angles(0, math.random(0, 359) * math.rad(1), 0)
		)
	else
		newPet.Position = spawnPosition
	end

	-- Set attributes
	newPet:SetAttribute("PetType", selectedType.name)
	newPet:SetAttribute("Rarity", selectedType.rarity)
	newPet:SetAttribute("Value", selectedType.collectValue)
	newPet:SetAttribute("ModelName", modelName)
	newPet:SetAttribute("AreaOrigin", areaName)

	-- Add animation if it's a model
	if newPet:IsA("Model") and newPet.PrimaryPart and newPet:FindFirstChild("Humanoid") then
		-- Look for animation script
		local animScript = newPet:FindFirstChild("AnimationScript")
		if not animScript then
			-- Create simple idle animation
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://507766388" -- Generic idle animation

			local humanoid = newPet:FindFirstChild("Humanoid")
			local animTrack = humanoid:LoadAnimation(animation)

			-- Play idle animation
			animTrack:Play()
			animTrack:AdjustSpeed(0.8)
		end
	elseif newPet:IsA("Model") and newPet.PrimaryPart then
		-- Add simple hover animation
		task.spawn(function()
			local origin = newPet.PrimaryPart.Position
			local startTime = os.time()

			while newPet and newPet.Parent and newPet.PrimaryPart do
				local elapsed = os.time() - startTime
				local offset = math.sin(elapsed * 0.8) * 0.3

				newPet:SetPrimaryPartCFrame(
					CFrame.new(origin.X, origin.Y + offset, origin.Z) *
						CFrame.Angles(0, elapsed * 0.2 % (math.pi * 2), 0)
				)

				task.wait(0.03)
			end
		end)
	end

	-- Set parent to pets folder in area
	local petsFolder = workspace.Areas[areaName]:FindFirstChild("Pets")
	if not petsFolder then
		petsFolder = Instance.new("Folder")
		petsFolder.Name = "Pets"
		petsFolder.Parent = workspace.Areas[areaName]
	end

	newPet.Parent = petsFolder
end

-- Function to spawn a pet in an area
local function spawnPetInArea(areaModel)
	-- Get the area name
	local areaName = areaModel.Name

	-- Get the configuration for this area, or default if not specified
	local config = areaRespawnConfig[areaName] or defaultConfig

	-- Get pets folder or create if it doesn't exist
	local petsFolder = areaModel:FindFirstChild("Pets")
	if not petsFolder then
		petsFolder = Instance.new("Folder")
		petsFolder.Name = "Pets"
		petsFolder.Parent = areaModel
	end

	-- Check if we're at the pet limit
	if #petsFolder:GetChildren() >= config.maxPets then
		return
	end

	-- Get spawn locations folder
	local spawnLocations = areaModel:FindFirstChild("PetSpawnLocations")
	if not spawnLocations or #spawnLocations:GetChildren() == 0 then
		-- If no spawn locations found, use area bounds to pick a random position
		local primaryPart = areaModel.PrimaryPart
		if not primaryPart then
			for _, part in pairs(areaModel:GetChildren()) do
				if part:IsA("BasePart") and part.Name:lower():find("ground") then
					primaryPart = part
					break
				end
			end
		end

		-- If still no primary part, we can't spawn
		if not primaryPart then return end

		-- Generate a random position on the ground
		local extents = primaryPart.Size * 0.5
		local randomPos = Vector3.new(
			primaryPart.Position.X + math.random(-extents.X * 0.8, extents.X * 0.8),
			primaryPart.Position.Y + extents.Y + 1, -- Slightly above ground
			primaryPart.Position.Z + math.random(-extents.Z * 0.8, extents.Z * 0.8)
		)

		-- Create a temporary spawn location
		local tempSpawn = Instance.new("Part")
		tempSpawn.Anchored = true
		tempSpawn.CanCollide = false
		tempSpawn.Transparency = 1
		tempSpawn.Position = randomPos
		tempSpawn.Parent = workspace

		-- Spawn the pet
		spawnPetAtLocation(tempSpawn, areaName)

		-- Remove temp part
		tempSpawn:Destroy()
	else
		-- Get random spawn location
		local spawnPoints = spawnLocations:GetChildren()
		local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]

		if spawnPoint then
			spawnPetAtLocation(spawnPoint, areaName)
		end
	end
end

-- Main respawn loop
task.spawn(function()
	while task.wait(1) do
		-- Check each area
		for _, areaModel in pairs(workspace.Areas:GetChildren()) do
			if areaModel:IsA("Model") then
				local areaName = areaModel.Name
				local config = areaRespawnConfig[areaName] or defaultConfig

				-- Get or create pets folder
				local petsFolder = areaModel:FindFirstChild("Pets")
				if not petsFolder then
					petsFolder = Instance.new("Folder")
					petsFolder.Name = "Pets"
					petsFolder.Parent = areaModel
				end

				-- Spawn a pet if below the maximum
				if #petsFolder:GetChildren() < config.maxPets then
					-- Random chance to spawn based on config
					local respawnChance = 1 / (config.minTime + (config.maxTime - config.minTime))
					if math.random() < respawnChance then
						spawnPetInArea(areaModel)
					end
				end
			end
		end
	end
end)
end

-- Initialize the pet collection and respawn system
	setupPetRespawnSystem()
	end

print("Enhanced pet collection system initialized")