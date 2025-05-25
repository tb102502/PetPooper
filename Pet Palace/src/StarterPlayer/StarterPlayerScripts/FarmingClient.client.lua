-- FarmingClient.client.lua
-- Place in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Load modules
local FarmingSeeds = require(ReplicatedStorage:WaitForChild("FarmingSeeds"))

-- Get remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlantSeed = RemoteEvents:WaitForChild("PlantSeed")
local HarvestPlant = RemoteEvents:WaitForChild("HarvestPlant")
local FeedPig = RemoteEvents:WaitForChild("FeedPig")
local GetFarmingData = RemoteEvents:WaitForChild("GetFarmingData")

-- Player data
local playerFarmingData = {
	inventory = {},
	pig = { feedCount = 0, size = 1 }
}

-- Currently selected items
local selectedSeed = nil
local selectedCrop = nil

-- UI References
local farmingUI = nil
local inventoryFrame = nil

-- Create notification
local function showNotification(title, message, color)
	local playerGui = player:WaitForChild("PlayerGui")

	local notification = playerGui:FindFirstChild("FarmingNotification")
	if notification then notification:Destroy() end

	notification = Instance.new("ScreenGui")
	notification.Name = "FarmingNotification"
	notification.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 80)
	frame.Position = UDim2.new(0.5, -150, 0.1, 0)
	frame.BackgroundColor3 = color or Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = notification

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, 0, 0.5, 0)
	messageLabel.Position = UDim2.new(0, 0, 0.5, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	messageLabel.TextSize = 12
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.Parent = frame

	-- Auto-hide after 3 seconds
	spawn(function()
		wait(3)
		if notification then notification:Destroy() end
	end)
end

-- Update inventory display
local function updateInventoryUI()
	if not inventoryFrame or not inventoryFrame.Visible then return end

	local container = inventoryFrame:FindFirstChild("Container")
	if not container then return end

	-- Clear existing items
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "ListLayout" then
			child:Destroy()
		end
	end

	-- Seeds section
	local seedsTitle = Instance.new("TextLabel")
	seedsTitle.Name = "SeedsTitle"
	seedsTitle.Size = UDim2.new(1, 0, 0, 30)
	seedsTitle.BackgroundColor3 = Color3.fromRGB(60, 100, 40)
	seedsTitle.Text = "🌱 SEEDS"
	seedsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	seedsTitle.TextSize = 14
	seedsTitle.Font = Enum.Font.GothamBold
	seedsTitle.Parent = container

	-- Add seed items
	for _, seed in ipairs(FarmingSeeds.Seeds) do
		local quantity = playerFarmingData.inventory[seed.ID] or 0
		if quantity > 0 then
			local itemFrame = Instance.new("Frame")
			itemFrame.Name = seed.ID .. "_Frame"
			itemFrame.Size = UDim2.new(1, 0, 0, 40)
			itemFrame.BackgroundColor3 = selectedSeed == seed.ID and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(60, 60, 60)
			itemFrame.Parent = container

			local itemLabel = Instance.new("TextLabel")
			itemLabel.Size = UDim2.new(0.7, 0, 1, 0)
			itemLabel.Position = UDim2.new(0, 10, 0, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.Text = seed.Name .. " x" .. quantity
			itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemLabel.TextSize = 12
			itemLabel.Font = Enum.Font.Gotham
			itemLabel.TextXAlignment = Enum.TextXAlignment.Left
			itemLabel.Parent = itemFrame

			local selectButton = Instance.new("TextButton")
			selectButton.Size = UDim2.new(0.25, 0, 0.8, 0)
			selectButton.Position = UDim2.new(0.73, 0, 0.1, 0)
			selectButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
			selectButton.Text = selectedSeed == seed.ID and "✓" or "Select"
			selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			selectButton.TextSize = 10
			selectButton.Font = Enum.Font.GothamBold
			selectButton.Parent = itemFrame

			selectButton.MouseButton1Click:Connect(function()
				if selectedSeed == seed.ID then
					selectedSeed = nil
				else
					selectedSeed = seed.ID
				end
				selectedCrop = nil
				updateInventoryUI()
				if selectedSeed then
					showNotification("Seed Selected", seed.Name .. " selected for planting", Color3.fromRGB(60, 100, 40))
				else
					showNotification("Seed Deselected", "No seed selected", Color3.fromRGB(60, 100, 40))
				end
			end)
		end
	end

	-- Crops section
	local cropsTitle = Instance.new("TextLabel")
	cropsTitle.Name = "CropsTitle"
	cropsTitle.Size = UDim2.new(1, 0, 0, 30)
	cropsTitle.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
	cropsTitle.Text = "🥕 CROPS"
	cropsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	cropsTitle.TextSize = 14
	cropsTitle.Font = Enum.Font.GothamBold
	cropsTitle.Parent = container

	-- Add crop items
	for _, crop in ipairs(FarmingSeeds.Crops) do
		local quantity = playerFarmingData.inventory[crop.ID] or 0
		if quantity > 0 then
			local itemFrame = Instance.new("Frame")
			itemFrame.Name = crop.ID .. "_Frame"
			itemFrame.Size = UDim2.new(1, 0, 0, 40)
			itemFrame.BackgroundColor3 = selectedCrop == crop.ID and Color3.fromRGB(140, 100, 60) or Color3.fromRGB(60, 60, 60)
			itemFrame.Parent = container

			local itemLabel = Instance.new("TextLabel")
			itemLabel.Size = UDim2.new(0.7, 0, 1, 0)
			itemLabel.Position = UDim2.new(0, 10, 0, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.Text = crop.Name .. " x" .. quantity
			itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemLabel.TextSize = 12
			itemLabel.Font = Enum.Font.Gotham
			itemLabel.TextXAlignment = Enum.TextXAlignment.Left
			itemLabel.Parent = itemFrame

			local feedButton = Instance.new("TextButton")
			feedButton.Size = UDim2.new(0.25, 0, 0.8, 0)
			feedButton.Position = UDim2.new(0.73, 0, 0.1, 0)
			feedButton.BackgroundColor3 = Color3.fromRGB(180, 100, 60)
			feedButton.Text = "Feed Pig"
			feedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			feedButton.TextSize = 10
			feedButton.Font = Enum.Font.GothamBold
			feedButton.Parent = itemFrame

			feedButton.MouseButton1Click:Connect(function()
				FeedPig:FireServer(crop.ID)
			end)
		end
	end

	-- Pig info section
	local pigTitle = Instance.new("TextLabel")
	pigTitle.Name = "PigTitle"
	pigTitle.Size = UDim2.new(1, 0, 0, 30)
	pigTitle.BackgroundColor3 = Color3.fromRGB(180, 120, 160)
	pigTitle.Text = "🐷 PIG STATUS"
	pigTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	pigTitle.TextSize = 14
	pigTitle.Font = Enum.Font.GothamBold
	pigTitle.Parent = container

	local pigInfo = Instance.new("TextLabel")
	pigInfo.Name = "PigInfo"
	pigInfo.Size = UDim2.new(1, 0, 0, 50)
	pigInfo.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	local feedCount = playerFarmingData.pig.feedCount or 0
	local size = playerFarmingData.pig.size or 1
	local nextGrowth = 10 - (feedCount % 10)
	pigInfo.Text = "Fed: " .. feedCount .. " times\nSize: " .. string.format("%.1f", size) .. "x\nNext growth: " .. nextGrowth .. " more feeds"
	pigInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
	pigInfo.TextSize = 12
	pigInfo.Font = Enum.Font.Gotham
	pigInfo.Parent = container
end

-- Setup farming UI
local function setupFarmingUI()
	local playerGui = player:WaitForChild("PlayerGui")

	farmingUI = Instance.new("ScreenGui")
	farmingUI.Name = "FarmingUI"
	farmingUI.ResetOnSpawn = false
	farmingUI.Parent = playerGui

	-- Main toggle button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "FarmingButton"
	toggleButton.Size = UDim2.new(0, 120, 0, 40)
	toggleButton.Position = UDim2.new(0, 20, 0.7, 0)
	toggleButton.BackgroundColor3 = Color3.fromRGB(60, 100, 40)
	toggleButton.Text = "🌾 Farming"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 14
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Parent = farmingUI

	-- Inventory frame
	inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0, 300, 0, 500)
	inventoryFrame.Position = UDim2.new(0, 150, 0.5, -250)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Visible = false
	inventoryFrame.Parent = farmingUI

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	titleBar.Parent = inventoryFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🌾 Farming Inventory"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar

	-- Container
	local container = Instance.new("ScrollingFrame")
	container.Name = "Container"
	container.Size = UDim2.new(1, -20, 1, -50)
	container.Position = UDim2.new(0, 10, 0, 45)
	container.BackgroundTransparency = 1
	container.ScrollBarThickness = 6
	container.CanvasSize = UDim2.new(0, 0, 0, 0)
	container.Parent = inventoryFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Name = "ListLayout"
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = container

	-- Update canvas size when content changes
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		container.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Button events
	toggleButton.MouseButton1Click:Connect(function()
		inventoryFrame.Visible = not inventoryFrame.Visible
		if inventoryFrame.Visible then
			updateInventoryUI()
		end
	end)

	closeButton.MouseButton1Click:Connect(function()
		inventoryFrame.Visible = false
	end)
end

-- Handle farm plot interactions
local function setupFarmInteraction()
	mouse.Button1Down:Connect(function()
		local target = mouse.Target
		if not target then return end

		local plot = nil
		if target.Name == "Soil" then
			plot = target.Parent
		end

		if plot and plot.Name:match("FarmPlot_") then
			local plotID = tonumber(plot.Name:match("FarmPlot_(%d+)"))
			if not plotID then return end

			if plot:GetAttribute("IsPlanted") then
				-- Check if ready to harvest
				local growthStage = plot:GetAttribute("GrowthStage") or 0
				if growthStage >= 4 then
					HarvestPlant:FireServer(plotID)
				else
					local progress = math.floor((growthStage / 4) * 100)
					showNotification("Plant Growing", "Growth: " .. progress .. "% (Stage " .. growthStage .. "/4)", Color3.fromRGB(100, 150, 100))
				end
			else
				-- Plant seed if selected
				if selectedSeed then
					PlantSeed:FireServer(plotID, selectedSeed)
				else
					showNotification("No Seed Selected", "Select a seed from your inventory first!", Color3.fromRGB(200, 100, 40))
				end
			end
		end
	end)
end

-- Handle data updates from both farming and main currency systems
GetFarmingData.OnClientEvent:Connect(function(data)
	playerFarmingData = data
	updateInventoryUI()
end)

-- Listen for main player stats updates (from existing shop system)
local UpdatePlayerStats = RemoteEvents:FindFirstChild("UpdatePlayerStats")
if UpdatePlayerStats then
	UpdatePlayerStats.OnClientEvent:Connect(function(data)
		-- Merge farming data if it exists
		if data.farming then
			for key, value in pairs(data.farming) do
				playerFarmingData[key] = value
			end
		end

		-- Update currency info
		if data.coins then playerFarmingData.coins = data.coins end
		if data.gems then playerFarmingData.gems = data.gems end

		updateInventoryUI()
	end)
end

-- Listen for currency updates
local CurrencyUpdated = RemoteEvents:FindFirstChild("CurrencyUpdated")
if CurrencyUpdated then
	CurrencyUpdated.OnClientEvent:Connect(function(currencyData)
		for currency, amount in pairs(currencyData) do
			playerFarmingData[currency:lower()] = amount
		end
	end)
end

-- Initialize
setupFarmingUI()
setupFarmInteraction()

-- Request initial data
player.CharacterAdded:Connect(function()
	wait(1)
	GetFarmingData:FireServer()
end)

if player.Character then
	GetFarmingData:FireServer()
end

print("Farming Client Loaded!")