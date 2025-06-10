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
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
	for _, obj in ipairs(remotes:GetChildren()) do
		if obj:IsA("RemoteEvent") then
			self.RemoteEvents[obj.Name] = obj
		elseif obj:IsA("RemoteFunction") then
			self.RemoteFunctions[obj.Name] = obj
		end
	end

	-- Connect events
	self.RemoteEvents.PlantSeed.OnClientEvent:Connect(function(plotModel)
		self:ShowSeedSelectionForPlot(plotModel)
	end)
	self.RemoteEvents.ItemPurchased.OnClientEvent:Connect(function(itemId, quantity)
		self:HandleItemPurchased(itemId, quantity)
	end)

	local remoteEvents = {
		-- Shop System (proximity-based)
		"OpenShop", "CloseShop", "PurchaseItem", "ItemPurchased", "CurrencyUpdated",

		-- Pig System (proximity-based)
		"ShowPigFeedingUI", "HidePigFeedingUI", "FeedPig",

		-- Farming System
		"PlantSeed", "HarvestCrop", "SellCrop", "SellMilk", "SellEgg",

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

	-- Livestock Stats (ADDED)
	if playerData and playerData.livestock then
		local livestockStats = {
			{"Milk Collected", playerData.stats and playerData.stats.milkCollected or 0},
			{"Milk Sold", playerData.stats and playerData.stats.milkSold or 0}, -- ADDED
			{"Fresh Milk in Storage", playerData.livestock.inventory and playerData.livestock.inventory.fresh_milk or 0}
		}

		local livestockFrame = self:CreateStatsSection("🥛 Livestock Stats", livestockStats, Color3.fromRGB(60, 100, 150), 2)
		livestockFrame.Parent = contentArea
	end

	-- Farming Stats  
	if playerData and playerData.farming then
		local farmingStats = {
			{"Farm Plots Owned", playerData.farming.plots or 0},
			{"Seeds in Inventory", self:CountSeeds(playerData.farming.inventory or {})},
			{"Crops in Inventory", self:CountCrops(playerData.farming.inventory or {})}
		}

		local farmingFrame = self:CreateStatsSection("🌾 Farming Stats", farmingStats, Color3.fromRGB(80, 140, 60), 3)
		farmingFrame.Parent = contentArea
	end

	-- Game Stats
	local gameStats = {}
	if playerData and playerData.stats then
		gameStats = {
			{"Coins Earned", playerData.stats.coinsEarned or 0},
			{"Crops Harvested", playerData.stats.cropsHarvested or 0},
			{"Pig Fed Times", playerData.stats.pigFed or 0}
		}
	else
		gameStats = {
			{"No stats available", "Play the game to see stats!"}
		}
	end

	local gameFrame = self:CreateStatsSection("📊 Game Stats", gameStats, Color3.fromRGB(60, 80, 140), 4)
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
	print("    Item: " .. tostring(itemId))
	print("    Quantity: " .. tostring(quantity))

	-- FIX: Safely handle nil cost and currency values
	local safeCost = cost or 0
	local safeCurrency = currency or "coins"

	print("    Cost: " .. tostring(safeCost) .. " " .. tostring(safeCurrency))

	-- Update local data
	if self.PlayerData then
		print("💳 CLIENT: Updating local currency data")
		local oldAmount = self.PlayerData[safeCurrency] or 0
		self.PlayerData[safeCurrency] = math.max(0, oldAmount - safeCost)
		print("    " .. safeCurrency .. ": " .. oldAmount .. " -> " .. self.PlayerData[safeCurrency])

		self:UpdateCurrencyDisplay()
	end

	-- Show appropriate notification for seeds
	if itemId:find("_seeds") then
		self:ShowNotification("🌱 Seeds Purchased!", 
			"Added " .. tostring(quantity) .. "x " .. itemId:gsub("_", " ") .. " to your farming inventory!\nOpen Farm menu to plant them!", "success")

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
--[[
    Complete Chicken Feeding System & Enhanced Farming UI
    
    PART 1: Add to GameClient.lua - Enhanced Farm Menu
    PART 2: Add to GameCore.lua - Server-side feeding logic
    PART 3: Add to ChickenSystemServer.lua - Feeding integration
]]

-- ========== PART 1: ENHANCED FARM MENU (ADD TO GameClient.lua) ==========

-- REPLACE your RefreshFarmMenu function in GameClient.lua with this enhanced version:

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

	-- SECTION 1: Farm Overview
	self:CreateFarmInfoSection(contentArea, layout, 1)

	-- SECTION 2: Complete Inventory Display
	if playerData and playerData.farming and playerData.farming.inventory then
		self:CreateCompleteInventorySection(contentArea, layout, 2)
	end

	-- SECTION 3: Chicken Management & Feeding
	if playerData and playerData.defense and playerData.defense.chickens then
		self:CreateEnhancedChickenSection(contentArea, layout, 3)
	end

	-- SECTION 4: Pest Control Tools (always show, even if no tools yet)
	self:CreatePestControlSection(contentArea, layout, 4)
	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and contentArea then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end

-- NEW: Complete Inventory Section showing ALL items

function GameClient:CreateCompleteInventorySection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "CompleteInventory"
	inventoryFrame.Size = UDim2.new(1, 0, 0, 300)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(45, 65, 45)
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.LayoutOrder = layoutOrder
	inventoryFrame.Parent = parent

	local inventoryCorner = Instance.new("UICorner")
	inventoryCorner.CornerRadius = UDim.new(0.02, 0)
	inventoryCorner.Parent = inventoryFrame

	-- Title
	local inventoryTitle = Instance.new("TextLabel")
	inventoryTitle.Size = UDim2.new(1, 0, 0, 35)
	inventoryTitle.BackgroundTransparency = 1
	inventoryTitle.Text = "📦 Complete Farm Inventory"
	inventoryTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
	inventoryTitle.TextScaled = true
	inventoryTitle.Font = Enum.Font.GothamBold
	inventoryTitle.Parent = inventoryFrame

	-- Inventory container
	local inventoryScroll = Instance.new("ScrollingFrame")
	inventoryScroll.Size = UDim2.new(1, -20, 1, -45)
	inventoryScroll.Position = UDim2.new(0, 10, 0, 40)
	inventoryScroll.BackgroundTransparency = 1
	inventoryScroll.ScrollBarThickness = 6
	inventoryScroll.Parent = inventoryFrame

	local inventoryLayout = Instance.new("UIListLayout")
	inventoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	inventoryLayout.Padding = UDim.new(0, 5)
	inventoryLayout.Parent = inventoryScroll

	-- Organize items by category
	local itemCategories = {
		{name = "🌱 Seeds", items = {}, color = Color3.fromRGB(60, 120, 60)},
		{name = "🌾 Crops", items = {}, color = Color3.fromRGB(100, 150, 60)},
		{name = "🥛 Livestock Products", items = {}, color = Color3.fromRGB(60, 100, 150)}, -- ADDED
		{name = "🌾 Chicken Feed", items = {}, color = Color3.fromRGB(150, 120, 60)},
		{name = "🧪 Pest Control", items = {}, color = Color3.fromRGB(120, 80, 80)},
		{name = "🥚 Other Items", items = {}, color = Color3.fromRGB(80, 80, 120)}
	}

	-- Categorize items from farming inventory
	if playerData.farming and playerData.farming.inventory then
		for itemId, quantity in pairs(playerData.farming.inventory) do
			if quantity > 0 then
				if itemId:find("_seeds") then
					table.insert(itemCategories[1].items, {id = itemId, quantity = quantity})
				elseif itemId:find("_feed") then
					table.insert(itemCategories[4].items, {id = itemId, quantity = quantity})
				elseif itemId == "organic_pesticide" or itemId == "super_pesticide" then
					table.insert(itemCategories[5].items, {id = itemId, quantity = quantity})
				elseif itemId:find("egg") then
					table.insert(itemCategories[6].items, {id = itemId, quantity = quantity})
				else
					-- Regular crops
					table.insert(itemCategories[2].items, {id = itemId, quantity = quantity})
				end
			end
		end
	end

	-- ADDED: Categorize items from livestock inventory
	if playerData.livestock and playerData.livestock.inventory then
		for itemId, quantity in pairs(playerData.livestock.inventory) do
			if quantity > 0 then
				table.insert(itemCategories[3].items, {id = itemId, quantity = quantity})
			end
		end
	end

	-- Add items from defense inventory
	if playerData.defense then
		if playerData.defense.chickens and playerData.defense.chickens.feed then
			for feedType, quantity in pairs(playerData.defense.chickens.feed) do
				if quantity > 0 then
					table.insert(itemCategories[4].items, {id = feedType, quantity = quantity})
				end
			end
		end

		if playerData.defense.pestControl then
			for toolType, quantity in pairs(playerData.defense.pestControl) do
				if type(quantity) == "number" and quantity > 0 then
					table.insert(itemCategories[5].items, {id = toolType, quantity = quantity})
				end
			end
		end
	end

	-- Create category sections
	local categoryOrder = 1
	for _, category in ipairs(itemCategories) do
		if #category.items > 0 then
			self:CreateInventoryCategory(inventoryScroll, category, categoryOrder)
			categoryOrder = categoryOrder + 1
		end
	end

	-- Show message if no items
	if categoryOrder == 1 then
		local noItemsLabel = Instance.new("TextLabel")
		noItemsLabel.Size = UDim2.new(1, 0, 1, 0)
		noItemsLabel.BackgroundTransparency = 1
		noItemsLabel.Text = "No items in inventory.\nBuy items from the shop to see them here!"
		noItemsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noItemsLabel.TextScaled = true
		noItemsLabel.Font = Enum.Font.Gotham
		noItemsLabel.Parent = inventoryScroll
	end

	-- Update canvas size
	inventoryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		inventoryScroll.CanvasSize = UDim2.new(0, 0, 0, inventoryLayout.AbsoluteContentSize.Y + 10)
	end)
end
function GameClient:CreateInventoryCategory(parent, category, layoutOrder)
	-- Create category header frame
	local categoryFrame = Instance.new("Frame")
	categoryFrame.Name = category.name:gsub(" ", "") .. "CategoryHeader"
	categoryFrame.Size = UDim2.new(1, 0, 0, 35)
	categoryFrame.BackgroundColor3 = category.color
	categoryFrame.BorderSizePixel = 0
	categoryFrame.LayoutOrder = layoutOrder
	categoryFrame.Parent = parent

	local categoryCorner = Instance.new("UICorner")
	categoryCorner.CornerRadius = UDim.new(0.1, 0)
	categoryCorner.Parent = categoryFrame

	-- Category title
	local categoryTitle = Instance.new("TextLabel")
	categoryTitle.Size = UDim2.new(1, 0, 1, 0)
	categoryTitle.BackgroundTransparency = 1
	categoryTitle.Text = category.name
	categoryTitle.TextColor3 = Color3.new(1, 1, 1)
	categoryTitle.TextScaled = true
	categoryTitle.Font = Enum.Font.GothamBold
	categoryTitle.Parent = categoryFrame

	-- Create individual items in this category
	for i, item in ipairs(category.items) do
		self:CreateInventoryItem(parent, item, layoutOrder + (i * 0.1))
	end

	return categoryFrame
end
-- UPDATE CreateInventoryItem to handle milk selling:

function GameClient:CreateInventoryItem(parent, itemData, layoutOrder)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = itemData.id .. "_Item"
	itemFrame.Size = UDim2.new(1, 0, 0, 50)
	itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = layoutOrder
	itemFrame.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = itemFrame

	-- Item icon
	local itemIcon = Instance.new("TextLabel")
	itemIcon.Size = UDim2.new(0, 35, 0, 35)
	itemIcon.Position = UDim2.new(0, 8, 0, 7)
	itemIcon.BackgroundTransparency = 1
	itemIcon.Text = self:GetItemIcon(itemData.id)
	itemIcon.TextScaled = true
	itemIcon.Font = Enum.Font.SourceSansSemibold
	itemIcon.Parent = itemFrame

	-- Item info
	local itemInfo = Instance.new("TextLabel")
	itemInfo.Size = UDim2.new(0.6, 0, 1, 0)
	itemInfo.Position = UDim2.new(0, 50, 0, 0)
	itemInfo.BackgroundTransparency = 1
	itemInfo.Text = self:GetItemDisplayName(itemData.id) .. "\nQuantity: " .. itemData.quantity
	itemInfo.TextColor3 = Color3.new(1, 1, 1)
	itemInfo.TextScaled = true
	itemInfo.Font = Enum.Font.Gotham
	itemInfo.TextXAlignment = Enum.TextXAlignment.Left
	itemInfo.Parent = itemFrame

	-- Action button
	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.new(0, 80, 0, 35)
	actionButton.Position = UDim2.new(1, -90, 0, 7)
	actionButton.BorderSizePixel = 0
	actionButton.TextScaled = true
	actionButton.Font = Enum.Font.Gotham
	actionButton.Parent = itemFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = actionButton

	-- Different actions based on item type
	if itemData.id:find("_feed") then
		-- Feed chicken button
		actionButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
		actionButton.Text = "🐔 Feed"
		actionButton.TextColor3 = Color3.new(1, 1, 1)

		actionButton.MouseButton1Click:Connect(function()
			self:ShowChickenFeedingInterface(itemData.id)
		end)

	elseif itemData.id == "fresh_milk" or itemData.id == "processed_milk" or itemData.id == "cheese" then
		-- FIXED: Sell milk products button
		actionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
		actionButton.Text = "💰 Sell"
		actionButton.TextColor3 = Color3.new(1, 1, 1)

		actionButton.MouseButton1Click:Connect(function()
			-- FIXED: Pass the actual milk type, not just amount
			self:SellMilkProduct(itemData.id, 1)
		end)

	elseif itemData.id:find("egg") then
		-- ADDED: Sell egg products button
		actionButton.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
		actionButton.Text = "💰 Sell"
		actionButton.TextColor3 = Color3.new(1, 1, 1)

		actionButton.MouseButton1Click:Connect(function()
			self:SellEggProduct(itemData.id, 1)
		end)

	elseif itemData.id == "organic_pesticide" or itemData.id == "super_pesticide" then
		-- Use pesticide button
		actionButton.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
		actionButton.Text = "🧪 Use"
		actionButton.TextColor3 = Color3.new(1, 1, 1)

		actionButton.MouseButton1Click:Connect(function()
			self:UsePesticideMode()
		end)

	elseif not itemData.id:find("_seeds") then
		-- Sell crop button
		actionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
		actionButton.Text = "💰 Sell"
		actionButton.TextColor3 = Color3.new(1, 1, 1)

		actionButton.MouseButton1Click:Connect(function()
			if self.RemoteEvents.SellCrop then
				self.RemoteEvents.SellCrop:FireServer(itemData.id, 1)
			end
		end)

	else
		-- Info button for seeds
		actionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		actionButton.Text = "ℹ️ Info"
		actionButton.TextColor3 = Color3.new(1, 1, 1)

		actionButton.MouseButton1Click:Connect(function()
			self:ShowNotification("Seed Info", "Go to your farm plots to plant these seeds!", "info")
		end)
	end
end

-- ADD new milk selling function:

function GameClient:SellMilkProduct(milkType, amount)
	print("GameClient: Selling " .. amount .. "x " .. milkType)

	if self.RemoteEvents.SellMilk then
		-- FIXED: Send both milkType and amount to server
		self.RemoteEvents.SellMilk:FireServer(milkType, amount)
		self:ShowNotification("Selling Milk", "Selling " .. amount .. "x " .. self:GetItemDisplayName(milkType) .. "!", "info")
	else
		warn("GameClient: SellMilk remote event not available")
		self:ShowNotification("Error", "Milk selling system not available!", "error")
	end
end

-- ADD this new function for selling eggs in GameClient.lua:
function GameClient:SellEggProduct(eggType, amount)
	print("GameClient: Selling " .. amount .. "x " .. eggType)

	if self.RemoteEvents.SellEgg then
		self.RemoteEvents.SellEgg:FireServer(eggType, amount)
		self:ShowNotification("Selling Eggs", "Selling " .. amount .. "x " .. self:GetItemDisplayName(eggType) .. "!", "info")
	else
		warn("GameClient: SellEgg remote event not available")
		self:ShowNotification("Error", "Egg selling system not available!", "error")
	end
end

-- NEW: Enhanced Chicken Section with Feeding
function GameClient:CreateEnhancedChickenSection(parent, layout, layoutOrder)
	local chickenFrame = Instance.new("Frame")
	chickenFrame.Name = "EnhancedChickenManagement"
	chickenFrame.Size = UDim2.new(1, 0, 0, 280)
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
	chickenTitle.Text = "🐔 Chicken Management & Feeding"
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

	-- Feed All Chickens button
	local feedAllButton = Instance.new("TextButton")
	feedAllButton.Size = UDim2.new(1, 0, 0, 50)
	feedAllButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
	feedAllButton.BorderSizePixel = 0
	feedAllButton.Text = "🌾 Feed All Chickens (Auto-select best feed)"
	feedAllButton.TextColor3 = Color3.new(1, 1, 1)
	feedAllButton.TextScaled = true
	feedAllButton.Font = Enum.Font.GothamBold
	feedAllButton.LayoutOrder = 1
	feedAllButton.Parent = chickenContent

	local feedAllCorner = Instance.new("UICorner")
	feedAllCorner.CornerRadius = UDim.new(0.1, 0)
	feedAllCorner.Parent = feedAllButton

	feedAllButton.MouseButton1Click:Connect(function()
		self:FeedAllChickens()
	end)

	-- Individual chicken feeding options
	self:CreateChickenFeedingOptions(chickenContent, playerData)

	-- Update canvas size
	chickenLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		chickenContent.CanvasSize = UDim2.new(0, 0, 0, chickenLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- Create chicken feeding options
function GameClient:CreateChickenFeedingOptions(parent, playerData)
	-- Show available feed types
	local feedTypes = {}

	if playerData.defense and playerData.defense.chickens and playerData.defense.chickens.feed then
		for feedType, quantity in pairs(playerData.defense.chickens.feed) do
			if quantity > 0 then
				table.insert(feedTypes, {type = feedType, quantity = quantity})
			end
		end
	end

	-- Also check farming inventory for feed
	if playerData.farming and playerData.farming.inventory then
		for itemId, quantity in pairs(playerData.farming.inventory) do
			if itemId:find("_feed") and quantity > 0 then
				table.insert(feedTypes, {type = itemId, quantity = quantity})
			end
		end
	end

	if #feedTypes > 0 then
		for i, feedData in ipairs(feedTypes) do
			self:CreateFeedOption(parent, feedData, i + 1)
		end
	else
		local noFeedLabel = Instance.new("TextLabel")
		noFeedLabel.Size = UDim2.new(1, 0, 0, 40)
		noFeedLabel.BackgroundColor3 = Color3.fromRGB(80, 60, 60)
		noFeedLabel.BorderSizePixel = 0
		noFeedLabel.Text = "No chicken feed available. Buy feed from the shop!"
		noFeedLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
		noFeedLabel.TextScaled = true
		noFeedLabel.Font = Enum.Font.Gotham
		noFeedLabel.LayoutOrder = 2
		noFeedLabel.Parent = parent

		local noFeedCorner = Instance.new("UICorner")
		noFeedCorner.CornerRadius = UDim.new(0.1, 0)
		noFeedCorner.Parent = noFeedLabel
	end
end

-- Create individual feed option
function GameClient:CreateFeedOption(parent, feedData, layoutOrder)
	local feedFrame = Instance.new("Frame")
	feedFrame.Name = feedData.type .. "_FeedOption"
	feedFrame.Size = UDim2.new(1, 0, 0, 60)
	feedFrame.BackgroundColor3 = Color3.fromRGB(70, 90, 70)
	feedFrame.BorderSizePixel = 0
	feedFrame.LayoutOrder = layoutOrder + 1
	feedFrame.Parent = parent

	local feedCorner = Instance.new("UICorner")
	feedCorner.CornerRadius = UDim.new(0.1, 0)
	feedCorner.Parent = feedFrame

	-- Feed icon
	local feedIcon = Instance.new("TextLabel")
	feedIcon.Size = UDim2.new(0, 40, 0, 40)
	feedIcon.Position = UDim2.new(0, 10, 0, 10)
	feedIcon.BackgroundTransparency = 1
	feedIcon.Text = self:GetItemIcon(feedData.type)
	feedIcon.TextScaled = true
	feedIcon.Font = Enum.Font.SourceSansSemibold
	feedIcon.Parent = feedFrame

	-- Feed info
	local feedInfo = Instance.new("TextLabel")
	feedInfo.Size = UDim2.new(0.6, 0, 1, 0)
	feedInfo.Position = UDim2.new(0, 60, 0, 0)
	feedInfo.BackgroundTransparency = 1
	feedInfo.Text = self:GetItemDisplayName(feedData.type) .. "\nAvailable: " .. feedData.quantity
	feedInfo.TextColor3 = Color3.new(1, 1, 1)
	feedInfo.TextScaled = true
	feedInfo.Font = Enum.Font.Gotham
	feedInfo.TextXAlignment = Enum.TextXAlignment.Left
	feedInfo.Parent = feedFrame

	-- Feed button
	local feedButton = Instance.new("TextButton")
	feedButton.Size = UDim2.new(0, 80, 0, 40)
	feedButton.Position = UDim2.new(1, -90, 0, 10)
	feedButton.BackgroundColor3 = Color3.fromRGB(120, 180, 120)
	feedButton.BorderSizePixel = 0
	feedButton.Text = "🐔 Use Feed"
	feedButton.TextColor3 = Color3.new(1, 1, 1)
	feedButton.TextScaled = true
	feedButton.Font = Enum.Font.Gotham
	feedButton.Parent = feedFrame

	local feedButtonCorner = Instance.new("UICorner")
	feedButtonCorner.CornerRadius = UDim.new(0.2, 0)
	feedButtonCorner.Parent = feedButton

	feedButton.MouseButton1Click:Connect(function()
		self:ShowChickenFeedingInterface(feedData.type)
	end)
end

-- NEW: Show chicken feeding interface
function GameClient:ShowChickenFeedingInterface(feedType)
	-- Remove existing feeding UI
	local existingUI = self.LocalPlayer.PlayerGui:FindFirstChild("ChickenFeedingUI")
	if existingUI then existingUI:Destroy() end

	local feedingUI = Instance.new("ScreenGui")
	feedingUI.Name = "ChickenFeedingUI"
	feedingUI.ResetOnSpawn = false
	feedingUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	feedingUI.Parent = self.LocalPlayer.PlayerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = feedingUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
	title.BorderSizePixel = 0
	title.Text = "🐔 Feed Chickens - " .. self:GetItemDisplayName(feedType)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = title

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
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
		feedingUI:Destroy()
	end)

	-- Content area
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -20, 1, -70)
	contentArea.Position = UDim2.new(0, 10, 0, 60)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainFrame

	-- Feed all button
	local feedAllButton = Instance.new("TextButton")
	feedAllButton.Size = UDim2.new(1, 0, 0, 50)
	feedAllButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
	feedAllButton.BorderSizePixel = 0
	feedAllButton.Text = "🌾 Feed All Chickens with " .. self:GetItemDisplayName(feedType)
	feedAllButton.TextColor3 = Color3.new(1, 1, 1)
	feedAllButton.TextScaled = true
	feedAllButton.Font = Enum.Font.GothamBold
	feedAllButton.Parent = contentArea

	local feedAllButtonCorner = Instance.new("UICorner")
	feedAllButtonCorner.CornerRadius = UDim.new(0.1, 0)
	feedAllButtonCorner.Parent = feedAllButton

	feedAllButton.MouseButton1Click:Connect(function()
		self:FeedAllChickensWithType(feedType)
		feedingUI:Destroy()
	end)

	-- Info text
	local infoText = Instance.new("TextLabel")
	infoText.Size = UDim2.new(1, 0, 1, -60)
	infoText.Position = UDim2.new(0, 0, 0, 60)
	infoText.BackgroundTransparency = 1
	infoText.Text = "This will feed all your deployed chickens with " .. self:GetItemDisplayName(feedType) .. ".\n\nWell-fed chickens:\n• Hunt pests more effectively\n• Lay eggs more frequently\n• Stay healthy longer\n\nHungry chickens may become less effective or even leave your farm!"
	infoText.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	infoText.TextScaled = true
	infoText.Font = Enum.Font.Gotham
	infoText.TextWrapped = true
	infoText.Parent = contentArea

	-- Animate in
	mainFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
	local slideIn = TweenService:Create(mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0.5, 0)}
	)
	slideIn:Play()
end

-- Feed all chickens
function GameClient:FeedAllChickens()
	if self.RemoteEvents.FeedAllChickens then
		self.RemoteEvents.FeedAllChickens:FireServer()
		self:ShowNotification("🐔 Feeding Chickens", "Feeding all your chickens with the best available feed!", "success")
	end
end

-- Feed all chickens with specific type
function GameClient:FeedAllChickensWithType(feedType)
	if self.RemoteEvents.FeedChickensWithType then
		self.RemoteEvents.FeedChickensWithType:FireServer(feedType)
		self:ShowNotification("🐔 Feeding Chickens", "Fed all chickens with " .. self:GetItemDisplayName(feedType) .. "!", "success")
	end
end

-- Get item icon
function GameClient:GetItemIcon(itemId)
	local icons = {
		-- Seeds
		carrot_seeds = "🥕",
		corn_seeds = "🌽", 
		strawberry_seeds = "🍓",
		golden_seeds = "✨",

		-- Crops
		carrot = "🥕",
		corn = "🌽",
		strawberry = "🍓",
		golden_fruit = "✨",

		-- Livestock Products (ADDED)
		fresh_milk = "🥛",
		processed_milk = "🧈",
		cheese = "🧀",

		-- Feed
		basic_feed = "🌾",
		premium_feed = "⭐",
		grain_feed = "🌾",

		-- Pest control
		organic_pesticide = "🧪",
		super_pesticide = "💉",
		pest_detector = "📡",

		-- Eggs
		chicken_egg = "🥚",
		guinea_egg = "🥚",
		rooster_egg = "🥚"
	}
	return icons[itemId] or "📦"
end
-- Get item display name
function GameClient:GetItemDisplayName(itemId)
	local names = {
		-- Seeds
		carrot_seeds = "Carrot Seeds",
		corn_seeds = "Corn Seeds",
		strawberry_seeds = "Strawberry Seeds", 
		golden_seeds = "Golden Seeds",

		-- Crops
		carrot = "Carrot",
		corn = "Corn",
		strawberry = "Strawberry",
		golden_fruit = "Golden Fruit",

		-- Livestock Products (ADDED)
		fresh_milk = "Fresh Milk",
		processed_milk = "Processed Milk",
		cheese = "Artisan Cheese",

		-- Feed
		basic_feed = "Basic Chicken Feed",
		premium_feed = "Premium Chicken Feed",
		grain_feed = "Grain Feed",

		-- Pest control
		organic_pesticide = "Organic Pesticide",
		super_pesticide = "Super Pesticide",
		pest_detector = "Pest Detector",

		-- Eggs
		chicken_egg = "Chicken Egg",
		guinea_egg = "Guinea Fowl Egg", 
		rooster_egg = "Rooster Egg"
	}
	return names[itemId] or itemId:gsub("_", " ")
end



-- REPLACE the CreateChickenManagementSection function in GameClient.lua

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
	chickenTitle.Text = "🐔 Active Chicken Defense"
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
	local totalChickens = 0
	local deployedChickens = 0

	-- Show deployed chickens
	if playerData and playerData.defense and playerData.defense.chickens and playerData.defense.chickens.owned then
		for chickenId, chickenData in pairs(playerData.defense.chickens.owned) do
			totalChickens = totalChickens + 1
			if chickenData.status == "deployed" then
				deployedChickens = deployedChickens + 1
				self:CreateActiveChickenDisplayItem(chickenContent, chickenId, chickenData)
			end
		end
	end

	-- Status summary
	local statusFrame = Instance.new("Frame")
	statusFrame.Size = UDim2.new(1, 0, 0, 60)
	statusFrame.BackgroundColor3 = Color3.fromRGB(80, 100, 80)
	statusFrame.BorderSizePixel = 0
	statusFrame.LayoutOrder = 1
	statusFrame.Parent = chickenContent

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0.1, 0)
	statusCorner.Parent = statusFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 1, 0)
	statusLabel.Position = UDim2.new(0, 10, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.new(1, 1, 1)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = statusFrame

	if deployedChickens > 0 then
		statusLabel.Text = "🛡️ " .. deployedChickens .. " chickens actively protecting your farm!\nThey will automatically hunt pests and lay eggs."
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for active protection
	else
		statusLabel.Text = "🛒 No chickens deployed yet.\nBuy chickens from the shop - they deploy automatically!"
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100) -- Orange for no protection
	end

	-- Buy more chickens button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(1, 0, 0, 50)
	buyButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Orange
	buyButton.BorderSizePixel = 0
	buyButton.Text = "🛒 Buy More Chickens (Auto-Deploy)"
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.LayoutOrder = 100
	buyButton.Parent = chickenContent

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.1, 0)
	buyCorner.Parent = buyButton

	buyButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Shop")
	end)

	-- Hover effect for buy button
	buyButton.MouseEnter:Connect(function()
		TweenService:Create(buyButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 160, 20)}):Play()
	end)

	buyButton.MouseLeave:Connect(function()
		TweenService:Create(buyButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 140, 0)}):Play()
	end)

	-- Feed management (if player has feed)
	if playerData and playerData.defense and playerData.defense.chickens and playerData.defense.chickens.feed then
		self:CreateFeedManagementSection(chickenContent, playerData.defense.chickens.feed)
	end

	-- Update canvas size
	chickenLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		chickenContent.CanvasSize = UDim2.new(0, 0, 0, chickenLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- NEW FUNCTION: Display active/deployed chickens (replaces deployment interface)
function GameClient:CreateActiveChickenDisplayItem(parent, chickenId, chickenData)
	local chickenItem = Instance.new("Frame")
	chickenItem.Name = "ActiveChicken_" .. chickenId
	chickenItem.Size = UDim2.new(1, 0, 0, 70)
	chickenItem.BackgroundColor3 = Color3.fromRGB(70, 90, 70)
	chickenItem.BorderSizePixel = 0
	chickenItem.LayoutOrder = 2
	chickenItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = chickenItem

	-- Chicken icon
	local chickenIcon = Instance.new("TextLabel")
	chickenIcon.Size = UDim2.new(0, 50, 0, 50)
	chickenIcon.Position = UDim2.new(0, 10, 0, 10)
	chickenIcon.BackgroundTransparency = 1
	chickenIcon.Text = self:GetChickenIcon(chickenData.type)
	chickenIcon.TextScaled = true
	chickenIcon.Font = Enum.Font.SourceSansSemibold
	chickenIcon.Parent = chickenItem

	-- Chicken info
	local chickenInfo = Instance.new("TextLabel")
	chickenInfo.Size = UDim2.new(0.6, 0, 1, 0)
	chickenInfo.Position = UDim2.new(0, 70, 0, 0)
	chickenInfo.BackgroundTransparency = 1
	chickenInfo.Text = self:GetChickenDisplayName(chickenData.type) .. "\n🛡️ Actively Protecting Farm"
	chickenInfo.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for active
	chickenInfo.TextScaled = true
	chickenInfo.Font = Enum.Font.Gotham
	chickenInfo.TextXAlignment = Enum.TextXAlignment.Left
	chickenInfo.Parent = chickenItem

	-- Status indicator (pulsing green dot)
	local statusDot = Instance.new("Frame")
	statusDot.Size = UDim2.new(0, 12, 0, 12)
	statusDot.Position = UDim2.new(1, -25, 0, 15)
	statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	statusDot.BorderSizePixel = 0
	statusDot.Parent = chickenItem

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(0.5, 0)
	dotCorner.Parent = statusDot

	-- Pulsing animation for status dot
	spawn(function()
		while statusDot and statusDot.Parent do
			TweenService:Create(statusDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				BackgroundColor3 = Color3.fromRGB(100, 255, 100),
				Size = UDim2.new(0, 16, 0, 16)
			}):Play()
			wait(0.1)
		end
	end)

	-- Action label (no more deploy button needed)
	local actionLabel = Instance.new("TextLabel")
	actionLabel.Size = UDim2.new(0, 80, 0, 25)
	actionLabel.Position = UDim2.new(1, -90, 0, 35)
	actionLabel.BackgroundTransparency = 1
	actionLabel.Text = "🔄 Patrolling"
	actionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	actionLabel.TextScaled = true
	actionLabel.Font = Enum.Font.Gotham
	actionLabel.Parent = chickenItem
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

	-- FIXED: Check the correct data path (defense.pestControl instead of pestControl)
	if playerData and playerData.defense and playerData.defense.pestControl then
		-- Pesticide inventory
		if playerData.defense.pestControl.organic_pesticide and playerData.defense.pestControl.organic_pesticide > 0 then
			self:CreatePestControlItem(pestContent, "organic_pesticide", playerData.defense.pestControl.organic_pesticide)
		end

		-- Super pesticide inventory (if exists)
		if playerData.defense.pestControl.super_pesticide and playerData.defense.pestControl.super_pesticide > 0 then
			self:CreatePestControlItem(pestContent, "super_pesticide", playerData.defense.pestControl.super_pesticide)
		end

		-- Pest detector status
		if playerData.defense.pestControl.pest_detector then
			self:CreatePestDetectorDisplay(pestContent)
		end
	else
		-- No pest control tools available
		local noPestToolsLabel = Instance.new("TextLabel")
		noPestToolsLabel.Size = UDim2.new(1, 0, 0, 40)
		noPestToolsLabel.BackgroundColor3 = Color3.fromRGB(80, 60, 60)
		noPestToolsLabel.BorderSizePixel = 0
		noPestToolsLabel.Text = "No pest control tools available.\nBuy tools from the shop first!"
		noPestToolsLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
		noPestToolsLabel.TextScaled = true
		noPestToolsLabel.Font = Enum.Font.Gotham
		noPestToolsLabel.LayoutOrder = 1
		noPestToolsLabel.Parent = pestContent

		local noToolsCorner = Instance.new("UICorner")
		noToolsCorner.CornerRadius = UDim.new(0.1, 0)
		noToolsCorner.Parent = noPestToolsLabel
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
function GameClient:CreatePestDetectorDisplay(parent)
	local detectorFrame = Instance.new("Frame")
	detectorFrame.Name = "PestDetector"
	detectorFrame.Size = UDim2.new(1, 0, 0, 50)
	detectorFrame.BackgroundColor3 = Color3.fromRGB(90, 70, 70)
	detectorFrame.BorderSizePixel = 0
	detectorFrame.LayoutOrder = 2
	detectorFrame.Parent = parent

	local detectorCorner = Instance.new("UICorner")
	detectorCorner.CornerRadius = UDim.new(0.1, 0)
	detectorCorner.Parent = detectorFrame

	-- Detector icon
	local detectorIcon = Instance.new("TextLabel")
	detectorIcon.Size = UDim2.new(0, 35, 0, 35)
	detectorIcon.Position = UDim2.new(0, 10, 0, 7)
	detectorIcon.BackgroundTransparency = 1
	detectorIcon.Text = "📡"
	detectorIcon.TextScaled = true
	detectorIcon.Font = Enum.Font.SourceSansSemibold
	detectorIcon.Parent = detectorFrame

	-- Detector info
	local detectorInfo = Instance.new("TextLabel")
	detectorInfo.Size = UDim2.new(0.8, 0, 1, 0)
	detectorInfo.Position = UDim2.new(0, 55, 0, 0)
	detectorInfo.BackgroundTransparency = 1
	detectorInfo.Text = "📡 Pest Detector Active\nEarly warning system operational"
	detectorInfo.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for active
	detectorInfo.TextScaled = true
	detectorInfo.Font = Enum.Font.Gotham
	detectorInfo.TextXAlignment = Enum.TextXAlignment.Left
	detectorInfo.Parent = detectorFrame

	-- Status indicator (pulsing green dot)
	local statusDot = Instance.new("Frame")
	statusDot.Size = UDim2.new(0, 12, 0, 12)
	statusDot.Position = UDim2.new(1, -25, 0, 15)
	statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	statusDot.BorderSizePixel = 0
	statusDot.Parent = detectorFrame

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(0.5, 0)
	dotCorner.Parent = statusDot

	-- Pulsing animation for status dot
	spawn(function()
		while statusDot and statusDot.Parent do
			TweenService:Create(statusDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				BackgroundColor3 = Color3.fromRGB(150, 255, 150),
				Size = UDim2.new(0, 16, 0, 16)
			}):Play()
			wait(0.1)
		end
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
		local shopItems = self:GetEnhancedShopItems()  -- CHANGED: Use enhanced version
		if shopItems and #shopItems > 0 then
			self:CreateShopContent(contentArea, shopItems)  -- Use the FIXED version from above
		else
			self:CreateDefaultShopContent(contentArea)
		end
	end)
end
-- REPLACE the GetShopItems function in GameClient.lua:

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

-- Replace the GetDefaultShopItems function in your GameClient.lua with this complete version

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

		-- ========== ROOF PROTECTION ==========
		{
			id = "basic_roof",
			name = "🏠 Basic Roof Protection",
			category = "farm",
			price = 500,
			currency = "coins",
			description = "Protect your crops from UFO attacks! Basic roof covers 1 farm plot.",
			icon = "🏠",
			maxPurchase = 10
		},
		{
			id = "reinforced_roof", 
			name = "🏘️ Reinforced Roof Protection",
			category = "farm",
			price = 1500,
			currency = "coins",
			description = "Heavy-duty roof protection! Covers 4 plots and is UFO-proof.",
			icon = "🏘️",
			maxPurchase = 3
		},
		{
			id = "mega_dome",
			name = "🛡️ Mega Protection Dome", 
			category = "premium",
			price = 100,
			currency = "farmTokens",
			description = "Ultimate protection! Dome covers ALL your farm plots and blocks UFO attacks completely.",
			icon = "🛡️",
			maxPurchase = 1
		},

		-- ========== CHICKEN DEFENSE ==========
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
			id = "guinea_fowl", 
			name = "🦃 Guinea Fowl",
			category = "defense",
			price = 300,
			currency = "coins",
			description = "Anti-locust specialist. Provides early warning system and superior pest elimination.",
			icon = "🦃",
			maxPurchase = 10
		},
		{
			id = "rooster",
			name = "🐓 Rooster", 
			category = "defense",
			price = 500,
			currency = "coins",
			description = "Flock leader that boosts all nearby chickens and reduces pest spawn rates.",
			icon = "🐓",
			maxPurchase = 3
		},

		-- ========== CHICKEN FEED ==========
		{
			id = "basic_feed",
			name = "🌾 Basic Chicken Feed",
			category = "defense", 
			price = 10,
			currency = "coins",
			description = "Keeps chickens fed and working. Each unit provides 6 hours of feeding.",
			icon = "🌾",
			maxPurchase = 100
		},
		{
			id = "premium_feed",
			name = "⭐ Premium Chicken Feed",
			category = "defense",
			price = 25,
			currency = "coins",
			description = "High-quality feed that increases egg production by 20% and lasts 12 hours.",
			icon = "⭐",
			maxPurchase = 50
		},

		-- ========== PEST CONTROL TOOLS ==========
		{
			id = "organic_pesticide",
			name = "🧪 Organic Pesticide",
			category = "tools",
			price = 50,
			currency = "coins", 
			description = "Manually eliminate pests from crops. One-time use, affects 3x3 area around target crop.",
			icon = "🧪",
			maxPurchase = 20
		},
		{
			id = "pest_detector",
			name = "📡 Pest Detector",
			category = "tools",
			price = 200,
			currency = "coins",
			description = "Early warning system that alerts you to pest infestations before they cause major damage.",
			icon = "📡",
			maxPurchase = 1
		},
		{
			id = "super_pesticide",
			name = "💉 Super Pesticide",
			category = "tools",
			price = 25,
			currency = "farmTokens",
			description = "Industrial-grade pesticide that eliminates ALL pests from your entire farm instantly!",
			icon = "💉",
			maxPurchase = 5
		},

		-- ========== LIVESTOCK UPGRADES ==========
		{
			id = "milk_efficiency_1",
			name = "🥛 Faster Milking I",
			category = "farm",
			price = 100,
			currency = "coins",
			description = "Reduce milk collection cooldown by 2 seconds.",
			icon = "🥛",
			maxPurchase = 1
		},
		{
			id = "milk_efficiency_2",
			name = "🥛 Faster Milking II",
			category = "farm",
			price = 250,
			currency = "coins",
			description = "Reduce milk collection cooldown by 5 seconds total.",
			icon = "🥛",
			maxPurchase = 1
		},
		{
			id = "milk_value_boost",
			name = "💰 Milk Value Boost",
			category = "farm",
			price = 300,
			currency = "coins",
			description = "Increase coins earned per milk collection by 5.",
			icon = "💰",
			maxPurchase = 1
		}
	}
end
-- Update the CreateShopContent function to include new categories:


-- REPLACE the CreateShopContent function in GameClient.lua with this version:

function GameClient:CreateShopContent(parent, shopItems)
	-- Remove loading label
	local loadingLabel = parent:FindFirstChild("LoadingLabel")
	if loadingLabel then loadingLabel:Destroy() end

	-- Create main layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = parent

	-- FIXED: Complete categories list including all item types
	local categories = {
		{name = "🌱 Seeds", key = "seeds", color = Color3.fromRGB(60, 120, 60)},
		{name = "🚜 Farm Upgrades", key = "farm", color = Color3.fromRGB(120, 90, 60)},
		{name = "⛏️ Mining Equipment", key = "mining", color = Color3.fromRGB(80, 60, 120)},
		{name = "🔨 Crafting Stations", key = "crafting", color = Color3.fromRGB(120, 80, 60)},
		{name = "🐔 Chicken Defense", key = "defense", color = Color3.fromRGB(100, 80, 120)},
		{name = "🧪 Pest Control", key = "tools", color = Color3.fromRGB(120, 80, 80)},
		{name = "✨ Enhancements", key = "farming", color = Color3.fromRGB(100, 100, 150)},
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
		else
			-- Debug: Show which categories are empty
			print("GameClient: No items found for category: " .. category.key)
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
	-- Defensive checks for nil values
	if not item then 
		warn("GameClient: CanAffordItem called with nil item")
		return false 
	end

	if not item.price or type(item.price) ~= "number" then
		warn("GameClient: Item " .. (item.id or "unknown") .. " has invalid price: " .. tostring(item.price))
		return false
	end

	if not item.currency or type(item.currency) ~= "string" then
		warn("GameClient: Item " .. (item.id or "unknown") .. " has invalid currency: " .. tostring(item.currency))
		return false
	end

	local playerData = self:GetPlayerData()
	if not playerData then 
		warn("GameClient: No player data available for affordability check")
		return false 
	end

	-- Safe currency check with default value
	local playerCurrency = playerData[item.currency]
	if not playerCurrency or type(playerCurrency) ~= "number" then
		playerCurrency = 0
	end

	local canAfford = playerCurrency >= item.price

	-- Debug logging for shop issues
	if not canAfford then
		print("GameClient: Cannot afford " .. (item.id or "unknown") .. " - Need " .. item.price .. " " .. item.currency .. ", have " .. playerCurrency)
	end

	return canAfford
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
--[[
    ENHANCED GameClient.lua - MINING, CRAFTING & RARITY UI
    Add these sections to your existing GameClient.lua
    
    NEW FEATURES:
    ✅ Mining interface with skill progression
    ✅ Crafting interface with recipe browser
    ✅ Enhanced shop with new categories
    ✅ Rarity display system
    ✅ Cave access and mining tools UI
]]

-- Add these new UI sections to your existing GameClient.lua

-- ========== NEW UI STATE ADDITIONS ==========

-- Add to existing GameClient.UIState:
GameClient.UIState.ActiveCraftingStation = nil
GameClient.UIState.MiningInterface = nil
GameClient.UIState.RarityEffects = {}

-- Add to existing GameClient.FarmingState:
GameClient.FarmingState.activeBoosters = {}
GameClient.FarmingState.rarityPreview = nil

-- ========== MINING INTERFACE ==========

-- Create mining skill interface
function GameClient:CreateMiningInterface()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing mining UI
	local existingUI = playerGui:FindFirstChild("MiningUI")
	if existingUI then existingUI:Destroy() end

	local miningUI = Instance.new("ScreenGui")
	miningUI.Name = "MiningUI"
	miningUI.ResetOnSpawn = false
	miningUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	miningUI.Parent = playerGui

	-- Mining button (left side, below farming)
	local miningButton = Instance.new("TextButton")
	miningButton.Name = "MiningButton"
	miningButton.Size = UDim2.new(0, 120, 0, 50)
	miningButton.Position = UDim2.new(0, 20, 0.4, 120) -- Below farm button
	miningButton.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
	miningButton.BorderSizePixel = 0
	miningButton.Text = "⛏️ Mining"
	miningButton.TextColor3 = Color3.new(1, 1, 1)
	miningButton.TextScaled = true
	miningButton.Font = Enum.Font.GothamBold
	miningButton.Parent = miningUI

	local miningCorner = Instance.new("UICorner")
	miningCorner.CornerRadius = UDim.new(0.1, 0)
	miningCorner.Parent = miningButton

	-- Crafting button (below mining)
	local craftingButton = Instance.new("TextButton")
	craftingButton.Name = "CraftingButton"
	craftingButton.Size = UDim2.new(0, 120, 0, 50)
	craftingButton.Position = UDim2.new(0, 20, 0.4, 180) -- Below mining button
	craftingButton.BackgroundColor3 = Color3.fromRGB(120, 80, 60)
	craftingButton.BorderSizePixel = 0
	craftingButton.Text = "🔨 Crafting"
	craftingButton.TextColor3 = Color3.new(1, 1, 1)
	craftingButton.TextScaled = true
	craftingButton.Font = Enum.Font.GothamBold
	craftingButton.Parent = miningUI

	local craftingCorner = Instance.new("UICorner")
	craftingCorner.CornerRadius = UDim.new(0.1, 0)
	craftingCorner.Parent = craftingButton

	-- Connect events
	miningButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Mining")
	end)

	craftingButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Crafting")
	end)

	-- Hover effects
	miningButton.MouseEnter:Connect(function()
		TweenService:Create(miningButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 80, 140)}):Play()
	end)

	miningButton.MouseLeave:Connect(function()
		TweenService:Create(miningButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 60, 120)}):Play()
	end)

	craftingButton.MouseEnter:Connect(function()
		TweenService:Create(craftingButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(140, 100, 80)}):Play()
	end)

	craftingButton.MouseLeave:Connect(function()
		TweenService:Create(craftingButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 80, 60)}):Play()
	end)

	self.UI.MiningUI = miningUI
	print("GameClient: Mining and crafting UI created")
end

-- Refresh mining menu
function GameClient:RefreshMiningMenu()
	local menu = self.UI.Menus.Mining
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = contentArea

	local playerData = self:GetPlayerData()

	-- Mining skill section
	self:CreateMiningSkillSection(contentArea, layout, 1)

	-- Cave access section
	self:CreateCaveAccessSection(contentArea, layout, 2)

	-- Tool management section
	self:CreateToolManagementSection(contentArea, layout, 3)

	-- Ore inventory section
	self:CreateOreInventorySection(contentArea, layout, 4)

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and contentArea then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end

-- Create mining skill section
function GameClient:CreateMiningSkillSection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local skillFrame = Instance.new("Frame")
	skillFrame.Name = "MiningSkill"
	skillFrame.Size = UDim2.new(1, 0, 0, 120)
	skillFrame.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
	skillFrame.BorderSizePixel = 0
	skillFrame.LayoutOrder = layoutOrder
	skillFrame.Parent = parent

	local skillCorner = Instance.new("UICorner")
	skillCorner.CornerRadius = UDim.new(0.02, 0)
	skillCorner.Parent = skillFrame

	-- Title
	local skillTitle = Instance.new("TextLabel")
	skillTitle.Size = UDim2.new(1, 0, 0, 35)
	skillTitle.BackgroundTransparency = 1
	skillTitle.Text = "⛏️ Mining Skill"
	skillTitle.TextColor3 = Color3.new(1, 1, 1)
	skillTitle.TextScaled = true
	skillTitle.Font = Enum.Font.GothamBold
	skillTitle.Parent = skillFrame

	-- Skill info
	local miningLevel = playerData and playerData.mining and playerData.mining.level or 1
	local miningXP = playerData and playerData.mining and playerData.mining.xp or 0

	local skillInfo = Instance.new("TextLabel")
	skillInfo.Size = UDim2.new(1, -20, 0, 25)
	skillInfo.Position = UDim2.new(0, 10, 0, 40)
	skillInfo.BackgroundTransparency = 1
	skillInfo.Text = "Level: " .. miningLevel .. " | XP: " .. miningXP
	skillInfo.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	skillInfo.TextScaled = true
	skillInfo.Font = Enum.Font.Gotham
	skillInfo.TextXAlignment = Enum.TextXAlignment.Left
	skillInfo.Parent = skillFrame

	-- XP Progress bar
	local progressFrame = Instance.new("Frame")
	progressFrame.Size = UDim2.new(1, -20, 0, 20)
	progressFrame.Position = UDim2.new(0, 10, 0, 70)
	progressFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	progressFrame.BorderSizePixel = 0
	progressFrame.Parent = skillFrame

	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0.3, 0, 1, 0) -- Example progress
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressFrame

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0.1, 0)
	progressCorner.Parent = progressFrame

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0.1, 0)
	progressBarCorner.Parent = progressBar
end

-- Create cave access section
function GameClient:CreateCaveAccessSection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local caveFrame = Instance.new("Frame")
	caveFrame.Name = "CaveAccess"
	caveFrame.Size = UDim2.new(1, 0, 0, 100)
	caveFrame.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
	caveFrame.BorderSizePixel = 0
	caveFrame.LayoutOrder = layoutOrder
	caveFrame.Parent = parent

	local caveCorner = Instance.new("UICorner")
	caveCorner.CornerRadius = UDim.new(0.02, 0)
	caveCorner.Parent = caveFrame

	-- Title
	local caveTitle = Instance.new("TextLabel")
	caveTitle.Size = UDim2.new(1, 0, 0, 35)
	caveTitle.BackgroundTransparency = 1
	caveTitle.Text = "🕳️ Mining Caves"
	caveTitle.TextColor3 = Color3.new(1, 1, 1)
	caveTitle.TextScaled = true
	caveTitle.Font = Enum.Font.GothamBold
	caveTitle.Parent = caveFrame

	local hasAccess = playerData and playerData.mining and playerData.mining.caveAccess

	if hasAccess then
		-- Access granted - show teleport button
		local teleportButton = Instance.new("TextButton")
		teleportButton.Size = UDim2.new(0.8, 0, 0, 40)
		teleportButton.Position = UDim2.new(0.1, 0, 0, 50)
		teleportButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
		teleportButton.BorderSizePixel = 0
		teleportButton.Text = "🚀 Enter Mining Caves"
		teleportButton.TextColor3 = Color3.new(1, 1, 1)
		teleportButton.TextScaled = true
		teleportButton.Font = Enum.Font.GothamBold
		teleportButton.Parent = caveFrame

		local teleportCorner = Instance.new("UICorner")
		teleportCorner.CornerRadius = UDim.new(0.1, 0)
		teleportCorner.Parent = teleportButton

		teleportButton.MouseButton1Click:Connect(function()
			self:RequestCaveTeleport()
		end)
	else
		-- Access needed - show purchase info
		local accessInfo = Instance.new("TextLabel")
		accessInfo.Size = UDim2.new(1, -20, 0, 50)
		accessInfo.Position = UDim2.new(0, 10, 0, 40)
		accessInfo.BackgroundTransparency = 1
		accessInfo.Text = "🔒 Cave Access Required\nPurchase from shop to unlock mining!"
		accessInfo.TextColor3 = Color3.fromRGB(255, 200, 200)
		accessInfo.TextScaled = true
		accessInfo.Font = Enum.Font.Gotham
		accessInfo.Parent = caveFrame
	end
end

-- Create tool management section
function GameClient:CreateToolManagementSection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local toolFrame = Instance.new("Frame")
	toolFrame.Name = "ToolManagement"
	toolFrame.Size = UDim2.new(1, 0, 0, 150)
	toolFrame.BackgroundColor3 = Color3.fromRGB(100, 80, 60)
	toolFrame.BorderSizePixel = 0
	toolFrame.LayoutOrder = layoutOrder
	toolFrame.Parent = parent

	local toolCorner = Instance.new("UICorner")
	toolCorner.CornerRadius = UDim.new(0.02, 0)
	toolCorner.Parent = toolFrame

	-- Title
	local toolTitle = Instance.new("TextLabel")
	toolTitle.Size = UDim2.new(1, 0, 0, 35)
	toolTitle.BackgroundTransparency = 1
	toolTitle.Text = "⛏️ Mining Tools"
	toolTitle.TextColor3 = Color3.new(1, 1, 1)
	toolTitle.TextScaled = true
	toolTitle.Font = Enum.Font.GothamBold
	toolTitle.Parent = toolFrame

	-- Current tool display
	local currentTool = playerData and playerData.mining and playerData.mining.currentTool

	if currentTool then
		local toolInfo = Instance.new("TextLabel")
		toolInfo.Size = UDim2.new(1, -20, 0, 30)
		toolInfo.Position = UDim2.new(0, 10, 0, 40)
		toolInfo.BackgroundTransparency = 1
		toolInfo.Text = "🔧 Equipped: " .. currentTool:gsub("_", " ")
		toolInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
		toolInfo.TextScaled = true
		toolInfo.Font = Enum.Font.Gotham
		toolInfo.TextXAlignment = Enum.TextXAlignment.Left
		toolInfo.Parent = toolFrame

		-- Durability display
		local durability = playerData.mining.toolDurability and playerData.mining.toolDurability[currentTool] or 0
		local durabilityInfo = Instance.new("TextLabel")
		durabilityInfo.Size = UDim2.new(1, -20, 0, 25)
		durabilityInfo.Position = UDim2.new(0, 10, 0, 75)
		durabilityInfo.BackgroundTransparency = 1
		durabilityInfo.Text = "Durability: " .. durability .. " uses remaining"
		durabilityInfo.TextColor3 = durability > 20 and Color3.new(0.9, 0.9, 0.9) or Color3.fromRGB(255, 100, 100)
		durabilityInfo.TextScaled = true
		durabilityInfo.Font = Enum.Font.Gotham
		durabilityInfo.TextXAlignment = Enum.TextXAlignment.Left
		durabilityInfo.Parent = toolFrame

		-- Upgrade tool button
		local upgradeButton = Instance.new("TextButton")
		upgradeButton.Size = UDim2.new(0.8, 0, 0, 30)
		upgradeButton.Position = UDim2.new(0.1, 0, 0, 110)
		upgradeButton.BackgroundColor3 = Color3.fromRGB(150, 120, 100)
		upgradeButton.BorderSizePixel = 0
		upgradeButton.Text = "⬆️ Upgrade Tool (Shop)"
		upgradeButton.TextColor3 = Color3.new(1, 1, 1)
		upgradeButton.TextScaled = true
		upgradeButton.Font = Enum.Font.Gotham
		upgradeButton.Parent = toolFrame

		local upgradeCorner = Instance.new("UICorner")
		upgradeCorner.CornerRadius = UDim.new(0.1, 0)
		upgradeCorner.Parent = upgradeButton

		upgradeButton.MouseButton1Click:Connect(function()
			self:OpenMenu("Shop")
		end)
	else
		local noToolInfo = Instance.new("TextLabel")
		noToolInfo.Size = UDim2.new(1, -20, 1, -40)
		noToolInfo.Position = UDim2.new(0, 10, 0, 40)
		noToolInfo.BackgroundTransparency = 1
		noToolInfo.Text = "❌ No Mining Tool Equipped\nPurchase a pickaxe from the shop!"
		noToolInfo.TextColor3 = Color3.fromRGB(255, 200, 200)
		noToolInfo.TextScaled = true
		noToolInfo.Font = Enum.Font.Gotham
		noToolInfo.Parent = toolFrame
	end
end

-- Create ore inventory section
function GameClient:CreateOreInventorySection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local oreFrame = Instance.new("Frame")
	oreFrame.Name = "OreInventory"
	oreFrame.Size = UDim2.new(1, 0, 0, 200)
	oreFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	oreFrame.BorderSizePixel = 0
	oreFrame.LayoutOrder = layoutOrder
	oreFrame.Parent = parent

	local oreCorner = Instance.new("UICorner")
	oreCorner.CornerRadius = UDim.new(0.02, 0)
	oreCorner.Parent = oreFrame

	-- Title
	local oreTitle = Instance.new("TextLabel")
	oreTitle.Size = UDim2.new(1, 0, 0, 35)
	oreTitle.BackgroundTransparency = 1
	oreTitle.Text = "💎 Ore Inventory"
	oreTitle.TextColor3 = Color3.new(1, 1, 1)
	oreTitle.TextScaled = true
	oreTitle.Font = Enum.Font.GothamBold
	oreTitle.Parent = oreFrame

	-- Ore scroll
	local oreScroll = Instance.new("ScrollingFrame")
	oreScroll.Size = UDim2.new(1, -20, 1, -45)
	oreScroll.Position = UDim2.new(0, 10, 0, 40)
	oreScroll.BackgroundTransparency = 1
	oreScroll.ScrollBarThickness = 6
	oreScroll.Parent = oreFrame

	local oreLayout = Instance.new("UIListLayout")
	oreLayout.SortOrder = Enum.SortOrder.LayoutOrder
	oreLayout.Padding = UDim.new(0, 5)
	oreLayout.Parent = oreScroll

	-- Display ores
	local oreCount = 0
	if playerData and playerData.mining and playerData.mining.inventory then
		for oreType, amount in pairs(playerData.mining.inventory) do
			if amount > 0 then
				self:CreateOreInventoryItem(oreScroll, oreType, amount)
				oreCount = oreCount + 1
			end
		end
	end

	if oreCount == 0 then
		local noOresLabel = Instance.new("TextLabel")
		noOresLabel.Size = UDim2.new(1, 0, 1, 0)
		noOresLabel.BackgroundTransparency = 1
		noOresLabel.Text = "No ores mined yet.\nAccess the caves and start mining!"
		noOresLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noOresLabel.TextScaled = true
		noOresLabel.Font = Enum.Font.Gotham
		noOresLabel.Parent = oreScroll
	end

	-- Update canvas size
	oreLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		oreScroll.CanvasSize = UDim2.new(0, 0, 0, oreLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- Create ore inventory item
function GameClient:CreateOreInventoryItem(parent, oreType, amount)
	local oreItem = Instance.new("Frame")
	oreItem.Name = oreType .. "_Item"
	oreItem.Size = UDim2.new(1, 0, 0, 50)
	oreItem.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	oreItem.BorderSizePixel = 0
	oreItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = oreItem

	-- Ore icon
	local oreIcon = Instance.new("TextLabel")
	oreIcon.Size = UDim2.new(0, 35, 0, 35)
	oreIcon.Position = UDim2.new(0, 8, 0, 7)
	oreIcon.BackgroundTransparency = 1
	oreIcon.Text = self:GetOreIcon(oreType)
	oreIcon.TextScaled = true
	oreIcon.Font = Enum.Font.SourceSansSemibold
	oreIcon.Parent = oreItem

	-- Ore info
	local oreInfo = Instance.new("TextLabel")
	oreInfo.Size = UDim2.new(0.5, 0, 1, 0)
	oreInfo.Position = UDim2.new(0, 50, 0, 0)
	oreInfo.BackgroundTransparency = 1
	oreInfo.Text = self:GetOreDisplayName(oreType) .. "\nAmount: " .. amount
	oreInfo.TextColor3 = Color3.new(1, 1, 1)
	oreInfo.TextScaled = true
	oreInfo.Font = Enum.Font.Gotham
	oreInfo.TextXAlignment = Enum.TextXAlignment.Left
	oreInfo.Parent = oreItem

	-- Sell button
	local sellButton = Instance.new("TextButton")
	sellButton.Size = UDim2.new(0, 80, 0, 35)
	sellButton.Position = UDim2.new(1, -90, 0, 7)
	sellButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
	sellButton.BorderSizePixel = 0
	sellButton.Text = "💰 Sell"
	sellButton.TextColor3 = Color3.new(1, 1, 1)
	sellButton.TextScaled = true
	sellButton.Font = Enum.Font.Gotham
	sellButton.Parent = oreItem

	local sellCorner = Instance.new("UICorner")
	sellCorner.CornerRadius = UDim.new(0.2, 0)
	sellCorner.Parent = sellButton

	sellButton.MouseButton1Click:Connect(function()
		self:SellOre(oreType, 1)
	end)
end

-- ========== CRAFTING INTERFACE ==========

-- Refresh crafting menu
function GameClient:RefreshCraftingMenu()
	local menu = self.UI.Menus.Crafting
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = contentArea

	local playerData = self:GetPlayerData()

	-- Crafting stations section
	self:CreateCraftingStationsSection(contentArea, layout, 1)

	-- Recipe browser section
	self:CreateRecipeBrowserSection(contentArea, layout, 2)

	-- Active recipes section
	self:CreateActiveRecipesSection(contentArea, layout, 3)

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and contentArea then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end

-- Create crafting stations section
function GameClient:CreateCraftingStationsSection(parent, layout, layoutOrder)
	local playerData = self:GetPlayerData()

	local stationsFrame = Instance.new("Frame")
	stationsFrame.Name = "CraftingStations"
	stationsFrame.Size = UDim2.new(1, 0, 0, 150)
	stationsFrame.BackgroundColor3 = Color3.fromRGB(120, 80, 60)
	stationsFrame.BorderSizePixel = 0
	stationsFrame.LayoutOrder = layoutOrder
	stationsFrame.Parent = parent

	local stationsCorner = Instance.new("UICorner")
	stationsCorner.CornerRadius = UDim.new(0.02, 0)
	stationsCorner.Parent = stationsFrame

	-- Title
	local stationsTitle = Instance.new("TextLabel")
	stationsTitle.Size = UDim2.new(1, 0, 0, 35)
	stationsTitle.BackgroundTransparency = 1
	stationsTitle.Text = "🔨 Your Crafting Stations"
	stationsTitle.TextColor3 = Color3.new(1, 1, 1)
	stationsTitle.TextScaled = true
	stationsTitle.Font = Enum.Font.GothamBold
	stationsTitle.Parent = stationsFrame

	-- Station list
	local stationList = Instance.new("Frame")
	stationList.Size = UDim2.new(1, -20, 1, -45)
	stationList.Position = UDim2.new(0, 10, 0, 40)
	stationList.BackgroundTransparency = 1
	stationList.Parent = stationsFrame

	local stationLayout = Instance.new("UIListLayout")
	stationLayout.SortOrder = Enum.SortOrder.LayoutOrder
	stationLayout.Padding = UDim.new(0, 5)
	stationLayout.Parent = stationList

	local hasStations = false
	if playerData and playerData.crafting and playerData.crafting.stations then
		local stationCount = 0
		for stationId, owned in pairs(playerData.crafting.stations) do
			if owned then
				stationCount = stationCount + 1
				hasStations = true
				self:CreateStationItem(stationList, stationId, stationCount)
			end
		end
	end

	if not hasStations then
		local noStationsLabel = Instance.new("TextLabel")
		noStationsLabel.Size = UDim2.new(1, 0, 1, 0)
		noStationsLabel.BackgroundTransparency = 1
		noStationsLabel.Text = "🛒 No Crafting Stations Yet\nPurchase stations from the shop!"
		noStationsLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
		noStationsLabel.TextScaled = true
		noStationsLabel.Font = Enum.Font.Gotham
		noStationsLabel.Parent = stationList
	end
end

-- Create station item
function GameClient:CreateStationItem(parent, stationId, layoutOrder)
	local stationItem = Instance.new("Frame")
	stationItem.Name = stationId .. "_Station"
	stationItem.Size = UDim2.new(1, 0, 0, 30)
	stationItem.BackgroundColor3 = Color3.fromRGB(140, 100, 80)
	stationItem.BorderSizePixel = 0
	stationItem.LayoutOrder = layoutOrder
	stationItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = stationItem

	-- Station icon and name
	local stationInfo = Instance.new("TextLabel")
	stationInfo.Size = UDim2.new(0.7, 0, 1, 0)
	stationInfo.BackgroundTransparency = 1
	stationInfo.Text = self:GetStationIcon(stationId) .. " " .. self:GetStationDisplayName(stationId)
	stationInfo.TextColor3 = Color3.new(1, 1, 1)
	stationInfo.TextScaled = true
	stationInfo.Font = Enum.Font.Gotham
	stationInfo.TextXAlignment = Enum.TextXAlignment.Left
	stationInfo.Parent = stationItem

	-- Use button
	local useButton = Instance.new("TextButton")
	useButton.Size = UDim2.new(0, 80, 0, 25)
	useButton.Position = UDim2.new(1, -85, 0, 2)
	useButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
	useButton.BorderSizePixel = 0
	useButton.Text = "🔧 Use"
	useButton.TextColor3 = Color3.new(1, 1, 1)
	useButton.TextScaled = true
	useButton.Font = Enum.Font.Gotham
	useButton.Parent = stationItem

	local useCorner = Instance.new("UICorner")
	useCorner.CornerRadius = UDim.new(0.2, 0)
	useCorner.Parent = useButton

	useButton.MouseButton1Click:Connect(function()
		self:OpenCraftingStation(stationId)
	end)
end

-- ========== ENHANCED SHOP SYSTEM ==========

-- Enhanced shop with new categories
function GameClient:RefreshEnhancedShopMenu()
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

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = contentArea

	-- Enhanced categories with new items
	local categories = {
		{name = "🌱 Seeds", key = "seeds", color = Color3.fromRGB(60, 120, 60)},
		{name = "🚜 Farm Upgrades", key = "farm", color = Color3.fromRGB(120, 90, 60)},
		{name = "⛏️ Mining Equipment", key = "mining", color = Color3.fromRGB(80, 60, 120)},
		{name = "🔨 Crafting Stations", key = "crafting", color = Color3.fromRGB(120, 80, 60)},
		{name = "🐔 Chicken Defense", key = "defense", color = Color3.fromRGB(100, 80, 120)},
		{name = "🧪 Pest Control", key = "tools", color = Color3.fromRGB(120, 80, 80)},
		{name = "✨ Enhancements", key = "farming", color = Color3.fromRGB(100, 100, 150)},
		{name = "🏆 Premium Items", key = "premium", color = Color3.fromRGB(120, 60, 120)}
	}

	local layoutOrder = 1

	-- Get shop items (now includes new items)
	local shopItems = self:GetEnhancedShopItems()
	local parent = contentArea
	for _, category in ipairs(categories) do
		local categoryItems = {}
		for _, item in ipairs(shopItems) do
			if item.category == category.key then
				table.insert(categoryItems, item)
			end
		end

		if #categoryItems > 0 then
			self:CreateEnhancedShopCategory(parent, category, categoryItems, layoutOrder)
			layoutOrder = layoutOrder + 1
		end
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and contentArea then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end

-- Get enhanced shop items (combine existing + new)
function GameClient:GetEnhancedShopItems()
	-- This would call your server to get the complete item list
	-- For now, return the basic structure
	if self.RemoteFunctions.GetShopItems then
		local success, items = pcall(function()
			return self.RemoteFunctions.GetShopItems:InvokeServer()
		end)

		if success and items then
			return items
		end
	end

	-- Fallback to basic items
	return self:GetDefaultShopItems()
end

-- ========== RARITY DISPLAY SYSTEM ==========

-- Show rarity preview when hovering over crops
function GameClient:CreateRarityPreviewSystem()
	-- Monitor mouse hover over crop models
	local mouse = LocalPlayer:GetMouse()

	mouse.Move:Connect(function()
		local target = mouse.Target
		if target and target.Parent and target.Parent.Name == "CropModel" then
			local plotModel = target.Parent.Parent
			local rarity = plotModel:GetAttribute("CropRarity")
			if rarity and rarity ~= "common" then
				self:ShowRarityTooltip(target, rarity)
			end
		else
			self:HideRarityTooltip()
		end
	end)
end

-- Show rarity tooltip
function GameClient:ShowRarityTooltip(target, rarity)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing tooltip
	local existing = playerGui:FindFirstChild("RarityTooltip")
	if existing then existing:Destroy() end

	local tooltip = Instance.new("ScreenGui")
	tooltip.Name = "RarityTooltip"
	tooltip.Parent = playerGui

	local tooltipFrame = Instance.new("Frame")
	tooltipFrame.Size = UDim2.new(0, 200, 0, 80)
	tooltipFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	tooltipFrame.BorderSizePixel = 0
	tooltipFrame.Parent = tooltip

	-- Position near mouse
	local mouse = LocalPlayer:GetMouse()
	tooltipFrame.Position = UDim2.new(0, mouse.X + 10, 0, mouse.Y - 40)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = tooltipFrame

	local rarityText = Instance.new("TextLabel")
	rarityText.Size = UDim2.new(1, 0, 1, 0)
	rarityText.BackgroundTransparency = 1
	rarityText.Text = "✨ " .. rarity:upper() .. " CROP ✨\n" .. self:GetRarityDescription(rarity)
	rarityText.TextColor3 = self:GetRarityColor(rarity)
	rarityText.TextScaled = true
	rarityText.Font = Enum.Font.GothamBold
	rarityText.TextStrokeTransparency = 0
	rarityText.TextStrokeColor3 = Color3.new(0, 0, 0)
	rarityText.Parent = tooltipFrame
end

-- Hide rarity tooltip
function GameClient:HideRarityTooltip()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local tooltip = playerGui:FindFirstChild("RarityTooltip")
	if tooltip then tooltip:Destroy() end
end

-- ========== UTILITY FUNCTIONS ==========

-- Get ore icon
function GameClient:GetOreIcon(oreType)
	local icons = {
		copper_ore = "🟤",
		iron_ore = "⚫",
		silver_ore = "⚪",
		gold_ore = "🟡",
		diamond_ore = "💎",
		obsidian_ore = "⬛"
	}
	return icons[oreType] or "⛏️"
end

-- Get ore display name
function GameClient:GetOreDisplayName(oreType)
	local names = {
		copper_ore = "Copper Ore",
		iron_ore = "Iron Ore", 
		silver_ore = "Silver Ore",
		gold_ore = "Gold Ore",
		diamond_ore = "Diamond Ore",
		obsidian_ore = "Obsidian Ore"
	}
	return names[oreType] or oreType:gsub("_", " ")
end

-- Get station icon
function GameClient:GetStationIcon(stationId)
	local icons = {
		workbench = "🔨",
		forge = "🔥",
		mystical_altar = "🔮"
	}
	return icons[stationId] or "🔧"
end

-- Get station display name
function GameClient:GetStationDisplayName(stationId)
	local names = {
		workbench = "Workbench",
		forge = "Forge",
		mystical_altar = "Mystical Altar"
	}
	return names[stationId] or stationId:gsub("_", " ")
end

-- Get rarity color
function GameClient:GetRarityColor(rarity)
	local colors = {
		common = Color3.new(1, 1, 1),
		uncommon = Color3.fromRGB(192, 192, 192),
		rare = Color3.fromRGB(255, 215, 0),
		epic = Color3.fromRGB(128, 0, 128), 
		legendary = Color3.fromRGB(255, 100, 100)
	}
	return colors[rarity] or Color3.new(1, 1, 1)
end

-- Get rarity description
function GameClient:GetRarityDescription(rarity)
	local descriptions = {
		common = "Standard quality",
		uncommon = "+20% value, silver shine",
		rare = "+50% value, golden glow",
		epic = "+100% value, large size",
		legendary = "+200% value, magical effects"
	}
	return descriptions[rarity] or "Special crop"
end

-- Request cave teleport
function GameClient:RequestCaveTeleport()
	if self.RemoteEvents.TeleportToCave then
		self.RemoteEvents.TeleportToCave:FireServer()
		self:ShowNotification("🚀 Teleporting", "Heading to the mining caves!", "info")
	end
end

-- Sell ore
function GameClient:SellOre(oreType, amount)
	if self.RemoteEvents.SellOre then
		self.RemoteEvents.SellOre:FireServer(oreType, amount)
		self:ShowNotification("💰 Selling Ore", "Selling " .. amount .. "x " .. self:GetOreDisplayName(oreType), "info")
	end
end

-- Open crafting station interface
function GameClient:OpenCraftingStation(stationId)
	self.UIState.ActiveCraftingStation = stationId
	self:ShowNotification("🔨 Crafting Station", "Opening " .. self:GetStationDisplayName(stationId) .. " interface!", "info")

	-- This would open a detailed crafting interface
	-- Implementation depends on your specific crafting UI needs
end

-- Enhanced setup to include new systems
function GameClient:SetupEnhancedSystems()
	-- Call existing setup
	self:SetupFarmingSystem()

	-- Add new systems
	self:CreateMiningInterface()
	self:CreateRarityPreviewSystem()

	print("GameClient: Enhanced systems initialized")
end

-- Override the OpenMenu function to handle new menu types
function GameClient:OpenEnhancedMenu(menuName)
	if menuName == "Mining" then
		local menu = self:GetOrCreateMenu("Mining")
		if menu then
			self:RefreshMiningMenu()
			-- Continue with existing opening logic
		end
	elseif menuName == "Crafting" then
		local menu = self:GetOrCreateMenu("Crafting") 
		if menu then
			self:RefreshCraftingMenu()
			-- Continue with existing opening logic
		end
	elseif menuName == "Shop" then
		local menu = self:GetOrCreateMenu("Shop")
		if menu then
			self:RefreshEnhancedShopMenu()
			-- Continue with existing opening logic
		end
	else
		-- Call existing OpenMenu for other types
		self:OpenMenu(menuName)
	end
end

-- Get enhanced menu title
function GameClient:GetEnhancedMenuTitle(menuName)
	local titles = {
		Mining = "⛏️ Mining Operations - Caves & Ores",
		Crafting = "🔨 Crafting Workshop - Tools & Recipes",
		Shop = "🛒 Enhanced Pet Palace Shop - Everything You Need!"
	}
	return titles[menuName] or self:GetMenuTitle(menuName)
end

print("Enhanced GameClient: ✅ Mining, Crafting & Rarity UI systems loaded!")
print("New Client Features:")
print("  ⛏️ Mining interface with skill progression")
print("  🔨 Crafting stations and recipe browser")
print("  ✨ Rarity tooltip and preview system")
print("  🛒 Enhanced shop with new categories")
print("  🎮 Tool management and ore inventory")
print("  🌟 Visual effects for rare crops")
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
print("GameClient: ✅ Milk system UI updates applied!")
print("Changes:")
print("  🥛 Added livestock products inventory section")
print("  💰 Milk selling buttons and functionality")
print("  📊 Updated stats display with milk collection/selling")
print("  🎨 New icons and display names for milk products")
print("  🔄 Updated inventory categorization")
return GameClient