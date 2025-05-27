--[[
    GameClient.lua - CONSOLIDATED CLIENT SYSTEM (FIXED)
    Place in: ReplicatedStorage/GameClient.lua
    
    This replaces: PetSystemClient, ShopSystemClient, UIController, and all other client scripts
    Single client interface for all game systems
]]

local GameClient = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Player and Game State
local LocalPlayer = Players.LocalPlayer
GameClient.PlayerData = {}
GameClient.RemoteEvents = {}
GameClient.RemoteFunctions = {}
GameClient.UI = {}
GameClient.Cache = {
	ShopItems = {},
	ActiveBoosters = {},
	EquippedPets = {}
}

-- UI State
GameClient.UIState = {
	ActiveMenus = {},
	CurrentPage = nil,
	IsTransitioning = false
}

-- Initialize the entire client system
function GameClient:Initialize()
	print("GameClient: Starting initialization...")

	self:SetupRemoteConnections()
	self:SetupUI()
	self:SetupInputHandling()
	self:SetupEffects()
	self:RequestInitialData()

	print("GameClient: Initialization complete!")
	return true
end

-- Setup Remote Connections
function GameClient:SetupRemoteConnections()
	-- Wait for remote folder
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("GameClient: Could not find GameRemotes folder")
		return
	end

	-- Store remote references
	for _, child in ipairs(remoteFolder:GetChildren()) do
		if child:IsA("RemoteEvent") then
			self.RemoteEvents[child.Name] = child
		elseif child:IsA("RemoteFunction") then
			self.RemoteFunctions[child.Name] = child
		end
	end

	-- Setup event handlers
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

	-- Pet System Events
	if self.RemoteEvents.PetCollected then
		self.RemoteEvents.PetCollected.OnClientEvent:Connect(function(petData, coinsAwarded)
			self:HandlePetCollected(petData, coinsAwarded)
		end)
	end

	if self.RemoteEvents.PetEquipped then
		self.RemoteEvents.PetEquipped.OnClientEvent:Connect(function(petId, petData)
			self:HandlePetEquipped(petId, petData)
		end)
	end

	-- Shop System Events
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased.OnClientEvent:Connect(function(item, quantity)
			self:HandleItemPurchased(item, quantity)
		end)
	end

	if self.RemoteEvents.CurrencyUpdated then
		self.RemoteEvents.CurrencyUpdated.OnClientEvent:Connect(function(currencyData)
			self:HandleCurrencyUpdate(currencyData)
		end)
	end

	-- Notification System
	if self.RemoteEvents.NotificationSent then
		self.RemoteEvents.NotificationSent.OnClientEvent:Connect(function(title, message, type)
			self:ShowNotification(title, message, type)
		end)
	end
end

-- UI System Setup
function GameClient:SetupUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Create main UI
	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "GameUI"
	mainUI.ResetOnSpawn = false
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainUI.Parent = playerGui

	self.UI.MainUI = mainUI

	-- Create UI layers
	self:CreateUILayers(mainUI)

	-- Setup specific UI components
	self:SetupCurrencyDisplay()
	self:SetupNavigationBar()
	self:SetupMenus()

	print("GameClient: UI system setup complete")
end

-- Create UI Layers
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
	local container = Instance.new("Frame")
	container.Name = "CurrencyDisplay"
	container.Size = UDim2.new(0.25, 0, 0.08, 0)
	container.Position = UDim2.new(0.99, 0, 0.02, 0)
	container.AnchorPoint = Vector2.new(1, 0)
	container.BackgroundTransparency = 1
	container.Parent = self.UI.Navigation

	-- Coins Display
	local coinsFrame = self:CreateCurrencyFrame("Coins", "rbxassetid://6031086173", Color3.fromRGB(255, 215, 0))
	coinsFrame.Size = UDim2.new(1, 0, 0.45, 0)
	coinsFrame.Position = UDim2.new(0, 0, 0, 0)
	coinsFrame.Parent = container

	-- Gems Display  
	local gemsFrame = self:CreateCurrencyFrame("Gems", "rbxassetid://6029251113", Color3.fromRGB(0, 200, 255))
	gemsFrame.Size = UDim2.new(1, 0, 0.45, 0)
	gemsFrame.Position = UDim2.new(0, 0, 0.55, 0)
	gemsFrame.Parent = container

	self.UI.CurrencyContainer = container
	self.UI.CoinsFrame = coinsFrame
	self.UI.GemsFrame = gemsFrame
end

function GameClient:CreateCurrencyFrame(currencyName, iconId, color)
	local frame = Instance.new("Frame")
	frame.Name = currencyName .. "Frame"
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.2, 0, 0.8, 0)
	icon.Position = UDim2.new(0.05, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageColor3 = color
	icon.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.25, 0, 0.8, 0)
	label.Position = UDim2.new(0.3, 0, 0.5, 0)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.BackgroundTransparency = 1
	label.Text = currencyName
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.new(0.4, 0, 0.8, 0)
	value.Position = UDim2.new(0.95, 0, 0.5, 0)
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextColor3 = Color3.new(1, 1, 1)
	value.TextScaled = true
	value.Font = Enum.Font.SourceSansSemibold
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = frame

	return frame
end

-- Navigation Bar
function GameClient:SetupNavigationBar()
	local navBar = Instance.new("Frame")
	navBar.Name = "NavigationBar"
	navBar.Size = UDim2.new(1, 0, 0.08, 0)
	navBar.Position = UDim2.new(0, 0, 0.92, 0)
	navBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	navBar.BorderSizePixel = 0
	navBar.Parent = self.UI.Navigation

	local buttons = {
		{name = "Pets", icon = "🐾"},
		{name = "Shop", icon = "🛒"},
		{name = "Farm", icon = "🌾"},
		{name = "Settings", icon = "⚙️"}
	}

	local buttonWidth = 1 / #buttons

	for i, buttonInfo in ipairs(buttons) do
		local button = self:CreateNavButton(buttonInfo.name, buttonInfo.icon)
		button.Size = UDim2.new(buttonWidth, 0, 1, 0)
		button.Position = UDim2.new((i-1) * buttonWidth, 0, 0, 0)
		button.Parent = navBar

		button.MouseButton1Click:Connect(function()
			self:OpenMenu(buttonInfo.name)
		end)
	end

	self.UI.NavigationBar = navBar
end

function GameClient:CreateNavButton(name, icon)
	local button = Instance.new("TextButton")
	button.Name = name .. "Button"
	button.BackgroundTransparency = 1
	button.Text = ""

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	background.BorderSizePixel = 0
	background.Parent = button

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 0.5, 0)
	iconLabel.Position = UDim2.new(0, 0, 0.1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.SourceSansSemibold
	iconLabel.Parent = button

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, 0, 0.3, 0)
	textLabel.Position = UDim2.new(0, 0, 0.65, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = name
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansSemibold
	textLabel.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		TweenService:Create(background, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(65, 65, 75)}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(background, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
	end)

	return button
end

-- Menu System
function GameClient:SetupMenus()
	-- Menus will be created dynamically when opened
	self.UI.Menus = {}
end

function GameClient:OpenMenu(menuName)
	if self.UIState.IsTransitioning then return end

	self:CloseActiveMenus()

	local menu = self:GetOrCreateMenu(menuName)
	if not menu then return end

	self.UIState.IsTransitioning = true
	self.UIState.CurrentPage = menuName
	self.UIState.ActiveMenus[menuName] = menu

	-- Show menu with animation
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

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.1, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = menuName
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

-- Input Handling
function GameClient:SetupInputHandling()
	-- Pet collection via clicking
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:HandlePetClick(input)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			self:CloseActiveMenus()
		end
	end)
end

-- Updated raycast code to replace deprecated FilterType
-- Replace the old raycast code in GameClient.lua with this:

function GameClient:HandlePetClick(input)
	local camera = workspace.CurrentCamera
	local mousePos = input.Position

	local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local raycastParams = RaycastParams.new()

	-- FIXED: Use modern FilterType enum
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude  -- New method
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

	local result = workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)

	if result and result.Instance then
		local model = result.Instance
		while model and model.Parent and model.Parent ~= workspace do
			model = model.Parent
		end

		if model and model:IsA("Model") and model:GetAttribute("PetType") then
			-- Found a wild pet, try to collect it
			if self.RemoteEvents.CollectWildPet then
				self.RemoteEvents.CollectWildPet:FireServer(model)
			end
		end
	end
end

-- Alternative: If you want to include only specific instances (whitelist)
-- Use this version instead:

function GameClient:HandlePetClickWhitelist(input)
	local camera = workspace.CurrentCamera
	local mousePos = input.Position

	local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local raycastParams = RaycastParams.new()

	-- Include only pet models (whitelist approach)
	raycastParams.FilterType = Enum.RaycastFilterType.Include

	-- Find all pet containers to include in raycast
	local petContainers = {}
	local areasFolder = workspace:FindFirstChild("Areas")
	if areasFolder then
		for _, area in pairs(areasFolder:GetChildren()) do
			local petsFolder = area:FindFirstChild("Pets")
			if petsFolder then
				table.insert(petContainers, petsFolder)
			end
		end
	end

	raycastParams.FilterDescendantsInstances = petContainers

	local result = workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)

	if result and result.Instance then
		local model = result.Instance
		while model and model.Parent and not model:GetAttribute("PetType") do
			model = model.Parent
		end

		if model and model:IsA("Model") and model:GetAttribute("PetType") then
			-- Found a wild pet, try to collect it
			if self.RemoteEvents.CollectWildPet then
				self.RemoteEvents.CollectWildPet:FireServer(model)
			end
		end
	end
end

-- Effects System
function GameClient:SetupEffects()
	-- Sound effects
	self.Sounds = {
		collect = self:CreateSound("rbxassetid://131961136", 0.5),
		purchase = self:CreateSound("rbxassetid://131961136", 0.3),
		notification = self:CreateSound("rbxassetid://131961136", 0.4)
	}
end

function GameClient:CreateSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = self.UI.MainUI
	return sound
end

-- Event Handlers
function GameClient:HandlePlayerDataUpdate(newData)
	self.PlayerData = newData
	self:UpdateCurrencyDisplay()
	self:UpdateActiveMenus()
end

function GameClient:HandlePetCollected(petData, coinsAwarded)
	-- Validate data first
	if not petData then
		warn("GameClient: HandlePetCollected called with nil petData")
		petData = {
			name = "Unknown Pet",
			type = "unknown",
			rarity = "Common"
		}
	end

	-- Ensure required fields exist
	petData.name = petData.name or petData.type or petData.id or "Pet"
	petData.rarity = petData.rarity or "Common"
	coinsAwarded = coinsAwarded or 0

	self:PlayCollectionEffect(petData)

	if self.Sounds.collect then
		self.Sounds.collect:Play()
	end

	self:ShowNotification("Pet Collected!", petData.name .. " (+" .. coinsAwarded .. " coins)", "success")

	print("GameClient: Collected " .. petData.name .. " for " .. coinsAwarded .. " coins")
end


function GameClient:HandleCurrencyUpdate(currencyData)
	for currency, amount in pairs(currencyData) do
		if self.PlayerData[currency:lower()] then
			self.PlayerData[currency:lower()] = amount
		end
	end
	self:UpdateCurrencyDisplay()
end

-- UI Updates
function GameClient:UpdateCurrencyDisplay()
	if not self.PlayerData then return end

	local coinsValue = self.UI.CoinsFrame:FindFirstChild("Value")
	if coinsValue then
		local newAmount = self.PlayerData.coins or 0
		self:AnimateValueChange(coinsValue, tonumber(coinsValue.Text) or 0, newAmount)
	end

	local gemsValue = self.UI.GemsFrame:FindFirstChild("Value")
	if gemsValue then
		local newAmount = self.PlayerData.gems or 0
		self:AnimateValueChange(gemsValue, tonumber(gemsValue.Text) or 0, newAmount)
	end
end

function GameClient:AnimateValueChange(label, oldValue, newValue)
	local difference = newValue - oldValue
	if difference == 0 then return end

	-- Flash green for increase, red for decrease
	local flashColor = difference > 0 and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
	label.TextColor3 = flashColor

	-- Animate the counting
	local duration = 0.5
	local startTime = tick()

	spawn(function()
		while tick() - startTime < duration do
			local alpha = (tick() - startTime) / duration
			local currentValue = math.floor(oldValue + (difference * alpha))

			-- Format with commas for thousands
			local formattedValue = self:FormatNumber(currentValue)
			label.Text = formattedValue

			wait()
		end

		-- Set final value and reset color
		label.Text = self:FormatNumber(newValue)
		TweenService:Create(label, TweenInfo.new(0.3), {TextColor3 = Color3.new(1, 1, 1)}):Play()
	end)
end

function GameClient:FormatNumber(number)
	local formatted = tostring(math.floor(number))
	-- Add commas for thousands
	if tonumber(formatted) >= 1000 then
		formatted = string.gsub(formatted, "(%d)(%d%d%d)$", "%1,%2")
		formatted = string.gsub(formatted, "(%d)(%d%d%d),", "%1,%2,")
	end
	return formatted
end

-- Menu Content Management
function GameClient:RefreshMenuContent(menuName)
	if menuName == "Pets" then
		self:RefreshPetsMenu()
	elseif menuName == "Shop" then
		self:RefreshShopMenu()
	elseif menuName == "Farm" then
		self:RefreshFarmMenu()
	elseif menuName == "Settings" then
		self:RefreshSettingsMenu()
	end
end

function GameClient:RefreshPetsMenu()
	local menu = self.UI.Menus.Pets
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create pet display
	if not self.PlayerData.pets or #self.PlayerData.pets.owned == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
		emptyLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
		emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No pets collected yet!\nGo explore and click on wild pets to collect them!"
		emptyLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.SourceSansSemibold
		emptyLabel.Parent = contentArea
		return
	end

	-- Create grid for pets
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 150, 0, 180)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.Name
	gridLayout.Parent = contentArea

	-- Add pets to grid
	for i, petData in ipairs(self.PlayerData.pets.owned) do
		local petCard = self:CreatePetCard(petData, i <= 5) -- First 5 can be equipped
		petCard.Parent = contentArea
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		contentArea.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
	end)
end

function GameClient:CreatePetCard(petData, canEquip)
	local card = Instance.new("Frame")
	card.Name = petData.id or ("Pet_" .. math.random(1000, 9999))
	card.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = card

	-- Pet image placeholder
	local image = Instance.new("Frame")
	image.Name = "Image"
	image.Size = UDim2.new(0.8, 0, 0.5, 0)
	image.Position = UDim2.new(0.5, 0, 0.25, 0)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	image.Parent = card

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0.1, 0)
	imageCorner.Parent = image

	-- Pet emoji as placeholder
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(1, 0, 1, 0)
	emoji.BackgroundTransparency = 1
	emoji.Text = self:GetPetEmoji(petData.type or "bunny")
	emoji.TextScaled = true
	emoji.Font = Enum.Font.SourceSansSemibold
	emoji.Parent = image

	-- Pet name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = petData.name or (petData.type or "Unknown Pet")
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansSemibold
	nameLabel.Parent = card

	-- Pet rarity
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	rarityLabel.Position = UDim2.new(0.5, 0, 0.72, 0)
	rarityLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = (petData.rarity or "Common"):upper()
	rarityLabel.TextColor3 = self:GetRarityColor(petData.rarity or "Common")
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansSemibold
	rarityLabel.Parent = card

	-- Equip button (if pet can be equipped)
	if canEquip then
		local isEquipped = self:IsPetEquipped(petData.id)

		local equipButton = Instance.new("TextButton")
		equipButton.Size = UDim2.new(0.8, 0, 0.12, 0)
		equipButton.Position = UDim2.new(0.5, 0, 0.88, 0)
		equipButton.AnchorPoint = Vector2.new(0.5, 0.5)
		equipButton.BackgroundColor3 = isEquipped and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 170, 255)
		equipButton.BorderSizePixel = 0
		equipButton.Text = isEquipped and "Unequip" or "Equip"
		equipButton.TextColor3 = Color3.new(1, 1, 1)
		equipButton.TextScaled = true
		equipButton.Font = Enum.Font.SourceSansSemibold
		equipButton.Parent = card

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.2, 0)
		buttonCorner.Parent = equipButton

		equipButton.MouseButton1Click:Connect(function()
			if self.RemoteEvents.PetEquipped and self.RemoteEvents.PetUnequipped then
				if isEquipped then
					self.RemoteEvents.PetUnequipped:FireServer(petData.id)
				else
					self.RemoteEvents.PetEquipped:FireServer(petData.id)
				end
			end
		end)
	end

	return card
end

function GameClient:GetPetEmoji(petType)
	local emojis = {
		Corgi = "🐶", 
		Cat = "🐱",
		Hamster = "🐾",
		RedPanda = "🐾"
	}
	return emojis[petType] or emojis.default
end

function GameClient:GetRarityColor(rarity)
	local colors = {
		Common = Color3.fromRGB(150, 150, 150),
		Uncommon = Color3.fromRGB(100, 200, 100),
		Rare = Color3.fromRGB(100, 100, 255),
		Epic = Color3.fromRGB(200, 100, 200),
		Legendary = Color3.fromRGB(255, 215, 0)
	}
	return colors[rarity] or colors.Common
end

function GameClient:IsPetEquipped(petId)
	if not self.PlayerData.pets or not self.PlayerData.pets.equipped then
		return false
	end

	for _, equippedPet in ipairs(self.PlayerData.pets.equipped) do
		if equippedPet.id == petId then
			return true
		end
	end
	return false
end

-- Shop Menu
function GameClient:RefreshShopMenu()
	local menu = self.UI.Menus.Shop
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Request shop items if we don't have them
	if not self.Cache.ShopItems or next(self.Cache.ShopItems) == nil then
		if self.RemoteFunctions.GetShopItems then
			local success, items = pcall(function()
				return self.RemoteFunctions.GetShopItems:InvokeServer()
			end)
			if success and items then
				self.Cache.ShopItems = items
			end
		end
	end

	if not self.Cache.ShopItems or next(self.Cache.ShopItems) == nil then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
		emptyLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
		emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "Shop items loading..."
		emptyLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.SourceSansSemibold
		emptyLabel.Parent = contentArea
		return
	end

	-- Create grid for shop items
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 180, 0, 220)
	gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	gridLayout.SortOrder = Enum.SortOrder.Name
	gridLayout.Parent = contentArea

	-- Add shop items to grid
	for itemId, itemData in pairs(self.Cache.ShopItems) do
		local itemCard = self:CreateShopItemCard(itemId, itemData)
		itemCard.Parent = contentArea
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		contentArea.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
	end)
end

function GameClient:CreateShopItemCard(itemId, itemData)
	local card = Instance.new("Frame")
	card.Name = itemId
	card.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = card

	-- Item image placeholder
	local image = Instance.new("Frame")
	image.Name = "Image"
	image.Size = UDim2.new(0.8, 0, 0.4, 0)
	image.Position = UDim2.new(0.5, 0, 0.2, 0)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	image.Parent = card

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0.1, 0)
	imageCorner.Parent = image

	-- Item emoji
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(1, 0, 1, 0)
	emoji.BackgroundTransparency = 1
	emoji.Text = self:GetItemEmoji(itemData.type or "item")
	emoji.TextScaled = true
	emoji.Font = Enum.Font.SourceSansSemibold
	emoji.Parent = image

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name or "Unknown Item"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansSemibold
	nameLabel.Parent = card

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
	descLabel.Position = UDim2.new(0.5, 0, 0.65, 0)
	descLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemData.description or ""
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.SourceSans
	descLabel.Parent = card

	-- Price and buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.8, 0, 0.12, 0)
	buyButton.Position = UDim2.new(0.5, 0, 0.88, 0)
	buyButton.AnchorPoint = Vector2.new(0.5, 0.5)
	buyButton.BorderSizePixel = 0
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.SourceSansSemibold
	buyButton.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = buyButton

	-- Check if player can afford
	local canAfford = self:CanAffordItem(itemData)
	local priceText = (itemData.price or 0) .. " " .. (itemData.currency or "Coins")

	buyButton.Text = "Buy: " .. priceText
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.BackgroundColor3 = canAfford and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
	buyButton.Active = canAfford

	if canAfford then
		buyButton.MouseButton1Click:Connect(function()
			if self.RemoteEvents.PurchaseItem then
				self.RemoteEvents.PurchaseItem:FireServer(itemId, 1)
			end
		end)
	end

	return card
end

function GameClient:GetItemEmoji(itemType)
	local emojis = {
		seed = "🌱",
		egg = "🥚",
		upgrade = "⬆️",
		booster = "⚡",
		pet = "🐾",
		default = "📦"
	}
	return emojis[itemType] or emojis.default
end

function GameClient:CanAffordItem(itemData)
	if not self.PlayerData or not itemData then return false end

	local currency = (itemData.currency or "coins"):lower()
	local playerAmount = self.PlayerData[currency] or 0
	local itemPrice = itemData.price or 0

	return playerAmount >= itemPrice
end

-- Farm Menu
function GameClient:RefreshFarmMenu()
	local menu = self.UI.Menus.Farm
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create farm interface
	local farmInfo = Instance.new("Frame")
	farmInfo.Name = "FarmInfo"
	farmInfo.Size = UDim2.new(1, 0, 0.3, 0)
	farmInfo.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	farmInfo.BorderSizePixel = 0
	farmInfo.Parent = contentArea

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0.02, 0)
	infoCorner.Parent = farmInfo

	local farmTitle = Instance.new("TextLabel")
	farmTitle.Size = UDim2.new(1, 0, 0.3, 0)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "🌾 Your Farm"
	farmTitle.TextColor3 = Color3.new(1, 1, 1)
	farmTitle.TextScaled = true
	farmTitle.Font = Enum.Font.SourceSansSemibold
	farmTitle.Parent = farmInfo

	local farmDesc = Instance.new("TextLabel")
	farmDesc.Size = UDim2.new(0.9, 0, 0.7, 0)
	farmDesc.Position = UDim2.new(0.05, 0, 0.3, 0)
	farmDesc.BackgroundTransparency = 1
	farmDesc.Text = "Plant seeds, grow crops, and feed your pig!\nVisit your farm in the game world to interact with your plots."
	farmDesc.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	farmDesc.TextScaled = true
	farmDesc.TextWrapped = true
	farmDesc.Font = Enum.Font.SourceSans
	farmDesc.Parent = farmInfo

	-- Farming inventory
	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "Inventory"
	inventoryFrame.Size = UDim2.new(1, 0, 0.65, 0)
	inventoryFrame.Position = UDim2.new(0, 0, 0.35, 0)
	inventoryFrame.BackgroundTransparency = 1
	inventoryFrame.Parent = contentArea

	local inventoryTitle = Instance.new("TextLabel")
	inventoryTitle.Size = UDim2.new(1, 0, 0.1, 0)
	inventoryTitle.BackgroundTransparency = 1
	inventoryTitle.Text = "Farming Inventory"
	inventoryTitle.TextColor3 = Color3.new(1, 1, 1)
	inventoryTitle.TextScaled = true
	inventoryTitle.Font = Enum.Font.SourceSansSemibold
	inventoryTitle.Parent = inventoryFrame

	-- Show farming inventory items
	if self.PlayerData.farming and self.PlayerData.farming.inventory then
		local yOffset = 0.15
		local itemHeight = 0.08

		for itemId, quantity in pairs(self.PlayerData.farming.inventory) do
			if quantity > 0 then
				local itemFrame = Instance.new("Frame")
				itemFrame.Size = UDim2.new(0.9, 0, itemHeight, 0)
				itemFrame.Position = UDim2.new(0.05, 0, yOffset, 0)
				itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
				itemFrame.BorderSizePixel = 0
				itemFrame.Parent = inventoryFrame

				local itemCorner = Instance.new("UICorner")
				itemCorner.CornerRadius = UDim.new(0.1, 0)
				itemCorner.Parent = itemFrame

				local itemLabel = Instance.new("TextLabel")
				itemLabel.Size = UDim2.new(0.8, 0, 1, 0)
				itemLabel.Position = UDim2.new(0.1, 0, 0, 0)
				itemLabel.BackgroundTransparency = 1
				itemLabel.Text = itemId:gsub("_", " "):gsub("^%l", string.upper) .. " x" .. quantity
				itemLabel.TextColor3 = Color3.new(1, 1, 1)
				itemLabel.TextScaled = true
				itemLabel.TextXAlignment = Enum.TextXAlignment.Left
				itemLabel.Font = Enum.Font.SourceSans
				itemLabel.Parent = itemFrame

				yOffset = yOffset + itemHeight + 0.02
			end
		end

		-- Pig status
		if self.PlayerData.farming.pig then
			local pig = self.PlayerData.farming.pig
			local pigFrame = Instance.new("Frame")
			pigFrame.Size = UDim2.new(0.9, 0, 0.15, 0)
			pigFrame.Position = UDim2.new(0.05, 0, yOffset + 0.05, 0)
			pigFrame.BackgroundColor3 = Color3.fromRGB(180, 120, 160)
			pigFrame.BorderSizePixel = 0
			pigFrame.Parent = inventoryFrame

			local pigCorner = Instance.new("UICorner")
			pigCorner.CornerRadius = UDim.new(0.05, 0)
			pigCorner.Parent = pigFrame

			local pigTitle = Instance.new("TextLabel")
			pigTitle.Size = UDim2.new(1, 0, 0.4, 0)
			pigTitle.BackgroundTransparency = 1
			pigTitle.Text = "🐷 Your Pig"
			pigTitle.TextColor3 = Color3.new(1, 1, 1)
			pigTitle.TextScaled = true
			pigTitle.Font = Enum.Font.SourceSansSemibold
			pigTitle.Parent = pigFrame

			local pigStatus = Instance.new("TextLabel")
			pigStatus.Size = UDim2.new(0.9, 0, 0.6, 0)
			pigStatus.Position = UDim2.new(0.05, 0, 0.4, 0)
			pigStatus.BackgroundTransparency = 1
			pigStatus.Text = "Fed: " .. (pig.feedCount or 0) .. " times | Size: " .. string.format("%.1f", pig.size or 1) .. "x"
			pigStatus.TextColor3 = Color3.new(0.9, 0.9, 0.9)
			pigStatus.TextScaled = true
			pigStatus.Font = Enum.Font.SourceSans
			pigStatus.Parent = pigFrame
		end
	else
		local noItemsLabel = Instance.new("TextLabel")
		noItemsLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
		noItemsLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		noItemsLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		noItemsLabel.BackgroundTransparency = 1
		noItemsLabel.Text = "No farming items yet!\nBuy seeds from the shop to get started."
		noItemsLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		noItemsLabel.TextScaled = true
		noItemsLabel.TextWrapped = true
		noItemsLabel.Font = Enum.Font.SourceSans
		noItemsLabel.Parent = inventoryFrame
	end
end

-- Settings Menu
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

	-- Simple settings for now
	local settingsLabel = Instance.new("TextLabel")
	settingsLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
	settingsLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
	settingsLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsLabel.BackgroundTransparency = 1
	settingsLabel.Text = "⚙️ Settings\n\nMore settings coming soon!"
	settingsLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	settingsLabel.TextScaled = true
	settingsLabel.Font = Enum.Font.SourceSansSemibold
	settingsLabel.Parent = contentArea
end

-- Effects and Notifications
function GameClient:PlayCollectionEffect(petData)
	-- Simple collection effect
	local character = LocalPlayer.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create floating text effect
	local effectGui = Instance.new("BillboardGui")
	effectGui.Size = UDim2.new(0, 200, 0, 100)
	effectGui.StudsOffset = Vector3.new(0, 5, 0)
	effectGui.Parent = rootPart

	local effectLabel = Instance.new("TextLabel")
	effectLabel.Size = UDim2.new(1, 0, 1, 0)
	effectLabel.BackgroundTransparency = 1

	-- Animate floating effect
	local petName = "Pet"
	if petData then
		petName = petData.name or petData.type or petData.id or "Pet"
	end
	effectLabel.Text = "+" .. petName

	effectLabel.TextColor3 = self:GetRarityColor(petData and petData.rarity or "Common")
	effectLabel.TextScaled = true
	effectLabel.Font = Enum.Font.SourceSansSemibold
	effectLabel.Parent = effectGui

	-- Animate floating effect
	local tween = TweenService:Create(effectGui, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 10, 0)
	})

	local fadeTween = TweenService:Create(effectLabel, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1
	})

	tween:Play()
	fadeTween:Play()

	tween.Completed:Connect(function()
		effectGui:Destroy()
	end)
end

function GameClient:ShowNotification(title, message, type)
	-- Validate inputs
	title = title or "Notification"
	message = message or ""
	type = type or "info"

	local notificationContainer = self.UI.Notifications

	local notification = Instance.new("Frame")
	notification.Name = "Notification_" .. tick()
	notification.Size = UDim2.new(0.3, 0, 0.1, 0)
	notification.Position = UDim2.new(1.1, 0, 0.15, 0)
	notification.AnchorPoint = Vector2.new(0, 0)
	notification.BackgroundColor3 = self:GetNotificationColor(type)
	notification.BorderSizePixel = 0
	notification.Parent = notificationContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = notification

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.95, 0, 0.4, 0)
	titleLabel.Position = UDim2.new(0.025, 0, 0.1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = tostring(title) -- Safe conversion
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.Parent = notification

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(0.95, 0, 0.4, 0)
	messageLabel.Position = UDim2.new(0.025, 0, 0.5, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = tostring(message) -- Safe conversion
	messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	messageLabel.TextScaled = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextWrapped = true
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.Parent = notification

	-- Animate notification
	local slideIn = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.99, 0, 0.15, 0)
	})

	slideIn:Play()

	-- Auto-remove after 4 seconds
	spawn(function()
		wait(4)
		local slideOut = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(1.1, 0, 0.15, 0)
		})
		slideOut:Play()
		slideOut.Completed:Connect(function()
			notification:Destroy()
		end)
	end)

	-- Play notification sound
	if self.Sounds.notification then
		self.Sounds.notification:Play()
	end
end

function GameClient:GetNotificationColor(type)
	local colors = {
		success = Color3.fromRGB(50, 150, 50),
		error = Color3.fromRGB(200, 50, 50),
		info = Color3.fromRGB(50, 100, 200),
		warning = Color3.fromRGB(200, 150, 50)
	}
	return colors[type] or colors.info
end

-- Data Management
function GameClient:RequestInitialData()
	-- Request player data
	if self.RemoteFunctions.GetPlayerData then
		spawn(function()
			local success, data = pcall(function()
				return self.RemoteFunctions.GetPlayerData:InvokeServer()
			end)
			if success and data then
				self:HandlePlayerDataUpdate(data)
			end
		end)
	end

	-- Request shop items
	if self.RemoteFunctions.GetShopItems then
		spawn(function()
			local success, items = pcall(function()
				return self.RemoteFunctions.GetShopItems:InvokeServer()
			end)
			if success and items then
				self.Cache.ShopItems = items
			end
		end)
	end
end

function GameClient:UpdateActiveMenus()
	-- Refresh currently open menu
	if self.UIState.CurrentPage then
		self:RefreshMenuContent(self.UIState.CurrentPage)
	end
end

-- Public API Methods
function GameClient:OpenShop()
	self:OpenMenu("Shop")
end

function GameClient:OpenPets()
	self:OpenMenu("Pets")
end

function GameClient:OpenFarm()
	self:OpenMenu("Farm")
end

function GameClient:GetPlayerData()
	return self.PlayerData
end

function GameClient:GetPlayerCurrency(currencyType)
	if not self.PlayerData then return 0 end
	return self.PlayerData[currencyType:lower()] or 0
end

-- Make globally available
_G.GameClient = GameClient

return GameClient