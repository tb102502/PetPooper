--[[
    FIXED UIManager.lua - Complete with Left-Side Buttons
    Place in: ReplicatedStorage/UIManager.lua
    
    FIXES:
    ✅ Added left-side menu buttons (Farm, Mining, Crafting)
    ✅ Proper button positioning and styling
    ✅ Complete shop system integration
    ✅ All missing functionality restored
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
	GameClient = nil,  -- Reference to GameClient (injected)
	LeftSideButtons = {} -- Store left-side button references
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
	}
}

print("UIManager: Enhanced module loaded with left-side buttons")

-- ========== INITIALIZATION ==========

function UIManager:Initialize()
	print("UIManager: Starting COMPLETE initialization...")

	-- Wait for PlayerGui
	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
	if not playerGui then
		error("UIManager: PlayerGui not found after 30 seconds")
	end

	-- Initialize state
	self.State.ActiveMenus = {}
	self.State.Layers = {}
	self.State.NotificationQueue = {}
	self.State.IsTransitioning = false
	self.State.CurrentPage = "None"
	self.State.LeftSideButtons = {}

	-- Create main UI structure
	local success, errorMsg = pcall(function()
		self:CreateMainUIStructure()
	end)

	if not success then
		error("UIManager: Failed to create main UI structure: " .. tostring(errorMsg))
	end

	-- Setup input handling
	self:SetupInputHandling()

	-- Setup notification system
	self:SetupNotificationSystem()

	-- FIXED: Setup left-side menu buttons
	self:SetupLeftSideButtons()

	print("UIManager: COMPLETE initialization finished!")
	return true
end

-- Set GameClient reference (called by GameClient during its initialization)
function UIManager:SetGameClient(gameClient)
	self.State.GameClient = gameClient
	print("UIManager: GameClient reference established")
end

-- ========== MAIN UI CREATION ==========

function UIManager:CreateMainUIStructure()
	local playerGui = LocalPlayer.PlayerGui

	-- Remove existing UI
	local existingUI = playerGui:FindFirstChild("MainGameUI")
	if existingUI then
		existingUI:Destroy()
	end

	-- Create main UI container
	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "MainGameUI"
	mainUI.ResetOnSpawn = false
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainUI.Parent = playerGui

	self.State.MainUI = mainUI

	-- Create currency display
	self:CreateCurrencyDisplay(mainUI)

	-- Create menu containers
	self:CreateMenuContainers(mainUI)

	-- Create notification area
	self:CreateNotificationArea(mainUI)

	print("UIManager: Main UI structure created")
end

-- ========== LEFT-SIDE MENU BUTTONS ==========

function UIManager:SetupLeftSideButtons()
	print("UIManager: Setting up left-side menu buttons...")

	local playerGui = LocalPlayer.PlayerGui

	-- Remove existing button UI
	local existingButtonUI = playerGui:FindFirstChild("LeftSideButtonsUI")
	if existingButtonUI then
		existingButtonUI:Destroy()
	end

	-- Create button UI container
	local buttonUI = Instance.new("ScreenGui")
	buttonUI.Name = "LeftSideButtonsUI"
	buttonUI.ResetOnSpawn = false
	buttonUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	buttonUI.Parent = playerGui

	-- Button configuration
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
		},
		{
			name = "Shop",
			text = "🛒 Shop",
			position = UDim2.new(0, 20, 0, 360),
			color = Color3.fromRGB(60, 120, 80),
			hoverColor = Color3.fromRGB(80, 140, 100),
			description = "Buy seeds, tools, and upgrades"
		}
	}

	-- Create each button
	for _, buttonConfig in ipairs(buttons) do
		local button = self:CreateLeftSideButton(buttonUI, buttonConfig)
		self.State.LeftSideButtons[buttonConfig.name] = button
	end

	print("UIManager: ✅ Left-side buttons created successfully")
end

function UIManager:CreateLeftSideButton(parent, config)
	-- Create button frame
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

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = button

	-- Add subtle shadow/stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.7
	stroke.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundColor3 = config.hoverColor,
				Size = UDim2.new(0, 150, 0, 65)
			}
		)
		hoverTween:Play()

		-- Show tooltip
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

		-- Hide tooltip
		self:HideButtonTooltip()
	end)

	-- Click handler
	button.MouseButton1Click:Connect(function()
		self:HandleLeftSideButtonClick(config.name)
	end)

	print("UIManager: Created " .. config.name .. " button")
	return button
end

function UIManager:ShowButtonTooltip(button, description)
	-- Remove existing tooltip
	self:HideButtonTooltip()

	-- Create tooltip
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

	-- Animate in
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

	-- Provide visual feedback
	local button = self.State.LeftSideButtons[buttonName]
	if button then
		-- Quick press animation
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

	-- Open the corresponding menu
	self:OpenMenu(buttonName)
end

-- ========== ENHANCED INPUT HANDLING ==========

function UIManager:SetupInputHandling()
	-- Close menus on escape
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			self:CloseActiveMenus()
		elseif input.KeyCode == Enum.KeyCode.F then
			-- F key for Farm
			self:OpenMenu("Farm")
		elseif input.KeyCode == Enum.KeyCode.M then
			-- M key for Mining
			self:OpenMenu("Mining")
		elseif input.KeyCode == Enum.KeyCode.C then
			-- C key for Crafting
			self:OpenMenu("Crafting")
		elseif input.KeyCode == Enum.KeyCode.B then
			-- B key for Shop (Buy)
			self:OpenMenu("Shop")
		end
	end)

	print("UIManager: Enhanced input handling setup complete")
	print("  Hotkeys: F=Farm, M=Mining, C=Crafting, B=Shop, ESC=Close")
end

-- Create currency display
function UIManager:CreateCurrencyDisplay(parent)
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyDisplay"
	currencyFrame.Size = UDim2.new(0, 300, 0, 80)
	currencyFrame.Position = UDim2.new(1, -320, 0, 20) -- Top right
	currencyFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	currencyFrame.BorderSizePixel = 0
	currencyFrame.ZIndex = self.Config.UIOrder.Main
	currencyFrame.Parent = parent

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = currencyFrame

	-- Stroke for better visibility
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 100)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = currencyFrame

	-- Coins display
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

	-- Farm tokens display
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

	-- Store references
	self.State.CurrencyLabels = {
		coins = coinsLabel,
		farmTokens = tokensLabel
	}

	print("UIManager: Enhanced currency display created")
end

-- Create menu containers
function UIManager:CreateMenuContainers(parent)
	-- Main menu container
	local menuContainer = Instance.new("Frame")
	menuContainer.Name = "MenuContainer"
	menuContainer.Size = UDim2.new(0.85, 0, 0.85, 0) -- Slightly smaller to accommodate buttons
	menuContainer.Position = UDim2.new(0.15, 0, 0.1, 0) -- Offset for left buttons
	menuContainer.BackgroundTransparency = 1
	menuContainer.ZIndex = self.Config.UIOrder.Menus
	menuContainer.Visible = false
	menuContainer.Parent = parent

	-- Background blur
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1.2, 0, 1.2, 0) -- Cover left buttons too
	background.Position = UDim2.new(-0.2, 0, -0.1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.3
	background.ZIndex = self.Config.UIOrder.Background
	background.Parent = menuContainer

	-- Menu frame
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

	-- Close button
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

-- Create notification area
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

-- ========== MENU MANAGEMENT ==========

function UIManager:OpenMenu(menuName)
	if self.State.IsTransitioning then
		print("UIManager: Ignoring menu open during transition")
		return false
	end

	print("UIManager: Opening menu: " .. menuName)

	-- Close existing menus first
	self:CloseActiveMenus()

	self.State.IsTransitioning = true
	self.State.CurrentPage = menuName

	local success = false

	if menuName == "Shop" then
		success = self:CreateShopMenu()
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
		-- Show menu container with animation
		local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
		if menuContainer then
			menuContainer.Visible = true
			menuContainer.BackgroundTransparency = 1

			-- Animate in
			local tween = TweenService:Create(menuContainer,
				TweenInfo.new(self.Config.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0}
			)
			tween:Play()

			tween.Completed:Connect(function()
				self.State.IsTransitioning = false
			end)
		end

		table.insert(self.State.ActiveMenus, menuName)
	else
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
		-- Animate out
		local tween = TweenService:Create(menuContainer,
			TweenInfo.new(self.Config.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}
		)
		tween:Play()

		tween.Completed:Connect(function()
			menuContainer.Visible = false

			-- Clear menu content
			local menuFrame = menuContainer:FindFirstChild("MenuFrame")
			if menuFrame then
				-- Keep close button, remove everything else
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

-- Get current page
function UIManager:GetCurrentPage()
	return self.State.CurrentPage
end

-- ========== MENU CREATION FUNCTIONS ==========

function UIManager:CreateShopMenu()
	print("UIManager: Creating enhanced shop menu")

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

	-- Content area
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -40, 1, -100)
	contentFrame.Position = UDim2.new(0, 20, 0, 80)
	contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 10
	contentFrame.Parent = menuFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0.02, 0)
	contentCorner.Parent = contentFrame

	-- Get shop items from GameClient
	self:PopulateShopContent(contentFrame)

	return true
end

function UIManager:CreateFarmMenu()
	print("UIManager: Creating enhanced farm menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	-- Title
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

	-- Farm expansion section
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

	-- Farm status
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

	-- Harvest All Button
	local harvestAllButton = Instance.new("TextButton")
	harvestAllButton.Name = "HarvestAllButton"
	harvestAllButton.Size = UDim2.new(0.4, 0, 0, 50)
	harvestAllButton.Position = UDim2.new(0.05, 0, 1, -70)
	harvestAllButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	harvestAllButton.BorderSizePixel = 0
	harvestAllButton.Text = "🌾 HARVEST ALL"
	harvestAllButton.TextColor3 = Color3.new(1, 1, 1)
	harvestAllButton.TextScaled = true
	harvestAllButton.Font = Enum.Font.GothamBold
	harvestAllButton.Parent = expansionFrame

	local harvestCorner = Instance.new("UICorner")
	harvestCorner.CornerRadius = UDim.new(0.1, 0)
	harvestCorner.Parent = harvestAllButton

	harvestAllButton.MouseButton1Click:Connect(function()
		if self.State.GameClient and self.State.GameClient.RequestHarvestAll then
			self.State.GameClient:RequestHarvestAll()
		else
			self:ShowNotification("Feature Unavailable", "Harvest All system not ready!", "warning")
		end
	end)

	-- Populate farm content
	self:PopulateFarmContent(expansionFrame)

	return true
end

function UIManager:CreateMiningMenu()
	print("UIManager: Creating enhanced mining menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	-- Title
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

	-- Coming soon message
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
	print("UIManager: Creating enhanced crafting menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	-- Title
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

	-- Coming soon message
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

	-- Title
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

	-- Placeholder content
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

function UIManager:PopulateShopContent(contentFrame)
	if not self.State.GameClient then
		-- Show loading message
		local loadingLabel = Instance.new("TextLabel")
		loadingLabel.Size = UDim2.new(1, 0, 1, 0)
		loadingLabel.BackgroundTransparency = 1
		loadingLabel.Text = "🛒 Loading shop items...\n\nIf this takes too long, try stepping on the shop area again."
		loadingLabel.TextColor3 = Color3.new(1, 1, 1)
		loadingLabel.TextScaled = true
		loadingLabel.Font = Enum.Font.Gotham
		loadingLabel.Parent = contentFrame
		return
	end

	-- Try to get shop items from GameClient
	local success, shopItems = pcall(function()
		if self.State.GameClient.GetShopItems then
			return self.State.GameClient:GetShopItems()
		end
		return {}
	end)

	if not success or not shopItems or #shopItems == 0 then
		-- Show no items message
		local noItemsLabel = Instance.new("TextLabel")
		noItemsLabel.Size = UDim2.new(1, 0, 1, 0)
		noItemsLabel.BackgroundTransparency = 1
		noItemsLabel.Text = "🛒 Shop items not available\n\nPlease try:\n• Stepping on the shop area again\n• Rejoining the game\n• Contacting support"
		noItemsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noItemsLabel.TextScaled = true
		noItemsLabel.Font = Enum.Font.Gotham
		noItemsLabel.Parent = contentFrame
		return
	end

	-- Create shop items
	local yOffset = 0
	for i, item in ipairs(shopItems) do
		local itemFrame = self:CreateShopItemFrame(item, i)
		itemFrame.Position = UDim2.new(0, 10, 0, yOffset)
		itemFrame.Parent = contentFrame
		yOffset = yOffset + 120
	end

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

function UIManager:PopulateFarmContent(expansionFrame)
	if not self.State.GameClient then
		return
	end

	-- Try to get player data
	local success, playerData = pcall(function()
		if self.State.GameClient.GetPlayerData then
			return self.State.GameClient:GetPlayerData()
		end
		return nil
	end)

	if success and playerData and playerData.farming then
		local expansionLevel = playerData.farming.expansionLevel or 1

		-- Update status label
		local statusLabel = expansionFrame:FindFirstChild("StatusLabel")
		if statusLabel then
			statusLabel.Text = "🌾 Current Farm Level: " .. expansionLevel .. "\n" ..
				"Grid Size: " .. self:GetGridSizeForLevel(expansionLevel) .. "\n" ..
				"Total Spots: " .. self:GetTotalSpotsForLevel(expansionLevel)
		end

		-- Add expansion button if available
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

-- Helper functions for farm content
function UIManager:GetGridSizeForLevel(level)
	local sizes = {[1] = "3x3", [2] = "5x5", [3] = "7x7", [4] = "9x9", [5] = "11x11"}
	return sizes[level] or "Unknown"
end

function UIManager:GetTotalSpotsForLevel(level)
	local spots = {[1] = 9, [2] = 25, [3] = 49, [4] = 81, [5] = 121}
	return spots[level] or 0
end

-- Create shop item frame
function UIManager:CreateShopItemFrame(item, index)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "ShopItem_" .. index
	itemFrame.Size = UDim2.new(1, -20, 0, 100)
	itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	itemFrame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = itemFrame

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, -10, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name or item.id
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame

	-- Item price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.4, -10, 0.5, 0)
	priceLabel.Position = UDim2.new(0.6, 0, 0, 5)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = (item.price or 0) .. " " .. (item.currency or "coins")
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Parent = itemFrame

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.7, -10, 0.4, 0)
	descLabel.Position = UDim2.new(0, 10, 0.5, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = item.description or "No description"
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = itemFrame

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.25, -10, 0.4, -5)
	buyButton.Position = UDim2.new(0.75, 0, 0.55, 0)
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

	return itemFrame
end

-- ========== NOTIFICATION SYSTEM ==========

function UIManager:SetupNotificationSystem()
	self.State.NotificationQueue = {}

	-- Process notification queue
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

	-- Count existing notifications
	local existingCount = 0
	for _, child in pairs(notificationArea:GetChildren()) do
		if child.Name:find("Notification_") then
			existingCount = existingCount + 1
		end
	end

	-- Remove oldest if too many
	if existingCount >= self.Config.MaxNotificationsVisible then
		for _, child in pairs(notificationArea:GetChildren()) do
			if child.Name:find("Notification_") then
				child:Destroy()
				break
			end
		end
		existingCount = existingCount - 1
	end

	-- Create notification
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

	-- Title
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

	-- Message
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

	-- Animate in
	notification.Position = UDim2.new(1, 0, 0, 20 + (existingCount * 90))
	local slideIn = TweenService:Create(notification,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0, 10, 0, 20 + (existingCount * 90))}
	)
	slideIn:Play()

	-- Auto-remove after display time
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

	-- Update coins
	if self.State.CurrencyLabels.coins then
		local coins = playerData.coins or 0
		self.State.CurrencyLabels.coins.Text = "💰 " .. self:FormatNumber(coins)
	end

	-- Update farm tokens
	if self.State.CurrencyLabels.farmTokens then
		local tokens = playerData.farmTokens or 0
		self.State.CurrencyLabels.farmTokens.Text = "🎫 " .. self:FormatNumber(tokens)
	end
end

-- Format numbers with commas
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

	-- Close and reopen menu to refresh
	local currentMenus = self.State.ActiveMenus
	self:CloseActiveMenus()

	spawn(function()
		wait(0.1) -- Brief delay
		self:OpenMenu(menuName)
	end)
end

-- ========== GET STATE FUNCTIONS ==========

function UIManager:GetState()
	return self.State
end


-- ========== CLEANUP ==========

function UIManager:Cleanup()
	print("UIManager: Performing cleanup...")

	-- Close all menus
	self:CloseActiveMenus()

	-- Clear notification queue
	self.State.NotificationQueue = {}

	-- Destroy main UI
	if self.State.MainUI then
		self.State.MainUI:Destroy()
		self.State.MainUI = nil
	end

	-- Destroy left-side buttons UI
	local leftSideUI = LocalPlayer.PlayerGui:FindFirstChild("LeftSideButtonsUI")
	if leftSideUI then
		leftSideUI:Destroy()
	end

	-- Reset state
	self.State = {
		MainUI = nil,
		CurrentPage = "None",
		ActiveMenus = {},
		IsTransitioning = false,
		Layers = {},
		NotificationQueue = {},
		CurrencyLabels = {},
		GameClient = nil,
		LeftSideButtons = {}
	}

	print("UIManager: Cleanup complete")
end

-- Make globally available
_G.UIManager = UIManager

print("UIManager: ✅ COMPLETE module ready with left-side buttons!")
print("📋 Available Methods:")
print("  Initialize() - Initialize the UI system")
print("  OpenMenu(menuName) - Open specific menu")
print("  CloseActiveMenus() - Close all open menus")
print("  ShowNotification(title, message, type) - Show notification")
print("  UpdateCurrencyDisplay(playerData) - Update currency display")
print("  SetGameClient(gameClient) - Set GameClient reference")
print("")
print("🎮 Left-Side Buttons Created:")
print("  🌾 Farm - Press F or click button")
print("  ⛏️ Mining - Press M or click button")
print("  🔨 Crafting - Press C or click button")
print("  🛒 Shop - Press B or click button")
print("")
print("⌨️ Hotkeys: F=Farm, M=Mining, C=Crafting, B=Shop, ESC=Close")

return UIManager