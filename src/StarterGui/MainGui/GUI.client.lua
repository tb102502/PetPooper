-- Pet Collection Simulator
-- GUI Script (LocalScript in StarterGui/MainGui)
-- UPDATED VERSION: Simplified to only show Inventory and owned content

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Get the local player
local player = Players.LocalPlayer

-- Forward declarations for functions used before defined
local ShowPetDetails

-- Ensure RemoteEvents and RemoteFunctions exist
local function ensureRemotesExist()
	if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
		local folder = Instance.new("Folder")
		folder.Name = "RemoteEvents"
		folder.Parent = ReplicatedStorage
	end

	if not ReplicatedStorage:FindFirstChild("RemoteFunctions") then
		local folder = Instance.new("Folder")
		folder.Name = "RemoteFunctions"
		folder.Parent = ReplicatedStorage
	end

	-- Create UpdatePlayerStats if it doesn't exist
	if not ReplicatedStorage.RemoteEvents:FindFirstChild("UpdatePlayerStats") then
		local event = Instance.new("RemoteEvent")
		event.Name = "UpdatePlayerStats"
		event.Parent = ReplicatedStorage.RemoteEvents
	end

	-- Create GetPlayerData if it doesn't exist
	if not ReplicatedStorage.RemoteFunctions:FindFirstChild("GetPlayerData") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetPlayerData"
		func.Parent = ReplicatedStorage.RemoteFunctions
	end
end

-- Call this function at the start
ensureRemotesExist()

-- Reference remote events and functions
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")
local GetPlayerData = RemoteFunctions:WaitForChild("GetPlayerData")

-- Get player data with error handling
local playerData
local success, result = pcall(function()
	return GetPlayerData:InvokeServer()
end)

if success and result then
	playerData = result
	print("GUI: Successfully loaded player data with " .. #playerData.pets .. " pets")
else
	warn("Failed to get player data: " .. tostring(result))
	-- Create default player data
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

-- GUI References
local mainGui = script.Parent
local topBar = mainGui:FindFirstChild("TopBar")
local statsFrame = mainGui:FindFirstChild("StatsFrame")
local buttonsFrame = mainGui:FindFirstChild("ButtonsFrame")
local contentFrame = mainGui:FindFirstChild("ContentFrame")

-- Track UI toggle state
local uiVisible = true

-- Create the toggle button
local function CreateToggleButton()
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 40, 0, 40)
	toggleButton.Position = UDim2.new(1, -50, 0, 5)
	toggleButton.Text = "X"
	toggleButton.TextSize = 20
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.BorderSizePixel = 0
	toggleButton.AutoButtonColor = true
	toggleButton.Parent = topBar

	-- Make it circular
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.5, 0)
	uiCorner.Parent = toggleButton

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(255, 255, 255)
	uiStroke.Thickness = 2
	uiStroke.Parent = toggleButton

	return toggleButton
end

-- Toggle UI visibility function
local function ToggleUIVisibility()
	uiVisible = not uiVisible

	-- Get the toggle button
	local toggleButton = topBar:FindFirstChild("ToggleButton")

	if uiVisible then
		-- Show UI
		if buttonsFrame then buttonsFrame.Visible = true end
		if contentFrame then contentFrame.Visible = true end

		-- Update toggle button appearance
		if toggleButton then
			toggleButton.Text = "X"
			toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		end
	else
		-- Hide UI
		if buttonsFrame then buttonsFrame.Visible = false end
		if contentFrame then contentFrame.Visible = false end

		-- Update toggle button appearance
		if toggleButton then
			toggleButton.Text = "≡"
			toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		end
	end
end

-- Function to create a rotating model in a ViewportFrame without using .Source
local function RotatePetModel(model, speed)
	if not model or not model.Parent then return end

	-- Store rotation information on the model itself
	local rotationInfo = Instance.new("StringValue")
	rotationInfo.Name = "RotationInfo"
	rotationInfo.Value = tostring(tick()) -- Store start time
	rotationInfo.Parent = model

	local speedValue = Instance.new("NumberValue")
	speedValue.Name = "RotationSpeed"
	speedValue.Value = speed or 20
	speedValue.Parent = model

	-- Start the rotation loop safely
	spawn(function()
		local angle = 0

		while true do
			if not model or not model.Parent then
				break -- Stop if model is removed
			end

			angle = angle + RunService.Heartbeat:Wait() * math.rad(speedValue.Value)

			if model.PrimaryPart then
				model:SetPrimaryPartCFrame(CFrame.new(model.PrimaryPart.Position) * CFrame.Angles(0, angle, 0))
			end
		end
	end)
end

-- Function to create 3D ViewportFrame-based pet template
local function CreatePetTemplate()
	local petTemplate = Instance.new("Frame")
	petTemplate.Name = "PetTemplate"
	petTemplate.Size = UDim2.new(0, 120, 0, 160) -- Made slightly taller for better proportions
	petTemplate.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	petTemplate.BorderColor3 = Color3.fromRGB(200, 200, 200)
	petTemplate.BorderSizePixel = 2
	petTemplate.Visible = false

	-- Add frame shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217" -- Shadow image
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ZIndex = 0
	shadow.Parent = petTemplate

	-- Add rounded corners to the template
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = petTemplate

	-- Create ViewportFrame for 3D pet display
	local petViewport = Instance.new("ViewportFrame")
	petViewport.Name = "PetViewport"
	petViewport.Size = UDim2.new(0, 100, 0, 100) -- Larger viewport
	petViewport.Position = UDim2.new(0.5, 0, 0, 10)
	petViewport.AnchorPoint = Vector2.new(0.5, 0)
	petViewport.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background (will be overridden by rarity)
	petViewport.BackgroundTransparency = 0
	petViewport.BorderSizePixel = 0
	petViewport.LightColor = Color3.fromRGB(255, 255, 255) -- Brighter light
	petViewport.LightDirection = Vector3.new(-1, -1, -1)
	petViewport.Ambient = Color3.fromRGB(150, 150, 150) -- Better ambient light

	-- Add rounded corners to viewport
	local viewportCorner = Instance.new("UICorner")
	viewportCorner.CornerRadius = UDim.new(0, 8)
	viewportCorner.Parent = petViewport

	petViewport.Parent = petTemplate

	-- Add rarity indicator
	local rarityIndicator = Instance.new("Frame")
	rarityIndicator.Name = "RarityIndicator"
	rarityIndicator.Size = UDim2.new(1, 0, 0, 4) -- Thicker indicator
	rarityIndicator.Position = UDim2.new(0, 0, 0, 0)
	rarityIndicator.BorderSizePixel = 0
	rarityIndicator.ZIndex = 2

	-- Add rounded top corners to match viewport
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 8)
	indicatorCorner.Parent = rarityIndicator

	rarityIndicator.Parent = petViewport

	-- Create improved labels
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 115)
	nameLabel.Text = "Pet Name"
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50) -- Darker text
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent = petTemplate

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, -10, 0, 20)
	rarityLabel.Position = UDim2.new(0, 5, 0, 135)
	rarityLabel.Text = "Common"
	rarityLabel.TextSize = 12
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Parent = petTemplate

	-- Add text stroke for better visibility on bright backgrounds
	rarityLabel.TextStrokeTransparency = 0.8
	rarityLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

	-- Add shimmer effect for high-rarity pets
	local shimmer = Instance.new("Frame")
	shimmer.Name = "Shimmer"
	shimmer.Size = UDim2.new(1, 0, 1, 0)
	shimmer.BackgroundTransparency = 1
	shimmer.BorderSizePixel = 0
	shimmer.ClipsDescendants = true
	shimmer.ZIndex = 3
	shimmer.Parent = petTemplate

	return petTemplate
end

-- Function to properly set up a pet model in a ViewportFrame
local function SetupPetModel(viewport, modelName, rarity)
	-- Make sure the viewport exists
	if not viewport then
		warn("SetupPetModel was given a nil viewport")
		return nil
	end

	-- Set background color based on rarity
	local backgroundColor
	if rarity == "Common" then
		backgroundColor = Color3.fromRGB(150, 150, 150) -- Darker gray
	elseif rarity == "Rare" then
		backgroundColor = Color3.fromRGB(30, 100, 180) -- Blue
	elseif rarity == "Epic" then
		backgroundColor = Color3.fromRGB(100, 40, 160) -- Purple
	elseif rarity == "Legendary" then
		backgroundColor = Color3.fromRGB(120, 100, 20) -- Gold
	else
		backgroundColor = Color3.fromRGB(40, 40, 40) -- Default dark
	end

	-- Apply background color
	viewport.BackgroundColor3 = backgroundColor

	-- Clear previous viewport contents
	for _, child in pairs(viewport:GetChildren()) do
		if child:IsA("Camera") or child:IsA("Model") or child:IsA("WorldModel") or 
			child.Name == "RarityIndicator" then
			if child.Name ~= "RarityIndicator" then -- Keep the rarity indicator
				child:Destroy()
			end
		end
	end

	-- Create WorldModel to contain our pet
	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "PetWorldModel"
	worldModel.Parent = viewport

	-- Create camera
	local camera = Instance.new("Camera")
	camera.FieldOfView = 50 -- Narrower FOV to make model look bigger
	camera.CameraType = Enum.CameraType.Scriptable
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- Try to find the model in ReplicatedStorage
	local model = nil
	if ReplicatedStorage:FindFirstChild("PetModels") and 
		ReplicatedStorage.PetModels:FindFirstChild(modelName) then
		model = ReplicatedStorage.PetModels:FindFirstChild(modelName):Clone()
	else
		-- Create a fallback model if the actual model isn't found
		model = Instance.new("Model")
		model.Name = modelName

		-- Create a simple part as the body
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(2, 2, 2)
		part.Position = Vector3.new(0, 0, 0)
		part.Anchored = true
		part.CanCollide = false
		part.Name = "Body"

		-- Color based on rarity
		if rarity == "Common" then
			part.Color = Color3.fromRGB(230, 230, 230) -- Light Gray
		elseif rarity == "Rare" then
			part.Color = Color3.fromRGB(70, 160, 255) -- Brighter Blue
		elseif rarity == "Epic" then
			part.Color = Color3.fromRGB(180, 80, 255) -- Bright Purple
		elseif rarity == "Legendary" then
			part.Color = Color3.fromRGB(255, 215, 0) -- Gold
		end

		part.Material = Enum.Material.SmoothPlastic
		part.Parent = model
		model.PrimaryPart = part

		-- Add eyes
		local eye1 = Instance.new("Part")
		eye1.Shape = Enum.PartType.Ball
		eye1.Size = Vector3.new(0.4, 0.4, 0.4)
		eye1.Position = Vector3.new(-0.5, 0.3, -0.8)
		eye1.Color = Color3.fromRGB(0, 0, 0)
		eye1.Anchored = true
		eye1.CanCollide = false
		eye1.Material = Enum.Material.SmoothPlastic
		eye1.Name = "Eye1"
		eye1.Parent = model

		local eye2 = eye1:Clone()
		eye2.Position = Vector3.new(0.5, 0.3, -0.8)
		eye2.Name = "Eye2"
		eye2.Parent = model
	end

	-- Clean up the model for display
	for _, item in pairs(model:GetDescendants()) do
		if item:IsA("Script") or item:IsA("LocalScript") or 
			item.Name == "ClickDetector" or 
			item.Name == "ProximityPrompt" then
			item:Destroy()
		end

		if item:IsA("BasePart") then
			item.Anchored = true
			item.CanCollide = false

			-- Enhance materials and colors based on rarity
			if item.Name ~= "Eye1" and item.Name ~= "Eye2" then
				if rarity == "Common" then
					-- Leave as is
				elseif rarity == "Rare" then
					item.Material = Enum.Material.Glass
					item.Reflectance = 0.2
				elseif rarity == "Epic" then
					item.Material = Enum.Material.Neon
					item.Reflectance = 0.1
				elseif rarity == "Legendary" then
					item.Material = Enum.Material.Glass
					item.Reflectance = 0.5
				end
			end
		end

		-- Add glow effects for epic/legendary pets
		if (rarity == "Epic" or rarity == "Legendary") and item:IsA("BasePart") and 
			item.Name ~= "Eye1" and item.Name ~= "Eye2" then
			local glow = Instance.new("PointLight")
			glow.Color = (rarity == "Epic") and 
				Color3.fromRGB(138, 43, 226) or 
				Color3.fromRGB(255, 215, 0)
			glow.Range = 4
			glow.Brightness = 1
			glow.Parent = item
		end
	end

	-- Add model to WorldModel
	model.Parent = worldModel

	-- Set model position - Find primary part or any part
	local refPart
	if model:FindFirstChild("HumanoidRootPart") then
		refPart = model.HumanoidRootPart
	elseif model.PrimaryPart then
		refPart = model.PrimaryPart
	else
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				refPart = part
				model.PrimaryPart = part
				break
			end
		end
	end

	-- Position the model and camera for best viewing angle
	if refPart then
		-- Make sure model is centered
		local modelCFrame = model:GetPivot()
		local offset = CFrame.new() - modelCFrame.Position

		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CFrame = part.CFrame * offset
			end
		end

		-- Calculate model size - be more aggressive in sizing
		local modelSize = model:GetExtentsSize()
		local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z)

		-- Position camera closer for larger appearance
		local distance = maxSize * 1.2 -- Closer camera

		-- MODIFIED: Set camera to a slightly lower angled position
		camera.CFrame = CFrame.new(
			Vector3.new(distance * 0.6, distance * 0.2, distance * 0.8), -- Lower Y position
			Vector3.new(0, -0.5, 0) -- Looking slightly lower
		)

		-- Add ambient lighting
		local ambientLight = Instance.new("PointLight")
		ambientLight.Range = distance * 3
		ambientLight.Brightness = 0.8
		ambientLight.Color = Color3.fromRGB(255, 255, 255)
		ambientLight.Parent = camera

		-- Add rarity-specific lighting effects
		if rarity == "Epic" or rarity == "Legendary" then
			local coloredLight = Instance.new("PointLight")
			coloredLight.Range = distance * 2
			coloredLight.Brightness = 0.5

			if rarity == "Epic" then
				coloredLight.Color = Color3.fromRGB(138, 43, 226) -- Purple
			else
				coloredLight.Color = Color3.fromRGB(255, 215, 0) -- Gold
			end

			coloredLight.Parent = camera
		end
	end

	-- Add rotation with safer approach
	-- Adjust rotation speed based on rarity
	local rotationSpeed = 20 -- Degrees per second
	if rarity == "Rare" then
		rotationSpeed = 25
	elseif rarity == "Epic" then
		rotationSpeed = 30
	elseif rarity == "Legendary" then
		rotationSpeed = 40
	end

	-- Start rotation
	RotatePetModel(model, rotationSpeed)

	-- Update rarity indicator if it exists
	local rarityIndicator = viewport:FindFirstChild("RarityIndicator")
	if rarityIndicator then
		if rarity == "Common" then
			rarityIndicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200) -- Gray
		elseif rarity == "Rare" then
			rarityIndicator.BackgroundColor3 = Color3.fromRGB(30, 144, 255) -- Blue
		elseif rarity == "Epic" then
			rarityIndicator.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Purple
		elseif rarity == "Legendary" then
			rarityIndicator.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		end
	end

	return model
end

-- Check if GUI elements exist
if not topBar or not statsFrame or not buttonsFrame or not contentFrame then
	warn("GUI elements not found! Creating them...")

	-- Create missing elements
	if not topBar then
		topBar = Instance.new("Frame")
		topBar.Name = "TopBar"
		topBar.Size = UDim2.new(1, 0, 0, 50)
		topBar.Position = UDim2.new(0, 0, 0, 0)
		topBar.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
		topBar.BorderSizePixel = 0
		topBar.Parent = mainGui

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
	end

	-- Create toggle button
	CreateToggleButton()

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

		-- Create labels
		local coinsLabel = Instance.new("TextLabel")
		coinsLabel.Name = "CoinsLabel"
		coinsLabel.Size = UDim2.new(1, -20, 0, 30)
		coinsLabel.Position = UDim2.new(0, 10, 0, 5)
		coinsLabel.Text = "Coins: 0"
		coinsLabel.TextSize = 18
		coinsLabel.Font = Enum.Font.BungeeInline
		coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
		coinsLabel.BackgroundTransparency = 1
		coinsLabel.Parent = statsFrame

		local gemsLabel = Instance.new("TextLabel")
		gemsLabel.Name = "GemsLabel"
		gemsLabel.Size = UDim2.new(1, -20, 0, 30)
		gemsLabel.Position = UDim2.new(0, 10, 0, 35)
		gemsLabel.Text = "Gems: 0"
		gemsLabel.TextSize = 18
		gemsLabel.Font = Enum.Font.BungeeInline
		gemsLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
		gemsLabel.TextXAlignment = Enum.TextXAlignment.Left
		gemsLabel.BackgroundTransparency = 1
		gemsLabel.Parent = statsFrame

		local petsLabel = Instance.new("TextLabel")
		petsLabel.Name = "PetsLabel"
		petsLabel.Size = UDim2.new(1, -20, 0, 30)
		petsLabel.Position = UDim2.new(0, 10, 0, 65)
		petsLabel.Text = "Pets: 0/100"
		petsLabel.TextSize = 18
		petsLabel.Font = Enum.Font.BungeeInline
		petsLabel.TextColor3 = Color3.fromRGB(170, 0, 170)
		petsLabel.TextXAlignment = Enum.TextXAlignment.Left
		petsLabel.BackgroundTransparency = 1
		petsLabel.Parent = statsFrame
	end

	if not buttonsFrame then
		buttonsFrame = Instance.new("Frame")
		buttonsFrame.Name = "ButtonsFrame"
		buttonsFrame.Size = UDim2.new(1, 0, 0, 50)
		buttonsFrame.Position = UDim2.new(0, 0, 0, 170)
		buttonsFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		buttonsFrame.BorderSizePixel = 0
		buttonsFrame.Parent = mainGui

		-- Create buttons (only Inventory, MyUpgrades, and MyAreas)
		local function createButton(name, position)
			local button = Instance.new("TextButton")
			button.Name = name.."Button"
			button.Size = UDim2.new(0.33, -10, 1, -10)
			button.Position = UDim2.new(position, 5, 0, 5)
			button.Text = name
			button.TextSize = 16
			button.Font = Enum.Font.GothamBold
			button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.BorderSizePixel = 0
			button.Parent = buttonsFrame
			return button
		end

		-- Create the three buttons for the main menu
		createButton("Inventory", 0)
		createButton("MyUpgrades", 0.33)
		createButton("MyAreas", 0.66)
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

		-- Create tab frames (only Inventory, MyUpgrades, and MyAreas)
		local function createTabFrame(name, visible)
			local frame = Instance.new("Frame")
			frame.Name = name.."Frame"
			frame.Size = UDim2.new(1, -20, 1, -20)
			frame.Position = UDim2.new(0, 10, 0, 10)
			frame.BackgroundTransparency = 1
			frame.Visible = visible
			frame.Parent = contentFrame
			return frame
		end

		createTabFrame("Inventory", true)
		createTabFrame("MyUpgrades", false)
		createTabFrame("MyAreas", false)
	end
else
	-- Create toggle button if it doesn't exist
	if not topBar:FindFirstChild("ToggleButton") then
		CreateToggleButton()
	end

	-- Ensure we have the updated tab frames
	if not contentFrame:FindFirstChild("MyUpgradesFrame") then
		local myUpgradesFrame = Instance.new("Frame")
		myUpgradesFrame.Name = "MyUpgradesFrame"
		myUpgradesFrame.Size = UDim2.new(1, -20, 1, -20)
		myUpgradesFrame.Position = UDim2.new(0, 10, 0, 10)
		myUpgradesFrame.BackgroundTransparency = 1
		myUpgradesFrame.Visible = false
		myUpgradesFrame.Parent = contentFrame
	end

	if not contentFrame:FindFirstChild("MyAreasFrame") then
		local myAreasFrame = Instance.new("Frame")
		myAreasFrame.Name = "MyAreasFrame"
		myAreasFrame.Size = UDim2.new(1, -20, 1, -20)
		myAreasFrame.Position = UDim2.new(0, 10, 0, 10)
		myAreasFrame.BackgroundTransparency = 1
		myAreasFrame.Visible = false
		myAreasFrame.Parent = contentFrame
	end
end

-- Tab Buttons
local inventoryButton = buttonsFrame:FindFirstChild("InventoryButton")
local myUpgradesButton = buttonsFrame:FindFirstChild("MyUpgradesButton")
local myAreasButton = buttonsFrame:FindFirstChild("MyAreasButton")

-- Content Frames
local inventoryFrame = contentFrame:FindFirstChild("InventoryFrame")
local myUpgradesFrame = contentFrame:FindFirstChild("MyUpgradesFrame")
local myAreasFrame = contentFrame:FindFirstChild("MyAreasFrame")

-- Stats Labels
local coinsLabel = statsFrame:FindFirstChild("CoinsLabel")
local gemsLabel = statsFrame:FindFirstChild("GemsLabel")
local petsLabel = statsFrame:FindFirstChild("PetsLabel")

-- Toggle Button
local toggleButton = topBar:FindFirstChild("ToggleButton")
if toggleButton then
	toggleButton.MouseButton1Click:Connect(ToggleUIVisibility)
end

-- Safe function to update a label's text
local function updateLabelText(label, text)
	if label then
		label.Text = text
	else
		warn("Tried to update nil label with text: " .. text)
	end
end

-- Define the ShowPetDetails function to display detailed info about a pet group
ShowPetDetails = function(petGroup)
	-- Remove any existing details panel
	local existingPanel = inventoryFrame:FindFirstChild("PetDetailsPanel")
	if existingPanel then
		existingPanel:Destroy()
	end

	-- Create a details panel
	local detailsPanel = Instance.new("Frame")
	detailsPanel.Name = "PetDetailsPanel"
	detailsPanel.Size = UDim2.new(0.7, 0, 0.8, 0)
	detailsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	detailsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	detailsPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	detailsPanel.BorderSizePixel = 0

	-- Set panel color based on rarity (subtle gradient)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 45

	if petGroup.rarity == "Common" then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
		})
	elseif petGroup.rarity == "Rare" then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 60, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 40, 80))
		})
	elseif petGroup.rarity == "Epic" then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 30, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 80))
		})
	elseif petGroup.rarity == "Legendary" then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 70, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 50, 10))
		})
	end
	gradient.Parent = detailsPanel

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = detailsPanel

	-- Add title with matching rarity color
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = petGroup.name
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.GothamBold

	-- Color based on rarity
	if petGroup.rarity == "Common" then
		titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230) -- Light Gray
	elseif petGroup.rarity == "Rare" then
		titleLabel.TextColor3 = Color3.fromRGB(70, 160, 255) -- Brighter Blue
	elseif petGroup.rarity == "Epic" then
		titleLabel.TextColor3 = Color3.fromRGB(180, 80, 255) -- Bright Purple
	elseif petGroup.rarity == "Legendary" then
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	end

	-- Add text stroke for better visibility
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.Parent = detailsPanel

	-- Enhanced pet details with icons
	local detailsText = Instance.new("TextLabel")
	detailsText.Size = UDim2.new(0.5, 0, 0.7, 0)
	detailsText.Position = UDim2.new(0.5, 0, 0, 60)
	detailsText.BackgroundTransparency = 1
	detailsText.TextColor3 = Color3.fromRGB(255, 255, 255)
	detailsText.TextSize = 18
	detailsText.Font = Enum.Font.Gotham
	detailsText.TextXAlignment = Enum.TextXAlignment.Left

	-- Calculate collection value based on rarity
	local collectValue = 
		(petGroup.rarity == "Common" and 1 or
			petGroup.rarity == "Rare" and 5 or
			petGroup.rarity == "Epic" and 20 or
			petGroup.rarity == "Legendary" and 100 or 1)

	detailsText.Text = string.format(
		"✨ Rarity: %s\n💰 Value: %d\n⭐ Level: %d\n🔢 Collected: %d",
		petGroup.rarity,
		collectValue,
		petGroup.highestLevel,
		petGroup.count
	)
	detailsText.TextWrapped = true
	detailsText.Parent = detailsPanel

	-- Add Enhanced viewport for 3D model
	local detailViewport = Instance.new("ViewportFrame")
	detailViewport.Size = UDim2.new(0.45, 0, 0.45, 0)
	detailViewport.Position = UDim2.new(0.05, 0, 0.4, 0)
	detailViewport.AnchorPoint = Vector2.new(0, 0.5)

	-- Set the background color based on rarity
	if petGroup.rarity == "Common" then
		detailViewport.BackgroundColor3 = Color3.fromRGB(200, 200, 200) -- Gray
	elseif petGroup.rarity == "Rare" then
		detailViewport.BackgroundColor3 = Color3.fromRGB(30, 100, 180) -- Blue
	elseif petGroup.rarity == "Epic" then
		detailViewport.BackgroundColor3 = Color3.fromRGB(100, 40, 160) -- Purple
	elseif petGroup.rarity == "Legendary" then
		detailViewport.BackgroundColor3 = Color3.fromRGB(120, 100, 20) -- Gold
	else
		detailViewport.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Default dark
	end

	detailViewport.BackgroundTransparency = 0
	detailViewport.BorderSizePixel = 0
	detailViewport.LightColor = Color3.fromRGB(255, 255, 255)
	detailViewport.LightDirection = Vector3.new(-1, -1, -1)
	detailViewport.Ambient = Color3.fromRGB(150, 150, 150)

	-- Add rounded corners to viewport
	local viewportCorner = Instance.new("UICorner")
	viewportCorner.CornerRadius = UDim.new(0, 8)
	viewportCorner.Parent = detailViewport

	detailViewport.Parent = detailsPanel

	-- Create close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -10, 0, 10)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "X"
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BorderSizePixel = 0

	-- Make it circular
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.5, 0)
	buttonCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		detailsPanel:Destroy()
	end)
	closeButton.Parent = detailsPanel

	-- Setup the 3D model with enhanced presentation
	local modelName = petGroup.modelName or 
		(petGroup.name:find("Corgi") and "Corgi" or "RedPanda")
	pcall(function()
		SetupPetModel(detailViewport, modelName, petGroup.rarity)
	end)

	-- Add the panel to the frame with a nice appear animation
	detailsPanel.Size = UDim2.new(0, 0, 0, 0)
	detailsPanel.Parent = inventoryFrame

	-- Animate panel appearing
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(
		detailsPanel, 
		tweenInfo, 
		{Size = UDim2.new(0.7, 0, 0.8, 0)}
	)
	tween:Play()

	-- Add equip button (if you want to add equip functionality)
	local equipButton = Instance.new("TextButton")
	equipButton.Size = UDim2.new(0.8, 0, 0, 40)
	equipButton.Position = UDim2.new(0.5, 0, 0.9, 0)
	equipButton.AnchorPoint = Vector2.new(0.5, 0.5)
	equipButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	equipButton.Text = "Equip Pet"
	equipButton.TextSize = 18
	equipButton.Font = Enum.Font.GothamBold
	equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipButton.BorderSizePixel = 0

	-- Rounded corners
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = equipButton

	-- Button gradient
	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Rotation = 90
	buttonGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 215))
	})
	buttonGradient.Parent = equipButton

	equipButton.MouseButton1Click:Connect(function()
		-- Implement equip functionality
		print("Equipping pet:", petGroup.name)

		-- This is where you would add code to equip the pet
		-- For example, fire a remote event to the server

		-- Show confirmation
		local confirmation = Instance.new("TextLabel")
		confirmation.Size = UDim2.new(1, 0, 0, 30)
		confirmation.Position = UDim2.new(0, 0, 1, 10)
		confirmation.BackgroundTransparency = 1
		confirmation.Text = "Pet equipped!"
		confirmation.TextSize = 16
		confirmation.Font = Enum.Font.GothamBold
		confirmation.TextColor3 = Color3.fromRGB(100, 255, 100)
		confirmation.Parent = equipButton

		-- Remove after 2 seconds
		spawn(function()
			wait(2)
			if confirmation.Parent then
				confirmation:Destroy()
			end
		end)
	end)

	equipButton.Parent = detailsPanel
end

-- Update player stats display
local function UpdateStats()
	if not playerData then
		warn("Player data is nil in UpdateStats")
		return
	end

	updateLabelText(coinsLabel, "Coins: " .. (playerData.coins or 0))
	updateLabelText(gemsLabel, "Gems: " .. (playerData.gems or 0))
	updateLabelText(petsLabel, "Pets: " .. (#playerData.pets or 0) .. "/100") -- Assuming max 100 pets
end

-- Update inventory display with grouping
local function UpdateInventory()
	if not inventoryFrame then 
		warn("Inventory frame not found")
		return 
	end

	print("Updating inventory with " .. #playerData.pets .. " pets")

	-- Clear existing pet displays and empty message
	for _, child in pairs(inventoryFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "PetTemplate" and child.Name ~= "ViewportTester" then
			child:Destroy()
		end
	end

	-- Get template or create one if it doesn't exist
	local petTemplate = inventoryFrame:FindFirstChild("PetTemplate")
	if not petTemplate then
		print("Creating new pet template with ViewportFrame")
		petTemplate = CreatePetTemplate()
		petTemplate.Parent = inventoryFrame
	end

	-- Display pets
	if not playerData or not playerData.pets then
		warn("Player data or pets table is nil in UpdateInventory")
		return
	end

	-- If there are no pets, show a message
	if #playerData.pets == 0 then
		local emptyMessage = Instance.new("TextLabel")
		emptyMessage.Name = "EmptyMessage"
		emptyMessage.Size = UDim2.new(1, -20, 0, 40)
		emptyMessage.Position = UDim2.new(0, 10, 0, 50)
		emptyMessage.Text = "No pets collected yet. Click on pets in the world to collect them!"
		emptyMessage.TextSize = 18
		emptyMessage.Font = Enum.Font.GothamBold
		emptyMessage.TextColor3 = Color3.fromRGB(80, 80, 80)
		emptyMessage.TextWrapped = true
		emptyMessage.BackgroundTransparency = 1
		emptyMessage.Parent = inventoryFrame
		return
	end

	-- Group pets by type and rarity
	local petGroups = {}

	for _, pet in ipairs(playerData.pets) do
		local key = pet.name .. "_" .. pet.rarity

		if not petGroups[key] then
			petGroups[key] = {
				name = pet.name,
				rarity = pet.rarity,
				modelName = pet.modelName,
				count = 1,
				level = pet.level, -- Use level of first pet
				highestLevel = pet.level -- Track highest level
			}
		else
			petGroups[key].count = petGroups[key].count + 1

			-- Keep track of highest level pet in the group
			if pet.level > petGroups[key].highestLevel then
				petGroups[key].highestLevel = pet.level
			end
		end
	end

	-- Convert the groups dictionary to an array for easier sorting
	local groupedPets = {}
	for _, group in pairs(petGroups) do
		table.insert(groupedPets, group)
	end

	-- Sort pets by rarity (Legendary -> Epic -> Rare -> Common)
	local rarityOrder = {
		["Legendary"] = 1,
		["Epic"] = 2,
		["Rare"] = 3,
		["Common"] = 4
	}

	table.sort(groupedPets, function(a, b)
		return (rarityOrder[a.rarity] or 99) < (rarityOrder[b.rarity] or 99)
	end)

	-- Calculate grid layout
	local petWidth = petTemplate.Size.X.Offset + 10 -- Adding margin
	local petHeight = petTemplate.Size.Y.Offset + 10 -- Adding margin
	local inventoryWidth = inventoryFrame.AbsoluteSize.X
	local petsPerRow = math.floor(inventoryWidth / petWidth)

	-- Ensure at least 1 pet per row
	if petsPerRow < 1 then petsPerRow = 1 end

	for i, petGroup in ipairs(groupedPets) do
		print("Creating display for pet group: " .. petGroup.name .. " x" .. petGroup.count)

		local petFrame = petTemplate:Clone()
		petFrame.Name = "PetGroup_" .. petGroup.name .. "_" .. petGroup.rarity
		petFrame.Visible = true

		-- Update text labels
		local nameLabel = petFrame:FindFirstChild("NameLabel")
		local rarityLabel = petFrame:FindFirstChild("RarityLabel")
		local levelLabel = petFrame:FindFirstChild("LevelLabel")

		-- Add a count indicator
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(0, 50, 0, 50)
		countLabel.Position = UDim2.new(1, -5, 0, 5)
		countLabel.AnchorPoint = Vector2.new(1, 0)
		countLabel.Text = "x" .. petGroup.count
		countLabel.TextSize = 24
		countLabel.Font = Enum.Font.GothamBlack
		countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		countLabel.TextStrokeTransparency = 0
		countLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Parent = petFrame

		-- Add visual indicator of multiple pets
		local stackIndicator = Instance.new("Frame")
		stackIndicator.Name = "StackIndicator"
		stackIndicator.Size = UDim2.new(0, 106, 0, 86)
		stackIndicator.Position = UDim2.new(0.5, -53, 0, 7)
		stackIndicator.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		stackIndicator.BorderSizePixel = 0
		stackIndicator.ZIndex = 0
		stackIndicator.Parent = petFrame

		-- Stack effect for multiple pets
		if petGroup.count > 1 then
			for i = 1, math.min(3, petGroup.count - 1) do
				local stackLayer = stackIndicator:Clone()
				stackLayer.Size = UDim2.new(0, 106 - (i * 3), 0, 86 - (i * 3))
				stackLayer.Position = UDim2.new(0.5, -53 + (i * 3), 0, 7 + (i * 2))
				stackLayer.ZIndex = -i
				stackLayer.Parent = petFrame
			end
		end

		if nameLabel then nameLabel.Text = petGroup.name end

		if rarityLabel then
			rarityLabel.Text = petGroup.rarity

			-- Color based on rarity
			if petGroup.rarity == "Common" then
				rarityLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray
			elseif petGroup.rarity == "Rare" then
				rarityLabel.TextColor3 = Color3.fromRGB(30, 144, 255) -- Blue
			elseif petGroup.rarity == "Epic" then
				rarityLabel.TextColor3 = Color3.fromRGB(138, 43, 226) -- Purple
			elseif petGroup.rarity == "Legendary" then
				rarityLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
			end
		end

		if levelLabel then 
			-- Level label moved to highest level display
			levelLabel.Text = "Level: " .. petGroup.highestLevel
		end

		-- Add shimmer effect for high-rarity pets
		if petGroup.rarity == "Epic" or petGroup.rarity == "Legendary" then
			-- Add shimmer effect for high-rarity pets
			local shimmer = petFrame:FindFirstChild("Shimmer")
			if shimmer then
				-- Create the shimmer overlay
				local shimmerOverlay = Instance.new("Frame")
				shimmerOverlay.Name = "ShimmerOverlay"
				shimmerOverlay.Size = UDim2.new(3, 0, 0, 2) -- Wide but thin line
				shimmerOverlay.Position = UDim2.new(-1, 0, 0, 0) -- Start off-screen
				shimmerOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				shimmerOverlay.BackgroundTransparency = 0.7
				shimmerOverlay.BorderSizePixel = 0
				shimmerOverlay.Rotation = 45 -- Diagonal line
				shimmerOverlay.ZIndex = 5
				shimmerOverlay.Parent = shimmer

				-- Create the animation
				spawn(function()
					while petFrame and petFrame.Parent do
						-- Animate the shimmer moving across the frame
						shimmerOverlay.Position = UDim2.new(-1, 0, 0, math.random(-20, 120))

						local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
						local tween = TweenService:Create(
							shimmerOverlay,
							tweenInfo,
							{Position = UDim2.new(1, 0, 0, shimmerOverlay.Position.Y.Offset)}
						)

						tween:Play()
						wait(math.random(3, 6)) -- Random delay between shimmers
					end
				end)
			end
		end

		-- Setup the 3D model in the ViewportFrame
		local petViewport = petFrame:FindFirstChild("PetViewport")
		if petViewport then
			local modelName = petGroup.modelName or 
				(petGroup.name:find("Corgi") and "Corgi" or "RedPanda")

			pcall(function() -- Use pcall to prevent errors from stopping the whole function
				SetupPetModel(petViewport, modelName, petGroup.rarity)
			end)
		end

		-- Position the pet frame in a grid layout
		local xPos = (i - 1) % petsPerRow
		local yPos = math.floor((i - 1) / petsPerRow)

		petFrame.Position = UDim2.new(
			0, xPos * petWidth + 10, -- 10px initial margin
			0, yPos * petHeight + 10  -- 10px initial margin
		)

		-- Make it clickable to show details
		local clickDetector = Instance.new("TextButton")
		clickDetector.Size = UDim2.new(1, 0, 1, 0)
		clickDetector.Position = UDim2.new(0, 0, 0, 0)
		clickDetector.BackgroundTransparency = 1
		clickDetector.Text = ""
		clickDetector.ZIndex = 10
		clickDetector.Parent = petFrame

		-- Add click handler to show pet details
		clickDetector.MouseButton1Click:Connect(function()
			ShowPetDetails(petGroup)
		end)

		petFrame.Parent = inventoryFrame
	end
end

-- Update My Upgrades display
local function UpdateMyUpgrades()
	if not myUpgradesFrame then return end

	-- Clear existing content
	for _, child in pairs(myUpgradesFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Check if player has any upgrades
	local hasUpgrades = false
	for upgradeName, level in pairs(playerData.upgrades) do
		if level > 1 then -- Level 1 is default, so only show if higher
			hasUpgrades = true
			break
		end
	end

	-- If no upgrades, show message
	if not hasUpgrades then
		local noUpgradesLabel = Instance.new("TextLabel")
		noUpgradesLabel.Name = "NoUpgradesLabel"
		noUpgradesLabel.Size = UDim2.new(1, -20, 0, 40)
		noUpgradesLabel.Position = UDim2.new(0, 10, 0, 50)
		noUpgradesLabel.Text = "You haven't purchased any upgrades yet. Visit the shop to buy upgrades!"
		noUpgradesLabel.TextSize = 18
		noUpgradesLabel.Font = Enum.Font.GothamBold
		noUpgradesLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
		noUpgradesLabel.TextWrapped = true
		noUpgradesLabel.BackgroundTransparency = 1
		noUpgradesLabel.Parent = myUpgradesFrame
		return
	end

	-- Create upgrade cards for each purchased upgrade
	local yOffset = 10
	for upgradeName, level in pairs(playerData.upgrades) do
		if level > 1 then -- Level 1 is default, so only show if higher
			-- Create upgrade card
			local upgradeCard = Instance.new("Frame")
			upgradeCard.Name = "UpgradeCard_" .. upgradeName
			upgradeCard.Size = UDim2.new(1, -20, 0, 80)
			upgradeCard.Position = UDim2.new(0, 10, 0, yOffset)
			upgradeCard.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			upgradeCard.BorderSizePixel = 0

			-- Add corners
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = upgradeCard

			-- Add title
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Size = UDim2.new(1, -20, 0, 30)
			titleLabel.Position = UDim2.new(0, 10, 0, 5)
			titleLabel.Text = upgradeName
			titleLabel.TextSize = 18
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.BackgroundTransparency = 1
			titleLabel.Parent = upgradeCard

			-- Add level indicator
			local levelLabel = Instance.new("TextLabel")
			levelLabel.Size = UDim2.new(1, -20, 0, 20)
			levelLabel.Position = UDim2.new(0, 10, 0, 35)
			levelLabel.Text = "Level: " .. level
			levelLabel.TextSize = 16
			levelLabel.Font = Enum.Font.Gotham
			levelLabel.TextColor3 = Color3.fromRGB(0, 120, 215)
			levelLabel.TextXAlignment = Enum.TextXAlignment.Left
			levelLabel.BackgroundTransparency = 1
			levelLabel.Parent = upgradeCard

			-- Add effect description based on upgrade type
			local effectText = ""
			if upgradeName == "Collection Speed" then
				effectText = "+" .. ((level - 1) * 10) .. "% Collection Speed"
			elseif upgradeName == "Pet Capacity" then
				effectText = "+" .. ((level - 1) * 5) .. " Pet Capacity"
			elseif upgradeName == "Collection Value" then
				effectText = "+" .. ((level - 1) * 20) .. "% Collection Value"
			end

			local effectLabel = Instance.new("TextLabel")
			effectLabel.Size = UDim2.new(1, -20, 0, 20)
			effectLabel.Position = UDim2.new(0, 10, 0, 55)
			effectLabel.Text = effectText
			effectLabel.TextSize = 14
			effectLabel.Font = Enum.Font.Gotham
			effectLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
			effectLabel.TextXAlignment = Enum.TextXAlignment.Left
			effectLabel.BackgroundTransparency = 1
			effectLabel.Parent = upgradeCard

			upgradeCard.Parent = myUpgradesFrame
			yOffset = yOffset + 90 -- Move down for next card
		end
	end
end

-- Update My Areas display
local function UpdateMyAreas()
	if not myAreasFrame then return end

	-- Clear existing content
	for _, child in pairs(myAreasFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Check if player has unlocked areas
	if #playerData.unlockedAreas <= 1 then -- Only starter area
		local noAreasLabel = Instance.new("TextLabel")
		noAreasLabel.Name = "NoAreasLabel"
		noAreasLabel.Size = UDim2.new(1, -20, 0, 40)
		noAreasLabel.Position = UDim2.new(0, 10, 0, 50)
		noAreasLabel.Text = "You haven't unlocked any additional areas yet. Visit the shop to unlock new areas!"
		noAreasLabel.TextSize = 18
		noAreasLabel.Font = Enum.Font.GothamBold
		noAreasLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
		noAreasLabel.TextWrapped = true
		noAreasLabel.BackgroundTransparency = 1
		noAreasLabel.Parent = myAreasFrame
		return
	end

	-- Create area cards
	local yOffset = 10
	for _, areaName in ipairs(playerData.unlockedAreas) do
		-- Create area card
		local areaCard = Instance.new("Frame")
		areaCard.Name = "AreaCard_" .. areaName
		areaCard.Size = UDim2.new(1, -20, 0, 100)
		areaCard.Position = UDim2.new(0, 10, 0, yOffset)
		areaCard.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
		areaCard.BorderSizePixel = 0

		-- Add corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = areaCard

		-- Area image (placeholder)
		local areaImage = Instance.new("ImageLabel")
		areaImage.Size = UDim2.new(0, 80, 0, 80)
		areaImage.Position = UDim2.new(0, 10, 0, 10)
		areaImage.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		areaImage.BorderSizePixel = 0

		-- Try to set an area-specific image based on name
		if areaName == "Starter Meadow" then
			areaImage.BackgroundColor3 = Color3.fromRGB(120, 200, 80) -- Green
		elseif areaName == "Mystic Forest" then
			areaImage.BackgroundColor3 = Color3.fromRGB(80, 160, 100) -- Dark green
		elseif areaName == "Dragon's Lair" then
			areaImage.BackgroundColor3 = Color3.fromRGB(200, 80, 80) -- Red
		end

		-- Add corners to image
		local imageCorner = Instance.new("UICorner")
		imageCorner.CornerRadius = UDim.new(0, 8)
		imageCorner.Parent = areaImage

		areaImage.Parent = areaCard

		-- Add area name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -110, 0, 30)
		nameLabel.Position = UDim2.new(0, 100, 0, 10)
		nameLabel.Text = areaName
		nameLabel.TextSize = 18
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = areaCard

		-- Add visit button
		local visitButton = Instance.new("TextButton")
		visitButton.Size = UDim2.new(0, 100, 0, 30)
		visitButton.Position = UDim2.new(0, 100, 0, 50)
		visitButton.Text = "Visit Area"
		visitButton.TextSize = 16
		visitButton.Font = Enum.Font.GothamBold
		visitButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		visitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		visitButton.BorderSizePixel = 0

		-- Add corners to button
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = visitButton

		-- Button click logic
		visitButton.MouseButton1Click:Connect(function()
			-- Logic to teleport player to area
			local Areas = workspace:FindFirstChild("Areas")
			if Areas and Areas:FindFirstChild(areaName) then
				local area = Areas[areaName]
				local spawnLocation

				-- Find a suitable spawn location
				if area:FindFirstChild("SpawnLocation") then
					spawnLocation = area.SpawnLocation
				elseif area:FindFirstChild("SpawnLocations") and area.SpawnLocations:FindFirstChildOfClass("BasePart") then
					spawnLocation = area.SpawnLocations:FindFirstChildOfClass("BasePart")
				else
					-- Look for any part that might be a spawn
					for _, child in pairs(area:GetDescendants()) do
						if child:IsA("BasePart") and 
							(child.Name:lower():find("spawn") or child.Name:lower():find("start")) then
							spawnLocation = child
							break
						end
					end
				end

				-- If we found a spawn location, teleport the player
				if spawnLocation and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					player.Character.HumanoidRootPart.CFrame = 
						CFrame.new(spawnLocation.Position + Vector3.new(0, 5, 0))

					-- Show confirmation message
					local confirmationMessage = Instance.new("TextLabel")
					confirmationMessage.Size = UDim2.new(0, 200, 0, 40)
					confirmationMessage.Position = UDim2.new(0.5, -100, 0.8, 0)
					confirmationMessage.AnchorPoint = Vector2.new(0, 0.5)
					confirmationMessage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					confirmationMessage.BackgroundTransparency = 0.2
					confirmationMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
					confirmationMessage.TextSize = 16
					confirmationMessage.Font = Enum.Font.GothamBold
					confirmationMessage.Text = "Teleported to " .. areaName
					confirmationMessage.TextWrapped = true

					-- Add corners
					local msgCorner = Instance.new("UICorner")
					msgCorner.CornerRadius = UDim.new(0, 8)
					msgCorner.Parent = confirmationMessage

					confirmationMessage.Parent = player.PlayerGui:WaitForChild("MainGui")

					-- Remove message after 3 seconds
					spawn(function()
						wait(3)
						confirmationMessage:Destroy()
					end)
				end
			end
		end)

		visitButton.Parent = areaCard
		areaCard.Parent = myAreasFrame

		yOffset = yOffset + 110 -- Move down for next card
	end
end

-- Safe function to update a label's text
local function updateLabelText(label, text)
	if label then
		label.Text = text
	else
		warn("Tried to update nil label with text: " .. text)
	end
end

-- Update player stats display
local function UpdateStats()
	if not playerData then
		warn("Player data is nil in UpdateStats")
		return
	end

	updateLabelText(coinsLabel, "Coins: " .. (playerData.coins or 0))
	updateLabelText(gemsLabel, "Gems: " .. (playerData.gems or 0))
	updateLabelText(petsLabel, "Pets: " .. (#playerData.pets or 0) .. "/100") -- Assuming max 100 pets
end

-- Tab switching function
local function SwitchTab(tabName)
	-- Show UI if it's hidden when switching tabs
	if not uiVisible then
		ToggleUIVisibility()
	end

	-- Hide all content frames
	if inventoryFrame then inventoryFrame.Visible = false end
	if myUpgradesFrame then myUpgradesFrame.Visible = false end
	if myAreasFrame then myAreasFrame.Visible = false end

	-- Reset all button colors
	if inventoryButton then inventoryButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215) end
	if myUpgradesButton then myUpgradesButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215) end
	if myAreasButton then myAreasButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215) end

	-- Show selected content and highlight button
	if tabName == "Inventory" and inventoryFrame and inventoryButton then
		inventoryFrame.Visible = true
		inventoryButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		UpdateInventory()
	elseif tabName == "MyUpgrades" and myUpgradesFrame and myUpgradesButton then
		myUpgradesFrame.Visible = true
		myUpgradesButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		UpdateMyUpgrades()
	elseif tabName == "MyAreas" and myAreasFrame and myAreasButton then
		myAreasFrame.Visible = true
		myAreasButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		UpdateMyAreas()
	end
end

-- Initialize GUI - only call this after all functions are defined!
local function InitializeGUI()
	-- Set all content frames invisible except inventory
	if inventoryFrame then inventoryFrame.Visible = true end
	if myUpgradesFrame then myUpgradesFrame.Visible = false end
	if myAreasFrame then myAreasFrame.Visible = false end

	-- Highlight inventory button
	if inventoryButton then inventoryButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end -- Highlighted color
	if myUpgradesButton then myUpgradesButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215) end -- Normal color
	if myAreasButton then myAreasButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215) end

	-- Initial stats update
	UpdateStats()

	-- Initial inventory update
	UpdateInventory()

	-- Initial upgrades and areas update
	UpdateMyUpgrades()
	UpdateMyAreas()

	-- Start with UI visible
	uiVisible = true
	if buttonsFrame then buttonsFrame.Visible = true end
	if contentFrame then contentFrame.Visible = true end

	print("GUI initialized successfully!")
end

-- Add a keyboard shortcut for toggling UI
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.H then
		-- H key to toggle UI visibility
		ToggleUIVisibility()
	end
end)

-- Setup button events
if inventoryButton then
	inventoryButton.MouseButton1Click:Connect(function()
		SwitchTab("Inventory")
	end)
end

if myUpgradesButton then
	myUpgradesButton.MouseButton1Click:Connect(function()
		SwitchTab("MyUpgrades")
	end)
end

if myAreasButton then
	myAreasButton.MouseButton1Click:Connect(function()
		SwitchTab("MyAreas")
	end)
end

-- Listen for player data updates
UpdatePlayerStats.OnClientEvent:Connect(function(newData)
	if newData then
		print("Received updated player data with " .. #newData.pets .. " pets")
		playerData = newData

		-- Always update stats
		UpdateStats()

		-- Update currently visible tab
		if inventoryFrame and inventoryFrame.Visible then
			UpdateInventory()
		elseif myUpgradesFrame and myUpgradesFrame.Visible then
			UpdateMyUpgrades()
		elseif myAreasFrame and myAreasFrame.Visible then
			UpdateMyAreas()
		end
	else
		warn("Received nil playerData in UpdatePlayerStats event")
	end
end)

-- Create a mini info button that shows when UI is hidden
local function CreateMiniInfoButton()
	local miniInfo = Instance.new("Frame")
	miniInfo.Name = "MiniInfo"
	miniInfo.Size = UDim2.new(0, 100, 0, 40)
	miniInfo.Position = UDim2.new(0, 10, 0, 60)
	miniInfo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	miniInfo.BackgroundTransparency = 0.5
	miniInfo.BorderSizePixel = 0
	miniInfo.Visible = false
	miniInfo.Parent = mainGui

	-- Add corner radius
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = miniInfo

	-- Add coins text
	local miniCoinsText = Instance.new("TextLabel")
	miniCoinsText.Name = "MiniCoinsText"
	miniCoinsText.Size = UDim2.new(1, 0, 1, 0)
	miniCoinsText.Position = UDim2.new(0, 0, 0, 0)
	miniCoinsText.Text = "100 🪙"
	miniCoinsText.TextSize = 16
	miniCoinsText.Font = Enum.Font.GothamBold
	miniCoinsText.TextColor3 = Color3.fromRGB(255, 215, 0)
	miniCoinsText.BackgroundTransparency = 1
	miniCoinsText.Parent = miniInfo

	-- Make it clickable to show UI
	local clickButton = Instance.new("TextButton")
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.Position = UDim2.new(0, 0, 0, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = miniInfo

	clickButton.MouseButton1Click:Connect(ToggleUIVisibility)

	return miniInfo
end

-- Create mini info if it doesn't exist
local miniInfo = mainGui:FindFirstChild("MiniInfo")
if not miniInfo then
	miniInfo = CreateMiniInfoButton()
end

-- Update the toggle visibility function to show/hide mini info
local originalToggleUIVisibility = ToggleUIVisibility
ToggleUIVisibility = function()
	originalToggleUIVisibility()

	-- Show/hide mini info when toggling UI
	if miniInfo then
		miniInfo.Visible = not uiVisible

		-- Update mini info text if needed
		if not uiVisible and miniInfo:FindFirstChild("MiniCoinsText") and playerData then
			miniInfo.MiniCoinsText.Text = tostring(playerData.coins) .. " 🪙"
		end
	end
end

-- Make player data accessible to other scripts
local function GetPlayerData()
	return playerData
end

-- Expose this function through a BindableFunction
local getPlayerDataFunc = Instance.new("BindableFunction")
getPlayerDataFunc.Name = "GetPlayerData"
getPlayerDataFunc.OnInvoke = GetPlayerData
getPlayerDataFunc.Parent = script

-- Initialize GUI at the END of the script, after all functions are defined
spawn(function()
	-- Wait a moment to ensure everything is loaded
	wait(1)

	-- Safe function call with error handling
	local success, err = pcall(InitializeGUI)
	if not success then
		warn("Error in InitializeGUI: " .. tostring(err))
	end
end)

print("Updated GUI script loaded with Inventory, MyUpgrades, and MyAreas tabs!")