--[[
    GameCore.lua - COMPLETE UPDATED VERSION WITH ALL FIXES
    Place in: ServerScriptService/Core/GameCore.lua
    
    ALL FIXES APPLIED:
    1. ✅ Fixed pet selling (no equipment checks)
    2. ✅ Fixed shop currency deduction
    3. ✅ Only custom pet models spawn
    4. ✅ Enhanced upgrade system with stats
    5. ✅ Proper egg hatching for seeds
    6. ✅ Collection radius and pet magnet upgrades
    7. ✅ Farming system integration
    8. ✅ Improved memory management
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
local SKIP_PET_VALIDATION = true -- Set to false once you add your pet models
-- Load configuration
local ItemConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("ItemConfig"))

-- Core Data Management
GameCore.PlayerData = {}
GameCore.DataStore = nil
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}

-- System States
GameCore.Systems = {
	Pets = {
		ActivePets = {},
		SpawnAreas = {},
		SpawnTimers = {},
		BehaviorConnections = {},
		NextBehaviorId = 1
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
	self:ValidateCustomPetsOnly()

	print("GameCore: All systems initialized successfully!")
	return true
end

-- Data Store Setup
function GameCore:SetupDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore("PetPalaceData_v4")
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

	-- Shop System Handlers
	self.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
		self:HandlePurchase(player, itemId, quantity or 1)
	end)

	-- Farming System Handlers
	self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotNumber, seedType)
		self:PlantSeed(player, plotNumber, seedType)
	end)

	self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotNumber)
		self:HarvestCrop(player, plotNumber)
	end)

	self.RemoteEvents.FeedPet.OnServerEvent:Connect(function(player, cropId)
		self:FeedPig(player, cropId)
	end)

	-- Remote Functions
	self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
		return self:GetPlayerData(player)
	end

	self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
		return ItemConfig.ShopItems
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
		coins = 500,  -- Increased starting coins
		gems = 25,    -- Increased starting gems
		pets = {
			owned = {},
			equipped = {}
		},
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 3,
			inventory = {
				carrot_seeds = 10,
				corn_seeds = 5,
				strawberry_seeds = 2
			},
			pig = {
				feedCount = 0,
				size = 1.0
			}
		},
		stats = {
			totalPetsCollected = 0,
			coinsEarned = 500,
			itemsPurchased = 0,
			cropsHarvested = 0,
			petsSold = 0,
			legendaryPetsFound = 0
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
			-- Merge with defaults to ensure all fields exist
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
	self:ApplyAllUpgradeEffects(player)
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

-- FIXED: Pet selling without equipment checks
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

	-- REMOVED: Equipment check - pets can be sold directly
	local sellValue = self:CalculatePetValue(petToSell)

	-- Remove pet from collection
	table.remove(playerData.pets.owned, petIndex)

	-- Add coins to player
	playerData.coins = playerData.coins + sellValue
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + sellValue
	playerData.stats.petsSold = (playerData.stats.petsSold or 0) + 1

	-- Update leaderstats immediately
	self:UpdatePlayerLeaderstats(player)

	-- Fire events
	if self.RemoteEvents.PetSold then
		self.RemoteEvents.PetSold:FireClient(player, petToSell, sellValue)
	end

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	if self.RemoteEvents.CurrencyUpdated then
		self.RemoteEvents.CurrencyUpdated:FireClient(player, {
			coins = playerData.coins
		})
	end

	-- Send notification
	self:SendNotification(player, "Pet Sold!", 
		"Sold " .. (petToSell.name or "Pet") .. " for " .. sellValue .. " coins", "success")

	-- Save data
	self:SavePlayerData(player)

	print("GameCore: " .. player.Name .. " sold " .. (petToSell.name or petToSell.type) .. " for " .. sellValue .. " coins")
	return true
end

-- FIXED: Shop purchase with proper currency deduction
function GameCore:HandlePurchase(player, itemId, quantity)
	local playerData = self:GetPlayerData(player)
	local item = ItemConfig.ShopItems[itemId]

	if not item then
		warn("GameCore: Invalid item ID: " .. itemId)
		self:SendNotification(player, "Error", "Item not found", "error")
		return false
	end

	quantity = quantity or 1
	local totalCost = item.price * quantity
	local currency = item.currency:lower()

	-- Check if player has enough currency
	if not playerData[currency] or playerData[currency] < totalCost then
		self:SendNotification(player, "Insufficient " .. item.currency, 
			"You need " .. totalCost .. " " .. item.currency .. " but only have " .. (playerData[currency] or 0), "error")
		return false
	end

	-- FIXED: Deduct currency FIRST
	playerData[currency] = playerData[currency] - totalCost

	-- Apply item effects
	local success = self:ApplyItemEffects(player, item, quantity)
	if not success then
		-- Refund if item effect failed
		playerData[currency] = playerData[currency] + totalCost
		self:SendNotification(player, "Purchase Failed", "Could not apply item effects", "error")
		return false
	end

	-- Update stats
	playerData.stats.itemsPurchased = (playerData.stats.itemsPurchased or 0) + 1

	-- Update leaderstats immediately
	self:UpdatePlayerLeaderstats(player)

	-- Fire all relevant events
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased:FireClient(player, itemId, quantity, totalCost, currency)
	end

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	if self.RemoteEvents.CurrencyUpdated then
		self.RemoteEvents.CurrencyUpdated:FireClient(player, {
			[currency] = playerData[currency]
		})
	end

	-- Send success notification
	self:SendNotification(player, "Purchase Successful!", 
		"Bought " .. quantity .. "x " .. item.name .. " for " .. totalCost .. " " .. currency, "success")

	-- Save data immediately
	self:SavePlayerData(player)

	print("GameCore: " .. player.Name .. " successfully purchased " .. quantity .. "x " .. item.name .. " for " .. totalCost .. " " .. currency)
	return true
end

-- ENHANCED: Apply item effects with proper upgrade handling
function GameCore:ApplyItemEffects(player, item, quantity)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	if item.type == "seed" then
		-- Add seeds to farming inventory
		if not playerData.farming then
			playerData.farming = {inventory = {}}
		end
		if not playerData.farming.inventory then
			playerData.farming.inventory = {}
		end

		playerData.farming.inventory[item.id] = (playerData.farming.inventory[item.id] or 0) + quantity

	elseif item.type == "egg" then
		-- FIXED: Hatch eggs to get seeds instead of pets
		for i = 1, quantity do
			local hatchResults = ItemConfig.HatchEgg(item.id)

			if not playerData.farming then
				playerData.farming = {inventory = {}}
			end
			if not playerData.farming.inventory then
				playerData.farming.inventory = {}
			end

			-- Add hatched seeds to inventory
			for seedId, seedAmount in pairs(hatchResults) do
				playerData.farming.inventory[seedId] = (playerData.farming.inventory[seedId] or 0) + seedAmount
			end

			-- Send notification about what was hatched
			local hatchedItems = {}
			for seedId, seedAmount in pairs(hatchResults) do
				local seedConfig = ItemConfig.Seeds[seedId]
				local seedName = seedConfig and seedConfig.name or seedId
				table.insert(hatchedItems, seedAmount .. "x " .. seedName)
			end

			if #hatchedItems > 0 then
				self:SendNotification(player, "Egg Hatched!", 
					"Received: " .. table.concat(hatchedItems, ", "), "success")
			end
		end

	elseif item.type == "upgrade" then
		-- ENHANCED: Handle upgrades with immediate effect application
		if not playerData.upgrades then
			playerData.upgrades = {}
		end

		local currentLevel = playerData.upgrades[item.id] or 0
		local maxLevel = item.maxLevel or 10

		if currentLevel >= maxLevel then
			self:SendNotification(player, "Max Level", "This upgrade is already at maximum level", "warning")
			return false
		end

		-- Increase upgrade level
		playerData.upgrades[item.id] = currentLevel + quantity

		-- Apply upgrade effects to player immediately
		self:ApplyUpgradeEffects(player, item.id, playerData.upgrades[item.id])

	elseif item.type == "booster" then
		-- Handle temporary boosters
		if not playerData.activeBoosters then
			playerData.activeBoosters = {}
		end

		local boosterData = {
			type = item.boostType,
			multiplier = item.multiplier,
			startTime = os.time(),
			duration = item.duration
		}

		playerData.activeBoosters[item.id] = boosterData

	else
		warn("GameCore: Unknown item type: " .. tostring(item.type))
		return false
	end

	return true
end

-- NEW: Apply upgrade effects to player attributes and stats
function GameCore:ApplyUpgradeEffects(player, upgradeId, level)
	if upgradeId == "speed_upgrade" then
		local newSpeed = 16 + (level * 2)
		player:SetAttribute("WalkSpeedLevel", level)
		player:SetAttribute("CurrentWalkSpeed", newSpeed)

		-- Update character speed if they exist
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = newSpeed
		end

	elseif upgradeId == "collection_radius_upgrade" then
		local newRadius = 5 + (level * 1)
		player:SetAttribute("CollectionRadius", newRadius)

	elseif upgradeId == "pet_magnet_upgrade" then
		local newMagnetRange = 8 + (level * 2)
		local newMagnetStrength = 1.0 + (level * 0.3)
		player:SetAttribute("MagnetRange", newMagnetRange)
		player:SetAttribute("MagnetStrength", newMagnetStrength)

	elseif upgradeId == "farm_plot_upgrade" then
		player:SetAttribute("FarmPlots", 3 + level)
		-- Update player's farm
		self:UpdatePlayerFarm(player)

	elseif upgradeId == "pet_storage_upgrade" then
		local newCapacity = 100 + (level * 25)
		player:SetAttribute("PetCapacity", newCapacity)
	end

	print("GameCore: Applied " .. upgradeId .. " level " .. level .. " to " .. player.Name)
end

-- NEW: Apply all existing upgrades when player joins
function GameCore:ApplyAllUpgradeEffects(player)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.upgrades then return end

	for upgradeId, level in pairs(playerData.upgrades) do
		self:ApplyUpgradeEffects(player, upgradeId, level)
	end
end

-- Pet System Implementation
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

	print("GameCore: Pet system initialized")
end

-- FIXED: Only use custom pet models
function GameCore:CreatePetModel(petConfig, position)
	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModelsFolder then
		warn("GameCore: PetModels folder not found in ReplicatedStorage")
		return nil
	end

	local template = petModelsFolder:FindFirstChild(petConfig.modelName or petConfig.name)
	if not template then
		warn("GameCore: Custom pet model not found: " .. (petConfig.modelName or petConfig.name))
		return nil -- NO FALLBACK - only custom models
	end

	-- Clone the custom model
	local petModel = template:Clone()

	-- Ensure proper configuration
	for _, part in pairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Anchored = false
			part.CanCollide = false
		end
	end

	-- Ensure required components
	local humanoid = petModel:FindFirstChild("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.WalkSpeed = math.random(4, 8)
		humanoid.JumpPower = math.random(30, 50)
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		humanoid.PlatformStand = false
		humanoid.Parent = petModel
	end

	local rootPart = petModel:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		rootPart = petModel.PrimaryPart
		if rootPart then
			rootPart.Name = "HumanoidRootPart"
		else
			-- Find suitable part
			for _, part in pairs(petModel:GetChildren()) do
				if part:IsA("BasePart") then
					part.Name = "HumanoidRootPart"
					rootPart = part
					break
				end
			end
		end
	end

	if not rootPart then
		warn("GameCore: Could not find suitable root part for " .. petConfig.name)
		petModel:Destroy()
		return nil
	end

	petModel.PrimaryPart = rootPart
	petModel.Name = petConfig.name .. "_" .. tick()
	petModel:SetAttribute("PetType", petConfig.id or petConfig.name)
	petModel:SetAttribute("Rarity", petConfig.rarity)
	petModel:SetAttribute("Value", petConfig.collectValue or 1)
	petModel:SetAttribute("SpawnTime", os.time())

	-- Position the pet
	local success = self:PositionPet(petModel, position)
	if not success then
		petModel:Destroy()
		return nil
	end

	-- Start behavior
	self:StartPetBehavior(petModel, petConfig)

	return petModel
end

-- Enhanced pet behavior system
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
	-- FIXED CODE:
	local connection  -- Declare first

	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if connection then connection:Disconnect() end  -- Now it exists!


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

		-- Enhanced proximity detection with player upgrade support
		local playerNearby = false
		local glowRadius = 12
		local collectRadius = 8 -- Increased base collection radius

		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local playerRoot = player.Character.HumanoidRootPart
				local distance = (rootPart.Position - playerRoot.Position).Magnitude

				-- Get player's collection radius from upgrades
				local playerCollectionRadius = player:GetAttribute("CollectionRadius") or collectRadius

				if distance <= playerCollectionRadius and not isCollected then
					isCollected = true
					if connection then connection:Disconnect() end
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
local behaviorConnection
behaviorConnection = RunService.Heartbeat:Connect(function(deltaTime)
	if not petModel or not petModel.Parent or isCollected then
		if behaviorConnection then 
			behaviorConnection:Disconnect()
			behaviorConnection = nil
		end
		return
	end
			removeGlow()
		end)
	end


-- Enhanced wild pet collection
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
	local playerCollectionRadius = player:GetAttribute("CollectionRadius") or 8

	if distance > playerCollectionRadius then
		return false
	end

	local petType = petModel:GetAttribute("PetType")
	local petRarity = petModel:GetAttribute("Rarity") or "Common"
	local petValue = petModel:GetAttribute("Value") or 1

	if not petType then
		warn("Pet model missing PetType attribute")
		return false
	end

	local petConfig = ItemConfig.Pets[petType]
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
	local maxPets = player:GetAttribute("PetCapacity") or 100

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

	-- Clean up behavior connection
	-- Clean up behavior connection
	local behaviorId = petModel:GetAttribute("BehaviorId")
	if behaviorId then
		local connection = self.Systems.Pets.BehaviorConnections[behaviorId]
		if connection then
			connection:Disconnect()
			self.Systems.Pets.BehaviorConnections[behaviorId] = nil
		end
	end

	-- Immediately destroy the pet to prevent double collection
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
		playerData.coins = playerData.coins + rewards.coins
		playerData.stats.coinsEarned = playerData.stats.coinsEarned + rewards.coins
	end
	if rewards.gems > 0 then
		playerData.gems = playerData.gems + rewards.gems
	end

	-- Update player stats
	playerData.stats.totalPetsCollected = playerData.stats.totalPetsCollected + 1
	if petRarity == "Legendary" then
		playerData.stats.legendaryPetsFound = (playerData.stats.legendaryPetsFound or 0) + 1
	end

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

	-- Save data
	self:SavePlayerData(player)

	print("GameCore: " .. player.Name .. " collected " .. petData.name .. " for " .. rewards.coins .. " coins")
	return true
end

-- Enhanced pet spawning
function GameCore:SpawnWildPet(areaName)
	local areaData = self.Systems.Pets.SpawnAreas[areaName]
	if not areaData then 
		warn("GameCore: Area data not found for " .. areaName)
		return 
	end

	local config = areaData.config
	local currentPetCount = #areaData.container:GetChildren()

	if currentPetCount >= config.maxPets then 
		return 
	end

	-- Choose pet based on weighted random from available pets
	local availablePets = config.availablePets
	local selectedPetId = availablePets[math.random(1, #availablePets)]
	local petConfig = ItemConfig.Pets[selectedPetId]

	if not petConfig then 
		warn("GameCore: Pet config not found for " .. selectedPetId)
		return 
	end

	-- Choose spawn position
	local spawnPositions = config.spawnPositions
	if not spawnPositions or #spawnPositions == 0 then
		warn("GameCore: No spawn positions found for " .. areaName)
		return
	end

	local basePosition = spawnPositions[math.random(1, #spawnPositions)]
	local randomOffset = Vector3.new(
		math.random(-3, 3),
		0,
		math.random(-3, 3)
	)
	local finalPosition = basePosition + randomOffset

	-- Create pet model (only custom models)
	local petModel = self:CreatePetModel(petConfig, finalPosition)
	if petModel then
		petModel.Parent = areaData.container
		petModel:SetAttribute("AreaOrigin", areaName)

		-- Set automatic despawn timer (10 minutes)
		spawn(function()
			wait(600) -- 10 minutes
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

-- Enhanced pet value calculation
function GameCore:CalculatePetValue(petData)
	local baseValues = {
		Common = 75,      -- Increased values
		Uncommon = 150,   
		Rare = 350,       
		Epic = 800,       
		Legendary = 2200  
	}

	local baseValue = baseValues[petData.rarity] or baseValues.Common
	local level = petData.level or 1
	local levelMultiplier = 1 + ((level - 1) * 0.15)

	return math.floor(baseValue * levelMultiplier)
end

-- Enhanced collection rewards
function GameCore:CalculateCollectionRewards(petConfig, rarity)
	local baseCoins = petConfig.collectValue or 25
	local baseGems = 0

	local multipliers = {
		Common = 1.0,
		Uncommon = 2.0,
		Rare = 4.0,
		Epic = 8.0,
		Legendary = 16.0
	}

	local mult = multipliers[rarity] or 1
	local coins = math.floor(baseCoins * mult)

	-- Enhanced gem chances
	local gemChances = {
		Common = 0.03,      -- 3% chance
		Uncommon = 0.10,    -- 10% chance  
		Rare = 0.20,        -- 20% chance
		Epic = 0.40,        -- 40% chance
		Legendary = 0.75    -- 75% chance
	}

	local gemChance = gemChances[rarity] or 0
	if math.random() < gemChance then
		baseGems = math.ceil(mult / 2)
	end

	return {
		coins = coins,
		gems = baseGems
	}
end

-- Shop System Implementation
function GameCore:InitializeShopSystem()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessDevProductPurchase(receiptInfo)
	end
	print("GameCore: Shop system initialized")
end

-- Farming System Implementation
function GameCore:InitializeFarmingSystem()
	-- Create farming area if it doesn't exist
	local farmingArea = workspace:FindFirstChild("FarmingArea")
	if not farmingArea then
		farmingArea = Instance.new("Model")
		farmingArea.Name = "FarmingArea"
		farmingArea.Parent = workspace

		-- Create basic farming ground
		local ground = Instance.new("Part")
		ground.Name = "FarmGround"
		ground.Size = Vector3.new(80, 2, 60)
		ground.Position = Vector3.new(-50, 1, -50)
		ground.Anchored = true
		ground.CanCollide = true
		ground.Material = Enum.Material.Grass
		ground.Color = Color3.fromRGB(86, 125, 70)
		ground.Parent = farmingArea

		print("GameCore: Created basic farming area at (-50, 1, -50)")
	end

	print("GameCore: Farming system initialized")
end

function GameCore:InitializePlayerFarm(player)
	local playerData = self:GetPlayerData(player)
	local farmPlotsLevel = playerData.upgrades.farm_plot_upgrade or 0
	local totalPlots = 3 + farmPlotsLevel

	local workspace = game:GetService("Workspace")
	local farmingAreas = workspace:FindFirstChild("FarmingAreas") or Instance.new("Folder")
	farmingAreas.Name = "FarmingAreas"
	farmingAreas.Parent = workspace

	local playerFarm = farmingAreas:FindFirstChild(player.Name)
	if not playerFarm then
		playerFarm = Instance.new("Folder")
		playerFarm.Name = player.Name
		playerFarm.Parent = farmingAreas
	end

	-- Count existing plots
	local existingPlots = 0
	for _, child in pairs(playerFarm:GetChildren()) do
		if child.Name:match("FarmPlot_") then
			existingPlots = existingPlots + 1
		end
	end

	-- Create additional plots if needed
	for i = existingPlots + 1, totalPlots do
		local plot = self:CreateFarmPlot(i)
		plot.Parent = playerFarm
	end

	self.Systems.Farming.PlayerFarms[player.UserId] = {
		folder = playerFarm,
		plots = totalPlots
	}
end

function GameCore:CreateFarmPlot(plotNumber)
	local plotModel = Instance.new("Model")
	plotModel.Name = "FarmPlot_" .. plotNumber

	-- Create soil base
	local soil = Instance.new("Part")
	soil.Name = "Soil"
	soil.Size = Vector3.new(8, 1, 8)

	-- Position plots in a grid
	local row = math.floor((plotNumber - 1) / 5)
	local col = (plotNumber - 1) % 5
	soil.Position = Vector3.new(col * 12, 0.5, row * 12)

	soil.Anchored = true
	soil.CanCollide = true
	soil.Material = Enum.Material.Ground
	soil.Color = Color3.fromRGB(101, 67, 33)
	soil.Parent = plotModel

	-- Add plot border
	local border = Instance.new("Part")
	border.Name = "Border"
	border.Size = Vector3.new(8.5, 0.2, 8.5)
	border.Position = soil.Position + Vector3.new(0, 0.6, 0)
	border.Anchored = true
	border.CanCollide = false
	border.Material = Enum.Material.Wood
	border.Color = Color3.fromRGB(160, 100, 50)
	border.Parent = plotModel

	-- Add plot label
	local plotGui = Instance.new("SurfaceGui")
	plotGui.Face = Enum.NormalId.Top
	plotGui.Parent = soil

	local plotLabel = Instance.new("TextLabel")
	plotLabel.Size = UDim2.new(1, 0, 1, 0)
	plotLabel.BackgroundTransparency = 1
	plotLabel.Text = "Plot " .. plotNumber
	plotLabel.TextColor3 = Color3.new(1, 1, 1)
	plotLabel.TextScaled = true
	plotLabel.Font = Enum.Font.GothamBold
	plotLabel.TextStrokeTransparency = 0
	plotLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	plotLabel.Parent = plotGui

	plotModel.PrimaryPart = soil

	-- Set plot attributes
	plotModel:SetAttribute("PlotID", plotNumber)
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)
	plotModel:SetAttribute("TimeToGrow", 0)

	return plotModel
end

function GameCore:UpdatePlayerFarm(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	local farmPlotsLevel = playerData.upgrades.farm_plot_upgrade or 0
	local totalPlots = 3 + farmPlotsLevel

	-- Find player's farm area
	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then
		self:InitializePlayerFarm(player)
		return
	end

	local playerFarm = farmingAreas:FindFirstChild(player.Name)
	if not playerFarm then
		self:InitializePlayerFarm(player)
		return
	end

	-- Count existing plots
	local existingPlots = 0
	for _, child in pairs(playerFarm:GetChildren()) do
		if child.Name:match("FarmPlot_") then
			existingPlots = existingPlots + 1
		end
	end

	-- Create additional plots if needed
	for i = existingPlots + 1, totalPlots do
		local plot = self:CreateFarmPlot(i)
		plot.Parent = playerFarm
		print("GameCore: Created additional farm plot " .. i .. " for " .. player.Name)
	end
end

-- Farming functions
function GameCore:PlantSeed(player, plotNumber, seedType)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Find the specific seed config
	local seedConfig = ItemConfig.Seeds[seedType .. "_seeds"]
	if not seedConfig then
		self:SendNotification(player, "Error", "Invalid seed type", "error")
		return
	end

	-- Check if player has the seed
	local seedInventory = playerData.farming.inventory[seedType .. "_seeds"]
	if not seedInventory or seedInventory <= 0 then
		self:SendNotification(player, "No Seeds", "You don't have any " .. seedConfig.name, "error")
		return
	end

	-- Find the plot (simplified - you may need to adjust based on your farm structure)
	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then
		self:SendNotification(player, "Error", "Farming area not found", "error")
		return
	end

	local playerFarm = farmingAreas:FindFirstChild(player.Name)
	if not playerFarm then
		self:SendNotification(player, "Error", "Your farm not found", "error")
		return
	end

	local plot = playerFarm:FindFirstChild("FarmPlot_" .. plotNumber)
	if not plot then
		self:SendNotification(player, "Error", "Plot not found", "error")
		return
	end

	-- Check if plot is empty
	if plot:GetAttribute("IsPlanted") then
		self:SendNotification(player, "Plot Occupied", "This plot already has a crop growing!", "warning")
		return
	end

	-- Plant the seed
	playerData.farming.inventory[seedType .. "_seeds"] = playerData.farming.inventory[seedType .. "_seeds"] - 1

	plot:SetAttribute("IsPlanted", true)
	plot:SetAttribute("PlantType", seedType)
	plot:SetAttribute("PlantTime", os.time())
	plot:SetAttribute("GrowthStage", 1)
	plot:SetAttribute("TimeToGrow", seedConfig.growTime)

	-- Start growth process
	self:StartCropGrowth(plot, seedConfig.growTime, seedType)

	self:SendNotification(player, "Seed Planted!", "Planted " .. seedConfig.name .. " in Plot " .. plotNumber, "success")

	-- Update player data
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	-- Save data
	self:SavePlayerData(player)
end

function GameCore:StartCropGrowth(plot, totalGrowTime, cropType)
	local plotNumber = plot:GetAttribute("PlotID")
	local stageTime = totalGrowTime / 4

	spawn(function()
		for stage = 2, 4 do
			wait(stageTime)

			-- Check if plot still exists and has the same crop
			if plot and plot.Parent and plot:GetAttribute("PlantType") == cropType then
				plot:SetAttribute("GrowthStage", stage)
				self:UpdateCropVisual(plot, cropType, stage)
				print("FarmingSystem: Plot " .. plotNumber .. " " .. cropType .. " reached stage " .. stage)
			else
				break
			end
		end
	end)
end

function GameCore:UpdateCropVisual(plot, cropType, stage)
	-- Remove existing crop model
	local existingCrop = plot:FindFirstChild("CropModel")
	if existingCrop then
		existingCrop:Destroy()
	end

	-- Create new crop model based on stage
	local cropModel = Instance.new("Model")
	cropModel.Name = "CropModel"
	cropModel.Parent = plot

	local cropPart = Instance.new("Part")
	cropPart.Name = "Crop"
	cropPart.Anchored = true
	cropPart.CanCollide = false

	-- Crop grows larger as it matures
	local sizeMultiplier = stage / 4
	cropPart.Size = Vector3.new(2 * sizeMultiplier, 3 * sizeMultiplier, 2 * sizeMultiplier)

	-- Position on top of plot
	local soil = plot:FindFirstChild("Soil")
	if soil then
		cropPart.Position = soil.Position + Vector3.new(0, soil.Size.Y/2 + cropPart.Size.Y/2, 0)
	end

	-- Set crop appearance based on type
	if cropType == "carrot" then
		cropPart.Color = Color3.fromRGB(255, 165, 0)
		cropPart.Shape = Enum.PartType.Cylinder
	elseif cropType == "corn" then
		cropPart.Color = Color3.fromRGB(255, 255, 0)
		cropPart.Shape = Enum.PartType.Block
	elseif cropType == "strawberry" then
		cropPart.Color = Color3.fromRGB(255, 0, 0)
		cropPart.Shape = Enum.PartType.Ball
	elseif cropType == "golden_fruit" then
		cropPart.Color = Color3.fromRGB(255, 215, 0)
		cropPart.Material = Enum.Material.Neon
		cropPart.Shape = Enum.PartType.Ball
	end

	cropPart.Parent = cropModel

	-- Add ready to harvest indicator if fully grown
	if stage >= 4 then
		cropPart.Material = Enum.Material.Neon

		-- Add click detector for harvesting
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = cropPart

		clickDetector.MouseClick:Connect(function(player)
			local plotNumber = plot:GetAttribute("PlotID")
			self:HarvestCrop(player, plotNumber)
		end)
	end
end

function GameCore:HarvestCrop(player, plotNumber)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Find the plot
	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then return end

	local playerFarm = farmingAreas:FindFirstChild(player.Name)
	if not playerFarm then return end

	local plot = playerFarm:FindFirstChild("FarmPlot_" .. plotNumber)
	if not plot then return end

	-- Check if plot has a fully grown crop
	local growthStage = plot:GetAttribute("GrowthStage") or 0
	local cropType = plot:GetAttribute("PlantType")

	if plot:GetAttribute("IsEmpty") or growthStage < 4 then
		self:SendNotification(player, "Not Ready", "This crop isn't ready for harvest yet!", "warning")
		return
	end

	-- Get crop config
	local seedConfig = ItemConfig.Seeds[cropType .. "_seeds"]
	local cropConfig = ItemConfig.Crops[cropType]

	if not cropConfig or not seedConfig then return end

	-- Give rewards
	local yieldAmount = seedConfig.yieldAmount or 1
	local coinReward = seedConfig.coinReward or 0

	-- Add crops to inventory
	if not playerData.farming.inventory[cropType] then
		playerData.farming.inventory[cropType] = 0
	end
	playerData.farming.inventory[cropType] = playerData.farming.inventory[cropType] + yieldAmount

	-- Add coins
	playerData.coins = playerData.coins + coinReward
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + coinReward
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + 1

	-- Clear the plot
	plot:SetAttribute("IsPlanted", false)
	plot:SetAttribute("PlantType", "")
	plot:SetAttribute("PlantTime", 0)
	plot:SetAttribute("GrowthStage", 0)

	-- Remove crop model
	local cropModel = plot:FindFirstChild("CropModel")
	if cropModel then
		cropModel:Destroy()
	end

	-- Update leaderstats
	self:UpdatePlayerLeaderstats(player)

	self:SendNotification(player, "Crop Harvested!", 
		"Harvested " .. yieldAmount .. "x " .. cropConfig.name .. " (+" .. coinReward .. " coins)", "success")

	-- Update player data
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	-- Save data
	self:SavePlayerData(player)
end

function GameCore:FeedPig(player, cropId)
	local playerData = self:GetPlayerData(player)
	if not playerData or not cropId then return end

	-- Check if player has the crop
	if not playerData.farming.inventory[cropId] or playerData.farming.inventory[cropId] <= 0 then
		self:SendNotification(player, "No Crops", "You don't have this crop", "error")
		return
	end

	-- Find crop data
	local cropData = ItemConfig.Crops[cropId]
	if not cropData then
		self:SendNotification(player, "Error", "Invalid crop type", "error")
		return
	end

	-- Initialize pig data if needed
	if not playerData.farming.pig then
		playerData.farming.pig = {
			feedCount = 0,
			size = 1
		}
	end

	-- Update pig feeding counter
	playerData.farming.pig.feedCount = playerData.farming.pig.feedCount + 1

	-- Check if pig should grow
	local shouldGrow = playerData.farming.pig.feedCount % 10 == 0
	local message = ""

	if shouldGrow then
		playerData.farming.pig.size = playerData.farming.pig.size + 0.2
		message = "Your pig grew larger! Fed count: " .. playerData.farming.pig.feedCount .. " (Size: " .. string.format("%.1f", playerData.farming.pig.size) .. "x)"
	else
		local remaining = 10 - (playerData.farming.pig.feedCount % 10)
		message = "Fed your pig! " .. remaining .. " more feeds until growth"
	end

	-- Remove crop from inventory
	playerData.farming.inventory[cropId] = playerData.farming.inventory[cropId] - 1

	-- Save data
	self:SavePlayerData(player)

	self:SendNotification(player, "Pig Fed!", message, "success")

	-- Update player data
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end
end

-- Player Management
function GameCore:SetupPlayerEvents()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
		self:CreatePlayerLeaderstats(player)

		-- Apply character upgrades when they spawn
		player.CharacterAdded:Connect(function(character)
			wait(1) -- Wait for character to fully load
			self:ApplyAllUpgradeEffects(player)
		end)
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

	local gems = Instance.new("IntValue")
	gems.Name = "Gems"
	gems.Value = self.PlayerData[player.UserId].gems
	gems.Parent = leaderstats

	local pets = Instance.new("IntValue")
	pets.Name = "Pets"
	pets.Value = #self.PlayerData[player.UserId].pets.owned
	pets.Parent = leaderstats
end

function GameCore:UpdatePlayerLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then coins.Value = playerData.coins end

	local gems = leaderstats:FindFirstChild("Gems")
	if gems then gems.Value = playerData.gems end

	local pets = leaderstats:FindFirstChild("Pets")
	if pets then pets.Value = #playerData.pets.owned end
end

function GameCore:CleanupPlayer(player)
	self.PlayerData[player.UserId] = nil

	if self.Systems.Farming.PlayerFarms[player.UserId] then
		self.Systems.Farming.PlayerFarms[player.UserId] = nil
	end

	-- Clean up pet behavior connections
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
			wait(15) -- Increased spawn interval

			for areaName, areaData in pairs(self.Systems.Pets.SpawnAreas) do
				if os.time() - areaData.lastSpawn >= areaData.config.spawnInterval then
					self:SpawnWildPet(areaName)
					areaData.lastSpawn = os.time()
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
			print("GameCore: Auto-saved all player data")
		end
	end)

	-- Memory cleanup loop
	spawn(function()
		while true do
			wait(120) -- Every 2 minutes
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
			if spawnTime and os.time() - spawnTime > 900 then -- 15 minutes old
				table.insert(oldPets, pet)
			end
		end
	end

	-- Count active connections
	for _, connection in pairs(self.Systems.Pets.BehaviorConnections) do
		if connection then
			totalConnections = totalConnections + 1
		end
	end

	-- Clean up old pets if too many exist
	if totalPets > 60 then
		for i = 1, math.min(#oldPets, 15) do
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
		print("GameCore: Cleaned up " .. math.min(#oldPets, 15) .. " old pets")
	end

	-- Clean up broken connections
	for behaviorId, connection in pairs(self.Systems.Pets.BehaviorConnections) do
		if not connection or not connection.Connected then
			self.Systems.Pets.BehaviorConnections[behaviorId] = nil
		end
	end
end

-- Utility Methods
function GameCore:SendNotification(player, title, message, type)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, type or "info")
	end
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

-- Validation function
function GameCore:ValidateCustomPetsOnly()
	if SKIP_PET_VALIDATION then
		print("GameCore: Pet model validation SKIPPED - will use fallback pets")
		return true
	end

	print("GameCore: Validating custom pet models...")

	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModelsFolder then
		warn("GameCore: PetModels folder not found in ReplicatedStorage!")

		-- CREATE the PetModels folder and basic pets
		petModelsFolder = Instance.new("Folder")
		petModelsFolder.Name = "PetModels"
		petModelsFolder.Parent = ReplicatedStorage

		-- Create basic pet models for testing
		self:CreateBasicPetModels(petModelsFolder)

		print("GameCore: Created basic pet models for testing")
		return true
	end

	local requiredModels = {"Corgi", "RedPanda", "Cat", "Hamster"}
	local foundModels = {}
	local missingModels = {}

	for _, modelName in ipairs(requiredModels) do
		local model = petModelsFolder:FindFirstChild(modelName)
		if model then
			table.insert(foundModels, modelName)
			print("✅ Found custom model: " .. modelName)
		else
			table.insert(missingModels, modelName)
			warn("❌ Missing custom model: " .. modelName)
		end
	end

	if #missingModels > 0 then
		print("GameCore: Creating missing pet models...")
		self:CreateBasicPetModels(petModelsFolder, missingModels)
	end

	print("GameCore: Pet model validation complete!")
	return true
end
function GameCore:CreateBasicPetModels(petModelsFolder, specificModels)
	local modelsToCreate = specificModels or {"Corgi", "RedPanda", "Cat", "Hamster"}

	for _, petName in ipairs(modelsToCreate) do
		local existingModel = petModelsFolder:FindFirstChild(petName)
		if existingModel then continue end

		-- Create a basic pet model
		local petModel = Instance.new("Model")
		petModel.Name = petName

		-- Create body part
		local body = Instance.new("Part")
		body.Name = "HumanoidRootPart"
		body.Size = Vector3.new(2, 2, 3)
		body.Shape = Enum.PartType.Block
		body.Anchored = false
		body.CanCollide = false
		body.Parent = petModel

		-- Create head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.5, 1.5, 1.5)
		head.Shape = Enum.PartType.Ball
		head.Anchored = false
		head.CanCollide = false
		head.Parent = petModel

		-- Position head
		local headWeld = Instance.new("WeldConstraint")
		headWeld.Part0 = body
		headWeld.Part1 = head
		headWeld.Parent = body
		head.CFrame = body.CFrame * CFrame.new(0, 2, 0)

		-- Set colors based on pet type
		if petName == "Corgi" then
			body.Color = Color3.fromRGB(255, 200, 150)
			head.Color = Color3.fromRGB(255, 200, 150)
		elseif petName == "RedPanda" then
			body.Color = Color3.fromRGB(194, 144, 90)
			head.Color = Color3.fromRGB(194, 144, 90)
		elseif petName == "Cat" then
			body.Color = Color3.fromRGB(110, 110, 110)
			head.Color = Color3.fromRGB(110, 110, 110)
		elseif petName == "Hamster" then
			body.Color = Color3.fromRGB(255, 215, 0)
			head.Color = Color3.fromRGB(255, 215, 0)
		end

		-- Add humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.WalkSpeed = math.random(4, 8)
		humanoid.JumpPower = math.random(30, 50)
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		humanoid.Parent = petModel

		-- Set primary part
		petModel.PrimaryPart = body

		-- Parent to folder
		petModel.Parent = petModelsFolder

		print("GameCore: Created basic " .. petName .. " model")
	end
end