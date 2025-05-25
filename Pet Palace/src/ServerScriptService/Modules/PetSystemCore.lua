--[[
    PetSystemCore.lua
    A consolidated module for pet functionality in PetPooper
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
    
    This module combines functionality from:
    - PetCollection.server.lua
    - EnhancedPetCollection.server.lua
    - RevisedPetSystem.lua
    - PetSpawner.server.lua
    - PetCollectionClient.client.lua
]]

local PetSystemCore = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")

-- Constants
PetSystemCore.Constants = {
	MAX_PETS_EQUIPPED = 10,
	DEFAULT_MOVEMENT_SPEED = 16,
	DEFAULT_COLLECTION_RADIUS = 15,
	SAVE_INTERVAL = 60, -- seconds
	RARITIES = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythical"
	},
	PET_DATA_KEY = "PetData_v1"
}

-- Configuration (can be modified by game)
PetSystemCore.Config = {
	MaxPetsEquipped = PetSystemCore.Constants.MAX_PETS_EQUIPPED,
	EnableAutoCollection = true,
	EnableMagneticCollection = true,
	SaveOnExit = true,
	PetSpawnDistance = 5,
	PetSpeed = PetSystemCore.Constants.DEFAULT_MOVEMENT_SPEED,
	CollectionRadius = PetSystemCore.Constants.DEFAULT_COLLECTION_RADIUS
}

-- Remote events and functions
PetSystemCore.Remotes = {
	Events = {},
	Functions = {}
}

-- Cache for active pets and player data
PetSystemCore.Cache = {
	PlayerPets = {}, -- [playerUserId] = {equippedPets = {}, ownedPets = {}}
	ActivePetInstances = {}, -- [petModelInstance] = {playerUserId, petId}
	PetDefinitions = {} -- Pet templates and stats
}

-- Create necessary remote events when initializing the module
function PetSystemCore:InitializeRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("PetSystem")

	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "PetSystem"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create remote events
	local events = {
		"PetEquipped",
		"PetUnequipped",
		"PetAdded",
		"PetRemoved",
		"PetsUpdated",
		"PetLevelUp"
	}

	for _, eventName in ipairs(events) do
		if not remoteFolder:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
			self.Remotes.Events[eventName] = event
		else
			self.Remotes.Events[eventName] = remoteFolder:FindFirstChild(eventName)
		end
	end

	-- Create remote functions
	local functions = {
		"GetEquippedPets",
		"GetOwnedPets",
		"GetPetData"
	}

	for _, funcName in ipairs(functions) do
		if not remoteFolder:FindFirstChild(funcName) then
			local func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
			self.Remotes.Functions[funcName] = func
		else
			self.Remotes.Functions[funcName] = remoteFolder:FindFirstChild(funcName)
		end
	end
end

-- Load pet templates and definitions
function PetSystemCore:LoadPetDefinitions()
	-- Check ServerStorage for pet templates
	local petTemplates = ServerStorage:FindFirstChild("PetTemplates")

	if not petTemplates then
		warn("PetSystemCore: No PetTemplates folder found in ServerStorage")
		return
	end

	-- Load all pet definitions
	for _, template in ipairs(petTemplates:GetChildren()) do
		if template:IsA("Model") then
			local config = template:FindFirstChild("Configuration")

			if config and config:IsA("Configuration") then
				local petId = template.Name
				local rarity = config:FindFirstChild("Rarity") and config.Rarity.Value or "Common"
				local speed = config:FindFirstChild("Speed") and config.Speed.Value or self.Config.PetSpeed
				local collectRadius = config:FindFirstChild("CollectRadius") and config.CollectRadius.Value or self.Config.CollectionRadius

				self.Cache.PetDefinitions[petId] = {
					template = template,
					rarity = rarity,
					speed = speed,
					collectRadius = collectRadius
				}
			end
		end
	end
end

-- Initialize the pet system
function PetSystemCore:Initialize()
	self:InitializeRemotes()
	self:LoadPetDefinitions()
	self:SetupDataHandling()
	self:SetupPlayerEvents()

	print("PetSystemCore: Initialized successfully")
end

-- Set up player-related events
function PetSystemCore:SetupPlayerEvents()
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
	end)

	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		if self.Config.SaveOnExit then
			self:SavePlayerData(player)
		end

		self:CleanupPlayerPets(player)
		self.Cache.PlayerPets[player.UserId] = nil
	end)

	-- Set up remote function handlers
	if self.Remotes.Functions.GetEquippedPets then
		self.Remotes.Functions.GetEquippedPets.OnServerInvoke = function(player)
			return self:GetEquippedPets(player)
		end
	end

	if self.Remotes.Functions.GetOwnedPets then
		self.Remotes.Functions.GetOwnedPets.OnServerInvoke = function(player)
			return self:GetOwnedPets(player)
		end
	end

	if self.Remotes.Functions.GetPetData then
		self.Remotes.Functions.GetPetData.OnServerInvoke = function(player, petId)
			return self:GetPetData(petId)
		end
	end
end

-- Set up data handling for saving and loading pet data
function PetSystemCore:SetupDataHandling()
	-- Initialize DataStore
	local petDataStore = DataStoreService:GetDataStore(self.Constants.PET_DATA_KEY)
	self.DataStore = petDataStore

	-- Set up periodic saving
	if RunService:IsServer() then
		coroutine.wrap(function()
			while true do
				wait(self.Constants.SAVE_INTERVAL)

				for _, player in ipairs(Players:GetPlayers()) do
					pcall(function()
						self:SavePlayerData(player)
					end)
				end
			end
		end)()
	end
end

-- Load player's pet data
function PetSystemCore:LoadPlayerData(player)
	if not player or not player.UserId then return end

	self.Cache.PlayerPets[player.UserId] = {
		equippedPets = {},
		ownedPets = {}
	}

	local success, data = pcall(function()
		return self.DataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		self.Cache.PlayerPets[player.UserId] = data
	end

	-- Fire update event to client
	if self.Remotes.Events.PetsUpdated then
		self.Remotes.Events.PetsUpdated:FireClient(player, self.Cache.PlayerPets[player.UserId])
	end
end

-- Save player's pet data
function PetSystemCore:SavePlayerData(player)
	if not player or not player.UserId then return end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData then return end

	local success, err = pcall(function()
		self.DataStore:SetAsync("Player_" .. player.UserId, playerData)
	end)

	if not success then
		warn("PetSystemCore: Failed to save player data for " .. player.Name .. ": " .. err)
	end
end

-- Clean up player's active pets
function PetSystemCore:CleanupPlayerPets(player)
	if not player or not player.UserId then return end

	-- Find and remove all pet instances for this player
	for petInstance, data in pairs(self.Cache.ActivePetInstances) do
		if data.playerUserId == player.UserId then
			pcall(function()
				petInstance:Destroy()
			end)
			self.Cache.ActivePetInstances[petInstance] = nil
		end
	end
end

-- Get a player's equipped pets
function PetSystemCore:GetEquippedPets(player)
	if not player or not player.UserId then return {} end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData or not playerData.equippedPets then return {} end

	return playerData.equippedPets
end

-- Get a player's owned pets
function PetSystemCore:GetOwnedPets(player)
	if not player or not player.UserId then return {} end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData or not playerData.ownedPets then return {} end

	return playerData.ownedPets
end

-- Get data for a specific pet
function PetSystemCore:GetPetData(petId)
	return self.Cache.PetDefinitions[petId] or nil
end

-- Add a pet to the player's inventory
function PetSystemCore:AddPet(player, petId, petData)
	if not player or not player.UserId then return false end
	if not self.Cache.PetDefinitions[petId] then return false end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData then
		playerData = {
			equippedPets = {},
			ownedPets = {}
		}
		self.Cache.PlayerPets[player.UserId] = playerData
	end

	-- Generate a unique ID for this specific pet instance
	local uniquePetId = petId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)

	-- Create the pet data if not provided
	if not petData then
		local baseData = self.Cache.PetDefinitions[petId]
		petData = {
			id = uniquePetId,
			petType = petId,
			rarity = baseData.rarity,
			level = 1,
			experience = 0,
			stats = {
				speed = baseData.speed,
				collectRadius = baseData.collectRadius
			},
			equipped = false,
			createdAt = os.time()
		}
	else
		petData.id = uniquePetId
		petData.petType = petId
		petData.equipped = false
	end

	-- Add to owned pets
	playerData.ownedPets[uniquePetId] = petData

	-- Fire events
	if self.Remotes.Events.PetAdded then
		self.Remotes.Events.PetAdded:FireClient(player, uniquePetId, petData)
	end

	if self.Remotes.Events.PetsUpdated then
		self.Remotes.Events.PetsUpdated:FireClient(player, playerData)
	end

	return true, uniquePetId
end

-- Remove a pet from the player's inventory
function PetSystemCore:RemovePet(player, uniquePetId)
	if not player or not player.UserId then return false end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData or not playerData.ownedPets then return false end

	local petData = playerData.ownedPets[uniquePetId]
	if not petData then return false end

	-- If equipped, unequip first
	if petData.equipped then
		self:UnequipPet(player, uniquePetId)
	end

	-- Remove from owned pets
	playerData.ownedPets[uniquePetId] = nil

	-- Fire events
	if self.Remotes.Events.PetRemoved then
		self.Remotes.Events.PetRemoved:FireClient(player, uniquePetId)
	end

	if self.Remotes.Events.PetsUpdated then
		self.Remotes.Events.PetsUpdated:FireClient(player, playerData)
	end

	return true
end

-- Equip a pet for a player
function PetSystemCore:EquipPet(player, uniquePetId)
	if not player or not player.UserId then return false end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData or not playerData.ownedPets then return false end

	local petData = playerData.ownedPets[uniquePetId]
	if not petData then return false end

	-- Check if max pets equipped
	local equippedCount = 0
	for _, _ in pairs(playerData.equippedPets) do
		equippedCount = equippedCount + 1
	end

	if equippedCount >= self.Config.MaxPetsEquipped then
		return false, "Max pets equipped"
	end

	-- Mark as equipped
	petData.equipped = true
	playerData.equippedPets[uniquePetId] = petData

	-- Spawn the pet in the world
	self:SpawnPetInstance(player, uniquePetId, petData)

	-- Fire events
	if self.Remotes.Events.PetEquipped then
		self.Remotes.Events.PetEquipped:FireClient(player, uniquePetId, petData)
	end

	if self.Remotes.Events.PetsUpdated then
		self.Remotes.Events.PetsUpdated:FireClient(player, playerData)
	end

	return true
end

-- Unequip a pet from a player
function PetSystemCore:UnequipPet(player, uniquePetId)
	if not player or not player.UserId then return false end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData or not playerData.ownedPets then return false end

	local petData = playerData.ownedPets[uniquePetId]
	if not petData or not petData.equipped then return false end

	-- Mark as unequipped
	petData.equipped = false
	playerData.equippedPets[uniquePetId] = nil

	-- Remove the pet from the world
	self:DespawnPetInstance(player, uniquePetId)

	-- Fire events
	if self.Remotes.Events.PetUnequipped then
		self.Remotes.Events.PetUnequipped:FireClient(player, uniquePetId)
	end

	if self.Remotes.Events.PetsUpdated then
		self.Remotes.Events.PetsUpdated:FireClient(player, playerData)
	end

	return true
end
function PetSystemCore:SpawnPetForPlayer(player, petId)
	local petData = self:GetPetData(player, petId)
	if not petData then return end

	local model = self:LoadPetModel(petData.type)
	if not model then return end
	model.Parent = workspace.Pets
end
-- Spawn a pet instance in the world
function PetSystemCore:SpawnPetInstance(player, uniquePetId, petData)
	if not player or not player.UserId then return nil end
	if not petData or not petData.petType then return nil end

	-- Get pet template
	local petTemplate = self.Cache.PetDefinitions[petData.petType]
	if not petTemplate or not petTemplate.template then return nil end

	-- Clone the template
	local petModel = petTemplate.template:Clone()
	petModel.Name = "Pet_" .. uniquePetId

	-- Set up pet model
	petModel:SetAttribute("Owner", player.UserId)
	petModel:SetAttribute("PetId", uniquePetId)
	petModel:SetAttribute("PetType", petData.petType)

	-- Calculate spawn position (behind player)
	local character = player.Character
	if not character then return nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	local spawnPosition = rootPart.Position - (rootPart.CFrame.LookVector * self.Config.PetSpawnDistance)
	petModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition, rootPart.Position))

	-- Set up the script to control the pet
	local petScript = Instance.new("Script")
	petScript.Name = "PetController"

	-- Simple pet following script
	petScript.Source = [[
        local pet = script.Parent
        local ownerUserId = pet:GetAttribute("Owner")
        local player = game:GetService("Players"):GetPlayerByUserId(ownerUserId)
        
        local RunService = game:GetService("RunService")
        local TweenService = game:GetService("TweenService")
        
        -- Configuration
        local followDistance = 5
        local petSpeed = ]] .. petData.stats.speed .. [[
        local updateFrequency = 0.1
        local maxDistanceBeforeWarp = 50
        
        while true do
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local character = player.Character
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local petPart = pet:FindFirstChild("PrimaryPart") or pet:FindFirstChildWhichIsA("BasePart")
                
                if rootPart and petPart then
                    local playerPosition = rootPart.Position
                    local petPosition = petPart.Position
                    
                    -- Calculate distance
                    local distance = (playerPosition - petPosition).Magnitude
                    
                    -- If too far away, warp closer
                    if distance > maxDistanceBeforeWarp then
                        local warpPosition = playerPosition - (rootPart.CFrame.LookVector * followDistance)
                        pet:SetPrimaryPartCFrame(CFrame.new(warpPosition, playerPosition))
                    else
                        -- Calculate target position (slightly behind player)
                        local targetPosition = playerPosition - (rootPart.CFrame.LookVector * followDistance)
                        
                        -- Create a tween to smoothly move the pet
                        local tweenInfo = TweenInfo.new(
                            distance / petSpeed,  -- Time based on distance and speed
                            Enum.EasingStyle.Quad,
                            Enum.EasingDirection.Out
                        )
                        
                        local tween = TweenService:Create(petPart, tweenInfo, {Position = targetPosition})
                        tween:Play()
                        
                        -- Look at player
                        local lookAtCFrame = CFrame.lookAt(petPosition, playerPosition)
                        pet:SetPrimaryPartCFrame(CFrame.new(petPosition) * lookAtCFrame.Rotation)
                    end
                end
            end
            
            wait(updateFrequency)
        end
    ]]

	petScript.Parent = petModel
	petModel.Parent = Workspace

	-- Store reference to the pet instance
	self.Cache.ActivePetInstances[petModel] = {
		playerUserId = player.UserId,
		petId = uniquePetId
	}

	return petModel
end

-- Despawn a pet instance from the world
function PetSystemCore:DespawnPetInstance(player, uniquePetId)
	if not player or not player.UserId then return false end

	-- Find the pet instance
	for petInstance, data in pairs(self.Cache.ActivePetInstances) do
		if data.playerUserId == player.UserId and data.petId == uniquePetId then
			pcall(function()
				petInstance:Destroy()
			end)
			self.Cache.ActivePetInstances[petInstance] = nil
			return true
		end
	end

	return false
end

-- Add experience to a pet
function PetSystemCore:AddPetExperience(player, uniquePetId, amount)
	if not player or not player.UserId then return false end

	local playerData = self.Cache.PlayerPets[player.UserId]
	if not playerData or not playerData.ownedPets then return false end

	local petData = playerData.ownedPets[uniquePetId]
	if not petData then return false end

	petData.experience = (petData.experience or 0) + amount

	-- Check for level up
	local experienceNeeded = self:CalculateExperienceForNextLevel(petData.level)

	if petData.experience >= experienceNeeded then
		petData.level = petData.level + 1
		petData.experience = petData.experience - experienceNeeded

		-- Increase pet stats
		petData.stats.speed = petData.stats.speed * 1.05 -- 5% speed increase per level
		petData.stats.collectRadius = petData.stats.collectRadius * 1.05 -- 5% radius increase per level

		-- Fire level up event
		if self.Remotes.Events.PetLevelUp then
			self.Remotes.Events.PetLevelUp:FireClient(player, uniquePetId, petData.level, petData.stats)
		end
	end

	-- Fire pets updated event
	if self.Remotes.Events.PetsUpdated then
		self.Remotes.Events.PetsUpdated:FireClient(player, playerData)
	end

	return true, petData.level, petData.experience
end

-- Calculate experience needed for next level
function PetSystemCore:CalculateExperienceForNextLevel(currentLevel)
	-- Simple formula: level^2 * 100
	return currentLevel * currentLevel * 100
end

-- Client-specific functionality
PetSystemCore.Client = {}

-- Initialize client-side pet system
function PetSystemCore.Client:Initialize()
	local remoteFolder = ReplicatedStorage:WaitForChild("PetSystem", 10)
	if not remoteFolder then
		warn("PetSystemCore.Client: Could not find PetSystem folder in ReplicatedStorage")
		return
	end

	-- Store remote event references
	for _, event in ipairs(remoteFolder:GetChildren()) do
		if event:IsA("RemoteEvent") then
			PetSystemCore.Remotes.Events[event.Name] = event
		elseif event:IsA("RemoteFunction") then
			PetSystemCore.Remotes.Functions[event.Name] = event
		end
	end

	-- Set up client-side event handlers
	self:SetupEventHandlers()

	-- Request initial pet data
	self:RequestPetData()

	print("PetSystemCore.Client: Initialized successfully")
end

-- Set up client-side event handlers
function PetSystemCore.Client:SetupEventHandlers()
	local events = PetSystemCore.Remotes.Events

	if events.PetsUpdated then
		events.PetsUpdated.OnClientEvent:Connect(function(petData)
			self:HandlePetsUpdated(petData)
		end)
	end

	if events.PetEquipped then
		events.PetEquipped.OnClientEvent:Connect(function(petId, petData)
			self:HandlePetEquipped(petId, petData)
		end)
	end

	if events.PetUnequipped then
		events.PetUnequipped.OnClientEvent:Connect(function(petId)
			self:HandlePetUnequipped(petId)
		end)
	end

	if events.PetLevelUp then
		events.PetLevelUp.OnClientEvent:Connect(function(petId, level, stats)
			self:HandlePetLevelUp(petId, level, stats)
		end)
	end
end

-- Handle pets updated event
function PetSystemCore.Client:HandlePetsUpdated(petData)
	-- Update local cache
	PetSystemCore.Cache.LocalPlayerPets = petData

	-- Fire local event for UI to update
	if self.OnPetsUpdated then
		self.OnPetsUpdated:Fire(petData)
	end
end

-- Handle pet equipped event
function PetSystemCore.Client:HandlePetEquipped(petId, petData)
	-- Update local UI or effects
	if self.OnPetEquipped then
		self.OnPetEquipped:Fire(petId, petData)
	end
end

-- Handle pet unequipped event
function PetSystemCore.Client:HandlePetUnequipped(petId)
	-- Update local UI or effects
	if self.OnPetUnequipped then
		self.OnPetUnequipped:Fire(petId)
	end
end

-- Handle pet level up event
function PetSystemCore.Client:HandlePetLevelUp(petId, level, stats)
	-- Show level up effects
	if self.OnPetLevelUp then
		self.OnPetLevelUp:Fire(petId, level, stats)
	end
end

-- Request pet data from server
function PetSystemCore.Client:RequestPetData()
	local functions = PetSystemCore.Remotes.Functions

	if functions.GetEquippedPets and functions.GetOwnedPets then
		local equippedPets = functions.GetEquippedPets:InvokeServer()
		local ownedPets = functions.GetOwnedPets:InvokeServer()

		PetSystemCore.Cache.LocalPlayerPets = {
			equippedPets = equippedPets,
			ownedPets = ownedPets
		}

		if self.OnPetsUpdated then
			self.OnPetsUpdated:Fire(PetSystemCore.Cache.LocalPlayerPets)
		end
	end
end

-- Get pet data for a specific pet
function PetSystemCore.Client:GetPetData(petId)
	local functions = PetSystemCore.Remotes.Functions

	if functions.GetPetData then
		return functions.GetPetData:InvokeServer(petId)
	end

	return nil
end

-- Create client-side events
PetSystemCore.Client.OnPetsUpdated = Instance.new("BindableEvent")
PetSystemCore.Client.OnPetEquipped = Instance.new("BindableEvent")
PetSystemCore.Client.OnPetUnequipped = Instance.new("BindableEvent")
PetSystemCore.Client.OnPetLevelUp = Instance.new("BindableEvent")

return PetSystemCore