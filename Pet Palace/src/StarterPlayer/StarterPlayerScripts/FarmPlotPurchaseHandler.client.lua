--[[
    FarmPlotPurchaseHandler.client.lua
    Add this to your GameClient.lua or create as separate client script
    Handles farm plot purchase UI and visual feedback
]]

-- Add this function to your GameClient.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameClient = require(ReplicatedStorage:WaitForChild("GameClient"))
-- UPDATED: Enhanced shop menu with farm plot purchase system
function GameClient:RefreshShopMenu()
	local menu = self.UI.Menus.Shop
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- FIXED: Clear existing content to prevent duplication
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("UIGridLayout") then
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

			-- Create shop sections
			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 10)
			layout.Parent = contentArea

			-- Check if player has farm plot
			local playerData = self:GetPlayerData()
			local hasFarmPlot = playerData and playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter

			-- Create shop categories with farm plot priority
			local categories = {
				{name = "🌾 Farming System", items = {}, priority = 1},
				{name = "💰 Upgrades", items = {}, priority = 2},
				{name = "🌱 Seeds & Tools", items = {}, priority = 3},
				{name = "📦 Seed Packs", items = {}, priority = 4}
			}

			-- Sort items into categories with special handling for farm plots
			for itemId, item in pairs(shopItems) do
				if itemId == "farm_plot_starter" then
					-- Always show starter plot if not owned
					if not hasFarmPlot then
						table.insert(categories[1].items, {id = itemId, data = item})
					end
				elseif itemId == "farm_plot_upgrade" then
					-- Only show additional plots if player has starter plot
					if hasFarmPlot then
						table.insert(categories[1].items, {id = itemId, data = item})
					end
				elseif item.type == "upgrade" and not item.requiresFarmPlot then
					table.insert(categories[2].items, {id = itemId, data = item})
				elseif item.type == "seed" then
					if hasFarmPlot then -- Only show seeds if player has farm plot
						table.insert(categories[3].items, {id = itemId, data = item})
					end
				elseif item.type == "egg" then
					if hasFarmPlot then -- Only show seed packs if player has farm plot
						table.insert(categories[4].items, {id = itemId, data = item})
					end
				else
					-- Other upgrades that don't require farm plots
					table.insert(categories[2].items, {id = itemId, data = item})
				end
			end

			-- Create UI for each category that has items
			for i, category in ipairs(categories) do
				if #category.items > 0 then
					self:CreateShopCategory(contentArea, category.name, category.items, i)
				end
			end

			-- Add helpful message if no farm plot
			if not hasFarmPlot then
				self:CreateFarmPlotPromotion(contentArea)
			end

			-- Update canvas size
			spawn(function()
				wait(0.1)
				contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
			end)
		else
			-- Show error message
			local errorLabel = Instance.new("TextLabel")
			errorLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
			errorLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
			errorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			errorLabel.BackgroundTransparency = 1
			errorLabel.Text = "Failed to load shop items\nPlease try again later"
			errorLabel.TextColor3 = Color3.new(0.8, 0.3, 0.3)
			errorLabel.TextScaled = true
			errorLabel.Font = Enum.Font.SourceSansSemibold
			errorLabel.Parent = contentArea
		end
	end
end

-- NEW: Create farm plot promotion section
function GameClient:CreateFarmPlotPromotion(parent)
	local promoFrame = Instance.new("Frame")
	promoFrame.Name = "FarmPlotPromotion"
	promoFrame.Size = UDim2.new(1, 0, 0, 120)
	promoFrame.BackgroundColor3 = Color3.fromRGB(60, 100, 40)
	promoFrame.BorderSizePixel = 0
	promoFrame.LayoutOrder = 0 -- Show at top
	promoFrame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = promoFrame

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 100, 40))
	}
	gradient.Rotation = 45
	gradient.Parent = promoFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.7, 0, 0.4, 0)
	title.Position = UDim2.new(0.05, 0, 0.1, 0)
	title.BackgroundTransparency = 1
	title.Text = "🌾 Start Your Farming Journey!"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = promoFrame

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.7, 0, 0.4, 0)
	desc.Position = UDim2.new(0.05, 0, 0.5, 0)
	desc.BackgroundTransparency = 1
	desc.Text = "Purchase your first farm plot for only 100 coins!\nIncludes free starter seeds and automatic placement."
	desc.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	desc.TextScaled = true
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Parent = promoFrame

	-- Farm icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0.2, 0, 0.6, 0)
	icon.Position = UDim2.new(0.75, 0, 0.2, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "🚜"
	icon.TextScaled = true
	icon.Font = Enum.Font.SourceSansSemibold
	icon.Parent = promoFrame
end

-- UPDATED: Create shop item with enhanced farm plot display
function GameClient:CreateShopItem(parent, itemId, itemData, layoutOrder)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = itemId .. "_Item"
	itemFrame.Size = UDim2.new(1, 0, 0, itemId == "farm_plot_starter" and 90 or 70) -- Bigger for starter plot
	itemFrame.BackgroundColor3 = itemId == "farm_plot_starter" and Color3.fromRGB(80, 120, 60) or Color3.fromRGB(50, 50, 60)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = layoutOrder
	itemFrame.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.05, 0)
	itemCorner.Parent = itemFrame

	-- Special glow for farm plot starter
	if itemId == "farm_plot_starter" then
		local glow = Instance.new("UIStroke")
		glow.Color = Color3.fromRGB(120, 200, 80)
		glow.Thickness = 2
		glow.Transparency = 0.3
		glow.Parent = itemFrame

		-- Animated glow effect
		local glowTween = game:GetService("TweenService"):Create(glow,
			TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.7}
		)
		glowTween:Play()
	end

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name or itemId
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.4, 0, 0.5, 0)
	descLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemData.description or "No description"
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = itemFrame

	-- Price label with enhanced styling for farm plot
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 0.4, 0)
	priceLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
	priceLabel.BackgroundTransparency = 1
	local currencyIcon = (itemData.currency == "gems") and "💎" or "💰"
	priceLabel.Text = (itemData.price or 0) .. " " .. currencyIcon
	priceLabel.TextColor3 = itemId == "farm_plot_starter" and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(255, 215, 0)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = itemFrame

	-- Special pricing note for farm plot upgrades
	if itemId == "farm_plot_upgrade" then
		local playerData = self:GetPlayerData()
		if playerData and playerData.upgrades then
			local currentLevel = playerData.upgrades[itemId] or 0
			local nextCost = self:CalculateNextUpgradeCost(itemId, currentLevel)
			if nextCost > 0 then
				priceLabel.Text = nextCost .. " " .. currencyIcon
			end
		end
	end

	-- Buy button with enhanced styling
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.2, 0, 0.6, 0)
	buyButton.Position = UDim2.new(0.75, 0, 0.2, 0)
	buyButton.BorderSizePixel = 0
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = itemFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.1, 0)
	buyCorner.Parent = buyButton

	-- Check if player can afford and configure button
	local playerData = self:GetPlayerData()
	if playerData then
		local currency = (itemData.currency or "coins"):lower()
		local playerCurrency = playerData[currency] or 0
		local itemPrice = itemData.price or 0

		-- Special handling for upgrades
		if itemData.type == "upgrade" and itemId ~= "farm_plot_starter" then
			local currentLevel = (playerData.upgrades and playerData.upgrades[itemId]) or 0
			local maxLevel = itemData.maxLevel or 10

			if currentLevel >= maxLevel then
				buyButton.Text = "MAX LEVEL"
				buyButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
				buyButton.TextColor3 = Color3.fromRGB(180, 180, 180)
				buyButton.Active = false
			else
				itemPrice = self:CalculateNextUpgradeCost(itemId, currentLevel)
				local canAfford = playerCurrency >= itemPrice

				buyButton.Text = canAfford and "BUY" or "Need " .. (itemPrice - playerCurrency)
				buyButton.BackgroundColor3 = canAfford and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(120, 60, 60)
				buyButton.TextColor3 = Color3.new(1, 1, 1)
				buyButton.Active = canAfford
			end
		else
			-- Regular items and farm plot starter
			local canAfford = playerCurrency >= itemPrice

			-- Special text for farm plot starter
			if itemId == "farm_plot_starter" then
				buyButton.Text = canAfford and "🌾 START FARMING!" or "Need " .. (itemPrice - playerCurrency) .. " coins"
				buyButton.BackgroundColor3 = canAfford and Color3.fromRGB(100, 180, 60) or Color3.fromRGB(120, 60, 60)
			else
				buyButton.Text = canAfford and "BUY" or "Can't Afford"
				buyButton.BackgroundColor3 = canAfford and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(120, 60, 60)
			end

			buyButton.TextColor3 = Color3.new(1, 1, 1)
			buyButton.Active = canAfford
		end

		-- Connect purchase event
		if buyButton.Active then
			buyButton.MouseButton1Click:Connect(function()
				self:PurchaseItem(itemId, itemData)
			end)
		end
	end

	return itemFrame
end

-- NEW: Enhanced purchase function with farm plot handling
function GameClient:PurchaseItem(itemId, itemData)
	if not self.RemoteEvents.PurchaseItem then
		warn("GameClient: PurchaseItem remote event not found")
		return
	end

	-- Special confirmation for farm plot starter
	if itemId == "farm_plot_starter" then
		self:ShowConfirmationDialog(
			"🌾 Purchase Farm Plot",
			"Purchase your first farm plot for 100 coins?\n\n• Automatically placed in Starter Meadow\n• Includes free starter seeds\n• Unlocks farming system\n\nThis is a one-time purchase!",
			function()
				self.RemoteEvents.PurchaseItem:FireServer(itemId, 1)
				self:ShowNotification("Purchase Sent", "Processing your farm plot purchase...", "info")
			end
		)
	else
		-- Regular purchase
		self.RemoteEvents.PurchaseItem:FireServer(itemId, 1)
	end
end

-- NEW: Calculate next upgrade cost (client-side for display)
function GameClient:CalculateNextUpgradeCost(upgradeId, currentLevel)
	local shopItems = self.Cache.ShopItems
	if not shopItems or not shopItems[upgradeId] then return 0 end

	local upgrade = shopItems[upgradeId]
	if currentLevel >= (upgrade.maxLevel or 10) then return 0 end

	local basePrice = upgrade.price or 0
	local nextLevel = currentLevel + 1

	-- Special pricing for farm plots
	if upgradeId == "farm_plot_upgrade" then
		local multiplier = upgrade.priceMultiplier or 1.3
		return math.floor(basePrice * (multiplier ^ currentLevel))
	else
		-- Standard upgrade pricing
		local priceMultiplier = 1.5
		return math.floor(basePrice * (priceMultiplier ^ (nextLevel - 1)))
	end
end

-- UPDATED: Handle item purchased with farm plot success feedback
function GameClient:HandleItemPurchased(itemId, quantity, cost, currency)
	if self.PlayerData then
		if currency == "coins" then
			self.PlayerData.coins = math.max(0, (self.PlayerData.coins or 0) - cost)
		elseif currency == "gems" then
			self.PlayerData.gems = math.max(0, (self.PlayerData.gems or 0) - cost)
		end

		self:UpdateCurrencyDisplay()
	end

	local itemName = itemId
	if self.Cache.ShopItems and self.Cache.ShopItems[itemId] then
		itemName = self.Cache.ShopItems[itemId].name or itemId
	end

	-- Special success message for farm plot
	if itemId == "farm_plot_starter" then
		self:ShowNotification("🌾 Farm Plot Created!", 
			"Your farm plot has been created in Starter Meadow! Check it out and start planting!", "success")

		-- Refresh shop menu to show new farming options
		if self.UIState.CurrentPage == "Shop" then
			wait(1) -- Small delay for server processing
			self:RefreshShopMenu()
		end
	elseif itemId == "farm_plot_upgrade" then
		self:ShowNotification("New Farm Plot Added!", 
			"Additional farm plot created next to your existing ones!", "success")
	else
		self:ShowNotification("Purchase Successful!", 
			"Bought " .. (quantity > 1 and (quantity .. "x ") or "") .. itemName .. " for " .. cost .. " " .. currency, 
			"success")
	end

	print("GameClient: Purchased " .. itemId .. " x" .. quantity .. " for " .. cost .. " " .. currency)
end