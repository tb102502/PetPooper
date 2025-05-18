-- Pet Collection Simulator
-- ShopGUI Script (LocalScript in StarterGui)

-- Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService") -- Not used in this script, but kept

-- Local player
local player = Players.LocalPlayer

-- Ensure RemoteEvents and RemoteFunctions exist
local function ensureRemotesExist()
	local reFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not reFolder then
		reFolder = Instance.new("Folder")
		reFolder.Name = "RemoteEvents"
		reFolder.Parent = ReplicatedStorage
	end
	local rfFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not rfFolder then
		rfFolder = Instance.new("Folder")
		rfFolder.Name = "RemoteFunctions"
		rfFolder.Parent = ReplicatedStorage
	end

	local function makeRE(name)
		if not reFolder:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = reFolder
		end
	end
	local function makeRF(name)
		if not rfFolder:FindFirstChild(name) then
			local fn = Instance.new("RemoteFunction")
			fn.Name = name
			fn.Parent = rfFolder
		end
	end

	makeRE("BuyUpgrade")
	makeRE("UnlockArea")
	makeRE("SellPet")
	makeRE("UpdatePlayerStats")
	makeRE("OpenShop") -- Assuming your ShopService uses this
	makeRF("PromptPurchase")
	makeRF("GetPlayerData")
end

ensureRemotesExist()

-- Remote references
local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local ShopEvents      = ReplicatedStorage:FindFirstChild("ShopEvents") -- From your ShopService script

local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")
local GetPlayerData     = RemoteFunctions:WaitForChild("GetPlayerData")
local BuyUpgrade        = RemoteEvents:WaitForChild("BuyUpgrade")
local UnlockArea        = RemoteEvents:WaitForChild("UnlockArea")
local SellPet           = RemoteEvents:WaitForChild("SellPet")
local PromptPurchase    = RemoteFunctions:WaitForChild("PromptPurchase")
local OpenShopRemote     = ReplicatedStorage.RemoteEvents:WaitForChild("OpenShop") -- Get from ShopEvents folder

-- Fetch player data
local playerData
local function fetchPlayerData()
	local ok, res = pcall(function()
		return GetPlayerData:InvokeServer()
	end)
	if ok and res then
		playerData = res
	else
		warn("ShopGUI: failed to load player data:", res)
		playerData = {
			coins = 0,
			gems = 0,
			pets = {},
			unlockedAreas = {"Starter Meadow"},
			upgrades = {
				["Collection Speed"] = 1,
				["Pet Capacity"]     = 1,
				["Collection Value"] = 1,
			},
		}
	end
end
fetchPlayerData() -- Initial fetch

-- Static shop definitions
local upgrades = {
	{ name="Collection Speed", baseCost=100, costMultiplier=1.5, maxLevel=10 },
	{ name="Pet Capacity",     baseCost=200, costMultiplier=2.0, maxLevel=5  },
	{ name="Collection Value", baseCost=500, costMultiplier=2.5, maxLevel=10 },
}

local areas = {
	{ name="Starter Meadow", unlockCost=0,    petSpawnRate=3, availablePets={"Common Corgi"} },
	{ name="Mystic Forest",  unlockCost=1000, petSpawnRate=7, availablePets={"Common Corgi","Rare RedPanda"} },
	{ name="Dragon's Lair",  unlockCost=10000,petSpawnRate=10, availablePets={"Rare RedPanda","Epic Corgi","Legendary RedPanda"} },
}

local premiumProducts = {
	{ name="VIP",          type="GamePass",   id=1, description="2x Coins, Exclusive Pets",     price=799 }, -- Placeholder IDs
	{ name="Auto-Collect", type="GamePass",   id=2, description="Automatically collect pets",   price=399 },
	{ name="Small Coins",  type="DevProduct", id=1, description="100 Coins",                    price=49  },
	{ name="Medium Coins", type="DevProduct", id=2, description="550 Coins (10% Bonus)",        price=99  },
	{ name="Large Coins",  type="DevProduct", id=3, description="1200 Coins (20% Bonus)",       price=199 },
}

----------------------------------------
-- GUI CREATION & TEMPLATES
----------------------------------------
local shopGUIInstance = nil -- Holds the single instance of our ShopGUI

local function CreateShopGui()
	shopGUIInstance = player.PlayerGui:FindFirstChild("ShopGUI")
	if shopGUIInstance then
		return shopGUIInstance
	end

	local newShopGUI = Instance.new("ScreenGui")
	newShopGUI.Name = "ShopGUI"
	newShopGUI.Enabled = false
	newShopGUI.ResetOnSpawn = false
	newShopGUI.Parent = player.PlayerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	mainFrame.BorderSizePixel = 1
	mainFrame.BorderColor3 = Color3.fromRGB(20,20,20)
	mainFrame.ClipsDescendants = true -- Good for rounded corners if you add them
	mainFrame.Parent = newShopGUI

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 35)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -40, 1, 0) -- Leave space for close button
	titleLabel.Text = "Shop"
	titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Position = UDim2.new(0, 10, 0, 0) -- Padding from left
	titleLabel.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 35, 1, 0) 
	closeButton.Position = UDim2.new(1, -35, 0, 0) -- Top right
	closeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	closeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.TextSize = 18
	closeButton.Parent = titleBar
	closeButton.ZIndex = 2 -- Ensure it's above other title bar elements if any overlap

	closeButton.MouseEnter:Connect(function() closeButton.BackgroundColor3 = Color3.fromRGB(200,80,80) end)
	closeButton.MouseLeave:Connect(function() closeButton.BackgroundColor3 = Color3.fromRGB(70,70,80) end)
	closeButton.MouseButton1Click:Connect(function()
		if newShopGUI then
			newShopGUI.Enabled = false
		end
	end)

	local tabButtonsFrame = Instance.new("Frame")
	tabButtonsFrame.Name = "TabButtons"
	tabButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
	tabButtonsFrame.Position = UDim2.new(0, 0, 0, 35) -- Below title bar
	tabButtonsFrame.BackgroundTransparency = 1
	tabButtonsFrame.Parent = mainFrame
	local tabListLayout = Instance.new("UIListLayout")
	tabListLayout.FillDirection = Enum.FillDirection.Horizontal
	tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabListLayout.Padding = UDim.new(0, 5)
	tabListLayout.Parent = tabButtonsFrame

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -95) -- Adjusted for padding and other frames
	contentFrame.Position = UDim2.new(0.5, 0, 0, 75 + ( (1 - (1* (1 - (95/mainFrame.AbsoluteSize.Y)))) /2) )  -- Below tabs, with padding
	contentFrame.AnchorPoint = Vector2.new(0.5,0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame

	local statsDisplay = Instance.new("Frame")
	statsDisplay.Name = "StatsDisplay"
	statsDisplay.Size = UDim2.new(1, 0, 0, 30) -- At the bottom
	statsDisplay.Position = UDim2.new(0, 0, 1, -30)
	statsDisplay.BackgroundTransparency = 1
	statsDisplay.Parent = mainFrame
	-- Add CoinsLabel, GemsLabel to statsDisplay here...
	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0.5, -5, 1, 0)
	coinsLabel.Position = UDim2.new(0, 5, 0, 0)
	coinsLabel.Font = Enum.Font.SourceSans
	coinsLabel.TextSize = 16
	coinsLabel.TextColor3 = Color3.fromRGB(255,223,0) -- Gold-ish
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Parent = statsDisplay

	local gemsLabel = Instance.new("TextLabel")
	gemsLabel.Name = "GemsLabel"
	gemsLabel.Size = UDim2.new(0.5, -5, 1, 0)
	gemsLabel.Position = UDim2.new(0.5, 0, 0, 0)
	gemsLabel.Font = Enum.Font.SourceSans
	gemsLabel.TextSize = 16
	gemsLabel.TextColor3 = Color3.fromRGB(0,255,127) -- Gem-like
	gemsLabel.TextXAlignment = Enum.TextXAlignment.Right
	gemsLabel.BackgroundTransparency = 1
	gemsLabel.Parent = statsDisplay


	-- Create tab frames (SellPetsFrame, BuyUpgradesFrame, etc.)
	local tabNames = {"Sell Pets", "Buy Upgrades", "Unlock Areas", "Premium Shop"}
	for i, tabNameString in ipairs(tabNames) do
		-- Tab Button
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tabNameString .. "Button"
		tabButton.Size = UDim2.new(0, 120, 0, 30)
		tabButton.Text = tabNameString
		tabButton.Font = Enum.Font.SourceSans
		tabButton.TextSize = 16
		tabButton.BackgroundColor3 = Color3.fromRGB(60,60,70)
		tabButton.TextColor3 = Color3.fromRGB(200,200,200)
		tabButton.LayoutOrder = i
		tabButton.Parent = tabButtonsFrame

		-- Corresponding Content ScrollingFrame
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Name = string.gsub(tabNameString, " ", "") .. "Frame" -- e.g., SellPetsFrame
		scrollFrame.Size = UDim2.new(1, 0, 1, 0)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.Visible = false -- Hide all initially
		scrollFrame.Parent = contentFrame
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Padding = UDim.new(0,5)
		uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout.Parent = scrollFrame


		tabButton.MouseButton1Click:Connect(function()
			-- Hide all other frames
			for _, child in ipairs(contentFrame:GetChildren()) do
				if child:IsA("ScrollingFrame") then
					child.Visible = false
				end
			end
			-- Show this one
			scrollFrame.Visible = true
			-- Update button appearance
			for _, btn in ipairs(tabButtonsFrame:GetChildren()) do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = Color3.fromRGB(60,60,70) -- Default
					btn.TextColor3 = Color3.fromRGB(200,200,200)
				end
			end
			tabButton.BackgroundColor3 = Color3.fromRGB(80,80,100) -- Active
			tabButton.TextColor3 = Color3.fromRGB(255,255,255)

			-- Refresh content for the now visible tab
			UpdateShopContent(newShopGUI)
		end)
	end

	shopGUIInstance = newShopGUI
	return newShopGUI
end

-- Helper to get the GUI, creating if it doesn't exist
local function GetShopGUI()
	if not shopGUIInstance or not shopGUIInstance.Parent then
		shopGUIInstance = CreateShopGui()
	end
	return shopGUIInstance
end


-- TEMPLATE CREATION FUNCTIONS (should be defined at this level, not nested)
local function CreateSellPetTemplate(petData)
	local template = Instance.new("Frame")
	-- ... configure template based on petData ...
	template.Name = petData.Name .. "Template"
	template.Size = UDim2.new(0.9,0,0,50)
	template.BackgroundColor3 = Color3.fromRGB(55,55,65)
	-- Add TextLabels for pet name, stats, and a Sell button
	return template
end

local function CreateUpgradeTemplate(upgradeInfo, currentLevel)
	local template = Instance.new("Frame")
	-- ... configure template ...
	template.Name = upgradeInfo.name .. "Template"
	template.Size = UDim2.new(0.9,0,0,60)
	template.BackgroundColor3 = Color3.fromRGB(55,55,65)
	-- Add TextLabels for name, level, cost, and a Buy button
	return template
end

local function CreatePremiumTemplate(productInfo)
	local template = Instance.new("Frame")
	-- ... configure template ...
	template.Name = productInfo.name .. "Template"
	template.Size = UDim2.new(0.9,0,0,70)
	template.BackgroundColor3 = Color3.fromRGB(55,55,65)
	-- Add TextLabels for name, description, price, and a Buy button
	return template
end

local function CreateAreaTemplate(areaInfo, isUnlocked)
	local template = Instance.new("Frame")
	-- ... configure template ...
	template.Name = areaInfo.name .. "Template"
	template.Size = UDim2.new(0.9,0,0,60)
	template.BackgroundColor3 = Color3.fromRGB(55,55,65)
	-- Add TextLabels for name, cost (if not unlocked), and an Unlock/Teleport button
	return template
end

----------------------------------------
-- UPDATE STATS
----------------------------------------
local function UpdateShopStats(currentShopGUI) -- Renamed parameter for clarity
	if not currentShopGUI or not currentShopGUI.Parent then return end -- Guard clause
	local PlayerGui = player:WaitForChild("PlayerGui")
	local mainGui    = PlayerGui:WaitForChild("MainGui")
	local statsFrame = mainGui:WaitForChild("StatsFrame")
	local coinsLabel   = statsFrame:FindFirstChild("CoinsLabel")
	local gemsLabel    = statsFrame:FindFirstChild("GemsLabel")
	local petsLabel	= statsFrame:FindFirstChild("PetsLabel")

	if coinsLabel then
		coinsLabel.Text = "Coins: " .. tostring(playerData.coins or 0)
	end
	if gemsLabel then
		gemsLabel.Text = "Gems: "  .. tostring(playerData.gems  or 0)
	end
	if petsLabel then
		petsLabel.Text = "Pets: "  .. tostring(playerData.pets  or 0)
	end
end

----------------------------------------
-- POPULATE TABS
----------------------------------------
local function PopulateSellPetsTab(currentShopGUI)
	if not currentShopGUI or not currentShopGUI.Parent then return end
	local mainFrame      = currentShopGUI:WaitForChild("MainFrame")
	local contentFrame   = mainFrame:WaitForChild("ContentFrame")
	local sellPetsFrame  = contentFrame:WaitForChild("SellPetsFrame")
	if not sellPetsFrame then return end
	sellPetsFrame:ClearAllChildren() -- Clear old items
	-- Add UIListLayout if not present
	if not sellPetsFrame:FindFirstChildOfClass("UIListLayout") then
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0,5)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = sellPetsFrame
	end

	if #playerData.pets == 0 then
		local noPetsLabel = Instance.new("TextLabel")
		noPetsLabel.Name = "NoPetsLabel"
		noPetsLabel.Size = UDim2.new(1,0,0,30)
		noPetsLabel.Text = "You have no pets to sell."
		noPetsLabel.BackgroundTransparency = 1
		noPetsLabel.TextColor3 = Color3.fromRGB(180,180,180)
		noPetsLabel.Parent = sellPetsFrame
		return
	end

	for i, pet in ipairs(playerData.pets) do
		local petTemplate = CreateSellPetTemplate(pet) -- Pass pet data
		petTemplate.LayoutOrder = i
		petTemplate.Parent = sellPetsFrame
		-- Add sell button logic inside CreateSellPetTemplate or here
		local sellButton = petTemplate:FindFirstChild("SellButton") -- Assuming it exists
		if sellButton then
			sellButton.MouseButton1Click:Connect(function()
				SellPet:FireServer(pet.uniqueId) -- Assuming pets have unique IDs
			end)
		end
	end
end

local function PopulateBuyUpgradesTab(currentShopGUI)
	if not currentShopGUI or not currentShopGUI.Parent then return end
	local mainFrame        = currentShopGUI:WaitForChild("MainFrame")
	local contentFrame     = mainFrame:WaitForChild("ContentFrame")
	local buyUpgradesFrame = contentFrame:WaitForChild("BuyUpgradesFrame")
	if not buyUpgradesFrame then return end
	buyUpgradesFrame:ClearAllChildren()
	if not buyUpgradesFrame:FindFirstChildOfClass("UIListLayout") then
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0,5)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = buyUpgradesFrame
	end

	for i, upgradeData in ipairs(upgrades) do
		local currentLevel = playerData.upgrades[upgradeData.name] or 0
		local upgradeTemplate = CreateUpgradeTemplate(upgradeData, currentLevel)
		upgradeTemplate.LayoutOrder = i
		upgradeTemplate.Parent = buyUpgradesFrame
		-- Add buy button logic
		local buyButton = upgradeTemplate:FindFirstChild("BuyButton")
		if buyButton then
			buyButton.MouseButton1Click:Connect(function()
				BuyUpgrade:FireServer(upgradeData.name)
			end)
		end
	end
end

local function PopulatePremiumShopTab(currentShopGUI)
	if not currentShopGUI or not currentShopGUI.Parent then return end
	local mainFrame         = currentShopGUI:WaitForChild("MainFrame")
	local contentFrame      = mainFrame:WaitForChild("ContentFrame")
	local premiumShopFrame  = contentFrame:WaitForChild("PremiumShopFrame")
	if not premiumShopFrame then return end
	premiumShopFrame:ClearAllChildren()
	if not premiumShopFrame:FindFirstChildOfClass("UIListLayout") then
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0,5)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = premiumShopFrame
	end

	for i, productData in ipairs(premiumProducts) do
		local premiumTemplate = CreatePremiumTemplate(productData)
		premiumTemplate.LayoutOrder = i
		premiumTemplate.Parent = premiumShopFrame
		-- Add purchase logic (using PromptPurchase)
		local buyButton = premiumTemplate:FindFirstChild("BuyButton")
		if buyButton then
			buyButton.MouseButton1Click:Connect(function()
				local success, result = pcall(function()
					return PromptPurchase:InvokeServer(productData.type, productData.id)
				end)
				if success then
					print("Purchase prompt result:", result)
				else
					warn("Error prompting purchase:", result)
				end
			end)
		end
	end
end

local function PopulateUnlockAreasTab(currentShopGUI)
	if not currentShopGUI or not currentShopGUI.Parent then return end
	local mainFrame         = currentShopGUI:WaitForChild("MainFrame")
	local contentFrame      = mainFrame:WaitForChild("ContentFrame")
	local unlockAreasFrame  = contentFrame:WaitForChild("UnlockAreasFrame")
	if not unlockAreasFrame then return end
	unlockAreasFrame:ClearAllChildren()
	if not unlockAreasFrame:FindFirstChildOfClass("UIListLayout") then
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0,5)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = unlockAreasFrame
	end

	for i, areaData in ipairs(areas) do
		local isUnlocked = table.find(playerData.unlockedAreas, areaData.name) ~= nil
		local areaTemplate = CreateAreaTemplate(areaData, isUnlocked)
		areaTemplate.LayoutOrder = i
		areaTemplate.Parent = unlockAreasFrame
		-- Add unlock/teleport logic
		local actionButton = areaTemplate:FindFirstChild("ActionButton")
		if actionButton then
			actionButton.MouseButton1Click:Connect(function()
				if not isUnlocked then
					UnlockArea:FireServer(areaData.name)
				else
					-- Implement teleport logic if desired
					print("Teleporting to", areaData.name)
				end
			end)
		end
	end
end

----------------------------------------
-- UPDATE CONTENT BASED ON VISIBLE TAB
----------------------------------------
local function UpdateShopContent(currentShopGUI)
	if not currentShopGUI or not currentShopGUI.Enabled or not currentShopGUI.Parent then return end

	fetchPlayerData() -- Refresh player data before updating UI
	UpdateShopStats(currentShopGUI)

	local playerGui = player:WaitForChild("PlayerGui")
	local shopGui = playerGui:WaitForChild("ShopGui")
	local currentShopGUI = shopGui
	local contentFrame = shopGui:WaitForChild("ContentFrame")
	local visibleTabFrame

	for _, frame in ipairs(contentFrame:GetChildren()) do
		if frame:IsA("ScrollingFrame") and frame.Visible then
			visibleTabFrame = frame
			break
		end
	end

	if not visibleTabFrame then return end

	if visibleTabFrame.Name == "SellPetsFrame" then
		PopulateSellPetsTab(currentShopGUI)
	elseif visibleTabFrame.Name == "BuyUpgradesFrame" then
		PopulateBuyUpgradesTab(currentShopGUI)
	elseif visibleTabFrame.Name == "PremiumShopFrame" then
		PopulatePremiumShopTab(currentShopGUI)
	elseif visibleTabFrame.Name == "UnlockAreasFrame" then
		PopulateUnlockAreasTab(currentShopGUI)
	end
end

----------------------------------------
-- OPEN SHOP FUNCTION
----------------------------------------
local function OpenShop(tabName)
	local currentShopGUI = GetShopGUI() -- Get or create the single instance
	currentShopGUI.Enabled = true

	UpdateShopContent(currentShopGUI) -- This will also update stats and populate the current/default tab

	-- Switch to the specified tab or default
	
	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild("MainGui")
	local guiModules = mainGui:WaitForChild("GuiModules")
	local Tabs = require(guiModules:WaitForChild("Tabs")) -- Requiring the Tabs module for access to tab names
	local tabButtonsFrame = Tabs:WaitForChild("TabButtons") -- Requiring the Tabs module for access to tab names
	local targetTabName = tabName or "Sell Pets" -- Default tab

	local targetButton = tabButtonsFrame:FindFirstChild(targetTabName .. "Button")
	if targetButton and targetButton:IsA("TextButton") then
		-- Simulate click to trigger tab switching logic including UI update and content population
		targetButton.MouseButton1Click:Fire() 
	else
		-- Fallback to the first available button if specified or default is not found
		local firstButton = tabButtonsFrame:FindFirstChildOfClass("TextButton")
		if firstButton then
			firstButton.MouseButton1Click:Fire()
		else
			warn("No tab buttons found to open shop with.")
		end
	end
end

----------------------------------------
-- LISTEN FOR SERVER OPEN SHOP EVENT (from ShopService)
----------------------------------------
-- LISTEN FOR SERVER OPEN SHOP EVENT
if OpenShopRemote then -- Use the corrected variable name
	OpenShopRemote.OnClientEvent:Connect(function(shopType) -- Make sure this matches the server-side event name
		print("ShopGUI: OpenShopRemote received from server with type:", shopType)
		OpenShop(shopType) -- This calls your local OpenShop function
	end)
else
	warn("ShopGUI: Could not find OpenShop RemoteEvent in ReplicatedStorage (or RemoteEvents folder).")
end
----------------------------------------
-- LISTEN FOR DATA UPDATES
----------------------------------------
UpdatePlayerStats.OnClientEvent:Connect(function(newData)
	if newData then
		playerData = newData
		local currentShopGUI = GetShopGUI() -- Get the instance
		if currentShopGUI and currentShopGUI.Enabled and currentShopGUI.Parent then
			UpdateShopContent(currentShopGUI)
		end
	else
		warn("ShopGUI: received nil playerData from UpdatePlayerStats event")
	end
end)

----------------------------------------
-- KEYBIND FOR OPEN/CLOSE (Toggle)
----------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.B then
		local currentShopGUI = GetShopGUI()
		currentShopGUI.Enabled = not currentShopGUI.Enabled -- Toggle visibility
		if currentShopGUI.Enabled then
			OpenShop() -- Call OpenShop to refresh content and select default tab
		end
	end
end)

----------------------------------------
-- INITIALIZE
----------------------------------------
-- Ensure the GUI is created when the script runs, if not already handled by PlayerGui loading.
-- The GetShopGUI() call at the top or in OpenShop/Keybind handles creation.
-- No need for the spawn block here if SetupShopTouchPart is server-side.
-- If SetupShopTouchPart was meant to be client-side for some reason, it would need separate handling.

print("ShopGUI LocalScript loaded!")

-- Make sure the GUI is created at least once.
GetShopGUI()