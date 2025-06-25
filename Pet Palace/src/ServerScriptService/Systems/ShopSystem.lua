--[[
    ENHANCED ShopSystem.lua - Purchase Order Support & Better Item Management
    
    IMPROVEMENTS:
    ✅ Respects purchaseOrder from ItemConfig for logical progression
    ✅ Enhanced item sorting by category and purchase order
    ✅ Better debugging for shop item ordering
    ✅ Improved item filtering and validation
    ✅ Enhanced purchase requirement checking
]]

local ShopSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Module State
ShopSystem.RemoteEvents = {}
ShopSystem.RemoteFunctions = {}
ShopSystem.ItemConfig = nil
ShopSystem.GameCore = nil

-- Purchase cooldowns
ShopSystem.PurchaseCooldowns = {}
ShopSystem.PURCHASE_COOLDOWN = 1

-- ========== INITIALIZATION ==========

function ShopSystem:Initialize(gameCore)
	print("ShopSystem: Initializing ENHANCED shop system with purchase order support...")

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

	print("ShopSystem: ✅ ENHANCED shop system initialization complete")
	return true
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

-- ========== ENHANCED SHOP ITEMS HANDLER ==========

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

		-- ENHANCED: Sort by category, then by purchase order, then by price
		table.sort(shopItemsArray, function(a, b)
			-- First sort by category
			if a.category ~= b.category then
				return self:GetCategoryPriority(a.category) < self:GetCategoryPriority(b.category)
			end

			-- Within same category, sort by purchase order
			local orderA = a.purchaseOrder or 999
			local orderB = b.purchaseOrder or 999

			if orderA ~= orderB then
				return orderA < orderB
			end

			-- If same purchase order, sort by price
			return a.price < b.price
		end)

		print("🛒 ShopSystem: Returning " .. #shopItemsArray .. " items (sorted by purchase order)")
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

function ShopSystem:GetCategoryPriority(category)
	-- Define the order categories should appear
	local categoryOrder = {
		seeds = 1,
		farm = 2,
		defense = 3,
		sell = 4,
		mining = 5,
		crafting = 6,
		premium = 7
	}

	return categoryOrder[category] or 999
end

function ShopSystem:ShouldShowItem(item, itemId, playerData)
	-- Don't show items marked as not purchasable (like crops in inventory)
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

	return true
end

function ShopSystem:LogItemOrdering(shopItemsArray)
	print("📋 Shop Items Order:")
	local currentCategory = ""
	local categoryCount = 0

	for i, item in ipairs(shopItemsArray) do
		if item.category ~= currentCategory then
			if currentCategory ~= "" then
				print("  └─ " .. categoryCount .. " items in " .. currentCategory)
			end
			currentCategory = item.category
			categoryCount = 0
			print("📁 " .. currentCategory:upper() .. " Category:")
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
		purchaseOrder = item.purchaseOrder or 999 -- ENHANCED: Include purchase order
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

		-- ENHANCED: Add requirement status for UI
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
		self:SendPurchaseConfirmation(player, item, quantity)
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

	-- Enhanced requirements checking
	if not self:MeetsEnhancedRequirements(playerData, item) then
		if item.requiresPurchase then
			local reqItem = self:GetShopItemById(item.requiresPurchase)
			local reqName = reqItem and reqItem.name or item.requiresPurchase
			return false, "🔒 Must purchase " .. reqName .. " first!"
		end

		if item.requiresFarmPlot then
			return false, "🔒 Requires a farm plot!"
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

	return true
end

function ShopSystem:ProcessPurchase(player, playerData, item, quantity)
	-- Calculate total cost
	local totalCost = item.price * quantity
	local currency = item.currency

	print("💰 Processing enhanced purchase:")
	print("  Player: " .. player.Name)
	print("  Item: " .. item.id .. " (" .. item.type .. ")")
	print("  Quantity: " .. quantity)
	print("  Total Cost: " .. totalCost .. " " .. currency)
	print("  Purchase Order: " .. (item.purchaseOrder or "none"))

	-- Deduct currency (skip for free items)
	if item.price > 0 then
		local oldAmount = playerData[currency] or 0
		playerData[currency] = oldAmount - totalCost
		print("💳 Deducted " .. totalCost .. " " .. currency .. " (had " .. oldAmount .. ", now " .. playerData[currency] .. ")")
	else
		print("🆓 Free item, no currency deducted")
	end

	-- Process by item type with enhanced error handling
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

	print("✅ Enhanced purchase processing successful!")

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

function ShopSystem:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	if not self.GameCore then return false end

	if item.id == "farm_plot_starter" then
		playerData.farming = playerData.farming or {}
		playerData.farming.plots = 1
		playerData.farming.inventory = playerData.farming.inventory or {}

		if item.effects and item.effects.starterSeeds then
			for seedId, amount in pairs(item.effects.starterSeeds) do
				playerData.farming.inventory[seedId] = (playerData.farming.inventory[seedId] or 0) + amount
				print("🎁 Added " .. amount .. "x " .. seedId .. " as starter bonus")
			end
		end

		local success = self.GameCore:CreatePlayerFarmPlot(player, 1)
		print("🌾 Created first farm plot: " .. tostring(success))
		return success

	elseif item.id == "farm_plot_expansion" then
		local currentPlots = playerData.farming and playerData.farming.plots or 0
		local newPlotNumber = currentPlots + quantity

		if newPlotNumber > 10 then 
			print("❌ Cannot exceed 10 farm plots")
			return false 
		end

		playerData.farming = playerData.farming or {}
		playerData.farming.plots = newPlotNumber

		for i = currentPlots + 1, newPlotNumber do
			self.GameCore:CreatePlayerFarmPlot(player, i)
			print("🚜 Created farm plot " .. i)
		end
		return true
	end

	return false
end

function ShopSystem:ProcessUpgradePurchase(player, playerData, item, quantity)
	playerData.upgrades = playerData.upgrades or {}

	if item.maxQuantity == 1 then
		playerData.upgrades[item.id] = true
		print("⬆️ Activated upgrade: " .. item.id)
	else
		local currentLevel = playerData.upgrades[item.id] or 0
		playerData.upgrades[item.id] = currentLevel + quantity
		print("⬆️ Upgraded " .. item.id .. " to level " .. (currentLevel + quantity))
	end

	return true
end

function ShopSystem:ProcessCowPurchase(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing enhanced cow purchase for " .. player.Name)
	print("  Item: " .. item.id .. " (Order: " .. (item.purchaseOrder or "none") .. ")")
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
function ShopSystem:ProcessCowPurchaseEnhanced(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing ENHANCED cow purchase for " .. player.Name)
	print("  Item: " .. item.id .. " (Tier: " .. (item.cowData and item.cowData.tier or "unknown") .. ")")

	if not self.GameCore then
		print("❌ GameCore not available!")
		return false
	end

	-- Initialize livestock data
	if not playerData.livestock then
		playerData.livestock = {cows = {}}
	end
	if not playerData.livestock.cows then
		playerData.livestock.cows = {}
	end

	-- Get cow configuration
	local cowConfig = self.GameCore:GetCowConfiguration(item.id)
	if not cowConfig then
		print("❌ GameCore:GetCowConfiguration failed for " .. item.id)
		return false
	end

	-- Handle upgrades differently from new cow purchases
	if item.type == "cow_upgrade" then
		return self:ProcessCowUpgrade(player, playerData, item, quantity)
	end

	-- Regular cow purchase logic
	local currentCowCount = 0
	for _ in pairs(playerData.livestock.cows) do
		currentCowCount = currentCowCount + 1
	end

	local maxCows = cowConfig.maxCows or 1
	if currentCowCount >= maxCows then
		self:SendNotification(player, "Cow Limit", "Maximum cows reached for this tier!", "error")
		return false
	end

	-- Purchase new cow
	local successCount = 0
	for i = 1, quantity do
		local success, result = pcall(function()
			return self.GameCore:PurchaseCow(player, item.id, cowConfig.tier)
		end)

		if success and result then
			successCount = successCount + 1
		else
			break
		end
	end

	return successCount > 0
end

-- New function to handle cow upgrades
function ShopSystem:ProcessCowUpgrade(player, playerData, item, quantity)
	print("🔄 ShopSystem: Processing cow upgrade for " .. player.Name)

	local upgradeConfig = self.GameCore:GetCowConfiguration(item.id)
	if not upgradeConfig then
		return false
	end

	-- Find cows that can be upgraded
	local upgradableCows = {}
	for cowId, cow in pairs(playerData.livestock.cows) do
		if cow.tier == upgradeConfig.upgradeFrom then
			table.insert(upgradableCows, cowId)
		end
	end

	if #upgradableCows == 0 then
		local requiredTier = upgradeConfig.upgradeFrom or "unknown"
		self:SendNotification(player, "No Upgradable Cows", 
			"You need a " .. requiredTier .. " tier cow to upgrade!", "error")
		return false
	end

	-- Upgrade cows
	local upgradeCount = math.min(quantity, #upgradableCows)
	local successCount = 0

	for i = 1, upgradeCount do
		local cowId = upgradableCows[i]
		local success, message = self.GameCore:UpgradeCow(player, cowId, item.id)

		if success then
			successCount = successCount + 1
			print("✅ Upgraded cow " .. cowId .. " to " .. upgradeConfig.tier)
		else
			print("❌ Failed to upgrade cow " .. cowId .. ": " .. (message or "unknown error"))
		end
	end

	if successCount > 0 then
		self:SendNotification(player, "🔄 Cow Upgraded!", 
			"Successfully upgraded " .. successCount .. " cow(s) to " .. upgradeConfig.tier .. " tier!", "success")
		return true
	end

	return false
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

function ShopSystem:SendPurchaseConfirmation(player, item, quantity)
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased:FireClient(player, item.id, quantity, item.price * quantity, item.currency)
	end

	local itemName = item.name or item.id:gsub("_", " ")
	self:SendNotification(player, "🛒 Purchase Complete!", 
		"Purchased " .. quantity .. "x " .. itemName .. "!", "success")
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
		print("  " .. category .. ": " .. stats.count .. " items (" .. stats.withOrder .. " with purchase order)")
	end

	return invalidItems == 0
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
		local orderA = a.item.purchaseOrder or 999
		local orderB = b.item.purchaseOrder or 999

		if orderA == orderB then
			return a.item.price < b.item.price
		end

		return orderA < orderB
	end)

	for i, itemData in ipairs(items) do
		local item = itemData.item
		local orderInfo = item.purchaseOrder and ("[" .. item.purchaseOrder .. "]") or "[NO ORDER]"
		print(i .. ". " .. orderInfo .. " " .. item.name .. " - " .. item.price .. " " .. item.currency)
	end

	print("==============================")
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
			end
		end
	end)
end)

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

print("ShopSystem: ✅ ENHANCED with purchase order support and better item management!")
print("🏪 IMPROVEMENTS:")
print("  📋 Respects purchaseOrder for logical item progression")
print("  🔄 Enhanced item sorting by category and purchase order")
print("  🔒 Better prerequisite checking and requirement validation")
print("  📊 Improved debugging for shop item ordering")
print("  📦 Enhanced item filtering to hide inappropriate items")
print("")
print("🔧 Debug Commands:")
print("  /debugorder [category] - Show purchase order for category")
print("  /debuginventory - Show all inventory locations")
print("  /debugsellable - Test sellable items detection")
print("  /testsell [item] [amount] - Test selling specific item")
print("  /givetest - Give test items for selling")

return ShopSystem