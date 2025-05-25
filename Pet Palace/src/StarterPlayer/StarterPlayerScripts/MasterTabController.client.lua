-- MasterTabController.client.lua
-- Simplified version that focuses on fixing the SellingFrame error
-- Updated: 2025-05-23 12:40:00
-- User: tb102502

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get shop data
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Track if we've initialized
local initialized = false

---------------------------------
-- UTILITY FUNCTIONS
---------------------------------

-- Function to add cost labels to frames like upgrades and areas
local function addCostLabelsToFrame(frame, frameType)
	-- Process all child frames that might be items
	local processedCount = 0
	for _, child in pairs(frame:GetChildren()) do
		-- Only process Frames or TextButtons that might be items
		if (child:IsA("Frame") or child:IsA("TextButton")) and 
			child.Name ~= "UIGridLayout" and 
			child.Name ~= "UIListLayout" then

			-- Skip if this item already has a proper cost label
			if child:FindFirstChild("CostLabel") and child:FindFirstChild("CostLabel"):FindFirstChild("CoinIcon") then
				continue
			end

			-- Remove existing cost label if it doesn't have a coin icon
			if child:FindFirstChild("CostLabel") then
				child:FindFirstChild("CostLabel"):Destroy()
			end

			-- Try to find a PurchaseButton or any button
			local purchaseButton = child:FindFirstChild("PurchaseButton")
			if not purchaseButton then
				-- If no specific purchase button, try to find any button
				for _, subChild in pairs(child:GetChildren()) do
					if subChild:IsA("TextButton") and subChild.Text and 
						(subChild.Text:lower():match("buy") or subChild.Text:lower():match("purchase") or
							subChild.Text:lower():match("unlock") or subChild.Text:lower():match("coin") or
							subChild.Text:lower():match("gem") or subChild.Text:lower():match("%d+")) then
						purchaseButton = subChild
						break
					end
				end
			end

			-- If we found a button, add a cost label
			if purchaseButton then
				-- Extract cost from button text if available
				local cost = "???"
				if purchaseButton.Text then
					-- Try to find the cost in the button text
					local costMatch = purchaseButton.Text:match("%d+")
					if costMatch then
						cost = costMatch
					end
				end

				-- Create cost label
				local costLabelFrame = Instance.new("Frame")
				costLabelFrame.Name = "CostLabel"
				costLabelFrame.Size = UDim2.new(0, 80, 0, 24)
				costLabelFrame.Position = UDim2.new(1, -86, 0, 6)
				costLabelFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
				costLabelFrame.BackgroundTransparency = 0.3
				costLabelFrame.ZIndex = 5
				costLabelFrame.Parent = child

				-- Add corner
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 12)
				corner.Parent = costLabelFrame

				-- Add coin icon
				local coinIcon = Instance.new("ImageLabel")
				coinIcon.Name = "CoinIcon"
				coinIcon.Size = UDim2.new(0, 20, 0, 20)
				coinIcon.Position = UDim2.new(0, 2, 0, 2)
				coinIcon.BackgroundTransparency = 1
				coinIcon.Image = "rbxassetid://6031233233" -- A generic coin icon
				coinIcon.ZIndex = 6
				coinIcon.Parent = costLabelFrame

				-- Add cost text
				local costText = Instance.new("TextLabel")
				costText.Name = "CostText"
				costText.Size = UDim2.new(0, 56, 0, 24)
				costText.Position = UDim2.new(0, 24, 0, 0)
				costText.Text = cost
				costText.TextColor3 = Color3.fromRGB(50, 50, 50)
				costText.TextSize = 14
				costText.Font = Enum.Font.Gotham
				costText.BackgroundTransparency = 1
				costText.TextXAlignment = Enum.TextXAlignment.Left
				costText.ZIndex = 6
				costText.Parent = costLabelFrame

				processedCount = processedCount + 1
			end
		end
	end

	print("Added/Updated " .. processedCount .. " cost labels in " .. frameType .. " frame")
end

-- Function to create sell content with both crops and pets
local function createSellContent(parentFrame)
	-- Clear existing content
	for _, child in pairs(parentFrame:GetChildren()) do
		if (child:IsA("Frame") or child:IsA("ScrollingFrame")) and 
			child.Name ~= "UIGridLayout" and 
			child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end

	-- Create tabs frame
	local sellTabs = Instance.new("Frame")
	sellTabs.Name = "SellTabs"
	sellTabs.Size = UDim2.new(1, 0, 0, 40)
	sellTabs.Position = UDim2.new(0, 0, 0, 0)
	sellTabs.BackgroundTransparency = 1
	sellTabs.Parent = parentFrame

	-- Create crops tab
	local cropsTab = Instance.new("TextButton")
	cropsTab.Name = "CropsTab"
	cropsTab.Size = UDim2.new(0.5, -5, 1, 0)
	cropsTab.Position = UDim2.new(0, 0, 0, 0)
	cropsTab.Text = "CROPS"
	cropsTab.Font = Enum.Font.Gotham
	cropsTab.TextSize = 16
	cropsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	cropsTab.BackgroundColor3 = Color3.fromRGB(80, 120, 180)  -- Active color
	cropsTab.Parent = sellTabs

	local cropsCorner = Instance.new("UICorner")
	cropsCorner.CornerRadius = UDim.new(0, 6)
	cropsCorner.Parent = cropsTab

	-- Create pets tab
	local petsTab = Instance.new("TextButton")
	petsTab.Name = "PetsTab"
	petsTab.Size = UDim2.new(0.5, -5, 1, 0)
	petsTab.Position = UDim2.new(0.5, 5, 0, 0)
	petsTab.Text = "PETS"
	petsTab.Font = Enum.Font.Gotham
	petsTab.TextSize = 16
	petsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
	petsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  -- Inactive color
	petsTab.Parent = sellTabs

	local petsCorner = Instance.new("UICorner")
	petsCorner.CornerRadius = UDim.new(0, 6)
	petsCorner.Parent = petsTab

	-- Create content container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "SellContent"
	contentContainer.Size = UDim2.new(1, 0, 1, -50)
	contentContainer.Position = UDim2.new(0, 0, 0, 50)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = parentFrame

	-- Create crop content
	local cropContent = Instance.new("ScrollingFrame")
	cropContent.Name = "CropContent"
	cropContent.Size = UDim2.new(1, 0, 1, 0)
	cropContent.BackgroundTransparency = 1
	cropContent.ScrollBarThickness = 6
	cropContent.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	cropContent.Visible = true
	cropContent.Parent = contentContainer

	-- Add grid layout
	local cropGrid = Instance.new("UIGridLayout")
	cropGrid.CellSize = UDim2.new(0, 100, 0, 130)
	cropGrid.CellPadding = UDim2.new(0, 10, 0, 10)
	cropGrid.SortOrder = Enum.SortOrder.Name
	cropGrid.Parent = cropContent

	-- Create pet content
	local petContent = Instance.new("ScrollingFrame")
	petContent.Name = "PetContent"
	petContent.Size = UDim2.new(1, 0, 1, 0)
	petContent.BackgroundTransparency = 1
	petContent.ScrollBarThickness = 6
	petContent.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	petContent.Visible = false
	petContent.Parent = contentContainer

	-- Add grid layout
	local petGrid = Instance.new("UIGridLayout")
	petGrid.CellSize = UDim2.new(0, 100, 0, 130)
	petGrid.CellPadding = UDim2.new(0, 10, 0, 10)
	petGrid.SortOrder = Enum.SortOrder.Name
	petGrid.Parent = petContent

	-- Connect tab buttons
	cropsTab.MouseButton1Click:Connect(function()
		cropContent.Visible = true
		petContent.Visible = false
		cropsTab.BackgroundColor3 = Color3.fromRGB(80, 120, 180)  -- Active
		petsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)     -- Inactive
		cropsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		petsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
	end)

	petsTab.MouseButton1Click:Connect(function()
		cropContent.Visible = false
		petContent.Visible = true
		petsTab.BackgroundColor3 = Color3.fromRGB(80, 120, 180)   -- Active
		cropsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)    -- Inactive
		petsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		cropsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
	end)

	-- Populate with items (simplified)
	local defaultItems = {
		crops = {
			{name = "Carrot", value = 30, image = "6686041557"},
			{name = "Corn", value = 75, image = "6686047557"},
			{name = "Strawberry", value = 150, image = "6686052839"},
			{name = "Golden Fruit", value = 500, image = "6686056891"}
		},
		pets = {
			{name = "Corgi", value = 5, image = "6686023447", rarity = "Common"},
			{name = "Cat", value = 150, image = "6686028301", rarity = "Common"},
			{name = "Hamster", value = 250, image = "6686031940", rarity = "Uncommon"},
			{name = "RedPanda", value = 500, image = "6686036280", rarity = "Rare"}
		}
	}

	-- Create crop items
	for i, item in ipairs(defaultItems.crops) do
		local frame = Instance.new("Frame")
		frame.Name = item.name
		frame.Size = UDim2.new(0, 100, 0, 130)
		frame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		frame.Parent = cropContent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = frame

		local image = Instance.new("ImageLabel")
		image.Size = UDim2.new(0, 60, 0, 60)
		image.Position = UDim2.new(0.5, -30, 0, 10)
		image.Image = "rbxassetid://" .. item.image
		image.BackgroundTransparency = 1
		image.Parent = frame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 20)
		nameLabel.Position = UDim2.new(0, 0, 0, 75)
		nameLabel.Text = item.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = frame

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, 0, 0, 20)
		priceLabel.Position = UDim2.new(0, 0, 0, 95)
		priceLabel.Text = "Sell: " .. item.value .. " Coins"
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
		priceLabel.TextSize = 12
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.BackgroundTransparency = 1
		priceLabel.Parent = frame

		local sellButton = Instance.new("TextButton")
		sellButton.Size = UDim2.new(1, -20, 0, 20)
		sellButton.Position = UDim2.new(0, 10, 0, 115)
		sellButton.Text = "SELL"
		sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		sellButton.TextSize = 12
		sellButton.Font = Enum.Font.Gotham
		sellButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		sellButton.Parent = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = sellButton
	end

	-- Create pet items
	for i, item in ipairs(defaultItems.pets) do
		local frame = Instance.new("Frame")
		frame.Name = item.name
		frame.Size = UDim2.new(0, 100, 0, 130)
		frame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		frame.Parent = petContent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = frame

		local image = Instance.new("ImageLabel")
		image.Size = UDim2.new(0, 60, 0, 60)
		image.Position = UDim2.new(0.5, -30, 0, 10)
		image.Image = "rbxassetid://" .. item.image
		image.BackgroundTransparency = 1
		image.Parent = frame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 20)
		nameLabel.Position = UDim2.new(0, 0, 0, 75)
		nameLabel.Text = item.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = frame

		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, 0, 0, 15)
		rarityLabel.Position = UDim2.new(0, 0, 0, 90)
		rarityLabel.Text = item.rarity
		rarityLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
		rarityLabel.TextSize = 10
		rarityLabel.Font = Enum.Font.Gotham
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Parent = frame

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, 0, 0, 20)
		priceLabel.Position = UDim2.new(0, 0, 0, 102)
		priceLabel.Text = "Sell: " .. item.value .. " Coins"
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
		priceLabel.TextSize = 10
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.BackgroundTransparency = 1
		priceLabel.Parent = frame

		local sellButton = Instance.new("TextButton")
		sellButton.Size = UDim2.new(1, -20, 0, 20)
		sellButton.Position = UDim2.new(0, 10, 0, 115)
		sellButton.Text = "SELL"
		sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		sellButton.TextSize = 12
		sellButton.Font = Enum.Font.Gotham
		sellButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		sellButton.Parent = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = sellButton
	end

	-- Update canvas size
	task.spawn(function()
		task.wait(0.05)
		if cropGrid and cropGrid:IsDescendantOf(game) then
			cropContent.CanvasSize = UDim2.new(0, cropGrid.AbsoluteContentSize.X, 0, cropGrid.AbsoluteContentSize.Y + 20)
		end

		if petGrid and petGrid:IsDescendantOf(game) then
			petContent.CanvasSize = UDim2.new(0, petGrid.AbsoluteContentSize.X, 0, petGrid.AbsoluteContentSize.Y + 20)
		end
	end)
end

---------------------------------
-- MAIN ENHANCEMENT CODE
---------------------------------

-- Create a frame if it doesn't exist
local function ensureFrameExists(contentFrame, frameName)
	local frame = contentFrame:FindFirstChild(frameName)
	if not frame then
		frame = Instance.new("Frame")
		frame.Name = frameName
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.Visible = false
		frame.Parent = contentFrame
		print("Created missing frame: " .. frameName)
	end
	return frame
end

-- Function specifically to handle the ConnectTabButtons error
local function fixSellingFrameError()
	
end
	-- Find the ShopGui and MainFrame
	if not shopGui then
		warn("ShopGui not found")
		return
	end

	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if not mainFrame then
		warn("MainFrame not found")
		return
	end

	local contentFrame = mainFrame:FindFirstChild("ContentFrame")
	if not contentFrame then
		warn("ContentFrame not found")
		return
	end

	-- Create both required frames
	local sellingFrame = ensureFrameExists(contentFrame, "SellingFrame")
	local sellFrame = ensureFrameExists(contentFrame, "SellFrame")

	-- Also create SaleFrame just in case
	local saleFrame = ensureFrameExists(contentFrame, "SaleFrame")

	-- Link them together with StringValues instead of trying to set script source
	local link1 = Instance.new("StringValue")
	link1.Name = "LinkedToSellFrame"
	link1.Value = "true"
	link1.Parent = sellingFrame

	local link2 = Instance.new("StringValue")
	link2.Name = "IsSellContent" 
	link2.Value = "true"
	link2.Parent = sellFrame

	-- Add our content to SellFrame
	createSellContent(sellFrame)

	-- Add cost labels to important frames
	local upgradeFrame = contentFrame:FindFirstChild("UpgradeFrame") or 
		contentFrame:FindFirstChild("UpgradesFrame") or
		contentFrame:FindFirstChild("CollectFrame")
	if upgradeFrame then
		addCostLabelsToFrame(upgradeFrame, "upgrades")
	end

	local areaFrame = contentFrame:FindFirstChild("AreaFrame") or 
		contentFrame:FindFirstChild("AreasFrame")
	if areaFrame then
		addCostLabelsToFrame(areaFrame, "areas")
	end

	-- Monitor when the system tries to show SellingFrame and redirect to SellFrame
	-- Monitor when the system tries to show SellingFrame and redirect to SellFrame
	spawn(function()
		while wait(0.1) do
			-- Check if SellingFrame is showing but SellFrame isn't
			if sellingFrame.Visible and not sellFrame.Visible then
				sellFrame.Visible = true

				-- Make sure SellFrame has content
				if not sellFrame:FindFirstChild("SellTabs") then
					createSellContent(sellFrame)
				end
			end

			-- Also check for other cases
			if (sellingFrame.Visible or sellFrame.Visible) and not sellFrame:FindFirstChild("SellTabs") then
				createSellContent(sellFrame)
			end
		end
	end)
	-- Add global function to update cost labels
	_G.RefreshCostLabels = function()
		if upgradeFrame then
			addCostLabelsToFrame(upgradeFrame, "upgrades")
		end

		if areaFrame then
			addCostLabelsToFrame(areaFrame, "areas")
		end
	end

	-- Fix for the tab button system
	local tabsFrame = mainFrame:FindFirstChild("TabsFrame")
	if tabsFrame then
		-- Look for SellTab or any similar button
		for _, button in pairs(tabsFrame:GetChildren()) do
			if button:IsA("TextButton") and 
				(button.Name:lower():match("sell") or 
					(button.Text and button.Text:lower():match("sell"))) then

				-- Add our own click handler
				button.MouseButton1Click:Connect(function()
					-- Add a small delay to let original handler run
					task.spawn(function()
						task.wait(0.1)

						-- Force SellFrame to have content and be visible
						if not sellFrame:FindFirstChild("SellTabs") then
							createSellContent(sellFrame)
						end

						sellFrame.Visible = true
					end)
				end)
			end
		end
	end

	print("Fixed SellingFrame error")

	-- Main initialization
-- Main initialization
local function initialize()
	if initialized then
		return
	end

	-- Run the fix function
	fixSellingFrameError()

	-- Mark as initialized
	initialized = true
	print("Shop UI enhancement initialized")
end

-- Run the initialization with a delay
spawn(function()
	wait(1)  -- Wait for other scripts to initialize
	initialize()

	-- Run again after a delay to ensure everything is loaded
	wait(2)
	fixSellingFrameError()
end)

print("MasterTabController loaded - " .. os.date("%Y-%m-%d %H:%M:%S"))