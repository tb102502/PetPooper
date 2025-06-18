--[[
    ENHANCED UIManager.lua - Tabbed Shop System with Uniform Fonts
    
    Features:
    - Professional tabbed shop interface
    - Consistent font hierarchy throughout
    - Modern, readable design
    - Category-based item organization
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

-- ========== FONT STANDARDIZATION ==========
-- Consistent font hierarchy for professional look
UIManager.Fonts = {
	-- Primary fonts for readability and modern feel
	Title = Enum.Font.GothamBold,      -- Main titles and headers
	Header = Enum.Font.Gotham, -- Section headers and tab labels
	Body = Enum.Font.Gotham,           -- Body text and descriptions
	Button = Enum.Font.Gotham, -- Buttons and interactive elements
	Number = Enum.Font.GothamBold,     -- Currency and numbers
	Icon = Enum.Font.Gotham    -- Icon labels
}

-- UI Configuration
UIManager.Config = {
	layers = {"Background", "Content", "Navigation", "Overlay", "Notifications"},
	animations = {
		slideIn = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		slideOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		fadeIn = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		hover = TweenInfo.new(0.2, Enum.EasingStyle.Sine),
		tabSwitch = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	},
	colors = {
		primary = Color3.fromRGB(80, 120, 60),
		secondary = Color3.fromRGB(60, 80, 120), 
		accent = Color3.fromRGB(255, 215, 0),
		error = Color3.fromRGB(220, 53, 69),
		success = Color3.fromRGB(40, 167, 69),
		warning = Color3.fromRGB(255, 193, 7),
		info = Color3.fromRGB(23, 162, 184),
		-- Shop specific colors
		shopTab = Color3.fromRGB(45, 55, 65),
		shopTabActive = Color3.fromRGB(70, 130, 80),
		shopItem = Color3.fromRGB(40, 50, 60),
		shopItemHover = Color3.fromRGB(55, 65, 75)
	},
	-- Shop category configuration - ADDED SELL CATEGORY
	shopCategories = {
		{id = "seeds", name = "🌱 Seeds", icon = "🌱", color = Color3.fromRGB(80, 200, 80)}, -- BRIGHTER GREEN
		{id = "farm", name = "🚜 Farm", icon = "🚜", color = Color3.fromRGB(120, 100, 60)},
		{id = "defense", name = "🛡️ Defense", icon = "🛡️", color = Color3.fromRGB(100, 80, 150)},
		{id = "sell", name = "💰 Sell", icon = "💰", color = Color3.fromRGB(255, 165, 0)},
		{id = "mining", name = "⛏️ Mining", icon = "⛏️", color = Color3.fromRGB(100, 100, 100)},
		{id = "crafting", name = "🔨 Crafting", icon = "🔨", color = Color3.fromRGB(150, 100, 50)},
		{id = "premium", name = "✨ Premium", icon = "✨", color = Color3.fromRGB(255, 215, 0)}
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
	ShopTabs = nil,
	CurrentShopTab = "seeds", -- Default shop tab
	ShopItems = {}
}

-- References to GameClient (injected during initialization)
UIManager.GameClient = nil

-- ========== INITIALIZATION ==========

function UIManager:Initialize()
	print("UIManager: Initializing enhanced UI system with tabbed shop...")

	-- Setup main UI structure
	self:SetupMainUI()
	self:SetupCurrencyDisplay()
	self:SetupIndividualButtons()
	self:SetupFarmingUI()
	self:SetupMiningUI()

	print("UIManager: ✅ Enhanced UI system initialized with standardized fonts")
	return true
end

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

	-- Apply standardized font if it's a text element
	if component:IsA("TextLabel") or component:IsA("TextButton") then
		local fontType = config.fontType or "Body"
		component.Font = self.Fonts[fontType] or self.Fonts.Body
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

	print("UIManager: Currency display created with uniform fonts")
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
	iconLabel.Font = self.Fonts.Icon
	iconLabel.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 80, 1, 0)
	label.Position = UDim2.new(0, 30, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = currencyName
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = self.Fonts.Body
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
	value.Font = self.Fonts.Number
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
			Parent = self.State.Layers.Navigation
		},
		fontType = "Icon",
		corner = 0.2,
		hover = {color = Color3.fromRGB(80, 80, 90)}
	})

	settingsButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Settings")
	end)

	self.State.SettingsButton = settingsButton
	print("UIManager: Settings button created with uniform font")
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
			Parent = farmingUI
		},
		fontType = "Button",
		corner = 0.1,
		hover = {color = Color3.fromRGB(100, 140, 80)}
	})

	-- Stats button (below farm button)
	-- Connect button events
	farmButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Farm")
	end)


	self.State.FarmingUI = farmingUI
	self.State.FarmButton = farmButton

	print("UIManager: Farming UI created with uniform fonts")
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

	-- Mining button (moved up to replace stats position)
	local miningButton = self:CreateUIComponent("miningButton", {
		class = "TextButton",
		properties = {
			Name = "MiningButton",
			Size = UDim2.new(0, 120, 0, 50),
			Position = UDim2.new(0, 20, 0.4, 60), -- Was 120, now 60 (stats position)
			BackgroundColor3 = Color3.fromRGB(80, 60, 120),
			BorderSizePixel = 0,
			Text = "⛏️ Mining",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Parent = miningUI
		},
		fontType = "Button",
		corner = 0.1,
		hover = {color = Color3.fromRGB(100, 80, 140)}
	})

	-- Crafting button (moved up as well)
	local craftingButton = self:CreateUIComponent("craftingButton", {
		class = "TextButton",
		properties = {
			Name = "CraftingButton",
			Size = UDim2.new(0, 120, 0, 50),
			Position = UDim2.new(0, 20, 0.4, 120), -- Was 180, now 120
			BackgroundColor3 = Color3.fromRGB(120, 80, 60),
			BorderSizePixel = 0,
			Text = "🔨 Crafting",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Parent = miningUI
		},
		fontType = "Button",
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
	print("UIManager: Mining and crafting UI created with improved spacing")
end

-- RESULT: Your button layout will be:
-- 🌾 Farming    (Position: 0.4, 0)
-- ⛏️ Mining     (Position: 0.4, 60)  -- Moved up from 120
-- 🔨 Crafting   (Position: 0.4, 120) -- Moved up from 180
-- (Empty space where Stats used to be)

-- ========== MENU SYSTEM ==========

function UIManager:OpenMenu(menuName)
	if self.State.IsTransitioning then return end

	self:CloseActiveMenus()

	local menu = self:GetOrCreateMenu(menuName)
	if not menu then return end

	self.State.IsTransitioning = true
	self.State.CurrentPage = menuName
	self.State.ActiveMenus[menuName] = menu

	-- FORCE SEEDS TAB WHEN OPENING SHOP
	if menuName == "Shop" then
		self.State.CurrentShopTab = "seeds"
		print("UIManager: Shop opening - forced to seeds tab")
	end

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
	menu.Size = UDim2.new(0.95, 0, 0.85, 0) -- Slightly larger for better visibility
	menu.Position = UDim2.new(0.5, 0, 0.5, 0)
	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.ZIndex = 100 -- FIXED: High ZIndex to appear above other UI
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

	-- Title label with uniform font
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.1, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = self:GetMenuTitle(menuName)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = self.Fonts.Title
	title.Parent = titleBar

	-- Close button with uniform font
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.08, 0, 0.8, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0.1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = self.Fonts.Button
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
	elseif menuName == "Settings" then
		self:RefreshSettingsMenu()
	elseif menuName == "Mining" then
		self:RefreshMiningMenu()
	elseif menuName == "Crafting" then
		self:RefreshCraftingMenu()
	end
end

-- ========== TABBED SHOP SYSTEM ==========

-- ADD this new function to UIManager.lua:
function UIManager:CreateShopErrorMessage(contentArea)
	local errorFrame = Instance.new("Frame")
	errorFrame.Name = "ShopError"
	errorFrame.Size = UDim2.new(1, 0, 1, 0)
	errorFrame.BackgroundColor3 = Color3.fromRGB(45, 50, 55)
	errorFrame.BorderSizePixel = 0
	errorFrame.Parent = contentArea

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = errorFrame

	local errorLabel = Instance.new("TextLabel")
	errorLabel.Size = UDim2.new(1, -40, 1, -40)
	errorLabel.Position = UDim2.new(0, 20, 0, 20)
	errorLabel.BackgroundTransparency = 1
	errorLabel.Text = "🛒 Shop Loading Error\n\nThe shop items could not be loaded.\n\nThis could be due to:\n• Server connection issues\n• RemoteFunction not setup properly\n• ItemConfig loading problems\n\nTry closing and reopening the shop,\nor contact an administrator."
	errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	errorLabel.TextScaled = true
	errorLabel.Font = self.Fonts.Body
	errorLabel.TextWrapped = true
	errorLabel.Parent = errorFrame

	local retryButton = Instance.new("TextButton")
	retryButton.Size = UDim2.new(0, 200, 0, 50)
	retryButton.Position = UDim2.new(0.5, -100, 0.8, -25)
	retryButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
	retryButton.BorderSizePixel = 0
	retryButton.Text = "🔄 Retry Loading Shop"
	retryButton.TextColor3 = Color3.new(1, 1, 1)
	retryButton.TextScaled = true
	retryButton.Font = self.Fonts.Button
	retryButton.Parent = errorFrame

	local retryCorner = Instance.new("UICorner")
	retryCorner.CornerRadius = UDim.new(0, 6)
	retryCorner.Parent = retryButton

	retryButton.MouseButton1Click:Connect(function()
		print("🛒 UIManager: Retry button clicked - refreshing shop")
		self:RefreshShopMenu()
	end)
end

-- ENHANCE the PopulateShopItems function for better debugging:
function UIManager:PopulateShopItems(categoryId)
	local itemContent = self.State.ShopItemContent
	if not itemContent then 
		warn("🛒 UIManager: No item content area found")
		return 
	end

	-- Clear existing items
	for _, child in ipairs(itemContent:GetChildren()) do
		if child:IsA("Frame") and (child.Name:find("ShopItem") or child.Name:find("SellItem")) then
			child:Destroy()
		end
	end

	print("🛒 UIManager: Populating shop items for category: " .. categoryId)
	print("🛒 UIManager: Total shop items available: " .. #self.State.ShopItems)

	-- Handle sell category separately
	if categoryId == "sell" then
		self:PopulateSellItems(itemContent)
		return
	end

	-- Filter items for this category
	local categoryItems = {}
	for _, item in ipairs(self.State.ShopItems) do
		if item.category == categoryId and item.category ~= "sell" then
			table.insert(categoryItems, item)
			print("🛒 UIManager: Added " .. item.id .. " to " .. categoryId .. " category")
		end
	end

	print("🛒 UIManager: Found " .. #categoryItems .. " items in " .. categoryId .. " category")

	-- Create item cards
	for i, item in ipairs(categoryItems) do
		local itemCard = self:CreateShopItemCard(itemContent, item, i)
	end

	-- ENHANCED: Better canvas size update with error handling
	spawn(function()
		wait(0.2) -- Give more time for items to render
		local gridLayout = itemContent:FindFirstChild("UIGridLayout")
		if gridLayout and gridLayout.AbsoluteContentSize then
			local contentSize = gridLayout.AbsoluteContentSize
			local newCanvasSize = contentSize.Y + 50 -- Extra padding
			itemContent.CanvasSize = UDim2.new(0, 0, 0, newCanvasSize)
			print("🛒 UIManager: Updated canvas size to: " .. newCanvasSize .. " for " .. #categoryItems .. " items")
		else
			warn("🛒 UIManager: Could not update canvas size - gridLayout not found")
		end
	end)

	-- Show helpful message if no items found
	if #categoryItems == 0 then
		print("🛒 UIManager: WARNING - No items found for category: " .. categoryId)

		local noItemsFrame = Instance.new("Frame")
		noItemsFrame.Name = "NoItemsMessage"
		noItemsFrame.Size = UDim2.new(1, 0, 0, 150)
		noItemsFrame.BackgroundColor3 = Color3.fromRGB(45, 50, 55)
		noItemsFrame.BorderSizePixel = 0
		noItemsFrame.LayoutOrder = 999
		noItemsFrame.Parent = itemContent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = noItemsFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 1, -20)
		label.Position = UDim2.new(0, 10, 0, 10)
		label.BackgroundTransparency = 1
		label.Text = "No " .. categoryId .. " items available.\n\nThis could mean:\n• Items not loaded from server\n• Category '" .. categoryId .. "' has no items\n• RemoteFunction connection issue\n\nTry refreshing or contact support!"
		label.TextColor3 = Color3.fromRGB(180, 180, 180)
		label.TextScaled = true
		label.Font = self.Fonts.Body
		label.Parent = noItemsFrame

		-- Update canvas for no items message
		itemContent.CanvasSize = UDim2.new(0, 0, 0, 200)
	end
end

function UIManager:ForceShopRefresh()
	print("🔄 FORCING SHOP REFRESH...")

	-- Clear shop state
	self.State.ShopItems = {}
	self.State.CurrentShopTab = "seeds"

	-- Get fresh shop items with logging
	if self.GameClient then
		print("🛒 Getting fresh shop items...")
		local shopItems = self.GameClient:GetShopItems()

		if shopItems and type(shopItems) == "table" and #shopItems > 0 then
			print("✅ Got " .. #shopItems .. " shop items")
			self.State.ShopItems = shopItems

			-- Force refresh the shop menu
			if self.State.Menus.Shop then
				self:RefreshShopMenu()
				print("✅ Shop menu refreshed")
			end
		else
			warn("❌ Failed to get valid shop items")
		end
	end
end
-- 3. ENHANCED SwitchShopTab with better seeds handling
function UIManager:SwitchShopTab(tabId)
	if not tabId then 
		tabId = "seeds" -- Default fallback
	end

	print("UIManager: Switching to shop tab: " .. tabId)

	self.State.CurrentShopTab = tabId

	-- Update tab button appearances
	for categoryId, button in pairs(self.State.ShopTabButtons or {}) do
		if categoryId == tabId then
			-- Active tab
			TweenService:Create(button, self.Config.animations.tabSwitch, {
				BackgroundColor3 = Color3.fromRGB(70, 130, 80), -- Green active color
				TextColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
		else
			-- Inactive tab
			TweenService:Create(button, self.Config.animations.tabSwitch, {
				BackgroundColor3 = Color3.fromRGB(60, 70, 80), -- Visible inactive color
				TextColor3 = Color3.fromRGB(200, 200, 200)
			}):Play()
		end
	end

	-- Update item content
	self:PopulateShopItems(tabId)

	print("UIManager: Successfully switched to shop tab:", tabId)
end


function UIManager:CreateShopTabHeader(parent)
	local tabHeader = Instance.new("Frame")
	tabHeader.Name = "TabHeader"
	tabHeader.Size = UDim2.new(1, 0, 0, 60)
	tabHeader.Position = UDim2.new(0, 0, 0, 0)
	tabHeader.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
	tabHeader.BorderSizePixel = 0
	tabHeader.Parent = parent

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = tabHeader

	-- Create scrolling frame for tabs with VISIBLE scroll bar
	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Name = "TabScroll"
	tabScroll.Size = UDim2.new(1, -10, 1, -10)
	tabScroll.Position = UDim2.new(0, 5, 0, 5)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	-- FIXED: Make scroll bar visible
	tabScroll.ScrollBarThickness = 8
	tabScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
	tabScroll.Parent = tabHeader

	-- Layout for tabs
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabScroll

	-- Create tab buttons
	self.State.ShopTabButtons = {}
	local totalWidth = 10 -- Start with padding

	for i, category in ipairs(self.Config.shopCategories) do
		local tabButton = self:CreateShopTabButton(tabScroll, category, i)
		self.State.ShopTabButtons[category.id] = tabButton

		-- FIXED: Calculate width properly - use predefined widths since AbsoluteSize isn't available yet
		local buttonWidth = 140 -- Default width
		if category.id == "seeds" then
			buttonWidth = 160 -- Seeds tab is larger
		end
		totalWidth = totalWidth + buttonWidth + 5 -- Add button width + padding
	end

	-- FIXED: Set proper canvas size immediately
	tabScroll.CanvasSize = UDim2.new(0, totalWidth, 0, 0)

	-- ENHANCED: Update canvas size after buttons are rendered
	spawn(function()
		wait(0.1) -- Wait for UI to render
		local actualTotalWidth = 10
		for _, button in pairs(self.State.ShopTabButtons) do
			if button and button.Parent then
				actualTotalWidth = actualTotalWidth + button.AbsoluteSize.X + 5
			end
		end
		-- Add extra space to ensure all tabs are accessible
		tabScroll.CanvasSize = UDim2.new(0, actualTotalWidth + 20, 0, 0)
		print("UIManager: Updated tab scroll canvas size to: " .. actualTotalWidth + 20)
	end)

	return tabHeader
end

function UIManager:CreateShopTabButton(parent, category, layoutOrder)
	local tabButton = Instance.new("TextButton")
	tabButton.Name = "Tab_" .. category.id
	-- FIXED: Use consistent sizing
	local buttonWidth = 140
	if category.id == "seeds" then
		buttonWidth = 160 -- Make seeds tab slightly larger for emphasis
	end

	tabButton.Size = UDim2.new(0, buttonWidth, 1, -10)
	tabButton.BorderSizePixel = 0
	tabButton.Text = category.name
	tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	tabButton.TextScaled = true
	tabButton.Font = self.Fonts.Header
	tabButton.LayoutOrder = layoutOrder
	tabButton.Parent = parent

	-- SPECIAL STYLING FOR SEEDS TAB (start active)
	if category.id == "seeds" then
		tabButton.BackgroundColor3 = Color3.fromRGB(70, 130, 80) -- Start active for seeds
	else
		tabButton.BackgroundColor3 = Color3.fromRGB(60, 70, 80) -- Inactive color
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = tabButton

	-- Tab click handler
	tabButton.MouseButton1Click:Connect(function()
		print("UIManager: Tab clicked: " .. category.id)
		self:SwitchShopTab(category.id)
	end)

	-- Enhanced hover effects with better visual feedback
	tabButton.MouseEnter:Connect(function()
		if self.State.CurrentShopTab ~= category.id then
			TweenService:Create(tabButton, self.Config.animations.hover, {
				BackgroundColor3 = Color3.fromRGB(80, 90, 100)
			}):Play()
		end
	end)

	tabButton.MouseLeave:Connect(function()
		if self.State.CurrentShopTab ~= category.id then
			TweenService:Create(tabButton, self.Config.animations.hover, {
				BackgroundColor3 = Color3.fromRGB(60, 70, 80)
			}):Play()
		end
	end)

	return tabButton
end

function UIManager:VerifyShopSeedsSetup()
	print("=== SHOP SEEDS SETUP VERIFICATION ===")

	local checks = {
		{name = "Seeds in shop categories", check = function()
			for _, cat in ipairs(self.Config.shopCategories) do
				if cat.id == "seeds" then return true end
			end
			return false
		end},

		{name = "Default shop items has seeds", check = function()
			local items = self:GetDefaultShopItems()
			for _, item in ipairs(items) do
				if item.category == "seeds" then return true end
			end
			return false
		end},

		{name = "Current shop tab is seeds", check = function()
			return self.State.CurrentShopTab == "seeds"
		end},

		{name = "Shop items populated", check = function()
			return self.State.ShopItems and #self.State.ShopItems > 0
		end}
	}

	local passed = 0
	local total = #checks

	for _, check in ipairs(checks) do
		local result = check.check()
		local status = result and "✅ PASS" or "❌ FAIL"
		print("  " .. check.name .. ": " .. status)
		if result then passed = passed + 1 end
	end

	print("Verification: " .. passed .. "/" .. total .. " checks passed")

	if passed == total then
		print("🎉 Shop seeds setup is PERFECT!")
	else
		print("⚠️  Shop seeds setup needs attention")
	end

	print("=====================================")
	return passed == total
end
function UIManager:CreateShopItemContent(parent)
	local itemContent = Instance.new("ScrollingFrame")
	itemContent.Name = "ItemContent"
	itemContent.Size = UDim2.new(1, 0, 1, -70)
	itemContent.Position = UDim2.new(0, 0, 0, 70)
	itemContent.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
	itemContent.BorderSizePixel = 0
	itemContent.ScrollBarThickness = 8
	itemContent.Parent = parent

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 8)
	contentCorner.Parent = itemContent

	-- Grid layout for items - FIXED: Larger, more centered items
	local itemLayout = Instance.new("UIGridLayout")
	itemLayout.CellSize = UDim2.new(0, 360, 0, 140) -- Larger items
	itemLayout.CellPadding = UDim2.new(0, 15, 0, 15) -- More spacing
	itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
	itemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Centered
	itemLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	itemLayout.Parent = itemContent

	-- Padding for the content
	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, 15)
	contentPadding.PaddingBottom = UDim.new(0, 15)
	contentPadding.PaddingLeft = UDim.new(0, 15)
	contentPadding.PaddingRight = UDim.new(0, 15)
	contentPadding.Parent = itemContent

	self.State.ShopItemContent = itemContent
	return itemContent
end

function UIManager:PopulateSellItems(itemContent)
	-- Get player data for sellable items
	local playerData = self.GameClient and self.GameClient:GetPlayerData() or {}
	local inventory = playerData.farming and playerData.farming.inventory or {}

	-- FIXED: Create sellable items array with better milk detection
	local sellableItems = {}

	-- FIXED: Add milk selling option - check multiple possible milk sources
	local milkQuantity = 0
	if playerData.milk then
		milkQuantity = playerData.milk
	elseif playerData.inventory and playerData.inventory.milk then
		milkQuantity = playerData.inventory.milk
	elseif inventory.milk then
		milkQuantity = inventory.milk
	elseif playerData.cow and playerData.cow.milk then
		milkQuantity = playerData.cow.milk
	end

	-- Always show milk option, even if quantity is 0
	table.insert(sellableItems, {
		id = "milk",
		name = "Fresh Milk",
		description = "Sell fresh milk from your cow. Premium quality milk sells for top prices!",
		sellPrice = 75,
		currency = "coins",
		icon = "🥛",
		quantity = milkQuantity,
		category = "sell",
		itemType = "milk"
	})

	-- Add crops to sellable items (exclude seeds)
	for itemId, quantity in pairs(inventory) do
		if not itemId:find("_seeds") and quantity > 0 and itemId ~= "milk" then
			table.insert(sellableItems, {
				id = itemId,
				name = self:GetItemDisplayName(itemId),
				description = "Sell your harvested " .. self:GetItemDisplayName(itemId):lower() .. " for coins.",
				sellPrice = self:GetItemSellPrice(itemId),
				currency = "coins", 
				icon = self:GetItemIcon(itemId),
				quantity = quantity,
				category = "sell",
				itemType = "crop"
			})
		end
	end

	-- FIXED: Add ore and other materials (for future expansion)
	local materials = playerData.materials or {}
	for materialId, quantity in pairs(materials) do
		if quantity > 0 then
			table.insert(sellableItems, {
				id = materialId,
				name = self:GetItemDisplayName(materialId),
				description = "Sell your mined " .. self:GetItemDisplayName(materialId):lower() .. " for coins.",
				sellPrice = self:GetItemSellPrice(materialId),
				currency = "coins",
				icon = self:GetItemIcon(materialId),
				quantity = quantity,
				category = "sell",
				itemType = "material"
			})
		end
	end

	-- Create sell item cards
	for i, item in ipairs(sellableItems) do
		local itemCard = self:CreateSellItemCard(itemContent, item, i)
	end

	-- Show helpful message if no sellable items
	if #sellableItems == 1 and sellableItems[1].quantity == 0 then -- Only milk with 0 quantity
		local infoFrame = Instance.new("Frame")
		infoFrame.Name = "SellInfo"
		infoFrame.Size = UDim2.new(1, 0, 0, 120)
		infoFrame.BackgroundColor3 = Color3.fromRGB(45, 50, 55)
		infoFrame.BorderSizePixel = 0
		infoFrame.LayoutOrder = 999
		infoFrame.Parent = itemContent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = infoFrame

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(1, -20, 1, -20)
		infoLabel.Position = UDim2.new(0, 10, 0, 10)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "💰 Welcome to the Sell Center!\n\n🥛 Collect milk from cows\n🌾 Harvest crops from your farm\n⛏️ Mine ores from caves\n\nThen return here to sell them for coins!"
		infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		infoLabel.TextScaled = true
		infoLabel.Font = self.Fonts.Body
		infoLabel.Parent = infoFrame
	end

	-- Update canvas size
	local gridLayout = itemContent:FindFirstChild("UIGridLayout")
	if gridLayout then
		local contentSize = gridLayout.AbsoluteContentSize
		itemContent.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 30)
	end
end

function UIManager:CreateSellItemCard(parent, item, layoutOrder)
	local itemCard = Instance.new("Frame")
	itemCard.Name = "SellItem_" .. item.id
	itemCard.BackgroundColor3 = Color3.fromRGB(55, 45, 35) -- Different color for sell items
	itemCard.BorderSizePixel = 0
	itemCard.LayoutOrder = layoutOrder
	itemCard.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = itemCard

	-- Special highlighting for milk
	if item.id == "milk" then
		local milkStroke = Instance.new("UIStroke")
		milkStroke.Color = Color3.fromRGB(255, 255, 255)
		milkStroke.Thickness = 2
		milkStroke.Transparency = 0.7
		milkStroke.Parent = itemCard
	end

	-- Item icon and name section
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0.4, 0)
	headerFrame.BackgroundTransparency = 1
	headerFrame.Parent = itemCard

	local itemIcon = Instance.new("TextLabel")
	itemIcon.Name = "Icon"
	itemIcon.Size = UDim2.new(0, 40, 0, 40)
	itemIcon.Position = UDim2.new(0, 10, 0.5, -20)
	itemIcon.BackgroundTransparency = 1
	itemIcon.Text = item.icon or "📦"
	itemIcon.TextScaled = true
	itemIcon.Font = self.Fonts.Icon
	itemIcon.Parent = headerFrame

	local itemName = Instance.new("TextLabel")
	itemName.Name = "Name"
	itemName.Size = UDim2.new(1, -60, 1, 0)
	itemName.Position = UDim2.new(0, 55, 0, 0)
	itemName.BackgroundTransparency = 1
	itemName.Text = item.name
	itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
	itemName.TextScaled = true
	itemName.TextXAlignment = Enum.TextXAlignment.Left
	itemName.Font = self.Fonts.Header
	itemName.Parent = headerFrame

	-- Description section
	local descFrame = Instance.new("Frame")
	descFrame.Name = "Description"
	descFrame.Size = UDim2.new(1, -10, 0.35, 0)
	descFrame.Position = UDim2.new(0, 5, 0.4, 0)
	descFrame.BackgroundTransparency = 1
	descFrame.Parent = itemCard

	-- FIXED: Better quantity display
	local quantityText = ""
	if item.quantity <= 0 then
		quantityText = "\n\n❌ You have: 0 (Need to collect more!)"
	else
		quantityText = "\n\n✅ You have: " .. item.quantity .. " ready to sell"
	end

	local description = Instance.new("TextLabel")
	description.Name = "Text"
	description.Size = UDim2.new(1, 0, 1, 0)
	description.BackgroundTransparency = 1
	description.Text = item.description .. quantityText
	description.TextColor3 = Color3.fromRGB(180, 180, 180)
	description.TextScaled = true
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Font = self.Fonts.Body
	description.Parent = descFrame

	-- Sell section
	local sellFrame = Instance.new("Frame")
	sellFrame.Name = "Sell"
	sellFrame.Size = UDim2.new(1, -10, 0.25, 0)
	sellFrame.Position = UDim2.new(0, 5, 0.75, 0)
	sellFrame.BackgroundTransparency = 1
	sellFrame.Parent = itemCard

	-- Price label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Size = UDim2.new(0.6, 0, 1, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 " .. self:FormatNumber(item.sellPrice) .. " each"
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Font = self.Fonts.Number
	priceLabel.Parent = sellFrame

	-- Sell button
	local sellButton = Instance.new("TextButton")
	sellButton.Name = "SellButton"
	sellButton.Size = UDim2.new(0.35, 0, 1, 0)
	sellButton.Position = UDim2.new(0.65, 0, 0, 0)
	sellButton.BorderSizePixel = 0
	sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellButton.TextScaled = true
	sellButton.Font = self.Fonts.Button
	sellButton.Parent = sellFrame

	local sellCorner = Instance.new("UICorner")
	sellCorner.CornerRadius = UDim.new(0, 4)
	sellCorner.Parent = sellButton

	-- FIXED: Proper sell button state
	if item.quantity <= 0 then
		sellButton.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
		sellButton.Text = "None"
		sellButton.AutoButtonColor = false
	else
		sellButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange for sell
		sellButton.Text = "Sell 1"
		sellButton.AutoButtonColor = true

		-- FIXED: Sell button functionality - only works in sell tab
		sellButton.MouseButton1Click:Connect(function()
			if self.State.CurrentShopTab == "sell" then
				self:HandleItemSell(item)
			end
		end)
	end

	-- Hover effects for the card
	itemCard.MouseEnter:Connect(function()
		TweenService:Create(itemCard, self.Config.animations.hover, {
			BackgroundColor3 = Color3.fromRGB(65, 55, 45)
		}):Play()
	end)

	itemCard.MouseLeave:Connect(function()
		TweenService:Create(itemCard, self.Config.animations.hover, {
			BackgroundColor3 = Color3.fromRGB(55, 45, 35)
		}):Play()
	end)

	return itemCard
end

function UIManager:GetItemSellPrice(itemId)
	local sellPrices = {
		-- Crops
		carrot = 15,
		corn = 25,
		strawberry = 40,
		golden_fruit = 100,
		-- Animal products
		milk = 75,
		-- Ores (for future mining system)
		copper_ore = 30,
		iron_ore = 50,
		gold_ore = 100,
		diamond_ore = 200,
		-- Materials
		wood = 10,
		stone = 5,
		-- Default
		default = 10
	}
	return sellPrices[itemId] or sellPrices.default
end

function UIManager:HandleItemSell(item)
	-- FIXED: Only allow selling in sell tab and with valid items
	if self.State.CurrentShopTab ~= "sell" then
		self:ShowNotification("❌ Sell Error", "Selling only available in the Sell tab!", "error")
		return
	end

	if item.quantity <= 0 then
		self:ShowNotification("❌ No Items", "You don't have any " .. item.name .. " to sell!", "warning")
		return
	end

	-- Try to sell via GameClient
	local sellSuccess = false
	if self.GameClient then
		if self.GameClient.SellItem then
			sellSuccess = pcall(function()
				self.GameClient:SellItem(item.id, 1)
			end)
		elseif self.GameClient.RemoteEvents and self.GameClient.RemoteEvents.SellItem then
			sellSuccess = pcall(function()
				self.GameClient.RemoteEvents.SellItem:FireServer(item.id, 1)
			end)
		end
	end

	if sellSuccess then
		-- Show success notification
		self:ShowNotification("💰 Item Sold!", 
			"Sold 1 " .. item.name .. " for " .. self:FormatNumber(item.sellPrice) .. " coins!", "success")

		-- Refresh sell tab after a moment
		spawn(function()
			wait(0.5)
			if self.State.CurrentShopTab == "sell" then
				self:PopulateSellItems(self.State.ShopItemContent)
			end
		end)
	else
		-- Show error notification
		self:ShowNotification("❌ Sell Error", "Could not sell item. Please try again.", "error")
	end
end

function UIManager:CreateShopItemCard(parent, item, layoutOrder)
	local itemCard = Instance.new("Frame")
	itemCard.Name = "ShopItem_" .. item.id
	itemCard.BackgroundColor3 = self.Config.colors.shopItem
	itemCard.BorderSizePixel = 0
	itemCard.LayoutOrder = layoutOrder
	itemCard.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = itemCard

	-- Item icon and name section
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0.4, 0)
	headerFrame.BackgroundTransparency = 1
	headerFrame.Parent = itemCard

	local itemIcon = Instance.new("TextLabel")
	itemIcon.Name = "Icon"
	itemIcon.Size = UDim2.new(0, 40, 0, 40) -- FIXED: Larger icon for bigger cards
	itemIcon.Position = UDim2.new(0, 10, 0.5, -20)
	itemIcon.BackgroundTransparency = 1
	itemIcon.Text = item.icon or "📦"
	itemIcon.TextScaled = true
	itemIcon.Font = self.Fonts.Icon
	itemIcon.Parent = headerFrame

	local itemName = Instance.new("TextLabel")
	itemName.Name = "Name"
	itemName.Size = UDim2.new(1, -60, 1, 0) -- FIXED: Adjust for larger icon
	itemName.Position = UDim2.new(0, 55, 0, 0)
	itemName.BackgroundTransparency = 1
	-- FIXED: Better emoji removal - remove common emoji patterns from start
	local cleanName = (item.name or item.id)
	cleanName = cleanName:gsub("^🌱%s*", "")
	cleanName = cleanName:gsub("^🥕%s*", "")
	cleanName = cleanName:gsub("^🌽%s*", "")
	cleanName = cleanName:gsub("^🍓%s*", "")
	cleanName = cleanName:gsub("^🌾%s*", "")
	cleanName = cleanName:gsub("^🚜%s*", "")
	cleanName = cleanName:gsub("^🐔%s*", "")
	cleanName = cleanName:gsub("^🧪%s*", "")
	cleanName = cleanName:gsub("^⛏️%s*", "")
	cleanName = cleanName:gsub("^🔨%s*", "")
	cleanName = cleanName:gsub("^✨%s*", "")
	cleanName = cleanName:gsub("^🤖%s*", "")
	cleanName = cleanName:gsub("^🛒%s*", "")
	cleanName = cleanName:gsub("^💰%s*", "")
	itemName.Text = cleanName
	itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
	itemName.TextScaled = true
	itemName.TextXAlignment = Enum.TextXAlignment.Left
	itemName.Font = self.Fonts.Header
	itemName.Parent = headerFrame

	-- Description section
	local descFrame = Instance.new("Frame")
	descFrame.Name = "Description"
	descFrame.Size = UDim2.new(1, -10, 0.35, 0)
	descFrame.Position = UDim2.new(0, 5, 0.4, 0)
	descFrame.BackgroundTransparency = 1
	descFrame.Parent = itemCard

	local description = Instance.new("TextLabel")
	description.Name = "Text"
	description.Size = UDim2.new(1, 0, 1, 0)
	description.BackgroundTransparency = 1
	description.Text = item.description or "No description available"
	description.TextColor3 = Color3.fromRGB(180, 180, 180)
	description.TextScaled = true
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Font = self.Fonts.Body
	description.Parent = descFrame

	-- Purchase section
	local purchaseFrame = Instance.new("Frame")
	purchaseFrame.Name = "Purchase"
	purchaseFrame.Size = UDim2.new(1, -10, 0.25, 0)
	purchaseFrame.Position = UDim2.new(0, 5, 0.75, 0)
	purchaseFrame.BackgroundTransparency = 1
	purchaseFrame.Parent = itemCard

	-- Price label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Size = UDim2.new(0.6, 0, 1, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = self:FormatPrice(item.price, item.currency)
	priceLabel.TextColor3 = self:GetCurrencyColor(item.currency)
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Font = self.Fonts.Number
	priceLabel.Parent = purchaseFrame

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0.35, 0, 1, 0)
	buyButton.Position = UDim2.new(0.65, 0, 0, 0)
	buyButton.BackgroundColor3 = self:GetBuyButtonColor(item)
	buyButton.BorderSizePixel = 0
	buyButton.Text = "Buy"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextScaled = true
	buyButton.Font = self.Fonts.Button
	buyButton.Parent = purchaseFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 4)
	buyCorner.Parent = buyButton

	-- Buy button functionality
	buyButton.MouseButton1Click:Connect(function()
		self:HandleItemPurchase(item)
	end)

	-- Hover effects for the card
	itemCard.MouseEnter:Connect(function()
		TweenService:Create(itemCard, self.Config.animations.hover, {
			BackgroundColor3 = self.Config.colors.shopItemHover
		}):Play()
	end)

	itemCard.MouseLeave:Connect(function()
		TweenService:Create(itemCard, self.Config.animations.hover, {
			BackgroundColor3 = self.Config.colors.shopItem
		}):Play()
	end)

	return itemCard
end

function UIManager:FormatPrice(price, currency)
	local currencySymbols = {
		coins = "💰",
		farmTokens = "🌾"
	}
	local symbol = currencySymbols[currency] or "💰"
	return symbol .. " " .. self:FormatNumber(price)
end

function UIManager:GetCurrencyColor(currency)
	if currency == "farmTokens" then
		return Color3.fromRGB(34, 139, 34)
	else
		return Color3.fromRGB(255, 215, 0)
	end
end

function UIManager:GetBuyButtonColor(item)
	if self.GameClient and self.GameClient.CanAffordItem then
		if self.GameClient:CanAffordItem(item) then
			return Color3.fromRGB(40, 167, 69) -- Green
		else
			return Color3.fromRGB(108, 117, 125) -- Gray
		end
	end
	return Color3.fromRGB(40, 167, 69) -- Default green
end

function UIManager:HandleItemPurchase(item)
	if self.GameClient and self.GameClient.PurchaseItem then
		self.GameClient:PurchaseItem(item)
	else
		self:ShowNotification("Purchase Error", "Purchase system not available!", "error")
	end
end

function UIManager:GetDefaultShopItems()
	return {
		-- Seeds Category
		{
			id = "carrot_seeds",
			name = "🥕 Carrot Seeds",
			description = "Fast-growing orange vegetables! Perfect for beginners.\n\n⏱️ Grow Time: 5 minutes\n💰 Sell Value: 15 coins each\n🐷 Pig Value: 1 crop point",
			price = 25,
			currency = "coins",
			category = "seeds",
			icon = "🥕",
			maxPurchase = 50,
			type = "seed",
			growTime = 300, -- 5 minutes
			yieldAmount = 2
		},
		{
			id = "corn_seeds",
			name = "🌽 Corn Seeds", 
			description = "Sweet corn that pigs love! Higher yield than carrots.\n\n⏱️ Grow Time: 8 minutes\n💰 Sell Value: 25 coins each\n🐷 Pig Value: 2 crop points",
			price = 50,
			currency = "coins",
			category = "seeds",
			icon = "🌽",
			maxPurchase = 50,
			type = "seed",
			growTime = 480, -- 8 minutes
			yieldAmount = 3
		},
		{
			id = "strawberry_seeds",
			name = "🍓 Strawberry Seeds", 
			description = "Delicious berries with premium value! Worth the wait.\n\n⏱️ Grow Time: 10 minutes\n💰 Sell Value: 40 coins each\n🐷 Pig Value: 3 crop points",
			price = 100,
			currency = "coins",
			category = "seeds",
			icon = "🍓",
			maxPurchase = 50,
			type = "seed",
			growTime = 600, -- 10 minutes
			yieldAmount = 2
		},
		{
			id = "wheat_seeds",
			name = "🌾 Wheat Seeds",
			description = "Essential grain crop for advanced farming.\n\n⏱️ Grow Time: 12 minutes\n💰 Sell Value: 30 coins each\n🐷 Pig Value: 2 crop points",
			price = 75,
			currency = "coins",
			category = "seeds",
			icon = "🌾",
			maxPurchase = 50,
			type = "seed",
			growTime = 720, -- 12 minutes
			yieldAmount = 4
		},
		{
			id = "tomato_seeds",
			name = "🍅 Tomato Seeds",
			description = "Juicy tomatoes that grow in clusters!\n\n⏱️ Grow Time: 7 minutes\n💰 Sell Value: 20 coins each\n🐷 Pig Value: 2 crop points",
			price = 60,
			currency = "coins",
			category = "seeds",
			icon = "🍅",
			maxPurchase = 50,
			type = "seed",
			growTime = 420, -- 7 minutes
			yieldAmount = 3
		},
		{
			id = "golden_seeds",
			name = "✨ Golden Seeds",
			description = "Magical seeds that produce golden fruit! Premium crop with massive pig value.\n\n⏱️ Grow Time: 15 minutes\n💰 Sell Value: 100 coins each\n🐷 Pig Value: 10 crop points",
			price = 50,
			currency = "farmTokens",
			category = "seeds", -- CHANGED from "premium" to "seeds"
			icon = "✨",
			maxPurchase = 25,
			type = "seed",
			growTime = 900, -- 15 minutes
			yieldAmount = 1
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

		-- ========== DEFENSE CATEGORY ==========
		{
			id = "basic_chicken",
			name = "🐔 Basic Chicken",
			category = "defense",
			price = 150,
			currency = "coins",
			description = "General purpose pest control. Eliminates aphids and lays eggs for steady income.",
			icon = "🐔",
			maxPurchase = 20,
			type = "chicken"
		},
		{
			id = "organic_pesticide",
			name = "🧪 Organic Pesticide",
			category = "defense",
			price = 50,
			currency = "coins", 
			description = "Manually eliminate pests from crops. One-time use, affects 3x3 area around target crop.",
			icon = "🧪",
			maxPurchase = 20,
			type = "tool"
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
			maxPurchase = 1,
			type = "tool"
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
			maxPurchase = 1,
			type = "tool"
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
			maxPurchase = 1,
			type = "upgrade"
		}
	}
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

	-- Title with uniform font
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -10, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 5, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = self.Fonts.Header
	titleLabel.Parent = notificationFrame

	-- Message with uniform font
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -10, 0.5, 0)
	messageLabel.Position = UDim2.new(0, 5, 0.4, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	messageLabel.TextScaled = true
	messageLabel.TextWrapped = true
	messageLabel.Font = self.Fonts.Body
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

-- ========== ENHANCED MENU REFRESH FUNCTIONS WITH REAL DATA ==========

function UIManager:RefreshFarmMenu()
	local menu = self.State.Menus.Farm
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	-- Get player data
	local playerData = self.GameClient and self.GameClient:GetPlayerData() or {}
	local farmingData = playerData.farming or {}
	local inventory = farmingData.inventory or {}

	-- Create main layout
	local mainLayout = Instance.new("UIListLayout")
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Padding = UDim.new(0, 15)
	mainLayout.Parent = contentArea

	--local mainPadding = Instance.new("UIPadding")
	--mainPadding.PaddingAll = UDim.new(0, 20)
	--mainPadding.Parent = contentArea

	-- Farm Overview Section
	local overviewFrame = self:CreateFarmSection(contentArea, "🌾 Farm Overview", 1)
	self:CreateFarmStatsDisplay(overviewFrame, farmingData)

	-- Seed Inventory Section  
	local seedFrame = self:CreateFarmSection(contentArea, "🌱 Seed Inventory", 2)
	self:CreateInventoryDisplay(seedFrame, inventory, "seeds")

	-- Crop Inventory Section
	local cropFrame = self:CreateFarmSection(contentArea, "🥕 Harvested Crops", 3)
	self:CreateInventoryDisplay(cropFrame, inventory, "crops")

	-- Farm Actions Section
	local actionsFrame = self:CreateFarmSection(contentArea, "🚜 Farm Actions", 4)
	self:CreateFarmActions(actionsFrame)

	-- Update canvas size
	contentArea.CanvasSize = UDim2.new(0, 0, 0, 600)
end

function UIManager:CreateFarmSection(parent, title, layoutOrder)
	local sectionFrame = Instance.new("Frame")
	sectionFrame.Name = "Section_" .. layoutOrder
	sectionFrame.Size = UDim2.new(1, 0, 0, 120)
	sectionFrame.BackgroundColor3 = Color3.fromRGB(45, 50, 55)
	sectionFrame.BorderSizePixel = 0
	sectionFrame.LayoutOrder = layoutOrder
	sectionFrame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = sectionFrame

	-- Section title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 30)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = self.Fonts.Header
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = sectionFrame

	-- Content area for section
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -20, 1, -40)
	contentFrame.Position = UDim2.new(0, 10, 0, 35)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = sectionFrame

	return contentFrame
end

function UIManager:CreateFarmStatsDisplay(parent, farmingData)
	local statsText = string.format(
		"Farm Plots: %d\nTotal Seeds: %d\nTotal Crops: %d\nFarming Level: %d",
		farmingData.plots or 0,
		self:CountInventoryType(farmingData.inventory, "seeds"),
		self:CountInventoryType(farmingData.inventory, "crops"),
		farmingData.level or 1
	)

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, 0, 1, 0)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = statsText
	statsLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	statsLabel.TextScaled = true
	statsLabel.Font = self.Fonts.Body
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsLabel.Parent = parent
end

function UIManager:CreateInventoryDisplay(parent, inventory, itemType)
	-- Create scrolling frame for inventory items
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scrollFrame

	local itemCount = 0
	for itemId, quantity in pairs(inventory) do
		local isCorrectType = (itemType == "seeds" and itemId:find("_seeds")) or 
			(itemType == "crops" and not itemId:find("_seeds"))

		if isCorrectType and quantity > 0 then
			self:CreateInventoryItem(scrollFrame, itemId, quantity, itemCount)
			itemCount = itemCount + 1
		end
	end

	if itemCount == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No " .. itemType .. " in inventory"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextScaled = true
		emptyLabel.Font = self.Fonts.Body
		emptyLabel.Parent = scrollFrame
	end

	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, itemCount * 110, 0, 0)
end

function UIManager:CreateInventoryItem(parent, itemId, quantity, layoutOrder)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "Item_" .. itemId
	itemFrame.Size = UDim2.new(0, 100, 1, 0)
	itemFrame.BackgroundColor3 = Color3.fromRGB(55, 60, 65)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = layoutOrder
	itemFrame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = itemFrame

	-- Item icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.4, 0)
	icon.BackgroundTransparency = 1
	icon.Text = self:GetItemIcon(itemId)
	icon.TextScaled = true
	icon.Font = self.Fonts.Icon
	icon.Parent = itemFrame

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -5, 0.35, 0)
	nameLabel.Position = UDim2.new(0, 2, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = self:GetItemDisplayName(itemId)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = self.Fonts.Body
	nameLabel.TextWrapped = true
	nameLabel.Parent = itemFrame

	-- Quantity
	local quantityLabel = Instance.new("TextLabel")
	quantityLabel.Size = UDim2.new(1, 0, 0.25, 0)
	quantityLabel.Position = UDim2.new(0, 0, 0.75, 0)
	quantityLabel.BackgroundTransparency = 1
	quantityLabel.Text = "x" .. quantity
	quantityLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	quantityLabel.TextScaled = true
	quantityLabel.Font = self.Fonts.Number
	quantityLabel.Parent = itemFrame
end

function UIManager:CreateFarmActions(parent)
	-- Harvest All button
	local harvestButton = Instance.new("TextButton")
	harvestButton.Size = UDim2.new(0.3, 0, 0.8, 0)
	harvestButton.Position = UDim2.new(0.05, 0, 0.1, 0)
	harvestButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
	harvestButton.BorderSizePixel = 0
	harvestButton.Text = "🌾 Harvest All"
	harvestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	harvestButton.TextScaled = true
	harvestButton.Font = self.Fonts.Button
	harvestButton.Parent = parent

	local harvestCorner = Instance.new("UICorner")
	harvestCorner.CornerRadius = UDim.new(0, 6)
	harvestCorner.Parent = harvestButton

	harvestButton.MouseButton1Click:Connect(function()
		if self.GameClient and self.GameClient.RequestHarvestAll then
			self.GameClient:RequestHarvestAll()
		end
	end)

	-- Plant Mode button
	local plantButton = Instance.new("TextButton")
	plantButton.Size = UDim2.new(0.3, 0, 0.8, 0)
	plantButton.Position = UDim2.new(0.37, 0, 0.1, 0)
	plantButton.BackgroundColor3 = Color3.fromRGB(80, 120, 60)
	plantButton.BorderSizePixel = 0
	plantButton.Text = "🌱 Plant Mode"
	plantButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	plantButton.TextScaled = true
	plantButton.Font = self.Fonts.Button
	plantButton.Parent = parent

	local plantCorner = Instance.new("UICorner")
	plantCorner.CornerRadius = UDim.new(0, 6)
	plantCorner.Parent = plantButton

	-- Refresh button
	local refreshButton = Instance.new("TextButton")
	refreshButton.Size = UDim2.new(0.25, 0, 0.8, 0)
	refreshButton.Position = UDim2.new(0.7, 0, 0.1, 0)
	refreshButton.BackgroundColor3 = Color3.fromRGB(23, 162, 184)
	refreshButton.BorderSizePixel = 0
	refreshButton.Text = "🔄 Refresh"
	refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	refreshButton.TextScaled = true
	refreshButton.Font = self.Fonts.Button
	refreshButton.Parent = parent

	local refreshCorner = Instance.new("UICorner")
	refreshCorner.CornerRadius = UDim.new(0, 6)
	refreshCorner.Parent = refreshButton

	refreshButton.MouseButton1Click:Connect(function()
		self:RefreshFarmMenu()
	end)
end


function UIManager:RefreshMiningMenu()
	local menu = self.State.Menus.Mining
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	-- Get player data
	local playerData = self.GameClient and self.GameClient:GetPlayerData() or {}
	local miningData = playerData.mining or {}

	-- Create placeholder for now since mining system isn't fully implemented
	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(1, 0, 1, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "⛏️ Mining System Coming Soon!\n\nThis will include:\n• Cave exploration\n• Ore collection\n• Tool management\n• Skill progression\n\nMining Level: " .. (miningData.level or 0) .. "\nOres Collected: " .. (miningData.oresCollected or 0)
	placeholder.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	placeholder.TextScaled = true
	placeholder.Font = self.Fonts.Body
	placeholder.Parent = contentArea
end

function UIManager:RefreshCraftingMenu()
	local menu = self.State.Menus.Crafting
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	-- Get player data
	local playerData = self.GameClient and self.GameClient:GetPlayerData() or {}
	local craftingData = playerData.crafting or {}

	-- Create placeholder for now since crafting system isn't fully implemented
	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(1, 0, 1, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "🔨 Crafting System Coming Soon!\n\nThis will include:\n• Recipe browser\n• Crafting stations\n• Material management\n• Advanced tools\n\nCrafting Level: " .. (craftingData.level or 0) .. "\nItems Crafted: " .. (craftingData.itemsCrafted or 0)
	placeholder.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	placeholder.TextScaled = true
	placeholder.Font = self.Fonts.Body
	placeholder.Parent = contentArea
end

-- Helper functions for inventory display
function UIManager:CountInventoryType(inventory, itemType)
	if not inventory then return 0 end

	local count = 0
	for itemId, quantity in pairs(inventory) do
		local isCorrectType = (itemType == "seeds" and itemId:find("_seeds")) or 
			(itemType == "crops" and not itemId:find("_seeds"))
		if isCorrectType then
			count = count + (quantity or 0)
		end
	end
	return count
end

function UIManager:GetItemIcon(itemId)
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
		-- Animal products
		milk = "🥛",
		egg = "🥚",
		-- Ores (for future mining system)
		copper_ore = "🟫",
		iron_ore = "⚫",
		gold_ore = "🟡",
		diamond_ore = "💎",
		-- Materials
		wood = "🪵",
		stone = "🪨",
		-- Default
		default = "📦"
	}
	return icons[itemId] or icons.default
end

function UIManager:GetItemDisplayName(itemId)
	local names = {
		-- Seeds
		carrot_seeds = "Carrot Seeds",
		corn_seeds = "Corn Seeds",
		strawberry_seeds = "Strawberry Seeds",
		golden_seeds = "Golden Seeds",
		-- Crops
		carrot = "Carrots",
		corn = "Corn",
		strawberry = "Strawberries",
		golden_fruit = "Golden Fruit",
		-- Animal products  
		milk = "Fresh Milk",
		egg = "Chicken Eggs",
		-- Ores
		copper_ore = "Copper Ore",
		iron_ore = "Iron Ore", 
		gold_ore = "Gold Ore",
		diamond_ore = "Diamond Ore",
		-- Materials
		wood = "Wood Planks",
		stone = "Stone Blocks",
		-- Default - clean up underscores
		default = function(id) return id:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end) end
	}

	if names[itemId] then
		return names[itemId]
	else
		return names.default(itemId)
	end
end

-- ========== DEBUG AND ADDITIONAL FIXES FOR UIMANAGER ==========
-- Add these functions to UIManager.lua for better debugging and scroll management

-- ========== ENHANCED SHOP TAB MANAGEMENT ==========
function UIManager:EnsureTabsVisible()
	-- Function to ensure all tabs are properly visible and scrollable
	if not self.State.ShopTabButtons then return end

	local tabHeader = self.State.Layers.Content:FindFirstChild("ShopMenu"):FindFirstChild("ContentArea"):FindFirstChild("TabHeader")
	if not tabHeader then return end

	local tabScroll = tabHeader:FindFirstChild("TabScroll")
	if not tabScroll then return end

	-- Calculate total width needed
	local totalWidth = 20 -- Starting padding
	local maxTabWidth = 0

	for categoryId, button in pairs(self.State.ShopTabButtons) do
		if button and button.Parent then
			local buttonWidth = button.AbsoluteSize.X
			if buttonWidth == 0 then
				-- Fallback to predefined sizes if AbsoluteSize isn't ready
				buttonWidth = categoryId == "seeds" and 160 or 140
			end
			totalWidth = totalWidth + buttonWidth + 5
			maxTabWidth = math.max(maxTabWidth, buttonWidth)
		end
	end

	-- Ensure canvas is large enough
	local minCanvasWidth = totalWidth + 50 -- Extra buffer
	tabScroll.CanvasSize = UDim2.new(0, minCanvasWidth, 0, 0)

	print("UIManager: EnsureTabsVisible - Canvas width set to: " .. minCanvasWidth)
	print("UIManager: Total calculated width: " .. totalWidth)
	print("UIManager: Number of tabs: " .. self:CountTable(self.State.ShopTabButtons))
end

-- ========== SCROLL BAR STYLING FUNCTION ==========
function UIManager:StyleScrollBars()
	-- Apply consistent scroll bar styling across all shop scroll frames
	local function styleScrollFrame(scrollFrame)
		if not scrollFrame or not scrollFrame:IsA("ScrollingFrame") then return end

		scrollFrame.ScrollBarThickness = 12
		scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
		scrollFrame.ScrollBarImageTransparency = 0.2
		scrollFrame.BorderSizePixel = 0

		-- Add scroll bar images for better appearance
		scrollFrame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-bottom.png"
		scrollFrame.TopImage = "rbxasset://textures/ui/Scroll/scroll-top.png"
		scrollFrame.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	end

	-- Style all shop scroll frames
	if self.State.Menus.Shop then
		local shopMenu = self.State.Menus.Shop

		-- Tab scroll frame
		local tabScroll = shopMenu:FindFirstChild("ContentArea"):FindFirstChild("TabHeader"):FindFirstChild("TabScroll")
		if tabScroll then
			styleScrollFrame(tabScroll)
		end

		-- Item content scroll frame
		local itemContent = shopMenu:FindFirstChild("ContentArea"):FindFirstChild("ItemContent")
		if itemContent then
			styleScrollFrame(itemContent)
		end
	end
end

-- ========== REFRESH SHOP WITH SCROLL FIXES ==========
function UIManager:RefreshShopMenu()
	local menu = self.State.Menus.Shop
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	print("🛒 UIManager: Refreshing shop menu with scroll fixes...")

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Get shop items from GameClient with enhanced debugging
	local shopItems = {}
	if self.GameClient and self.GameClient.GetShopItems then
		print("🛒 UIManager: Requesting shop items from GameClient...")
		shopItems = self.GameClient:GetShopItems()
		print("🛒 UIManager: Received " .. (shopItems and #shopItems or 0) .. " shop items from GameClient")
	else
		warn("🛒 UIManager: GameClient or GetShopItems not available")
		shopItems = self:GetDefaultShopItems()
		print("🛒 UIManager: Using fallback items: " .. #shopItems)
	end

	if not shopItems or #shopItems == 0 then
		warn("🛒 UIManager: No shop items available, creating error message")
		self:CreateShopErrorMessage(contentArea)
		return
	end

	self.State.ShopItems = shopItems

	-- ENSURE WE START WITH SEEDS TAB
	self.State.CurrentShopTab = "seeds"

	-- Create tab header with fixes
	local tabHeader = self:CreateShopTabHeader(contentArea)

	-- Create item content area with fixes
	local itemContent = self:CreateShopItemContent(contentArea)

	-- Apply scroll bar styling
	spawn(function()
		wait(0.1)
		self:StyleScrollBars()
	end)

	-- Ensure tabs are visible
	spawn(function()
		wait(0.2)
		self:EnsureTabsVisible()
	end)

	-- FORCE POPULATE SEEDS CATEGORY
	print("🛒 UIManager: Forcing switch to seeds tab with " .. #shopItems .. " total items")
	self:SwitchShopTab("seeds")

	print("🛒 UIManager: Enhanced shop menu created with scroll fixes")
end

-- ========== DEBUG FUNCTIONS ==========
function UIManager:DebugShopScrolling()
	print("=== SHOP SCROLLING DEBUG ===")

	if not self.State.Menus.Shop then
		print("❌ Shop menu not open")
		return
	end

	local shopMenu = self.State.Menus.Shop
	local contentArea = shopMenu:FindFirstChild("ContentArea")

	if contentArea then
		print("✅ Content area found")

		-- Check tab header
		local tabHeader = contentArea:FindFirstChild("TabHeader")
		if tabHeader then
			print("✅ Tab header found")

			local tabScroll = tabHeader:FindFirstChild("TabScroll")
			if tabScroll then
				print("✅ Tab scroll found")
				print("  Size:", tabScroll.Size)
				print("  CanvasSize:", tabScroll.CanvasSize)
				print("  ScrollBarThickness:", tabScroll.ScrollBarThickness)
				print("  Scrolling direction:", tabScroll.ScrollingDirection)

				local buttons = {}
				for id, button in pairs(self.State.ShopTabButtons or {}) do
					if button and button.Parent then
						table.insert(buttons, {
							id = id,
							size = button.AbsoluteSize,
							position = button.AbsolutePosition
						})
					end
				end
				print("  Tab buttons:", #buttons)
				for _, btn in ipairs(buttons) do
					print("    " .. btn.id .. ": Size=" .. tostring(btn.size) .. ", Pos=" .. tostring(btn.position))
				end
			else
				print("❌ Tab scroll not found")
			end
		else
			print("❌ Tab header not found")
		end

		-- Check item content
		local itemContent = contentArea:FindFirstChild("ItemContent")
		if itemContent then
			print("✅ Item content found")
			print("  Size:", itemContent.Size)
			print("  CanvasSize:", itemContent.CanvasSize)
			print("  ScrollBarThickness:", itemContent.ScrollBarThickness)

			local itemCount = 0
			for _, child in ipairs(itemContent:GetChildren()) do
				if child:IsA("Frame") and child.Name:find("Item") then
					itemCount = itemCount + 1
				end
			end
			print("  Item frames:", itemCount)
		else
			print("❌ Item content not found")
		end
	else
		print("❌ Content area not found")
	end

	print("Current shop tab:", self.State.CurrentShopTab)
	print("Shop items count:", self.State.ShopItems and #self.State.ShopItems or 0)
	print("===========================")
end

function UIManager:FixShopScrolling()
	print("🔧 UIManager: Applying shop scrolling fixes...")

	if not self.State.Menus.Shop then
		print("❌ No shop menu to fix")
		return
	end

	-- Apply styling fixes
	self:StyleScrollBars()

	-- Ensure tabs are properly sized
	self:EnsureTabsVisible()

	-- Refresh current tab content with proper sizing
	if self.State.CurrentShopTab then
		spawn(function()
			wait(0.1)
			self:PopulateShopItems(self.State.CurrentShopTab)
		end)
	end

	print("✅ Shop scrolling fixes applied")
end

-- ========== COUNT UTILITY ==========
function UIManager:CountTable(t)
	if not t then return 0 end
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== GLOBAL DEBUG COMMANDS ==========
-- Add these to the end of UIManager.lua
_G.DebugShopScrolling = function()
	if _G.UIManager then
		_G.UIManager:DebugShopScrolling()
	else
		print("UIManager not available")
	end
end

_G.FixShopScrolling = function()
	if _G.UIManager then
		_G.UIManager:FixShopScrolling()
	else
		print("UIManager not available")
	end
end

_G.TestShopTabs = function()
	if _G.UIManager then
		_G.UIManager:EnsureTabsVisible()
		print("Tab visibility test completed")
	else
		print("UIManager not available")
	end
end

print("🔧 UIManager debug tools loaded!")
print("Commands:")
print("  _G.DebugShopScrolling() - Debug scroll state")
print("  _G.FixShopScrolling() - Apply scroll fixes")
print("  _G.TestShopTabs() - Test tab visibility")
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
		ShopTabs = nil,
		CurrentShopTab = "seeds",
		ShopItems = {}
	}

	print("UIManager: Cleaned up")
end
_G.TestSeedsShop = function()
	if _G.UIManager then
		_G.UIManager:TestSeedsShop()
	else
		print("UIManager not available")
	end
end

_G.DebugShopSeeds = function()
	if _G.UIManager then
		return _G.UIManager:DebugShopSeeds()
	else
		print("UIManager not available")
	end
end
function UIManager:DebugShopState()
	print("=== SHOP STATE DEBUG ===")
	print("ShopItems exists:", self.State.ShopItems ~= nil)
	if self.State.ShopItems then
		print("ShopItems type:", type(self.State.ShopItems))
		print("ShopItems count:", type(self.State.ShopItems) == "table" and #self.State.ShopItems or "N/A")

		if type(self.State.ShopItems) == "table" and #self.State.ShopItems > 0 then
			print("First item:", self.State.ShopItems[1].id, self.State.ShopItems[1].category)
		end
	end
	print("Current shop tab:", self.State.CurrentShopTab)
	print("Shop menu exists:", self.State.Menus.Shop ~= nil)
	print("GameClient exists:", self.GameClient ~= nil)
	print("======================")
end
print("🧪 Shop debugging tools loaded!")
print("Commands:")
print("  _G.TestSeedsShop() - Test opening shop to seeds")
print("  _G.DebugShopSeeds() - Debug seed items")
print("UIManager: ✅ Enhanced tabbed shop system with isolated sell functionality loaded!")
print("Features:")
print("  🎨 Professional tabbed shop interface with isolated SELL tab")
print("  📱 Mobile-friendly tab scrolling") 
print("  🎬 Smooth tab switching animations")
print("  🔔 Enhanced notification system")
print("  📋 Category-based item organization")
print("  ✍️ Consistent Gotham font family throughout")
print("  🎯 Modern, readable design")
print("  📦 REAL inventory display in Farm/Stats/Mining/Crafting menus")
print("  💰 ISOLATED milk selling functionality in dedicated sell tab")
print("  🌾 Interactive farming dashboard with harvest buttons")
print("  📊 Detailed player statistics")
print("")
print("Shop Categories:")
print("  🌱 Seeds - Buy farming seeds")
print("  🚜 Farm - Farm plots and upgrades") 
print("  🛡️ Defense - Chickens and pest control")
print("  💰 Sell - ONLY place to sell crops, milk, and ores")
print("  ⛏️ Mining - Tools and cave access")
print("  🔨 Crafting - Workbenches and recipes")
print("  ✨ Premium - Special items with farm tokens")
print("")
print("🔧 FIXED ISSUES:")
print("  ✅ Sell functionality isolated to ONLY the sell tab")
print("  ✅ Milk detection improved with multiple data source checks")
print("  ✅ Better quantity display and sell button states")
print("  ✅ Enhanced error handling for sell operations")
print("  ✅ Support for future ore and material selling")

return UIManager