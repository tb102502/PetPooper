--[[
    CLEAN GameClient.lua - Core Game Logic
    
    Focuses on game logic, data management, and remote events
    NO EXTERNAL MODULE DEPENDENCIES - Only Roblox services
]]

local GameClient = {}

-- Services ONLY - no external module requires
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load ItemConfig safely - this is the ONLY external module we load
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
	PigState = {}
}

-- ========== INITIALIZATION ==========

function GameClient:Initialize(uiManager)
	print("GameClient: Starting clean core initialization...")

	-- Store UIManager reference
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
		-- Set GameClient reference in UIManager
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

	print("GameClient: 🎉 Clean core initialization complete!")
	return true
end

-- ========== REMOTE CONNECTIONS ==========

function GameClient:SetupRemoteConnections()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
	for _, obj in ipairs(remotes:GetChildren()) do
		if obj:IsA("RemoteEvent") then
			self.RemoteEvents[obj.Name] = obj
		elseif obj:IsA("RemoteFunction") then
			self.RemoteFunctions[obj.Name] = obj
		end
	end

	-- Setup all event handlers
	self:SetupAllEventHandlers()
	print("GameClient: Remote connections established")
end

function GameClient:SetupAllEventHandlers()
	print("GameClient: Setting up all event handlers...")

	-- Clean up existing connections
	if self.ActiveConnections then
		for _, connection in pairs(self.ActiveConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end
	self.ActiveConnections = {}

	-- All event handlers
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

		-- Shop System Events
		ItemPurchased = function(itemId, quantity, cost, currency)
			pcall(function() self:HandleItemPurchased(itemId, quantity, cost, currency) end)
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

	-- Shop proximity handlers
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

	-- Pig proximity handlers
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
		elseif input.KeyCode == Enum.KeyCode.H then
			-- H key for Harvest All
			self:RequestHarvestAll()
		end
	end)
end

-- ========== FARMING SYSTEM LOGIC ==========

function GameClient:SetupFarmingSystemLogic()
	-- Initialize farming state
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
				-- Create default data structure for offline testing
				self:HandlePlayerDataUpdate({
					coins = 100,
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
		if self.UIManager then self.UIManager:RefreshMenuContent("Shop") end
	elseif currentPage == "Farm" then
		if self.UIManager then self.UIManager:RefreshMenuContent("Farm") end
	elseif currentPage == "Stats" then
		if self.UIManager then self.UIManager:RefreshMenuContent("Stats") end
	end

	-- Update planting mode if seeds changed
	if self.FarmingState.isPlantingMode then
		local currentSeeds = newData.farming and newData.farming.inventory or {}
		local selectedSeedCount = currentSeeds[self.FarmingState.selectedSeed] or 0

		if selectedSeedCount <= 0 then
			-- Selected seed is out of stock, exit planting mode
			self:ExitPlantingMode()
			if self.UIManager then
				self.UIManager:ShowNotification("Out of Seeds", "You ran out of " .. (self.FarmingState.selectedSeed or ""):gsub("_", " ") .. "!", "warning")
			end
		end
	end
end

function GameClient:HandleItemPurchased(itemId, quantity, cost, currency)
	print("🎉 CLIENT: Received purchase confirmation!")
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

	-- Show appropriate notification
	if itemId:find("_seeds") then
		if self.UIManager then
			self.UIManager:ShowNotification("🌱 Seeds Purchased!", 
				"Added " .. tostring(quantity) .. "x " .. itemId:gsub("_", " ") .. " to your farming inventory!", "success")
		end
	elseif itemId == "farm_plot_starter" then
		if self.UIManager then
			self.UIManager:ShowNotification("🌾 Farm Plot Created!", 
				"Your farm plot is ready! Press F to start farming.", "success")
		end
	else
		if self.UIManager then
			self.UIManager:ShowNotification("Purchase Complete!", 
				"Purchased " .. itemId, "success")
		end
	end

	-- Refresh shop if open
	if self.UIManager and self.UIManager:GetCurrentPage() == "Shop" then
		spawn(function()
			wait(0.5) -- Wait for server data update
			self.UIManager:RefreshMenuContent("Shop")
		end)
	end

	print("✅ CLIENT: Purchase handling completed")
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

-- ========== SHOP SYSTEM ==========

function GameClient:GetShopItems()
	if self.RemoteFunctions.GetShopItems then
		local success, items = pcall(function()
			return self.RemoteFunctions.GetShopItems:InvokeServer()
		end)

		if success and items then
			print("GameClient: Received shop items from server")
			return items
		else
			warn("GameClient: Failed to get shop items: " .. tostring(items))
		end
	end

	-- Return default items if server call fails
	return self:GetDefaultShopItems()
end

function GameClient:GetDefaultShopItems()
	return {
		-- ========== SEEDS CATEGORY ==========
		{
			id = "carrot_seeds",
			name = "🥕 Carrot Seeds",
			description = "Plant these to grow nutritious carrots! Harvest time: 5 minutes",
			price = 25,
			currency = "coins",
			category = "seeds",
			icon = "🥕",
			maxPurchase = 50
		},
		{
			id = "corn_seeds",
			name = "🌽 Corn Seeds", 
			description = "Sweet corn for the pigs! Harvest time: 8 minutes",
			price = 50,
			currency = "coins",
			category = "seeds",
			icon = "🌽",
			maxPurchase = 50
		},
		{
			id = "strawberry_seeds",
			name = "🍓 Strawberry Seeds", 
			category = "seeds",
			price = 100,
			currency = "coins",
			description = "Sweet strawberries. Ready in 10 minutes. Worth 3 crop points when fed to pig.",
			icon = "🍓",
			maxPurchase = 50
		},
		{
			id = "golden_seeds",
			name = "✨ Golden Seeds",
			category = "premium",
			price = 50,
			currency = "farmTokens",
			description = "Magical golden fruit! Ready in 15 minutes. Worth 10 crop points when fed to pig!",
			icon = "✨",
			maxPurchase = 25
		},

		-- ========== FARM UPGRADES ==========
		{
			id = "farm_plot_starter",
			name = "🌾 Basic Farm Plot",
			description = "Unlock your first farm plot to start growing crops!",
			price = 100,
			currency = "coins", 
			category = "farm",
			icon = "🌾",
			maxPurchase = 1
		},
		{
			id = "farm_plot_expansion",
			name = "🚜 Farm Plot Expansion",
			description = "Add more farming space! Each expansion gives you another farm plot.",
			price = 500,
			currency = "coins",
			category = "farm", 
			icon = "🚜",
			maxPurchase = 9
		},

		-- ========== DEFENSE CATEGORY ==========
		{
			id = "basic_chicken",
			name = "🐔 Basic Chicken",
			category = "defense",
			price = 150,
			currency = "coins",
			description = "General purpose pest control. Eliminates aphids and lays eggs for steady income.",
			icon = "🐔",
			maxPurchase = 20
		},
		{
			id = "organic_pesticide",
			name = "🧪 Organic Pesticide",
			category = "defense",
			price = 50,
			currency = "coins", 
			description = "Manually eliminate pests from crops. One-time use, affects 3x3 area around target crop.",
			icon = "🧪",
			maxPurchase = 20
		},

		-- ========== MINING CATEGORY ==========
		{
			id = "basic_pickaxe",
			name = "⛏️ Basic Pickaxe",
			category = "mining",
			price = 200,
			currency = "coins",
			description = "Essential tool for mining. Allows access to copper and iron deposits.",
			icon = "⛏️",
			maxPurchase = 1
		},

		-- ========== CRAFTING CATEGORY ==========
		{
			id = "basic_workbench",
			name = "🔨 Basic Workbench",
			category = "crafting",
			price = 500,
			currency = "coins",
			description = "Essential crafting station. Craft basic tools and farm equipment.",
			icon = "🔨",
			maxPurchase = 1
		},

		-- ========== PREMIUM CATEGORY ==========
		{
			id = "auto_harvester",
			name = "🤖 Auto Harvester",
			category = "premium",
			price = 150,
			currency = "farmTokens",
			description = "Automatically harvests ready crops every 30 seconds. The ultimate farming upgrade!",
			icon = "🤖",
			maxPurchase = 1
		}
	}
end

function GameClient:PurchaseItem(item)
	if not self:CanAffordItem(item) then
		if self.UIManager then
			self.UIManager:ShowNotification("Insufficient Funds", "You don't have enough " .. item.currency .. "!", "error")
		end
		return
	end

	if self.RemoteEvents.PurchaseItem then
		print("GameClient: Purchasing item:", item.id, "for", item.price, item.currency)
		self.RemoteEvents.PurchaseItem:FireServer(item.id, 1)
	else
		warn("GameClient: PurchaseItem remote event not available")
		if self.UIManager then
			self.UIManager:ShowNotification("Shop Error", "Purchase system unavailable!", "error")
		end
	end
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

-- ========== FARMING SYSTEM ==========

function GameClient:ShowSeedSelectionForPlot(plotModel)
	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		if self.UIManager then
			self.UIManager:ShowNotification("No Seeds", "You need to buy seeds from the shop first!", "warning")
		end
		return
	end

	-- Count available seeds
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

	-- Create seed selection UI (simple version for now)
	self:CreateSimpleSeedSelectionUI(plotModel, availableSeeds)
end

function GameClient:CreateSimpleSeedSelectionUI(plotModel, availableSeeds)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing seed selection UI
	local existingUI = playerGui:FindFirstChild("SeedSelectionUI")
	if existingUI then existingUI:Destroy() end

	-- Create simple seed selection UI
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

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	title.BorderSizePixel = 0
	title.Text = "🌱 Select Seed to Plant"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Close button
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

	-- Create seed buttons
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

		-- Plant this seed when clicked
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

-- ========== PIG FEEDING SYSTEM ==========

function GameClient:ShowPigFeedingInterface()
	print("GameClient: Showing simple pig feeding interface")

	-- Remove existing pig UI
	local existingUI = LocalPlayer.PlayerGui:FindFirstChild("PigFeedingUI")
	if existingUI then existingUI:Destroy() end

	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		if self.UIManager then
			self.UIManager:ShowNotification("No Crops", "You need to harvest crops first to feed the pig!", "warning")
		end
		return
	end

	-- Simple pig feeding notification
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
		golden_fruit = "✨ Golden Fruit"
	}
	return displayNames[cropId] or cropId:gsub("_", " ")
end

-- ========== NOTIFICATION HANDLERS ==========

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

-- ========== PUBLIC API METHODS ==========

function GameClient:OpenMenu(menuName)
	if self.UIManager then
		self.UIManager:OpenMenu(menuName)
	end
end

function GameClient:CloseMenus()
	if self.UIManager then
		self.UIManager:CloseActiveMenus()
	end
end

-- Internal proximity method
function GameClient:OpenShopProximity()
	print("GameClient: Opening shop via proximity system")
	if self.UIManager then
		self.UIManager:OpenMenu("Shop")
	end
end

-- ========== ERROR RECOVERY ==========

function GameClient:RecoverFromError(errorMsg)
	warn("GameClient: Attempting recovery from error: " .. tostring(errorMsg))

	-- Reset critical systems
	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {},
		activeBoosters = {},
		rarityPreview = nil
	}

	-- Try to reconnect remotes
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
	print("=== CLEAN GAMECLIENT DEBUG STATUS ===")
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
	end
	print("RemoteEvents count:", self.RemoteEvents and self:CountTable(self.RemoteEvents) or 0)
	print("RemoteFunctions count:", self.RemoteFunctions and self:CountTable(self.RemoteFunctions) or 0)
	print("===============================")
end

function GameClient:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== CLEANUP ==========

function GameClient:Cleanup()
	-- Cleanup connections
	if self.ActiveConnections then
		for _, connection in pairs(self.ActiveConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end

	-- Cleanup UIManager
	if self.UIManager then
		self.UIManager:Cleanup()
	end

	-- Reset state
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

_G.TestFarm = function()
	if _G.GameClient then
		_G.GameClient:OpenMenu("Farm")
	end
end

_G.TestStats = function()
	if _G.GameClient then
		_G.GameClient:OpenMenu("Stats")
	end
end

print("GameClient: ✅ Clean version loaded successfully!")
print("🎯 Core Features:")
print("  📊 Data management and remote events")
print("  🎮 Game logic and farming system")
print("  🔗 UIManager integration via reference only")
print("  🛡️ Error recovery system")
print("  🚫 NO external module dependencies")
print("")
print("🔧 Debug Commands:")
print("  _G.TestFarm() - Open farm menu")
print("  _G.TestStats() - Open stats menu")
print("  _G.DebugGameClient() - Show system status")

return GameClient