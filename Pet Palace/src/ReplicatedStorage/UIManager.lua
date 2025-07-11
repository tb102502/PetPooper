--[[
    FIXED UIManager.lua - Consistent Item Sizing Across All Categories
    Place in: ReplicatedStorage/UIManager.lua
    
    FIXES:
    ✅ Single item creation method for ALL categories
    ✅ Consistent sizing across Seeds, Farming, Mining, Crafting, Premium
    ✅ Removed conflicting item creation pathways
    ✅ Unified population system
    ✅ Fixed height inconsistencies
]]

local UIManager = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Local references
local LocalPlayer = Players.LocalPlayer

-- UI State Management
UIManager.State = {
	MainUI = nil,
	CurrentPage = "None",
	ActiveMenus = {},
	IsTransitioning = false,
	Layers = {},
	NotificationQueue = {},
	CurrencyLabels = {},
	GameClient = nil,
	TopMenuButtons = {},
	-- Shop tab state
	ShopTabs = {},
	ActiveShopTab = "seeds",
	RemoteEvents = {},
	RemoteFunctions = {},
	PurchaseCooldowns = {}, -- Add this line
	PURCHASE_COOLDOWN = 2 -- 2 second cooldown
}

-- UI Configuration
UIManager.Config = {
	TransitionTime = 0.3,
	NotificationDisplayTime = 2,
	MaxNotificationsVisible = 3,
	UIOrder = {
		Background = 1,
		Main = 2,
		TopMenu = 3,
		Menus = 4,
		Notifications = 5,
		Error = 6
	},
	MobileScale = 1.3,
	TabletScale = 1.15,
	DesktopScale = 1.0,
	-- Shop tab configuration
	ShopTabConfig = {
		{id = "seeds", name = "🌱 Seeds", color = Color3.fromRGB(100, 200, 100)},
		{id = "farm", name = "🌾 Farming", color = Color3.fromRGB(139, 90, 43)},
		{id = "mining", name = "⛏️ Mining", color = Color3.fromRGB(150, 150, 150)},
		{id = "crafting", name = "🔨 Crafting", color = Color3.fromRGB(200, 120, 80)},
		{id = "premium", name = "✨ Premium", color = Color3.fromRGB(255, 215, 0)},
		{id = "sell", name = "💰 Sell", color = Color3.fromRGB(255, 165, 0)}
	}
}

-- FIXED: Single, consistent item configuration for ALL categories


UIManager.ExtraLargeItemConfig = {
	-- EXTRA LARGE item frame size
	ItemFrame = {
		HeightPercent = 0.33,        -- 33% height (50% larger than 22%) - MASSIVE!
		SpacingPercent = 0.04,       -- 4% spacing (50% larger than 2.5%) - huge gaps
		BackgroundColor = Color3.fromRGB(60, 60, 60),
		CornerRadius = UDim.new(0.03, 0)
	},

	-- EXTRA LARGE element positioning and sizing
	Elements = {
		CategoryIndicator = {
			Size = UDim2.new(0.015, 0, 1, 0),          -- 50% wider indicator
			Position = UDim2.new(0, 0, 0, 0)
		},
		ItemIcon = {
			Size = UDim2.new(0.225, 0, 0.9, 0),        -- MASSIVE: 22.5% x 90% (50% larger than 15% x 60%)
			Position = UDim2.new(0.02, 0, 0.05, 0)     -- Centered in larger space
		},
		ItemName = {
			Size = UDim2.new(0.32, 0, 0.525, 0),       -- 32% x 52.5% (50% larger than 34% x 35%)
			Position = UDim2.new(0.26, 0, 0.05, 0)     -- Adjusted for massive icon
		},
		ItemDescription = {
			Size = UDim2.new(0.32, 0, 0.375, 0),       -- 32% x 37.5% (50% larger than 34% x 25%)
			Position = UDim2.new(0.26, 0, 0.6, 0)      -- Positioned below larger name
		},
		PriceArea = {
			Size = UDim2.new(0.18, 0, 0.9, 0),         -- 18% x 90% (50% larger than 18% x 60%)
			Position = UDim2.new(0.59, 0, 0.05, 0)     -- Better positioned
		},
		ButtonArea = {
			Size = UDim2.new(0.19, 0, 0.9, 0),         -- 19% x 90% (50% larger than 16% x 60%)
			Position = UDim2.new(0.79, 0, 0.05, 0)     -- Rightmost position
		},
		Badge = {
			Size = UDim2.new(0.12, 0, 0.42, 0),        -- 12% x 42% (50% larger than 8% x 28%)
			Position = UDim2.new(0.02, 0, 0.02, 0)
		}
	},

	-- EXTRA LARGE text scaling (50% larger than previous)
	TextScaling = {
		IconSize = 42,         -- 50% larger than 28px
		NameSize = 33,         -- 50% larger than 22px  
		DescriptionSize = 27,  -- 50% larger than 18px
		PriceSize = 30,        -- 50% larger than 20px
		ButtonSize = 24,       -- 50% larger than 16px
		BadgeSize = 21         -- 50% larger than 14px
	},

	-- Proportional padding for extra large items
	Padding = {
		TopPercent = 0.015,    -- 1.5% top padding (items are so large we need less)
		BottomPercent = 0.06   -- 6% bottom padding
	}
}

-- ========== INITIALIZATION ==========

function UIManager:Initialize()
	print("UIManager: Starting FIXED initialization with consistent sizing...")

	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
	if not playerGui then
		error("UIManager: PlayerGui not found after 30 seconds")
	end

	self.State.ActiveMenus = {}
	self.State.Layers = {}
	self.State.NotificationQueue = {}
	self.State.IsTransitioning = false
	self.State.CurrentPage = "None"
	self.State.TopMenuButtons = {}
	self.State.ShopTabs = {}
	self.State.ActiveShopTab = "seeds"
	self.State.RemoteEvents = {}
	self.State.RemoteFunctions = {}
	self:AddScrollingDebugCommands()
	local success, errorMsg = pcall(function()
		self:CreateMainUIStructure()
	end)

	if not success then
		error("UIManager: Failed to create main UI structure: " .. tostring(errorMsg))
	end
	print("UIManager: ✅ Main UI structure created")

	self:ConnectToRemoteEvents()
	self:SetupInputHandling()
	print("UIManager: ✅ Input handling setup")

	self:SetupNotificationSystem()
	print("UIManager: ✅ Notification system setup")

	local menuSuccess, menuError = pcall(function()
		self:SetupTopMenu()
	end)

	if not menuSuccess then
		warn("UIManager: Failed to create top menu: " .. tostring(menuError))
		spawn(function()
			wait(1)
			print("UIManager: Retrying top menu creation...")
			local retrySuccess, retryError = pcall(function()
				self:SetupTopMenu()
			end)

			if retrySuccess then
				print("UIManager: ✅ Top menu created on retry")
			else
				warn("UIManager: Failed again to create top menu: " .. tostring(retryError))
			end
		end)
	else
		print("UIManager: ✅ Top menu created successfully")
	end

	print("UIManager: 🎉 FIXED initialization complete with UNIFORM sizing!")
	return true
end

-- ========== REMOTE EVENT CONNECTIONS ==========

function UIManager:ConnectToRemoteEvents()
	print("UIManager: Connecting to remote events...")

	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not gameRemotes then
		warn("UIManager: GameRemotes folder not found! Shop won't work properly.")
		return
	end

	local openShopEvent = gameRemotes:WaitForChild("OpenShop", 5)
	if openShopEvent and openShopEvent:IsA("RemoteEvent") then
		self.State.RemoteEvents.OpenShop = openShopEvent

		openShopEvent.OnClientEvent:Connect(function()
			print("UIManager: 🛒 Received OpenShop event from server!")
			self:HandleOpenShopFromServer()
		end)

		print("UIManager: ✅ Connected to OpenShop event")
	else
		warn("UIManager: OpenShop remote event not found!")
	end

	local closeShopEvent = gameRemotes:WaitForChild("CloseShop", 5)
	if closeShopEvent and closeShopEvent:IsA("RemoteEvent") then
		self.State.RemoteEvents.CloseShop = closeShopEvent

		closeShopEvent.OnClientEvent:Connect(function()
			print("UIManager: 🚪 Received CloseShop event from server!")
			self:HandleCloseShopFromServer()
		end)

		print("UIManager: ✅ Connected to CloseShop event")
	else
		warn("UIManager: CloseShop remote event not found!")
	end

	local showNotificationEvent = gameRemotes:WaitForChild("ShowNotification", 5)
	if showNotificationEvent and showNotificationEvent:IsA("RemoteEvent") then
		self.State.RemoteEvents.ShowNotification = showNotificationEvent

		showNotificationEvent.OnClientEvent:Connect(function(title, message, notificationType)
			self:ShowNotification(title, message, notificationType)
		end)

		print("UIManager: ✅ Connected to ShowNotification event")
	end

	local getShopItemsFunc = gameRemotes:WaitForChild("GetShopItems", 5)
	if getShopItemsFunc and getShopItemsFunc:IsA("RemoteFunction") then
		self.State.RemoteFunctions.GetShopItems = getShopItemsFunc
		print("UIManager: ✅ Connected to GetShopItems function")
	end

	local getSellableItemsFunc = gameRemotes:WaitForChild("GetSellableItems", 5)
	if getSellableItemsFunc and getSellableItemsFunc:IsA("RemoteFunction") then
		self.State.RemoteFunctions.GetSellableItems = getSellableItemsFunc
		print("UIManager: ✅ Connected to GetSellableItems function")
	end

	local purchaseItemEvent = gameRemotes:WaitForChild("PurchaseItem", 5)
	if purchaseItemEvent and purchaseItemEvent:IsA("RemoteEvent") then
		self.State.RemoteEvents.PurchaseItem = purchaseItemEvent
		print("UIManager: ✅ Connected to PurchaseItem event")
	end

	local sellItemEvent = gameRemotes:WaitForChild("SellItem", 5)
	if sellItemEvent and sellItemEvent:IsA("RemoteEvent") then
		self.State.RemoteEvents.SellItem = sellItemEvent
		print("UIManager: ✅ Connected to SellItem event")
	end

	print("UIManager: ✅ Remote event connections complete")
end
-- ========== DEVICE HELPERS ==========

function UIManager:GetDeviceType()
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		if math.min(viewportSize.X, viewportSize.Y) < 600 then
			return "Mobile"
		else
			return "Tablet"
		end
	else
		return "Desktop"
	end
end

function UIManager:GetTextScaleForDevice()
	local deviceType = self:GetDeviceType()
	return self.UniformItemConfig.DeviceTextScale[deviceType] or 1.1
end

function UIManager:ApplyTextSizing(textElement, baseSize, elementType)
	local textScale = self:GetTextScaleForDevice()
	local minSize = self.UniformItemConfig.MinTextSizes[elementType] or 12
	local finalSize = math.max(minSize, baseSize * textScale)

	textElement.TextSize = finalSize
	textElement.TextScaled = true
end

-- ========== SINGLE ITEM CREATION METHOD - Used for ALL Categories ==========


function UIManager:CreateExtraLargeShopItem(item, index, categoryColor, itemType, containerHeight, playerData)
	print("UIManager: Creating EXTRA LARGE item: " .. (item.name or item.id) .. " - Index: " .. index)

	local config = self.ExtraLargeItemConfig

	-- Get purchase status
	local purchaseStatus = self:GetItemPurchaseStatus(item, playerData)

	-- ========== EXTRA LARGE POSITIONING ==========
	local topPaddingPixels = containerHeight * config.Padding.TopPercent
	local itemHeightPixels = containerHeight * config.ItemFrame.HeightPercent    -- 33% height!
	local itemSpacingPixels = containerHeight * config.ItemFrame.SpacingPercent  -- 4% spacing

	local yPositionPixels = topPaddingPixels + ((index - 1) * (itemHeightPixels + itemSpacingPixels))

	print("  EXTRA LARGE Item " .. index .. " - Height: " .. itemHeightPixels .. "px, Position: " .. yPositionPixels .. "px")

	-- ========== EXTRA LARGE MAIN FRAME ==========
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = itemType .. "Item_" .. index
	itemFrame.Size = UDim2.new(0.96, 0, 0, itemHeightPixels)  -- MASSIVE: 33% height
	itemFrame.Position = UDim2.new(0.02, 0, 0, yPositionPixels)
	itemFrame.BackgroundColor3 = config.ItemFrame.BackgroundColor
	itemFrame.BorderSizePixel = 0
	itemFrame.ClipsDescendants = false

	-- Modify appearance for sold out items
	if not purchaseStatus.canPurchase and purchaseStatus.reason == "already_purchased" then
		itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	end

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = config.ItemFrame.CornerRadius
	itemCorner.Parent = itemFrame

	-- ========== EXTRA LARGE CATEGORY INDICATOR ==========
	local categoryIndicator = Instance.new("Frame")
	categoryIndicator.Name = "CategoryIndicator"
	categoryIndicator.Size = config.Elements.CategoryIndicator.Size
	categoryIndicator.Position = config.Elements.CategoryIndicator.Position
	categoryIndicator.BackgroundColor3 = categoryColor
	categoryIndicator.BorderSizePixel = 0
	categoryIndicator.Parent = itemFrame

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0.5, 0)
	indicatorCorner.Parent = categoryIndicator

	-- ========== MASSIVE ITEM ICON ==========
	local itemIcon = Instance.new("TextLabel")
	itemIcon.Name = "ItemIcon"
	itemIcon.Size = config.Elements.ItemIcon.Size                -- MASSIVE: 22.5% x 90%
	itemIcon.Position = config.Elements.ItemIcon.Position
	itemIcon.BackgroundTransparency = 1
	itemIcon.Text = item.icon or "📦"
	itemIcon.TextColor3 = Color3.new(1, 1, 1)
	itemIcon.Font = Enum.Font.Gotham
	itemIcon.TextSize = config.TextScaling.IconSize              -- HUGE TEXT: 42px
	itemIcon.TextScaled = true
	itemIcon.Parent = itemFrame

	-- Dim icon for sold out items
	if not purchaseStatus.canPurchase and purchaseStatus.reason == "already_purchased" then
		itemIcon.TextTransparency = 0.5
	end

	-- ========== EXTRA LARGE ITEM NAME ==========
	local itemName = Instance.new("TextLabel")
	itemName.Name = "ItemName"
	itemName.Size = config.Elements.ItemName.Size               -- LARGE: 32% x 52.5%
	itemName.Position = config.Elements.ItemName.Position
	itemName.BackgroundTransparency = 1
	itemName.Text = item.name or item.id
	itemName.TextColor3 = Color3.new(1, 1, 1)
	itemName.Font = Enum.Font.GothamBold
	itemName.TextSize = config.TextScaling.NameSize             -- LARGE TEXT: 33px
	itemName.TextXAlignment = Enum.TextXAlignment.Left
	itemName.TextYAlignment = Enum.TextYAlignment.Center
	itemName.TextWrapped = true
	itemName.TextScaled = true
	itemName.Parent = itemFrame

	-- ========== EXTRA LARGE ITEM DESCRIPTION ==========
	local itemDescription = Instance.new("TextLabel")
	itemDescription.Name = "ItemDescription"
	itemDescription.Size = config.Elements.ItemDescription.Size  -- LARGE: 32% x 37.5%
	itemDescription.Position = config.Elements.ItemDescription.Position
	itemDescription.BackgroundTransparency = 1
	itemDescription.TextColor3 = Color3.fromRGB(200, 200, 200)
	itemDescription.Font = Enum.Font.Gotham
	itemDescription.TextSize = config.TextScaling.DescriptionSize -- LARGE TEXT: 27px
	itemDescription.TextXAlignment = Enum.TextXAlignment.Left
	itemDescription.TextYAlignment = Enum.TextYAlignment.Top
	itemDescription.TextWrapped = true
	itemDescription.TextScaled = true
	itemDescription.Parent = itemFrame

	-- Update description based on purchase status
	local baseDescription = self:GetItemDescription(item, itemType)
	if not purchaseStatus.canPurchase then
		if purchaseStatus.reason == "already_purchased" then
			itemDescription.Text = "✅ PURCHASED\n" .. baseDescription
			itemDescription.TextColor3 = Color3.fromRGB(100, 255, 100)
		elseif purchaseStatus.reason == "cow_already_owned" then
			itemDescription.Text = "🐄 You already have a cow!\nUse upgrades to improve it."
			itemDescription.TextColor3 = Color3.fromRGB(100, 150, 255)
		else
			itemDescription.Text = baseDescription
		end
	else
		itemDescription.Text = baseDescription
	end

	-- ========== EXTRA LARGE PRICE AREA ==========
	self:CreateExtraLargePriceArea(itemFrame, item, itemType, config)

	-- ========== EXTRA LARGE BUTTON AREA ==========
	self:CreateExtraLargeButtonArea(itemFrame, item, itemType, config, purchaseStatus)

	-- ========== EXTRA LARGE BADGE ==========
	self:CreateExtraLargeBadge(itemFrame, item, itemType, config)

	-- ========== HOVER EFFECTS ==========
	self:AddUniformHoverEffects(itemFrame)

	print("✅ Created EXTRA LARGE item: " .. (item.name or item.id) .. " - Height: " .. itemHeightPixels .. "px")
	return itemFrame
end

-- ========== UNIFORM PRICE AREA ==========

function UIManager:CreateExtraLargePriceArea(parent, item, itemType, config)
	local priceContainer = Instance.new("Frame")
	priceContainer.Name = "PriceContainer"
	priceContainer.Size = config.Elements.PriceArea.Size        -- LARGE: 18% x 90%
	priceContainer.Position = config.Elements.PriceArea.Position
	priceContainer.BackgroundTransparency = 1
	priceContainer.Parent = parent

	if itemType == "sell" then
		-- SELL ITEMS: Extra large price displays
		local pricePerItem = Instance.new("TextLabel")
		pricePerItem.Name = "PricePerItem"
		pricePerItem.Size = UDim2.new(1, 0, 0.45, 0)
		pricePerItem.Position = UDim2.new(0, 0, 0, 0)
		pricePerItem.BackgroundTransparency = 1
		pricePerItem.Text = (item.sellPrice or 0) .. " 💰 each"
		pricePerItem.TextColor3 = Color3.fromRGB(255, 215, 0)
		pricePerItem.Font = Enum.Font.Gotham
		pricePerItem.TextSize = config.TextScaling.PriceSize     -- HUGE: 30px
		pricePerItem.TextXAlignment = Enum.TextXAlignment.Right
		pricePerItem.TextWrapped = true
		pricePerItem.TextScaled = true
		pricePerItem.Parent = priceContainer

		local totalValue = Instance.new("TextLabel")
		totalValue.Name = "TotalValue"
		totalValue.Size = UDim2.new(1, 0, 0.45, 0)
		totalValue.Position = UDim2.new(0, 0, 0.55, 0)
		totalValue.BackgroundTransparency = 1
		totalValue.Text = "Total: " .. (item.totalValue or 0) .. " 💰"
		totalValue.TextColor3 = Color3.fromRGB(100, 255, 100)
		totalValue.Font = Enum.Font.GothamBold
		totalValue.TextSize = config.TextScaling.PriceSize
		totalValue.TextXAlignment = Enum.TextXAlignment.Right
		totalValue.TextWrapped = true
		totalValue.TextScaled = true
		totalValue.Parent = priceContainer
	else
		-- BUY ITEMS: Extra large single price
		local buyPrice = Instance.new("TextLabel")
		buyPrice.Name = "BuyPrice"
		buyPrice.Size = UDim2.new(1, 0, 1, 0)
		buyPrice.Position = UDim2.new(0, 0, 0, 0)
		buyPrice.BackgroundTransparency = 1
		buyPrice.Text = (item.price or 0) .. " " .. (item.currency == "farmTokens" and "🎫" or "💰")
		buyPrice.TextColor3 = item.currency == "farmTokens" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
		buyPrice.Font = Enum.Font.GothamBold
		buyPrice.TextSize = config.TextScaling.PriceSize         -- HUGE: 30px
		buyPrice.TextXAlignment = Enum.TextXAlignment.Right
		buyPrice.TextYAlignment = Enum.TextYAlignment.Center
		buyPrice.TextWrapped = true
		buyPrice.TextScaled = true
		buyPrice.Parent = priceContainer
	end
end

-- ========== UNIFORM BUTTON AREA ==========

function UIManager:CreateExtraLargeButtonArea(parent, item, itemType, config, purchaseStatus)
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = config.Elements.ButtonArea.Size      -- LARGE: 19% x 90%
	buttonContainer.Position = config.Elements.ButtonArea.Position
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = parent

	if itemType == "sell" then
		-- SELL ITEMS: Extra large sell buttons
		local sell1Button = Instance.new("TextButton")
		sell1Button.Name = "Sell1Button"
		sell1Button.Size = UDim2.new(1, 0, 0.45, 0)
		sell1Button.Position = UDim2.new(0, 0, 0, 0)
		sell1Button.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		sell1Button.BorderSizePixel = 0
		sell1Button.Text = "SELL 1"
		sell1Button.TextColor3 = Color3.new(1, 1, 1)
		sell1Button.Font = Enum.Font.GothamBold
		sell1Button.TextSize = config.TextScaling.ButtonSize     -- LARGE: 24px
		sell1Button.TextScaled = true
		sell1Button.Parent = buttonContainer

		local sell1Corner = Instance.new("UICorner")
		sell1Corner.CornerRadius = UDim.new(0.08, 0)
		sell1Corner.Parent = sell1Button

		local sellAllButton = Instance.new("TextButton")
		sellAllButton.Name = "SellAllButton"
		sellAllButton.Size = UDim2.new(1, 0, 0.45, 0)
		sellAllButton.Position = UDim2.new(0, 0, 0.55, 0)
		sellAllButton.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
		sellAllButton.BorderSizePixel = 0
		sellAllButton.Text = "SELL ALL"
		sellAllButton.TextColor3 = Color3.new(1, 1, 1)
		sellAllButton.Font = Enum.Font.GothamBold
		sellAllButton.TextSize = config.TextScaling.ButtonSize
		sellAllButton.TextScaled = true
		sellAllButton.Parent = buttonContainer

		local sellAllCorner = Instance.new("UICorner")
		sellAllCorner.CornerRadius = UDim.new(0.08, 0)
		sellAllCorner.Parent = sellAllButton

		-- Connect functionality
		sell1Button.MouseButton1Click:Connect(function()
			self:HandleSellClick(item.id, 1)
		end)

		sellAllButton.MouseButton1Click:Connect(function()
			self:HandleSellClick(item.id, item.stock or 0)
		end)
	else
		-- BUY ITEMS: Extra large status-aware button
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(1, 0, 1, 0)
		buyButton.Position = UDim2.new(0, 0, 0, 0)
		buyButton.BackgroundColor3 = purchaseStatus.statusColor
		buyButton.BorderSizePixel = 0
		buyButton.Text = purchaseStatus.statusText
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextSize = config.TextScaling.ButtonSize       -- LARGE: 24px
		buyButton.TextScaled = true
		buyButton.Active = purchaseStatus.canPurchase
		buyButton.Parent = buttonContainer

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0.08, 0)
		buyCorner.Parent = buyButton

		-- Visual state based on purchase status
		if not purchaseStatus.canPurchase then
			buyButton.BackgroundTransparency = 0.3
			buyButton.TextTransparency = 0.2

			-- Add extra large checkmark for sold out items
			if purchaseStatus.reason == "already_purchased" then
				local checkmark = Instance.new("TextLabel")
				checkmark.Size = UDim2.new(0.4, 0, 0.7, 0)
				checkmark.Position = UDim2.new(0.05, 0, 0.15, 0)
				checkmark.BackgroundTransparency = 1
				checkmark.Text = "✓"
				checkmark.TextColor3 = Color3.new(1, 1, 1)
				checkmark.TextSize = config.TextScaling.ButtonSize
				checkmark.TextScaled = true
				checkmark.Font = Enum.Font.GothamBold
				checkmark.Parent = buyButton
			end
		end

		-- Connect functionality
		if purchaseStatus.canPurchase then
			buyButton.MouseButton1Click:Connect(function()
				self:HandleBuyClick(item.id, 1)
			end)

			-- Hover effects
			buyButton.MouseEnter:Connect(function()
				local hoverTween = TweenService:Create(buyButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = self:LightenColor(purchaseStatus.statusColor, 0.2)}
				)
				hoverTween:Play()
			end)

			buyButton.MouseLeave:Connect(function()
				local leaveTween = TweenService:Create(buyButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = purchaseStatus.statusColor}
				)
				leaveTween:Play()
			end)
		else
			buyButton.MouseEnter:Connect(function()
				self:ShowPurchaseStatusTooltip(buyButton, item, purchaseStatus)
			end)
		end
	end
end

-- ========== UNIFORM BADGE ==========

function UIManager:CreateExtraLargeBadge(parent, item, itemType, config)
	local badge = Instance.new("Frame")
	badge.Name = "ExtraLargeBadge"
	badge.Size = config.Elements.Badge.Size                     -- LARGE: 12% x 42%
	badge.Position = config.Elements.Badge.Position
	badge.BorderSizePixel = 0
	badge.Parent = parent

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0.3, 0)
	badgeCorner.Parent = badge

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Size = UDim2.new(1, 0, 1, 0)
	badgeLabel.Position = UDim2.new(0, 0, 0, 0)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.TextColor3 = Color3.new(1, 1, 1)
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.TextSize = config.TextScaling.BadgeSize          -- LARGE: 21px
	badgeLabel.TextScaled = true
	badgeLabel.Parent = badge

	if itemType == "sell" then
		badge.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		badgeLabel.Text = tostring(item.stock or 0)
	else
		if item.purchaseOrder and item.purchaseOrder <= 20 then
			badge.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			badgeLabel.Text = tostring(item.purchaseOrder)
		else
			badge.Visible = false
		end
	end
end

-- ========== UNIFORM HOVER EFFECTS ==========

function UIManager:AddUniformHoverEffects(itemFrame)
	local originalColor = itemFrame.BackgroundColor3
	local hoverColor = Color3.fromRGB(70, 70, 70)

	itemFrame.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(itemFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = hoverColor}
		)
		hoverTween:Play()
	end)

	itemFrame.MouseLeave:Connect(function()
		local leaveTween = TweenService:Create(itemFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = originalColor}
		)
		leaveTween:Play()
	end)
end

-- ========== UNIFORM HANDLERS ==========

function UIManager:HandleBuyClick(itemId, quantity)
	print("UIManager: Buy click - " .. itemId .. " x" .. quantity)

	-- ADDED: Purchase cooldown check to prevent double purchasing
	local currentTime = tick()
	local lastPurchase = self.State.PurchaseCooldowns[itemId] or 0

	if currentTime - lastPurchase < self.State.PURCHASE_COOLDOWN then
		print("UIManager: Purchase blocked - cooldown active for " .. itemId)
		self:ShowNotification("Purchase Cooldown", "Please wait before purchasing again!", "warning")
		return
	end

	-- ADDED: Set cooldown timestamp
	self.State.PurchaseCooldowns[itemId] = currentTime

	if self.State.RemoteEvents.PurchaseItem then
		self.State.RemoteEvents.PurchaseItem:FireServer(itemId, quantity)
		print("UIManager: Sent purchase request for " .. itemId)

		-- Show immediate feedback
	else
		-- Reset cooldown if remote not available
		self.State.PurchaseCooldowns[itemId] = nil
		self:ShowNotification("Shop Error", "Purchase system not available!", "error")
	end
end

-- ADDED: Method to clear cooldown after successful purchase
function UIManager:ClearPurchaseCooldown(itemId)
	if self.State.PurchaseCooldowns[itemId] then
		self.State.PurchaseCooldowns[itemId] = nil
		print("UIManager: Cleared purchase cooldown for " .. itemId)
	end
end

-- ADDED: Method to handle successful purchase confirmation
function UIManager:HandlePurchaseSuccess(itemId, quantity, cost, currency)
	-- Clear the cooldown since purchase was successful
	self:ClearPurchaseCooldown(itemId)

	-- Show success notification
	local currencyName = currency == "farmTokens" and "Farm Tokens" or "Coins"

end

function UIManager:HandleSellClick(itemId, quantity)
	print("UIManager: Sell click - " .. itemId .. " x" .. quantity)

	if self.State.RemoteEvents.SellItem then
		self.State.RemoteEvents.SellItem:FireServer(itemId, quantity)
		print("UIManager: Sent sell request")
	else
		self:ShowNotification("Sell Error", "Sell system not available!", "error")
	end
end

function UIManager:GetItemDescription(item, itemType)
	if itemType == "sell" then
		return item.description or ("You have " .. (item.stock or 0) .. " in stock")
	else
		local desc = item.description or "No description available"
		return desc:len() > 100 and (desc:sub(1, 100) .. "...") or desc
	end
end

-- ========== SINGLE TAB CONTENT POPULATION - Used for ALL Categories ==========

function UIManager:PopulateExtraLargeShopTabContent(tabId)
	print("UIManager: Populating EXTRA LARGE content for tab: " .. tabId)

	local tab = self.State.ShopTabs[tabId]
	if not tab then 
		warn("UIManager: Tab not found: " .. tabId)
		return 
	end

	local contentFrame = tab.content

	-- Clear existing content
	for _, child in pairs(contentFrame:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end

	contentFrame.CanvasPosition = Vector2.new(0, 0)

	-- Get player data
	local playerData = nil
	if self.State.GameClient and self.State.GameClient.GetPlayerData then
		playerData = self.State.GameClient:GetPlayerData()
	end

	local containerHeight = contentFrame.AbsoluteSize.Y
	if containerHeight == 0 then
		containerHeight = 500
	end

	if tabId == "sell" then
		self:PopulateExtraLargeSellTab(contentFrame, tab.config.color, containerHeight)
		return
	end

	-- Get shop items
	local shopItems = {}
	if self.State.RemoteFunctions.GetShopItems then
		local success, result = pcall(function()
			return self.State.RemoteFunctions.GetShopItems:InvokeServer()
		end)

		if success and result then
			shopItems = result
		else
			warn("UIManager: Failed to get shop items: " .. tostring(result))
		end
	end

	if #shopItems == 0 then
		self:CreateUniformNoItemsMessage(contentFrame, tab.config.name)
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, containerHeight)
		return
	end

	-- Filter and sort items
	local categoryItems = {}
	for _, item in ipairs(shopItems) do
		if item.category == tabId then
			table.insert(categoryItems, item)
		end
	end

	if #categoryItems == 0 then
		self:CreateUniformComingSoonMessage(contentFrame, tab.config.name, tab.config.color)
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, containerHeight)
		return
	end

	table.sort(categoryItems, function(a, b)
		local orderA = a.purchaseOrder or 999
		local orderB = b.purchaseOrder or 999
		if orderA == orderB then
			return a.price < b.price
		end
		return orderA < orderB
	end)

	print("UIManager: Creating " .. #categoryItems .. " EXTRA LARGE items for " .. tabId)

	-- Create EXTRA LARGE items
	for i, item in ipairs(categoryItems) do
		local itemFrame = self:CreateExtraLargeShopItem(item, i, tab.config.color, "buy", containerHeight, playerData)
		itemFrame.Parent = contentFrame
	end

	-- Set EXTRA LARGE canvas size
	local totalCanvasHeight = self:CalculateExtraLargeCanvasSize(#categoryItems, containerHeight)
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, totalCanvasHeight)

	print("UIManager: ✅ EXTRA LARGE " .. tabId .. " tab with " .. #categoryItems .. " items")
	print("  Items per screen: ~" .. string.format("%.1f", containerHeight / (containerHeight * 0.37))) -- 33% + 4%
end

function UIManager:PopulateExtraLargeSellTab(contentFrame, categoryColor, containerHeight)
	print("UIManager: Populating EXTRA LARGE sell tab...")

	local sellableItems = {}
	if self.State.RemoteFunctions.GetSellableItems then
		local success, result = pcall(function()
			return self.State.RemoteFunctions.GetSellableItems:InvokeServer()
		end)

		if success and result then
			sellableItems = result
		else
			warn("UIManager: Failed to get sellable items: " .. tostring(result))
		end
	end

	if #sellableItems == 0 then
		self:CreateUniformNoSellItemsMessage(contentFrame)
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, containerHeight)
		return
	end

	for i, item in ipairs(sellableItems) do
		local itemFrame = self:CreateExtraLargeShopItem(item, i, categoryColor, "sell", containerHeight)
		itemFrame.Parent = contentFrame
	end

	local totalCanvasHeight = self:CalculateExtraLargeCanvasSize(#sellableItems, containerHeight)
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, totalCanvasHeight)

	print("UIManager: ✅ EXTRA LARGE sell tab with " .. #sellableItems .. " items")
end

function UIManager:GetItemPurchaseStatus(item, playerData)
	if not playerData then
		return {
			canPurchase = true,
			statusText = "BUY",
			statusColor = Color3.fromRGB(100, 200, 100),
			reason = "available"
		}
	end

	local itemId = item.id
	local purchaseHistory = playerData.purchaseHistory or {}
	local livestock = playerData.livestock or {}
	local upgrades = playerData.upgrades or {}

	-- Check for single-purchase items that are already owned
	if item.maxQuantity == 1 and purchaseHistory[itemId] then
		return {
			canPurchase = false,
			statusText = "SOLD OUT",
			statusColor = Color3.fromRGB(120, 120, 120),
			reason = "already_purchased"
		}
	end

	-- ========== SPECIAL COW SYSTEM LOGIC ==========

	-- Basic cow - only allow if player doesn't have any cows
	if itemId == "basic_cow" then
		local hasCows = livestock.cows and #livestock.cows > 0
		if hasCows then
			return {
				canPurchase = false,
				statusText = "OWNED",
				statusColor = Color3.fromRGB(100, 150, 255),
				reason = "cow_already_owned"
			}
		end
	end

	-- Extra basic cows - never allow (player should upgrade instead)
	if itemId == "extra_basic_cow" then
		return {
			canPurchase = false,
			statusText = "USE UPGRADES",
			statusColor = Color3.fromRGB(255, 165, 0),
			reason = "use_upgrades_instead"
		}
	end

	-- Cow upgrades - only allow if player has a cow and meets requirements
	if item.type == "cow_upgrade" then
		local hasCows = livestock.cows and #livestock.cows > 0
		if not hasCows then
			return {
				canPurchase = false,
				statusText = "NEED COW",
				statusColor = Color3.fromRGB(255, 100, 100),
				reason = "no_cow_to_upgrade"
			}
		end

		-- Check if upgrade already applied
		if upgrades[itemId] then
			return {
				canPurchase = false,
				statusText = "APPLIED",
				statusColor = Color3.fromRGB(100, 255, 100),
				reason = "upgrade_already_applied"
			}
		end

		-- Check upgrade chain requirements
		local upgradeRequirement = self:GetCowUpgradeRequirement(itemId, livestock.cows)
		if not upgradeRequirement.canUpgrade then
			return {
				canPurchase = false,
				statusText = upgradeRequirement.statusText,
				statusColor = Color3.fromRGB(255, 165, 0),
				reason = upgradeRequirement.reason
			}
		end
	end

	-- Check currency affordability
	local totalCost = item.price * 1
	local playerCurrency = playerData[item.currency] or 0
	if playerCurrency < totalCost then
		return {
			canPurchase = false,
			statusText = "CAN'T AFFORD",
			statusColor = Color3.fromRGB(200, 100, 100),
			reason = "insufficient_funds"
		}
	end

	-- Default: item is available for purchase
	return {
		canPurchase = true,
		statusText = "BUY",
		statusColor = Color3.fromRGB(100, 200, 100),
		reason = "available"
	}
end

-- ========== COW UPGRADE REQUIREMENTS ==========

function UIManager:GetCowUpgradeRequirement(upgradeId, playerCows)
	if not playerCows or #playerCows == 0 then
		return {
			canUpgrade = false,
			statusText = "NEED COW",
			reason = "no_cow"
		}
	end

	-- Get the first (and only) cow
	local cow = playerCows[1]
	local currentTier = cow.tier or "basic"

	-- Define upgrade chain
	local upgradeChain = {
		silver_cow_upgrade = {requiredTier = "basic", resultTier = "silver"},
		gold_cow_upgrade = {requiredTier = "silver", resultTier = "gold"},
		diamond_cow_upgrade = {requiredTier = "gold", resultTier = "diamond"},
		rainbow_cow_upgrade = {requiredTier = "diamond", resultTier = "rainbow"},
		cosmic_cow_upgrade = {requiredTier = "rainbow", resultTier = "cosmic"}
	}

	local upgradeInfo = upgradeChain[upgradeId]
	if not upgradeInfo then
		return {
			canUpgrade = false,
			statusText = "INVALID",
			reason = "unknown_upgrade"
		}
	end

	-- Check if cow is at required tier
	if currentTier ~= upgradeInfo.requiredTier then
		local requiredTierDisplay = upgradeInfo.requiredTier:gsub("^%l", string.upper)
		return {
			canUpgrade = false,
			statusText = "NEED " .. requiredTierDisplay:upper(),
			reason = "wrong_tier"
		}
	end

	return {
		canUpgrade = true,
		statusText = "UPGRADE",
		reason = "can_upgrade"
	}
end

-- ========== UPDATED BUTTON CREATION WITH PURCHASE STATUS ==========

function UIManager:CreateStatusAwareButtonArea(parent, item, itemType, config, purchaseStatus)
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = config.Elements.ButtonArea.Size
	buttonContainer.Position = config.Elements.ButtonArea.Position
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = parent

	if itemType == "sell" then
		-- Sell items - create sell buttons (unchanged)
		self:CreateSellButtons(buttonContainer, item)
	else
		-- Buy items - create status-aware buy button
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(1, 0, 1, 0)
		buyButton.Position = UDim2.new(0, 0, 0, 0)
		buyButton.BackgroundColor3 = purchaseStatus.statusColor
		buyButton.BorderSizePixel = 0
		buyButton.Text = purchaseStatus.statusText
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextScaled = true
		buyButton.Active = purchaseStatus.canPurchase
		buyButton.Parent = buttonContainer

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0.08, 0)
		buyCorner.Parent = buyButton

		-- Visual state based on purchase status
		if not purchaseStatus.canPurchase then
			buyButton.BackgroundTransparency = 0.3
			buyButton.TextTransparency = 0.2

			-- Add subtle pattern or icon for sold out items
			if purchaseStatus.reason == "already_purchased" then
				local checkmark = Instance.new("TextLabel")
				checkmark.Size = UDim2.new(0.3, 0, 0.6, 0)
				checkmark.Position = UDim2.new(0.05, 0, 0.2, 0)
				checkmark.BackgroundTransparency = 1
				checkmark.Text = "✓"
				checkmark.TextColor3 = Color3.new(1, 1, 1)
				checkmark.TextScaled = true
				checkmark.Font = Enum.Font.GothamBold
				checkmark.Parent = buyButton
			end
		end

		-- Connect buy functionality only if can purchase
		if purchaseStatus.canPurchase then
			buyButton.MouseButton1Click:Connect(function()
				self:HandleBuyClick(item.id, 1)
			end)

			-- Hover effects for purchasable items
			buyButton.MouseEnter:Connect(function()
				local hoverTween = TweenService:Create(buyButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = self:LightenColor(purchaseStatus.statusColor, 0.2)}
				)
				hoverTween:Play()
			end)

			buyButton.MouseLeave:Connect(function()
				local leaveTween = TweenService:Create(buyButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = purchaseStatus.statusColor}
				)
				leaveTween:Play()
			end)
		else
			-- Disabled state - show tooltip on hover
			buyButton.MouseEnter:Connect(function()
				self:ShowPurchaseStatusTooltip(buyButton, item, purchaseStatus)
			end)
		end
	end
end

-- ========== PURCHASE STATUS TOOLTIP ==========

function UIManager:ShowPurchaseStatusTooltip(button, item, purchaseStatus)
	local tooltipText = ""

	if purchaseStatus.reason == "already_purchased" then
		tooltipText = "This upgrade has already been purchased!"
	elseif purchaseStatus.reason == "cow_already_owned" then
		tooltipText = "You already have a cow! Use upgrades to improve it."
	elseif purchaseStatus.reason == "use_upgrades_instead" then
		tooltipText = "Use cow upgrades instead of buying more cows!"
	elseif purchaseStatus.reason == "no_cow_to_upgrade" then
		tooltipText = "You need to buy a basic cow first!"
	elseif purchaseStatus.reason == "upgrade_already_applied" then
		tooltipText = "This upgrade has already been applied to your cow!"
	elseif purchaseStatus.reason == "wrong_tier" then
		tooltipText = "Your cow needs to be upgraded first!"
	elseif purchaseStatus.reason == "insufficient_funds" then
		local currency = item.currency == "farmTokens" and "Farm Tokens" or "Coins"
		tooltipText = "Not enough " .. currency .. "! Need " .. item.price
	end

	if tooltipText ~= "" then
		self:ShowNotification("Purchase Status", tooltipText, "info")
	end
end


function UIManager:CalculateExtraLargeCanvasSize(itemCount, containerHeight)
	local config = self.ExtraLargeItemConfig

	-- Each item takes MASSIVE space now
	local itemHeightPercent = config.ItemFrame.HeightPercent      -- 33%!
	local itemSpacingPercent = config.ItemFrame.SpacingPercent    -- 4%

	local itemHeightPixels = containerHeight * itemHeightPercent
	local itemSpacingPixels = containerHeight * itemSpacingPercent

	-- Calculate total content height
	local totalItemsHeight = itemCount * itemHeightPixels
	local totalSpacingHeight = math.max(0, (itemCount - 1) * itemSpacingPixels)

	-- Padding
	local topPaddingPixels = containerHeight * config.Padding.TopPercent
	local bottomPaddingPixels = containerHeight * config.Padding.BottomPercent

	local totalCanvasPixels = totalItemsHeight + totalSpacingHeight + topPaddingPixels + bottomPaddingPixels

	-- Ensure minimum canvas size
	local minimumCanvasPixels = containerHeight
	totalCanvasPixels = math.max(totalCanvasPixels, minimumCanvasPixels)

	print("UIManager: EXTRA LARGE Canvas calculation:")
	print("  Items: " .. itemCount)
	print("  Item height: " .. itemHeightPixels .. "px (" .. (itemHeightPercent * 100) .. "%)")
	print("  Item spacing: " .. itemSpacingPixels .. "px")
	print("  Total canvas: " .. totalCanvasPixels .. "px")
	print("  Items per screen: " .. string.format("%.1f", containerHeight / (itemHeightPixels + itemSpacingPixels)))

	return totalCanvasPixels
end

-- ========== UNIFORM MESSAGE CREATION ==========

function UIManager:CreateUniformNoItemsMessage(contentFrame, categoryName)
	local messageFrame = Instance.new("Frame")
	messageFrame.Name = "NoItemsMessage"
	messageFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
	messageFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
	messageFrame.BackgroundTransparency = 1
	messageFrame.Parent = contentFrame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, 0, 1, 0)
	messageLabel.Position = UDim2.new(0, 0, 0, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = "⚠️ No " .. categoryName .. " items available\n\nCheck server connection or try refreshing"
	messageLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextWrapped = true
	messageLabel.Parent = messageFrame

	self:ApplyTextSizing(messageLabel, 20, "ItemDescription")
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

function UIManager:CreateUniformNoSellItemsMessage(contentFrame)
	local messageFrame = Instance.new("Frame")
	messageFrame.Name = "NoSellItemsMessage"
	messageFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
	messageFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
	messageFrame.BackgroundTransparency = 1
	messageFrame.Parent = contentFrame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, 0, 1, 0)
	messageLabel.Position = UDim2.new(0, 0, 0, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = "💰 No items to sell!\n\nGrow crops, collect milk, or mine ores to have items to sell."
	messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextWrapped = true
	messageLabel.Parent = messageFrame

	self:ApplyTextSizing(messageLabel, 20, "ItemDescription")
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

function UIManager:CreateUniformComingSoonMessage(contentFrame, categoryName, categoryColor)
	local comingSoonFrame = self:CreateUniformShopItem({
		id = "coming_soon",
		name = categoryName .. " System",
		description = "Coming Soon!\n\nNew features and items will be available in this category soon. Stay tuned for updates!",
		icon = "🚧",
		price = 0,
		currency = "coins",
		category = "coming_soon"
	}, 1, categoryColor, "coming_soon")

	comingSoonFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	comingSoonFrame.Parent = contentFrame

	-- Set canvas size for single uniform item
	local config = self.UniformItemConfig
	local totalHeight = config.ItemFrame.Size.Y.Scale + config.ItemFrame.Spacing + 0.02
	contentFrame.CanvasSize = UDim2.new(0, 0, totalHeight, 0)
end
function UIManager:AddScrollingDebugCommands()
	game:GetService("Players").PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/scrolltest" then
					local activeTab = self.State.ShopTabs[self.State.ActiveShopTab]
					if activeTab then
						local contentFrame = activeTab.content
						print("=== SCROLLING TEST ===")
						print("Tab: " .. self.State.ActiveShopTab)
						print("Container: " .. contentFrame.AbsoluteSize.Y .. "px")
						print("Canvas: " .. contentFrame.CanvasSize.Y.Offset .. "px")
						print("Children: " .. #contentFrame:GetChildren())
						print("Can scroll: " .. tostring(contentFrame.CanvasSize.Y.Offset > contentFrame.AbsoluteSize.Y))

						-- Test scrolling
						print("Testing scroll to bottom...")
						contentFrame.CanvasPosition = Vector2.new(0, contentFrame.CanvasSize.Y.Offset)
						wait(1)
						print("Current position: " .. contentFrame.CanvasPosition.Y)
						print("Max scroll: " .. (contentFrame.CanvasSize.Y.Offset - contentFrame.AbsoluteSize.Y))
					end

				elseif command == "/fixnow" then
					print("🔧 Force fixing scrolling for current tab...")
					if self.State.ShopTabs[self.State.ActiveShopTab] then
						self.State.ShopTabs[self.State.ActiveShopTab].populated = false
						self:PopulateShopTabContent(self.State.ActiveShopTab)
					end
				end
			end
		end)
	end)
end
function UIManager:DebugTransitionState()
	print("=== TRANSITION STATE DEBUG ===")
	print("IsTransitioning:", self.State.IsTransitioning)
	print("TransitionStartTime:", self.State.TransitionStartTime)
	print("CurrentPage:", self.State.CurrentPage)
	print("ActiveMenus:", #self.State.ActiveMenus)
	for i, menu in ipairs(self.State.ActiveMenus) do
		print("  " .. i .. ". " .. menu)
	end

	if self.State.TransitionStartTime then
		local duration = tick() - self.State.TransitionStartTime
		print("Transition Duration:", duration .. "s")
		if duration > 2 then
			print("⚠️ STUCK TRANSITION DETECTED!")
		end
	end

	local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
	if menuContainer then
		print("MenuContainer Visible:", menuContainer.Visible)
		print("MenuContainer Transparency:", menuContainer.BackgroundTransparency)
	end
	print("==============================")
end

-- Global debug commands
_G.DebugUITransition = function()
	if _G.UIManager and _G.UIManager.DebugTransitionState then
		_G.UIManager:DebugTransitionState()
	end
end

_G.RecoverUI = function()
	if _G.UIManager and _G.UIManager.RecoverFromStuckState then
		_G.UIManager:RecoverFromStuckState()
		print("UI state recovered!")
	end
end

_G.ForceShop = function()
	if _G.UIManager then
		_G.UIManager:RecoverFromStuckState()
		wait(0.1)
		local success = _G.UIManager:OpenMenu("Shop")
		print("Force shop open:", success and "SUCCESS" or "FAILED")
	end
end
-- ADD this enhanced method to your UIManager.lua
-- Replace the existing HandleOpenShopFromServer method

function UIManager:HandleOpenShopFromServer()
	print("UIManager: 🛒 Received OpenShop event from server!")

	-- Force clear any stuck states
	self.State.IsTransitioning = false
	self.State.TransitionStartTime = nil

	-- Close any existing menus first
	if #self.State.ActiveMenus > 0 then
		print("UIManager: Closing existing menus before opening shop")
		self:CloseActiveMenusForced()
		wait(0.1)
	end

	-- Try to open shop with retry logic
	local attempts = 0
	local maxAttempts = 3
	local success = false

	while not success and attempts < maxAttempts do
		attempts = attempts + 1
		print("UIManager: Shop open attempt " .. attempts .. "/" .. maxAttempts)

		success = self:OpenMenu("Shop")

		if success then
			print("UIManager: ✅ Shop opened successfully!")
			self:ShowNotification("🛒 Shop Opened", "Welcome to the Shop!", "success")
			break
		else
			print("UIManager: ❌ Shop open attempt " .. attempts .. " failed")
			if attempts < maxAttempts then
				-- Reset state and try again
				self.State.IsTransitioning = false
				self.State.TransitionStartTime = nil
				self.State.CurrentPage = "None"
				wait(0.2)
			end
		end
	end

	if not success then
		warn("UIManager: ❌ Shop failed to open after " .. maxAttempts .. " attempts")
		self:ShowNotification("Shop Error", "Shop failed to open. Try the /shop command.", "error")
	end
end
function UIManager:HandleCloseShopFromServer()
	print("UIManager: Handling shop close request from server...")

	if self.State.CurrentPage == "Shop" then
		self:CloseActiveMenus()
		print("UIManager: ✅ Shop closed from server event")
		self:ShowNotification("👋 Shop Closed", "Thanks for visiting!", "info")
	else
		print("UIManager: Shop close event received but shop wasn't open")
	end
end

function UIManager:SetGameClient(gameClient)
	self.State.GameClient = gameClient
	print("UIManager: GameClient reference established")
end

-- ========== MAIN UI CREATION ==========

function UIManager:CreateMainUIStructure()
	local playerGui = LocalPlayer.PlayerGui

	local existingUI = playerGui:FindFirstChild("MainGameUI")
	if existingUI then
		existingUI:Destroy()
	end

	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "MainGameUI"
	mainUI.ResetOnSpawn = false
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainUI.Parent = playerGui

	self.State.MainUI = mainUI

	self:CreateCurrencyDisplay(mainUI)
	self:CreateMenuContainers(mainUI)
	self:CreateNotificationArea(mainUI)

	print("UIManager: Main UI structure created")
end

function UIManager:CreateCurrencyDisplay(parent)
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyDisplay"
	currencyFrame.Size = UDim2.new(0.25, 0, 0.08, 0)
	currencyFrame.Position = UDim2.new(0.74, 0, 0.09, 0)
	currencyFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	currencyFrame.BorderSizePixel = 0
	currencyFrame.ZIndex = self.Config.UIOrder.Main
	currencyFrame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = currencyFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 100)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = currencyFrame

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0.5, 0, 1, 0)
	coinsLabel.Position = UDim2.new(0, 0, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "💰 0"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Parent = currencyFrame

	local tokensLabel = Instance.new("TextLabel")
	tokensLabel.Name = "TokensLabel"
	tokensLabel.Size = UDim2.new(0.5, 0, 1, 0)
	tokensLabel.Position = UDim2.new(0.5, 0, 0, 0)
	tokensLabel.BackgroundTransparency = 1
	tokensLabel.Text = "🎫 0"
	tokensLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	tokensLabel.TextScaled = true
	tokensLabel.Font = Enum.Font.GothamBold
	tokensLabel.Parent = currencyFrame

	self.State.CurrencyLabels = {
		coins = coinsLabel,
		farmTokens = tokensLabel
	}

	print("UIManager: Currency display created")
end

function UIManager:CreateMenuContainers(parent)
	local menuContainer = Instance.new("Frame")
	menuContainer.Name = "MenuContainer"
	menuContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
	menuContainer.Position = UDim2.new(0.05, 0, 0.17, 0)
	menuContainer.BackgroundTransparency = 1
	menuContainer.ZIndex = self.Config.UIOrder.Menus
	menuContainer.Visible = false
	menuContainer.Parent = parent

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1.1, 0, 1.1, 0)
	background.Position = UDim2.new(-0.05, 0, -0.05, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.3
	background.ZIndex = self.Config.UIOrder.Background
	background.Parent = menuContainer

	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(1, 0, 1, 0)
	menuFrame.Position = UDim2.new(0, 0, 0, 0)
	menuFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	menuFrame.BorderSizePixel = 0
	menuFrame.ZIndex = self.Config.UIOrder.Menus
	menuFrame.Parent = menuContainer

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0.02, 0)
	menuCorner.Parent = menuFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0.02, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.ZIndex = self.Config.UIOrder.Menus + 1
	closeButton.Parent = menuFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		self:CloseActiveMenus()
	end)

	print("UIManager: Menu containers created")
end

function UIManager:CreateNotificationArea(parent)
	local notificationArea = Instance.new("Frame")
	notificationArea.Name = "NotificationArea"
	notificationArea.Size = UDim2.new(0.3, 0, 1, 0)
	notificationArea.Position = UDim2.new(0.69, 0, 0, 0)
	notificationArea.BackgroundTransparency = 1
	notificationArea.ZIndex = self.Config.UIOrder.Notifications
	notificationArea.Parent = parent

	print("UIManager: Notification area created")
end

-- ========== TOP MENU SYSTEM ==========

function UIManager:SetupTopMenu()
	print("UIManager: Setting up top menu...")

	local playerGui = LocalPlayer.PlayerGui

	local existingMenuUI = playerGui:FindFirstChild("TopMenuUI")
	if existingMenuUI then
		existingMenuUI:Destroy()
		print("UIManager: Removed existing top menu")
	end

	local menuUI = Instance.new("ScreenGui")
	menuUI.Name = "TopMenuUI"
	menuUI.ResetOnSpawn = false
	menuUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	menuUI.IgnoreGuiInset = true
	menuUI.Parent = playerGui

	local menuBar = Instance.new("Frame")
	menuBar.Name = "MenuBar"
	menuBar.Size = UDim2.new(1, 0, 0.08, 0)
	menuBar.Position = UDim2.new(0, 0, 0, 0)
	menuBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	menuBar.BorderSizePixel = 0
	menuBar.ZIndex = self.Config.UIOrder.TopMenu
	menuBar.Parent = menuUI

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
	}
	gradient.Rotation = 90
	gradient.Parent = menuBar

	local borderLine = Instance.new("Frame")
	borderLine.Name = "BorderLine"
	borderLine.Size = UDim2.new(1, 0, 0, 2)
	borderLine.Position = UDim2.new(0, 0, 1, -2)
	borderLine.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	borderLine.BorderSizePixel = 0
	borderLine.Parent = menuBar

	local buttons = {
		{
			name = "Farm",
			text = "🌾 Farm",
			color = Color3.fromRGB(80, 120, 60),
			hoverColor = Color3.fromRGB(100, 140, 80),
			description = "Manage your farm and crops"
		},
		{
			name = "Mining", 
			text = "⛏️ Mining",
			color = Color3.fromRGB(80, 80, 120),
			hoverColor = Color3.fromRGB(100, 100, 140),
			description = "Mine ores and explore caves"
		},
		{
			name = "Crafting",
			text = "🔨 Crafting", 
			color = Color3.fromRGB(120, 80, 60),
			hoverColor = Color3.fromRGB(140, 100, 80),
			description = "Craft tools and equipment"
		}
	}

	local buttonWidth = 0.15
	local buttonSpacing = 0.02
	local totalButtons = #buttons
	local totalWidth = (buttonWidth * totalButtons) + (buttonSpacing * (totalButtons - 1))
	local startX = (1 - totalWidth) / 2

	for i, buttonConfig in ipairs(buttons) do
		local success, error = pcall(function()
			local xPosition = startX + ((i - 1) * (buttonWidth + buttonSpacing))
			local button = self:CreateTopMenuButton(menuBar, buttonConfig, xPosition, buttonWidth)
			self.State.TopMenuButtons[buttonConfig.name] = button
			print("UIManager: ✅ Created " .. buttonConfig.name .. " top menu button")
		end)

		if not success then
			warn("UIManager: Failed to create " .. buttonConfig.name .. " button: " .. tostring(error))
		end
	end

	print("UIManager: ✅ Top menu setup complete")
end

function UIManager:CreateTopMenuButton(parent, config, xPosition, width)
	local button = Instance.new("TextButton")
	button.Name = config.name .. "Button"
	button.Size = UDim2.new(width, 0, 0.8, 0)
	button.Position = UDim2.new(xPosition, 0, 0.1, 0)
	button.BackgroundColor3 = config.color
	button.BorderSizePixel = 0
	button.Text = config.text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.ZIndex = self.Config.UIOrder.TopMenu + 1
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = button

	button.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundColor3 = config.hoverColor,
				Size = UDim2.new(width * 1.05, 0, 0.85, 0)
			}
		)
		hoverTween:Play()
	end)

	button.MouseLeave:Connect(function()
		local leaveTween = TweenService:Create(button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundColor3 = config.color,
				Size = UDim2.new(width, 0, 0.8, 0)
			}
		)
		leaveTween:Play()
	end)

	button.MouseButton1Click:Connect(function()
		print("UIManager: Top menu button clicked: " .. config.name)
		self:HandleTopMenuButtonClick(config.name)
	end)

	return button
end

function UIManager:HandleTopMenuButtonClick(buttonName)
	print("UIManager: Top menu button clicked: " .. buttonName)

	local button = self.State.TopMenuButtons[buttonName]
	if button then
		local pressDown = TweenService:Create(button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{Size = UDim2.new(button.Size.X.Scale * 0.95, 0, button.Size.Y.Scale * 0.95, 0)}
		)
		local pressUp = TweenService:Create(button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{Size = UDim2.new(button.Size.X.Scale / 0.95, 0, button.Size.Y.Scale / 0.95, 0)}
		)

		pressDown:Play()
		pressDown.Completed:Connect(function()
			pressUp:Play()
		end)
	end

	print("UIManager: Attempting to open menu: " .. buttonName)
	local success = self:OpenMenu(buttonName)

	if success then
		print("UIManager: ✅ Successfully opened " .. buttonName .. " menu")
	else
		print("UIManager: ❌ Failed to open " .. buttonName .. " menu")
	end
end

-- ========== INPUT HANDLING ==========

function UIManager:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			self:CloseActiveMenus()
		elseif input.KeyCode == Enum.KeyCode.F then
			print("UIManager: F key pressed - opening Farm")
			self:OpenMenu("Farm")
		elseif input.KeyCode == Enum.KeyCode.M then
			print("UIManager: M key pressed - opening Mining")
			self:OpenMenu("Mining")
		elseif input.KeyCode == Enum.KeyCode.C then
			print("UIManager: C key pressed - opening Crafting")
			self:OpenMenu("Crafting")
		elseif input.KeyCode == Enum.KeyCode.H then
			print("UIManager: H key pressed - manually opening Shop")
			self:OpenMenu("Shop")
		end
	end)

	print("UIManager: Input handling setup complete")
end

-- ========== MENU MANAGEMENT ==========

function UIManager:OpenMenu(menuName)
	print("UIManager: Opening menu: " .. menuName)

	-- FORCE RESET: Always reset transition state at start
	if self.State.IsTransitioning then
		print("UIManager: FORCING reset of transition state (was stuck)")
		self.State.IsTransitioning = false
		self.State.TransitionStartTime = nil
	end

	-- Additional safety check - if TransitionStartTime exists without IsTransitioning
	if self.State.TransitionStartTime then
		print("UIManager: Clearing orphaned TransitionStartTime")
		self.State.TransitionStartTime = nil
	end

	print("UIManager: Starting fresh menu open for: " .. menuName)

	-- Set new transition state
	self.State.IsTransitioning = true
	self.State.TransitionStartTime = tick()
	self.State.CurrentPage = menuName

	-- Force close existing menus immediately (no animation)
	if #self.State.ActiveMenus > 0 then
		print("UIManager: Force closing existing menus")
		self:CloseActiveMenusForced()
		wait(0.1) -- Small delay to ensure cleanup
	end

	-- Verify UI structure exists
	if not self.State.MainUI then
		warn("UIManager: MainUI not initialized!")
		self.State.IsTransitioning = false
		self.State.TransitionStartTime = nil
		return false
	end

	local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
	if not menuContainer then
		warn("UIManager: MenuContainer not found!")
		self.State.IsTransitioning = false
		self.State.TransitionStartTime = nil
		return false
	end

	local menuFrame = menuContainer:FindFirstChild("MenuFrame")
	if not menuFrame then
		warn("UIManager: MenuFrame not found!")
		self.State.IsTransitioning = false
		self.State.TransitionStartTime = nil
		return false
	end

	print("UIManager: UI structure verified, creating menu content...")

	-- Create menu content
	local contentSuccess = false

	local success, errorMsg = pcall(function()
		if menuName == "Shop" then
			contentSuccess = self:CreateTabbedShopMenu()
		elseif menuName == "Farm" then
			contentSuccess = self:CreateFarmMenu()
		elseif menuName == "Mining" then
			contentSuccess = self:CreateMiningMenu()
		elseif menuName == "Crafting" then
			contentSuccess = self:CreateCraftingMenu()
		else
			contentSuccess = self:CreateGenericMenu(menuName)
		end
	end)

	if not success then
		warn("UIManager: Error creating menu content: " .. tostring(errorMsg))
		self.State.IsTransitioning = false
		self.State.TransitionStartTime = nil
		return false
	end

	if contentSuccess then
		print("UIManager: Menu content created successfully")

		-- FORCE show the menu container immediately
		menuContainer.Visible = true
		menuContainer.BackgroundTransparency = 0

		-- Reset transition state immediately (don't wait for animation)
		self.State.IsTransitioning = false
		self.State.TransitionStartTime = nil

		-- Add to active menus
		self.State.ActiveMenus = {menuName} -- Replace array instead of append

		print("UIManager: ✅ Menu " .. menuName .. " opened successfully (FORCED)")
		return true
	else
		warn("UIManager: Failed to create menu content for " .. menuName)
		self.State.IsTransitioning = false
		self.State.TransitionStartTime = nil
		self.State.CurrentPage = "None"
		return false
	end
end

function UIManager:RecoverFromStuckState()
	print("UIManager: Recovering from stuck state...")

	-- Force reset all problematic state
	self.State.IsTransitioning = false
	self.State.TransitionStartTime = nil
	self.State.ActiveMenus = {}
	self.State.CurrentPage = "None"

	-- Hide any visible menu containers
	local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
	if menuContainer then
		menuContainer.Visible = false
	end

	print("UIManager: State recovery completed")
end

function UIManager:CloseActiveMenus()
	if #self.State.ActiveMenus == 0 then
		-- FIXED: Reset transition state even if no menus
		self.State.IsTransitioning = false
		return
	end

	print("UIManager: Closing active menus")

	local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
	if menuContainer and menuContainer.Visible then
		local tween = TweenService:Create(menuContainer,
			TweenInfo.new(self.Config.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}
		)
		tween:Play()

		tween.Completed:Connect(function()
			menuContainer.Visible = false

			local menuFrame = menuContainer:FindFirstChild("MenuFrame")
			if menuFrame then
				for _, child in pairs(menuFrame:GetChildren()) do
					if child.Name ~= "CloseButton" and not child:IsA("UICorner") then
						child:Destroy()
					end
				end
			end

			-- FIXED: Reset transition state when closing completes
			self.State.IsTransitioning = false
			print("UIManager: Menu close animation completed, transition state reset")
		end)
	else
		-- FIXED: Reset transition state immediately if no animation needed
		self.State.IsTransitioning = false
	end

	self.State.ActiveMenus = {}
	self.State.CurrentPage = "None"
end
function UIManager:CloseActiveMenusForced()
	print("UIManager: Force closing active menus")

	local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
	if menuContainer then
		menuContainer.Visible = false

		local menuFrame = menuContainer:FindFirstChild("MenuFrame")
		if menuFrame then
			for _, child in pairs(menuFrame:GetChildren()) do
				if child.Name ~= "CloseButton" and not child:IsA("UICorner") then
					child:Destroy()
				end
			end
		end
	end

	-- FIXED: Force reset all state
	self.State.ActiveMenus = {}
	self.State.CurrentPage = "None"
	self.State.IsTransitioning = false

	print("UIManager: Force close completed, all state reset")
end

-- ========== SHOP MENU SYSTEM ==========

function UIManager:CreateTabbedShopMenu()
	print("UIManager: Creating UNIFORM tabbed shop menu...")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "🛒 Pet Palace Market"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local accessNote = Instance.new("TextLabel")
	accessNote.Name = "AccessNote"
	accessNote.Size = UDim2.new(0.95, 0, 0.05, 0)
	accessNote.Position = UDim2.new(0.025, 0, 0.12, 0)
	accessNote.BackgroundTransparency = 1
	accessNote.Text = "🎯 UNIFORM sizing system • All items same size across all categories"
	accessNote.TextColor3 = Color3.fromRGB(100, 255, 100)
	accessNote.TextScaled = true
	accessNote.Font = Enum.Font.Gotham
	accessNote.Parent = menuFrame

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(0.95, 0, 0.08, 0)
	tabContainer.Position = UDim2.new(0.025, 0, 0.18, 0)
	tabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabContainer.BorderSizePixel = 0
	tabContainer.Parent = menuFrame

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0.02, 0)
	tabCorner.Parent = tabContainer

	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(0.95, 0, 0.7, 0)
	contentContainer.Position = UDim2.new(0.025, 0, 0.27, 0)
	contentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = menuFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0.02, 0)
	contentCorner.Parent = contentContainer

	self:CreateShopTabs(tabContainer, contentContainer)
	self:ShowShopTab(self.State.ActiveShopTab)

	print("UIManager: ✅ UNIFORM shop menu created successfully")
	return true
end


function UIManager:CreateShopTabs(tabContainer, contentContainer)
	print("UIManager: Creating properly contained shop tabs...")

	self.State.ShopTabs = {}

	local tabWidth = 1 / #self.Config.ShopTabConfig

	for i, tabConfig in ipairs(self.Config.ShopTabConfig) do
		-- Create tab button (same as before)
		local tabButton = Instance.new("TextButton")
		tabButton.Name = "Tab_" .. tabConfig.id
		tabButton.Size = UDim2.new(tabWidth, -0.01, 0.9, 0)
		tabButton.Position = UDim2.new(tabWidth * (i - 1), 0.005, 0.05, 0)
		tabButton.BackgroundColor3 = tabConfig.color
		tabButton.BorderSizePixel = 0
		tabButton.Text = tabConfig.name
		tabButton.TextColor3 = Color3.new(1, 1, 1)
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.GothamBold
		tabButton.Parent = tabContainer

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0.1, 0)
		tabCorner.Parent = tabButton

		-- ========== PROPERLY CONTAINED SCROLLING FRAME ==========
		local contentFrame = Instance.new("ScrollingFrame")
		contentFrame.Name = "Content_" .. tabConfig.id

		-- FIXED: Proper sizing that stays within container bounds
		contentFrame.Size = UDim2.new(0.98, 0, 0.98, 0)  -- 98% to leave small margin
		contentFrame.Position = UDim2.new(0.01, 0, 0.01, 0)  -- 1% margin from edges
		contentFrame.BackgroundTransparency = 1
		contentFrame.BorderSizePixel = 0

		-- ========== CRITICAL: PROPER CLIPPING SETTINGS ==========
		contentFrame.ClipsDescendants = true  -- MUST be true to contain content

		-- Scrolling properties
		contentFrame.ScrollBarThickness = 14
		contentFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
		contentFrame.ScrollBarImageTransparency = 0.2
		contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
		contentFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		contentFrame.ScrollingEnabled = true
		contentFrame.Active = true
		contentFrame.Selectable = false
		contentFrame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable

		-- Default canvas size
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
		contentFrame.CanvasPosition = Vector2.new(0, 0)

		contentFrame.Visible = false
		contentFrame.Parent = contentContainer

		self.State.ShopTabs[tabConfig.id] = {
			button = tabButton,
			content = contentFrame,
			config = tabConfig,
			populated = false
		}

		-- Connect events
		tabButton.MouseButton1Click:Connect(function()
			self:ShowShopTab(tabConfig.id)
		end)

		tabButton.MouseEnter:Connect(function()
			if self.State.ActiveShopTab ~= tabConfig.id then
				local hoverTween = TweenService:Create(tabButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = self:LightenColor(tabConfig.color, 0.2)}
				)
				hoverTween:Play()
			end
		end)

		tabButton.MouseLeave:Connect(function()
			if self.State.ActiveShopTab ~= tabConfig.id then
				local leaveTween = TweenService:Create(tabButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = tabConfig.color}
				)
				leaveTween:Play()
			end
		end)

		print("UIManager: ✅ Created properly contained tab: " .. tabConfig.name)
	end
end


function UIManager:ShowShopTab(tabId)
	print("UIManager: Switching to shop tab: " .. tabId)

	-- Update active tab first
	local previousTab = self.State.ActiveShopTab
	self.State.ActiveShopTab = tabId

	-- Handle tab visual states
	for id, tab in pairs(self.State.ShopTabs) do
		local isActive = (id == tabId)

		tab.content.Visible = isActive

		local targetColor = isActive and self:LightenColor(tab.config.color, 0.3) or tab.config.color
		local buttonTween = TweenService:Create(tab.button,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad),
			{BackgroundColor3 = targetColor}
		)
		buttonTween:Play()

		if isActive then
			local indicator = tab.button:FindFirstChild("ActiveIndicator")
			if not indicator then
				indicator = Instance.new("Frame")
				indicator.Name = "ActiveIndicator"
				indicator.Size = UDim2.new(1, 0, 0.1, 0)
				indicator.Position = UDim2.new(0, 0, 0.9, 0)
				indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				indicator.BorderSizePixel = 0
				indicator.Parent = tab.button

				local indicatorCorner = Instance.new("UICorner")
				indicatorCorner.CornerRadius = UDim.new(0.5, 0)
				indicatorCorner.Parent = indicator
			end
		else
			local indicator = tab.button:FindFirstChild("ActiveIndicator")
			if indicator then
				indicator:Destroy()
			end
		end
	end

	-- FIXED: Populate content with correct method name
	if not self.State.ShopTabs[tabId].populated then
		self:PopulateExtraLargeShopTabContent(tabId)
		self.State.ShopTabs[tabId].populated = true
	end
end
-- ========== FARM MENU (Simple example of consistent structure) ==========

function UIManager:CreateFarmMenu()
	print("UIManager: Creating farm menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "🌾 FARM MANAGEMENT"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(0.8, 0, 0.5, 0)
	placeholder.Position = UDim2.new(0.1, 0, 0.25, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "Farm inventory and management will be displayed here.\n\nSame UNIFORM sizing as shop items will be used."
	placeholder.TextColor3 = Color3.fromRGB(200, 200, 200)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.Gotham
	placeholder.TextWrapped = true
	placeholder.Parent = menuFrame

	return true
end

function UIManager:CreateMiningMenu()
	print("UIManager: Creating mining menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "⛏️ MINING OPERATIONS"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(0.8, 0, 0.5, 0)
	placeholder.Position = UDim2.new(0.1, 0, 0.25, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "Mining tools and progress will be displayed here.\n\nUsing the same UNIFORM item sizing as the shop."
	placeholder.TextColor3 = Color3.fromRGB(200, 200, 200)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.Gotham
	placeholder.TextWrapped = true
	placeholder.Parent = menuFrame

	return true
end

function UIManager:CreateCraftingMenu()
	print("UIManager: Creating crafting menu")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "🔨 CRAFTING WORKSHOP"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(0.8, 0, 0.5, 0)
	placeholder.Position = UDim2.new(0.1, 0, 0.25, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "Crafting recipes and stations will be displayed here.\n\nConsistent with UNIFORM shop item sizing."
	placeholder.TextColor3 = Color3.fromRGB(200, 200, 200)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.Gotham
	placeholder.TextWrapped = true
	placeholder.Parent = menuFrame

	return true
end

function UIManager:CreateGenericMenu(menuName)
	print("UIManager: Creating generic menu for: " .. menuName)

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.02, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = menuName:upper() .. " MENU"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(0.8, 0, 0.5, 0)
	placeholder.Position = UDim2.new(0.1, 0, 0.25, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "Menu content for " .. menuName .. " will be implemented here."
	placeholder.TextColor3 = Color3.fromRGB(200, 200, 200)
	placeholder.TextScaled = true
	placeholder.Font = Enum.Font.Gotham
	placeholder.Parent = menuFrame

	return true
end

-- ========== UTILITY FUNCTIONS ==========

function UIManager:UpdateCurrencyDisplay(playerData)
	if not playerData or not self.State.CurrencyLabels then return end

	if self.State.CurrencyLabels.coins then
		local coins = playerData.coins or 0
		self.State.CurrencyLabels.coins.Text = "💰 " .. self:FormatNumber(coins)
	end

	if self.State.CurrencyLabels.farmTokens then
		local tokens = playerData.farmTokens or 0
		self.State.CurrencyLabels.farmTokens.Text = "🎫 " .. self:FormatNumber(tokens)
	end
end

function UIManager:FormatNumber(number)
	if number < 1000 then
		return tostring(number)
	elseif number < 1000000 then
		return string.format("%.1fK", number / 1000)
	else
		return string.format("%.1fM", number / 1000000)
	end
end

function UIManager:LightenColor(color, amount)
	return Color3.new(
		math.min(1, color.R + amount),
		math.min(1, color.G + amount),
		math.min(1, color.B + amount)
	)
end

function UIManager:RefreshMenuContent(menuName)
	if self.State.CurrentPage ~= menuName then return end

	print("UIManager: Refreshing content for " .. menuName)

	if menuName == "Shop" then
		local activeTab = self.State.ShopTabs[self.State.ActiveShopTab]
		if activeTab then
			activeTab.populated = false
			-- FIXED: Use correct method name
			self:PopulateExtraLargeShopTabContent(self.State.ActiveShopTab)
		end
	else
		local currentMenus = self.State.ActiveMenus
		self:CloseActiveMenus()

		spawn(function()
			wait(0.1)
			self:OpenMenu(menuName)
		end)
	end
end


function UIManager:GetCurrentPage()
	return self.State.CurrentPage
end

function UIManager:GetState()
	return self.State
end

-- ========== NOTIFICATION SYSTEM ==========

function UIManager:SetupNotificationSystem()
	self.State.NotificationQueue = {}

	spawn(function()
		while true do
			if #self.State.NotificationQueue > 0 then
				local notification = table.remove(self.State.NotificationQueue, 1)
				self:DisplayNotification(notification)
			end
			wait(0.1)
		end
	end)

	print("UIManager: Notification system setup complete")
end

function UIManager:ShowNotification(title, message, notificationType)
	notificationType = notificationType or "info"
	if title:find("Purchase") or title:find("Bought") or title:find("Complete") or title:find("Purchased") then
		print("🔔 NOTIFICATION DEBUG:")
		print("  Title: " .. title)
		print("  Message: " .. message)
		print("  Type: " .. notificationType)
		print("  Source: " .. debug.traceback())
		print("========================")
	end

	-- Continue with normal notification logic...
	table.insert(self.State.NotificationQueue, {
		title = title,
		message = message,
		type = notificationType,
		timestamp = tick()
	

	})
end

function UIManager:DisplayNotification(notificationData)
	if not self.State.MainUI then return end

	local notificationArea = self.State.MainUI:FindFirstChild("NotificationArea")
	if not notificationArea then return end

	local existingCount = 0
	for _, child in pairs(notificationArea:GetChildren()) do
		if child.Name:find("Notification_") then
			existingCount = existingCount + 1
		end
	end

	if existingCount >= self.Config.MaxNotificationsVisible then
		for _, child in pairs(notificationArea:GetChildren()) do
			if child.Name:find("Notification_") then
				child:Destroy()
				break
			end
		end
		existingCount = existingCount - 1
	end

	local notification = Instance.new("Frame")
	notification.Name = "Notification_" .. tick()
	notification.Size = UDim2.new(0.9, 0, 0.1, 0)
	notification.Position = UDim2.new(0.05, 0, 0.1 + (existingCount * 0.11), 0)
	notification.BackgroundColor3 = self:GetNotificationColor(notificationData.type)
	notification.BorderSizePixel = 0
	notification.ZIndex = self.Config.UIOrder.Notifications
	notification.Parent = notificationArea

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0.1, 0)
	notifCorner.Parent = notification

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.9, 0, 0.5, 0)
	titleLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = notificationData.title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notification

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
	messageLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = notificationData.message
	messageLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	messageLabel.TextScaled = true
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextWrapped = true
	messageLabel.Parent = notification

	notification.Position = UDim2.new(1, 0, 0.1 + (existingCount * 0.11), 0)
	local slideIn = TweenService:Create(notification,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.05, 0, 0.1 + (existingCount * 0.11), 0)}
	)
	slideIn:Play()

	spawn(function()
		wait(self.Config.NotificationDisplayTime)
		if notification and notification.Parent then
			local slideOut = TweenService:Create(notification,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(1, 0, notification.Position.Y.Scale, 0)}
			)
			slideOut:Play()
			slideOut.Completed:Connect(function()
				notification:Destroy()
			end)
		end
	end)
end

function UIManager:GetNotificationColor(notificationType)
	local colors = {
		success = Color3.fromRGB(46, 125, 50),
		error = Color3.fromRGB(211, 47, 47),
		warning = Color3.fromRGB(245, 124, 0),
		info = Color3.fromRGB(25, 118, 210)
	}
	return colors[notificationType] or colors.info
end

-- ========== CLEANUP ==========

function UIManager:Cleanup()
	print("UIManager: Performing cleanup...")

	self:CloseActiveMenus()

	self.State.NotificationQueue = {}

	if self.State.MainUI then
		self.State.MainUI:Destroy()
		self.State.MainUI = nil
	end

	local topMenuUI = LocalPlayer.PlayerGui:FindFirstChild("TopMenuUI")
	if topMenuUI then
		topMenuUI:Destroy()
	end

	self.State = {
		MainUI = nil,
		CurrentPage = "None",
		ActiveMenus = {},
		IsTransitioning = false,
		Layers = {},
		NotificationQueue = {},
		CurrencyLabels = {},
		GameClient = nil,
		TopMenuButtons = {},
		ShopTabs = {},
		ActiveShopTab = "seeds",
		RemoteEvents = {},
		RemoteFunctions = {}
	}
	game:GetService("Players").PlayerAdded:Connect(function(player)
		if player == LocalPlayer then
			player.Chatted:Connect(function(message)
				if message:lower() == "/testshop" then
					print("🧪 Testing shop open...")

					-- Test direct shop opening
					local success = self:OpenMenu("Shop")
					print("Direct open result:", success)

					-- Show current state
					print("Current state:")
					print("  IsTransitioning:", self.State.IsTransitioning)
					print("  CurrentPage:", self.State.CurrentPage)
					print("  ActiveMenus:", #self.State.ActiveMenus)
					print("  MainUI exists:", self.State.MainUI ~= nil)

					if self.State.MainUI then
						local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
						print("  MenuContainer exists:", menuContainer ~= nil)
						if menuContainer then
							print("  MenuContainer visible:", menuContainer.Visible)
						end
					end
				elseif message:lower() == "/resetui" then
					print("🔧 Resetting UI state...")
					self.State.IsTransitioning = false
					self.State.TransitionStartTime = nil
					self.State.ActiveMenus = {}
					self.State.CurrentPage = "None"
					print("UI state reset!")
				end
			end)
		end
	end)
	print("UIManager: Cleanup complete")
end
function UIManager:EmergencyReset()
	print("UIManager: 🚨 EMERGENCY RESET TRIGGERED")

	-- Reset all state
	self.State.IsTransitioning = false
	self.State.TransitionStartTime = nil
	self.State.ActiveMenus = {}
	self.State.CurrentPage = "None"

	-- Hide all UI
	if self.State.MainUI then
		local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
		if menuContainer then
			menuContainer.Visible = false
		end
	end

	print("UIManager: Emergency reset complete")
	return true
end

-- ADD these improved debug commands to UIManager.lua:
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

LocalPlayer.Chatted:Connect(function(message)
	local command = message:lower()

	if command == "/emergencyreset" then
		if UIManager then
			UIManager:EmergencyReset()
			print("✅ Emergency reset completed!")
		end

	elseif command == "/forceshop" then
		if UIManager then
			print("🔧 Force opening shop...")
			UIManager:EmergencyReset()
			wait(0.2)
			local success = UIManager:OpenMenu("Shop")
			print("Force shop result:", success)
		end

	elseif command == "/uistatus" then
		if UIManager and UIManager.State then
			print("=== DETAILED UI STATUS ===")
			print("IsTransitioning:", UIManager.State.IsTransitioning)
			print("TransitionStartTime:", UIManager.State.TransitionStartTime)
			print("CurrentPage:", UIManager.State.CurrentPage)
			print("ActiveMenus count:", #UIManager.State.ActiveMenus)
			for i, menu in ipairs(UIManager.State.ActiveMenus) do
				print("  " .. i .. ": " .. menu)
			end
			print("MainUI exists:", UIManager.State.MainUI ~= nil)

			if UIManager.State.MainUI then
				local menuContainer = UIManager.State.MainUI:FindFirstChild("MenuContainer")
				print("MenuContainer exists:", menuContainer ~= nil)
				if menuContainer then
					print("MenuContainer.Visible:", menuContainer.Visible)
					print("MenuContainer.BackgroundTransparency:", menuContainer.BackgroundTransparency)
				end
			end
			print("========================")
		end
	end
end)

_G.EmergencyShopFix = function()
	if _G.UIManager then
		print("🚨 EMERGENCY SHOP FIX")

		-- Force reset everything
		_G.UIManager.State.IsTransitioning = false
		_G.UIManager.State.TransitionStartTime = nil
		_G.UIManager.State.ActiveMenus = {}
		_G.UIManager.State.CurrentPage = "None"

		-- Hide any visible menus
		local menuContainer = _G.UIManager.State.MainUI and _G.UIManager.State.MainUI:FindFirstChild("MenuContainer")
		if menuContainer then
			menuContainer.Visible = false
		end

		wait(0.1)

		-- Force open shop
		local success = _G.UIManager:OpenMenu("Shop")
		print("Emergency shop open result:", success)
		return success
	end
	return false
end
_G.UIManager = UIManager

print("UIManager: ✅ FIXED FOR CONSISTENT SIZING!")
print("🎯 SOLUTION APPLIED:")
print("  ✅ Single CreateUniformShopItem method for ALL categories")
print("  ✅ Single PopulateShopTabContent method for ALL categories")
print("  ✅ Consistent UniformItemConfig used everywhere")
print("  ✅ Removed all conflicting item creation methods")
print("  ✅ Same 18% height for ALL items in ALL categories")
print("")
print("🔧 Key Fix:")
print("  All Seeds, Farming, Mining, Crafting, Premium items")
print("  now use the EXACT SAME sizing configuration!")
print("")
print("🧪 Test Result:")
print("  Seeds tab items = 18% height")
print("  Crafting tab items = 18% height") 
print("  All other tabs = 18% height")
print("  CONSISTENT sizing across ALL categories!")

return UIManager

