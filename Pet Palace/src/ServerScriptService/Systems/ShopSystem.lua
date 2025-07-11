--[[
    FIXED ShopSystem.lua - Items Now Show in Shop
    
    FIXES APPLIED:
    ✅ Fixed overly restrictive category requirements
    ✅ Made basic items always visible
    ✅ Fixed validation logic
    ✅ Added proper debugging
    ✅ Removed blocking requirements for starter items
]]

local ShopSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local GameCore = require(ServerScriptService.Core:WaitForChild("GameCore"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Module State
ShopSystem.RemoteEvents = {}
ShopSystem.RemoteFunctions = {}
ShopSystem.ItemConfig = nil
ShopSystem.GameCore = nil

-- Purchase cooldowns
ShopSystem.PurchaseCooldowns = {}
ShopSystem.PURCHASE_COOLDOWN = 1

-- FIXED: Category configuration for tabbed system
ShopSystem.CategoryConfig = {
	seeds = {
		name = "Seeds",
		emoji = "🌱",
		description = "Plant these to grow crops on your farm",
		priority = 1
	},
	farm = {
		name = "Farming",
		emoji = "🌾",
		description = "Essential farming equipment and expansions",
		priority = 2

	},
	mining = {
		name = "Mining",
		emoji = "⛏️",
		description = "Tools and equipment for mining operations",
		priority = 4
	},
	crafting = {
		name = "Crafting",
		emoji = "🔨",
		description = "Workbenches and crafting stations",
		priority = 5
	},
	premium = {
		name = "Premium",
		emoji = "✨",
		description = "Premium items and exclusive upgrades",
		priority = 6
	},
	sell = {
		name = "Sell Items",
		emoji = "💰",
		description = "Sell your crops, milk, and other items for coins",
		priority = 7
	}
}

-- ========== INITIALIZATION ==========

function ShopSystem:Initialize(gameCore)
	print("ShopSystem: Initializing FIXED shop system...")

	self.GameCore = gameCore

	-- Load ItemConfig
	local success, itemConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
	end)

	if success and itemConfig then
		self.ItemConfig = itemConfig
		print("ShopSystem: ✅ ItemConfig loaded successfully")
		print("ShopSystem: Found " .. self:CountShopItems() .. " total items in ItemConfig")
	else
		error("ShopSystem: Failed to load ItemConfig: " .. tostring(itemConfig))
	end

	-- Setup remote connections
	self:SetupRemoteConnections()
	self:SetupRemoteHandlers()
	self:ValidateShopData()
	self:SetupSeedDebugCommands()
	print("ShopSystem: ✅ FIXED shop system initialization complete")
	return true
end

function ShopSystem:CountShopItems()
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		return 0
	end

	local count = 0
	for _ in pairs(self.ItemConfig.ShopItems) do
		count = count + 1
	end
	return count
end

-- ========== REMOTE SETUP ==========

function ShopSystem:SetupRemoteConnections()
	print("ShopSystem: Setting up remote connections...")

	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	local requiredRemotes = {
		{name = "GetShopItems", type = "RemoteFunction"},
		{name = "GetShopItemsByCategory", type = "RemoteFunction"},
		{name = "GetShopCategories", type = "RemoteFunction"},
		{name = "GetSellableItems", type = "RemoteFunction"},
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
		end

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

	if self.RemoteFunctions.GetShopItems then
		self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
			return self:HandleGetShopItems(player)
		end
	end

	if self.RemoteFunctions.GetShopItemsByCategory then
		self.RemoteFunctions.GetShopItemsByCategory.OnServerInvoke = function(player, category)
			return self:HandleGetShopItemsByCategory(player, category)
		end
	end

	if self.RemoteFunctions.GetShopCategories then
		self.RemoteFunctions.GetShopCategories.OnServerInvoke = function(player)
			return self:HandleGetShopCategories(player)
		end
	end

	if self.RemoteFunctions.GetSellableItems then
		self.RemoteFunctions.GetSellableItems.OnServerInvoke = function(player)
			return self:HandleGetSellableItems(player)
		end
	end

	if self.RemoteEvents.PurchaseItem then
		self.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
			self:HandlePurchase(player, itemId, quantity or 1)
		end)
	end

	if self.RemoteEvents.SellItem then
		self.RemoteEvents.SellItem.OnServerEvent:Connect(function(player, itemId, quantity)
			self:HandleSell(player, itemId, quantity or 1)
		end)
	end

	print("ShopSystem: All remote handlers connected")
end

-- ========== FIXED SHOP ITEMS HANDLERS ==========

function ShopSystem:HandleGetShopItems(player)
	print("🛒 ShopSystem: FIXED GetShopItems request from " .. player.Name)

	local success, result = pcall(function()
		if not self.ItemConfig or not self.ItemConfig.ShopItems then
			error("ItemConfig.ShopItems not available")
		end

		local shopItemsArray = {}
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		local totalItems = 0
		local validItems = 0
		local shownItems = 0

		-- Convert ShopItems to array with FIXED validation
		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			totalItems = totalItems + 1

			if self:ValidateItemFixed(item, itemId) then
				validItems = validItems + 1

				if self:ShouldShowItemFixed(item, itemId, playerData) then
					shownItems = shownItems + 1
					local itemCopy = self:CreateEnhancedItemCopy(item, itemId, playerData)
					table.insert(shopItemsArray, itemCopy)
				else
					print("🔒 Item hidden: " .. itemId .. " (requirements not met)")
				end
			else
				print("❌ Item invalid: " .. itemId .. " (validation failed)")
			end
		end

		-- Sort items
		table.sort(shopItemsArray, function(a, b)
			return self:CompareItemsForSorting(a, b)
		end)

		print("🛒 ShopSystem: Item processing complete:")
		print("  📊 Total items in ItemConfig: " .. totalItems)
		print("  ✅ Valid items: " .. validItems)
		print("  👁️ Shown items: " .. shownItems)
		print("  📦 Returning " .. #shopItemsArray .. " items to client")

		return shopItemsArray
	end)

	if success then
		return result
	else
		warn("🛒 ShopSystem: GetShopItems failed: " .. tostring(result))
		return {}
	end
end

-- FIXED: Much more permissive validation
function ShopSystem:ValidateItemFixed(item, itemId)
	if not item then 
		print("❌ Item is nil: " .. itemId)
		return false 
	end

	-- Check required basic properties
	if not item.name or item.name == "" then
		print("❌ Item missing name: " .. itemId)
		return false
	end

	if not item.price or type(item.price) ~= "number" or item.price < 0 then
		print("❌ Item has invalid price: " .. itemId .. " (price: " .. tostring(item.price) .. ")")
		return false
	end

	if not item.currency then
		print("❌ Item missing currency: " .. itemId)
		return false
	end

	-- Validate currency
	local validCurrencies = {"coins", "farmTokens", "Robux"}
	local isValidCurrency = false
	for _, validCurrency in ipairs(validCurrencies) do
		if item.currency == validCurrency then
			isValidCurrency = true
			break
		end
	end

	if not isValidCurrency then
		print("❌ Item has invalid currency: " .. itemId .. " (currency: " .. tostring(item.currency) .. ")")
		return false
	end

	-- Validate category (but don't fail if missing - provide default)
	if not item.category then
		print("⚠️ Item missing category, using 'farm': " .. itemId)
		item.category = "farm"
	end

	if not self.CategoryConfig[item.category] then
		print("⚠️ Item has unknown category: " .. itemId .. " (category: " .. tostring(item.category) .. ")")
		-- Don't fail validation, just warn
	end

	-- Provide defaults for missing optional properties
	if not item.description then
		item.description = "No description available"
	end

	if not item.icon then
		item.icon = "📦"
	end

	print("✅ Item validated: " .. itemId)
	return true
end

-- FIXED: Much more permissive showing logic
function ShopSystem:ShouldShowItemFixed(item, itemId, playerData)
	-- Always show basic starter items regardless of requirements
	local alwaysShowItems = {
		"farm_plot_starter",
		"carrot_seeds", 
		"potato_seeds",
		"cabbage_seeds",
		"cave_access_pass",
		"basic_workbench"
	}

	for _, alwaysShow in ipairs(alwaysShowItems) do
		if itemId == alwaysShow then
			print("✅ Always showing starter item: " .. itemId)
			return true
		end
	end

	-- Don't show items explicitly marked as not purchasable
	if item.notPurchasable == true then
		print("🔒 Item not purchasable: " .. itemId)
		return false
	end

	-- Check purchase requirements (only for advanced items)
	if item.requiresPurchase and playerData then
		local hasPurchased = playerData.purchaseHistory and playerData.purchaseHistory[item.requiresPurchase]
		if not hasPurchased then
			print("🔒 Item requires purchase: " .. itemId .. " requires " .. item.requiresPurchase)
			return false
		end
	end

	-- Check if already owned (for single-purchase items)
	if item.maxQuantity == 1 and playerData then
		local alreadyOwned = playerData.purchaseHistory and playerData.purchaseHistory[itemId]
		if alreadyOwned then
			print("🔒 Item already owned: " .. itemId)
			return false
		end
	end

	-- REMOVED: Overly restrictive category requirements
	-- Most items should be visible even if requirements aren't met
	-- Players can see what's available and work towards requirements

	print("✅ Item will be shown: " .. itemId)
	return true
end

-- Keep category-specific items handler
function ShopSystem:HandleGetShopItemsByCategory(player, category)
	print("🛒 ShopSystem: GetShopItemsByCategory request from " .. player.Name .. " for category: " .. tostring(category))

	if not category then
		warn("🛒 ShopSystem: No category specified")
		return {}
	end

	if category ~= "sell" and not self.CategoryConfig[category] then
		warn("🛒 ShopSystem: Invalid category requested: " .. tostring(category))
		return {}
	end

	local success, result = pcall(function()
		if not self.ItemConfig or not self.ItemConfig.ShopItems then
			error("ItemConfig.ShopItems not available")
		end

		local categoryItems = {}
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		-- Filter items by category
		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			if item.category == category and self:ValidateItemFixed(item, itemId) and self:ShouldShowItemFixed(item, itemId, playerData) then
				local itemCopy = self:CreateEnhancedItemCopy(item, itemId, playerData)
				table.insert(categoryItems, itemCopy)
			end
		end

		-- Sort by purchase order within category
		table.sort(categoryItems, function(a, b)
			local orderA = a.purchaseOrder or 999
			local orderB = b.purchaseOrder or 999

			if orderA == orderB then
				return a.price < b.price
			end

			return orderA < orderB
		end)

		print("🛒 ShopSystem: Returning " .. #categoryItems .. " items for " .. category .. " category")
		return categoryItems
	end)

	if success then
		return result
	else
		warn("🛒 ShopSystem: GetShopItemsByCategory failed: " .. tostring(result))
		return {}
	end
end

function ShopSystem:HandleGetShopCategories(player)
	print("🛒 ShopSystem: GetShopCategories request from " .. player.Name)

	local categories = {}

	for categoryId, config in pairs(self.CategoryConfig) do
		-- Count items in this category
		local itemCount = 0
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		for itemId, item in pairs(self.ItemConfig.ShopItems or {}) do
			if item.category == categoryId and self:ValidateItemFixed(item, itemId) and self:ShouldShowItemFixed(item, itemId, playerData) then
				itemCount = itemCount + 1
			end
		end

		if itemCount > 0 then
			table.insert(categories, {
				id = categoryId,
				name = config.name,
				emoji = config.emoji,
				description = config.description,
				priority = config.priority,
				itemCount = itemCount
			})
		end
	end

	-- Sort by priority
	table.sort(categories, function(a, b)
		return a.priority < b.priority
	end)

	print("🛒 ShopSystem: Returning " .. #categories .. " categories")
	return categories
end

-- ========== FIXED SELLING SYSTEM ==========

function ShopSystem:HandleGetSellableItems(player)
	print("🏪 ShopSystem: GetSellableItems request from " .. player.Name)

	local success, result = pcall(function()
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
		if not playerData then
			return {}
		end

		local sellableItems = {}

		-- Define sellable item types with their locations and properties
		local sellableItemTypes = {
			-- Crops
			{id = "carrot", name = "🥕 Carrot", sellPrice = 10},
			{id = "potato", name = "🥔 Potato", sellPrice = 15},
			{id = "cabbage", name = "🥬 Cabbage", sellPrice = 20},
			{id = "radish", name = "🌶️ Radish", sellPrice = 25},
			{id = "broccoli", name = "🥦 Broccoli", sellPrice = 30},
			{id = "tomato", name = "🍅 Tomato", sellPrice = 35},
			{id = "strawberry", name = "🍓 Strawberry", sellPrice = 40},
			{id = "wheat", name = "🌾 Wheat", sellPrice = 45},
			{id = "corn", name = "🌽 Corn", sellPrice = 60},	
			{id = "broccarrot", name = "🌽 Broccarrot", sellPrice = 150},		
			{id = "broctato", name = "🌽 Broctato", sellPrice = 200},
			{id = "craddish", name = "🌽 Craddish", sellPrice = 250},
			{id = "brocmato", name = "🌽 Brocmato", sellPrice = 300},
			{id = "cornmato", name = "🌽 Cornmato", sellPrice = 400},
			
			
			-- Animal Products
			{id = "milk", name = "🥛 Fresh Milk", sellPrice = 2},
			-- Ores
			{id = "copper_ore", name = "🟫 Copper Ore", sellPrice = 30},
			{id = "bronze_ore", name = "🟤 Bronze Ore", sellPrice = 45},
			{id = "silver_ore", name = "⚪ Silver Ore", sellPrice = 80},
			{id = "gold_ore", name = "🟡 Gold Ore", sellPrice = 150},
			{id = "platinum_ore", name = "⚫ Platinum Ore", sellPrice = 300}
		}

		-- Check each sellable item type
		for _, itemType in ipairs(sellableItemTypes) do
			local totalStock = self:GetPlayerStockComprehensive(playerData, itemType.id)

			if totalStock > 0 then
				table.insert(sellableItems, {
					id = itemType.id,
					name = itemType.name,
					sellPrice = itemType.sellPrice,
					currency = "coins",
					category = "sell",
					description = "You have " .. totalStock .. " in stock. Sell for " .. itemType.sellPrice .. " coins each.",
					icon = itemType.name:match("^%S+") or "📦",
					stock = totalStock,
					totalValue = totalStock * itemType.sellPrice,
					type = "sellable"
				})
			end
		end

		-- Sort by total value (highest first)
		table.sort(sellableItems, function(a, b)
			return a.totalValue > b.totalValue
		end)

		print("🏪 ShopSystem: Returning " .. #sellableItems .. " sellable items")
		return sellableItems
	end)

	if success then
		return result
	else
		warn("🏪 ShopSystem: GetSellableItems failed: " .. tostring(result))
		return {}
	end
end

function ShopSystem:HandleSell(player, itemId, quantity)
	print("🏪 ShopSystem: Sell request - " .. player.Name .. " wants to sell " .. quantity .. "x " .. itemId)

	-- Validate inputs
	if not itemId or not quantity or quantity <= 0 then
		self:SendNotification(player, "Invalid Sell Request", "Invalid item or quantity!", "error")
		return false
	end

	-- Get player data
	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Player Data Error", "Could not load player data!", "error")
		return false
	end

	-- Check if player has the item
	local playerStock = self:GetPlayerStockComprehensive(playerData, itemId)
	if playerStock < quantity then
		self:SendNotification(player, "Insufficient Stock", "You only have " .. playerStock .. "x " .. itemId .. "!", "error")
		return false
	end

	-- Get sell price
	local sellPrice = self:GetItemSellPrice(itemId)
	if sellPrice <= 0 then
		self:SendNotification(player, "Cannot Sell", "This item cannot be sold!", "error")
		return false
	end

	-- Calculate total value
	local totalValue = sellPrice * quantity
	local currency = self:GetItemSellCurrency(itemId)

	-- Process the sale
	local success, errorMsg = pcall(function()
		return self:ProcessSale(player, playerData, itemId, quantity, totalValue, currency)
	end)

	if success and errorMsg then
		self:SendSaleConfirmation(player, itemId, quantity, totalValue, currency)
		print("🏪 ShopSystem: Sale successful - " .. player.Name .. " sold " .. quantity .. "x " .. itemId .. " for " .. totalValue .. " " .. currency)
		return true
	else
		local error = success and "Unknown error" or tostring(errorMsg)
		self:SendNotification(player, "Sale Failed", "Transaction failed: " .. error, "error")
		return false
	end
end

function ShopSystem:ProcessSale(player, playerData, itemId, quantity, totalValue, currency)
	print("💰 Processing sale:")
	print("  Player: " .. player.Name)
	print("  Item: " .. itemId)
	print("  Quantity: " .. quantity)
	print("  Total Value: " .. totalValue .. " " .. currency)

	-- Remove items from player inventory
	local removed = self:RemoveItemFromPlayerInventory(playerData, itemId, quantity)
	if not removed then
		error("Failed to remove items from inventory")
	end

	-- Add currency to player
	playerData[currency] = (playerData[currency] or 0) + totalValue
	print("💳 Added " .. totalValue .. " " .. currency .. " to player")

	-- Save and update
	if self.GameCore then
		self.GameCore:SavePlayerData(player)
		if self.GameCore.RemoteEvents and self.GameCore.RemoteEvents.PlayerDataUpdated then
			self.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end
		if self.GameCore.RemoteEvents and self.GameCore.RemoteEvents.CurrencyUpdated then
			self.GameCore.RemoteEvents.CurrencyUpdated:FireClient(player, currency, playerData[currency])
		end
	end

	-- Fire item sold event
	if self.RemoteEvents.ItemSold then
		self.RemoteEvents.ItemSold:FireClient(player, itemId, quantity, totalValue, currency)
	end

	return true
end

function ShopSystem:RemoveItemFromPlayerInventory(playerData, itemId, quantity)
	if not playerData then return false end

	local remaining = quantity

	-- Check different inventory locations and remove items
	local locations = {
		{"farming", "inventory"},
		{"livestock", "inventory"},
		{"inventory"}
	}

	for _, path in ipairs(locations) do
		if remaining <= 0 then break end

		local inventory = playerData
		for _, key in ipairs(path) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				inventory = nil
				break
			end
		end

		if inventory and inventory[itemId] then
			local available = inventory[itemId]
			local toRemove = math.min(available, remaining)

			inventory[itemId] = available - toRemove
			remaining = remaining - toRemove

			if inventory[itemId] <= 0 then
				inventory[itemId] = nil
			end

			print("📦 Removed " .. toRemove .. "x " .. itemId .. " from " .. table.concat(path, "."))
		end
	end

	-- Special case for milk
	if itemId == "milk" and remaining > 0 and playerData.milk then
		local available = playerData.milk
		local toRemove = math.min(available, remaining)

		playerData.milk = available - toRemove
		remaining = remaining - toRemove

		print("🥛 Removed " .. toRemove .. "x milk from direct milk storage")
	end

	-- Check if we removed all requested items
	return remaining <= 0
end

function ShopSystem:GetItemSellPrice(itemId)
	-- Check if it's a crop first
	if self.ItemConfig and self.ItemConfig.Crops and self.ItemConfig.Crops[itemId] then
		return self.ItemConfig.Crops[itemId].sellValue or 0
	end

	-- Check mining ores
	if self.ItemConfig and self.ItemConfig.MiningSystem and self.ItemConfig.MiningSystem.ores and self.ItemConfig.MiningSystem.ores[itemId] then
		return self.ItemConfig.MiningSystem.ores[itemId].sellValue or 0
	end

	-- Other sellable items with fixed prices
	local sellPrices = {
		-- Animal products
		milk = 2,
		-- Materials
		wood = 10,
		stone = 5
	}

	return sellPrices[itemId] or 0
end

function ShopSystem:GetItemSellCurrency(itemId)
	-- Check if it's a crop first
	if self.ItemConfig and self.ItemConfig.Crops and self.ItemConfig.Crops[itemId] then
		return "coins" -- Most crops sell for coins
	end

	-- Check mining ores
	if self.ItemConfig and self.ItemConfig.MiningSystem and self.ItemConfig.MiningSystem.ores and self.ItemConfig.MiningSystem.ores[itemId] then
		local oreData = self.ItemConfig.MiningSystem.ores[itemId]
		return oreData.sellCurrency or "coins"
	end

	-- Default to coins for other items
	return "coins"
end

function ShopSystem:SendSaleConfirmation(player, itemId, quantity, totalValue, currency)
	local currencyName = currency == "farmTokens" and "Farm Tokens" or "Coins"
	local message = "Sold " .. quantity .. "x " .. itemId .. " for " .. totalValue .. " " .. currencyName .. "!"

	self:SendNotification(player, "Sale Successful", message, "success")
end
-- ========== UTILITY FUNCTIONS ==========

function ShopSystem:CompareItemsForSorting(a, b)
	-- First sort by category priority
	local categoryA = self.CategoryConfig[a.category]
	local categoryB = self.CategoryConfig[b.category]

	if categoryA and categoryB then
		if categoryA.priority ~= categoryB.priority then
			return categoryA.priority < categoryB.priority
		end
	elseif categoryA then
		return true
	elseif categoryB then
		return false
	end

	-- Within same category, sort by purchase order
	local orderA = a.purchaseOrder or 999
	local orderB = b.purchaseOrder or 999

	if orderA ~= orderB then
		return orderA < orderB
	end

	-- If same purchase order, sort by price
	return a.price < b.price
end

function ShopSystem:CreateEnhancedItemCopy(item, itemId, playerData)
	local itemCopy = {
		id = itemId,
		name = item.name,
		price = item.price,
		currency = item.currency,
		category = item.category,
		description = item.description or "No description available",
		icon = item.icon or "📦",
		maxQuantity = item.maxQuantity or 999,
		type = item.type or "item",
		purchaseOrder = item.purchaseOrder or 999
	}

	-- Copy all other properties
	for key, value in pairs(item) do
		if not itemCopy[key] then
			if type(value) == "table" then
				itemCopy[key] = self:DeepCopyTable(value)
			else
				itemCopy[key] = value
			end
		end
	end

	-- Add player-specific data
	if playerData then
		itemCopy.canAfford = self:CanPlayerAfford(playerData, item)
		itemCopy.meetsRequirements = true -- Fixed: Always show as meeting requirements for UI
		itemCopy.alreadyOwned = self:IsAlreadyOwned(playerData, itemId)
		itemCopy.playerStock = self:GetPlayerStock(playerData, itemId)

		-- Add category-specific data
		itemCopy.categoryInfo = self.CategoryConfig[item.category]

		-- Add requirement status for UI
		if item.requiresPurchase then
			local reqItem = self:GetShopItemById(item.requiresPurchase)
			itemCopy.requirementName = reqItem and reqItem.name or item.requiresPurchase
			itemCopy.requirementMet = playerData.purchaseHistory and playerData.purchaseHistory[item.requiresPurchase] or false
		end
	end

	return itemCopy
end

-- ========== VALIDATION ==========

function ShopSystem:ValidateShopData()
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		error("ShopSystem: ItemConfig.ShopItems not available!")
	end

	local validItems = 0
	local invalidItems = 0
	local categoryStats = {}

	print("ShopSystem: Validating shop data...")

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if self:ValidateItemFixed(item, itemId) then
			validItems = validItems + 1

			local category = item.category or "unknown"
			if not categoryStats[category] then
				categoryStats[category] = {count = 0, withOrder = 0}
			end
			categoryStats[category].count = categoryStats[category].count + 1

			if item.purchaseOrder then
				categoryStats[category].withOrder = categoryStats[category].withOrder + 1
			end
		else
			invalidItems = invalidItems + 1
			print("❌ Invalid item: " .. itemId)
		end
	end

	print("ShopSystem: FIXED validation complete!")
	print("  ✅ Valid items: " .. validItems)
	print("  ❌ Invalid items: " .. invalidItems)

	print("Category breakdown:")
	for category, stats in pairs(categoryStats) do
		local categoryInfo = self.CategoryConfig[category]
		local categoryDisplay = categoryInfo and (categoryInfo.emoji .. " " .. categoryInfo.name) or category
		print("  " .. categoryDisplay .. ": " .. stats.count .. " items (" .. stats.withOrder .. " with purchase order)")
	end

	return invalidItems == 0
end

-- ========== PURCHASE SYSTEM (Existing methods) ==========

function ShopSystem:HandlePurchase(player, itemId, quantity)
	print("🛒 ShopSystem: Purchase request - " .. player.Name .. " wants " .. quantity .. "x " .. itemId)

	-- Cooldown check
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

	-- Basic validation (much simpler now)
	if not self:CanPlayerAfford(playerData, item, quantity) then
		local currency = item.currency == "farmTokens" and "Farm Tokens" or "Coins"
		local needed = item.price * quantity
		local has = playerData[item.currency] or 0
		self:SendNotification(player, "Cannot Afford", "Not enough " .. currency .. "! Need " .. needed .. ", have " .. has, "error")
		return false
	end

	-- Process purchase
	local success, errorMsg = pcall(function()
		return self:ProcessPurchase(player, playerData, item, quantity)
	end)

	if success and errorMsg then
		self.PurchaseCooldowns[userId] = currentTime
		self:SendEnhancedPurchaseConfirmation(player, item, quantity)
		print("🛒 ShopSystem: Purchase successful - " .. player.Name .. " bought " .. quantity .. "x " .. itemId)
		return true
	else
		local error = success and "Unknown error" or tostring(errorMsg)
		self:SendNotification(player, "Purchase Failed", "Transaction failed: " .. error, "error")
		return false
	end
end

-- [Keep all existing purchase processing methods...]

function ShopSystem:ProcessPurchase(player, playerData, item, quantity)
	-- Calculate total cost
	local totalCost = item.price * quantity
	local currency = item.currency

	print("💰 Processing purchase:")
	print("  Player: " .. player.Name)
	print("  Item: " .. item.id .. " (" .. (item.type or "item") .. ")")
	print("  Category: " .. item.category)
	print("  Quantity: " .. quantity)
	print("  Total Cost: " .. totalCost .. " " .. currency)

	-- Deduct currency (skip for free items)
	if item.price > 0 then
		local oldAmount = playerData[currency] or 0
		playerData[currency] = oldAmount - totalCost
		print("💳 Deducted " .. totalCost .. " " .. currency)
	end

	-- Process by item type
	local processed = false

	if item.type == "seed" then
		processed = self:ProcessSeedPurchase(player, playerData, item, quantity)
	elseif item.type == "farmPlot" then
		processed = self:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	elseif item.type == "upgrade" then
		processed = self:ProcessUpgradePurchase(player, playerData, item, quantity)
	elseif item.type == "cow" or item.type == "cow_upgrade" then
		processed = self:ProcessCowPurchase(player, playerData, item, quantity)
	else
		processed = self:ProcessGenericPurchase(player, playerData, item, quantity)
	end

	if not processed then
		-- Refund on failure
		if item.price > 0 then
			playerData[currency] = (playerData[currency] or 0) + totalCost
		end
		error("Processing failed for: " .. item.id)
	end

	-- Mark as purchased
	if item.maxQuantity == 1 then
		playerData.purchaseHistory = playerData.purchaseHistory or {}
		playerData.purchaseHistory[item.id] = true
	end

	-- Save and update
	if self.GameCore then
		self.GameCore:SavePlayerData(player)
		if self.GameCore.RemoteEvents and self.GameCore.RemoteEvents.PlayerDataUpdated then
			self.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end
	end

	return true
end

-- [Include all your existing process methods: ProcessSeedPurchase, ProcessFarmPlotPurchase, etc.]

function ShopSystem:ProcessSeedPurchase(player, playerData, item, quantity)
	if not playerData.farming then
		playerData.farming = {plots = 0, inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	local currentAmount = playerData.farming.inventory[item.id] or 0
	playerData.farming.inventory[item.id] = currentAmount + quantity

	print("🌱 Added " .. quantity .. "x " .. item.id .. " to farming inventory")
	return true
end

function ShopSystem:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	print("🌾 Processing farm plot purchase")

	if item.id == "farm_plot_starter" then
		-- Initialize farming data
		if not playerData.farming then
			playerData.farming = {
				plots = 1,
				inventory = {
					carrot_seeds = 5,
					potato_seeds = 3
				}
			}
		end

		-- Create the physical farm plot
		local success = self.GameCore:CreateSimpleFarmPlot(player)
		if not success then
			return false
		end

		print("🌾 Created farm plot for " .. player.Name)
		return true
	end

	return true
end

function ShopSystem:ProcessGenericPurchase(player, playerData, item, quantity)
	if not playerData.inventory then
		playerData.inventory = {}
	end

	local currentAmount = playerData.inventory[item.id] or 0
	playerData.inventory[item.id] = currentAmount + quantity

	print("📦 Added " .. quantity .. "x " .. item.id .. " to inventory")
	return true
end

function ShopSystem:ProcessUpgradePurchase(player, playerData, item, quantity)
	if not playerData.upgrades then
		playerData.upgrades = {}
	end

	playerData.upgrades[item.id] = true
	print("⬆️ Applied upgrade: " .. item.id)
	return true
end

function ShopSystem:ProcessCowPurchase(player, playerData, item, quantity)
	print("🐄 Processing cow purchase")

	if not self.GameCore then
		return false
	end

	-- Initialize livestock data
	if not playerData.livestock then
		playerData.livestock = {cows = {}}
	end

	-- Try to purchase cow through GameCore
	local success, result = pcall(function()
		return self.GameCore:PurchaseCow(player, item.id, nil)
	end)

	return success and result
end

-- ========== UTILITY METHODS ==========

function ShopSystem:GetShopItemById(itemId)
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		return nil
	end
	return self.ItemConfig.ShopItems[itemId]
end

function ShopSystem:CanPlayerAfford(playerData, item, quantity)
	quantity = quantity or 1
	if not item.price or not item.currency then return false end
	if item.price == 0 then return true end

	local totalCost = item.price * quantity
	local playerCurrency = playerData[item.currency] or 0
	return playerCurrency >= totalCost
end

function ShopSystem:IsAlreadyOwned(playerData, itemId)
	return playerData.purchaseHistory and playerData.purchaseHistory[itemId] or false
end

function ShopSystem:GetPlayerStock(playerData, itemId)
	return self:GetPlayerStockComprehensive(playerData, itemId)
end

function ShopSystem:GetPlayerStockComprehensive(playerData, itemId)
	if not playerData then return 0 end

	local totalStock = 0

	-- Check different inventory locations
	local locations = {
		{"farming", "inventory"},
		{"livestock", "inventory"},
		{"inventory"}
	}

	for _, path in ipairs(locations) do
		local inventory = playerData
		for _, key in ipairs(path) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				inventory = nil
				break
			end
		end

		if inventory and inventory[itemId] then
			totalStock = totalStock + inventory[itemId]
		end
	end

	-- Special case for milk
	if itemId == "milk" and playerData.milk then
		totalStock = totalStock + playerData.milk
	end

	return totalStock
end

function ShopSystem:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function ShopSystem:SendEnhancedPurchaseConfirmation(player, item, quantity)
	print("🎉 ShopSystem: Sending purchase confirmation for " .. item.id)

	-- Calculate total cost
	local totalCost = item.price * quantity

	-- Send the ItemPurchased event (this is what GameClient listens for)
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased:FireClient(player, item.id, quantity, totalCost, item.currency)
		print("📡 ShopSystem: Sent ItemPurchased event to client")
	end

	-- Also send a notification
	local currencyName = item.currency == "farmTokens" and "Farm Tokens" or "Coins"
	local itemName = item.name or item.id

	self:SendNotification(player, "Purchase Successful!", 
		"Bought " .. quantity .. "x " .. itemName .. " for " .. totalCost .. " " .. currencyName, "success")
end

-- Also add this debug method to help troubleshoot:
function ShopSystem:DebugPurchaseFlow(player, itemId)
	print("=== PURCHASE FLOW DEBUG ===")
	print("Player: " .. player.Name)
	print("Item: " .. itemId)
	print("RemoteEvents.PurchaseItem exists: " .. tostring(self.RemoteEvents.PurchaseItem ~= nil))
	print("RemoteEvents.ItemPurchased exists: " .. tostring(self.RemoteEvents.ItemPurchased ~= nil))
	print("GameCore reference exists: " .. tostring(self.GameCore ~= nil))

	if self.GameCore then
		local playerData = self.GameCore:GetPlayerData(player)
		if playerData then
			print("Player coins: " .. (playerData.coins or 0))
			print("Player farmTokens: " .. (playerData.farmTokens or 0))
		end
	end
	print("===========================")
end

function ShopSystem:DeepCopyTable(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = self:DeepCopyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- ========== DEBUG COMMANDS ==========

function ShopSystem:DebugSeedVisibility(player)
	print("=== SEED VISIBILITY DEBUG ===")

	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		print("❌ ItemConfig.ShopItems not available!")
		return
	end

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	local seedsInConfig = {}
	local seedsShown = {}
	local seedsHidden = {}

	-- Find all seeds in ItemConfig
	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if item.type == "seed" or item.category == "seeds" or string.find(itemId, "seed") then
			table.insert(seedsInConfig, {
				id = itemId,
				name = item.name,
				price = item.price,
				category = item.category,
				type = item.type,
				valid = self:ValidateItemFixed(item, itemId),
				shown = self:ShouldShowItemFixed(item, itemId, playerData)
			})
		end
	end

	print("📊 SEED ANALYSIS:")
	print("  Total seeds found in ItemConfig: " .. #seedsInConfig)

	for _, seedData in ipairs(seedsInConfig) do
		local status = "✅"
		local reason = "OK"

		if not seedData.valid then
			status = "❌"
			reason = "INVALID"
			table.insert(seedsHidden, seedData)
		elseif not seedData.shown then
			status = "🔒"
			reason = "HIDDEN"
			table.insert(seedsHidden, seedData)
		else
			table.insert(seedsShown, seedData)
		end

		print("  " .. status .. " " .. seedData.id .. " (" .. seedData.name .. ") - " .. reason)
	end

	print("\n📈 SUMMARY:")
	print("  Seeds that WILL show: " .. #seedsShown)
	print("  Seeds that WON'T show: " .. #seedsHidden)

	if #seedsHidden > 0 then
		print("\n🔍 HIDDEN SEEDS ANALYSIS:")
		for _, seed in ipairs(seedsHidden) do
			print("  🔒 " .. seed.id .. ":")
			print("    Name: " .. (seed.name or "MISSING"))
			print("    Price: " .. (seed.price or "MISSING"))
			print("    Category: " .. (seed.category or "MISSING"))
			print("    Type: " .. (seed.type or "MISSING"))
			print("    Valid: " .. tostring(seed.valid))
			print("    Shown: " .. tostring(seed.shown))

			-- Check specific issues
			if not seed.name or seed.name == "" then
				print("    ❌ ISSUE: Missing or empty name")
			end
			if not seed.price or type(seed.price) ~= "number" then
				print("    ❌ ISSUE: Missing or invalid price")
			end
			if not seed.category then
				print("    ❌ ISSUE: Missing category")
			end
			if not seed.type then
				print("    ❌ ISSUE: Missing type")
			end
		end
	end

	return seedsShown, seedsHidden
end

-- ========== AUTOMATIC SEED FIXING ==========

--[[function ShopSystem:FixSeedVisibilityIssues()
	print("🔧 FIXING SEED VISIBILITY ISSUES...")

	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		print("❌ ItemConfig.ShopItems not available!")
		return false
	end

	local fixedCount = 0
	local seedsProcessed = 0

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if item.type == "seed" or item.category == "seeds" or string.find(itemId, "seed") then
			seedsProcessed = seedsProcessed + 1
			local wasFixed = false

			-- Fix missing name
			if not item.name or item.name == "" then
				item.name = "🌱 " .. itemId:gsub("_", " "):gsub("^%l", string.upper)
				print("  Fixed name for " .. itemId)
				wasFixed = true
			end

			-- Fix missing price
			if not item.price or type(item.price) ~= "number" then
				-- Default seed prices based on name complexity
				local defaultPrices = {
					carrot_seeds = 5,
					potato_seeds = 10,
					cabbage_seeds = 15,
					radish_seeds = 20,
					broccoli_seeds = 25,
					tomato_seeds = 30,									
					strawberry_seeds = 35,
					wheat_seeds = 40,
					corn_seeds = 50,
					golden_seeds = 250,
					glorious_sunflower_seeds = 999
				}
				item.price = defaultPrices[itemId] or 100
				print("  Fixed price for " .. itemId .. " to " .. item.price)
				wasFixed = true
			end
			-- Fix missing currency
			if not item.currency then
				if itemId == "golden_seeds" or itemId == "glorious_sunflower_seeds" then
					item.currency = "farmTokens"
				else
					item.currency = "coins"
				end
				print("  Fixed currency for " .. itemId)
				wasFixed = true
			end

			-- Fix missing category
			if not item.category then
				item.category = "seeds"
				print("  Fixed category for " .. itemId)
				wasFixed = true
			end

			-- Fix missing type
			if not item.type then
				item.type = "seed"
				print("  Fixed type for " .. itemId)
				wasFixed = true
			end

			-- Fix missing description
			if not item.description then
				item.description = "Plant these seeds to grow crops on your farm!"
				print("  Fixed description for " .. itemId)
				wasFixed = true
			end

			-- Fix missing icon
			if not item.icon then
				item.icon = "🌱"
				print("  Fixed icon for " .. itemId)
				wasFixed = true
			end

			-- Fix missing maxQuantity
			if not item.maxQuantity then
				item.maxQuantity = 100
				wasFixed = true
			end

			-- Remove any blocking flags
			if item.notPurchasable then
				item.notPurchasable = nil
				print("  Removed notPurchasable flag from " .. itemId)
				wasFixed = true
			end

			if item.requiresPurchase and itemId ~= "glorious_sunflower_seeds" then
				-- Only keep requirements for premium seeds
				item.requiresPurchase = nil
				print("  Removed requiresPurchase from " .. itemId)
				wasFixed = true
			end

			if wasFixed then
				fixedCount = fixedCount + 1
			end
		end
	end

	print("🔧 SEED FIXING COMPLETE:")
	print("  Seeds processed: " .. seedsProcessed)
	print("  Seeds fixed: " .. fixedCount)

	return fixedCount > 0
end
]]
-- ========== ENHANCED SEED VALIDATION ==========

function ShopSystem:ValidateSeedSpecifically(item, itemId)
	local issues = {}

	-- Check required properties for seeds
	if not item.name or item.name == "" then
		table.insert(issues, "Missing name")
	end

	if not item.price or type(item.price) ~= "number" or item.price < 0 then
		table.insert(issues, "Invalid price: " .. tostring(item.price))
	end

	if not item.currency then
		table.insert(issues, "Missing currency")
	elseif item.currency ~= "coins" and item.currency ~= "farmTokens" then
		table.insert(issues, "Invalid currency: " .. item.currency)
	end

	if not item.category then
		table.insert(issues, "Missing category")
	elseif item.category ~= "seeds" then
		table.insert(issues, "Wrong category: " .. item.category .. " (should be 'seeds')")
	end

	if not item.type then
		table.insert(issues, "Missing type")
	elseif item.type ~= "seed" then
		table.insert(issues, "Wrong type: " .. item.type .. " (should be 'seed')")
	end

	-- Check farming data
	if not item.farmingData then
		table.insert(issues, "Missing farmingData")
	else
		if not item.farmingData.growTime then
			table.insert(issues, "Missing farmingData.growTime")
		end
		if not item.farmingData.resultCropId then
			table.insert(issues, "Missing farmingData.resultCropId")
		end
	end

	return #issues == 0, issues
end

-- ========== DEBUG COMMANDS ==========

function ShopSystem:SetupSeedDebugCommands()
	game:GetService("Players").PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/debugseeds" then
					self:DebugSeedVisibility(player)

				elseif command == "/fixseeds" then
					local fixed = self:FixSeedVisibilityIssues()
					if fixed then
						print("✅ Seeds fixed! Try /debugseeds to see results.")
					else
						print("ℹ️ No seed fixes needed.")
					end

				elseif command == "/testseeds" then
					local seedItems = self:HandleGetShopItemsByCategory(player, "seeds")
					print("=== SEED CATEGORY TEST ===")
					print("Seeds returned: " .. #seedItems)
					for i, seed in ipairs(seedItems) do
						print("  " .. i .. ". " .. seed.name .. " - " .. seed.price .. " " .. seed.currency)
					end
					print("========================")

				elseif command == "/forceseeds" then
					print("Forcing all seeds to show...")
					-- Temporarily make all seeds visible
					for itemId, item in pairs(self.ItemConfig.ShopItems) do
						if item.type == "seed" or string.find(itemId, "seed") then
							item.notPurchasable = nil
							item.requiresPurchase = nil
							if not item.category then item.category = "seeds" end
							if not item.type then item.type = "seed" end
							if not item.name then item.name = "🌱 " .. itemId end
							if not item.price then item.price = 100 end
							if not item.currency then item.currency = "coins" end
						end
					end
					print("✅ All seeds should now be visible!")
				end
			end
		end)
	end)
end


game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/debugshop" then
				print("=== SHOP DEBUG ===")
				print("Total items in ItemConfig: " .. ShopSystem:CountShopItems())

				local testItems = ShopSystem:HandleGetShopItems(player)
				print("Items returned to client: " .. #testItems)

				for i, item in ipairs(testItems) do
					if i <= 10 then -- Show first 10
						print("  " .. i .. ". " .. item.name .. " (" .. item.category .. ") - " .. item.price .. " " .. item.currency)
					end
				end

				if #testItems > 10 then
					print("  ... and " .. (#testItems - 10) .. " more items")
				end
				print("==================")

			elseif command == "/debugcategory" then
				local category = args[2] or "seeds"
				local items = ShopSystem:HandleGetShopItemsByCategory(player, category)
				print("=== " .. category:upper() .. " CATEGORY DEBUG ===")
				print("Items in " .. category .. ": " .. #items)
				for i, item in ipairs(items) do
					print("  " .. i .. ". " .. item.name .. " - " .. item.price .. " " .. item.currency)
				end
				print("=================================")

			elseif command == "/forceshow" then
				-- Force show all items by temporarily disabling requirements
				print("Forcing all items to show...")
				local originalShouldShow = ShopSystem.ShouldShowItemFixed
				ShopSystem.ShouldShowItemFixed = function(self, item, itemId, playerData)
					return true
				end

				local items = ShopSystem:HandleGetShopItems(player)
				print("With all restrictions removed: " .. #items .. " items")

				-- Restore original function
				ShopSystem.ShouldShowItemFixed = originalShouldShow
			end
		end
	end)
end)
game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "YourUsernameHere" then -- Replace with your actual username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/testpurchase" then
				local itemId = args[2] or "carrot_seeds"
				print("🧪 Testing purchase flow for " .. itemId)
				ShopSystem:DebugPurchaseFlow(player, itemId)

			elseif command == "/checkremotes" then
				print("=== REMOTE EVENTS CHECK ===")
				local gameRemotes = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
				if gameRemotes then
					local purchaseEvent = gameRemotes:FindFirstChild("PurchaseItem")
					if purchaseEvent then
						print("✅ PurchaseItem remote exists")
						print("Connections: " .. #purchaseEvent.Event:GetConnections())
					else
						print("❌ PurchaseItem remote missing")
					end
				else
					print("❌ GameRemotes folder missing")
				end
				print("===========================")

			elseif command == "/givecoins" then
				local amount = tonumber(args[2]) or 1000
				if ShopSystem.GameCore then
					local playerData = ShopSystem.GameCore:GetPlayerData(player)
					if playerData then
						playerData.coins = (playerData.coins or 0) + amount
						ShopSystem.GameCore:SavePlayerData(player)
						if ShopSystem.GameCore.RemoteEvents and ShopSystem.GameCore.RemoteEvents.PlayerDataUpdated then
							ShopSystem.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
						end
						print("💰 Gave " .. amount .. " coins to " .. player.Name)
					end
				end
			end
		end
	end)
end)
print("ShopSystem: ✅ FIXED - Items should now show in shop!")
print("🔧 FIXES APPLIED:")
print("  ✅ Made validation more permissive")
print("  ✅ Always show starter items")
print("  ✅ Removed blocking category requirements")
print("  ✅ Added comprehensive debugging")
print("  ✅ Fixed item visibility logic")
print("")
print("🧪 DEBUG COMMANDS:")
print("  /debugshop - Show shop item debug info")
print("  /debugcategory [category] - Debug specific category")
print("  /forceshow - Test with all restrictions removed")

return ShopSystem