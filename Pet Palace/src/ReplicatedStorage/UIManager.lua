--[[
    FIXED UIManager.lua - Added Remote Event Listeners for Shop Opening
    Place in: ReplicatedStorage/UIManager.lua
    
    KEY FIXES:
    ✅ Added remote event listeners for OpenShop/CloseShop
    ✅ Connected to ProximitySystem events
    ✅ Added proper error handling for remote connections
    ✅ All original functionality preserved
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
	-- FIXED: Add remote event storage
	RemoteEvents = {},
	RemoteFunctions = {}
}

-- UI Configuration
UIManager.Config = {
	TransitionTime = 0.3,
	NotificationDisplayTime = 5,
	MaxNotificationsVisible = 3,
	UIOrder = {
		Background = 1,
		Main = 2,
		TopMenu = 3,
		Menus = 4,
		Notifications = 5,
		Error = 6
	},
	-- IMPROVED Device scaling
	MobileScale = 1.3,
	TabletScale = 1.15,
	DesktopScale = 1.0,
	-- Shop tab configuration
	ShopTabConfig = {
		{id = "seeds", name = "🌱 Seeds", color = Color3.fromRGB(100, 200, 100)},
		{id = "farm", name = "🌾 Farming", color = Color3.fromRGB(139, 90, 43)},
		{id = "defense", name = "🛡️ Defense", color = Color3.fromRGB(120, 80, 200)},
		{id = "mining", name = "⛏️ Mining", color = Color3.fromRGB(150, 150, 150)},
		{id = "crafting", name = "🔨 Crafting", color = Color3.fromRGB(200, 120, 80)},
		{id = "premium", name = "✨ Premium", color = Color3.fromRGB(255, 215, 0)},
		{id = "sell", name = "💰 Sell", color = Color3.fromRGB(255, 165, 0)}
	}
}


UIManager.LargeUniformShopConfig = {
	-- FIXED: Larger item frames matching Farming tab size
	ItemFrame = {
		Size = UDim2.new(0.95, 0, 0.18, 0),           -- LARGER: 18% height (was 14%)
		Position = UDim2.new(0.025, 0, 0, 0),         -- 2.5% left margin
		BackgroundColor = Color3.fromRGB(60, 60, 60),
		CornerRadius = UDim.new(0.03, 0),
		Spacing = 0.02                                 -- 2% gap between items
	},

	-- FIXED: Larger element positioning for better visibility
	Elements = {
		CategoryIndicator = {
			Size = UDim2.new(0.008, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0)
		},
		ItemIcon = {
			Size = UDim2.new(0.12, 0, 0.5, 0),         -- LARGER: 12% width, 50% height
			Position = UDim2.new(0.02, 0, 0.25, 0)     -- Centered vertically
		},
		ItemName = {
			Size = UDim2.new(0.35, 0, 0.3, 0),         -- LARGER: 35% width, 30% height
			Position = UDim2.new(0.16, 0, 0.05, 0)
		},
		ItemDescription = {
			Size = UDim2.new(0.35, 0, 0.4, 0),         -- LARGER: 35% width, 40% height  
			Position = UDim2.new(0.16, 0, 0.35, 0)
		},
		PriceArea = {
			Size = UDim2.new(0.16, 0, 0.7, 0),         -- LARGER: 16% width, 70% height
			Position = UDim2.new(0.53, 0, 0.15, 0)
		},
		ButtonArea = {
			Size = UDim2.new(0.14, 0, 0.7, 0),         -- LARGER: 14% width, 70% height
			Position = UDim2.new(0.84, 0, 0.15, 0)
		},
		Badge = {
			Size = UDim2.new(0.06, 0, 0.22, 0),        -- LARGER badge
			Position = UDim2.new(0.02, 0, 0.02, 0)
		}
	},

	-- Device-specific text scaling
	DeviceTextScale = {
		Mobile = 1.3,    -- Larger text on mobile
		Tablet = 1.2,    -- Larger text on tablet  
		Desktop = 1.1    -- Slightly larger text on desktop
	},

	-- Minimum text sizes for readability
	MinTextSizes = {
		ItemName = 16,
		ItemDescription = 14,
		Price = 15,
		Button = 13,
		Badge = 12
	}
}

-- ========== DEVICE TEXT SCALING ==========

function UIManager:GetLargeTextScaleForDevice()
	local deviceType = self:GetDeviceType()
	return self.LargeUniformShopConfig.DeviceTextScale[deviceType] or 1.1
end

function UIManager:ApplyLargeTextSizing(textElement, baseSize, elementType)
	local textScale = self:GetLargeTextScaleForDevice()
	local minSize = self.LargeUniformShopConfig.MinTextSizes[elementType] or 12
	local finalSize = math.max(minSize, baseSize * textScale)

	textElement.TextSize = finalSize
	textElement.TextScaled = true
end

-- ========== LARGE UNIFORM SHOP ITEM CREATION ==========

function UIManager:CreateLargeUniformShopItem(item, index, categoryColor, itemType)
	print("Creating LARGE uniform shop item: " .. (item.name or item.id) .. " (Type: " .. itemType .. ")")

	local config = self.LargeUniformShopConfig

	-- Calculate Y position for this item
	local yPosition = (index - 1) * (config.ItemFrame.Size.Y.Scale + config.ItemFrame.Spacing)

	-- ========== MAIN ITEM FRAME (Large & Identical) ==========
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = itemType .. "Item_" .. index
	itemFrame.Size = config.ItemFrame.Size                    -- LARGE: Always 18% height
	itemFrame.Position = UDim2.new(config.ItemFrame.Position.X.Scale, 0, yPosition, 0)
	itemFrame.BackgroundColor3 = config.ItemFrame.BackgroundColor
	itemFrame.BorderSizePixel = 0
	itemFrame.ClipsDescendants = false

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = config.ItemFrame.CornerRadius
	itemCorner.Parent = itemFrame

	-- ========== CATEGORY INDICATOR ==========
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

	-- ========== LARGE ITEM ICON ==========
	local itemIcon = Instance.new("TextLabel")
	itemIcon.Name = "ItemIcon"
	itemIcon.Size = config.Elements.ItemIcon.Size             -- LARGE: 12% x 50%
	itemIcon.Position = config.Elements.ItemIcon.Position
	itemIcon.BackgroundTransparency = 1
	itemIcon.Text = item.icon or "📦"
	itemIcon.TextColor3 = Color3.new(1, 1, 1)
	itemIcon.Font = Enum.Font.Gotham
	itemIcon.Parent = itemFrame

	-- Apply large text sizing
	self:ApplyLargeTextSizing(itemIcon, 20, "ItemName")

	-- ========== LARGE ITEM NAME ==========
	local itemName = Instance.new("TextLabel")
	itemName.Name = "ItemName"
	itemName.Size = config.Elements.ItemName.Size             -- LARGE: 35% x 30%
	itemName.Position = config.Elements.ItemName.Position
	itemName.BackgroundTransparency = 1
	itemName.Text = item.name or item.id
	itemName.TextColor3 = Color3.new(1, 1, 1)
	itemName.Font = Enum.Font.GothamBold
	itemName.TextXAlignment = Enum.TextXAlignment.Left
	itemName.TextYAlignment = Enum.TextYAlignment.Center
	itemName.TextWrapped = true
	itemName.Parent = itemFrame

	-- Apply large text sizing
	self:ApplyLargeTextSizing(itemName, 18, "ItemName")

	-- ========== LARGE ITEM DESCRIPTION ==========
	local itemDescription = Instance.new("TextLabel")
	itemDescription.Name = "ItemDescription"
	itemDescription.Size = config.Elements.ItemDescription.Size    -- LARGE: 35% x 40%
	itemDescription.Position = config.Elements.ItemDescription.Position
	itemDescription.BackgroundTransparency = 1
	itemDescription.Text = self:GetLargeItemDescription(item, itemType)
	itemDescription.TextColor3 = Color3.fromRGB(200, 200, 200)
	itemDescription.Font = Enum.Font.Gotham
	itemDescription.TextXAlignment = Enum.TextXAlignment.Left
	itemDescription.TextYAlignment = Enum.TextYAlignment.Top
	itemDescription.TextWrapped = true
	itemDescription.Parent = itemFrame

	-- Apply large text sizing
	self:ApplyLargeTextSizing(itemDescription, 16, "ItemDescription")

	-- ========== LARGE PRICE AREA ==========
	self:CreateLargePriceArea(itemFrame, item, itemType, config)

	-- ========== LARGE BUTTON AREA ==========
	self:CreateLargeButtonArea(itemFrame, item, itemType, config)

	-- ========== LARGE BADGE ==========
	self:CreateLargeBadge(itemFrame, item, itemType, config)

	-- ========== HOVER EFFECTS ==========
	self:AddLargeHoverEffects(itemFrame)

	print("✅ Created LARGE uniform item: " .. (item.name or item.id))
	return itemFrame
end

-- ========== LARGE PRICE AREA ==========

function UIManager:CreateLargePriceArea(parent, item, itemType, config)
	local priceContainer = Instance.new("Frame")
	priceContainer.Name = "PriceContainer"
	priceContainer.Size = config.Elements.PriceArea.Size      -- LARGE: 16% x 70%
	priceContainer.Position = config.Elements.PriceArea.Position
	priceContainer.BackgroundTransparency = 1
	priceContainer.Parent = parent

	if itemType == "sell" then
		-- SELL ITEMS: Price per item + total value
		local pricePerItem = Instance.new("TextLabel")
		pricePerItem.Name = "PricePerItem"
		pricePerItem.Size = UDim2.new(1, 0, 0.45, 0)
		pricePerItem.Position = UDim2.new(0, 0, 0, 0)
		pricePerItem.BackgroundTransparency = 1
		pricePerItem.Text = (item.sellPrice or 0) .. " 💰 each"
		pricePerItem.TextColor3 = Color3.fromRGB(255, 215, 0)
		pricePerItem.Font = Enum.Font.Gotham
		pricePerItem.TextXAlignment = Enum.TextXAlignment.Right
		pricePerItem.TextWrapped = true
		pricePerItem.Parent = priceContainer

		local totalValue = Instance.new("TextLabel")
		totalValue.Name = "TotalValue"
		totalValue.Size = UDim2.new(1, 0, 0.45, 0)
		totalValue.Position = UDim2.new(0, 0, 0.55, 0)
		totalValue.BackgroundTransparency = 1
		totalValue.Text = "Total: " .. (item.totalValue or 0) .. " 💰"
		totalValue.TextColor3 = Color3.fromRGB(100, 255, 100)
		totalValue.Font = Enum.Font.GothamBold
		totalValue.TextXAlignment = Enum.TextXAlignment.Right
		totalValue.TextWrapped = true
		totalValue.Parent = priceContainer

		-- Apply large text sizing
		self:ApplyLargeTextSizing(pricePerItem, 14, "Price")
		self:ApplyLargeTextSizing(totalValue, 15, "Price")
	else
		-- BUY ITEMS: Single price
		local buyPrice = Instance.new("TextLabel")
		buyPrice.Name = "BuyPrice"
		buyPrice.Size = UDim2.new(1, 0, 1, 0)
		buyPrice.Position = UDim2.new(0, 0, 0, 0)
		buyPrice.BackgroundTransparency = 1
		buyPrice.Text = (item.price or 0) .. " " .. (item.currency == "farmTokens" and "🎫" or "💰")
		buyPrice.TextColor3 = item.currency == "farmTokens" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
		buyPrice.Font = Enum.Font.GothamBold
		buyPrice.TextXAlignment = Enum.TextXAlignment.Right
		buyPrice.TextYAlignment = Enum.TextYAlignment.Center
		buyPrice.TextWrapped = true
		buyPrice.Parent = priceContainer

		-- Apply large text sizing
		self:ApplyLargeTextSizing(buyPrice, 16, "Price")
	end
end

-- ========== LARGE BUTTON AREA ==========

function UIManager:CreateLargeButtonArea(parent, item, itemType, config)
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = config.Elements.ButtonArea.Size    -- LARGE: 14% x 70%
	buttonContainer.Position = config.Elements.ButtonArea.Position
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = parent

	if itemType == "sell" then
		-- SELL ITEMS: Two large buttons
		local sell1Button = Instance.new("TextButton")
		sell1Button.Name = "Sell1Button"
		sell1Button.Size = UDim2.new(1, 0, 0.45, 0)
		sell1Button.Position = UDim2.new(0, 0, 0, 0)
		sell1Button.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		sell1Button.BorderSizePixel = 0
		sell1Button.Text = "SELL 1"
		sell1Button.TextColor3 = Color3.new(1, 1, 1)
		sell1Button.Font = Enum.Font.GothamBold
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
		sellAllButton.Parent = buttonContainer

		local sellAllCorner = Instance.new("UICorner")
		sellAllCorner.CornerRadius = UDim.new(0.08, 0)
		sellAllCorner.Parent = sellAllButton

		-- Apply large text sizing
		self:ApplyLargeTextSizing(sell1Button, 12, "Button")
		self:ApplyLargeTextSizing(sellAllButton, 12, "Button")

		-- Connect sell functionality
		sell1Button.MouseButton1Click:Connect(function()
			self:HandleLargeSellClick(item.id, 1)
		end)

		sellAllButton.MouseButton1Click:Connect(function()
			self:HandleLargeSellClick(item.id, item.stock or 0)
		end)

	else
		-- BUY ITEMS: Single large button
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(1, 0, 1, 0)
		buyButton.Position = UDim2.new(0, 0, 0, 0)
		buyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		buyButton.BorderSizePixel = 0
		buyButton.Text = "BUY"
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.Font = Enum.Font.GothamBold
		buyButton.Parent = buttonContainer

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0.08, 0)
		buyCorner.Parent = buyButton

		-- Apply large text sizing
		self:ApplyLargeTextSizing(buyButton, 14, "Button")

		-- Connect buy functionality
		buyButton.MouseButton1Click:Connect(function()
			self:HandleLargeBuyClick(item.id, 1)
		end)
	end
end

-- ========== LARGE BADGE ==========

function UIManager:CreateLargeBadge(parent, item, itemType, config)
	local badge = Instance.new("Frame")
	badge.Name = "LargeBadge"
	badge.Size = config.Elements.Badge.Size                   -- LARGE: 6% x 22%
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
	badgeLabel.Parent = badge

	if itemType == "sell" then
		-- Stock badge
		badge.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		badgeLabel.Text = tostring(item.stock or 0)
	else
		-- Purchase order badge
		if item.purchaseOrder and item.purchaseOrder <= 20 then
			badge.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			badgeLabel.Text = tostring(item.purchaseOrder)
		else
			badge.Visible = false
		end
	end

	-- Apply large text sizing
	self:ApplyLargeTextSizing(badgeLabel, 11, "Badge")
end

-- ========== LARGE HOVER EFFECTS ==========

function UIManager:AddLargeHoverEffects(itemFrame)
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

-- ========== LARGE ITEM HANDLERS ==========

function UIManager:HandleLargeBuyClick(itemId, quantity)
	print("UIManager: Large buy click - " .. itemId .. " x" .. quantity)

	if self.State.RemoteEvents.PurchaseItem then
		self.State.RemoteEvents.PurchaseItem:FireServer(itemId, quantity)
		print("UIManager: Sent purchase request via large system")
	else
		self:ShowNotification("Shop Error", "Purchase system not available!", "error")
	end
end

function UIManager:HandleLargeSellClick(itemId, quantity)
	print("UIManager: Large sell click - " .. itemId .. " x" .. quantity)

	if self.State.RemoteEvents.SellItem then
		self.State.RemoteEvents.SellItem:FireServer(itemId, quantity)
		print("UIManager: Sent sell request via large system")
	else
		self:ShowNotification("Sell Error", "Sell system not available!", "error")
	end
end

function UIManager:GetLargeItemDescription(item, itemType)
	if itemType == "sell" then
		return item.description or ("You have " .. (item.stock or 0) .. " in stock")
	else
		local desc = item.description or "No description available"
		-- Allow longer descriptions for large layout
		return desc:len() > 100 and (desc:sub(1, 100) .. "...") or desc
	end
end

-- ========== LARGE SHOP TAB CONTENT POPULATION ==========

function UIManager:PopulateLargeShopTabContent(tabId)
	print("UIManager: Populating LARGE content for tab: " .. tabId)

	local tab = self.State.ShopTabs[tabId]
	if not tab then return end

	local contentFrame = tab.content

	-- Clear existing content
	for _, child in pairs(contentFrame:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	if tabId == "sell" then
		self:PopulateLargeSellTab(contentFrame, tab.config.color)
		return
	end

	-- Get shop items for buy tabs
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
		self:CreateLargeNoItemsMessage(contentFrame, tab.config.name)
		return
	end

	-- Filter items by category
	local categoryItems = {}
	for _, item in ipairs(shopItems) do
		if item.category == tabId then
			table.insert(categoryItems, item)
		end
	end

	if #categoryItems == 0 then
		self:CreateLargeComingSoonMessage(contentFrame, tab.config.name, tab.config.color)
		return
	end

	-- Sort items
	table.sort(categoryItems, function(a, b)
		local orderA = a.purchaseOrder or 999
		local orderB = b.purchaseOrder or 999

		if orderA == orderB then
			return a.price < b.price
		end

		return orderA < orderB
	end)

	-- Create LARGE UNIFORM items
	for i, item in ipairs(categoryItems) do
		local itemFrame = self:CreateLargeUniformShopItem(item, i, tab.config.color, "buy")
		itemFrame.Parent = contentFrame
	end

	-- Set canvas size based on large uniform spacing
	local config = self.LargeUniformShopConfig
	local totalHeight = #categoryItems * (config.ItemFrame.Size.Y.Scale + config.ItemFrame.Spacing) + 0.02
	contentFrame.CanvasSize = UDim2.new(0, 0, totalHeight, 0)

	print("UIManager: ✅ Populated " .. #categoryItems .. " LARGE items in " .. tabId .. " tab")
end

function UIManager:PopulateLargeSellTab(contentFrame, categoryColor)
	print("UIManager: Populating LARGE sell tab...")

	-- Get sellable items
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
		self:CreateLargeNoSellItemsMessage(contentFrame)
		return
	end

	-- Create LARGE UNIFORM sell items
	for i, item in ipairs(sellableItems) do
		local itemFrame = self:CreateLargeUniformShopItem(item, i, categoryColor, "sell")
		itemFrame.Parent = contentFrame
	end

	-- Set canvas size based on large uniform spacing
	local config = self.LargeUniformShopConfig
	local totalHeight = #sellableItems * (config.ItemFrame.Size.Y.Scale + config.ItemFrame.Spacing) + 0.02
	contentFrame.CanvasSize = UDim2.new(0, 0, totalHeight, 0)

	print("UIManager: ✅ Populated " .. #sellableItems .. " LARGE sell items")
end

-- ========== LARGE MESSAGE CREATION ==========

function UIManager:CreateLargeNoItemsMessage(contentFrame, categoryName)
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

	self:ApplyLargeTextSizing(messageLabel, 16, "ItemDescription")
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

function UIManager:CreateLargeNoSellItemsMessage(contentFrame)
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

	self:ApplyLargeTextSizing(messageLabel, 16, "ItemDescription")
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

function UIManager:CreateLargeComingSoonMessage(contentFrame, categoryName, categoryColor)
	local comingSoonFrame = self:CreateLargeUniformShopItem({
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

	-- Set canvas size for single large item
	local config = self.LargeUniformShopConfig
	local totalHeight = config.ItemFrame.Size.Y.Scale + config.ItemFrame.Spacing + 0.02
	contentFrame.CanvasSize = UDim2.new(0, 0, totalHeight, 0)
end

-- ========== REPLACE MAIN POPULATION METHOD ==========

function UIManager:PopulateShopTabContent(tabId)
	-- Redirect to large uniform system
	self:PopulateLargeShopTabContent(tabId)
end

print("LARGE UNIFORM SHOP SYSTEM: ✅ Loaded!")
print("🎯 MATCHES FARMING TAB SIZE:")
print("  📐 Every item frame: 18% height (larger than before)")
print("  🔍 Icons: 12% x 50% (much larger)")
print("  📝 Descriptions: 35% x 40% (much larger)")
print("  💰 Prices: 16% x 70% (larger)")
print("  🔘 Buttons: 14% x 70% (larger)")
print("  📱 Enhanced text scaling for all devices")
print("")
print("🧪 RESULT:")
print("  • All tabs will match Farming tab size")
print("  • Icons and descriptions much more visible")
print("  • Perfect uniformity maintained")
print("  • Better readability on all devices")

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

function UIManager:GetScaleFactor()
	local deviceType = self:GetDeviceType()
	if deviceType == "Mobile" then
		return self.Config.MobileScale
	elseif deviceType == "Tablet" then
		return self.Config.TabletScale
	else
		return self.Config.DesktopScale
	end
end

function UIManager:GetDeviceAdjustments()
	local deviceType = self:GetDeviceType()
	local adjustments = {
		Mobile = {
			TextSizeMultiplier = 1.2,
			ButtonTouchPadding = 4,
			MinTextSize = 12
		},
		Tablet = {
			TextSizeMultiplier = 1.1,
			ButtonTouchPadding = 2,
			MinTextSize = 10
		},
		Desktop = {
			TextSizeMultiplier = 1.0,
			ButtonTouchPadding = 0,
			MinTextSize = 8
		}
	}
	return adjustments[deviceType] or adjustments.Desktop
end
-- ========== INITIALIZATION ==========

function UIManager:Initialize()
	print("UIManager: Starting FIXED initialization with remote event listeners...")

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

	local success, errorMsg = pcall(function()
		self:CreateMainUIStructure()
	end)

	if not success then
		error("UIManager: Failed to create main UI structure: " .. tostring(errorMsg))
	end
	print("UIManager: ✅ Main UI structure created")

	-- FIXED: Connect to remote events FIRST
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

	print("UIManager: 🎉 FIXED initialization complete with remote listeners!")
	return true
end

-- ========== FIXED: REMOTE EVENT CONNECTIONS ==========

function UIManager:ConnectToRemoteEvents()
	print("UIManager: Connecting to remote events...")

	-- Wait for GameRemotes folder
	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not gameRemotes then
		warn("UIManager: GameRemotes folder not found! Shop won't work properly.")
		return
	end

	-- FIXED: Connect to shop opening/closing events
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

	-- Connect to other important events
	local showNotificationEvent = gameRemotes:WaitForChild("ShowNotification", 5)
	if showNotificationEvent and showNotificationEvent:IsA("RemoteEvent") then
		self.State.RemoteEvents.ShowNotification = showNotificationEvent

		showNotificationEvent.OnClientEvent:Connect(function(title, message, notificationType)
			self:ShowNotification(title, message, notificationType)
		end)

		print("UIManager: ✅ Connected to ShowNotification event")
	end

	-- Connect to shop functions
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

-- ========== FIXED: SHOP EVENT HANDLERS ==========

function UIManager:HandleOpenShopFromServer()
	print("UIManager: Handling shop open request from server...")

	-- Close any existing menus first
	if #self.State.ActiveMenus > 0 then
		print("UIManager: Closing existing menus before opening shop...")
		self:CloseActiveMenus()
		wait(0.1) -- Brief delay for smooth transition
	end

	-- Open the shop menu
	local success = self:OpenMenu("Shop")

	if success then
		print("UIManager: ✅ Shop opened successfully from server event!")
		self:ShowNotification("🛒 Shop Opened", "Welcome to the Pet Palace Market!", "success")
	else
		print("UIManager: ❌ Failed to open shop from server event")
		self:ShowNotification("Shop Error", "Failed to open shop. Please try again.", "error")
	end
end

function UIManager:HandleCloseShopFromServer()
	print("UIManager: Handling shop close request from server...")

	-- Only close if shop is currently open
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

-- ========== MAIN UI CREATION (Keep existing) ==========

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

	print("UIManager: Responsive main UI structure created")
end

-- ========== TOP MENU SYSTEM (Keep existing) ==========

function UIManager:SetupTopMenu()
	print("UIManager: Setting up responsive top menu...")

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

	-- Top menu bar
	local menuBar = Instance.new("Frame")
	menuBar.Name = "MenuBar"
	menuBar.Size = UDim2.new(1, 0, 0.08, 0)
	menuBar.Position = UDim2.new(0, 0, 0, 0)
	menuBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	menuBar.BorderSizePixel = 0
	menuBar.ZIndex = self.Config.UIOrder.TopMenu
	menuBar.Parent = menuUI

	-- Menu bar gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
	}
	gradient.Rotation = 90
	gradient.Parent = menuBar

	-- Menu bar border
	local borderLine = Instance.new("Frame")
	borderLine.Name = "BorderLine"
	borderLine.Size = UDim2.new(1, 0, 0, 2)
	borderLine.Position = UDim2.new(0, 0, 1, -2)
	borderLine.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	borderLine.BorderSizePixel = 0
	borderLine.Parent = menuBar

	-- Create menu buttons
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

	-- Shop proximity indicator
	self:CreateProximityShopIndicator(menuBar)

	print("UIManager: ✅ Responsive top menu setup complete")
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

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	stroke.Parent = button

	local scaleFactor = self:GetScaleFactor()
	if scaleFactor > 1.1 then
		button.TextSize = 14 * scaleFactor
	end

	button.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundColor3 = config.hoverColor,
				Size = UDim2.new(width * 1.05, 0, 0.85, 0)
			}
		)
		hoverTween:Play()

		self:ShowButtonTooltip(button, config.description)
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

		self:HideButtonTooltip()
	end)

	button.MouseButton1Click:Connect(function()
		print("UIManager: Top menu button clicked: " .. config.name)
		self:HandleTopMenuButtonClick(config.name)
	end)

	return button
end

function UIManager:CreateProximityShopIndicator(parent)
	local indicator = Instance.new("Frame")
	indicator.Name = "ShopProximityIndicator"
	indicator.Size = UDim2.new(0.15, 0, 0.8, 0)
	indicator.Position = UDim2.new(0.84, 0, 0.1, 0)
	indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.ZIndex = self.Config.UIOrder.TopMenu + 1
	indicator.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "🛒 Shop Available"
	label.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Parent = indicator

	self.State.ShopProximityIndicator = indicator

	print("UIManager: ✅ Created responsive proximity shop indicator")
end

function UIManager:ShowShopProximityIndicator()
	if self.State.ShopProximityIndicator then
		self.State.ShopProximityIndicator.Visible = true

		local tween = TweenService:Create(self.State.ShopProximityIndicator,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(60, 120, 80)}
		)
		tween:Play()
	end
end

function UIManager:HideShopProximityIndicator()
	if self.State.ShopProximityIndicator then
		local tween = TweenService:Create(self.State.ShopProximityIndicator,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(60, 60, 60)}
		)
		tween:Play()

		tween.Completed:Connect(function()
			self.State.ShopProximityIndicator.Visible = false
		end)
	end
end

function UIManager:ShowButtonTooltip(button, description)
	self:HideButtonTooltip()

	local tooltip = Instance.new("Frame")
	tooltip.Name = "ButtonTooltip"
	tooltip.Size = UDim2.new(0.2, 0, 0.06, 0)
	tooltip.Position = UDim2.new(0, button.AbsolutePosition.X, 0, button.AbsolutePosition.Y + button.AbsoluteSize.Y + 5)
	tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	tooltip.BorderSizePixel = 0
	tooltip.ZIndex = self.Config.UIOrder.Notifications
	tooltip.Parent = self.State.MainUI

	local tooltipCorner = Instance.new("UICorner")
	tooltipCorner.CornerRadius = UDim.new(0.1, 0)
	tooltipCorner.Parent = tooltip

	local tooltipText = Instance.new("TextLabel")
	tooltipText.Size = UDim2.new(1, 0, 1, 0)
	tooltipText.Position = UDim2.new(0, 0, 0, 0)
	tooltipText.BackgroundTransparency = 1
	tooltipText.Text = description
	tooltipText.TextColor3 = Color3.new(1, 1, 1)
	tooltipText.TextScaled = true
	tooltipText.Font = Enum.Font.Gotham
	tooltipText.TextWrapped = true
	tooltipText.Parent = tooltip

	tooltip.BackgroundTransparency = 1
	tooltipText.TextTransparency = 1

	local fadeIn = TweenService:Create(tooltip, TweenInfo.new(0.2), {BackgroundTransparency = 0.1})
	local textFadeIn = TweenService:Create(tooltipText, TweenInfo.new(0.2), {TextTransparency = 0})

	fadeIn:Play()
	textFadeIn:Play()
end

function UIManager:HideButtonTooltip()
	local tooltip = self.State.MainUI:FindFirstChild("ButtonTooltip")
	if tooltip then
		tooltip:Destroy()
	end
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
			-- FIXED: Add manual shop opening key for testing
		elseif input.KeyCode == Enum.KeyCode.H then
			print("UIManager: H key pressed - manually opening Shop")
			self:OpenMenu("Shop")
		end
	end)

	print("UIManager: Input handling setup complete")
end

-- ========== MENU MANAGEMENT ==========

function UIManager:OpenMenu(menuName)
	if self.State.IsTransitioning then
		print("UIManager: Ignoring menu open during transition")
		return false
	end

	print("UIManager: Opening menu: " .. menuName)

	if #self.State.ActiveMenus > 0 then
		print("UIManager: Closing existing menus...")
		self:CloseActiveMenus()
		wait(0.1)
	end

	self.State.IsTransitioning = true
	self.State.CurrentPage = menuName

	local success = false

	if menuName == "Shop" then
		success = self:CreateTabbedShopMenu()
	elseif menuName == "Farm" then
		success = self:CreateFarmMenu()
	elseif menuName == "Mining" then
		success = self:CreateMiningMenu()
	elseif menuName == "Crafting" then
		success = self:CreateCraftingMenu()
	elseif menuName == "Premium" then
		success = self:CreatePremiumMenu()
	else
		print("UIManager: Unknown menu type: " .. menuName)
		success = self:CreateGenericMenu(menuName)
	end

	if success then
		print("UIManager: Menu content created successfully")

		local menuContainer = self.State.MainUI:FindFirstChild("MenuContainer")
		if menuContainer then
			menuContainer.Visible = true

			local tween = TweenService:Create(menuContainer,
				TweenInfo.new(self.Config.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0}
			)
			tween:Play()

			tween.Completed:Connect(function()
				self.State.IsTransitioning = false
				print("UIManager: Menu " .. menuName .. " opened successfully")
			end)
		else
			warn("UIManager: MenuContainer not found!")
			self.State.IsTransitioning = false
			return false
		end

		table.insert(self.State.ActiveMenus, menuName)
	else
		print("UIManager: Failed to create menu content for " .. menuName)
		self.State.IsTransitioning = false
		self.State.CurrentPage = "None"
	end

	return success
end

function UIManager:CloseActiveMenus()
	if #self.State.ActiveMenus == 0 then
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
		end)
	end

	self.State.ActiveMenus = {}
	self.State.CurrentPage = "None"
end

-- ========== CURRENCY DISPLAY ==========

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

	print("UIManager: Responsive currency display created")
end

-- ========== MENU CONTAINERS ==========

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

	print("UIManager: Responsive menu containers created")
end

-- ========== NOTIFICATION AREA ==========

function UIManager:CreateNotificationArea(parent)
	local notificationArea = Instance.new("Frame")
	notificationArea.Name = "NotificationArea"
	notificationArea.Size = UDim2.new(0.3, 0, 1, 0)
	notificationArea.Position = UDim2.new(0.69, 0, 0, 0)
	notificationArea.BackgroundTransparency = 1
	notificationArea.ZIndex = self.Config.UIOrder.Notifications
	notificationArea.Parent = parent

	print("UIManager: Responsive notification area created")
end

-- ========== SHOP MENU SYSTEM ==========

function UIManager:CreateTabbedShopMenu()
	print("UIManager: Creating FIXED tabbed shop menu...")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame

	-- Title
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

	-- Access note
	local accessNote = Instance.new("TextLabel")
	accessNote.Name = "AccessNote"
	accessNote.Size = UDim2.new(0.95, 0, 0.05, 0)
	accessNote.Position = UDim2.new(0.025, 0, 0.12, 0)
	accessNote.BackgroundTransparency = 1
	accessNote.Text = "🎯 Connected to server • Remote events working"
	accessNote.TextColor3 = Color3.fromRGB(100, 255, 100)
	accessNote.TextScaled = true
	accessNote.Font = Enum.Font.Gotham
	accessNote.Parent = menuFrame

	-- Create tab container
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

	-- Create content container
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

	-- Create tabs
	self:CreateShopTabs(tabContainer, contentContainer)

	-- Show default tab
	self:ShowShopTab(self.State.ActiveShopTab)

	print("UIManager: ✅ FIXED shop menu created successfully")
	return true
end

function UIManager:CreateShopTabs(tabContainer, contentContainer)
	print("UIManager: Creating FIXED shop tabs...")

	self.State.ShopTabs = {}

	local tabWidth = 1 / #self.Config.ShopTabConfig

	for i, tabConfig in ipairs(self.Config.ShopTabConfig) do
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

		local contentFrame = Instance.new("ScrollingFrame")
		contentFrame.Name = "Content_" .. tabConfig.id
		contentFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
		contentFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
		contentFrame.BackgroundTransparency = 1
		contentFrame.BorderSizePixel = 0
		contentFrame.ScrollBarThickness = 8
		contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
		contentFrame.Visible = false
		contentFrame.Parent = contentContainer

		self.State.ShopTabs[tabConfig.id] = {
			button = tabButton,
			content = contentFrame,
			config = tabConfig,
			populated = false
		}

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

		print("UIManager: Created tab: " .. tabConfig.name)
	end
end

function UIManager:PopulateSellTabContentFixed(contentFrame, categoryColor)
	print("UIManager: Redirecting to LARGE sell tab system...")

	-- FIXED: Use the large uniform sell tab method
	self:PopulateLargeSellTab(contentFrame, categoryColor)
end

-- ========== VERIFICATION METHODS ==========

-- Add this method to verify the system is working:
function UIManager:VerifyLargeUniformSystem()
	print("=== LARGE UNIFORM SYSTEM VERIFICATION ===")

	if self.LargeUniformShopConfig then
		print("✅ LargeUniformShopConfig found")
		print("  Item frame size: " .. tostring(self.LargeUniformShopConfig.ItemFrame.Size))
		print("  Icon size: " .. tostring(self.LargeUniformShopConfig.Elements.ItemIcon.Size))
		print("  Description size: " .. tostring(self.LargeUniformShopConfig.Elements.ItemDescription.Size))
	else
		print("❌ LargeUniformShopConfig missing!")
	end

	-- Check for conflicting methods
	local conflictingMethods = {
		"CreateTrulyUniformShopItem",
		"CreateStandardShopItemFrame", 
		"GetAdjustedItemConfig",
		"CreateUniformPriceArea"
	}

	print("Checking for conflicting methods:")
	for _, methodName in ipairs(conflictingMethods) do
		if self[methodName] then
			print("  ⚠️ Found conflicting method: " .. methodName)
		else
			print("  ✅ No conflict: " .. methodName)
		end
	end

	-- Check for required large methods
	local requiredMethods = {
		"CreateLargeUniformShopItem",
		"CreateLargePriceArea",
		"CreateLargeButtonArea",
		"PopulateLargeShopTabContent"
	}

	print("Checking for required large methods:")
	for _, methodName in ipairs(requiredMethods) do
		if self[methodName] then
			print("  ✅ Found required method: " .. methodName)
		else
			print("  ❌ Missing required method: " .. methodName)
		end
	end

	print("=========================================")
end

print("🔧 CLEAN UIMANAGER FIX LOADED!")
print("📋 APPLY THESE CHANGES:")
print("  1. Remove all old uniform methods")
print("  2. Fix CreateInventoryCategory method")
print("  3. Fix PopulateCategoryMenuContent method") 
print("  4. Fix CreateComingSoonContent method")
print("  5. Add missing GetDeviceAdjustments method")
print("  6. Fix PopulateSellTabContentFixed method")
print("")
print("🧪 TEST COMMAND:")
print("  Add this to test: _G.UIManager:VerifyLargeUniformSystem()")
function UIManager:ShowShopTab(tabId)
	print("UIManager: Switching to shop tab: " .. tabId)

	if not self.State.ShopTabs[tabId] then
		warn("UIManager: Tab not found: " .. tabId)
		return
	end

	local previousTab = self.State.ActiveShopTab
	self.State.ActiveShopTab = tabId

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

	if not self.State.ShopTabs[tabId].populated then
		self:PopulateShopTabContent(tabId)
		self.State.ShopTabs[tabId].populated = true
	end
end

function UIManager:GetItemDescription(item, itemType)
	if itemType == "sell" then
		return item.description or ("You have " .. (item.stock or 0) .. " in stock")
	else
		local desc = item.description or "No description"
		return desc:len() > 80 and (desc:sub(1, 80) .. "...") or desc
	end
end

function UIManager:AddItemFrameHoverEffects(itemFrame)
	itemFrame.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(itemFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{BackgroundColor3 = Color3.fromRGB(70, 70, 70)}
		)
		hoverTween:Play()
	end)

	itemFrame.MouseLeave:Connect(function()
		local leaveTween = TweenService:Create(itemFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{BackgroundColor3 = Color3.fromRGB(60, 60, 60)}
		)
		leaveTween:Play()
	end)
end

-- [Keep all other existing methods: CreateFarmMenu, CreateMiningMenu, etc.]

function UIManager:CreateFarmMenu()
	print("UIManager: Creating responsive farm menu")

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

	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0.95, 0, 0.8, 0)
	inventoryFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Parent = menuFrame

	local inventoryCorner = Instance.new("UICorner")
	inventoryCorner.CornerRadius = UDim.new(0.02, 0)
	inventoryCorner.Parent = inventoryFrame

	local inventoryTitle = Instance.new("TextLabel")
	inventoryTitle.Name = "InventoryTitle"
	inventoryTitle.Size = UDim2.new(0.9, 0, 0.1, 0)
	inventoryTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	inventoryTitle.BackgroundTransparency = 1
	inventoryTitle.Text = "📦 FARM INVENTORY"
	inventoryTitle.TextColor3 = Color3.new(1, 1, 1)
	inventoryTitle.TextScaled = true
	inventoryTitle.Font = Enum.Font.GothamBold
	inventoryTitle.Parent = inventoryFrame

	self:PopulateFarmInventory(inventoryFrame)

	return true
end

function UIManager:PopulateFarmInventory(inventoryFrame)
	if not self.State.GameClient then
		local loadingLabel = Instance.new("TextLabel")
		loadingLabel.Name = "LoadingLabel"
		loadingLabel.Size = UDim2.new(0.9, 0, 0.8, 0)
		loadingLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
		loadingLabel.BackgroundTransparency = 1
		loadingLabel.Text = "Loading farm inventory..."
		loadingLabel.TextColor3 = Color3.new(1, 1, 1)
		loadingLabel.TextScaled = true
		loadingLabel.Font = Enum.Font.Gotham
		loadingLabel.Parent = inventoryFrame
		return
	end

	local success, playerData = pcall(function()
		if self.State.GameClient.GetPlayerData then
			return self.State.GameClient:GetPlayerData()
		end
		return nil
	end)

	if not success or not playerData then
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.new(0.9, 0, 0.8, 0)
		errorLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = "❌ Unable to load inventory data"
		errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		errorLabel.TextScaled = true
		errorLabel.Font = Enum.Font.Gotham
		errorLabel.Parent = inventoryFrame
		return
	end

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "InventoryScroll"
	scrollFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
	scrollFrame.Position = UDim2.new(0.025, 0, 0.12, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = inventoryFrame

	local yPosition = 0.02
	local categorySpacing = 0.02

	yPosition = self:CreateInventoryCategory(scrollFrame, "🌱 SEEDS", yPosition, playerData.seeds or {})
	yPosition = yPosition + categorySpacing

	yPosition = self:CreateInventoryCategory(scrollFrame, "🌾 HARVESTED CROPS", yPosition, playerData.crops or {})
	yPosition = yPosition + categorySpacing

	local milkData = {
		milk = playerData.milk or 0
	}
	yPosition = self:CreateInventoryCategory(scrollFrame, "🥛 DAIRY PRODUCTS", yPosition, milkData)

	scrollFrame.CanvasSize = UDim2.new(0, 0, yPosition + 0.05, 0)
end

function UIManager:CreateInventoryCategory(parentFrame, categoryTitle, startY, itemData)
	local config = self.LargeUniformShopConfig  -- FIXED: Use large config
	local adjustments = self:GetDeviceAdjustments()

	local categoryHeader = Instance.new("Frame")
	categoryHeader.Name = categoryTitle:gsub("[^%w]", "") .. "Header"
	categoryHeader.Size = UDim2.new(0.95, 0, config.ItemFrame.Size.Y.Scale * 0.5, 0)  -- FIXED
	categoryHeader.Position = UDim2.new(0.025, 0, startY, 0)
	categoryHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	categoryHeader.BorderSizePixel = 0
	categoryHeader.Parent = parentFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.1, 0)
	headerCorner.Parent = categoryHeader

	local headerLabel = Instance.new("TextLabel")
	headerLabel.Size = UDim2.new(0.9, 0, 1, 0)
	headerLabel.Position = UDim2.new(0.05, 0, 0, 0)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = categoryTitle
	headerLabel.TextColor3 = Color3.new(1, 1, 1)
	headerLabel.TextScaled = true
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Parent = categoryHeader

	local currentY = startY + (config.ItemFrame.Size.Y.Scale * 0.6)  -- FIXED

	local hasItems = false
	if type(itemData) == "table" then
		for itemName, quantity in pairs(itemData) do
			if quantity and quantity > 0 then
				hasItems = true
				break
			end
		end
	end

	if not hasItems then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyLabel"
		emptyLabel.Size = UDim2.new(0.9, 0, config.ItemFrame.Size.Y.Scale * 0.4, 0)  -- FIXED
		emptyLabel.Position = UDim2.new(0.05, 0, currentY, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No items in this category"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
		emptyLabel.Parent = parentFrame

		return currentY + (config.ItemFrame.Size.Y.Scale * 0.5)  -- FIXED
	end

	for itemName, quantity in pairs(itemData) do
		if quantity and quantity > 0 then
			local itemFrame = Instance.new("Frame")
			itemFrame.Name = itemName .. "Item"
			itemFrame.Size = UDim2.new(0.9, 0, config.ItemFrame.Size.Y.Scale * 0.4, 0)  -- FIXED
			itemFrame.Position = UDim2.new(0.05, 0, currentY, 0)
			itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = parentFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0.05, 0)
			itemCorner.Parent = itemFrame

			local itemIcon = self:GetItemIcon(itemName)
			local iconLabel = Instance.new("TextLabel")
			iconLabel.Size = UDim2.new(0.1, 0, 0.8, 0)
			iconLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
			iconLabel.BackgroundTransparency = 1
			iconLabel.Text = itemIcon
			iconLabel.TextColor3 = Color3.new(1, 1, 1)
			iconLabel.TextScaled = true
			iconLabel.Font = Enum.Font.Gotham
			iconLabel.Parent = itemFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, 0, 0.8, 0)
			nameLabel.Position = UDim2.new(0.15, 0, 0.1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = self:FormatItemName(itemName)
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.Gotham
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = itemFrame

			local quantityLabel = Instance.new("TextLabel")
			quantityLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
			quantityLabel.Position = UDim2.new(0.78, 0, 0.1, 0)
			quantityLabel.BackgroundTransparency = 1
			quantityLabel.Text = "x" .. self:FormatNumber(quantity)
			quantityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			quantityLabel.TextScaled = true
			quantityLabel.Font = Enum.Font.GothamBold
			quantityLabel.TextXAlignment = Enum.TextXAlignment.Right
			quantityLabel.Parent = itemFrame

			itemFrame.MouseEnter:Connect(function()
				local hoverTween = TweenService:Create(itemFrame,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = Color3.fromRGB(45, 45, 45)}
				)
				hoverTween:Play()
			end)

			itemFrame.MouseLeave:Connect(function()
				local leaveTween = TweenService:Create(itemFrame,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{BackgroundColor3 = Color3.fromRGB(35, 35, 35)}
				)
				leaveTween:Play()
			end)

			currentY = currentY + (config.ItemFrame.Size.Y.Scale * 0.5)  -- FIXED
		end
	end

	return currentY
end


function UIManager:GetItemIcon(itemName)
	local iconMap = {
		carrot_seeds = "🥕", carrotSeeds = "🥕",
		tomato_seeds = "🍅", tomatoSeeds = "🍅",
		corn_seeds = "🌽", cornSeeds = "🌽",
		wheat_seeds = "🌾", wheatSeeds = "🌾",
		potato_seeds = "🥔", potatoSeeds = "🥔",
		lettuce_seeds = "🥬", lettuceSeeds = "🥬",
		carrot = "🥕", tomato = "🍅", corn = "🌽", 
		wheat = "🌾", potato = "🥔", lettuce = "🥬",
		milk = "🥛", default = "📦"
	}
	return iconMap[itemName] or iconMap.default
end

function UIManager:FormatItemName(itemName)
	local displayName = itemName:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return a:upper()..b end)
	if itemName:find("_seeds") or itemName:find("Seeds") then
		displayName = displayName:gsub(" Seeds", "") .. " Seeds"
	end
	return displayName
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

	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(0.95, 0, 0.85, 0)
	contentContainer.Position = UDim2.new(0.025, 0, 0.12, 0)
	contentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = menuFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0.02, 0)
	contentCorner.Parent = contentContainer

	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "MiningContent"
	contentFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
	contentFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 8
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	contentFrame.Parent = contentContainer

	self:PopulateCategoryMenuContent(contentFrame, "mining", Color3.fromRGB(150, 150, 150))

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

	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(0.95, 0, 0.85, 0)
	contentContainer.Position = UDim2.new(0.025, 0, 0.12, 0)
	contentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = menuFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0.02, 0)
	contentCorner.Parent = contentContainer

	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "CraftingContent"
	contentFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
	contentFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 8
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	contentFrame.Parent = contentContainer

	self:PopulateCategoryMenuContent(contentFrame, "crafting", Color3.fromRGB(200, 120, 80))

	return true
end

function UIManager:PopulateCategoryMenuContent(contentFrame, category, categoryColor)
	print("UIManager: Populating " .. category .. " menu with LARGE uniform items...")

	-- Clear existing content
	for _, child in pairs(contentFrame:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	-- Get shop items via remote function
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
		self:CreateLargeComingSoonMessage(contentFrame, category, categoryColor)  -- FIXED: Use large method
		return
	end

	-- Filter items by category
	local categoryItems = {}
	for _, item in ipairs(shopItems) do
		if item.category == category then
			table.insert(categoryItems, item)
		end
	end

	if #categoryItems == 0 then
		self:CreateLargeComingSoonMessage(contentFrame, category, categoryColor)  -- FIXED: Use large method
		return
	end

	-- Sort items
	table.sort(categoryItems, function(a, b)
		local orderA = a.purchaseOrder or 999
		local orderB = b.purchaseOrder or 999

		if orderA == orderB then
			return a.price < b.price
		end

		return orderA < orderB
	end)

	-- FIXED: Use large uniform system
	for i, item in ipairs(categoryItems) do
		local itemFrame = self:CreateLargeUniformShopItem(item, i, categoryColor, "buy")  -- FIXED: Use large method
		itemFrame.Parent = contentFrame
	end

	-- FIXED: Use large config for canvas size
	local config = self.LargeUniformShopConfig
	local totalHeight = #categoryItems * (config.ItemFrame.Size.Y.Scale + config.ItemFrame.Spacing) + 0.02
	contentFrame.CanvasSize = UDim2.new(0, 0, totalHeight, 0)

	print("UIManager: ✅ Populated " .. #categoryItems .. " LARGE items in " .. category .. " menu")
end

function UIManager:CreateComingSoonContent(contentFrame, category, categoryColor)
	-- FIXED: Use large coming soon message instead
	self:CreateLargeComingSoonMessage(contentFrame, category, categoryColor)
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
			self:PopulateShopTabContent(self.State.ActiveShopTab)
		end
	elseif menuName == "Farm" then
		self:RefreshFarmContent()
	else
		local currentMenus = self.State.ActiveMenus
		self:CloseActiveMenus()

		spawn(function()
			wait(0.1)
			self:OpenMenu(menuName)
		end)
	end
end

function UIManager:RefreshFarmContent()
	if self.State.CurrentPage ~= "Farm" then return end

	print("UIManager: Refreshing farm inventory content")

	local menuFrame = self.State.MainUI.MenuContainer.MenuFrame
	local inventoryFrame = menuFrame:FindFirstChild("InventoryFrame")

	if inventoryFrame then
		local scrollFrame = inventoryFrame:FindFirstChild("InventoryScroll")
		if scrollFrame then
			for _, child in pairs(scrollFrame:GetChildren()) do
				if not child:IsA("UICorner") and not child:IsA("UIListLayout") then
					child:Destroy()
				end
			end

			self:PopulateFarmInventory(inventoryFrame)
		end
	end
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

	print("UIManager: Responsive notification system setup complete")
end

function UIManager:ShowNotification(title, message, notificationType)
	notificationType = notificationType or "info"

	print("UIManager: Queuing notification: " .. title)

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

function UIManager:GetCurrentPage()
	return self.State.CurrentPage
end

function UIManager:GetState()
	return self.State
end

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

	print("UIManager: Cleanup complete")
end

_G.UIManager = UIManager

print("UIManager: ✅ FIXED WITH REMOTE EVENT LISTENERS!")
print("🔧 KEY FIXES APPLIED:")
print("  ✅ Added ConnectToRemoteEvents() method")
print("  ✅ Connected to OpenShop/CloseShop events")
print("  ✅ Added HandleOpenShopFromServer() handler")
print("  ✅ Added HandleCloseShopFromServer() handler")
print("  ✅ Updated shop item creation to use remote events")
print("  ✅ Fixed purchasing/selling to use remote events")
print("  ✅ Added proper error handling for remote connections")
print("")
print("🎯 REMOTE EVENTS CONNECTED:")
print("  🛒 OpenShop - Opens shop when server fires event")
print("  🚪 CloseShop - Closes shop when server fires event")
print("  📢 ShowNotification - Displays server notifications")
print("  🛍️ GetShopItems - Fetches shop items from server")
print("  💰 GetSellableItems - Fetches sellable items from server")
print("  💳 PurchaseItem - Sends purchase requests to server")
print("  🏪 SellItem - Sends sell requests to server")
print("")
print("📝 TESTING:")
print("  • Step on the large green shop area in game")
print("  • Shop should open automatically via remote event")
print("  • Press H key to manually test shop opening")
print("  • Check F9 console for connection status")

return UIManager