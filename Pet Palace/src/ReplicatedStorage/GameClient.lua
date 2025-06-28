--[[
    UPDATED GameClient.lua - Tabbed Shop Support
    Place in: ReplicatedStorage/GameClient.lua
    
    CHANGES:
    ✅ Enhanced shop menu opening for tabbed system
    ✅ Support for tab-specific item filtering
    ✅ Better shop state management
    ✅ Enhanced purchase confirmations for categories
]]

local GameClient = {}

-- Services ONLY - no external module requires
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load ItemConfig safely
local ItemConfig = nil
local function loadItemConfig()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig"))
	end)
	if success then
		ItemConfig = result
		print("GameClient: ItemConfig loaded successfully")
	else
		warn("GameClient: Could not load ItemConfig: " .. tostring(result))
	end
end

-- Player and Game State
local LocalPlayer = Players.LocalPlayer
GameClient.PlayerData = {}
GameClient.RemoteEvents = {}
GameClient.RemoteFunctions = {}
GameClient.ActiveConnections = {}

-- References to UIManager (injected during initialization)
GameClient.UIManager = nil

-- Game State
GameClient.FarmingState = {
	selectedSeed = nil,
	isPlantingMode = false,
	selectedCrop = nil,
	seedInventory = {},
	activeBoosters = {},
	rarityPreview = nil
}

GameClient.Cache = {
	ShopItems = {},
	CowCooldown = 0,
	PigState = {},
	-- NEW: Shop tab cache
	ShopTabCache = {},
	LastShopRefresh = 0
}

-- ========== INITIALIZATION ==========

function GameClient:Initialize(uiManager)
	print("GameClient: Starting enhanced core initialization with tabbed shop support...")

	self.UIManager = uiManager

	local success, errorMsg

	-- Step 1: Load ItemConfig
	success, errorMsg = pcall(function()
		loadItemConfig()
	end)
	if not success then
		error("GameClient initialization failed at step 'ItemConfig': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ ItemConfig initialized")

	-- Step 2: Setup Remote Connections
	success, errorMsg = pcall(function()
		self:SetupRemoteConnections()
	end)
	if not success then
		error("GameClient initialization failed at step 'RemoteConnections': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ RemoteConnections initialized")

	-- Step 3: Establish UIManager connection
	if self.UIManager then
		self.UIManager:SetGameClient(self)
		print("GameClient: ✅ UIManager reference established")
	else
		error("GameClient: UIManager not provided during initialization")
	end

	-- Step 4: Setup Input Handling
	success, errorMsg = pcall(function()
		self:SetupInputHandling()
	end)
	if not success then
		error("GameClient initialization failed at step 'InputHandling': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ InputHandling initialized")

	-- Step 5: Setup Proximity System Handlers
	success, errorMsg = pcall(function()
		self:SetupProximitySystemHandlers()
	end)
	if not success then
		error("GameClient initialization failed at step 'ProximitySystemHandlers': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ ProximitySystemHandlers initialized")

	-- Step 6: Setup Farming System Logic
	success, errorMsg = pcall(function()
		self:SetupFarmingSystemLogic()
	end)
	if not success then
		error("GameClient initialization failed at step 'FarmingSystemLogic': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ FarmingSystemLogic initialized")

	-- Step 7: Request Initial Data
	success, errorMsg = pcall(function()
		self:RequestInitialData()
	end)
	if not success then
		error("GameClient initialization failed at step 'InitialData': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ InitialData initialized")

	print("GameClient: 🎉 Enhanced initialization complete with tabbed shop support!")
	return true
end

-- ========== INPUT HANDLING ==========

function GameClient:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			if self.UIManager then
				self.UIManager:CloseActiveMenus()
			end
		elseif input.KeyCode == Enum.KeyCode.F then
			self:OpenMenu("Farm")
		elseif input.KeyCode == Enum.KeyCode.M then
			self:OpenMenu("Mining")
		elseif input.KeyCode == Enum.KeyCode.C then
			self:OpenMenu("Crafting")
		elseif input.KeyCode == Enum.KeyCode.H then
			self:RequestHarvestAll()
		end
	end)

	print("GameClient: Input handling setup complete (shop hotkey removed)")
	print("  Available hotkeys: F=Farm, M=Mining, C=Crafting, H=Harvest All, ESC=Close")
	print("  Shop access: Proximity only via ShopTouchPart")
end

-- ========== FARMING SYSTEM LOGIC ==========

function GameClient:SetupFarmingSystemLogic()
	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {},
		activeBoosters = {},
		rarityPreview = nil
	}

	print("GameClient: Farming system logic setup complete")
end

-- ========== MENU AND ACTION METHODS ==========

function GameClient:OpenMenu(menuName)
	if menuName == "Shop" then
		print("GameClient: Shop menu opening blocked - use proximity system")
		if self.UIManager then
			self.UIManager:ShowNotification("Shop Access", "Step on the shop area to access the shop!", "info")
		end
		return false
	end

	if self.UIManager then
		return self.UIManager:OpenMenu(menuName)
	end
	return false
end

function GameClient:CloseMenus()
	if self.UIManager then
		self.UIManager:CloseActiveMenus()
	end
end

function GameClient:RequestHarvestAll()
	if not self.RemoteEvents.HarvestAllCrops then
		if self.UIManager then
			self.UIManager:ShowNotification("System Error", "Harvest All system not available!", "error")
		end
		return
	end

	if self.UIManager then
		self.UIManager:ShowNotification("🌾 Harvesting...", "Checking all crops for harvest...", "info")
	end
	self.RemoteEvents.HarvestAllCrops:FireServer()
	print("GameClient: Sent harvest all request to server")
end

-- ========== REMOTE CONNECTIONS ==========

function GameClient:SetupRemoteConnections()
	print("GameClient: Setting up enhanced remote connections...")

	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remotes then
		error("GameClient: GameRemotes folder not found after 10 seconds!")
	end

	self.RemoteEvents = {}
	self.RemoteFunctions = {}

	local requiredRemoteEvents = {
		-- Core game events
		"CollectMilk", "FeedPig", "PlayerDataUpdated", "ShowNotification",
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		"PestSpotted", "PestEliminated", "ChickenPlaced", "ChickenMoved",
		"FeedAllChickens", "FeedChickensWithType", "UsePesticide",

		-- Shop events (enhanced for tabbed system)
		"PurchaseItem", "ItemPurchased", "SellItem", "ItemSold", "CurrencyUpdated",

		-- Proximity events
		"OpenShop", "CloseShop", "ShowPigFeedingUI", "HidePigFeedingUI"
	}

	local requiredRemoteFunctions = {
		-- Core functions
		"GetPlayerData", "GetFarmingData",

		-- Shop functions (enhanced for tabbed system)
		"GetShopItems", "GetShopItemsByCategory", "GetSellableItems" -- ADD GetSellableItems HERE
	}


	-- Load remote events
	for _, eventName in ipairs(requiredRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if remote and remote:IsA("RemoteEvent") then
			self.RemoteEvents[eventName] = remote
			print("GameClient: ✅ Connected RemoteEvent: " .. eventName)
		else
			warn("GameClient: ⚠️  Missing RemoteEvent: " .. eventName)
		end
	end

	-- Load remote functions
	for _, funcName in ipairs(requiredRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if remote and remote:IsA("RemoteFunction") then
			self.RemoteFunctions[funcName] = remote
			print("GameClient: ✅ Connected RemoteFunction: " .. funcName)
		else
			warn("GameClient: ⚠️  Missing RemoteFunction: " .. funcName)
		end
	end

	self:SetupAllEventHandlers()

	print("GameClient: Enhanced remote connections established")
	print("  RemoteEvents: " .. self:CountTable(self.RemoteEvents))
	print("  RemoteFunctions: " .. self:CountTable(self.RemoteFunctions))
end

function GameClient:SetupAllEventHandlers()
	print("GameClient: Setting up all event handlers...")

	if self.ActiveConnections then
		for _, connection in pairs(self.ActiveConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end
	self.ActiveConnections = {}

	local eventHandlers = {
		-- Player Data Updates
		PlayerDataUpdated = function(newData)
			pcall(function() self:HandlePlayerDataUpdate(newData) end)
		end,

		-- Farming System
		PlantSeed = function(plotModel)
			pcall(function()
				print("GameClient: Received plot click, showing seed selection for", plotModel.Name)
				self:ShowSeedSelectionForPlot(plotModel)
			end)
		end,

		-- Enhanced Shop System Events
		ItemPurchased = function(itemId, quantity, cost, currency)
			pcall(function() self:HandleEnhancedItemPurchased(itemId, quantity, cost, currency) end)
		end,

		ItemSold = function(itemId, quantity, earnings, currency)
			pcall(function() self:HandleItemSold(itemId, quantity, earnings, currency) end)
		end,

		CurrencyUpdated = function(currencyData)
			pcall(function() self:HandleCurrencyUpdate(currencyData) end)
		end,

		-- Notification Handler
		ShowNotification = function(title, message, notificationType)
			pcall(function() 
				if self.UIManager then
					self.UIManager:ShowNotification(title, message, notificationType) 
				end
			end)
		end,

		-- Pest Control Events
		PestSpotted = function(pestType, cropType, plotInfo)
			pcall(function() self:HandlePestSpottedNotification(pestType, cropType, plotInfo) end)
		end,

		PestEliminated = function(pestType, eliminatedBy)
			pcall(function() self:HandlePestEliminatedNotification(pestType, eliminatedBy) end)
		end,

		-- Chicken Events
		ChickenPlaced = function(chickenType, position)
			pcall(function() self:HandleChickenPlacedNotification(chickenType, position) end)
		end
	}

	-- Connect all handlers
	for eventName, handler in pairs(eventHandlers) do
		if self.RemoteEvents[eventName] then
			local connection = self.RemoteEvents[eventName].OnClientEvent:Connect(handler)
			table.insert(self.ActiveConnections, connection)
			print("GameClient: ✅ Connected " .. eventName)
		else
			warn("GameClient: ❌ Missing remote event: " .. eventName)
		end
	end
end

-- ========== PROXIMITY SYSTEM HANDLERS ==========

function GameClient:SetupProximitySystemHandlers()
	print("GameClient: Setting up proximity system handlers...")

	if self.RemoteEvents.OpenShop then
		self.RemoteEvents.OpenShop.OnClientEvent:Connect(function()
			print("GameClient: Proximity shop triggered - opening tabbed shop menu")
			self:OpenShopProximity()
		end)
	end

	if self.RemoteEvents.CloseShop then
		self.RemoteEvents.CloseShop.OnClientEvent:Connect(function()
			print("GameClient: Proximity shop close triggered")
			if self.UIManager and self.UIManager:GetCurrentPage() == "Shop" then
				self.UIManager:CloseActiveMenus()
			end
		end)
	end

	if self.RemoteEvents.ShowPigFeedingUI then
		self.RemoteEvents.ShowPigFeedingUI.OnClientEvent:Connect(function()
			self:ShowPigFeedingInterface()
		end)
	end

	if self.RemoteEvents.HidePigFeedingUI then
		self.RemoteEvents.HidePigFeedingUI.OnClientEvent:Connect(function()
			self:HidePigFeedingInterface()
		end)
	end

	print("GameClient: Proximity system handlers setup complete")
end

-- ========== EVENT HANDLERS ==========

function GameClient:HandlePlayerDataUpdate(newData)
	if not newData then return end

	local oldData = self.PlayerData
	self.PlayerData = newData

	-- Update currency display through UIManager
	if self.UIManager then
		self.UIManager:UpdateCurrencyDisplay(newData)
	end

	-- Update current page if needed
	local currentPage = self.UIManager and self.UIManager:GetCurrentPage()
	if currentPage == "Shop" then
		-- Refresh the active shop tab if shop is open
		if self.UIManager then 
			self.UIManager:RefreshMenuContent("Shop") 
		end
	elseif currentPage == "Farm" then
		if self.UIManager then self.UIManager:RefreshMenuContent("Farm") end
	elseif currentPage == "Mining" then
		if self.UIManager then self.UIManager:RefreshMenuContent("Mining") end
	elseif currentPage == "Crafting" then
		if self.UIManager then self.UIManager:RefreshMenuContent("Crafting") end
	end

	-- FIXED: Smart planting mode seed check
	if self.FarmingState.isPlantingMode and self.FarmingState.selectedSeed then
		local currentSeeds = newData.farming and newData.farming.inventory or {}
		local newSeedCount = currentSeeds[self.FarmingState.selectedSeed] or 0

		-- Get old seed count for comparison
		local oldSeeds = oldData and oldData.farming and oldData.farming.inventory or {}
		local oldSeedCount = oldSeeds[self.FarmingState.selectedSeed] or 0

		-- Only show "out of seeds" if:
		-- 1. We have 0 seeds now, AND
		-- 2. We had 0 seeds before (meaning no successful planting just happened)
		-- This prevents the error when successfully planting the last seed
		if newSeedCount <= 0 then
			if oldSeedCount <= 0 then
				-- We already had no seeds and still have no seeds - this is a real "no seeds" situation
				self:ExitPlantingMode()
				if self.UIManager then
					self.UIManager:ShowNotification("Out of Seeds", 
						"You don't have any " .. (self.FarmingState.selectedSeed or ""):gsub("_", " ") .. " to plant!", "warning")
				end
			else
				-- We had seeds before but now have 0 - this means we just planted our last seed successfully
				-- Don't show error, but do exit planting mode
				self:ExitPlantingMode()
				if self.UIManager then
					self.UIManager:ShowNotification("Last Seed Planted", 
						"You planted your last " .. (self.FarmingState.selectedSeed or ""):gsub("_", " ") .. "! Buy more seeds to continue planting.", "info")
				end
			end
		end
	end
end

-- ENHANCED: Shop event handlers for tabbed system
function GameClient:HandleEnhancedItemPurchased(itemId, quantity, cost, currency)
	print("🎉 CLIENT: Received enhanced purchase confirmation!")
	print("    Item: " .. tostring(itemId))
	print("    Quantity: " .. tostring(quantity))

	-- Update local data
	if self.PlayerData then
		print("💳 CLIENT: Updating local currency data")
		local safeCost = cost or 0
		local safeCurrency = currency or "coins"
		local oldAmount = self.PlayerData[safeCurrency] or 0
		self.PlayerData[safeCurrency] = math.max(0, oldAmount - safeCost)

		if self.UIManager then
			self.UIManager:UpdateCurrencyDisplay(self.PlayerData)
		end
	end

	-- Enhanced category-aware notifications
	local categoryEmoji = self:GetCategoryEmoji(itemId)
	local itemCategory = self:GetItemCategory(itemId)

	if itemId:find("_seeds") then
		if self.UIManager then
			self.UIManager:ShowNotification(categoryEmoji .. " Seeds Purchased!", 
				"Added " .. tostring(quantity) .. "x " .. itemId:gsub("_", " ") .. " to your farming inventory!", "success")
		end
	elseif itemId == "farm_plot_starter" then
		if self.UIManager then
			self.UIManager:ShowNotification("🌾 Farm Plot Created!", 
				"Your farm plot is ready! Press F to start farming.", "success")
		end
	elseif itemCategory == "defense" then
		if self.UIManager then
			self.UIManager:ShowNotification("🛡️ Defense Purchase!", 
				"Added " .. itemId:gsub("_", " ") .. " to your defense arsenal!", "success")
		end
	elseif itemCategory == "mining" then
		if self.UIManager then
			self.UIManager:ShowNotification("⛏️ Mining Equipment!", 
				"Added " .. itemId:gsub("_", " ") .. " to your mining tools!", "success")
		end
	elseif itemCategory == "crafting" then
		if self.UIManager then
			self.UIManager:ShowNotification("🔨 Crafting Station!", 
				"Built " .. itemId:gsub("_", " ") .. " for your workshop!", "success")
		end
	elseif itemCategory == "premium" then
		if self.UIManager then
			self.UIManager:ShowNotification("✨ Premium Purchase!", 
				"Unlocked premium " .. itemId:gsub("_", " ") .. "!", "success")
		end
	else
		if self.UIManager then
			self.UIManager:ShowNotification("🛒 Purchase Complete!", 
				"Purchased " .. itemId, "success")
		end
	end

	-- Refresh shop if open (specific to active tab)
	if self.UIManager and self.UIManager:GetCurrentPage() == "Shop" then
		spawn(function()
			wait(0.5) -- Wait for server data update
			self.UIManager:RefreshMenuContent("Shop")
		end)
	end

	print("✅ CLIENT: Enhanced purchase handling completed")
end

function GameClient:HandleItemSold(itemId, quantity, earnings, currency)
	print("💰 CLIENT: Received sell confirmation!")
	print("    Item: " .. tostring(itemId))
	print("    Quantity: " .. tostring(quantity))
	print("    Earnings: " .. tostring(earnings))

	if self.PlayerData then
		local safeCurrency = currency or "coins"
		local safeEarnings = earnings or 0
		self.PlayerData[safeCurrency] = (self.PlayerData[safeCurrency] or 0) + safeEarnings

		if self.UIManager then
			self.UIManager:UpdateCurrencyDisplay(self.PlayerData)
		end
	end

	if self.UIManager then
		local itemName = self:GetItemDisplayName(itemId)
		local totalValue = quantity * (earnings / quantity) -- Calculate per-item price

		self.UIManager:ShowNotification("💰 Item Sold!", 
			"Sold " .. tostring(quantity) .. "x " .. itemName .. " for " .. tostring(earnings) .. " " .. currency .. "!", "success")
	end

	-- Refresh sell tab if shop is open and sell tab is active
	if self.UIManager and self.UIManager:GetCurrentPage() == "Shop" then
		if self.State.ActiveShopTab == "sell" then
			spawn(function()
				wait(0.5) -- Wait for server data update
				if self.UIManager then
					self.UIManager:PopulateShopTabContent("sell")
				end
			end)
		end
	end
end

function GameClient:RefreshMenuContent(menuName)
	if self.State.CurrentPage ~= menuName then return end

	print("GameClient: Refreshing content for " .. menuName)

	if menuName == "Shop" then
		-- Refresh current shop tab (including sell tab)
		local activeTab = self.State.ShopTabs and self.State.ShopTabs[self.State.ActiveShopTab]
		if activeTab then
			activeTab.populated = false
			if self.UIManager then
				self.UIManager:PopulateShopTabContent(self.State.ActiveShopTab)
			end
		end
	else
		local currentMenus = self.State.ActiveMenus
		self:CloseMenus()

		spawn(function()
			wait(0.1)
			self:OpenMenu(menuName)
		end)
	end
end

function GameClient:HandleCurrencyUpdate(currencyData)
	if currencyData and self.PlayerData then
		for currency, amount in pairs(currencyData) do
			self.PlayerData[currency] = amount
		end
		if self.UIManager then
			self.UIManager:UpdateCurrencyDisplay(self.PlayerData)
		end
	end
end

function GameClient:ShowSeedSelectionForPlot(plotModel)
	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		if self.UIManager then
			self.UIManager:ShowNotification("No Seeds", "You need to buy seeds from the shop first!", "warning")
		end
		return
	end

	local availableSeeds = {}
	for itemId, quantity in pairs(playerData.farming.inventory) do
		if itemId:find("_seeds") and quantity > 0 then
			table.insert(availableSeeds, {id = itemId, quantity = quantity})
		end
	end

	if #availableSeeds == 0 then
		if self.UIManager then
			self.UIManager:ShowNotification("No Seeds", "You don't have any seeds to plant! Buy some from the shop.", "warning")
		end
		return
	end

	self:CreateSimpleSeedSelectionUI(plotModel, availableSeeds)
end

function GameClient:HandlePestSpottedNotification(pestType, cropType, plotInfo)
	local pestName = pestType:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	if self.UIManager then
		self.UIManager:ShowNotification("🐛 Pest Alert!", 
			pestName .. " spotted on your " .. cropType .. " crop! Deploy chickens or use pesticide.", "warning")
	end
end

function GameClient:HandlePestEliminatedNotification(pestType, eliminatedBy)
	local pestName = pestType:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	if self.UIManager then
		self.UIManager:ShowNotification("✅ Pest Eliminated!", 
			pestName .. " eliminated by " .. eliminatedBy .. "!", "success")
	end
end

function GameClient:HandleChickenPlacedNotification(chickenType, position)
	if self.UIManager then
		self.UIManager:ShowNotification("🐔 Chicken Deployed!", 
			self:GetChickenDisplayName(chickenType) .. " is now protecting your farm!", "success")
	end
end

function GameClient:GetChickenDisplayName(chickenType)
	local names = {
		basic_chicken = "Basic Chicken",
		guinea_fowl = "Guinea Fowl",
		rooster = "Rooster"
	}
	return names[chickenType] or chickenType:gsub("_", " ")
end

-- ========== FARMING MODE FUNCTIONS ==========

function GameClient:StartPlantingMode(seedId)
	print("GameClient: Starting planting mode with seed:", seedId)
	self.FarmingState.selectedSeed = seedId
	self.FarmingState.isPlantingMode = true
	if self.UIManager then
		self.UIManager:ShowNotification("🌱 Planting Mode", "Go to your farm and click on plots to plant seeds!", "success")
	end
end

function GameClient:ExitPlantingMode()
	print("GameClient: Exiting planting mode")
	self.FarmingState.selectedSeed = nil
	self.FarmingState.isPlantingMode = false
	if self.UIManager then
		self.UIManager:ShowNotification("🌱 Planting Mode", "Planting mode deactivated", "info")
	end
end

-- ========== DATA MANAGEMENT ==========

function GameClient:RequestInitialData()
	print("GameClient: Requesting initial data from server...")

	if self.RemoteFunctions.GetPlayerData then
		spawn(function()
			local success, data = pcall(function()
				return self.RemoteFunctions.GetPlayerData:InvokeServer()
			end)

			if success and data then
				print("GameClient: Received initial data from server")
				self:HandlePlayerDataUpdate(data)
			else
				warn("GameClient: Failed to get initial data: " .. tostring(data))
				self:HandlePlayerDataUpdate({
					coins = 0,
					farmTokens = 0,
					upgrades = {},
					purchaseHistory = {},
					farming = {
						plots = 0,
						inventory = {}
					},
					pig = {
						size = 1.0,
						cropPoints = 0,
						transformationCount = 0,
						totalFed = 0
					}
				})
			end
		end)
	else
		warn("GameClient: GetPlayerData remote function not available")
	end
end

function GameClient:GetPlayerData()
	return self.PlayerData
end

-- ========== ENHANCED SHOP SYSTEM METHODS ==========

function GameClient:GetShopItems()
	print("🛒 CLIENT: Requesting shop items for tabbed system...")

	-- Try to get from cache first
	local currentTime = tick()
	if self.Cache.ShopItems and #self.Cache.ShopItems > 0 and 
		(currentTime - self.Cache.LastShopRefresh) < 30 then
		print("🛒 CLIENT: Using cached shop items")
		return self.Cache.ShopItems
	end

	-- Request fresh data from server
	if self.RemoteFunctions and self.RemoteFunctions.GetShopItems then
		print("🛒 CLIENT: Using ShopSystem RemoteFunction")
		local success, items = pcall(function()
			return self.RemoteFunctions.GetShopItems:InvokeServer()
		end)

		if success and items and type(items) == "table" then
			print("🛒 CLIENT: Received " .. #items .. " items from ShopSystem")

			local validItems = {}
			for _, item in ipairs(items) do
				if item.id and item.name and item.price and item.currency and item.category then
					table.insert(validItems, item)
				else
					warn("🛒 CLIENT: Invalid item received: " .. tostring(item.id))
				end
			end

			print("🛒 CLIENT: " .. #validItems .. " valid items after validation")
			if #validItems > 0 then
				-- Cache the results
				self.Cache.ShopItems = validItems
				self.Cache.LastShopRefresh = currentTime
				return validItems
			end
		else
			warn("🛒 CLIENT: ShopSystem RemoteFunction failed: " .. tostring(items))
		end
	else
		warn("🛒 CLIENT: GetShopItems RemoteFunction not available")
	end

	return {}
end

function GameClient:GetShopItemsByCategory(category)
	print("🛒 CLIENT: Requesting items for category: " .. category)

	-- Check if we have cached data for this category
	if self.Cache.ShopTabCache[category] then
		local cacheData = self.Cache.ShopTabCache[category]
		local currentTime = tick()

		if (currentTime - cacheData.timestamp) < 30 then
			print("🛒 CLIENT: Using cached data for " .. category)
			return cacheData.items
		end
	end

	-- Get all items and filter by category
	local allItems = self:GetShopItems()
	local categoryItems = {}

	for _, item in ipairs(allItems) do
		if item.category == category then
			table.insert(categoryItems, item)
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

	-- Cache the filtered results
	self.Cache.ShopTabCache[category] = {
		items = categoryItems,
		timestamp = tick()
	}

	print("🛒 CLIENT: Filtered " .. #categoryItems .. " items for " .. category .. " category")
	return categoryItems
end
function GameClient:GetSellableItems()
	print("💰 CLIENT: Requesting sellable items...")

	-- Request sellable items from server
	if self.RemoteFunctions and self.RemoteFunctions.GetSellableItems then
		print("💰 CLIENT: Using GetSellableItems RemoteFunction")
		local success, items = pcall(function()
			return self.RemoteFunctions.GetSellableItems:InvokeServer()
		end)

		if success and items and type(items) == "table" then
			print("💰 CLIENT: Received " .. #items .. " sellable items")
			return items
		else
			warn("💰 CLIENT: GetSellableItems RemoteFunction failed: " .. tostring(items))
		end
	else
		warn("💰 CLIENT: GetSellableItems RemoteFunction not available")
	end

	return {}
end

function GameClient:PurchaseItem(item)
	if not self:CanAffordItem(item) then
		if self.UIManager then
			self.UIManager:ShowNotification("Insufficient Funds", "You don't have enough " .. item.currency .. "!", "error")
		end
		return
	end

	if self.RemoteEvents.PurchaseItem then
		print("GameClient: Purchasing item via ShopSystem:", item.id, "for", item.price, item.currency)
		self.RemoteEvents.PurchaseItem:FireServer(item.id, 1)

		-- Clear relevant cache after purchase
		self:ClearShopCache(item.category)
	else
		warn("GameClient: PurchaseItem remote event not available")
		if self.UIManager then
			self.UIManager:ShowNotification("Shop Error", "Purchase system unavailable!", "error")
		end
	end
end


function GameClient:SellItem(itemId, quantity)
	if not self.RemoteEvents.SellItem then
		if self.UIManager then
			self.UIManager:ShowNotification("Sell Error", "Sell system not available!", "error")
		end
		return false
	end

	print("💰 CLIENT: Selling " .. quantity .. "x " .. itemId)
	self.RemoteEvents.SellItem:FireServer(itemId, quantity)
	return true
end

function GameClient:CanAffordItem(item)
	if not item or not item.price or not item.currency then
		return false
	end

	local playerData = self:GetPlayerData()
	if not playerData then 
		return false 
	end

	local playerCurrency = playerData[item.currency] or 0
	return playerCurrency >= item.price
end

function GameClient:ClearShopCache(category)
	if category then
		self.Cache.ShopTabCache[category] = nil
		print("🛒 CLIENT: Cleared cache for " .. category .. " category")
	else
		self.Cache.ShopItems = {}
		self.Cache.ShopTabCache = {}
		self.Cache.LastShopRefresh = 0
		print("🛒 CLIENT: Cleared all shop cache")
	end
end

-- ========== CATEGORY HELPER FUNCTIONS ==========

function GameClient:GetCategoryEmoji(itemId)
	local categoryEmojis = {
		seeds = "🌱",
		farm = "🌾",
		defense = "🛡️",
		mining = "⛏️",
		crafting = "🔨",
		premium = "✨"
	}

	local category = self:GetItemCategory(itemId)
	return categoryEmojis[category] or "📦"
end

function GameClient:GetItemCategory(itemId)
	if not ItemConfig or not ItemConfig.ShopItems then
		return "unknown"
	end

	local item = ItemConfig.ShopItems[itemId]
	return item and item.category or "unknown"
end

-- ========== FARMING SYSTEM ==========

function GameClient:CreateSimpleSeedSelectionUI(plotModel, availableSeeds)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local existingUI = playerGui:FindFirstChild("SeedSelectionUI")
	if existingUI then existingUI:Destroy() end

	local seedUI = Instance.new("ScreenGui")
	seedUI.Name = "SeedSelectionUI"
	seedUI.ResetOnSpawn = false
	seedUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	seedUI.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 300, 0, 200)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = seedUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = mainFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	title.BorderSizePixel = 0
	title.Text = "🌱 Select Seed to Plant"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 80, 0, 30)
	closeButton.Position = UDim2.new(0.5, -40, 1, -40)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "Cancel"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = mainFrame

	closeButton.MouseButton1Click:Connect(function()
		seedUI:Destroy()
	end)

	for i, seedData in ipairs(availableSeeds) do
		local seedButton = Instance.new("TextButton")
		seedButton.Size = UDim2.new(1, -20, 0, 30)
		seedButton.Position = UDim2.new(0, 10, 0, 40 + (i * 35))
		seedButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
		seedButton.BorderSizePixel = 0
		seedButton.Text = seedData.id:gsub("_", " ") .. " (x" .. seedData.quantity .. ")"
		seedButton.TextColor3 = Color3.new(1, 1, 1)
		seedButton.TextScaled = true
		seedButton.Font = Enum.Font.Gotham
		seedButton.Parent = mainFrame

		seedButton.MouseButton1Click:Connect(function()
			print("GameClient: Player selected seed:", seedData.id)
			self:PlantSelectedSeed(plotModel, seedData.id)
			seedUI:Destroy()
		end)
	end
end

function GameClient:PlantSelectedSeed(plotModel, seedId)
	print("GameClient: Attempting to plant", seedId, "on plot", plotModel.Name)

	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed:FireServer(plotModel, seedId)
		if self.UIManager then
			self.UIManager:ShowNotification("🌱 Planting...", "Attempting to plant " .. seedId:gsub("_", " ") .. "!", "info")
		end
	else
		warn("GameClient: PlantSeed remote event not available")
		if self.UIManager then
			self.UIManager:ShowNotification("Error", "Planting system not available!", "error")
		end
	end
end

-- ========== PIG FEEDING SYSTEM ==========

function GameClient:ShowPigFeedingInterface()
	print("GameClient: Showing simple pig feeding interface")

	local existingUI = LocalPlayer.PlayerGui:FindFirstChild("PigFeedingUI")
	if existingUI then existingUI:Destroy() end

	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		if self.UIManager then
			self.UIManager:ShowNotification("No Crops", "You need to harvest crops first to feed the pig!", "warning")
		end
		return
	end

	if self.UIManager then
		self.UIManager:ShowNotification("🐷 Pig Feeding", "Pig feeding system active - approach pig to feed!", "info")
	end
end

function GameClient:HidePigFeedingInterface()
	print("GameClient: Hiding pig feeding interface")
	local pigUI = LocalPlayer.PlayerGui:FindFirstChild("PigFeedingUI")
	if pigUI then
		pigUI:Destroy()
	end
end

function GameClient:GetCropDisplayName(cropId)
	local displayNames = {
		carrot = "🥕 Carrot",
		corn = "🌽 Corn", 
		strawberry = "🍓 Strawberry",
		golden_fruit = "✨ Golden Fruit",
		wheat = "🌾 Wheat",
		potato = "🥔 Potato",
		tomato = "🍅 Tomato",
		cabbage = "🥬 Cabbage",
		radish = "🌶️ Radish",
		broccoli = "🥦 Broccoli",
		glorious_sunflower = "🌻 Glorious Sunflower",
		milk = "🥛 Fresh Milk",
		fresh_milk = "🥛 Fresh Milk",
		chicken_egg = "🥚 Chicken Egg",
		guinea_egg = "🥚 Guinea Fowl Egg",
		rooster_egg = "🥚 Rooster Egg",
		copper_ore = "🟫 Copper Ore",
		bronze_ore = "🟤 Bronze Ore",
		silver_ore = "⚪ Silver Ore",
		gold_ore = "🟡 Gold Ore",
		platinum_ore = "⚫ Platinum Ore",
		obsidian_ore = "⬛ Obsidian Ore"
	}

	return displayNames[cropId] or cropId:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

function GameClient:GetItemDisplayName(itemId)
	local names = {
		-- Seeds
		carrot_seeds = "Carrot Seeds",
		corn_seeds = "Corn Seeds",
		strawberry_seeds = "Strawberry Seeds",
		golden_seeds = "Golden Seeds",
		wheat_seeds = "Wheat Seeds",
		potato_seeds = "Potato Seeds",
		cabbage_seeds = "Cabbage Seeds",
		radish_seeds = "Radish Seeds",
		broccoli_seeds = "Broccoli Seeds",
		tomato_seeds = "Tomato Seeds",
		glorious_sunflower_seeds = "Glorious Sunflower Seeds",

		-- Crops
		carrot = "Carrots",
		corn = "Corn",
		strawberry = "Strawberries",
		golden_fruit = "Golden Fruit",
		wheat = "Wheat",
		potato = "Potatoes",
		cabbage = "Cabbage",
		radish = "Radishes",
		broccoli = "Broccoli",
		tomato = "Tomatoes",
		glorious_sunflower = "Glorious Sunflower",

		-- Animal products
		milk = "Fresh Milk",
		fresh_milk = "Fresh Milk",
		chicken_egg = "Chicken Eggs",
		guinea_egg = "Guinea Fowl Eggs",
		rooster_egg = "Rooster Eggs",

		-- Defense items
		basic_chicken = "Basic Chicken",
		guinea_fowl = "Guinea Fowl",
		rooster = "Rooster",
		organic_pesticide = "Organic Pesticide",
		super_pesticide = "Super Pesticide",
		pest_detector = "Pest Detector",
		basic_feed = "Basic Chicken Feed",
		premium_feed = "Premium Chicken Feed",

		-- Mining tools
		basic_pickaxe = "Basic Pickaxe",
		stone_pickaxe = "Stone Pickaxe",
		iron_pickaxe = "Iron Pickaxe",
		diamond_pickaxe = "Diamond Pickaxe",
		obsidian_pickaxe = "Obsidian Pickaxe",
		cave_access_pass = "Cave Access Pass",

		-- Crafting items
		basic_workbench = "Basic Workbench",
		forge = "Advanced Forge",
		mystical_altar = "Mystical Altar",

		-- Premium items
		auto_harvester = "Auto Harvester",
		rarity_booster = "Rarity Booster",
		mega_dome = "Mega Protection Dome",

		-- Cow system
		milk_efficiency_1 = "Enhanced Milking I",
		milk_efficiency_2 = "Enhanced Milking II",
		milk_efficiency_3 = "Enhanced Milking III",
		milk_value_boost = "Premium Milk Quality",

		-- Ores
		copper_ore = "Copper Ore",
		bronze_ore = "Bronze Ore",
		silver_ore = "Silver Ore",
		gold_ore = "Gold Ore",
		platinum_ore = "Platinum Ore",
		obsidian_ore = "Obsidian Ore"
	}

	if names[itemId] then
		return names[itemId]
	else
		return itemId:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	end
end

-- ========== PROXIMITY SHOP METHOD ==========

function GameClient:OpenShopProximity()
	print("GameClient: Opening tabbed shop via proximity system")
	if self.UIManager then
		return self.UIManager:OpenMenu("Shop")
	end
	return false
end

-- ========== UTILITY FUNCTIONS ==========

function GameClient:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== ERROR RECOVERY ==========

function GameClient:RecoverFromError(errorMsg)
	warn("GameClient: Attempting recovery from error: " .. tostring(errorMsg))

	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {},
		activeBoosters = {},
		rarityPreview = nil
	}

	-- Clear shop cache on error
	self:ClearShopCache()

	local success, error = pcall(function()
		self:SetupRemoteConnections()
	end)

	if success then
		print("GameClient: Recovery successful")
		return true
	else
		warn("GameClient: Recovery failed: " .. tostring(error))
		return false
	end
end

-- ========== DEBUG FUNCTIONS ==========

function GameClient:DebugStatus()
	print("=== ENHANCED GAMECLIENT DEBUG STATUS ===")
	print("PlayerData exists:", self.PlayerData ~= nil)
	if self.PlayerData then
		print("  Coins:", self.PlayerData.coins or "N/A")
		print("  Farm Tokens:", self.PlayerData.farmTokens or "N/A") 
		print("  Farming data exists:", self.PlayerData.farming ~= nil)
	end
	print("UIManager exists:", self.UIManager ~= nil)
	if self.UIManager then
		print("  UIManager state exists:", self.UIManager.State ~= nil)
		print("  Current page:", self.UIManager:GetCurrentPage() or "None")
		if self.UIManager.State and self.UIManager.State.ShopTabs then
			print("  Active shop tab:", self.UIManager.State.ActiveShopTab or "None")
		end
	end
	print("RemoteEvents count:", self.RemoteEvents and self:CountTable(self.RemoteEvents) or 0)
	print("RemoteFunctions count:", self.RemoteFunctions and self:CountTable(self.RemoteFunctions) or 0)
	print("Shop cache status:")
	print("  Cached items:", self.Cache.ShopItems and #self.Cache.ShopItems or 0)
	print("  Cached tabs:", self.Cache.ShopTabCache and self:CountTable(self.Cache.ShopTabCache) or 0)
	print("Shop access: PROXIMITY ONLY")
	print("Available hotkeys: F=Farm, M=Mining, C=Crafting, H=Harvest All")
	print("=====================================")
end

function GameClient:DebugShopCache()
print("=== ENHANCED SHOP CACHE DEBUG ===")
print("Total cached items:", self.Cache.ShopItems and #self.Cache.ShopItems or 0)
print("Last refresh:", self.Cache.LastShopRefresh or 0)
print("Tab cache:")
for category, data in pairs(self.Cache.ShopTabCache or {}) do
	print("  " .. category .. ": " .. #data.items .. " items (age: " .. (tick() - data.timestamp) .. "s)")
end

-- Test sellable items
if self.GetSellableItems then
	local sellableItems = self:GetSellableItems()
	print("Current sellable items: " .. #sellableItems)
	for i, item in ipairs(sellableItems) do
		print("  " .. item.name .. ": " .. item.stock .. " in stock (value: " .. item.totalValue .. " coins)")
	end
end
print("========================")
end

-- ========== CLEANUP ==========

function GameClient:Cleanup()
	if self.ActiveConnections then
		for _, connection in pairs(self.ActiveConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end

	if self.UIManager then
		self.UIManager:Cleanup()
	end

	self.PlayerData = {}
	self.ActiveConnections = {}
	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {},
		activeBoosters = {},
		rarityPreview = nil
	}
	self.Cache = {
		ShopItems = {},
		CowCooldown = 0,
		PigState = {},
		ShopTabCache = {},
		LastShopRefresh = 0
	}

	print("GameClient: Cleaned up")
end

-- ========== GLOBAL REGISTRATION ==========

_G.GameClient = GameClient

_G.GetGameClient = function()
	return _G.GameClient
end

_G.DebugGameClient = function()
	if _G.GameClient and _G.GameClient.DebugStatus then
		_G.GameClient:DebugStatus()
	end
end

_G.DebugShopCache = function()
	if _G.GameClient and _G.GameClient.DebugShopCache then
		_G.GameClient:DebugShopCache()
	end
end

_G.TestFarm = function()
	if _G.GameClient then
		_G.GameClient:OpenMenu("Farm")
	end
end

print("GameClient: ✅ Enhanced for tabbed shop system!")
print("🎯 Changes Made:")
print("  🛒 Enhanced shop system with tab support")
print("  📦 Smart caching for better performance")
print("  🏷️ Category-aware purchase notifications")
print("  🔄 Tab-specific cache management")
print("  📊 Enhanced debugging tools")
print("")
print("🔧 Available Features:")
print("  🛒 Shop: Tabbed interface via proximity")
print("  🌾 Farming: F key or button")
print("  ⛏️ Mining: M key or button")
print("  🔨 Crafting: C key or button")
print("  🌾 Harvest All: H key")
print("")
print("🔧 Debug Commands:")
print("  _G.TestFarm() - Open farm menu")
print("  _G.DebugGameClient() - Show system status")
print("  _G.DebugShopCache() - Show shop cache status")

return GameClient