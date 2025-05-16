-- UpgradeShopUI.client.lua
-- Place this in StarterGui/MainGui/ContentFrame/UpgradesFrame
-- Handles the client-side upgrade UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local UpgradeSystem = require(ReplicatedStorage:WaitForChild("UpgradeSystem"))

-- Get remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyUpgrade = RemoteEvents:WaitForChild("BuyUpgrade")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")

-- Get UI references
local upgradesFrame = script.Parent
local categoryButtons = upgradesFrame:WaitForChild("CategoryButtons")
local upgradesList = upgradesFrame:WaitForChild("UpgradesList")
local upgradeTemplate = upgradesList:WaitForChild("UpgradeTemplate")

-- If the template doesn't exist, create it
if not upgradeTemplate then
	upgradeTemplate = CreateUpgradeTemplate()
	upgradeTemplate.Parent = upgradesList
end

-- Ensure the template is not visible
upgradeTemplate.Visible = false

-- Player data
local playerData = {
	coins = 0,
	upgrades = {}
}

-- Current category
local currentCategory = "Collecting"

-- Function to create an upgrade template (if it doesn't exist)
function CreateUpgradeTemplate()
	local template = Instance.new("Frame")
	template.Name = "UpgradeTemplate"
	template.Size = UDim2.new(1, -20, 0, 100)
	template.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	template.BorderColor3 = Color3.fromRGB(200, 200, 200)
	template.BorderSizePixel = 2
	template.Visible = false

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = template

	-- Add icon
	local iconFrame = Instance.new("ImageLabel")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 80, 0, 80)
	iconFrame.Position = UDim2.new(0, 10, 0, 10)
	iconFrame.BackgroundTransparency = 1
	iconFrame.Image = "rbxassetid://7733673307" -- Default star icon
	iconFrame.Parent = template

	-- Add upgrade name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -110, 0, 30)
	nameLabel.Position = UDim2.new(0, 100, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = "Upgrade Name"
	nameLabel.Parent = template

	-- Add description
	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "DescriptionLabel"
	descriptionLabel.Size = UDim2.new(1, -110, 0, 40)
	descriptionLabel.Position = UDim2.new(0, 100, 0, 35)
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	descriptionLabel.TextSize = 14
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
	descriptionLabel.TextWrapped = true
	descriptionLabel.Text = "Upgrade description goes here with details about what this upgrade does."
	descriptionLabel.Parent = template

	-- Add level indicator
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0, 100, 0, 20)
	levelLabel.Position = UDim2.new(0, 100, 0, 75)
	levelLabel.BackgroundTransparency = 1
	levelLabel.TextColor3 = Color3.fromRGB(50, 100, 50)
	levelLabel.TextSize = 14
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Text = "Level: 0/10"
	levelLabel.Parent = template

	-- Add buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0, 120, 0, 30)
	buyButton.Position = UDim2.new(1, -130, 0, 70)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 16
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Text = "Buy: 100"
	buyButton.Parent = template

	-- Add rounded corners to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = buyButton

	-- Add locked overlay (for locked upgrades)
	local lockedOverlay = Instance.new("Frame")
	lockedOverlay.Name = "LockedOverlay"
	lockedOverlay.Size = UDim2.new(1, 0, 1, 0)
	lockedOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	lockedOverlay.BackgroundTransparency = 0.7
	lockedOverlay.Visible = false
	lockedOverlay.ZIndex = 5
	lockedOverlay.Parent = template

	-- Add lock icon
	local lockIcon = Instance.new("ImageLabel")
	lockIcon.Name = "LockIcon"
	lockIcon.Size = UDim2.new(0, 40, 0, 40)
	lockIcon.Position = UDim2.new(0.5, -20, 0.5, -35)
	lockIcon.BackgroundTransparency = 1
	lockIcon.Image = "rbxassetid://7734053495" -- Lock icon
	lockIcon.ZIndex = 6
	lockIcon.Parent = lockedOverlay

	-- Add locked text
	local lockedText = Instance.new("TextLabel")
	lockedText.Name = "LockedText"
	lockedText.Size = UDim2.new(1, -20, 0, 30)
	lockedText.Position = UDim2.new(0, 10, 0.5, 5)
	lockedText.BackgroundTransparency = 1
	lockedText.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockedText.TextSize = 14
	lockedText.Font = Enum.Font.GothamBold
	lockedText.Text = "Requires: Auto-Collect Pass"
	lockedText.ZIndex = 6
	lockedText.Parent = lockedOverlay

	-- Add corners to locked overlay
	local lockedCorner = Instance.new("UICorner")
	lockedCorner.CornerRadius = UDim.new(0, 8)
	lockedCorner.Parent = lockedOverlay

	return template
end

-- Function to create category buttons if they don't exist
function EnsureCategoryButtons()
	if categoryButtons:FindFirstChild("Collecting") then return end

	for i, category in ipairs(UpgradeSystem.Categories) do
		local button = Instance.new("TextButton")
		button.Name = category
		button.Size = UDim2.new(0, 150, 0, 40)
		button.Position = UDim2.new(0, 10 + (i-1) * 160, 0, 10)
		button.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		button.TextColor3 = Color3.fromRGB(50, 50, 50)
		button.TextSize = 16
		button.Font = Enum.Font.GothamBold
		button.Text = category

		-- Add rounded corners
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = button

		-- Add click event
		button.MouseButton1Click:Connect(function()
			SelectCategory(category)
		end)

		button.Parent = categoryButtons
	end

	-- Select default category
	SelectCategory("Collecting")
end

-- Function to select a category
function SelectCategory(category)
	currentCategory = category

	-- Update button appearance
	for _, button in pairs(categoryButtons:GetChildren()) do
		if button:IsA("TextButton") then
			if button.Name == category then
				-- Selected
				button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				button.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				-- Not selected
				button.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
				button.TextColor3 = Color3.fromRGB(50, 50, 50)
			end
		end
	end

	-- Refresh the upgrades list
	UpdateUpgradesList()
end

-- Function to update the upgrades list
function UpdateUpgradesList()
	-- Clear existing upgrades
	for _, child in pairs(upgradesList:GetChildren()) do
		if child:IsA("Frame") and child ~= upgradeTemplate then
			child:Destroy()
		end
	end

	-- Get upgrades for the current category
	local upgrades = UpgradeSystem.GetUpgradesByCategory(currentCategory)

	-- Add each upgrade to the list
	for i, upgrade in ipairs(upgrades) do
		local upgradeFrame = upgradeTemplate:Clone()
		upgradeFrame.Name = upgrade.id
		upgradeFrame.Visible = true

		-- Position in the list
		upgradeFrame.Position = UDim2.new(0, 10, 0, 10 + (i-1) * 110)

		-- Update icon
		local iconFrame = upgradeFrame:FindFirstChild("IconFrame")
		if iconFrame then
			iconFrame.Image = upgrade.icon or "rbxassetid://7733673307"
		end

		-- Update name
		local nameLabel = upgradeFrame:FindFirstChild("NameLabel")
		if nameLabel then
			nameLabel.Text = upgrade.name
		end

		-- Get current level
		local currentLevel = playerData.upgrades and playerData.upgrades[upgrade.id] or 0

		-- Update description
		local descriptionLabel = upgradeFrame:FindFirstChild("DescriptionLabel")
		if descriptionLabel then
			descriptionLabel.Text = UpgradeSystem.FormatDescription(upgrade, currentLevel)
		end

		-- Update level indicator
		local levelLabel = upgradeFrame:FindFirstChild("LevelLabel")
		if levelLabel then
			levelLabel.Text = "Level: " .. currentLevel .. "/" .. upgrade.maxLevel

			-- Color based on level
			if currentLevel == 0 then
				levelLabel.TextColor3 = Color3.fromRGB(100, 100, 100) -- Gray
			elseif currentLevel == upgrade.maxLevel then
				levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
			else
				levelLabel.TextColor3 = Color3.fromRGB(0, 150, 0) -- Green
			end
		end

		-- Update buy button
		local buyButton = upgradeFrame:FindFirstChild("BuyButton")
		if buyButton then
			-- Calculate cost
			local cost = UpgradeSystem.CalculateUpgradeCost(upgrade, currentLevel)

			if currentLevel >= upgrade.maxLevel then
				-- Max level reached
				buyButton.Text = "MAXED"
				buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray
				buyButton.Active = false
			elseif cost then
				-- Can upgrade
				buyButton.Text = "Buy: " .. cost

				-- Color based on affordability
				if playerData.coins >= cost then
					buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Green
				else
					buyButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- Red
				end

				-- Add click event
				buyButton.MouseButton1Click:Connect(function()
					BuyUpgrade:FireServer(upgrade.id)
				end)
			end
		end

		-- Check if upgrade is locked
		local isUnlocked = UpgradeSystem.IsUpgradeUnlocked(upgrade, playerData)
		local lockedOverlay = upgradeFrame:FindFirstChild("LockedOverlay")

		if lockedOverlay then
			lockedOverlay.Visible = not isUnlocked

			-- Update locked message
			local lockedText = lockedOverlay:FindFirstChild("LockedText")
			if lockedText and upgrade.gamePassRequired then
				lockedText.Text = "Requires: " .. upgrade.gamePassRequired .. " Pass"
			elseif lockedText and upgrade.unlockCondition then
				-- Special unlock conditions
				if upgrade.id == "rebirth_coins" then
					lockedText.Text = "Unlocks after first rebirth"
				else
					lockedText.Text = "Locked - Special requirement"
				end
			end
		end

		upgradeFrame.Parent = upgradesList
	end

	-- Resize the scrolling frame
	upgradesList.CanvasSize = UDim2.new(0, 0, 0, 10 + (#upgrades * 110))
end

-- Function to handle the UpdatePlayerStats event
function OnUpdatePlayerStats(newData)
	if not newData then return end

	-- Update player data
	playerData = newData

	-- Update UI
	UpdateUpgradesList()

	-- Update stats in other parts of the UI
	UpdateUIStats()
end

-- Function to update UI stats
function UpdateUIStats()
	-- Find the StatsFrame (assuming it's a sibling or ancestor)
	local mainGui = player.PlayerGui:FindFirstChild("MainGui")
	if not mainGui then return end

	local statsFrame = mainGui:FindFirstChild("StatsFrame")
	if not statsFrame then return end

	-- Update coins
	local coinsLabel = statsFrame:FindFirstChild("CoinsLabel")
	if coinsLabel then
		coinsLabel.Text = "Coins: " .. (playerData.coins or 0)
	end
end

-- Listen for player stats updates
UpdatePlayerStats.OnClientEvent:Connect(OnUpdatePlayerStats)

-- Initialize UI
EnsureCategoryButtons()

-- Initial UI update
spawn(function()
	wait(1) -- Give time for UI and player data to load

	-- Get initial player data
	local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if RemoteFunctions then
		local GetPlayerData = RemoteFunctions:FindFirstChild("GetPlayerData")
		if GetPlayerData then
			local success, data = pcall(function()
				return GetPlayerData:InvokeServer()
			end)

			if success and data then
				OnUpdatePlayerStats(data)
			end
		end
	end

	-- If no data was loaded, use default data to at least show the UI
	if not playerData.upgrades then
		playerData = {
			coins = 1000,
			upgrades = {
				collection_speed = 1,
				pet_capacity = 1,
				collection_value = 1
			}
		}
		UpdateUpgradesList()
	end
end)

print("Upgrade Shop UI loaded")