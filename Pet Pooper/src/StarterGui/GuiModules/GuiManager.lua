-- Updated GuiManager.lua (ModuleScript)
-- Now uses ModuleLoader for safer module loading
-- Place in StarterGui/MainGui/GuiModules/GuiManager.lua

local GuiManager = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- References
local player = Players.LocalPlayer
local mainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")

-- Use ModuleLoader for safer module loading
local ModuleLoader = require(script.Parent.Utility.ModuleLoader)

-- Load utility modules
local NotificationManager = ModuleLoader.LoadModule(script.Parent.Utility.NotificationManager)
local ViewportRenderer = ModuleLoader.LoadModule(script.Parent.Utility.ViewportRenderer)
local DataManager = ModuleLoader.LoadModule(script.Parent.Utility.DataManager)
local RemoteManager = ModuleLoader.LoadModule(script.Parent.Utility.RemoteManager)
local ShopManager = ModuleLoader.LoadModule(script.Parent.Utility.ShopManager, true) -- Optional

-- Load tab modules
local InventoryTab = ModuleLoader.LoadModule(script.Parent.Tabs.InventoryTab)
local UpgradesTab = ModuleLoader.LoadModule(script.Parent.Tabs.UpgradesTab)
local AreasTab = ModuleLoader.LoadModule(script.Parent.Tabs.AreasTab)
local ShopTab = ModuleLoader.LoadModule(script.Parent.Tabs.ShopTab)

-- UI state
local uiVisible = true
local currentTab = "Inventory"
local playerData = {}

-- Tab configuration
local tabs = {
	Inventory = {
		module = InventoryTab,
		initialized = false
	},
	Upgrades = {
		module = UpgradesTab,
		initialized = false
	},
	Areas = {
		module = AreasTab,
		initialized = false
	},
	Shop = {
		module = ShopTab,
		initialized = false
	}
}

-- Ensure GUI structure exists
local function ensureGuiStructure()
	-- Check if basic structure exists
	local topBar = mainGui:FindFirstChild("TopBar")
	local statsFrame = mainGui:FindFirstChild("StatsFrame")
	local buttonsFrame = mainGui:FindFirstChild("ButtonsFrame")
	local contentFrame = mainGui:FindFirstChild("ContentFrame")

	-- If any are missing, create them
	if not topBar then
		topBar = Instance.new("Frame")
		topBar.Name = "TopBar"
		topBar.Size = UDim2.new(1, 0, 0, 50)
		topBar.Position = UDim2.new(0, 0, 0, 0)
		topBar.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
		topBar.BorderSizePixel = 0
		topBar.Parent = mainGui

		-- Add game title
		local gameTitle = Instance.new("TextLabel")
		gameTitle.Name = "GameTitle"
		gameTitle.Size = UDim2.new(0, 300, 0, 40)
		gameTitle.Position = UDim2.new(0.5, -150, 0.5, -20)
		gameTitle.Text = "Pet Collection Simulator"
		gameTitle.TextSize = 24
		gameTitle.Font = Enum.Font.GothamBold
		gameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		gameTitle.BackgroundTransparency = 1
		gameTitle.Parent = topBar

		-- Add toggle button
		local toggleButton = Instance.new("TextButton")
		toggleButton.Name = "ToggleButton"
		toggleButton.Size = UDim2.new(0, 40, 0, 40)
		toggleButton.Position = UDim2.new(1, -50, 0.5, -20)
		toggleButton.Text = "X"
		toggleButton.TextSize = 20
		toggleButton.Font = Enum.Font.GothamBold
		toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		toggleButton.BorderSizePixel = 0
		toggleButton.Parent = topBar
	end

	if not statsFrame then
		statsFrame = Instance.new("Frame")
		statsFrame.Name = "StatsFrame"
		statsFrame.Size = UDim2.new(0, 300, 0, 100)
		statsFrame.Position = UDim2.new(0, 10, 0, 60)
		statsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		statsFrame.BackgroundTransparency = 0.5
		statsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		statsFrame.BorderSizePixel = 2
		statsFrame.Parent = mainGui

		-- Create stat labels
		local function createStatLabel(name, position, color)
			local label = Instance.new("TextLabel")
			label.Name = name
			label.Size = UDim2.new(1, -20, 0, 30)
			label.Position = UDim2.new(0, 10, 0, position)
			label.Text = name:gsub("Label", "") .. ": 0"
			label.TextSize = 18
			label.Font = Enum.Font.BungeeInline
			label.TextColor3 = color
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.BackgroundTransparency = 1
			label.Parent = statsFrame
			return label
		end

		createStatLabel("CoinsLabel", 5, Color3.fromRGB(255, 215, 0))
		createStatLabel("GemsLabel", 35, Color3.fromRGB(0, 255, 255))
		createStatLabel("PetsLabel", 65, Color3.fromRGB(170, 0, 170))
	end

	if not buttonsFrame then
		buttonsFrame = Instance.new("Frame")
		buttonsFrame.Name = "ButtonsFrame"
		buttonsFrame.Size = UDim2.new(1, 0, 0, 50)
		buttonsFrame.Position = UDim2.new(0, 0, 0, 170)
		buttonsFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		buttonsFrame.BorderSizePixel = 0
		buttonsFrame.Parent = mainGui

		-- Create tab buttons
		local buttonNames = {"Inventory", "Upgrades", "Areas", "Shop"}
		for i, name in ipairs(buttonNames) do
			local button = Instance.new("TextButton")
			button.Name = name .. "Button"
			button.Size = UDim2.new(0.25, -10, 1, -10)
			button.Position = UDim2.new((i-1) * 0.25, 5, 0, 5)
			button.Text = name
			button.TextSize = 16
			button.Font = Enum.Font.GothamBold
			button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.BorderSizePixel = 0
			button.Parent = buttonsFrame
		end
	end

	if not contentFrame then
		contentFrame = Instance.new("Frame")
		contentFrame.Name = "ContentFrame"
		contentFrame.Size = UDim2.new(1, -20, 1, -230)
		contentFrame.Position = UDim2.new(0, 10, 0, 230)
		contentFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		contentFrame.BackgroundTransparency = 0.5
		contentFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		contentFrame.BorderSizePixel = 2
		contentFrame.Parent = mainGui
	end
end

-- Initialize the GUI Manager
function GuiManager.Initialize()
	print("Initializing GUI Manager...")

	-- Ensure basic GUI structure exists
	ensureGuiStructure()

	-- Initialize utility modules
	if RemoteManager then RemoteManager.Initialize() end
	if NotificationManager then NotificationManager.Initialize(mainGui) end
	if ViewportRenderer then ViewportRenderer.Initialize() end
	if ShopManager then ShopManager.Initialize() end

	-- Initialize data manager with update callback
	if DataManager then
		DataManager.Initialize(function(newData)
			playerData = newData
			GuiManager.UpdateStats()
			GuiManager.UpdateCurrentTab()
		end)

		-- Get initial player data
		DataManager.GetPlayerData():andThen(function(data)
			playerData = data
			GuiManager.UpdateStats()
		end):catch(function(err)
			warn("Failed to get initial player data:", err)
			-- Use default fallback data
			playerData = {
				coins = 0,
				gems = 0,
				pets = {},
				unlockedAreas = {"Starter Meadow"},
				upgrades = {
					["Collection Speed"] = 1,
					["Pet Capacity"] = 1,
					["Collection Value"] = 1
				}
			}
			GuiManager.UpdateStats()
		end)
	end

	-- Connect UI events
	GuiManager.ConnectButtons()

	-- Show default tab
	GuiManager.SwitchTab("Inventory")

	print("GUI Manager initialization complete!")
end

-- Toggle UI visibility
function GuiManager.ToggleUIVisibility()
	uiVisible = not uiVisible

	local buttonsFrame = mainGui:FindFirstChild("ButtonsFrame")
	local contentFrame = mainGui:FindFirstChild("ContentFrame")
	local toggleButton = mainGui:FindFirstChild("TopBar") and mainGui.TopBar:FindFirstChild("ToggleButton")

	-- Toggle visibility
	if buttonsFrame then buttonsFrame.Visible = uiVisible end
	if contentFrame then contentFrame.Visible = uiVisible end

	-- Update toggle button appearance
	if toggleButton then
		if uiVisible then
			toggleButton.Text = "X"
			toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		else
			toggleButton.Text = "≡"
			toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		end
	end
end

-- Update player stats display
function GuiManager.UpdateStats()
	local statsFrame = mainGui:FindFirstChild("StatsFrame")
	if not statsFrame then return end

	local coinsLabel = statsFrame:FindFirstChild("CoinsLabel")
	local gemsLabel = statsFrame:FindFirstChild("GemsLabel")
	local petsLabel = statsFrame:FindFirstChild("PetsLabel")

	if coinsLabel then
		coinsLabel.Text = "Coins: " .. (playerData.coins or 0)
	end

	if gemsLabel then
		gemsLabel.Text = "Gems: " .. (playerData.gems or 0)
	end

	if petsLabel then
		petsLabel.Text = "Pets: " .. (#(playerData.pets or {})) .. "/100"
	end
end

-- Switch to a specific tab
function GuiManager.SwitchTab(tabName)
	-- Show UI if hidden
	if not uiVisible then
		GuiManager.ToggleUIVisibility()
	end

	-- Check if tab exists
	if not tabs[tabName] then
		warn("Tab doesn't exist: " .. tabName)
		return
	end

	print("Switching to tab: " .. tabName)

	-- Update button states
	local buttonsFrame = mainGui:FindFirstChild("ButtonsFrame")
	if buttonsFrame then
		for _, button in pairs(buttonsFrame:GetChildren()) do
			if button:IsA("TextButton") then
				if button.Name == tabName .. "Button" then
					button.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Active
				else
					button.BackgroundColor3 = Color3.fromRGB(0, 120, 215) -- Inactive
				end
			end
		end
	end

	-- Get or create tab frame
	local contentFrame = mainGui:FindFirstChild("ContentFrame")
	if not contentFrame then return end

	-- Hide all existing tab frames
	for _, child in pairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:find("Frame") then
			child.Visible = false
		end
	end

	-- Get or create the specific tab frame
	local tabFrame = contentFrame:FindFirstChild(tabName .. "Frame")
	if not tabFrame then
		tabFrame = Instance.new("Frame")
		tabFrame.Name = tabName .. "Frame"
		tabFrame.Size = UDim2.new(1, -20, 1, -20)
		tabFrame.Position = UDim2.new(0, 10, 0, 10)
		tabFrame.BackgroundTransparency = 1
		tabFrame.Parent = contentFrame
	end

	-- Show the tab frame
	tabFrame.Visible = true

	-- Initialize tab if needed
	local tab = tabs[tabName]
	if tab and tab.module and not tab.initialized then
		local success, err = pcall(function()
			tab.module.Initialize(tabFrame, playerData)
		end)

		if success then
			tab.initialized = true
		else
			warn("Failed to initialize " .. tabName .. " tab:", err)
		end
	end

	-- Update tab content
	if tab and tab.module and tab.initialized then
		local success, err = pcall(function()
			tab.module.Update(playerData)
		end)

		if not success then
			warn("Failed to update " .. tabName .. " tab:", err)
		end
	end

	-- Set current tab
	currentTab = tabName
end

-- Update current tab
function GuiManager.UpdateCurrentTab()
	GuiManager.SwitchTab(currentTab)
end

-- Connect UI event handlers
function GuiManager.ConnectButtons()
	local buttonsFrame = mainGui:FindFirstChild("ButtonsFrame")
	local toggleButton = mainGui:FindFirstChild("TopBar") and mainGui.TopBar:FindFirstChild("ToggleButton")

	-- Connect tab buttons
	if buttonsFrame then
		for tabName, _ in pairs(tabs) do
			local button = buttonsFrame:FindFirstChild(tabName .. "Button")
			if button then
				button.MouseButton1Click:Connect(function()
					GuiManager.SwitchTab(tabName)
				end)
			end
		end
	end

	-- Connect toggle button
	if toggleButton then
		toggleButton.MouseButton1Click:Connect(function()
			GuiManager.ToggleUIVisibility()
		end)
	end

	-- Add keyboard shortcut
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.H then
			GuiManager.ToggleUIVisibility()
		end
	end)
end

-- Get current player data
function GuiManager.GetPlayerData()
	return playerData
end

-- Cleanup function (for development/testing)
function GuiManager.Cleanup()
	-- Clear module cache
	ModuleLoader.ClearCache()

	-- Reset state
	uiVisible = true
	currentTab = "Inventory"
	playerData = {}

	-- Reset tab states
	for _, tab in pairs(tabs) do
		tab.initialized = false
	end
end

return GuiManager