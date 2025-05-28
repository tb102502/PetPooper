-- StatsUI.lua - Player stats display system
-- Add this to GameClient for stats display

-- Add this to GameClient.lua
local Player = game.Players.LocalPlayer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameClient = require(ReplicatedStorage.GameClient)
function GameClient:CreateStatsMenu()
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsMenu"
	statsFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
	statsFrame.Position = UDim2.new(0.2, 0, 0.15, 0)
	statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	statsFrame.BorderSizePixel = 0
	statsFrame.Visible = false
	statsFrame.Parent = self.UI.Overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = statsFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "📊 Player Stats & Upgrades"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = statsFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0.02, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.BorderSizePixel = 0
	closeButton.Parent = statsFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.3, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		statsFrame.Visible = false
	end)

	-- Stats container
	local statsContainer = Instance.new("ScrollingFrame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(0.45, 0, 0.85, 0)
	statsContainer.Position = UDim2.new(0.025, 0, 0.12, 0)
	statsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	statsContainer.BorderSizePixel = 0
	statsContainer.ScrollBarThickness = 8
	statsContainer.Parent = statsFrame

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0.02, 0)
	statsCorner.Parent = statsContainer

	-- Upgrades container
	local upgradesContainer = Instance.new("ScrollingFrame")
	upgradesContainer.Name = "UpgradesContainer"
	upgradesContainer.Size = UDim2.new(0.45, 0, 0.85, 0)
	upgradesContainer.Position = UDim2.new(0.525, 0, 0.12, 0)
	upgradesContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	upgradesContainer.BorderSizePixel = 0
	upgradesContainer.ScrollBarThickness = 8
	upgradesContainer.Parent = statsFrame

	local upgradesCorner = Instance.new("UICorner")
	upgradesCorner.CornerRadius = UDim.new(0.02, 0)
	upgradesCorner.Parent = upgradesContainer

	-- Stats layout
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Padding = UDim.new(0.01, 0)
	statsLayout.Parent = statsContainer

	-- Upgrades layout
	local upgradesLayout = Instance.new("UIListLayout")
	upgradesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	upgradesLayout.Padding = UDim.new(0.01, 0)
	upgradesLayout.Parent = upgradesContainer

	-- Section headers
	self:CreateStatSection(statsContainer, "📈 Player Statistics", true)
	self:CreateStatSection(upgradesContainer, "⬆️ Upgrades & Abilities", true)

	self.UI.StatsMenu = statsFrame
	return statsFrame
end

function GameClient:CreateStatSection(parent, title, isHeader)
	local section = Instance.new("Frame")
	section.Name = title
	section.Size = UDim2.new(1, -10, 0, isHeader and 40 or 30)
	section.BackgroundColor3 = isHeader and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(40, 40, 50)
	section.BorderSizePixel = 0
	section.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = section

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = title
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = isHeader and Enum.Font.SourceSansBold or Enum.Font.SourceSans
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = section

	return section
end

function GameClient:CreateStatItem(parent, statName, statValue, icon)
	local item = Instance.new("Frame")
	item.Name = statName
	item.Size = UDim2.new(1, -10, 0, 25)
	item.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	item.BorderSizePixel = 0
	item.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = item

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0.1, 0, 1, 0)
	iconLabel.Position = UDim2.new(0, 5, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon or "📊"
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.TextScaled = true
	iconLabel.Parent = item

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
	nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = statName
	nameLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = item

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0.25, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.75, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(statValue)
	valueLabel.TextColor3 = Color3.new(1, 1, 0.5)
	valueLabel.TextScaled = true
	valueLabel.Font = Enum.Font.SourceSansBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = item

	return item
end

function GameClient:UpdateStatsDisplay()
	if not self.UI.StatsMenu or not self.PlayerData then return end

	local statsContainer = self.UI.StatsMenu:FindFirstChild("StatsContainer")
	local upgradesContainer = self.UI.StatsMenu:FindFirstChild("UpgradesContainer")

	if not statsContainer or not upgradesContainer then return end

	-- Clear existing items (except headers)
	for _, child in pairs(statsContainer:GetChildren()) do
		if child:IsA("Frame") and not child.Name:find("Statistics") then
			child:Destroy()
		end
	end

	for _, child in pairs(upgradesContainer:GetChildren()) do
		if child:IsA("Frame") and not child.Name:find("Upgrades") then
			child:Destroy()
		end
	end

	-- Player stats
	local stats = self.PlayerData.stats or {}
	self:CreateStatItem(statsContainer, "Pets Collected", stats.totalPetsCollected or 0, "🐾")
	self:CreateStatItem(statsContainer, "Coins Earned", stats.coinsEarned or 0, "💰")
	self:CreateStatItem(statsContainer, "Items Purchased", stats.itemsPurchased or 0, "🛒")
	self:CreateStatItem(statsContainer, "Crops Harvested", stats.cropsHarvested or 0, "🌾")
	self:CreateStatItem(statsContainer, "Pets Sold", stats.petsSold or 0, "💸")

	-- Current resources
	self:CreateStatItem(statsContainer, "Current Coins", self.PlayerData.coins or 0, "💰")
	self:CreateStatItem(statsContainer, "Current Gems", self.PlayerData.gems or 0, "💎")
	self:CreateStatItem(statsContainer, "Owned Pets", #(self.PlayerData.pets and self.PlayerData.pets.owned or {}), "🐕")

	-- Upgrades and abilities
	local upgrades = self.PlayerData.upgrades or {}
	self:CreateStatItem(upgradesContainer, "Walk Speed", (upgrades.speed_upgrade or 0) * 2 + 16, "⚡")
	self:CreateStatItem(upgradesContainer, "Collection Speed", string.format("%.1f", (upgrades.collection_upgrade or 0) * 0.1 + 1.0) .. "x", "🧲")
	self:CreateStatItem(upgradesContainer, "Farm Plots", (upgrades.farm_plot_upgrade or 0) + 3, "🌱")
	self:CreateStatItem(upgradesContainer, "Pet Storage", self:GetPlayerMaxPets(Players.LocalPlayer.UserId), "📦")

	-- Resize containers
	statsContainer.CanvasSize = UDim2.new(0, 0, 0, statsContainer.UIListLayout.AbsoluteContentSize.Y + 10)
	upgradesContainer.CanvasSize = UDim2.new(0, 0, 0, upgradesContainer.UIListLayout.AbsoluteContentSize.Y + 10)
end

function GameClient:OpenStats()
	if not self.UI.StatsMenu then
		self:CreateStatsMenu()
	end

	self:UpdateStatsDisplay()
	self.UI.StatsMenu.Visible = true
end