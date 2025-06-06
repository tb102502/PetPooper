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

-- UI State
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

	-- Step 3: Setup UI
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

	-- Shop proximity handlers
	if self.RemoteEvents.OpenShop then
		self.RemoteEvents.OpenShop.OnClientEvent:Connect(function()
			self:OpenMenu("Shop")
		end)
	end

	if self.RemoteEvents.CloseShop then
		self.RemoteEvents.CloseShop.OnClientEvent:Connect(function()
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

-- ========== PIG FEEDING SYSTEM ==========

-- Show pig feeding interface (proximity-based)
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

	-- Create pig feeding UI
	local pigUI = Instance.new("ScreenGui")
	pigUI.Name = "PigFeedingUI"
	pigUI.ResetOnSpawn = false
	pigUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pigUI.Parent = LocalPlayer.PlayerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 400, 0, 350)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 182, 193) -- Pink theme for pig
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = pigUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = mainFrame

	-- Title
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

	-- Pig status display
	local statusFrame = Instance.new("Frame")
	statusFrame.Size = UDim2.new(1, -20, 0, 80)
	statusFrame.Position = UDim2.new(0, 10, 0, 60)
	statusFrame.BackgroundColor3 = Color3.fromRGB(255, 192, 203)
	statusFrame.BorderSizePixel = 0
	statusFrame.Parent = mainFrame

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0.05, 0)
	statusCorner.Parent = statusFrame

	local pigStats = Instance.new("TextLabel")
	pigStats.Size = UDim2.new(0.9, 0, 1, 0)
	pigStats.Position = UDim2.new(0.05, 0, 0, 0)
	pigStats.BackgroundTransparency = 1
	pigStats.TextColor3 = Color3.new(0, 0, 0)
	pigStats.TextScaled = true
	pigStats.Font = Enum.Font.Gotham
	pigStats.TextXAlignment = Enum.TextXAlignment.Left
	pigStats.Parent = statusFrame

	-- Update pig stats
	self:UpdatePigStatsDisplay(pigStats, playerData)

	-- Crops scroll frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -160)
	scrollFrame.Position = UDim2.new(0, 10, 0, 150)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scrollFrame

	-- Add crops to feed
	for cropId, quantity in pairs(playerData.farming.inventory) do
		if quantity > 0 and not cropId:find("_seeds") then
			self:CreatePigFeedItem(scrollFrame, cropId, quantity)
		end
	end

	-- Update canvas size
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)

	-- Animate in
	mainFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
	local slideIn = TweenService:Create(mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0.5, 0)}
	)
	slideIn:Play()

	self.UI.PigFeedingUI = pigUI
end

-- Hide pig feeding interface
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

-- Update pig stats display
function GameClient:UpdatePigStatsDisplay(pigStats, playerData)
	if not pigStats or not playerData or not playerData.pig then return end

	local pig = playerData.pig
	local pointsNeeded = ItemConfig and ItemConfig.GetCropPointsForMegaPig and ItemConfig.GetCropPointsForMegaPig(pig.transformationCount or 0) or 100

	pigStats.Text = string.format(
		"🐷 Size: %.1fx  |  🌾 Crop Points: %d/%d  |  ⭐ Transformations: %d",
		pig.size or 1.0,
		pig.cropPoints or 0,
		pointsNeeded,
		pig.transformationCount or 0
	)
end

-- Create crop feed item for pig
function GameClient:CreatePigFeedItem(parent, cropId, quantity)
	local cropData = ItemConfig and ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
	local cropName = cropData and cropData.name or cropId:gsub("_", " ")
	local cropPoints = cropData and cropData.cropPoints or 1

	local cropItem = Instance.new("Frame")
	cropItem.Name = cropId .. "_FeedItem"
	cropItem.Size = UDim2.new(1, 0, 0, 60)
	cropItem.BackgroundColor3 = Color3.fromRGB(255, 240, 245)
	cropItem.BorderSizePixel = 0
	cropItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = cropItem

	local cropIcon = Instance.new("TextLabel")
	cropIcon.Size = UDim2.new(0, 40, 0, 40)
	cropIcon.Position = UDim2.new(0, 10, 0, 10)
	cropIcon.BackgroundTransparency = 1
	cropIcon.Text = self:GetCropEmoji(cropId)
	cropIcon.TextScaled = true
	cropIcon.Font = Enum.Font.SourceSansSemibold
	cropIcon.Parent = cropItem

	local cropInfo = Instance.new("TextLabel")
	cropInfo.Size = UDim2.new(0.5, 0, 1, 0)
	cropInfo.Position = UDim2.new(0, 60, 0, 0)
	cropInfo.BackgroundTransparency = 1
	cropInfo.Text = cropName .. " x" .. quantity .. "\n+" .. cropPoints .. " crop points"
	cropInfo.TextColor3 = Color3.new(0, 0, 0)
	cropInfo.TextScaled = true
	cropInfo.Font = Enum.Font.Gotham
	cropInfo.TextXAlignment = Enum.TextXAlignment.Left
	cropInfo.Parent = cropItem

	local feedButton = Instance.new("TextButton")
	feedButton.Size = UDim2.new(0, 100, 0, 40)
	feedButton.Position = UDim2.new(1, -110, 0, 10)
	feedButton.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
	feedButton.BorderSizePixel = 0
	feedButton.Text = "🐷 Feed"
	feedButton.TextColor3 = Color3.new(1, 1, 1)
	feedButton.TextScaled = true
	feedButton.Font = Enum.Font.GothamBold
	feedButton.Parent = cropItem

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = feedButton

	-- Connect feed button
	feedButton.MouseButton1Click:Connect(function()
		if self.RemoteEvents.FeedPig then
			self.RemoteEvents.FeedPig:FireServer(cropId)
			-- Update the display
			spawn(function()
				wait(0.5) -- Wait for server response
				local playerData = self:GetPlayerData()
				if playerData then
					local pigStats = cropItem.Parent.Parent:FindFirstChild("Frame"):FindFirstChild("TextLabel")
					if pigStats then
						self:UpdatePigStatsDisplay(pigStats, playerData)
					end
				end
			end)
		end
	end)

	-- Hover effects
	feedButton.MouseEnter:Connect(function()
		feedButton.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
	end)

	feedButton.MouseLeave:Connect(function()
		feedButton.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
	end)
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

-- Create farming UI
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

	-- Farming toggle button
	local farmButton = Instance.new("TextButton")
	farmButton.Name = "FarmingButton"
	farmButton.Size = UDim2.new(0, 120, 0, 50)
	farmButton.Position = UDim2.new(0, 20, 0.5, 0)
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

	self.UI.FarmingUI = farmingUI
	self.UI.FarmButton = farmButton

	-- Connect farming button
	farmButton.MouseButton1Click:Connect(function()
		self:OpenMenu("Farm")
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

-- ========== UI SYSTEM ==========

-- UI System Setup
function GameClient:SetupUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "GameUI"
	mainUI.ResetOnSpawn = false
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainUI.Parent = playerGui

	self.UI.MainUI = mainUI

	self:CreateUILayers(mainUI)
	self:SetupCurrencyDisplay()
	self:SetupNavigationBar()
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

-- Navigation Bar (updated - removed Shop and Livestock, kept Farm and Settings)
function GameClient:SetupNavigationBar()
	local navBar = Instance.new("Frame")
	navBar.Name = "NavigationBar"
	navBar.Size = UDim2.new(1, 0, 0.08, 0)
	navBar.Position = UDim2.new(0, 0, 0.92, 0)
	navBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	navBar.BorderSizePixel = 0
	navBar.Parent = self.UI.Navigation

	local buttons = {
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

	button.MouseEnter:Connect(function()
		TweenService:Create(background, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(65, 65, 75)}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(background, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
	end)

	return button
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
		self:RefreshFarmMenu() -- This will now show updated seed inventory
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
		Shop = "🛒 Shop - Seeds & Upgrades",
		Farm = "🌾 Farming Dashboard",
		Settings = "⚙️ Settings"
	}
	return titles[menuName] or menuName
end

function GameClient:RefreshMenuContent(menuName)
	if menuName == "Shop" then
		self:RefreshShopMenu()
	elseif menuName == "Farm" then
		self:RefreshFarmMenu()
	elseif menuName == "Settings" then
		self:RefreshSettingsMenu()
	end
end

-- ========== SHOP MENU ==========

-- Shop Menu
function GameClient:RefreshShopMenu()
	local menu = self.UI.Menus.Shop
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Load shop items from server
	if self.RemoteFunctions.GetShopItems then
		local success, shopItems = pcall(function()
			return self.RemoteFunctions.GetShopItems:InvokeServer()
		end)

		if success and shopItems then
			self.Cache.ShopItems = shopItems

			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 10)
			layout.Parent = contentArea

			-- Create shop categories
			local categories = {
				{name = "🥛 Livestock Upgrades", items = {}, priority = 1},
				{name = "🌾 Farming System", items = {}, priority = 2},
				{name = "🌱 Seeds & Crops", items = {}, priority = 3}
			}

			-- Sort items into categories
			for itemId, item in pairs(shopItems) do
				if item.category == "livestock" then
					table.insert(categories[1].items, {id = itemId, data = item})
				elseif item.category == "farming" or item.type == "farmPlot" then
					table.insert(categories[2].items, {id = itemId, data = item})
				elseif item.category == "seeds" then
					table.insert(categories[3].items, {id = itemId, data = item})
				end
			end

			-- Create UI for each category
			for i, category in ipairs(categories) do
				if #category.items > 0 then
					self:CreateShopCategory(contentArea, category.name, category.items, i)
				end
			end

			-- Update canvas size
			spawn(function()
				wait(0.2)
				if layout and layout.Parent and contentArea then
					contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 40)
				end
			end)
		end
	end
end

function GameClient:CreateShopCategory(parent, categoryName, items, layoutOrder)
	local categoryFrame = Instance.new("Frame")
	categoryFrame.Name = categoryName .. "_Category"
	categoryFrame.Size = UDim2.new(1, -12, 0, 60 + (#items * 80))
	categoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	categoryFrame.BorderSizePixel = 0
	categoryFrame.LayoutOrder = layoutOrder
	categoryFrame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = categoryFrame

	-- Category title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	title.BorderSizePixel = 0
	title.Text = categoryName
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = categoryFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = title

	-- Items container
	local itemsContainer = Instance.new("Frame")
	itemsContainer.Size = UDim2.new(1, -20, 1, -50)
	itemsContainer.Position = UDim2.new(0, 10, 0, 45)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.Parent = categoryFrame

	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	itemsLayout.Padding = UDim.new(0, 5)
	itemsLayout.Parent = itemsContainer

	-- Add items
	for i, itemInfo in ipairs(items) do
		self:CreateShopItem(itemsContainer, itemInfo.id, itemInfo.data, i)
	end
end

function GameClient:CreateShopItem(parent, itemId, itemData, layoutOrder)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = itemId .. "_Item"
	itemFrame.Size = UDim2.new(1, 0, 0, 70)
	itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = layoutOrder
	itemFrame.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.05, 0)
	itemCorner.Parent = itemFrame

	-- Item icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 10, 0, 10)
	icon.BackgroundTransparency = 1
	icon.Text = itemData.icon or "📦"
	icon.TextScaled = true
	icon.Font = Enum.Font.SourceSansSemibold
	icon.Parent = itemFrame

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 70, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name or itemId
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
	descLabel.Position = UDim2.new(0, 70, 0, 35)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemData.description or "No description"
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = itemFrame

	-- Price label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 0.4, 0)
	priceLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
	priceLabel.BackgroundTransparency = 1
	local currencyIcon = (itemData.currency == "farmTokens") and "🌾" or "💰"
	priceLabel.Text = (itemData.price or 0) .. " " .. currencyIcon
	priceLabel.TextColor3 = (itemData.currency == "farmTokens") and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(255, 215, 0)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = itemFrame

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.2, 0, 0.6, 0)
	buyButton.Position = UDim2.new(0.75, 0, 0.2, 0)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	buyButton.BorderSizePixel = 0
	buyButton.Text = "Buy"
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = itemFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.1, 0)
	buyCorner.Parent = buyButton

	-- Check if player can afford
	local playerData = self.PlayerData
	if playerData then
		local currency = itemData.currency or "coins"
		local playerCurrency = playerData[currency] or 0
		local canAfford = playerCurrency >= (itemData.price or 0)

		if not canAfford then
			buyButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
			buyButton.Text = "Can't Afford"
			buyButton.Active = false
		end
	end

	-- Buy button click
	buyButton.MouseButton1Click:Connect(function()
		if self.RemoteEvents.PurchaseItem then
			self.RemoteEvents.PurchaseItem:FireServer(itemId, 1)
		end
	end)
end

-- ========== FARM MENU (ENHANCED) ==========

-- Enhanced Farm Menu with Seed Inventory Display
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

	-- SECTION 2: Seed Inventory Display
	self:CreateSeedInventorySection(contentArea, layout)

	-- SECTION 3: Crop Inventory Display
	self:CreateCropInventorySection(contentArea, layout)

	-- SECTION 4: Quick Actions
	self:CreateFarmingActionsSection(contentArea, layout)

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if layout and layout.Parent and contentArea then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end)
end

-- Create seed inventory section
function GameClient:CreateSeedInventorySection(parent, layout)
	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		-- Show "no seeds" message
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

		return
	end

	-- Create seed inventory frame
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

	-- Title
	local seedTitle = Instance.new("TextLabel")
	seedTitle.Size = UDim2.new(1, 0, 0, 30)
	seedTitle.BackgroundTransparency = 1
	seedTitle.Text = "🌱 Your Seed Inventory"
	seedTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
	seedTitle.TextScaled = true
	seedTitle.Font = Enum.Font.GothamBold
	seedTitle.Parent = seedFrame

	-- Seed scroll area
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
			self:CreateSeedInventoryItem(seedScroll, itemId, quantity)
			seedCount = seedCount + 1
		end
	end

	-- Update title with count
	seedTitle.Text = "🌱 Your Seed Inventory (" .. seedCount .. " types)"

	-- Update canvas size
	seedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		seedScroll.CanvasSize = UDim2.new(0, 0, 0, seedLayout.AbsoluteContentSize.Y + 10)
	end)

	-- If no seeds, show helper message
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
end

-- Create individual seed inventory item
function GameClient:CreateSeedInventoryItem(parent, seedId, quantity)
	local seedData = ItemConfig and ItemConfig.GetSeedData and ItemConfig.GetSeedData(seedId)
	local seedInfo = ItemConfig and ItemConfig.GetItem and ItemConfig.GetItem(seedId)

	local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
	local growTime = seedData and seedData.growTime or 300
	local yieldAmount = seedData and seedData.yieldAmount or 1

	local seedItem = Instance.new("Frame")
	seedItem.Name = seedId .. "_Item"
	seedItem.Size = UDim2.new(1, 0, 0, 80)
	seedItem.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
	seedItem.BorderSizePixel = 0
	seedItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = seedItem

	-- Seed icon
	local seedIcon = Instance.new("TextLabel")
	seedIcon.Size = UDim2.new(0, 50, 0, 50)
	seedIcon.Position = UDim2.new(0, 10, 0, 15)
	seedIcon.BackgroundTransparency = 1
	seedIcon.Text = seedInfo and seedInfo.icon or "🌱"
	seedIcon.TextScaled = true
	seedIcon.Font = Enum.Font.SourceSansSemibold
	seedIcon.Parent = seedItem

	-- Seed info
	local seedInfoLabel = Instance.new("TextLabel")
	seedInfoLabel.Size = UDim2.new(0.5, 0, 0.6, 0)
	seedInfoLabel.Position = UDim2.new(0, 70, 0, 5)
	seedInfoLabel.BackgroundTransparency = 1
	seedInfoLabel.Text = seedName .. " x" .. quantity .. "\nGrow time: " .. math.floor(growTime/60) .. " min | Yield: " .. yieldAmount
	seedInfoLabel.TextColor3 = Color3.new(1, 1, 1)
	seedInfoLabel.TextScaled = true
	seedInfoLabel.Font = Enum.Font.Gotham
	seedInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
	seedInfoLabel.Parent = seedItem

	-- Plant button
	local plantButton = Instance.new("TextButton")
	plantButton.Size = UDim2.new(0, 120, 0, 50)
	plantButton.Position = UDim2.new(1, -130, 0, 15)
	plantButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	plantButton.BorderSizePixel = 0
	plantButton.Text = "🌱 Go Plant"
	plantButton.TextColor3 = Color3.new(1, 1, 1)
	plantButton.TextScaled = true
	plantButton.Font = Enum.Font.GothamBold
	plantButton.Parent = seedItem

	local plantCorner = Instance.new("UICorner")
	plantCorner.CornerRadius = UDim.new(0.2, 0)
	plantCorner.Parent = plantButton

	-- Connect plant button
	plantButton.MouseButton1Click:Connect(function()
		self:StartPlantingMode(seedId)
	end)

	-- Hover effects
	plantButton.MouseEnter:Connect(function()
		plantButton.BackgroundColor3 = Color3.fromRGB(120, 220, 120)
	end)

	plantButton.MouseLeave:Connect(function()
		plantButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	end)

	-- Selected seed indicator
	if self.FarmingState.selectedSeed == seedId then
		seedItem.BackgroundColor3 = Color3.fromRGB(70, 100, 70)
		plantButton.Text = "✅ Selected"
		plantButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	end
end

-- Create crop inventory section
function GameClient:CreateCropInventorySection(parent, layout)
	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		return
	end

	-- Check if player has any crops
	local hasCrops = false
	for itemId, quantity in pairs(playerData.farming.inventory) do
		if not itemId:find("_seeds") and quantity > 0 then
			hasCrops = true
			break
		end
	end

	if not hasCrops then return end

	-- Create crop inventory frame
	local cropFrame = Instance.new("Frame")
	cropFrame.Name = "CropInventory"
	cropFrame.Size = UDim2.new(1, 0, 0, 150)
	cropFrame.BackgroundColor3 = Color3.fromRGB(60, 50, 40)
	cropFrame.BorderSizePixel = 0
	cropFrame.LayoutOrder = 3
	cropFrame.Parent = parent

	local cropCorner = Instance.new("UICorner")
	cropCorner.CornerRadius = UDim.new(0.02, 0)
	cropCorner.Parent = cropFrame

	-- Title
	local cropTitle = Instance.new("TextLabel")
	cropTitle.Size = UDim2.new(1, 0, 0, 30)
	cropTitle.BackgroundTransparency = 1
	cropTitle.Text = "🥕 Your Harvested Crops"
	cropTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
	cropTitle.TextScaled = true
	cropTitle.Font = Enum.Font.GothamBold
	cropTitle.Parent = cropFrame

	-- Crop scroll area
	local cropScroll = Instance.new("ScrollingFrame")
	cropScroll.Size = UDim2.new(1, -20, 1, -40)
	cropScroll.Position = UDim2.new(0, 10, 0, 35)
	cropScroll.BackgroundTransparency = 1
	cropScroll.ScrollBarThickness = 6
	cropScroll.Parent = cropFrame

	local cropLayout = Instance.new("UIGridLayout")
	cropLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cropLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	cropLayout.CellSize = UDim2.new(0, 180, 0, 60)
	cropLayout.Parent = cropScroll

	-- Add crops to inventory display
	for itemId, quantity in pairs(playerData.farming.inventory) do
		if not itemId:find("_seeds") and quantity > 0 then
			self:CreateCropInventoryItem(cropScroll, itemId, quantity)
		end
	end

	-- Update canvas size
	cropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		cropScroll.CanvasSize = UDim2.new(0, 0, 0, cropLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- Create individual crop inventory item
function GameClient:CreateCropInventoryItem(parent, cropId, quantity)
	local cropData = ItemConfig and ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
	local cropName = cropData and cropData.name or cropId:gsub("_", " ")
	local sellValue = cropData and cropData.sellValue or 1

	local cropItem = Instance.new("Frame")
	cropItem.Name = cropId .. "_Item"
	cropItem.Size = UDim2.new(0, 180, 0, 60)
	cropItem.BackgroundColor3 = Color3.fromRGB(70, 60, 50)
	cropItem.BorderSizePixel = 0
	cropItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = cropItem

	-- Crop icon
	local cropIcon = Instance.new("TextLabel")
	cropIcon.Size = UDim2.new(0, 30, 0, 30)
	cropIcon.Position = UDim2.new(0, 5, 0, 15)
	cropIcon.BackgroundTransparency = 1
	cropIcon.Text = self:GetCropEmoji(cropId)
	cropIcon.TextScaled = true
	cropIcon.Font = Enum.Font.SourceSansSemibold
	cropIcon.Parent = cropItem

	-- Crop info
	local cropInfo = Instance.new("TextLabel")
	cropInfo.Size = UDim2.new(0, 90, 1, 0)
	cropInfo.Position = UDim2.new(0, 40, 0, 0)
	cropInfo.BackgroundTransparency = 1
	cropInfo.Text = cropName .. " x" .. quantity .. "\n" .. sellValue .. " 🌾 each"
	cropInfo.TextColor3 = Color3.new(1, 1, 1)
	cropInfo.TextScaled = true
	cropInfo.Font = Enum.Font.Gotham
	cropInfo.TextXAlignment = Enum.TextXAlignment.Left
	cropInfo.Parent = cropItem

	-- Sell button
	local sellButton = Instance.new("TextButton")
	sellButton.Size = UDim2.new(0, 45, 0, 45)
	sellButton.Position = UDim2.new(1, -50, 0, 7)
	sellButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
	sellButton.BorderSizePixel = 0
	sellButton.Text = "💰"
	sellButton.TextColor3 = Color3.new(1, 1, 1)
	sellButton.TextScaled = true
	sellButton.Font = Enum.Font.GothamBold
	sellButton.Parent = cropItem

	local sellCorner = Instance.new("UICorner")
	sellCorner.CornerRadius = UDim.new(0.2, 0)
	sellCorner.Parent = sellButton

	-- Connect sell button
	sellButton.MouseButton1Click:Connect(function()
		if self.RemoteEvents.SellCrop then
			self.RemoteEvents.SellCrop:FireServer(cropId, 1)
		end
	end)
end

-- Create farming actions section
function GameClient:CreateFarmingActionsSection(parent, layout)
	local actionsFrame = Instance.new("Frame")
	actionsFrame.Name = "FarmingActions"
	actionsFrame.Size = UDim2.new(1, 0, 0, 100)
	actionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	actionsFrame.BorderSizePixel = 0
	actionsFrame.LayoutOrder = 4
	actionsFrame.Parent = parent

	local actionsCorner = Instance.new("UICorner")
	actionsCorner.CornerRadius = UDim.new(0.02, 0)
	actionsCorner.Parent = actionsFrame

	-- Quick actions layout
	local actionsLayout = Instance.new("UIListLayout")
	actionsLayout.FillDirection = Enum.FillDirection.Horizontal
	actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actionsLayout.Padding = UDim.new(0, 20)
	actionsLayout.Parent = actionsFrame

	-- Go to Farm button
	local goToFarmButton = Instance.new("TextButton")
	goToFarmButton.Size = UDim2.new(0, 150, 0, 60)
	goToFarmButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
	goToFarmButton.BorderSizePixel = 0
	goToFarmButton.Text = "🚜 Go to Farm"
	goToFarmButton.TextColor3 = Color3.new(1, 1, 1)
	goToFarmButton.TextScaled = true
	goToFarmButton.Font = Enum.Font.GothamBold
	goToFarmButton.Parent = actionsFrame

	local farmCorner = Instance.new("UICorner")
	farmCorner.CornerRadius = UDim.new(0.1, 0)
	farmCorner.Parent = goToFarmButton

	-- Go to Shop button
	local goToShopButton = Instance.new("TextButton")
	goToShopButton.Size = UDim2.new(0, 150, 0, 60)
	goToShopButton.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
	goToShopButton.BorderSizePixel = 0
	goToShopButton.Text = "🛒 Buy Seeds"
	goToShopButton.TextColor3 = Color3.new(1, 1, 1)
	goToShopButton.TextScaled = true
	goToShopButton.Font = Enum.Font.GothamBold
	goToShopButton.Parent = actionsFrame

	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0.1, 0)
	shopCorner.Parent = goToShopButton

	-- Connect buttons
	goToFarmButton.MouseButton1Click:Connect(function()
		self:CloseActiveMenus()
		self:TeleportToFarm()
	end)

	goToShopButton.MouseButton1Click:Connect(function()
		self:CloseActiveMenus()
		self:TeleportToShop()
	end)
end

-- ========== PLANTING SYSTEM ==========

-- Start planting mode
function GameClient:StartPlantingMode(seedId)
	print("GameClient: Starting planting mode with seed:", seedId)

	self.FarmingState.selectedSeed = seedId
	self.FarmingState.isPlantingMode = true

	-- Update UI to show selected seed
	self:RefreshFarmMenu()

	-- Close farm menu to allow planting
	self:CloseActiveMenus()

	-- Show planting instruction
	self:ShowNotification("🌱 Planting Mode Active", 
		"Go to your farm and click on empty plots to plant " .. seedId:gsub("_", " ") .. "!", "success")

	-- Create planting mode UI indicator
	self:CreatePlantingModeUI(seedId)
end

-- Create planting mode UI
function GameClient:CreatePlantingModeUI(seedId)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing planting UI
	local existingUI = playerGui:FindFirstChild("PlantingModeUI")
	if existingUI then existingUI:Destroy() end

	local plantingUI = Instance.new("ScreenGui")
	plantingUI.Name = "PlantingModeUI"
	plantingUI.ResetOnSpawn = false
	plantingUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	plantingUI.Parent = playerGui

	-- Planting indicator
	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 300, 0, 80)
	indicator.Position = UDim2.new(0.5, -150, 0, 20)
	indicator.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
	indicator.BorderSizePixel = 0
	indicator.Parent = plantingUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0.6, 0)
	label.Position = UDim2.new(0.1, 0, 0.1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🌱 PLANTING: " .. seedId:gsub("_", " "):upper()
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = indicator

	local instruction = Instance.new("TextLabel")
	instruction.Size = UDim2.new(0.8, 0, 0.3, 0)
	instruction.Position = UDim2.new(0.1, 0, 0.7, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = "Click empty farm plots to plant seeds"
	instruction.TextColor3 = Color3.fromRGB(200, 255, 200)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.Gotham
	instruction.Parent = indicator

	-- Cancel button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0, 80, 0, 25)
	cancelButton.Position = UDim2.new(1, -85, 0, 5)
	cancelButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = Color3.new(1, 1, 1)
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.Gotham
	cancelButton.Parent = indicator

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0.2, 0)
	cancelCorner.Parent = cancelButton

	cancelButton.MouseButton1Click:Connect(function()
		self:ExitPlantingMode()
	end)

	self.UI.PlantingModeUI = plantingUI
end

-- Exit planting mode
function GameClient:ExitPlantingMode()
	print("GameClient: Exiting planting mode")

	self.FarmingState.selectedSeed = nil
	self.FarmingState.isPlantingMode = false

	-- Remove planting UI
	if self.UI.PlantingModeUI then
		self.UI.PlantingModeUI:Destroy()
		self.UI.PlantingModeUI = nil
	end

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local existingUI = playerGui:FindFirstChild("PlantingModeUI")
	if existingUI then existingUI:Destroy() end

	self:ShowNotification("🌱 Planting Mode", "Planting mode deactivated", "info")
end

-- ========== SETTINGS MENU ==========

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

	-- Create settings content
	local settingsInfo = Instance.new("TextLabel")
	settingsInfo.Size = UDim2.new(0.9, 0, 1, 0)
	settingsInfo.Position = UDim2.new(0.05, 0, 0, 0)
	settingsInfo.BackgroundTransparency = 1
	settingsInfo.Text = "⚙️ Game Controls:\n\nF - Open farming interface\nESC - Close menus\n\n🎮 About Pet Palace Farming:\n\n🐄 Cow Milk Collection:\n- Click the cow directly when indicator is green\n- Cow moos when you collect milk!\n- Upgrades reduce cooldown and increase value\n\n🐷 Pig Feeding:\n- Walk close to the pig to see feeding interface\n- Feed crops to grow pig and unlock MEGA rewards\n- Pig oinks when you feed it!\n\n🛒 Shop:\n- Walk up to the shop building to browse items\n- Buy seeds with coins, premium items with farm tokens\n\n🌾 Farming:\n- Plant seeds, harvest crops, sell for farm tokens\n- Use farming interface (F key) to manage your crops"
	settingsInfo.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	settingsInfo.TextScaled = true
	settingsInfo.TextWrapped = true
	settingsInfo.Font = Enum.Font.Gotham
	settingsInfo.TextXAlignment = Enum.TextXAlignment.Left
	settingsInfo.Parent = contentArea
end

-- ========== TELEPORT HELPERS ==========

-- Teleport to farm
function GameClient:TeleportToFarm()
	local player = LocalPlayer
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	-- Look for player's farm in workspace
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
	if playerFarm then
		local firstPlot = playerFarm:FindFirstChild("FarmPlot_1")
		if firstPlot and firstPlot.PrimaryPart then
			local teleportPos = firstPlot.PrimaryPart.Position + Vector3.new(0, 5, 10)
			player.Character.HumanoidRootPart.CFrame = CFrame.new(teleportPos)
			self:ShowNotification("🚜 Teleported", "Welcome to your farm!", "success")
			return
		end
	end

	-- Fallback to general farm area
	local generalFarmPos = Vector3.new(-350, 5, 120)
	player.Character.HumanoidRootPart.CFrame = CFrame.new(generalFarmPos)
	self:ShowNotification("🚜 Teleported", "Teleported to farm area!", "info")
end

-- Teleport to shop
function GameClient:TeleportToShop()
	local player = LocalPlayer
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	-- Teleport to shop area
	local shopPos = Vector3.new(-250, 5, 120)
	player.Character.HumanoidRootPart.CFrame = CFrame.new(shopPos)
	self:ShowNotification("🛒 Teleported", "Welcome to the shop!", "success")
end

-- ========== UTILITY METHODS ==========

-- Get crop emoji
function GameClient:GetCropEmoji(cropId)
	local emojiMap = {
		carrot = "🥕",
		corn = "🌽",
		strawberry = "🍓", 
		golden_fruit = "✨"
	}
	return emojiMap[cropId] or "🌾"
end

-- Show notification
function GameClient:ShowNotification(title, message, type)
	if not title or not message then return end

	print("Notification [" .. (type or "info"):upper() .. "]: " .. title .. " - " .. message)

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

-- ========== DATA MANAGEMENT ==========

-- Request initial player data from server
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
					},
					stats = {
						milkCollected = 0,
						coinsEarned = 100,
						cropsHarvested = 0,
						pigFed = 0,
						megaTransformations = 0
					}
				})
			end
		end)
	else
		warn("GameClient: GetPlayerData remote function not available")
	end
end

-- Get current player data
function GameClient:GetPlayerData()
	return self.PlayerData
end

-- Get player currency amount
function GameClient:GetPlayerCurrency(currencyType)
	if not self.PlayerData then return 0 end
	return self.PlayerData[currencyType:lower()] or 0
end

-- Handle character respawning
function GameClient:HandleCharacterRespawn(character)
	print("GameClient: Handling character respawn")
	-- Reapply any character-based modifications here if needed
	-- For now, just ensure UI is still visible
	if self.UI.MainUI then
		self.UI.MainUI.Parent = LocalPlayer.PlayerGui
	end
end

-- ========== PUBLIC API METHODS ==========

-- Public method to open shop menu
function GameClient:OpenShop()
	self:OpenMenu("Shop")
end

-- Public method to open farm menu  
function GameClient:OpenFarm()
	self:OpenMenu("Farm")
end

-- Public method to open settings
function GameClient:OpenSettings()
	self:OpenMenu("Settings")
end

-- Public method to close all menus
function GameClient:CloseMenus()
	self:CloseActiveMenus()
end

-- ========== DEBUG AND UTILITY ==========

-- Debug function to check GameClient status
function GameClient:DebugStatus()
	print("=== GAMECLIENT DEBUG STATUS ===")
	print("PlayerData exists:", self.PlayerData ~= nil)
	print("RemoteEvents count:", self.RemoteEvents and self:CountTable(self.RemoteEvents) or 0)
	print("RemoteFunctions count:", self.RemoteFunctions and self:CountTable(self.RemoteFunctions) or 0)
	print("UI systems:", self.UI and "Available" or "Missing")
	print("Farming state:", self.FarmingState and "Available" or "Missing")

	if self.PlayerData then
		print("Coins:", self.PlayerData.coins or 0)
		print("Farm Tokens:", self.PlayerData.farmTokens or 0)
		print("Has farming data:", self.PlayerData.farming ~= nil)
		if self.PlayerData.farming and self.PlayerData.farming.inventory then
			local seedCount = 0
			for itemId, quantity in pairs(self.PlayerData.farming.inventory) do
				if itemId:find("_seeds") then
					seedCount = seedCount + quantity
				end
			end
			print("Total seeds:", seedCount)
		end
	end
	print("===============================")
end

-- Debug function to check farming data
function GameClient:DebugFarmingData()
	local playerData = self:GetPlayerData()
	print("=== FARMING DEBUG ===")
	print("Player Data Exists:", playerData ~= nil)

	if playerData then
		print("Has Farming Data:", playerData.farming ~= nil)

		if playerData.farming then
			print("Plots:", playerData.farming.plots or "nil")
			print("Inventory Exists:", playerData.farming.inventory ~= nil)

			if playerData.farming.inventory then
				print("Inventory Contents:")
				for itemId, quantity in pairs(playerData.farming.inventory) do
					print("  " .. itemId .. ": " .. quantity)
				end
			end
		end
	end
	print("=== END DEBUG ===")
end

-- Count table entries
function GameClient:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- Error recovery function
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

	-- Try to reconnect remotes
	local success, error = pcall(function()
		self:SetupRemoteConnections()
	end)

	if success then
		print("GameClient: Recovery successful")
		return true
	else
		warn("GameClient: Recovery failed: " .. tostring(error))
		return false
	end
end

-- ========== GLOBAL REGISTRATION ==========

-- Make GameClient globally available
_G.GameClient = GameClient

-- Create a more robust global check
_G.GetGameClient = function()
	if _G.GameClient and type(_G.GameClient) == "table" then
		return _G.GameClient
	else
		warn("GameClient not available globally")
		return nil
	end
end

-- Make debug functions globally available
_G.DebugGameClient = function()
	if _G.GameClient and _G.GameClient.DebugStatus then
		_G.GameClient:DebugStatus()
	else
		print("GameClient or DebugStatus method not available")
	end
end

_G.DebugFarming = function()
	if _G.GameClient and _G.GameClient.DebugFarmingData then
		_G.GameClient:DebugFarmingData()
	else
		print("GameClient or DebugFarmingData method not available")
	end
end

-- ========== FINAL MESSAGES ==========

print("GameClient: Enhanced livestock and farming system loaded!")
print("✅ Fixed initialization and missing methods")
print("✅ Complete farming system with seed inventory")
print("✅ Proximity-based shop and pig feeding")
print("✅ Enhanced UI with proper navigation")
print("✅ Sound effects integration ready")
print("")
print("Available Features:")
print("🐄 Click cow directly for milk collection")
print("🐷 Walk close to pig for feeding interface")  
print("🛒 Walk to shop building for shopping")
print("🌾 Complete farming system (F key)")
print("🎮 Updated navigation (Farm & Settings)")
print("")
print("Debug Commands (Console):")
print("  _G.DebugGameClient() - Show GameClient status")
print("  _G.DebugFarming() - Show farming data")
print("  _G.GetGameClient() - Get GameClient safely")
print("")
print("Key Controls:")
print("  F - Open Farm menu")
print("  ESC - Close menus")
print("  Click plots to plant/harvest")
print("  Walk near pig/shop for proximity interactions")

-- Return the GameClient module
return GameClient-- Setup Input Handling