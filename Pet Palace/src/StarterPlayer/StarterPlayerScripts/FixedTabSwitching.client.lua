-- FixedTabSwitching.client.lua
-- Add this to your SimpleShopClient.client.lua or create as separate script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui")

-- Variable to track current tab
local currentTab = "Collecting"

-- Function to switch tabs
local function switchTab(tabName)
	currentTab = tabName
	print("Switching to tab:", tabName)

	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local tabsFrame = mainFrame:FindFirstChild("TabsFrame")
	local contentFrame = mainFrame:FindFirstChild("ContentFrame")

	if not tabsFrame or not contentFrame then
		warn("TabsFrame or ContentFrame not found!")
		return
	end

	-- Update tab button appearances
	local tabs = {"CollectingTab", "AreasTab", "PremiumTab"}
	for _, tabButtonName in ipairs(tabs) do
		local tabButton = tabsFrame:FindFirstChild(tabButtonName)
		if tabButton then
			if tabButtonName == tabName .. "Tab" then
				-- Active tab
				tabButton.BackgroundColor3 = Color3.fromRGB(80, 120, 180)
				tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				-- Inactive tab
				tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end
	end

	-- Show/hide content frames
	local contentFrames = {"CollectingFrame", "AreasFrame", "PremiumFrame"}
	for _, frameName in ipairs(contentFrames) do
		local frame = contentFrame:FindFirstChild(frameName)
		if frame then
			if frameName == tabName .. "Frame" then
				frame.Visible = true
				-- Optional: Animate frame appearing
				frame.Size = UDim2.new(1, 0, 0, 0)
				local tween = TweenService:Create(
					frame,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Size = UDim2.new(1, 0, 1, 0)}
				)
				tween:Play()
			else
				frame.Visible = false
			end
		end
	end
end

-- Function to setup tab buttons
local function setupTabButtons()
	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then
		warn("MainFrame not found!")
		return
	end

	local tabsFrame = mainFrame:FindFirstChild("TabsFrame")
	if not tabsFrame then
		warn("TabsFrame not found!")
		return
	end

	-- Connect each tab button
	local tabButtons = {
		{name = "CollectingTab", tab = "Collecting"},
		{name = "AreasTab", tab = "Areas"},
		{name = "PremiumTab", tab = "Premium"}
	}

	for _, buttonInfo in ipairs(tabButtons) do
		local button = tabsFrame:FindFirstChild(buttonInfo.name)
		if button and button:IsA("TextButton") then
			-- Clear existing connections
			button.MouseButton1Click:Connect(function()
				print("Tab button clicked:", buttonInfo.tab)
				switchTab(buttonInfo.tab)
			end)

			print("Connected tab button:", buttonInfo.name)
		else
			warn("Tab button not found or not a TextButton:", buttonInfo.name)
		end
	end

	-- Set initial tab
	switchTab("Collecting")
end

-- Function to create missing content frames
local function createMissingContentFrames()
	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local contentFrame = mainFrame:FindFirstChild("ContentFrame")
	if not contentFrame then
		warn("ContentFrame not found!")
		return
	end

	local frameNames = {"CollectingFrame", "AreasFrame", "PremiumFrame"}

	for _, frameName in ipairs(frameNames) do
		local frame = contentFrame:FindFirstChild(frameName)
		if not frame then
			print("Creating missing frame:", frameName)

			frame = Instance.new("ScrollingFrame")
			frame.Name = frameName
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.Position = UDim2.new(0, 0, 0, 0)
			frame.BackgroundTransparency = 1
			frame.ScrollBarThickness = 8
			frame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
			frame.CanvasSize = UDim2.new(0, 0, 0, 600) -- Adjust as needed
			frame.Visible = false
			frame.Parent = contentFrame

			-- Add UIListLayout for automatic item arrangement
			local listLayout = Instance.new("UIListLayout")
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Padding = UDim.new(0, 10)
			listLayout.Parent = frame

			-- Add content based on frame type
			if frameName == "CollectingFrame" then
				createUpgradeItems(frame)
			elseif frameName == "AreasFrame" then
				createAreaItems(frame)
			elseif frameName == "PremiumFrame" then
				createPremiumItems(frame)
			end
		end
	end
end

-- Function to create upgrade items
function createUpgradeItems(frame)
	for i = 1, 5 do
		local item = Instance.new("Frame")
		item.Name = "Item" .. i
		item.Size = UDim2.new(1, -20, 0, 120)
		item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.Parent = frame

		-- Add UICorner
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = item

		-- Add title label
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(0.6, 0, 0, 30)
		titleLabel.Position = UDim2.new(0, 20, 0, 10)
		titleLabel.Text = "Upgrade " .. i
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 18
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.BackgroundTransparency = 1
		titleLabel.Parent = item

		-- Add description label
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescriptionLabel"
		descLabel.Size = UDim2.new(0.6, 0, 0, 40)
		descLabel.Position = UDim2.new(0, 20, 0, 40)
		descLabel.Text = "Description for upgrade " .. i
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextSize = 14
		descLabel.Font = Enum.Font.Gotham
		descLabel.BackgroundTransparency = 1
		descLabel.TextWrapped = true
		descLabel.Parent = item

		-- Add purchase button
		local purchaseButton = Instance.new("TextButton")
		purchaseButton.Name = "PurchaseButton"
		purchaseButton.Size = UDim2.new(0, 120, 0, 35)
		purchaseButton.Position = UDim2.new(1, -140, 0, 75)
		purchaseButton.Text = "Purchase"
		purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		purchaseButton.TextSize = 16
		purchaseButton.Font = Enum.Font.GothamBold
		purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		purchaseButton.BorderSizePixel = 0
		purchaseButton.Parent = item

		-- Add button corner
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = purchaseButton
	end
end

-- Function to create area items
function createAreaItems(frame)
	for i = 1, 3 do
		local item = Instance.new("Frame")
		item.Name = "Item" .. i
		item.Size = UDim2.new(1, -20, 0, 120)
		item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.Parent = frame

		-- Add UICorner
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = item

		-- Add content similar to upgrade items but for areas
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(0.6, 0, 0, 30)
		titleLabel.Position = UDim2.new(0, 20, 0, 10)
		titleLabel.Text = "Area " .. i
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 18
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.BackgroundTransparency = 1
		titleLabel.Parent = item

		local unlockButton = Instance.new("TextButton")
		unlockButton.Name = "UnlockButton"
		unlockButton.Size = UDim2.new(0, 120, 0, 35)
		unlockButton.Position = UDim2.new(1, -140, 0, 75)
		unlockButton.Text = "Unlock"
		unlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		unlockButton.TextSize = 16
		unlockButton.Font = Enum.Font.GothamBold
		unlockButton.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
		unlockButton.BorderSizePixel = 0
		unlockButton.Parent = item

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = unlockButton
	end
end

-- Function to create premium items
function createPremiumItems(frame)
	for i = 1, 6 do
		local item = Instance.new("Frame")
		item.Name = "Item" .. i
		item.Size = UDim2.new(1, -20, 0, 120)
		item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.Parent = frame

		-- Add UICorner
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = item

		-- Add content for premium items
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(0.6, 0, 0, 30)
		titleLabel.Position = UDim2.new(0, 20, 0, 10)
		titleLabel.Text = "Premium " .. i
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 18
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.BackgroundTransparency = 1
		titleLabel.Parent = item

		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0, 120, 0, 35)
		buyButton.Position = UDim2.new(1, -140, 0, 75)
		buyButton.Text = "Buy"
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextSize = 16
		buyButton.Font = Enum.Font.GothamBold
		buyButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
		buyButton.BorderSizePixel = 0
		buyButton.Parent = item

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = buyButton
	end
end

-- Wait for shop to be available and then setup
spawn(function()
	-- Wait for shop GUI to be fully loaded
	repeat wait(0.5) until shopGui:FindFirstChild("MainFrame")

	print("Setting up shop tabs...")

	-- Create missing frames if needed
	createMissingContentFrames()

	-- Setup tab buttons
	setupTabButtons()

	print("Shop tab system ready!")
end)

-- Export the switch function for external use
_G.ShopSwitchTab = switchTab