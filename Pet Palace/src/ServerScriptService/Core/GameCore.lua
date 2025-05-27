--[[
    GameCore.lua - CONSOLIDATED GAME CORE SYSTEM (FIXED)
    Place in: ServerScriptService/Core/GameCore.lua
    
    FIXES:
    - Uses custom pet models from ReplicatedStorage/PetModels
    - Creates proper remote events needed by other scripts  
    - Fixed pet model handling and creation
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
		ActivePets = {}, -- [petInstance] = {owner, petId, data}
		SpawnAreas = {},
		SpawnTimers = {}
	},
	Shop = {
		ActiveBoosters = {}, -- [playerId] = {boosterId = boosterData}
		PurchaseCooldowns = {}
	},
	Farming = {
		PlayerFarms = {}, -- [playerId] = farmData
		GrowthTimers = {}
	}
}

-- Initialize the entire game core
function GameCore:Initialize()
	print("GameCore: Starting comprehensive initialization...")

	-- Initialize in order
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

-- Remote Events Setup (Consolidated) - FIXED
function GameCore:SetupRemoteEvents()
	-- Create main remote folder
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Define all remote events (EXPANDED LIST)
	local events = {
		-- Pet System
		"PetCollected", "PetEquipped", "PetUnequipped", "CollectWildPet",
		-- Shop System  
		"PurchaseItem", "CurrencyUpdated", "ItemPurchased",
		-- Farming System
		"PlantSeed", "HarvestCrop", "FeedPet", "GetFarmingData", "BuySeed",
		-- General
		"PlayerDataUpdated", "NotificationSent", "UpdatePlayerStats",
		-- Additional events needed by other scripts
		"CollectPet", "SendNotification", "EnableAutoCollect", "UpdateVIPStatus",
		"OpenShopClient", "UpdateShopData",
		
		"SellPet", "SellMultiplePets", "GetPetValue"
	}

	local functions = {
		"GetPlayerData", "GetShopItems", "GetPetCollection"
	}

	-- Create events
	for _, eventName in ipairs(events) do
		local event = remoteFolder:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
		end
		self.RemoteEvents[eventName] = event
	end

	-- Create functions
	for _, funcName in ipairs(functions) do
		local func = remoteFolder:FindFirstChild(funcName)
		if not func then
			func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
		end
		self.RemoteFunctions[funcName] = func
	end

	-- Setup handlers
	self:SetupEventHandlers()

	print("GameCore: Remote events setup complete")
end

-- Event Handlers
function GameCore:SetupEventHandlers()
	-- Pet System Handlers
	self.RemoteEvents.CollectWildPet.OnServerEvent:Connect(function(player, petModel)
		self:HandleWildPetCollection(player, petModel)
	end)
	-- Pet Selling Handlers
	self.RemoteEvents.SellPet.OnServerEvent:Connect(function(player, petId)
		self:SellPet(player, petId)
	end)

	self.RemoteEvents.SellMultiplePets.OnServerEvent:Connect(function(player, petIds)
		self:SellMultiplePets(player, petIds)
	end)
	-- Alternative pet collection handler for compatibility
	self.RemoteEvents.CollectPet.OnServerEvent:Connect(function(player, petIdentifier)
		-- Handle both model and string identifiers
		if typeof(petIdentifier) == "Instance" then
			self:HandleWildPetCollection(player, petIdentifier)
		else
			-- Find pet by name/identifier
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

	-- Farming System Handlers
	self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotId, seedId)
		self:PlantSeed(player, plotId, seedId)
	end)

	self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotId)
		self:HarvestCrop(player, plotId)
	end)

	self.RemoteEvents.GetFarmingData.OnServerEvent:Connect(function(player)
		local playerData = self:GetPlayerData(player)
		self.RemoteEvents.GetFarmingData:FireClient(player, playerData.farming or {})
	end)

	self.RemoteEvents.BuySeed.OnServerEvent:Connect(function(player, seedId)
		self:HandlePurchase(player, seedId, 1)
	end)

	-- Remote Functions
	self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
		return self:GetPlayerData(player)
	end

	self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
		return self:GetShopItems(player)
	end
end

function GameCore:OptimizeSpawning()
	-- Limit total pets in world
	local maxTotalPets = 50
	local currentTotal = 0

	for _, areaData in pairs(self.Systems.Pets.SpawnAreas) do
		currentTotal = currentTotal + #areaData.container:GetChildren()
	end

	-- Don't spawn if too many pets exist
	if currentTotal >= maxTotalPets then
		return false
	end

	return true
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
		-- Currency
		coins = GameConfig.StartingCoins or 0,
		gems = GameConfig.StartingGems or 0,

		-- Pets
		pets = {
			owned = {},
			equipped = {}
		},

		-- Shop & Upgrades
		upgrades = {},
		purchaseHistory = {},

		-- Farming
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

		-- Stats
		stats = {
			totalPetsCollected = 0,
			coinsEarned = 0,
			itemsPurchased = 0,
			cropsHarvested = 0
		},

		-- Meta
		firstJoin = os.time(),
		lastSave = os.time()
	}

	local loadedData = defaultData

	-- Try to load from DataStore
	if not self.UseMemoryStore then
		local success, data = pcall(function()
			return self.DataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			-- Merge loaded data with defaults (ensure new fields exist)
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

	-- Initialize player-specific systems
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
	-- Setup pet spawn areas
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

	print("GameCore: Pet system initialized")
end

function GameCore:HandleWildPetCollection(player, petModel)
	if not petModel or not petModel.Parent then return end

	local petType = petModel:GetAttribute("PetType") or "unknown"
	local petRarity = petModel:GetAttribute("Rarity") or "Common"
	local petValue = petModel:GetAttribute("Value") or 1

	-- Add pet to player collection
	local petConfig = ItemConfig.Pets[petType]
	local petData = {
		id = petType .. "_" .. os.time() .. "_" .. math.random(1000, 9999),
		type = petType,
		name = petConfig and petConfig.name or petType, -- FIXED: Ensure name exists
		displayName = petConfig and petConfig.displayName or petType,
		rarity = petRarity,
		level = 1,
		experience = 0,
		obtained = os.time()
	}

	local playerData = self:GetPlayerData(player)
	table.insert(playerData.pets.owned, petData)

	-- Award currency
	local coinsAwarded = petValue * 10
	playerData.coins = playerData.coins + coinsAwarded
	playerData.stats.totalPetsCollected = playerData.stats.totalPetsCollected + 1
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + coinsAwarded

	-- Remove pet from world
	petModel:Destroy()

	-- Notify client with proper data
	self.RemoteEvents.PetCollected:FireClient(player, petData, coinsAwarded)
	self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	self.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	print("GameCore: " .. player.Name .. " collected " .. (petData.name or petType) .. " for " .. coinsAwarded .. " coins")
end

function GameCore:HandlePetCollectionByName(player, petName)
	-- Find pet in world by name
	local areasFolder = workspace:FindFirstChild("Areas")
	if not areasFolder then return end

	for _, area in pairs(areasFolder:GetChildren()) do
		local petsFolder = area:FindFirstChild("Pets")
		if petsFolder then
			for _, pet in pairs(petsFolder:GetChildren()) do
				if pet.Name == petName or pet.Name:match(petName) then
					self:HandleWildPetCollection(player, pet)
					return
				end
			end
		end
	end
end

function GameCore:SpawnWildPet(areaName)
	local areaData = self.Systems.Pets.SpawnAreas[areaName]
	if not areaData then return end

	local config = areaData.config
	local currentPetCount = #areaData.container:GetChildren()

	-- Enhanced limits to prevent memory issues
	if currentPetCount >= config.maxPets then 
		return 
	end

	-- Global pet limit to prevent memory overload
	local totalPets = 0
	for _, area in pairs(self.Systems.Pets.SpawnAreas) do
		totalPets = totalPets + #area.container:GetChildren()
	end

	if totalPets >= 100 then -- Global limit
		print("GameCore: Global pet limit reached, skipping spawn")
		return
	end

	-- Choose random pet from available types
	local availablePets = config.availablePets
	local selectedPetId = availablePets[math.random(1, #availablePets)]
	local petConfig = ItemConfig.Pets[selectedPetId]

	if not petConfig then return end

	-- Create pet model with memory efficiency
	local petModel = self:CreatePetModel(petConfig, config.spawnPositions[math.random(1, #config.spawnPositions)])
	if petModel then
		petModel.Parent = areaData.container

		-- Add cleanup timer to prevent memory buildup
		spawn(function()
			wait(300) -- 5 minutes
			if petModel and petModel.Parent then
				petModel:Destroy()
			end
		end)

		print("GameCore: Spawned " .. selectedPetId .. " in " .. areaName)
		return petModel
	end
end

-- FIXED: Memory-efficient pet model creation
function GameCore:CreatePetModel(petConfig, position)
	-- Try to get model from ReplicatedStorage/PetModels first
	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	local template = petModelsFolder and petModelsFolder:FindFirstChild(petConfig.modelName)

	local petModel
	if template then
		-- Clone the custom model with memory efficiency
		petModel = template:Clone()

		-- Ensure parts are optimized
		for _, part in pairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				-- Remove unnecessary properties to save memory
				part.TopSurface = Enum.SurfaceType.Smooth
				part.BottomSurface = Enum.SurfaceType.Smooth
			end
		end
	else
		-- Create optimized fallback model
		petModel = self:CreateOptimizedPetModel(petConfig)
	end

	if not petModel then return nil end

	-- Setup attributes
	petModel.Name = petConfig.name .. "_" .. tick()
	petModel:SetAttribute("PetType", petConfig.id)
	petModel:SetAttribute("Rarity", petConfig.rarity)
	petModel:SetAttribute("Value", petConfig.collectValue or 1)

	-- Position the pet
	local success = self:PositionPet(petModel, position)
	if not success then
		petModel:Destroy()
		return nil
	end

	-- Simple click detection (no complex scripts)
	self:SetupSimplePetInteraction(petModel)

	return petModel
end
function GameCore:SetupSimplePetInteraction(petModel)
	local interactionPart = petModel:FindFirstChild("HumanoidRootPart") or 
		petModel.PrimaryPart or 
		petModel:FindFirstChildOfClass("BasePart")

	if not interactionPart then return end

	-- Remove existing detector
	local existingDetector = interactionPart:FindFirstChild("ClickDetector")
	if existingDetector then
		existingDetector:Destroy()
	end

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 30
	clickDetector.Parent = interactionPart

	-- Simple visual feedback
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = interactionPart
	selectionBox.Color3 = Color3.fromRGB(0, 255, 0)
	selectionBox.Transparency = 0.7
	selectionBox.Visible = false
	selectionBox.Parent = interactionPart

	clickDetector.MouseHoverEnter:Connect(function(player)
		selectionBox.Visible = true
	end)

	clickDetector.MouseHoverLeave:Connect(function(player)
		selectionBox.Visible = false
	end)

	clickDetector.MouseClick:Connect(function(player)
		self:HandleWildPetCollection(player, petModel)
	end)
end
-- NEW: Optimized pet model creation
function GameCore:CreateOptimizedPetModel(petConfig)
	local model = Instance.new("Model")
	model.Name = petConfig.name

	-- Minimal humanoid for compatibility
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	-- Single main part to reduce memory
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 2)
	rootPart.Shape = Enum.PartType.Ball
	rootPart.Transparency = 0
	rootPart.CanCollide = false
	rootPart.Anchored = true
	rootPart.Color = petConfig.colors and petConfig.colors.primary or Color3.fromRGB(255, 255, 255)
	rootPart.Material = Enum.Material.Plastic
	rootPart.TopSurface = Enum.SurfaceType.Smooth
	rootPart.BottomSurface = Enum.SurfaceType.Smooth
	rootPart.Parent = model

	-- Single decoration part
	local decoration = Instance.new("Part")
	decoration.Name = "Decoration"
	decoration.Size = Vector3.new(0.5, 0.5, 0.5)
	decoration.Shape = Enum.PartType.Ball
	decoration.Position = rootPart.Position + Vector3.new(0, 1, 0)
	decoration.Anchored = true
	decoration.CanCollide = false
	decoration.Color = petConfig.colors and petConfig.colors.secondary or Color3.fromRGB(200, 200, 200)
	decoration.Material = Enum.Material.Neon
	decoration.Parent = model

	model.PrimaryPart = rootPart
	return model
end

-- FIXED: Simple pet positioning
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

-- IMPROVED CreateBasicPetModel function
function GameCore:CreateBasicPetModel(petConfig)
	local model = Instance.new("Model")
	model.Name = petConfig.name

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 0.8  -- Semi-transparent, not invisible
	rootPart.CanCollide = false
	rootPart.Anchored = true
	rootPart.Color = Color3.fromRGB(100, 100, 100)  -- Visible color for debugging
	rootPart.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Shape = Enum.PartType.Ball
	head.Color = petConfig.colors and petConfig.colors.primary or Color3.fromRGB(255, 255, 255)
	head.Position = rootPart.Position + Vector3.new(0, 1, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Transparency = 0  -- Ensure it's visible
	head.Parent = model

	local body = Instance.new("Part")
	body.Name = "Torso"
	body.Size = Vector3.new(2, 2, 3)
	body.Color = petConfig.colors and petConfig.colors.primary or Color3.fromRGB(200, 200, 200)
	body.Position = rootPart.Position + Vector3.new(0, -1, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Transparency = 0  -- Ensure it's visible
	body.Parent = model

	-- Add some distinctive features
	local ears = Instance.new("Part")
	ears.Name = "Ears"
	ears.Size = Vector3.new(0.5, 1, 0.5)
	ears.Color = Color3.fromRGB(150, 150, 150)
	ears.Position = head.Position + Vector3.new(0, 1, 0)
	ears.Anchored = true
	ears.CanCollide = false
	ears.Transparency = 0
	ears.Parent = model

	-- Add a tail for visibility
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.3, 0.3, 1.5)
	tail.Color = petConfig.colors and petConfig.colors.secondary or Color3.fromRGB(180, 180, 180)
	tail.Position = body.Position + Vector3.new(0, 0, -2)
	tail.Anchored = true
	tail.CanCollide = false
	tail.Transparency = 0
	tail.Parent = model

	model.PrimaryPart = rootPart

	print("GameCore: Created basic model for " .. petConfig.name .. " with " .. #model:GetChildren() .. " parts")
	return model
end

-- IMPROVED SetupPetInteraction function
function GameCore:SetupPetInteraction(petModel)
	-- Find the best part for interaction
	local interactionPart = petModel:FindFirstChild("HumanoidRootPart") or 
		petModel.PrimaryPart or 
		petModel:FindFirstChildOfClass("BasePart")

	if not interactionPart then
		warn("GameCore: No suitable interaction part found for " .. petModel.Name)
		return
	end

	-- Remove existing ClickDetector to avoid duplicates
	local existingDetector = interactionPart:FindFirstChild("ClickDetector")
	if existingDetector then
		existingDetector:Destroy()
	end

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 50  -- Increased for better usability
	clickDetector.Parent = interactionPart

	-- Add visual feedback
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = interactionPart
	selectionBox.Color3 = Color3.fromRGB(0, 255, 0)
	selectionBox.Transparency = 0.7
	selectionBox.Visible = false
	selectionBox.Parent = interactionPart

	-- Mouse hover effects
	clickDetector.MouseHoverEnter:Connect(function(player)
		selectionBox.Visible = true
	end)

	clickDetector.MouseHoverLeave:Connect(function(player)
		selectionBox.Visible = false
	end)

	clickDetector.MouseClick:Connect(function(player)
		print("GameCore: Player " .. player.Name .. " clicked pet " .. petModel.Name)
		self:HandleWildPetCollection(player, petModel)
	end)

	print("GameCore: Set up interaction for " .. petModel.Name .. " on part " .. interactionPart.Name)
end
-- Shop System Implementation
function GameCore:InitializeShopSystem()
	-- Setup marketplace service
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

	-- Check if player can afford
	if not playerData[currency] or playerData[currency] < totalCost then
		self.RemoteEvents.NotificationSent:FireClient(player, "Insufficient " .. item.currency, "You need more " .. item.currency, "error")
		return
	end

	-- Process purchase
	playerData[currency] = playerData[currency] - totalCost
	playerData.stats.itemsPurchased = playerData.stats.itemsPurchased + 1

	-- Apply item effects
	self:ApplyItemEffects(player, item, quantity)

	-- Notify client
	self.RemoteEvents.ItemPurchased:FireClient(player, item, quantity)
	self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	self.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	print("GameCore: " .. player.Name .. " purchased " .. quantity .. "x " .. item.name)
end

function GameCore:ApplyItemEffects(player, item, quantity)
	local playerData = self:GetPlayerData(player)

	if item.type == "seed" then
		-- Add seeds to farming inventory
		if not playerData.farming.inventory[item.id] then
			playerData.farming.inventory[item.id] = 0
		end
		playerData.farming.inventory[item.id] = playerData.farming.inventory[item.id] + quantity

	elseif item.type == "upgrade" then
		-- Apply upgrade
		if not playerData.upgrades[item.id] then
			playerData.upgrades[item.id] = 0
		end
		playerData.upgrades[item.id] = playerData.upgrades[item.id] + quantity

	elseif item.type == "pet" then
		-- Add pet directly to collection
		local petData = {
			id = item.id .. "_" .. os.time() .. "_" .. math.random(1000, 9999),
			type = item.id,
			rarity = item.rarity or "Common",
			level = 1,
			experience = 0,
			obtained = os.time()
		}
		table.insert(playerData.pets.owned, petData)
	end
end
-- Pet Selling System Functions - ADD THESE TO GAMECORE

-- Calculate pet value based on rarity and level
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

	-- Increase value by 10% per level above 1
	local levelMultiplier = 1 + ((level - 1) * 0.1)

	return math.floor(baseValue * levelMultiplier)
end

-- Sell a single pet
function GameCore:SellPet(player, petId)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.pets or not playerData.pets.owned then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Find the pet to sell
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

	-- Check if pet is currently equipped
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

	-- Calculate sell value
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

	-- Notify client
	self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	self:SendNotification(player, "Pet Sold!", 
		"Sold " .. (petToSell.name or "Pet") .. " for " .. sellValue .. " coins", "success")

	print("GameCore: " .. player.Name .. " sold " .. (petToSell.name or petToSell.type) .. " for " .. sellValue .. " coins")
	return true
end

-- Sell multiple pets at once
function GameCore:SellMultiplePets(player, petIds)
	if not petIds or #petIds == 0 then
		self:SendNotification(player, "No Pets Selected", "Select pets to sell first", "error")
		return false
	end

	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.pets or not playerData.pets.owned then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	local totalValue = 0
	local soldPets = {}
	local failedSells = {}

	-- Process each pet
	for _, petId in ipairs(petIds) do
		local petToSell = nil
		local petIndex = nil

		-- Find the pet
		for i, pet in ipairs(playerData.pets.owned) do
			if pet.id == petId then
				petToSell = pet
				petIndex = i
				break
			end
		end

		if not petToSell then
			table.insert(failedSells, "Pet not found: " .. petId)
			continue
		end

		-- Check if equipped
		local isEquipped = false
		for _, equippedPet in ipairs(playerData.pets.equipped or {}) do
			if equippedPet.id == petId then
				isEquipped = true
				break
			end
		end

		if isEquipped then
			table.insert(failedSells, (petToSell.name or "Pet") .. " is equipped")
			continue
		end

		-- Calculate value and remove pet
		local sellValue = self:CalculatePetValue(petToSell)
		table.remove(playerData.pets.owned, petIndex)

		totalValue = totalValue + sellValue
		table.insert(soldPets, petToSell.name or petToSell.type)

		-- Adjust indices for remaining removals
		for j = #petIds, 1, -1 do
			if j > petIndex then
				-- Adjust any remaining indices
			end
		end
	end

	if totalValue > 0 then
		-- Add coins
		playerData.coins = playerData.coins + totalValue
		playerData.stats.coinsEarned = playerData.stats.coinsEarned + totalValue

		-- Update stats
		if not playerData.stats.petsSold then
			playerData.stats.petsSold = 0
		end
		playerData.stats.petsSold = playerData.stats.petsSold + #soldPets

		-- Update client
		self:UpdatePlayerLeaderstats(player)
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)

		self:SendNotification(player, "Pets Sold!", 
			"Sold " .. #soldPets .. " pets for " .. totalValue .. " coins", "success")
	end

	-- Report any failed sells
	if #failedSells > 0 then
		self:SendNotification(player, "Some Sales Failed", 
			table.concat(failedSells, ", "), "warning")
	end

	return totalValue > 0
end

-- Get the sell value of a pet (for UI display)
function GameCore:GetPetSellValue(player, petId)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.pets or not playerData.pets.owned then
		return 0
	end

	for _, pet in ipairs(playerData.pets.owned) do
		if pet.id == petId then
			return self:CalculatePetValue(pet)
		end
	end

	return 0
end
-- Farming System Implementation  
function GameCore:InitializeFarmingSystem()
	print("GameCore: Farming system initialized")
end

function GameCore:InitializePlayerFarm(player)
	local playerData = self:GetPlayerData(player)

	-- Create farm area in workspace
	local workspace = game:GetService("Workspace")
	local farmingAreas = workspace:FindFirstChild("FarmingAreas") or Instance.new("Folder")
	farmingAreas.Name = "FarmingAreas"
	farmingAreas.Parent = workspace

	local playerFarm = farmingAreas:FindFirstChild(player.Name)
	if playerFarm then return end

	playerFarm = Instance.new("Folder")
	playerFarm.Name = player.Name
	playerFarm.Parent = farmingAreas

	-- Create farm plots
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

	-- Plot attributes
	plotModel:SetAttribute("PlotID", plotNumber)
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)

	return plotModel
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
	-- Clean up player data
	self.PlayerData[player.UserId] = nil

	-- Clean up systems
	if self.Systems.Farming.PlayerFarms[player.UserId] then
		self.Systems.Farming.PlayerFarms[player.UserId] = nil
	end

	-- Clean up pets
	for petInstance, data in pairs(self.Systems.Pets.ActivePets) do
		if data.owner == player.UserId then
			pcall(function() petInstance:Destroy() end)
			self.Systems.Pets.ActivePets[petInstance] = nil
		end
	end
end

-- Update Loops
function GameCore:StartUpdateLoops()
	-- Pet spawning loop with memory management
	spawn(function()
		while true do
			wait(10) -- Longer interval to reduce CPU usage

			-- Check memory usage
			local stats = game:GetService("Stats")
			local memoryUsage = stats:GetTotalMemoryUsageMb()

			if memoryUsage > 800 then -- Reduce spawning if memory high
				print("GameCore: High memory usage, reducing spawning")
				wait(30) -- Wait longer
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
			wait(300) -- Save every 5 minutes
			for _, player in ipairs(Players:GetPlayers()) do
				self:SavePlayerData(player)
			end
		end
	end)

	-- Memory cleanup loop
	spawn(function()
		while true do
			wait(60) -- Every minute
			self:CleanupMemory()
		end
	end)
end
function GameCore:CleanupMemory()
	local totalPets = 0
	local oldPets = {}

	-- Count and identify old pets
	for areaName, areaData in pairs(self.Systems.Pets.SpawnAreas) do
		for _, pet in pairs(areaData.container:GetChildren()) do
			totalPets = totalPets + 1

			-- Mark pets older than 10 minutes for cleanup
			local spawnTime = pet:GetAttribute("SpawnTime")
			if not spawnTime then
				pet:SetAttribute("SpawnTime", os.time())
			elseif os.time() - spawnTime > 600 then -- 10 minutes
				table.insert(oldPets, pet)
			end
		end
	end

	-- Clean up old pets if we have too many
	if totalPets > 80 then
		for i = 1, math.min(#oldPets, 20) do
			if oldPets[i] and oldPets[i].Parent then
				oldPets[i]:Destroy()
			end
		end
		print("GameCore: Cleaned up " .. math.min(#oldPets, 20) .. " old pets")
	end

	-- Clean up ActivePets references
	for petInstance, data in pairs(self.Systems.Pets.ActivePets) do
		if not petInstance or not petInstance.Parent then
			self.Systems.Pets.ActivePets[petInstance] = nil
		end
	end
end
function GameCore:UpdateFarmGrowth()
	local workspace = game:GetService("Workspace")
	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then return end

	local currentTime = os.time()

	for _, playerFarm in pairs(farmingAreas:GetChildren()) do
		for _, plot in pairs(playerFarm:GetChildren()) do
			if plot:IsA("Model") and plot:GetAttribute("IsPlanted") then
				local plantTime = plot:GetAttribute("PlantTime") or 0
				local plantType = plot:GetAttribute("PlantType") or ""
				local growthStage = plot:GetAttribute("GrowthStage") or 0

				local seedConfig = ItemConfig.Seeds[plantType]
				if seedConfig then
					local growthTime = seedConfig.growTime or 60
					local elapsedTime = currentTime - plantTime
					local expectedStage = math.min(math.floor((elapsedTime / growthTime) * 4), 4)

					if expectedStage > growthStage then
						plot:SetAttribute("GrowthStage", expectedStage)
						self:UpdatePlantVisual(plot, plantType, expectedStage)
					end
				end
			end
		end
	end
end

function GameCore:UpdatePlantVisual(plot, plantType, growthStage)
	-- Remove old plant model
	local oldPlant = plot:FindFirstChild("Plant")
	if oldPlant then oldPlant:Destroy() end

	-- Create new plant model based on growth stage
	local plantModel = Instance.new("Model")
	plantModel.Name = "Plant"

	-- Create stem
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.2, 0.5 + (growthStage * 0.3), 0.2)
	stem.Position = Vector3.new(0, stem.Size.Y/2, 0)
	stem.Anchored = true
	stem.CanCollide = false
	stem.Material = Enum.Material.Grass
	stem.Color = Color3.fromRGB(58, 125, 21)
	stem.Parent = plantModel

	-- Add fruit when fully grown
	if growthStage >= 4 then
		local seedConfig = ItemConfig.Seeds[plantType]
		local fruit = Instance.new("Part")
		fruit.Name = "Fruit"
		fruit.Position = Vector3.new(0, stem.Size.Y - 0.1, 0)
		fruit.Anchored = true
		fruit.CanCollide = false

		if plantType == "carrot_seeds" then
			fruit.Color = Color3.fromRGB(255, 128, 0)
			fruit.Shape = Enum.PartType.Cylinder
			fruit.Size = Vector3.new(0.3, 0.8, 0.3)
		elseif plantType == "corn_seeds" then
			fruit.Color = Color3.fromRGB(255, 240, 0)
			fruit.Shape = Enum.PartType.Cylinder
			fruit.Size = Vector3.new(0.4, 1, 0.4)
		else
			fruit.Color = Color3.fromRGB(255, 0, 0)
			fruit.Shape = Enum.PartType.Ball
			fruit.Size = Vector3.new(0.5, 0.5, 0.5)
		end

		fruit.Parent = plantModel
	end

	plantModel.Parent = plot

	-- Position relative to soil
	local soil = plot:FindFirstChild("Soil")
	if soil and plantModel.PrimaryPart then
		plantModel:SetPrimaryPartCFrame(CFrame.new(soil.Position + Vector3.new(0, soil.Size.Y/2 + 0.1, 0)))
	end
end

-- Farming System Methods
function GameCore:PlantSeed(player, plotId, seedId)
	local playerData = self:GetPlayerData(player)
	local farmData = self.Systems.Farming.PlayerFarms[player.UserId]

	if not farmData then
		warn("GameCore: No farm found for " .. player.Name)
		return
	end

	-- Find the plot
	local plot = farmData.folder:FindFirstChild("FarmPlot_" .. plotId)
	if not plot then
		self.RemoteEvents.NotificationSent:FireClient(player, "Invalid plot", "Plot not found", "error")
		return
	end

	-- Check if plot is already planted
	if plot:GetAttribute("IsPlanted") then
		self.RemoteEvents.NotificationSent:FireClient(player, "Plot already planted", "This plot already has a plant", "error")
		return
	end

	-- Check if player has seeds
	local seedCount = playerData.farming.inventory[seedId] or 0
	if seedCount <= 0 then
		self.RemoteEvents.NotificationSent:FireClient(player, "No seeds available", "You don't have any " .. seedId, "error")
		return
	end

	-- Plant the seed
	playerData.farming.inventory[seedId] = seedCount - 1
	plot:SetAttribute("IsPlanted", true)
	plot:SetAttribute("PlantType", seedId)
	plot:SetAttribute("GrowthStage", 0)
	plot:SetAttribute("PlantTime", os.time())

	-- Create initial plant visual
	self:UpdatePlantVisual(plot, seedId, 0)

	-- Update client
	self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	self.RemoteEvents.NotificationSent:FireClient(player, "Seed planted!", "Your " .. seedId .. " has been planted", "success")

	print("GameCore: " .. player.Name .. " planted " .. seedId .. " in plot " .. plotId)
end

function GameCore:HarvestCrop(player, plotId)
	local playerData = self:GetPlayerData(player)
	local farmData = self.Systems.Farming.PlayerFarms[player.UserId]

	if not farmData then return end

	local plot = farmData.folder:FindFirstChild("FarmPlot_" .. plotId)
	if not plot or not plot:GetAttribute("IsPlanted") then
		self.RemoteEvents.NotificationSent:FireClient(player, "Nothing to harvest", "This plot is empty", "error")
		return
	end

	local growthStage = plot:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		self.RemoteEvents.NotificationSent:FireClient(player, "Crop not ready", "Wait for the crop to fully grow", "error")
		return
	end

	local plantType = plot:GetAttribute("PlantType")
	local seedConfig = ItemConfig.Seeds[plantType]

	if not seedConfig then return end

	-- Award crop
	local cropId = seedConfig.resultId
	local yieldAmount = seedConfig.yieldAmount or 1

	if not playerData.farming.inventory[cropId] then
		playerData.farming.inventory[cropId] = 0
	end
	playerData.farming.inventory[cropId] = playerData.farming.inventory[cropId] + yieldAmount

	-- Award coins
	local coinReward = seedConfig.coinReward or (yieldAmount * 10)
	playerData.coins = playerData.coins + coinReward
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + coinReward
	playerData.stats.cropsHarvested = playerData.stats.cropsHarvested + yieldAmount

	-- Reset plot
	plot:SetAttribute("IsPlanted", false)
	plot:SetAttribute("PlantType", "")
	plot:SetAttribute("GrowthStage", 0)
	plot:SetAttribute("PlantTime", 0)

	-- Remove plant visual
	local plant = plot:FindFirstChild("Plant")
	if plant then plant:Destroy() end

	-- Update client
	self:UpdatePlayerLeaderstats(player)
	self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	self.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)
	self.RemoteEvents.NotificationSent:FireClient(player, "Harvested " .. yieldAmount .. " crops!", "You earned " .. coinReward .. " coins", "success")

	print("GameCore: " .. player.Name .. " harvested " .. yieldAmount .. " " .. cropId)
end

-- Pet Management Methods
function GameCore:EquipPet(player, petId)
	local playerData = self:GetPlayerData(player)

	-- Find the pet in owned pets
	local petToEquip = nil
	for _, pet in ipairs(playerData.pets.owned) do
		if pet.id == petId then
			petToEquip = pet
			break
		end
	end

	if not petToEquip then
		self.RemoteEvents.NotificationSent:FireClient(player, "Pet not found", "Could not find that pet", "error")
		return
	end

	-- Check if already equipped
	for _, equippedPet in ipairs(playerData.pets.equipped) do
		if equippedPet.id == petId then
			self.RemoteEvents.NotificationSent:FireClient(player, "Pet already equipped", "This pet is already equipped", "error")
			return
		end
	end

	-- Check max equipped limit
	if #playerData.pets.equipped >= GameConfig.MaxEquippedPets then
		self.RemoteEvents.NotificationSent:FireClient(player, "Max pets equipped", "You can only have " .. GameConfig.MaxEquippedPets .. " pets equipped", "error")
		return
	end

	-- Equip the pet (but don't spawn following pets to avoid script errors)
	table.insert(playerData.pets.equipped, petToEquip)

	-- Update client
	self.RemoteEvents.PetEquipped:FireClient(player, petId, petToEquip)
	self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)

	print("GameCore: " .. player.Name .. " equipped pet " .. petId)
end
function GameCore:SpawnPlayerPet(player, petData)
	local character = player.Character
	if not character then return end

	local petConfig = ItemConfig.Pets[petData.type]
	if not petConfig then return end

	-- Create pet model
	local petModel = self:CreatePetModel(petConfig, character.HumanoidRootPart.Position + Vector3.new(5, 0, 0))
	if not petModel then return end

	petModel.Name = petData.type .. "_" .. petData.id
	petModel.Parent = workspace

	-- Add following behavior
	self:AddPetFollowBehavior(petModel, player)

	-- Track the pet
	self.Systems.Pets.ActivePets[petModel] = {
		owner = player.UserId,
		petId = petData.id,
		data = petData
	}
end

function GameCore:AddPetFollowBehavior(petModel, player)
	local moveScript = Instance.new("Script")
	moveScript.Name = "FollowScript"
	moveScript.Source = [[
        local pet = script.Parent
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        
        local player = Players:FindFirstChild("]] .. player.Name .. [[")
        if not player then return end
        
        local humanoid = pet:FindFirstChild("Humanoid")
        local rootPart = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
        if not humanoid or not rootPart then return end
        
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not player or not player.Parent or not player.Character then
                connection:Disconnect()
                return
            end
            
            local character = player.Character
            local charRoot = character:FindFirstChild("HumanoidRootPart")
            if not charRoot then return end
            
            local distance = (rootPart.Position - charRoot.Position).Magnitude
            if distance > 10 then
                -- Teleport if too far
                rootPart.CFrame = CFrame.new(charRoot.Position + Vector3.new(5, 0, 0))
            elseif distance > 5 then
                -- Walk towards player
                local direction = (charRoot.Position - rootPart.Position).Unit
                rootPart.CFrame = rootPart.CFrame + direction * 2
            end
        end)
    ]]
	moveScript.Parent = petModel
end

-- Currency and Economy Methods
function GameCore:AddCurrency(player, currencyType, amount)
	local playerData = self:GetPlayerData(player)

	if not playerData[currencyType:lower()] then
		playerData[currencyType:lower()] = 0
	end

	playerData[currencyType:lower()] = playerData[currencyType:lower()] + amount

	-- Update leaderstats
	self:UpdatePlayerLeaderstats(player)

	-- Notify client
	self.RemoteEvents.CurrencyUpdated:FireClient(player, {
		[currencyType] = playerData[currencyType:lower()]
	})

	return true
end

function GameCore:ProcessDevProductPurchase(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player probably left the game
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productConfig = ItemConfig.DeveloperProducts[receiptInfo.ProductId]
	if not productConfig then
		warn("GameCore: Unknown product ID: " .. receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Give the purchased item
	if productConfig.currencyType and productConfig.amount then
		self:AddCurrency(player, productConfig.currencyType, productConfig.amount)

		self.RemoteEvents.NotificationSent:FireClient(player, 
			"Purchase Complete", 
			"Added " .. productConfig.amount .. " " .. productConfig.currencyType, 
			"success")

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Utility Methods
function GameCore:SendNotification(player, title, message, type)
	self.RemoteEvents.NotificationSent:FireClient(player, title, message, type or "info")
end

function GameCore:GetPlayerStats(player)
	local playerData = self:GetPlayerData(player)
	return playerData.stats
end

function GameCore:AwardAchievement(player, achievementId)
	local playerData = self:GetPlayerData(player)

	if not playerData.achievements then
		playerData.achievements = {}
	end

	if playerData.achievements[achievementId] then
		return false -- Already has achievement
	end

	playerData.achievements[achievementId] = os.time()

	local achievementConfig = ItemConfig.Achievements[achievementId]
	if achievementConfig then
		-- Award any rewards
		if achievementConfig.coinReward then
			self:AddCurrency(player, "coins", achievementConfig.coinReward)
		end

		self.RemoteEvents.NotificationSent:FireClient(player, 
			"Achievement Unlocked!", 
			achievementConfig.name, 
			"achievement")
	end

	return true
end

-- Debug and Admin Methods
function GameCore:AdminGiveCurrency(player, currencyType, amount)
	if not player:GetAttribute("Admin") then return false end

	self:AddCurrency(player, currencyType, amount)
	return true
end

function GameCore:AdminSpawnPet(player, petType, position)
	if not player:GetAttribute("Admin") then return false end

	local petConfig = ItemConfig.Pets[petType]
	if not petConfig then return false end

	local petModel = self:CreatePetModel(petConfig, position or player.Character.HumanoidRootPart.Position)
	if petModel then
		petModel.Parent = workspace
		return true
	end

	return false
end

-- Make the module globally available
_G.GameCore = GameCore

return GameCore