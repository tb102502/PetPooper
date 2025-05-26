--[[
    ShopSystemCore.lua - FIXED VERSION
    Core functionality for the shop system
    Created: 2025-05-24
    Fixed: 2025-05-25 - Resolved syntax errors and consolidated functionality
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
	DefaultCurrency = {
		Coins = 100,
		Gems = 10
	},
	CurrencyNames = {
		Primary = "Coins",
		Premium = "Gems"
	},
	PurchaseDebounce = 2,
	CurrencySaveInterval = 60
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

	self:SetupDataStore()
	self:LoadShopItems()
	self:SetupRemotes()
	self:ConnectPlayerEvents()
	self:StartAutoSave()
	self:ConnectMarketplaceService()

	print("ShopSystemCore: Initialization complete")
	return true
end

-- Set up data store
function ShopSystemCore:SetupDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore(self.Config.DataStoreKey)
	end)

	if success then
		self.ShopDataStore = dataStore
		print("ShopSystemCore: Data store setup complete")
	else
		warn("ShopSystemCore: Failed to get data store, using memory store instead")
		self.IsUsingMemoryStore = true
	end
end

-- Load shop items from configuration
function ShopSystemCore:LoadShopItems()
	-- Load from ShopData module if available
	local shopDataModule = ReplicatedStorage:FindFirstChild("ShopData")
	if shopDataModule then
		local success, shopData = pcall(function()
			return require(shopDataModule)
		end)

		if success and shopData then
			-- Consolidate all shop items into a single array
			self.Cache.ShopItems = {}

			-- Add items from different categories
			for categoryName, items in pairs(shopData) do
				if type(items) == "table" and items[1] then -- Check if it's an array
					for _, item in ipairs(items) do
						item.category = categoryName
						table.insert(self.Cache.ShopItems, item)
					end
				end
			end

			print("ShopSystemCore: Loaded " .. #self.Cache.ShopItems .. " shop items")
		else
			warn("ShopSystemCore: Failed to load shop data, using defaults")
			self:CreateDefaultShopItems()
		end
	else
		warn("ShopSystemCore: No ShopData module found, using defaults")
		self:CreateDefaultShopItems()
	end
end

-- Create default shop items
function ShopSystemCore:CreateDefaultShopItems()
	self.Cache.ShopItems = {
		{
			id = "basic_pet_egg",
			name = "Basic Pet Egg",
			description = "A basic pet egg with common pets",
			price = 100,
			currency = "Coins",
			category = "Eggs",
			image = "rbxassetid://123456789"
		},
		{
			id = "rare_pet_egg", 
			name = "Rare Pet Egg",
			description = "A rare pet egg with uncommon pets",
			price = 250,
			currency = "Coins",
			category = "Eggs",
			image = "rbxassetid://123456790"
		},
		{
			id = "coin_booster",
			name = "2x Coins Booster",
			description = "Double coins for 30 minutes",
			price = 25,
			currency = "Gems",
			category = "Boosters",
			duration = 1800,
			boostType = "Currency",
			boostValue = 2,
			boostCurrency = "Coins"
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

	-- Remote events
	local events = {
		"PurchaseItem",
		"CurrencyUpdated", 
		"ItemPurchased",
		"PremiumPurchased",
		"BoosterActivated",
		"BoosterExpired"
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
		"GetShopItems",
		"GetPlayerCurrency", 
		"GetActiveBoosts"
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

	-- Connect handlers
	self.Remotes.Functions.GetShopItems.OnServerInvoke = function(player)
		return self:GetShopItems(player)
	end

	self.Remotes.Functions.GetPlayerCurrency.OnServerInvoke = function(player)
		return self:GetPlayerCurrency(player)
	end

	self.Remotes.Functions.GetActiveBoosts.OnServerInvoke = function(player)
		return self:GetActiveBoosts(player)
	end

	self.Remotes.Events.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
		self:HandleItemPurchase(player, itemId, quantity or 1)
	end)

	print("ShopSystemCore: Remote events and functions set up")
end

-- Connect player events
function ShopSystemCore:ConnectPlayerEvents()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayerData(player)
		self:CleanupPlayerData(player)
	end)

	-- Load data for existing players
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

-- Connect to MarketplaceService
function ShopSystemCore:ConnectMarketplaceService()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end
	print("ShopSystemCore: Connected to MarketplaceService")
end

-- Load player data
function ShopSystemCore:LoadPlayerData(player)
	local defaultData = {
		Currency = {
			[self.Config.CurrencyNames.Primary] = self.Config.DefaultCurrency.Coins,
			[self.Config.CurrencyNames.Premium] = self.Config.DefaultCurrency.Gems
		},
		PurchaseHistory = {},
		Boosters = {}
	}

	local data = defaultData

	if not self.IsUsingMemoryStore then
		local success, result = pcall(function()
			return self.ShopDataStore:GetAsync(tostring(player.UserId))
		end)

		if success and result then
			data = result
			-- Ensure all required fields exist
			if not data.Currency then
				data.Currency = defaultData.Currency
			end
			if not data.PurchaseHistory then
				data.PurchaseHistory = {}
			end
			if not data.Boosters then
				data.Boosters = {}
			end
		end
	end

	self.Cache.PlayerData[player.UserId] = data
	self.Cache.PurchaseHistory[player.UserId] = data.PurchaseHistory

	self:UpdateActiveBoosts(player)
	self:NotifyCurrencyUpdate(player)

	print("ShopSystemCore: Loaded data for player " .. player.Name)
end

-- Save player data
function ShopSystemCore:SavePlayerData(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]
	if not data then return end

	data.PurchaseHistory = self.Cache.PurchaseHistory[userId] or {}

	if not self.IsUsingMemoryStore then
		local success, err = pcall(function()
			self.ShopDataStore:SetAsync(tostring(userId), data)
		end)

		if not success then
			warn("ShopSystemCore: Failed to save data for " .. player.Name .. ": " .. tostring(err))
		end
	end
end

-- Save all player data
function ShopSystemCore:SaveAllPlayerData()
	for _, player in ipairs(Players:GetPlayers()) do
		self:SavePlayerData(player)
	end
end

-- Cleanup player data
function ShopSystemCore:CleanupPlayerData(player)
	local userId = player.UserId
	self.Cache.PlayerData[userId] = nil
	self.Cache.PurchaseHistory[userId] = nil
	self.Cache.PlayerDebounce[userId] = nil
	self.Cache.CurrencyBoosts[userId] = nil
end

-- Update active boosts
function ShopSystemCore:UpdateActiveBoosts(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]
	if not data or not data.Boosters then return end

	local currentTime = os.time()
	local activeBoosts = {}
	local updated = false

	for i, booster in ipairs(data.Boosters) do
		if booster.expiresAt > currentTime then
			table.insert(activeBoosts, booster)
		else
			self.Remotes.Events.BoosterExpired:FireClient(player, booster.id)
			updated = true
		end
	end

	if updated then
		data.Boosters = activeBoosts
	end

	-- Update currency boosts cache
	self.Cache.CurrencyBoosts[userId] = {}
	for _, booster in ipairs(activeBoosts) do
		if booster.boostType == "Currency" then
			local multiplier = self.Cache.CurrencyBoosts[userId][booster.boostCurrency] or 1
			self.Cache.CurrencyBoosts[userId][booster.boostCurrency] = multiplier * booster.boostValue
		end
	end
end

-- Notify client of currency update
function ShopSystemCore:NotifyCurrencyUpdate(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]
	if not data then return end

	self.Remotes.Events.CurrencyUpdated:FireClient(player, data.Currency)
end

-- Get shop items for a player
function ShopSystemCore:GetShopItems(player)
	return self.Cache.ShopItems
end

-- Get player currency
function ShopSystemCore:GetPlayerCurrency(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data then
		return self.Config.DefaultCurrency
	end

	return data.Currency
end

-- Get active boosts for a player
function ShopSystemCore:GetActiveBoosts(player)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data or not data.Boosters then
		return {}
	end

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

	self.Cache.PlayerDebounce[userId] = tick()

	-- Find item
	local item = nil
	for _, shopItem in ipairs(self.Cache.ShopItems) do
		if shopItem.id == itemId or shopItem.ID == itemId then
			item = shopItem
			break
		end
	end

	if not item then
		return false, "Item not found"
	end

	-- Get currency field name
	local currencyField = item.currency or item.Currency or "Coins"
	local totalPrice = (item.price or item.Price or 0) * quantity

	-- Check if player has enough currency
	local data = self.Cache.PlayerData[userId]
	if not data then
		return false, "Player data not found"
	end

	if not data.Currency[currencyField] or data.Currency[currencyField] < totalPrice then
		return false, "Not enough " .. currencyField
	end

	-- Process purchase
	data.Currency[currencyField] = data.Currency[currencyField] - totalPrice

	-- Record purchase
	local purchaseHistory = self.Cache.PurchaseHistory[userId] or {}
	purchaseHistory[itemId] = os.time()
	self.Cache.PurchaseHistory[userId] = purchaseHistory

	-- Process item effects
	self:ProcessItemEffects(player, item, quantity)

	-- Notify client
	self.Remotes.Events.ItemPurchased:FireClient(player, item, quantity)
	self:NotifyCurrencyUpdate(player)

	print("ShopSystemCore: Player " .. player.Name .. " purchased " .. quantity .. " " .. (item.name or item.Name))
	return true, "Purchase successful"
end

-- Process item effects
function ShopSystemCore:ProcessItemEffects(player, item, quantity)
	local category = item.category or "General"

	if category == "Eggs" then
		self:ProcessPetEgg(player, item, quantity)
	elseif category == "Boosters" then
		self:ProcessBooster(player, item, quantity)
	elseif category == "Farming" then
		self:ProcessFarmingItem(player, item, quantity)
	end
end

-- Process pet egg purchase
function ShopSystemCore:ProcessPetEgg(player, item, quantity)
	-- Connect to PetSystem if available
	local petSystem = _G.PetSystemCore
	if petSystem and typeof(petSystem.AddPet) == "function" then
		for i = 1, quantity do
			-- Simple pet generation based on egg type
			local petTypes = {"Corgi", "Cat", "RedPanda", "Hamster"}
			local selectedPet = petTypes[math.random(1, #petTypes)]

			local success, petId = petSystem:AddPet(player, selectedPet)
			if success then
				print("Added pet " .. selectedPet .. " to " .. player.Name)
			end
		end
	else
		print("ShopSystemCore: PetSystem not available for egg processing")
	end
end

-- Process booster purchase
function ShopSystemCore:ProcessBooster(player, item, quantity)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]
	if not data then return end

	local currentTime = os.time()
	local duration = (item.duration or 1800) * quantity
	local boosterId = item.id .. "_" .. currentTime

	local booster = {
		id = boosterId,
		itemId = item.id,
		name = item.name,
		boostType = item.boostType,
		boostValue = item.boostValue,
		boostCurrency = item.boostCurrency,
		activatedAt = currentTime,
		expiresAt = currentTime + duration
	}

	if not data.Boosters then
		data.Boosters = {}
	end
	table.insert(data.Boosters, booster)

	-- Update boosts cache
	if item.boostType == "Currency" then
		if not self.Cache.CurrencyBoosts[userId] then
			self.Cache.CurrencyBoosts[userId] = {}
		end
		local current = self.Cache.CurrencyBoosts[userId][item.boostCurrency] or 1
		self.Cache.CurrencyBoosts[userId][item.boostCurrency] = current * item.boostValue
	end

	self.Remotes.Events.BoosterActivated:FireClient(player, booster)
end

-- Process farming item purchase
function ShopSystemCore:ProcessFarmingItem(player, item, quantity)
	-- Connect to farming system if available
	local farmingModule = _G.FarmingModule
	if farmingModule then
		-- Add seeds/tools to farming inventory
		local playerData = self.Cache.PlayerData[player.UserId]
		if not playerData.FarmingInventory then
			playerData.FarmingInventory = {}
		end

		local currentAmount = playerData.FarmingInventory[item.id] or 0
		playerData.FarmingInventory[item.id] = currentAmount + quantity

		print("Added " .. quantity .. " " .. item.name .. " to " .. player.Name .. "'s farming inventory")
	end
end

-- Process developer product purchases
function ShopSystemCore:ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Define product mappings
	local productInfo = {
		[1234567] = {currencyType = "Gems", amount = 100},
		[1234568] = {currencyType = "Gems", amount = 500}, 
		[1234569] = {currencyType = "Gems", amount = 1000}
	}

	local product = productInfo[receiptInfo.ProductId]
	if not product then
		warn("ShopSystemCore: Unknown product ID: " .. receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Add currency to player
	local success = self:AddCurrency(player, product.currencyType, product.amount)
	if success then
		self.Remotes.Events.PremiumPurchased:FireClient(player, product.currencyType, product.amount)
		self:SavePlayerData(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Add currency to a player
function ShopSystemCore:AddCurrency(player, currencyType, amount)
	if not player or not currencyType or not amount then
		return false
	end

	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data then
		data = {
			Currency = self.Config.DefaultCurrency,
			PurchaseHistory = {},
			Boosters = {}
		}
		self.Cache.PlayerData[userId] = data
	end

	if not data.Currency then
		data.Currency = {}
	end

	if not data.Currency[currencyType] then
		data.Currency[currencyType] = 0
	end

	-- Apply currency boosts
	local boost = 1
	if self.Cache.CurrencyBoosts[userId] and self.Cache.CurrencyBoosts[userId][currencyType] then
		boost = self.Cache.CurrencyBoosts[userId][currencyType]
	end

	local boostedAmount = math.floor(amount * boost)
	data.Currency[currencyType] = data.Currency[currencyType] + boostedAmount

	self:NotifyCurrencyUpdate(player)

	print("ShopSystemCore: Added " .. boostedAmount .. " " .. currencyType .. " to " .. player.Name)
	return true
end

-- Remove currency from a player
function ShopSystemCore:RemoveCurrency(player, currencyType, amount)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]
	if not data or not data.Currency then return false end

	if not data.Currency[currencyType] or data.Currency[currencyType] < amount then
		return false
	end

	data.Currency[currencyType] = data.Currency[currencyType] - amount
	self:NotifyCurrencyUpdate(player)
	return true
end

-- Get currency amount for a player
function ShopSystemCore:GetCurrency(player, currencyType)
	local userId = player.UserId
	local data = self.Cache.PlayerData[userId]

	if not data or not data.Currency then
		return 0
	end

	return data.Currency[currencyType] or 0
end

-- Check if player can afford something
function ShopSystemCore:CanAfford(player, currencyType, cost)
	return self:GetCurrency(player, currencyType) >= cost
end

return ShopSystemCore