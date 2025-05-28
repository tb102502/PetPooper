--[[
    GameCore.lua - FIXED VERSION
    Place in: ServerScriptService/Core/GameCore.lua
    
    FIXES:
    1. Removed Connection attribute storage (not supported)
    2. Fixed sound IDs to use working Roblox defaults
    3. Enhanced pet movement system
    4. Better memory management
    5. Improved error handling
]]

local GameCore = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

-- Load configuration
local GameConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("GameConfig"))
local ItemConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("ItemConfig"))

-- Core Data Management
GameCore.PlayerData = {}
GameCore.DataStore = nil
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}

-- System States
GameCore.Systems = {
	Pets = {
		ActivePets = {}, -- [petInstance] = {owner, petId, data, behaviorId}
		SpawnAreas = {},
		SpawnTimers = {},
		BehaviorConnections = {}, -- [behaviorId] = connection
		NextBehaviorId = 1 -- Counter for unique behavior IDs
	},
	Shop = {
		ActiveBoosters = {},
		PurchaseCooldowns = {}
	},
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {}
	}
}

-- Pet Configurations
GameCore.PetConfigs = {
	Corgi = {
		name = "Corgi",
		displayName = "Cuddly Corgi",
		rarity = "Common",
		collectValue = 10,
		baseStats = { happiness = 50, energy = 100 },
		colors = {
			primary = Color3.fromRGB(255, 200, 150),
			secondary = Color3.fromRGB(255, 255, 255)
		}
	},
	RedPanda = {
		name = "Red Panda",
		displayName = "Rambunctious Red Panda",
		rarity = "Common",
		collectValue = 12,
		baseStats = { happiness = 60, energy = 90 },
		colors = {
			primary = Color3.fromRGB(194, 144, 90),
			secondary = Color3.fromRGB(140, 100, 60)
		}
	},
	Cat = {
		name = "Cat",
		displayName = "Curious Cat",
		rarity = "Uncommon",
		collectValue = 25,
		baseStats = { happiness = 70, energy = 80 },
		colors = {
			primary = Color3.fromRGB(100, 100, 100),
			secondary = Color3.fromRGB(200, 200, 200)
		}
	},
	Hamster = {
		name = "Hamster",
		displayName = "Happy Hamster",
		rarity = "Legendary",
		collectValue = 100,
		baseStats = { happiness = 90, energy = 95 },
		colors = {
			primary = Color3.fromRGB(255, 215, 0),
			secondary = Color3.fromRGB(255, 255, 200)
		}
	}
}

-- Initialize the entire game core
function GameCore:Initialize()
	print("GameCore: Starting comprehensive initialization...")

	self:SetupDataStore()
	self:SetupRemoteEvents()
	self:InitializePetSystem()
	self:InitializeShopSystem()
	self:InitializeFarmingSystem()
	self:SetupPlayerEvents()
	self:StartUpdateLoops()

	print("GameCore: All systems initialized successfully!")
	return true
end

-- Data Store Setup
function GameCore:SetupDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore("PetPalaceData_v3")
	end)

	if success then
		self.DataStore = dataStore
		print("GameCore: DataStore connected")
	else
		warn("GameCore: DataStore failed, using memory storage")
		self.UseMemoryStore = true
	end
end

-- Remote Events Setup
function GameCore:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	local events = {
		"PetCollected", "PetEquipped", "PetUnequipped", "CollectWildPet",
		"PurchaseItem", "CurrencyUpdated", "ItemPurchased",
		"PlantSeed", "HarvestCrop", "FeedPet", "GetFarmingData", "BuySeed",
		"PlayerDataUpdated", "NotificationSent", "UpdatePlayerStats",
		"CollectPet", "SendNotification", "EnableAutoCollect", "UpdateVIPStatus",
		"OpenShopClient", "UpdateShopData", "ShowNotification",
		"SellPet", "SellMultiplePets", "PetSold"
	}

	local functions = {
		"GetPlayerData", "GetShopItems", "GetPetCollection"
	}

	for _, eventName in ipairs(events) do
		local event = remoteFolder:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
		end
		self.RemoteEvents[eventName] = event
	end

	for _, funcName in ipairs(functions) do
		local func = remoteFolder:FindFirstChild(funcName)
		if not func then
			func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
		end
		self.RemoteFunctions[funcName] = func
	end

	self:SetupEventHandlers()
	print("GameCore: Remote events setup complete")
end

-- Event Handlers
function GameCore:SetupEventHandlers()
	-- Pet System Handlers
	self.RemoteEvents.CollectWildPet.OnServerEvent:Connect(function(player, petModel)
		self:HandleWildPetCollection(player, petModel)
	end)

	self.RemoteEvents.SellPet.OnServerEvent:Connect(function(player, petId)
		self:SellPet(player, petId)
	end)

	self.RemoteEvents.SellMultiplePets.OnServerEvent:Connect(function(player, petIds)
		self:SellMultiplePets(player, petIds)
	end)

	self.RemoteEvents.CollectPet.OnServerEvent:Connect(function(player, petIdentifier)
		if typeof(petIdentifier) == "Instance" then
			self:HandleWildPetCollection(player, petIdentifier)
		else
			self:HandlePetCollectionByName(player, petIdentifier)
		end
	end)

	self.RemoteEvents.PetEquipped.OnServerEvent:Connect(function(player, petId)
		self:EquipPet(player, petId)
	end)

	-- Shop System Handlers
	self.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
		self:HandlePurchase(player, itemId, quantity or 1)
	end)

	-- Remote Functions
	self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
		return self:GetPlayerData(player)
	end

	self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
		return self:GetShopItems(player)
	end

	print("GameCore: Event handlers setup complete")
end

-- Player Data Management
function GameCore:GetPlayerData(player)
	if not self.PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return self.PlayerData[player.UserId]
end

function GameCore:LoadPlayerData(player)
	local defaultData = {
		coins = GameConfig.StartingCoins or 100,
		gems = GameConfig.StartingGems or 10,
		pets = {
			owned = {},
			equipped = {}
		},
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 3,
			inventory = {
				carrot_seeds = 5,
				corn_seeds = 3
			},
			pig = {
				feedCount = 0,
				size = 1.0
			}
		},
		stats = {
			totalPetsCollected = 0,
			coinsEarned = 0,
			itemsPurchased = 0,
			cropsHarvested = 0,
			petsSold = 0
		},
		firstJoin = os.time(),
		lastSave = os.time()
	}

	local loadedData = defaultData

	if not self.UseMemoryStore then
		local success, data = pcall(function()
			return self.DataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			for key, value in pairs(defaultData) do
				if data[key] == nil then
					data[key] = value
				elseif type(value) == "table" and type(data[key]) == "table" then
					for subKey, subValue in pairs(value) do
						if data[key][subKey] == nil then
							data[key][subKey] = subValue
						end
					end
				end
			end
			loadedData = data
		end
	end

	self.PlayerData[player.UserId] = loadedData
	self:InitializePlayerFarm(player)
	self:UpdatePlayerLeaderstats(player)

	print("GameCore: Loaded data for " .. player.Name)
	return loadedData
end

function GameCore:SavePlayerData(player)
	local data = self.PlayerData[player.UserId]
	if not data then return end

	data.lastSave = os.time()

	if not self.UseMemoryStore then
		spawn(function()
			local success, err = pcall(function()
				self.DataStore:SetAsync("Player_" .. player.UserId, data)
			end)
			if not success then
				warn("GameCore: Save failed for " .. player.Name .. ": " .. tostring(err))
			end
		end)
	end
end

-- Pet System Implementation (FIXED)
function GameCore:InitializePetSystem()
	local workspace = game:GetService("Workspace")
	local areasFolder = workspace:FindFirstChild("Areas") or Instance.new("Folder")
	areasFolder.Name = "Areas"
	areasFolder.Parent = workspace

	for _, areaConfig in ipairs(ItemConfig.SpawnAreas) do
		local areaFolder = areasFolder:FindFirstChild(areaConfig.name)
		if not areaFolder then
			areaFolder = Instance.new("Folder")
			areaFolder.Name = areaConfig.name
			areaFolder.Parent = areasFolder
		end

		local petsContainer = areaFolder:FindFirstChild("Pets")
		if not petsContainer then
			petsContainer = Instance.new("Folder")
			petsContainer.Name = "Pets"
			petsContainer.Parent = areaFolder
		end

		self.Systems.Pets.SpawnAreas[areaConfig.name] = {
			container = petsContainer,
			config = areaConfig,
			lastSpawn = 0
		}
	end

	self:ValidateAndFixPetModels()
	print("GameCore: Pet system initialized")
end

-- FIXED: Enhanced pet model creation
function GameCore:CreatePetModel(petConfig, position)
	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	local template = petModelsFolder and petModelsFolder:FindFirstChild(petConfig.modelName or petConfig.name)

	local petModel
	if template then
		petModel = template:Clone()
		for _, part in pairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Anchored = false
				part.CanCollide = false
			end
		end
	else
		petModel = self:CreateMovingPetModel(petConfig)
	end

	if not petModel then return nil end

	petModel.Name = petConfig.name .. "_" .. tick()
	petModel:SetAttribute("PetType", petConfig.id or petConfig.name)
	petModel:SetAttribute("Rarity", petConfig.rarity)
	petModel:SetAttribute("Value", petConfig.collectValue or 1)
	petModel:SetAttribute("SpawnTime", os.time())

	local success = self:PositionPet(petModel, position)
	if not success then
		petModel:Destroy()
		return nil
	end

	-- FIXED: Start behavior without storing connection as attribute
	self:StartPetBehavior(petModel, petConfig)

	return petModel
end

-- Enhanced pet model creation
function GameCore:CreateMovingPetModel(petConfig)
	local model = Instance.new("Model")
	model.Name = petConfig.name

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = math.random(4, 8)
	humanoid.JumpPower = math.random(30, 50)
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.PlatformStand = false
	humanoid.Parent = model

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Anchored = false
	rootPart.TopSurface = Enum.SurfaceType.Smooth
	rootPart.BottomSurface = Enum.SurfaceType.Smooth
	rootPart.Parent = model

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = rootPart

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.5, 1.5, 2)
	body.Shape = Enum.PartType.Ball
	body.Color = petConfig.colors and petConfig.colors.primary or Color3.fromRGB(255, 255, 255)
	body.Material = Enum.Material.Plastic
	body.CanCollide = false
	body.Anchored = false
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = body
	weld.Parent = body

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Shape = Enum.PartType.Ball
	head.Color = petConfig.colors and petConfig.colors.secondary or Color3.fromRGB(200, 200, 200)
	head.Material = Enum.Material.Neon
	head.CanCollide = false
	head.Anchored = false
	head.TopSurface = Enum.SurfaceType.Smooth
	head.BottomSurface = Enum.SurfaceType.Smooth
	head.Parent = model

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = head

	head.CFrame = body.CFrame + Vector3.new(0, 1.25, 0)

	for i, side in ipairs({"Left", "Right"}) do
		local eye = Instance.new("Part")
		eye.Name = side .. "Eye"
		eye.Size = Vector3.new(0.2, 0.2, 0.2)
		eye.Color = Color3.fromRGB(0, 0, 0)
		eye.Shape = Enum.PartType.Ball
		eye.CanCollide = false
		eye.Anchored = false
		eye.TopSurface = Enum.SurfaceType.Smooth
		eye.BottomSurface = Enum.SurfaceType.Smooth
		eye.Parent = model

		local eyeWeld = Instance.new("WeldConstraint")
		eyeWeld.Part0 = head
		eyeWeld.Part1 = eye
		eyeWeld.Parent = eye

		local xOffset = (i == 1) and -0.3 or 0.3
		eye.CFrame = head.CFrame + Vector3.new(xOffset, 0.2, 0.4)
	end

	model.PrimaryPart = rootPart
	return model
end

-- FIXED: Pet behavior system without connection attributes
-- GameCore.lua FIXES
-- Replace these functions in your GameCore.lua

-- FIXED: Pet behavior system with proper collection distance
function GameCore:StartPetBehavior(petModel, petConfig)
	local humanoid = petModel:FindFirstChild("Humanoid")
	local rootPart = petModel.PrimaryPart or petModel:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	-- Generate unique behavior ID
	local behaviorId = self.Systems.Pets.NextBehaviorId
	self.Systems.Pets.NextBehaviorId = self.Systems.Pets.NextBehaviorId + 1

	-- Store behavior ID on the pet
	petModel:SetAttribute("BehaviorId", behaviorId)

	local originalPosition = rootPart.Position
	local wanderRadius = 15
	local moveTime = 0
	local jumpTime = 0
	local targetPosition = originalPosition
	local isCollected = false
	local glowEffect = nil

	local function getRandomTarget()
		local angle = math.random() * math.pi * 2
		local distance = math.random(5, wanderRadius)
		local offset = Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)
		return originalPosition + offset
	end

	local function createGlow()
		if glowEffect or isCollected then return end

		glowEffect = Instance.new("Part")
		glowEffect.Name = "GlowEffect"
		glowEffect.Size = Vector3.new(6, 6, 6)
		glowEffect.Shape = Enum.PartType.Ball
		glowEffect.Material = Enum.Material.ForceField
		glowEffect.Color = Color3.fromRGB(255, 255, 0)
		glowEffect.Transparency = 0.7
		glowEffect.CanCollide = false
		glowEffect.Anchored = true
		glowEffect.Parent = petModel

		petModel:SetAttribute("HasGlow", true)
	end

	local function removeGlow()
		if glowEffect then
			glowEffect:Destroy()
			glowEffect = nil
			petModel:SetAttribute("HasGlow", false)
		end
	end

	-- Main behavior loop
	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not petModel or not petModel.Parent or isCollected then
			if connection then connection:Disconnect() end
			return
		end

		if not humanoid or not humanoid.Parent or not rootPart or not rootPart.Parent then
			if connection then connection:Disconnect() end
			return
		end

		moveTime = moveTime + deltaTime
		jumpTime = jumpTime + deltaTime

		-- Random jumping
		if jumpTime > math.random(3, 8) then
			jumpTime = 0
			if humanoid.FloorMaterial ~= Enum.Material.Air then
				humanoid.Jump = true
			end
		end

		-- Random movement
		if moveTime > math.random(2, 5) then
			moveTime = 0
			targetPosition = getRandomTarget()
		end

		-- Move towards target
		local currentPosition = rootPart.Position
		local direction = (targetPosition - currentPosition)

		if direction.Magnitude > 2 then
			direction = direction.Unit
			humanoid:MoveTo(currentPosition + direction * 10)
		else
			targetPosition = getRandomTarget()
		end

		-- Proximity detection
		local playerNearby = false
		local glowRadius = 8
		local collectRadius = 5 -- INCREASED from 4 to 5

		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local playerRoot = player.Character.HumanoidRootPart
				local distance = (rootPart.Position - playerRoot.Position).Magnitude

				if distance <= collectRadius and not isCollected then
					isCollected = true
					if connection then connection:Disconnect() end
					-- IMMEDIATE collection and destruction
					spawn(function()
						self:HandleWildPetCollection(player, petModel)
					end)
					return
				elseif distance <= glowRadius then
					playerNearby = true
				end
			end
		end

		-- Manage glow effect
		if playerNearby and not petModel:GetAttribute("HasGlow") then
			createGlow()
		elseif not playerNearby and petModel:GetAttribute("HasGlow") then
			removeGlow()
		end

		-- Update glow position
		if glowEffect then
			glowEffect.CFrame = rootPart.CFrame
		end
	end)

	-- Store connection using behavior ID
	self.Systems.Pets.BehaviorConnections[behaviorId] = connection

	-- Cleanup when pet is removed
	petModel.AncestryChanged:Connect(function()
		if not petModel.Parent then
			if connection then connection:Disconnect() end
			self.Systems.Pets.BehaviorConnections[behaviorId] = nil
			removeGlow()
		end
	end)
end

-- FIXED: Wild pet collection with proper distance check and immediate destruction
function GameCore:HandleWildPetCollection(player, petModel)
	if not player or not petModel or not petModel.Parent then 
		return false 
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local playerRoot = character.HumanoidRootPart
	local petPosition

	if petModel:IsA("Model") and petModel.PrimaryPart then
		petPosition = petModel.PrimaryPart.Position
	elseif petModel:IsA("BasePart") then
		petPosition = petModel.Position
	else
		for _, part in pairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				petPosition = part.Position
				break
			end
		end
	end

	if not petPosition then return false end

	local distance = (playerRoot.Position - petPosition).Magnitude
	-- FIXED: Increased collection distance to 8 studs
	if distance > 8 then
		-- Only warn in debug mode
		-- warn("Player " .. player.Name .. " tried to collect pet from too far away: " .. distance)
		return false
	end

	local petType = petModel:GetAttribute("PetType")
	local petRarity = petModel:GetAttribute("Rarity") or "Common"
	local petValue = petModel:GetAttribute("Value") or 1

	if not petType then
		warn("Pet model missing PetType attribute")
		return false
	end

	local petConfig = self.PetConfigs[petType]
	if not petConfig then
		warn("Unknown pet type: " .. tostring(petType))
		return false
	end

	local petData = {
		id = HttpService:GenerateGUID(false),
		type = petType,
		name = petConfig.name,
		displayName = petConfig.displayName,
		rarity = petRarity,
		level = 1,
		experience = 0,
		acquired = os.time(),
		source = "wild_catch",
		stats = {},
		collectValue = petValue
	}

	if petConfig.baseStats then
		for k, v in pairs(petConfig.baseStats) do
			petData.stats[k] = v
		end
	end

	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	local currentPetCount = #(playerData.pets and playerData.pets.owned or {})
	local maxPets = self:GetPlayerMaxPets(player.UserId)

	if currentPetCount >= maxPets then
		if self.RemoteEvents.ShowNotification then
			self.RemoteEvents.ShowNotification:FireClient(player, 
				"Inventory Full!", 
				"You can't collect more pets. Sell some pets or upgrade your storage!", 
				"warning"
			)
		end
		return false
	end

	-- FIXED: Clean up behavior connection BEFORE creating effects
	local behaviorId = petModel:GetAttribute("BehaviorId")
	if behaviorId then
		local connection = self.Systems.Pets.BehaviorConnections[behaviorId]
		if connection then
			connection:Disconnect()
			self.Systems.Pets.BehaviorConnections[behaviorId] = nil
		end
	end

	-- FIXED: Immediately destroy the pet to prevent double collection
	petModel:Destroy()

	-- Add pet to player's collection
	local success = self:AddPetToPlayer(player.UserId, petData)
	if not success then
		warn("Failed to add pet to player " .. player.UserId)
		return false
	end

	-- Calculate and award rewards
	local rewards = self:CalculateCollectionRewards(petConfig, petRarity)
	if rewards.coins > 0 then
		self:AddPlayerCurrency(player.UserId, "coins", rewards.coins)
	end
	if rewards.gems > 0 then
		self:AddPlayerCurrency(player.UserId, "gems", rewards.gems)
	end

	-- Update player stats
	playerData.stats.totalPetsCollected = playerData.stats.totalPetsCollected + 1
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + rewards.coins

	self:UpdatePlayerLeaderstats(player)

	-- Send notifications and updates
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player,
			"Pet Collected!", 
			"Caught " .. petData.name .. " (+" .. rewards.coins .. " coins)",
			"success"
		)
	end

	if self.RemoteEvents.PetCollected then
		self.RemoteEvents.PetCollected:FireClient(player, petData, rewards.coins)
	end

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	-- Schedule respawn of new pet in same area
	spawn(function()
		wait(math.random(5, 10)) -- Wait 5-10 seconds before respawning
		-- Find which area this pet was in and spawn a new one
		for areaName, areaData in pairs(self.Systems.Pets.SpawnAreas) do
			local currentPetCount = #areaData.container:GetChildren()
			if currentPetCount < areaData.config.maxPets then
				self:SpawnWildPet(areaName)
				break
			end
		end
	end)

	self:LogPlayerAction(player.UserId, "pet_collected", {
		petType = petType,
		rarity = petRarity,
		method = "proximity",
		rewards = rewards
	})

	print("GameCore: " .. player.Name .. " collected " .. petData.name .. " for " .. rewards.coins .. " coins")
	return true
end

-- FIXED: Pet selling system without equip checks
function GameCore:SellPet(player, petId)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.pets or not playerData.pets.owned then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	local petToSell = nil
	local petIndex = nil

	for i, pet in ipairs(playerData.pets.owned) do
		if pet.id == petId then
			petToSell = pet
			petIndex = i
			break
		end
	end

	if not petToSell then
		self:SendNotification(player, "Pet Not Found", "Could not find that pet to sell", "error")
		return false
	end

	-- REMOVED: Equipment check since we're not using equipment system
	-- Just sell the pet directly

	local sellValue = self:CalculatePetValue(petToSell)

	-- Remove pet from collection
	table.remove(playerData.pets.owned, petIndex)

	-- Add coins to player
	playerData.coins = playerData.coins + sellValue
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + sellValue

	-- Update stats
	if not playerData.stats.petsSold then
		playerData.stats.petsSold = 0
	end
	playerData.stats.petsSold = playerData.stats.petsSold + 1

	-- Update leaderstats
	self:UpdatePlayerLeaderstats(player)

	-- Fire pet sold event with pet data
	if self.RemoteEvents.PetSold then
		self.RemoteEvents.PetSold:FireClient(player, petToSell, sellValue)
	end

	-- Update player data immediately
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	-- Send notification
	self:SendNotification(player, "Pet Sold!", 
		"Sold " .. (petToSell.name or "Pet") .. " for " .. sellValue .. " coins", "success")

	print("GameCore: " .. player.Name .. " sold " .. (petToSell.name or petToSell.type) .. " for " .. sellValue .. " coins")
	return true
end
-- FIXED: Collection effect with working sound
function GameCore:CreatePetCollectionEffect(petModel, player)
	local petPosition
	if petModel:IsA("Model") and petModel.PrimaryPart then
		petPosition = petModel.PrimaryPart.Position
	elseif petModel:IsA("BasePart") then
		petPosition = petModel.Position
	else
		for _, part in pairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				petPosition = part.Position
				break
			end
		end
	end

	if not petPosition then return end

	-- Create collection beam effect
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local playerRoot = character.HumanoidRootPart

		local beamPart = Instance.new("Part")
		beamPart.Size = Vector3.new(0.1, 0.1, 0.1)
		beamPart.Transparency = 1
		beamPart.Anchored = true
		beamPart.CanCollide = false
		beamPart.Position = petPosition
		beamPart.Parent = workspace

		local attachment0 = Instance.new("Attachment")
		attachment0.Parent = beamPart

		local attachment1 = Instance.new("Attachment")
		attachment1.Parent = playerRoot

		local beam = Instance.new("Beam")
		beam.Attachment0 = attachment0
		beam.Attachment1 = attachment1
		beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
		beam.Width0 = 0.5
		beam.Width1 = 0.1
		beam.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		}
		beam.Parent = beamPart

		local beamTween = TweenService:Create(beam,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = NumberSequence.new(1),
				Width0 = 0.1,
				Width1 = 0.05
			}
		)

		beamTween:Play()
		Debris:AddItem(beamPart, 0.6)
	end

	-- Make pet disappear with shrinking effect
	if petModel:IsA("Model") then
		for _, part in pairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				local shrinkTween = TweenService:Create(part,
					TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
					{
						Size = Vector3.new(0.1, 0.1, 0.1),
						Transparency = 1
					}
				)
				shrinkTween:Play()
			end
		end
	elseif petModel:IsA("BasePart") then
		local shrinkTween = TweenService:Create(petModel,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{
				Size = Vector3.new(0.1, 0.1, 0.1),
				Transparency = 1
			}
		)
		shrinkTween:Play()
	end

	-- FIXED: Use working Roblox default sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingsharp.wav" -- Default Roblox sound that works
	sound.Volume = 0.5
	sound.Parent = workspace

	local success, err = pcall(function()
		sound:Play()
	end)

	if not success then
		warn("Server: Failed to play collection sound: " .. tostring(err))
	end

	Debris:AddItem(sound, 2)
end

-- Calculate collection rewards
function GameCore:CalculateCollectionRewards(petConfig, rarity)
	local baseCoins = petConfig.collectValue or 1
	local baseGems = 0

	local multipliers = {
		Common = 1,
		Uncommon = 2,
		Rare = 4,
		Epic = 8,
		Legendary = 16,
		Mythic = 32
	}

	local mult = multipliers[rarity] or 1
	local coins = math.floor(baseCoins * mult)

	local gemChances = {
		Common = 0.01,
		Uncommon = 0.05,
		Rare = 0.10,
		Epic = 0.20,
		Legendary = 0.40,
		Mythic = 0.70
	}

	local gemChance = gemChances[rarity] or 0
	if math.random() < gemChance then
		baseGems = math.ceil(mult / 4)
	end

	return {
		coins = coins,
		gems = baseGems
	}
end

-- Pet Spawning System
function GameCore:SpawnWildPet(areaName)
	local areaData = self.Systems.Pets.SpawnAreas[areaName]
	if not areaData then 
		return 
	end

	local config = areaData.config
	local currentPetCount = #areaData.container:GetChildren()

	if currentPetCount >= config.maxPets then 
		return 
	end

	local totalPets = 0
	for _, area in pairs(self.Systems.Pets.SpawnAreas) do
		totalPets = totalPets + #area.container:GetChildren()
	end

	if totalPets >= 100 then
		return
	end

	local availablePets = config.availablePets
	local selectedPetId = availablePets[math.random(1, #availablePets)]
	local petConfig = self.PetConfigs[selectedPetId]

	if not petConfig then return end

	local petModel = self:CreatePetModel(petConfig, config.spawnPositions[math.random(1, #config.spawnPositions)])
	if petModel then
		petModel.Parent = areaData.container

		spawn(function()
			wait(300) -- 5 minutes
			if petModel and petModel.Parent then
				local behaviorId = petModel:GetAttribute("BehaviorId")
				if behaviorId then
					local connection = self.Systems.Pets.BehaviorConnections[behaviorId]
					if connection then
						connection:Disconnect()
						self.Systems.Pets.BehaviorConnections[behaviorId] = nil
					end
				end
				petModel:Destroy()
			end
		end)

		print("GameCore: Spawned " .. selectedPetId .. " in " .. areaName)
		return petModel
	end
end

-- Pet positioning
function GameCore:PositionPet(petModel, position)
	if petModel.PrimaryPart then
		petModel.PrimaryPart.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
		return true
	end

	local rootPart = petModel:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
		return true
	end

	return false
end

-- Pet Selling System
function GameCore:CalculatePetValue(petData)
	local baseValues = {
		Common = 25,
		Uncommon = 75, 
		Rare = 200,
		Epic = 500,
		Legendary = 1500
	}

	local baseValue = baseValues[petData.rarity] or baseValues.Common
	local level = petData.level or 1
	local levelMultiplier = 1 + ((level - 1) * 0.1)

	return math.floor(baseValue * levelMultiplier)
end

function GameCore:SellPet(player, petId)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.pets or not playerData.pets.owned then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	local petToSell = nil
	local petIndex = nil

	for i, pet in ipairs(playerData.pets.owned) do
		if pet.id == petId then
			petToSell = pet
			petIndex = i
			break
		end
	end

	if not petToSell then
		self:SendNotification(player, "Pet Not Found", "Could not find that pet to sell", "error")
		return false
	end

	local isEquipped = false
	for _, equippedPet in ipairs(playerData.pets.equipped or {}) do
		if equippedPet.id == petId then
			isEquipped = true
			break
		end
	end

	if isEquipped then
		self:SendNotification(player, "Cannot Sell", "Unequip the pet before selling it", "error")
		return false
	end

	local sellValue = self:CalculatePetValue(petToSell)

	table.remove(playerData.pets.owned, petIndex)
	playerData.coins = playerData.coins + sellValue
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + sellValue

	if not playerData.stats.petsSold then
		playerData.stats.petsSold = 0
	end
	playerData.stats.petsSold = playerData.stats.petsSold + 1

	self:UpdatePlayerLeaderstats(player)

	if self.RemoteEvents.PetSold then
		self.RemoteEvents.PetSold:FireClient(player, petToSell, sellValue)
	end

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Pet Sold!", 
		"Sold " .. (petToSell.name or "Pet") .. " for " .. sellValue .. " coins", "success")

	print("GameCore: " .. player.Name .. " sold " .. (petToSell.name or petToSell.type) .. " for " .. sellValue .. " coins")
	return true
end

-- Shop System Implementation
function GameCore:InitializeShopSystem()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessDevProductPurchase(receiptInfo)
	end
	print("GameCore: Shop system initialized")
end

function GameCore:GetShopItems(player)
	return ItemConfig.ShopItems
end

function GameCore:HandlePurchase(player, itemId, quantity)
	local playerData = self:GetPlayerData(player)
	local item = ItemConfig.ShopItems[itemId]

	if not item then
		warn("GameCore: Invalid item ID: " .. itemId)
		return
	end

	local totalCost = item.price * quantity
	local currency = item.currency:lower()

	if not playerData[currency] or playerData[currency] < totalCost then
		self:SendNotification(player, "Insufficient " .. item.currency, "You need more " .. item.currency, "error")
		return
	end

	playerData[currency] = playerData[currency] - totalCost
	playerData.stats.itemsPurchased = playerData.stats.itemsPurchased + 1

	self:ApplyItemEffects(player, item, quantity)

	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased:FireClient(player, itemId, quantity, totalCost, currency)
	end
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("GameCore: " .. player.Name .. " purchased " .. quantity .. "x " .. item.name)
end

function GameCore:ApplyItemEffects(player, item, quantity)
	local playerData = self:GetPlayerData(player)

	if item.type == "seed" then
		if not playerData.farming.inventory[item.id] then
			playerData.farming.inventory[item.id] = 0
		end
		playerData.farming.inventory[item.id] = playerData.farming.inventory[item.id] + quantity

	elseif item.type == "upgrade" then
		if not playerData.upgrades[item.id] then
			playerData.upgrades[item.id] = 0
		end
		playerData.upgrades[item.id] = playerData.upgrades[item.id] + quantity

	elseif item.type == "pet" then
		local petData = {
			id = HttpService:GenerateGUID(false),
			type = item.id,
			rarity = item.rarity or "Common",
			level = 1,
			experience = 0,
			obtained = os.time()
		}
		table.insert(playerData.pets.owned, petData)
	end
end

-- Farming System Implementation  
function GameCore:InitializeFarmingSystem()
	print("GameCore: Farming system initialized")
end

function GameCore:InitializePlayerFarm(player)
	local playerData = self:GetPlayerData(player)

	local workspace = game:GetService("Workspace")
	local farmingAreas = workspace:FindFirstChild("FarmingAreas") or Instance.new("Folder")
	farmingAreas.Name = "FarmingAreas"
	farmingAreas.Parent = workspace

	local playerFarm = farmingAreas:FindFirstChild(player.Name)
	if playerFarm then return end

	playerFarm = Instance.new("Folder")
	playerFarm.Name = player.Name
	playerFarm.Parent = farmingAreas

	local plotCount = playerData.farming.plots or 3
	for i = 1, plotCount do
		local plot = self:CreateFarmPlot(i)
		plot.Parent = playerFarm
	end

	self.Systems.Farming.PlayerFarms[player.UserId] = {
		folder = playerFarm,
		plots = plotCount
	}
end

function GameCore:CreateFarmPlot(plotNumber)
	local plotModel = Instance.new("Model")
	plotModel.Name = "FarmPlot_" .. plotNumber

	local soil = Instance.new("Part")
	soil.Name = "Soil"
	soil.Size = Vector3.new(4, 0.5, 4)
	soil.Position = Vector3.new((plotNumber - 1) * 5, 0, 0)
	soil.Anchored = true
	soil.CanCollide = true
	soil.Material = Enum.Material.Sand
	soil.Color = Color3.fromRGB(110, 70, 45)
	soil.Parent = plotModel

	plotModel.PrimaryPart = soil

	plotModel:SetAttribute("PlotID", plotNumber)
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)

	return plotModel
end

-- Pet Management Methods
function GameCore:EquipPet(player, petId)
	local playerData = self:GetPlayerData(player)

	local petToEquip = nil
	for _, pet in ipairs(playerData.pets.owned) do
		if pet.id == petId then
			petToEquip = pet
			break
		end
	end

	if not petToEquip then
		self:SendNotification(player, "Pet not found", "Could not find that pet", "error")
		return
	end

	for _, equippedPet in ipairs(playerData.pets.equipped) do
		if equippedPet.id == petId then
			self:SendNotification(player, "Pet already equipped", "This pet is already equipped", "error")
			return
		end
	end

	if #playerData.pets.equipped >= (GameConfig.MaxEquippedPets or 5) then
		self:SendNotification(player, "Max pets equipped", "You can only have " .. (GameConfig.MaxEquippedPets or 5) .. " pets equipped", "error")
		return
	end

	table.insert(playerData.pets.equipped, petToEquip)

	if self.RemoteEvents.PetEquipped then
		self.RemoteEvents.PetEquipped:FireClient(player, petId, petToEquip)
	end
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("GameCore: " .. player.Name .. " equipped pet " .. petId)
end

-- Player Management
function GameCore:SetupPlayerEvents()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
		self:CreatePlayerLeaderstats(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayerData(player)
		self:CleanupPlayer(player)
	end)
end

function GameCore:CreatePlayerLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = self.PlayerData[player.UserId].coins
	coins.Parent = leaderstats

	local pets = Instance.new("IntValue")
	pets.Name = "Pets"
	pets.Value = #self.PlayerData[player.UserId].pets.owned
	pets.Parent = leaderstats
end

function GameCore:UpdatePlayerLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local playerData = self.PlayerData[player.UserId]

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then coins.Value = playerData.coins end

	local pets = leaderstats:FindFirstChild("Pets")
	if pets then pets.Value = #playerData.pets.owned end
end

function GameCore:CleanupPlayer(player)
	self.PlayerData[player.UserId] = nil

	if self.Systems.Farming.PlayerFarms[player.UserId] then
		self.Systems.Farming.PlayerFarms[player.UserId] = nil
	end

	-- Clean up pet behavior connections (FIXED)
	for behaviorId, connection in pairs(self.Systems.Pets.BehaviorConnections) do
		if connection then
			connection:Disconnect()
		end
	end
end

-- Update Loops
function GameCore:StartUpdateLoops()
	-- Pet spawning loop
	spawn(function()
		while true do
			wait(10)

			local stats = game:GetService("Stats")
			local memoryUsage = stats:GetTotalMemoryUsageMb()

			if memoryUsage > 800 then
				print("GameCore: High memory usage, reducing spawning")
				wait(30)
			else
				for areaName, areaData in pairs(self.Systems.Pets.SpawnAreas) do
					if os.time() - areaData.lastSpawn >= areaData.config.spawnInterval then
						self:SpawnWildPet(areaName)
						areaData.lastSpawn = os.time()
					end
				end
			end
		end
	end)

	-- Auto-save loop
	spawn(function()
		while true do
			wait(300)
			for _, player in ipairs(Players:GetPlayers()) do
				self:SavePlayerData(player)
			end
		end
	end)

	-- Memory cleanup loop
	spawn(function()
		while true do
			wait(60)
			self:CleanupMemory()
		end
	end)
end

function GameCore:CleanupMemory()
	local totalPets = 0
	local oldPets = {}
	local totalConnections = 0

	for areaName, areaData in pairs(self.Systems.Pets.SpawnAreas) do
		for _, pet in pairs(areaData.container:GetChildren()) do
			totalPets = totalPets + 1

			local spawnTime = pet:GetAttribute("SpawnTime")
			if not spawnTime then
				pet:SetAttribute("SpawnTime", os.time())
			elseif os.time() - spawnTime > 600 then
				table.insert(oldPets, pet)
			end
		end
	end

	for _, connection in pairs(self.Systems.Pets.BehaviorConnections) do
		if connection then
			totalConnections = totalConnections + 1
		end
	end

	if totalPets > 80 then
		for i = 1, math.min(#oldPets, 20) do
			if oldPets[i] and oldPets[i].Parent then
				local behaviorId = oldPets[i]:GetAttribute("BehaviorId")
				if behaviorId then
					local connection = self.Systems.Pets.BehaviorConnections[behaviorId]
					if connection then
						connection:Disconnect()
						self.Systems.Pets.BehaviorConnections[behaviorId] = nil
					end
				end
				oldPets[i]:Destroy()
			end
		end
		print("GameCore: Cleaned up " .. math.min(#oldPets, 20) .. " old pets")
	end

	-- Clean up broken behavior connections
	for behaviorId, connection in pairs(self.Systems.Pets.BehaviorConnections) do
		if not connection or not connection.Connected then
			self.Systems.Pets.BehaviorConnections[behaviorId] = nil
		end
	end

	print("GameCore: Memory cleanup - Pets: " .. totalPets .. ", Connections: " .. totalConnections)
end

-- Utility Methods
function GameCore:SendNotification(player, title, message, type)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, type or "info")
	end
end

function GameCore:AddPlayerCurrency(userId, currencyType, amount)
	local playerData = self.PlayerData[userId]
	if not playerData then return false end

	local current = playerData[currencyType:lower()] or 0
	playerData[currencyType:lower()] = current + amount

	return true
end

function GameCore:GetPlayerMaxPets(userId)
	return 100
end

function GameCore:AddPetToPlayer(userId, petData)
	local playerData = self.PlayerData[userId]
	if not playerData then return false end

	if not playerData.pets then
		playerData.pets = { owned = {}, equipped = {} }
	end

	if not playerData.pets.owned then
		playerData.pets.owned = {}
	end

	table.insert(playerData.pets.owned, petData)
	return true
end

function GameCore:LogPlayerAction(userId, action, data)
	print("Player " .. userId .. " action: " .. action .. " - " .. HttpService:JSONEncode(data or {}))
end

-- Pet Model Validation and Fixing
function GameCore:ValidateAndFixPetModels()
	print("=== PET MODEL VALIDATOR STARTING ===")

	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModelsFolder then
		warn("No PetModels folder found in ReplicatedStorage!")
		self:CreateMissingPetModels()
		return true
	end

	local fixedCount = 0
	local totalModels = 0

	for _, model in pairs(petModelsFolder:GetChildren()) do
		if model:IsA("Model") then
			totalModels = totalModels + 1
			print("\nChecking model: " .. model.Name)

			local needsFix = false
			local hasHumanoid = model:FindFirstChild("Humanoid")
			local hasRootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart

			if not hasHumanoid then
				print("  Missing Humanoid - will add")
				needsFix = true
			end

			if not hasRootPart then
				print("  Missing HumanoidRootPart - will add")
				needsFix = true
			end

			local anchoredParts = 0
			local totalParts = 0

			for _, part in pairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					totalParts = totalParts + 1
					if part.Anchored then
						anchoredParts = anchoredParts + 1
					end
				end
			end

			if anchoredParts > 1 then
				print("  Has " .. anchoredParts .. "/" .. totalParts .. " anchored parts - will fix")
				needsFix = true
			end

			if needsFix then
				print("  FIXING MODEL: " .. model.Name)
				self:FixPetModel(model)
				fixedCount = fixedCount + 1
			else
				print("  ✅ Model is OK")
			end
		end
	end

	print("Fixed " .. fixedCount .. " models out of " .. totalModels .. " total")
	return true
end

function GameCore:FixPetModel(model)
	local humanoid = model:FindFirstChild("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.WalkSpeed = math.random(4, 8)
		humanoid.JumpPower = math.random(30, 50)
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		humanoid.PlatformStand = false
		humanoid.Parent = model
		print("    Added Humanoid")
	end

	local rootPart = model:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		if model.PrimaryPart then
			rootPart = model.PrimaryPart
			rootPart.Name = "HumanoidRootPart"
			print("    Renamed PrimaryPart to HumanoidRootPart")
		else
			rootPart = Instance.new("Part")
			rootPart.Name = "HumanoidRootPart"
			rootPart.Size = Vector3.new(2, 2, 1)
			rootPart.Transparency = 1
			rootPart.CanCollide = false
			rootPart.Anchored = false
			rootPart.TopSurface = Enum.SurfaceType.Smooth
			rootPart.BottomSurface = Enum.SurfaceType.Smooth
			rootPart.Parent = model

			local cf, size = model:GetBoundingBox()
			rootPart.CFrame = cf

			print("    Created new HumanoidRootPart")
		end
	end

	model.PrimaryPart = rootPart

	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= rootPart then
			part.Anchored = false
			part.CanCollide = false
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth

			local existingWeld = part:FindFirstChild("WeldConstraint")
			if not existingWeld then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = rootPart
				weld.Part1 = part
				weld.Parent = part
			end
		end
	end

	print("    Fixed part anchoring and welding")
end

function GameCore:CreateMissingPetModels()
	print("=== CREATING MISSING PET MODELS ===")

	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModelsFolder then
		petModelsFolder = Instance.new("Folder")
		petModelsFolder.Name = "PetModels"
		petModelsFolder.Parent = ReplicatedStorage
		print("Created PetModels folder")
	end

	local createdCount = 0

	for petName, config in pairs(self.PetConfigs) do
		local existingModel = petModelsFolder:FindFirstChild(petName)
		if not existingModel then
			print("Creating missing model: " .. petName)
			local newModel = self:CreatePetTemplate(petName, config.colors.primary, config.colors.secondary)
			newModel.Parent = petModelsFolder
			createdCount = createdCount + 1
		end
	end

	print("Created " .. createdCount .. " missing pet models")
	return createdCount > 0
end

function GameCore:CreatePetTemplate(petName, primaryColor, secondaryColor)
	local model = Instance.new("Model")
	model.Name = petName

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = math.random(4, 8)
	humanoid.JumpPower = math.random(30, 50)
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Anchored = false
	rootPart.Parent = model

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.5, 1.5, 2)
	body.Shape = Enum.PartType.Ball
	body.Color = primaryColor or Color3.fromRGB(255, 200, 200)
	body.Material = Enum.Material.Plastic
	body.CanCollide = false
	body.Anchored = false
	body.Parent = model

	local bodyWeld = Instance.new("WeldConstraint")
	bodyWeld.Part0 = rootPart
	bodyWeld.Part1 = body
	bodyWeld.Parent = body

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Shape = Enum.PartType.Ball
	head.Color = secondaryColor or Color3.fromRGB(255, 255, 255)
	head.Material = Enum.Material.Neon
	head.CanCollide = false
	head.Anchored = false
	head.Parent = model

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = head

	head.CFrame = body.CFrame + Vector3.new(0, 1.25, 0)

	for i, side in ipairs({"Left", "Right"}) do
		local eye = Instance.new("Part")
		eye.Name = side .. "Eye"
		eye.Size = Vector3.new(0.2, 0.2, 0.2)
		eye.Color = Color3.fromRGB(0, 0, 0)
		eye.Shape = Enum.PartType.Ball
		eye.CanCollide = false
		eye.Anchored = false
		eye.Parent = model

		local eyeWeld = Instance.new("WeldConstraint")
		eyeWeld.Part0 = head
		eyeWeld.Part1 = eye
		eyeWeld.Parent = eye

		local xOffset = (i == 1) and -0.3 or 0.3
		eye.CFrame = head.CFrame + Vector3.new(xOffset, 0.2, 0.4)
	end

	model.PrimaryPart = rootPart
	return model
end

-- Performance monitoring
function GameCore:GetPerformanceStats()
	local totalPets = 0
	local totalConnections = 0

	for _, areaData in pairs(self.Systems.Pets.SpawnAreas) do
		if areaData.container then
			totalPets = totalPets + #areaData.container:GetChildren()
		end
	end

	for _, connection in pairs(self.Systems.Pets.BehaviorConnections) do
		if connection then
			totalConnections = totalConnections + 1
		end
	end

	return {
		totalPets = totalPets,
		totalConnections = totalConnections,
		playerCount = #Players:GetPlayers(),
		memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()
	}
end

-- Make the module globally available
_G.GameCore = GameCore

return GameCore