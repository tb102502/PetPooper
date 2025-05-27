-- FarmingShopIntegration.client.lua
-- Place in StarterPlayerScripts
-- Integrates farming with existing shop system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shop GUI
local shopGui = playerGui:WaitForChild("ShopGui", 10)
if not shopGui then
	warn("ShopGui not found! Farming shop integration disabled.")
	return
end

-- Load shop data
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Get remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuySeed = RemoteEvents:WaitForChild("BuySeed")

-- Track current player data
local currentPlayerData = {}

-- Helper function to find item by button name
local function findFarmingItem(buttonName)
	local searchName
	if buttonName == "ExtraPlot" then
		searchName = "farm_plot_upgrade"
	elseif buttonName:match("Seed$") then
		searchName = buttonName:gsub("Seed$", ""):lower() .. "_seeds"
	else
		searchName = buttonName:lower()
	end

	-- Check in Farming category
	if ShopData.Farming then
		for _, item in ipairs(ShopData.Farming) do
			if item.ID:lower() == searchName then
				return item
			end
		end
	end

	return nil
end

-- Update farming item visuals
local function updateFarmingItemDisplay(button, itemData, playerData)
	if not button or not itemData then return end

	-- Create or update price label
	local priceLabel = button:FindFirstChild("PriceLabel")
	if not priceLabel then
		priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(1, 0, 0, 20)
		priceLabel.Position = UDim2.new(0, 0, 1, -20)
		priceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		priceLabel.BackgroundTransparency = 0.3
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		priceLabel.TextSize = 12
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.ZIndex = 5
		priceLabel.Parent = button
	end

	-- Handle farm plot upgrade differently
	if itemData.Type == "Upgrade" and itemData.ID == "farm_plot_upgrade" then
		local currentLevel = 0
		if playerData.upgrades and playerData.upgrades.farmPlots then
			currentLevel = playerData.upgrades.farmPlots
		end

		local isMaxed = currentLevel >= (itemData.MaxLevel or 7)

		-- Create level label
		local levelLabel = button:FindFirstChild("LevelLabel")
		if not levelLabel then
			levelLabel = Instance.new("TextLabel")
			levelLabel.Name = "LevelLabel"
			levelLabel.Size = UDim2.new(1, 0, 0, 20)
			levelLabel.Position = UDim2.new(0, 0, 0, 0)
			levelLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			levelLabel.BackgroundTransparency = 0.3
			levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			levelLabel.TextSize = 12
			levelLabel.Font = Enum.Font.GothamBold
			levelLabel.ZIndex = 5
			levelLabel.Parent = button
		end

		levelLabel.Text = "Plots: " .. (3 + currentLevel) .. "/" .. (3 + itemData.MaxLevel)

		if isMaxed then
			priceLabel.Text = "MAX LEVEL"
			priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		else
			priceLabel.Text = itemData.Price .. " " .. itemData.Currency
			priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
		end
	else
		-- Regular seed item
		priceLabel.Text = itemData.Price .. " " .. itemData.Currency

		-- Check affordability
		local currencyField = itemData.Currency:lower()
		local canAfford = false

		if playerData[currencyField] and playerData[currencyField] >= itemData.Price then
			canAfford = true
		end

		if canAfford then
			button.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
			priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			button.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
			priceLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
		end
	end
end

-- Track connections to prevent duplicates
local buttonConnections = {}

-- Connect farming buttons to purchase events
local function connectFarmingButtons()
	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local contentFrame = mainFrame:FindFirstChild("ContentFrame")
	if not contentFrame then return end

	local farmingFrame = contentFrame:FindFirstChild("FarmingFrame")
	if not farmingFrame then
		warn("FarmingFrame not found in shop!")
		return
	end

	-- Find and connect all farming buttons
	for _, button in pairs(farmingFrame:GetChildren()) do
		if button:IsA("TextButton") or button:IsA("ImageButton") then
			local itemData = findFarmingItem(button.Name)

			if itemData then
				-- Update visual appearance
				updateFarmingItemDisplay(button, itemData, currentPlayerData)

				-- Clear existing connection for this button (prevent duplicates)
				if buttonConnections[button] then
					buttonConnections[button]:Disconnect()
					buttonConnections[button] = nil
				end

				-- Connect purchase event and store connection
				buttonConnections[button] = button.MouseButton1Click:Connect(function()
					print("Purchasing farming item:", itemData.Name)
					BuySeed:FireServer(itemData.ID)
				end)

				print("Connected farming button:", button.Name, "->", itemData.Name)
			end
		end
	end
end

-- Handle tab switching to farming
local function setupFarmingTab()
	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local tabsFrame = mainFrame:FindFirstChild("TabsFrame")
	local contentFrame = mainFrame:FindFirstChild("ContentFrame")

	if not tabsFrame or not contentFrame then return end

	local farmingTab = tabsFrame:FindFirstChild("FarmingTab")
	if farmingTab then
		farmingTab.MouseButton1Click:Connect(function()
			-- Hide all frames
			for _, frame in pairs(contentFrame:GetChildren()) do
				if frame:IsA("Frame") or frame:IsA("ScrollingFrame") then
					frame.Visible = false
				end
			end

			-- Show farming frame
			local farmingFrame = contentFrame:FindFirstChild("FarmingFrame")
			if farmingFrame then
				farmingFrame.Visible = true
			end

			-- Update tab appearances
			for _, tab in pairs(tabsFrame:GetChildren()) do
				if tab:IsA("TextButton") then
					if tab == farmingTab then
						tab.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
					else
						tab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					end
				end
			end

			-- Connect buttons when tab is opened
			spawn(function()
				wait(0.1) -- Small delay to ensure UI is ready
				connectFarmingButtons()
			end)
		end)
	end
end

-- Listen for player data updates
local UpdatePlayerStats = RemoteEvents:FindFirstChild("UpdatePlayerStats")
if UpdatePlayerStats then
	UpdatePlayerStats.OnClientEvent:Connect(function(playerData)
		currentPlayerData = playerData

		-- Update farming button appearances if farming tab is open
		local mainFrame = shopGui:FindFirstChild("MainFrame")
		if mainFrame and mainFrame.Visible then
			local contentFrame = mainFrame:FindFirstChild("ContentFrame")
			local farmingFrame = contentFrame and contentFrame:FindFirstChild("FarmingFrame")

			if farmingFrame and farmingFrame.Visible then
				spawn(function()
					wait(0.1)
					connectFarmingButtons()
				end)
			end
		end
	end)
end

-- Listen for currency updates
local CurrencyUpdated = RemoteEvents:FindFirstChild("CurrencyUpdated")
if CurrencyUpdated then
	CurrencyUpdated.OnClientEvent:Connect(function(currencyData)
		-- Update current data with new currency values
		for currency, amount in pairs(currencyData) do
			currentPlayerData[currency:lower()] = amount
		end

		-- Refresh farming buttons if visible
		local mainFrame = shopGui:FindFirstChild("MainFrame")
		if mainFrame and mainFrame.Visible then
			local contentFrame = mainFrame:FindFirstChild("ContentFrame")
			local farmingFrame = contentFrame and contentFrame:FindFirstChild("FarmingFrame")

			if farmingFrame and farmingFrame.Visible then
				spawn(function()
					wait(0.1)
					connectFarmingButtons()
				end)
			end
		end
	end)
end

-- Wait for shop to fully load then setup
spawn(function()
	wait(2) -- Give time for shop GUI to fully initialize
	setupFarmingTab()
	print("Farming shop integration loaded")
end)

-- Clean up connections when player leaves
Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		-- Clean up all button connections
		for button, connection in pairs(buttonConnections) do
			if connection then
				connection:Disconnect()
			end
		end
		buttonConnections = {}
	end
end)

-- Ensure buttons are connected when shop opens
local function onShopOpened()
	spawn(function()
		wait(0.5) -- Give time for shop to open
		connectFarmingButtons()
	end)
end

-- Listen for shop opening (if there's an event for it)
local OpenShopClient = RemoteEvents:FindFirstChild("OpenShopClient")
if OpenShopClient then
	OpenShopClient.OnClientEvent:Connect(onShopOpened)
end

-- Also connect when main frame becomes visible
spawn(function()
	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if mainFrame then
		mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
			if mainFrame.Visible then
				onShopOpened()
			end
		end)
	end
end)