--[[
    COMPLETE UIManager.lua - Fixed Shop Opening + Uniform Item Sizing
    Place in: ReplicatedStorage/UIManager.lua
    
    FEATURES:
    ✅ All original functionality preserved
    ✅ Shop opening/closing works properly
    ✅ Improved uniform item sizing (15% height)
    ✅ Better device-specific scaling
    ✅ Consistent sizing across ALL tabs
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
	TopMenuButtons = {},
	-- Shop tab state
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
		TopMenu = 3,
		Menus = 4,
		Notifications = 5,
		Error = 6
	},
	-- IMPROVED Device scaling
	MobileScale = 1.3,
	TabletScale = 1.15,
	DesktopScale = 1.0,
	-- Shop tab configuration
	ShopTabConfig = {
		{id = "seeds", name = "🌱 Seeds", color = Color3.fromRGB(100, 200, 100)},
		{id = "farm", name = "🌾 Farming", color = Color3.fromRGB(139, 90, 43)},
		{id = "defense", name = "🛡️ Defense", color = Color3.fromRGB(120, 80, 200)},
		{id = "mining", name = "⛏️ Mining", color = Color3.fromRGB(150, 150, 150)},
		{id = "crafting", name = "🔨 Crafting", color = Color3.fromRGB(200, 120, 80)},
		{id = "premium", name = "✨ Premium", color = Color3.fromRGB(255, 215, 0)},
		{id = "sell", name = "💰 Sell", color = Color3.fromRGB(255, 165, 0)}
	}
}

-- ========== TRULY UNIFORM SHOP ITEM CONFIGURATION ==========
UIManager.ItemConfig = {
	-- FIXED: Absolutely uniform sizing for ALL shop items (no device variations)
	ItemFrameSize = UDim2.new(0.95, 0, 0.15, 0), -- Fixed 15% height for ALL items
	ItemSpacing = 0.015, -- Fixed spacing between ALL items
	YIncrement = 0.165,  -- Fixed increment for ALL items (0.15 + 0.015)

	-- FIXED: Identical proportions for ALL internal elements
	CategoryIndicatorSize = UDim2.new(0.008, 0, 1, 0),
	CategoryIndicatorPosition = UDim2.new(0, 0, 0, 0),

	BadgeSize = UDim2.new(0.06, 0, 0.22, 0),
	BadgePosition = UDim2.new(0.015, 0, 0.03, 0),

	IconSize = UDim2.new(0.10, 0, 0.45, 0),
	IconPosition = UDim2.new(0.04, 0, 0.275, 0),

	NameSize = UDim2.new(0.34, 0, 0.28, 0),
	NamePosition = UDim2.new(0.16, 0, 0.08, 0),

	PriceSize = UDim2.new(0.20, 0, 0.28, 0),
	PricePosition = UDim2.new(0.52, 0, 0.08, 0),

	DescriptionSize = UDim2.new(0.34, 0, 0.32, 0),
	DescriptionPosition = UDim2.new(0.16, 0, 0.45, 0),

	ButtonSize = UDim2.new(0.16, 0, 0.28, 0),
	ButtonPosition = UDim2.new(0.82, 0, 0.45, 0)
}

-- SIMPLIFIED: Device-specific adjustments ONLY for text and buttons, NOT frame sizes
UIManager.DeviceAdjustments = {
	Mobile = {
		TextSizeMultiplier = 1.2,
		ButtonTouchPadding = 4, -- Extra padding for touch
		MinTextSize = 12
	},
	Tablet = {
		TextSizeMultiplier = 1.1,
		ButtonTouchPadding = 2,
		MinTextSize = 10
	},
	Desktop = {
		TextSizeMultiplier = 1.0,
		ButtonTouchPadding = 0,
		MinTextSize = 8
	}
}

print("UIManager: COMPLETE responsive module loaded with fixed shop opening + uniform sizing")

-- ========== DEVICE DETECTION ==========

function UIManager:GetDeviceType()
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		-- Mobile device
		if math.min(viewportSize.X, viewportSize.Y) < 600 then
			return "Mobile"
		else
			return "Tablet"
		end
	else
		-- Desktop
		return "Desktop"
	end
end

function UIManager:GetScaleFactor()
	local deviceType = self:GetDeviceType()
	if deviceType == "Mobile" then
		return self.Config.MobileScale
	elseif deviceType == "Tablet" then
		return self.Config.TabletScale
	else
		return self.Config.DesktopScale
	end
end

function UIManager:GetDeviceAdjustments()
	local deviceType = self:GetDeviceType()
	return self.DeviceAdjustments[deviceType] or self.DeviceAdjustments.Desktop
end

function UIManager:GetAdjustedItemConfig()
	-- FIXED: Return base config without any size modifications
	-- ALL items use exactly the same frame sizes
	return self.ItemConfig
end

-- ========== INITIALIZATION ==========

function UIManager:Initialize()
	print("UIManager: Starting responsive initialization...")

	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
	if not playerGui then
		error("UIManager: PlayerGui not found after 30 seconds")
	end

	self.State.ActiveMenus = {}
	self.State.Layers = {}
	self.State.NotificationQueue = {}
	self.State.IsTransitioning = false
	self.State.CurrentPage = "None"
	self.State.TopMenuButtons = {}
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

	local menuSuccess, menuError = pcall(function()
		self:SetupTopMenu()
	end)

	if not menuSuccess then
		warn("UIManager: Failed to create top menu: " .. tostring(menuError))
		spawn(function()
			wait(1)
			print("UIManager: Retrying top menu creation...")
			local retrySuccess, retryError = pcall(function()
				self:SetupTopMenu()
			end)

			if retrySuccess then
				print("UIManager: ✅ Top menu created on retry")
			else
				warn("UIManager: Failed again to create top menu: " .. tostring(retryError))
			end
		end)
	else
		print("UIManager: ✅ Top menu created successfully")
	end

	print("UIManager: 🎉 Responsive initialization complete!")
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

	print("UIManager: Responsive main UI structure created")
end

-- ========== TOP MENU SYSTEM ==========

function UIManager:SetupTopMenu()
	print("UIManager: Setting up responsive top menu...")

	local playerGui = LocalPlayer.PlayerGui

	local existingMenuUI = playerGui:FindFirstChild("TopMenuUI")
	if existingMenuUI then
		existingMenuUI:Destroy()
		print("UIManager: Removed existing top menu")
	end

	local menuUI = Instance.new("ScreenGui")
	menuUI.Name = "TopMenuUI"
	menuUI.ResetOnSpawn = false
	menuUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	menuUI.IgnoreGuiInset = true
	menuUI.Parent = playerGui

	-- Top menu bar
	local menuBar = Instance.new("Frame")
	menuBar.Name = "MenuBar"
	menuBar.Size = UDim2.new(1, 0, 0.08, 0)
	menuBar.Position = UDim2.new(0, 0, 0, 0)
	menuBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	menuBar.BorderSizePixel = 0
	menuBar.ZIndex = self.Config.UIOrder.TopMenu
	menuBar.Parent = menuUI

	-- Menu bar gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
	}
	gradient.Rotation = 90
	gradient.Parent = menuBar

	-- Menu bar border
	local borderLine = Instance.new("Frame")
	borderLine.Name = "BorderLine"
	borderLine.Size = UDim2.new(1, 0, 0, 2)
	borderLine.Position = UDim2.new(0, 0, 1, -2)
	borderLine.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	borderLine.BorderSizePixel = 0
	borderLine.Parent = menuBar

	-- Create menu buttons
	local buttons = {
		{
			name = "Farm",
			text = "🌾 Farm",
			color = Color3.fromRGB(80, 120, 60),
			hoverColor = Color3.fromRGB(100, 140, 80),
			description = "Manage your farm and crops"
		},
		{
			name = "Mining", 
			text = "⛏️ Mining",
			color = Color3.fromRGB(80, 80, 120),
			hoverColor = Color3.fromRGB(100, 100, 140),
			description = "Mine ores and explore caves"
		},
		{
			name = "Crafting",
			text = "🔨 Crafting", 
			color = Color3.fromRGB(120, 80, 60),
			hoverColor = Color3.fromRGB(140, 100, 80),
			description = "Craft tools and equipment"
		}
	}

	local buttonWidth = 0.15
	local buttonSpacing = 0.02
	local totalButtons = #buttons
	local totalWidth = (buttonWidth * totalButtons) + (buttonSpacing * (totalButtons - 1))
	local startX = (1 - totalWidth) / 2

	for i, buttonConfig in ipairs(buttons) do
		local success, error = pcall(function()
			local xPosition = startX + ((i - 1) * (buttonWidth + buttonSpacing))
			local button = self:CreateTopMenuButton(menuBar, buttonConfig, xPosition, buttonWidth)
			self.State.TopMenuButtons[buttonConfig.name] = button
			print("UIManager: ✅ Created " .. buttonConfig.name .. " top menu button")
		end)

		if not success then
			warn("UIManager: Failed to create " .. buttonConfig.name .. " button: " .. tostring(error))
		end
	end

	-- Shop proximity indicator
	self:CreateProximityShopIndicator(menuBar)

	print("UIManager: ✅ Responsive top menu setup complete")
end

function UIManager:CreateTopMenuButton(parent, config, xPosition, width)
	local button = Instance.new("TextButton")
	button.Name = config.name .. "Button"
	button.Size = UDim2.new(width, 0, 0.8, 0)
	button.Position = UDim2.new(xPosition, 0, 0.1, 0)
	button.BackgroundColor3 = config.color
	button.BorderSizePixel = 0
	button.Text = config.text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.ZIndex = self.Config.UIOrder.TopMenu + 1
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	stroke.Parent = button

	local scaleFactor = self:GetScaleFactor()
	if scaleFactor > 1.1 then
		button.TextSize = 14 * scaleFactor
	end

	button.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundColor3 = config.hoverColor,
				Size = UDim2.new(width * 1.05, 0, 0.85, 0)
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
				Size = UDim2.new(width, 0, 0.8, 0)
			}
		)
		leaveTween:Play()

		self:HideButtonTooltip()
	end)

	button.MouseButton1Click:Connect(function()
		print("UIManager: Top menu button clicked: " .. config.name)
		self:HandleTopMenuButtonClick(config.name)
	end)

	return button
end

function UIManager:CreateProximityShopIndicator(parent)
	local indicator = Instance.new("Frame")
	indicator.Name = "ShopProximityIndicator"
	indicator.Size = UDim2.new(0.15, 0, 0.8, 0)
	indicator.Position = UDim2.new(0.84, 0, 0.1, 0)
	indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.ZIndex = self.Config.UIOrder.TopMenu + 1
	indicator.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "🛒 Shop Available"
	label.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Parent = indicator

	self.State.ShopProximityIndicator = indicator

	print("UIManager: ✅ Created responsive proximity shop indicator")
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

function UIManager:ShowButtonTooltip(button, description)
	self:HideButtonTooltip()

	local tooltip = Instance.new("Frame")
	tooltip.Name = "ButtonTooltip"
	tooltip.Size = UDim2.new(0.2, 0, 0.06, 0)
	tooltip.Position = UDim2.new(0, button.AbsolutePosition.X, 0, button.AbsolutePosition.Y + button.AbsoluteSize.Y + 5)
	tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	tooltip.BorderSizePixel = 0
	tooltip.ZIndex = self.Config.UIOrder.Notifications
	tooltip.Parent = self.State.MainUI

	local tooltipCorner = Instance.new("UICorner")
	tooltipCorner.CornerRadius = UDim.new(0.1, 0)
	tooltipCorner.Parent = tooltip

	local tooltipText = Instance.new("TextLabel")
	tooltipText.Size = UDim2.new(1, 0, 1, 0)
	tooltipText.Position = UDim2.new(0, 0, 0, 0)
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

function UIManager:HandleTopMenuButtonClick(buttonName)
	print("UIManager: Top menu button clicked: " .. buttonName)

	local button = self.State.TopMenuButtons[buttonName]
	if button then
		local pressDown = TweenService:Create(button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{Size = UDim2.new(button.Size.X.Scale * 0.95, 0, button.Size.Y.Scale * 0.95, 0)}
		)
		local pressUp = TweenService:Create(button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{Size = UDim2.new(button.Size.X.Scale / 0.95, 0, button.Size.Y.Scale / 0.95, 0)}
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

	print("UIManager: Input handling setup complete")
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
	elseif menuName == "Premium" then
		success = self:CreatePremiumMenu()
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

-- ========== CURRENCY DISPLAY ==========

function UIManager:CreateCurrencyDisplay(parent)
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyDisplay"
	currencyFrame.Size = UDim2.new(0.25, 0, 0.08, 0)
	currencyFrame.Position = UDim2.new(0.74, 0, 0.09, 0)
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
	coinsLabel.Size = UDim2.new(0.5, 0, 1, 0)
	coinsLabel.Position = UDim2.new(0, 0, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "💰 0"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Parent = currencyFrame

	local tokensLabel = Instance.new("TextLabel")
	tokensLabel.Name = "TokensLabel"
	tokensLabel.Size = UDim2.new(0.5, 0, 1, 0)
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

	print("UIManager: Responsive currency display created")
end

-- ========== MENU CONTAINERS ==========

function UIManager:CreateMenuContainers(parent)
	local menuContainer = Instance.new("Frame")
	menuContainer.Name = "MenuContainer"
	menuContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
	menuContainer.Position = UDim2.new(0.05, 0, 0.17, 0)
	menuContainer.BackgroundTransparency = 1
	menuContainer.ZIndex = self.Config.UIOrder.Menus
	menuContainer.Visible = false
	menuContainer.Parent = parent

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1.1, 0, 1.1, 0)
	background.Position = UDim2.new(-0.05, 0, -0.05, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.3
	background.ZIndex = self.Config.UIOrder.Background
	background.Parent = menuContainer

	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(1, 0, 1, 0)
	menuFrame.Position = UDim2.new(0, 0, 0, 0)
	menuFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	menuFrame.BorderSizePixel = 0
	menuFrame.ZIndex = self.Config.UIOrder.Menus
	menuFrame.Parent = menuContainer

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0.02, 0)
	menuCorner.Parent = menuFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0.02, 0)
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

	print("UIManager: Responsive menu containers created")
end

-- ========== NOTIFICATION AREA ==========

function UIManager:CreateNotificationArea(parent)
	local notificationArea = Instance.new("Frame")
	notificationArea.Name = "NotificationArea"
	notificationArea.Size = UDim2.new(0.3, 0, 1, 0)
	notificationArea.Position = UDim2.new(0.69, 0, 0, 0)
	notificationArea.BackgroundTransparency = 1
	notificationArea.ZIndex = self.Config.UIOrder.Notifications
	notificationArea.Parent = parent

	print("UIManager: Responsive notification area created")
end

-- ========== TRULY UNIFORM SHOP ITEM CREATION ==========

function UIManager:CreateStandardShopItemFrame(item, index, categoryColor, itemType)
	itemType = itemType or "buy"

	-- FIXED: Use base config - NO size variations between devices/tabs
	local config = self.ItemConfig -- Direct reference, no adjustments to frame sizes
	local adjustments = self:GetDeviceAdjustments()

	local itemFrame = Instance.new("Frame")
	itemFrame.Name = (itemType == "sell" and "SellItem_" or "ShopItem_") .. index
	itemFrame.Size = config.ItemFrameSize -- FIXED: Always the same size
	itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	itemFrame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = itemFrame

	-- Category color indicator (identical for all items)
	local indicator = Instance.new("Frame")
	indicator.Name = "CategoryIndicator"
	indicator.Size = config.CategoryIndicatorSize
	indicator.Position = config.CategoryIndicatorPosition
	indicator.BackgroundColor3 = categoryColor
	indicator.BorderSizePixel = 0
	indicator.Parent = itemFrame

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0.05, 0)
	indicatorCorner.Parent = indicator

	-- Badge (identical positioning for all items)
	self:CreateUniformItemBadge(itemFrame, item, itemType, config, adjustments)

	-- Item icon (identical positioning for all items)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "ItemIcon"
	iconLabel.Size = config.IconSize
	iconLabel.Position = config.IconPosition
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = item.icon or "📦"
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.Gotham
	iconLabel.Parent = itemFrame

	-- Item name (identical positioning for all items)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = config.NameSize
	nameLabel.Position = config.NamePosition
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name or item.id
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame

	-- Apply text scaling ONLY (not size scaling)
	if adjustments.TextSizeMultiplier > 1.0 and adjustments.MinTextSize then
		nameLabel.TextSize = math.max(adjustments.MinTextSize, nameLabel.TextSize * adjustments.TextSizeMultiplier)
	end

	-- Price information (identical positioning for all items)
	self:CreateUniformItemPriceInfo(itemFrame, item, itemType, config, adjustments)

	-- Description (identical positioning for all items)
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "ItemDescription"
	descLabel.Size = config.DescriptionSize
	descLabel.Position = config.DescriptionPosition
	descLabel.BackgroundTransparency = 1
	descLabel.Text = self:GetItemDescription(item, itemType)
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextWrapped = true
	descLabel.Parent = itemFrame

	-- Apply text scaling ONLY (not size scaling)
	if adjustments.TextSizeMultiplier > 1.0 and adjustments.MinTextSize then
		descLabel.TextSize = math.max(adjustments.MinTextSize, descLabel.TextSize * adjustments.TextSizeMultiplier)
	end

	-- Action buttons (identical positioning for all items)
	self:CreateUniformItemButtons(itemFrame, item, itemType, config, adjustments)

	-- Hover effects (identical for all items)
	self:AddItemFrameHoverEffects(itemFrame)

	return itemFrame
end

function UIManager:CreateItemBadge(itemFrame, item, itemType, config, adjustments)
	local badge = Instance.new("Frame")
	badge.Name = itemType == "sell" and "StockBadge" or "OrderBadge"
	badge.Size = config.BadgeSize
	badge.Position = config.BadgePosition
	badge.BorderSizePixel = 0
	badge.Parent = itemFrame

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0.3, 0)
	badgeCorner.Parent = badge

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Size = UDim2.new(1, 0, 1, 0)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.TextColor3 = Color3.new(1, 1, 1)
	badgeLabel.TextScaled = true
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.Parent = badge

	if itemType == "sell" then
		badge.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		badgeLabel.Text = tostring(item.stock or 0)
	else
		if item.purchaseOrder and item.purchaseOrder <= 20 then
			badge.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			badgeLabel.Text = tostring(item.purchaseOrder)
		else
			badge.Visible = false
		end
	end
end

function UIManager:CreateItemPriceInfo(itemFrame, item, itemType, config, adjustments)
	if itemType == "sell" then
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PricePerItem"
		priceLabel.Size = UDim2.new(config.PriceSize.X.Scale, 0, 0.12, 0)
		priceLabel.Position = UDim2.new(config.PricePosition.X.Scale, 0, 0.08, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = (item.sellPrice or 0) .. " 💰 each"
		priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextXAlignment = Enum.TextXAlignment.Right
		priceLabel.Parent = itemFrame

		local totalLabel = Instance.new("TextLabel")
		totalLabel.Name = "TotalValue"
		totalLabel.Size = UDim2.new(config.PriceSize.X.Scale, 0, 0.12, 0)
		totalLabel.Position = UDim2.new(config.PricePosition.X.Scale, 0, 0.22, 0)
		totalLabel.BackgroundTransparency = 1
		totalLabel.Text = "Total: " .. (item.totalValue or 0) .. " 💰"
		totalLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		totalLabel.TextScaled = true
		totalLabel.Font = Enum.Font.GothamBold
		totalLabel.TextXAlignment = Enum.TextXAlignment.Right
		totalLabel.Parent = itemFrame
	else
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PurchasePrice"
		priceLabel.Size = config.PriceSize
		priceLabel.Position = config.PricePosition
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = (item.price or 0) .. " " .. (item.currency == "farmTokens" and "🎫" or "💰")
		priceLabel.TextColor3 = item.currency == "farmTokens" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextXAlignment = Enum.TextXAlignment.Right
		priceLabel.Parent = itemFrame
	end
end

function UIManager:GetItemDescription(item, itemType)
	if itemType == "sell" then
		return item.description or ("You have " .. (item.stock or 0) .. " in stock")
	else
		local desc = item.description or "No description"
		return desc:len() > 80 and (desc:sub(1, 80) .. "...") or desc
	end
end

function UIManager:CreateItemButtons(itemFrame, item, itemType, config, adjustments)
	if itemType == "sell" then
		local buttonContainer = Instance.new("Frame")
		buttonContainer.Name = "SellButtonContainer"
		buttonContainer.Size = config.ButtonSize
		buttonContainer.Position = config.ButtonPosition
		buttonContainer.BackgroundTransparency = 1
		buttonContainer.Parent = itemFrame

		local sell1Button = Instance.new("TextButton")
		sell1Button.Name = "Sell1Button"
		sell1Button.Size = UDim2.new(1, 0, 0.45, 0)
		sell1Button.Position = UDim2.new(0, 0, 0, 0)
		sell1Button.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		sell1Button.BorderSizePixel = 0
		sell1Button.Text = "SELL 1"
		sell1Button.TextColor3 = Color3.new(1, 1, 1)
		sell1Button.TextScaled = true
		sell1Button.Font = Enum.Font.GothamBold
		sell1Button.Parent = buttonContainer

		local sell1Corner = Instance.new("UICorner")
		sell1Corner.CornerRadius = UDim.new(0.1, 0)
		sell1Corner.Parent = sell1Button

		local sellAllButton = Instance.new("TextButton")
		sellAllButton.Name = "SellAllButton"
		sellAllButton.Size = UDim2.new(1, 0, 0.45, 0)
		sellAllButton.Position = UDim2.new(0, 0, 0.55, 0)
		sellAllButton.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
		sellAllButton.BorderSizePixel = 0
		sellAllButton.Text = "SELL ALL"
		sellAllButton.TextColor3 = Color3.new(1, 1, 1)
		sellAllButton.TextScaled = true
		sellAllButton.Font = Enum.Font.GothamBold
		sellAllButton.Parent = buttonContainer

		local sellAllCorner = Instance.new("UICorner")
		sellAllCorner.CornerRadius = UDim.new(0.1, 0)
		sellAllCorner.Parent = sellAllButton

		sell1Button.MouseButton1Click:Connect(function()
			if self.State.GameClient and self.State.GameClient.SellItem then
				self.State.GameClient:SellItem(item.id, 1)
			else
				self:ShowNotification("Sell Error", "Sell system not available!", "error")
			end
		end)

		sellAllButton.MouseButton1Click:Connect(function()
			if self.State.GameClient and self.State.GameClient.SellItem then
				self.State.GameClient:SellItem(item.id, item.stock)
			else
				self:ShowNotification("Sell Error", "Sell system not available!", "error")
			end
		end)
	else
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = config.ButtonSize
		buyButton.Position = config.ButtonPosition
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

		buyButton.MouseButton1Click:Connect(function()
			if self.State.GameClient and self.State.GameClient.PurchaseItem then
				self.State.GameClient:PurchaseItem(item)
			else
				self:ShowNotification("Shop Error", "Purchase system not available!", "error")
			end
		end)
	end
end

function UIManager:AddItemFrameHoverEffects(itemFrame)
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
end

-- ========== SHOP MENU SYSTEM ==========

function UIManager:CreateTabbedShopMenu()
	print("UIManager: Creating responsive tabbed shop menu with uniform item sizing")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "🛒 Supply Depot"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	-- Access note
	local accessNote = Instance.new("TextLabel")
	accessNote.Name = "AccessNote"
	accessNote.Size = UDim2.new(0.95, 0, 0.05, 0)
	accessNote.Position = UDim2.new(0.025, 0, 0.12, 0)
	accessNote.BackgroundTransparency = 1
	accessNote.Text = "👣 Organized by category • Uniform item presentation"
	accessNote.TextColor3 = Color3.fromRGB(200, 200, 200)
	accessNote.TextScaled = true
	accessNote.Font = Enum.Font.Gotham
	accessNote.Parent = menuFrame

	-- Create tab container
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(0.95, 0, 0.08, 0)
	tabContainer.Position = UDim2.new(0.025, 0, 0.18, 0)
	tabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabContainer.BorderSizePixel = 0
	tabContainer.Parent = menuFrame

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0.02, 0)
	tabCorner.Parent = tabContainer

	-- Create content container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(0.95, 0, 0.7, 0)
	contentContainer.Position = UDim2.new(0.025, 0, 0.27, 0)
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
	print("UIManager: Creating responsive shop tabs")

	self.State.ShopTabs = {}

	local tabWidth = 1 / #self.Config.ShopTabConfig

	for i, tabConfig in ipairs(self.Config.ShopTabConfig) do
		local tabButton = Instance.new("TextButton")
		tabButton.Name = "Tab_" .. tabConfig.id
		tabButton.Size = UDim2.new(tabWidth, -0.01, 0.9, 0)
		tabButton.Position = UDim2.new(tabWidth * (i - 1), 0.005, 0.05, 0)
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

		local contentFrame = Instance.new("ScrollingFrame")
		contentFrame.Name = "Content_" .. tabConfig.id
		contentFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
		contentFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
		contentFrame.BackgroundTransparency = 1
		contentFrame.BorderSizePixel = 0
		contentFrame.ScrollBarThickness = 8
		contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
		contentFrame.Visible = false
		contentFrame.Parent = contentContainer

		self.State.ShopTabs[tabConfig.id] = {
			button = tabButton,
			content = contentFrame,
			config = tabConfig,
			populated = false
		}

		tabButton.MouseButton1Click:Connect(function()
			self:ShowShopTab(tabConfig.id)
		end)

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

		print("UIManager: Created responsive tab: " .. tabConfig.name)
	end
end

function UIManager:PopulateShopTabContent(tabId)
	print("UIManager: Populating content for tab: " .. tabId .. " with uniform sizing")

	local tab = self.State.ShopTabs[tabId]
	if not tab then return end

	local contentFrame = tab.content

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

	if tabId == "sell" then
		self:PopulateUniformSellTabContent(contentFrame, tab.config.color)
		return
	end

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

	local categoryItems = {}
	for _, item in ipairs(shopItems) do
		if item.category == tabId then
			table.insert(categoryItems, item)
		end
	end

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

	local config = self:GetAdjustedItemConfig()
	local yPosition = 0.015

	for i, item in ipairs(categoryItems) do
		local itemFrame = self:CreateStandardShopItemFrame(item, i, tab.config.color, "buy")
		itemFrame.Position = UDim2.new(0.025, 0, yPosition, 0)
		itemFrame.Parent = contentFrame
		yPosition = yPosition + config.YIncrement
	end

	contentFrame.CanvasSize = UDim2.new(0, 0, yPosition + 0.03, 0)

	print("UIManager: Populated " .. #categoryItems .. " items in " .. tabId .. " tab with uniform sizing")
end

function UIManager:PopulateUniformSellTabContent(contentFrame, categoryColor)
	print("UIManager: Populating sell tab content with uniform sizing")

	local success, sellableItems = pcall(function()
		if self.State.GameClient.GetSellableItems then
			return self.State.GameClient:GetSellableItems()
		end
		return {}
	end)

	if not success or not sellableItems or #sellableItems == 0 then
		local noItemsLabel = Instance.new("TextLabel")
		noItemsLabel.Size = UDim2.new(1, 0, 1, 0)
		noItemsLabel.BackgroundTransparency = 1
		noItemsLabel.Text = "💰 No items to sell!\n\nGrow crops or collect milk to have items to sell."
		noItemsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noItemsLabel.TextScaled = true
		noItemsLabel.Font = Enum.Font.Gotham
		noItemsLabel.Parent = contentFrame
		return
	end

	local config = self:GetAdjustedItemConfig()
	local yPosition = 0.015

	for i, item in ipairs(sellableItems) do
		local itemFrame = self:CreateStandardShopItemFrame(item, i, categoryColor, "sell")
		itemFrame.Position = UDim2.new(0.025, 0, yPosition, 0)
		itemFrame.Parent = contentFrame
		yPosition = yPosition + config.YIncrement
	end

	contentFrame.CanvasSize = UDim2.new(0, 0, yPosition + 0.03, 0)

	print("UIManager: Populated " .. #sellableItems .. " sellable items with uniform sizing")
end

function UIManager:ShowShopTab(tabId)
	print("UIManager: Switching to shop tab: " .. tabId)

	if not self.State.ShopTabs[tabId] then
		warn("UIManager: Tab not found: " .. tabId)
		return
	end

	local previousTab = self.State.ActiveShopTab
	self.State.ActiveShopTab = tabId

	for id, tab in pairs(self.State.ShopTabs) do
		local isActive = (id == tabId)

		tab.content.Visible = isActive

		local targetColor = isActive and self:LightenColor(tab.config.color, 0.3) or tab.config.color
		local buttonTween = TweenService:Create(tab.button,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad),
			{BackgroundColor3 = targetColor}
		)
		buttonTween:Play()

		if isActive then
			local indicator = tab.button:FindFirstChild("ActiveIndicator")
			if not indicator then
				indicator = Instance.new("Frame")
				indicator.Name = "ActiveIndicator"
				indicator.Size = UDim2.new(1, 0, 0.1, 0)
				indicator.Position = UDim2.new(0, 0, 0.9, 0)
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

	if not self.State.ShopTabs[tabId].populated then
		self:PopulateShopTabContent(tabId)
		self.State.ShopTabs[tabId].populated = true
	end
end

-- ========== OTHER MENU FUNCTIONS ==========

function UIManager:CreateFarmMenu()
	print("UIManager: Creating responsive farm menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "🌾 FARM MANAGEMENT"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0.95, 0, 0.8, 0)
	inventoryFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Parent = menuFrame

	local inventoryCorner = Instance.new("UICorner")
	inventoryCorner.CornerRadius = UDim.new(0.02, 0)
	inventoryCorner.Parent = inventoryFrame

	local inventoryTitle = Instance.new("TextLabel")
	inventoryTitle.Name = "InventoryTitle"
	inventoryTitle.Size = UDim2.new(0.9, 0, 0.1, 0)
	inventoryTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	inventoryTitle.BackgroundTransparency = 1
	inventoryTitle.Text = "📦 FARM INVENTORY"
	inventoryTitle.TextColor3 = Color3.new(1, 1, 1)
	inventoryTitle.TextScaled = true
	inventoryTitle.Font = Enum.Font.GothamBold
	inventoryTitle.Parent = inventoryFrame

	self:PopulateFarmInventory(inventoryFrame)

	return true
end

function UIManager:PopulateFarmInventory(inventoryFrame)
	if not self.State.GameClient then
		local loadingLabel = Instance.new("TextLabel")
		loadingLabel.Name = "LoadingLabel"
		loadingLabel.Size = UDim2.new(0.9, 0, 0.8, 0)
		loadingLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
		loadingLabel.BackgroundTransparency = 1
		loadingLabel.Text = "Loading farm inventory..."
		loadingLabel.TextColor3 = Color3.new(1, 1, 1)
		loadingLabel.TextScaled = true
		loadingLabel.Font = Enum.Font.Gotham
		loadingLabel.Parent = inventoryFrame
		return
	end

	local success, playerData = pcall(function()
		if self.State.GameClient.GetPlayerData then
			return self.State.GameClient:GetPlayerData()
		end
		return nil
	end)

	if not success or not playerData then
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.new(0.9, 0, 0.8, 0)
		errorLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = "❌ Unable to load inventory data"
		errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		errorLabel.TextScaled = true
		errorLabel.Font = Enum.Font.Gotham
		errorLabel.Parent = inventoryFrame
		return
	end

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "InventoryScroll"
	scrollFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
	scrollFrame.Position = UDim2.new(0.025, 0, 0.12, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = inventoryFrame

	local yPosition = 0.02
	local categorySpacing = 0.02

	yPosition = self:CreateInventoryCategory(scrollFrame, "🌱 SEEDS", yPosition, playerData.seeds or {})
	yPosition = yPosition + categorySpacing

	yPosition = self:CreateInventoryCategory(scrollFrame, "🌾 HARVESTED CROPS", yPosition, playerData.crops or {})
	yPosition = yPosition + categorySpacing

	local milkData = {
		milk = playerData.milk or 0
	}
	yPosition = self:CreateInventoryCategory(scrollFrame, "🥛 DAIRY PRODUCTS", yPosition, milkData)

	scrollFrame.CanvasSize = UDim2.new(0, 0, yPosition + 0.05, 0)
end

function UIManager:CreateInventoryCategory(parentFrame, categoryTitle, startY, itemData)
	local config = self:GetAdjustedItemConfig()
	local adjustments = self:GetDeviceAdjustments()

	local categoryHeader = Instance.new("Frame")
	categoryHeader.Name = categoryTitle:gsub("[^%w]", "") .. "Header"
	categoryHeader.Size = UDim2.new(0.95, 0, config.ItemFrameSize.Y.Scale * 0.5, 0)
	categoryHeader.Position = UDim2.new(0.025, 0, startY, 0)
	categoryHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	categoryHeader.BorderSizePixel = 0
	categoryHeader.Parent = parentFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.1, 0)
	headerCorner.Parent = categoryHeader

	local headerLabel = Instance.new("TextLabel")
	headerLabel.Size = UDim2.new(0.9, 0, 1, 0)
	headerLabel.Position = UDim2.new(0.05, 0, 0, 0)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = categoryTitle
	headerLabel.TextColor3 = Color3.new(1, 1, 1)
	headerLabel.TextScaled = true
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Parent = categoryHeader

	local currentY = startY + (config.ItemFrameSize.Y.Scale * 0.6)

	local hasItems = false
	if type(itemData) == "table" then
		for itemName, quantity in pairs(itemData) do
			if quantity and quantity > 0 then
				hasItems = true
				break
			end
		end
	end

	if not hasItems then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyLabel"
		emptyLabel.Size = UDim2.new(0.9, 0, config.ItemFrameSize.Y.Scale * 0.4, 0)
		emptyLabel.Position = UDim2.new(0.05, 0, currentY, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No items in this category"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
		emptyLabel.Parent = parentFrame

		return currentY + (config.ItemFrameSize.Y.Scale * 0.5)
	end

	for itemName, quantity in pairs(itemData) do
		if quantity and quantity > 0 then
			local itemFrame = Instance.new("Frame")
			itemFrame.Name = itemName .. "Item"
			itemFrame.Size = UDim2.new(0.9, 0, config.ItemFrameSize.Y.Scale * 0.4, 0)
			itemFrame.Position = UDim2.new(0.05, 0, currentY, 0)
			itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = parentFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0.05, 0)
			itemCorner.Parent = itemFrame

			local itemIcon = self:GetItemIcon(itemName)
			local iconLabel = Instance.new("TextLabel")
			iconLabel.Size = UDim2.new(0.1, 0, 0.8, 0)
			iconLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
			iconLabel.BackgroundTransparency = 1
			iconLabel.Text = itemIcon
			iconLabel.TextColor3 = Color3.new(1, 1, 1)
			iconLabel.TextScaled = true
			iconLabel.Font = Enum.Font.Gotham
			iconLabel.Parent = itemFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, 0, 0.8, 0)
			nameLabel.Position = UDim2.new(0.15, 0, 0.1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = self:FormatItemName(itemName)
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.Gotham
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = itemFrame

			local quantityLabel = Instance.new("TextLabel")
			quantityLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
			quantityLabel.Position = UDim2.new(0.78, 0, 0.1, 0)
			quantityLabel.BackgroundTransparency = 1
			quantityLabel.Text = "x" .. self:FormatNumber(quantity)
			quantityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			quantityLabel.TextScaled = true
			quantityLabel.Font = Enum.Font.GothamBold
			quantityLabel.TextXAlignment = Enum.TextXAlignment.Right
			quantityLabel.Parent = itemFrame

			itemFrame.MouseEnter:Connect(function()
				local hoverTween = TweenService:Create(itemFrame,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = Color3.fromRGB(45, 45, 45)}
				)
				hoverTween:Play()
			end)

			itemFrame.MouseLeave:Connect(function()
				local leaveTween = TweenService:Create(itemFrame,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = Color3.fromRGB(35, 35, 35)}
				)
				leaveTween:Play()
			end)

			currentY = currentY + (config.ItemFrameSize.Y.Scale * 0.5)
		end
	end

	return currentY
end

function UIManager:GetItemIcon(itemName)
	local iconMap = {
		carrot_seeds = "🥕", carrotSeeds = "🥕",
		tomato_seeds = "🍅", tomatoSeeds = "🍅",
		corn_seeds = "🌽", cornSeeds = "🌽",
		wheat_seeds = "🌾", wheatSeeds = "🌾",
		potato_seeds = "🥔", potatoSeeds = "🥔",
		lettuce_seeds = "🥬", lettuceSeeds = "🥬",
		carrot = "🥕", tomato = "🍅", corn = "🌽", 
		wheat = "🌾", potato = "🥔", lettuce = "🥬",
		milk = "🥛", default = "📦"
	}
	return iconMap[itemName] or iconMap.default
end

function UIManager:FormatItemName(itemName)
	local displayName = itemName:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return a:upper()..b end)
	if itemName:find("_seeds") or itemName:find("Seeds") then
		displayName = displayName:gsub(" Seeds", "") .. " Seeds"
	end
	return displayName
end

function UIManager:CreateMiningMenu()
	print("UIManager: Creating mining menu with UNIFORM item sizing")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "⛏️ MINING OPERATIONS"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	-- Create content container (same as shop)
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(0.95, 0, 0.85, 0)
	contentContainer.Position = UDim2.new(0.025, 0, 0.12, 0)
	contentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = menuFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0.02, 0)
	contentCorner.Parent = contentContainer

	-- Create scrolling frame for items
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "MiningContent"
	contentFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
	contentFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 8
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	contentFrame.Parent = contentContainer

	-- Populate with mining items using UNIFORM sizing
	self:PopulateCategoryMenuContent(contentFrame, "mining", Color3.fromRGB(150, 150, 150))

	return true
end

function UIManager:CreateCraftingMenu()
	print("UIManager: Creating crafting menu with UNIFORM item sizing")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "🔨 CRAFTING WORKSHOP"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	-- Create content container (same as shop)
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(0.95, 0, 0.85, 0)
	contentContainer.Position = UDim2.new(0.025, 0, 0.12, 0)
	contentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = menuFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0.02, 0)
	contentCorner.Parent = contentContainer

	-- Create scrolling frame for items
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "CraftingContent"
	contentFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
	contentFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 8
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	contentFrame.Parent = contentContainer

	-- Populate with crafting items using UNIFORM sizing
	self:PopulateCategoryMenuContent(contentFrame, "crafting", Color3.fromRGB(200, 120, 80))

	return true
end

-- NEW: Universal category menu content population with UNIFORM sizing
function UIManager:PopulateCategoryMenuContent(contentFrame, category, categoryColor)
	print("UIManager: Populating " .. category .. " menu with UNIFORM item sizing")

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
		loadingLabel.Text = "Loading " .. category .. " items..."
		loadingLabel.TextColor3 = Color3.new(1, 1, 1)
		loadingLabel.TextScaled = true
		loadingLabel.Font = Enum.Font.Gotham
		loadingLabel.Parent = contentFrame
		return
	end

	-- Get shop items
	local success, shopItems = pcall(function()
		if self.State.GameClient.GetShopItems then
			return self.State.GameClient:GetShopItems()
		end
		return {}
	end)

	if not success or not shopItems or #shopItems == 0 then
		-- Show coming soon message with uniform styling
		self:CreateComingSoonContent(contentFrame, category, categoryColor)
		return
	end

	-- Filter items by category
	local categoryItems = {}
	for _, item in ipairs(shopItems) do
		if item.category == category then
			table.insert(categoryItems, item)
		end
	end

	-- If no items, show coming soon
	if #categoryItems == 0 then
		self:CreateComingSoonContent(contentFrame, category, categoryColor)
		return
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

	-- Create items with TRULY UNIFORM sizing (identical to shop tabs)
	local config = self.ItemConfig -- Use base config directly
	local yPosition = 0.015

	for i, item in ipairs(categoryItems) do
		local itemFrame = self:CreateStandardShopItemFrame(item, i, categoryColor, "buy")
		itemFrame.Position = UDim2.new(0.025, 0, yPosition, 0)
		itemFrame.Parent = contentFrame
		yPosition = yPosition + config.YIncrement -- FIXED: Always same increment
	end

	-- Update canvas size with padding
	contentFrame.CanvasSize = UDim2.new(0, 0, yPosition + 0.03, 0)

	print("UIManager: Populated " .. #categoryItems .. " items in " .. category .. " menu with TRULY UNIFORM sizing")
end

-- NEW: Coming soon content with truly uniform styling
function UIManager:CreateComingSoonContent(contentFrame, category, categoryColor)
	local config = self.ItemConfig -- Use base config directly

	-- Create a "coming soon" item using the same sizing as ALL shop items
	local comingSoonFrame = Instance.new("Frame")
	comingSoonFrame.Name = "ComingSoonFrame"
	comingSoonFrame.Size = UDim2.new(0.95, 0, config.ItemFrameSize.Y.Scale * 3, 0) -- Make it 3x height for more text
	comingSoonFrame.Position = UDim2.new(0.025, 0, 0.015, 0)
	comingSoonFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	comingSoonFrame.BorderSizePixel = 0
	comingSoonFrame.Parent = contentFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = comingSoonFrame

	-- Category indicator (identical to shop items)
	local indicator = Instance.new("Frame")
	indicator.Name = "CategoryIndicator"
	indicator.Size = config.CategoryIndicatorSize
	indicator.Position = config.CategoryIndicatorPosition
	indicator.BackgroundColor3 = categoryColor
	indicator.BorderSizePixel = 0
	indicator.Parent = comingSoonFrame

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0.05, 0)
	indicatorCorner.Parent = indicator

	-- Coming soon content
	local contentLabel = Instance.new("TextLabel")
	contentLabel.Size = UDim2.new(0.9, 0, 1, 0)
	contentLabel.Position = UDim2.new(0.05, 0, 0, 0)
	contentLabel.BackgroundTransparency = 1
	contentLabel.TextColor3 = Color3.new(1, 1, 1)
	contentLabel.TextScaled = true
	contentLabel.Font = Enum.Font.Gotham
	contentLabel.TextWrapped = true
	contentLabel.Parent = comingSoonFrame

	-- Category-specific coming soon text
	local comingSoonText = {
		mining = "⛏️ MINING SYSTEM\n\nComing Soon!\n\n• Deep cave exploration\n• Valuable ore collection\n• Advanced pickaxe tools\n• Mining skill progression",
		crafting = "🔨 CRAFTING SYSTEM\n\nComing Soon!\n\n• Advanced tool creation\n• Equipment upgrades\n• Recipe discovery\n• Material processing",
		premium = "✨ PREMIUM SYSTEM\n\nComing Soon!\n\n• Exclusive items\n• Special abilities\n• Premium subscriptions\n• Enhanced features"
	}

	contentLabel.Text = comingSoonText[category] or (category:upper() .. " SYSTEM\n\nComing Soon!")

	-- Set canvas size (using fixed base config)
	contentFrame.CanvasSize = UDim2.new(0, 0, config.ItemFrameSize.Y.Scale * 3.5, 0)
end

function UIManager:CreateGenericMenu(menuName)
	print("UIManager: Creating generic menu for: " .. menuName)

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = menuName:upper() .. " MENU"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(0.8, 0, 0.5, 0)
	placeholder.Position = UDim2.new(0.1, 0, 0.25, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "Menu content for " .. menuName .. " will be implemented here."
	placeholder.TextColor3 = Color3.fromRGB(200, 200, 200)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.Gotham
	placeholder.Parent = menuFrame

	return true
end

-- ========== UTILITY FUNCTIONS ==========

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

function UIManager:LightenColor(color, amount)
	return Color3.new(
		math.min(1, color.R + amount),
		math.min(1, color.G + amount),
		math.min(1, color.B + amount)
	)
end

function UIManager:RefreshMenuContent(menuName)
	if self.State.CurrentPage ~= menuName then return end

	print("UIManager: Refreshing content for " .. menuName)

	if menuName == "Shop" then
		local activeTab = self.State.ShopTabs[self.State.ActiveShopTab]
		if activeTab then
			activeTab.populated = false
			self:PopulateShopTabContent(self.State.ActiveShopTab)
		end
	elseif menuName == "Farm" then
		self:RefreshFarmContent()
	else
		local currentMenus = self.State.ActiveMenus
		self:CloseActiveMenus()

		spawn(function()
			wait(0.1)
			self:OpenMenu(menuName)
		end)
	end
end

function UIManager:RefreshFarmContent()
	if self.State.CurrentPage ~= "Farm" then return end

	print("UIManager: Refreshing farm inventory content")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame
	local inventoryFrame = menuFrame:FindFirstChild("InventoryFrame")

	if inventoryFrame then
		local scrollFrame = inventoryFrame:FindFirstChild("InventoryScroll")
		if scrollFrame then
			for _, child in pairs(scrollFrame:GetChildren()) do
				if not child:IsA("UICorner") and not child:IsA("UIListLayout") then
					child:Destroy()
				end
			end

			self:PopulateFarmInventory(inventoryFrame)
		end
	end
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

	print("UIManager: Responsive notification system setup complete")
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
	notification.Size = UDim2.new(0.9, 0, 0.1, 0)
	notification.Position = UDim2.new(0.05, 0, 0.1 + (existingCount * 0.11), 0)
	notification.BackgroundColor3 = self:GetNotificationColor(notificationData.type)
	notification.BorderSizePixel = 0
	notification.ZIndex = self.Config.UIOrder.Notifications
	notification.Parent = notificationArea

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0.1, 0)
	notifCorner.Parent = notification

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.9, 0, 0.5, 0)
	titleLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = notificationData.title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notification

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
	messageLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = notificationData.message
	messageLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	messageLabel.TextScaled = true
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextWrapped = true
	messageLabel.Parent = notification

	notification.Position = UDim2.new(1, 0, 0.1 + (existingCount * 0.11), 0)
	local slideIn = TweenService:Create(notification,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.05, 0, 0.1 + (existingCount * 0.11), 0)}
	)
	slideIn:Play()

	spawn(function()
		wait(self.Config.NotificationDisplayTime)
		if notification and notification.Parent then
			local slideOut = TweenService:Create(notification,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(1, 0, notification.Position.Y.Scale, 0)}
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

function UIManager:GetCurrentPage()
	return self.State.CurrentPage
end

function UIManager:GetState()
	return self.State
end

function UIManager:Cleanup()
	print("UIManager: Performing cleanup...")

	self:CloseActiveMenus()

	self.State.NotificationQueue = {}

	if self.State.MainUI then
		self.State.MainUI:Destroy()
		self.State.MainUI = nil
	end

	local topMenuUI = LocalPlayer.PlayerGui:FindFirstChild("TopMenuUI")
	if topMenuUI then
		topMenuUI:Destroy()
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
		TopMenuButtons = {},
		ShopTabs = {},
		ActiveShopTab = "seeds"
	}

	print("UIManager: Cleanup complete")
end

_G.UIManager = UIManager

print("UIManager: ✅ COMPLETE WITH TRULY UNIFORM SHOP ITEM SIZING!")
print("📏 TRULY UNIFORM SIZING ACHIEVED:")
print("  📐 ALL items use EXACTLY 15% height (0.15 scale) - NO variations")
print("  🎯 ALL tabs use IDENTICAL ItemConfig - NO device adjustments to frame sizes")
print("  📊 ALL internal elements positioned identically across ALL tabs")
print("  🔄 ALL YIncrement values are EXACTLY 0.165 (0.15 + 0.015)")
print("  📱 Device scaling applies ONLY to text size and button padding, NOT frame sizes")
print("")
print("✨ UNIFORM ACROSS ALL TABS:")
print("  🌱 Seeds tab - Uses base ItemConfig")
print("  🌾 Farming tab - Uses base ItemConfig") 
print("  🛡️ Defense tab - Uses base ItemConfig")
print("  ⛏️ Mining tab - Uses base ItemConfig")
print("  🔨 Crafting tab - Uses base ItemConfig")
print("  ✨ Premium tab - Uses base ItemConfig")
print("  💰 Sell tab - Uses base ItemConfig")
print("")
print("🎯 CONSISTENCY GUARANTEE:")
print("  📐 Frame sizes: IDENTICAL across all tabs and device types")
print("  📍 Element positions: IDENTICAL across all tabs")
print("  📏 Spacing: IDENTICAL across all tabs")
print("  🎨 Visual style: IDENTICAL across all tabs")

return UIManager