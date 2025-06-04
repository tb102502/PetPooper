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
	else
		warn("GameClient: Could not load ItemConfig: " .. tostring(result))
	end
end

loadItemConfig()

-- Player and Game State
local LocalPlayer = Players.LocalPlayer
GameClient.PlayerData = {}
GameClient.RemoteEvents = {}
GameClient.RemoteFunctions = {}
GameClient.UI = {}
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

-- Initialize the entire client system
function GameClient:Initialize()
	print("GameClient: Starting initialization...")

	local success, errorMsg = pcall(function()
		loadItemConfig()

		self:SetupRemoteConnections()
		self:SetupUI()
		self:SetupInputHandling()
		self:SetupLivestockInteractions()
		self:SetupFarmingSystem()
		self:RequestInitialData()
	end)

	if not success then
		error("GameClient initialization failed: " .. tostring(errorMsg))
	end

	print("GameClient: Initialization complete!")
	return true
end

-- Setup Remote Connections
function GameClient:SetupRemoteConnections()
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("GameClient: GameRemotes folder not found")
		return
	end

	local remoteEvents = {
		"CollectMilk", "FeedPig",
		"PurchaseItem", "ItemPurchased", "CurrencyUpdated", 
		"PlantSeed", "HarvestCrop", "SellCrop",
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

-- Setup Livestock Interactions
function GameClient:SetupLivestockInteractions()
	print("GameClient: Setting up livestock interactions...")

	-- Setup cow milk collection
	self:SetupCowInteraction()

	-- Setup pig feeding
	self:SetupPigInteraction()
end

-- Setup cow milk collection interaction
function GameClient:SetupCowInteraction()
	-- The cow interaction is handled server-side via ClickDetector
	-- We just need to provide UI feedback and handle the collection

	-- Create milk collection UI indicator
	self:CreateMilkCollectionUI()
end

-- Create milk collection UI
function GameClient:CreateMilkCollectionUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing UI
	local existingUI = playerGui:FindFirstChild("MilkCollectionUI")
	if existingUI then existingUI:Destroy() end

	local milkUI = Instance.new("ScreenGui")
	milkUI.Name = "MilkCollectionUI"
	milkUI.ResetOnSpawn = false
	milkUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	milkUI.Parent = playerGui

	-- Milk status display
	local milkFrame = Instance.new("Frame")
	milkFrame.Name = "MilkStatus"
	milkFrame.Size = UDim2.new(0, 200, 0, 60)
	milkFrame.Position = UDim2.new(0, 20, 0.3, 0)
	milkFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	milkFrame.BorderSizePixel = 0
	milkFrame.Parent = milkUI

	local milkCorner = Instance.new("UICorner")
	milkCorner.CornerRadius = UDim.new(0.1, 0)
	milkCorner.Parent = milkFrame

	local milkIcon = Instance.new("TextLabel")
	milkIcon.Size = UDim2.new(0, 40, 0, 40)
	milkIcon.Position = UDim2.new(0, 10, 0, 10)
	milkIcon.BackgroundTransparency = 1
	milkIcon.Text = "🥛"
	milkIcon.TextScaled = true
	milkIcon.Font = Enum.Font.SourceSansSemibold
	milkIcon.Parent = milkFrame

	local milkLabel = Instance.new("TextLabel")
	milkLabel.Name = "MilkLabel"
	milkLabel.Size = UDim2.new(1, -60, 1, 0)
	milkLabel.Position = UDim2.new(0, 55, 0, 0)
	milkLabel.BackgroundTransparency = 1
	milkLabel.Text = "Cow Ready!"
	milkLabel.TextColor3 = Color3.new(1, 1, 1)
	milkLabel.TextScaled = true
	milkLabel.Font = Enum.Font.GothamBold
	milkLabel.Parent = milkFrame

	self.UI.MilkCollectionUI = milkUI
	self.UI.MilkLabel = milkLabel

	-- Update milk status regularly
	spawn(function()
		while self.UI.MilkCollectionUI and self.UI.MilkCollectionUI.Parent do
			self:UpdateMilkStatus()
			wait(1)
		end
	end)
end

-- Update milk collection status
function GameClient:UpdateMilkStatus()
	if not self.UI.MilkLabel then return end

	local playerData = self:GetPlayerData()
	if not playerData then return end

	-- This would be updated by server events in a real implementation
	-- For now, we'll show basic status
	self.UI.MilkLabel.Text = "Click Cow to Collect Milk!"
	self.UI.MilkLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
end

-- Setup pig feeding interaction
function GameClient:SetupPigInteraction()
	-- Create pig feeding UI
	self:CreatePigFeedingUI()
end

-- Create pig feeding UI
function GameClient:CreatePigFeedingUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing UI
	local existingUI = playerGui:FindFirstChild("PigFeedingUI")
	if existingUI then existingUI:Destroy() end

	local pigUI = Instance.new("ScreenGui")
	pigUI.Name = "PigFeedingUI"
	pigUI.ResetOnSpawn = false
	pigUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pigUI.Parent = playerGui

	-- Pig feeding button
	local feedButton = Instance.new("TextButton")
	feedButton.Name = "PigFeedButton"
	feedButton.Size = UDim2.new(0, 120, 0, 50)
	feedButton.Position = UDim2.new(0, 20, 0.4, 0)
	feedButton.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
	feedButton.BorderSizePixel = 0
	feedButton.Text = "🐷 Feed Pig"
	feedButton.TextColor3 = Color3.new(0, 0, 0)
	feedButton.TextScaled = true
	feedButton.Font = Enum.Font.GothamBold
	feedButton.Parent = pigUI

	local feedCorner = Instance.new("UICorner")
	feedCorner.CornerRadius = UDim.new(0.1, 0)
	feedCorner.Parent = feedButton

	-- Pig status display
	local pigStatusFrame = Instance.new("Frame")
	pigStatusFrame.Name = "PigStatus"
	pigStatusFrame.Size = UDim2.new(0, 300, 0, 100)
	pigStatusFrame.Position = UDim2.new(0, 150, 0.4, 0)
	pigStatusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	pigStatusFrame.BorderSizePixel = 0
	pigStatusFrame.Visible = false
	pigStatusFrame.Parent = pigUI

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0.05, 0)
	statusCorner.Parent = pigStatusFrame

	local pigTitle = Instance.new("TextLabel")
	pigTitle.Size = UDim2.new(1, 0, 0.3, 0)
	pigTitle.BackgroundTransparency = 1
	pigTitle.Text = "🐷 Pig Status"
	pigTitle.TextColor3 = Color3.new(1, 1, 1)
	pigTitle.TextScaled = true
	pigTitle.Font = Enum.Font.GothamBold
	pigTitle.Parent = pigStatusFrame

	local pigStats = Instance.new("TextLabel")
	pigStats.Name = "PigStats"
	pigStats.Size = UDim2.new(0.9, 0, 0.7, 0)
	pigStats.Position = UDim2.new(0.05, 0, 0.3, 0)
	pigStats.BackgroundTransparency = 1
	pigStats.Text = "Size: 1.0x\nCrop Points: 0/100\nNext: MEGA PIG"
	pigStats.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	pigStats.TextScaled = true
	pigStats.Font = Enum.Font.Gotham
	pigStats.TextXAlignment = Enum.TextXAlignment.Left
	pigStats.Parent = pigStatusFrame

	self.UI.PigFeedingUI = pigUI
	self.UI.PigFeedButton = feedButton
	self.UI.PigStatusFrame = pigStatusFrame
	self.UI.PigStats = pigStats

	-- Connect feed button
	feedButton.MouseButton1Click:Connect(function()
		self:TogglePigFeedingMenu()
	end)
end

-- Toggle pig feeding menu
function GameClient:TogglePigFeedingMenu()
	if not self.UI.PigStatusFrame then return end

	local isVisible = self.UI.PigStatusFrame.Visible
	self.UI.PigStatusFrame.Visible = not isVisible

	if not isVisible then
		self:UpdatePigStatus()
		self:ShowCropFeedingOptions()
	end
end

-- Update pig status display
function GameClient:UpdatePigStatus()
	if not self.UI.PigStats then return end

	local playerData = self:GetPlayerData()
	if not playerData or not playerData.pig then return end

	local pig = playerData.pig
	local pointsNeeded = ItemConfig and ItemConfig.GetCropPointsForMegaPig and ItemConfig.GetCropPointsForMegaPig(pig.transformationCount or 0) or 100

	self.UI.PigStats.Text = string.format(
		"Size: %.1fx\nCrop Points: %d/%d\nTransformations: %d",
		pig.size or 1.0,
		pig.cropPoints or 0,
		pointsNeeded,
		pig.transformationCount or 0
	)
end

-- Show crop feeding options
function GameClient:ShowCropFeedingOptions()
	-- This would show a menu of available crops to feed
	-- For now, we'll create a simple interface

	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:ShowNotification("No Crops", "You need to harvest crops first!", "warning")
		return
	end

	-- Create feeding menu
	self:CreateCropFeedingMenu()
end

-- Create crop feeding menu
function GameClient:CreateCropFeedingMenu()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing menu
	local existingMenu = playerGui:FindFirstChild("CropFeedingMenu")
	if existingMenu then existingMenu:Destroy() end

	local feedingMenu = Instance.new("ScreenGui")
	feedingMenu.Name = "CropFeedingMenu"
	feedingMenu.ResetOnSpawn = false
	feedingMenu.Parent = playerGui

	local menuFrame = Instance.new("Frame")
	menuFrame.Size = UDim2.new(0, 400, 0, 300)
	menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	menuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	menuFrame.BorderSizePixel = 0
	menuFrame.Parent = feedingMenu

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0.02, 0)
	menuCorner.Parent = menuFrame

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = menuFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.1, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🐷 Feed Pig - Select Crop"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -70)
	scrollFrame.Position = UDim2.new(0, 10, 0, 60)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = menuFrame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scrollFrame

	-- Add crops to feed
	local playerData = self:GetPlayerData()
	if playerData and playerData.farming and playerData.farming.inventory then
		for cropId, quantity in pairs(playerData.farming.inventory) do
			if quantity > 0 and not cropId:find("_seeds") then
				self:CreateCropFeedItem(scrollFrame, cropId, quantity)
			end
		end
	end

	-- Update canvas size
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)

	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		feedingMenu:Destroy()
	end)

	self.UI.CropFeedingMenu = feedingMenu
end

-- Create crop feed item
function GameClient:CreateCropFeedItem(parent, cropId, quantity)
	local cropData = ItemConfig and ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
	local cropName = cropData and cropData.name or cropId:gsub("_", " ")
	local cropPoints = cropData and cropData.cropPoints or 1

	local cropItem = Instance.new("Frame")
	cropItem.Name = cropId .. "_FeedItem"
	cropItem.Size = UDim2.new(1, 0, 0, 70)
	cropItem.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	cropItem.BorderSizePixel = 0
	cropItem.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.05, 0)
	itemCorner.Parent = cropItem

	local cropIcon = Instance.new("TextLabel")
	cropIcon.Size = UDim2.new(0, 50, 0, 50)
	cropIcon.Position = UDim2.new(0, 10, 0, 10)
	cropIcon.BackgroundTransparency = 1
	cropIcon.Text = self:GetCropEmoji(cropId)
	cropIcon.TextScaled = true
	cropIcon.Font = Enum.Font.SourceSansSemibold
	cropIcon.Parent = cropItem

	local cropInfo = Instance.new("TextLabel")
	cropInfo.Size = UDim2.new(0.5, 0, 0.6, 0)
	cropInfo.Position = UDim2.new(0, 70, 0, 5)
	cropInfo.BackgroundTransparency = 1
	cropInfo.Text = cropName .. " x" .. quantity .. "\n+" .. cropPoints .. " crop points"
	cropInfo.TextColor3 = Color3.new(1, 1, 1)
	cropInfo.TextScaled = true
	cropInfo.Font = Enum.Font.Gotham
	cropInfo.TextXAlignment = Enum.TextXAlignment.Left
	cropInfo.Parent = cropItem

	local feedButton = Instance.new("TextButton")
	feedButton.Size = UDim2.new(0, 80, 0, 50)
	feedButton.Position = UDim2.new(1, -90, 0, 10)
	feedButton.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
	feedButton.BorderSizePixel = 0
	feedButton.Text = "Feed"
	feedButton.TextColor3 = Color3.new(0, 0, 0)
	feedButton.TextScaled = true
	feedButton.Font = Enum.Font.GothamBold
	feedButton.Parent = cropItem

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.1, 0)
	buttonCorner.Parent = feedButton

	-- Connect feed button
	feedButton.MouseButton1Click:Connect(function()
		if self.RemoteEvents.FeedPig then
			self.RemoteEvents.FeedPig:FireServer(cropId)
			-- Close the menu
			if self.UI.CropFeedingMenu then
				self.UI.CropFeedingMenu:Destroy()
			end
		end
	end)
end

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

-- Create farming UI (simplified version focusing on new system)
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
		self:ToggleFarmingUI()
	end)
end

-- Toggle farming UI
function GameClient:ToggleFarmingUI()
	-- This will open the existing farming interface
	-- We can reuse most of the existing farming UI code
	print("GameClient: Opening farming interface")
end

-- Setup farming inputs
function GameClient:SetupFarmingInputs()
	-- Keyboard shortcuts
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.F then
			self:ToggleFarmingUI()
		elseif input.KeyCode == Enum.KeyCode.M then
			-- Quick milk collection
			if self.RemoteEvents.CollectMilk then
				self.RemoteEvents.CollectMilk:FireServer()
			end
		elseif input.KeyCode == Enum.KeyCode.P then
			-- Quick pig feeding
			self:TogglePigFeedingMenu()
		end
	end)
end

-- UI System Setup (updated for new currency system)
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

-- Currency Display (updated for two currencies)
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

-- Navigation Bar (updated for new system)
function GameClient:SetupNavigationBar()
	local navBar = Instance.new("Frame")
	navBar.Name = "NavigationBar"
	navBar.Size = UDim2.new(1, 0, 0.08, 0)
	navBar.Position = UDim2.new(0, 0, 0.92, 0)
	navBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	navBar.BorderSizePixel = 0
	navBar.Parent = self.UI.Navigation

	local buttons = {
		{name = "Shop", icon = "🛒"},
		{name = "Farm", icon = "🌾"},
		{name = "Livestock", icon = "🐄"},
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

-- Menu system and other existing methods would go here...
-- (Include the existing menu creation and management code)

-- Setup Menus
function GameClient:SetupMenus()
	self.UI.Menus = {}
end

-- Event handlers
function GameClient:HandlePlayerDataUpdate(newData)
	if not newData then return end

	local oldData = self.PlayerData
	self.PlayerData = newData

	self:UpdateCurrencyDisplay()
	self:UpdatePigStatus()

	-- Update current page if needed
	if self.UIState.CurrentPage == "Shop" then
		self:RefreshShopMenu()
	elseif self.UIState.CurrentPage == "Farm" then
		self:RefreshFarmMenu()
	elseif self.UIState.CurrentPage == "Livestock" then
		self:RefreshLivestockMenu()
	end
end

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

	-- Show appropriate notification
	if itemId == "farm_plot_starter" then
		self:ShowNotification("🌾 Farm Plot Created!", 
			"Your farm plot is ready! Press F to start farming.", "success")
	elseif itemId:find("_seeds") then
		self:ShowNotification("Seeds Added!", 
			"Added " .. quantity .. "x seeds to your farming inventory!", "success")
	else
		self:ShowNotification("Purchase Complete!", 
			"Purchased " .. (ItemConfig.GetItem(itemId).name or itemId), "success")
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
		Farm = "🌾 Farming System",
		Livestock = "🐄 Livestock Management",
		Settings = "⚙️ Settings"
	}
	return titles[menuName] or menuName
end

function GameClient:RefreshMenuContent(menuName)
	if menuName == "Shop" then
		self:RefreshShopMenu()
	elseif menuName == "Farm" then
		self:RefreshFarmMenu()
	elseif menuName == "Livestock" then
		self:RefreshLivestockMenu()
	elseif menuName == "Settings" then
		self:RefreshSettingsMenu()
	end
end

-- Shop Menu (updated for new items)
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

			-- Create shop categories for new system
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

-- Livestock Menu
function GameClient:RefreshLivestockMenu()
	local menu = self.UI.Menus.Livestock
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 20)
	layout.Parent = contentArea

	-- Cow section
	self:CreateCowSection(contentArea, 1)

	-- Pig section  
	self:CreatePigSection(contentArea, 2)

	-- Update canvas size
	spawn(function()
		wait(0.1)
		contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)
end

function GameClient:CreateCowSection(parent, layoutOrder)
	local cowSection = Instance.new("Frame")
	cowSection.Name = "CowSection"
	cowSection.Size = UDim2.new(1, 0, 0, 200)
	cowSection.BackgroundColor3 = Color3.fromRGB(245, 245, 220)
	cowSection.BorderSizePixel = 0
	cowSection.LayoutOrder = layoutOrder
	cowSection.Parent = parent

	local cowCorner = Instance.new("UICorner")
	cowCorner.CornerRadius = UDim.new(0.05, 0)
	cowCorner.Parent = cowSection

	-- Cow title
	local cowTitle = Instance.new("TextLabel")
	cowTitle.Size = UDim2.new(1, 0, 0, 40)
	cowTitle.BackgroundTransparency = 1
	cowTitle.Text = "🐄 Cow - Milk Production"
	cowTitle.TextColor3 = Color3.new(0, 0, 0)
	cowTitle.TextScaled = true
	cowTitle.Font = Enum.Font.GothamBold
	cowTitle.Parent = cowSection

	-- Cow stats
	local cowStats = Instance.new("TextLabel")
	cowStats.Size = UDim2.new(0.6, 0, 1, -50)
	cowStats.Position = UDim2.new(0.05, 0, 0, 45)
	cowStats.BackgroundTransparency = 1
	cowStats.Text = "Next milk collection: Click cow when indicator is green!\nMilk value: 10 coins (+ upgrades)\nCooldown: 30 seconds (- upgrades)\n\nHotkey: M"
	cowStats.TextColor3 = Color3.new(0.2, 0.2, 0.2)
	cowStats.TextScaled = true
	cowStats.Font = Enum.Font.Gotham
	cowStats.TextXAlignment = Enum.TextXAlignment.Left
	cowStats.Parent = cowSection

	-- Collect milk button
	local milkButton = Instance.new("TextButton")
	milkButton.Size = UDim2.new(0.3, 0, 0.6, 0)
	milkButton.Position = UDim2.new(0.65, 0, 0.2, 0)
	milkButton.BackgroundColor3 = Color3.fromRGB(135, 206, 235)
	milkButton.BorderSizePixel = 0
	milkButton.Text = "🥛 Collect Milk"
	milkButton.TextColor3 = Color3.new(1, 1, 1)
	milkButton.TextScaled = true
	milkButton.Font = Enum.Font.GothamBold
	milkButton.Parent = cowSection

	local milkCorner = Instance.new("UICorner")
	milkCorner.CornerRadius = UDim.new(0.1, 0)
	milkCorner.Parent = milkButton

	milkButton.MouseButton1Click:Connect(function()
		if self.RemoteEvents.CollectMilk then
			self.RemoteEvents.CollectMilk:FireServer()
		end
	end)
end

function GameClient:CreatePigSection(parent, layoutOrder)
	local pigSection = Instance.new("Frame")
	pigSection.Name = "PigSection"
	pigSection.Size = UDim2.new(1, 0, 0, 250)
	pigSection.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
	pigSection.BorderSizePixel = 0
	pigSection.LayoutOrder = layoutOrder
	pigSection.Parent = parent

	local pigCorner = Instance.new("UICorner")
	pigCorner.CornerRadius = UDim.new(0.05, 0)
	pigCorner.Parent = pigSection

	-- Pig title
	local pigTitle = Instance.new("TextLabel")
	pigTitle.Size = UDim2.new(1, 0, 0, 40)
	pigTitle.BackgroundTransparency = 1
	pigTitle.Text = "🐷 Pig - Feed for MEGA Rewards!"
	pigTitle.TextColor3 = Color3.new(0, 0, 0)
	pigTitle.TextScaled = true
	pigTitle.Font = Enum.Font.GothamBold
	pigTitle.Parent = pigSection

	-- Pig stats
	local pigStats = Instance.new("TextLabel")
	pigStats.Name = "PigStatsDisplay"
	pigStats.Size = UDim2.new(0.6, 0, 1, -90)
	pigStats.Position = UDim2.new(0.05, 0, 0, 45)
	pigStats.BackgroundTransparency = 1
	pigStats.Text = "Size: 1.0x\nCrop Points: 0/100\nNext MEGA PIG: Feed 100 crop points\n\nFeed crops to grow pig and unlock exclusive upgrades!\nHotkey: P"
	pigStats.TextColor3 = Color3.new(0.2, 0.2, 0.2)
	pigStats.TextScaled = true
	pigStats.Font = Enum.Font.Gotham
	pigStats.TextXAlignment = Enum.TextXAlignment.Left
	pigStats.Parent = pigSection

	-- Feed pig button
	local feedButton = Instance.new("TextButton")
	feedButton.Size = UDim2.new(0.3, 0, 0.6, 0)
	feedButton.Position = UDim2.new(0.65, 0, 0.2, 0)
	feedButton.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
	feedButton.BorderSizePixel = 0
	feedButton.Text = "🌾 Feed Pig"
	feedButton.TextColor3 = Color3.new(1, 1, 1)
	feedButton.TextScaled = true
	feedButton.Font = Enum.Font.GothamBold
	feedButton.Parent = pigSection

	local feedCorner = Instance.new("UICorner")
	feedCorner.CornerRadius = UDim.new(0.1, 0)
	feedCorner.Parent = feedButton

	feedButton.MouseButton1Click:Connect(function()
		self:TogglePigFeedingMenu()
	end)

	-- Store reference for updates
	self.UI.PigStatsDisplay = pigStats
end

-- Farm Menu (reuse existing with updates)
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

	-- Create farm info section
	local farmInfo = Instance.new("Frame")
	farmInfo.Name = "FarmInfo"
	farmInfo.Size = UDim2.new(1, 0, 0.4, 0)
	farmInfo.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	farmInfo.BorderSizePixel = 0
	farmInfo.Parent = contentArea

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0.02, 0)
	infoCorner.Parent = farmInfo

	local farmTitle = Instance.new("TextLabel")
	farmTitle.Size = UDim2.new(1, 0, 0.2, 0)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "🌾 Farming System - Grow Crops for Farm Tokens!"
	farmTitle.TextColor3 = Color3.new(1, 1, 1)
	farmTitle.TextScaled = true
	farmTitle.Font = Enum.Font.GothamBold
	farmTitle.Parent = farmInfo

	local farmDesc = Instance.new("TextLabel")
	farmDesc.Size = UDim2.new(0.9, 0, 0.8, 0)
	farmDesc.Position = UDim2.new(0.05, 0, 0.2, 0)
	farmDesc.BackgroundTransparency = 1
	farmDesc.Text = "1. Buy seeds with COINS from the shop\n2. Plant seeds on your farm plots\n3. Harvest crops when ready\n4. Sell crops for FARM TOKENS or feed to pig\n5. Use Farm Tokens to buy premium seeds!"
	farmDesc.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	farmDesc.TextScaled = true
	farmDesc.TextWrapped = true
	farmDesc.Font = Enum.Font.Gotham
	farmDesc.TextXAlignment = Enum.TextXAlignment.Left
	farmDesc.Parent = farmInfo
end

-- Settings Menu
function GameClient:RefreshSettingsMenu()
	-- Keep existing settings menu implementation
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
	settingsInfo.Text = "⚙️ Game Controls:\n\nM - Quick milk collection\nP - Open pig feeding menu\nF - Open farming interface\nESC - Close menus\n\n🎮 About Pet Palace Farming:\nCollect milk from the cow for coins\nBuy and plant seeds with coins\nHarvest crops for Farm Tokens\nFeed crops to pig for exclusive upgrades!"
	settingsInfo.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	settingsInfo.TextScaled = true
	settingsInfo.TextWrapped = true
	settingsInfo.Font = Enum.Font.Gotham
	settingsInfo.TextXAlignment = Enum.TextXAlignment.Left
	settingsInfo.Parent = contentArea
end

-- Utility Methods
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

-- Helper functions
function GameClient:GetCropEmoji(cropId)
	local emojiMap = {
		carrot = "🥕",
		corn = "🌽",
		strawberry = "🍓", 
		golden_fruit = "✨"
	}
	return emojiMap[cropId] or "🌾"
end

-- Data Management
function GameClient:RequestInitialData()
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
end

function GameClient:GetPlayerData()
	return self.PlayerData
end

function GameClient:GetPlayerCurrency(currencyType)
	if not self.PlayerData then return 0 end
	return self.PlayerData[currencyType:lower()] or 0
end

-- Public API Methods
function GameClient:OpenShop()
	self:OpenMenu("Shop")
end

function GameClient:OpenFarm()
	self:OpenMenu("Farm")
end

function GameClient:OpenLivestock()
	self:OpenMenu("Livestock")
end

-- Make globally available
_G.GameClient = GameClient

-- Make livestock client functions available for other scripts
_G.LivestockClient = {
	CollectMilk = function() 
		if _G.GameClient and _G.GameClient.RemoteEvents.CollectMilk then
			_G.GameClient.RemoteEvents.CollectMilk:FireServer()
		end
	end,
	OpenPigFeeding = function() 
		if _G.GameClient and _G.GameClient.TogglePigFeedingMenu then
			_G.GameClient:TogglePigFeedingMenu()
		end
	end,
	OpenLivestockMenu = function() 
		if _G.GameClient and _G.GameClient.OpenLivestock then
			_G.GameClient:OpenLivestock()
		end
	end
}

print("GameClient: Livestock and farming system loaded!")

return GameClient--[[
    GameClient.lua - UPDATED FOR LIVESTOCK & FARMING SYSTEM
    Place in: ReplicatedStorage/GameClient.lua
    
    MAJOR CHANGES:
    - Removed pet collection system entirely
    - Added cow milk collection UI and interactions
    - Added pig feeding system UI
    - Updated shop UI for new items and currencies
    - Enhanced farming UI for new crop system
]]
