--[[
    ENHANCED ShopSystem.lua - Complete Integration with ItemConfig
    Place in: ServerScriptService/Systems/ShopSystem.lua
    
    FIXES:
    ✅ Full integration with complete ItemConfig
    ✅ Better item validation and processing
    ✅ Enhanced debugging for missing items
    ✅ Improved error handling
    ✅ Support for all item types and categories
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
	print("ShopSystem: Initializing ENHANCED shop management module...")

	self.GameCore = gameCore

	-- Load ItemConfig
	local success, itemConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig"))
	end)

	if success and itemConfig then
		self.ItemConfig = itemConfig
		print("ShopSystem: ✅ ItemConfig loaded successfully")

		-- Debug ItemConfig contents
		self:DebugItemConfig()
	else
		error("ShopSystem: Failed to load ItemConfig: " .. tostring(itemConfig))
	end

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Setup remote handlers
	self:SetupRemoteHandlers()

	-- Validate shop data
	self:ValidateShopData()

	print("ShopSystem: ✅ Enhanced shop system initialization complete")
	return true
end

function ShopSystem:DebugItemConfig()
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		warn("ShopSystem: No ShopItems in ItemConfig!")
		return
	end

	local itemCount = 0
	local categoryBreakdown = {}
	local typeBreakdown = {}

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		itemCount = itemCount + 1

		local category = item.category or "unknown"
		local itemType = item.type or "unknown"

		categoryBreakdown[category] = (categoryBreakdown[category] or 0) + 1
		typeBreakdown[itemType] = (typeBreakdown[itemType] or 0) + 1
	end

	print("🛒 ShopSystem: ItemConfig Debug Summary")
	print("  📦 Total items: " .. itemCount)
	print("  🏷️ Categories:")
	for category, count in pairs(categoryBreakdown) do
		print("    " .. category .. ": " .. count .. " items")
	end
	print("  🔖 Types:")
	for itemType, count in pairs(typeBreakdown) do
		print("    " .. itemType .. ": " .. count .. " items")
	end
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

-- ========== ENHANCED SHOP ITEM MANAGEMENT ==========

function ShopSystem:HandleGetShopItems(player)
	print("🛒 ShopSystem: ENHANCED GetShopItems request from " .. player.Name)

	local success, result = pcall(function()
		if not self.ItemConfig or not self.ItemConfig.ShopItems then
			error("ItemConfig.ShopItems not available")
		end

		local shopItemsArray = {}
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		-- Convert dictionary to array with enhanced validation
		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			-- Enhanced validation
			if self:ValidateItemEnhanced(item, itemId) then
				local itemCopy = self:CreateEnhancedItemCopy(item, itemId, playerData)
				table.insert(shopItemsArray, itemCopy)
				print("🛒 ShopSystem: Added item: " .. itemId .. " (" .. item.category .. ")")
			else
				warn("🛒 ShopSystem: Invalid item skipped: " .. itemId)
			end
		end

		-- Sort items by category and then by price
		table.sort(shopItemsArray, function(a, b)
			if a.category == b.category then
				return a.price < b.price
			end
			return a.category < b.category
		end)

		print("🛒 ShopSystem: Sending " .. #shopItemsArray .. " valid items to " .. player.Name)

		-- Debug category breakdown
		local categoryCount = {}
		for _, item in ipairs(shopItemsArray) do
			categoryCount[item.category] = (categoryCount[item.category] or 0) + 1
		end

		print("🛒 ShopSystem: Category breakdown for " .. player.Name .. ":")
		for category, count in pairs(categoryCount) do
			print("    " .. category .. ": " .. count .. " items")
		end

		return shopItemsArray
	end)

	if success then
		return result
	else
		warn("🛒 ShopSystem: GetShopItems failed: " .. tostring(result))
		return {}
	end
end

function ShopSystem:ValidateItemEnhanced(item, itemId)
	if not item then 
		warn("ShopSystem: Item is nil: " .. itemId)
		return false 
	end

	-- Required properties
	local required = {"name", "price", "currency", "category", "description", "icon"}
	for _, prop in ipairs(required) do
		if not item[prop] then
			warn("ShopSystem: Item " .. itemId .. " missing required property: " .. prop)
			return false
		end
	end

	-- Validate data types
	if type(item.price) ~= "number" or item.price < 0 then
		warn("ShopSystem: Item " .. itemId .. " has invalid price: " .. tostring(item.price))
		return false
	end

	if type(item.currency) ~= "string" or (item.currency ~= "coins" and item.currency ~= "farmTokens") then
		warn("ShopSystem: Item " .. itemId .. " has invalid currency: " .. tostring(item.currency))
		return false
	end

	if type(item.category) ~= "string" then
		warn("ShopSystem: Item " .. itemId .. " has invalid category: " .. tostring(item.category))
		return false
	end

	-- Validate special properties for specific item types
	if item.type == "seed" then
		if not item.farmingData then
			warn("ShopSystem: Seed item " .. itemId .. " missing farmingData")
			return false
		end
		if not item.farmingData.growTime or not item.farmingData.resultCropId then
			warn("ShopSystem: Seed item " .. itemId .. " missing essential farmingData properties")
			return false
		end
	end
	-- Validate cow-specific properties
	if item.type == "cow" or item.type == "cow_upgrade" then
		if not item.cowData then
			warn("ShopSystem: Cow item " .. itemId .. " missing cowData")
			return false
		end

		local cowData = item.cowData
		if not cowData.tier or not cowData.milkAmount or not cowData.cooldown then
			warn("ShopSystem: Cow item " .. itemId .. " missing essential cowData properties")
			return false
		end

		if item.type == "cow_upgrade" and not cowData.upgradeFrom then
			warn("ShopSystem: Cow upgrade item " .. itemId .. " missing upgradeFrom property")
			return false
		end
	end

	print("ShopSystem: ✅ Cow Integration Module loaded!")
	print("🐄 NEW FEATURES:")
	print("  🛒 Cow purchase and upgrade handling")
	print("  ✅ Cow capacity and tier validation")
	print("  🌿 Pasture expansion processing")
	print("  🤖 Auto-milker and tool purchases")
	print("  🔧 Enhanced cow-specific validation")
	return true
end

function ShopSystem:CreateEnhancedItemCopy(item, itemId, playerData)
	-- Start with essential properties
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

	-- Copy all additional properties safely
	for key, value in pairs(item) do
		if not itemCopy[key] and key ~= "farmingData" then -- Handle farmingData specially
			if type(value) == "table" then
				itemCopy[key] = self:DeepCopyTable(value)
			else
				itemCopy[key] = value
			end
		end
	end

	-- Handle farmingData for seeds
	if item.farmingData then
		itemCopy.farmingData = self:DeepCopyTable(item.farmingData)
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

function ShopSystem:GetPlayerStock(playerData, itemId)
	-- Check various inventory locations for existing stock
	local locations = {
		{"farming", "inventory"},
		{"livestock", "inventory"},
		{"defense", "chickens", "feed"},
		{"defense", "pestControl"},
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
			return inventory[itemId]
		end
	end

	return 0
end

-- ========== ENHANCED PURCHASE SYSTEM ==========

function ShopSystem:HandlePurchase(player, itemId, quantity)
	print("🛒 ShopSystem: ENHANCED Purchase request - " .. player.Name .. " wants " .. quantity .. "x " .. itemId)

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

	-- Enhanced validation
	local canPurchase, reason = self:ValidatePurchaseEnhanced(player, playerData, item, quantity)
	if not canPurchase then
		self:SendNotification(player, "Cannot Purchase", reason, "error")
		return false
	end

	-- Process purchase with enhanced handling
	local success = self:ProcessPurchaseEnhanced(player, playerData, item, quantity)
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


function ShopSystem:ValidatePurchaseEnhanced(player, playerData, item, quantity)
	-- Check if player can afford it
	if not self:CanPlayerAfford(playerData, item, quantity) then
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

		if item.requiresFarmPlot then
			return false, "Requires farm plot! Buy 'Your First Farm Plot' first."
		end

		return false, "Requirements not met!"
	end

	-- Check quantity limits
	if item.maxQuantity and item.maxQuantity == 1 then
		if self:IsAlreadyOwned(playerData, item.id) then
			return false, "Already purchased!"
		end
	end

	-- Check specific item type requirements
	if item.type == "seed" and item.requiresFarmPlot then
		local hasPlots = playerData.farming and playerData.farming.plots and playerData.farming.plots > 0
		if not hasPlots then
			return false, "Seeds require a farm plot! Buy a farm plot first."
		end
	end

	-- COW-SPECIFIC VALIDATION
	if item.type == "cow" or item.type == "cow_upgrade" then
		local canPurchase, reason = self:ValidateCowPurchase(player, playerData, item, quantity)
		if not canPurchase then
			return false, reason
		end
	end

	-- Check stock limits (if any)
	if item.stockLimit then
		local purchased = self:GetPurchaseCount(playerData, item.id)
		if purchased + quantity > item.stockLimit then
			return false, "Not enough stock available!"
		end
	end

	return true, "Can purchase"
end
function ShopSystem:ProcessPurchaseEnhanced(player, playerData, item, quantity)
	local success, error = pcall(function()
		-- Calculate total cost
		local totalCost = item.price * quantity
		local currency = item.currency

		-- Deduct currency
		local oldAmount = playerData[currency] or 0
		playerData[currency] = oldAmount - totalCost

		-- Process by item type with enhanced handling
		local processed = false

		if item.type == "seed" then
			processed = self:ProcessSeedPurchaseEnhanced(player, playerData, item, quantity)
		elseif item.type == "farmPlot" then
			processed = self:ProcessFarmPlotPurchaseEnhanced(player, playerData, item, quantity)
		elseif item.type == "upgrade" then
			processed = self:ProcessUpgradePurchaseEnhanced(player, playerData, item, quantity)
		elseif item.type == "chicken" then
			processed = self:ProcessChickenPurchaseEnhanced(player, playerData, item, quantity)
		elseif item.type == "feed" then
			processed = self:ProcessFeedPurchaseEnhanced(player, playerData, item, quantity)
		elseif item.type == "tool" then
			processed = self:ProcessToolPurchaseEnhanced(player, playerData, item, quantity)
		elseif item.type == "building" then
			processed = self:ProcessBuildingPurchase(player, playerData, item, quantity)
		elseif item.type == "access" then
			processed = self:ProcessAccessPurchase(player, playerData, item, quantity)
		elseif item.type == "enhancement" then
			processed = self:ProcessEnhancementPurchase(player, playerData, item, quantity)
		elseif item.type == "cow" or item.type == "cow_upgrade" then
			
			processed = self:ProcessCowPurchase(player, playerData, item, quantity)
		elseif item.type == "protection" then
			processed = self:ProcessProtectionPurchase(player, playerData, item, quantity)
		else
			processed = self:ProcessGenericPurchaseEnhanced(player, playerData, item, quantity)
		end

		if not processed then
			-- Refund on failure
			playerData[currency] = oldAmount
			error("Item processing failed for type: " .. (item.type or "unknown"))
		end

		-- Mark as purchased for single-purchase items
		if item.maxQuantity == 1 then
			playerData.purchaseHistory = playerData.purchaseHistory or {}
			playerData.purchaseHistory[item.id] = true
		end

		-- Update purchase count for multi-purchase items
		if item.maxQuantity and item.maxQuantity > 1 then
			playerData.purchaseHistory = playerData.purchaseHistory or {}
			local currentCount = playerData.purchaseHistory[item.id] or 0
			playerData.purchaseHistory[item.id] = currentCount + quantity
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

-- ========== ENHANCED ITEM TYPE PROCESSORS ==========

function ShopSystem:ProcessSeedPurchaseEnhanced(player, playerData, item, quantity)
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

	-- Add starter bonus for first seed purchase
	if currentAmount == 0 and item.farmingData then
		-- Give a small bonus of basic fertilizer or booster
		playerData.boosters = playerData.boosters or {}
		if not playerData.boosters.first_seed_bonus then
			playerData.boosters.first_seed_bonus = true
			print("ShopSystem: Applied first seed purchase bonus for " .. player.Name)
		end
	end

	return true
end

function ShopSystem:ProcessFarmPlotPurchaseEnhanced(player, playerData, item, quantity)
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
				print("ShopSystem: Added starter seed: " .. seedId .. " x" .. amount)
			end
		end

		-- Create the first farm plot
		local success = self.GameCore:CreatePlayerFarmPlot(player, 1)
		if success then
			print("ShopSystem: Created first farm plot for " .. player.Name)
		end
		return success

	elseif item.id == "farm_plot_expansion" then
		-- Additional farm plots
		local currentPlots = playerData.farming and playerData.farming.plots or 0
		local newPlotNumber = currentPlots + quantity

		if newPlotNumber > 10 then
			return false
		end

		playerData.farming = playerData.farming or {}
		playerData.farming.plots = newPlotNumber

		-- Create the new plots
		for i = currentPlots + 1, newPlotNumber do
			local success = self.GameCore:CreatePlayerFarmPlot(player, i)
			if success then
				print("ShopSystem: Created farm plot " .. i .. " for " .. player.Name)
			else
				warn("ShopSystem: Failed to create farm plot " .. i .. " for " .. player.Name)
			end
		end
		return true
	end

	return false
end

function ShopSystem:ProcessChickenPurchaseEnhanced(player, playerData, item, quantity)
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

	-- Add chickens to inventory
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

	print("ShopSystem: Added " .. quantity .. "x " .. item.id .. " chickens for " .. player.Name)
	return true
end

function ShopSystem:ProcessFeedPurchaseEnhanced(player, playerData, item, quantity)
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

	print("ShopSystem: Added " .. quantity .. "x " .. item.id .. " to feed inventory")
	return true
end

function ShopSystem:ProcessBuildingPurchase(player, playerData, item, quantity)
	-- Initialize buildings data
	if not playerData.buildings then
		playerData.buildings = {}
	end

	playerData.buildings[item.id] = {
		purchaseTime = os.time(),
		level = 1,
		uses = 0
	}

	print("ShopSystem: Added building " .. item.id .. " for " .. player.Name)
	return true
end

function ShopSystem:ProcessAccessPurchase(player, playerData, item, quantity)
	-- Initialize access data
	if not playerData.access then
		playerData.access = {}
	end

	playerData.access[item.id] = {
		purchaseTime = os.time(),
		unlocked = true
	}

	-- Special handling for cave access
	if item.effects and item.effects.unlocksCave then
		if not playerData.mining then
			playerData.mining = {caves = {}, tools = {}, level = 1, xp = 0}
		end
		if not playerData.mining.caves then
			playerData.mining.caves = {}
		end

		playerData.mining.caves[item.effects.unlocksCave] = {
			unlocked = true,
			firstVisit = false
		}
	end

	print("ShopSystem: Granted access " .. item.id .. " for " .. player.Name)
	return true
end

function ShopSystem:ProcessEnhancementPurchase(player, playerData, item, quantity)
	-- Initialize boosters data
	if not playerData.boosters then
		playerData.boosters = {}
	end

	if item.effects then
		if item.effects.guaranteedRarity then
			playerData.boosters.rarity_booster = (playerData.boosters.rarity_booster or 0) + (item.effects.uses or 1) * quantity
		elseif item.effects.rarityBoost then
			playerData.boosters.rarity_boost_active = {
				multiplier = item.effects.rarityBoost,
				duration = item.effects.duration or 600,
				startTime = os.time()
			}
		end
	end

	print("ShopSystem: Applied enhancement " .. item.id .. " for " .. player.Name)
	return true
end

function ShopSystem:ProcessProtectionPurchase(player, playerData, item, quantity)
	-- Initialize protection data
	if not playerData.defense then
		playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}, pestControl = {}, roofs = {}}
	end
	if not playerData.defense.roofs then
		playerData.defense.roofs = {}
	end

	playerData.defense.roofs[item.id] = {
		purchaseTime = os.time(),
		coverage = item.effects and item.effects.coverage or 1,
		protection = item.effects and item.effects.ufoProtection or false
	}

	print("ShopSystem: Added protection " .. item.id .. " for " .. player.Name)
	return true
end

function ShopSystem:ProcessGenericPurchaseEnhanced(player, playerData, item, quantity)
	-- Generic item processing with better categorization
	if not playerData.inventory then
		playerData.inventory = {}
	end

	local currentAmount = playerData.inventory[item.id] or 0
	playerData.inventory[item.id] = currentAmount + quantity

	print("ShopSystem: Added " .. quantity .. "x " .. item.id .. " to general inventory")
	return true
end

function ShopSystem:IsToolBetter(newTool, currentTool)
	local toolRanks = {
		basic_pickaxe = 1,
		stone_pickaxe = 2,
		iron_pickaxe = 3,
		diamond_pickaxe = 4,
		obsidian_pickaxe = 5
	}

	return (toolRanks[newTool] or 0) > (toolRanks[currentTool] or 0)
end

-- ========== ENHANCED SELLING SYSTEM ==========

function ShopSystem:HandleSell(player, itemId, quantity)
	print("💰 ShopSystem: ENHANCED Sell request - " .. player.Name .. " wants to sell " .. quantity .. "x " .. itemId)

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Sell Error", "Player data not found", "error")
		return false
	end

	-- Find the item in player's inventory with enhanced search
	local availableQuantity, inventoryPath = self:FindPlayerItemEnhanced(playerData, itemId)

	if availableQuantity < quantity then
		self:SendNotification(player, "Not Enough Items", 
			"You only have " .. availableQuantity .. "x " .. self:GetItemDisplayName(itemId) .. "!", "error")
		return false
	end

	-- Get enhanced sell price with rarity consideration
	local sellPrice, sellCurrency = self:GetItemSellPriceEnhanced(itemId, playerData)
	if not sellPrice or sellPrice <= 0 then
		self:SendNotification(player, "Cannot Sell", "This item cannot be sold!", "error")
		return false
	end

	-- Process sale with enhanced handling
	local success = self:ProcessSaleEnhanced(player, playerData, itemId, quantity, sellPrice, sellCurrency, inventoryPath)

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

function ShopSystem:FindPlayerItemEnhanced(playerData, itemId)
	local inventoryLocations = {
		{path = {"farming", "inventory"}, name = "farming"},
		{path = {"livestock", "inventory"}, name = "livestock"},
		{path = {"defense", "chickens", "feed"}, name = "feed"},
		{path = {"defense", "pestControl"}, name = "pestControl"},
		{path = {"inventory"}, name = "general"},
		{path = {"mining", "inventory"}, name = "mining"}
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

function ShopSystem:GetItemSellPriceEnhanced(itemId, playerData)
	-- Enhanced sell prices with rarity consideration
	local baseSellPrices = {
		-- Crops
		carrot = {price = 15, currency = "coins"},
		corn = {price = 25, currency = "coins"},
		strawberry = {price = 40, currency = "coins"},
		wheat = {price = 20, currency = "coins"},
		potato = {price = 18, currency = "coins"},
		cabbage = {price = 22, currency = "coins"},
		radish = {price = 12, currency = "coins"},
		broccoli = {price = 35, currency = "coins"},
		tomato = {price = 30, currency = "coins"},
		golden_fruit = {price = 100, currency = "coins"},
		glorious_sunflower = {price = 500, currency = "farmTokens"},

		-- Animal products
		milk = {price = 75, currency = "coins"},
		fresh_milk = {price = 75, currency = "coins"},
		chicken_egg = {price = 5, currency = "coins"},
		guinea_egg = {price = 8, currency = "coins"},
		rooster_egg = {price = 12, currency = "coins"},

		-- Ores
		copper_ore = {price = 30, currency = "coins"},
		bronze_ore = {price = 35, currency = "coins"},
		iron_ore = {price = 50, currency = "coins"},
		silver_ore = {price = 75, currency = "coins"},
		gold_ore = {price = 100, currency = "coins"},
		platinum_ore = {price = 150, currency = "coins"},
		diamond_ore = {price = 200, currency = "coins"},
		obsidian_ore = {price = 500, currency = "coins"}
	}

	local priceData = baseSellPrices[itemId] or {price = 10, currency = "coins"}

	-- Apply rarity multiplier if applicable
	if itemId:find("_rare") or itemId:find("_epic") or itemId:find("_legendary") then
		local rarityMultiplier = 1.0
		if itemId:find("_rare") then rarityMultiplier = 1.5
		elseif itemId:find("_epic") then rarityMultiplier = 2.0
		elseif itemId:find("_legendary") then rarityMultiplier = 3.0
		end

		priceData.price = math.floor(priceData.price * rarityMultiplier)
	end

	return priceData.price, priceData.currency
end

function ShopSystem:ProcessSaleEnhanced(player, playerData, itemId, quantity, sellPrice, sellCurrency, inventoryPath)
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

		-- Update enhanced stats
		playerData.stats = playerData.stats or {}
		playerData.stats.itemsSold = (playerData.stats.itemsSold or 0) + quantity
		playerData.stats.coinsEarned = (playerData.stats.coinsEarned or 0) + (sellCurrency == "coins" and totalEarnings or 0)
		playerData.stats.farmTokensEarned = (playerData.stats.farmTokensEarned or 0) + (sellCurrency == "farmTokens" and totalEarnings or 0)

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

-- ========== COW PURCHASE PROCESSORS ==========

function ShopSystem:ProcessCowPurchase(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing cow purchase - " .. item.id)

	if not self.GameCore then
		warn("ShopSystem: GameCore not available for cow purchase")
		return false
	end

	-- Validate cow purchase
	local canPurchase, reason = self:ValidateCowPurchase(player, playerData, item, quantity)
	if not canPurchase then
		self:SendNotification(player, "Cannot Purchase Cow", reason, "error")
		return false
	end

	-- Process based on cow type
	if item.type == "cow" then
		return self:ProcessNewCowPurchase(player, playerData, item, quantity)
	elseif item.type == "cow_upgrade" then
		return self:ProcessCowUpgradePurchase(player, playerData, item, quantity)
	end

	return false
end

function ShopSystem:ProcessNewCowPurchase(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing new cow purchase")

	-- Initialize livestock data if needed
	if not playerData.livestock then
		playerData.livestock = {cows = {}}
	end
	if not playerData.livestock.cows then
		playerData.livestock.cows = {}
	end

	local successCount = 0

	-- Purchase each cow
	for i = 1, quantity do
		local success = self.GameCore:PurchaseCow(player, item.id, nil)
		if success then
			successCount = successCount + 1
		else
			break -- Stop on first failure
		end
	end

	if successCount > 0 then
		print("🐄 ShopSystem: Successfully purchased " .. successCount .. " cows")
		return true
	end

	return false
end

function ShopSystem:ProcessCowUpgradePurchase(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing cow upgrade purchase")

	-- Find eligible cows for upgrade
	local eligibleCows = self:FindEligibleCowsForUpgrade(playerData, item)

	if #eligibleCows == 0 then
		local upgradeFrom = item.cowData and item.cowData.upgradeFrom or "unknown"
		self:SendNotification(player, "No Eligible Cows", 
			"You need a " .. upgradeFrom .. " cow to upgrade to " .. item.cowData.tier .. "!", "error")
		return false
	end

	if #eligibleCows < quantity then
		self:SendNotification(player, "Not Enough Cows", 
			"You only have " .. #eligibleCows .. " eligible cows for this upgrade!", "error")
		return false
	end

	local successCount = 0

	-- Upgrade cows
	for i = 1, quantity do
		local cowId = eligibleCows[i]
		local success = self.GameCore:PurchaseCow(player, item.id, cowId)
		if success then
			successCount = successCount + 1
		else
			break
		end
	end

	if successCount > 0 then
		print("🐄 ShopSystem: Successfully upgraded " .. successCount .. " cows")
		return true
	end

	return false
end

-- ========== COW VALIDATION ==========

function ShopSystem:ValidateCowPurchase(player, playerData, item, quantity)
	-- Check if player has farm plots
	if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
		return false, "You need a farm plot first! Buy 'Your First Farm Plot' from the shop."
	end

	-- Check cow capacity
	local currentCowCount = self:GetPlayerCowCount(playerData)
	local maxCows = self:GetPlayerMaxCows(playerData)

	if item.type == "cow" then
		-- New cow purchase
		if currentCowCount + quantity > maxCows then
			return false, "Cow limit reached! You have " .. currentCowCount .. "/" .. maxCows .. " cows. Buy pasture expansions for more space."
		end

		-- Check specific cow requirements
		if item.id == "extra_basic_cow" then
			if not self:PlayerOwnsCow(playerData, "basic") then
				return false, "You need to buy a Basic Cow first!"
			end
		end

	elseif item.type == "cow_upgrade" then
		-- Cow upgrade
		local eligibleCows = self:FindEligibleCowsForUpgrade(playerData, item)
		if #eligibleCows < quantity then
			local upgradeFrom = item.cowData and item.cowData.upgradeFrom or "previous tier"
			return false, "You need " .. quantity .. "x " .. upgradeFrom .. " cows to upgrade! You have " .. #eligibleCows .. " eligible cows."
		end
	end

	return true, "Valid cow purchase"
end

function ShopSystem:FindEligibleCowsForUpgrade(playerData, upgradeItem)
	local eligibleCows = {}

	if not playerData.livestock or not playerData.livestock.cows then
		return eligibleCows
	end

	local upgradeFrom = upgradeItem.cowData and upgradeItem.cowData.upgradeFrom
	if not upgradeFrom then
		return eligibleCows
	end

	-- Find cows of the required tier
	for cowId, cowData in pairs(playerData.livestock.cows) do
		if cowData.tier == upgradeFrom then
			table.insert(eligibleCows, cowId)
		end
	end

	return eligibleCows
end

function ShopSystem:GetPlayerCowCount(playerData)
	if not playerData.livestock or not playerData.livestock.cows then
		return 0
	end

	local count = 0
	for _ in pairs(playerData.livestock.cows) do
		count = count + 1
	end
	return count
end

function ShopSystem:GetPlayerMaxCows(playerData)
	local baseCows = 5
	local bonusCows = 0

	if playerData.upgrades then
		if playerData.upgrades.pasture_expansion_1 then bonusCows = bonusCows + 2 end
		if playerData.upgrades.pasture_expansion_2 then bonusCows = bonusCows + 3 end
		if playerData.upgrades.mega_pasture then bonusCows = bonusCows + 5 end
	end

	return baseCows + bonusCows
end

function ShopSystem:PlayerOwnsCow(playerData, tierOrType)
	if not playerData.livestock or not playerData.livestock.cows then
		return false
	end

	for cowId, cowData in pairs(playerData.livestock.cows) do
		if cowData.tier == tierOrType or cowId:find(tierOrType) then
			return true
		end
	end

	return false
end

-- ========== ENHANCED ITEM PROCESSOR ==========

-- REPLACE the existing ProcessToolPurchaseEnhanced function with this enhanced version:

function ShopSystem:ProcessToolPurchaseEnhanced(player, playerData, item, quantity)
	-- Handle cow-related tools
	if item.id == "cow_relocator" then
		return self:ProcessCowRelocatorPurchase(player, playerData, item, quantity)
	elseif item.id == "cow_feed_premium" then
		return self:ProcessPremiumFeedPurchase(player, playerData, item, quantity)
	elseif item.id == "auto_milker" then
		return self:ProcessAutoMilkerPurchase(player, playerData, item, quantity)
	end

	-- Determine where to store the tool based on its purpose
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
	elseif item.id:find("pickaxe") then
		-- Mining tools
		if not playerData.mining then
			playerData.mining = {tools = {}, level = 1, xp = 0}
		end
		if not playerData.mining.tools then
			playerData.mining.tools = {}
		end

		playerData.mining.tools[item.id] = {
			durability = item.toolData and item.toolData.durability or 100,
			purchaseTime = os.time()
		}

		-- Set as active tool if it's the first/best tool
		if not playerData.mining.activeTool or self:IsToolBetter(item.id, playerData.mining.activeTool) then
			playerData.mining.activeTool = item.id
		end
	else
		-- General tools
		if not playerData.inventory then
			playerData.inventory = {}
		end
		local currentAmount = playerData.inventory[item.id] or 0
		playerData.inventory[item.id] = currentAmount + quantity
	end

	print("ShopSystem: Added " .. quantity .. "x " .. item.id .. " tool(s)")
	return true
end

-- ========== COW TOOL PROCESSORS ==========

function ShopSystem:ProcessCowRelocatorPurchase(player, playerData, item, quantity)
	-- Initialize tools inventory
	if not playerData.tools then
		playerData.tools = {}
	end

	local currentAmount = playerData.tools.cow_relocator or 0
	playerData.tools.cow_relocator = currentAmount + quantity

	print("ShopSystem: Added " .. quantity .. "x cow relocator tools")
	return true
end

function ShopSystem:ProcessPremiumFeedPurchase(player, playerData, item, quantity)
	-- Initialize livestock feed storage
	if not playerData.livestock then
		playerData.livestock = {cows = {}, feed = {}}
	end
	if not playerData.livestock.feed then
		playerData.livestock.feed = {}
	end

	local currentAmount = playerData.livestock.feed.premium_feed or 0
	playerData.livestock.feed.premium_feed = currentAmount + quantity

	print("ShopSystem: Added " .. quantity .. "x premium cow feed")
	return true
end

function ShopSystem:ProcessAutoMilkerPurchase(player, playerData, item, quantity)
	-- Auto milker is a one-time upgrade
	playerData.upgrades = playerData.upgrades or {}
	playerData.upgrades.auto_milker = true

	print("ShopSystem: Granted auto milker upgrade to " .. player.Name)
	return true
end

-- ========== PASTURE EXPANSION PROCESSOR ==========

-- REPLACE the existing ProcessUpgradePurchaseEnhanced function with this enhanced version:

function ShopSystem:ProcessUpgradePurchaseEnhanced(player, playerData, item, quantity)
	playerData.upgrades = playerData.upgrades or {}

	-- Handle pasture expansions specially
	if item.id:find("pasture") then
		return self:ProcessPastureExpansion(player, playerData, item, quantity)
	end

	if item.maxQuantity == 1 then
		-- Single purchase upgrade
		playerData.upgrades[item.id] = true
	else
		-- Stackable upgrade
		local currentLevel = playerData.upgrades[item.id] or 0
		playerData.upgrades[item.id] = currentLevel + quantity
	end

	print("ShopSystem: Applied upgrade " .. item.id .. " for " .. player.Name)
	return true
end

function ShopSystem:ProcessPastureExpansion(player, playerData, item, quantity)
	playerData.upgrades = playerData.upgrades or {}
	playerData.upgrades[item.id] = true

	-- Apply the capacity increase
	local increase = item.effects and item.effects.maxCowIncrease or 0
	local currentCapacity = self:GetPlayerMaxCows(playerData)
	local newCapacity = currentCapacity + increase

	self:SendNotification(player, "🌿 Pasture Expanded!", 
		"Cow capacity increased from " .. currentCapacity .. " to " .. newCapacity .. " cows!", "success")

	print("ShopSystem: Expanded pasture for " .. player.Name .. " - new capacity: " .. newCapacity)
	return true
end
-- ========== ENHANCED VALIDATION HELPERS ==========

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

function ShopSystem:GetShopItemById(itemId)
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		return nil
	end
	return self.ItemConfig.ShopItems[itemId]
end

-- ========== UTILITY FUNCTIONS ==========

function ShopSystem:GetItemDisplayName(itemId)
	local displayNames = {
		carrot = "🥕 Carrot",
		corn = "🌽 Corn",
		strawberry = "🍓 Strawberry",
		wheat = "🌾 Wheat",
		potato = "🥔 Potato",
		cabbage = "🥬 Cabbage",
		radish = "🌶️ Radish",
		broccoli = "🥦 Broccoli",
		tomato = "🍅 Tomato",
		golden_fruit = "✨ Golden Fruit",
		glorious_sunflower = "🌻 Glorious Sunflower",
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

-- ========== ENHANCED VALIDATION AND DEBUG ==========

function ShopSystem:ValidateShopData()
	print("ShopSystem: Validating ENHANCED shop data...")

	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		error("ShopSystem: ItemConfig.ShopItems not available!")
	end

	local validItems = 0
	local invalidItems = 0
	local categories = {}
	local types = {}

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if self:ValidateItemEnhanced(item, itemId) then
			validItems = validItems + 1
			local category = item.category or "unknown"
			local itemType = item.type or "unknown"
			categories[category] = (categories[category] or 0) + 1
			types[itemType] = (types[itemType] or 0) + 1
		else
			invalidItems = invalidItems + 1
		end
	end

	print("ShopSystem: Enhanced validation complete")
	print("  ✅ Valid items: " .. validItems)
	print("  ❌ Invalid items: " .. invalidItems)
	print("  📊 Categories:")
	for category, count in pairs(categories) do
		print("    " .. category .. ": " .. count .. " items")
	end
	print("  🔖 Types:")
	for itemType, count in pairs(types) do
		print("    " .. itemType .. ": " .. count .. " items")
	end

	if invalidItems > 0 then
		warn("ShopSystem: " .. invalidItems .. " invalid items found!")
	end

	return invalidItems == 0
end

function ShopSystem:DebugShopSystem(player)
	print("=== ENHANCED SHOP SYSTEM DEBUG ===")
	print("ItemConfig loaded:", self.ItemConfig ~= nil)
	print("GameCore reference:", self.GameCore ~= nil)
	print("RemoteFunctions connected:", self:CountTable(self.RemoteFunctions))
	print("RemoteEvents connected:", self:CountTable(self.RemoteEvents))

	if self.ItemConfig and self.ItemConfig.ShopItems then
		local itemCount = 0
		local categoryCount = {}
		local typeCount = {}

		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			itemCount = itemCount + 1
			local cat = item.category or "unknown"
			local typ = item.type or "unknown"
			categoryCount[cat] = (categoryCount[cat] or 0) + 1
			typeCount[typ] = (typeCount[typ] or 0) + 1
		end

		print("Total items:", itemCount)
		print("Categories:")
		for cat, count in pairs(categoryCount) do
			print("  " .. cat .. ": " .. count)
		end
		print("Types:")
		for typ, count in pairs(typeCount) do
			print("  " .. typ .. ": " .. count)
		end
	end

	-- Test the GetShopItems function
	if player then
		local items = self:HandleGetShopItems(player)
		print("GetShopItems test:", #items .. " items returned")

		local categoryBreakdown = {}
		for _, item in ipairs(items) do
			categoryBreakdown[item.category] = (categoryBreakdown[item.category] or 0) + 1
		end

		print("Returned items by category:")
		for cat, count in pairs(categoryBreakdown) do
			print("  " .. cat .. ": " .. count)
		end
	end

	print("=====================================")
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

print("ShopSystem: ✅ ENHANCED shop management module loaded!")
print("🌟 NEW FEATURES:")
print("  📦 Complete ItemConfig integration with ALL items")
print("  🔍 Enhanced item validation and error detection")
print("  🛠️ Support for all item types (seeds, tools, buildings, etc.)")
print("  💰 Enhanced selling system with rarity support")
print("  📊 Detailed debugging and category breakdown")
print("  🎯 Better purchase validation and error messages")
print("  🔧 Enhanced item processors for each type")

return ShopSystem