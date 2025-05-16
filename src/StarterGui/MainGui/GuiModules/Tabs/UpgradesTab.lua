-- UpgradesTab.lua (ModuleScript)
-- Place in StarterGui/MainGui/GuiModules/Tabs/

local UpgradesTab = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyUpgrade = RemoteEvents:WaitForChild("BuyUpgrade")

-- Initialize variables
local playerData = nil
local upgradesFrame = nil

-- Upgrade data definitions
local upgradeDefinitions = {
	{
		name = "Collection Speed",
		description = "Collect pets faster",
		baseCost = 100,
		costMultiplier = 1.5,
		maxLevel = 10,
		effectPerLevel = 0.1
	},
	{
		name = "Pet Capacity",
		description = "Carry more pets at once",
		baseCost = 200,
		costMultiplier = 2,
		maxLevel = 5,
		effectPerLevel = 5
	},
	{
		name = "Collection Value",
		description = "Increase the value of collected pets",
		baseCost = 500,
		costMultiplier = 2.5,
		maxLevel = 10,
		effectPerLevel = 0.2
	}
}

-- Initialize the tab
function UpgradesTab.Init(frame, data)
	upgradesFrame = frame
	playerData = data

	-- Create the tab content if it doesn't exist
	if not upgradesFrame:FindFirstChild("UpgradeTemplate") then
		UpgradesTab.CreateTemplate()
	end

	return UpgradesTab
end

-- Create the upgrade item template
function UpgradesTab.CreateTemplate()
	local upgradeTemplate = Instance.new("Frame")
	upgradeTemplate.Name = "UpgradeTemplate"
	upgradeTemplate.Size = UDim2.new(0, 300, 0, 100)
	upgradeTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	upgradeTemplate.BorderColor3 = Color3.fromRGB(200, 200, 200)
	upgradeTemplate.BorderSizePixel = 2
	upgradeTemplate.Visible = false
	upgradeTemplate.Parent = upgradesFrame

	-- Create title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -10, 0, 30)
	titleLabel.Position = UDim2.new(0, 5, 0, 5)
	titleLabel.Text = "Upgrade Name"
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = upgradeTemplate

	-- Create description label
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(1, -10, 0, 20)
	descLabel.Position = UDim2.new(0, 5, 0, 35)
	descLabel.Text = "Upgrade description goes here"
	descLabel.TextSize = 14
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.BackgroundTransparency = 1
	descLabel.Parent = upgradeTemplate

	-- Create level label
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0.5, -10, 0, 25)
	levelLabel.Position = UDim2.new(0, 5, 0, 65)
	levelLabel.Text = "Level: 1/10"
	levelLabel.TextSize = 14
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextColor3 = Color3.fromRGB(0, 100, 200)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.BackgroundTransparency = 1
	levelLabel.Parent = upgradeTemplate

	-- Create buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0.45, 0, 0, 30)
	buyButton.Position = UDim2.new(0.53, 0, 0, 60)
	buyButton.Text = "Upgrade: 100"
	buyButton.TextSize = 14
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	buyButton.BorderSizePixel = 0
	buyButton.Parent = upgradeTemplate

	-- Add rounded corners to button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = buyButton
end

-- Update the tab content with current data
function UpgradesTab.Update(data)
	playerData = data or playerData

	if not upgradesFrame then return end
	print("Updating upgrades display")

	-- Clear existing upgrade displays
	for _, child in pairs(upgradesFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UpgradeTemplate" then
			child:Destroy()
		end
	end

	local upgradeTemplate = upgradesFrame:FindFirstChild("UpgradeTemplate")
	if not upgradeTemplate then
		UpgradesTab.CreateTemplate()
		upgradeTemplate = upgradesFrame:FindFirstChild("UpgradeTemplate")
	end

	-- Create upgrade display for each upgrade
	for i, upgrade in ipairs(upgradeDefinitions) do
		local upgradeFrame = upgradeTemplate:Clone()
		upgradeFrame.Name = upgrade.name
		upgradeFrame.Visible = true

		-- Update texts
		upgradeFrame.TitleLabel.Text = upgrade.name
		upgradeFrame.DescLabel.Text = upgrade.description

		-- Calculate current level and next price
		local currentLevel = 1
		if playerData and playerData.upgrades and playerData.upgrades[upgrade.name] then
			currentLevel = playerData.upgrades[upgrade.name]
		end

		upgradeFrame.LevelLabel.Text = "Level: " .. currentLevel .. "/" .. upgrade.maxLevel

		-- Calculate cost of next level
		local cost = math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ (currentLevel - 1)))
		upgradeFrame.BuyButton.Text = "Upgrade: " .. cost

		-- Set button color based on affordability
		if playerData and playerData.coins >= cost and currentLevel < upgrade.maxLevel then
			upgradeFrame.BuyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)  -- Green
		else
			upgradeFrame.BuyButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)  -- Red
		end

		-- If max level, update button
		if currentLevel >= upgrade.maxLevel then
			upgradeFrame.BuyButton.Text = "MAX LEVEL"
			upgradeFrame.BuyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)  -- Gray
		end

		-- Position the frame
		upgradeFrame.Position = UDim2.new(0, 10, 0, (i-1) * 110 + 10)

		-- Connect buy button
		local buyButton = upgradeFrame.BuyButton
		buyButton.MouseButton1Click:Connect(function()
			-- Don't process if at max level
			if currentLevel >= upgrade.maxLevel then return end

			-- Check if player has enough coins
			if playerData and playerData.coins >= cost then
				-- Fire BuyUpgrade event to server
				if BuyUpgrade then
					BuyUpgrade:FireServer(upgrade.name)
				end
			else
				-- Show "not enough coins" message
				local message = buyButton:FindFirstChild("Message")
				if not message then
					message = Instance.new("TextLabel")
					message.Name = "Message"
					message.Size = UDim2.new(1, 0, 0, 20)
					message.Position = UDim2.new(0, 0, 1, 5)
					message.Text = "Not enough coins!"
					message.TextSize = 12
					message.Font = Enum.Font.GothamBold
					message.TextColor3 = Color3.fromRGB(255, 50, 50)
					message.BackgroundTransparency = 1
					message.Parent = buyButton

					-- Remove message after 2 seconds
					spawn(function()
						wait(2)
						if message and message.Parent then
							message:Destroy()
						end
					end)
				end
			end
		end)

		upgradeFrame.Parent = upgradesFrame
	end
end

return UpgradesTab