--[[
    ShopSystem.lua - Complete Shop Management Module
    Place in: ServerScriptService/Systems/ShopSystem.lua
    
    Features:
    ✅ Complete shop item management
    ✅ Purchase processing and validation
    ✅ Remote function handling
    ✅ Integration with ItemConfig
    ✅ Debug and testing tools
    ✅ Error handling and recovery
]]

local ShopSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Module State
ShopSystem.RemoteEvents = {}
ShopSystem.RemoteFunctions = {}
ShopSystem.ItemConfig = nil
ShopSystem.GameCore = nil -- Will be injected

-- Purchase cooldowns to prevent spam
ShopSystem.PurchaseCooldowns = {}
ShopSystem.PURCHASE_COOLDOWN = 1 -- 1 second between purchases

-- ========== INITIALIZATION ==========

function ShopSystem:Initialize(gameCore)
	print("ShopSystem: Initializing shop management module...")

	self.GameCore = gameCore

	-- Load ItemConfig
	local success, itemConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig"))
	end)

	if success and itemConfig then
		self.ItemConfig = itemConfig
		print("ShopSystem: ✅ ItemConfig loaded successfully")
	else
		error("ShopSystem: Failed to load ItemConfig: " .. tostring(itemConfig))
	end

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Setup remote handlers
	self:SetupRemoteHandlers()

	-- Validate shop data
	self:ValidateShopData()

	print("ShopSystem: ✅ Shop system initialization complete")
	return true
end

function ShopSystem:SetupRemoteConnections()
	print("ShopSystem: Setting up remote connections...")

	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Ensure shop-related remotes exist
	local requiredRemotes = {
		-- RemoteFunctions
		{name = "GetShopItems", type = "RemoteFunction"},

		-- RemoteEvents  
		{name = "PurchaseItem", type = "RemoteEvent"},
		{name = "ItemPurchased", type = "RemoteEvent"},
		{name = "SellItem", type = "RemoteEvent"},
		{name = "ItemSold", type = "RemoteEvent"},
		{name = "CurrencyUpdated", type = "RemoteEvent"},
		{name = "ShowNotification", type = "RemoteEvent"}
	}

	for _, remote in ipairs(requiredRemotes) do
		local existing = remoteFolder:FindFirstChild(remote.name)
		if not existing then
			local newRemote = Instance.new(remote.type)
			newRemote.Name = remote.name
			newRemote.Parent = remoteFolder
			print("ShopSystem: Created " .. remote.type .. ": " .. remote.name)
		end

		-- Store reference
		if remote.type == "RemoteEvent" then
			self.RemoteEvents[remote.name] = remoteFolder:FindFirstChild(remote.name)
		else
			self.RemoteFunctions[remote.name] = remoteFolder:FindFirstChild(remote.name)
		end
	end

	print("ShopSystem: Remote connections established")
end

function ShopSystem:SetupRemoteHandlers()
	print("ShopSystem: Setting up remote handlers...")

	-- GetShopItems RemoteFunction
	if self.RemoteFunctions.GetShopItems then
		self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
			return self:HandleGetShopItems(player)
		end
		print("ShopSystem: ✅ GetShopItems handler connected")
	end

	-- PurchaseItem RemoteEvent
	if self.RemoteEvents.PurchaseItem then
		self.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
			self:HandlePurchase(player, itemId, quantity or 1)
		end)
		print("ShopSystem: ✅ PurchaseItem handler connected")
	end

	-- SellItem RemoteEvent
	if self.RemoteEvents.SellItem then
		self.RemoteEvents.SellItem.OnServerEvent:Connect(function(player, itemId, quantity)
			self:HandleSell(player, itemId, quantity or 1)
		end)
		print("ShopSystem: ✅ SellItem handler connected")
	end

	print("ShopSystem: All remote handlers connected")
end

-- ========== SHOP ITEM MANAGEMENT ==========

function ShopSystem:HandleGetShopItems(player)
	print("🛒 ShopSystem: GetShopItems request from " .. player.Name)

	local success, result = pcall(function()
		if not self.ItemConfig or not self.ItemConfig.ShopItems then
			error("ItemConfig.ShopItems not available")
		end

		local shopItemsArray = {}
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		-- Convert dictionary to array with player-specific data
		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			-- Validate essential properties
			if self:ValidateItem(item, itemId) then
				local itemCopy = self:CreateItemCopy(item, itemId, playerData)
				table.insert(shopItemsArray, itemCopy)
			else
				warn("ShopSystem: Invalid item skipped: " .. itemId)
			end
		end

		print("🛒 ShopSystem: Sending " .. #shopItemsArray .. " items to " .. player.Name)
		return shopItemsArray
	end)

	if success then
		return result
	else
		warn("🛒 ShopSystem: GetShopItems failed: " .. tostring(result))
		return {}
	end
end

function ShopSystem:ValidateItem(item, itemId)
	if not item then return false end

	local required = {"name", "price", "currency", "category"}
	for _, prop in ipairs(required) do
		if not item[prop] then
			warn("ShopSystem: Item " .. itemId .. " missing property: " .. prop)
			return false
		end
	end

	-- Validate data types
	if type(item.price) ~= "number" or item.price < 0 then
		warn("ShopSystem: Item " .. itemId .. " has invalid price: " .. tostring(item.price))
		return false
	end

	if type(item.currency) ~= "string" then
		warn("ShopSystem: Item " .. itemId .. " has invalid currency: " .. tostring(item.currency))
		return false
	end

	return true
end

function ShopSystem:CreateItemCopy(item, itemId, playerData)
	local itemCopy = {
		id = itemId,
		name = item.name,
		price = item.price,
		currency = item.currency,
		category = item.category,
		description = item.description or "No description available",
		icon = item.icon or "📦",
		maxQuantity = item.maxQuantity or 999,
		type = item.type or "item"
	}

	-- Copy all additional properties
	for key, value in pairs(item) do
		if not itemCopy[key] then
			itemCopy[key] = value
		end
	end

	-- Add player-specific data
	if playerData then
		itemCopy.canAfford = self:CanPlayerAfford(playerData, item)
		itemCopy.meetsRequirements = self:MeetsRequirements(playerData, item)
		itemCopy.alreadyOwned = self:IsAlreadyOwned(playerData, itemId)
	end

	return itemCopy
end

function ShopSystem:GetShopItemById(itemId)
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		return nil
	end
	return self.ItemConfig.ShopItems[itemId]
end

function ShopSystem:GetShopItemsByCategory(category)
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		return {}
	end

	local items = {}
	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if item.category == category then
			items[itemId] = item
		end
	end
	return items
end

-- ========== PURCHASE SYSTEM ==========

function ShopSystem:HandlePurchase(player, itemId, quantity)
	print("🛒 ShopSystem: Purchase request - " .. player.Name .. " wants " .. quantity .. "x " .. itemId)

	-- Check purchase cooldown
	local userId = player.UserId
	local currentTime = os.time()
	local lastPurchase = self.PurchaseCooldowns[userId] or 0

	if currentTime - lastPurchase < self.PURCHASE_COOLDOWN then
		self:SendNotification(player, "Purchase Cooldown", "Please wait before making another purchase!", "warning")
		return false
	end

	-- Get item data
	local item = self:GetShopItemById(itemId)
	if not item then
		self:SendNotification(player, "Invalid Item", "Item not found: " .. itemId, "error")
		return false
	end

	-- Get player data
	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Player Data Error", "Could not load player data!", "error")
		return false
	end

	-- Validate purchase
	local canPurchase, reason = self:ValidatePurchase(player, playerData, item, quantity)
	if not canPurchase then
		self:SendNotification(player, "Cannot Purchase", reason, "error")
		return false
	end

	-- Process purchase
	local success = self:ProcessPurchase(player, playerData, item, quantity)
	if success then
		-- Update cooldown
		self.PurchaseCooldowns[userId] = currentTime

		-- Send confirmation
		self:SendPurchaseConfirmation(player, item, quantity)

		print("🛒 ShopSystem: Purchase successful - " .. player.Name .. " bought " .. quantity .. "x " .. itemId)
	else
		self:SendNotification(player, "Purchase Failed", "Transaction could not be completed!", "error")
		print("🛒 ShopSystem: Purchase failed for " .. player.Name)
	end

	return success
end

function ShopSystem:ValidatePurchase(player, playerData, item, quantity)
	-- Check if player can afford it
	if not self:CanPlayerAfford(playerData, item, quantity) then
		local currency = item.currency == "farmTokens" and "Farm Tokens" or "Coins"
		return false, "Not enough " .. currency .. "!"
	end

	-- Check requirements
	if not self:MeetsRequirements(playerData, item) then
		if item.requiresPurchase then
			local reqItem = self:GetShopItemById(item.requiresPurchase)
			local reqName = reqItem and reqItem.name or item.requiresPurchase
			return false, "Requires: " .. reqName
		end

		if item.requiresFarmPlot then
			return false, "Requires farm plot!"
		end

		return false, "Requirements not met!"
	end

	-- Check quantity limits
	if item.maxQuantity and item.maxQuantity == 1 then
		if self:IsAlreadyOwned(playerData, item.id) then
			return false, "Already purchased!"
		end
	end

	-- Check stock limits (if any)
	if item.stockLimit then
		local purchased = self:GetPurchaseCount(playerData, item.id)
		if purchased + quantity > item.stockLimit then
			return false, "Not enough stock!"
		end
	end

	return true, "Can purchase"
end

function ShopSystem:ProcessPurchase(player, playerData, item, quantity)
	local success, error = pcall(function()
		-- Calculate total cost
		local totalCost = item.price * quantity
		local currency = item.currency

		-- Deduct currency
		local oldAmount = playerData[currency] or 0
		playerData[currency] = oldAmount - totalCost

		-- Process by item type
		local processed = false

		if item.type == "seed" then
			processed = self:ProcessSeedPurchase(player, playerData, item, quantity)
		elseif item.type == "farmPlot" then
			processed = self:ProcessFarmPlotPurchase(player, playerData, item, quantity)
		elseif item.type == "upgrade" then
			processed = self:ProcessUpgradePurchase(player, playerData, item, quantity)
		elseif item.type == "chicken" then
			processed = self:ProcessChickenPurchase(player, playerData, item, quantity)
		elseif item.type == "feed" then
			processed = self:ProcessFeedPurchase(player, playerData, item, quantity)
		elseif item.type == "tool" then
			processed = self:ProcessToolPurchase(player, playerData, item, quantity)
		else
			processed = self:ProcessGenericPurchase(player, playerData, item, quantity)
		end

		if not processed then
			-- Refund on failure
			playerData[currency] = oldAmount
			error("Item processing failed")
		end

		-- Mark as purchased for single-purchase items
		if item.maxQuantity == 1 then
			playerData.purchaseHistory = playerData.purchaseHistory or {}
			playerData.purchaseHistory[item.id] = true
		end

		-- Save and update
		if self.GameCore then
			self.GameCore:SavePlayerData(player)
			self.GameCore:UpdatePlayerLeaderstats(player)

			-- Send player data update
			if self.GameCore.RemoteEvents and self.GameCore.RemoteEvents.PlayerDataUpdated then
				self.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
			end
		end

		return true
	end)

	if not success then
		warn("ShopSystem: Purchase processing failed: " .. tostring(error))
		return false
	end

	return true
end

-- ========== ITEM TYPE PROCESSORS ==========

function ShopSystem:ProcessSeedPurchase(player, playerData, item, quantity)
	-- Initialize farming data
	if not playerData.farming then
		playerData.farming = {plots = 0, inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	-- Add seeds to inventory
	local currentAmount = playerData.farming.inventory[item.id] or 0
	playerData.farming.inventory[item.id] = currentAmount + quantity

	print("ShopSystem: Added " .. quantity .. "x " .. item.id .. " to farming inventory")
	return true
end

function ShopSystem:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	if not self.GameCore then return false end

	if item.id == "farm_plot_starter" then
		-- First farm plot
		playerData.farming = playerData.farming or {}
		playerData.farming.plots = 1
		playerData.farming.inventory = playerData.farming.inventory or {}

		-- Add starter seeds if specified
		if item.effects and item.effects.starterSeeds then
			for seedId, amount in pairs(item.effects.starterSeeds) do
				playerData.farming.inventory[seedId] = (playerData.farming.inventory[seedId] or 0) + amount
			end
		end

		-- Create the first farm plot
		return self.GameCore:CreatePlayerFarmPlot(player, 1)

	elseif item.id == "farm_plot_expansion" then
		-- Additional farm plots
		local currentPlots = playerData.farming and playerData.farming.plots or 0
		local newPlotNumber = currentPlots + 1

		if newPlotNumber > 10 then
			return false
		end

		playerData.farming = playerData.farming or {}
		playerData.farming.plots = newPlotNumber

		-- Create the new plot
		return self.GameCore:CreatePlayerFarmPlot(player, newPlotNumber)
	end

	return false
end

function ShopSystem:ProcessUpgradePurchase(player, playerData, item, quantity)
	playerData.upgrades = playerData.upgrades or {}
	local currentLevel = playerData.upgrades[item.id] or 0
	playerData.upgrades[item.id] = currentLevel + quantity

	-- Apply upgrade effects if GameCore has the method
	if self.GameCore and self.GameCore.ApplyUpgradeEffect then
		self.GameCore:ApplyUpgradeEffect(player, item.id, playerData.upgrades[item.id])
	end

	return true
end

function ShopSystem:ProcessChickenPurchase(player, playerData, item, quantity)
	-- Initialize defense data
	if not playerData.defense then
		playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}, pestControl = {}, roofs = {}}
	end
	if not playerData.defense.chickens then
		playerData.defense.chickens = {owned = {}, deployed = {}, feed = {}}
	end
	if not playerData.defense.chickens.owned then
		playerData.defense.chickens.owned = {}
	end

	-- Check if player has a farm
	local hasValidFarm = playerData.farming and playerData.farming.plots and playerData.farming.plots > 0
	if not hasValidFarm then
		return false
	end

	-- Add chicken to inventory
	for i = 1, quantity do
		local chickenId = HttpService:GenerateGUID(false)
		playerData.defense.chickens.owned[chickenId] = {
			type = item.id,
			purchaseTime = os.time(),
			status = "available",
			chickenId = chickenId
		}
	end

	return true
end

function ShopSystem:ProcessFeedPurchase(player, playerData, item, quantity)
	-- Initialize feed storage
	if not playerData.defense then
		playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}, pestControl = {}, roofs = {}}
	end
	if not playerData.defense.chickens then
		playerData.defense.chickens = {owned = {}, deployed = {}, feed = {}}
	end
	if not playerData.defense.chickens.feed then
		playerData.defense.chickens.feed = {}
	end

	-- Add feed to inventory
	local currentAmount = playerData.defense.chickens.feed[item.id] or 0
	playerData.defense.chickens.feed[item.id] = currentAmount + quantity

	return true
end

function ShopSystem:ProcessToolPurchase(player, playerData, item, quantity)
	-- Initialize tool storage based on tool type
	if item.id:find("pesticide") or item.id:find("pest_") then
		-- Pest control tools
		if not playerData.defense then
			playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}, pestControl = {}, roofs = {}}
		end
		if not playerData.defense.pestControl then
			playerData.defense.pestControl = {}
		end

		if item.id == "pest_detector" then
			playerData.defense.pestControl.pest_detector = true
		else
			local currentAmount = playerData.defense.pestControl[item.id] or 0
			playerData.defense.pestControl[item.id] = currentAmount + quantity
		end
	else
		-- General tools
		if not playerData.inventory then
			playerData.inventory = {}
		end
		local currentAmount = playerData.inventory[item.id] or 0
		playerData.inventory[item.id] = currentAmount + quantity
	end

	return true
end

function ShopSystem:ProcessGenericPurchase(player, playerData, item, quantity)
	-- Generic item processing
	if not playerData.inventory then
		playerData.inventory = {}
	end

	local currentAmount = playerData.inventory[item.id] or 0
	playerData.inventory[item.id] = currentAmount + quantity

	return true
end

-- ========== SELLING SYSTEM ==========

function ShopSystem:HandleSell(player, itemId, quantity)
	print("🛒 ShopSystem: Sell request - " .. player.Name .. " wants to sell " .. quantity .. "x " .. itemId)

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Sell Error", "Player data not found", "error")
		return false
	end

	-- Find the item in player's inventory
	local availableQuantity, inventoryPath = self:FindPlayerItem(playerData, itemId)

	if availableQuantity < quantity then
		self:SendNotification(player, "Not Enough Items", 
			"You only have " .. availableQuantity .. "x " .. self:GetItemDisplayName(itemId) .. "!", "error")
		return false
	end

	-- Get sell price
	local sellPrice, sellCurrency = self:GetItemSellPrice(itemId)
	if not sellPrice or sellPrice <= 0 then
		self:SendNotification(player, "Cannot Sell", "This item cannot be sold!", "error")
		return false
	end

	-- Process sale
	local success = self:ProcessSale(player, playerData, itemId, quantity, sellPrice, sellCurrency, inventoryPath)

	if success then
		-- Send confirmation
		if self.RemoteEvents.ItemSold then
			self.RemoteEvents.ItemSold:FireClient(player, itemId, quantity, sellPrice * quantity, sellCurrency)
		end

		local itemName = self:GetItemDisplayName(itemId)
		self:SendNotification(player, "💰 Item Sold!", 
			"Sold " .. quantity .. "x " .. itemName .. " for " .. (sellPrice * quantity) .. " " .. sellCurrency .. "!", "success")
	end

	return success
end

function ShopSystem:FindPlayerItem(playerData, itemId)
	local inventoryLocations = {
		{path = {"farming", "inventory"}, name = "farming"},
		{path = {"livestock", "inventory"}, name = "livestock"},
		{path = {"defense", "chickens", "feed"}, name = "feed"},
		{path = {"inventory"}, name = "general"}
	}

	-- Special handling for milk
	if itemId == "milk" or itemId == "fresh_milk" then
		if playerData.milk and playerData.milk > 0 then
			return playerData.milk, {"milk"}
		end
	end

	-- Check all inventory locations
	for _, location in ipairs(inventoryLocations) do
		local inventory = playerData
		for _, key in ipairs(location.path) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				inventory = nil
				break
			end
		end

		if inventory and inventory[itemId] and inventory[itemId] > 0 then
			return inventory[itemId], location.path
		end
	end

	return 0, nil
end

function ShopSystem:ProcessSale(player, playerData, itemId, quantity, sellPrice, sellCurrency, inventoryPath)
	local success, error = pcall(function()
		local totalEarnings = sellPrice * quantity

		-- Remove items from inventory
		if inventoryPath and inventoryPath[1] == "milk" then
			playerData.milk = math.max(0, playerData.milk - quantity)
		elseif inventoryPath then
			local inventory = playerData
			for _, key in ipairs(inventoryPath) do
				inventory = inventory[key]
			end
			inventory[itemId] = math.max(0, inventory[itemId] - quantity)
		else
			error("Item not found in inventory")
		end

		-- Add currency
		playerData[sellCurrency] = (playerData[sellCurrency] or 0) + totalEarnings

		-- Update stats
		playerData.stats = playerData.stats or {}
		playerData.stats.itemsSold = (playerData.stats.itemsSold or 0) + quantity
		playerData.stats.coinsEarned = (playerData.stats.coinsEarned or 0) + (sellCurrency == "coins" and totalEarnings or 0)

		-- Save and update
		if self.GameCore then
			self.GameCore:SavePlayerData(player)
			self.GameCore:UpdatePlayerLeaderstats(player)

			if self.GameCore.RemoteEvents and self.GameCore.RemoteEvents.PlayerDataUpdated then
				self.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
			end
		end

		return true
	end)

	if not success then
		warn("ShopSystem: Sale processing failed: " .. tostring(error))
		return false
	end

	return true
end

-- ========== VALIDATION HELPERS ==========

function ShopSystem:CanPlayerAfford(playerData, item, quantity)
	quantity = quantity or 1
	if not item.price or not item.currency then return false end

	local totalCost = item.price * quantity
	local playerCurrency = playerData[item.currency] or 0

	return playerCurrency >= totalCost
end

function ShopSystem:MeetsRequirements(playerData, item)
	-- Check purchase requirements
	if item.requiresPurchase then
		if not playerData.purchaseHistory or not playerData.purchaseHistory[item.requiresPurchase] then
			return false
		end
	end

	-- Check farm plot requirement
	if item.requiresFarmPlot then
		if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
			return false
		end
	end

	return true
end

function ShopSystem:IsAlreadyOwned(playerData, itemId)
	return playerData.purchaseHistory and playerData.purchaseHistory[itemId] or false
end

function ShopSystem:GetPurchaseCount(playerData, itemId)
	-- For items that can be purchased multiple times
	if playerData.purchaseHistory and playerData.purchaseHistory[itemId] then
		if type(playerData.purchaseHistory[itemId]) == "number" then
			return playerData.purchaseHistory[itemId]
		else
			return 1 -- Boolean true means purchased once
		end
	end
	return 0
end

-- ========== UTILITY FUNCTIONS ==========

function ShopSystem:GetItemSellPrice(itemId)
	local sellPrices = {
		-- Crops
		carrot = {price = 15, currency = "coins"},
		corn = {price = 25, currency = "coins"},
		strawberry = {price = 40, currency = "coins"},
		golden_fruit = {price = 100, currency = "coins"},
		-- Animal products
		milk = {price = 75, currency = "coins"},
		fresh_milk = {price = 75, currency = "coins"},
		chicken_egg = {price = 5, currency = "coins"},
		-- Ores
		copper_ore = {price = 30, currency = "coins"},
		iron_ore = {price = 50, currency = "coins"},
		gold_ore = {price = 100, currency = "coins"},
		diamond_ore = {price = 200, currency = "coins"}
	}

	local priceData = sellPrices[itemId] or {price = 10, currency = "coins"}
	return priceData.price, priceData.currency
end

function ShopSystem:GetItemDisplayName(itemId)
	local displayNames = {
		carrot = "🥕 Carrot",
		corn = "🌽 Corn",
		strawberry = "🍓 Strawberry",
		golden_fruit = "✨ Golden Fruit",
		milk = "🥛 Fresh Milk",
		fresh_milk = "🥛 Fresh Milk",
		chicken_egg = "🥚 Chicken Egg"
	}

	return displayNames[itemId] or itemId:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

function ShopSystem:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function ShopSystem:SendPurchaseConfirmation(player, item, quantity)
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased:FireClient(player, item.id, quantity, item.price * quantity, item.currency)
	end

	local itemName = item.name or item.id:gsub("_", " ")
	self:SendNotification(player, "🛒 Purchase Complete!", 
		"Purchased " .. quantity .. "x " .. itemName .. "!", "success")
end

-- ========== VALIDATION AND DEBUG ==========

function ShopSystem:ValidateShopData()
	print("ShopSystem: Validating shop data...")

	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		error("ShopSystem: ItemConfig.ShopItems not available!")
	end

	local validItems = 0
	local invalidItems = 0
	local categories = {}

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if self:ValidateItem(item, itemId) then
			validItems = validItems + 1
			local category = item.category or "unknown"
			categories[category] = (categories[category] or 0) + 1
		else
			invalidItems = invalidItems + 1
		end
	end

	print("ShopSystem: Validation complete")
	print("  ✅ Valid items: " .. validItems)
	print("  ❌ Invalid items: " .. invalidItems)
	print("  📊 Categories:")
	for category, count in pairs(categories) do
		print("    " .. category .. ": " .. count .. " items")
	end

	if invalidItems > 0 then
		warn("ShopSystem: " .. invalidItems .. " invalid items found!")
	end

	return invalidItems == 0
end

function ShopSystem:DebugShopSystem(player)
	print("=== SHOP SYSTEM DEBUG ===")
	print("ItemConfig loaded:", self.ItemConfig ~= nil)
	print("GameCore reference:", self.GameCore ~= nil)
	print("RemoteFunctions connected:", self:CountTable(self.RemoteFunctions))
	print("RemoteEvents connected:", self:CountTable(self.RemoteEvents))

	if self.ItemConfig and self.ItemConfig.ShopItems then
		local itemCount = 0
		local categoryCount = {}
		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			itemCount = itemCount + 1
			local cat = item.category or "unknown"
			categoryCount[cat] = (categoryCount[cat] or 0) + 1
		end

		print("Total items:", itemCount)
		print("Categories:")
		for cat, count in pairs(categoryCount) do
			print("  " .. cat .. ": " .. count)
		end
	end

	-- Test the GetShopItems function
	if player then
		local items = self:HandleGetShopItems(player)
		print("GetShopItems test:", #items .. " items returned")
	end

	print("========================")
end

function ShopSystem:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== CLEANUP ==========

function ShopSystem:Cleanup()
	-- Disconnect any connections
	for _, connection in pairs(self.Connections or {}) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	-- Clear references
	self.GameCore = nil
	self.ItemConfig = nil
	self.RemoteEvents = {}
	self.RemoteFunctions = {}
	self.PurchaseCooldowns = {}

	print("ShopSystem: Cleaned up")
end

print("ShopSystem: ✅ Complete shop management module loaded!")
print("Features:")
print("  🛒 Complete item management and validation")
print("  💰 Purchase and selling system")
print("  🔌 Remote function handling")
print("  🛡️ Error handling and validation")
print("  🧪 Debug and testing tools")

return ShopSystem