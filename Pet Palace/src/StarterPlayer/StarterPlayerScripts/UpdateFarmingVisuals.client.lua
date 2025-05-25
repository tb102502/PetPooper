-- Place this script in StarterPlayerScripts
-- This script only adds price labels to existing buttons without creating new ones
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui", 10)

-- Load the shop data
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Helper function to find item data by button name
local function findItemByButtonName(buttonName)
	-- Convert button name to item ID format
	local searchName
	if buttonName == "ExtraPlot" then
		searchName = "farm_plot_upgrade"
	elseif buttonName:match("Seed$") then
		-- CarrotSeed -> carrot_seeds
		searchName = buttonName:gsub("Seed$", ""):lower() .. "_seeds"
	else
		searchName = buttonName:lower()
	end

	-- Check in Farming category
	for _, item in ipairs(ShopData.Farming) do
		if string.lower(item.ID) == searchName then
			return item
		end
	end

	-- Check in FarmingTools category
	if ShopData.FarmingTools then
		for _, item in ipairs(ShopData.FarmingTools) do
			if string.lower(item.ID) == searchName then
				return item
			end
		end
	end

	return nil
end

-- Function to update farm plot button
local function updateExtraPlotButton(playerData)
	if not shopGui then return end

	local mainFrame = shopGui:WaitForChild("MainFrame")
	local contentFrame = mainFrame:WaitForChild("ContentFrame")
	local farmingFrame = contentFrame:WaitForChild("FarmingFrame")

	local extraPlotButton = farmingFrame:FindFirstChild("ExtraPlot")
	if not extraPlotButton then return end

	-- Get plot upgrade data
	local plotUpgradeData = findItemByButtonName("ExtraPlot")
	if not plotUpgradeData then return end

	-- Get current level
	local currentLevel = 1
	if playerData and playerData.upgrades and playerData.upgrades.farmPlots then
		currentLevel = playerData.upgrades.farmPlots
	end

	-- Create or update level label
	local levelLabel = extraPlotButton:FindFirstChild("LevelLabel")
	if not levelLabel then
		levelLabel = Instance.new("TextLabel")
		levelLabel.Name = "LevelLabel"
		levelLabel.Size = UDim2.new(1, 0, 0, 20)
		levelLabel.Position = UDim2.new(0, 0, 0, 0)
		levelLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		levelLabel.BackgroundTransparency = 0.5
		levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		levelLabel.TextSize = 14
		levelLabel.Font = Enum.Font.GothamBold
		levelLabel.Text = "Level " .. currentLevel .. "/" .. plotUpgradeData.MaxLevel
		levelLabel.ZIndex = 5
		levelLabel.Parent = extraPlotButton
	else
		levelLabel.Text = "Level " .. currentLevel .. "/" .. plotUpgradeData.MaxLevel
	end

	-- Check if maxed
	local isMaxed = currentLevel >= plotUpgradeData.MaxLevel

	-- Update price label
	local priceLabel = extraPlotButton:FindFirstChild("PriceLabel")
	if not priceLabel then
		priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(1, 0, 0, 20)
		priceLabel.Position = UDim2.new(0, 0, 1, -20)
		priceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		priceLabel.BackgroundTransparency = 0.5
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		priceLabel.TextSize = 14
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.ZIndex = 5
		priceLabel.Parent = extraPlotButton
	end

	if isMaxed then
		priceLabel.Text = "MAX LEVEL"
	else
		priceLabel.Text = plotUpgradeData.Price .. " " .. plotUpgradeData.Currency
		end

		-- Update button appearance if maxed
if isMaxed then
	extraPlotButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray out maxed button
	extraPlotButton.Active = false -- Disable button if maxed
else
	extraPlotButton.BackgroundColor3 = Color3.fromRGB(70, 120, 70) -- Normal color
	extraPlotButton.Active = true
end
end

-- Function to add price labels to seed buttons
local function updateFarmingButtonsVisuals()
	if not shopGui then return end

	local mainFrame = shopGui:WaitForChild("MainFrame")
	local contentFrame = mainFrame:WaitForChild("ContentFrame")
	local farmingFrame = contentFrame:WaitForChild("FarmingFrame")

	-- Find all buttons in the farming frame
	for _, button in pairs(farmingFrame:GetChildren()) do
		if button:IsA("TextButton") or button:IsA("ImageButton") then
			if button.Name ~= "ExtraPlot" then  -- ExtraPlot is handled separately
				-- Find item data based on button name
				local itemData = findItemByButtonName(button.Name)

				if itemData then
					-- Add price label if it doesn't exist
					local priceLabel = button:FindFirstChild("PriceLabel")
					if not priceLabel then
						priceLabel = Instance.new("TextLabel")
						priceLabel.Name = "PriceLabel"
						priceLabel.Size = UDim2.new(1, 0, 0, 20)
						priceLabel.Position = UDim2.new(0, 0, 1, -20)
						priceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
						priceLabel.BackgroundTransparency = 0.5
						priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
						priceLabel.TextSize = 14
						priceLabel.Font = Enum.Font.GothamBold
						priceLabel.Text = itemData.Price .. " " .. itemData.Currency
						priceLabel.ZIndex = 5
						priceLabel.Parent = button
					else
						priceLabel.Text = itemData.Price .. " " .. itemData.Currency
					end
				end
			end
		end
	end
end

-- Listen for player data updates
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")

UpdatePlayerStats.OnClientEvent:Connect(function(playerData)
	updateExtraPlotButton(playerData)
	_G.PlayerData = playerData  -- Store for future reference
end)

-- Update visuals when shop is opened
spawn(function()
	while wait(1) do
		local mainFrame = shopGui and shopGui:FindFirstChild("MainFrame")
		if mainFrame then
			mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
				if mainFrame.Visible then
					updateFarmingButtonsVisuals()
					updateExtraPlotButton(_G.PlayerData)
				end
			end)
			break -- Exit the loop once we've connected the signal
		end
	end
end)

-- Initial update
spawn(function()
	wait(2) -- Give time for UI to fully load
	updateFarmingButtonsVisuals()
	updateExtraPlotButton(_G.PlayerData)
end)

print("Farming visuals update script loaded")