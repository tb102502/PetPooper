--[[
    FIXED ShopSystem.lua - Robust Purchase & Selling System
    
    FIXES:
    ✅ Comprehensive inventory checking across all locations
    ✅ Robust item removal system
    ✅ Streamlined selling logic (single method)
    ✅ Enhanced error handling and debugging
    ✅ Proper integration with fixed ItemConfig
    ✅ Consistent purchase processing
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
	print("ShopSystem: Initializing FIXED shop system...")

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

	print("ShopSystem: ✅ FIXED shop system initialization complete")
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

-- ========== SHOP ITEMS HANDLER ==========

function ShopSystem:HandleGetShopItems(player)
	print("🛒 ShopSystem: GetShopItems request from " .. player.Name)

	local success, result = pcall(function()
		if not self.ItemConfig or not self.ItemConfig.ShopItems then
			error("ItemConfig.ShopItems not available")
		end

		local shopItemsArray = {}
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			if self:ValidateItem(item, itemId) then
				local itemCopy = self:CreateItemCopy(item, itemId, playerData)
				table.insert(shopItemsArray, itemCopy)
			end
		end

		-- Sort items by category and price
		table.sort(shopItemsArray, function(a, b)
			if a.category == b.category then
				return a.price < b.price
			end
			return a.category < b.category
		end)

		print("🛒 ShopSystem: Returning " .. #shopItemsArray .. " items")
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
	end

	return itemCopy
end

-- ========== PURCHASE SYSTEM ==========

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

	-- Validate purchase
	local canPurchase, reason = self:ValidatePurchase(player, playerData, item, quantity)
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

function ShopSystem:ValidatePurchase(player, playerData, item, quantity)
	-- Check if player can afford it
	if item.price > 0 and not self:CanPlayerAfford(playerData, item, quantity) then
		local currency = item.currency == "farmTokens" and "Farm Tokens" or "Coins"
		local needed = item.price * quantity
		local has = playerData[item.currency] or 0
		return false, "Not enough " .. currency .. "! Need " .. needed .. ", have " .. has
	end

	-- Check requirements
	if not self:MeetsRequirements(playerData, item) then
		if item.requiresPurchase then
			local reqItem = self:GetShopItemById(item.requiresPurchase)
			local reqName = reqItem and reqItem.name or item.requiresPurchase
			return false, "Requires: " .. reqName
		end
		return false, "Requirements not met!"
	end

	-- Check quantity limits
	if item.maxQuantity and item.maxQuantity == 1 then
		if self:IsAlreadyOwned(playerData, item.id) then
			return false, "Already purchased!"
		end
	end

	return true, "Can purchase"
end

function ShopSystem:ProcessPurchase(player, playerData, item, quantity)
	-- Calculate total cost
	local totalCost = item.price * quantity
	local currency = item.currency

	-- Deduct currency (skip for free items)
	if item.price > 0 then
		local oldAmount = playerData[currency] or 0
		playerData[currency] = oldAmount - totalCost
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
	elseif item.type == "chicken" then
		processed = self:ProcessChickenPurchase(player, playerData, item, quantity)
	elseif item.type == "feed" then
		processed = self:ProcessFeedPurchase(player, playerData, item, quantity)
	elseif item.type == "tool" then
		processed = self:ProcessToolPurchase(player, playerData, item, quantity)
	elseif item.type == "building" then
		processed = self:ProcessBuildingPurchase(player, playerData, item, quantity)
	elseif item.type == "access" then
		processed = self:ProcessAccessPurchase(player, playerData, item, quantity)
	else
		processed = self:ProcessGenericPurchase(player, playerData, item, quantity)
	end

	if not processed then
		-- Refund on failure
		if item.price > 0 then
			playerData[currency] = (playerData[currency] or 0) + totalCost
		end
		error("Item processing failed for type: " .. (item.type or "unknown"))
	end

	-- Mark as purchased
	if item.maxQuantity == 1 then
		playerData.purchaseHistory = playerData.purchaseHistory or {}
		playerData.purchaseHistory[item.id] = true
	end

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
			end
		end

		local success = self.GameCore:CreatePlayerFarmPlot(player, 1)
		return success

	elseif item.id == "farm_plot_expansion" then
		local currentPlots = playerData.farming and playerData.farming.plots or 0
		local newPlotNumber = currentPlots + quantity

		if newPlotNumber > 10 then return false end

		playerData.farming = playerData.farming or {}
		playerData.farming.plots = newPlotNumber

		for i = currentPlots + 1, newPlotNumber do
			self.GameCore:CreatePlayerFarmPlot(player, i)
		end
		return true
	end

	return false
end

function ShopSystem:ProcessUpgradePurchase(player, playerData, item, quantity)
	playerData.upgrades = playerData.upgrades or {}

	if item.maxQuantity == 1 then
		playerData.upgrades[item.id] = true
	else
		local currentLevel = playerData.upgrades[item.id] or 0
		playerData.upgrades[item.id] = currentLevel + quantity
	end

	return true
end

function ShopSystem:ProcessCowPurchase(player, playerData, item, quantity)
	if not self.GameCore then return false end

	-- Initialize livestock data
	if not playerData.livestock then
		playerData.livestock = {cows = {}}
	end
	if not playerData.livestock.cows then
		playerData.livestock.cows = {}
	end

	local successCount = 0

	for i = 1, quantity do
		local success, error = pcall(function()
			return self.GameCore:PurchaseCow(player, item.id, nil)
		end)

		if success and error then
			successCount = successCount + 1
		else
			break
		end
	end

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
		else
			local currentAmount = playerData.defense.pestControl[item.id] or 0
			playerData.defense.pestControl[item.id] = currentAmount + quantity
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
	else
		if not playerData.inventory then
			playerData.inventory = {}
		end
		local currentAmount = playerData.inventory[item.id] or 0
		playerData.inventory[item.id] = currentAmount + quantity
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

	return true
end

function ShopSystem:ProcessGenericPurchase(player, playerData, item, quantity)
	if not playerData.inventory then
		playerData.inventory = {}
	end

	local currentAmount = playerData.inventory[item.id] or 0
	playerData.inventory[item.id] = currentAmount + quantity

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
		-- Farming inventory (crops, seeds)
		{path = {"farming", "inventory"}, priority = 1},

		-- Livestock inventory (milk, eggs)
		{path = {"livestock", "inventory"}, priority = 2},

		-- General inventory
		{path = {"inventory"}, priority = 3},

		-- Defense inventories
		{path = {"defense", "chickens", "feed"}, priority = 4},
		{path = {"defense", "pestControl"}, priority = 5},

		-- Mining inventory
		{path = {"mining", "inventory"}, priority = 6},

		-- Building inventory
		{path = {"buildings", "inventory"}, priority = 7}
	}

	-- Special handling for milk (can be stored in multiple places)
	if itemId == "milk" or itemId == "fresh_milk" then
		-- Direct milk property
		if playerData.milk and playerData.milk > 0 then
			totalStock = totalStock + playerData.milk
			print("📦 Found " .. playerData.milk .. " milk in direct property")
		end
	end

	-- Search all inventory locations
	for _, location in ipairs(inventoryLocations) do
		local inventory = playerData
		local pathValid = true

		-- Navigate to the inventory location
		for _, key in ipairs(location.path) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				pathValid = false
				break
			end
		end

		-- Check if item exists in this location
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

	-- Special handling for milk (remove from direct property first)
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
		{"farming", "inventory"},     -- Priority 1: Crops go here
		{"livestock", "inventory"},   -- Priority 2: Animal products
		{"inventory"},               -- Priority 3: General items
		{"defense", "chickens", "feed"}, -- Priority 4: Chicken feed
		{"defense", "pestControl"},   -- Priority 5: Pest control items
		{"mining", "inventory"},      -- Priority 6: Mining materials
		{"buildings", "inventory"}    -- Priority 7: Building materials
	}

	-- Remove from inventories in priority order
	for _, pathArray in ipairs(inventoryLocations) do
		if remainingToRemove <= 0 then
			break
		end

		local inventory = playerData
		local pathValid = true

		-- Navigate to inventory location
		for _, key in ipairs(pathArray) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				pathValid = false
				break
			end
		end

		-- Remove items if found
		if pathValid and inventory and inventory[itemId] then
			local availableAmount = inventory[itemId]
			if type(availableAmount) == "number" and availableAmount > 0 then
				local removeAmount = math.min(availableAmount, remainingToRemove)

				inventory[itemId] = availableAmount - removeAmount
				remainingToRemove = remainingToRemove - removeAmount

				print("🗑️ Removed " .. removeAmount .. "x " .. itemId .. " from " .. table.concat(pathArray, "."))

				-- Clean up zero entries
				if inventory[itemId] <= 0 then
					inventory[itemId] = nil
				end
			end
		end
	end

	-- Check if removal was successful
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
	-- Legacy method - redirects to comprehensive version
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

	-- Default currency based on item type
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

	-- Clean up item ID as fallback
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
	if item.requiresPurchase then
		if not playerData.purchaseHistory or not playerData.purchaseHistory[item.requiresPurchase] then
			return false
		end
	end

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

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if self:ValidateItem(item, itemId) then
			validItems = validItems + 1
		else
			invalidItems = invalidItems + 1
		end
	end

	print("ShopSystem: Validation complete - Valid: " .. validItems .. ", Invalid: " .. invalidItems)
	return invalidItems == 0
end

-- ========== DEBUG FUNCTIONS ==========

function ShopSystem:DebugPlayerInventory(player)
	print("=== PLAYER INVENTORY DEBUG ===")

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		print("❌ No player data found")
		return
	end

	-- Check all inventory locations
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

	-- Special milk check
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

-- ========== ADMIN COMMANDS ==========

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/debuginventory" then
				ShopSystem:DebugPlayerInventory(player)

			elseif command == "/debugsellable" then
				ShopSystem:DebugSellableItems(player)

			elseif command == "/testsell" then
				local itemId = args[2] or "carrot"
				local quantity = tonumber(args[3]) or 1
				print("Testing sale of " .. quantity .. "x " .. itemId)
				ShopSystem:HandleSell(player, itemId, quantity)

			elseif command == "/givetest" then
				-- Give test items for selling
				local playerData = ShopSystem.GameCore and ShopSystem.GameCore:GetPlayerData(player)
				if playerData then
					-- Initialize inventories
					playerData.farming = playerData.farming or {inventory = {}}
					playerData.farming.inventory = playerData.farming.inventory or {}
					playerData.livestock = playerData.livestock or {inventory = {}}
					playerData.livestock.inventory = playerData.livestock.inventory or {}

					-- Give test items
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

print("ShopSystem: ✅ FIXED robust purchase & selling system loaded!")
print("🏪 Features:")
print("  🛒 Streamlined purchase processing")
print("  💰 Comprehensive selling system")
print("  📦 Multi-location inventory management")
print("  🔍 Enhanced debugging tools")
print("  ⚡ Better error handling")
print("")
print("🔧 Debug Commands:")
print("  /debuginventory - Show all inventory locations")
print("  /debugsellable - Test sellable items detection")
print("  /testsell [item] [amount] - Test selling specific item")
print("  /givetest - Give test items for selling")

return ShopSystem