--[[
    PetSystemCore.lua - CONSOLIDATED VERSION
    Complete pet system combining all scattered pet functionality
    Created: 2025-05-24
    Consolidated: 2025-05-25 - Merged PetInitializer, spawning, movement, and collection
]]

local PetSystemCore = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")

-- Load required modules
local PetRegistry = ReplicatedStorage:FindFirstChild("Modules") and 
	ReplicatedStorage.Modules:FindFirstChild("PetRegistry") and 
	require(ReplicatedStorage.Modules.PetRegistry)

-- Constants
PetSystemCore.Constants = {
	MAX_PETS_EQUIPPED = 10,
	DEFAULT_MOVEMENT_SPEED = 16,
	DEFAULT_COLLECTION_RADIUS = 15,
	SAVE_INTERVAL = 60,
	PET_DATA_KEY = "PetData_v2",
	SPAWN_AREAS = {
		{
			name = "Starter Meadow",
			maxPets = 15,
			spawnRate = 5,
			availablePets = {"bunny", "puppy"},
			spawnLocations = {
				Vector3.new(0, 1, 0),
				Vector3.new(10, 1, 10),
				Vector3.new(-10, 1, 10),
				Vector3.new(10, 1, -10),
				Vector3.new(-10, 1, -10)
			}
		},
		{
			name = "Mystic Forest", 
			maxPets = 12,
			spawnRate = 8,
			availablePets = {"bunny", "puppy", "cat", "duck"},
			spawnLocations = {
				Vector3.new(50, 1, 0),
				Vector3.new(60, 1, 10),
				Vector3.new(40, 1, 10)
			}
		},
		{
			name = "Dragon's Lair",
			maxPets = 8,
			spawnRate = 12,
			availablePets = {"fox", "raccoon", "dragon", "unicorn"},
			spawnLocations = {
				Vector3.new(100, 1, 0),
				Vector3.new(110, 1, 10)
			}
		}
	}
}

-- Configuration
PetSystemCore.Config = {
	MaxPetsEquipped = PetSystemCore.Constants.MAX_PETS_EQUIPPED,
	EnableAutoCollection = true,
	EnableMagneticCollection = true,
	SaveOnExit = true,
	PetSpawnDistance = 5,
	PetSpeed = PetSystemCore.Constants.DEFAULT_MOVEMENT_SPEED,
	CollectionRadius = PetSystemCore.Constants.DEFAULT_COLLECTION_RADIUS,
	SpawnInterval = 1 -- Check spawning every second
}

-- Cache for active pets and player data
PetSystemCore.Cache = {
	PlayerPets = {}, -- [playerUserId] = {equippedPets = {}, ownedPets = {}}
	ActivePetInstances = {}, -- [petModelInstance] = {playerUserId, petId}
	PetDefinitions = {}, -- Pet templates and stats
	SpawnTimers = {}, -- Track spawn timing for each area
	AreaInstances = {} -- Track spawned pets per area
}

-- Remote events and functions
PetSystemCore.Remotes = {
	Events = {},
	Functions = {}
}

-- Initialize the pet system
function PetSystemCore:Initialize()
	print("PetSystemCore: Starting consolidated initialization...")

	self:InitializeRemotes()
	self:LoadPetDefinitions()
	self:SetupDataHandling()
	self:SetupPlayerEvents()
	self:SetupSpawning()
	self:StartSpawnLoop()

	print("PetSystemCore: Initialization complete")
	return true
end

-- Initialize remotes
function PetSystemCore:InitializeRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("PetSystem")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "PetSystem"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Remote events
	local events = {
		"PetEquipped",
		"PetUnequipped",
		"PetAdded", 
		"PetRemoved",
		"PetsUpdated",
		"PetLevelUp",
		"PetCollected",
		"EquipPet",
		"UnequipPet",
		"CollectPet"
	}

	for _, eventName in ipairs(events) do
		local event = remoteFolder:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
		end
		self.Remotes.Events[eventName] = event
	end

	-- Remote functions
	local functions = {
		"GetEquippedPets",
		"GetOwnedPets",
		"GetPetData"
	}

	for _, funcName in ipairs(functions) do
		local func = remoteFolder:FindFirstChild(funcName)
		if not func then
			func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
		end
		self.Remotes.Functions[funcName] = func
	end

	print("PetSystemCore: Remotes initialized")
end

-- Load pet definitions from registry or create defaults
function PetSystemCore:LoadPetDefinitions()
	if PetRegistry and PetRegistry.Pets then
		-- Use the registry system
		for _, pet in ipairs(PetRegistry.Pets) do
			self.Cache.PetDefinitions[pet.id] = {
				id = pet.id,
				name = pet.name,
				displayName = pet.displayName,
				rarity = pet.rarity,
				price = pet.price,
				abilities = pet.abilities or {},
				colors = pet.colors or {primary = Color3.white(), secondary = Color3.gray()},
				modelName = pet.modelName,
				chance = pet.chance or 10
			}
		end
		print("PetSystemCore: Loaded " .. #PetRegistry.Pets .. " pets from registry")
	else
		-- Create default pets
		self:CreateDefaultPets()
	end
end

-- Create default pet definitions
function PetSystemCore:CreateDefaultPets()
	local defaultPets = {
		{
			id = "bunny",
			name = "Bunny",
			displayName = "Fluffy Bunny", 
			rarity = "Common",
			price = 100,
			abilities = {collectSpeed = 1.0, jumpHeight = 2},
			colors = {primary = Color3.white(), secondary = Color3.fromRGB(230, 230, 230)},
			modelName = "Bunny",
			chance = 30
		},
		{
			id = "puppy",
			name = "Puppy",
			displayName = "Playful Puppy",
			rarity = "Common", 
			price = 150,
			abilities = {collectRange = 1.2, walkSpeed = 1.2},
			colors = {primary = Color3.fromRGB(194, 144, 90), secondary = Color3.fromRGB(140, 100, 60)},
			modelName = "Puppy",
			chance = 25
		},
		{
			id = "cat",
			name = "Cat",
			displayName = "Curious Cat",
			rarity = "Uncommon",
			price = 300,
			abilities = {collectRange = 1.5, walkSpeed = 1.5},
			colors = {primary = Color3.fromRGB(110, 110, 110), secondary = Color3.fromRGB(80, 80, 80)},
			modelName = "Cat",
			chance = 15
		},
		{
			id = "dragon",
			name = "Dragon", 
			displayName = "Baby Dragon",
			rarity = "Legendary",
			price = 10000,
			abilities = {coinMultiplier = 5.0, collectRange = 4.0},
			colors = {primary = Color3.fromRGB(255, 0, 0), secondary = Color3.fromRGB(255, 200, 0)},
			modelName = "Dragon",
			chance = 1
		}
	}

	for _, pet in ipairs(defaultPets) do
		self.Cache.PetDefinitions[pet.id] = pet
	end

	print("PetSystemCore: Created " .. #defaultPets .. " default pets")
end

-- Set up data handling
function PetSystemCore:SetupDataHandling()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore(self.Constants.PET_DATA_KEY)
	end)

	if success then
		self.DataStore = dataStore
		print("PetSystemCore: DataStore connected")
	else
		warn("PetSystemCore: Failed to connect to DataStore, using memory storage")
		self.IsUsingMemoryStore = true
	end

	-- Set up periodic saving
	if RunService:IsServer() then
		spawn(function()
			while true do
				wait(self.Constants.SAVE_INTERVAL)
				for _, player in ipairs(Players:GetPlayers()) do
					pcall(function()
						self:SavePlayerData(player)
					end)
				end
			end
		end)
	end
end

-- Set up player events
function PetSystemCore:SetupPlayerEvents()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if self.Config.SaveOnExit then
			self:SavePlayerData(player)
		end
		self:CleanupPlayerPets(player)
		self.Cache.PlayerPets[player.UserId] = nil
	end)

	-- Set up remote handlers
	self.Remotes.Functions.GetEquippedPets.OnServerInvoke = function(player)
		return self:GetEquippedPets(player)
	end

	self.Remotes.Functions.GetOwnedPets.OnServerInvoke = function(player)
		return self:GetOwnedPets(player)
	end

	self.Remotes.Functions.GetPetData.OnServerInvoke = function(player, petId)
		return self:GetPetData(petId)
	end

	self.Remotes.Events.EquipPet.OnServerEvent:Connect(function(player, petId)
		self:EquipPet(player, petId)
	end)

	self.Remotes.Events.UnequipPet.OnServerEvent:Connect(function(player, petId)
		self:UnequipPet(player, petId)
	end)

	self.Remotes.Events.CollectPet.OnServerEvent:Connect(function(player, petModel)
		self:HandlePetCollection(player, petModel)
	end)
end

-- Set up spawning areas
function PetSystemCore:SetupSpawning()
	-- Create Areas folder in workspace
	local areasFolder = Workspace:FindFirstChild("Areas")
	if not areasFolder then
		areasFolder = Instance.new("Folder")
		areasFolder.Name = "Areas"
		areasFolder.Parent = Workspace
	end

	-- Initialize each spawn area
	for _, areaConfig in ipairs(self.Constants.SPAWN_AREAS) do
		local areaFolder = areasFolder:FindFirstChild(areaConfig.name)
		if not areaFolder then
			areaFolder = Instance.new("Folder")
			areaFolder.Name = areaConfig.name
			areaFolder.Parent = areasFolder
		end

		-- Create Pets subfolder
		local petsFolder = areaFolder:FindFirstChild("Pets")
		if not petsFolder then
			petsFolder = Instance.new("Folder")
			petsFolder.Name = "Pets"
			petsFolder.Parent = areaFolder
		end

		-- Initialize area tracking
		self.Cache.SpawnTimers[areaConfig.name] = 0
		self.Cache.AreaInstances[areaConfig.name] = petsFolder

		print("PetSystemCore: Set up spawn area: " .. areaConfig.name)
	end
end

-- Start the main spawn loop
function PetSystemCore:StartSpawnLoop()
	spawn(function()
		while true do
			wait(self.Config.SpawnInterval)

			for _, areaConfig in ipairs(self.Constants.SPAWN_AREAS) do
				self:UpdateAreaSpawning(areaConfig)
			end
		end
	end)

	print("PetSystemCore: Spawn loop started")
end

-- Update spawning for a specific area
function PetSystemCore:UpdateAreaSpawning(areaConfig)
	local areaFolder = self.Cache.AreaInstances[areaConfig.name]
	if not areaFolder then return end

	local currentPetCount = #areaFolder:GetChildren()

	-- Check if we need to spawn more pets
	if currentPetCount < areaConfig.maxPets then
		local timeSinceLastSpawn = self.Cache.SpawnTimers[areaConfig.name]

		if timeSinceLastSpawn >= areaConfig.spawnRate then
			self:SpawnPetInArea(areaConfig)
			self.Cache.SpawnTimers[areaConfig.name] = 0
		else
			self.Cache.SpawnTimers[areaConfig.name] = timeSinceLastSpawn + self.Config.SpawnInterval
		end
	end
end

-- Spawn a pet in a specific area
function PetSystemCore:SpawnPetInArea(areaConfig)
	-- Choose random pet type from available pets
	local availablePets = {}
	for _, petId in ipairs(areaConfig.availablePets) do
		local petDef = self.Cache.PetDefinitions[petId]
		if petDef then
			table.insert(availablePets, petDef)
		end
	end

	if #availablePets == 0 then return end

	-- Weighted random selection based on chance
	local totalChance = 0
	for _, pet in ipairs(availablePets) do
		totalChance = totalChance + pet.chance
	end

	local randomValue = math.random() * totalChance
	local currentTotal = 0
	local selectedPet = nil

	for _, pet in ipairs(availablePets) do
		currentTotal = currentTotal + pet.chance
		if randomValue <= currentTotal then
			selectedPet = pet
			break
		end
	end

	if not selectedPet then
		selectedPet = availablePets[1] -- Fallback
	end

	-- Choose random spawn location
	local spawnPos = areaConfig.spawnLocations[math.random(1, #areaConfig.spawnLocations)]

	-- Add some randomness to the position
	spawnPos = spawnPos + Vector3.new(
		(math.random() - 0.5) * 10,
		0,
		(math.random() - 0.5) * 10
	)

	-- Create the pet model
	local petModel = self:CreatePetModel(selectedPet, spawnPos)
	if petModel then
		petModel.Parent = self.Cache.AreaInstances[areaConfig.name]
		print("PetSystemCore: Spawned " .. selectedPet.name .. " in " .. areaConfig.name)
	end
end

-- Create a pet model
function PetSystemCore:CreatePetModel(petDef, position)
	-- Try to get model from ReplicatedStorage first
	local petModels = ReplicatedStorage:FindFirstChild("PetModels")
	local template = petModels and petModels:FindFirstChild(petDef.modelName)

	local petModel
	if template then
		petModel = template:Clone()
	else
		-- Create basic model if template doesn't exist
		petModel = self:CreateBasicPetModel(petDef, position)
	end

	if not petModel then return nil end

	-- Set up pet attributes
	petModel.Name = petDef.name .. "_" .. tick()
	petModel:SetAttribute("PetType", petDef.id)
	petModel:SetAttribute("Rarity", petDef.rarity)
	petModel:SetAttribute("Value", petDef.price or 100)
	petModel:SetAttribute("CollectValue", petDef.abilities.coinMultiplier or 1)

	-- Position the model
	if petModel.PrimaryPart then
		petModel:SetPrimaryPartCFrame(CFrame.new(position))
	elseif petModel:FindFirstChild("HumanoidRootPart") then
		petModel.HumanoidRootPart.CFrame = CFrame.new(position)
	end

	-- Add visual effects based on rarity
	self:AddRarityEffects(petModel, petDef.rarity)

	-- Set up click detection
	self:SetupPetInteraction(petModel)

	-- Add movement behavior
	self:AddPetMovement(petModel, petDef)

	return petModel
end

-- Create basic pet model (fallback)
function PetSystemCore:CreateBasicPetModel(petDef, position)
	local model = Instance.new("Model")
	model.Name = petDef.name

	-- Create humanoid for animations
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	-- Create root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"  
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Anchored = true
	rootPart.Position = position
	rootPart.Parent = model

	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Shape = Enum.PartType.Ball
	head.Position = position + Vector3.new(0, 1, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Color = petDef.colors.primary
	head.Parent = model

	-- Create body
	local body = Instance.new("Part")
	body.Name = "Torso"
	body.Size = Vector3.new(2, 2, 3)
	body.Position = position
	body.Anchored = true
	body.CanCollide = false
	body.Color = petDef.colors.primary
	body.Parent = model

	-- Set primary part
	model.PrimaryPart = rootPart

	return model
end

-- Add rarity effects to pet
function PetSystemCore:AddRarityEffects(petModel, rarity)
	local rootPart = petModel:FindFirstChild("HumanoidRootPart") or petModel.PrimaryPart
	if not rootPart then return end

	if rarity == "Epic" or rarity == "Legendary" then
		-- Create attachment for particles
		local attachment = Instance.new("Attachment")
		attachment.Parent = rootPart

		-- Create particle emitter
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxassetid://6880496507"
		particles.LightEmission = 0.5
		particles.Lifetime = NumberRange.new(0.5, 1.5)
		particles.Speed = NumberRange.new(0.5, 1)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.4),
			NumberSequenceKeypoint.new(1, 1)
		})

		if rarity == "Epic" then
			particles.Color = ColorSequence.new(Color3.fromRGB(138, 43, 226))
			particles.Size = NumberSequence.new(0.15)
			particles.Rate = 10
		else -- Legendary
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
			particles.Size = NumberSequence.new(0.25)
			particles.Rate = 20

			-- Add glow for legendary
			local pointLight = Instance.new("PointLight")
			pointLight.Color = Color3.fromRGB(255, 215, 0)
			pointLight.Range = 10
			pointLight.Brightness = 1
			pointLight.Parent = rootPart
		end

		particles.Parent = attachment
	end
end

-- Set up pet interaction (clicking)
function PetSystemCore:SetupPetInteraction(petModel)
	local rootPart = petModel:FindFirstChild("HumanoidRootPart") or petModel.PrimaryPart
	if not rootPart then return end

	local clickDetector = rootPart:FindFirstChild("ClickDetector")
	if not clickDetector then
		clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = rootPart
	end

	clickDetector.MouseClick:Connect(function(player)
		self:HandlePetCollection(player, petModel)
	end)
end

-- Add movement behavior to pet
function PetSystemCore:AddPetMovement(petModel, petDef)
	-- Create a simple movement script
	local moveScript = Instance.new("Script")
	moveScript.Name = "PetMovement"
	moveScript.Source = [[
        local pet = script.Parent
        local humanoid = pet:FindFirstChildOfClass("Humanoid")
        local rootPart = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
        
        if not humanoid or not rootPart then return end
        
        local wanderRadius = 10
        local moveSpeed = 2
        local waitTime = math.random(2, 8)
        
        while pet.Parent and rootPart.Parent do
            wait(waitTime)
            
            -- Choose random direction within wander radius
            local originalPos = rootPart.Position
            local randomOffset = Vector3.new(
                (math.random() - 0.5) * wanderRadius * 2,
                0,
                (math.random() - 0.5) * wanderRadius * 2
            )
            
            local targetPos = originalPos + randomOffset
            
            -- Simple movement towards target
            local direction = (targetPos - rootPart.Position).Unit
            local distance = (targetPos - rootPart.Position).Magnitude
            
            if distance > 1 then
                rootPart.CFrame = rootPart.CFrame + direction * math.min(moveSpeed, distance)
            end
            
            waitTime = math.random(2, 8)
        end
    ]]
	moveScript.Parent = petModel
end

-- Handle pet collection
function PetSystemCore:HandlePetCollection(player, petModel)
	if not player or not petModel or not petModel.Parent then return end

	-- Get pet data
	local petType = petModel:GetAttribute("PetType") or "unknown"
	local petRarity = petModel:GetAttribute("Rarity") or "Common"
	local petValue = petModel:GetAttribute("CollectValue") or 1

	-- Add pet to player's collection
	local success, petId = self:AddPet(player, petType, {
		rarity = petRarity,
		collectedAt = os.time()
	})

	if success then
		-- Award currency
		local shopSystem = _G.ShopSystemCore
		if shopSystem and typeof(shopSystem.AddCurrency) == "function" then
			shopSystem:AddCurrency(player, "Coins", petValue * 10)
		end

		-- Fire collection event to client for effects
		self.Remotes.Events.PetCollected:FireClient(player, {
			name = petType,
			rarity = petRarity,
			value = petValue
		})

		-- Remove the pet from world
		petModel:Destroy()

		print("PetSystemCore: " .. player.Name .. " collected " .. petType .. " (" .. petRarity .. ")")
	else
		warn("PetSystemCore: Failed to add pet to " .. player.Name .. "'s collection")
	end
end

-- Load player data
function PetSystemCore:LoadPlayerData(player)
	if not player or not player.UserId then return end

	local defaultData = {
		equippedPets = {},
		ownedPets = {}
	}

	self.Cache.PlayerPets[player.UserId] = defaultData

	if not self.IsUsingMemoryStore then
		local success, data = pcall(function()
			return self.DataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			self.Cache.PlayerPets[player.UserId] = data
		end
	end

	-- Fire update event to client
	self.Remotes.Events.PetsUpdated:FireClient(player, self.Cache.PlayerPets[player.UserId])

	print("PetSystemCore: Loaded data for " .. player.Name)
end

-- Save player data
function PetSystemCore:SavePlayerData(player)
	if not player or not player.UserId then return end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData then return end

	if not self.IsUsingMemoryStore then
		local success, err = pcall(function()
			self.DataStore:SetAsync("Player_" .. player.UserId, playerData)
		end)

		if not success then
			warn("PetSystemCore: Failed to save player data for " .. player.Name .. ": " .. err)
		end
	end
end

-- Clean up player's active pets
function PetSystemCore:CleanupPlayerPets(player)
	if not player or not player.UserId then return end

	for petInstance, data in pairs(self.Cache.ActivePetInstances) do
		if data.playerUserId == player.UserId then
			pcall(function()
				petInstance:Destroy()
			end)
			self.Cache.ActivePetInstances[petInstance] = nil
		end
	end
end

-- Get equipped pets
function PetSystemCore:GetEquippedPets(player)
	if not player or not player.UserId then return {} end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData then return {} end

	return playerData.equippedPets or {}
end

-- Get owned pets
function PetSystemCore:GetOwnedPets(player)
	if not player or not player.UserId then return {} end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData then return {} end

	return playerData.ownedPets or {}
end

-- Get pet data
function PetSystemCore:GetPetData(petId)
	return self.Cache.PetDefinitions[petId]
end

-- Add a pet to player's collection
function PetSystemCore:AddPet(player, petId, petData)
	if not player or not player.UserId then return false end
	if not self.Cache.PetDefinitions[petId] then return false end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData then
		playerData = {equippedPets = {}, ownedPets = {}}
		self.Cache.PlayerPets[player.UserId] = playerData
	end

	-- Generate unique ID
	local uniquePetId = petId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)

	-- Create pet data
	local newPetData = petData or {}
	local basePetData = self.Cache.PetDefinitions[petId]

	newPetData.id = uniquePetId
	newPetData.petType = petId
	newPetData.name = basePetData.displayName or basePetData.name
	newPetData.rarity = newPetData.rarity or basePetData.rarity
	newPetData.level = newPetData.level or 1
	newPetData.experience = newPetData.experience or 0
	newPetData.equipped = false
	newPetData.createdAt = newPetData.createdAt or os.time()

	-- Add to owned pets
	if not playerData.ownedPets then
		playerData.ownedPets = {}
	end
	playerData.ownedPets[uniquePetId] = newPetData

	-- Fire events
	self.Remotes.Events.PetAdded:FireClient(player, uniquePetId, newPetData)
	self.Remotes.Events.PetsUpdated:FireClient(player, playerData)

	return true, uniquePetId
end

-- Equip a pet
function PetSystemCore:EquipPet(player, uniquePetId)
	if not player or not player.UserId then return false end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData or not playerData.ownedPets then return false end

	local petData = playerData.ownedPets[uniquePetId]
	if not petData then return false end

	-- Check max equipped
	local equippedCount = 0
	for _ in pairs(playerData.equippedPets or {}) do
		equippedCount = equippedCount + 1
	end

	if equippedCount >= self.Config.MaxPetsEquipped then
		return false, "Max pets equipped"
	end

	-- Mark as equipped
	petData.equipped = true
	if not playerData.equippedPets then
		playerData.equippedPets = {}
	end
	playerData.equippedPets[uniquePetId] = petData

	-- Fire events
	self.Remotes.Events.PetEquipped:FireClient(player, uniquePetId, petData)
	self.Remotes.Events.PetsUpdated:FireClient(player, playerData)

	return true
end

-- Unequip a pet
function PetSystemCore:UnequipPet(player, uniquePetId)
	if not player or not player.UserId then return false end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData or not playerData.ownedPets then return false end

	local petData = playerData.ownedPets[uniquePetId]
	if not petData or not petData.equipped then return false end

	-- Mark as unequipped
	petData.equipped = false
	if playerData.equippedPets then
		playerData.equippedPets[uniquePetId] = nil
	end

	-- Fire events
	self.Remotes.Events.PetUnequipped:FireClient(player, uniquePetId)
	self.Remotes.Events.PetsUpdated:FireClient(player, playerData)

	return true
end

return PetSystemCore