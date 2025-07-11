--[[
    ENHANCED GameClient.lua - Enhanced Inventory Integration
    Place in: ReplicatedStorage/GameClient.lua
    
    ENHANCEMENTS:
    ✅ Added inventory data methods for UIManager
    ✅ Enhanced player data structure handling
    ✅ Added milk tracking and updates
    ✅ Improved data refresh for inventory menus
    ✅ Added planting mode integration
]]

local GameClient = {}

-- Services ONLY - no external module requires
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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

-- ENHANCED: Game State with inventory tracking
GameClient.FarmingState = {
	selectedSeed = nil,
	isPlantingMode = false,
	selectedCrop = nil,
	seedInventory = {},
	activeBoosters = {},
	rarityPreview = nil
}

-- ENHANCED: Cache with inventory data
GameClient.Cache = {
	CowCooldown = 0,
	LastDataUpdate = 0,
	LastInventoryUpdate = 0,
	InventoryHash = ""
}

-- ========== INITIALIZATION ==========

function GameClient:Initialize(uiManager)
	print("GameClient: Starting ENHANCED initialization...")

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

	-- ENHANCED: Setup periodic inventory refresh
	self:SetupInventoryRefresh()

	print("GameClient: 🎉 ENHANCED initialization complete!")
	return true
end

-- ========== REMOTE CONNECTIONS ==========

function GameClient:SetupRemoteConnections()
	print("GameClient: Setting up ENHANCED remote connections...")

	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remotes then
		error("GameClient: GameRemotes folder not found after 10 seconds!")
	end

	self.RemoteEvents = {}
	self.RemoteFunctions = {}

	-- ENHANCED: Core game events with inventory support
	local requiredRemoteEvents = {
		-- Core game events
		"PlayerDataUpdated", "ShowNotification",
		-- Farming events
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		-- Inventory events
		"InventoryUpdated", "ItemSold", "ItemPurchased",
		-- Milking events
		"StartMilkingSession", "StopMilkingSession", "ContinueMilking", "MilkingSessionUpdate",
		-- Proximity events
		"OpenShop", "CloseShop"
	}

	-- ENHANCED: Functions with inventory support
	local requiredRemoteFunctions = {
		"GetPlayerData", "GetFarmingData", "GetInventoryData", "GetMiningData", "GetCraftingData"
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

	self:SetupEventHandlers()

	print("GameClient: ENHANCED remote connections established")
	print("  RemoteEvents: " .. self:CountTable(self.RemoteEvents))
	print("  RemoteFunctions: " .. self:CountTable(self.RemoteFunctions))
end

function GameClient:SetupEventHandlers()
	print("GameClient: Setting up ENHANCED event handlers...")

	if self.ActiveConnections then
		for _, connection in pairs(self.ActiveConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end
	self.ActiveConnections = {}

	local eventHandlers = {
		-- ENHANCED: Player Data Updates with inventory refresh
		PlayerDataUpdated = function(newData)
			pcall(function() 
				self:HandlePlayerDataUpdate(newData)
				self:RefreshInventoryDisplays()
			end)
		end,

		-- ENHANCED: Inventory-specific updates
		InventoryUpdated = function(inventoryType, newInventory)
			pcall(function()
				self:HandleInventoryUpdate(inventoryType, newInventory)
			end)
		end,

		ItemSold = function(itemId, quantity, totalValue)
			pcall(function()
				self:HandleItemSold(itemId, quantity, totalValue)
			end)
		end,

		ItemPurchased = function(itemId, quantity, cost, currency)
			pcall(function()
				self:HandleItemPurchased(itemId, quantity, cost, currency)
			end)
		end,

		-- Farming System
		PlantSeed = function(plotModel)
			pcall(function()
				print("GameClient: Received plot click, showing seed selection for", plotModel.Name)
				self:ShowSeedSelectionForPlot(plotModel)
			end)
		end,

		-- Notification Handler
		ShowNotification = function(title, message, notificationType)
			pcall(function() 
				if self.UIManager then
					self.UIManager:ShowNotification(title, message, notificationType)
				end
			end)
		end,
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

-- ========== ENHANCED DATA MANAGEMENT ==========

function GameClient:GetPlayerData()
	return self.PlayerData
end

-- ADDED: Get specific inventory data for UI
function GameClient:GetInventoryData(inventoryType)
	if not self.PlayerData then return {} end

	if inventoryType == "farming" then
		return self.PlayerData.farming and self.PlayerData.farming.inventory or {}
	elseif inventoryType == "mining" then
		return self.PlayerData.mining and self.PlayerData.mining.inventory or {}
	elseif inventoryType == "crafting" then
		return self.PlayerData.crafting and self.PlayerData.crafting.inventory or {}
	elseif inventoryType == "livestock" then
		return self.PlayerData.livestock or {}
	elseif inventoryType == "upgrades" then
		return self.PlayerData.upgrades or {}
	end

	return {}
end

-- ADDED: Get farming-specific data
function GameClient:GetFarmingData()
	return self.PlayerData.farming or {
		plots = 0,
		inventory = {},
		level = 1
	}
end

-- ADDED: Get mining-specific data
function GameClient:GetMiningData()
	return self.PlayerData.mining or {
		inventory = {},
		tools = {},
		level = 1
	}
end

-- ADDED: Get crafting-specific data
function GameClient:GetCraftingData()
	return self.PlayerData.crafting or {
		inventory = {},
		recipes = {},
		stations = {}
	}
end

-- ADDED: Get livestock data
function GameClient:GetLivestockData()
	return self.PlayerData.livestock or {
		cows = {}
	}
end

-- ========== ENHANCED EVENT HANDLERS ==========

function GameClient:HandlePlayerDataUpdate(newData)
	if not newData then return end

	local oldData = self.PlayerData
	self.PlayerData = newData

	-- Update currency display through UIManager (including milk)
	if self.UIManager then
		self.UIManager:UpdateCurrencyDisplay(newData)
	end

	-- ENHANCED: Check for inventory changes
	local inventoryChanged = self:CheckInventoryChanges(oldData, newData)
	if inventoryChanged then
		self:RefreshInventoryDisplays()
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

	-- Handle planting mode seed check
	if self.FarmingState.isPlantingMode and self.FarmingState.selectedSeed then
		local currentSeeds = newData.farming and newData.farming.inventory or {}
		local newSeedCount = currentSeeds[self.FarmingState.selectedSeed] or 0

		local oldSeeds = oldData and oldData.farming and oldData.farming.inventory or {}
		local oldSeedCount = oldSeeds[self.FarmingState.selectedSeed] or 0

		if newSeedCount <= 0 then
			if oldSeedCount <= 0 then
				self:ExitPlantingMode()
				if self.UIManager then
					self.UIManager:ShowNotification("Out of Seeds", 
						"You don't have any " .. (self.FarmingState.selectedSeed or ""):gsub("_", " ") .. " to plant!", "warning")
				end
			else
				self:ExitPlantingMode()
				if self.UIManager then
					self.UIManager:ShowNotification("Last Seed Planted", 
						"You planted your last " .. (self.FarmingState.selectedSeed or ""):gsub("_", " ") .. "! Buy more seeds to continue planting.", "info")
				end
			end
		end
	end
end

-- ADDED: Handle inventory-specific updates
function GameClient:HandleInventoryUpdate(inventoryType, newInventory)
	print("GameClient: Handling inventory update for " .. inventoryType)

	if inventoryType == "farming" then
		if self.PlayerData.farming then
			self.PlayerData.farming.inventory = newInventory
		end
	elseif inventoryType == "mining" then
		if self.PlayerData.mining then
			self.PlayerData.mining.inventory = newInventory
		end
	elseif inventoryType == "crafting" then
		if self.PlayerData.crafting then
			self.PlayerData.crafting.inventory = newInventory
		end
	end

	-- Update currency if this affects it
	if self.UIManager then
		self.UIManager:UpdateCurrencyDisplay(self.PlayerData)
	end

	-- Refresh inventory displays
	self:RefreshInventoryDisplays()
end

-- ADDED: Handle item sold notification
function GameClient:HandleItemSold(itemId, quantity, totalValue)
	print("GameClient: Item sold - " .. itemId .. " x" .. quantity .. " for " .. totalValue)

	if self.UIManager then
		local itemName = ItemConfig.ShopItems[itemId] and ItemConfig.ShopItems[itemId].name or itemId
		self.UIManager:ShowNotification("💰 Item Sold", 
			"Sold " .. quantity .. "x " .. itemName:gsub("🥕 ", ""):gsub("🌱 ", "") .. " for " .. totalValue .. " coins!", "success")
	end

	-- Refresh inventory displays
	self:RefreshInventoryDisplays()
end

-- ADDED: Handle item purchased notification
function GameClient:HandleItemPurchased(itemId, quantity, cost, currency)
	print("GameClient: Item purchased - " .. itemId .. " x" .. quantity .. " for " .. cost .. " " .. currency)

	if self.UIManager then
		local itemName = ItemConfig.ShopItems[itemId] and ItemConfig.ShopItems[itemId].name or itemId
		local currencyName = currency == "farmTokens" and "Farm Tokens" or "Coins"
		self.UIManager:ShowNotification("🛒 Purchase Complete", 
			"Bought " .. quantity .. "x " .. itemName:gsub("🥕 ", ""):gsub("🌱 ", "") .. "!", "success")
	end

	-- Refresh inventory displays
	self:RefreshInventoryDisplays()
end

-- ADDED: Check if inventory has changed
function GameClient:CheckInventoryChanges(oldData, newData)
	if not oldData or not newData then return true end

	-- Simple hash-based change detection
	local oldHash = self:GenerateInventoryHash(oldData)
	local newHash = self:GenerateInventoryHash(newData)

	if oldHash ~= newHash then
		self.Cache.InventoryHash = newHash
		self.Cache.LastInventoryUpdate = tick()
		return true
	end

	return false
end

-- ADDED: Generate inventory hash for change detection
function GameClient:GenerateInventoryHash(data)
	local hashString = ""

	-- Include relevant inventory data
	if data.farming and data.farming.inventory then
		for k, v in pairs(data.farming.inventory) do
			hashString = hashString .. k .. ":" .. v .. ";"
		end
	end

	if data.mining and data.mining.inventory then
		for k, v in pairs(data.mining.inventory) do
			hashString = hashString .. k .. ":" .. v .. ";"
		end
	end

	if data.crafting and data.crafting.inventory then
		for k, v in pairs(data.crafting.inventory) do
			hashString = hashString .. k .. ":" .. v .. ";"
		end
	end

	-- Include milk count
	hashString = hashString .. "milk:" .. (data.milk or 0) .. ";"

	-- Include currency
	hashString = hashString .. "coins:" .. (data.coins or 0) .. ";"
	hashString = hashString .. "farmTokens:" .. (data.farmTokens or 0) .. ";"

	return hashString
end

-- ADDED: Refresh inventory displays in UI
function GameClient:RefreshInventoryDisplays()
	if not self.UIManager then return end

	local currentPage = self.UIManager:GetCurrentPage()
	if currentPage == "Farm" or currentPage == "Mining" or currentPage == "Crafting" then
		-- Add small delay to ensure data is fully updated
		spawn(function()
			wait(0.1)
			self.UIManager:RefreshMenuContent(currentPage)
		end)
	end
end

-- ========== ENHANCED INVENTORY REFRESH SYSTEM ==========

function GameClient:SetupInventoryRefresh()
	print("GameClient: Setting up periodic inventory refresh...")

	-- Refresh inventory data every 30 seconds to ensure sync
	spawn(function()
		while true do
			wait(30)
			if self.RemoteFunctions.GetPlayerData then
				local success, data = pcall(function()
					return self.RemoteFunctions.GetPlayerData:InvokeServer()
				end)

				if success and data then
					-- Check if data has changed
					if self:CheckInventoryChanges(self.PlayerData, data) then
						print("GameClient: Periodic inventory sync - changes detected")
						self:HandlePlayerDataUpdate(data)
					end
				end
			end
		end
	end)
end

-- ========== ENHANCED PLANTING SYSTEM ==========

function GameClient:StartPlantingMode(seedId)
	print("GameClient: Starting ENHANCED planting mode with seed:", seedId)

	-- Verify player has seeds
	local seedInventory = self:GetInventoryData("farming")
	local seedCount = seedInventory[seedId] or 0

	if seedCount <= 0 then
		if self.UIManager then
			self.UIManager:ShowNotification("No Seeds", "You don't have any " .. seedId:gsub("_", " ") .. " to plant!", "warning")
		end
		return false
	end

	self.FarmingState.selectedSeed = seedId
	self.FarmingState.isPlantingMode = true

	if self.UIManager then
		local seedName = ItemConfig.ShopItems[seedId] and ItemConfig.ShopItems[seedId].name or seedId
		self.UIManager:ShowNotification("🌱 Planting Mode", 
			"Selected " .. seedName:gsub("🌱 ", "") .. "! Go to your farm and click on empty plots to plant.", "success")
	end

	return true
end

function GameClient:ExitPlantingMode()
	print("GameClient: Exiting planting mode")
	self.FarmingState.selectedSeed = nil
	self.FarmingState.isPlantingMode = false
	if self.UIManager then
		self.UIManager:ShowNotification("🌱 Planting Mode", "Planting mode deactivated", "info")
	end
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
		elseif input.KeyCode == Enum.KeyCode.I then
			-- ADDED: Inventory shortcut
			local currentPage = self.UIManager and self.UIManager:GetCurrentPage()
			if currentPage == "None" then
				self:OpenMenu("Farm") -- Default to farm for inventory
			else
				self.UIManager:CloseActiveMenus()
			end
		end
	end)

	print("GameClient: Enhanced input handling setup complete")
	print("  Available hotkeys: F=Farm, M=Mining, C=Crafting, H=Harvest All, I=Inventory, ESC=Close")
	print("  Shop access: Proximity only via ShopTouchPart")
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

-- ========== PROXIMITY SYSTEM HANDLERS ==========

function GameClient:SetupProximitySystemHandlers()
	print("GameClient: Setting up proximity system handlers...")

	if self.RemoteEvents.OpenShop then
		self.RemoteEvents.OpenShop.OnClientEvent:Connect(function()
			print("GameClient: Proximity shop triggered - opening shop menu")
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

	print("GameClient: Proximity system handlers setup complete")
end

function GameClient:OpenShopProximity()
	print("GameClient: Opening shop via proximity system")
	if self.UIManager then
		return self.UIManager:OpenMenu("Shop")
	end
	return false
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

	print("GameClient: Enhanced farming system logic setup complete")
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
					milk = 0, -- ADDED
					upgrades = {},
					purchaseHistory = {},
					farming = {
						plots = 0,
						inventory = {}
					},
					mining = {
						inventory = {},
						tools = {},
						level = 1
					},
					crafting = {
						inventory = {},
						recipes = {},
						stations = {}
					},
					livestock = {
						cows = {}
					}
				})
			end
		end)
	else
		warn("GameClient: GetPlayerData remote function not available")
	end
end

-- ========== UTILITY FUNCTIONS ==========

function GameClient:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== ENHANCED DEBUG FUNCTIONS ==========

function GameClient:DebugStatus()
	print("=== ENHANCED GAMECLIENT DEBUG STATUS ===")
	print("PlayerData exists:", self.PlayerData ~= nil)
	if self.PlayerData then
		print("  Coins:", self.PlayerData.coins or "N/A")
		print("  Farm Tokens:", self.PlayerData.farmTokens or "N/A") 
		print("  Milk:", self.PlayerData.milk or "N/A") -- ADDED
		print("  Farming data exists:", self.PlayerData.farming ~= nil)
		if self.PlayerData.farming then
			print("    Seeds:", self:CountTable(self.PlayerData.farming.inventory or {}))
		end
		print("  Mining data exists:", self.PlayerData.mining ~= nil)
		if self.PlayerData.mining then
			print("    Ores:", self:CountTable(self.PlayerData.mining.inventory or {}))
			print("    Tools:", self:CountTable(self.PlayerData.mining.tools or {}))
		end
		print("  Crafting data exists:", self.PlayerData.crafting ~= nil)
		if self.PlayerData.crafting then
			print("    Materials:", self:CountTable(self.PlayerData.crafting.inventory or {}))
		end
		print("  Livestock data exists:", self.PlayerData.livestock ~= nil)
		if self.PlayerData.livestock then
			print("    Cows:", #(self.PlayerData.livestock.cows or {}))
		end
	end
	print("UIManager exists:", self.UIManager ~= nil)
	if self.UIManager then
		print("  Current page:", self.UIManager:GetCurrentPage() or "None")
	end
	print("RemoteEvents count:", self.RemoteEvents and self:CountTable(self.RemoteEvents) or 0)
	print("RemoteFunctions count:", self.RemoteFunctions and self:CountTable(self.RemoteFunctions) or 0)
	print("Shop access: PROXIMITY ONLY")
	print("Available hotkeys: F=Farm, M=Mining, C=Crafting, H=Harvest All, I=Inventory")
	print("Planting mode active:", self.FarmingState.isPlantingMode)
	if self.FarmingState.isPlantingMode then
		print("  Selected seed:", self.FarmingState.selectedSeed)
	end
	print("Last inventory update:", self.Cache.LastInventoryUpdate)
	print("=========================================")
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
		CowCooldown = 0,
		LastDataUpdate = 0,
		LastInventoryUpdate = 0,
		InventoryHash = ""
	}

	print("GameClient: Enhanced cleanup completed")
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

print("GameClient: ✅ ENHANCED VERSION LOADED!")
print("🎯 NEW FEATURES:")
print("  ✅ Enhanced inventory data handling")
print("  ✅ Milk tracking integration")
print("  ✅ Real-time inventory refresh")
print("  ✅ Improved planting mode with inventory checks")
print("  ✅ Mining and crafting data support")
print("  ✅ Periodic inventory sync")
print("  ✅ Enhanced notification system")
print("")
print("🔧 Enhanced hotkeys:")
print("  F = Farm Menu (Seeds, Crops, Livestock, Upgrades)")
print("  M = Mining Menu (Ores, Tools, Progress)")
print("  C = Crafting Menu (Stations, Materials, Recipes)")
print("  H = Harvest All Crops")
print("  I = Toggle Inventory (Farm menu)")
print("  ESC = Close all menus")

return GameClient