local GameClient = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
GameClient.Cache = {
	ShopItems = {},
	CowCooldown = 0,
	PigState = {}
}

-- UI State with proper initialization
GameClient.UI = {
	MainUI = nil,
	Background = nil,
	Content = nil,
	Navigation = nil,
	Overlay = nil,
	Notifications = nil,
	CurrencyContainer = nil,
	CoinsFrame = nil,
	FarmTokensFrame = nil,
	NavigationBar = nil,
	FarmingUI = nil,
	FarmButton = nil,
	Menus = {},
	PlantingModeUI = nil,
	PigFeedingUI = nil
}

GameClient.UIState = {
	ActiveMenus = {},
	CurrentPage = nil,
	IsTransitioning = false
}

-- Farming state
GameClient.FarmingState = {
	selectedSeed = nil,
	isPlantingMode = false,
	selectedCrop = nil,
	seedInventory = {}
}

-- ========== INITIALIZATION ==========

-- Enhanced Initialize method with proper error handling
function GameClient:Initialize()
	print("GameClient: Starting enhanced initialization...")

	-- Initialize UI table first
	self.UI = self.UI or {}

	-- FIXED: Use direct method calls instead of anonymous functions
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

	-- Step 3: Setup UI (FIXED ORDER)
	success, errorMsg = pcall(function()
		self:SetupUI()
	end)
	if not success then
		error("GameClient initialization failed at step 'UI': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ UI initialized")

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

	-- Step 6: Setup Farming System
	success, errorMsg = pcall(function()
		self:SetupFarmingSystem()
	end)
	if not success then
		error("GameClient initialization failed at step 'FarmingSystem': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ FarmingSystem initialized")

	-- Step 7: Request Initial Data
	success, errorMsg = pcall(function()
		self:RequestInitialData()
	end)
	if not success then
		error("GameClient initialization failed at step 'InitialData': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ InitialData initialized")

	print("GameClient: 🎉 Initialization complete!")
	return true
end

-- ========== REMOTE CONNECTIONS ==========

-- Setup Remote Connections
function GameClient:SetupRemoteConnections()
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("GameClient: GameRemotes folder not found")
		return
	end

	local remoteEvents = {
		-- Shop System (proximity-based)
		"OpenShop", "CloseShop", "PurchaseItem", "ItemPurchased", "CurrencyUpdated",

		-- Pig System (proximity-based)
		"ShowPigFeedingUI", "HidePigFeedingUI", "FeedPig",

		-- Farming System
		"PlantSeed", "HarvestCrop", "SellCrop",

		-- General
		"PlayerDataUpdated", "ShowNotification"
	}

	local remoteFunctions = {
		"GetPlayerData", "GetShopItems", "GetFarmingData"
	}

	-- Connect remote events
	for _, eventName in ipairs(remoteEvents) do
		local event = remoteFolder:FindFirstChild(eventName)
		if event then
			self.RemoteEvents[eventName] = event
		else
			warn("GameClient: Missing remote event: " .. eventName)
		end
	end

	-- Connect remote functions  
	for _, funcName in ipairs(remoteFunctions) do
		local func = remoteFolder:FindFirstChild(funcName)
		if func then
			self.RemoteFunctions[funcName] = func
		else
			warn("GameClient: Missing remote function: " .. funcName)
		end
	end

	self:SetupEventHandlers()
	print("GameClient: Remote connections established")
end

-- Setup Event Handlers
function GameClient:SetupEventHandlers()
	-- Player Data Updates
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function(newData)
			self:HandlePlayerDataUpdate(newData)
		end)
	end

	-- Shop System Events
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased.OnClientEvent:Connect(function(itemId, quantity, cost, currency)
			self:HandleItemPurchased(itemId, quantity, cost, currency)
		end)
	end

	if self.RemoteEvents.CurrencyUpdated then
		self.RemoteEvents.CurrencyUpdated.OnClientEvent:Connect(function(currencyData)
			self:HandleCurrencyUpdate(currencyData)
		end)
	end

	-- Notification Handler
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification.OnClientEvent:Connect(function(title, message, notificationType)
			self:ShowNotification(title, message, notificationType)
		end)
	end

	print("GameClient: Event handlers setup complete")
end

-- ========== PROXIMITY SYSTEM HANDLERS ==========

-- Setup proximity system handlers
function GameClient:SetupProximitySystemHandlers()
	print("GameClient: Setting up proximity system handlers...")

	-- Shop proximity handlers (shop only accessible this way)
	if self.RemoteEvents.OpenShop then
		self.RemoteEvents.OpenShop.OnClientEvent:Connect(function()
			print("GameClient: Proximity shop triggered - opening shop menu")
			self:OpenShopProximity() -- Internal method for proximity access
		end)
	end

	if self.RemoteEvents.CloseShop then
		self.RemoteEvents.CloseShop.OnClientEvent:Connect(function()
			print("GameClient: Proximity shop close triggered")
			if self.UIState.CurrentPage == "Shop" then
				self:CloseActiveMenus()
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

-- ========== UI SYSTEM (FIXED) ==========

-- UI System Setup with proper initialization order
function GameClient:SetupUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove any existing UI
	local existingUI = playerGui:FindFirstChild("GameUI")
	if existingUI then
		existingUI:Destroy()
	end

	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "GameUI"
	mainUI.ResetOnSpawn = false
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainUI.Parent = playerGui

	-- Store reference FIRST
	self.UI.MainUI = mainUI

	-- Create UI layers
	self:CreateUILayers(mainUI)

	-- Setup individual UI components
	self:SetupCurrencyDisplay()
	self:SetupIndividualButtons()
	self:SetupMenus()

	print("GameClient: UI system setup complete")
end

function GameClient:CreateUILayers(parent)
	local layers = {"Background", "Content", "Navigation", "Overlay", "Notifications"}

	for i, layerName in ipairs(layers) do
		local layer = Instance.new("Frame")
		layer.Name = layerName
		layer.Size = UDim2.new(1, 0, 1, 0)
		layer.BackgroundTransparency = 1
		layer.ZIndex = i
		layer.Parent = parent

		self.UI[layerName] = layer
	end
end

-- Currency Display
function GameClient:SetupCurrencyDisplay()
	if not self.UI.Navigation then
		warn("GameClient: Navigation layer not found for currency display")
		return
	end

	local container = Instance.new("Frame")
	container.Name = "CurrencyDisplay"
	container.Size = UDim2.new(0.25, 0, 0.12, 0)
	container.Position = UDim2.new(0.99, 0, 0.02, 0)
	container.AnchorPoint = Vector2.new(1, 0)
	container.BackgroundTransparency = 1
	container.Parent = self.UI.Navigation

	local coinsFrame = self:CreateCurrencyFrame("Coins", "💰", Color3.fromRGB(255, 215, 0))
	coinsFrame.Size = UDim2.new(1, 0, 0.45, 0)
	coinsFrame.Position = UDim2.new(0, 0, 0, 0)
	coinsFrame.Parent = container

	local farmTokensFrame = self:CreateCurrencyFrame("Farm Tokens", "🌾", Color3.fromRGB(34, 139, 34))
	farmTokensFrame.Size = UDim2.new(1, 0, 0.45, 0)
	farmTokensFrame.Position = UDim2.new(0, 0, 0.55, 0)
	farmTokensFrame.Parent = container

	self.UI.CurrencyContainer = container
	self.UI.CoinsFrame = coinsFrame
	self.UI.FarmTokensFrame = farmTokensFrame
end

function GameClient:CreateCurrencyFrame(currencyName, icon, color)
	local frame = Instance.new("Frame")
	frame.Name = currencyName .. "Frame"
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	frame.BorderSizePixel = 0

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = frame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 20, 0, 20)
	iconLabel.Position = UDim2.new(0, 5, 0.5, -10)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = color
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.SourceSansSemibold
	iconLabel.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 80, 1, 0)
	label.Position = UDim2.new(0, 30, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = currencyName
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.new(1, -120, 1, 0)
	value.Position = UDim2.new(0, 115, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextColor3 = color
	value.TextScaled = true
	value.Font = Enum.Font.GothamBold
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = frame

	return frame
end

-- Navigation Bar REMOVED - Individual buttons instead
function GameClient:SetupIndividualButtons()
	if not self.UI.Navigation then
		warn("GameClient: Navigation layer not found for individual buttons")
		return
	end

	-- Settings gear button (top right)
	local settingsButton = Instance.new("TextButton")
	settingsButton.Name = "SettingsGear"
	settingsButton.Size = UDim2.new(0, 50, 0, 50)
	settingsButton.Position = UDim2.new(1, -60, 0, 10)
	settingsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	settingsButton.BorderSizePixel = 0
	settingsButton.Text = "⚙️"
	settingsButton.TextColor3 = Color3.new(1, 1, 1)
	settingsButton.TextScaled = true
	settingsButton.Font = Enum.Font.SourceSansSemibold
	settingsButton.Parent = self.UI.Navigation

	local settingsCorner = Instance.new("UICorner")
	settingsCorner.CornerRadius = UDim.new(0.2, 0)
	settingsCorner.Parent = settingsButton

	settingsButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Settings")
	end)

	settingsButton.MouseEnter:Connect(function()
		TweenService:Create(settingsButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 80, 90)}):Play()
	end)

	settingsButton.MouseLeave:Connect(function()
		TweenService:Create(settingsButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
	end)

	self.UI.SettingsButton = settingsButton
end

-- ========== STATS MENU ==========

function GameClient:RefreshStatsMenu()
	local menu = self.UI.Menus.Stats
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local playerData = self:GetPlayerData()

	-- Create main layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = contentArea

	-- Currency Stats
	local currencyFrame = self:CreateStatsSection("💰 Currency Stats", {
		{"Coins", (playerData and playerData.coins or 0) .. " 💰"},
		{"Farm Tokens", (playerData and playerData.farmTokens or 0) .. " 🌾"}
	}, Color3.fromRGB(60, 120, 60), 1)
	currencyFrame.Parent = contentArea

	-- Farming Stats  
	if playerData and playerData.farming then
		local farmingStats = {
			{"Farm Plots Owned", playerData.farming.plots or 0},
			{"Seeds in Inventory", self:CountSeeds(playerData.farming.inventory or {})},
			{"Crops in Inventory", self:CountCrops(playerData.farming.inventory or {})}
		}

		local farmingFrame = self:CreateStatsSection("🌾 Farming Stats", farmingStats, Color3.fromRGB(80, 140, 60), 2)
		farmingFrame.Parent = contentArea
	end

	-- Game Stats
	local gameStats = {}
	if playerData and playerData.stats then
		gameStats = {
			{"Milk Collected", playerData.stats.milkCollected or 0},
			{"Coins Earned", playerData.stats.coinsEarned or 0},
			{"Crops Harvested", playerData.stats.cropsHarvested or 0},
			{"Pig Fed Times", playerData.stats.pigFed or 0}
		}
	else
		gameStats = {
			{"No stats available", "Play the game to see stats!"}
		}
	end

	local gameFrame = self:CreateStatsSection("📊 Game Stats", gameStats, Color3.fromRGB(60, 80, 140), 3)
	gameFrame.Parent = contentArea

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and contentArea then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end

function GameClient:CreateStatsSection(title, stats, color, layoutOrder)
	local sectionFrame = Instance.new("Frame")
	sectionFrame.Name = title:gsub(" ", "") .. "Section"
	sectionFrame.Size = UDim2.new(1, 0, 0, 40 + (#stats * 30))
	sectionFrame.BackgroundColor3 = color
	sectionFrame.BorderSizePixel = 0
	sectionFrame.LayoutOrder = layoutOrder

	local sectionCorner = Instance.new("UICorner")
	sectionCorner.CornerRadius = UDim.new(0.02, 0)
	sectionCorner.Parent = sectionFrame

	-- Section title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 35)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = sectionFrame

	-- Stats container
	local statsContainer = Instance.new("Frame")
	statsContainer.Size = UDim2.new(1, -20, 1, -40)
	statsContainer.Position = UDim2.new(0, 10, 0, 35)
	statsContainer.BackgroundTransparency = 1
	statsContainer.Parent = sectionFrame

	-- Create stat lines
	for i, stat in ipairs(stats) do
		local statFrame = Instance.new("Frame")
		statFrame.Size = UDim2.new(1, 0, 0, 25)
		statFrame.Position = UDim2.new(0, 0, 0, (i-1) * 25)
		statFrame.BackgroundTransparency = 1
		statFrame.Parent = statsContainer

		local statName = Instance.new("TextLabel")
		statName.Size = UDim2.new(0.7, 0, 1, 0)
		statName.BackgroundTransparency = 1
		statName.Text = stat[1]
		statName.TextColor3 = Color3.new(1, 1, 1)
		statName.TextScaled = true
		statName.Font = Enum.Font.Gotham
		statName.TextXAlignment = Enum.TextXAlignment.Left
		statName.Parent = statFrame

		local statValue = Instance.new("TextLabel")
		statValue.Size = UDim2.new(0.3, 0, 1, 0)
		statValue.Position = UDim2.new(0.7, 0, 0, 0)
		statValue.BackgroundTransparency = 1
		statValue.Text = tostring(stat[2])
		statValue.TextColor3 = Color3.fromRGB(255, 255, 100)
		statValue.TextScaled = true
		statValue.Font = Enum.Font.GothamBold
		statValue.TextXAlignment = Enum.TextXAlignment.Right
		statValue.Parent = statFrame
	end

	return sectionFrame
end

function GameClient:CountSeeds(inventory)
	local count = 0
	for itemId, quantity in pairs(inventory) do
		if itemId:find("_seeds") then
			count = count + quantity
		end
	end
	return count
end

function GameClient:CountCrops(inventory)
	local count = 0
	for itemId, quantity in pairs(inventory) do
		if not itemId:find("_seeds") then
			count = count + quantity
		end
	end
	return count
end

-- Setup Input Handling
function GameClient:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Escape then
			self:CloseActiveMenus()
		end
	end)
end

-- Setup Menus
function GameClient:SetupMenus()
	self.UI.Menus = {}
end

-- ========== FARMING SYSTEM ==========

-- Setup Farming System
function GameClient:SetupFarmingSystem()
	-- Initialize farming state
	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {}
	}

	-- Create farming UI
	self:CreateFarmingUI()
	self:SetupFarmingInputs()

	print("GameClient: Farming system setup complete")
end

-- Create farming UI with Farm and Stats buttons on left side
function GameClient:CreateFarmingUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing farming UI
	local existingUI = playerGui:FindFirstChild("FarmingUI")
	if existingUI then existingUI:Destroy() end

	local farmingUI = Instance.new("ScreenGui")
	farmingUI.Name = "FarmingUI"
	farmingUI.ResetOnSpawn = false
	farmingUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	farmingUI.Parent = playerGui

	-- Farm button (top left)
	local farmButton = Instance.new("TextButton")
	farmButton.Name = "FarmingButton"
	farmButton.Size = UDim2.new(0, 120, 0, 50)
	farmButton.Position = UDim2.new(0, 20, 0.4, 0)
	farmButton.BackgroundColor3 = Color3.fromRGB(80, 120, 60)
	farmButton.BorderSizePixel = 0
	farmButton.Text = "🌾 Farming"
	farmButton.TextColor3 = Color3.new(1, 1, 1)
	farmButton.TextScaled = true
	farmButton.Font = Enum.Font.GothamBold
	farmButton.Parent = farmingUI

	local farmCorner = Instance.new("UICorner")
	farmCorner.CornerRadius = UDim.new(0.1, 0)
	farmCorner.Parent = farmButton

	-- Stats button (below farm button)
	local statsButton = Instance.new("TextButton")
	statsButton.Name = "StatsButton"
	statsButton.Size = UDim2.new(0, 120, 0, 50)
	statsButton.Position = UDim2.new(0, 20, 0.4, 60) -- 60 pixels below farm button
	statsButton.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
	statsButton.BorderSizePixel = 0
	statsButton.Text = "📊 Stats"
	statsButton.TextColor3 = Color3.new(1, 1, 1)
	statsButton.TextScaled = true
	statsButton.Font = Enum.Font.GothamBold
	statsButton.Parent = farmingUI

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0.1, 0)
	statsCorner.Parent = statsButton

	self.UI.FarmingUI = farmingUI
	self.UI.FarmButton = farmButton
	self.UI.StatsButton = statsButton

	-- Connect button events
	farmButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Farm")
	end)

	statsButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Stats")
	end)

	-- Hover effects for farm button
	farmButton.MouseEnter:Connect(function()
		TweenService:Create(farmButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 140, 80)}):Play()
	end)

	farmButton.MouseLeave:Connect(function()
		TweenService:Create(farmButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 120, 60)}):Play()
	end)

	-- Hover effects for stats button
	statsButton.MouseEnter:Connect(function()
		TweenService:Create(statsButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 100, 140)}):Play()
	end)

	statsButton.MouseLeave:Connect(function()
		TweenService:Create(statsButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 80, 120)}):Play()
	end)
end

-- Setup farming inputs
function GameClient:SetupFarmingInputs()
	-- Keyboard shortcuts
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.F then
			self:OpenMenu("Farm")
		end
	end)
end

-- ========== NOTIFICATIONS (FIXED) ==========

-- Show notification with proper error handling
function GameClient:ShowNotification(title, message, type)
	if not title or not message then return end

	print("Notification [" .. (type or "info"):upper() .. "]: " .. title .. " - " .. message)

	-- Ensure Notifications layer exists
	if not self.UI or not self.UI.Notifications then
		warn("GameClient: Notifications layer not initialized, falling back to print")
		return
	end

	-- Create notification UI
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Size = UDim2.new(0, 300, 0, 80)
	notificationFrame.Position = UDim2.new(1, -320, 0, 20)
	notificationFrame.BackgroundColor3 = self:GetNotificationColor(type or "info")
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Parent = self.UI.Notifications

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = notificationFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -10, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 5, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.Parent = notificationFrame

	-- Message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -10, 0.5, 0)
	messageLabel.Position = UDim2.new(0, 5, 0.4, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	messageLabel.TextScaled = true
	messageLabel.TextWrapped = true
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.Parent = notificationFrame

	-- Animate in
	notificationFrame.Position = UDim2.new(1, 0, 0, 20)
	local slideIn = TweenService:Create(notificationFrame, 
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -320, 0, 20)}
	)
	slideIn:Play()

	-- Auto-remove after 3 seconds
	spawn(function()
		wait(3)
		local slideOut = TweenService:Create(notificationFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(1, 0, 0, 20)}
		)
		slideOut:Play()
		slideOut.Completed:Connect(function()
			notificationFrame:Destroy()
		end)
	end)
end

function GameClient:GetNotificationColor(notificationType)
	local colors = {
		success = Color3.fromRGB(40, 167, 69),
		error = Color3.fromRGB(220, 53, 69),
		warning = Color3.fromRGB(255, 193, 7),
		info = Color3.fromRGB(23, 162, 184)
	}

	return colors[notificationType] or colors.info
end

-- ========== EVENT HANDLERS ==========

-- Enhanced player data update handler
function GameClient:HandlePlayerDataUpdate(newData)
	if not newData then return end

	local oldData = self.PlayerData
	self.PlayerData = newData

	self:UpdateCurrencyDisplay()

	-- Update current page if needed
	if self.UIState.CurrentPage == "Shop" then
		self:RefreshShopMenu()
	elseif self.UIState.CurrentPage == "Farm" then
		self:RefreshFarmMenu()
	end

	-- Update planting mode UI if seeds changed
	if self.FarmingState.isPlantingMode then
		local currentSeeds = newData.farming and newData.farming.inventory or {}
		local selectedSeedCount = currentSeeds[self.FarmingState.selectedSeed] or 0

		if selectedSeedCount <= 0 then
			-- Selected seed is out of stock, exit planting mode
			self:ExitPlantingMode()
			self:ShowNotification("Out of Seeds", "You ran out of " .. (self.FarmingState.selectedSeed or ""):gsub("_", " ") .. "!", "warning")
		end
	end
end

-- Enhanced purchase handler specifically for seeds
function GameClient:HandleItemPurchased(itemId, quantity, cost, currency)
	print("GameClient: Item purchased:", itemId, "x" .. quantity)

	-- Update local data
	if self.PlayerData then
		if currency == "coins" then
			self.PlayerData.coins = math.max(0, (self.PlayerData.coins or 0) - cost)
		elseif currency == "farmTokens" then
			self.PlayerData.farmTokens = math.max(0, (self.PlayerData.farmTokens or 0) - cost)
		end
		self:UpdateCurrencyDisplay()
	end

	-- Show appropriate notification for seeds
	if itemId:find("_seeds") then
		self:ShowNotification("🌱 Seeds Purchased!", 
			"Added " .. quantity .. "x " .. itemId:gsub("_", " ") .. " to your farming inventory!\nOpen Farm menu to plant them!", "success")

		-- Auto-refresh farm menu if it's open
		if self.UIState.CurrentPage == "Farm" then
			spawn(function()
				wait(0.5) -- Wait for server data update
				self:RefreshFarmMenu()
			end)
		end
	elseif itemId == "farm_plot_starter" then
		self:ShowNotification("🌾 Farm Plot Created!", 
			"Your farm plot is ready! Press F to start farming.", "success")
	else
		local item = ItemConfig and ItemConfig.GetItem and ItemConfig.GetItem(itemId)
		self:ShowNotification("Purchase Complete!", 
			"Purchased " .. (item and item.name or itemId), "success")
	end

	-- Refresh shop to update affordability
	if self.UIState.CurrentPage == "Shop" then
		spawn(function()
			wait(0.5) -- Wait for server data update
			self:RefreshShopMenu()
		end)
	end
end

function GameClient:HandleCurrencyUpdate(currencyData)
	for currency, amount in pairs(currencyData) do
		if self.PlayerData[currency:lower()] then
			self.PlayerData[currency:lower()] = amount
		end
	end
	self:UpdateCurrencyDisplay()
end

-- ========== CURRENCY DISPLAY ==========

-- Currency display updates
function GameClient:UpdateCurrencyDisplay()
	if not self.PlayerData then return end

	local coinsValue = self.UI.CoinsFrame and self.UI.CoinsFrame:FindFirstChild("Value")
	local farmTokensValue = self.UI.FarmTokensFrame and self.UI.FarmTokensFrame:FindFirstChild("Value")

	if coinsValue then
		local newAmount = self.PlayerData.coins or 0
		self:AnimateValueChange(coinsValue, tonumber(coinsValue.Text) or 0, newAmount)
	end

	if farmTokensValue then
		local newAmount = self.PlayerData.farmTokens or 0
		self:AnimateValueChange(farmTokensValue, tonumber(farmTokensValue.Text) or 0, newAmount)
	end
end

function GameClient:AnimateValueChange(textLabel, fromValue, toValue)
	if not textLabel then return end

	fromValue = tonumber(fromValue) or 0
	toValue = tonumber(toValue) or 0

	if fromValue == toValue then
		textLabel.Text = self:FormatNumber(toValue)
		return
	end

	local steps = math.min(20, math.abs(toValue - fromValue))
	local stepSize = (toValue - fromValue) / steps

	spawn(function()
		for i = 1, steps do
			local currentValue = math.floor(fromValue + (stepSize * i))
			textLabel.Text = self:FormatNumber(currentValue)
			wait(0.02)
		end
		textLabel.Text = self:FormatNumber(toValue)
	end)
end

function GameClient:FormatNumber(number)
	if number >= 1000000000 then
		return string.format("%.1fB", number / 1000000000)
	elseif number >= 1000000 then
		return string.format("%.1fM", number / 1000000)
	elseif number >= 1000 then
		return string.format("%.1fK", number / 1000)
	else
		return tostring(math.floor(number))
	end
end

-- ========== MENU SYSTEM ==========

-- Menu system methods
function GameClient:OpenMenu(menuName)
	if self.UIState.IsTransitioning then return end

	self:CloseActiveMenus()

	local menu = self:GetOrCreateMenu(menuName)
	if not menu then return end

	self.UIState.IsTransitioning = true
	self.UIState.CurrentPage = menuName
	self.UIState.ActiveMenus[menuName] = menu

	menu.Visible = true
	menu.Position = UDim2.new(0.5, 0, 1.2, 0)

	local tween = TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})

	tween:Play()
	tween.Completed:Connect(function()
		self.UIState.IsTransitioning = false
		self:RefreshMenuContent(menuName)
	end)
end

function GameClient:CloseActiveMenus()
	for menuName, menu in pairs(self.UIState.ActiveMenus) do
		if menu and menu.Visible then
			local tween = TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 1.2, 0)
			})
			tween:Play()
			tween.Completed:Connect(function()
				menu.Visible = false
			end)
		end
	end

	self.UIState.ActiveMenus = {}
	self.UIState.CurrentPage = nil
end

function GameClient:GetOrCreateMenu(menuName)
	if self.UI.Menus[menuName] then
		return self.UI.Menus[menuName]
	end

	local menu = self:CreateBaseMenu(menuName)
	self.UI.Menus[menuName] = menu

	return menu
end

function GameClient:CreateBaseMenu(menuName)
	if not self.UI.Content then
		warn("GameClient: Content layer not found for menu creation")
		return nil
	end

	local menu = Instance.new("Frame")
	menu.Name = menuName .. "Menu"
	menu.Size = UDim2.new(0.9, 0, 0.8, 0)
	menu.Position = UDim2.new(0.5, 0, 0.5, 0)
	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.Parent = self.UI.Content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = menu

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0.1, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = menu

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.1, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = self:GetMenuTitle(menuName)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansSemibold
	title.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.08, 0, 0.8, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0.1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansSemibold
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		self:CloseActiveMenus()
	end)

	local contentArea = Instance.new("ScrollingFrame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(0.95, 0, 0.85, 0)
	contentArea.Position = UDim2.new(0.5, 0, 0.55, 0)
	contentArea.AnchorPoint = Vector2.new(0.5, 0.5)
	contentArea.BackgroundTransparency = 1
	contentArea.ScrollBarThickness = 6
	contentArea.Parent = menu

	return menu
end

function GameClient:GetMenuTitle(menuName)
	local titles = {
		Shop = "🛒 Pet Palace Shop - Seeds & Upgrades",
		Farm = "🌾 Farming Dashboard",
		Stats = "📊 Player Statistics",
		Settings = "⚙️ Settings"
	}
	return titles[menuName] or menuName
end

function GameClient:RefreshMenuContent(menuName)
	if menuName == "Shop" then
		self:RefreshShopMenu()
	elseif menuName == "Farm" then
		self:RefreshFarmMenu()
	elseif menuName == "Stats" then
		self:RefreshStatsMenu()
	elseif menuName == "Settings" then
		self:RefreshSettingsMenu()
	end
end

-- ========== FARM MENU (SIMPLIFIED) ==========

-- Farm Menu with basic seed inventory display
function GameClient:RefreshFarmMenu()
	local menu = self.UI.Menus.Farm
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Create main layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = contentArea

	-- SECTION 1: Farm Info
	local farmInfo = Instance.new("Frame")
	farmInfo.Name = "FarmInfo"
	farmInfo.Size = UDim2.new(1, 0, 0, 120)
	farmInfo.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	farmInfo.BorderSizePixel = 0
	farmInfo.LayoutOrder = 1
	farmInfo.Parent = contentArea

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0.02, 0)
	infoCorner.Parent = farmInfo

	local farmTitle = Instance.new("TextLabel")
	farmTitle.Size = UDim2.new(1, 0, 0.3, 0)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "🌾 Farming System"
	farmTitle.TextColor3 = Color3.new(1, 1, 1)
	farmTitle.TextScaled = true
	farmTitle.Font = Enum.Font.GothamBold
	farmTitle.Parent = farmInfo

	local farmDesc = Instance.new("TextLabel")
	farmDesc.Size = UDim2.new(0.9, 0, 0.7, 0)
	farmDesc.Position = UDim2.new(0.05, 0, 0.3, 0)
	farmDesc.BackgroundTransparency = 1
	farmDesc.Text = "Buy seeds from the shop, plant them on your farm plots, harvest crops, and sell for Farm Tokens!"
	farmDesc.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	farmDesc.TextScaled = true
	farmDesc.TextWrapped = true
	farmDesc.Font = Enum.Font.Gotham
	farmDesc.TextXAlignment = Enum.TextXAlignment.Left
	farmDesc.Parent = farmInfo

	-- SECTION 2: Basic seed inventory (if player data available)
	local playerData = self:GetPlayerData()
	if playerData and playerData.farming and playerData.farming.inventory then
		self:CreateBasicSeedInventory(contentArea, layout)
	else
		self:CreateNoSeedsMessage(contentArea, layout)
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and contentArea then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end

function GameClient:CreateBasicSeedInventory(parent, layout)
	local playerData = self:GetPlayerData()

	local seedFrame = Instance.new("Frame")
	seedFrame.Name = "SeedInventory"
	seedFrame.Size = UDim2.new(1, 0, 0, 200)
	seedFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	seedFrame.BorderSizePixel = 0
	seedFrame.LayoutOrder = 2
	seedFrame.Parent = parent

	local seedCorner = Instance.new("UICorner")
	seedCorner.CornerRadius = UDim.new(0.02, 0)
	seedCorner.Parent = seedFrame

	local seedTitle = Instance.new("TextLabel")
	seedTitle.Size = UDim2.new(1, 0, 0, 30)
	seedTitle.BackgroundTransparency = 1
	seedTitle.Text = "🌱 Your Seed Inventory"
	seedTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
	seedTitle.TextScaled = true
	seedTitle.Font = Enum.Font.GothamBold
	seedTitle.Parent = seedFrame

	local seedScroll = Instance.new("ScrollingFrame")
	seedScroll.Size = UDim2.new(1, -20, 1, -40)
	seedScroll.Position = UDim2.new(0, 10, 0, 35)
	seedScroll.BackgroundTransparency = 1
	seedScroll.ScrollBarThickness = 6
	seedScroll.Parent = seedFrame

	local seedLayout = Instance.new("UIListLayout")
	seedLayout.SortOrder = Enum.SortOrder.LayoutOrder
	seedLayout.Padding = UDim.new(0, 5)
	seedLayout.Parent = seedScroll

	-- Add seeds to inventory display
	local seedCount = 0
	for itemId, quantity in pairs(playerData.farming.inventory) do
		if itemId:find("_seeds") and quantity > 0 then
			self:CreateBasicSeedItem(seedScroll, itemId, quantity)
			seedCount = seedCount + 1
		end
	end

	if seedCount == 0 then
		local noSeedsLabel = Instance.new("TextLabel")
		noSeedsLabel.Size = UDim2.new(1, 0, 1, 0)
		noSeedsLabel.BackgroundTransparency = 1
		noSeedsLabel.Text = "No seeds in inventory.\nBuy seeds from the shop first!"
		noSeedsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noSeedsLabel.TextScaled = true
		noSeedsLabel.Font = Enum.Font.Gotham
		noSeedsLabel.Parent = seedScroll
	end

	-- Update canvas size
	seedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		seedScroll.CanvasSize = UDim2.new(0, 0, 0, seedLayout.AbsoluteContentSize.Y + 10)
	end)
end

function GameClient:CreateNoSeedsMessage(parent, layout)
	local noSeedsFrame = Instance.new("Frame")
	noSeedsFrame.Name = "NoSeedsInfo"
	noSeedsFrame.Size = UDim2.new(1, 0, 0, 80)
	noSeedsFrame.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
	noSeedsFrame.BorderSizePixel = 0
	noSeedsFrame.LayoutOrder = 2
	noSeedsFrame.Parent = parent

	local noSeedsCorner = Instance.new("UICorner")
	noSeedsCorner.CornerRadius = UDim.new(0.02, 0)
	noSeedsCorner.Parent = noSeedsFrame

	local noSeedsLabel = Instance.new("TextLabel")
	noSeedsLabel.Size = UDim2.new(1, 0, 1, 0)
	noSeedsLabel.BackgroundTransparency = 1
	noSeedsLabel.Text = "🌱 No Seeds Available - Visit the Shop to Buy Seeds!"
	noSeedsLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
	noSeedsLabel.TextScaled = true
	noSeedsLabel.Font = Enum.Font.GothamBold
	noSeedsLabel.Parent = noSeedsFrame
end

function GameClient:CreateBasicSeedItem(parent, seedId, quantity)
	local seedItem = Instance.new("Frame")
	seedItem.Name = seedId .. "_Item"
	seedItem.Size = UDim2.new(1, 0, 0, 60)
	seedItem.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
	seedItem.BorderSizePixel = 0
	seedItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = seedItem

	local seedIcon = Instance.new("TextLabel")
	seedIcon.Size = UDim2.new(0, 40, 0, 40)
	seedIcon.Position = UDim2.new(0, 10, 0, 10)
	seedIcon.BackgroundTransparency = 1
	seedIcon.Text = "🌱"
	seedIcon.TextScaled = true
	seedIcon.Font = Enum.Font.SourceSansSemibold
	seedIcon.Parent = seedItem

	local seedInfo = Instance.new("TextLabel")
	seedInfo.Size = UDim2.new(0.6, 0, 1, 0)
	seedInfo.Position = UDim2.new(0, 60, 0, 0)
	seedInfo.BackgroundTransparency = 1
	seedInfo.Text = seedId:gsub("_", " ") .. " x" .. quantity
	seedInfo.TextColor3 = Color3.new(1, 1, 1)
	seedInfo.TextScaled = true
	seedInfo.Font = Enum.Font.Gotham
	seedInfo.TextXAlignment = Enum.TextXAlignment.Left
	seedInfo.Parent = seedItem

	local infoButton = Instance.new("TextButton")
	infoButton.Size = UDim2.new(0, 80, 0, 40)
	infoButton.Position = UDim2.new(1, -90, 0, 10)
	infoButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
	infoButton.BorderSizePixel = 0
	infoButton.Text = "ℹ️ Info"
	infoButton.TextColor3 = Color3.new(1, 1, 1)
	infoButton.TextScaled = true
	infoButton.Font = Enum.Font.Gotham
	infoButton.Parent = seedItem

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0.2, 0)
	infoCorner.Parent = infoButton

	infoButton.MouseButton1Click:Connect(function()
		self:ShowNotification("Seed Info", "Go to your farm plot to plant these seeds!", "info")
	end)
end

-- ========== SETTINGS MENU ==========

function GameClient:RefreshSettingsMenu()
	local menu = self.UI.Menus.Settings
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create settings content
	local settingsInfo = Instance.new("TextLabel")
	settingsInfo.Size = UDim2.new(0.9, 0, 1, 0)
	settingsInfo.Position = UDim2.new(0.05, 0, 0, 0)
	settingsInfo.BackgroundTransparency = 1
	settingsInfo.Text = "⚙️ Game Controls:\n\nF - Open farming interface\nESC - Close menus\n\n🎮 About Pet Palace Farming:\n\n🐄 Cow Milk Collection:\n- Click the cow directly when indicator is green\n- Cow moos when you collect milk!\n\n🐷 Pig Feeding:\n- Walk close to the pig to see feeding interface\n- Feed crops to grow pig and unlock MEGA rewards\n\n🛒 Shop:\n- Walk up to the shop building to browse items\n\n🌾 Farming:\n- Plant seeds, harvest crops, sell for farm tokens\n- Use farming interface (F key) to manage your crops"
	settingsInfo.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	settingsInfo.TextScaled = true
	settingsInfo.TextWrapped = true
	settingsInfo.Font = Enum.Font.Gotham
	settingsInfo.TextXAlignment = Enum.TextXAlignment.Left
	settingsInfo.Parent = contentArea
end

-- ========== SHOP MENU SYSTEM ==========

function GameClient:RefreshShopMenu()
	local menu = self.UI.Menus.Shop
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Show loading message while fetching data
	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Name = "LoadingLabel"
	loadingLabel.Size = UDim2.new(1, 0, 1, 0)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Text = "🛒 Loading Shop Items..."
	loadingLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	loadingLabel.TextScaled = true
	loadingLabel.Font = Enum.Font.Gotham
	loadingLabel.Parent = contentArea

	-- Request shop items from server
	spawn(function()
		local shopItems = self:GetShopItems()
		if shopItems and #shopItems > 0 then
			self:CreateShopContent(contentArea, shopItems)
		else
			self:CreateDefaultShopContent(contentArea)
		end
	end)
end

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
		-- Seeds Category
		{
			id = "carrot_seeds",
			name = "Carrot Seeds",
			description = "Plant these to grow nutritious carrots! Harvest time: 30 seconds",
			price = 10,
			currency = "coins",
			category = "seeds",
			icon = "🥕",
			maxPurchase = 50
		},
		{
			id = "wheat_seeds", 
			name = "Wheat Seeds",
			description = "Classic farming crop! Harvest time: 45 seconds",
			price = 15,
			currency = "coins",
			category = "seeds",
			icon = "🌾",
			maxPurchase = 50
		},
		{
			id = "corn_seeds",
			name = "Corn Seeds", 
			description = "Sweet corn for the pigs! Harvest time: 60 seconds",
			price = 25,
			currency = "coins",
			category = "seeds",
			icon = "🌽",
			maxPurchase = 50
		},
		{
			id = "potato_seeds",
			name = "Potato Seeds",
			description = "Hearty potatoes perfect for pig feeding! Harvest time: 90 seconds", 
			price = 35,
			currency = "coins",
			category = "seeds",
			icon = "🥔",
			maxPurchase = 50
		},
		-- Farm Upgrades
		{
			id = "farm_plot_starter",
			name = "Basic Farm Plot",
			description = "Unlock your first farm plot to start growing crops!",
			price = 100,
			currency = "coins", 
			category = "farm",
			icon = "🌱",
			maxPurchase = 1  -- Can only buy once
		},
		{
			id = "farm_plot_expansion",
			name = "Farm Plot Expansion",
			description = "Add more farming space! Each expansion gives you 4 more plots.",
			price = 500,
			currency = "coins",
			category = "farm", 
			icon = "🚜",
			maxPurchase = 1  -- Can only buy once per expansion level
		},
		-- Premium Seeds (Farm Token purchases)
		{
			id = "golden_carrot_seeds",
			name = "Golden Carrot Seeds",
			description = "Premium seeds that grow faster and sell for more! Harvest time: 15 seconds",
			price = 50,
			currency = "farmTokens",
			category = "premium",
			icon = "🏆",
			maxPurchase = 20
		}
	}
end

function GameClient:CreateShopContent(parent, shopItems)
	-- Remove loading label
	local loadingLabel = parent:FindFirstChild("LoadingLabel")
	if loadingLabel then loadingLabel:Destroy() end

	-- Create main layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = parent

	-- Group items by category
	local categories = {
		{name = "🌱 Seeds", key = "seeds", color = Color3.fromRGB(60, 120, 60)},
		{name = "🚜 Farm Upgrades", key = "farm", color = Color3.fromRGB(120, 90, 60)},
		{name = "🏆 Premium Items", key = "premium", color = Color3.fromRGB(120, 60, 120)}
	}

	local layoutOrder = 1

	for _, category in ipairs(categories) do
		local categoryItems = {}
		for _, item in ipairs(shopItems) do
			if item.category == category.key then
				table.insert(categoryItems, item)
			end
		end

		if #categoryItems > 0 then
			self:CreateShopCategory(parent, category, categoryItems, layoutOrder)
			layoutOrder = layoutOrder + 1
		end
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and parent then
			parent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end

function GameClient:CreateDefaultShopContent(parent)
	-- Remove loading label
	local loadingLabel = parent:FindFirstChild("LoadingLabel")
	if loadingLabel then loadingLabel:Destroy() end

	local defaultItems = self:GetDefaultShopItems()
	self:CreateShopContent(parent, defaultItems)
end

function GameClient:CreateShopCategory(parent, category, items, layoutOrder)
	-- Category header
	local categoryFrame = Instance.new("Frame")
	categoryFrame.Name = category.key .. "Category"
	categoryFrame.Size = UDim2.new(1, 0, 0, 50)
	categoryFrame.BackgroundColor3 = category.color
	categoryFrame.BorderSizePixel = 0
	categoryFrame.LayoutOrder = layoutOrder
	categoryFrame.Parent = parent

	local categoryCorner = Instance.new("UICorner")
	categoryCorner.CornerRadius = UDim.new(0.02, 0)
	categoryCorner.Parent = categoryFrame

	local categoryTitle = Instance.new("TextLabel")
	categoryTitle.Size = UDim2.new(1, 0, 1, 0)
	categoryTitle.BackgroundTransparency = 1
	categoryTitle.Text = category.name
	categoryTitle.TextColor3 = Color3.new(1, 1, 1)
	categoryTitle.TextScaled = true
	categoryTitle.Font = Enum.Font.GothamBold
	categoryTitle.Parent = categoryFrame

	-- Items container
	local itemsContainer = Instance.new("Frame")
	itemsContainer.Name = category.key .. "Items"
	itemsContainer.Size = UDim2.new(1, 0, 0, #items * 80 + 10)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.LayoutOrder = layoutOrder + 0.5
	itemsContainer.Parent = parent

	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	itemsLayout.Padding = UDim.new(0, 5)
	itemsLayout.Parent = itemsContainer

	-- Create item entries
	for i, item in ipairs(items) do
		self:CreateShopItem(itemsContainer, item, i)
	end
end

function GameClient:CreateShopItem(parent, item, layoutOrder)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = item.id .. "_ShopItem"
	itemFrame.Size = UDim2.new(1, 0, 0, 75)
	itemFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = layoutOrder
	itemFrame.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.02, 0)
	itemCorner.Parent = itemFrame

	-- Check if item is sold out (for limited items)
	local isSoldOut = self:IsItemSoldOut(item)

	-- Item icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 50, 0, 50)
	iconLabel.Position = UDim2.new(0, 10, 0, 12)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = item.icon or "📦"
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.SourceSansSemibold
	iconLabel.Parent = itemFrame

	-- Gray out icon if sold out
	if isSoldOut then
		iconLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	end

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 0, 25)
	nameLabel.Position = UDim2.new(0, 70, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = isSoldOut and Color3.fromRGB(120, 120, 120) or Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.4, 0, 0, 40)
	descLabel.Position = UDim2.new(0, 70, 0, 30)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = item.description
	descLabel.TextColor3 = isSoldOut and Color3.fromRGB(100, 100, 100) or Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = itemFrame

	-- Price display
	local priceFrame = Instance.new("Frame")
	priceFrame.Size = UDim2.new(0, 120, 0, 30)
	priceFrame.Position = UDim2.new(1, -250, 0, 10)
	priceFrame.BackgroundColor3 = isSoldOut and Color3.fromRGB(60, 60, 60) or self:GetCurrencyColor(item.currency)
	priceFrame.BorderSizePixel = 0
	priceFrame.Parent = itemFrame

	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0.2, 0)
	priceCorner.Parent = priceFrame

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 1, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = isSoldOut and "SOLD OUT" or self:FormatPrice(item.price, item.currency)
	priceLabel.TextColor3 = Color3.new(1, 1, 1)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = priceFrame

	-- Purchase button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 100, 0, 50)
	buyButton.Position = UDim2.new(1, -110, 0, 12)
	buyButton.BorderSizePixel = 0
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = itemFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.1, 0)
	buyCorner.Parent = buyButton

	-- Set button state based on availability
	if isSoldOut then
		buyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		buyButton.Text = "❌ SOLD OUT"
		buyButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		buyButton.Active = false
	elseif self:CanAffordItem(item) then
		buyButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
		buyButton.Text = "🛒 Buy"
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.Active = true

		-- Purchase functionality
		buyButton.MouseButton1Click:Connect(function()
			self:PurchaseItem(item)
		end)

		buyButton.MouseEnter:Connect(function()
			TweenService:Create(buyButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 170, 80)}):Play()
		end)

		buyButton.MouseLeave:Connect(function()
			TweenService:Create(buyButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 150, 60)}):Play()
		end)
	else
		buyButton.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
		buyButton.Text = "💸 Too Expensive"
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.Active = false
	end
end

-- Check if an item is sold out (for limited purchase items)
function GameClient:IsItemSoldOut(item)
	local playerData = self:GetPlayerData()
	if not playerData or not playerData.purchaseHistory then
		return false
	end

	-- Check for items with maxPurchase limit
	if item.maxPurchase and item.maxPurchase == 1 then
		-- Check if player already purchased this item
		return playerData.purchaseHistory[item.id] == true
	end

	return false
end

function GameClient:GetCurrencyColor(currency)
	local colors = {
		coins = Color3.fromRGB(255, 215, 0),
		farmTokens = Color3.fromRGB(34, 139, 34)
	}
	return colors[currency] or Color3.fromRGB(100, 100, 100)
end

function GameClient:FormatPrice(price, currency)
	local symbols = {
		coins = "💰",
		farmTokens = "🌾"
	}
	return (symbols[currency] or "💎") .. " " .. tostring(price)
end

function GameClient:CanAffordItem(item)
	local playerData = self:GetPlayerData()
	if not playerData then return false end

	local playerCurrency = playerData[item.currency] or 0
	return playerCurrency >= item.price
end

function GameClient:PurchaseItem(item)
	if not self:CanAffordItem(item) then
		self:ShowNotification("Insufficient Funds", "You don't have enough " .. item.currency .. "!", "error")
		return
	end

	if self.RemoteEvents.PurchaseItem then
		print("GameClient: Purchasing item:", item.id, "for", item.price, item.currency)

		-- Temporarily disable purchase button to prevent double-purchasing
		local shopMenu = self.UI.Menus.Shop
		if shopMenu then
			local contentArea = shopMenu:FindFirstChild("ContentArea")
			if contentArea then
				for _, child in ipairs(contentArea:GetDescendants()) do
					if child.Name == item.id .. "_ShopItem" and child:IsA("Frame") then
						local buyButton = child:FindFirstChildOfClass("TextButton")
						if buyButton then
							buyButton.Active = false
							buyButton.Text = "⏳ Processing..."
							buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
							break
						end
					end
				end
			end
		end

		self.RemoteEvents.PurchaseItem:FireServer(item.id, 1) -- Purchase quantity 1
	else
		warn("GameClient: PurchaseItem remote event not available")
		self:ShowNotification("Shop Error", "Purchase system unavailable!", "error")
	end
end

-- ========== DEBUG HELPER FUNCTIONS ==========

_G.TestFarm = function()
	if _G.GameClient then
		_G.GameClient:OpenFarm()
	end
end

_G.TestStats = function()
	if _G.GameClient then
		_G.GameClient:OpenStats()
	end
end

_G.GetShopItems = function()
	if _G.GameClient then
		local items = _G.GameClient:GetShopItems()
		print("Shop items available:")
		for i, item in ipairs(items) do
			print(i .. ":", item.name, "-", item.price, item.currency)
		end
		return items
	end
end

-- ========== PIG FEEDING SYSTEM ==========

function GameClient:ShowPigFeedingInterface()
	print("GameClient: Showing pig feeding interface")

	-- Remove existing pig UI
	local existingUI = LocalPlayer.PlayerGui:FindFirstChild("PigFeedingUI")
	if existingUI then existingUI:Destroy() end

	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:ShowNotification("No Crops", "You need to harvest crops first to feed the pig!", "warning")
		return
	end

	-- Basic pig feeding UI
	local pigUI = Instance.new("ScreenGui")
	pigUI.Name = "PigFeedingUI"
	pigUI.ResetOnSpawn = false
	pigUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pigUI.Parent = LocalPlayer.PlayerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = pigUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = mainFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
	title.BorderSizePixel = 0
	title.Text = "🐷 Feed the Pig - Walk Away to Close"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = title

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -20, 1, -60)
	infoLabel.Position = UDim2.new(0, 10, 0, 55)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "🐷 Pig Feeding Interface\n\nFeed your harvested crops to the pig to help it grow!\n\nCrops will appear here when you harvest them from your farm plots."
	infoLabel.TextColor3 = Color3.new(0, 0, 0)
	infoLabel.TextScaled = true
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextWrapped = true
	infoLabel.Parent = mainFrame

	-- Animate in
	mainFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
	local slideIn = TweenService:Create(mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0.5, 0)}
	)
	slideIn:Play()

	self.UI.PigFeedingUI = pigUI
end

function GameClient:HidePigFeedingInterface()
	print("GameClient: Hiding pig feeding interface")

	local pigUI = self.UI.PigFeedingUI or LocalPlayer.PlayerGui:FindFirstChild("PigFeedingUI")
	if pigUI then
		local mainFrame = pigUI:FindFirstChild("Frame")
		if mainFrame then
			local slideOut = TweenService:Create(mainFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, 0, 1.2, 0)}
			)
			slideOut:Play()
			slideOut.Completed:Connect(function()
				pigUI:Destroy()
			end)
		else
			pigUI:Destroy()
		end
		self.UI.PigFeedingUI = nil
	end
end

-- ========== PLANTING SYSTEM ==========

function GameClient:StartPlantingMode(seedId)
	print("GameClient: Starting planting mode with seed:", seedId)
	self.FarmingState.selectedSeed = seedId
	self.FarmingState.isPlantingMode = true
	self:ShowNotification("🌱 Planting Mode", "Go to your farm and click on plots to plant seeds!", "success")
end

function GameClient:ExitPlantingMode()
	print("GameClient: Exiting planting mode")
	self.FarmingState.selectedSeed = nil
	self.FarmingState.isPlantingMode = false
	self:ShowNotification("🌱 Planting Mode", "Planting mode deactivated", "info")
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

-- ========== PUBLIC API METHODS ==========

-- Note: Shop removed from public API - only accessible via proximity
function GameClient:OpenFarm()
	self:OpenMenu("Farm")
end

function GameClient:OpenStats()
	self:OpenMenu("Stats")
end

function GameClient:OpenSettings()
	self:OpenMenu("Settings")
end

function GameClient:CloseMenus()
	self:CloseActiveMenus()
end

-- ========== INTERNAL PROXIMITY METHODS ==========

-- Internal method - only called by proximity system
function GameClient:OpenShopProximity()
	print("GameClient: Opening shop via proximity system")
	self:OpenMenu("Shop")
end

-- ========== ERROR RECOVERY ==========

function GameClient:RecoverFromError(errorMsg)
	warn("GameClient: Attempting recovery from error: " .. tostring(errorMsg))

	-- Reset critical systems
	self.UIState = {
		ActiveMenus = {},
		CurrentPage = nil,
		IsTransitioning = false
	}

	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {}
	}

	-- Reset UI table
	self.UI = {
		MainUI = nil,
		Background = nil,
		Content = nil,
		Navigation = nil,
		Overlay = nil,
		Notifications = nil,
		CurrencyContainer = nil,
		CoinsFrame = nil,
		FarmTokensFrame = nil,
		NavigationBar = nil,
		FarmingUI = nil,
		FarmButton = nil,
		Menus = {},
		PlantingModeUI = nil,
		PigFeedingUI = nil
	}

	-- Try to reconnect remotes
	local success, error = pcall(function()
		self:SetupRemoteConnections()
	end)

	if success then
		-- Try to reinitialize UI
		local uiSuccess, uiError = pcall(function()
			self:SetupUI()
		end)

		if uiSuccess then
			print("GameClient: Recovery successful")
			return true
		else
			warn("GameClient: UI recovery failed: " .. tostring(uiError))
			return false
		end
	else
		warn("GameClient: Recovery failed: " .. tostring(error))
		return false
	end
end

-- ========== DEBUG FUNCTIONS ==========

function GameClient:DebugStatus()
	print("=== GAMECLIENT DEBUG STATUS ===")
	print("PlayerData exists:", self.PlayerData ~= nil)
	if self.PlayerData then
		print("  Coins:", self.PlayerData.coins or "N/A")
		print("  Farm Tokens:", self.PlayerData.farmTokens or "N/A") 
		print("  Farming data exists:", self.PlayerData.farming ~= nil)
	end
	print("UI table exists:", self.UI ~= nil)
	print("MainUI exists:", self.UI and self.UI.MainUI ~= nil)
	print("Notifications layer exists:", self.UI and self.UI.Notifications ~= nil)
	print("Current page:", self.UIState and self.UIState.CurrentPage or "None")
	print("Active menus:", self.UIState and self:CountTable(self.UIState.ActiveMenus) or 0)
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

print("GameClient: Fixed version loaded successfully!")
print("✅ Proper UI initialization order")
print("✅ Error recovery system")
print("✅ Safe notification system")
print("✅ Individual button layout (no bottom nav bar)")
print("✅ Shop only accessible via proximity (touchpart)")
print("✅ Stats menu with player data")
print("✅ SOLD OUT status for limited items")
print("✅ Debugging functions available")
print("")
print("UI Layout:")
print("  🌾 Farm button (left side)")
print("  📊 Stats button (below farm button)")
print("  ⚙️ Settings gear (top right)")
print("  🛒 Shop (proximity only - walk to shop building)")
print("")
print("Debug Commands:")
print("  _G.TestFarm() - Open farm menu")
print("  _G.TestStats() - Open stats menu")
print("  _G.DebugGameClient() - Show system status")

return GameClient