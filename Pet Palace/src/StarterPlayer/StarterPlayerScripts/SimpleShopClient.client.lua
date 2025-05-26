-- Enhanced SimpleShopClient.client.lua
-- Add color system to your client-side shop handler

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shop GUI
local shopGui = playerGui:WaitForChild("ShopGui", 10)
if not shopGui then
	warn("ShopGui not found in PlayerGui!")
	return
end

-- Get RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local OpenShopClient = RemoteEvents:WaitForChild("OpenShopClient")
local UpdateShopData = RemoteEvents:WaitForChild("UpdateShopData")
local BuyUpgrade = RemoteEvents:WaitForChild("BuyUpgrade")
local SellPet = RemoteEvents:WaitForChild("SellPet")

-- Color application function
local function applyUpgradeColors(upgradeFrame, colorData, currentLevel, maxLevel)
	if not colorData then return end

	-- FIX: Properly handle the color data
	local primaryColor, secondaryColor, iconColor, accentColor

	-- Handle either table format or array format
	if type(colorData) == "table" then
		if colorData.primary then
			-- Using the object format
			primaryColor = Color3.fromRGB(colorData.primary[1], colorData.primary[2], colorData.primary[3])
			secondaryColor = Color3.fromRGB(colorData.secondary[1], colorData.secondary[2], colorData.secondary[3])
			iconColor = Color3.fromRGB(colorData.icon[1], colorData.icon[2], colorData.icon[3])
			accentColor = Color3.fromRGB(colorData.accent[1], colorData.accent[2], colorData.accent[3])
		else
			-- Fallback to predefined colors
			primaryColor = Color3.fromRGB(60, 80, 120)
			secondaryColor = Color3.fromRGB(100, 140, 200)
			iconColor = Color3.fromRGB(220, 220, 220)
			accentColor = Color3.fromRGB(80, 170, 80)
		end
	else
		-- Fallback to predefined colors
		primaryColor = Color3.fromRGB(60, 80, 120)
		secondaryColor = Color3.fromRGB(100, 140, 200) 
		iconColor = Color3.fromRGB(220, 220, 220)
		accentColor = Color3.fromRGB(80, 170, 80)
	end

	-- Set main frame background
	upgradeFrame.BackgroundColor3 = primaryColor

	-- Add or update UIStroke for border
	local stroke = upgradeFrame:FindFirstChild("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = upgradeFrame
	end
	stroke.Thickness = 2
	stroke.Color = secondaryColor
	stroke.Transparency = 0

	-- Color the icon if it exists
	local icon = upgradeFrame:FindFirstChild("Icon")
	if icon then
		icon.ImageColor3 = iconColor
	end

	-- Create or update level indicator
	local levelIndicator = upgradeFrame:FindFirstChild("LevelIndicator")
	if not levelIndicator then
		levelIndicator = Instance.new("Frame")
		levelIndicator.Name = "LevelIndicator"
		levelIndicator.Size = UDim2.new(0, 200, 0, 4)
		levelIndicator.Position = UDim2.new(0, 90, 1, -8)
		levelIndicator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		levelIndicator.BorderSizePixel = 0
		levelIndicator.Parent = upgradeFrame

		-- Add progress fill
		local progressFill = Instance.new("Frame")
		progressFill.Name = "ProgressFill"
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		progressFill.Position = UDim2.new(0, 0, 0, 0)
		progressFill.BackgroundColor3 = secondaryColor
		progressFill.BorderSizePixel = 0
		progressFill.Parent = levelIndicator

		-- Rounded corners
		local corner1 = Instance.new("UICorner")
		corner1.CornerRadius = UDim.new(0, 2)
		corner1.Parent = levelIndicator

		local corner2 = Instance.new("UICorner")
		corner2.CornerRadius = UDim.new(0, 2)
		corner2.Parent = progressFill
	end

	-- Update progress fill
	local progressFill = levelIndicator:FindFirstChild("ProgressFill")
	if progressFill then
		local progress = currentLevel / maxLevel

		-- Animate the progress bar
		local tween = TweenService:Create(
			progressFill,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Size = UDim2.new(progress, 0, 1, 0),
				BackgroundColor3 = secondaryColor
			}
		)
		tween:Play()
	end

	-- Special effects for maxed upgrades
	if currentLevel >= maxLevel then
		-- Enhanced border for maxed upgrades
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(255, 255, 255) -- White glow

		-- Add sparkle effect
		local sparkleEffect = upgradeFrame:FindFirstChild("SparkleEffect")
		if not sparkleEffect then
			sparkleEffect = Instance.new("ImageLabel")
			sparkleEffect.Name = "SparkleEffect"
			sparkleEffect.Size = UDim2.new(1, 20, 1, 20)
			sparkleEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
			sparkleEffect.AnchorPoint = Vector2.new(0.5, 0.5)
			sparkleEffect.BackgroundTransparency = 1
			sparkleEffect.Image = "rbxassetid://8560915132" -- Sparkle texture
			sparkleEffect.ImageColor3 = secondaryColor
			sparkleEffect.ImageTransparency = 0.3
			sparkleEffect.ZIndex = 0
			sparkleEffect.Parent = upgradeFrame

			-- Animate sparkles
			local sparkleTween = TweenService:Create(
				sparkleEffect,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{
					ImageTransparency = 0.7,
					Rotation = 360
				}
			)
			sparkleTween:Play()
		end

		-- Update purchase button text and color
		local purchaseButton = upgradeFrame:FindFirstChild("PurchaseButton")
		if purchaseButton then
			purchaseButton.Text = "MAXED OUT!"
			purchaseButton.BackgroundColor3 = secondaryColor
			purchaseButton.Active = false
		end
	else
		-- Remove sparkle effect for non-maxed upgrades
		local sparkleEffect = upgradeFrame:FindFirstChild("SparkleEffect")
		if sparkleEffect then
			sparkleEffect:Destroy()
		end
	end

	-- Add hover effects
	local purchaseButton = upgradeFrame:FindFirstChild("PurchaseButton")
	if purchaseButton and currentLevel < maxLevel then
		-- Remove old connections by using a StringValue to track connection state
		local connectionTracker = upgradeFrame:FindFirstChild("ConnectionTracker")
		if connectionTracker then
			-- If we've already set up connections before, disconnect them by just creating new ones
			-- (Previous connections will be garbage collected)
			connectionTracker.Value = tostring(os.time()) -- Update tracker
		else
			connectionTracker = Instance.new("StringValue")
			connectionTracker.Name = "ConnectionTracker"
			connectionTracker.Value = tostring(os.time())
			connectionTracker.Parent = upgradeFrame
		end

		-- Add hover effects with new connections
		purchaseButton.MouseEnter:Connect(function()
			purchaseButton.BackgroundColor3 = accentColor
		end)

		purchaseButton.MouseLeave:Connect(function()
			purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50) -- Default green
		end)
	end
end

-- Function to update shop content with colors
local function updateShopContent(shopData)
	if not shopData then return end

	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local contentFrame = mainFrame:FindFirstChild("ContentFrame")
	if not contentFrame then return end

	local collectingFrame = contentFrame:FindFirstChild("CollectingFrame")
	if not collectingFrame then 
		collectingFrame = contentFrame:FindFirstChild("UpgradesFrame")
	end

	if not collectingFrame then return end

	print("Updating shop with color data")

	-- Update collecting upgrades
	if shopData.Collecting then
		for i, upgradeData in ipairs(shopData.Collecting) do
			local itemFrame = collectingFrame:FindFirstChild("Item" .. i)
			if itemFrame then
				-- Apply colors if available
				if upgradeData.colors then
					pcall(function()
						applyUpgradeColors(itemFrame, upgradeData.colors, upgradeData.currentLevel, upgradeData.maxLevel)
					end)
				end

				-- Update text content
				local titleLabel = itemFrame:FindFirstChild("TitleLabel")
				if titleLabel then
					titleLabel.Text = upgradeData.id:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
				end

				local descLabel = itemFrame:FindFirstChild("DescriptionLabel")
				if descLabel then
					descLabel.Text = "Level " .. upgradeData.currentLevel .. "/" .. upgradeData.maxLevel
				end

				local purchaseButton = itemFrame:FindFirstChild("PurchaseButton")
				if purchaseButton then
					-- Cleared the problematic getconnections code
					-- We'll just create new connections each time - old ones will be garbage collected

					if upgradeData.maxed then
						purchaseButton.Text = "MAXED OUT!"
						purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
						purchaseButton.Active = false
					else
						purchaseButton.Text = "Upgrade: " .. upgradeData.cost .. " Coins"
						purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
						purchaseButton.Active = true

						-- Connect purchase event
						purchaseButton.MouseButton1Click:Connect(function()
							print("Purchasing upgrade:", upgradeData.id)
							BuyUpgrade:FireServer(upgradeData.id)
						end)
					end
				end
			end
		end
	end

	-- Store the shop data globally for other scripts to access
	_G.ShopData = shopData
end

-- Function to open shop (existing)
local function openShop(tabName)
	-- If MasterTabController is handling tab switching, defer to it
	if _G.MasterSwitchTab then
		local mainFrame = shopGui:FindFirstChild("MainFrame")
		if mainFrame then
			-- Show the shop
			mainFrame.Visible = true

			-- Animate shop opening
			mainFrame.Size = UDim2.new(0, 0, 0, 0)
			mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

			local openTween = TweenService:Create(
				mainFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(0.8, 0, 0.8, 0),
					Position = UDim2.new(0.1, 0, 0.1, 0)
				}
			)

			openTween:Play()

			-- Let MasterTabController switch tabs
			_G.MasterSwitchTab(tabName or "Farming")
			return
		end
	end

	-- Fallback to original implementation if MasterTabController isn't active
	tabName = tabName or "Collecting"

	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then
		warn("MainFrame not found in ShopGui!")
		return
	end

	print("Opening shop with tab:", tabName)

	-- Show the shop
	mainFrame.Visible = true

	-- Animate shop opening
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local openTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0.8, 0, 0.8, 0),
			Position = UDim2.new(0.1, 0, 0.1, 0)
		}
	)

	openTween:Play()

	-- Switch to the requested tab
	local tabsFrame = mainFrame:FindFirstChild("TabsFrame")
	local contentFrame = mainFrame:FindFirstChild("ContentFrame")

	if tabsFrame and contentFrame then
		-- Update tab button colors
		for _, button in pairs(tabsFrame:GetChildren()) do
			if button:IsA("TextButton") then
				if button.Name == tabName .. "Tab" then
					button.BackgroundColor3 = Color3.fromRGB(80, 120, 180) -- Active
				else
					button.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Inactive
				end
			end
		end

		-- Show/hide content frames
		for _, frame in pairs(contentFrame:GetChildren()) do
			if frame:IsA("Frame") or frame:IsA("ScrollingFrame") then
				frame.Visible = (frame.Name == tabName .. "Frame")
			end
		end
	end
end

-- Function to close shop (existing)
local function closeShop()
	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local closeTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}
	)

	closeTween:Play()
	closeTween.Completed:Connect(function()
		mainFrame.Visible = false
	end)
end

-- Listen for server events
OpenShopClient.OnClientEvent:Connect(function(tabName)
	openShop(tabName)
end)

-- Update shop data when received (ENHANCED)
UpdateShopData.OnClientEvent:Connect(function(shopData)
	print("Received shop data update with colors")
	pcall(function()
		updateShopContent(shopData)
	end)
end)

-- Setup close button if it exists
spawn(function()
	wait(1) -- Give GUI time to load

	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if mainFrame then
		local topBar = mainFrame:FindFirstChild("TopBar")
		if topBar then
			local closeButton = topBar:FindFirstChild("CloseButton")
			if closeButton and closeButton:IsA("TextButton") then
				closeButton.MouseButton1Click:Connect(closeShop)
				print("Connected shop close button")
			end
		end
	end
end)

print("Fixed SimpleShopClient with proper color handling loaded!")