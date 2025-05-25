-- Place this in a LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Reference to main GUI
local mainGui = playerGui:WaitForChild("MainGui", 10)
if not mainGui then
	-- Create the MainGui if it doesn't exist
	mainGui = Instance.new("ScreenGui")
	mainGui.Name = "MainGui"
	mainGui.ResetOnSpawn = false
	mainGui.Parent = playerGui
end

-- Create or get the stats frame
local statsFrame = mainGui:FindFirstChild("StatsFrame")
if not statsFrame then
	statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(0, 300, 0, 120)
	statsFrame.Position = UDim2.new(0, 10, 0, 10)
	statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	statsFrame.BackgroundTransparency = 0.3
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = mainGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = statsFrame

	-- Add stat labels with proper styling
	local function createStatLabel(name, icon, position, color)
		local statFrame = Instance.new("Frame")
		statFrame.Name = name .. "Frame"
		statFrame.Size = UDim2.new(1, -20, 0, 30)
		statFrame.Position = UDim2.new(0, 10, 0, position)
		statFrame.BackgroundTransparency = 0.9
		statFrame.BackgroundColor3 = color
		statFrame.BorderSizePixel = 0
		statFrame.Parent = statsFrame

		-- Add icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(0, 30, 0, 30)
		iconLabel.Position = UDim2.new(0, 0, 0, 0)
		iconLabel.Text = icon
		iconLabel.TextColor3 = color
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.TextSize = 18
		iconLabel.BackgroundTransparency = 1
		iconLabel.Parent = statFrame

		-- Add name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(0, 70, 0, 30)
		nameLabel.Position = UDim2.new(0, 30, 0, 0)
		nameLabel.Text = name .. ":"
		nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = statFrame

		-- Add value
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "ValueLabel"
		valueLabel.Size = UDim2.new(0, 150, 0, 30)
		valueLabel.Position = UDim2.new(0, 100, 0, 0)
		valueLabel.Text = "0"
		valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextSize = 14
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.BackgroundTransparency = 1
		valueLabel.Parent = statFrame

		return valueLabel
	end

	-- Create the stat labels with icons and colors
	local coinsLabel = createStatLabel("Coins", "🪙", 10, Color3.fromRGB(255, 215, 0))
	local gemsLabel = createStatLabel("Gems", "💎", 45, Color3.fromRGB(0, 200, 255))
	local petsLabel = createStatLabel("Pets", "🐾", 80, Color3.fromRGB(170, 0, 170))
end

-- Function to update the stats display with animation
local function updateStats(playerData)
	if not playerData then return end

	local function updateStatValue(name, value, formatting)
		local statFrame = statsFrame:FindFirstChild(name .. "Frame")
		if not statFrame then return end

		local valueLabel = statFrame:FindFirstChild("ValueLabel")
		if not valueLabel then return end

		-- Format the value if needed
		local formattedValue = formatting and formatting(value) or tostring(value)

		-- Only animate if value changed
		if valueLabel.Text ~= formattedValue then
			-- Store original scale
			local originalScale = valueLabel.TextSize

			-- Create scale-up tween
			local scaleUp = TweenService:Create(
				valueLabel,
				TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{TextSize = originalScale * 1.3}
			)

			-- Create scale-down tween
			local scaleDown = TweenService:Create(
				valueLabel,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextSize = originalScale}
			)

			-- Play the animation sequence
			scaleUp:Play()
			scaleUp.Completed:Connect(function()
				valueLabel.Text = formattedValue
				scaleDown:Play()
			end)
		end
	end

	-- Update each stat with appropriate formatting
	updateStatValue("Coins", playerData.coins, function(value)
		-- Format large numbers with commas
		return string.format("%s", value >= 1000 
			and string.format("%.1fK", value/1000) 
			or value)
	end)

	updateStatValue("Gems", playerData.gems)

	updateStatValue("Pets", playerData.pets and #playerData.pets or 0, function(value)
		-- Show collected/capacity format
		local capacity = playerData.petCapacity or 100
		return string.format("%d/%d", value, capacity)
	end)
end

-- Listen for player data updates
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")

UpdatePlayerStats.OnClientEvent:Connect(function(playerData)
	updateStats(playerData)
end)

-- Try to get initial player data
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local GetPlayerData = RemoteFunctions:WaitForChild("GetPlayerData", 10)

if GetPlayerData then
	local success, playerData = pcall(function()
		return GetPlayerData:InvokeServer()
	end)

	if success and playerData then
		updateStats(playerData)
	end
end

-- Add fade-in animation for initial appearance
statsFrame.BackgroundTransparency = 1
for _, child in pairs(statsFrame:GetChildren()) do
	if child:IsA("Frame") then
		child.BackgroundTransparency = 1
		for _, grandchild in pairs(child:GetChildren()) do
			if grandchild:IsA("TextLabel") then
				grandchild.TextTransparency = 1
			end
		end
	end
end

-- Create fade-in sequence
local fadeInTime = 0.5
spawn(function()
	wait(1) -- Wait for everything to load

	-- Fade in main frame
	TweenService:Create(
		statsFrame,
		TweenInfo.new(fadeInTime),
		{BackgroundTransparency = 0.3}
	):Play()

	-- Fade in stat frames and labels
	for i, child in pairs(statsFrame:GetChildren()) do
		if child:IsA("Frame") then
			TweenService:Create(
				child,
				TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, i * 0.1),
				{BackgroundTransparency = 0.9}
			):Play()

			for j, grandchild in pairs(child:GetChildren()) do
				if grandchild:IsA("TextLabel") then
					TweenService:Create(
						grandchild,
						TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, i * 0.1),
						{TextTransparency = 0}
					):Play()
				end
			end
		end
	end
end)

print("Stats Frame initialized and ready for updates")