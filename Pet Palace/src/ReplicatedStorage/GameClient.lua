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
local ServerScriptService = game:GetService("ServerScriptService")
local GameCore = nil
local function LoadGamCore()
	local success, result = pcall(function()
		return require(ServerScriptService.Core:WaitForChild("GameCore"))
	end)
	if success then
		GameCore = result
		print("GameCore: ItemConfig loaded successfully")
	else
		warn("GameCore: Could not load ItemConfig: " .. tostring(result))
	end
end

-- Player and Game State
local LocalPlayer = Players.LocalPlayer
GameClient.PlayerData = {}
GameClient.RemoteEvents = {}
GameClient.Connections = {}
GameClient.RemoteFunctions = {}
GameClient.ActiveConnections = {}
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
-- REPLACE scattered UI methods with this unified system (GameClient.lua)
GameClient.UIComponents = {}
GameClient.UIConfig = {
	layers = {"Background", "Content", "Navigation", "Overlay", "Notifications"},
	animations = {
		slideIn = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		slideOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		fadeIn = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		hover = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
	},
	colors = {
		primary = Color3.fromRGB(80, 120, 60),
		secondary = Color3.fromRGB(60, 80, 120), 
		accent = Color3.fromRGB(255, 215, 0),
		error = Color3.fromRGB(220, 53, 69),
		success = Color3.fromRGB(40, 167, 69),
		warning = Color3.fromRGB(255, 193, 7),
		info = Color3.fromRGB(23, 162, 184)
	}
}

-- UNIFIED UI Creation
function GameClient:CreateUIComponent(componentType, config)
	local component = Instance.new(config.class or "Frame")

	-- Apply base properties
	for property, value in pairs(config.properties or {}) do
		component[property] = value
	end

	-- Add common elements
	if config.corner then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(config.corner, 0)
		corner.Parent = component
	end

	if config.stroke then
		local stroke = Instance.new("UIStroke")
		stroke.Color = config.stroke.color or Color3.new(1, 1, 1)
		stroke.Thickness = config.stroke.thickness or 1
		stroke.Transparency = config.stroke.transparency or 0
		stroke.Parent = component
	end

	-- Add hover effects
	if config.hover and component:IsA("GuiButton") then
		self:AddHoverEffect(component, config.hover)
	end

	-- Store component for management
	self.UIComponents[config.name or component.Name] = component

	return component
end

-- UNIFIED Hover Effects
function GameClient:AddHoverEffect(button, hoverConfig)
	local originalColor = button.BackgroundColor3
	local hoverColor = hoverConfig.color or Color3.new(originalColor.R + 0.1, originalColor.G + 0.1, originalColor.B + 0.1)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, self.UIConfig.animations.hover, {
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, self.UIConfig.animations.hover, {
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

-- OPTIMIZED Menu System
function GameClient:CreateMenu(menuName, config)
	if self.UI.Menus[menuName] then
		return self.UI.Menus[menuName]
	end

	local menu = self:CreateUIComponent("menu", {
		class = "Frame",
		name = menuName .. "Menu",
		properties = {
			Size = UDim2.new(0.9, 0, 0.8, 0),
			Position = UDim2.new(0.5, 0, 1.2, 0), -- Start off-screen
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(35, 35, 45),
			BorderSizePixel = 0,
			Visible = false,
			Parent = self.UI.Content
		},
		corner = 0.02
	})

	-- Create title bar
	local titleBar = self:CreateUIComponent("titleBar", {
		properties = {
			Name = "TitleBar",
			Size = UDim2.new(1, 0, 0.1, 0),
			BackgroundColor3 = Color3.fromRGB(25, 25, 35),
			BorderSizePixel = 0,
			Parent = menu
		},
		corner = 0.02
	})

	-- Create title label
	local titleLabel = self:CreateUIComponent("titleLabel", {
		class = "TextLabel",
		properties = {
			Name = "Title",
			Size = UDim2.new(0.8, 0, 1, 0),
			Position = UDim2.new(0.1, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = self:GetMenuTitle(menuName),
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Font = Enum.Font.SourceSansSemibold,
			Parent = titleBar
		}
	})

	-- Create close button
	local closeButton = self:CreateUIComponent("closeButton", {
		class = "TextButton",
		properties = {
			Name = "CloseButton",
			Size = UDim2.new(0.08, 0, 0.8, 0),
			Position = UDim2.new(0.9, 0, 0.1, 0),
			BackgroundColor3 = self.UIConfig.colors.error,
			BorderSizePixel = 0,
			Text = "✕",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Font = Enum.Font.SourceSansSemibold,
			Parent = titleBar
		},
		corner = 0.5,
		hover = {color = Color3.fromRGB(240, 70, 70)}
	})

	closeButton.MouseButton1Click:Connect(function()
		self:CloseActiveMenus()
	end)

	-- Create content area
	local contentArea = self:CreateUIComponent("contentArea", {
		class = "ScrollingFrame",
		properties = {
			Name = "ContentArea",
			Size = UDim2.new(0.95, 0, 0.85, 0),
			Position = UDim2.new(0.5, 0, 0.55, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ScrollBarThickness = 6,
			Parent = menu
		}
	})

	self.UI.Menus[menuName] = menu
	return menu
end

-- OPTIMIZED Animation System
function GameClient:AnimateMenu(menu, animationType, callback)
	if self.UIState.IsTransitioning then return end

	self.UIState.IsTransitioning = true

	local targetPosition, tweenInfo

	if animationType == "open" then
		menu.Visible = true
		menu.Position = UDim2.new(0.5, 0, 1.2, 0)
		targetPosition = UDim2.new(0.5, 0, 0.5, 0)
		tweenInfo = self.UIConfig.animations.slideIn
	elseif animationType == "close" then
		targetPosition = UDim2.new(0.5, 0, 1.2, 0)
		tweenInfo = self.UIConfig.animations.slideOut
	end

	local tween = TweenService:Create(menu, tweenInfo, {Position = targetPosition})
	tween:Play()

	tween.Completed:Connect(function()
		self.UIState.IsTransitioning = false
		if animationType == "close" then
			menu.Visible = false
		end
		if callback then callback() end
	end)
end
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
		"PlayerDataUpdated", "ShowNotification",

		-- Chicken System Events
		"PurchaseChicken", "FeedChicken", "CollectEgg", "ChickenPlaced", "ChickenMoved",

		-- Pest Control Events
		"UsePesticide", "PestSpotted", "PestEliminated"
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

	-- Setup all event handlers in one place (FIXED)
	self:SetupAllEventHandlers()
	print("GameClient: Remote connections established")
end



-- REPLACE the connection setup patterns with this tracked version:
function GameClient:ConnectEvent(eventName, handler)
	if self.RemoteEvents[eventName] then
		local connection = self.RemoteEvents[eventName].OnClientEvent:Connect(handler)

		-- Store connection for cleanup
		if not self.Connections[eventName] then
			self.Connections[eventName] = {}
		end
		table.insert(self.Connections[eventName], connection)

		return connection
	else
		warn("GameClient: Remote event not found: " .. eventName)
		return nil
	end
end

-- ADD cleanup method
function GameClient:CleanupConnections()
	for eventName, connections in pairs(self.Connections) do
		for _, connection in ipairs(connections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end
	self.Connections = {}
end

-- ADD to GameCore.lua - Player cleanup

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

	-- All event handlers in one place
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
			pcall(function() self:ShowNotification(title, message, notificationType) end)
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

	print("GameClient: All event handlers setup complete (" .. #self.ActiveConnections .. " connections)")
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
	container.Position = UDim2.new(0.95, 0, 0.02, 0) -- Moved slightly left from 0.99 to 0.98
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

	print("GameClient: Currency display positioned to avoid gear overlap")
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

	-- Settings gear button (top right) - MOVED UP to avoid blocking currency
	local settingsButton = Instance.new("TextButton")
	settingsButton.Name = "SettingsGear"
	settingsButton.Size = UDim2.new(0, 45, 0, 45) -- Slightly smaller
	settingsButton.Position = UDim2.new(1, -45, 0, 4) -- 4 pixels from very top 
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
	print("GameClient: Settings button positioned to not block currency display")
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

	-- Check if UI system is properly initialized
	if not self.UI or not self.UI.Notifications then
		warn("GameClient: UI not fully initialized yet - notification printed to console only")
		return
	end

	-- Ensure Notifications layer exists and is valid
	if not self.UI.Notifications.Parent then
		warn("GameClient: Notifications layer destroyed - falling back to print")
		return
	end

	-- Create notification UI (rest of existing code...)
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
		if notificationFrame and notificationFrame.Parent then
			local slideOut = TweenService:Create(notificationFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(1, 0, 0, 20)}
			)
			slideOut:Play()
			slideOut.Completed:Connect(function()
				notificationFrame:Destroy()
			end)
		end
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
	print("🎉 CLIENT: Received purchase confirmation!")
	print("    Item: " .. itemId)
	print("    Quantity: " .. quantity)
	print("    Cost: " .. cost .. " " .. currency)

	-- Update local data
	if self.PlayerData then
		print("💳 CLIENT: Updating local currency data")
		local oldAmount = self.PlayerData[currency] or 0
		self.PlayerData[currency] = math.max(0, oldAmount - cost)
		print("    " .. currency .. ": " .. oldAmount .. " -> " .. self.PlayerData[currency])

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
		local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
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

	print("✅ CLIENT: Purchase handling completed")
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
function GameClient:CreateFarmInfoSection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local farmInfoFrame = Instance.new("Frame")
	farmInfoFrame.Name = "FarmInfo"
	farmInfoFrame.Size = UDim2.new(1, 0, 0, 120)
	farmInfoFrame.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	farmInfoFrame.BorderSizePixel = 0
	farmInfoFrame.LayoutOrder = layoutOrder
	farmInfoFrame.Parent = parent

	local farmCorner = Instance.new("UICorner")
	farmCorner.CornerRadius = UDim.new(0.02, 0)
	farmCorner.Parent = farmInfoFrame

	-- Section title
	local farmTitle = Instance.new("TextLabel")
	farmTitle.Size = UDim2.new(1, 0, 0, 35)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "🌾 Farm Overview"
	farmTitle.TextColor3 = Color3.new(1, 1, 1)
	farmTitle.TextScaled = true
	farmTitle.Font = Enum.Font.GothamBold
	farmTitle.Parent = farmInfoFrame

	-- Farm info content
	local farmContent = Instance.new("Frame")
	farmContent.Size = UDim2.new(1, -20, 1, -45)
	farmContent.Position = UDim2.new(0, 10, 0, 40)
	farmContent.BackgroundTransparency = 1
	farmContent.Parent = farmInfoFrame

	local farmLayout = Instance.new("UIListLayout")
	farmLayout.SortOrder = Enum.SortOrder.LayoutOrder
	farmLayout.Padding = UDim.new(0, 5)
	farmLayout.Parent = farmContent

	-- Farm plots info
	local plotsInfo = Instance.new("TextLabel")
	plotsInfo.Size = UDim2.new(1, 0, 0, 25)
	plotsInfo.BackgroundTransparency = 1
	plotsInfo.Text = "Farm Plots: " .. (playerData and playerData.farming and playerData.farming.plots or 0)
	plotsInfo.TextColor3 = Color3.new(1, 1, 1)
	plotsInfo.TextScaled = true
	plotsInfo.Font = Enum.Font.Gotham
	plotsInfo.TextXAlignment = Enum.TextXAlignment.Left
	plotsInfo.LayoutOrder = 1
	plotsInfo.Parent = farmContent

	-- Quick status
	local statusInfo = Instance.new("TextLabel")
	statusInfo.Size = UDim2.new(1, 0, 0, 25)
	statusInfo.BackgroundTransparency = 1
	statusInfo.Text = "Status: " .. (playerData and playerData.farming and playerData.farming.plots and playerData.farming.plots > 0 and "Farm Active" or "Get your first farm plot from the shop!")
	statusInfo.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	statusInfo.TextScaled = true
	statusInfo.Font = Enum.Font.Gotham
	statusInfo.TextXAlignment = Enum.TextXAlignment.Left
	statusInfo.LayoutOrder = 2
	statusInfo.Parent = farmContent
end

-- ========== FIX #2: Add missing CreateSeedInventorySection method (GameClient.lua) ==========
-- ADD this method to GameClient.lua (after CreateFarmInfoSection):

function GameClient:CreateSeedInventorySection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local seedFrame = Instance.new("Frame")
	seedFrame.Name = "SeedInventory"
	seedFrame.Size = UDim2.new(1, 0, 0, 200)
	seedFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	seedFrame.BorderSizePixel = 0
	seedFrame.LayoutOrder = layoutOrder
	seedFrame.Parent = parent

	local seedCorner = Instance.new("UICorner")
	seedCorner.CornerRadius = UDim.new(0.02, 0)
	seedCorner.Parent = seedFrame

	local seedTitle = Instance.new("TextLabel")
	seedTitle.Size = UDim2.new(1, 0, 0, 35)
	seedTitle.BackgroundTransparency = 1
	seedTitle.Text = "🌱 Your Seed Inventory"
	seedTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
	seedTitle.TextScaled = true
	seedTitle.Font = Enum.Font.GothamBold
	seedTitle.Parent = seedFrame

	local seedScroll = Instance.new("ScrollingFrame")
	seedScroll.Size = UDim2.new(1, -20, 1, -45)
	seedScroll.Position = UDim2.new(0, 10, 0, 40)
	seedScroll.BackgroundTransparency = 1
	seedScroll.ScrollBarThickness = 6
	seedScroll.Parent = seedFrame

	local seedLayout = Instance.new("UIListLayout")
	seedLayout.SortOrder = Enum.SortOrder.LayoutOrder
	seedLayout.Padding = UDim.new(0, 5)
	seedLayout.Parent = seedScroll

	-- Add seeds to inventory display
	local seedCount = 0
	if playerData and playerData.farming and playerData.farming.inventory then
		for itemId, quantity in pairs(playerData.farming.inventory) do
			if itemId:find("_seeds") and quantity > 0 then
				self:CreateBasicSeedItem(seedScroll, itemId, quantity)
				seedCount = seedCount + 1
			end
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

-- ========== FIX #3: Add missing CreateCropInventorySection method (GameClient.lua) ==========
-- ADD this method to GameClient.lua (after CreateSeedInventorySection):

function GameClient:CreateCropInventorySection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local cropFrame = Instance.new("Frame")
	cropFrame.Name = "CropInventory"
	cropFrame.Size = UDim2.new(1, 0, 0, 200)
	cropFrame.BackgroundColor3 = Color3.fromRGB(60, 40, 60)
	cropFrame.BorderSizePixel = 0
	cropFrame.LayoutOrder = layoutOrder
	cropFrame.Parent = parent

	local cropCorner = Instance.new("UICorner")
	cropCorner.CornerRadius = UDim.new(0.02, 0)
	cropCorner.Parent = cropFrame

	local cropTitle = Instance.new("TextLabel")
	cropTitle.Size = UDim2.new(1, 0, 0, 35)
	cropTitle.BackgroundTransparency = 1
	cropTitle.Text = "🌽 Harvested Crops"
	cropTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	cropTitle.TextScaled = true
	cropTitle.Font = Enum.Font.GothamBold
	cropTitle.Parent = cropFrame

	local cropScroll = Instance.new("ScrollingFrame")
	cropScroll.Size = UDim2.new(1, -20, 1, -45)
	cropScroll.Position = UDim2.new(0, 10, 0, 40)
	cropScroll.BackgroundTransparency = 1
	cropScroll.ScrollBarThickness = 6
	cropScroll.Parent = cropFrame

	local cropLayout = Instance.new("UIListLayout")
	cropLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cropLayout.Padding = UDim.new(0, 5)
	cropLayout.Parent = cropScroll

	-- Add crops to inventory display
	local cropCount = 0
	if playerData and playerData.farming and playerData.farming.inventory then
		for itemId, quantity in pairs(playerData.farming.inventory) do
			if not itemId:find("_seeds") and quantity > 0 then
				self:CreateBasicCropItem(cropScroll, itemId, quantity)
				cropCount = cropCount + 1
			end
		end
	end

	if cropCount == 0 then
		local noCropsLabel = Instance.new("TextLabel")
		noCropsLabel.Size = UDim2.new(1, 0, 1, 0)
		noCropsLabel.BackgroundTransparency = 1
		noCropsLabel.Text = "No harvested crops yet.\nPlant seeds and harvest them!"
		noCropsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noCropsLabel.TextScaled = true
		noCropsLabel.Font = Enum.Font.Gotham
		noCropsLabel.Parent = cropScroll
	end

	-- Update canvas size
	cropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		cropScroll.CanvasSize = UDim2.new(0, 0, 0, cropLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- ========== FIX #4: Add missing CreateBasicCropItem method (GameClient.lua) ==========
-- ADD this method to GameClient.lua (after CreateCropInventorySection):

function GameClient:CreateBasicCropItem(parent, cropId, quantity)
	local cropItem = Instance.new("Frame")
	cropItem.Name = cropId .. "_CropItem"
	cropItem.Size = UDim2.new(1, 0, 0, 60)
	cropItem.BackgroundColor3 = Color3.fromRGB(70, 50, 70)
	cropItem.BorderSizePixel = 0
	cropItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = cropItem

	local cropIcon = Instance.new("TextLabel")
	cropIcon.Size = UDim2.new(0, 40, 0, 40)
	cropIcon.Position = UDim2.new(0, 10, 0, 10)
	cropIcon.BackgroundTransparency = 1
	cropIcon.Text = self:GetCropIcon(cropId)
	cropIcon.TextScaled = true
	cropIcon.Font = Enum.Font.SourceSansSemibold
	cropIcon.Parent = cropItem

	local cropInfo = Instance.new("TextLabel")
	cropInfo.Size = UDim2.new(0.5, 0, 1, 0)
	cropInfo.Position = UDim2.new(0, 60, 0, 0)
	cropInfo.BackgroundTransparency = 1
	cropInfo.Text = self:GetCropDisplayName(cropId) .. " x" .. quantity
	cropInfo.TextColor3 = Color3.new(1, 1, 1)
	cropInfo.TextScaled = true
	cropInfo.Font = Enum.Font.Gotham
	cropInfo.TextXAlignment = Enum.TextXAlignment.Left
	cropInfo.Parent = cropItem

	local sellButton = Instance.new("TextButton")
	sellButton.Size = UDim2.new(0, 80, 0, 40)
	sellButton.Position = UDim2.new(1, -90, 0, 10)
	sellButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
	sellButton.BorderSizePixel = 0
	sellButton.Text = "💰 Sell"
	sellButton.TextColor3 = Color3.new(1, 1, 1)
	sellButton.TextScaled = true
	sellButton.Font = Enum.Font.Gotham
	sellButton.Parent = cropItem

	local sellCorner = Instance.new("UICorner")
	sellCorner.CornerRadius = UDim.new(0.2, 0)
	sellCorner.Parent = sellButton

	sellButton.MouseButton1Click:Connect(function()
		if self.RemoteEvents.SellCrop then
			self.RemoteEvents.SellCrop:FireServer(cropId, 1)
		end
	end)
end

-- ========== FIX #5: Add missing utility methods (GameClient.lua) ==========
-- ADD these helper methods to GameClient.lua (after CreateBasicCropItem):

function GameClient:GetCropIcon(cropId)
	local icons = {
		carrot = "🥕",
		corn = "🌽",
		strawberry = "🍓",
		golden_fruit = "✨"
	}
	return icons[cropId] or "🌾"
end

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

	local playerData = self:GetPlayerData()

	-- SECTION 1: Farm Info (SAFE VERSION)
	self:CreateFarmInfoSection(contentArea, layout, 1)

	-- SECTION 2: Seed Inventory (SAFE VERSION)
	if playerData and playerData.farming and playerData.farming.inventory then
		self:CreateSeedInventorySection(contentArea, layout, 2)
	end

	-- SECTION 3: Crop Inventory (SAFE VERSION)
	if playerData and playerData.farming and playerData.farming.inventory then
		self:CreateCropInventorySection(contentArea, layout, 5)
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and contentArea then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end


function GameClient:CreateChickenManagementSection(parent, layout, layoutOrder)
	local chickenFrame = Instance.new("Frame")
	chickenFrame.Name = "ChickenManagement"
	chickenFrame.Size = UDim2.new(1, 0, 0, 250)
	chickenFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
	chickenFrame.BorderSizePixel = 0
	chickenFrame.LayoutOrder = layoutOrder
	chickenFrame.Parent = parent

	local chickenCorner = Instance.new("UICorner")
	chickenCorner.CornerRadius = UDim.new(0.02, 0)
	chickenCorner.Parent = chickenFrame

	-- Section title
	local chickenTitle = Instance.new("TextLabel")
	chickenTitle.Size = UDim2.new(1, 0, 0, 35)
	chickenTitle.BackgroundTransparency = 1
	chickenTitle.Text = "🐔 Chicken Defense System"
	chickenTitle.TextColor3 = Color3.new(1, 1, 1)
	chickenTitle.TextScaled = true
	chickenTitle.Font = Enum.Font.GothamBold
	chickenTitle.Parent = chickenFrame

	-- Chicken content area
	local chickenContent = Instance.new("ScrollingFrame")
	chickenContent.Size = UDim2.new(1, -20, 1, -45)
	chickenContent.Position = UDim2.new(0, 10, 0, 40)
	chickenContent.BackgroundTransparency = 1
	chickenContent.ScrollBarThickness = 6
	chickenContent.Parent = chickenFrame

	local chickenLayout = Instance.new("UIListLayout")
	chickenLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chickenLayout.Padding = UDim.new(0, 5)
	chickenLayout.Parent = chickenContent

	local playerData = self:GetPlayerData()
	local hasChickens = false

	-- Show owned chickens
	if playerData.chickens and playerData.chickens.owned then
		for chickenId, chickenData in pairs(playerData.chickens.owned) do
			self:CreateChickenDisplayItem(chickenContent, chickenId, chickenData)
			hasChickens = true
		end
	end

	-- Deployment button
	local deployButton = Instance.new("TextButton")
	deployButton.Size = UDim2.new(1, 0, 0, 40)
	deployButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
	deployButton.BorderSizePixel = 0
	deployButton.Text = hasChickens and "🐔 Deploy Chicken" or "🛒 Buy Chickens from Shop"
	deployButton.TextColor3 = Color3.new(1, 1, 1)
	deployButton.TextScaled = true
	deployButton.Font = Enum.Font.GothamBold
	deployButton.LayoutOrder = 100
	deployButton.Parent = chickenContent

	local deployCorner = Instance.new("UICorner")
	deployCorner.CornerRadius = UDim.new(0.1, 0)
	deployCorner.Parent = deployButton

	deployButton.MouseButton1Click:Connect(function()
		if hasChickens then
			self:OpenChickenDeploymentInterface()
		else
			self:OpenMenu("Shop")
		end
	end)

	-- Feed management
	if playerData.chickens and playerData.chickens.feed then
		self:CreateFeedManagementSection(chickenContent, playerData.chickens.feed)
	end

	-- Update canvas size
	chickenLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		chickenContent.CanvasSize = UDim2.new(0, 0, 0, chickenLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- Create individual chicken display item
function GameClient:CreateChickenDisplayItem(parent, chickenId, chickenData)
	local chickenItem = Instance.new("Frame")
	chickenItem.Name = "ChickenItem_" .. chickenId
	chickenItem.Size = UDim2.new(1, 0, 0, 60)
	chickenItem.BackgroundColor3 = Color3.fromRGB(70, 90, 70)
	chickenItem.BorderSizePixel = 0
	chickenItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = chickenItem

	-- Chicken icon
	local chickenIcon = Instance.new("TextLabel")
	chickenIcon.Size = UDim2.new(0, 40, 0, 40)
	chickenIcon.Position = UDim2.new(0, 10, 0, 10)
	chickenIcon.BackgroundTransparency = 1
	chickenIcon.Text = self:GetChickenIcon(chickenData.type)
	chickenIcon.TextScaled = true
	chickenIcon.Font = Enum.Font.SourceSansSemibold
	chickenIcon.Parent = chickenItem

	-- Chicken info
	local chickenInfo = Instance.new("TextLabel")
	chickenInfo.Size = UDim2.new(0.5, 0, 1, 0)
	chickenInfo.Position = UDim2.new(0, 60, 0, 0)
	chickenInfo.BackgroundTransparency = 1
	chickenInfo.Text = self:GetChickenDisplayName(chickenData.type) .. "\nStatus: " .. (chickenData.status or "available")
	chickenInfo.TextColor3 = Color3.new(1, 1, 1)
	chickenInfo.TextScaled = true
	chickenInfo.Font = Enum.Font.Gotham
	chickenInfo.TextXAlignment = Enum.TextXAlignment.Left
	chickenInfo.Parent = chickenItem

	-- Action buttons
	if chickenData.status == "available" then
		local deployBtn = Instance.new("TextButton")
		deployBtn.Size = UDim2.new(0, 80, 0, 35)
		deployBtn.Position = UDim2.new(1, -90, 0, 12)
		deployBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
		deployBtn.BorderSizePixel = 0
		deployBtn.Text = "Deploy"
		deployBtn.TextColor3 = Color3.new(1, 1, 1)
		deployBtn.TextScaled = true
		deployBtn.Font = Enum.Font.Gotham
		deployBtn.Parent = chickenItem

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0.2, 0)
		btnCorner.Parent = deployBtn

		deployBtn.MouseButton1Click:Connect(function()
			self:DeploySpecificChicken(chickenId, chickenData.type)
		end)
	end
end

-- ========== NEW SECTION: Pest Control ==========

function GameClient:CreatePestControlSection(parent, layout, layoutOrder)
	local pestFrame = Instance.new("Frame")
	pestFrame.Name = "PestControl"
	pestFrame.Size = UDim2.new(1, 0, 0, 200)
	pestFrame.BackgroundColor3 = Color3.fromRGB(80, 60, 60)
	pestFrame.BorderSizePixel = 0
	pestFrame.LayoutOrder = layoutOrder
	pestFrame.Parent = parent

	local pestCorner = Instance.new("UICorner")
	pestCorner.CornerRadius = UDim.new(0.02, 0)
	pestCorner.Parent = pestFrame

	-- Section title
	local pestTitle = Instance.new("TextLabel")
	pestTitle.Size = UDim2.new(1, 0, 0, 35)
	pestTitle.BackgroundTransparency = 1
	pestTitle.Text = "🧪 Pest Control Arsenal"
	pestTitle.TextColor3 = Color3.new(1, 1, 1)
	pestTitle.TextScaled = true
	pestTitle.Font = Enum.Font.GothamBold
	pestTitle.Parent = pestFrame

	-- Pest control content
	local pestContent = Instance.new("Frame")
	pestContent.Size = UDim2.new(1, -20, 1, -45)
	pestContent.Position = UDim2.new(0, 10, 0, 40)
	pestContent.BackgroundTransparency = 1
	pestContent.Parent = pestFrame

	local pestLayout = Instance.new("UIListLayout")
	pestLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pestLayout.Padding = UDim.new(0, 5)
	pestLayout.Parent = pestContent

	local playerData = self:GetPlayerData()

	-- Pesticide inventory
	if playerData.pestControl.organic_pesticide and playerData.pestControl.organic_pesticide > 0 then
		self:CreatePestControlItem(pestContent, "organic_pesticide", playerData.pestControl.organic_pesticide)
	end

	-- Pest detector status
	if playerData.pestControl.pest_detector then
		self:CreatePestDetectorDisplay(pestContent)
	end

	-- Buy pest control tools button
	local buyPestControlBtn = Instance.new("TextButton")
	buyPestControlBtn.Size = UDim2.new(1, 0, 0, 40)
	buyPestControlBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 80)
	buyPestControlBtn.BorderSizePixel = 0
	buyPestControlBtn.Text = "🛒 Buy Pest Control Tools"
	buyPestControlBtn.TextColor3 = Color3.new(1, 1, 1)
	buyPestControlBtn.TextScaled = true
	buyPestControlBtn.Font = Enum.Font.GothamBold
	buyPestControlBtn.LayoutOrder = 100
	buyPestControlBtn.Parent = pestContent

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.1, 0)
	buyCorner.Parent = buyPestControlBtn

	buyPestControlBtn.MouseButton1Click:Connect(function()
		self:OpenMenu("Shop")
	end)
end

-- Create pest control item display
function GameClient:CreatePestControlItem(parent, itemType, quantity)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "PestItem_" .. itemType
	itemFrame.Size = UDim2.new(1, 0, 0, 50)
	itemFrame.BackgroundColor3 = Color3.fromRGB(90, 70, 70)
	itemFrame.BorderSizePixel = 0
	itemFrame.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = itemFrame

	-- Item icon
	local itemIcon = Instance.new("TextLabel")
	itemIcon.Size = UDim2.new(0, 35, 0, 35)
	itemIcon.Position = UDim2.new(0, 10, 0, 7)
	itemIcon.BackgroundTransparency = 1
	itemIcon.Text = "🧪"
	itemIcon.TextScaled = true
	itemIcon.Font = Enum.Font.SourceSansSemibold
	itemIcon.Parent = itemFrame

	-- Item info
	local itemInfo = Instance.new("TextLabel")
	itemInfo.Size = UDim2.new(0.6, 0, 1, 0)
	itemInfo.Position = UDim2.new(0, 55, 0, 0)
	itemInfo.BackgroundTransparency = 1
	itemInfo.Text = "Organic Pesticide x" .. quantity .. "\nEliminate pests from crops"
	itemInfo.TextColor3 = Color3.new(1, 1, 1)
	itemInfo.TextScaled = true
	itemInfo.Font = Enum.Font.Gotham
	itemInfo.TextXAlignment = Enum.TextXAlignment.Left
	itemInfo.Parent = itemFrame

	-- Use button
	local useBtn = Instance.new("TextButton")
	useBtn.Size = UDim2.new(0, 70, 0, 30)
	useBtn.Position = UDim2.new(1, -80, 0, 10)
	useBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
	useBtn.BorderSizePixel = 0
	useBtn.Text = "Use"
	useBtn.TextColor3 = Color3.new(1, 1, 1)
	useBtn.TextScaled = true
	useBtn.Font = Enum.Font.Gotham
	useBtn.Parent = itemFrame

	local useCorner = Instance.new("UICorner")
	useCorner.CornerRadius = UDim.new(0.2, 0)
	useCorner.Parent = useBtn

	useBtn.MouseButton1Click:Connect(function()
		self:UsePesticideMode()
	end)
end

function GameClient:ShowSeedSelectionForPlot(plotModel)
	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:ShowNotification("No Seeds", "You need to buy seeds from the shop first!", "warning")
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
		self:ShowNotification("No Seeds", "You don't have any seeds to plant! Buy some from the shop.", "warning")
		return
	end

	-- Create seed selection UI
	self:CreateSeedSelectionUI(plotModel, availableSeeds)
end

-- 🌱 NEW FUNCTION: Create the actual seed selection interface
function GameClient:CreateSeedSelectionUI(plotModel, availableSeeds)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing seed selection UI
	local existingUI = playerGui:FindFirstChild("SeedSelectionUI")
	if existingUI then existingUI:Destroy() end

	-- Create seed selection UI
	local seedUI = Instance.new("ScreenGui")
	seedUI.Name = "SeedSelectionUI"
	seedUI.ResetOnSpawn = false
	seedUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	seedUI.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
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
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	title.BorderSizePixel = 0
	title.Text = "🌱 Select Seed to Plant"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = title

	-- Seed container
	local seedContainer = Instance.new("ScrollingFrame")
	seedContainer.Size = UDim2.new(1, -20, 1, -100)
	seedContainer.Position = UDim2.new(0, 10, 0, 60)
	seedContainer.BackgroundTransparency = 1
	seedContainer.ScrollBarThickness = 6
	seedContainer.Parent = mainFrame

	local seedLayout = Instance.new("UIListLayout")
	seedLayout.SortOrder = Enum.SortOrder.LayoutOrder
	seedLayout.Padding = UDim.new(0, 5)
	seedLayout.Parent = seedContainer

	-- Create seed buttons
	for i, seedData in ipairs(availableSeeds) do
		local seedButton = Instance.new("TextButton")
		seedButton.Size = UDim2.new(1, 0, 0, 60)
		seedButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
		seedButton.BorderSizePixel = 0
		seedButton.Text = seedData.id:gsub("_", " "):gsub("seeds", "Seeds") .. " (x" .. seedData.quantity .. ")"
		seedButton.TextColor3 = Color3.new(1, 1, 1)
		seedButton.TextScaled = true
		seedButton.Font = Enum.Font.Gotham
		seedButton.Parent = seedContainer

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.1, 0)
		buttonCorner.Parent = seedButton

		-- Plant this seed when clicked
		seedButton.MouseButton1Click:Connect(function()
			print("GameClient: Player selected seed:", seedData.id)
			self:PlantSelectedSeed(plotModel, seedData.id)
			seedUI:Destroy() -- Close the UI
		end)

		-- Hover effects
		seedButton.MouseEnter:Connect(function()
			TweenService:Create(seedButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 140, 100)}):Play()
		end)

		seedButton.MouseLeave:Connect(function()
			TweenService:Create(seedButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 120, 80)}):Play()
		end)
	end

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 100, 0, 30)
	closeButton.Position = UDim2.new(0.5, -50, 1, -40)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "Cancel"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.2, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		seedUI:Destroy()
	end)

	-- Update canvas size
	seedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		seedContainer.CanvasSize = UDim2.new(0, 0, 0, seedLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Animate in
	mainFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
	local slideIn = TweenService:Create(mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0.5, 0)}
	)
	slideIn:Play()
end

-- 🌱 NEW FUNCTION: Actually plant the selected seed
function GameClient:PlantSelectedSeed(plotModel, seedId)
	print("GameClient: Attempting to plant", seedId, "on plot", plotModel.Name)

	-- Fire to server to plant the seed
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed:FireServer(plotModel, seedId)
		self:ShowNotification("🌱 Planting...", "Attempting to plant " .. seedId:gsub("_", " ") .. "!", "info")
	else
		warn("GameClient: PlantSeed remote event not available")
		self:ShowNotification("Error", "Planting system not available!", "error")
	end
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
			id = "strawberry_seeds",
			name = "Strawberry Seeds", 
			category = "seeds",
			price = 100,
			currency = "coins",
			description = "Sweet strawberries. Ready in 10 minutes. Worth 3 crop points when fed to pig.",
			icon = "🍓",
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
			id = "golden_seeds",
			name = "Golden Seeds",
			category = "seeds",
			price = 50,
			currency = "farmTokens",
			description = "Magical golden fruit! Ready in 15 minutes. Worth 10 crop points when fed to pig!",
			icon = "✨",
			maxPurchase = 25
		},
	--	Roof Upgrades
		{	id = "basic_roof",
			name = "🏠 Basic Roof Protection",
			category = "farming",
			price = 500,
			currency = "coins",
			description = "Protect your crops from UFO attacks! Basic roof covers 1 farm plot.",
			icon = "🏠",
			maxQuantity = 10, -- Can buy up to 10 roofs (one per plot)
		},
		{	id = "reinforced_roof", 
			name = "🏘️ Reinforced Roof Protection",
			category = "farming",
			price = 500,
			currency = "coins",
			description = "Heavy-duty roof protection! Covers 4 plots and is UFO-proof.",
			icon = "🏘️",
			maxQuantity = 3, -- Can buy up to 3 (covers 12 plots total)
		},

		{	mega_dome = {
			id = "mega_dome",
			name = "🛡️ Mega Protection Dome", 
			category = "farming",
			price = 100, -- Expensive but worth it
			currency = "farmTokens",
			description = "Ultimate protection! Dome covers ALL your farm plots and blocks UFO attacks completely.",
			icon = "🛡️",
			maxQuantity = 1, -- Only one mega dome allowed
		}
		-- Add more shop items here
	}
	}
	end

-- Update the CreateShopContent function to include new categories:

function GameClient:CreateShopContent(parent, shopItems)
	-- Remove loading label
	local loadingLabel = parent:FindFirstChild("LoadingLabel")
	if loadingLabel then loadingLabel:Destroy() end

	-- Create main layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = parent

	-- Enhanced categories including new pest/chicken items
	local categories = {
		{name = "🌱 Seeds", key = "seeds", color = Color3.fromRGB(60, 120, 60)},
		{name = "🚜 Farm Upgrades", key = "farm", color = Color3.fromRGB(120, 90, 60)},
		{name = "🐔 Chicken Defense", key = "defense", color = Color3.fromRGB(100, 80, 120)}, -- NEW
		{name = "🧪 Pest Control", key = "tools", color = Color3.fromRGB(120, 80, 80)}, -- NEW
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
			print("🛒 CLIENT: Purchase button clicked for " .. item.id)

			-- Check if we can afford it
			if not self:CanAffordItem(item) then
				print("❌ CLIENT: Cannot afford " .. item.id)
				self:ShowNotification("Insufficient Funds", "You don't have enough " .. item.currency .. "!", "error")
				return
			end

			-- Check if RemoteEvent exists
			if not self.RemoteEvents.PurchaseItem then
				print("❌ CLIENT: PurchaseItem remote event not found!")
				self:ShowNotification("Shop Error", "Purchase system unavailable!", "error")
				return
			end

			-- Disable button temporarily
			buyButton.Active = false
			buyButton.Text = "⏳ Processing..."
			buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

			print("📤 CLIENT: Firing purchase request to server...")
			print("    Item ID: " .. item.id)
			print("    Price: " .. item.price .. " " .. item.currency)

			-- Fire purchase request
			self.RemoteEvents.PurchaseItem:FireServer(item.id, 1)

			-- Re-enable button after 3 seconds if no response
			spawn(function()
				wait(3)
				if buyButton and buyButton.Parent then
					buyButton.Active = true
					buyButton.Text = "🛒 Buy"
					buyButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
					print("⏰ CLIENT: Purchase button re-enabled after timeout")
				end
			end)
		end)
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

-- ========== NEW CHICKEN DEPLOYMENT INTERFACE ==========

function GameClient:OpenChickenDeploymentInterface()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing deployment UI
	local existingUI = playerGui:FindFirstChild("ChickenDeploymentUI")
	if existingUI then existingUI:Destroy() end

	local playerData = self:GetPlayerData()
	if not playerData or not playerData.chickens or not playerData.chickens.owned then
		self:ShowNotification("No Chickens", "You don't have any chickens to deploy!", "warning")
		return
	end

	-- Get available chickens
	local availableChickens = {}
	for chickenId, chickenData in pairs(playerData.chickens.owned) do
		if chickenData.status == "available" then
			table.insert(availableChickens, {id = chickenId, data = chickenData})
		end
	end

	if #availableChickens == 0 then
		self:ShowNotification("No Available Chickens", "All your chickens are already deployed!", "warning")
		return
	end

	-- Create deployment UI
	local deployUI = Instance.new("ScreenGui")
	deployUI.Name = "ChickenDeploymentUI"
	deployUI.ResetOnSpawn = false
	deployUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	deployUI.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 450, 0, 350)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = deployUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundColor3 = Color3.fromRGB(80, 100, 80)
	title.BorderSizePixel = 0
	title.Text = "🐔 Deploy Chicken Defense"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = title

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Size = UDim2.new(1, -20, 0, 40)
	instructions.Position = UDim2.new(0, 10, 0, 60)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Select a chicken type to deploy near your farm for pest protection:"
	instructions.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	instructions.TextScaled = true
	instructions.Font = Enum.Font.Gotham
	instructions.TextWrapped = true
	instructions.Parent = mainFrame

	-- Chicken selection area
	local chickenContainer = Instance.new("ScrollingFrame")
	chickenContainer.Size = UDim2.new(1, -20, 1, -150)
	chickenContainer.Position = UDim2.new(0, 10, 0, 110)
	chickenContainer.BackgroundTransparency = 1
	chickenContainer.ScrollBarThickness = 6
	chickenContainer.Parent = mainFrame

	local chickenLayout = Instance.new("UIListLayout")
	chickenLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chickenLayout.Padding = UDim.new(0, 5)
	chickenLayout.Parent = chickenContainer

	-- Create chicken selection buttons
	for i, chickenInfo in ipairs(availableChickens) do
		self:CreateChickenDeploymentButton(chickenContainer, chickenInfo, deployUI)
	end

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 100, 0, 30)
	closeButton.Position = UDim2.new(0.5, -50, 1, -40)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "Cancel"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.2, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		deployUI:Destroy()
	end)

	-- Update canvas size
	chickenLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		chickenContainer.CanvasSize = UDim2.new(0, 0, 0, chickenLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- Create chicken deployment button
function GameClient:CreateChickenDeploymentButton(parent, chickenInfo, deployUI)
	local chickenButton = Instance.new("TextButton")
	chickenButton.Size = UDim2.new(1, 0, 0, 70)
	chickenButton.BackgroundColor3 = Color3.fromRGB(80, 100, 80)
	chickenButton.BorderSizePixel = 0
	chickenButton.Parent = parent

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.1, 0)
	buttonCorner.Parent = chickenButton

	-- Chicken icon
	local chickenIcon = Instance.new("TextLabel")
	chickenIcon.Size = UDim2.new(0, 50, 0, 50)
	chickenIcon.Position = UDim2.new(0, 10, 0, 10)
	chickenIcon.BackgroundTransparency = 1
	chickenIcon.Text = self:GetChickenIcon(chickenInfo.data.type)
	chickenIcon.TextScaled = true
	chickenIcon.Font = Enum.Font.SourceSansSemibold
	chickenIcon.Parent = chickenButton

	-- Chicken info
	local chickenInfo = Instance.new("TextLabel")
	chickenInfo.Size = UDim2.new(1, -70, 1, 0)
	chickenInfo.Position = UDim2.new(0, 70, 0, 0)
	chickenInfo.BackgroundTransparency = 1
	chickenInfo.Text = self:GetChickenDisplayName(chickenInfo.data.type) .. "\n" .. self:GetChickenDescription(chickenInfo.data.type)
	chickenInfo.TextColor3 = Color3.new(1, 1, 1)
	chickenInfo.TextScaled = true
	chickenInfo.Font = Enum.Font.Gotham
	chickenInfo.TextXAlignment = Enum.TextXAlignment.Left
	chickenInfo.Parent = chickenButton

	chickenButton.MouseButton1Click:Connect(function()
		deployUI:Destroy()
		self:StartChickenPlacementMode(chickenInfo.id, chickenInfo.data.type)
	end)

	-- Hover effects
	chickenButton.MouseEnter:Connect(function()
		TweenService:Create(chickenButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 120, 100)}):Play()
	end)

	chickenButton.MouseLeave:Connect(function()
		TweenService:Create(chickenButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 100, 80)}):Play()
	end)
end

-- ========== CHICKEN PLACEMENT SYSTEM ==========

function GameClient:StartChickenPlacementMode(chickenId, chickenType)
	self:ShowNotification("🐔 Chicken Placement", 
		"Click near your farm to place your " .. self:GetChickenDisplayName(chickenType) .. "!", "info")

	-- Enable placement mode
	self.ChickenPlacementState = {
		active = true,
		chickenId = chickenId,
		chickenType = chickenType
	}

	-- Create placement visual preview
	self:CreateChickenPlacementPreview(chickenType)

	-- Handle click to place
	local connection
	connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 and self.ChickenPlacementState and self.ChickenPlacementState.active then
			local mouse = LocalPlayer:GetMouse()
			local hit = mouse.Hit
			if hit then
				self:PlaceChickenAtPosition(chickenId, chickenType, hit.Position)
				connection:Disconnect()
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			-- Cancel placement
			self:CancelChickenPlacement()
			connection:Disconnect()
		end
	end)
end

-- Place chicken at clicked position
function GameClient:PlaceChickenAtPosition(chickenId, chickenType, position)
	if not self.ChickenPlacementState or not self.ChickenPlacementState.active then return end

	-- Send placement request to server
	if self.RemoteEvents.PurchaseChicken then
		self.RemoteEvents.PurchaseChicken:FireServer(chickenType, position)
	end

	-- Cleanup placement mode
	self:CancelChickenPlacement()

	self:ShowNotification("🐔 Chicken Deployed!", 
		self:GetChickenDisplayName(chickenType) .. " deployed to protect your farm!", "success")
end

-- ========== PEST CONTROL SYSTEMS ==========

function GameClient:UsePesticideMode()
	self:ShowNotification("🧪 Pesticide Mode", 
		"Click on a crop with pests to apply organic pesticide!", "info")

	-- Enable pesticide use mode
	self.PesticideUseState = {
		active = true
	}

	-- Handle click to use pesticide
	local connection
	connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 and self.PesticideUseState and self.PesticideUseState.active then
			local mouse = LocalPlayer:GetMouse()
			local target = mouse.Target

			if target and target.Parent and target.Parent.Name:find("PlantingSpot") then
				self:UsePesticideOnPlot(target.Parent)
				connection:Disconnect()
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			-- Cancel pesticide use
			self.PesticideUseState = nil
			connection:Disconnect()
			self:ShowNotification("Pesticide Mode Cancelled", "", "info")
		end
	end)
end

function GameClient:UsePesticideOnPlot(plotModel)
	if not self.PesticideUseState or not self.PesticideUseState.active then return end

	-- Send pesticide use request to server
	if self.RemoteEvents.UsePesticide then
		self.RemoteEvents.UsePesticide:FireServer(plotModel)
	end

	-- Cleanup pesticide mode
	self.PesticideUseState = nil
end

-- ========== NOTIFICATION HANDLERS ==========

function GameClient:HandlePestSpottedNotification(pestType, cropType, plotInfo)
	local pestName = pestType:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	self:ShowNotification("🐛 Pest Alert!", 
		pestName .. " spotted on your " .. cropType .. " crop! Deploy chickens or use pesticide.", "warning")
end

function GameClient:HandlePestEliminatedNotification(pestType, eliminatedBy)
	local pestName = pestType:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	self:ShowNotification("✅ Pest Eliminated!", 
		pestName .. " eliminated by " .. eliminatedBy .. "!", "success")
end

function GameClient:HandleChickenPlacedNotification(chickenType, position)
	self:ShowNotification("🐔 Chicken Deployed!", 
		self:GetChickenDisplayName(chickenType) .. " is now protecting your farm!", "success")
end

-- ========== UTILITY FUNCTIONS ==========

function GameClient:GetChickenIcon(chickenType)
	local icons = {
		basic_chicken = "🐔",
		guinea_fowl = "🦃", 
		rooster = "🐓"
	}
	return icons[chickenType] or "🐔"
end

function GameClient:GetChickenDisplayName(chickenType)
	local names = {
		basic_chicken = "Basic Chicken",
		guinea_fowl = "Guinea Fowl",
		rooster = "Rooster"
	}
	return names[chickenType] or chickenType:gsub("_", " ")
end

function GameClient:GetChickenDescription(chickenType)
	local descriptions = {
		basic_chicken = "General pest control & egg production",
		guinea_fowl = "Anti-locust specialist with alarm system", 
		rooster = "Area boost & intimidation effects"
	}
	return descriptions[chickenType] or "Chicken description"
end

function GameClient:CreateFeedManagementSection(parent, feedData)
	local feedFrame = Instance.new("Frame")
	feedFrame.Name = "FeedManagement"
	feedFrame.Size = UDim2.new(1, 0, 0, 80)
	feedFrame.BackgroundColor3 = Color3.fromRGB(80, 100, 80)
	feedFrame.BorderSizePixel = 0
	feedFrame.LayoutOrder = 50
	feedFrame.Parent = parent

	local feedCorner = Instance.new("UICorner")
	feedCorner.CornerRadius = UDim.new(0.1, 0)
	feedCorner.Parent = feedFrame

	local feedTitle = Instance.new("TextLabel")
	feedTitle.Size = UDim2.new(1, 0, 0, 25)
	feedTitle.BackgroundTransparency = 1
	feedTitle.Text = "🌾 Feed Storage"
	feedTitle.TextColor3 = Color3.new(1, 1, 1)
	feedTitle.TextScaled = true
	feedTitle.Font = Enum.Font.GothamBold
	feedTitle.Parent = feedFrame

	local feedInfo = Instance.new("TextLabel")
	feedInfo.Size = UDim2.new(1, -20, 1, -30)
	feedInfo.Position = UDim2.new(0, 10, 0, 25)
	feedInfo.BackgroundTransparency = 1
	feedInfo.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	feedInfo.TextScaled = true
	feedInfo.Font = Enum.Font.Gotham
	feedInfo.TextXAlignment = Enum.TextXAlignment.Left
	feedInfo.Parent = feedFrame

	-- Display feed amounts
	local feedText = ""
	for feedType, amount in pairs(feedData) do
		if amount > 0 then
			feedText = feedText .. feedType:gsub("_", " ") .. ": " .. amount .. "\n"
		end
	end

	if feedText == "" then
		feedText = "No feed available - buy feed from shop"
	end

	feedInfo.Text = feedText
end

print("GameClient: Enhanced with pest and chicken management UI!")
print("New Features:")
print("  ✅ Chicken deployment interface")
print("  ✅ Pest control tools interface") 
print("  ✅ Enhanced farm menu with defense systems")
print("  ✅ Shop categories for chickens and pest control")
print("  ✅ Interactive placement and usage modes")
print("  ✅ Enhanced notifications for pest/chicken events")
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
	print("GameClient: Showing compact pig feeding interface")

	-- Remove existing pig UI
	local existingUI = LocalPlayer.PlayerGui:FindFirstChild("PigFeedingUI")
	if existingUI then existingUI:Destroy() end

	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:ShowNotification("No Crops", "You need to harvest crops first to feed the pig!", "warning")
		return
	end

	-- Check for available crops (not seeds)
	local availableCrops = {}
	for itemId, quantity in pairs(playerData.farming.inventory) do
		if not itemId:find("_seeds") and quantity > 0 then
			table.insert(availableCrops, {id = itemId, quantity = quantity})
		end
	end

	-- Compact pig feeding UI with transparency
	local pigUI = Instance.new("ScreenGui")
	pigUI.Name = "PigFeedingUI"
	pigUI.ResetOnSpawn = false
	pigUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pigUI.Parent = LocalPlayer.PlayerGui

	-- SMALLER main frame with transparency
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 280, 0, 200) -- Reduced from 400x300 to 280x200
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
	mainFrame.BackgroundTransparency = 0.3 -- Added transparency
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = pigUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.03, 0)
	corner.Parent = mainFrame

	-- Compact title bar
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 35) -- Reduced height
	title.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
	title.BackgroundTransparency = 0.2 -- Semi-transparent title
	title.BorderSizePixel = 0
	title.Text = "🐷 Feed the Pig"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.03, 0)
	titleCorner.Parent = title

	-- Close button (smaller)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 25, 0, 25) -- Smaller close button
	closeButton.Position = UDim2.new(1, -30, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BackgroundTransparency = 0.2
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = title

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		pigUI:Destroy()
	end)

	-- Content area (smaller and semi-transparent)
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -10, 1, -45) -- Adjusted for smaller title
	contentArea.Position = UDim2.new(0, 5, 0, 40)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainFrame

	if #availableCrops > 0 then
		-- Create crop feeding interface
		local cropsLabel = Instance.new("TextLabel")
		cropsLabel.Size = UDim2.new(1, 0, 0, 25)
		cropsLabel.BackgroundTransparency = 1
		cropsLabel.Text = "🌾 Select crop to feed:"
		cropsLabel.TextColor3 = Color3.new(0.1, 0.1, 0.1)
		cropsLabel.TextScaled = true
		cropsLabel.Font = Enum.Font.Gotham
		cropsLabel.TextXAlignment = Enum.TextXAlignment.Left
		cropsLabel.Parent = contentArea

		-- Crops container (smaller scrolling area)
		local cropsContainer = Instance.new("ScrollingFrame")
		cropsContainer.Size = UDim2.new(1, 0, 1, -30)
		cropsContainer.Position = UDim2.new(0, 0, 0, 30)
		cropsContainer.BackgroundTransparency = 1
		cropsContainer.ScrollBarThickness = 4 -- Thinner scrollbar
		cropsContainer.Parent = contentArea

		local cropsLayout = Instance.new("UIListLayout")
		cropsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		cropsLayout.Padding = UDim.new(0, 3) -- Tighter spacing
		cropsLayout.Parent = cropsContainer

		-- Create compact crop buttons
		for i, cropData in ipairs(availableCrops) do
			local cropButton = Instance.new("TextButton")
			cropButton.Size = UDim2.new(1, 0, 0, 35) -- Smaller buttons
			cropButton.BackgroundColor3 = Color3.fromRGB(255, 240, 245)
			cropButton.BackgroundTransparency = 0.1 -- Semi-transparent buttons
			cropButton.BorderSizePixel = 0
			cropButton.Text = self:GetCropDisplayName(cropData.id) .. " (x" .. cropData.quantity .. ")"
			cropButton.TextColor3 = Color3.new(0.2, 0.2, 0.2)
			cropButton.TextScaled = true
			cropButton.Font = Enum.Font.Gotham
			cropButton.Parent = cropsContainer

			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0.1, 0)
			buttonCorner.Parent = cropButton

			-- Feed crop when clicked
			cropButton.MouseButton1Click:Connect(function()
				print("GameClient: Feeding pig with", cropData.id)
				if self.RemoteEvents.FeedPig then
					self.RemoteEvents.FeedPig:FireServer(cropData.id)
				end
				pigUI:Destroy() -- Close UI after feeding
			end)

			-- Hover effects (subtle for transparency)
			cropButton.MouseEnter:Connect(function()
				TweenService:Create(cropButton, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(255, 230, 240),
					BackgroundTransparency = 0.05
				}):Play()
			end)

			cropButton.MouseLeave:Connect(function()
				TweenService:Create(cropButton, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(255, 240, 245),
					BackgroundTransparency = 0.1
				}):Play()
			end)
		end

		-- Update canvas size
		cropsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			cropsContainer.CanvasSize = UDim2.new(0, 0, 0, cropsLayout.AbsoluteContentSize.Y + 10)
		end)

	else
		-- No crops available message
		local noCropsLabel = Instance.new("TextLabel")
		noCropsLabel.Size = UDim2.new(1, 0, 1, 0)
		noCropsLabel.BackgroundTransparency = 1
		noCropsLabel.Text = "🌾 No crops available!\n\nHarvest some crops from your farm first, then come back to feed the pig."
		noCropsLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
		noCropsLabel.TextScaled = true
		noCropsLabel.Font = Enum.Font.Gotham
		noCropsLabel.TextWrapped = true
		noCropsLabel.Parent = contentArea
	end

	-- Animate in (smoother animation for smaller UI)
	mainFrame.Position = UDim2.new(0.5, 0, 1.1, 0)
	local slideIn = TweenService:Create(mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0.5, 0)}
	)
	slideIn:Play()

	self.UI.PigFeedingUI = pigUI
	print("GameClient: Compact pig feeding UI created")
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

function GameClient:GetCropDisplayName(cropId)
	local displayNames = {
		carrot = "🥕 Carrot",
		corn = "🌽 Corn", 
		strawberry = "🍓 Strawberry",
		golden_fruit = "✨ Golden Fruit"
	}

	return displayNames[cropId] or cropId:gsub("_", " ")
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