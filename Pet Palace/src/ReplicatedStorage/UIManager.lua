--[[
    CLEAN UIManager.lua - Modular UI System for Pet Palace
    
    Handles all UI creation, management, and interactions
    NO EXTERNAL MODULE DEPENDENCIES - Only Roblox services
]]

local UIManager = {}

-- Services ONLY - no external module requires
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Player reference
local LocalPlayer = Players.LocalPlayer

-- UI Configuration
UIManager.Config = {
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

-- UI State
UIManager.State = {
	MainUI = nil,
	Layers = {},
	Menus = {},
	ActiveMenus = {},
	CurrentPage = nil,
	IsTransitioning = false,
	Components = {},
	ShopTabs = nil
}

-- References to GameClient (injected during initialization)
UIManager.GameClient = nil

-- ========== INITIALIZATION ==========

function UIManager:Initialize()
	print("UIManager: Initializing clean UI system...")

	-- Setup main UI structure
	self:SetupMainUI()
	self:SetupCurrencyDisplay()
	self:SetupIndividualButtons()
	self:SetupFarmingUI()
	self:SetupMiningUI()

	print("UIManager: ✅ Clean UI system initialized")
	return true
end

-- Add method to set GameClient reference later
function UIManager:SetGameClient(gameClient)
	self.GameClient = gameClient
	print("UIManager: GameClient reference established")
end

function UIManager:SetupMainUI()
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

	self.State.MainUI = mainUI

	-- Create UI layers
	self:CreateUILayers(mainUI)

	print("UIManager: Main UI structure created")
end

function UIManager:CreateUILayers(parent)
	for i, layerName in ipairs(self.Config.layers) do
		local layer = Instance.new("Frame")
		layer.Name = layerName
		layer.Size = UDim2.new(1, 0, 1, 0)
		layer.BackgroundTransparency = 1
		layer.ZIndex = i
		layer.Parent = parent

		self.State.Layers[layerName] = layer
	end
end

-- ========== UI COMPONENT CREATION ==========

function UIManager:CreateUIComponent(componentType, config)
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
	self.State.Components[config.name or component.Name] = component

	return component
end

function UIManager:AddHoverEffect(button, hoverConfig)
	local originalColor = button.BackgroundColor3
	local hoverColor = hoverConfig.color or Color3.new(originalColor.R + 0.1, originalColor.G + 0.1, originalColor.B + 0.1)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, self.Config.animations.hover, {
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, self.Config.animations.hover, {
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

-- ========== CURRENCY DISPLAY ==========

function UIManager:SetupCurrencyDisplay()
	if not self.State.Layers.Navigation then
		warn("UIManager: Navigation layer not found for currency display")
		return
	end

	local container = Instance.new("Frame")
	container.Name = "CurrencyDisplay"
	container.Size = UDim2.new(0.25, 0, 0.12, 0)
	container.Position = UDim2.new(0.95, 0, 0.02, 0)
	container.AnchorPoint = Vector2.new(1, 0)
	container.BackgroundTransparency = 1
	container.Parent = self.State.Layers.Navigation

	local coinsFrame = self:CreateCurrencyFrame("Coins", "💰", Color3.fromRGB(255, 215, 0))
	coinsFrame.Size = UDim2.new(1, 0, 0.45, 0)
	coinsFrame.Position = UDim2.new(0, 0, 0, 0)
	coinsFrame.Parent = container

	local farmTokensFrame = self:CreateCurrencyFrame("Farm Tokens", "🌾", Color3.fromRGB(34, 139, 34))
	farmTokensFrame.Size = UDim2.new(1, 0, 0.45, 0)
	farmTokensFrame.Position = UDim2.new(0, 0, 0.55, 0)
	farmTokensFrame.Parent = container

	self.State.CurrencyContainer = container
	self.State.CoinsFrame = coinsFrame
	self.State.FarmTokensFrame = farmTokensFrame

	print("UIManager: Currency display created")
end

function UIManager:CreateCurrencyFrame(currencyName, icon, color)
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

function UIManager:UpdateCurrencyDisplay(playerData)
	if not playerData then return end

	local coinsValue = self.State.CoinsFrame and self.State.CoinsFrame:FindFirstChild("Value")
	local farmTokensValue = self.State.FarmTokensFrame and self.State.FarmTokensFrame:FindFirstChild("Value")

	if coinsValue then
		local newAmount = playerData.coins or 0
		self:AnimateValueChange(coinsValue, tonumber(coinsValue.Text) or 0, newAmount)
	end

	if farmTokensValue then
		local newAmount = playerData.farmTokens or 0
		self:AnimateValueChange(farmTokensValue, tonumber(farmTokensValue.Text) or 0, newAmount)
	end
end

function UIManager:AnimateValueChange(textLabel, fromValue, toValue)
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

function UIManager:FormatNumber(number)
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

-- ========== INDIVIDUAL BUTTONS ==========

function UIManager:SetupIndividualButtons()
	if not self.State.Layers.Navigation then
		warn("UIManager: Navigation layer not found for individual buttons")
		return
	end

	-- Settings gear button (top right)
	local settingsButton = self:CreateUIComponent("settingsButton", {
		class = "TextButton",
		properties = {
			Name = "SettingsGear",
			Size = UDim2.new(0, 45, 0, 45),
			Position = UDim2.new(1, -45, 0, 4),
			BackgroundColor3 = Color3.fromRGB(60, 60, 70),
			BorderSizePixel = 0,
			Text = "⚙️",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Font = Enum.Font.SourceSansSemibold,
			Parent = self.State.Layers.Navigation
		},
		corner = 0.2,
		hover = {color = Color3.fromRGB(80, 80, 90)}
	})

	settingsButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Settings")
	end)

	self.State.SettingsButton = settingsButton
	print("UIManager: Settings button created")
end

-- ========== FARMING UI ==========

function UIManager:SetupFarmingUI()
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
	local farmButton = self:CreateUIComponent("farmButton", {
		class = "TextButton",
		properties = {
			Name = "FarmingButton",
			Size = UDim2.new(0, 120, 0, 50),
			Position = UDim2.new(0, 20, 0.4, 0),
			BackgroundColor3 = Color3.fromRGB(80, 120, 60),
			BorderSizePixel = 0,
			Text = "🌾 Farming",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			Parent = farmingUI
		},
		corner = 0.1,
		hover = {color = Color3.fromRGB(100, 140, 80)}
	})

	-- Stats button (below farm button)
	local statsButton = self:CreateUIComponent("statsButton", {
		class = "TextButton",
		properties = {
			Name = "StatsButton",
			Size = UDim2.new(0, 120, 0, 50),
			Position = UDim2.new(0, 20, 0.4, 60),
			BackgroundColor3 = Color3.fromRGB(60, 80, 120),
			BorderSizePixel = 0,
			Text = "📊 Stats",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			Parent = farmingUI
		},
		corner = 0.1,
		hover = {color = Color3.fromRGB(80, 100, 140)}
	})

	-- Connect button events
	farmButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Farm")
	end)

	statsButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Stats")
	end)

	self.State.FarmingUI = farmingUI
	self.State.FarmButton = farmButton
	self.State.StatsButton = statsButton

	print("UIManager: Farming UI created")
end

-- ========== MINING UI ==========

function UIManager:SetupMiningUI()
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
	local miningButton = self:CreateUIComponent("miningButton", {
		class = "TextButton",
		properties = {
			Name = "MiningButton",
			Size = UDim2.new(0, 120, 0, 50),
			Position = UDim2.new(0, 20, 0.4, 120),
			BackgroundColor3 = Color3.fromRGB(80, 60, 120),
			BorderSizePixel = 0,
			Text = "⛏️ Mining",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			Parent = miningUI
		},
		corner = 0.1,
		hover = {color = Color3.fromRGB(100, 80, 140)}
	})

	-- Crafting button (below mining)
	local craftingButton = self:CreateUIComponent("craftingButton", {
		class = "TextButton",
		properties = {
			Name = "CraftingButton",
			Size = UDim2.new(0, 120, 0, 50),
			Position = UDim2.new(0, 20, 0.4, 180),
			BackgroundColor3 = Color3.fromRGB(120, 80, 60),
			BorderSizePixel = 0,
			Text = "🔨 Crafting",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			Parent = miningUI
		},
		corner = 0.1,
		hover = {color = Color3.fromRGB(140, 100, 80)}
	})

	-- Connect events
	miningButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Mining")
	end)

	craftingButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Crafting")
	end)

	self.State.MiningUI = miningUI
	print("UIManager: Mining and crafting UI created")
end

-- ========== MENU SYSTEM ==========

function UIManager:OpenMenu(menuName)
	if self.State.IsTransitioning then return end

	self:CloseActiveMenus()

	local menu = self:GetOrCreateMenu(menuName)
	if not menu then return end

	self.State.IsTransitioning = true
	self.State.CurrentPage = menuName
	self.State.ActiveMenus[menuName] = menu

	menu.Visible = true
	menu.Position = UDim2.new(0.5, 0, 1.2, 0)

	local tween = TweenService:Create(menu, self.Config.animations.slideIn, {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})

	tween:Play()
	tween.Completed:Connect(function()
		self.State.IsTransitioning = false
		self:RefreshMenuContent(menuName)
	end)
end

function UIManager:CloseActiveMenus()
	for menuName, menu in pairs(self.State.ActiveMenus) do
		if menu and menu.Visible then
			local tween = TweenService:Create(menu, self.Config.animations.slideOut, {
				Position = UDim2.new(0.5, 0, 1.2, 0)
			})
			tween:Play()
			tween.Completed:Connect(function()
				menu.Visible = false
			end)
		end
	end

	self.State.ActiveMenus = {}
	self.State.CurrentPage = nil
end

function UIManager:GetOrCreateMenu(menuName)
	if self.State.Menus[menuName] then
		return self.State.Menus[menuName]
	end

	local menu = self:CreateBaseMenu(menuName)
	self.State.Menus[menuName] = menu

	return menu
end

function UIManager:CreateBaseMenu(menuName)
	if not self.State.Layers.Content then
		warn("UIManager: Content layer not found for menu creation")
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
	menu.Parent = self.State.Layers.Content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = menu

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0.1, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = menu

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = titleBar

	-- Title label
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

	-- Close button
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

	-- Content area
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

function UIManager:GetMenuTitle(menuName)
	local titles = {
		Shop = "🛒 Pet Palace Shop - Seeds & Upgrades",
		Farm = "🌾 Farming Dashboard",
		Stats = "📊 Player Statistics",
		Settings = "⚙️ Settings",
		Mining = "⛏️ Mining Operations - Caves & Ores",
		Crafting = "🔨 Crafting Workshop - Tools & Recipes"
	}
	return titles[menuName] or menuName
end

function UIManager:RefreshMenuContent(menuName)
	if menuName == "Shop" then
		self:RefreshShopMenu()
	elseif menuName == "Farm" then
		self:RefreshFarmMenu()
	elseif menuName == "Stats" then
		self:RefreshStatsMenu()
	elseif menuName == "Settings" then
		self:RefreshSettingsMenu()
	elseif menuName == "Mining" then
		self:RefreshMiningMenu()
	elseif menuName == "Crafting" then
		self:RefreshCraftingMenu()
	end
end

-- ========== NOTIFICATION SYSTEM ==========

function UIManager:ShowNotification(title, message, type)
	if not title or not message then return end

	print("Notification [" .. (type or "info"):upper() .. "]: " .. title .. " - " .. message)

	-- Check if UI system is properly initialized
	if not self.State.Layers.Notifications then
		warn("UIManager: Notifications layer not available - notification printed to console only")
		return
	end

	-- Ensure Notifications layer exists and is valid
	if not self.State.Layers.Notifications.Parent then
		warn("UIManager: Notifications layer destroyed - falling back to print")
		return
	end

	-- Create notification UI
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Size = UDim2.new(0, 300, 0, 80)
	notificationFrame.Position = UDim2.new(1, -320, 0, 20)
	notificationFrame.BackgroundColor3 = self:GetNotificationColor(type or "info")
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Parent = self.State.Layers.Notifications

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

function UIManager:GetNotificationColor(notificationType)
	return self.Config.colors[notificationType] or self.Config.colors.info
end

-- ========== BASIC MENU REFRESH FUNCTIONS ==========

function UIManager:RefreshShopMenu()
	local menu = self.State.Menus.Shop
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Simple shop content for now
	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Size = UDim2.new(1, 0, 1, 0)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Text = "🛒 Shop System Loading...\n\nThis will show tabbed categories for:\n• Seeds\n• Farm Upgrades\n• Defense\n• Mining\n• Crafting\n• Premium Items"
	loadingLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	loadingLabel.TextScaled = true
	loadingLabel.Font = Enum.Font.Gotham
	loadingLabel.Parent = contentArea
end

function UIManager:RefreshFarmMenu()
	local menu = self.State.Menus.Farm
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Simple farm content
	local farmLabel = Instance.new("TextLabel")
	farmLabel.Size = UDim2.new(1, 0, 1, 0)
	farmLabel.BackgroundTransparency = 1
	farmLabel.Text = "🌾 Farm Dashboard\n\nThis will show:\n• Your farm plots\n• Crop inventory\n• Harvest all button\n• Farm statistics"
	farmLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	farmLabel.TextScaled = true
	farmLabel.Font = Enum.Font.Gotham
	farmLabel.Parent = contentArea
end

function UIManager:RefreshStatsMenu()
	local menu = self.State.Menus.Stats
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Simple stats content
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, 0, 1, 0)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "📊 Player Statistics\n\nThis will show:\n• Currency totals\n• Crops harvested\n• Farm progress\n• Achievements"
	statsLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	statsLabel.TextScaled = true
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.Parent = contentArea
end

function UIManager:RefreshSettingsMenu()
	local menu = self.State.Menus.Settings
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Settings content
	local settingsInfo = Instance.new("TextLabel")
	settingsInfo.Size = UDim2.new(0.9, 0, 1, 0)
	settingsInfo.Position = UDim2.new(0.05, 0, 0, 0)
	settingsInfo.BackgroundTransparency = 1
	settingsInfo.Text = "⚙️ Game Controls:\n\nF - Open farming interface\nESC - Close menus\n\n🎮 About Pet Palace Farming:\n\n🐄 Cow Milk Collection:\n- Click the cow directly when indicator is green\n\n🐷 Pig Feeding:\n- Walk close to the pig to see feeding interface\n\n🛒 Shop:\n- Walk up to the shop building to browse items\n\n🌾 Farming:\n- Plant seeds, harvest crops, sell for farm tokens"
	settingsInfo.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	settingsInfo.TextScaled = true
	settingsInfo.TextWrapped = true
	settingsInfo.Font = Enum.Font.Gotham
	settingsInfo.TextXAlignment = Enum.TextXAlignment.Left
	settingsInfo.Parent = contentArea
end

function UIManager:RefreshMiningMenu()
	local menu = self.State.Menus.Mining
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(1, 0, 1, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "⛏️ Mining System Coming Soon!\n\nThis will include:\n• Cave exploration\n• Ore collection\n• Tool management\n• Skill progression"
	placeholder.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.Gotham
	placeholder.Parent = contentArea
end

function UIManager:RefreshCraftingMenu()
	local menu = self.State.Menus.Crafting
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(1, 0, 1, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "🔨 Crafting System Coming Soon!\n\nThis will include:\n• Recipe browser\n• Crafting stations\n• Material management\n• Advanced tools"
	placeholder.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.Gotham
	placeholder.Parent = contentArea
end

-- ========== PUBLIC API ==========

function UIManager:GetCurrentPage()
	return self.State.CurrentPage
end

function UIManager:IsMenuOpen(menuName)
	return self.State.ActiveMenus[menuName] ~= nil
end

function UIManager:GetState()
	return self.State
end

-- ========== CLEANUP ==========

function UIManager:Cleanup()
	-- Cleanup any active UI elements
	if self.State.MainUI then
		self.State.MainUI:Destroy()
	end

	-- Reset state
	self.State = {
		MainUI = nil,
		Layers = {},
		Menus = {},
		ActiveMenus = {},
		CurrentPage = nil,
		IsTransitioning = false,
		Components = {},
		ShopTabs = nil
	}

	print("UIManager: Cleaned up")
end

print("UIManager: ✅ Clean modular UI system loaded!")
print("Features:")
print("  🎨 No external dependencies - only Roblox services")
print("  📱 Component-based architecture") 
print("  🎬 Animation system")
print("  🔔 Notification system")
print("  📋 Menu management")
print("  🎯 Clean separation of concerns")

return UIManager