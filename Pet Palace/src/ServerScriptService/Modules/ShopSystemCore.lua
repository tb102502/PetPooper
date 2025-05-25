--[[
    ShopSystemCore.lua
    Core functionality for the shop system
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
]]

local ShopSystemCore = {}

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Constants
ShopSystemCore.Config = {
	DataStoreKey = "ShopData_v1",
	DefaultCurrency = 100,
	CurrencyNames = {
		Primary = "Coins",
		Premium = "Gems"
	},
	PurchaseDebounce = 2, -- Seconds to wait between purchases
	CurrencySaveInterval = 60 -- Save currency values every minute
}

-- Cache
ShopSystemCore.Cache = {
	PlayerData = {},
	ShopItems = {},
	CurrencyBoosts = {},
	PurchaseHistory = {},
	PlayerDebounce = {}
}

-- Remote events and functions
ShopSystemCore.Remotes = {
	Events = {},
	Functions = {}
}

-- Initialize the shop system
function ShopSystemCore:Initialize()
	print("ShopSystemCore: Initializing...")

	-- Set up data storage
	self:SetupDataStore()

	-- Load shop items
	self:LoadShopItems()

	-- Set up remote events and functions
	self:SetupRemotes()

	-- Connect player events
	self:ConnectPlayerEvents()

	-- Start auto-save
	self:StartAutoSave()

	-- Connect to developer product purchases
	self:ConnectMarketplaceService()

	print("ShopSystemCore: Initialization complete")
	return true
end

-- Set up data store for shop data
function ShopSystemCore:SetupDataStore()
	self.ShopDataStore = DataStoreService:GetDataStore(self.Config.DataStoreKey)

	-- Create backup of data store if needed
	if not self.ShopDataStore then
		warn("ShopSystemCore: Failed to get data store, using memory store instead")
		self.IsUsingMemoryStore = true
	else
		print("ShopSystemCore: Data store setup complete")
	end
end

-- Load shop items from configuration
function ShopSystemCore:LoadShopItems()
	local shopConfig = ServerScriptService.Modules:FindFirstChild("ShopConfig")

	if shopConfig and shopConfig:IsA("ModuleScript") then
		local success, config = pcall(function()
			return require(shopConfig)
		end)

		if success and config then
			self.Cache.ShopItems = config.Items or {}
			self.Config.CurrencyNames = config.CurrencyNames or self.Config.CurrencyNames

			print("ShopSystemCore: Loaded shop configuration")
		else
			warn("ShopSystemCore: Failed to load shop configuration, using defaults")
			self:CreateDefaultShopItems()
		end
	else
		warn("ShopSystemCore: No shop configuration found, using defaults")
		self:CreateDefaultShopItems()
	end
end

-- Create default shop items if no configuration is found
function ShopSystemCore:CreateDefaultShopItems()
	self.Cache.ShopItems = {
		{
			id = "basic_pet_egg",
			name = "Basic Pet Egg",
			description = "A basic pet egg with common pets",
			price = 100,
			currency = "Coins",
			category = "Eggs",
			image = "rbxassetid://123456789",
			cooldown = 0,
			tags = {"pet", "egg", "basic"}
		},
		{
			id = "rare_pet_egg",
			name = "Rare Pet Egg",
			description = "A rare pet egg with uncommon pets",
			price = 250,
			currency = "Coins",
			category = "Eggs",
			image = "rbxassetid://123456790",
			cooldown = 0,
			tags = {"pet", "egg", "rare"}
		},
		{
			id = "legendary_pet_egg",
			name = "Legendary Pet Egg",
			description = "A legendary pet egg with rare pets",
			price = 50,
			currency = "Gems",
			category = "Eggs",
			image = "rbxassetid://123456791",
			cooldown = 0,
			tags = {"pet", "egg", "legendary"}
		},
		{
			id = "coin_booster",
			name = "2x Coins Booster",
			description = "Double coins for 30 minutes",
			price = 25,
			currency = "Gems",
			category = "Boosters",
			image = "rbxassetid://123456792",
			cooldown = 1800,
			duration = 1800,
			boostType = "Currency",
			boostValue = 2,
			boostCurrency = "Coins",
			tags = {"booster", "currency", "coins"}
		}
	}

	print("ShopSystemCore: Created default shop items")
end

-- Set up remote events and functions
function ShopSystemCore:SetupRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("ShopSystem")

	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "ShopSystem"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Set up remote events
	local events = {
		"PurchaseItem",
		"CurrencyUpdated",
		"ItemPurchased",
		"PremiumPurchased",
		"BoosterActivated",
		"BoosterExpired"
	}

	self.Remotes.Events = {}

	for _, eventName in ipairs(events) do
		local event = remoteFolder:FindFirstChild(eventName)

		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
		end

		self.Remotes.Events[eventName] = event
	end

	-- Set up remote functions
	local functions = {
		"GetShopItems",
		"GetPlayerCurrency",
		"GetActiveBoosts"
	}

	self.Remotes.Functions = {}

	for _, funcName in ipairs(functions) do
		local func = remoteFolder:FindFirstChild(funcName)

		if not func then
			func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
		end

		self.Remotes.Functions[funcName] = func
	end

	-- Connect remote function handlers
	self.Remotes.Functions.GetShopItems.OnServerInvoke = function(player)
		return self:GetShopItems(player)
	end

	self.Remotes.Functions.GetPlayerCurrency.OnServerInvoke = function(player)
		return self:GetPlayerCurrency(player)
	end

	self.Remotes.Functions.GetActiveBoosts.OnServerInvoke = function(player)
		return self:GetActiveBoosts(player)
	end

	-- Connect remote event handlers
	self.Remotes.Events.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
		self:HandleItemPurchase(player, itemId, quantity or 1)
	end)

	print("ShopSystemCore: Remote events and functions set up")
end

-- Connect player events
function ShopSystemCore:ConnectPlayerEvents()
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
	end)

	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayerData(player)
		self.Cache.PlayerData[player.UserId] = nil
		self.Cache.PurchaseHistory[player.UserId] = nil
		self.Cache.PlayerDebounce[player.UserId] = nil
	end)

	-- Load data for players already in the game
	for _, player in ipairs(Players:GetPlayers()) do
		self:LoadPlayerData(player)
	end

	print("ShopSystemCore: Player events connected")
end

-- Start auto-save timer
function ShopSystemCore:StartAutoSave()
	spawn(function()
		while true do
			wait(self.Config.CurrencySaveInterval)
			self:SaveAllPlayerData()
		end
	end)

	print("ShopSystemCore: Auto-save timer started")
end

-- Connect to MarketplaceService for developer products
function ShopSystemCore:ConnectMarketplaceService()
	-- Handle game passes and developer products
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end

	print("ShopSystemCore: Connected to MarketplaceService")
end

-- Load player data
function ShopSystemCore:LoadPlayerData(player)
	-- Initialize default data
	local defaultData = {
		Currencies = {
			[self.Config.CurrencyNames.Primary] = self.Config.DefaultCurrency,
			[self.Config.CurrencyNames.Premium] = 0
		},
		PurchaseHistory = {},
		Boosters = {}
	}

	-- Try to load from data store
	local data = defaultData

	if not self.IsUsingMemoryStore then
		local success, result = pcall(function()
			return self.ShopDataStore:GetAsync(tostring(player.UserId))
		end)

		if success and result then
			-- Merge with defaults for any missing fields
			data = result

			if not data.Currencies then
				data.Currencies = defaultData.Currencies
			else
				-- Ensure all currencies exist
				for currency, value in pairs(defaultData.Currencies) do
					if data.Currencies[currency] == nil then
						data.Currencies[currency] = value
					end
				end
			end

			if not data.PurchaseHistory then
				data.PurchaseHistory = {}
			end

			if not data.Boosters then
				data.Boosters = {}
			end
		else
			warn("ShopSystemCore: Failed to load data for player " .. player.Name)
		end
	end

	-- Store in cache
	self.Cache.PlayerData[player.UserId] = data
	self.Cache.PurchaseHistory[player.UserId] = data.PurchaseHistory

	-- Update active boosters
	self:UpdateActiveBoosts(player)

	-- Notify client of currency update
	self:NotifyCurrencyUpdate(player)

	print("ShopSystemCore: Loaded data for player " .. player.Name)
end

-- Save player data
function ShopSystemCore:SavePlayerData(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data then
		return
	end

	-- Update purchase history
	data.PurchaseHistory = self.Cache.PurchaseHistory[userId] or {}

	-- Save to data store
	if not self.IsUsingMemoryStore then
		local success, err = pcall(function()
			self.ShopDataStore:SetAsync(tostring(userId), data)
		end)

		if not success then
			warn("ShopSystemCore: Failed to save data for player " .. player.Name .. ": " .. tostring(err))
		end
	end

	print("ShopSystemCore: Saved data for player " .. player.Name)
end

-- Save all player data
function ShopSystemCore:SaveAllPlayerData()
	for _, player in ipairs(Players:GetPlayers()) do
		self:SavePlayerData(player)
	end

	print("ShopSystemCore: Saved data for all players")
end

-- Update active boosters
function ShopSystemCore:UpdateActiveBoosts(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data or not data.Boosters then
		return
	end

	local currentTime = os.time()
	local activeBoosts = {}
	local updated = false

	-- Filter out expired boosters
	for i, booster in ipairs(data.Boosters) do
		if booster.expiresAt > currentTime then
			table.insert(activeBoosts, booster)
		else
			-- Notify client about expired booster
			self.Remotes.Events.BoosterExpired:FireClient(player, booster.id)
			updated = true
		end
	end

	-- Update boosters in player data
	if updated then
		data.Boosters = activeBoosts
	end

	-- Update currency boosts cache
	self.Cache.CurrencyBoosts[userId] = {}

	for _, booster in ipairs(activeBoosts) do
		if booster.boostType == "Currency" then
			self.Cache.CurrencyBoosts[userId][booster.boostCurrency] = (self.Cache.CurrencyBoosts[userId][booster.boostCurrency] or 1) * booster.boostValue
		end
	end
end

-- Notify client of currency update
function ShopSystemCore:NotifyCurrencyUpdate(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data then
		return
	end

	self.Remotes.Events.CurrencyUpdated:FireClient(player, data.Currencies)
end

-- Get shop items for a player
function ShopSystemCore:GetShopItems(player)
	-- You could filter items based on player level, game state, etc.
	return self.Cache.ShopItems
end

-- Get player currency
function ShopSystemCore:GetPlayerCurrency(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data then
		return {
			[self.Config.CurrencyNames.Primary] = self.Config.DefaultCurrency,
			[self.Config.CurrencyNames.Premium] = 0
		}
	end

	return data.Currencies
end

-- Get active boosts for a player
function ShopSystemCore:GetActiveBoosts(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data or not data.Boosters then
		return {}
	end

	-- Update boosters before returning
	self:UpdateActiveBoosts(player)

	return data.Boosters
end

-- Handle item purchase
function ShopSystemCore:HandleItemPurchase(player, itemId, quantity)
	local userId = player.UserId

	-- Check debounce
	if self.Cache.PlayerDebounce[userId] and tick() - self.Cache.PlayerDebounce[userId] < self.Config.PurchaseDebounce then
		return false, "Please wait before making another purchase"
	end

	-- Set debounce
	self.Cache.PlayerDebounce[userId] = tick()

	-- Find item
	local item
	for _, shopItem in ipairs(self.Cache.ShopItems) do
		if shopItem.id == itemId then
			item = shopItem
			break
		end
	end

	if not item then
		return false, "Item not found"
	end

	-- Validate quantity
	quantity = quantity or 1
	if quantity < 1 then
		quantity = 1
	end

	-- Calculate total price
	local totalPrice = item.price * quantity

	-- Check if player has enough currency
	local data = self.Cache.PlayerData[userId]
	if not data then
		return false, "Player data not found"
	end

	if not data.Currencies[item.currency] or data.Currencies[item.currency] < totalPrice then
		return false, "Not enough " .. item.currency
	end

	-- Check cooldown
	local purchaseHistory = self.Cache.PurchaseHistory[userId] or {}
	local lastPurchase = purchaseHistory[itemId]

	if lastPurchase and item.cooldown and os.time() - lastPurchase < item.cooldown then
		return false, "Item on cooldown"
	end

	-- Process purchase
	data.Currencies[item.currency] = data.Currencies[item.currency] - totalPrice

	-- Record purchase time
	purchaseHistory[itemId] = os.time()
	self.Cache.PurchaseHistory[userId] = purchaseHistory

	-- Process item effects
	self:ProcessItemEffects(player, item, quantity)

	-- Notify client
	self.Remotes.Events.ItemPurchased:FireClient(player, item, quantity)
	self:NotifyCurrencyUpdate(player)

	print("ShopSystemCore: Player " .. player.Name .. " purchased " .. quantity .. " " .. item.name)
	return true, "Purchase successful"
end

-- Process item effects
function ShopSystemCore:ProcessItemEffects(player, item, quantity)
	-- Process different types of items
	if item.category == "Eggs" then
		-- Handle pet eggs
		for i = 1, quantity do
			self:ProcessPetEgg(player, item)
		end
	elseif item.category == "Boosters" then
		-- Handle boosters
		self:ProcessBooster(player, item, quantity)
	end
end

-- Process pet egg purchase
function ShopSystemCore:ProcessPetEgg(player, item)
	-- Check if PetSystem is available
	local petSystem = rawget(_G, "PetSystemCore")

	if petSystem then
		-- Determine pet rarities based on egg type
		local rarityChances = {
			["basic_pet_egg"] = {common = 70, uncommon = 25, rare = 5, epic = 0, legendary = 0},
			["rare_pet_egg"] = {common = 40, uncommon = 40, rare = 15, epic = 5, legendary = 0},
			["legendary_pet_egg"] = {common = 10, uncommon = 30, rare = 40, epic = 15, legendary = 5}
		}

		local chances = rarityChances[item.id] or rarityChances["basic_pet_egg"]

		-- Select a random pet based on rarity
		local roll = math.random(1, 100)
		local selectedRarity
		local cumulativeChance = 0

		for rarity, chance in pairs(chances) do
			cumulativeChance = cumulativeChance + chance
			if roll <= cumulativeChance then
				selectedRarity = rarity
				break
			end
		end

		-- Get pets of the selected rarity
		local availablePets = {}

		for petId, petData in pairs(petSystem.Cache.PetDefinitions) do
			if petData.rarity == selectedRarity then
				table.insert(availablePets, petId)
			end
		end

		-- Select a random pet from the available ones
		if #availablePets > 0 then
			local selectedPetId = availablePets[math.random(1, #availablePets)]

			-- Add pet to player's inventory
			petSystem:AddPet(player, selectedPetId)
		else
			-- Fallback if no pets of the selected rarity are found
			warn("ShopSystemCore: No pets found for rarity " .. selectedRarity)
		end
	else
		print("ShopSystemCore: PetSystem not found, pet egg effect not processed")
	end
end

-- Process booster purchase
function ShopSystemCore:ProcessBooster(player, item, quantity)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data then
		return
	end

	-- Create or update booster
	local currentTime = os.time()
	local expiresAt = currentTime + (item.duration * quantity)
	local boosterId = item.id .. "_" .. currentTime

	-- Create new booster
	local booster = {
		id = boosterId,
		itemId = item.id,
		name = item.name,
		boostType = item.boostType,
		boostValue = item.boostValue,
		boostCurrency = item.boostCurrency,
		activatedAt = currentTime,
		expiresAt = expiresAt
	}

	-- Add to player's boosters
	if not data.Boosters then
		data.Boosters = {}
	end

	table.insert(data.Boosters, booster)

	-- Update currency boosts cache
	if item.boostType == "Currency" then
		if not self.Cache.CurrencyBoosts[userId] then
			self.Cache.CurrencyBoosts[userId] = {}
		end

		self.Cache.CurrencyBoosts[userId][item.boostCurrency] = (self.Cache.CurrencyBoosts[userId][item.boostCurrency] or 1) * item.boostValue
	end

	-- Notify client
	self.Remotes.Events.BoosterActivated:FireClient(player, booster)

	-- Process developer product purchases
function ShopSystemCore:ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		-- Player might have left the game, save the purchase for later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data then
		-- Player data not loaded, try again later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Define purchases
	local productInfo = {
		[1234567] = {currencyType = "Gems", amount = 100},
		[1234568] = {currencyType = "Gems", amount = 500},
		[1234569] = {currencyType = "Gems", amount = 1000},
		[1234570] = {currencyType = "Coins", amount = 10000}
	}

	local product = productInfo[receiptInfo.ProductId]

	if not product then
		warn("ShopSystemCore: Unknown product ID: " .. receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Add currency to player
	data.Currencies[product.currencyType] = (data.Currencies[product.currencyType] or 0) + product.amount

	-- Notify client
	self:NotifyCurrencyUpdate(player)
	self.Remotes.Events.PremiumPurchased:FireClient(player, product.currencyType, product.amount)

	print("ShopSystemCore: Player " .. player.Name .. " purchased " .. product.amount .. " " .. product.currencyType)

	-- Save player data
	self:SavePlayerData(player)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Add currency to a player
	-- Find where the ShopSystemCore table is defined and make sure it includes these methods
	-- This is likely in ServerScriptService.Modules.ShopSystemCore

	-- Add currency to a player
	-- Add this method to your ShopSystemCore module

	-- Add currency to a player
	-- Add this to your ShopSystemCore module
	-- This code needs to be added to your ShopSystemCore module in ServerScriptService.Modules
	-- Make sure it's defined before it's used in ShopSystemInitializer

	-- Add currency to a player
	function ShopSystemCore:AddCurrency(player, currencyType, amount)
		if not player or not currencyType or not amount then
			warn("ShopSystemCore: Invalid parameters for AddCurrency")
			return false
		end

		-- Try to get player data, create if it doesn't exist
		local playerData = self:GetPlayerData(player)
		if not playerData then
			warn("ShopSystemCore: Creating new data for player " .. player.Name)
			playerData = self:CreateDefaultPlayerData(player)
		end

		-- Ensure currency exists in player data
		if not playerData.Currency then
			playerData.Currency = {}
		end

		-- Initialize currency if it doesn't exist yet
		if not playerData.Currency[currencyType] then
			playerData.Currency[currencyType] = 0
		end

		-- Add currency
		playerData.Currency[currencyType] = playerData.Currency[currencyType] + amount

		print("ShopSystemCore: Added " .. amount .. " " .. currencyType .. " to " .. player.Name)

		-- Save player data
		self:SavePlayerData(player)

		-- Notify the client
		if self.Remotes and self.Remotes.Events and self.Remotes.Events.CurrencyUpdated then
			self.Remotes.Events.CurrencyUpdated:FireClient(player, playerData.Currency)
		else
			warn("ShopSystemCore: Could not notify client about currency update, remotes not set up")
		end

		return true
	end

	-- Get currency for a player
	function ShopSystemCore:GetCurrency(player, currencyType)
		-- Get player data
		local playerData = self:GetPlayerData(player)
		if not playerData then
			return 0
		end

		-- Return currency amount or 0 if not found
		if playerData.Currency and playerData.Currency[currencyType] then
			return playerData.Currency[currencyType]
		else
			return 0
		end
	end

	-- Create default player data
	function ShopSystemCore:CreateDefaultPlayerData(player)
		local shopConfig = self:GetConfig()

		-- Create default data structure
		local playerData = {
			Currency = {},
			Inventory = {},
			Boosters = {}
		}

		-- Set default currency amounts
		for currencyType, amount in pairs(shopConfig.StartingCurrency or {}) do
			playerData.Currency[currencyType] = amount
		end

		-- Save to datastore if needed
		self.PlayerData[player.UserId] = playerData
		self:SavePlayerData(player)

		return playerData
	end
	-- Update currency display for player
	function ShopSystemCore:UpdateCurrencyForPlayer(player)
		-- Get currency data
		local playerData = self:GetPlayerData(player)
		if not playerData or not playerData.Currency then
			return
		end

		-- Fire remote event to update client
		if self.Remotes and self.Remotes.Events and self.Remotes.Events.CurrencyUpdated then
			self.Remotes.Events.CurrencyUpdated:FireClient(player, playerData.Currency)
		end
	end

	-- Check if a player can afford a purchase
	function ShopSystemCore:CanAfford(player, currencyType, cost)
		local currentAmount = self:GetCurrency(player, currencyType)
		return currentAmount >= cost
	end
	-- Remove currency from a player
function ShopSystemCore:RemoveCurrency(player, currencyType, amount)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data then
		return false
	end

	-- Check if player has enough
	if not data.Currencies[currencyType] or data.Currencies[currencyType] < amount then
		return false
	end

	-- Remove currency
	data.Currencies[currencyType] = data.Currencies[currencyType] - amount

	-- Notify client
	self:NotifyCurrencyUpdate(player)

	return true
	end
end
	return ShopSystemCore