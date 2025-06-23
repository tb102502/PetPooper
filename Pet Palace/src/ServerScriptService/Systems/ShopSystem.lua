--[[
    FIXED ShopSystem.lua - Robux Support & Enhanced Error Handling
    
    FIXES:
    ✅ Added Robux currency support for premium items
    ✅ Enhanced cow purchase validation and processing
    ✅ Better error handling and debugging
    ✅ Fixed ItemConfig integration issues
    ✅ Added proper free item handling (price = 0)
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

-- Purchase cooldowns and Robux handling
ShopSystem.PurchaseCooldowns = {}
ShopSystem.PURCHASE_COOLDOWN = 1
ShopSystem.RobuxProducts = {} -- Store Robux product IDs

-- ========== INITIALIZATION ==========

function ShopSystem:Initialize(gameCore)
	print("ShopSystem: Initializing FIXED shop system with Robux support...")

	self.GameCore = gameCore

	-- Load ItemConfig with better error handling
	local success, itemConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
	end)

	if success and itemConfig then
		self.ItemConfig = itemConfig
		print("ShopSystem: ✅ ItemConfig loaded successfully")
		self:DebugItemConfig()
	else
		error("ShopSystem: Failed to load ItemConfig: " .. tostring(itemConfig))
	end

	-- Setup Robux products
	self:InitializeRobuxProducts()

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Setup remote handlers
	self:SetupRemoteHandlers()

	-- Validate shop data
	self:ValidateShopData()

	print("ShopSystem: ✅ FIXED shop system initialization complete")
	return true
end

function ShopSystem:InitializeRobuxProducts()
	print("ShopSystem: Initializing Robux product integration...")

	-- Define Robux products for premium items
	self.RobuxProducts = {
		auto_harvester = 1234567890, -- Replace with actual Developer Product IDs
		rarity_booster = 1234567891,
		mega_dome = 1234567892,
		cosmic_cow_upgrade = 1234567893,
		cow_feed_premium = 1234567894,
		auto_milker = 1234567895,
		mega_pasture = 1234567896
	}

	-- Setup MarketplaceService for Robux purchases
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessRobuxPurchase(receiptInfo)
	end

	print("ShopSystem: Robux products initialized")
end

-- ========== ENHANCED PURCHASE SYSTEM ==========

function ShopSystem:HandlePurchase(player, itemId, quantity)
	print("🛒 ShopSystem: FIXED Purchase request - " .. player.Name .. " wants " .. quantity .. "x " .. itemId)

	-- Check purchase cooldown
	local userId = player.UserId
	local currentTime = os.time()
	local lastPurchase = self.PurchaseCooldowns[userId] or 0

	if currentTime - lastPurchase < self.PURCHASE_COOLDOWN then
		self:SendNotification(player, "Purchase Cooldown", "Please wait before making another purchase!", "warning")
		return false
	end

	-- Get item data with enhanced error handling
	local item = self:GetShopItemById(itemId)
	if not item then
		self:SendNotification(player, "Invalid Item", "Item not found: " .. itemId, "error")
		warn("ShopSystem: Item not found in ItemConfig: " .. itemId)
		return false
	end

	print("🛒 ShopSystem: Found item - " .. item.name .. " (price: " .. item.price .. " " .. item.currency .. ")")

	-- Handle Robux purchases differently
	if item.currency == "Robux" then
		return self:HandleRobuxPurchase(player, item, quantity)
	end

	-- Get player data
	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Player Data Error", "Could not load player data!", "error")
		warn("ShopSystem: Could not get player data for " .. player.Name)
		return false
	end

	-- Enhanced validation
	local canPurchase, reason = self:ValidatePurchaseEnhanced(player, playerData, item, quantity)
	if not canPurchase then
		self:SendNotification(player, "Cannot Purchase", reason, "error")
		print("🛒 ShopSystem: Purchase validation failed - " .. reason)
		return false
	end

	-- Process purchase with enhanced handling
	local success, errorMsg = pcall(function()
		return self:ProcessPurchaseEnhanced(player, playerData, item, quantity)
	end)

	if success and errorMsg then
		-- Update cooldown
		self.PurchaseCooldowns[userId] = currentTime

		-- Send confirmation
		self:SendPurchaseConfirmation(player, item, quantity)

		print("🛒 ShopSystem: Purchase successful - " .. player.Name .. " bought " .. quantity .. "x " .. itemId)
		return true
	else
		local error = success and "Unknown error" or tostring(errorMsg)
		self:SendNotification(player, "Purchase Failed", "Transaction failed: " .. error, "error")
		warn("🛒 ShopSystem: Purchase failed for " .. player.Name .. " - " .. error)
		return false
	end
end

-- ========== ROBUX PURCHASE HANDLING ==========

function ShopSystem:HandleRobuxPurchase(player, item, quantity)
	print("💎 ShopSystem: Processing Robux purchase - " .. item.id)

	local productId = self.RobuxProducts[item.id]
	if not productId then
		self:SendNotification(player, "Robux Error", "This premium item is not available for purchase yet!", "error")
		return false
	end

	-- Validate requirements (non-currency)
	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if playerData then
		local meetsReqs = self:MeetsRequirements(playerData, item)
		if not meetsReqs then
			if item.requiresPurchase then
				local reqItem = self:GetShopItemById(item.requiresPurchase)
				local reqName = reqItem and reqItem.name or item.requiresPurchase
				self:SendNotification(player, "Requirements Not Met", "Requires: " .. reqName, "error")
				return false
			end
		end
	end

	-- Store pending purchase info
	if not self.PendingRobuxPurchases then
		self.PendingRobuxPurchases = {}
	end

	self.PendingRobuxPurchases[player.UserId] = {
		itemId = item.id,
		quantity = quantity,
		timestamp = os.time()
	}

	-- Prompt Robux purchase
	local success, error = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)

	if not success then
		self:SendNotification(player, "Purchase Error", "Could not open Robux purchase dialog!", "error")
		warn("ShopSystem: Failed to prompt Robux purchase: " .. tostring(error))
		self.PendingRobuxPurchases[player.UserId] = nil
		return false
	end

	print("💎 ShopSystem: Robux purchase dialog opened for " .. player.Name)
	return true
end

function ShopSystem:ProcessRobuxPurchase(receiptInfo)
	print("💎 ShopSystem: Processing Robux receipt for player " .. receiptInfo.PlayerId)

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		warn("ShopSystem: Player not found for Robux receipt")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Find the item by product ID
	local itemId = nil
	for id, productId in pairs(self.RobuxProducts) do
		if productId == receiptInfo.ProductId then
			itemId = id
			break
		end
	end

	if not itemId then
		warn("ShopSystem: Unknown product ID in receipt: " .. receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Get pending purchase info
	local pendingPurchase = self.PendingRobuxPurchases and self.PendingRobuxPurchases[receiptInfo.PlayerId]
	local quantity = pendingPurchase and pendingPurchase.quantity or 1

	-- Clear pending purchase
	if self.PendingRobuxPurchases then
		self.PendingRobuxPurchases[receiptInfo.PlayerId] = nil
	end

	-- Get item and player data
	local item = self:GetShopItemById(itemId)
	if not item then
		warn("ShopSystem: Item not found for Robux purchase: " .. itemId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		warn("ShopSystem: Player data not found for Robux purchase")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Process the premium item (no currency deduction needed)
	local success, error = pcall(function()
		return self:ProcessRobuxItemGrant(player, playerData, item, quantity)
	end)

	if success and error then
		self:SendPurchaseConfirmation(player, item, quantity)
		print("💎 ShopSystem: Robux purchase completed successfully")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("ShopSystem: Failed to process Robux item grant: " .. tostring(error))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end
function ShopSystem:ProcessPurchaseEnhanced(player, playerData, item, quantity)
	local success, error = pcall(function()
		-- Calculate total cost
		local totalCost = item.price * quantity
		local currency = item.currency

		-- Deduct currency (skip for free items)
		if item.price > 0 then
			local oldAmount = playerData[currency] or 0
			playerData[currency] = oldAmount - totalCost
		end

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
			if item.price > 0 then
				playerData[currency] = (playerData[currency] or 0) + totalCost
			end
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

-- ========== ITEM TYPE PROCESSORS ==========

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

function ShopSystem:ProcessUpgradePurchaseEnhanced(player, playerData, item, quantity)
	playerData.upgrades = playerData.upgrades or {}

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

	-- Add chickens to inventory
	local HttpService = game:GetService("HttpService")
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

function ShopSystem:ProcessToolPurchaseEnhanced(player, playerData, item, quantity)
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
	-- Generic item processing
	if not playerData.inventory then
		playerData.inventory = {}
	end

	local currentAmount = playerData.inventory[item.id] or 0
	playerData.inventory[item.id] = currentAmount + quantity

	print("ShopSystem: Added " .. quantity .. "x " .. item.id .. " to general inventory")
	return true
end

-- ========== HELPER METHODS ==========

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


function ShopSystem:ProcessRobuxItemGrant(player, playerData, item, quantity)
	print("💎 ShopSystem: Granting Robux item - " .. item.id)

	-- Process by item type (no currency deduction)
	local processed = false

	if item.type == "cow" or item.type == "cow_upgrade" then
		processed = self:ProcessCowPurchase(player, playerData, item, quantity)
	elseif item.type == "upgrade" then
		processed = self:ProcessUpgradePurchaseEnhanced(player, playerData, item, quantity)
	elseif item.type == "enhancement" then
		processed = self:ProcessEnhancementPurchase(player, playerData, item, quantity)
	elseif item.type == "protection" then
		processed = self:ProcessProtectionPurchase(player, playerData, item, quantity)
	else
		processed = self:ProcessGenericPurchaseEnhanced(player, playerData, item, quantity)
	end

	if not processed then
		error("Failed to process Robux item: " .. item.id)
	end

	-- Mark as purchased
	if item.maxQuantity == 1 then
		playerData.purchaseHistory = playerData.purchaseHistory or {}
		playerData.purchaseHistory[item.id] = true
	end

	-- Save data
	if self.GameCore then
		self.GameCore:SavePlayerData(player)
		self.GameCore:UpdatePlayerLeaderstats(player)

		if self.GameCore.RemoteEvents and self.GameCore.RemoteEvents.PlayerDataUpdated then
			self.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end
	end

	return true
end

-- ========== ENHANCED COW PURCHASE VALIDATION ==========

function ShopSystem:ValidatePurchaseEnhanced(player, playerData, item, quantity)
	-- Check if player can afford it (skip for free items)
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

	-- COW-SPECIFIC VALIDATION with enhanced error messages
	if item.type == "cow" or item.type == "cow_upgrade" then
		local canPurchase, reason = self:ValidateCowPurchase(player, playerData, item, quantity)
		if not canPurchase then
			return false, reason
		end
	end

	return true, "Can purchase"
end

-- ========== ENHANCED COW PURCHASE PROCESSING ==========

--[[
    FIXED ShopSystem Cow Purchase Validation
    
    Add these methods to your existing ShopSystem.lua to fix cow purchase issues
    
    FIXES:
    ✅ Enhanced error handling for cow purchases
    ✅ Better validation before calling GameCore
    ✅ Improved debugging and error messages
    ✅ Safe fallback mechanisms
]]

-- ========== ENHANCED COW PURCHASE VALIDATION ==========

-- REPLACE your existing ProcessCowPurchase method with this fixed version:
function ShopSystem:ProcessCowPurchase(player, playerData, item, quantity)
	print("🐄 ShopSystem: ENHANCED cow purchase processing - " .. item.id)

	-- Step 1: Validate ShopSystem state
	if not self.GameCore then
		warn("🐄 ShopSystem: GameCore not available for cow purchase")
		self:SendNotification(player, "System Error", "Game core system not available!", "error")
		return false
	end

	-- Step 2: Enhanced cow item validation
	print("🐄 ShopSystem: Validating cow item...")
	local validation = self:ValidateCowItemExtensive(item)
	if not validation.valid then
		warn("🐄 ShopSystem: Cow item validation failed - " .. validation.reason)
		self:SendNotification(player, "Invalid Item", validation.reason, "error")
		return false
	end

	-- Step 3: Enhanced player validation
	print("🐄 ShopSystem: Validating player state...")
	local playerValidation = self:ValidatePlayerForCowPurchase(player, playerData, item, quantity)
	if not playerValidation.valid then
		warn("🐄 ShopSystem: Player validation failed - " .. playerValidation.reason)
		self:SendNotification(player, "Cannot Purchase", playerValidation.reason, "error")
		return false
	end

	-- Step 4: Process based on cow type with enhanced error handling
	local success = false
	local errorMsg = "Unknown error"

	if item.type == "cow" then
		success, errorMsg = self:ProcessNewCowPurchaseEnhanced(player, playerData, item, quantity)
	elseif item.type == "cow_upgrade" then
		success, errorMsg = self:ProcessCowUpgradePurchaseEnhanced(player, playerData, item, quantity)
	else
		errorMsg = "Unknown cow type: " .. (item.type or "nil")
	end

	if success then
		print("🐄 ShopSystem: Cow purchase processing completed successfully")
		return true
	else
		warn("🐄 ShopSystem: Cow purchase processing failed - " .. errorMsg)
		self:SendNotification(player, "Purchase Failed", errorMsg, "error")
		return false
	end
end

-- Enhanced cow item validation
function ShopSystem:ValidateCowItemExtensive(item)
	if not item then
		return {valid = false, reason = "Item is nil"}
	end

	if not item.id then
		return {valid = false, reason = "Item missing ID"}
	end

	if not item.type or (item.type ~= "cow" and item.type ~= "cow_upgrade") then
		return {valid = false, reason = "Item is not a cow type (got: " .. tostring(item.type) .. ")"}
	end

	if not item.cowData then
		return {valid = false, reason = "Item missing cowData for: " .. item.id}
	end

	local cowData = item.cowData
	if not cowData.tier then
		return {valid = false, reason = "Cow missing tier data"}
	end

	if not cowData.milkAmount or type(cowData.milkAmount) ~= "number" then
		return {valid = false, reason = "Cow missing or invalid milkAmount"}
	end

	if not cowData.cooldown or type(cowData.cooldown) ~= "number" then
		return {valid = false, reason = "Cow missing or invalid cooldown"}
	end

	if item.type == "cow_upgrade" and not cowData.upgradeFrom then
		return {valid = false, reason = "Cow upgrade missing upgradeFrom property"}
	end

	return {valid = true, reason = "Cow item is valid"}
end

-- Enhanced player validation for cow purchases
function ShopSystem:ValidatePlayerForCowPurchase(player, playerData, item, quantity)
	if not player or not player.Parent then
		return {valid = false, reason = "Player not in game"}
	end

	if not playerData then
		return {valid = false, reason = "Player data not found"}
	end

	-- For basic cow, be more lenient with requirements
	if item.id == "basic_cow" then
		print("🐄 ShopSystem: Basic cow validation - minimal requirements")
		return {valid = true, reason = "Basic cow approved"}
	end

	-- Validate farm requirements for non-basic cows
	if not playerData.farming then
		return {valid = false, reason = "You need a farm first! Buy 'Your First Farm Plot'."}
	end

	if not playerData.farming.plots or playerData.farming.plots <= 0 then
		return {valid = false, reason = "You need a farm plot first! Buy 'Your First Farm Plot'."}
	end

	-- Validate cow capacity
	if item.type == "cow" then
		local currentCowCount = self:GetPlayerCowCountSafe(playerData)
		local maxCows = self:GetPlayerMaxCowsSafe(playerData)

		if currentCowCount + quantity > maxCows then
			return {valid = false, reason = "Cow limit reached! You have " .. currentCowCount .. "/" .. maxCows .. " cows. Buy pasture expansions."}
		end
	elseif item.type == "cow_upgrade" then
		local eligibleCows = self:FindEligibleCowsForUpgrade(playerData, item)
		if #eligibleCows < quantity then
			local upgradeFrom = item.cowData.upgradeFrom or "previous tier"
			return {valid = false, reason = "You need " .. quantity .. "x " .. upgradeFrom .. " cows to upgrade!"}
		end
	end

	return {valid = true, reason = "Player validation passed"}
end

-- Enhanced new cow purchase processing
function ShopSystem:ProcessNewCowPurchaseEnhanced(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing new cow purchase with enhanced safety - " .. item.id)

	-- Initialize livestock data structure safely
	if not playerData.livestock then
		playerData.livestock = {cows = {}}
		print("🐄 ShopSystem: Initialized livestock data")
	end
	if not playerData.livestock.cows then
		playerData.livestock.cows = {}
		print("🐄 ShopSystem: Initialized cows data")
	end

	-- For basic cows, auto-create farm plot if needed
	if item.id == "basic_cow" then
		if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
			print("🐄 ShopSystem: Auto-creating farm plot for basic cow")
			playerData.farming = playerData.farming or {}
			playerData.farming.plots = 1
			playerData.farming.inventory = playerData.farming.inventory or {}

			-- Try to create the farm plot via GameCore
			if self.GameCore and self.GameCore.CreatePlayerFarmPlot then
				local plotSuccess = pcall(function()
					return self.GameCore:CreatePlayerFarmPlot(player, 1)
				end)
				if not plotSuccess then
					warn("🐄 ShopSystem: Failed to auto-create farm plot")
				end
			end
		end
	end

	local successCount = 0
	local lastError = "Unknown error"

	-- Purchase each cow with comprehensive error handling
	for i = 1, quantity do
		print("🐄 ShopSystem: Attempting to purchase cow " .. i .. "/" .. quantity)

		local success, error = pcall(function()
			if not self.GameCore or not self.GameCore.PurchaseCow then
				error("GameCore.PurchaseCow method not available")
			end

			local result = self.GameCore:PurchaseCow(player, item.id, nil)
			if not result then
				error("GameCore.PurchaseCow returned false")
			end
			return result
		end)

		if success and error then
			successCount = successCount + 1
			print("🐄 ShopSystem: Successfully purchased cow " .. i .. "/" .. quantity)
		else
			lastError = tostring(error)
			warn("🐄 ShopSystem: Failed to purchase cow " .. i .. ": " .. lastError)
			break -- Stop on first failure to avoid cascading issues
		end

		-- Add small delay between cow purchases to prevent race conditions
		if i < quantity then
			wait(0.1)
		end
	end

	if successCount > 0 then
		print("🐄 ShopSystem: Successfully purchased " .. successCount .. " cows")

		-- Special handling for first cow purchase
		if item.id == "basic_cow" and successCount == 1 then
			spawn(function()
				wait(2) -- Give time for cow to appear
				self:SendNotification(player, "🐄 Your First Cow!", 
					"Your cow is ready! Click on it to collect milk every " .. 
						(item.cowData.cooldown or 5) .. " seconds!", "success")
			end)
		end

		return true, "Success"
	else
		return false, "Failed to purchase any cows. Last error: " .. lastError
	end
end

-- Enhanced cow upgrade processing
function ShopSystem:ProcessCowUpgradePurchaseEnhanced(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing cow upgrade with enhanced safety - " .. item.id)

	local eligibleCows = self:FindEligibleCowsForUpgrade(playerData, item)
	if #eligibleCows < quantity then
		return false, "Not enough eligible cows for upgrade"
	end

	local successCount = 0
	local lastError = "Unknown error"

	for i = 1, quantity do
		local cowId = eligibleCows[i]
		print("🐄 ShopSystem: Attempting to upgrade cow " .. cowId)

		local success, error = pcall(function()
			if not self.GameCore or not self.GameCore.PurchaseCow then
				error("GameCore.PurchaseCow method not available")
			end

			local result = self.GameCore:PurchaseCow(player, item.id, cowId)
			if not result then
				error("GameCore.PurchaseCow returned false")
			end
			return result
		end)

		if success and error then
			successCount = successCount + 1
			print("🐄 ShopSystem: Successfully upgraded cow " .. cowId)
		else
			lastError = tostring(error)
			warn("🐄 ShopSystem: Failed to upgrade cow " .. cowId .. ": " .. lastError)
			break
		end

		-- Add delay between upgrades
		if i < quantity then
			wait(0.1)
		end
	end

	if successCount > 0 then
		print("🐄 ShopSystem: Successfully upgraded " .. successCount .. " cows")
		return true, "Success"
	else
		return false, "Failed to upgrade any cows. Last error: " .. lastError
	end
end

-- Safe cow counting methods
function ShopSystem:GetPlayerCowCountSafe(playerData)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return 0
	end

	local count = 0
	for _ in pairs(playerData.livestock.cows) do
		count = count + 1
	end
	return count
end

function ShopSystem:GetPlayerMaxCowsSafe(playerData)
	local baseCows = 5
	local bonusCows = 0

	if playerData and playerData.upgrades then
		if playerData.upgrades.pasture_expansion_1 then bonusCows = bonusCows + 2 end
		if playerData.upgrades.pasture_expansion_2 then bonusCows = bonusCows + 3 end
		if playerData.upgrades.mega_pasture then bonusCows = bonusCows + 5 end
	end

	return baseCows + bonusCows
end

-- Enhanced error reporting
function ShopSystem:ReportCowPurchaseError(player, itemId, error)
	local errorReport = {
		player = player.Name,
		userId = player.UserId,
		itemId = itemId,
		error = error,
		timestamp = os.time(),
		gameCore = self.GameCore ~= nil,
		itemConfig = self.ItemConfig ~= nil
	}

	print("🚨 COW PURCHASE ERROR REPORT:")
	for key, value in pairs(errorReport) do
		print("  " .. key .. ": " .. tostring(value))
	end

	-- Check if the item exists in ItemConfig
	if self.ItemConfig and self.ItemConfig.ShopItems then
		local item = self.ItemConfig.ShopItems[itemId]
		if item then
			print("  Item found in config: true")
			print("  Item type: " .. (item.type or "unknown"))
			print("  Has cowData: " .. tostring(item.cowData ~= nil))
		else
			print("  Item found in config: false")
			print("  Available cow items:")
			for id, _ in pairs(self.ItemConfig.ShopItems) do
				if id:find("cow") then
					print("    " .. id)
				end
			end
		end
	else
		print("  ItemConfig not available")
	end
end

-- Enhanced debugging method
function ShopSystem:DebugCowPurchase(player, itemId)
	print("=== COW PURCHASE DEBUG FOR " .. player.Name .. " ===")
	print("Item ID: " .. itemId)

	-- Check ShopSystem state
	print("ShopSystem state:")
	print("  GameCore available: " .. tostring(self.GameCore ~= nil))
	print("  ItemConfig available: " .. tostring(self.ItemConfig ~= nil))

	if self.GameCore then
		print("  GameCore.PurchaseCow exists: " .. tostring(self.GameCore.PurchaseCow ~= nil))
	end

	-- Check item
	if self.ItemConfig and self.ItemConfig.ShopItems then
		local item = self.ItemConfig.ShopItems[itemId]
		if item then
			print("Item validation:")
			local validation = self:ValidateCowItemExtensive(item)
			print("  Valid: " .. tostring(validation.valid))
			print("  Reason: " .. validation.reason)
		else
			print("Item not found in ItemConfig!")
		end
	end

	-- Check player
	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if playerData then
		print("Player validation:")
		local item = self.ItemConfig.ShopItems[itemId]
		if item then
			local validation = self:ValidatePlayerForCowPurchase(player, playerData, item, 1)
			print("  Valid: " .. tostring(validation.valid))
			print("  Reason: " .. validation.reason)
		end
	else
		print("Player data not available!")
	end

	print("=============================================")
end
game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/debugmilk" then
				if _G.ShopSystem and _G.ShopSystem.DebugMilkSelling then
					_G.ShopSystem:DebugMilkSelling(player)
				else
					print("ShopSystem not available for debugging")
				end

			elseif command == "/givemilk" then
				local amount = tonumber(args[2]) or 5
				local playerData = _G.GameCore and _G.GameCore:GetPlayerData(player)
				if playerData then
					playerData.milk = (playerData.milk or 0) + amount
					playerData.livestock = playerData.livestock or {}
					playerData.livestock.inventory = playerData.livestock.inventory or {}
					playerData.livestock.inventory.milk = (playerData.livestock.inventory.milk or 0) + amount
					print("Gave " .. amount .. " milk to " .. player.Name)
				end

			elseif command == "/sellmilk" then
				local amount = tonumber(args[2]) or 1
				if _G.ShopSystem and _G.ShopSystem.HandleSell then
					_G.ShopSystem:HandleSell(player, "milk", amount)
				end
			end
		end
	end)
end)
-- Add this to your existing SetupAdminCommands or create new admin commands
function ShopSystem:SetupCowDebugCommands()
	game:GetService("Players").PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/debugcowpurchase" then
					local itemId = args[2] or "basic_cow"
					self:DebugCowPurchase(player, itemId)

				elseif command == "/testcowitem" then
					local itemId = args[2] or "basic_cow"
					if self.ItemConfig and self.ItemConfig.ShopItems then
						local item = self.ItemConfig.ShopItems[itemId]
						if item then
							local validation = self:ValidateCowItemExtensive(item)
							print("Item validation result:")
							print("  Valid: " .. tostring(validation.valid))
							print("  Reason: " .. validation.reason)
						else
							print("Item not found: " .. itemId)
						end
					else
						print("ItemConfig not available")
					end
				end
			end
		end)
	end)
end

print("ShopSystem: ✅ Enhanced cow purchase validation loaded!")
print("🔧 New Debug Commands:")
print("  /debugcowpurchase [itemId] - Debug cow purchase process")
print("  /testcowitem [itemId] - Test cow item validation")
function ShopSystem:DebugMilkSelling(player)
	print("=== MILK SELLING DEBUG FOR " .. player.Name .. " ===")

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		print("❌ No player data found")
		return
	end

	-- Check milk item definition
	local milkItem = self:GetShopItemById("milk")
	if milkItem then
		print("✅ Milk item found in shop:")
		print("  Name: " .. (milkItem.name or "N/A"))
		print("  Price: " .. (milkItem.price or "N/A"))
		print("  Type: " .. (milkItem.type or "N/A"))
		print("  Category: " .. (milkItem.category or "N/A"))
		print("  Sellable: " .. tostring(milkItem.sellable))
		print("  Is sellable (function): " .. tostring(self:IsItemSellable(milkItem)))
	else
		print("❌ Milk item NOT found in shop items")
	end

	-- Check milk inventory
	print("\n📦 Milk inventory check:")
	print("  Direct milk: " .. (playerData.milk or 0))

	if playerData.livestock and playerData.livestock.inventory then
		print("  Livestock milk: " .. (playerData.livestock.inventory.milk or 0))
	else
		print("  Livestock inventory: NOT FOUND")
	end

	if playerData.farming and playerData.farming.inventory then
		print("  Farming milk: " .. (playerData.farming.inventory.milk or 0))
	else
		print("  Farming inventory: NOT FOUND")
	end

	-- Check total stock
	local totalMilk = self:GetPlayerStock(playerData, "milk")
	print("  Total milk (GetPlayerStock): " .. totalMilk)

	-- Test selling
	if totalMilk > 0 then
		print("\n🧪 Testing milk sale of 1 unit...")
		local success = self:HandleSell(player, "milk", 1)
		print("  Sale result: " .. tostring(success))
	else
		print("\n❌ No milk to test selling")
	end

	print("==========================================")
end

function ShopSystem:ProcessNewCowPurchase(player, playerData, item, quantity)
	print("🐄 ShopSystem: Processing new cow purchase - " .. item.id)

	-- Initialize livestock data if needed
	if not playerData.livestock then
		playerData.livestock = {cows = {}}
		print("🐄 ShopSystem: Initialized livestock data")
	end
	if not playerData.livestock.cows then
		playerData.livestock.cows = {}
		print("🐄 ShopSystem: Initialized cows data")
	end

	-- Ensure player has farm plot for cow
	if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
		-- Auto-create first farm plot for cow purchases
		playerData.farming = playerData.farming or {}
		playerData.farming.plots = 1
		playerData.farming.inventory = playerData.farming.inventory or {}

		if self.GameCore and self.GameCore.CreatePlayerFarmPlot then
			self.GameCore:CreatePlayerFarmPlot(player, 1)
			print("🐄 ShopSystem: Auto-created farm plot for cow")
		end
	end

	local successCount = 0

	-- Purchase each cow with enhanced error handling
	for i = 1, quantity do
		local success, error = pcall(function()
			return self.GameCore:PurchaseCow(player, item.id, nil)
		end)

		if success and error then
			successCount = successCount + 1
			print("🐄 ShopSystem: Successfully purchased cow " .. i .. "/" .. quantity)
		else
			warn("🐄 ShopSystem: Failed to purchase cow " .. i .. ": " .. tostring(error))
			break
		end
	end

	if successCount > 0 then
		print("🐄 ShopSystem: Successfully purchased " .. successCount .. " cows")

		-- Send helpful notification for first cow
		if item.id == "basic_cow" then
			spawn(function()
				wait(2)
				self:SendNotification(player, "🐄 First Cow!", 
					"Your cow is ready! Click on it to collect milk every " .. (item.cowData.cooldown or 5) .. " seconds!", "success")
			end)
		end

		return true
	end

	warn("🐄 ShopSystem: Failed to purchase any cows")
	return false
end

-- ========== ENHANCED ERROR HANDLING ==========

function ShopSystem:CanPlayerAfford(playerData, item, quantity)
	quantity = quantity or 1
	if not item.price or not item.currency then return false end

	-- Free items are always affordable
	if item.price == 0 then return true end

	local totalCost = item.price * quantity
	local playerCurrency = playerData[item.currency] or 0

	return playerCurrency >= totalCost
end

function ShopSystem:ValidateCowPurchase(player, playerData, item, quantity)
	print("🐄 ShopSystem: FIXED cow purchase validation - " .. item.id)

	-- Check if item has valid cow data
	if not item.cowData then
		return false, "Item missing cow data: " .. item.id
	end

	-- SPECIAL HANDLING FOR FIRST COW PURCHASE
	if item.id == "basic_cow" then
		print("🐄 ShopSystem: Basic cow purchase - minimal validation")
		return true, "Basic cow purchase approved"
	end

	-- FOR COW UPGRADES - Enhanced validation
	if item.type == "cow_upgrade" then
		print("🐄 ShopSystem: Validating cow upgrade - " .. item.id)

		-- Check if player has livestock system initialized
		if not playerData.livestock then
			return false, "You need to buy a basic cow first!"
		end

		if not playerData.livestock.cows then
			return false, "You need to buy a basic cow first!"
		end

		-- Find eligible cows for upgrade
		local eligibleCows = self:FindEligibleCowsForUpgrade(playerData, item)
		print("🐄 ShopSystem: Found " .. #eligibleCows .. " eligible cows for upgrade")

		if #eligibleCows < quantity then
			local upgradeFrom = item.cowData and item.cowData.upgradeFrom or "unknown tier"
			return false, "You need " .. quantity .. "x " .. upgradeFrom .. " cows to upgrade! You only have " .. #eligibleCows .. " eligible cows."
		end

		print("🐄 ShopSystem: Cow upgrade validation passed")
		return true, "Cow upgrade validation successful"
	end

	-- FOR NEW COW PURCHASES (non-basic)
	if item.type == "cow" then
		print("🐄 ShopSystem: Validating new cow purchase - " .. item.id)

		-- Check if player has farm plots
		if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
			return false, "You need a farm plot first! Buy 'Your First Farm Plot' from the shop."
		end

		-- Check cow capacity
		local currentCowCount = self:GetPlayerCowCount(playerData)
		local maxCows = self:GetPlayerMaxCows(playerData)

		if currentCowCount + quantity > maxCows then
			return false, "Cow limit reached! You have " .. currentCowCount .. "/" .. maxCows .. " cows. Buy pasture expansions for more space."
		end

		print("🐄 ShopSystem: New cow purchase validation passed")
		return true, "New cow purchase validation successful"
	end

	return true, "Valid cow purchase"
end

-- ENHANCED FindEligibleCowsForUpgrade function:
function ShopSystem:FindEligibleCowsForUpgrade(playerData, upgradeItem)
	local eligibleCows = {}

	if not playerData.livestock or not playerData.livestock.cows then
		print("🐄 ShopSystem: No livestock or cows found")
		return eligibleCows
	end

	local upgradeFrom = upgradeItem.cowData and upgradeItem.cowData.upgradeFrom
	if not upgradeFrom then
		print("🐄 ShopSystem: No upgradeFrom specified for " .. upgradeItem.id)
		return eligibleCows
	end

	print("🐄 ShopSystem: Looking for cows of tier: " .. upgradeFrom)

	-- Find cows of the required tier
	for cowId, cowData in pairs(playerData.livestock.cows) do
		print("🐄 ShopSystem: Checking cow " .. cowId .. " with tier: " .. (cowData.tier or "unknown"))
		if cowData.tier == upgradeFrom then
			table.insert(eligibleCows, cowId)
			print("🐄 ShopSystem: Found eligible cow: " .. cowId)
		end
	end

	print("🐄 ShopSystem: Total eligible cows found: " .. #eligibleCows)
	return eligibleCows
end

-- ========== UTILITY METHODS ==========

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

function ShopSystem:GetShopItemById(itemId)
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		warn("ShopSystem: ItemConfig or ShopItems not available")
		return nil
	end

	local item = self.ItemConfig.ShopItems[itemId]
	if not item then
		warn("ShopSystem: Item not found: " .. itemId)
		-- Print available items for debugging
		print("Available items:")
		for id, _ in pairs(self.ItemConfig.ShopItems) do
			print("  " .. id)
		end
	end

	return item
end

-- ========== KEEP ALL OTHER EXISTING METHODS ==========
-- (The rest of the methods from the original ShopSystem.lua remain unchanged)

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
			print("ShopSystem: Created " .. remote.type .. ": " .. remote.name)
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
		print("ShopSystem: ✅ GetShopItems handler connected")
	end

	if self.RemoteEvents.PurchaseItem then
		self.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
			self:HandlePurchase(player, itemId, quantity or 1)
		end)
		print("ShopSystem: ✅ PurchaseItem handler connected")
	end

	if self.RemoteEvents.SellItem then
		self.RemoteEvents.SellItem.OnServerEvent:Connect(function(player, itemId, quantity)
			self:HandleSell(player, itemId, quantity or 1)
		end)
		print("ShopSystem: ✅ SellItem handler connected")
	end

	print("ShopSystem: All remote handlers connected")
end
function ShopSystem:HandleSell(player, itemId, quantity)
	print("🏪 ShopSystem: HandleSell request - " .. player.Name .. " wants to sell " .. quantity .. "x " .. itemId)

	-- Get player data
	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Player Data Error", "Could not load player data!", "error")
		return false
	end

	-- Check if player has the item to sell
	local playerStock = self:GetPlayerStock(playerData, itemId)
	if playerStock < quantity then
		self:SendNotification(player, "Not Enough Items", 
			"You only have " .. playerStock .. "x " .. itemId .. " but tried to sell " .. quantity .. "!", "error")
		return false
	end

	-- Get item data to determine sell price
	local item = self:GetShopItemById(itemId)
	if not item then
		self:SendNotification(player, "Invalid Item", "Cannot sell unknown item: " .. itemId, "error")
		return false
	end

	-- Calculate sell price (typically 50% of purchase price)
	local sellPrice = math.floor((item.price or 0) * 0.5)
	if sellPrice <= 0 then
		self:SendNotification(player, "Cannot Sell", "This item cannot be sold!", "error")
		return false
	end

	local totalEarnings = sellPrice * quantity
	local currency = item.currency or "coins"

	-- Remove items from player inventory
	local success = self:RemovePlayerItems(playerData, itemId, quantity)
	if not success then
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

	local itemName = item.name or itemId:gsub("_", " ")
	local currencyName = currency == "farmTokens" and "Farm Tokens" or "Coins"

	self:SendNotification(player, "🏪 Item Sold!", 
		"Sold " .. quantity .. "x " .. itemName .. " for " .. totalEarnings .. " " .. currencyName .. "!", "success")

	print("🏪 ShopSystem: Successfully sold " .. quantity .. "x " .. itemId .. " for " .. player.Name)
	return true
end

function ShopSystem:RemovePlayerItems(playerData, itemId, quantity)
	print("🗑️ ShopSystem: Removing " .. quantity .. "x " .. itemId .. " from player inventory")

	-- SPECIAL HANDLING FOR MILK REMOVAL
	if itemId == "milk" or itemId == "fresh_milk" then
		local remainingToRemove = quantity

		-- Remove from direct milk property first
		if playerData.milk and playerData.milk > 0 and remainingToRemove > 0 then
			local removeFromDirect = math.min(playerData.milk, remainingToRemove)
			playerData.milk = playerData.milk - removeFromDirect
			remainingToRemove = remainingToRemove - removeFromDirect
			print("🥛 Removed " .. removeFromDirect .. " milk from direct property")
		end

		-- Remove from livestock inventory
		if remainingToRemove > 0 and playerData.livestock and playerData.livestock.inventory and playerData.livestock.inventory.milk then
			local removeFromLivestock = math.min(playerData.livestock.inventory.milk, remainingToRemove)
			playerData.livestock.inventory.milk = playerData.livestock.inventory.milk - removeFromLivestock
			remainingToRemove = remainingToRemove - removeFromLivestock
			print("🥛 Removed " .. removeFromLivestock .. " milk from livestock inventory")

			if playerData.livestock.inventory.milk <= 0 then
				playerData.livestock.inventory.milk = nil
			end
		end

		-- Remove from farming inventory
		if remainingToRemove > 0 and playerData.farming and playerData.farming.inventory and playerData.farming.inventory.milk then
			local removeFromFarming = math.min(playerData.farming.inventory.milk, remainingToRemove)
			playerData.farming.inventory.milk = playerData.farming.inventory.milk - removeFromFarming
			remainingToRemove = remainingToRemove - removeFromFarming
			print("🥛 Removed " .. removeFromFarming .. " milk from farming inventory")

			if playerData.farming.inventory.milk <= 0 then
				playerData.farming.inventory.milk = nil
			end
		end

		-- Check if we successfully removed all requested milk
		if remainingToRemove <= 0 then
			print("✅ Successfully removed " .. quantity .. " milk from inventories")
			return true
		else
			warn("❌ Could only remove " .. (quantity - remainingToRemove) .. "/" .. quantity .. " milk")
			return false
		end
	end

	-- Regular item removal logic for other items
	local inventoryPaths = {
		{"farming", "inventory"},
		{"livestock", "inventory"},
		{"defense", "chickens", "feed"},
		{"defense", "pestControl"},
		{"inventory"}
	}

	for _, path in ipairs(inventoryPaths) do
		local inventory = playerData
		for _, key in ipairs(path) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				inventory = nil
				break
			end
		end

		if inventory and inventory[itemId] and inventory[itemId] >= quantity then
			inventory[itemId] = inventory[itemId] - quantity
			if inventory[itemId] <= 0 then
				inventory[itemId] = nil
			end
			print("✅ Removed " .. quantity .. "x " .. itemId .. " from " .. table.concat(path, "."))
			return true
		end
	end

	warn("❌ Could not find " .. quantity .. "x " .. itemId .. " in any player inventory")
	return false
end

function ShopSystem:GetSellableItems(playerData)
	print("ShopSystem: Getting sellable items for player")

	local sellableItems = {}

	-- Define sellable item categories
	local sellableCategories = {
		"crops", "milk", "seeds", "feed", "materials"
	}

	-- Check all inventory locations
	local inventoryPaths = {
		{"farming", "inventory"},
		{"livestock", "inventory"},
		{"inventory"}
	}

	for _, path in ipairs(inventoryPaths) do
		local inventory = playerData

		for _, key in ipairs(path) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				inventory = nil
				break
			end
		end

		if inventory then
			for itemId, quantity in pairs(inventory) do
				if quantity > 0 then
					local item = self:GetShopItemById(itemId)
					if item and self:IsItemSellable(item) then
						sellableItems[itemId] = {
							name = item.name,
							quantity = quantity,
							sellPrice = math.floor((item.price or 0) * 0.5),
							currency = item.currency or "coins"
						}
					end
				end
			end
		end
	end

	return sellableItems
end

function ShopSystem:IsItemSellable(item)
	print("🏪 Checking if item is sellable: " .. (item.id or "unknown"))

	-- Define which items can be sold
	local sellableTypes = {
		"crop", "seed", "material", "feed", "livestock_product"
	}

	local sellableCategories = {
		"crops", "seeds", "materials", "livestock"
	}

	-- SPECIFIC CHECK FOR CROPS
	if item.id and (item.id:find("crop") or item.category == "crops") then
		print("🌾 CROP DETECTED - marking as sellable: " .. item.id)
		return true
	end

	-- SPECIFIC CHECKS FOR KNOWN SELLABLE ITEMS
	local knownSellableItems = {
		"carrot", "corn", "strawberry", "wheat", "potato", 
		"tomato", "cabbage", "radish", "broccoli", "milk",
		"carrot_seeds", "corn_seeds", "strawberry_seeds"
	}

	for _, sellableItem in ipairs(knownSellableItems) do
		if item.id == sellableItem then
			print("🌱 KNOWN SELLABLE ITEM: " .. item.id)
			return true
		end
	end

	-- Check if explicitly marked as sellable
	if item.sellable == true then
		print("✅ EXPLICITLY SELLABLE: " .. item.id)
		return true
	end

	-- Check if item type is sellable
	if item.type then
		for _, sellableType in ipairs(sellableTypes) do
			if item.type == sellableType or item.type:find(sellableType) then
				print("📦 SELLABLE BY TYPE (" .. item.type .. "): " .. item.id)
				return true
			end
		end
	end

	-- Check if item category is sellable
	if item.category then
		for _, sellableCategory in ipairs(sellableCategories) do
			if item.category == sellableCategory then
				print("📂 SELLABLE BY CATEGORY (" .. item.category .. "): " .. item.id)
				return true
			end
		end
	end

	-- Items marked as not sellable
	if item.notSellable then
		print("❌ MARKED AS NOT SELLABLE: " .. item.id)
		return false
	end

	print("❓ ITEM NOT RECOGNIZED AS SELLABLE: " .. item.id)
	return false
end

-- ENHANCED GetPlayerStock for crop detection:
function ShopSystem:GetPlayerStock(playerData, itemId)
	print("🔍 ShopSystem: Searching for " .. itemId .. " in player inventory")

	-- SPECIAL HANDLING FOR CROPS
	if itemId == "milk" or itemId == "fresh_milk" then
		local totalMilk = 0

		if playerData.milk and playerData.milk > 0 then
			totalMilk = totalMilk + playerData.milk
		end

		if playerData.livestock and playerData.livestock.inventory and playerData.livestock.inventory.milk then
			totalMilk = totalMilk + playerData.livestock.inventory.milk
		end

		if playerData.farming and playerData.farming.inventory and playerData.farming.inventory.milk then
			totalMilk = totalMilk + playerData.farming.inventory.milk
		end

		print("🥛 Total milk found: " .. totalMilk)
		return totalMilk
	end

	-- ENHANCED CROP DETECTION - Check farming inventory FIRST
	if playerData.farming and playerData.farming.inventory then
		local farmingAmount = playerData.farming.inventory[itemId]
		if farmingAmount and farmingAmount > 0 then
			print("🌾 Found " .. farmingAmount .. "x " .. itemId .. " in farming inventory")
			return farmingAmount
		end
	end

	-- Regular inventory search
	local inventoryPaths = {
		{"livestock", "inventory"}, 
		{"defense", "chickens", "feed"},
		{"defense", "pestControl"},
		{"inventory"}
	}

	for _, path in ipairs(inventoryPaths) do
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
			print("📦 Found " .. inventory[itemId] .. "x " .. itemId .. " in " .. table.concat(path, "."))
			return inventory[itemId]
		end
	end

	print("❌ No " .. itemId .. " found in any inventory")
	return 0
end

-- ========== ENHANCED SELL SYSTEM WITH BULK SELLING ==========

function ShopSystem:HandleBulkSell(player, itemIds)
	print("🏪 ShopSystem: HandleBulkSell request from " .. player.Name)

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Error", "Could not load player data!", "error")
		return false
	end

	local totalEarnings = 0
	local totalItems = 0
	local currency = "coins"

	for _, itemId in ipairs(itemIds) do
		local quantity = self:GetPlayerStock(playerData, itemId)
		if quantity > 0 then
			local item = self:GetShopItemById(itemId)
			if item and self:IsItemSellable(item) then
				local sellPrice = math.floor((item.price or 0) * 0.5)
				local itemEarnings = sellPrice * quantity

				if self:RemovePlayerItems(playerData, itemId, quantity) then
					totalEarnings = totalEarnings + itemEarnings
					totalItems = totalItems + quantity
					currency = item.currency or currency
				end
			end
		end
	end

	if totalEarnings > 0 then
		playerData[currency] = (playerData[currency] or 0) + totalEarnings

		if self.GameCore then
			self.GameCore:SavePlayerData(player)
			self.GameCore:UpdatePlayerLeaderstats(player)
		end

		local currencyName = currency == "farmTokens" and "Farm Tokens" or "Coins"
		self:SendNotification(player, "🏪 Bulk Sale Complete!", 
			"Sold " .. totalItems .. " items for " .. totalEarnings .. " " .. currencyName .. "!", "success")

		return true
	else
		self:SendNotification(player, "Nothing to Sell", "No sellable items found!", "warning")
		return false
	end
end

-- ========== ADD SELL-ALL FUNCTIONALITY ==========

function ShopSystem:HandleSellAll(player, itemType)
	print("🏪 ShopSystem: HandleSellAll request - " .. player.Name .. " selling all " .. (itemType or "items"))

	local playerData = self.GameCore and self.GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Error", "Could not load player data!", "error")
		return false
	end

	local sellableItems = self:GetSellableItems(playerData)
	local itemsToSell = {}

	-- Filter by item type if specified
	if itemType then
		for itemId, itemData in pairs(sellableItems) do
			local item = self:GetShopItemById(itemId)
			if item and (item.type == itemType or item.category == itemType) then
				table.insert(itemsToSell, itemId)
			end
		end
	else
		-- Sell all sellable items
		for itemId, _ in pairs(sellableItems) do
			table.insert(itemsToSell, itemId)
		end
	end

	if #itemsToSell > 0 then
		return self:HandleBulkSell(player, itemsToSell)
	else
		self:SendNotification(player, "Nothing to Sell", "No " .. (itemType or "sellable") .. " items found!", "warning")
		return false
	end
end

print("ShopSystem: ✅ HandleSell method and selling system added!")
print("🏪 NEW FEATURES:")
print("  💰 Item selling with 50% return value")
print("  📦 Bulk selling functionality") 
print("  🔄 Sell-all by category")
print("  📊 Automatic inventory management")

-- Add the rest of your existing methods here...
-- (HandleGetShopItems, CreateEnhancedItemCopy, ProcessPurchaseEnhanced, etc.)

function ShopSystem:HandleGetShopItems(player)
	print("🛒 ShopSystem: FIXED GetShopItems request from " .. player.Name)

	local success, result = pcall(function()
		if not self.ItemConfig or not self.ItemConfig.ShopItems then
			error("ItemConfig.ShopItems not available")
		end

		local shopItemsArray = {}
		local playerData = self.GameCore and self.GameCore:GetPlayerData(player)

		local categoryCount = {}

		for itemId, item in pairs(self.ItemConfig.ShopItems) do
			if self:ValidateItemEnhanced(item, itemId) then
				-- COUNT ITEMS BY CATEGORY FOR DEBUGGING
				local category = item.category or "unknown"
				categoryCount[category] = (categoryCount[category] or 0) + 1

				local itemCopy = self:CreateEnhancedItemCopy(item, itemId, playerData)
				table.insert(shopItemsArray, itemCopy)

				-- SPECIAL LOGGING FOR CRAFTING ITEMS
				if category == "crafting" then
					print("🔨 CRAFTING ITEM ADDED: " .. itemId .. " (" .. item.name .. ")")
				end
			else
				print("❌ INVALID ITEM SKIPPED: " .. itemId)
			end
		end

		-- DEBUG: Print category breakdown
		print("🛒 ShopSystem: Items by category:")
		for category, count in pairs(categoryCount) do
			print("  " .. category .. ": " .. count .. " items")
		end

		table.sort(shopItemsArray, function(a, b)
			if a.category == b.category then
				return a.price < b.price
			end
			return a.category < b.category
		end)

		print("🛒 ShopSystem: Returning " .. #shopItemsArray .. " total items")
		return shopItemsArray
	end)

	if success then
		return result
	else
		warn("🛒 ShopSystem: GetShopItems failed: " .. tostring(result))
		return {}
	end
end

-- FIX: Enhanced validation to ensure crafting items pass validation
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

	-- Enhanced price validation (allow 0 for free items)
	if type(item.price) ~= "number" or item.price < 0 then
		warn("ShopSystem: Item " .. itemId .. " has invalid price: " .. tostring(item.price))
		return false
	end

	-- FIXED: Enhanced currency validation with Robux support
	local validCurrencies = {"coins", "farmTokens", "Robux"}
	local isValidCurrency = false
	for _, validCurrency in ipairs(validCurrencies) do
		if item.currency == validCurrency then
			isValidCurrency = true
			break
		end
	end

	if not isValidCurrency then
		warn("ShopSystem: Item " .. itemId .. " has invalid currency: " .. tostring(item.currency))
		return false
	end

	-- SPECIAL VALIDATION FOR CRAFTING ITEMS
	if item.category == "crafting" then
		print("🔨 Validating crafting item: " .. itemId)
		-- Crafting items are valid as long as they have the basic required properties
		print("🔨 Crafting item validation passed: " .. itemId)
		return true
	end

	-- Validate cow-specific properties
	if item.type == "cow" or item.type == "cow_upgrade" then
		if not item.cowData then
			warn("ShopSystem: Cow item " .. itemId .. " missing cowData")
			return false
		end

		local cowData = item.cowData
		if not cowData.tier then
			warn("ShopSystem: Cow item " .. itemId .. " missing tier in cowData")
			return false
		end
		if not cowData.milkAmount then
			warn("ShopSystem: Cow item " .. itemId .. " missing milkAmount in cowData")
			return false
		end
		if not cowData.cooldown then
			warn("ShopSystem: Cow item " .. itemId .. " missing cooldown in cowData")
			return false
		end

		if item.type == "cow_upgrade" and not cowData.upgradeFrom then
			warn("ShopSystem: Cow upgrade item " .. itemId .. " missing upgradeFrom property")
			return false
		end
	end

	return true
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
		type = item.type or "item"
	}

	for key, value in pairs(item) do
		if not itemCopy[key] and key ~= "farmingData" then
			if type(value) == "table" then
				itemCopy[key] = self:DeepCopyTable(value)
			else
				itemCopy[key] = value
			end
		end
	end

	if item.farmingData then
		itemCopy.farmingData = self:DeepCopyTable(item.farmingData)
	end

	if playerData then
		itemCopy.canAfford = self:CanPlayerAfford(playerData, item)
		itemCopy.meetsRequirements = self:MeetsRequirements(playerData, item)
		itemCopy.alreadyOwned = self:IsAlreadyOwned(playerData, itemId)
		itemCopy.playerStock = self:GetPlayerStock(playerData, itemId)
	end

	return itemCopy
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

-- Add other utility methods
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

function ShopSystem:DebugItemConfig()
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		warn("ShopSystem: No ShopItems in ItemConfig!")
		return
	end

	local itemCount = 0
	local categoryBreakdown = {}

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		itemCount = itemCount + 1
		local category = item.category or "unknown"
		categoryBreakdown[category] = (categoryBreakdown[category] or 0) + 1
	end

	print("🛒 ShopSystem: ItemConfig Debug Summary")
	print("  📦 Total items: " .. itemCount)
	print("  🏷️ Categories:")
	for category, count in pairs(categoryBreakdown) do
		print("    " .. category .. ": " .. count .. " items")
	end
end

function ShopSystem:ValidateShopData()
	if not self.ItemConfig or not self.ItemConfig.ShopItems then
		error("ShopSystem: ItemConfig.ShopItems not available!")
	end

	local validItems = 0
	local invalidItems = 0

	for itemId, item in pairs(self.ItemConfig.ShopItems) do
		if self:ValidateItemEnhanced(item, itemId) then
			validItems = validItems + 1
		else
			invalidItems = invalidItems + 1
		end
	end

	print("ShopSystem: Validation complete - Valid: " .. validItems .. ", Invalid: " .. invalidItems)
	return invalidItems == 0
end

print("ShopSystem: ✅ FIXED with Robux support and enhanced cow handling!")

return ShopSystem