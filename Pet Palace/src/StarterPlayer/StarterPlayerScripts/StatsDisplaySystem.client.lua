--[[
    StatsDisplaySystem.client.lua - PLAYER STATS UI SYSTEM
    Place in: StarterPlayerScripts/StatsDisplaySystem.client.lua
    
    Features:
    - Real-time stats display
    - Upgrade visualization 
    - Progress tracking
    - Performance metrics
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Wait for GameClient
local GameClient = _G.GameClient
if not GameClient then
	local clientReady = ReplicatedStorage:WaitForChild("GameClientReady", 10)
	if clientReady then
		clientReady.Event:Wait()
		GameClient = _G.GameClient
	end
end

if not GameClient then
	error("StatsDisplaySystem: GameClient not available")
end

local StatsSystem = {}

-- UI References
StatsSystem.UI = {
	MainFrame = nil,
	StatsContainer = nil,
	UpgradesContainer = nil,
	ToggleButton = nil
}

-- Stats tracking
StatsSystem.CurrentStats = {
	walkSpeed = 16,
	collectionRadius = 5,
	magnetStrength = 8,
	farmPlots = 3,
	petStorage = 100,
	-- Performance stats
	petsCollected = 0,
	coinsEarned = 0,
	totalPlayTime = 0
}

-- Create the main stats UI
function StatsSystem:CreateStatsUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing UI
	local existingUI = playerGui:FindFirstChild("StatsUI")
	if existingUI then
		existingUI:Destroy()
	end

	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StatsUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Toggle button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "StatsToggle"
	toggleButton.Size = UDim2.new(0, 120, 0, 40)
	toggleButton.Position = UDim2.new(0, 20, 0.3, 0)
	toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = "📊 Stats"
	toggleButton.TextColor3 = Color3.new(1, 1, 1)
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0.1, 0)
	toggleCorner.Parent = toggleButton

	-- Main stats frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "StatsFrame"
	mainFrame.Size = UDim2.new(0, 700, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0.02, 0)
	mainCorner.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.1, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "📊 Player Statistics & Upgrades"
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

	-- Content area
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, 0, 1, -60)
	contentFrame.Position = UDim2.new(0, 0, 0, 60)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame

	-- Left side - Current Stats
	local statsContainer = Instance.new("ScrollingFrame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(0.48, 0, 1, 0)
	statsContainer.Position = UDim2.new(0.01, 0, 0, 0)
	statsContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	statsContainer.BorderSizePixel = 0
	statsContainer.ScrollBarThickness = 6
	statsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	statsContainer.Parent = contentFrame

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0.02, 0)
	statsCorner.Parent = statsContainer

	-- Right side - Upgrades
	local upgradesContainer = Instance.new("ScrollingFrame")
	upgradesContainer.Name = "UpgradesContainer"
	upgradesContainer.Size = UDim2.new(0.48, 0, 1, 0)
	upgradesContainer.Position = UDim2.new(0.51, 0, 0, 0)
	upgradesContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	upgradesContainer.BorderSizePixel = 0
	upgradesContainer.ScrollBarThickness = 6
	upgradesContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	upgradesContainer.Parent = contentFrame

	local upgradesCorner = Instance.new("UICorner")
	upgradesCorner.CornerRadius = UDim.new(0.02, 0)
	upgradesCorner.Parent = upgradesContainer

	-- Store references
	self.UI.MainFrame = mainFrame
	self.UI.StatsContainer = statsContainer
	self.UI.UpgradesContainer = upgradesContainer
	self.UI.ToggleButton = toggleButton

	-- Connect events
	toggleButton.MouseButton1Click:Connect(function()
		self:ToggleStatsUI()
	end)

	closeButton.MouseButton1Click:Connect(function()
		self:HideStatsUI()
	end)

	-- Setup layouts
	self:SetupLayouts()

	print("StatsSystem: UI created successfully")
end

-- Setup scroll layouts
function StatsSystem:SetupLayouts()
	-- Stats container layout
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Padding = UDim.new(0, 5)
	statsLayout.Parent = self.UI.StatsContainer

	statsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.UI.StatsContainer.CanvasSize = UDim2.new(0, 0, 0, statsLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Upgrades container layout
	local upgradesLayout = Instance.new("UIListLayout")
	upgradesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	upgradesLayout.Padding = UDim.new(0, 5)
	upgradesLayout.Parent = self.UI.UpgradesContainer

	upgradesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.UI.UpgradesContainer.CanvasSize = UDim2.new(0, 0, 0, upgradesLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- Create section header
function StatsSystem:CreateSectionHeader(parent, title, layoutOrder)
	local header = Instance.new("Frame")
	header.Name = title .. "_Header"
	header.Size = UDim2.new(1, -10, 0, 35)
	header.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	header.BorderSizePixel = 0
	header.LayoutOrder = layoutOrder or 1
	header.Parent = parent

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.1, 0)
	headerCorner.Parent = header

	local headerLabel = Instance.new("TextLabel")
	headerLabel.Size = UDim2.new(1, -10, 1, 0)
	headerLabel.Position = UDim2.new(0, 5, 0, 0)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = title
	headerLabel.TextColor3 = Color3.new(1, 1, 1)
	headerLabel.TextScaled = true
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Parent = header

	return header
end

-- Create stat item
function StatsSystem:CreateStatItem(parent, name, value, icon, layoutOrder, maxValue)
	local item = Instance.new("Frame")
	item.Name = name .. "_Item"
	item.Size = UDim2.new(1, -10, 0, 50)
	item.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	item.BorderSizePixel = 0
	item.LayoutOrder = layoutOrder or 10
	item.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.1, 0)
	itemCorner.Parent = item

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 40, 1, 0)
	iconLabel.Position = UDim2.new(0, 5, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon or "📊"
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.SourceSansSemibold
	iconLabel.Parent = item

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, -50, 1, 0)
	nameLabel.Position = UDim2.new(0, 45, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = item

	-- Value
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(value)
	valueLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	valueLabel.TextScaled = true
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = item

	-- Progress bar (if maxValue provided)
	if maxValue and maxValue > 0 then
		local progressBG = Instance.new("Frame")
		progressBG.Size = UDim2.new(0.18, 0, 0.3, 0)
		progressBG.Position = UDim2.new(0.8, 0, 0.35, 0)
		progressBG.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		progressBG.BorderSizePixel = 0
		progressBG.Parent = item

		local progressBar = Instance.new("Frame")
		progressBar.Name = "ProgressBar"
		progressBar.Size = UDim2.new(math.min(value / maxValue, 1), 0, 1, 0)
		progressBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		progressBar.BorderSizePixel = 0
		progressBar.Parent = progressBG

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(0.5, 0)
		barCorner.Parent = progressBG

		local barCorner2 = Instance.new("UICorner")
		barCorner2.CornerRadius = UDim.new(0.5, 0)
		barCorner2.Parent = progressBar
	end

	return item
end

-- Create upgrade item with purchase button
function StatsSystem:CreateUpgradeItem(parent, upgradeId, layoutOrder)
	local playerData = GameClient:GetPlayerData()
	if not playerData then return end

	-- Get upgrade info from ItemConfig
	local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("ItemConfig"))
	local upgrade = ItemConfig.ShopItems[upgradeId]
	if not upgrade then return end

	local currentLevel = playerData.upgrades[upgradeId] or 0
	local maxLevel = upgrade.maxLevel or 10
	local nextCost = ItemConfig.GetNextUpgradeCost(upgradeId, currentLevel)
	local currentEffect = ItemConfig.GetUpgradeEffect(upgradeId, currentLevel)

	local item = Instance.new("Frame")
	item.Name = upgradeId .. "_Upgrade"
	item.Size = UDim2.new(1, -10, 0, 80)
	item.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	item.BorderSizePixel = 0
	item.LayoutOrder = layoutOrder or 10
	item.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.05, 0)
	itemCorner.Parent = item

	-- Upgrade name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = upgrade.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = item

	-- Level info
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
	levelLabel.Position = UDim2.new(0.65, 0, 0.05, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Level " .. currentLevel .. "/" .. maxLevel
	levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextXAlignment = Enum.TextXAlignment.Right
	levelLabel.Parent = item

	-- Description/Effect
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.6, 0, 0.3, 0)
	descLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = upgrade.description .. " (Current: " .. currentEffect .. ")"
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = item

	-- Purchase button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0.3, 0, 0.5, 0)
	buyButton.Position = UDim2.new(0.65, 0, 0.4, 0)
	buyButton.BorderSizePixel = 0
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = item

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.1, 0)
	buyCorner.Parent = buyButton

	-- Configure button based on upgrade state
	if currentLevel >= maxLevel then
		buyButton.Text = "MAX LEVEL"
		buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		buyButton.TextColor3 = Color3.fromRGB(180, 180, 180)
		buyButton.Active = false
	elseif nextCost > 0 then
		local currency = upgrade.currency or "coins"
		local currencySymbol = currency == "coins" and "💰" or "💎"
		local playerCurrency = playerData[currency] or 0
		local canAfford = playerCurrency >= nextCost

		buyButton.Text = "Buy: " .. nextCost .. " " .. currencySymbol
		buyButton.BackgroundColor3 = canAfford and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(120, 60, 60)
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.Active = canAfford

		if canAfford then
			buyButton.MouseButton1Click:Connect(function()
				self:PurchaseUpgrade(upgradeId)
			end)
		end
	end

	-- Progress bar
	local progressBG = Instance.new("Frame")
	progressBG.Size = UDim2.new(0.9, 0, 0.15, 0)
	progressBG.Position = UDim2.new(0.05, 0, 0.8, 0)
	progressBG.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	progressBG.BorderSizePixel = 0
	progressBG.Parent = item

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(currentLevel / maxLevel, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBG

	local progCorner = Instance.new("UICorner")
	progCorner.CornerRadius = UDim.new(0.5, 0)
	progCorner.Parent = progressBG

	local progCorner2 = Instance.new("UICorner")
	progCorner2.CornerRadius = UDim.new(0.5, 0)
	progCorner2.Parent = progressBar

	return item
end

-- Purchase upgrade
function StatsSystem:PurchaseUpgrade(upgradeId)
	if GameClient and GameClient.RemoteEvents and GameClient.RemoteEvents.PurchaseItem then
		GameClient.RemoteEvents.PurchaseItem:FireServer(upgradeId, 1)
		print("StatsSystem: Purchasing upgrade:", upgradeId)
	end
end

-- Update all stats display
function StatsSystem:UpdateStatsDisplay()
	if not self.UI.StatsContainer or not self.UI.UpgradesContainer then return end

	local playerData = GameClient:GetPlayerData()
	if not playerData then return end

	-- Clear existing items
	for _, child in pairs(self.UI.StatsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, child in pairs(self.UI.UpgradesContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get current upgrade levels
	local upgrades = playerData.upgrades or {}
	local speedLevel = upgrades.speed_upgrade or 0
	local collectionLevel = upgrades.collection_radius_upgrade or 0
	local magnetLevel = upgrades.pet_magnet_upgrade or 0
	local farmLevel = upgrades.farm_plot_upgrade or 0
	local storageLevel = upgrades.pet_storage_upgrade or 0

	-- Calculate current stats
	self.CurrentStats.walkSpeed = 16 + (speedLevel * 2)
	self.CurrentStats.collectionRadius = 5 + (collectionLevel * 1)
	self.CurrentStats.magnetStrength = 8 + (magnetLevel * 2)
	self.CurrentStats.farmPlots = 3 + farmLevel
	self.CurrentStats.petStorage = 100 + (storageLevel * 25)

	-- STATS SECTION
	self:CreateSectionHeader(self.UI.StatsContainer, "🏃 Movement & Collection", 1)
	self:CreateStatItem(self.UI.StatsContainer, "Walk Speed", self.CurrentStats.walkSpeed, "⚡", 2)
	self:CreateStatItem(self.UI.StatsContainer, "Collection Radius", self.CurrentStats.collectionRadius .. " studs", "🎯", 3)
	self:CreateStatItem(self.UI.StatsContainer, "Pet Magnet Range", self.CurrentStats.magnetStrength .. " studs", "🧲", 4)

	self:CreateSectionHeader(self.UI.StatsContainer, "🌾 Farming & Storage", 5)
	self:CreateStatItem(self.UI.StatsContainer, "Farm Plots", self.CurrentStats.farmPlots, "🌱", 6)
	self:CreateStatItem(self.UI.StatsContainer, "Pet Storage", self.CurrentStats.petStorage, "📦", 7)

	self:CreateSectionHeader(self.UI.StatsContainer, "📈 Performance Stats", 8)
	local stats = playerData.stats or {}
	self:CreateStatItem(self.UI.StatsContainer, "Pets Collected", stats.totalPetsCollected or 0, "🐾", 9)
	self:CreateStatItem(self.UI.StatsContainer, "Coins Earned", stats.coinsEarned or 0, "💰", 10)
	self:CreateStatItem(self.UI.StatsContainer, "Crops Harvested", stats.cropsHarvested or 0, "🌾", 11)
	self:CreateStatItem(self.UI.StatsContainer, "Pets Sold", stats.petsSold or 0, "💸", 12)

	self:CreateSectionHeader(self.UI.StatsContainer, "💎 Current Resources", 13)
	self:CreateStatItem(self.UI.StatsContainer, "Coins", playerData.coins or 0, "💰", 14)
	self:CreateStatItem(self.UI.StatsContainer, "Gems", playerData.gems or 0, "💎", 15)
	self:CreateStatItem(self.UI.StatsContainer, "Owned Pets", #(playerData.pets and playerData.pets.owned or {}), "🐕", 16)

	-- UPGRADES SECTION
	self:CreateSectionHeader(self.UI.UpgradesContainer, "⬆️ Available Upgrades", 1)
	self:CreateUpgradeItem(self.UI.UpgradesContainer, "speed_upgrade", 2)
	self:CreateUpgradeItem(self.UI.UpgradesContainer, "collection_radius_upgrade", 3)
	self:CreateUpgradeItem(self.UI.UpgradesContainer, "pet_magnet_upgrade", 4)
	self:CreateUpgradeItem(self.UI.UpgradesContainer, "farm_plot_upgrade", 5)
	self:CreateUpgradeItem(self.UI.UpgradesContainer, "pet_storage_upgrade", 6)

	print("StatsSystem: Display updated with current player stats")
end

-- Toggle stats UI visibility
function StatsSystem:ToggleStatsUI()
	if not self.UI.MainFrame then return end

	local isVisible = self.UI.MainFrame.Visible
	if isVisible then
		self:HideStatsUI()
	else
		self:ShowStatsUI()
	end
end

-- Show stats UI
function StatsSystem:ShowStatsUI()
	if not self.UI.MainFrame then return end

	self:UpdateStatsDisplay()
	self.UI.MainFrame.Visible = true

	-- Animate in
	self.UI.MainFrame.Position = UDim2.new(0.5, -350, 1.2, 0)
	local tween = TweenService:Create(self.UI.MainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -350, 0.5, -250)}
	)
	tween:Play()
end

-- Hide stats UI
function StatsSystem:HideStatsUI()
	if not self.UI.MainFrame then return end

	local tween = TweenService:Create(self.UI.MainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, -350, 1.2, 0)}
	)
	tween:Play()

	tween.Completed:Connect(function()
		self.UI.MainFrame.Visible = false
	end)
end

-- Listen for player data updates
function StatsSystem:ConnectToUpdates()
	if GameClient and GameClient.RemoteEvents then
		-- Listen for player data updates
		if GameClient.RemoteEvents.PlayerDataUpdated then
			GameClient.RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function()
				if self.UI.MainFrame and self.UI.MainFrame.Visible then
					self:UpdateStatsDisplay()
				end
			end)
		end

		-- Listen for currency updates
		if GameClient.RemoteEvents.CurrencyUpdated then
			GameClient.RemoteEvents.CurrencyUpdated.OnClientEvent:Connect(function()
				if self.UI.MainFrame and self.UI.MainFrame.Visible then
					self:UpdateStatsDisplay()
				end
			end)
		end

		-- Listen for item purchases
		if GameClient.RemoteEvents.ItemPurchased then
			GameClient.RemoteEvents.ItemPurchased.OnClientEvent:Connect(function()
				if self.UI.MainFrame and self.UI.MainFrame.Visible then
					wait(0.5) -- Small delay to ensure data is updated
					self:UpdateStatsDisplay()
				end
			end)
		end
	end
end

-- Setup keybind
function StatsSystem:SetupKeybind()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.P then -- P for Player stats
			self:ToggleStatsUI()
		end
	end)
end

-- Initialize the system
function StatsSystem:Initialize()
	self:CreateStatsUI()
	self:ConnectToUpdates()
	self:SetupKeybind()

	-- Auto-update every 5 seconds if visible
	spawn(function()
		while true do
			wait(5)
			if self.UI.MainFrame and self.UI.MainFrame.Visible then
				self:UpdateStatsDisplay()
			end
		end
	end)

	print("StatsSystem: Initialized successfully (Press P to open)")
end

-- Make globally available
_G.StatsSystem = StatsSystem

-- Initialize when script runs
StatsSystem:Initialize()

return StatsSystem