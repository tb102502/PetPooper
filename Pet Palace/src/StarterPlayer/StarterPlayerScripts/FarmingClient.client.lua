-- FarmingClient.client.lua
-- Place in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()

-- Forward function declarations to resolve unknown global issue
local updateInventoryUI
local showPetSelectionUI

-- Ensure Modules folder exists
if not ReplicatedStorage:FindFirstChild("Modules") then
	local modulesFolder = Instance.new("Folder")
	modulesFolder.Name = "Modules"
	modulesFolder.Parent = ReplicatedStorage
	print("Created Modules folder in ReplicatedStorage")
end

-- Try to load FarmingSeeds module
local FarmingSeeds
local success = pcall(function()
	FarmingSeeds = require(ReplicatedStorage:WaitForChild("FarmingSeeds", 5))
end)

if not success then
	-- Create a basic FarmingSeeds module if it doesn't exist
	print("Creating FarmingSeeds module...")
	local farmingSeedsModule = Instance.new("ModuleScript")
	farmingSeedsModule.Name = "FarmingSeeds"

	farmingSeedsModule.Source = [[
    -- FarmingSeeds.lua
    return {
        Seeds = {
            {
                ID = "carrot_seeds",
                Name = "Carrot Seeds",
                Price = 20,
                Currency = "Coins",
                Type = "Seed",
                ImageId = "rbxassetid://6686038519",
                Description = "Plant these to grow carrots! Grows in 60 seconds.",
                GrowTime = 60,
                YieldAmount = 1,
                ResultID = "carrot",
                FeedValue = 1
            },
            {
                ID = "corn_seeds",
                Name = "Corn Seeds",
                Price = 50,
                Currency = "Coins",
                Type = "Seed",
                ImageId = "rbxassetid://6686045507",
                Description = "Plant these to grow corn! Grows in 120 seconds.",
                GrowTime = 120,
                YieldAmount = 3,
                ResultID = "corn",
                FeedValue = 2
            }
        ],
        Crops = {
            {
                ID = "carrot",
                Name = "Carrot",
                ImageId = "rbxassetid://6686041557",
                Description = "A freshly grown carrot! Feed it to your pet.",
                FeedValue = 1,
                SellValue = 30
            },
            {
                ID = "corn",
                Name = "Corn",
                ImageId = "rbxassetid://6686047557",
                Description = "Fresh corn! Feed it to your pet.",
                FeedValue = 2,
                SellValue = 75
            }
        }
    }
    ]]

	farmingSeedsModule.Parent = ReplicatedStorage
	FarmingSeeds = require(farmingSeedsModule)
	print("Created and loaded FarmingSeeds module")
end

-- Reference remote events
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
	print("Created RemoteEvents folder in ReplicatedStorage")
end

-- Create remote events if they don't exist
local function ensureRemoteEventExists(name)
	if not RemoteEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = RemoteEvents
		print("Created missing RemoteEvent: " .. name)
	end
	return RemoteEvents:FindFirstChild(name)
end

local BuySeed = ensureRemoteEventExists("BuySeed")
local PlantSeed = ensureRemoteEventExists("PlantSeed")
local HarvestPlant = ensureRemoteEventExists("HarvestPlant")
local FeedPet = ensureRemoteEventExists("FeedPet")
local GetFarmingData = ensureRemoteEventExists("GetFarmingData")

-- Player data
local playerFarmingData = {
	inventory = {},
	unlockedPlots = 0
}

-- Currently selected seed
local selectedSeed = nil

-- Show pet selection UI for feeding
showPetSelectionUI = function(cropID)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Create pet selection UI
	local petSelectionUI = playerGui:FindFirstChild("PetSelectionUI")
	if petSelectionUI then
		petSelectionUI:Destroy()
	end

	petSelectionUI = Instance.new("ScreenGui")
	petSelectionUI.Name = "PetSelectionUI"
	petSelectionUI.ResetOnSpawn = false
	petSelectionUI.Parent = playerGui

	-- Create background frame
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.new(0, 300, 0, 400)
	frame.Position = UDim2.new(0.5, -150, 0.5, -200)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.Parent = petSelectionUI

	-- Create title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Text = "Select a Pet to Feed"
	title.Parent = frame

	-- Create close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Text = "X"
	closeButton.Parent = title

	-- Close button handler
	closeButton.MouseButton1Click:Connect(function()
		petSelectionUI:Destroy()
	end)

	-- Create container for pet list
	local container = Instance.new("ScrollingFrame")
	container.Name = "Container"
	container.Size = UDim2.new(1, -20, 1, -50)
	container.Position = UDim2.new(0, 10, 0, 45)
	container.BackgroundTransparency = 1
	container.ScrollBarThickness = 6
	container.ScrollingDirection = Enum.ScrollingDirection.Y
	container.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set dynamically
	container.Parent = frame

	-- Create UI list layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Name = "ListLayout"
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Parent = container

	-- Find player's pets
	-- This would normally query your pet data system
	-- For this example, we'll just create dummy data
	local playerPets = {
		{id = "pet1", name = "Fluffy", type = "Common Corgi", feedCount = 4},
		{id = "pet2", name = "Jumpy", type = "Rare RedPanda", feedCount = 8},
		{id = "pet3", name = "Sparkles", type = "Epic Corgi", feedCount = 12}
	}

	-- Add pet items to the list
	for _, pet in ipairs(playerPets) do
		local petFrame = Instance.new("Frame")
		petFrame.Name = pet.id .. "_Frame"
		petFrame.Size = UDim2.new(1, 0, 0, 60)
		petFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		petFrame.BorderSizePixel = 0

		local petName = Instance.new("TextLabel")
		petName.Name = "PetName"
		petName.Size = UDim2.new(1, -20, 0, 20)
		petName.Position = UDim2.new(0, 10, 0, 5)
		petName.BackgroundTransparency = 1
		petName.TextColor3 = Color3.fromRGB(255, 255, 255)
		petName.TextSize = 14
		petName.Font = Enum.Font.GothamBold
		petName.TextXAlignment = Enum.TextXAlignment.Left
		petName.Text = pet.name .. " (" .. pet.type .. ")"
		petName.Parent = petFrame

		local feedInfo = Instance.new("TextLabel")
		feedInfo.Name = "FeedInfo"
		feedInfo.Size = UDim2.new(1, -20, 0, 20)
		feedInfo.Position = UDim2.new(0, 10, 0, 25)
		feedInfo.BackgroundTransparency = 1
		feedInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
		feedInfo.TextSize = 12
		feedInfo.Font = Enum.Font.Gotham
		feedInfo.TextXAlignment = Enum.TextXAlignment.Left
		feedInfo.Text = "Fed: " .. pet.feedCount .. " times (Next growth: " .. (10 - (pet.feedCount % 10)) .. " more)"
		feedInfo.Parent = petFrame

		local selectButton = Instance.new("TextButton")
		selectButton.Name = "SelectButton"
		selectButton.Size = UDim2.new(0.3, 0, 0.5, 0)
		selectButton.Position = UDim2.new(0.68, 0, 0.25, 0)
		selectButton.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
		selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		selectButton.TextSize = 12
		selectButton.Font = Enum.Font.GothamBold
		selectButton.Text = "Feed"
		selectButton.Parent = petFrame

		-- Feed pet handler
		selectButton.MouseButton1Click:Connect(function()
			-- Fire event to feed the pet
			FeedPet:FireServer(pet.id, cropID)

			-- Close the UI
			petSelectionUI:Destroy()
		end)

		petFrame.Parent = container
	end

	-- Update canvas size
	if listLayout then
		container.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	else
		-- Fallback if ListLayout is not found
		local totalHeight = 0
		for _, child in pairs(container:GetChildren()) do
			if child:IsA("GuiObject") then
				totalHeight = totalHeight + child.Size.Y.Offset
			end
		end
		container.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
	end
end

-- Update inventory UI based on player data
updateInventoryUI = function()
	local playerGui = player:WaitForChild("PlayerGui")
	local farmingUI = playerGui:FindFirstChild("FarmingUI")
	if not farmingUI then return end

	local inventoryFrame = farmingUI:FindFirstChild("InventoryFrame")
	if not inventoryFrame then return end

	local container = inventoryFrame:FindFirstChild("Container")
	if not container then return end

	-- Clear existing items
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add seeds section
	local seedsTitle = Instance.new("TextLabel")
	seedsTitle.Name = "SeedsTitle"
	seedsTitle.Size = UDim2.new(1, 0, 0, 30)
	seedsTitle.BackgroundColor3 = Color3.fromRGB(60, 80, 40)
	seedsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	seedsTitle.TextSize = 16
	seedsTitle.Font = Enum.Font.GothamBold
	seedsTitle.Text = "Seeds"
	seedsTitle.Parent = container

	-- Add seed items
	if FarmingSeeds and FarmingSeeds.Seeds then
		for _, seed in ipairs(FarmingSeeds.Seeds) do
			local quantity = playerFarmingData.inventory[seed.ID] or 0
			if quantity > 0 then
				local itemFrame = Instance.new("Frame")
				itemFrame.Name = seed.ID .. "_Frame"
				itemFrame.Size = UDim2.new(1, 0, 0, 40)
				itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				itemFrame.BorderSizePixel = 0

				local itemName = Instance.new("TextLabel")
				itemName.Name = "ItemName"
				itemName.Size = UDim2.new(0.6, 0, 1, 0)
				itemName.Position = UDim2.new(0, 10, 0, 0)
				itemName.BackgroundTransparency = 1
				itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
				itemName.TextSize = 14
				itemName.Font = Enum.Font.Gotham
				itemName.TextXAlignment = Enum.TextXAlignment.Left
				itemName.Text = seed.Name .. " x" .. quantity
				itemName.Parent = itemFrame

				local useButton = Instance.new("TextButton")
				useButton.Name = "UseButton"
				useButton.Size = UDim2.new(0.3, 0, 0.8, 0)
				useButton.Position = UDim2.new(0.68, 0, 0.1, 0)
				useButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
				useButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				useButton.TextSize = 12
				useButton.Font = Enum.Font.GothamBold
				useButton.Text = "Select"
				useButton.Parent = itemFrame

				-- Select seed for planting
				useButton.MouseButton1Click:Connect(function()
					selectedSeed = seed.ID
					inventoryFrame.Visible = false

					-- Update UI to show selected seed
					local notification = playerGui:FindFirstChild("Notification") or Instance.new("TextLabel")
					notification.Name = "Notification"
					notification.Size = UDim2.new(0, 200, 0, 40)
					notification.Position = UDim2.new(0.5, -100, 0.9, 0)
					notification.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
					notification.TextColor3 = Color3.fromRGB(255, 255, 255)
					notification.TextSize = 14
					notification.Font = Enum.Font.GothamBold
					notification.Text = "Selected: " .. seed.Name
					notification.Parent = playerGui

					-- Auto-hide after 3 seconds
					spawn(function()
						wait(3)
						notification:Destroy()
					end)
				end)

				itemFrame.Parent = container
			end
		end
	end

	-- Add crops section
	local cropsTitle = Instance.new("TextLabel")
	cropsTitle.Name = "CropsTitle"
	cropsTitle.Size = UDim2.new(1, 0, 0, 30)
	cropsTitle.BackgroundColor3 = Color3.fromRGB(80, 60, 40)
	cropsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	cropsTitle.TextSize = 16
	cropsTitle.Font = Enum.Font.GothamBold
	cropsTitle.Text = "Harvested Crops"
	cropsTitle.Parent = container

	-- Add crop items
	if FarmingSeeds and FarmingSeeds.Crops then
		for _, crop in ipairs(FarmingSeeds.Crops) do
			local quantity = playerFarmingData.inventory[crop.ID] or 0
			if quantity > 0 then
				local itemFrame = Instance.new("Frame")
				itemFrame.Name = crop.ID .. "_Frame"
				itemFrame.Size = UDim2.new(1, 0, 0, 40)
				itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				itemFrame.BorderSizePixel = 0

				local itemName = Instance.new("TextLabel")
				itemName.Name = "ItemName"
				itemName.Size = UDim2.new(0.6, 0, 1, 0)
				itemName.Position = UDim2.new(0, 10, 0, 0)
				itemName.BackgroundTransparency = 1
				itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
				itemName.TextSize = 14
				itemName.Font = Enum.Font.Gotham
				itemName.TextXAlignment = Enum.TextXAlignment.Left
				itemName.Text = crop.Name .. " x" .. quantity
				itemName.Parent = itemFrame

				local feedButton = Instance.new("TextButton")
				feedButton.Name = "FeedButton"
				feedButton.Size = UDim2.new(0.3, 0, 0.8, 0)
				feedButton.Position = UDim2.new(0.68, 0, 0.1, 0)
				feedButton.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
				feedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				feedButton.TextSize = 12
				feedButton.Font = Enum.Font.GothamBold
				feedButton.Text = "Feed Pet"
				feedButton.Parent = itemFrame

				-- Feed pet handler
				feedButton.MouseButton1Click:Connect(function()
					inventoryFrame.Visible = false

					-- Show pet selection UI
					showPetSelectionUI(crop.ID)
				end)

				itemFrame.Parent = container
			end
		end
	end

	-- Update canvas size based on children
	local listLayout = container:FindFirstChild("ListLayout")
	if listLayout then
		container.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	else
		-- Fallback if ListLayout is not found
		local totalHeight = 0
		for _, child in pairs(container:GetChildren()) do
			if child:IsA("GuiObject") then
				totalHeight = totalHeight + child.Size.Y.Offset
			end
		end
		container.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
	end
end

-- UI setup (simplified for this example)
local function setupFarmingUI()
	local playerGui = player:WaitForChild("PlayerGui")

	-- Create the farming UI if it doesn't exist
	local farmingUI = playerGui:FindFirstChild("FarmingUI")
	if not farmingUI then
		farmingUI = Instance.new("ScreenGui")
		farmingUI.Name = "FarmingUI"
		farmingUI.ResetOnSpawn = false
		farmingUI.Parent = playerGui
	end

	-- Create inventory frame
	local inventoryFrame = farmingUI:FindFirstChild("InventoryFrame") or Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0, 300, 0, 400)
	inventoryFrame.Position = UDim2.new(0, 20, 0.5, -200)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	inventoryFrame.BackgroundTransparency = 0.5
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Visible = false
	inventoryFrame.Parent = farmingUI

	-- Create title
	local title = inventoryFrame:FindFirstChild("Title") or Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Text = "Farming Inventory"
	title.Parent = inventoryFrame

	-- Create close button
	local closeButton = title:FindFirstChild("CloseButton") or Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Text = "X"
	closeButton.Parent = title

	-- Close button handler
	closeButton.MouseButton1Click:Connect(function()
		inventoryFrame.Visible = false
	end)

	-- Create inventory container
	local inventoryContainer = inventoryFrame:FindFirstChild("Container") or Instance.new("ScrollingFrame")
	inventoryContainer.Name = "Container"
	inventoryContainer.Size = UDim2.new(1, -20, 1, -50)
	inventoryContainer.Position = UDim2.new(0, 10, 0, 45)
	inventoryContainer.BackgroundTransparency = 1
	inventoryContainer.ScrollBarThickness = 6
	inventoryContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	inventoryContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set dynamically
	inventoryContainer.Parent = inventoryFrame

	-- Create UI list layout
	local listLayout = inventoryContainer:FindFirstChild("ListLayout") or Instance.new("UIListLayout")
	listLayout.Name = "ListLayout"
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Parent = inventoryContainer

	-- Create toggle button
	local toggleButton = farmingUI:FindFirstChild("FarmingButton") or Instance.new("TextButton")
	toggleButton.Name = "FarmingButton"
	toggleButton.Size = UDim2.new(0, 120, 0, 40)
	toggleButton.Position = UDim2.new(0, 20, 0.7, 0)
	toggleButton.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 16
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Text = "Farming"
	toggleButton.Parent = farmingUI

	-- Toggle button handler
	toggleButton.MouseButton1Click:Connect(function()
		inventoryFrame.Visible = not inventoryFrame.Visible
		if inventoryFrame.Visible then
			updateInventoryUI()
		end
	end)

	return farmingUI
end

-- Handle interaction with farm plots
local function setupFarmInteraction()
	-- Handle mouse clicks
	mouse.Button1Down:Connect(function()
		local target = mouse.Target
		if not target then return end

		-- Check if we clicked on a farm plot
		local plot = nil
		if target.Name == "Soil" then
			plot = target.Parent
		end

		if plot and plot.Name:match("FarmPlot_") then
			local plotID = tonumber(plot.Name:match("FarmPlot_(%d+)"))
			if not plotID then return end

			-- Check if the plot is already planted
			if plot:GetAttribute("IsPlanted") then
				-- Check if the plant is ready to harvest
				if plot:GetAttribute("GrowthStage") == 4 then
					-- Harvest the plant
					HarvestPlant:FireServer(plotID)
				else
					-- Show growth progress
					local growthStage = plot:GetAttribute("GrowthStage") or 0
					local growthPercent = math.floor((growthStage / 4) * 100)

					-- Show growth notification
					local playerGui = player:WaitForChild("PlayerGui")
					local notification = playerGui:FindFirstChild("Notification") or Instance.new("TextLabel")
					notification.Name = "Notification"
					notification.Size = UDim2.new(0, 200, 0, 40)
					notification.Position = UDim2.new(0.5, -100, 0.9, 0)
					notification.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
					notification.TextColor3 = Color3.fromRGB(255, 255, 255)
					notification.TextSize = 14
					notification.Font = Enum.Font.GothamBold
					notification.Text = "Growth: " .. growthPercent .. "% (Stage " .. growthStage .. "/4)"
					notification.Parent = playerGui

					-- Auto-hide after 3 seconds
					spawn(function()
						wait(3)
						notification:Destroy()
					end)
				end
			else
				-- If we have a selected seed, plant it
				if selectedSeed then
					PlantSeed:FireServer(plotID, selectedSeed)
					selectedSeed = nil
				else
					-- Prompt to select a seed
					local playerGui = player:WaitForChild("PlayerGui")
					local notification = playerGui:FindFirstChild("Notification") or Instance.new("TextLabel")
					notification.Name = "Notification"
					notification.Size = UDim2.new(0, 200, 0, 40)
					notification.Position = UDim2.new(0.5, -100, 0.9, 0)
					notification.BackgroundColor3 = Color3.fromRGB(200, 100, 40)
					notification.TextColor3 = Color3.fromRGB(255, 255, 255)
					notification.TextSize = 14
					notification.Font = Enum.Font.GothamBold
					notification.Text = "Select a seed first!"
					notification.Parent = playerGui

					-- Auto-hide after 3 seconds
					spawn(function()
						wait(3)
						notification:Destroy()
					end)
				end
			end
		end
	end)
end

-- Receive player farming data updates
GetFarmingData.OnClientEvent:Connect(function(data)
	playerFarmingData = data
	updateInventoryUI()
end)

-- Set up UI
setupFarmingUI()

-- Set up farm plot interaction
setupFarmInteraction()

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	-- Get initial farming data
	GetFarmingData:FireServer()
end)

-- Request initial data
GetFarmingData:FireServer()

print("Farming Client Script Loaded!")