-- SimplifiedShopManager.lua
-- Place in StarterGui/GuiModules/Utility/SimplifiedShopManager.lua

local SimplifiedShopManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Shop data definitions
local SHOP_DATA = {
	Collecting = {
		{
			id = "walkSpeed",
			name = "Swift Steps",
			description = "Increases your walking speed",
			icon = "rbxassetid://6022668955", -- Speed icon
			currency = "coins",
			baseCost = 100,
			costMultiplier = 1.5,
			maxLevel = 10,
			currentLevel = 1
		},
		{
			id = "stamina",
			name = "Extra Stamina",
			description = "Increases your maximum stamina",
			icon = "rbxassetid://6034287594", -- Stamina icon
			currency = "coins",
			baseCost = 150,
			costMultiplier = 1.8,
			maxLevel = 5,
			currentLevel = 1
		},
		{
			id = "collectRange",
			name = "Extended Reach",
			description = "Increases pet collection range",
			icon = "rbxassetid://6034684930", -- Range icon
			currency = "coins",
			baseCost = 200,
			costMultiplier = 2.0,
			maxLevel = 8,
			currentLevel = 1
		},
		{
			id = "collectSpeed",
			name = "Quick Collection",
			description = "Collect pets faster",
			icon = "rbxassetid://6031075938", -- Fast icon
			currency = "coins",
			baseCost = 250,
			costMultiplier = 1.7,
			maxLevel = 6,
			currentLevel = 1
		}
	},

	Areas = {
		{
			id = "mysticForest",
			name = "Mystic Forest",
			description = "Unlock the magical forest area with rare pets",
			icon = "rbxassetid://6031265976", -- Forest icon
			currency = "coins",
			cost = 1000,
			unlocked = false
		},
		{
			id = "dragonLair",
			name = "Dragon's Lair",
			description = "Discover legendary dragons and epic pets",
			icon = "rbxassetid://6031068421", -- Dragon icon
			currency = "coins",
			cost = 10000,
			unlocked = false
		},
		{
			id = "crystalCave",
			name = "Crystal Cave",
			description = "Explore shimmering caves with crystal pets",
			icon = "rbxassetid://6031225835", -- Crystal icon
			currency = "gems",
			cost = 500,
			unlocked = false
		}
	},

	Premium = {
		{
			id = "unlimitedStamina",
			name = "Unlimited Stamina",
			description = "Never run out of stamina again!",
			icon = "rbxassetid://6031280882", -- Premium icon
			currency = "robux",
			cost = 199,
			owned = false
		},
		{
			id = "doubleXP",
			name = "Double Pet XP",
			description = "All pets gain double experience",
			icon = "rbxassetid://6031097225", -- XP icon
			currency = "robux",
			cost = 149,
			owned = false
		},
		{
			id = "autoCollect",
			name = "Auto Collector",
			description = "Automatically collect nearby pets",
			icon = "rbxassetid://6031075938", -- Auto icon
			currency = "robux",
			cost = 299,
			owned = false
		},
		{
			id = "petSlots",
			name = "Extra Pet Slots",
			description = "Carry 50% more pets",
			icon = "rbxassetid://6031226106", -- Slots icon
			currency = "robux",
			cost = 99,
			owned = false
		}
	}
}

-- State
local currentTab = "Collecting"
local shopVisible = false

-- GUI References (will be set when shop is found)
local shopGui = nil
local mainFrame = nil
local tabsFrame = nil
local contentFrame = nil

-- Initialize the shop manager
function SimplifiedShopManager.Initialize()
	-- Find the shop GUI
	shopGui = playerGui:WaitForChild("ShopGui", 5)
	if not shopGui then
		warn("ShopGui not found in PlayerGui")
		return
	end

	-- Get GUI references
	mainFrame = shopGui:WaitForChild("MainFrame")
	tabsFrame = mainFrame:WaitForChild("TabsFrame")
	contentFrame = mainFrame:WaitForChild("ContentFrame")

	-- Setup tab buttons
	SimplifiedShopManager.SetupTabButtons()

	-- Setup close button
	local closeButton = mainFrame:WaitForChild("TopBar"):WaitForChild("CloseButton")
	closeButton.MouseButton1Click:Connect(function()
		SimplifiedShopManager.CloseShop()
	end)

	-- Initially hide the shop
	mainFrame.Visible = false
	shopVisible = false

	-- Load initial data
	SimplifiedShopManager.UpdateShopData()

	print("SimplifiedShopManager initialized")
end

-- Setup tab button connections
function SimplifiedShopManager.SetupTabButtons()
	local collectingTab = tabsFrame:WaitForChild("CollectingTab")
	local areasTab = tabsFrame:WaitForChild("AreasTab")
	local premiumTab = tabsFrame:WaitForChild("PremiumTab")

	collectingTab.MouseButton1Click:Connect(function()
		SimplifiedShopManager.SwitchTab("Collecting")
	end)

	areasTab.MouseButton1Click:Connect(function()
		SimplifiedShopManager.SwitchTab("Areas")
	end)

	premiumTab.MouseButton1Click:Connect(function()
		SimplifiedShopManager.SwitchTab("Premium")
	end)

	-- Set initial tab
	SimplifiedShopManager.SwitchTab("Collecting")
end

-- Switch between tabs
function SimplifiedShopManager.SwitchTab(tabName)
	currentTab = tabName

	-- Update tab button appearances
	local tabs = {"CollectingTab", "AreasTab", "PremiumTab"}
	for _, tab in ipairs(tabs) do
		local tabButton = tabsFrame:FindFirstChild(tab)
		if tabButton then
			if tab == tabName .. "Tab" then
				tabButton.BackgroundColor3 = Color3.fromRGB(80, 120, 180) -- Active
			else
				tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Inactive
			end
		end
	end

	-- Show/hide content frames
	for _, frameName in ipairs({"CollectingFrame", "AreasFrame", "PremiumFrame"}) do
		local frame = contentFrame:FindFirstChild(frameName)
		if frame then
			frame.Visible = (frameName == tabName .. "Frame")
		end
	end

	-- Update content
	SimplifiedShopManager.UpdateTabContent(tabName)
end

-- Update content for a specific tab
function SimplifiedShopManager.UpdateTabContent(tabName)
	local data = SHOP_DATA[tabName]
	if not data then return end

	local frame = contentFrame:FindFirstChild(tabName .. "Frame")
	if not frame then return end

	-- Update each item in the tab
	for i, itemData in ipairs(data) do
		local itemFrame = frame:FindFirstChild("Item" .. i)
		if itemFrame then
			SimplifiedShopManager.UpdateItemDisplay(itemFrame, itemData, tabName)
		end
	end
end

-- Update individual item display
function SimplifiedShopManager.UpdateItemDisplay(itemFrame, itemData, tabType)
	-- Update icon
	local icon = itemFrame:FindFirstChild("Icon")
	if icon then
		icon.Image = itemData.icon
	end

	-- Update title
	local titleLabel = itemFrame:FindFirstChild("TitleLabel")
	if titleLabel then
		titleLabel.Text = itemData.name
	end

	-- Update description
	local descLabel = itemFrame:FindFirstChild("DescriptionLabel")
	if descLabel then
		descLabel.Text = itemData.description
	end

	-- Update cost/level display
	local purchaseButton = itemFrame:FindFirstChild("PurchaseButton")
	if purchaseButton then
		if tabType == "Collecting" then
			-- Handle upgrades
			local cost = math.floor(itemData.baseCost * (itemData.costMultiplier ^ (itemData.currentLevel - 1)))
			local maxed = itemData.currentLevel >= itemData.maxLevel

			if maxed then
				purchaseButton.Text = "MAXED"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				purchaseButton.Active = false
			else
				purchaseButton.Text = cost .. " " .. itemData.currency:upper()
				purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
				purchaseButton.Active = true
			end

			-- Update level display
			local levelLabel = itemFrame:FindFirstChild("LevelFrame"):FindFirstChild("CurrentLevel")
			if levelLabel then
				levelLabel.Text = "Level: " .. itemData.currentLevel .. "/" .. itemData.maxLevel
			end

		elseif tabType == "Areas" then
			-- Handle area unlocks
			if itemData.unlocked then
				purchaseButton.Text = "UNLOCKED"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
				purchaseButton.Active = false
			else
				purchaseButton.Text = itemData.cost .. " " .. itemData.currency:upper()
				purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
				purchaseButton.Active = true
			end

		elseif tabType == "Premium" then
			-- Handle premium items
			if itemData.owned then
				purchaseButton.Text = "OWNED"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
				purchaseButton.Active = false
			else
				purchaseButton.Text = itemData.cost .. " R$"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
				purchaseButton.Active = true
			end
		end

		-- Connect purchase event
		if purchaseButton.Active then
			-- Clear previous connections
			purchaseButton.MouseButton1Click:Connect(function()
				SimplifiedShopManager.PurchaseItem(itemData, tabType)
			end)
		end
	end
end

-- Handle item purchases
function SimplifiedShopManager.PurchaseItem(itemData, tabType)
	print("Attempting to purchase:", itemData.name)

	-- Get the appropriate remote event
	local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	if tabType == "Collecting" then
		local buyUpgrade = RemoteEvents:FindFirstChild("BuyUpgrade")
		if buyUpgrade then
			buyUpgrade:FireServer(itemData.id)
		end
	elseif tabType == "Areas" then
		local unlockArea = RemoteEvents:FindFirstChild("UnlockArea")
		if unlockArea then
			unlockArea:FireServer(itemData.id)
		end
	elseif tabType == "Premium" then
		local buyPremium = RemoteEvents:FindFirstChild("BuyPremium")
		if buyPremium then
			buyPremium:FireServer(itemData.id)
		end
	end

	-- Add visual feedback
	SimplifiedShopManager.ShowPurchaseFeedback(itemData.name)
end

-- Show purchase feedback
function SimplifiedShopManager.ShowPurchaseFeedback(itemName)
	-- Create temporary feedback label
	local feedback = Instance.new("TextLabel")
	feedback.Size = UDim2.new(0, 300, 0, 50)
	feedback.Position = UDim2.new(0.5, -150, 0.5, -25)
	feedback.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	feedback.TextColor3 = Color3.fromRGB(255, 255, 255)
	feedback.Font = Enum.Font.GothamBold
	feedback.TextSize = 18
	feedback.Text = "Purchased: " .. itemName
	feedback.TextTransparency = 0
	feedback.BackgroundTransparency = 0
	feedback.ZIndex = 10
	feedback.Parent = mainFrame

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = feedback

	-- Animate feedback
	local tween = TweenService:Create(
		feedback,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0.5, -150, 0.3, -25),
			TextTransparency = 1,
			BackgroundTransparency = 1
		}
	)

	tween:Play()
	tween.Completed:Connect(function()
		feedback:Destroy()
	end)
end

-- Open the shop
function SimplifiedShopManager.OpenShop(tabName)
	if not mainFrame then return end

	tabName = tabName or "Collecting"
	mainFrame.Visible = true
	shopVisible = true

	-- Animate shop opening
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0.8, 0, 0.8, 0),
			Position = UDim2.new(0.1, 0, 0.1, 0)
		}
	)
	tween:Play()

	-- Switch to requested tab
	SimplifiedShopManager.SwitchTab(tabName)
end

-- Close the shop
function SimplifiedShopManager.CloseShop()
	if not mainFrame then return end

	-- Animate shop closing
	local tween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		mainFrame.Visible = false
		shopVisible = false
	end)
end

-- Update shop data from server
function SimplifiedShopManager.UpdateShopData(newData)
	if newData then
		-- Update local data with server data
		for tabName, items in pairs(newData) do
			if SHOP_DATA[tabName] then
				for i, item in ipairs(items) do
					if SHOP_DATA[tabName][i] then
						-- Update relevant fields
						for key, value in pairs(item) do
							SHOP_DATA[tabName][i][key] = value
						end
					end
				end
			end
		end
	end

	-- Refresh current tab
	if shopVisible then
		SimplifiedShopManager.UpdateTabContent(currentTab)
	end
end

-- Check if shop is open
function SimplifiedShopManager.IsShopOpen()
	return shopVisible
end

-- Get shop data (for other scripts)
function SimplifiedShopManager.GetShopData()
	return SHOP_DATA
end

return SimplifiedShopManager