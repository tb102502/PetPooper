--[[
    UPDATED UIManager.lua - Tabbed Shop System
    Place in: ReplicatedStorage/UIManager.lua
    
    NEW FEATURES:
    ✅ Separate tabs for Seeds, Farming, Defense, Mining, Crafting, Premium
    ✅ Category-based item filtering
    ✅ Smooth tab switching animations
    ✅ Visual category indicators
    ✅ Purchase order respected within each tab
]]

local UIManager = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Local references
local LocalPlayer = Players.LocalPlayer

-- UI State Management
UIManager.State = {
	MainUI = nil,
	CurrentPage = "None",
	ActiveMenus = {},
	IsTransitioning = false,
	Layers = {},
	NotificationQueue = {},
	CurrencyLabels = {},
	GameClient = nil,
	LeftSideButtons = {},
	-- NEW: Shop tab state
	ShopTabs = {},
	ActiveShopTab = "seeds"
}

-- UI Configuration
UIManager.Config = {
	TransitionTime = 0.3,
	NotificationDisplayTime = 5,
	MaxNotificationsVisible = 3,
	UIOrder = {
		Background = 1,
		Main = 2,
		Menus = 3,
		Notifications = 4,
		Error = 5
	},
	-- NEW: Shop tab configuration
	ShopTabConfig = {
		{id = "seeds", name = "🌱 Seeds", color = Color3.fromRGB(100, 200, 100)},
		{id = "farm", name = "🌾 Farming", color = Color3.fromRGB(139, 90, 43)},
		{id = "defense", name = "🛡️ Defense", color = Color3.fromRGB(120, 80, 200)},
		{id = "mining", name = "⛏️ Mining", color = Color3.fromRGB(150, 150, 150)},
		{id = "crafting", name = "🔨 Crafting", color = Color3.fromRGB(200, 120, 80)},
		{id = "premium", name = "✨ Premium", color = Color3.fromRGB(255, 215, 0)}
	}
}

print("UIManager: Enhanced module loaded with tabbed shop system")

-- ========== INITIALIZATION ==========

function UIManager:Initialize()
	print("UIManager: Starting initialization with tabbed shop...")

	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
	if not playerGui then
		error("UIManager: PlayerGui not found after 30 seconds")
	end

	self.State.ActiveMenus = {}
	self.State.Layers = {}
	self.State.NotificationQueue = {}
	self.State.IsTransitioning = false
	self.State.CurrentPage = "None"
	self.State.LeftSideButtons = {}
	self.State.ShopTabs = {}
	self.State.ActiveShopTab = "seeds"

	local success, errorMsg = pcall(function()
		self:CreateMainUIStructure()
	end)

	if not success then
		error("UIManager: Failed to create main UI structure: " .. tostring(errorMsg))
	end
	print("UIManager: ✅ Main UI structure created")

	self:SetupInputHandling()
	print("UIManager: ✅ Input handling setup")

	self:SetupNotificationSystem()
	print("UIManager: ✅ Notification system setup")

	local buttonSuccess, buttonError = pcall(function()
		self:SetupLeftSideButtons()
	end)

	if not buttonSuccess then
		warn("UIManager: Failed to create left-side buttons: " .. tostring(buttonError))
		spawn(function()
			wait(1)
			print("UIManager: Retrying left-side button creation...")
			local retrySuccess, retryError = pcall(function()
				self:SetupLeftSideButtons()
			end)

			if retrySuccess then
				print("UIManager: ✅ Left-side buttons created on retry")
			else
				warn("UIManager: Failed again to create left-side buttons: " .. tostring(retryError))
			end
		end)
	else
		print("UIManager: ✅ Left-side buttons created successfully")
	end

	print("UIManager: 🎉 Initialization complete with tabbed shop system!")
	return true
end

function UIManager:SetGameClient(gameClient)
	self.State.GameClient = gameClient
	print("UIManager: GameClient reference established")
end

-- ========== MAIN UI CREATION ==========

function UIManager:CreateMainUIStructure()
	local playerGui = LocalPlayer.PlayerGui

	local existingUI = playerGui:FindFirstChild("MainGameUI")
	if existingUI then
		existingUI:Destroy()
	end

	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "MainGameUI"
	mainUI.ResetOnSpawn = false
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainUI.Parent = playerGui

	self.State.MainUI = mainUI

	self:CreateCurrencyDisplay(mainUI)
	self:CreateMenuContainers(mainUI)
	self:CreateNotificationArea(mainUI)

	print("UIManager: Main UI structure created")
end

-- ========== LEFT-SIDE MENU BUTTONS ==========

function UIManager:SetupLeftSideButtons()
	print("UIManager: Setting up left-side menu buttons (proximity-only shop)...")

	local playerGui = LocalPlayer.PlayerGui

	local existingButtonUI = playerGui:FindFirstChild("LeftSideButtonsUI")
	if existingButtonUI then
		existingButtonUI:Destroy()
		print("UIManager: Removed existing left-side buttons")
	end

	local buttonUI = Instance.new("ScreenGui")
	buttonUI.Name = "LeftSideButtonsUI"
	buttonUI.ResetOnSpawn = false
	buttonUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	buttonUI.Parent = playerGui

	local buttons = {
		{
			name = "Farm",
			text = "🌾 Farm",
			position = UDim2.new(0, 20, 0, 150),
			color = Color3.fromRGB(80, 120, 60),
			hoverColor = Color3.fromRGB(100, 140, 80),
			description = "Manage your farm and crops"
		},
		{
			name = "Mining", 
			text = "⛏️ Mining",
			position = UDim2.new(0, 20, 0, 220),
			color = Color3.fromRGB(80, 80, 120),
			hoverColor = Color3.fromRGB(100, 100, 140),
			description = "Mine ores and explore caves"
		},
		{
			name = "Crafting",
			text = "🔨 Crafting", 
			position = UDim2.new(0, 20, 0, 290),
			color = Color3.fromRGB(120, 80, 60),
			hoverColor = Color3.fromRGB(140, 100, 80),
			description = "Craft tools and equipment"
		}
	}

	for i, buttonConfig in ipairs(buttons) do
		local success, error = pcall(function()
			local button = self:CreateLeftSideButton(buttonUI, buttonConfig)
			self.State.LeftSideButtons[buttonConfig.name] = button
			print("UIManager: ✅ Created " .. buttonConfig.name .. " button")
		end)

		if not success then
			warn("UIManager: Failed to create " .. buttonConfig.name .. " button: " .. tostring(error))
		end
	end

	self:CreateProximityShopIndicator(buttonUI)

	print("UIManager: ✅ Left-side buttons setup complete (shop removed)")
end

function UIManager:CreateProximityShopIndicator(parent)
	local indicator = Instance.new("Frame")
	indicator.Name = "ShopProximityIndicator"
	indicator.Size = UDim2.new(0, 140, 0, 60)
	indicator.Position = UDim2.new(0, 20, 0, 360)
	indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.ZIndex = self.Config.UIOrder.Main
	indicator.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, -10)
	label.Position = UDim2.new(0, 5, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = "🛒 Shop\nStep on shop area"
	label.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Parent = indicator

	self.State.ShopProximityIndicator = indicator

	print("UIManager: ✅ Created proximity shop indicator")
end

function UIManager:ShowShopProximityIndicator()
	if self.State.ShopProximityIndicator then
		self.State.ShopProximityIndicator.Visible = true

		local tween = TweenService:Create(self.State.ShopProximityIndicator,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(60, 120, 80)}
		)
		tween:Play()
	end
end

function UIManager:HideShopProximityIndicator()
	if self.State.ShopProximityIndicator then
		local tween = TweenService:Create(self.State.ShopProximityIndicator,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(60, 60, 60)}
		)
		tween:Play()

		tween.Completed:Connect(function()
			self.State.ShopProximityIndicator.Visible = false
		end)
	end
end

function UIManager:CreateLeftSideButton(parent, config)
	local button = Instance.new("TextButton")
	button.Name = config.name .. "Button"
	button.Size = UDim2.new(0, 140, 0, 60)
	button.Position = config.position
	button.BackgroundColor3 = config.color
	button.BorderSizePixel = 0
	button.Text = config.text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.ZIndex = self.Config.UIOrder.Main
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.7
	stroke.Parent = button

	button.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundColor3 = config.hoverColor,
				Size = UDim2.new(0, 150, 0, 65)
			}
		)
		hoverTween:Play()

		self:ShowButtonTooltip(button, config.description)
	end)

	button.MouseLeave:Connect(function()
		local leaveTween = TweenService:Create(button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundColor3 = config.color,
				Size = UDim2.new(0, 140, 0, 60)
			}
		)
		leaveTween:Play()

		self:HideButtonTooltip()
	end)

	button.MouseButton1Click:Connect(function()
		print("UIManager: Left-side button clicked: " .. config.name)
		self:HandleLeftSideButtonClick(config.name)
	end)

	return button
end

function UIManager:ShowButtonTooltip(button, description)
	self:HideButtonTooltip()

	local tooltip = Instance.new("Frame")
	tooltip.Name = "ButtonTooltip"
	tooltip.Size = UDim2.new(0, 200, 0, 50)
	tooltip.Position = UDim2.new(0, button.AbsolutePosition.X + button.AbsoluteSize.X + 10, 0, button.AbsolutePosition.Y)
	tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	tooltip.BorderSizePixel = 0
	tooltip.ZIndex = self.Config.UIOrder.Notifications
	tooltip.Parent = self.State.MainUI

	local tooltipCorner = Instance.new("UICorner")
	tooltipCorner.CornerRadius = UDim.new(0.1, 0)
	tooltipCorner.Parent = tooltip

	local tooltipText = Instance.new("TextLabel")
	tooltipText.Size = UDim2.new(1, -10, 1, -10)
	tooltipText.Position = UDim2.new(0, 5, 0, 5)
	tooltipText.BackgroundTransparency = 1
	tooltipText.Text = description
	tooltipText.TextColor3 = Color3.new(1, 1, 1)
	tooltipText.TextScaled = true
	tooltipText.Font = Enum.Font.Gotham
	tooltipText.TextWrapped = true
	tooltipText.Parent = tooltip

	tooltip.BackgroundTransparency = 1
	tooltipText.TextTransparency = 1

	local fadeIn = TweenService:Create(tooltip, TweenInfo.new(0.2), {BackgroundTransparency = 0.1})
	local textFadeIn = TweenService:Create(tooltipText, TweenInfo.new(0.2), {TextTransparency = 0})

	fadeIn:Play()
	textFadeIn:Play()
end

function UIManager:HideButtonTooltip()
	local tooltip = self.State.MainUI:FindFirstChild("ButtonTooltip")
	if tooltip then
		tooltip:Destroy()
	end
end

function UIManager:HandleLeftSideButtonClick(buttonName)
	print("UIManager: Left-side button clicked: " .. buttonName)

	local button = self.State.LeftSideButtons[buttonName]
	if button then
		local pressDown = TweenService:Create(button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{Size = UDim2.new(0, 135, 0, 58)}
		)
		local pressUp = TweenService:Create(button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{Size = UDim2.new(0, 140, 0, 60)}
		)

		pressDown:Play()
		pressDown.Completed:Connect(function()
			pressUp:Play()
		end)
	end

	print("UIManager: Attempting to open menu: " .. buttonName)
	local success = self:OpenMenu(buttonName)

	if success then
		print("UIManager: ✅ Successfully opened " .. buttonName .. " menu")
	else
		print("UIManager: ❌ Failed to open " .. buttonName .. " menu")
	end
end

-- ========== INPUT HANDLING ==========

function UIManager:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			self:CloseActiveMenus()
		elseif input.KeyCode == Enum.KeyCode.F then
			print("UIManager: F key pressed - opening Farm")
			self:OpenMenu("Farm")
		elseif input.KeyCode == Enum.KeyCode.M then
			print("UIManager: M key pressed - opening Mining")
			self:OpenMenu("Mining")
		elseif input.KeyCode == Enum.KeyCode.C then
			print("UIManager: C key pressed - opening Crafting")
			self:OpenMenu("Crafting")
		end
	end)

	print("UIManager: Input handling setup complete (shop hotkey removed)")
	print("  Hotkeys: F=Farm, M=Mining, C=Crafting, ESC=Close")
	print("  Shop: Only accessible via ShopTouchPart proximity")
end

-- ========== MENU MANAGEMENT ==========

function UIManager:OpenMenu(menuName)
	if self.State.IsTransitioning then
		print("UIManager: Ignoring menu open during transition")
		return false
	end

	print("UIManager: Opening menu: " .. menuName)

	if #self.State.ActiveMenus > 0 then
		print("UIManager: Closing existing menus...")
		self:CloseActiveMenus()
		wait(0.1)
	end

	self.State.IsTransitioning = true
	self.State.CurrentPage = menuName

	local success = false

	if menuName == "Shop" then
		success = self:CreateTabbedShopMenu()
	elseif menuName == "Farm" then
		success = self:CreateFarmMenu()
	elseif menuName == "Mining" then
		success = self:CreateMiningMenu()
	elseif menuName == "Crafting" then
		success = self:CreateCraftingMenu()
	else
		print("UIManager: Unknown menu type: " .. menuName)
		success = self:CreateGenericMenu(menuName)
	end

	if success then
		print("UIManager: Menu content created successfully")

		local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
		if menuContainer then
			menuContainer.Visible = true

			local tween = TweenService:Create(menuContainer,
				TweenInfo.new(self.Config.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0}
			)
			tween:Play()

			tween.Completed:Connect(function()
				self.State.IsTransitioning = false
				print("UIManager: Menu " .. menuName .. " opened successfully")
			end)
		else
			warn("UIManager: MenuContainer not found!")
			self.State.IsTransitioning = false
			return false
		end

		table.insert(self.State.ActiveMenus, menuName)
	else
		print("UIManager: Failed to create menu content for " .. menuName)
		self.State.IsTransitioning = false
		self.State.CurrentPage = "None"
	end

	return success
end

function UIManager:CloseActiveMenus()
	if #self.State.ActiveMenus == 0 then
		return
	end

	print("UIManager: Closing active menus")

	local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
	if menuContainer and menuContainer.Visible then
		local tween = TweenService:Create(menuContainer,
			TweenInfo.new(self.Config.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}
		)
		tween:Play()

		tween.Completed:Connect(function()
			menuContainer.Visible = false

			local menuFrame = menuContainer:FindFirstChild("MenuFrame")
			if menuFrame then
				for _, child in pairs(menuFrame:GetChildren()) do
					if child.Name ~= "CloseButton" and not child:IsA("UICorner") then
						child:Destroy()
					end
				end
			end
		end)
	end

	self.State.ActiveMenus = {}
	self.State.CurrentPage = "None"
end

function UIManager:GetCurrentPage()
	return self.State.CurrentPage
end

-- ========== CURRENCY DISPLAY ==========

function UIManager:CreateCurrencyDisplay(parent)
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyDisplay"
	currencyFrame.Size = UDim2.new(0, 300, 0, 80)
	currencyFrame.Position = UDim2.new(1, -320, 0, 20)
	currencyFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	currencyFrame.BorderSizePixel = 0
	currencyFrame.ZIndex = self.Config.UIOrder.Main
	currencyFrame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = currencyFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 100)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = currencyFrame

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0.5, -5, 1, 0)
	coinsLabel.Position = UDim2.new(0, 5, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "💰 0"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Parent = currencyFrame

	local tokensLabel = Instance.new("TextLabel")
	tokensLabel.Name = "TokensLabel"
	tokensLabel.Size = UDim2.new(0.5, -5, 1, 0)
	tokensLabel.Position = UDim2.new(0.5, 0, 0, 0)
	tokensLabel.BackgroundTransparency = 1
	tokensLabel.Text = "🎫 0"
	tokensLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	tokensLabel.TextScaled = true
	tokensLabel.Font = Enum.Font.GothamBold
	tokensLabel.Parent = currencyFrame

	self.State.CurrencyLabels = {
		coins = coinsLabel,
		farmTokens = tokensLabel
	}

	print("UIManager: Enhanced currency display created")
end

-- ========== MENU CONTAINERS ==========

function UIManager:CreateMenuContainers(parent)
	local menuContainer = Instance.new("Frame")
	menuContainer.Name = "MenuContainer"
	menuContainer.Size = UDim2.new(0.85, 0, 0.85, 0)
	menuContainer.Position = UDim2.new(0.15, 0, 0.1, 0)
	menuContainer.BackgroundTransparency = 1
	menuContainer.ZIndex = self.Config.UIOrder.Menus
	menuContainer.Visible = false
	menuContainer.Parent = parent

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1.2, 0, 1.2, 0)
	background.Position = UDim2.new(-0.2, 0, -0.1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.3
	background.ZIndex = self.Config.UIOrder.Background
	background.Parent = menuContainer

	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
	menuFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
	menuFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	menuFrame.BorderSizePixel = 0
	menuFrame.ZIndex = self.Config.UIOrder.Menus
	menuFrame.Parent = menuContainer

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0.02, 0)
	menuCorner.Parent = menuFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.ZIndex = self.Config.UIOrder.Menus + 1
	closeButton.Parent = menuFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		self:CloseActiveMenus()
	end)

	print("UIManager: Enhanced menu containers created")
end

-- ========== NOTIFICATION AREA ==========

function UIManager:CreateNotificationArea(parent)
	local notificationArea = Instance.new("Frame")
	notificationArea.Name = "NotificationArea"
	notificationArea.Size = UDim2.new(0, 400, 1, 0)
	notificationArea.Position = UDim2.new(1, -420, 0, 0)
	notificationArea.BackgroundTransparency = 1
	notificationArea.ZIndex = self.Config.UIOrder.Notifications
	notificationArea.Parent = parent

	print("UIManager: Notification area created")
end

-- ========== TABBED SHOP MENU ==========

function UIManager:CreateTabbedShopMenu()
	print("UIManager: Creating tabbed shop menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "🛒 PET PALACE SHOP"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	-- Proximity access note
	local accessNote = Instance.new("TextLabel")
	accessNote.Name = "AccessNote"
	accessNote.Size = UDim2.new(1, -40, 0, 20)
	accessNote.Position = UDim2.new(0, 20, 0, 80)
	accessNote.BackgroundTransparency = 1
	accessNote.Text = "👣 Organized by category • Logical purchase progression"
	accessNote.TextColor3 = Color3.fromRGB(200, 200, 200)
	accessNote.TextScaled = true
	accessNote.Font = Enum.Font.Gotham
	accessNote.Parent = menuFrame

	-- Create tab container
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, -40, 0, 50)
	tabContainer.Position = UDim2.new(0, 20, 0, 110)
	tabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabContainer.BorderSizePixel = 0
	tabContainer.Parent = menuFrame

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0.02, 0)
	tabCorner.Parent = tabContainer

	-- Create content container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -40, 1, -180)
	contentContainer.Position = UDim2.new(0, 20, 0, 170)
	contentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = menuFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0.02, 0)
	contentCorner.Parent = contentContainer

	-- Create tabs
	self:CreateShopTabs(tabContainer, contentContainer)

	-- Show default tab
	self:ShowShopTab(self.State.ActiveShopTab)

	return true
end

function UIManager:CreateShopTabs(tabContainer, contentContainer)
	print("UIManager: Creating shop tabs")

	-- Clear existing tabs
	self.State.ShopTabs = {}

	local tabWidth = 1 / #self.Config.ShopTabConfig

	for i, tabConfig in ipairs(self.Config.ShopTabConfig) do
		-- Create tab button
		local tabButton = Instance.new("TextButton")
		tabButton.Name = "Tab_" .. tabConfig.id
		tabButton.Size = UDim2.new(tabWidth, -5, 1, -10)
		tabButton.Position = UDim2.new(tabWidth * (i - 1), 5, 0, 5)
		tabButton.BackgroundColor3 = tabConfig.color
		tabButton.BorderSizePixel = 0
		tabButton.Text = tabConfig.name
		tabButton.TextColor3 = Color3.new(1, 1, 1)
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.GothamBold
		tabButton.Parent = tabContainer

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0.1, 0)
		tabCorner.Parent = tabButton

		-- Create content frame for this tab
		local contentFrame = Instance.new("ScrollingFrame")
		contentFrame.Name = "Content_" .. tabConfig.id
		contentFrame.Size = UDim2.new(1, -20, 1, -20)
		contentFrame.Position = UDim2.new(0, 10, 0, 10)
		contentFrame.BackgroundTransparency = 1
		contentFrame.BorderSizePixel = 0
		contentFrame.ScrollBarThickness = 8
		contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
		contentFrame.Visible = false
		contentFrame.Parent = contentContainer

		-- Store tab reference
		self.State.ShopTabs[tabConfig.id] = {
			button = tabButton,
			content = contentFrame,
			config = tabConfig,
			populated = false
		}

		-- Tab click handler
		tabButton.MouseButton1Click:Connect(function()
			self:ShowShopTab(tabConfig.id)
		end)

		-- Tab hover effects
		tabButton.MouseEnter:Connect(function()
			if self.State.ActiveShopTab ~= tabConfig.id then
				local hoverTween = TweenService:Create(tabButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = self:LightenColor(tabConfig.color, 0.2)}
				)
				hoverTween:Play()
			end
		end)

		tabButton.MouseLeave:Connect(function()
			if self.State.ActiveShopTab ~= tabConfig.id then
				local leaveTween = TweenService:Create(tabButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = tabConfig.color}
				)
				leaveTween:Play()
			end
		end)

		print("UIManager: Created tab: " .. tabConfig.name)
	end
end

function UIManager:ShowShopTab(tabId)
	print("UIManager: Switching to shop tab: " .. tabId)

	if not self.State.ShopTabs[tabId] then
		warn("UIManager: Tab not found: " .. tabId)
		return
	end

	-- Update active tab
	local previousTab = self.State.ActiveShopTab
	self.State.ActiveShopTab = tabId

	-- Update tab appearances
	for id, tab in pairs(self.State.ShopTabs) do
		local isActive = (id == tabId)

		-- Hide/show content
		tab.content.Visible = isActive

		-- Update button appearance
		local targetColor = isActive and self:LightenColor(tab.config.color, 0.3) or tab.config.color
		local buttonTween = TweenService:Create(tab.button,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad),
			{BackgroundColor3 = targetColor}
		)
		buttonTween:Play()

		-- Add selection indicator for active tab
		if isActive then
			local indicator = tab.button:FindFirstChild("ActiveIndicator")
			if not indicator then
				indicator = Instance.new("Frame")
				indicator.Name = "ActiveIndicator"
				indicator.Size = UDim2.new(1, 0, 0, 3)
				indicator.Position = UDim2.new(0, 0, 1, -3)
				indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				indicator.BorderSizePixel = 0
				indicator.Parent = tab.button

				local indicatorCorner = Instance.new("UICorner")
				indicatorCorner.CornerRadius = UDim.new(0.5, 0)
				indicatorCorner.Parent = indicator
			end
		else
			local indicator = tab.button:FindFirstChild("ActiveIndicator")
			if indicator then
				indicator:Destroy()
			end
		end
	end

	-- Populate tab content if not already done
	if not self.State.ShopTabs[tabId].populated then
		self:PopulateShopTabContent(tabId)
		self.State.ShopTabs[tabId].populated = true
	end
end

function UIManager:PopulateShopTabContent(tabId)
	print("UIManager: Populating content for tab: " .. tabId)

	local tab = self.State.ShopTabs[tabId]
	if not tab then return end

	local contentFrame = tab.content

	-- Clear existing content
	for _, child in pairs(contentFrame:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	if not self.State.GameClient then
		local loadingLabel = Instance.new("TextLabel")
		loadingLabel.Size = UDim2.new(1, 0, 1, 0)
		loadingLabel.BackgroundTransparency = 1
		loadingLabel.Text = "Loading " .. tab.config.name .. " items..."
		loadingLabel.TextColor3 = Color3.new(1, 1, 1)
		loadingLabel.TextScaled = true
		loadingLabel.Font = Enum.Font.Gotham
		loadingLabel.Parent = contentFrame
		return
	end

	-- Get shop items from GameClient
	local success, shopItems = pcall(function()
		if self.State.GameClient.GetShopItems then
			return self.State.GameClient:GetShopItems()
		end
		return {}
	end)

	if not success or not shopItems or #shopItems == 0 then
		local noItemsLabel = Instance.new("TextLabel")
		noItemsLabel.Size = UDim2.new(1, 0, 1, 0)
		noItemsLabel.BackgroundTransparency = 1
		noItemsLabel.Text = "No " .. tab.config.name .. " items available"
		noItemsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noItemsLabel.TextScaled = true
		noItemsLabel.Font = Enum.Font.Gotham
		noItemsLabel.Parent = contentFrame
		return
	end

	-- Filter items by category
	local categoryItems = {}
	for _, item in ipairs(shopItems) do
		if item.category == tabId then
			table.insert(categoryItems, item)
		end
	end

	-- Sort by purchase order
	table.sort(categoryItems, function(a, b)
		local orderA = a.purchaseOrder or 999
		local orderB = b.purchaseOrder or 999

		if orderA == orderB then
			return a.price < b.price
		end

		return orderA < orderB
	end)

	if #categoryItems == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No items in " .. tab.config.name .. " category"
		emptyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = contentFrame
		return
	end

	-- Create items with enhanced layout
	local yOffset = 0
	local itemSpacing = 10

	for i, item in ipairs(categoryItems) do
		local itemFrame = self:CreateEnhancedShopItemFrame(item, i, tab.config.color)
		itemFrame.Position = UDim2.new(0, 10, 0, yOffset)
		itemFrame.Parent = contentFrame
		yOffset = yOffset + 120 + itemSpacing
	end

	-- Update canvas size with padding
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)

	print("UIManager: Populated " .. #categoryItems .. " items in " .. tabId .. " tab")
end

function UIManager:CreateEnhancedShopItemFrame(item, index, categoryColor)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "ShopItem_" .. index
	itemFrame.Size = UDim2.new(1, -20, 0, 120)
	itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	itemFrame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = itemFrame

	-- Category color indicator
	local indicator = Instance.new("Frame")
	indicator.Name = "CategoryIndicator"
	indicator.Size = UDim2.new(0, 5, 1, 0)
	indicator.Position = UDim2.new(0, 0, 0, 0)
	indicator.BackgroundColor3 = categoryColor
	indicator.BorderSizePixel = 0
	indicator.Parent = itemFrame

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0.05, 0)
	indicatorCorner.Parent = indicator

	-- Purchase order badge (if exists)
	if item.purchaseOrder and item.purchaseOrder <= 20 then
		local orderBadge = Instance.new("Frame")
		orderBadge.Name = "OrderBadge"
		orderBadge.Size = UDim2.new(0, 30, 0, 30)
		orderBadge.Position = UDim2.new(0, 10, 0, 5)
		orderBadge.BackgroundColor3 = categoryColor
		orderBadge.BorderSizePixel = 0
		orderBadge.Parent = itemFrame

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0.5, 0)
		badgeCorner.Parent = orderBadge

		local orderLabel = Instance.new("TextLabel")
		orderLabel.Size = UDim2.new(1, 0, 1, 0)
		orderLabel.BackgroundTransparency = 1
		orderLabel.Text = tostring(item.purchaseOrder)
		orderLabel.TextColor3 = Color3.new(1, 1, 1)
		orderLabel.TextScaled = true
		orderLabel.Font = Enum.Font.GothamBold
		orderLabel.Parent = orderBadge
	end

	-- Item icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "ItemIcon"
	iconLabel.Size = UDim2.new(0, 60, 0, 60)
	iconLabel.Position = UDim2.new(0, 20, 0, 30)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = item.icon or "📦"
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.Gotham
	iconLabel.Parent = itemFrame

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.45, -100, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 90, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name or item.id
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame

	-- Item price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.25, 0, 0.4, 0)
	priceLabel.Position = UDim2.new(0.75, -10, 0, 10)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = (item.price or 0) .. " " .. (item.currency == "farmTokens" and "🎫" or "💰")
	priceLabel.TextColor3 = item.currency == "farmTokens" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Parent = itemFrame

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.45, -100, 0.5, -5)
	descLabel.Position = UDim2.new(0, 90, 0.4, 5)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = item.description and item.description:sub(1, 100) .. (item.description:len() > 100 and "..." or "") or "No description"
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextWrapped = true
	descLabel.Parent = itemFrame

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.2, -10, 0.5, -10)
	buyButton.Position = UDim2.new(0.8, 0, 0.4, 5)
	buyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	buyButton.BorderSizePixel = 0
	buyButton.Text = "BUY"
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = itemFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.1, 0)
	buyCorner.Parent = buyButton

	-- Buy button functionality
	buyButton.MouseButton1Click:Connect(function()
		if self.State.GameClient and self.State.GameClient.PurchaseItem then
			self.State.GameClient:PurchaseItem(item)
		else
			self:ShowNotification("Shop Error", "Purchase system not available!", "error")
		end
	end)

	-- Hover effects
	itemFrame.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(itemFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{BackgroundColor3 = Color3.fromRGB(70, 70, 70)}
		)
		hoverTween:Play()
	end)

	itemFrame.MouseLeave:Connect(function()
		local leaveTween = TweenService:Create(itemFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{BackgroundColor3 = Color3.fromRGB(60, 60, 60)}
		)
		leaveTween:Play()
	end)

	return itemFrame
end

-- ========== OTHER MENU CREATION FUNCTIONS ==========

function UIManager:CreateFarmMenu()
	print("UIManager: Creating farm menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "🌾 FARM MANAGEMENT"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local expansionFrame = Instance.new("Frame")
	expansionFrame.Name = "ExpansionFrame"
	expansionFrame.Size = UDim2.new(1, -40, 0, 200)
	expansionFrame.Position = UDim2.new(0, 20, 0, 90)
	expansionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	expansionFrame.BorderSizePixel = 0
	expansionFrame.Parent = menuFrame

	local expansionCorner = Instance.new("UICorner")
	expansionCorner.CornerRadius = UDim.new(0.02, 0)
	expansionCorner.Parent = expansionFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -20, 0, 60)
	statusLabel.Position = UDim2.new(0, 10, 0, 10)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Loading farm status..."
	statusLabel.TextColor3 = Color3.new(1, 1, 1)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = expansionFrame

	self:PopulateFarmContent(expansionFrame)

	return true
end

function UIManager:CreateMiningMenu()
	print("UIManager: Creating mining menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "⛏️ MINING OPERATIONS"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local comingSoon = Instance.new("TextLabel")
	comingSoon.Size = UDim2.new(0.8, 0, 0.5, 0)
	comingSoon.Position = UDim2.new(0.1, 0, 0.25, 0)
	comingSoon.BackgroundTransparency = 1
	comingSoon.Text = "⛏️ MINING SYSTEM\n\nComing Soon!\n\n• Deep cave exploration\n• Valuable ore collection\n• Advanced pickaxe tools\n• Mining skill progression"
	comingSoon.TextColor3 = Color3.fromRGB(200, 200, 200)
	comingSoon.TextScaled = true
	comingSoon.Font = Enum.Font.Gotham
	comingSoon.Parent = menuFrame

	return true
end

function UIManager:CreateCraftingMenu()
	print("UIManager: Creating crafting menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "🔨 CRAFTING WORKSHOP"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local comingSoon = Instance.new("TextLabel")
	comingSoon.Size = UDim2.new(0.8, 0, 0.5, 0)
	comingSoon.Position = UDim2.new(0.1, 0, 0.25, 0)
	comingSoon.BackgroundTransparency = 1
	comingSoon.Text = "🔨 CRAFTING SYSTEM\n\nComing Soon!\n\n• Advanced tool creation\n• Equipment upgrades\n• Recipe discovery\n• Material processing"
	comingSoon.TextColor3 = Color3.fromRGB(200, 200, 200)
	comingSoon.TextScaled = true
	comingSoon.Font = Enum.Font.Gotham
	comingSoon.Parent = menuFrame

	return true
end

function UIManager:CreateGenericMenu(menuName)
	print("UIManager: Creating generic menu for: " .. menuName)

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = string.upper(menuName)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(0.8, 0, 0.5, 0)
	placeholder.Position = UDim2.new(0.1, 0, 0.25, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = menuName .. " menu is not yet implemented."
	placeholder.TextColor3 = Color3.fromRGB(200, 200, 200)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.Gotham
	placeholder.Parent = menuFrame

	return true
end

-- ========== CONTENT POPULATION ==========

function UIManager:PopulateFarmContent(expansionFrame)
	if not self.State.GameClient then
		return
	end

	local success, playerData = pcall(function()
		if self.State.GameClient.GetPlayerData then
			return self.State.GameClient:GetPlayerData()
		end
		return nil
	end)

	if success and playerData and playerData.farming then
		local expansionLevel = playerData.farming.expansionLevel or 1

		local statusLabel = expansionFrame:FindFirstChild("StatusLabel")
		if statusLabel then
			statusLabel.Text = "🌾 Current Farm Level: " .. expansionLevel .. "\n" .. 
				"Grid Size: " .. self:GetGridSizeForLevel(expansionLevel) .. "\n" .. 
				"Total Spots: " .. self:GetTotalSpotsForLevel(expansionLevel)
		end

		if expansionLevel < 5 then
			local expandButton = Instance.new("TextButton")
			expandButton.Name = "ExpandButton"
			expandButton.Size = UDim2.new(0.5, 0, 0, 50)
			expandButton.Position = UDim2.new(0.5, 0, 1, -70)
			expandButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			expandButton.BorderSizePixel = 0
			expandButton.Text = "🌱 Expand Farm"
			expandButton.TextColor3 = Color3.new(1, 1, 1)
			expandButton.TextScaled = true
			expandButton.Font = Enum.Font.GothamBold
			expandButton.Parent = expansionFrame

			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0.1, 0)
			buttonCorner.Parent = expandButton

			expandButton.MouseButton1Click:Connect(function()
				self:ShowNotification("Farm Expansion", "Farm expansion system coming soon!", "info")
			end)
		end
	end
end

function UIManager:GetGridSizeForLevel(level)
	local sizes = {[1] = "3x3", [2] = "5x5", [3] = "7x7", [4] = "9x9", [5] = "11x11"}
	return sizes[level] or "Unknown"
end

function UIManager:GetTotalSpotsForLevel(level)
	local spots = {[1] = 9, [2] = 25, [3] = 49, [4] = 81, [5] = 121}
	return spots[level] or 0
end

-- ========== NOTIFICATION SYSTEM ==========

function UIManager:SetupNotificationSystem()
	self.State.NotificationQueue = {}

	spawn(function()
		while true do
			if #self.State.NotificationQueue > 0 then
				local notification = table.remove(self.State.NotificationQueue, 1)
				self:DisplayNotification(notification)
			end
			wait(0.1)
		end
	end)

	print("UIManager: Enhanced notification system setup complete")
end

function UIManager:ShowNotification(title, message, notificationType)
	notificationType = notificationType or "info"

	print("UIManager: Queuing notification: " .. title)

	table.insert(self.State.NotificationQueue, {
		title = title,
		message = message,
		type = notificationType,
		timestamp = tick()
	})
end

function UIManager:DisplayNotification(notificationData)
	if not self.State.MainUI then return end

	local notificationArea = self.State.MainUI:FindFirstChild("NotificationArea")
	if not notificationArea then return end

	local existingCount = 0
	for _, child in pairs(notificationArea:GetChildren()) do
		if child.Name:find("Notification_") then
			existingCount = existingCount + 1
		end
	end

	if existingCount >= self.Config.MaxNotificationsVisible then
		for _, child in pairs(notificationArea:GetChildren()) do
			if child.Name:find("Notification_") then
				child:Destroy()
				break
			end
		end
		existingCount = existingCount - 1
	end

	local notification = Instance.new("Frame")
	notification.Name = "Notification_" .. tick()
	notification.Size = UDim2.new(1, -20, 0, 80)
	notification.Position = UDim2.new(0, 10, 0, 20 + (existingCount * 90))
	notification.BackgroundColor3 = self:GetNotificationColor(notificationData.type)
	notification.BorderSizePixel = 0
	notification.ZIndex = self.Config.UIOrder.Notifications
	notification.Parent = notificationArea

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0.1, 0)
	notifCorner.Parent = notification

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0.5, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = notificationData.title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notification

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -20, 0.5, -5)
	messageLabel.Position = UDim2.new(0, 10, 0.5, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = notificationData.message
	messageLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	messageLabel.TextScaled = true
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextWrapped = true
	messageLabel.Parent = notification

	notification.Position = UDim2.new(1, 0, 0, 20 + (existingCount * 90))
	local slideIn = TweenService:Create(notification,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0, 10, 0, 20 + (existingCount * 90))}
	)
	slideIn:Play()

	spawn(function()
		wait(self.Config.NotificationDisplayTime)
		if notification and notification.Parent then
			local slideOut = TweenService:Create(notification,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(1, 0, 0, notification.Position.Y.Offset)}
			)
			slideOut:Play()
			slideOut.Completed:Connect(function()
				notification:Destroy()
			end)
		end
	end)
end

function UIManager:GetNotificationColor(notificationType)
	local colors = {
		success = Color3.fromRGB(46, 125, 50),
		error = Color3.fromRGB(211, 47, 47),
		warning = Color3.fromRGB(245, 124, 0),
		info = Color3.fromRGB(25, 118, 210)
	}
	return colors[notificationType] or colors.info
end

-- ========== CURRENCY DISPLAY ==========

function UIManager:UpdateCurrencyDisplay(playerData)
	if not playerData or not self.State.CurrencyLabels then return end

	if self.State.CurrencyLabels.coins then
		local coins = playerData.coins or 0
		self.State.CurrencyLabels.coins.Text = "💰 " .. self:FormatNumber(coins)
	end

	if self.State.CurrencyLabels.farmTokens then
		local tokens = playerData.farmTokens or 0
		self.State.CurrencyLabels.farmTokens.Text = "🎫 " .. self:FormatNumber(tokens)
	end
end

function UIManager:FormatNumber(number)
	if number < 1000 then
		return tostring(number)
	elseif number < 1000000 then
		return string.format("%.1fK", number / 1000)
	else
		return string.format("%.1fM", number / 1000000)
	end
end

-- ========== MENU REFRESH ==========

function UIManager:RefreshMenuContent(menuName)
	if self.State.CurrentPage ~= menuName then return end

	print("UIManager: Refreshing content for " .. menuName)

	if menuName == "Shop" then
		-- Refresh current shop tab
		local activeTab = self.State.ShopTabs[self.State.ActiveShopTab]
		if activeTab then
			activeTab.populated = false
			self:PopulateShopTabContent(self.State.ActiveShopTab)
		end
	else
		local currentMenus = self.State.ActiveMenus
		self:CloseActiveMenus()

		spawn(function()
			wait(0.1)
			self:OpenMenu(menuName)
		end)
	end
end

-- ========== UTILITY FUNCTIONS ==========

function UIManager:LightenColor(color, amount)
	return Color3.new(
		math.min(1, color.R + amount),
		math.min(1, color.G + amount),
		math.min(1, color.B + amount)
	)
end

function UIManager:GetState()
	return self.State
end

-- ========== CLEANUP ==========

function UIManager:Cleanup()
	print("UIManager: Performing cleanup...")

	self:CloseActiveMenus()

	self.State.NotificationQueue = {}

	if self.State.MainUI then
		self.State.MainUI:Destroy()
		self.State.MainUI = nil
	end

	local leftSideUI = LocalPlayer.PlayerGui:FindFirstChild("LeftSideButtonsUI")
	if leftSideUI then
		leftSideUI:Destroy()
	end

	self.State = {
		MainUI = nil,
		CurrentPage = "None",
		ActiveMenus = {},
		IsTransitioning = false,
		Layers = {},
		NotificationQueue = {},
		CurrencyLabels = {},
		GameClient = nil,
		LeftSideButtons = {},
		ShopTabs = {},
		ActiveShopTab = "seeds"
	}

	print("UIManager: Cleanup complete")
end

_G.UIManager = UIManager

print("UIManager: ✅ Enhanced with TABBED SHOP SYSTEM!")
print("🛒 NEW SHOP FEATURES:")
print("  📁 Separate tabs: Seeds, Farming, Defense, Mining, Crafting, Premium")
print("  🎨 Category-specific colors and indicators")
print("  📋 Purchase order badges for logical progression")
print("  ✨ Smooth tab switching animations")
print("  🔍 Category-based item filtering")
print("  📱 Enhanced item cards with better layout")
print("")
print("🎮 Tab Navigation:")
print("  Click tabs to switch categories")
print("  Items sorted by purchase order within each tab")
print("  Category colors for visual organization")

return UIManager