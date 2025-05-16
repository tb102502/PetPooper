-- GuiManager.lua (ModuleScript)
-- Place in StarterGui/MainGui/GuiModules/GuiManager.lua

local GuiManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- References
local player = Players.LocalPlayer
local mainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- Module imports
local InventoryTab = require(script.Parent.Tabs.InventoryTab)
local UpgradesTab = require(script.Parent.Tabs.UpgradesTab)
local AreasTab = require(script.Parent.Tabs.AreasTab)
local ShopTab = require(script.Parent.Tabs.ShopTab)
local NotificationManager = require(script.Parent.Utility.NotificationManager)
local ViewportRenderer = require(script.Parent.Utility.ViewportRenderer)

-- UI References
local topBar = mainGui:WaitForChild("TopBar")
local statsFrame = mainGui:WaitForChild("StatsFrame")
local playerGui = game:GetService("StarterGui")
local shopGui = playerGui:WaitForChild("ShopGui")
local buttonsFrame = topBar:WaitForChild("ButtonsFrame")
local contentFrame = shopGui:WaitForChild("ContentFrame")

-- Tab frames and buttons
local tabs = {
	Inventory = {
		button = buttonsFrame:WaitForChild("InventoryButton"),
		frame = topBar:WaitForChild("InventoryFrame"),
		module = InventoryTab,
		initialized = false
	},
	Upgrades = {
		button = buttonsFrame:WaitForChild("UpgradesButton"),
		frame = contentFrame:WaitForChild("UpgradesFrame"),
		module = UpgradesTab,
		initialized = false
	},
	Areas = {
		button = buttonsFrame:WaitForChild("AreasButton"),
		frame = contentFrame:WaitForChild("AreasFrame"),
		module = AreasTab,
		initialized = false
	},
	Shop = {
		button = buttonsFrame:WaitForChild("ShopButton"),
		frame = contentFrame:WaitForChild("ShopFrame"),
		module = ShopTab,
		initialized = false
	}
}

-- Stats labels
local coinsLabel = statsFrame:WaitForChild("CoinsLabel")
local gemsLabel = statsFrame:WaitForChild("GemsLabel")
local petsLabel = statsFrame:WaitForChild("PetsLabel")

-- Toggle Button
local toggleButton = topBar:WaitForChild("ToggleButton")

-- State management
local uiVisible = true
local currentTab = "Inventory"
local playerData = {}

-- Initialize the remote connections
function GuiManager.InitRemotes()
	-- Get player data remote function
	local GetPlayerData = remoteFunctions:WaitForChild("GetPlayerData")
	local UpdatePlayerStats = remoteEvents:WaitForChild("UpdatePlayerStats")

	-- Load initial player data
	local success, result = pcall(function()
		return GetPlayerData:InvokeServer()
	end)

	if success and result then
		playerData = result
		print("GUI: Successfully loaded player data with " .. #playerData.pets .. " pets")
	else
		warn("Failed to get player data: " .. tostring(result))
		-- Create default player data as fallback
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
	end

	-- Listen for player data updates
	UpdatePlayerStats.OnClientEvent:Connect(function(newData)
		if newData then
			print("Received updated player data with " .. #newData.pets .. " pets")
			playerData = newData

			-- Update stats
			GuiManager.UpdateStats()

			-- Update current tab
			GuiManager.UpdateCurrentTab()
		else
			warn("Received nil playerData in UpdatePlayerStats event")
		end
	end)

	-- Set up notification handler
	NotificationManager.Initialize(mainGui)
	local SendNotification = remoteEvents:WaitForChild("SendNotification", 10)
	if SendNotification then
		SendNotification.OnClientEvent:Connect(function(title, message, iconType)
			NotificationManager.ShowNotification(title, message, iconType)
		end)
	end
end

-- Toggle UI visibility
function GuiManager.ToggleUIVisibility()
	uiVisible = not uiVisible

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

	-- Toggle mini info display if it exists
	local miniInfo = mainGui:FindFirstChild("MiniInfo")
	if miniInfo then
		miniInfo.Visible = not uiVisible

		-- Update mini info text if needed
		if not uiVisible and miniInfo:FindFirstChild("MiniCoinsText") then
			miniInfo.MiniCoinsText.Text = tostring(playerData.coins) .. " 🪙"
		end
	end
end

-- Update player stats display
function GuiManager.UpdateStats()
	if coinsLabel then
		coinsLabel.Text = "Coins: " .. (playerData.coins or 0)
	end

	if gemsLabel then
		gemsLabel.Text = "Gems: " .. (playerData.gems or 0)
	end

	if petsLabel then
		petsLabel.Text = "Pets: " .. (#playerData.pets or 0) .. "/100" -- Assuming max 100 pets
	end
end

-- Switch to a specific tab
function GuiManager.SwitchTab(tabName)
	-- Show UI if it's hidden
	if not uiVisible then
		GuiManager.ToggleUIVisibility()
	end

	-- Do nothing if tab doesn't exist
	if not tabs[tabName] then
		warn("Tab doesn't exist: " .. tabName)
		return
	end

	print("Switching to tab: " .. tabName)

	-- Hide all tab frames and reset button colors
	for name, tab in pairs(tabs) do
		if tab.frame then tab.frame.Visible = false end
		if tab.button then tab.button.BackgroundColor3 = Color3.fromRGB(0, 120, 215) end
	end

	-- Show selected tab and highlight button
	local tab = tabs[tabName]
	if tab.frame then tab.frame.Visible = true end
	if tab.button then tab.button.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end

	-- Initialize tab if needed
	if not tab.initialized then
		tab.module.Initialize(tab.frame, playerData)
		tab.initialized = true
	end

	-- Update tab content
	tab.module.Update(playerData)

	-- Set current tab
	currentTab = tabName
end

-- Update current tab
function GuiManager.UpdateCurrentTab()
	if tabs[currentTab] then
		tabs[currentTab].module.Update(playerData)
	end
end

-- Get player data
function GuiManager.GetPlayerData()
	return playerData
end

-- Connect tab buttons
function GuiManager.ConnectButtons()
	-- Connect tab buttons
	for name, tab in pairs(tabs) do
		if tab.button then
			tab.button.MouseButton1Click:Connect(function()
				GuiManager.SwitchTab(name)
			end)
		end
	end

	-- Connect toggle button
	if toggleButton then
		toggleButton.MouseButton1Click:Connect(function()
			GuiManager.ToggleUIVisibility()
		end)
	end

	-- Add keyboard shortcut for toggling UI
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.H then
			-- H key to toggle UI visibility
			GuiManager.ToggleUIVisibility()
		end
	end)
end

-- Initialize the GUI
function GuiManager.Initialize()
	print("Initializing GUI Manager...")

	-- Initialize remote connections
	GuiManager.InitRemotes()

	-- Initialize ViewportRenderer utility
	ViewportRenderer.Initialize()

	-- Connect buttons
	GuiManager.ConnectButtons()

	-- Update stats
	GuiManager.UpdateStats()

	-- Show the default tab (Inventory)
	GuiManager.SwitchTab("Inventory")

	print("GUI Manager initialization complete!")
end

return GuiManager