--[[
    UIController.lua
    Central UI management system for PetPooper
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
]]

local UIController = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Constants
UIController.Config = {
	DefaultTransitionTime = 0.3,
	DefaultEasingStyle = Enum.EasingStyle.Quad,
	DefaultEasingDirection = Enum.EasingDirection.Out,
	MenuOpenSound = "rbxassetid://3852850565",
	ButtonClickSound = "rbxassetid://3852111441",
	NotificationSound = "rbxassetid://3852494735"
}

-- State
UIController.State = {
	ActiveMenus = {},
	CurrentPage = nil,
	IsTransitioning = false,
	IsUILocked = false
}

-- Cache
UIController.Cache = {
	UIElements = {},
	EventConnections = {},
	SoundInstances = {}
}

-- Initialize UI Controller
function UIController:Initialize()
	print("UIController: Initializing...")

	-- Set up the main UI
	self:SetupMainUI()

	-- Connect to external systems
	self:ConnectExternalSystems()

	-- Set up sounds
	self:SetupSounds()

	-- Set up input handling
	self:SetupInputHandling()

	-- Create animation presets
	self:CreateAnimationPresets()

	-- Set up currency display
	self:SetupCurrencyDisplay()

	print("UIController: Initialization complete")
	return true
end

-- Set up the main UI structure
function UIController:SetupMainUI()
	-- Get the player GUI
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Look for existing UI or create one
	local mainUI = playerGui:FindFirstChild("MainUI")

	if not mainUI then
		-- Create the main UI
		mainUI = Instance.new("ScreenGui")
		mainUI.Name = "MainUI"
		mainUI.ResetOnSpawn = false
		mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		mainUI.Parent = playerGui

		-- Create UI structure
		self:CreateUIStructure(mainUI)
	end

	-- Cache the UI
	self.Cache.UIElements.MainUI = mainUI

	-- Set up layers for proper rendering
	self:SetupUILayers(mainUI)
end

-- Create the basic UI structure
function UIController:CreateUIStructure(parent)
	-- Main container that holds all other elements
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent
	self.Cache.UIElements.Container = container

	-- Create UI layers
	local layers = {
		"Background", -- Background elements like images
		"Content",    -- Main content of menus and pages
		"Navigation", -- Navigation elements like tabs and buttons
		"Overlay",    -- Overlay elements like confirmations
		"Notification" -- Notification elements on top of everything
	}

	for _, layerName in ipairs(layers) do
		local layer = Instance.new("Frame")
		layer.Name = layerName
		layer.Size = UDim2.new(1, 0, 1, 0)
		layer.BackgroundTransparency = 1
		layer.Parent = container
		self.Cache.UIElements[layerName] = layer
	end

	-- Create main menu buttons
	self:CreateMainMenuButtons()
end

-- Set up proper UI layers for rendering order
function UIController:SetupUILayers(mainUI)
	-- Set ZIndex for proper rendering
	local layers = {
		Background = 1,
		Content = 2,
		Navigation = 3,
		Overlay = 4,
		Notification = 5
	}

	for name, zIndex in pairs(layers) do
		local layer = self.Cache.UIElements[name]
		if layer then
			layer.ZIndex = zIndex
		end
	end
end

-- Create main menu buttons
function UIController:CreateMainMenuButtons()
	local navLayer = self.Cache.UIElements.Navigation

	-- Create a navigation bar
	local navBar = Instance.new("Frame")
	navBar.Name = "NavigationBar"
	navBar.Size = UDim2.new(1, 0, 0.08, 0)
	navBar.Position = UDim2.new(0, 0, 0.92, 0)
	navBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	navBar.BorderSizePixel = 0
	navBar.Parent = navLayer
	self.Cache.UIElements.NavigationBar = navBar

	-- Create main buttons
	local buttons = {
		{name = "Pets", icon = "rbxassetid://6031302950"},
		{name = "Shop", icon = "rbxassetid://6031265976"},
		{name = "Inventory", icon = "rbxassetid://6026568198"},
		{name = "Settings", icon = "rbxassetid://6031280882"}
	}

	local buttonWidth = 1 / #buttons

	for i, buttonInfo in ipairs(buttons) do
		local button = self:CreateButton(
			buttonInfo.name,
			UDim2.new(buttonWidth, 0, 1, 0),
			UDim2.new((i-1) * buttonWidth, 0, 0, 0),
			buttonInfo.icon
		)
		button.Parent = navBar
		self.Cache.UIElements[buttonInfo.name .. "Button"] = button

		-- Connect button click
		button.MouseButton1Click:Connect(function()
			self:OpenMenu(buttonInfo.name)
		end)
	end
end

-- Create a standard button
function UIController:CreateButton(name, size, position, icon)
	local button = Instance.new("ImageButton")
	button.Name = name .. "Button"
	button.Size = size
	button.Position = position
	button.BackgroundTransparency = 1
	button.Image = ""

	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	background.BorderSizePixel = 0
	background.Parent = button

	-- Icon
	local iconImage = Instance.new("ImageLabel")
	iconImage.Name = "Icon"
	iconImage.Size = UDim2.new(0.5, 0, 0.5, 0)
	iconImage.Position = UDim2.new(0.25, 0, 0.15, 0)
	iconImage.BackgroundTransparency = 1
	iconImage.Image = icon
	iconImage.Parent = button

	-- Text
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.new(1, 0, 0.3, 0)
	text.Position = UDim2.new(0, 0, 0.65, 0)
	text.BackgroundTransparency = 1
	text.Text = name
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.SourceSansSemibold
	text.Parent = button

	-- Hover effect
	button.MouseEnter:Connect(function()
		TweenService:Create(
			background,
			TweenInfo.new(0.2),
			{BackgroundColor3 = Color3.fromRGB(65, 65, 75)}
		):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(
			background,
			TweenInfo.new(0.2),
			{BackgroundColor3 = Color3.fromRGB(45, 45, 55)}
		):Play()
	end)

	return button
end

-- Connect to external systems
function UIController:ConnectExternalSystems()
	-- Connect to Pet System
	self:ConnectPetSystem()

	-- Connect to Shop System
	self:ConnectShopSystem()
end

-- Connect to the Pet System
function UIController:ConnectPetSystem()
	-- Get the pet system client
	local petSystem = _G.PetSystemClient

	if not petSystem then
		warn("UIController: PetSystemClient not found in _G")
		return
	end

	-- Connect to pet system events
	if petSystem.OnPetsUpdated then
		petSystem.OnPetsUpdated:Connect(function(petData)
			self:UpdatePetUI(petData)
		end)
	end

	if petSystem.OnPetEquipped then
		petSystem.OnPetEquipped:Connect(function(petId, petData)
			self:ShowNotification("Pet Equipped", petData.name .. " has been equipped!")
		end)
	end

	if petSystem.OnPetUnequipped then
		petSystem.OnPetUnequipped:Connect(function(petId)
			self:ShowNotification("Pet Unequipped", "Pet has been unequipped.")
		end)
	end

	if petSystem.OnPetLevelUp then
		petSystem.OnPetLevelUp:Connect(function(petId, level, stats)
			self:ShowNotification("Level Up!", "Pet reached level " .. tostring(level) .. "!")
		end)
	end

	print("UIController: Connected to PetSystemClient")
end

-- Connect to the Shop System
function UIController:ConnectShopSystem()
	-- Get the shop system client
	local shopSystem = _G.ShopSystemClient

	if not shopSystem then
		warn("UIController: ShopSystemClient not found in _G")
		return
	end

	-- Connect to shop system events
	if shopSystem.OnCurrencyUpdated then
		shopSystem.OnCurrencyUpdated:Connect(function(currencyData)
			self:UpdateCurrencyUI(currencyData)
		end)
	end

	if shopSystem.OnItemPurchased then
		shopSystem.OnItemPurchased:Connect(function(item, quantity)
			self:ShowNotification("Purchased", "You bought " .. quantity .. " " .. item.name .. "!")
		end)
	end

	if shopSystem.OnPremiumPurchased then
		shopSystem.OnPremiumPurchased:Connect(function(currencyType, amount)
			self:ShowNotification("Purchase Complete", "Added " .. amount .. " " .. currencyType .. " to your account!")
		end)
	end

	if shopSystem.OnShopItemsLoaded then
		shopSystem.OnShopItemsLoaded:Connect(function(items)
			self:UpdateShopUI(items)
		end)
	end

	print("UIController: Connected to ShopSystemClient")
end

-- Set up sound effects
function UIController:SetupSounds()
	local sounds = {
		MenuOpen = self.Config.MenuOpenSound,
		ButtonClick = self.Config.ButtonClickSound,
		Notification = self.Config.NotificationSound
	}

	for name, id in pairs(sounds) do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = id
		sound.Volume = 0.5
		sound.Parent = self.Cache.UIElements.MainUI
		self.Cache.SoundInstances[name] = sound
	end
end

-- Set up input handling
function UIController:SetupInputHandling()
	-- Handle key presses
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Handle escape key to close menus
		if input.KeyCode == Enum.KeyCode.Escape then
			self:CloseActiveMenu()
		end
	end)
end

-- Create animation presets
function UIController:CreateAnimationPresets()
	self.Animations = {
		FadeIn = function(object, duration)
			return TweenService:Create(
				object,
				TweenInfo.new(duration or self.Config.DefaultTransitionTime, self.Config.DefaultEasingStyle, self.Config.DefaultEasingDirection),
				{BackgroundTransparency = 0}
			)
		end,

		FadeOut = function(object, duration)
			return TweenService:Create(
				object,
				TweenInfo.new(duration or self.Config.DefaultTransitionTime, self.Config.DefaultEasingStyle, self.Config.DefaultEasingDirection),
				{BackgroundTransparency = 1}
			)
		end,

		SlideIn = function(object, fromPosition, toPosition, duration)
			return TweenService:Create(
				object,
				TweenInfo.new(duration or self.Config.DefaultTransitionTime, self.Config.DefaultEasingStyle, self.Config.DefaultEasingDirection),
				{Position = toPosition}
			)
		end,

		SlideOut = function(object, fromPosition, toPosition, duration)
			return TweenService:Create(
				object,
				TweenInfo.new(duration or self.Config.DefaultTransitionTime, self.Config.DefaultEasingStyle, self.Config.DefaultEasingDirection),
				{Position = toPosition}
			)
		end,

		Scale = function(object, fromScale, toScale, duration)
			return TweenService:Create(
				object,
				TweenInfo.new(duration or self.Config.DefaultTransitionTime, self.Config.DefaultEasingStyle, self.Config.DefaultEasingDirection),
				{Scale = toScale}
			)
		end
	}
end

-- Create and set up the currency display
function UIController:SetupCurrencyDisplay()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local mainUI = playerGui:FindFirstChild("MainUI")

	if not mainUI then 
		warn("UIController: MainUI not found, cannot set up currency display")
		return 
	end

	-- Check if the module is available
	local success, CurrencyDisplay
	success, CurrencyDisplay = pcall(function()
		return require(ReplicatedStorage:WaitForChild("CurrencyDisplay", 5))
	end)

	if not success then
		warn("UIController: Failed to load CurrencyDisplay module: " .. tostring(CurrencyDisplay))
		return
	end

	-- Initialize the currency display
	local initSuccess, errorMsg = pcall(function()
		CurrencyDisplay:Initialize(mainUI)
	end)

	if initSuccess then
		print("UIController: Currency display successfully set up")
	else
		warn("UIController: Error initializing currency display: " .. tostring(errorMsg))
	end
end

-- Open a menu by name
function UIController:OpenMenu(menuName)
	if self.State.IsTransitioning then return end
	self.State.IsTransitioning = true

	-- Close the current menu first
	self:CloseActiveMenu(function()
		-- Play sound
		local sound = self.Cache.SoundInstances.MenuOpen
		if sound then
			sound:Play()
		end

		-- Create the menu if it doesn't exist
		local menu = self:GetOrCreateMenu(menuName)

		-- Show the menu
		menu.Visible = true

		-- Add to active menus
		self.State.ActiveMenus[menuName] = menu
		self.State.CurrentPage = menuName

		-- Animate menu opening
		local startPosition = UDim2.new(0.5, 0, 1.2, 0)
		local endPosition = UDim2.new(0.5, 0, 0.5, 0)

		menu.Position = startPosition

		local tween = TweenService:Create(
			menu,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Position = endPosition}
		)

		tween:Play()

		tween.Completed:Wait()
		self.State.IsTransitioning = false

		-- Refresh the menu content
		self:RefreshMenuContent(menuName)
	end)
end

-- Close the active menu
function UIController:CloseActiveMenu(callback)
	if not self.State.CurrentPage then
		-- No active menu to close
		if callback then
			callback()
		end
		return
	end

	local menuName = self.State.CurrentPage
	local menu = self.State.ActiveMenus[menuName]

	if not menu then
		-- Menu doesn't exist
		self.State.CurrentPage = nil
		if callback then
			callback()
		end
		return
	end

	-- Animate menu closing
	local startPosition = menu.Position
	local endPosition = UDim2.new(0.5, 0, 1.2, 0)

	local tween = TweenService:Create(
		menu,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = endPosition}
	)

	tween:Play()

	tween.Completed:Connect(function()
		menu.Visible = false
		self.State.ActiveMenus[menuName] = nil
		self.State.CurrentPage = nil

		if callback then
			callback()
		end
	end)
end

-- Get or create a menu
function UIController:GetOrCreateMenu(menuName)
	local contentLayer = self.Cache.UIElements.Content
	local existingMenu = contentLayer:FindFirstChild(menuName .. "Menu")

	if existingMenu then
		return existingMenu
	end

	-- Create a new menu
	local menu = Instance.new("Frame")
	menu.Name = menuName .. "Menu"
	menu.Size = UDim2.new(0.9, 0, 0.8, 0)
	menu.Position = UDim2.new(0.5, 0, 0.5, 0)
	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.Parent = contentLayer

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = menu

	-- Add title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	title.BorderSizePixel = 0
	title.Text = menuName
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansSemibold
	title.Parent = menu

	-- Add title corner rounding
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = title

	-- Add close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	closeButton.Position = UDim2.new(0.96, 0, 0.02, 0)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansSemibold
	closeButton.Parent = menu

	-- Add close button corner rounding
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		local sound = self.Cache.SoundInstances.ButtonClick
		if sound then
			sound:Play()
		end
		self:CloseActiveMenu()
	end)

	-- Create content container
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(0.95, 0, 0.85, 0)
	content.Position = UDim2.new(0.5, 0, 0.55, 0)
	content.AnchorPoint = Vector2.new(0.5, 0.5)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	content.Parent = menu

	-- Set up specific menu content
	self:SetupMenuContent(menuName, content)

	return menu
end

-- Set up menu content based on menu type
function UIController:SetupMenuContent(menuName, contentFrame)
	if menuName == "Pets" then
		self:SetupPetsMenu(contentFrame)
	elseif menuName == "Shop" then
		self:SetupShopMenu(contentFrame)
	elseif menuName == "Inventory" then
		self:SetupInventoryMenu(contentFrame)
	elseif menuName == "Settings" then
		self:SetupSettingsMenu(contentFrame)
	end
end

-- Refresh menu content based on current data
function UIController:RefreshMenuContent(menuName)
	if menuName == "Pets" then
		self:RefreshPetsMenu()
	elseif menuName == "Shop" then
		self:RefreshShopMenu()
	elseif menuName == "Inventory" then
		self:RefreshInventoryMenu()
	elseif menuName == "Settings" then
		self:RefreshSettingsMenu()
	end
end

-- Refresh the Pets menu
function UIController:RefreshPetsMenu()
	self:SwitchPetsTab("Equipped") -- Start with the equipped tab
end

-- Refresh the Shop menu
function UIController:RefreshShopMenu()
	self:SwitchShopTab("Eggs") -- Start with the eggs tab
end

-- Set up the Pets menu
function UIController:SetupPetsMenu(contentFrame)
	-- Create tabs at the top
	local tabsContainer = Instance.new("Frame")
	tabsContainer.Name = "Tabs"
	tabsContainer.Size = UDim2.new(1, 0, 0.08, 0)
	tabsContainer.BackgroundTransparency = 1
	tabsContainer.Parent = contentFrame

	local tabs = {
		"Equipped",
		"Collection"
	}

	local tabWidth = 1 / #tabs

	for i, tabName in ipairs(tabs) do
		local tab = Instance.new("TextButton")
		tab.Name = tabName .. "Tab"
		tab.Size = UDim2.new(tabWidth, 0, 1, 0)
		tab.Position = UDim2.new((i-1) * tabWidth, 0, 0, 0)
		tab.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		tab.BorderSizePixel = 0
		tab.Text = tabName
		tab.TextColor3 = Color3.new(1, 1, 1)
		tab.TextScaled = true
		tab.Font = Enum.Font.SourceSansSemibold
		tab.Parent = tabsContainer

		-- Selected indicator
		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.Size = UDim2.new(1, 0, 0.1, 0)
		indicator.Position = UDim2.new(0, 0, 0.9, 0)
		indicator.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		indicator.BorderSizePixel = 0
		indicator.Visible = (i == 1) -- First tab is active by default
		indicator.Parent = tab

		-- Connect tab click
		tab.MouseButton1Click:Connect(function()
			self:SwitchPetsTab(tabName)
		end)
	end

	-- Create pet display container
	local petsContainer = Instance.new("Frame")
	petsContainer.Name = "PetsContainer"
	petsContainer.Size = UDim2.new(1, 0, 0.9, 0)
	petsContainer.Position = UDim2.new(0, 0, 0.1, 0)
	petsContainer.BackgroundTransparency = 1
	petsContainer.Parent = contentFrame

	-- Create containers for each tab
	local equippedContainer = Instance.new("Frame")
	equippedContainer.Name = "EquippedContainer"
	equippedContainer.Size = UDim2.new(1, 0, 1, 0)
	equippedContainer.BackgroundTransparency = 1
	equippedContainer.Parent = petsContainer

	local collectionContainer = Instance.new("Frame")
	collectionContainer.Name = "CollectionContainer"
	collectionContainer.Size = UDim2.new(1, 0, 1, 0)
	collectionContainer.BackgroundTransparency = 1
	collectionContainer.Visible = false
	collectionContainer.Parent = petsContainer
end

-- Set up the Shop menu
function UIController:SetupShopMenu(contentFrame)
	-- Create tabs at the top
	local tabsContainer = Instance.new("Frame")
	tabsContainer.Name = "Tabs"
	tabsContainer.Size = UDim2.new(1, 0, 0.08, 0)
	tabsContainer.BackgroundTransparency = 1
	tabsContainer.Parent = contentFrame

	local tabs = {
		"Eggs",
		"Boosters",
		"Currency"
	}

	local tabWidth = 1 / #tabs

	for i, tabName in ipairs(tabs) do
		local tab = Instance.new("TextButton")
		tab.Name = tabName .. "Tab"
		tab.Size = UDim2.new(tabWidth, 0, 1, 0)
		tab.Position = UDim2.new((i-1) * tabWidth, 0, 0, 0)
		tab.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		tab.BorderSizePixel = 0
		tab.Text = tabName
		tab.TextColor3 = Color3.new(1, 1, 1)
		tab.TextScaled = true
		tab.Font = Enum.Font.SourceSansSemibold
		tab.Parent = tabsContainer

		-- Selected indicator
		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.Size = UDim2.new(1, 0, 0.1, 0)
		indicator.Position = UDim2.new(0, 0, 0.9, 0)
		indicator.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		indicator.BorderSizePixel = 0
		indicator.Visible = (i == 1) -- First tab is active by default
		indicator.Parent = tab

		-- Connect tab click
		tab.MouseButton1Click:Connect(function()
			self:SwitchShopTab(tabName)
		end)
	end

	-- Create shop items container
	local shopContainer = Instance.new("Frame")
	shopContainer.Name = "ShopContainer"
	shopContainer.Size = UDim2.new(1, 0, 0.9, 0)
	shopContainer.Position = UDim2.new(0, 0, 0.1, 0)
	shopContainer.BackgroundTransparency = 1
	shopContainer.Parent = contentFrame

	-- Create containers for each tab
	local eggsContainer = Instance.new("Frame")
	eggsContainer.Name = "EggsContainer"
	eggsContainer.Size = UDim2.new(1, 0, 1, 0)
	eggsContainer.BackgroundTransparency = 1
	eggsContainer.Parent = shopContainer

	local boostersContainer = Instance.new("Frame")
	boostersContainer.Name = "BoostersContainer"
	boostersContainer.Size = UDim2.new(1, 0, 1, 0)
	boostersContainer.BackgroundTransparency = 1
	boostersContainer.Visible = false
	boostersContainer.Parent = shopContainer

	local currencyContainer = Instance.new("Frame")
	currencyContainer.Name = "CurrencyContainer"
	currencyContainer.Size = UDim2.new(1, 0, 1, 0)
	currencyContainer.BackgroundTransparency = 1
	currencyContainer.Visible = false
	currencyContainer.Parent = shopContainer
end

-- Set up the Inventory menu
function UIController:SetupInventoryMenu(contentFrame)
	-- Simple container for items
	local itemsContainer = Instance.new("Frame")
	itemsContainer.Name = "ItemsContainer"
	itemsContainer.Size = UDim2.new(1, 0, 1, 0)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.Parent = contentFrame

	-- Placeholder text
	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(0.8, 0, 0.2, 0)
	placeholder.Position = UDim2.new(0.5, 0, 0.4, 0)
	placeholder.AnchorPoint = Vector2.new(0.5, 0.5)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "Inventory Coming Soon"
	placeholder.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.SourceSansSemibold
	placeholder.Parent = itemsContainer
end

-- Set up the Settings menu
function UIController:SetupSettingsMenu(contentFrame)
	-- Create settings container
	local settingsContainer = Instance.new("Frame")
	settingsContainer.Name = "SettingsContainer"
	settingsContainer.Size = UDim2.new(1, 0, 1, 0)
	settingsContainer.BackgroundTransparency = 1
	settingsContainer.Parent = contentFrame

	-- Create settings list
	local settingsList = {
		{name = "Music", type = "toggle", default = true},
		{name = "Sound Effects", type = "toggle", default = true},
		{name = "Hide Pets", type = "toggle", default = false},
		{name = "Graphics Quality", type = "slider", min = 1, max = 10, default = 5},
		{name = "Delete Save Data", type = "button", danger = true}
	}

	local yOffset = 0.05
	local spacing = 0.12

	for i, setting in ipairs(settingsList) do
		local position = UDim2.new(0.05, 0, yOffset + (i-1) * spacing, 0)

		self:CreateSettingUI(setting, position, settingsContainer)
	end
end

-- Create a setting UI element
function UIController:CreateSettingUI(setting, position, parent)
	local container = Instance.new("Frame")
	container.Name = setting.name .. "Setting"
	container.Size = UDim2.new(0.9, 0, 0.1, 0)
	container.Position = position
	container.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	container.BorderSizePixel = 0
	container.Parent = parent

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = container

	-- Add label
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.6, 0, 0.8, 0)
	label.Position = UDim2.new(0.05, 0, 0.1, 0)
	label.BackgroundTransparency = 1
	label.Text = setting.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.SourceSansSemibold
	label.Parent = container

	-- Add control based on type
	if setting.type == "toggle" then
		local toggle = Instance.new("Frame")
		toggle.Name = "Toggle"
		toggle.Size = UDim2.new(0.12, 0, 0.7, 0)
		toggle.Position = UDim2.new(0.85, 0, 0.15, 0)
		toggle.BackgroundColor3 = setting.default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 110)
		toggle.BorderSizePixel = 0
		toggle.Parent = container

		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(0.5, 0)
		toggleCorner.Parent = toggle

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0.5, 0, 1, 0)
		knob.Position = setting.default and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.Parent = toggle

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(0.5, 0)
		knobCorner.Parent = knob

		-- Make clickable
		container.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:ToggleSetting(setting.name, toggle, knob)
			end
		end)
	elseif setting.type == "slider" then
		local sliderBack = Instance.new("Frame")
		sliderBack.Name = "SliderBack"
		sliderBack.Size = UDim2.new(0.3, 0, 0.3, 0)
		sliderBack.Position = UDim2.new(0.65, 0, 0.35, 0)
		sliderBack.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		sliderBack.BorderSizePixel = 0
		sliderBack.Parent = container

		local sliderBackCorner = Instance.new("UICorner")
		sliderBackCorner.CornerRadius = UDim.new(0.5, 0)
		sliderBackCorner.Parent = sliderBack

		local sliderFill = Instance.new("Frame")
		sliderFill.Name = "SliderFill"
		sliderFill.Size = UDim2.new(setting.default / setting.max, 0, 1, 0)
		sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		sliderFill.BorderSizePixel = 0
		sliderFill.Parent = sliderBack

		local sliderFillCorner = Instance.new("UICorner")
		sliderFillCorner.CornerRadius = UDim.new(0.5, 0)
		sliderFillCorner.Parent = sliderFill

		local sliderValue = Instance.new("TextLabel")
		sliderValue.Name = "Value"
		sliderValue.Size = UDim2.new(0.1, 0, 0.8, 0)
		sliderValue.Position = UDim2.new(0.88, 0, 0.1, 0)
		sliderValue.BackgroundTransparency = 1
		sliderValue.Text = tostring(setting.default)
		sliderValue.TextColor3 = Color3.new(1, 1, 1)
		sliderValue.TextScaled = true
		sliderValue.Font = Enum.Font.SourceSansSemibold
		sliderValue.Parent = container

		-- Make slider draggable
		local isDragging = false

		sliderBack.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				isDragging = true
				self:UpdateSliderPosition(input.Position.X, sliderBack, sliderFill, sliderValue, setting)
			end
		end)

		sliderBack.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				isDragging = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				self:UpdateSliderPosition(input.Position.X, sliderBack, sliderFill, sliderValue, setting)
			end
		end)
	elseif setting.type == "button" then
		local button = Instance.new("TextButton")
		button.Name = "Button"
		button.Size = UDim2.new(0.3, 0, 0.7, 0)
		button.Position = UDim2.new(0.65, 0, 0.15, 0)
		button.BackgroundColor3 = setting.danger and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 170, 255)
		button.BorderSizePixel = 0
		button.Text = setting.danger and "Delete" or "Apply"
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.SourceSansSemibold
		button.Parent = container

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.2, 0)
		buttonCorner.Parent = button

		-- Connect button click
		button.MouseButton1Click:Connect(function()
			if setting.danger then
				self:ShowConfirmationDialog(
					"Delete Save Data",
					"Are you sure you want to delete all your save data? This action cannot be undone.",
					function() self:DeleteSaveData() end
				)
			else
				-- Handle other button actions
				self:ApplySetting(setting.name)
			end
		end)
	end
end

-- Update slider position
function UIController:UpdateSliderPosition(mouseX, sliderBack, sliderFill, valueLabel, setting)
	local absolutePosition = sliderBack.AbsolutePosition.X
	local absoluteSize = sliderBack.AbsoluteSize.X

	local relativeX = math.clamp(mouseX - absolutePosition, 0, absoluteSize)
	local normalizedValue = relativeX / absoluteSize

	-- Calculate actual value
	local range = setting.max - setting.min
	local actualValue = math.floor((normalizedValue * range) + setting.min + 0.5)

	-- Update UI
	sliderFill.Size = UDim2.new(normalizedValue, 0, 1, 0)
	valueLabel.Text = tostring(actualValue)

	-- Apply the setting
	self:ApplySetting(setting.name, actualValue)
end

-- Switch between pet tabs
function UIController:SwitchPetsTab(tabName)
	local contentFrame = self.Cache.UIElements.Content:FindFirstChild("PetsMenu")
	if not contentFrame then return end

	local petsContainer = contentFrame.Content:FindFirstChild("PetsContainer")
	if not petsContainer then return end

	-- Update tab indicators
	local tabs = contentFrame.Content.Tabs:GetChildren()
	for _, tab in ipairs(tabs) do
		if tab:IsA("TextButton") then
			local indicator = tab:FindFirstChild("Indicator")
			if indicator then
				indicator.Visible = (tab.Name == tabName .. "Tab")
			end
		end
	end

	-- Show the selected container
	for _, container in ipairs(petsContainer:GetChildren()) do
		if container:IsA("Frame") then
			container.Visible = (container.Name == tabName .. "Container")
		end
	end

	-- Refresh the content
	if tabName == "Equipped" then
		self:RefreshEquippedPets()
	elseif tabName == "Collection" then
		self:RefreshPetCollection()
	end
end

-- Switch between shop tabs
function UIController:SwitchShopTab(tabName)
	local contentFrame = self.Cache.UIElements.Content:FindFirstChild("ShopMenu")
	if not contentFrame then return end

	local shopContainer = contentFrame.Content:FindFirstChild("ShopContainer")
	if not shopContainer then return end

	-- Update tab indicators
	local tabs = contentFrame.Content.Tabs:GetChildren()
	for _, tab in ipairs(tabs) do
		if tab:IsA("TextButton") then
			local indicator = tab:FindFirstChild("Indicator")
			if indicator then
				indicator.Visible = (tab.Name == tabName .. "Tab")
			end
		end
	end

	-- Show the selected container
	for _, container in ipairs(shopContainer:GetChildren()) do
		if container:IsA("Frame") then
			container.Visible = (container.Name == tabName .. "Container")
		end
	end

	-- Refresh the content
	if tabName == "Eggs" then
		self:RefreshEggsShop()
	elseif tabName == "Boosters" then
		self:RefreshBoostersShop()
	elseif tabName == "Currency" then
		self:RefreshCurrencyShop()
	end
end

-- Toggle a setting
function UIController:ToggleSetting(settingName, toggleFrame, knobFrame)
	-- Play sound
	local sound = self.Cache.SoundInstances.ButtonClick
	if sound then
		sound:Play()
	end

	-- Toggle state
	local isOn = knobFrame.Position.X.Scale > 0.1

	-- Animate the toggle
	if isOn then
		-- Turn off
		TweenService:Create(toggleFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 100, 110)}):Play()
		TweenService:Create(knobFrame, TweenInfo.new(0.2), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	else
		-- Turn on
		TweenService:Create(toggleFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}):Play()
		TweenService:Create(knobFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0, 0)}):Play()
	end

	-- Apply the setting
	self:ApplySetting(settingName, not isOn)
end

-- Apply a setting
function UIController:ApplySetting(settingName, value)
	if settingName == "Music" then
		-- Toggle music
		self:ToggleMusic(value)
	elseif settingName == "Sound Effects" then
		-- Toggle sound effects
		self:ToggleSoundEffects(value)
	elseif settingName == "Hide Pets" then
		-- Toggle pet visibility
		self:TogglePetVisibility(value)
	elseif settingName == "Graphics Quality" then
		-- Set graphics quality
		self:SetGraphicsQuality(value)
	end

	-- Show notification
	self:ShowNotification("Setting Applied", settingName .. " has been updated.")
end

-- Toggle music
function UIController:ToggleMusic(enabled)
	-- Implementation would depend on your music system
	print("UIController: Music toggled to " .. tostring(enabled))
end

-- Toggle sound effects
function UIController:ToggleSoundEffects(enabled)
	-- Set all sound volumes
	for _, sound in pairs(self.Cache.SoundInstances) do
		sound.Volume = enabled and 0.5 or 0
	end

	print("UIController: Sound effects toggled to " .. tostring(enabled))
end

-- Toggle pet visibility
function UIController:TogglePetVisibility(hidden)
	-- Implementation would depend on your pet rendering system
	local petSystem = _G.PetSystemClient

	if petSystem and typeof(petSystem.SetPetsVisible) == "function" then
		petSystem.SetPetsVisible(not hidden)
	end

	print("UIController: Pet visibility toggled to " .. tostring(not hidden))
end

-- Set graphics quality
function UIController:SetGraphicsQuality(level)
	-- Implementation would depend on your graphics settings
	print("UIController: Graphics quality set to " .. tostring(level))
end

-- Delete save data
function UIController:DeleteSaveData()
	-- Implementation would depend on your data saving system
	local petSystem = _G.PetSystemClient
	local shopSystem = _G.ShopSystemClient

	-- Call appropriate reset methods on the systems
	if petSystem and typeof(petSystem.ResetData) == "function" then
		petSystem:ResetData()
	end

	if shopSystem and typeof(shopSystem.ResetData) == "function" then
		shopSystem:ResetData()
	end

	-- Show notification
	self:ShowNotification("Data Reset", "Your save data has been deleted. Please rejoin the game.")

	print("UIController: Save data deleted")
end

-- Show a confirmation dialog
function UIController:ShowConfirmationDialog(title, message, callback)
	local overlayLayer = self.Cache.UIElements.Overlay

	-- Check if dialog already exists
	local existingDialog = overlayLayer:FindFirstChild("ConfirmationDialog")
	if existingDialog then
		existingDialog:Destroy()
	end

	-- Create overlay background
	local overlay = Instance.new("Frame")
	overlay.Name = "ConfirmationDialog"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Parent = overlayLayer

	-- Create dialog box
	local dialog = Instance.new("Frame")
	dialog.Name = "Dialog"
	dialog.Size = UDim2.new(0.4, 0, 0.3, 0)
	dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	dialog.BorderSizePixel = 0
	dialog.Parent = overlay

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = dialog

	-- Add title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	titleLabel.BorderSizePixel = 0
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.Parent = dialog

	-- Add title corner rounding
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.05, 0)
	titleCorner.Parent = titleLabel

	-- Add message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
	messageLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	messageLabel.TextScaled = true
	messageLabel.TextWrapped = true
	messageLabel.Font = Enum.Font.SourceSansSemibold
	messageLabel.Parent = dialog

	-- Add buttons
	local buttonSize = UDim2.new(0.4, 0, 0.15, 0)

	-- Cancel button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = buttonSize
	cancelButton.Position = UDim2.new(0.15, 0, 0.75, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = Color3.new(1, 1, 1)
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.SourceSansSemibold
	cancelButton.Parent = dialog

	-- Add cancel button corner rounding
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0.2, 0)
	cancelCorner.Parent = cancelButton

	-- Confirm button
	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "ConfirmButton"
	confirmButton.Size = buttonSize
	confirmButton.Position = UDim2.new(0.65, 0, 0.75, 0)
	confirmButton.AnchorPoint = Vector2.new(0.1, 0)
	confirmButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	confirmButton.BorderSizePixel = 0
	confirmButton.Text = "Confirm"
	confirmButton.TextColor3 = Color3.new(1, 1, 1)
	confirmButton.TextScaled = true
	confirmButton.Font = Enum.Font.SourceSansSemibold
	confirmButton.Parent = dialog

	-- Add confirm button corner rounding
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0.2, 0)
	confirmCorner.Parent = confirmButton

	-- Connect buttons
	cancelButton.MouseButton1Click:Connect(function()
		-- Play sound
		local sound = self.Cache.SoundInstances.ButtonClick
		if sound then
			sound:Play()
		end

		-- Close dialog
		overlay:Destroy()
	end)

	confirmButton.MouseButton1Click:Connect(function()
		-- Play sound
		local sound = self.Cache.SoundInstances.ButtonClick
		if sound then
			sound:Play()
		end

		-- Close dialog
		overlay:Destroy()

		-- Execute callback
		if callback then
			callback()
		end
	end)
end

-- Show a notification
function UIController:ShowNotification(title, message)
	local notificationLayer = self.Cache.UIElements.Notification

	-- Play sound
	local sound = self.Cache.SoundInstances.Notification
	if sound then
		sound:Play()
	end

	-- Create notification
	local notification = Instance.new("Frame")
	notification.Name = "Notification_" .. tick()
	notification.Size = UDim2.new(0.3, 0, 0.1, 0)
	notification.Position = UDim2.new(1.1, 0, 0.8, 0)
	notification.AnchorPoint = Vector2.new(0, 1)
	notification.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	notification.BorderSizePixel = 0
	notification.Parent = notificationLayer

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = notification

	-- Add title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0.95, 0, 0.3, 0)
	titleLabel.Position = UDim2.new(0.025, 0, 0.1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.Parent = notification

	-- Add message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(0.95, 0, 0.4, 0)
	messageLabel.Position = UDim2.new(0.025, 0, 0.5, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.TextScaled = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextWrapped = true
	messageLabel.Font = Enum.Font.SourceSansSemibold
	messageLabel.Parent = notification

	-- Animate notification
	TweenService:Create(
		notification,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.99, 0, 0.8, 0)}
	):Play()

	-- Auto-remove notification after 4 seconds
	delay(4, function()
		TweenService:Create(
			notification,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Position = UDim2.new(1.1, 0, 0.8, 0)}
		):Play()

		wait(0.5)
		notification:Destroy()
	end)
end

-- Update pet UI based on data from pet system
function UIController:UpdatePetUI(petData)
	print("UIController: Updating pet UI with new data")
	self:RefreshEquippedPets()
	self:RefreshPetCollection()
end

-- Update currency UI based on data from shop system
function UIController:UpdateCurrencyUI(currencyData)
	print("UIController: Updating currency UI with new data")
	-- Currency display is handled by the CurrencyDisplay module
end

-- Update shop UI with items from shop system
function UIController:UpdateShopUI(items)
	print("UIController: Updating shop UI with new items")
	self:RefreshEggsShop()
	self:RefreshBoostersShop()
	self:RefreshCurrencyShop()
end

-- Refresh equipped pets display
function UIController:RefreshEquippedPets()
	-- Define a helper function for safe access
	local function safeFind(parent, childName)
		if not parent then return nil end
		return parent:FindFirstChild(childName)
	end

	-- Get the nested UI elements safely
	local contentFrame = safeFind(self.Cache.UIElements.Content, "PetsMenu")
	if not contentFrame then 
		warn("UIController: PetsMenu not found in Content")
		return 
	end

	local content = safeFind(contentFrame, "Content")
	if not content then 
		warn("UIController: Content not found in PetsMenu")
		return 
	end

	local petsContainer = safeFind(content, "PetsContainer")
	if not petsContainer then 
		warn("UIController: PetsContainer not found in Content")
		return
	end

	local equippedContainer = safeFind(petsContainer, "EquippedContainer")
	if not equippedContainer then 
		warn("UIController: EquippedContainer not found in PetsContainer")
		return 
	end

	-- Clear current pets
	for _, child in ipairs(equippedContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Get equipped pets from pet system
	local petSystem = _G.PetSystemClient
	if not petSystem then 
		warn("UIController: PetSystemClient not found in _G")

		-- Create a message to inform user
		local message = Instance.new("TextLabel")
		message.Size = UDim2.new(0.8, 0, 0.2, 0)
		message.Position = UDim2.new(0.5, 0, 0.4, 0)
		message.AnchorPoint = Vector2.new(0.5, 0.5)
		message.BackgroundTransparency = 1
		message.Text = "Pet system not loaded yet. Try again later."
		message.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		message.TextScaled = true
		message.Font = Enum.Font.SourceSansSemibold  -- Fixed font enum
		message.Parent = equippedContainer
		return 
	end

	local equippedPets = {}

	-- Check if function exists and is callable
	if typeof(petSystem.GetEquippedPets) == "function" then
		local success, result = pcall(function()
			return petSystem:GetEquippedPets()
		end)

		if success and result then
			equippedPets = result
		else
			warn("UIController: Error getting equipped pets: " .. tostring(result))
		end
	else
		warn("UIController: GetEquippedPets function not found in PetSystemClient")
	end

	-- If no pets are equipped, show message
	if #equippedPets == 0 then
		local message = Instance.new("TextLabel")
		message.Size = UDim2.new(0.8, 0, 0.2, 0)
		message.Position = UDim2.new(0.5, 0, 0.4, 0)
		message.AnchorPoint = Vector2.new(0.5, 0.5)
		message.BackgroundTransparency = 1
		message.Text = "No pets equipped. Go to Collection to equip pets."
		message.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		message.TextScaled = true
		message.Font = Enum.Font.SourceSansSemibold  -- Fixed font enum
		message.Parent = equippedContainer
		return
	end

	-- Create a grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.23, 0, 0.4, 0)
	gridLayout.CellPadding = UDim2.new(0.02, 0, 0.05, 0)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = equippedContainer

	-- Add pets to grid
	for i, petData in ipairs(equippedPets) do
		-- Add a pcall for CreatePetCard to prevent errors
		local success, errorMsg = pcall(function()
			self:CreatePetCard(petData, equippedContainer, i, true)
		end)

		if not success then
			warn("UIController: Failed to create pet card: " .. tostring(errorMsg))
		end
	end
end

-- Refresh pet collection display
function UIController:RefreshPetCollection()
	-- Define a helper function for safe access
	local function safeFind(parent, childName)
		if not parent then return nil end
		return parent:FindFirstChild(childName)
	end

	-- Get the nested UI elements safely
	local contentFrame = safeFind(self.Cache.UIElements.Content, "PetsMenu")
	if not contentFrame then return end

	local content = safeFind(contentFrame, "Content")
	if not content then return end

	local petsContainer = safeFind(content, "PetsContainer")
	if not petsContainer then return end

	local collectionContainer = safeFind(petsContainer, "CollectionContainer")
	if not collectionContainer then return end

	-- Clear current pets
	for _, child in ipairs(collectionContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Get owned pets from pet system
	local petSystem = _G.PetSystemClient
	if not petSystem then return end

	local ownedPets = {}
	if typeof(petSystem.GetOwnedPets) == "function" then
		ownedPets = petSystem:GetOwnedPets()
	end

	-- If no pets are owned, show message
	if #ownedPets == 0 then
		local message = Instance.new("TextLabel")
		message.Size = UDim2.new(0.8, 0, 0.2, 0)
		message.Position = UDim2.new(0.5, 0, 0.4, 0)
		message.AnchorPoint = Vector2.new(0.5, 0.5)
		message.BackgroundTransparency = 1
		message.Text = "No pets in your collection. Visit the Shop to get pets!"
		message.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		message.TextScaled = true
		message.Font = Enum.Font.SourceSansSemibold
		message.Parent = collectionContainer
		return
	end

	-- Create a grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.23, 0, 0.35, 0)
	gridLayout.CellPadding = UDim2.new(0.02, 0, 0.05, 0)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = collectionContainer

	-- Add pets to grid
	for i, petData in ipairs(ownedPets) do
		self:CreatePetCard(petData, collectionContainer, i, false)
	end
end

-- Create a pet card UI element
function UIController:CreatePetCard(petData, parent, index, isEquipped)
	-- Create card container
	local card = Instance.new("Frame")
	card.Name = "PetCard_" .. petData.id
	card.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = card

	-- Add pet image
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(0.9, 0, 0.6, 0)
	image.Position = UDim2.new(0.5, 0, 0.3, 0)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundTransparency = 1
	image.Image = petData.image or "rbxassetid://6031302950" -- Default image
	image.Parent = card

	-- Add pet name
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.9, 0, 0.15, 0)
	name.Position = UDim2.new(0.5, 0, 0.7, 0)
	name.AnchorPoint = Vector2.new(0.5, 0.5)
	name.BackgroundTransparency = 1
	name.Text = petData.name or "Unknown Pet"
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextScaled = true
	name.Font = Enum.Font.SourceSansSemibold
	name.Parent = card

	-- Add rarity indicator based on pet data
	local rarityColors = {
		common = Color3.fromRGB(150, 150, 150),
		uncommon = Color3.fromRGB(100, 200, 100),
		rare = Color3.fromRGB(100, 100, 255),
		epic = Color3.fromRGB(200, 100, 200),
		legendary = Color3.fromRGB(255, 215, 0)
	}

	local rarityColor = rarityColors[petData.rarity] or rarityColors.common

	local rarity = Instance.new("TextLabel")
	rarity.Size = UDim2.new(0.9, 0, 0.1, 0)
	rarity.Position = UDim2.new(0.5, 0, 0.82, 0)
	rarity.AnchorPoint = Vector2.new(0.5, 0.5)
	rarity.BackgroundTransparency = 1
	rarity.Text = (petData.rarity or "Common"):upper()
	rarity.TextColor3 = rarityColor
	rarity.TextScaled = true
	rarity.Font = Enum.Font.SourceSansSemibold
	rarity.Parent = card

	-- Add button based on context
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.8, 0, 0.12, 0)
	button.Position = UDim2.new(0.5, 0, 0.93, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = isEquipped and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 170, 255)
	button.BorderSizePixel = 0
	button.Text = isEquipped and "Unequip" or "Equip"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.SourceSansSemibold
	button.Parent = card

	-- Add button corner rounding
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = button

	-- Connect button
	button.MouseButton1Click:Connect(function()
		-- Play sound
		local sound = self.Cache.SoundInstances.ButtonClick
		if sound then
			sound:Play()
		end

		-- Call appropriate function in pet system
		local petSystem = _G.PetSystemClient
		if petSystem then
			if isEquipped then
				if typeof(petSystem.UnequipPet) == "function" then
					petSystem:UnequipPet(petData.id)
				end
			else
				if typeof(petSystem.EquipPet) == "function" then
					petSystem:EquipPet(petData.id)
				end
			end
		end
	end)
end

-- Refresh the shop menu UI with eggs tab
function UIController:RefreshEggsShop()
	local contentFrame = self.Cache.UIElements.Content:FindFirstChild("ShopMenu")
	if not contentFrame then return end

	local eggsContainer = contentFrame.Content.ShopContainer.EggsContainer
	if not eggsContainer then return end

	-- Clear current items
	for _, child in ipairs(eggsContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Get shop items from shop system
	local shopSystem = _G.ShopSystemClient
	if not shopSystem then return end

	local shopItems = shopSystem.Cache.ShopItems or {}

	-- Filter for egg items
	local eggItems = {}
	for _, item in pairs(shopItems) do
		if item.category == "Eggs" then
			table.insert(eggItems, item)
		end
	end

	-- If no eggs are available, show message
	if #eggItems == 0 then
		local message = Instance.new("TextLabel")
		message.Size = UDim2.new(0.8, 0, 0.2, 0)
		message.Position = UDim2.new(0.5, 0, 0.4, 0)
		message.AnchorPoint = Vector2.new(0.5, 0.5)
		message.BackgroundTransparency = 1
		message.Text = "No eggs available in the shop."
		message.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		message.TextScaled = true
		message.Font = Enum.Font.SourceSansSemibold
		message.Parent = eggsContainer
		return
	end

	-- Create a grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.3, 0, 0.45, 0)
	gridLayout.CellPadding = UDim2.new(0.05, 0, 0.05, 0)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = eggsContainer

	-- Add eggs to grid
	for i, item in ipairs(eggItems) do
		self:CreateShopItemCard(item, eggsContainer, i)
	end
end

-- Refresh the shop menu UI with boosters tab
function UIController:RefreshBoostersShop()
	local contentFrame = self.Cache.UIElements.Content:FindFirstChild("ShopMenu")
	if not contentFrame then return end

	local boostersContainer = contentFrame.Content.ShopContainer.BoostersContainer
	if not boostersContainer then return end

	-- Clear current items
	for _, child in ipairs(boostersContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Get shop items from shop system
	local shopSystem = _G.ShopSystemClient
	if not shopSystem then return end

	local shopItems = shopSystem.Cache.ShopItems or {}

	-- Filter for booster items
	local boosterItems = {}
	for _, item in pairs(shopItems) do
		if item.category == "Boosters" then
			table.insert(boosterItems, item)
		end
	end

	-- If no boosters are available, show message
	if #boosterItems == 0 then
		local message = Instance.new("TextLabel")
		message.Size = UDim2.new(0.8, 0, 0.2, 0)
		message.Position = UDim2.new(0.5, 0, 0.4, 0)
		message.AnchorPoint = Vector2.new(0.5, 0.5)
		message.BackgroundTransparency = 1
		message.Text = "No boosters available in the shop."
		message.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		message.TextScaled = true
		message.Font = Enum.Font.SourceSansSemibold
		message.Parent = boostersContainer
		return
	end

	-- Create a grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.3, 0, 0.45, 0)
	gridLayout.CellPadding = UDim2.new(0.05, 0, 0.05, 0)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = boostersContainer

	-- Add boosters to grid
	for i, item in ipairs(boosterItems) do
		self:CreateShopItemCard(item, boostersContainer, i)
	end
end

-- Refresh the shop menu UI with currency tab
function UIController:RefreshCurrencyShop()
	local contentFrame = self.Cache.UIElements.Content:FindFirstChild("ShopMenu")
	if not contentFrame then return end

	local currencyContainer = contentFrame.Content.ShopContainer.CurrencyContainer
	if not currencyContainer then return end

	-- Clear current items
	for _, child in ipairs(currencyContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Create premium currency options
	local options = {
		{name = "Small Gems Pack", amount = 100, price = "R$49", productId = 1234567, icon = "rbxassetid://6029251113"},
		{name = "Medium Gems Pack", amount = 500, price = "R$199", productId = 1234568, icon = "rbxassetid://6029251113"},
		{name = "Large Gems Pack", amount = 1000, price = "R$399", productId = 1234569, icon = "rbxassetid://6029251113"},
		{name = "Coin Boost", amount = 10000, price = "R$99", productId = 1234570, icon = "rbxassetid://6031086173"}
	}

	-- Create a grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.45, 0, 0.3, 0)
	gridLayout.CellPadding = UDim2.new(0.05, 0, 0.05, 0)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = currencyContainer

	-- Add currency options to grid
	for i, option in ipairs(options) do
		self:CreateCurrencyPurchaseCard(option, currencyContainer, i)
	end
end

-- Create a shop item card UI element
function UIController:CreateShopItemCard(item, parent, index)
	-- Create card container
	local card = Instance.new("Frame")
	card.Name = "ShopItemCard_" .. item.id
	card.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = card

	-- Add item image
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(0.8, 0, 0.5, 0)
	image.Position = UDim2.new(0.5, 0, 0.3, 0)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundTransparency = 1
	image.Image = item.image or "rbxassetid://6031302950" -- Default image
	image.Parent = card

	-- Add item name
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.9, 0, 0.15, 0)
	name.Position = UDim2.new(0.5, 0, 0.65, 0)
	name.AnchorPoint = Vector2.new(0.5, 0.5)
	name.BackgroundTransparency = 1
	name.Text = item.name or "Unknown Item"
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextScaled = true
	name.Font = Enum.Font.SourceSansSemibold
	name.Parent = card

	-- Add price container
	local priceContainer = Instance.new("Frame")
	priceContainer.Size = UDim2.new(0.7, 0, 0.15, 0)
	priceContainer.Position = UDim2.new(0.5, 0, 0.8, 0)
	priceContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	priceContainer.BackgroundTransparency = 1
	priceContainer.Parent = card

	-- Add price icon
	local currencyIcon
	if item.currency == "Coins" then
		currencyIcon = "rbxassetid://6031086173"
	else
		currencyIcon = "rbxassetid://6029251113" -- Gems
	end

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.2, 0, 1, 0)
	icon.Position = UDim2.new(0, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = currencyIcon
	icon.Parent = priceContainer

	-- Add price value
	local price = Instance.new("TextLabel")
	price.Size = UDim2.new(0.75, 0, 1, 0)
	price.Position = UDim2.new(0.25, 0, 0.5, 0)
	price.AnchorPoint = Vector2.new(0, 0.5)
	price.BackgroundTransparency = 1
	price.Text = tostring(item.price)
	price.TextColor3 = Color3.new(1, 1, 1)
	price.TextScaled = true
	price.Font = Enum.Font.SourceSansSemibold
	price.TextXAlignment = Enum.TextXAlignment.Right
	price.Parent = priceContainer

	-- Add buy button
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.7, 0, 0.12, 0)
	button.Position = UDim2.new(0.5, 0, 0.93, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	button.BorderSizePixel = 0
	button.Text = "Buy"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.SourceSansSemibold
	button.Parent = card

	-- Add button corner rounding
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = button

	-- Connect button
	button.MouseButton1Click:Connect(function()
		-- Play sound
		local sound = self.Cache.SoundInstances.ButtonClick
		if sound then
			sound:Play()
		end

		-- Show purchase confirmation
		self:ShowConfirmationDialog(
			"Purchase " .. item.name,
			"Are you sure you want to buy " .. item.name .. " for " .. item.price .. " " .. item.currency .. "?",
			function()
				-- Call purchase function in shop system
				local shopSystem = _G.ShopSystemClient
				if shopSystem and typeof(shopSystem.PurchaseItem) == "function" then
					shopSystem:PurchaseItem(item.id, 1)
				end
			end
		)
	end)
end

-- Create a currency purchase card UI element
function UIController:CreateCurrencyPurchaseCard(option, parent, index)
	-- Create card container
	local card = Instance.new("Frame")
	card.Name = "CurrencyCard_" .. index
	card.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = card

	-- Add item image
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(0.3, 0, 0.5, 0)
	image.Position = UDim2.new(0.2, 0, 0.35, 0)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundTransparency = 1
	image.Image = option.icon
	image.Parent = card

	-- Add amount value
	local amount = Instance.new("TextLabel")
	amount.Size = UDim2.new(0.4, 0, 0.3, 0)
	amount.Position = UDim2.new(0.7, 0, 0.35, 0)
	amount.AnchorPoint = Vector2.new(0.5, 0.5)
	amount.BackgroundTransparency = 1
	amount.Text = "+" .. tostring(option.amount)
	amount.TextColor3 = Color3.new(1, 1, 1)
	amount.TextScaled = true
	amount.Font = Enum.Font.SourceSansSemibold
	amount.Parent = card

	-- Add name
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.9, 0, 0.15, 0)
	name.Position = UDim2.new(0.5, 0, 0.7, 0)
	name.AnchorPoint = Vector2.new(0.5, 0.5)
	name.BackgroundTransparency = 1
	name.Text = option.name
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextScaled = true
	name.Font = Enum.Font.SourceSansSemibold
	name.Parent = card

	-- Add buy button
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.7, 0, 0.15, 0)
	button.Position = UDim2.new(0.5, 0, 0.9, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	button.BorderSizePixel = 0
	button.Text = option.price
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.SourceSansSemibold
	button.Parent = card

	-- Add button corner rounding
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = button

	-- Connect button
	button.MouseButton1Click:Connect(function()
		-- Play sound
		local sound = self.Cache.SoundInstances.ButtonClick
		if sound then
			sound:Play()
		end

		-- Call purchase function in shop system
		local shopSystem = _G.ShopSystemClient
		if shopSystem and typeof(shopSystem.BuyDeveloperProduct) == "function" then
			shopSystem:BuyDeveloperProduct(option.productId)
		end
	end)
end

-- Refresh inventory menu
function UIController:RefreshInventoryMenu()
	local contentFrame = self.Cache.UIElements.Content:FindFirstChild("InventoryMenu")
	if not contentFrame then return end

	-- Implementation depends on your game's inventory system
	print("UIController: Refreshing inventory menu")
	

	-- Refresh settings menu
function UIController:RefreshSettingsMenu()
	local contentFrame = self.Cache.UIElements.Content:FindFirstChild("SettingsMenu")
		if not contentFrame then return end
	end
end

	-- No need to refresh settings unless you want to load saved settings
	print("UIController: Refreshing settings menu")
	

	return UIController