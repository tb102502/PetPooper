-- Pet Collection Simulator
-- Shop UI (LocalScript in StarterGui/MainGui/ContentFrame/ShopFrame)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Get the local player
local player = Players.LocalPlayer

-- Get remote functions
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local PromptPurchase = RemoteFunctions:WaitForChild("PromptPurchase")
local GetShopItems = RemoteFunctions:WaitForChild("GetShopItems")
local CheckGamePassOwnership = RemoteFunctions:WaitForChild("CheckGamePassOwnership")

-- Get remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")
local SendNotification = RemoteEvents:WaitForChild("SendNotification")

-- Reference to the shop frame
local shopFrame = script.Parent

-- Player data
local playerData = {}

-- Shop items
local shopItems = {}

-- Tab references
local coinsTab
local gemsTab
local passesTab
local petsTab
local boostsTab
local upgradesTab

-- Create UI elements
local function SetupShopUI()
	-- Create tabs at the top
	local tabsFrame = Instance.new("Frame")
	tabsFrame.Name = "TabsFrame"
	tabsFrame.Size = UDim2.new(1, 0, 0, 40)
	tabsFrame.Position = UDim2.new(0, 0, 0, 0)
	tabsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabsFrame.BorderSizePixel = 0
	tabsFrame.Parent = shopFrame

	-- Create tab buttons
	local function CreateTabButton(name, position, color)
		local button = Instance.new("TextButton")
		button.Name = name .. "Tab"
		button.Size = UDim2.new(0.16, -5, 1, -10)
		button.Position = UDim2.new(position * 0.16, position * 5, 0, 5)
		button.Text = name
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 14
		button.Font = Enum.Font.GothamBold
		button.BackgroundColor3 = color
		button.BorderSizePixel = 0

		-- Add rounded corners
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 8)
		uiCorner.Parent = button

		button.Parent = tabsFrame
		return button
	end

	-- Create tabs with different colors
	coinsTab = CreateTabButton("Coins", 0, Color3.fromRGB(255, 200, 0))
	gemsTab = CreateTabButton("Gems", 1, Color3.fromRGB(0, 200, 255))
	passesTab = CreateTabButton("Passes", 2, Color3.fromRGB(255, 100, 100))
	petsTab = CreateTabButton("Pets", 3, Color3.fromRGB(200, 100, 255))
	boostsTab = CreateTabButton("Boosts", 4, Color3.fromRGB(100, 255, 100))
	upgradesTab = CreateTabButton("Upgrades", 5, Color3.fromRGB(255, 150, 0))

	-- Create container for shop items
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "ShopContent"
	contentFrame.Size = UDim2.new(1, -20, 1, -50)
	contentFrame.Position = UDim2.new(0, 10, 0, 45)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ScrollBarThickness = 6
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1000) -- Will be updated dynamically
	contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = shopFrame

	-- Create UIGridLayout for shop items
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 180, 0, 220)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = contentFrame

	-- Create the product template (will be cloned for each item)
	local template = Instance.new("Frame")
	template.Name = "ProductTemplate"
	template.Size = UDim2.new(0, 180, 0, 220)
	template.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	template.BorderSizePixel = 0
	template.Visible = false

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = template

	-- Add product image
	local imageFrame = Instance.new("Frame")
	imageFrame.Name = "ImageFrame"
	imageFrame.Size = UDim2.new(1, -20, 0, 100)
	imageFrame.Position = UDim2.new(0, 10, 0, 10)
	imageFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	imageFrame.BorderSizePixel = 0

	-- Rounded corners for image frame
	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 8)
	imageCorner.Parent = imageFrame

	-- Image label for product
	local productImage = Instance.new("ImageLabel")
	productImage.Name = "ProductImage"
	productImage.Size = UDim2.new(0, 80, 0, 80)
	productImage.Position = UDim2.new(0.5, -40, 0.5, -40)
	productImage.BackgroundTransparency = 1
	productImage.Image = "rbxassetid://0" -- Will be set per item
	productImage.Parent = imageFrame

	imageFrame.Parent = template

	-- Add product name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 120)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = "Product Name"
	nameLabel.TextWrapped = true
	nameLabel.Parent = template

	-- Add description
	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "DescriptionLabel"
	descriptionLabel.Size = UDim2.new(1, -20, 0, 30)
	descriptionLabel.Position = UDim2.new(0, 10, 0, 150)
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descriptionLabel.TextSize = 12
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.Text = "Product description goes here"
	descriptionLabel.TextWrapped = true
	descriptionLabel.Parent = template

	-- Add purchase button
	local purchaseButton = Instance.new("TextButton")
	purchaseButton.Name = "PurchaseButton"
	purchaseButton.Size = UDim2.new(1, -20, 0, 30)
	purchaseButton.Position = UDim2.new(0, 10, 0, 180)
	purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	purchaseButton.TextSize = 14
	purchaseButton.Font = Enum.Font.GothamBold
	purchaseButton.Text = "Buy for 100"
	purchaseButton.BorderSizePixel = 0

	-- Rounded corners for button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = purchaseButton

	purchaseButton.Parent = template

	-- Add highlight effect
	local highlight = Instance.new("UIStroke")
	highlight.Name = "Highlight"
	highlight.Color = Color3.fromRGB(0, 200, 255)
	highlight.Thickness = 2
	highlight.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	highlight.Transparency = 1
	highlight.Parent = template

	-- Add the template to the shop frame for reference
	template.Parent = shopFrame

	return contentFrame
end

-- Create a shop item from the template
local function CreateShopItem(contentFrame, itemInfo, category, layoutOrder)
	-- Clone the template
	local template = shopFrame:FindFirstChild("ProductTemplate")
	if not template then
		warn("Product template not found")
		return
	end

	local itemFrame = template:Clone()
	itemFrame.Name = itemInfo.name:gsub(" ", "") .. "Item"
	itemFrame.Visible = true
	itemFrame.LayoutOrder = layoutOrder

	-- Set item information
	local nameLabel = itemFrame:FindFirstChild("NameLabel")
	if nameLabel then
		nameLabel.Text = itemInfo.name
	end

	local descriptionLabel = itemFrame:FindFirstChild("DescriptionLabel")
	if descriptionLabel then
		if category == "Coins" or category == "Gems" then
			descriptionLabel.Text = itemInfo.coinsAmount and (itemInfo.coinsAmount .. " Coins") or 
				(itemInfo.gemsAmount .. " Gems")
		elseif category == "Passes" then
			local benefitTexts = {}
			for benefit, value in pairs(itemInfo.benefits) do
				if type(value) == "number" then
					table.insert(benefitTexts, benefit .. ": " .. value .. "x")
				elseif value == true then
					table.insert(benefitTexts, benefit)
				end
			end
			descriptionLabel.Text = table.concat(benefitTexts, ", ")
		elseif category == "Pets" then
			descriptionLabel.Text = itemInfo.rarity .. " Pet • +" .. (itemInfo.collectValue or 0) .. " Coins"
		elseif category == "Boosts" then
			if itemInfo.type == "Temporary" then
				local durationMinutes = math.floor(itemInfo.duration / 60)
				descriptionLabel.Text = itemInfo.effect .. "x • " .. durationMinutes .. " mins"
			else
				descriptionLabel.Text = itemInfo.description
			end
		elseif category == "Upgrades" then
			descriptionLabel.Text = itemInfo.description
		end
	end

	-- Set image based on category
	local imageFrame = itemFrame:FindFirstChild("ImageFrame")
	if imageFrame then
		local productImage = imageFrame:FindFirstChild("ProductImage")
		if productImage then
			-- You would need actual asset IDs for your images
			if category == "Coins" then
				productImage.Image = "rbxassetid://6834836539" -- Example coin image
				imageFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			elseif category == "Gems" then
				productImage.Image = "rbxassetid://7062389373" -- Example gem image
				imageFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
			elseif category == "Passes" then
				if itemInfo.name:find("VIP") then
					productImage.Image = "rbxassetid://6823357859" -- Example VIP image
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				elseif itemInfo.name:find("Auto") then
					productImage.Image = "rbxassetid://6831593864" -- Example auto collect image
					imageFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
				elseif itemInfo.name:find("Super") then
					productImage.Image = "rbxassetid://6869651181" -- Example super pets image
					imageFrame.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
				elseif itemInfo.name:find("Fast") then
					productImage.Image = "rbxassetid://7072724538" -- Example fast hatch image
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
				elseif itemInfo.name:find("Ultra") then
					productImage.Image = "rbxassetid://6894580861" -- Example ultra luck image
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
				elseif itemInfo.name:find("Extra") then
					productImage.Image = "rbxassetid://7072706191" -- Example storage image
					imageFrame.BackgroundColor3 = Color3.fromRGB(150, 150, 255)
				end
			elseif category == "Pets" then
				if itemInfo.name:find("Corgi") then
					productImage.Image = "rbxassetid://7072738781" -- Example corgi image
				elseif itemInfo.name:find("Panda") then
					productImage.Image = "rbxassetid://7072737419" -- Example panda image
				elseif itemInfo.name:find("Dragon") then
					productImage.Image = "rbxassetid://7072720357" -- Example dragon image
				end

				-- Set background color based on rarity
				if itemInfo.rarity == "Common" then
					imageFrame.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
				elseif itemInfo.rarity == "Rare" then
					imageFrame.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
				elseif itemInfo.rarity == "Epic" then
					imageFrame.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
				elseif itemInfo.rarity == "Legendary" then
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				elseif itemInfo.rarity == "Premium" then
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
				elseif itemInfo.rarity == "VIP" then
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				elseif itemInfo.rarity == "Event" then
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
				end
			elseif category == "Boosts" then
				if itemInfo.name:find("Coin") then
					productImage.Image = "rbxassetid://6834836539" -- Example coin boost image
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				elseif itemInfo.name:find("Luck") then
					productImage.Image = "rbxassetid://6894580861" -- Example luck boost image
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
				elseif itemInfo.name:find("EXP") then
					productImage.Image = "rbxassetid://7072706969" -- Example XP boost image
					imageFrame.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
				end
			elseif category == "Upgrades" then
				if itemInfo.name:find("Magnet") then
					productImage.Image = "rbxassetid://7072723647" -- Example magnet image
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
				elseif itemInfo.name:find("Storage") then
					productImage.Image = "rbxassetid://7072706191" -- Example storage image
					imageFrame.BackgroundColor3 = Color3.fromRGB(150, 150, 255)
				elseif itemInfo.name:find("Luck") then
					productImage.Image = "rbxassetid://6894580861" -- Example luck image
					imageFrame.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
				end
			end
		end
	end

	-- Configure the purchase button
	local purchaseButton = itemFrame:FindFirstChild("PurchaseButton")
	if purchaseButton then
		if category == "Coins" or category == "Gems" then
			-- Robux purchases
			purchaseButton.Text = "Buy for R$" .. (itemInfo.robuxCost or "?")
			purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		elseif category == "Passes" then
			-- Check if already owned
			local alreadyOwned = false
			if playerData.ownedGamePasses and playerData.ownedGamePasses[itemInfo.name] then
				alreadyOwned = true
			end

			if alreadyOwned then
				purchaseButton.Text = "Owned"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			else
				purchaseButton.Text = "Buy for R$" .. (itemInfo.robuxCost or "?")
				purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			end
		elseif category == "Pets" then
			-- Gem purchases
			if itemInfo.gemCost then
				purchaseButton.Text = "Buy for " .. itemInfo.gemCost .. " 💎"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
			elseif itemInfo.rarity == "VIP" then
				-- VIP exclusive
				local hasVIP = false
				if playerData.ownedGamePasses and playerData.ownedGamePasses["VIP Pass"] then
					hasVIP = true
				end

				if hasVIP then
					purchaseButton.Text = "Unlock Free"
					purchaseButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				else
					purchaseButton.Text = "VIP Only"
					purchaseButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
				end
			elseif itemInfo.rarity == "Event" then
				-- Event exclusive
				purchaseButton.Text = itemInfo.eventName .. " Event"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
			end
		elseif category == "Boosts" then
			if itemInfo.type == "Temporary" then
				purchaseButton.Text = "Buy for " .. itemInfo.cost .. " 💎"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
			else
				-- Permanent upgrades
				local currentLevel = playerData.upgrades and playerData.upgrades[itemInfo.name] or 0
				local nextLevel = currentLevel + 1

				if nextLevel > itemInfo.maxLevel then
					purchaseButton.Text = "MAX LEVEL"
					purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
				else
					local cost = itemInfo.baseCost * (itemInfo.costMultiplier ^ currentLevel)
					if itemInfo.purchaseWith == "Coins" then
						purchaseButton.Text = "Buy for " .. math.floor(cost) .. " 🪙"
						purchaseButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
					else
						purchaseButton.Text = "Buy for " .. math.floor(cost) .. " 💎"
						purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
					end
				end
			end
		elseif category == "Upgrades" then
			-- Permanent upgrades
			local currentLevel = playerData.upgrades and playerData.upgrades[itemInfo.name] or 0
			local nextLevel = currentLevel + 1

			if nextLevel > itemInfo.maxLevel then
				purchaseButton.Text = "MAX LEVEL"
				purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			else
				local cost = itemInfo.baseCost * (itemInfo.costMultiplier ^ currentLevel)
				if itemInfo.purchaseWith == "Coins" then
					purchaseButton.Text = "Buy for " .. math.floor(cost) .. " 🪙"
					purchaseButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				else
					purchaseButton.Text = "Buy for " .. math.floor(cost) .. " 💎"
					purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
				end
			end
		end

		-- Add the purchase functionality
		purchaseButton.MouseButton1Click:Connect(function()
			-- Create the prompt based on category
			if category == "Coins" or category == "Gems" then
				-- Robux purchases (developer products)
				PromptPurchase:InvokeServer("DevProduct", itemInfo.name)
			elseif category == "Passes" then
				-- Game passes
				if not (playerData.ownedGamePasses and playerData.ownedGamePasses[itemInfo.name]) then
					PromptPurchase:InvokeServer("GamePass", itemInfo.name)
				end
			elseif category == "Pets" then
				-- Premium pets with gems
				if itemInfo.gemCost and playerData.gems >= itemInfo.gemCost then
					PromptPurchase:InvokeServer("PremiumPet", itemInfo.name)
				elseif itemInfo.rarity == "VIP" and playerData.ownedGamePasses and playerData.ownedGamePasses["VIP Pass"] then
					PromptPurchase:InvokeServer("PremiumPet", itemInfo.name)
				else
					-- Not enough gems or not VIP
					if itemInfo.gemCost and playerData.gems < itemInfo.gemCost then
						-- Show not enough gems notification
						SendNotification:FireClient(
							player, 
							"Not Enough Gems", 
							"You need " .. itemInfo.gemCost .. " gems to purchase this pet!",
							"gems"
						)
					elseif itemInfo.rarity == "VIP" and not (playerData.ownedGamePasses and playerData.ownedGamePasses["VIP Pass"]) then
						-- Prompt the VIP game pass
						PromptPurchase:InvokeServer("GamePass", "VIP Pass")
					end
				end
			elseif category == "Boosts" or category == "Upgrades" then
				if itemInfo.type == "Temporary" then
					-- Temporary boosts with gems
					if playerData.gems >= itemInfo.cost then
						PromptPurchase:InvokeServer("TemporaryBoost", itemInfo.name)
					else
						-- Not enough gems
						SendNotification:FireClient(
							player, 
							"Not Enough Gems", 
							"You need " .. itemInfo.cost .. " gems to purchase this boost!",
							"gems"
						)
					end
				else
					-- Permanent upgrades
					local currentLevel = playerData.upgrades and playerData.upgrades[itemInfo.name] or 0
					local nextLevel = currentLevel + 1

					if nextLevel <= itemInfo.maxLevel then
						local cost = itemInfo.baseCost * (itemInfo.costMultiplier ^ currentLevel)

						if itemInfo.purchaseWith == "Coins" and playerData.coins >= cost then
							PromptPurchase:InvokeServer("PermanentUpgrade", itemInfo.name)
						elseif itemInfo.purchaseWith == "Gems" and playerData.gems >= cost then
							PromptPurchase:InvokeServer("PermanentUpgrade", itemInfo.name)
						else
							-- Not enough currency
							local currencyName
							local currencyIcon

							-- Fixed ternary operator
							if itemInfo.purchaseWith == "Coins" then
								currencyName = "coins"
								currencyIcon = "coins"
							else
								currencyName = "gems"
								currencyIcon = "gems"
							end

							SendNotification:FireClient(
								player, 
								"Not Enough " .. itemInfo.purchaseWith, 
								"You need " .. math.floor(cost) .. " " .. currencyName .. " to purchase this upgrade!",
								currencyIcon
							)
						end
					end
				end
			end
		end)

		-- Add hover effects
		purchaseButton.MouseEnter:Connect(function()
			-- Lighten the button
			TweenService:Create(
				purchaseButton,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundColor3 = purchaseButton.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.3)}
			):Play()

			-- Show highlight
			TweenService:Create(
				itemFrame.Highlight,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 0}
			):Play()
		end)

		purchaseButton.MouseLeave:Connect(function()
			-- Restore the button color
			TweenService:Create(
				purchaseButton,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundColor3 = purchaseButton.BackgroundColor3}
			):Play()

			-- Hide highlight
			TweenService:Create(
				itemFrame.Highlight,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			):Play()
		end)
	end

	-- Add the item to the content frame
	itemFrame.Parent = contentFrame

	return itemFrame
end

-- Populate shop items for a specific category
local function PopulateShopItems(category, contentFrame)
	-- Clear existing items
	for _, child in pairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:find("Item") then
			child:Destroy()
		end
	end

	-- Load the appropriate items
	local items = {}
	if category == "Coins" then
		-- Coins IAPs
		for _, product in pairs(shopItems.DeveloperProducts) do
			if product.coinsAmount then
				table.insert(items, product)
			end
		end
	elseif category == "Gems" then
		-- Gems IAPs
		for _, product in pairs(shopItems.DeveloperProducts) do
			if product.gemsAmount then
				table.insert(items, product)
			end
		end
	elseif category == "Passes" then
		-- Game Passes
		for _, pass in pairs(shopItems.GamePasses) do
			table.insert(items, pass)
		end
	elseif category == "Pets" then
		-- Premium Pets
		for _, pet in pairs(shopItems.PremiumPets) do
			table.insert(items, pet)
		end

		-- VIP Pets
		for _, pet in pairs(shopItems.VIPPets) do
			table.insert(items, pet)
		end

		-- Event Pets (if any active events)
		for _, pet in pairs(shopItems.EventPets) do
			table.insert(items, pet)
		end
	elseif category == "Boosts" then
		-- Temporary boosts
		for _, upgrade in pairs(shopItems.Upgrades) do
			if upgrade.type == "Temporary" then
				table.insert(items, upgrade)
			end
		end
	elseif category == "Upgrades" then
		-- Permanent upgrades
		for _, upgrade in pairs(shopItems.Upgrades) do
			if upgrade.type == "Permanent" then
				table.insert(items, upgrade)
			end
		end
	end

	-- Create shop items
	for i, itemInfo in ipairs(items) do
		CreateShopItem(contentFrame, itemInfo, category, i)
	end

	-- Update the scrolling frame canvas size
	local gridLayout = contentFrame:FindFirstChildOfClass("UIGridLayout")
	if gridLayout then
		local rows = math.ceil(#items / 3) -- Assuming 3 items per row
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 230) -- 220 for item height + 10 for padding
	end
end

-- Show a specific tab
local function ShowTab(tabName, contentFrame)
	-- Update the selected tab
	local tabs = {coinsTab, gemsTab, passesTab, petsTab, boostsTab, upgradesTab}

	for _, tab in ipairs(tabs) do
		if tab.Text == tabName then
			-- Highlight the selected tab
			TweenService:Create(
				tab,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0}
			):Play()
		else
			-- Dim the other tabs
			TweenService:Create(
				tab,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0.5}
			):Play()
		end
	end

	-- Update the shop items
	PopulateShopItems(tabName, contentFrame)
end

-- Initialize the shop
local function Initialize()
	-- Get player data
	pcall(function()
		local success, data = pcall(function()
			return ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetPlayerData"):InvokeServer()
		end)

		if success and data then
			playerData = data
		end
	end)

	-- Get shop items
	pcall(function()
		local success, data = pcall(function()
			return GetShopItems:InvokeServer()
		end)

		if success and data then
			shopItems = data
		end
	end)

	-- Set up the shop UI
	local contentFrame = SetupShopUI()

	-- Set up tab buttons
	coinsTab.MouseButton1Click:Connect(function()
		ShowTab("Coins", contentFrame)
	end)

	gemsTab.MouseButton1Click:Connect(function()
		ShowTab("Gems", contentFrame)
	end)

	passesTab.MouseButton1Click:Connect(function()
		ShowTab("Passes", contentFrame)
	end)

	petsTab.MouseButton1Click:Connect(function()
		ShowTab("Pets", contentFrame)
	end)

	boostsTab.MouseButton1Click:Connect(function()
		ShowTab("Boosts", contentFrame)
	end)

	upgradesTab.MouseButton1Click:Connect(function()
		ShowTab("Upgrades", contentFrame)
	end)

	-- Show the coins tab by default
	ShowTab("Coins", contentFrame)

	-- Listen for player data updates
	UpdatePlayerStats.OnClientEvent:Connect(function(newData)
		if newData then
			playerData = newData

			-- Refresh the current tab
			local selectedTab = nil
			for _, tab in ipairs({coinsTab, gemsTab, passesTab, petsTab, boostsTab, upgradesTab}) do
				if tab.BackgroundTransparency == 0 then
					selectedTab = tab.Text
					break
				end
			end

			if selectedTab then
				ShowTab(selectedTab, contentFrame)
			end
		end
	end)
end

-- Initialize the shop when the script runs
Initialize()