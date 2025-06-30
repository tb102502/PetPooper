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
	defense = {
		name = "Defense",
		emoji = "🛡️",
		description = "Protect your farm from pests and UFO attacks",
		priority = 3
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
		"basic_cow",
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
			{id = "carrot", name = "🥕 Carrots", sellPrice = 8},
			{id = "corn", name = "🌽 Corn", sellPrice = 725},
			{id = "strawberry", name = "🍓 Strawberries", sellPrice = 350},
			{id = "wheat", name = "🌾 Wheat", sellPrice = 600},
			{id = "potato", name = "🥔 Potatoes", sellPrice = 40},
			{id = "tomato", name = "🍅 Tomatoes", sellPrice = 675},
			{id = "cabbage", name = "🥬 Cabbage", sellPrice = 75},
			{id = "radish", name = "🌶️ Radishes", sellPrice = 140},
			{id = "broccoli", name = "🥦 Broccoli", sellPrice = 110},

			-- Animal Products
			{id = "milk", name = "🥛 Fresh Milk", sellPrice = 75},
			{id = "fresh_milk", name = "🥛 Fresh Milk", sellPrice = 75},
			{id = "chicken_egg", name = "🥚 Chicken Eggs", sellPrice = 15},
			{id = "guinea_egg", name = "🥚 Guinea Fowl Eggs", sellPrice = 20},
			{id = "rooster_egg", name = "🥚 Rooster Eggs", sellPrice = 25},

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
					corn_seeds = 3
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
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased:FireClient(player, item.id, quantity, item.price * quantity, item.currency)
	end
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