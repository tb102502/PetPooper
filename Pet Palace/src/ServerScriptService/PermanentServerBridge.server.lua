--[[
    PermanentServerBridge.server.lua - Stable Remote Handlers
    Place in: ServerScriptService/PermanentServerBridge.server.lua
    
    This script provides stable remote handlers that won't be destroyed.
    It acts as a bridge until proper systems (GameCore/ShopSystem) initialize.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("=== PERMANENT SERVER BRIDGE STARTING ===")

-- Create GameRemotes folder if missing
local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GameRemotes"
	remoteFolder.Parent = ReplicatedStorage
	print("📁 Created GameRemotes folder")
end

-- Track if proper systems are initialized
local GameCoreInitialized = false
local ShopSystemInitialized = false

-- Default player data structure
local function getDefaultPlayerData()
	return {
		coins = 500,  -- Increased from 100 so players can afford items
		farmTokens = 10,  -- Give some farm tokens too
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 0,
			inventory = {
				-- Give players some starter items to sell for testing
				carrot = 5,
				corn = 3,
				strawberry = 2
			}
		},
		livestock = {
			cow = {
				lastMilkCollection = 0,
				totalMilkCollected = 0
			},
			pig = {
				size = 1.0,
				cropPoints = 0,
				transformationCount = 0,
				totalFed = 0
			},
			inventory = {}
		},
		defense = {
			chickens = {owned = {}, deployed = {}, feed = {}},
			pestControl = {},
			roofs = {}
		},
		stats = {
			milkCollected = 0,
			coinsEarned = 500,  -- Updated to match starting coins
			cropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0,
			seedsPlanted = 0,
			pestsEliminated = 0
		},
		-- Add some milk for testing selling
		milk = 3,
		bridgeMode = true -- Indicates this is from the bridge
	}
end

-- Default shop items
local function getDefaultShopItems()
	return {
		-- Seeds Category  
		{
			id = "carrot_seeds",
			name = "🥕 Carrot Seeds",
			description = "Fast-growing orange vegetables! Perfect for beginners.\n\n⏱️ Grow Time: 5 minutes\n💰 Sell Value: 15 coins each",
			price = 25,
			currency = "coins",
			category = "seeds",
			icon = "🥕",
			maxPurchase = 50,
			type = "seed"
		},
		{
			id = "corn_seeds",
			name = "🌽 Corn Seeds",
			description = "Sweet corn that pigs love! Higher yield than carrots.\n\n⏱️ Grow Time: 8 minutes\n💰 Sell Value: 25 coins each",
			price = 50,
			currency = "coins",
			category = "seeds",
			icon = "🌽",
			maxPurchase = 50,
			type = "seed"
		},
		{
			id = "strawberry_seeds",
			name = "🍓 Strawberry Seeds",
			description = "Delicious berries with premium value! Worth the wait.\n\n⏱️ Grow Time: 10 minutes\n💰 Sell Value: 40 coins each",
			price = 100,
			currency = "coins",
			category = "seeds",
			icon = "🍓",
			maxPurchase = 50,
			type = "seed"
		},
		{
			id = "golden_seeds",
			name = "✨ Golden Seeds",
			description = "Magical seeds that produce golden fruit! Premium crop.\n\n⏱️ Grow Time: 15 minutes\n💰 Sell Value: 100 coins each",
			price = 50,
			currency = "farmTokens",
			category = "seeds",
			icon = "✨",
			maxPurchase = 25,
			type = "seed"
		},

		-- Farm Category
		{
			id = "farm_plot_starter",
			name = "🌾 Basic Farm Plot",
			description = "Unlock your first farm plot to start growing crops!",
			price = 100,
			currency = "coins",
			category = "farm",
			icon = "🌾",
			maxPurchase = 1,
			type = "farmPlot"
		},
		{
			id = "farm_plot_expansion", 
			name = "🚜 Farm Plot Expansion",
			description = "Add more farming space! Each expansion gives you another farm plot.",
			price = 500,
			currency = "coins",
			category = "farm",
			icon = "🚜",
			maxPurchase = 9,
			type = "farmPlot"
		},

		-- Defense Category
		{
			id = "basic_chicken",
			name = "🐔 Basic Chicken",
			description = "General purpose pest control. Eliminates aphids and lays eggs for steady income.",
			price = 150,
			currency = "coins",
			category = "defense",
			icon = "🐔",
			maxPurchase = 20,
			type = "chicken"
		},
		{
			id = "organic_pesticide",
			name = "🧪 Organic Pesticide",
			description = "Manually eliminate pests from crops. One-time use, affects 3x3 area around target crop.",
			price = 50,
			currency = "coins",
			category = "defense",
			icon = "🧪",
			maxPurchase = 20,
			type = "tool"
		},

		-- Mining Category
		{
			id = "basic_pickaxe",
			name = "⛏️ Basic Pickaxe",
			description = "Essential tool for mining. Allows access to copper and iron deposits.",
			price = 200,
			currency = "coins",
			category = "mining",
			icon = "⛏️",
			maxPurchase = 1,
			type = "tool"
		},

		-- Crafting Category
		{
			id = "basic_workbench",
			name = "🔨 Basic Workbench",
			description = "Essential crafting station. Craft basic tools and farm equipment.",
			price = 500,
			currency = "coins",
			category = "crafting",
			icon = "🔨",
			maxPurchase = 1,
			type = "tool"
		},

		-- Premium Category
		{
			id = "auto_harvester",
			name = "🤖 Auto Harvester",
			description = "Automatically harvests ready crops every 30 seconds. The ultimate farming upgrade!",
			price = 150,
			currency = "farmTokens",
			category = "premium",
			icon = "🤖",
			maxPurchase = 1,
			type = "upgrade"
		}
	}
end

-- Storage for player data (temporary until proper systems load)
local TempPlayerData = {}

-- Function to create all required remotes
local function setupAllRemotes()
	local requiredRemotes = {
		-- GameCore RemoteEvents
		{name = "CollectMilk", type = "RemoteEvent"},
		{name = "FeedPig", type = "RemoteEvent"},
		{name = "PlayerDataUpdated", type = "RemoteEvent"},
		{name = "ShowNotification", type = "RemoteEvent"},
		{name = "PlantSeed", type = "RemoteEvent"},
		{name = "HarvestCrop", type = "RemoteEvent"},
		{name = "HarvestAllCrops", type = "RemoteEvent"},
		{name = "PestSpotted", type = "RemoteEvent"},
		{name = "PestEliminated", type = "RemoteEvent"},
		{name = "ChickenPlaced", type = "RemoteEvent"},

		-- Proximity RemoteEvents
		{name = "OpenShop", type = "RemoteEvent"},
		{name = "CloseShop", type = "RemoteEvent"},
		{name = "ShowPigFeedingUI", type = "RemoteEvent"},
		{name = "HidePigFeedingUI", type = "RemoteEvent"},

		-- ShopSystem RemoteEvents
		{name = "PurchaseItem", type = "RemoteEvent"},
		{name = "ItemPurchased", type = "RemoteEvent"},
		{name = "SellItem", type = "RemoteEvent"},
		{name = "ItemSold", type = "RemoteEvent"},
		{name = "CurrencyUpdated", type = "RemoteEvent"},

		-- RemoteFunctions
		{name = "GetPlayerData", type = "RemoteFunction"},
		{name = "GetShopItems", type = "RemoteFunction"},
		{name = "GetFarmingData", type = "RemoteFunction"}
	}

	local created = 0
	for _, remoteInfo in ipairs(requiredRemotes) do
		local existing = remoteFolder:FindFirstChild(remoteInfo.name)
		if not existing then
			local newRemote = Instance.new(remoteInfo.type)
			newRemote.Name = remoteInfo.name
			newRemote.Parent = remoteFolder
			created = created + 1
			print("📦 Created " .. remoteInfo.type .. ": " .. remoteInfo.name)
		end
	end

	if created > 0 then
		print("✅ Created " .. created .. " missing remotes")
	else
		print("✅ All remotes already exist")
	end
end

-- Setup stable RemoteFunction handlers
local function setupStableHandlers()
	-- GetPlayerData handler
	local getPlayerData = remoteFolder:FindFirstChild("GetPlayerData")
	if getPlayerData and getPlayerData:IsA("RemoteFunction") then
		getPlayerData.OnServerInvoke = function(player)
			-- ALWAYS provide bridge data if we have it, even if GameCore is initialized
			-- This ensures continuity when systems transition
			print("🌉 Bridge: GetPlayerData for " .. player.Name)

			-- Return cached data or default
			if TempPlayerData[player.UserId] then
				local data = TempPlayerData[player.UserId]
				print("🌉 Bridge: Returning bridge data for " .. player.Name .. " (coins: " .. (data.coins or 0) .. ")")

				-- Debug seed inventory
				if data.farming and data.farming.inventory then
					local seedCount = 0
					for item, quantity in pairs(data.farming.inventory) do
						if item:find("_seeds") then
							print("🌱 Bridge: " .. player.Name .. " has " .. quantity .. "x " .. item)
							seedCount = seedCount + 1
						end
					end
					if seedCount == 0 then
						print("⚠️  Bridge: " .. player.Name .. " has NO SEEDS in bridge data")
					end
				end

				return data
			else
				local defaultData = getDefaultPlayerData()
				TempPlayerData[player.UserId] = defaultData
				print("🌉 Bridge: Created new default data for " .. player.Name)
				return defaultData
			end
		end
		print("✅ Bridge: GetPlayerData handler ready")
	end

	-- GetShopItems handler
	local getShopItems = remoteFolder:FindFirstChild("GetShopItems")
	if getShopItems and getShopItems:IsA("RemoteFunction") then
		getShopItems.OnServerInvoke = function(player)
			if ShopSystemInitialized then
				-- Let ShopSystem handle it
				return nil
			end

			print("🌉 Bridge: GetShopItems for " .. player.Name)
			return getDefaultShopItems()
		end
		print("✅ Bridge: GetShopItems handler ready")
	end

	-- GetFarmingData handler
	local getFarmingData = remoteFolder:FindFirstChild("GetFarmingData")
	if getFarmingData and getFarmingData:IsA("RemoteFunction") then
		getFarmingData.OnServerInvoke = function(player)
			print("🌉 Bridge: GetFarmingData for " .. player.Name)

			local playerData = TempPlayerData[player.UserId]
			if playerData and playerData.farming then
				print("🌉 Bridge: Returning farming data for " .. player.Name)
				return playerData.farming
			else
				print("🌉 Bridge: No farming data, returning default")
				return {plots = 0, inventory = {}}
			end
		end
		print("✅ Bridge: GetFarmingData handler ready")
	end
end

-- Setup basic event handlers for shopping and core game functions
local function setupBasicEventHandlers()
	-- PurchaseItem handler - FIXED: Now actually processes purchases
	local purchaseItem = remoteFolder:FindFirstChild("PurchaseItem")
	if purchaseItem and purchaseItem:IsA("RemoteEvent") then
		purchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
			if ShopSystemInitialized then
				return -- Let ShopSystem handle it
			end

			quantity = quantity or 1
			print("🌉 Bridge: Processing purchase - " .. player.Name .. " wants " .. quantity .. "x " .. itemId)

			-- Get or create player data
			if not TempPlayerData[player.UserId] then
				TempPlayerData[player.UserId] = getDefaultPlayerData()
			end

			local playerData = TempPlayerData[player.UserId]

			-- Find the item in shop catalog
			local shopItems = getDefaultShopItems()
			local item = nil
			for _, shopItem in ipairs(shopItems) do
				if shopItem.id == itemId then
					item = shopItem
					break
				end
			end

			if not item then
				local showNotification = remoteFolder:FindFirstChild("ShowNotification")
				if showNotification then
					showNotification:FireClient(player, "❌ Item Not Found", 
						"The item " .. itemId .. " is not available for purchase.", "error")
				end
				return
			end

			-- Check if player can afford it
			local totalCost = item.price * quantity
			local playerCurrency = playerData[item.currency] or 0

			if playerCurrency < totalCost then
				local currencyName = item.currency == "farmTokens" and "Farm Tokens" or "Coins"
				local showNotification = remoteFolder:FindFirstChild("ShowNotification")
				if showNotification then
					showNotification:FireClient(player, "❌ Insufficient Funds", 
						"You need " .. totalCost .. " " .. currencyName .. " but only have " .. playerCurrency .. "!", "error")
				end
				return
			end

			-- Process the purchase
			local success = processPurchase(playerData, item, quantity)

			if success then
				-- Send confirmation events
				local itemPurchased = remoteFolder:FindFirstChild("ItemPurchased")
				if itemPurchased then
					itemPurchased:FireClient(player, itemId, quantity, totalCost, item.currency)
				end

				local playerDataUpdated = remoteFolder:FindFirstChild("PlayerDataUpdated")
				if playerDataUpdated then
					playerDataUpdated:FireClient(player, playerData)
				end

				print("✅ Bridge: Purchase successful - " .. quantity .. "x " .. itemId .. " for " .. totalCost .. " " .. item.currency)
				print("🌉 Bridge: Player " .. player.Name .. " now has " .. (playerData.farming.inventory[itemId] or 0) .. "x " .. itemId)
			else
				local showNotification = remoteFolder:FindFirstChild("ShowNotification")
				if showNotification then
					showNotification:FireClient(player, "❌ Purchase Failed", 
						"Could not complete the purchase. Please try again.", "error")
				end
			end
		end)
		print("✅ Bridge: PurchaseItem handler ready")
	end

	-- PlantSeed handler - ADDED: Handle farm plot clicks in bridge mode
	local plantSeed = remoteFolder:FindFirstChild("PlantSeed")
	if plantSeed and plantSeed:IsA("RemoteEvent") then
		plantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			if GameCoreInitialized then
				return -- Let GameCore handle it
			end

			print("🌉 Bridge: PlantSeed request - " .. player.Name .. " wants to plant " .. seedId)

			-- Get player data
			if not TempPlayerData[player.UserId] then
				TempPlayerData[player.UserId] = getDefaultPlayerData()
			end

			local playerData = TempPlayerData[player.UserId]

			-- Check if player has the seed
			local seedCount = 0
			if playerData.farming and playerData.farming.inventory then
				seedCount = playerData.farming.inventory[seedId] or 0
			end

			if seedCount <= 0 then
				local showNotification = remoteFolder:FindFirstChild("ShowNotification")
				if showNotification then
					showNotification:FireClient(player, "❌ No Seeds", 
						"You don't have any " .. seedId:gsub("_", " ") .. "! Buy some from the shop.", "error")
				end
				return
			end

			-- In bridge mode, just simulate planting (remove seed, show notification)
			playerData.farming.inventory[seedId] = playerData.farming.inventory[seedId] - 1

			-- Update client data
			local playerDataUpdated = remoteFolder:FindFirstChild("PlayerDataUpdated")
			if playerDataUpdated then
				playerDataUpdated:FireClient(player, playerData)
			end

			local showNotification = remoteFolder:FindFirstChild("ShowNotification")
			if showNotification then
				showNotification:FireClient(player, "🌱 Seed Planted! (Bridge Mode)", 
					"Planted " .. seedId:gsub("_", " ") .. "! Full farming will work when GameCore loads.", "success")
			end

			print("✅ Bridge: Simulated planting " .. seedId .. " for " .. player.Name)
		end)
		print("✅ Bridge: PlantSeed handler ready")
	end

	-- ENHANCED: Handle the farm plot click to show seed selection
	-- This is triggered when a player clicks on a farm plot
	local showSeedSelection = remoteFolder:FindFirstChild("ShowSeedSelection")
	if not showSeedSelection then
		showSeedSelection = Instance.new("RemoteEvent")
		showSeedSelection.Name = "ShowSeedSelection"
		showSeedSelection.Parent = remoteFolder
	end

	showSeedSelection.OnServerEvent:Connect(function(player, plotModel)
		if GameCoreInitialized then
			return -- Let GameCore handle it
		end

		print("🌉 Bridge: Farm plot clicked by " .. player.Name)

		-- Get player data
		if not TempPlayerData[player.UserId] then
			TempPlayerData[player.UserId] = getDefaultPlayerData()
		end

		local playerData = TempPlayerData[player.UserId]

		-- Check for seeds
		local hasSeeds = false
		if playerData.farming and playerData.farming.inventory then
			for itemId, quantity in pairs(playerData.farming.inventory) do
				if itemId:find("_seeds") and quantity > 0 then
					hasSeeds = true
					break
				end
			end
		end

		if hasSeeds then
			-- Send PlantSeed event to client to show seed selection
			local plantSeedEvent = remoteFolder:FindFirstChild("PlantSeed")
			if plantSeedEvent then
				plantSeedEvent:FireClient(player, plotModel)
			end
		else
			local showNotification = remoteFolder:FindFirstChild("ShowNotification")
			if showNotification then
				showNotification:FireClient(player, "🌱 No Seeds Available", 
					"You need to buy seeds from the shop first! Try carrot seeds (25 coins).", "warning")
			end
		end
	end)

	-- SellItem handler - Already working
	local sellItem = remoteFolder:FindFirstChild("SellItem")
	if sellItem and sellItem:IsA("RemoteEvent") then
		sellItem.OnServerEvent:Connect(function(player, itemId, quantity)
			if ShopSystemInitialized then
				return -- Let ShopSystem handle it
			end

			quantity = quantity or 1
			print("🌉 Bridge: Processing sale - " .. player.Name .. " selling " .. quantity .. "x " .. itemId)

			-- Get or create player data
			if not TempPlayerData[player.UserId] then
				TempPlayerData[player.UserId] = getDefaultPlayerData()
			end

			local playerData = TempPlayerData[player.UserId]

			-- Find the item in player's inventory and get sell price
			local availableQuantity, sellPrice, sellCurrency = findPlayerItemForSale(playerData, itemId)

			if availableQuantity < quantity then
				local showNotification = remoteFolder:FindFirstChild("ShowNotification")
				if showNotification then
					showNotification:FireClient(player, "❌ Not Enough Items", 
						"You only have " .. availableQuantity .. "x " .. getItemDisplayName(itemId) .. "!", "error")
				end
				return
			end

			-- Process the sale
			local success = processSale(playerData, itemId, quantity, sellPrice, sellCurrency)

			if success then
				local totalEarnings = sellPrice * quantity

				-- Send confirmation events
				local itemSold = remoteFolder:FindFirstChild("ItemSold")
				if itemSold then
					itemSold:FireClient(player, itemId, quantity, totalEarnings, sellCurrency)
				end

				local playerDataUpdated = remoteFolder:FindFirstChild("PlayerDataUpdated")
				if playerDataUpdated then
					playerDataUpdated:FireClient(player, playerData)
				end

				print("✅ Bridge: Sold " .. quantity .. "x " .. itemId .. " for " .. totalEarnings .. " " .. sellCurrency)
			else
				local showNotification = remoteFolder:FindFirstChild("ShowNotification")
				if showNotification then
					showNotification:FireClient(player, "❌ Sale Failed", 
						"Could not complete the sale. Please try again.", "error")
				end
			end
		end)
		print("✅ Bridge: SellItem handler ready")
	end
end

-- Helper function to process purchases
function processPurchase(playerData, item, quantity)
	local success, error = pcall(function()
		local totalCost = item.price * quantity

		-- Deduct currency
		playerData[item.currency] = (playerData[item.currency] or 0) - totalCost

		-- Add item to appropriate inventory based on type
		if item.type == "seed" then
			-- Add to farming inventory
			if not playerData.farming then playerData.farming = {inventory = {}} end
			if not playerData.farming.inventory then playerData.farming.inventory = {} end
			playerData.farming.inventory[item.id] = (playerData.farming.inventory[item.id] or 0) + quantity

		elseif item.type == "farmPlot" then
			-- Handle farm plots
			if item.id == "farm_plot_starter" then
				playerData.farming = playerData.farming or {}
				playerData.farming.plots = 1
				playerData.farming.inventory = playerData.farming.inventory or {}

				-- Add starter seeds if specified
				if item.effects and item.effects.starterSeeds then
					for seedId, amount in pairs(item.effects.starterSeeds) do
						playerData.farming.inventory[seedId] = (playerData.farming.inventory[seedId] or 0) + amount
					end
				end
			elseif item.id == "farm_plot_expansion" then
				local currentPlots = playerData.farming and playerData.farming.plots or 0
				playerData.farming = playerData.farming or {}
				playerData.farming.plots = currentPlots + quantity
			end

		elseif item.type == "chicken" then
			-- Add to defense inventory
			if not playerData.defense then playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}} end
			if not playerData.defense.chickens then playerData.defense.chickens = {owned = {}, deployed = {}, feed = {}} end
			if not playerData.defense.chickens.owned then playerData.defense.chickens.owned = {} end

			for i = 1, quantity do
				local chickenId = "chicken_" .. os.time() .. "_" .. i
				playerData.defense.chickens.owned[chickenId] = {
					type = item.id,
					purchaseTime = os.time(),
					status = "available"
				}
			end

		elseif item.type == "tool" then
			-- Add to general inventory
			if not playerData.inventory then playerData.inventory = {} end
			playerData.inventory[item.id] = (playerData.inventory[item.id] or 0) + quantity

		elseif item.type == "upgrade" then
			-- Add to upgrades
			if not playerData.upgrades then playerData.upgrades = {} end
			playerData.upgrades[item.id] = (playerData.upgrades[item.id] or 0) + quantity

		else
			-- Generic item - add to general inventory
			if not playerData.inventory then playerData.inventory = {} end
			playerData.inventory[item.id] = (playerData.inventory[item.id] or 0) + quantity
		end

		-- Mark as purchased for single-purchase items
		if item.maxPurchase == 1 then
			if not playerData.purchaseHistory then playerData.purchaseHistory = {} end
			playerData.purchaseHistory[item.id] = true
		end

		-- Update stats
		if not playerData.stats then playerData.stats = {} end
		playerData.stats.itemsPurchased = (playerData.stats.itemsPurchased or 0) + quantity
		playerData.stats.coinsSpent = (playerData.stats.coinsSpent or 0) + (item.currency == "coins" and (item.price * quantity) or 0)

		return true
	end)

	if not success then
		print("❌ Bridge: Purchase processing failed: " .. tostring(error))
		return false
	end

	return true
end

-- Helper function to find player items for selling
function findPlayerItemForSale(playerData, itemId)
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

	-- Check various inventory locations
	local inventoryLocations = {
		{"farming", "inventory"},
		{"livestock", "inventory"},
		{"defense", "chickens", "feed"},
		{"inventory"}
	}

	-- Special handling for milk
	if itemId == "milk" or itemId == "fresh_milk" then
		if playerData.milk and playerData.milk > 0 then
			return playerData.milk, priceData.price, priceData.currency
		end
	end

	-- Check all inventory locations
	for _, locationPath in ipairs(inventoryLocations) do
		local inventory = playerData
		for _, key in ipairs(locationPath) do
			if inventory and inventory[key] then
				inventory = inventory[key]
			else
				inventory = nil
				break
			end
		end

		if inventory and inventory[itemId] and inventory[itemId] > 0 then
			return inventory[itemId], priceData.price, priceData.currency
		end
	end

	return 0, priceData.price, priceData.currency
end

-- Helper function to process the sale
function processSale(playerData, itemId, quantity, sellPrice, sellCurrency)
	local success, error = pcall(function()
		local totalEarnings = sellPrice * quantity

		-- Remove items from inventory
		local removed = false

		-- Special handling for milk
		if itemId == "milk" or itemId == "fresh_milk" then
			if playerData.milk and playerData.milk >= quantity then
				playerData.milk = playerData.milk - quantity
				removed = true
			end
		end

		-- Check inventory locations if not milk
		if not removed then
			local inventoryLocations = {
				{"farming", "inventory"},
				{"livestock", "inventory"},
				{"defense", "chickens", "feed"},
				{"inventory"}
			}

			for _, locationPath in ipairs(inventoryLocations) do
				local inventory = playerData
				for _, key in ipairs(locationPath) do
					if inventory and inventory[key] then
						inventory = inventory[key]
					else
						inventory = nil
						break
					end
				end

				if inventory and inventory[itemId] and inventory[itemId] >= quantity then
					inventory[itemId] = inventory[itemId] - quantity
					removed = true
					break
				end
			end
		end

		if not removed then
			error("Could not find items to remove")
		end

		-- Add currency
		playerData[sellCurrency] = (playerData[sellCurrency] or 0) + totalEarnings

		-- Update stats
		if not playerData.stats then
			playerData.stats = {}
		end
		playerData.stats.itemsSold = (playerData.stats.itemsSold or 0) + quantity
		playerData.stats.coinsEarned = (playerData.stats.coinsEarned or 0) + (sellCurrency == "coins" and totalEarnings or 0)

		return true
	end)

	if not success then
		print("❌ Bridge: Sale processing failed: " .. tostring(error))
		return false
	end

	return true
end

-- Helper function to get item display name
function getItemDisplayName(itemId)
	local displayNames = {
		carrot = "🥕 Carrot", corn = "🌽 Corn", strawberry = "🍓 Strawberry",
		golden_fruit = "✨ Golden Fruit", milk = "🥛 Fresh Milk", fresh_milk = "🥛 Fresh Milk",
		chicken_egg = "🥚 Chicken Egg"
	}

	return displayNames[itemId] or itemId:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

-- Monitor for proper system initialization
local function monitorSystems()
	spawn(function()
		while true do
			wait(5) -- Check every 5 seconds

			-- Check for GameCore
			if not GameCoreInitialized and _G.GameCore then
				GameCoreInitialized = true
				print("🎮 Bridge: GameCore detected and initialized!")
			end

			-- Check for ShopSystem
			if not ShopSystemInitialized and _G.ShopSystem then
				ShopSystemInitialized = true
				print("🛒 Bridge: ShopSystem detected and initialized!")
			end

			-- If both are initialized, we can reduce monitoring
			if GameCoreInitialized and ShopSystemInitialized then
				print("🎉 Bridge: All systems initialized! Bridge will remain for stability.")
				break
			end
		end
	end)
end

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
	if TempPlayerData[player.UserId] then
		TempPlayerData[player.UserId] = nil
		print("🧹 Bridge: Cleaned up data for " .. player.Name)
	end
end)

-- Welcome new players
Players.PlayerAdded:Connect(function(player)
	wait(2) -- Give them time to load

	local showNotification = remoteFolder:FindFirstChild("ShowNotification")
	if showNotification then
		showNotification:FireClient(player, "🌉 Welcome to Pet Palace!", 
			"Game systems are loading... You can start playing immediately!", "success")
	end

	print("👋 Bridge: " .. player.Name .. " connected")
end)

-- Main initialization
setupAllRemotes()
setupStableHandlers()
setupBasicEventHandlers()
monitorSystems()

-- Global access for debugging
_G.ServerBridge = {
	GameCoreInitialized = function() return GameCoreInitialized end,
	ShopSystemInitialized = function() return ShopSystemInitialized end,
	TempPlayerData = TempPlayerData,
	GetPlayerCount = function() 
		local count = 0
		for _ in pairs(TempPlayerData) do count = count + 1 end
		return count
	end,
	-- Debug function to check player inventory
	DebugPlayerInventory = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then
			print("Player not found: " .. playerName)
			return
		end

		local playerData = TempPlayerData[player.UserId]
		if not playerData then
			print("No data for player: " .. playerName)
			return
		end

		print("=== INVENTORY DEBUG FOR " .. playerName .. " ===")
		print("Coins: " .. (playerData.coins or 0))
		print("Farm Tokens: " .. (playerData.farmTokens or 0))
		print("Direct milk: " .. (playerData.milk or 0))

		if playerData.farming and playerData.farming.inventory then
			print("Farming inventory:")
			for item, quantity in pairs(playerData.farming.inventory) do
				print("  " .. item .. ": " .. quantity)
			end
		end

		if playerData.livestock and playerData.livestock.inventory then
			print("Livestock inventory:")
			for item, quantity in pairs(playerData.livestock.inventory) do
				print("  " .. item .. ": " .. quantity)
			end
		end
		print("=======================================")
	end,
	-- Function to give player items for testing
	GiveTestItems = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then
			print("Player not found: " .. playerName)
			return
		end

		if not TempPlayerData[player.UserId] then
			TempPlayerData[player.UserId] = getDefaultPlayerData()
		end

		local playerData = TempPlayerData[player.UserId]

		-- Add test items
		playerData.milk = (playerData.milk or 0) + 5
		if not playerData.farming then playerData.farming = {inventory = {}} end
		if not playerData.farming.inventory then playerData.farming.inventory = {} end

		playerData.farming.inventory.carrot = (playerData.farming.inventory.carrot or 0) + 10
		playerData.farming.inventory.corn = (playerData.farming.inventory.corn or 0) + 8
		playerData.farming.inventory.strawberry = (playerData.farming.inventory.strawberry or 0) + 5

		-- Update client
		local playerDataUpdated = remoteFolder:FindFirstChild("PlayerDataUpdated")
		if playerDataUpdated then
			playerDataUpdated:FireClient(player, playerData)
		end

		local showNotification = remoteFolder:FindFirstChild("ShowNotification")
		if showNotification then
			showNotification:FireClient(player, "🎁 Test Items Added!", 
				"Added sellable items to your inventory for testing!", "success")
		end

		print("✅ Added test items to " .. playerName)
	end,
	-- Function to give player coins for testing purchases
	GiveTestCoins = function(playerName, amount)
		amount = amount or 1000
		local player = Players:FindFirstChild(playerName)
		if not player then
			print("Player not found: " .. playerName)
			return
		end

		if not TempPlayerData[player.UserId] then
			TempPlayerData[player.UserId] = getDefaultPlayerData()
		end

		local playerData = TempPlayerData[player.UserId]

		-- Add coins
		playerData.coins = (playerData.coins or 0) + amount
		playerData.farmTokens = (playerData.farmTokens or 0) + math.floor(amount / 10)

		-- Update client
		local playerDataUpdated = remoteFolder:FindFirstChild("PlayerDataUpdated")
		if playerDataUpdated then
			playerDataUpdated:FireClient(player, playerData)
		end

		local showNotification = remoteFolder:FindFirstChild("ShowNotification")
		if showNotification then
			showNotification:FireClient(player, "💰 Test Currency Added!", 
				"Added " .. amount .. " coins and " .. math.floor(amount / 10) .. " farm tokens for testing!", "success")
		end

		print("✅ Added " .. amount .. " coins to " .. playerName)
	end,
	-- Function to debug seed inventory specifically
	DebugSeeds = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then
			print("Player not found: " .. playerName)
			return
		end

		local playerData = TempPlayerData[player.UserId]
		if not playerData then
			print("No bridge data for player: " .. playerName)
			return
		end

		print("=== SEED INVENTORY DEBUG FOR " .. playerName .. " ===")
		print("Coins: " .. (playerData.coins or 0))
		print("Farm Tokens: " .. (playerData.farmTokens or 0))

		if playerData.farming and playerData.farming.inventory then
			print("Seeds found:")
			local seedCount = 0
			for item, quantity in pairs(playerData.farming.inventory) do
				if item:find("_seeds") then
					print("  " .. item .. ": " .. quantity)
					seedCount = seedCount + 1
				end
			end
			if seedCount == 0 then
				print("  ❌ NO SEEDS FOUND!")
				print("All farming inventory items:")
				for item, quantity in pairs(playerData.farming.inventory) do
					print("    " .. item .. ": " .. quantity)
				end
			end
		else
			print("❌ No farming inventory found!")
		end
		print("============================================")
	end,
	-- Function to force sync player data to client
	ForceSyncPlayer = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then
			print("Player not found: " .. playerName)
			return
		end

		local playerData = TempPlayerData[player.UserId]
		if not playerData then
			print("No bridge data for player: " .. playerName)
			return
		end

		-- Force send updated data to client
		local playerDataUpdated = remoteFolder:FindFirstChild("PlayerDataUpdated")
		if playerDataUpdated then
			playerDataUpdated:FireClient(player, playerData)
			print("✅ Forced sync of player data to " .. playerName)
		else
			print("❌ PlayerDataUpdated remote not found")
		end
	end
}

print("=== PERMANENT SERVER BRIDGE READY ===")
print("✅ All remotes created and stable handlers set")
print("🌉 Acting as bridge until GameCore and ShopSystem initialize")
print("📱 Clients can now connect without errors")
print("🔍 Monitoring for proper system initialization...")

-- Status update every 30 seconds
spawn(function()
	while true do
		wait(30)
		local playerCount = 0
		for _ in pairs(TempPlayerData) do playerCount = playerCount + 1 end

		print("🌉 Bridge Status: GameCore=" .. (GameCoreInitialized and "✅" or "⏳") .. 
			" ShopSystem=" .. (ShopSystemInitialized and "✅" or "⏳") .. 
			" Players=" .. playerCount)
	end
end)