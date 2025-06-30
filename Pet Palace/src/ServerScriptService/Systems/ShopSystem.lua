--[[
    UPDATED ShopSystem.lua - Tabbed Categories Support
    Place in: ServerScriptService/Systems/ShopSystem.lua
    
    NEW FEATURES:
    ✅ Enhanced category-based item filtering
    ✅ Tab-specific remote functions
    ✅ Better category validation and sorting
    ✅ Enhanced purchase notifications by category
    ✅ Category-aware inventory management
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

-- NEW: Category configuration for tabbed system
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

-- ========== 2. ADD SELL TAB HANDLER TO ShopSystem.lua ==========
-- Add this new method to ShopSystem.lua:

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
			{id = "carrot", name = "🥕 Carrots", locations = {{"farming", "inventory"}}, sellPrice = 8},
			{id = "corn", name = "🌽 Corn", locations = {{"farming", "inventory"}}, sellPrice = 725},
			{id = "strawberry", name = "🍓 Strawberries", locations = {{"farming", "inventory"}}, sellPrice = 350},
			{id = "wheat", name = "🌾 Wheat", locations = {{"farming", "inventory"}}, sellPrice = 600},
			{id = "potato", name = "🥔 Potatoes", locations = {{"farming", "inventory"}}, sellPrice = 40},
			{id = "tomato", name = "🍅 Tomatoes", locations = {{"farming", "inventory"}}, sellPrice = 675},
			{id = "cabbage", name = "🥬 Cabbage", locations = {{"farming", "inventory"}}, sellPrice = 75},
			{id = "radish", name = "🌶️ Radishes", locations = {{"farming", "inventory"}}, sellPrice = 140},
			{id = "broccoli", name = "🥦 Broccoli", locations = {{"farming", "inventory"}}, sellPrice = 110},

			-- Animal Products
			{id = "milk", name = "🥛 Fresh Milk", locations = {{"livestock", "inventory"}, {"farming", "inventory"}, {}}, sellPrice = 75},
			{id = "chicken_egg", name = "🥚 Chicken Eggs", locations = {{"defense", "eggs"}, {"inventory"}}, sellPrice = 15},
			{id = "guinea_egg", name = "🥚 Guinea Fowl Eggs", locations = {{"defense", "eggs"}, {"inventory"}}, sellPrice = 20},
			{id = "rooster_egg", name = "🥚 Rooster Eggs", locations = {{"defense", "eggs"}, {"inventory"}}, sellPrice = 25},

			-- Ores (if mining is implemented)
			{id = "copper_ore", name = "🟫 Copper Ore", locations = {{"mining", "inventory"}, {"inventory"}}, sellPrice = 30},
			{id = "bronze_ore", name = "🟤 Bronze Ore", locations = {{"mining", "inventory"}, {"inventory"}}, sellPrice = 45},
			{id = "silver_ore", name = "⚪ Silver Ore", locations = {{"mining", "inventory"}, {"inventory"}}, sellPrice = 80},
			{id = "gold_ore", name = "🟡 Gold Ore", locations = {{"mining", "inventory"}, {"inventory"}}, sellPrice = 150},
			{id = "platinum_ore", name = "⚫ Platinum Ore", locations = {{"mining", "inventory"}, {"inventory"}}, sellPrice = 300}
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

-- ========== INITIALIZATION ==========

function ShopSystem:Initialize(gameCore)
	print("ShopSystem: Initializing ENHANCED tabbed shop system...")

	self.GameCore = gameCore

	-- Load ItemConfig
	local success, itemConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
	end)

	if success and itemConfig then
		self.ItemConfig = itemConfig
		print("ShopSystem: ✅ ItemConfig loaded successfully")
	else
		error("ShopSystem: Failed to load ItemConfig: " .. tostring(itemConfig))
	end

	-- Setup remote connections
	self:SetupRemoteConnections()
	self:SetupRemoteHandlers()
	self:ValidateShopData()
	self:ValidateCategoryData()

	print("ShopSystem: ✅ ENHANCED tabbed shop system initialization complete")
	return true
end

-- ========== REMOTE SETUP ==========

function ShopSystem:SetupRemoteConnections()
	print("ShopSystem: Setting up enhanced remote connections...")

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
		{name = "GetSellableItems", type = "RemoteFunction"}, -- ADD THIS LINE
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

	print("ShopSystem: Enhanced remote connections established")
end

function ShopSystem:SetupRemoteHandlers()
	print("ShopSystem: Setting up enhanced remote handlers...")

	if self.RemoteFunctions.GetShopItems then
		self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
			return self:HandleGetShopItems(player)
		end
	end

	-- NEW: Category-specific shop items handler
	if self.RemoteFunctions.GetShopItemsByCategory then
		self.RemoteFunctions.GetShopItemsByCategory.OnServerInvoke = function(player, category)
			return self:HandleGetShopItemsByCategory(player, category)
		end
	end

	-- NEW: Category information handler
	if self.RemoteFunctions.GetShopCategories then
		self.RemoteFunctions.GetShopCategories.OnServerInvoke = function(player)
			return self:HandleGetShopCategories(player)
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
	
	if self.RemoteFunctions.GetSellableItems then
		self.RemoteFunctions.GetSellableItems.OnServerInvoke = function(player)
			return self:HandleGetSellableItems(player)
		end
	end
	print("ShopSystem: All enhanced remote handlers connected")
end

-- ========== ENHANCED SHOP ITEMS HANDLERS ==========

function ShopSystem:HandleGetShopItems(player)
	print("🛒 ShopSystem: GetShopItems request from " .. player.Name)

	local success, result = pcall(function()
		if not self.ItemConfig or not self.ItemConfig.ShopItems then
			error("ItemConfig.ShopItems not available")
		end

		local shopItemsArray = {}
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		-- Convert ShopItems to array with enhanced data
		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			if self:ValidateItem(item, itemId) and self:ShouldShowItem(item, itemId, playerData) then
				local itemCopy = self:CreateEnhancedItemCopy(item, itemId, playerData)
				table.insert(shopItemsArray, itemCopy)
			end
		end

		-- ENHANCED: Sort by category priority, then purchase order, then price
		table.sort(shopItemsArray, function(a, b)
			return self:CompareItemsForSorting(a, b)
		end)

		print("🛒 ShopSystem: Returning " .. #shopItemsArray .. " items (sorted by category and purchase order)")
		self:LogItemOrdering(shopItemsArray)

		return shopItemsArray
	end)

	if success then
		return result
	else
		warn("🛒 ShopSystem: GetShopItems failed: " .. tostring(result))
		return {}
	end
end

-- NEW: Category-specific items handler
function ShopSystem:HandleGetShopItemsByCategory(player, category)
	print("🛒 ShopSystem: GetShopItemsByCategory request from " .. player.Name .. " for category: " .. tostring(category))

	if not category or not self.CategoryConfig[category] then
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
			if item.category == category and self:ValidateItem(item, itemId) and self:ShouldShowItem(item, itemId, playerData) then
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

-- NEW: Category information handler
function ShopSystem:HandleGetShopCategories(player)
	print("🛒 ShopSystem: GetShopCategories request from " .. player.Name)

	local categories = {}

	for categoryId, config in pairs(self.CategoryConfig) do
		-- Count items in this category
		local itemCount = 0
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		for itemId, item in pairs(self.ItemConfig.ShopItems or {}) do
			if item.category == categoryId and self:ValidateItem(item, itemId) and self:ShouldShowItem(item, itemId, playerData) then
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

function ShopSystem:ShouldShowItem(item, itemId, playerData)
	-- Don't show items marked as not purchasable
	if item.notPurchasable then
		return false
	end

	-- Check if item has purchase requirements
	if item.requiresPurchase and playerData then
		local hasPurchased = playerData.purchaseHistory and playerData.purchaseHistory[item.requiresPurchase]
		if not hasPurchased then
			print("🔒 Item " .. itemId .. " requires " .. item.requiresPurchase .. " (not purchased)")
			return false
		end
	end

	-- Check max quantity limits for single-purchase items
	if item.maxQuantity == 1 and playerData then
		local alreadyOwned = playerData.purchaseHistory and playerData.purchaseHistory[itemId]
		if alreadyOwned then
			print("🔒 Item " .. itemId .. " already purchased (max quantity 1)")
			return false
		end
	end

	-- NEW: Check category-specific requirements
	if not self:MeetsCategoryRequirements(item, itemId, playerData) then
		return false
	end

	return true
end

function ShopSystem:MeetsCategoryRequirements(item, itemId, playerData)
	local category = item.category

	-- Category-specific logic
	if category == "mining" then
		-- Mining items might require cave access
		if itemId:find("pickaxe") and itemId ~= "cave_access_pass" then
			if not (playerData and playerData.access and playerData.access.cave_access_pass) then
				return false
			end
		end
	elseif category == "crafting" then
		-- Advanced crafting items might require basic workbench
		if itemId ~= "basic_workbench" then
			if not (playerData and playerData.buildings and playerData.buildings.basic_workbench) then
				return false
			end
		end
	elseif category == "defense" then
		-- Advanced defense items might require farm plot
		if itemId:find("chicken") or itemId:find("pesticide") then
			if not (playerData and playerData.farming and playerData.farming.plots and playerData.farming.plots > 0) then
				return false
			end
		end
	end

	return true
end

function ShopSystem:LogItemOrdering(shopItemsArray)
	print("📋 Enhanced Shop Items Order:")
	local currentCategory = ""
	local categoryCount = 0

	for i, item in ipairs(shopItemsArray) do
		if item.category ~= currentCategory then
			if currentCategory ~= "" then
				print("  └─ " .. categoryCount .. " items in " .. currentCategory)
			end
			currentCategory = item.category
			categoryCount = 0
			local categoryInfo = self.CategoryConfig[currentCategory]
			local categoryDisplay = categoryInfo and (categoryInfo.emoji .. " " .. categoryInfo.name) or currentCategory
			print("📁 " .. categoryDisplay:upper() .. " Category:")
		end

		categoryCount = categoryCount + 1
		local orderInfo = item.purchaseOrder and (" [Order: " .. item.purchaseOrder .. "]") or ""
		print("  " .. categoryCount .. ". " .. item.name .. " - " .. item.price .. " " .. item.currency .. orderInfo)
	end

	if currentCategory ~= "" then
		print("  └─ " .. categoryCount .. " items in " .. currentCategory)
	end
end

function ShopSystem:ValidateItem(item, itemId)
	if not item then return false end

	local required = {"name", "price", "currency", "category", "description", "icon"}
	for _, prop in ipairs(required) do
		if not item[prop] then
			return false
		end
	end

	if type(item.price) ~= "number" or item.price < 0 then
		return false
	end

	local validCurrencies = {"coins", "farmTokens", "Robux"}
	local isValidCurrency = false
	for _, validCurrency in ipairs(validCurrencies) do
		if item.currency == validCurrency then
			isValidCurrency = true
			break
		end
	end

	-- NEW: Validate category
	if not self.CategoryConfig[item.category] then
		warn("🛒 ShopSystem: Invalid category for item " .. itemId .. ": " .. tostring(item.category))
		return false
	end

	return isValidCurrency
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
		itemCopy.meetsRequirements = self:MeetsRequirements(playerData, item)
		itemCopy.alreadyOwned = self:IsAlreadyOwned(playerData, itemId)
		itemCopy.playerStock = self:GetPlayerStock(playerData, itemId)

		-- ENHANCED: Add category-specific data
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

-- ========== ENHANCED PURCHASE SYSTEM ==========

function ShopSystem:HandlePurchase(player, itemId, quantity)
	print("🛒 ShopSystem: Enhanced purchase request - " .. player.Name .. " wants " .. quantity .. "x " .. itemId)

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

	-- Enhanced purchase validation
	local canPurchase, reason = self:ValidateEnhancedPurchase(player, playerData, item, quantity)
	if not canPurchase then
		self:SendNotification(player, "Cannot Purchase", reason, "error")
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

function ShopSystem:ValidateEnhancedPurchase(player, playerData, item, quantity)
	-- Check if player can afford it
	if item.price > 0 and not self:CanPlayerAfford(playerData, item, quantity) then
		local currency = item.currency == "farmTokens" and "Farm Tokens" or "Coins"
		local needed = item.price * quantity
		local has = playerData[item.currency] or 0
		return false, "Not enough " .. currency .. "! Need " .. needed .. ", have " .. has
	end

	-- Enhanced requirements checking (REMOVED expansion-specific logic)
	if not self:MeetsEnhancedRequirements(playerData, item) then
		if item.requiresPurchase then
			local reqItem = self:GetShopItemById(item.requiresPurchase)
			local reqName = reqItem and reqItem.name or item.requiresPurchase
			return false, "🔒 Must purchase " .. reqName .. " first!"
		end

		if item.requiresFarmPlot then
			return false, "🔒 Requires a farm plot!"
		end

		-- Category-specific requirement messages
		local categoryRequirement = self:GetCategoryRequirementMessage(item, playerData)
		if categoryRequirement then
			return false, categoryRequirement
		end

		return false, "🔒 Requirements not met!"
	end

	-- Check quantity limits
	if item.maxQuantity and item.maxQuantity == 1 then
		if self:IsAlreadyOwned(playerData, item.id) then
			return false, "Already purchased this item!"
		end
	end

	-- Check if trying to buy more than max quantity
	if item.maxQuantity and quantity > item.maxQuantity then
		return false, "Cannot buy more than " .. item.maxQuantity .. " of this item!"
	end

	return true, "Can purchase"
end

-- REMOVE expansion-specific category requirements
function ShopSystem:GetCategoryRequirementMessage(item, playerData)
	local category = item.category

	if category == "mining" then
		if item.id:find("pickaxe") and item.id ~= "cave_access_pass" then
			if not (playerData and playerData.access and playerData.access.cave_access_pass) then
				return "🔒 Requires Cave Access Pass!"
			end
		end
	elseif category == "crafting" then
		if item.id ~= "basic_workbench" then
			if not (playerData and playerData.buildings and playerData.buildings.basic_workbench) then
				return "🔒 Requires Basic Workbench!"
			end
		end
	elseif category == "defense" then
		if item.id:find("chicken") or item.id:find("pesticide") then
			if not (playerData and playerData.farming and playerData.farming.plots and playerData.farming.plots > 0) then
				return "🔒 Requires a farm plot!"
			end
		end
	end

	return nil
end

function ShopSystem:MeetsEnhancedRequirements(playerData, item)
	-- Check purchase prerequisites
	if item.requiresPurchase then
		if not playerData.purchaseHistory or not playerData.purchaseHistory[item.requiresPurchase] then
			print("🔒 Purchase requirement not met: " .. item.requiresPurchase)
			return false
		end
	end

	-- Check farm plot requirement
	if item.requiresFarmPlot then
		if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
			print("🔒 Farm plot requirement not met")
			return false
		end
	end

	-- Check level requirements (if implemented)
	if item.requiredLevel then
		local playerLevel = playerData.level or 1
		if playerLevel < item.requiredLevel then
			print("🔒 Level requirement not met: need " .. item.requiredLevel .. ", have " .. playerLevel)
			return false
		end
	end

	-- NEW: Check category-specific requirements
	if not self:MeetsCategoryRequirements(item, item.id, playerData) then
		return false
	end

	return true
end

function ShopSystem:ProcessPurchase(player, playerData, item, quantity)
	-- Calculate total cost
	local totalCost = item.price * quantity
	local currency = item.currency

	print("💰 Processing simplified purchase:")
	print("  Player: " .. player.Name)
	print("  Item: " .. item.id .. " (" .. item.type .. ")")
	print("  Category: " .. item.category)
	print("  Quantity: " .. quantity)
	print("  Total Cost: " .. totalCost .. " " .. currency)

	-- Deduct currency (skip for free items)
	if item.price > 0 then
		local oldAmount = playerData[currency] or 0
		playerData[currency] = oldAmount - totalCost
		print("💳 Deducted " .. totalCost .. " " .. currency .. " (had " .. oldAmount .. ", now " .. playerData[currency] .. ")")
	else
		print("🆓 Free item, no currency deducted")
	end

	-- Process by item type with simplified error handling
	local processed = false
	local errorMsg = ""

	if item.type == "seed" then
		processed = self:ProcessSeedPurchase(player, playerData, item, quantity)
		errorMsg = "Seed processing failed"
	elseif item.type == "farmPlot" then
		processed = self:ProcessFarmPlotPurchase(player, playerData, item, quantity)
		errorMsg = "Farm plot processing failed"
	elseif item.type == "upgrade" then
		processed = self:ProcessUpgradePurchase(player, playerData, item, quantity)
		errorMsg = "Upgrade processing failed"
	elseif item.type == "cow" or item.type == "cow_upgrade" then
		processed = self:ProcessCowPurchase(player, playerData, item, quantity)
		errorMsg = "Cow processing failed"
	elseif item.type == "chicken" then
		processed = self:ProcessChickenPurchase(player, playerData, item, quantity)
		errorMsg = "Chicken processing failed"
	elseif item.type == "feed" then
		processed = self:ProcessFeedPurchase(player, playerData, item, quantity)
		errorMsg = "Feed processing failed"
	elseif item.type == "tool" then
		processed = self:ProcessToolPurchase(player, playerData, item, quantity)
		errorMsg = "Tool processing failed"
	elseif item.type == "building" then
		processed = self:ProcessBuildingPurchase(player, playerData, item, quantity)
		errorMsg = "Building processing failed"
	elseif item.type == "access" then
		processed = self:ProcessAccessPurchase(player, playerData, item, quantity)
		errorMsg = "Access processing failed"
	else
		processed = self:ProcessGenericPurchase(player, playerData, item, quantity)
		errorMsg = "Generic item processing failed"
	end

	if not processed then
		-- Refund on failure
		if item.price > 0 then
			playerData[currency] = (playerData[currency] or 0) + totalCost
			print("💸 Refunded " .. totalCost .. " " .. currency .. " due to processing failure")
		end
		error(errorMsg .. " for type: " .. (item.type or "unknown") .. " (item: " .. item.id .. ")")
	end

	print("✅ Simplified purchase processing successful!")

	-- Mark as purchased
	if item.maxQuantity == 1 then
		playerData.purchaseHistory = playerData.purchaseHistory or {}
		playerData.purchaseHistory[item.id] = true
		print("📝 Marked " .. item.id .. " as purchased in history")
	end

	-- Update purchase statistics
	playerData.stats = playerData.stats or {}
	playerData.stats.totalPurchases = (playerData.stats.totalPurchases or 0) + quantity
	playerData.stats.totalSpent = (playerData.stats.totalSpent or 0) + totalCost

	-- Category-specific statistics
	local categoryKey = "spent_" .. item.category
	playerData.stats[categoryKey] = (playerData.stats[categoryKey] or 0) + totalCost

	-- Save and update
	if self.GameCore then
		self.GameCore:SavePlayerData(player)
		self.GameCore:UpdatePlayerLeaderstats(player)

		if self.GameCore.RemoteEvents and self.GameCore.RemoteEvents.PlayerDataUpdated then
			self.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end
	end

	return true
end


-- ========== ITEM TYPE PROCESSORS ==========

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

-- FIXED ProcessFarmPlotPurchase method - replace in ShopSystem.lua
function ShopSystem:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	print("🌾 ShopSystem: SIMPLIFIED ProcessFarmPlotPurchase - " .. player.Name .. " buying " .. item.id)

	-- Handle farm plot starter (creates full 10x10 farm immediately)
	if item.id == "farm_plot_starter" then
		print("🌾 ShopSystem: Processing farm plot starter (10x10 grid)")

		-- Check if player already has a farm
		if playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter then
			return false, "You already have a farm plot!"
		end

		-- Initialize farming data with full access
		if not playerData.farming then
			playerData.farming = {
				plots = 1,
				
				
			}
		end

		-- Create the physical simple farm plot (10x10, all unlocked)
		local success = self.GameCore:CreateSimpleFarmPlot(player)
		if not success then
			warn("🌾 ShopSystem: Failed to create simple farm for " .. player.Name)
			return false, "Failed to create farm plot"
		end

		print("🌾 ShopSystem: Created 10x10 farm plot for " .. player.Name .. " (100 spots, all unlocked)")
		return true, "Farm plot created successfully with full 10x10 grid!"
	end

	-- Legacy farm plot purchase (convert to simple system)
	print("🌾 ShopSystem: Processing legacy farm plot purchase")

	if not playerData.farming then
		playerData.farming = {plots = 0, inventory = {}}
	end

	playerData.farming.plots = (playerData.farming.plots or 0) + quantity

	-- Ensure they have a simple farm
	local success = self.GameCore:EnsurePlayerHasSimpleFarm(player)
	if not success then
		-- Create one if they don't have it
		success = self.GameCore:CreateSimpleFarmPlot(player)
		if not success then
			playerData.farming.plots = playerData.farming.plots - quantity
			return false, "Failed to create farm plot"
		end
	end

	print("🌾 ShopSystem: Added " .. quantity .. " farm plot(s), total: " .. playerData.farming.plots)
	return true, "Farm plot added successfully!"
end

function ShopSystem:ProcessCowPurchase(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing enhanced cow purchase for " .. player.Name)
	print("  Item: " .. item.id .. " (Order: " .. (item.purchaseOrder or "none") .. ")")
	print("  Category: " .. item.category)
	print("  Quantity: " .. quantity)
	print("  Price: " .. item.price .. " " .. item.currency)

	if not self.GameCore then
		print("❌ GameCore not available!")
		return false
	end

	-- Initialize livestock data
	if not playerData.livestock then
		playerData.livestock = {cows = {}}
		print("✅ Initialized livestock data")
	end
	if not playerData.livestock.cows then
		playerData.livestock.cows = {}
		print("✅ Initialized cows data")
	end

	-- Verify item has cow data
	if not item.cowData then
		print("❌ Item missing cowData:", item.id)
		self:SendNotification(player, "Invalid Cow", "Cow data not found for " .. item.id, "error")
		return false
	end
	print("✅ Cow data found:", item.cowData.tier)

	-- Verify GameCore has cow configuration
	local cowConfig = self.GameCore:GetCowConfiguration(item.id)
	if not cowConfig then
		print("❌ GameCore:GetCowConfiguration failed for " .. item.id)
		self:SendNotification(player, "Configuration Error", "Cow configuration not found!", "error")
		return false
	end
	print("✅ Cow configuration found:", cowConfig.tier)

	-- Auto-create farm plot if needed
	if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
		print("⚠️ Player has no farm plot, creating one...")

		playerData.farming = playerData.farming or {}
		playerData.farming.plots = 1
		playerData.farming.inventory = playerData.farming.inventory or {}

		local plotSuccess = self.GameCore:CreatePlayerFarmPlot(player, 1)
		if not plotSuccess then
			print("❌ Failed to create farm plot")
			self:SendNotification(player, "Farm Plot Error", "Could not create farm plot!", "error")
			return false
		end
		print("✅ Auto-created farm plot")
	end

	-- Check cow limits
	local currentCowCount = 0
	for _ in pairs(playerData.livestock.cows) do
		currentCowCount = currentCowCount + 1
	end

	local maxCows = cowConfig.maxCows or 1
	print("📊 Current cows: " .. currentCowCount .. "/" .. maxCows)

	if currentCowCount >= maxCows then
		print("❌ Cow limit reached")
		self:SendNotification(player, "Cow Limit", "You already have the maximum number of cows!", "error")
		return false
	end

	-- Purchase cows
	local successCount = 0

	for i = 1, quantity do
		print("🐄 Attempting to purchase cow " .. i .. "/" .. quantity)

		local success, result = pcall(function()
			return self.GameCore:PurchaseCow(player, item.id, nil)
		end)

		if success then
			if result then
				successCount = successCount + 1
				print("✅ Cow " .. i .. " purchased successfully")
			else
				print("❌ Cow " .. i .. " purchase returned false")
				break
			end
		else
			print("❌ Cow " .. i .. " purchase error: " .. tostring(result))
			break
		end
	end

	print("🐄 Purchase complete: " .. successCount .. "/" .. quantity .. " cows purchased")
	return successCount > 0
end

function ShopSystem:ProcessChickenPurchase(player, playerData, item, quantity)
	if not playerData.defense then
		playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}, pestControl = {}, roofs = {}}
	end
	if not playerData.defense.chickens then
		playerData.defense.chickens = {owned = {}, deployed = {}, feed = {}}
	end
	if not playerData.defense.chickens.owned then
		playerData.defense.chickens.owned = {}
	end

	for i = 1, quantity do
		local chickenId = HttpService:GenerateGUID(false)
		playerData.defense.chickens.owned[chickenId] = {
			type = item.id,
			purchaseTime = os.time(),
			status = "available",
			chickenId = chickenId,
			health = 100,
			hunger = 50
		}
		print("🐔 Created chicken: " .. chickenId)
	end

	return true
end

function ShopSystem:ProcessFeedPurchase(player, playerData, item, quantity)
	if not playerData.defense then
		playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}, pestControl = {}, roofs = {}}
	end
	if not playerData.defense.chickens then
		playerData.defense.chickens = {owned = {}, deployed = {}, feed = {}}
	end
	if not playerData.defense.chickens.feed then
		playerData.defense.chickens.feed = {}
	end

	local currentAmount = playerData.defense.chickens.feed[item.id] or 0
	playerData.defense.chickens.feed[item.id] = currentAmount + quantity

	print("🌾 Added " .. quantity .. "x " .. item.id .. " to feed inventory")
	return true
end

function ShopSystem:ProcessToolPurchase(player, playerData, item, quantity)
	if item.id:find("pesticide") or item.id:find("pest_") then
		if not playerData.defense then
			playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}, pestControl = {}, roofs = {}}
		end
		if not playerData.defense.pestControl then
			playerData.defense.pestControl = {}
		end

		if item.id == "pest_detector" then
			playerData.defense.pestControl.pest_detector = true
			print("🔍 Activated pest detector")
		else
			local currentAmount = playerData.defense.pestControl[item.id] or 0
			playerData.defense.pestControl[item.id] = currentAmount + quantity
			print("🧪 Added " .. quantity .. "x " .. item.id .. " to pest control")
		end
	elseif item.id:find("pickaxe") then
		if not playerData.mining then
			playerData.mining = {tools = {}, level = 1, xp = 0}
		end
		if not playerData.mining.tools then
			playerData.mining.tools = {}
		end

		playerData.mining.tools[item.id] = {
			durability = 100,
			purchaseTime = os.time()
		}

		if not playerData.mining.activeTool then
			playerData.mining.activeTool = item.id
		end

		print("⛏️ Added " .. item.id .. " to mining tools")
	else
		if not playerData.inventory then
			playerData.inventory = {}
		end
		local currentAmount = playerData.inventory[item.id] or 0
		playerData.inventory[item.id] = currentAmount + quantity
		print("🔧 Added " .. quantity .. "x " .. item.id .. " to inventory")
	end

	return true
end

function ShopSystem:ProcessBuildingPurchase(player, playerData, item, quantity)
	if not playerData.buildings then
		playerData.buildings = {}
	end

	playerData.buildings[item.id] = {
		purchaseTime = os.time(),
		level = 1,
		uses = 0
	}

	print("🏗️ Built " .. item.id)
	return true
end

function ShopSystem:ProcessAccessPurchase(player, playerData, item, quantity)
	if not playerData.access then
		playerData.access = {}
	end

	playerData.access[item.id] = {
		purchaseTime = os.time(),
		unlocked = true
	}

	print("🔓 Unlocked access: " .. item.id)
	return true
end

function ShopSystem:ProcessUpgradePurchase(player, playerData, item, quantity)
	if not playerData.upgrades then
		playerData.upgrades = {}
	end

	playerData.upgrades[item.id] = {
		purchaseTime = os.time(),
		level = 1
	}

	print("⬆️ Applied upgrade: " .. item.id)
	return true
end

function ShopSystem:ProcessGenericPurchase(player, playerData, item, quantity)
	if not playerData.inventory then
		playerData.inventory = {}
	end

	local currentAmount = playerData.inventory[item.id] or 0
	playerData.inventory[item.id] = currentAmount + quantity

	print("📦 Added " .. quantity .. "x " .. item.id .. " to generic inventory")
	return true
end

-- ========== ROBUST SELLING SYSTEM ==========

function ShopSystem:HandleSell(player, itemId, quantity)
	print("🏪 ShopSystem: ROBUST Sell request - " .. player.Name .. " selling " .. quantity .. "x " .. itemId)

	-- Get player data
	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Player Data Error", "Could not load player data!", "error")
		return false
	end

	-- Check if player has the item using comprehensive search
	local playerStock = self:GetPlayerStockComprehensive(playerData, itemId)
	if playerStock < quantity then
		self:SendNotification(player, "Not Enough Items", 
			"You only have " .. playerStock .. "x " .. itemId .. " but tried to sell " .. quantity .. "!", "error")
		return false
	end

	-- Check if item is sellable using ItemConfig
	if not self.ItemConfig.IsItemSellable(itemId) then
		self:SendNotification(player, "Cannot Sell", itemId .. " cannot be sold!", "error")
		return false
	end

	-- Get sell price using ItemConfig
	local sellPrice = self.ItemConfig.GetItemSellPrice(itemId)
	if sellPrice <= 0 then
		self:SendNotification(player, "No Value", "This item has no sell value!", "error")
		return false
	end

	-- Calculate earnings
	local totalEarnings = sellPrice * quantity
	local currency = self:GetItemCurrency(itemId)

	-- Remove items using comprehensive removal
	local removeSuccess = self:RemovePlayerItemsComprehensive(playerData, itemId, quantity)
	if not removeSuccess then
		self:SendNotification(player, "Sell Failed", "Could not remove items from inventory!", "error")
		return false
	end

	-- Add currency to player
	playerData[currency] = (playerData[currency] or 0) + totalEarnings

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.itemsSold = (playerData.stats.itemsSold or 0) + quantity
	playerData.stats.coinsEarned = (playerData.stats.coinsEarned or 0) + (currency == "coins" and totalEarnings or 0)

	-- Save and update
	if self.GameCore then
		self.GameCore:SavePlayerData(player)
		self.GameCore:UpdatePlayerLeaderstats(player)

		if self.GameCore.RemoteEvents and self.GameCore.RemoteEvents.PlayerDataUpdated then
			self.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end
	end

	-- Send confirmations
	if self.RemoteEvents.ItemSold then
		self.RemoteEvents.ItemSold:FireClient(player, itemId, quantity, totalEarnings, currency)
	end

	local itemName = self:GetItemDisplayName(itemId)
	local currencyName = currency == "farmTokens" and "Farm Tokens" or "Coins"

	self:SendNotification(player, "🏪 Item Sold!", 
		"Sold " .. quantity .. "x " .. itemName .. " for " .. totalEarnings .. " " .. currencyName .. "!", "success")

	print("🏪 ShopSystem: Successfully sold " .. quantity .. "x " .. itemId .. " for " .. player.Name)
	return true
end

-- ========== COMPREHENSIVE INVENTORY MANAGEMENT ==========

function ShopSystem:GetPlayerStockComprehensive(playerData, itemId)
	print("🔍 ShopSystem: Comprehensive stock search for " .. itemId)

	if not playerData then
		return 0
	end

	local totalStock = 0

	-- Define all possible inventory locations
	local inventoryLocations = {
		{path = {"farming", "inventory"}, priority = 1},
		{path = {"livestock", "inventory"}, priority = 2},
		{path = {"inventory"}, priority = 3},
		{path = {"defense", "chickens", "feed"}, priority = 4},
		{path = {"defense", "pestControl"}, priority = 5},
		{path = {"mining", "inventory"}, priority = 6},
		{path = {"buildings", "inventory"}, priority = 7}
	}

	-- Special handling for milk
	if itemId == "milk" or itemId == "fresh_milk" then
		if playerData.milk and playerData.milk > 0 then
			totalStock = totalStock + playerData.milk
			print("📦 Found " .. playerData.milk .. " milk in direct property")
		end
	end

	-- Search all inventory locations
	for _, location in ipairs(inventoryLocations) do
		local inventory = playerData
		local pathValid = true

		for _, key in ipairs(location.path) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				pathValid = false
				break
			end
		end

		if pathValid and inventory and inventory[itemId] then
			local amount = inventory[itemId]
			if type(amount) == "number" and amount > 0 then
				totalStock = totalStock + amount
				print("📦 Found " .. amount .. "x " .. itemId .. " in " .. table.concat(location.path, "."))
			end
		end
	end

	print("📊 Total stock for " .. itemId .. ": " .. totalStock)
	return totalStock
end

function ShopSystem:RemovePlayerItemsComprehensive(playerData, itemId, quantity)
	print("🗑️ ShopSystem: Comprehensive removal of " .. quantity .. "x " .. itemId)

	if not playerData then
		return false
	end

	local remainingToRemove = quantity

	-- Special handling for milk
	if itemId == "milk" or itemId == "fresh_milk" then
		if remainingToRemove > 0 and playerData.milk and playerData.milk > 0 then
			local removeFromDirect = math.min(playerData.milk, remainingToRemove)
			playerData.milk = playerData.milk - removeFromDirect
			remainingToRemove = remainingToRemove - removeFromDirect
			print("🥛 Removed " .. removeFromDirect .. " milk from direct property")
		end
	end

	-- Define inventory locations in order of priority
	local inventoryLocations = {
		{"farming", "inventory"},
		{"livestock", "inventory"},
		{"inventory"},
		{"defense", "chickens", "feed"},
		{"defense", "pestControl"},
		{"mining", "inventory"},
		{"buildings", "inventory"}
	}

	-- Remove from inventories in priority order
	for _, pathArray in ipairs(inventoryLocations) do
		if remainingToRemove <= 0 then
			break
		end

		local inventory = playerData
		local pathValid = true

		for _, key in ipairs(pathArray) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				pathValid = false
				break
			end
		end

		if pathValid and inventory and inventory[itemId] then
			local availableAmount = inventory[itemId]
			if type(availableAmount) == "number" and availableAmount > 0 then
				local removeAmount = math.min(availableAmount, remainingToRemove)

				inventory[itemId] = availableAmount - removeAmount
				remainingToRemove = remainingToRemove - removeAmount

				print("🗑️ Removed " .. removeAmount .. "x " .. itemId .. " from " .. table.concat(pathArray, "."))

				if inventory[itemId] <= 0 then
					inventory[itemId] = nil
				end
			end
		end
	end

	if remainingToRemove <= 0 then
		print("✅ Successfully removed all " .. quantity .. "x " .. itemId)
		return true
	else
		warn("❌ Could only remove " .. (quantity - remainingToRemove) .. "/" .. quantity .. "x " .. itemId)
		return false
	end
end

-- ========== UTILITY FUNCTIONS ==========

function ShopSystem:GetPlayerStock(playerData, itemId)
	return self:GetPlayerStockComprehensive(playerData, itemId)
end

function ShopSystem:GetShopItemById(itemId)
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		return nil
	end

	return self.ItemConfig.ShopItems[itemId]
end

function ShopSystem:GetItemCurrency(itemId)
	local item = self:GetShopItemById(itemId)
	if item and item.currency then
		return item.currency
	end

	if itemId == "golden_fruit" then
		return "farmTokens"
	end

	return "coins"
end

function ShopSystem:GetItemDisplayName(itemId)
	local item = self:GetShopItemById(itemId)
	if item and item.name then
		return item.name
	end

	return itemId:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

function ShopSystem:CanPlayerAfford(playerData, item, quantity)
	quantity = quantity or 1
	if not item.price or not item.currency then return false end

	if item.price == 0 then return true end

	local totalCost = item.price * quantity
	local playerCurrency = playerData[item.currency] or 0

	return playerCurrency >= totalCost
end

function ShopSystem:MeetsRequirements(playerData, item)
	return self:MeetsEnhancedRequirements(playerData, item)
end

function ShopSystem:IsAlreadyOwned(playerData, itemId)
	return playerData.purchaseHistory and playerData.purchaseHistory[itemId] or false
end

function ShopSystem:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function ShopSystem:SendEnhancedPurchaseConfirmation(player, item, quantity)
	-- Send the purchase data to client - client will handle the notification
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased:FireClient(player, item.id, quantity, item.price * quantity, item.currency)
	end

	-- REMOVED: Server-side notification call to prevent duplicates
	-- The client-side HandleEnhancedItemPurchased method will show the proper notification
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

function ShopSystem:ValidateShopData()
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		error("ShopSystem: ItemConfig.ShopItems not available!")
	end

	local validItems = 0
	local invalidItems = 0
	local categoryStats = {}

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if self:ValidateItem(item, itemId) then
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
		end
	end

	print("ShopSystem: Enhanced validation complete!")
	print("  Valid items: " .. validItems)
	print("  Invalid items: " .. invalidItems)

	print("Category breakdown:")
	for category, stats in pairs(categoryStats) do
		local categoryInfo = self.CategoryConfig[category]
		local categoryDisplay = categoryInfo and (categoryInfo.emoji .. " " .. categoryInfo.name) or category
		print("  " .. categoryDisplay .. ": " .. stats.count .. " items (" .. stats.withOrder .. " with purchase order)")
	end

	return invalidItems == 0
end

function ShopSystem:ValidateCategoryData()
	print("ShopSystem: Validating category configuration...")

	-- Check that all categories in shop items are defined
	local undefinedCategories = {}

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if item.category and not self.CategoryConfig[item.category] then
			if not undefinedCategories[item.category] then
				undefinedCategories[item.category] = {}
			end
			table.insert(undefinedCategories[item.category], itemId)
		end
	end

	if next(undefinedCategories) then
		warn("ShopSystem: Found items with undefined categories:")
		for category, items in pairs(undefinedCategories) do
			warn("  " .. category .. ": " .. table.concat(items, ", "))
		end
	else
		print("ShopSystem: ✅ All item categories are properly defined")
	end

	-- Report category usage
	print("ShopSystem: Category usage report:")
	for categoryId, config in pairs(self.CategoryConfig) do
		local itemCount = 0
		for _, item in pairs(self.ItemConfig.ShopItems) do
			if item.category == categoryId then
				itemCount = itemCount + 1
			end
		end
		print("  " .. config.emoji .. " " .. config.name .. ": " .. itemCount .. " items")
	end
end

-- ========== DEBUG FUNCTIONS ==========

function ShopSystem:DebugPurchaseOrder(category)
	print("=== PURCHASE ORDER DEBUG for " .. (category or "ALL") .. " ===")

	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		print("❌ ItemConfig not available")
		return
	end

	local items = {}
	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if not category or item.category == category then
			table.insert(items, {id = itemId, item = item})
		end
	end

	-- Sort by purchase order
	table.sort(items, function(a, b)
		return self:CompareItemsForSorting(a.item, b.item)
	end)

	for i, itemData in ipairs(items) do
		local item = itemData.item
		local categoryInfo = self.CategoryConfig[item.category]
		local categoryDisplay = categoryInfo and (categoryInfo.emoji .. " " .. categoryInfo.name) or item.category
		local orderInfo = item.purchaseOrder and ("[" .. item.purchaseOrder .. "]") or "[NO ORDER]"
		print(i .. ". " .. categoryDisplay .. " " .. orderInfo .. " " .. item.name .. " - " .. item.price .. " " .. item.currency)
	end

	print("==============================")
end

function ShopSystem:DebugCategorySystem(player)
	print("=== CATEGORY SYSTEM DEBUG ===")

	local categories = self:HandleGetShopCategories(player)

	print("Available categories:")
	for _, category in ipairs(categories) do
		print("  " .. category.emoji .. " " .. category.name .. " (" .. category.itemCount .. " items)")
		print("    Priority: " .. category.priority)
		print("    Description: " .. category.description)
	end

	print("============================")
end

-- ========== ADMIN COMMANDS ==========

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/debugorder" then
				local category = args[2]
				ShopSystem:DebugPurchaseOrder(category)

			elseif command == "/debugcategories" then
				ShopSystem:DebugCategorySystem(player)

			elseif command == "/testcategory" then
				local category = args[2] or "seeds"
				local items = ShopSystem:HandleGetShopItemsByCategory(player, category)
				print("Category " .. category .. " has " .. #items .. " items:")
				for i, item in ipairs(items) do
					print("  " .. i .. ". " .. item.name .. " - " .. item.price .. " " .. item.currency)
				end

			elseif command == "/debuginventory" then
				ShopSystem:DebugPlayerInventory(player)

			elseif command == "/debugsellable" then
				ShopSystem:DebugSellableItems(player)

			elseif command == "/testsell" then
				local itemId = args[2] or "carrot"
				local quantity = tonumber(args[3]) or 1
				print("Testing sale of " .. quantity .. "x " .. itemId)
				ShopSystem:HandleSell(player, itemId, quantity)

			elseif command == "/givetest" then
				local playerData = ShopSystem.GameCore and ShopSystem.GameCore:GetPlayerData(player)
				if playerData then
					playerData.farming = playerData.farming or {inventory = {}}
					playerData.farming.inventory = playerData.farming.inventory or {}
					playerData.livestock = playerData.livestock or {inventory = {}}
					playerData.livestock.inventory = playerData.livestock.inventory or {}

					local testItems = {
						{id = "carrot", amount = 10, location = {"farming", "inventory"}},
						{id = "corn", amount = 5, location = {"farming", "inventory"}},
						{id = "milk", amount = 8, location = {"livestock", "inventory"}},
						{id = "copper_ore", amount = 3, location = {"inventory"}}
					}

					for _, testItem in ipairs(testItems) do
						local inventory = playerData
						for _, key in ipairs(testItem.location) do
							if not inventory[key] then
								inventory[key] = {}
							end
							inventory = inventory[key]
						end

						inventory[testItem.id] = (inventory[testItem.id] or 0) + testItem.amount
					end

					print("Gave test items to " .. player.Name)
					if ShopSystem.GameCore then
						ShopSystem.GameCore:SavePlayerData(player)
					end
				end

				-- SIMPLIFIED FARM COMMANDS (remove expansion-specific ones)
			elseif command == "/givesimplefarm" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer then
					local playerData = ShopSystem.GameCore and ShopSystem.GameCore:GetPlayerData(targetPlayer)
					if playerData then
						-- Give them the simple farm
						playerData.purchaseHistory = playerData.purchaseHistory or {}
						playerData.purchaseHistory.farm_plot_starter = true
						playerData.farming = playerData.farming or {
							plots = 1,
							inventory = {
								carrot_seeds = 5, 
								corn_seeds = 3
							}
						}

						-- Create the simple farm
						ShopSystem.GameCore:CreateSimpleFarmPlot(targetPlayer)

						if ShopSystem.GameCore.SendNotification then
							ShopSystem.GameCore:SendNotification(targetPlayer, "Admin Gift", "You received a free 10x10 farm with 100 planting spots!", "success")
						end
						print("Admin: Gave simple farm to " .. targetPlayer.Name)
					end
				else
					print("Admin: Player " .. targetName .. " not found")
				end

			elseif command == "/resetsimplefarm" then
				local targetName = args[2]
				if targetName then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						-- Remove their simple farm from workspace
						local farm = ShopSystem.GameCore:GetPlayerSimpleFarm(targetPlayer)
						if farm then
							farm:Destroy()
							print("Admin: Destroyed " .. targetPlayer.Name .. "'s simple farm")
						end

						-- Reset their farm data
						local playerData = ShopSystem.GameCore and ShopSystem.GameCore:GetPlayerData(targetPlayer)
						if playerData then
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = nil
							playerData.farming = nil
						end

						ShopSystem.GameCore:SavePlayerData(targetPlayer)
						print("Admin: Reset simple farm data for " .. targetPlayer.Name)

						if ShopSystem.GameCore.SendNotification then
							ShopSystem.GameCore:SendNotification(targetPlayer, "Admin Action", "Your farm has been reset", "info")
						end
					else
						print("Admin: Player " .. targetName .. " not found")
					end
				end

			elseif command == "/simplefarmstats" then
				local totalFarms = 0
				local playersWithFarms = 0

				for _, p in pairs(Players:GetPlayers()) do
					local playerData = ShopSystem.GameCore and ShopSystem.GameCore:GetPlayerData(p)
					if playerData and playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter then
						playersWithFarms = playersWithFarms + 1
						totalFarms = totalFarms + 1
						print("  " .. p.Name .. ": HAS SIMPLE FARM (10x10 grid, 100 spots)")
					else
						print("  " .. p.Name .. ": NO FARM")
					end
				end

				print("Simple Farm Stats:")
				print("  Total farms: " .. totalFarms)
				print("  Players with farms: " .. playersWithFarms)
				print("  Grid size: 10x10 (100 spots each)")
				print("  All spots unlocked immediately!")
			end
		end
	end)
end)

print("ShopSystem: ✅ SIMPLIFIED - No expansion system!")
print("🌾 SIMPLIFIED FEATURES:")
print("  ✅ Single farm purchase = Full 10x10 grid")
print("  ❌ No expansion levels or unlocking")
print("  ❌ No expansion purchase requirements")
print("  ✅ 100 spots available immediately")
print("")
print("🔧 Simplified Admin Commands:")
print("  /givesimplefarm [player] - Give free 10x10 farm")
print("  /resetsimplefarm [player] - Reset player's farm")
print("  /simplefarmstats - Show farm statistics")
print("  (All expansion commands removed)")

function ShopSystem:DebugPlayerInventory(player)
	print("=== PLAYER INVENTORY DEBUG ===")

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		print("❌ No player data found")
		return
	end

	local inventoryLocations = {
		{"farming", "inventory"},
		{"livestock", "inventory"},
		{"inventory"},
		{"defense", "chickens", "feed"},
		{"defense", "pestControl"},
		{"mining", "inventory"}
	}

	for _, pathArray in ipairs(inventoryLocations) do
		local inventory = playerData
		local pathValid = true

		for _, key in ipairs(pathArray) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				pathValid = false
				break
			end
		end

		if pathValid and inventory then
			local hasItems = false
			for itemId, amount in pairs(inventory) do
				if type(amount) == "number" and amount > 0 then
					if not hasItems then
						print("📦 " .. table.concat(pathArray, ".") .. ":")
						hasItems = true
					end
					print("  " .. itemId .. ": " .. amount)
				end
			end
			if not hasItems then
				print("📦 " .. table.concat(pathArray, ".") .. ": (empty)")
			end
		else
			print("📦 " .. table.concat(pathArray, ".") .. ": (not found)")
		end
	end

	if playerData.milk then
		print("🥛 Direct milk property: " .. playerData.milk)
	end

	print("===============================")
end

function ShopSystem:DebugSellableItems(player)
	print("=== SELLABLE ITEMS DEBUG ===")

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		print("❌ No player data found")
		return
	end

	local testItems = {"carrot", "corn", "strawberry", "wheat", "milk", "copper_ore", "chicken_egg"}

	for _, itemId in ipairs(testItems) do
		local stock = self:GetPlayerStockComprehensive(playerData, itemId)
		local sellable = self.ItemConfig.IsItemSellable(itemId)
		local sellPrice = self.ItemConfig.GetItemSellPrice(itemId)

		print("🧪 " .. itemId .. ":")
		print("  Stock: " .. stock)
		print("  Sellable: " .. tostring(sellable))
		print("  Sell Price: " .. sellPrice)
	end

	print("============================")
end

print("ShopSystem: ✅ ENHANCED with full tabbed categories support!")
print("🛒 NEW TABBED FEATURES:")
print("  📁 Category-specific item filtering and retrieval")
print("  🎨 Enhanced category configuration with emojis and descriptions")
print("  📊 Category-aware purchase confirmations and statistics")
print("  🔍 Category-specific requirement validation")
print("  📋 Enhanced sorting by category priority and purchase order")
print("  🎯 Category usage reporting and validation")
print("")
print("🔧 New Remote Functions:")
print("  GetShopItemsByCategory(category) - Get items for specific tab")
print("  GetShopCategories() - Get all available categories with info")
print("")
print("🔧 Enhanced Debug Commands:")
print("  /debugorder [category] - Show purchase order for category")
print("  /debugcategories - Show all available categories")
print("  /testcategory [category] - Test category filtering")
print("  /debuginventory - Show all inventory locations")
print("  /debugsellable - Test sellable items detection")
print("  /testsell [item] [amount] - Test selling specific item")
print("  /givetest - Give test items for selling")

return ShopSystem