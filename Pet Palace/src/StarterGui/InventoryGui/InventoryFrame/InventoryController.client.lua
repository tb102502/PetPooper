-- InventoryController.client.lua
-- Place this in StarterGui/InventoryGui/InventoryFrame
-- This script manages the inventory tabs and content

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local UpgradesFrame = script.Parent

-- Track current tab
local currentTab = "Pets"

-- Initialize player data
local playerData = {
	pets = {},
	upgrades = {},
	unlockedAreas = {"Starter Meadow"}
}

-- Try to load the RemoteFunctions
local function safeGetRemoteFunction(name)
	local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not RemoteFunctions then return nil end

	return RemoteFunctions:FindFirstChild(name)
end

-- Try to get player data from server
local GetPlayerData = safeGetRemoteFunction("GetPlayerData")
if GetPlayerData then
	local success, result = pcall(function()
		return GetPlayerData:InvokeServer()
	end)

	if success and result then
		playerData = result
		print("Successfully loaded player data")
	end
end

-- Update player data when it changes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if RemoteEvents then
	local UpdatePlayerStats = RemoteEvents:FindFirstChild("UpdatePlayerStats")
	if UpdatePlayerStats then
		UpdatePlayerStats.OnClientEvent:Connect(function(newData)
			playerData = newData
			updateCurrentTab()
			print("Updated inventory with new player data")
		end)
	end
end


local tabNames = {"Pets", "Inventory", "Collecting", "Advanced"}

	for i, tabName in ipairs(tabNames) do
		local tabButton = Instance.new("TextButton")
		-- Connect tab button
		tabButton.MouseButton1Click:Connect(function()
		
	end)
end

-- Switch between tabs
function switchTab(tabName)
	-- Update current tab
	currentTab = tabName

	-- Show/hide content frames
	local contentContainer = UpgradesFrame:FindFirstChild("ContentContainer")
	if contentContainer then
		for _, child in pairs(contentContainer:GetChildren()) do
			if child:IsA("ScrollingFrame") then
				child.Visible = child.Name == tabName .. "Content"
			end
		end
	end

	-- Update content for the selected tab
	updateTabContent(tabName)
end

-- Update current tab
function updateCurrentTab()
	updateTabContent(currentTab)
end

-- Function to create a pet display
local function createPetDisplay(pet, petTemplate)
	if not petTemplate then
		-- Create a template if not provided
		petTemplate = Instance.new("Frame")
		petTemplate.Name = "PetTemplate"
		petTemplate.Size = UDim2.new(0, 120, 0, 160)
		petTemplate.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		petTemplate.BorderSizePixel = 0

		-- Add ViewportFrame for pet model
		local petViewport = Instance.new("ViewportFrame")
		petViewport.Name = "PetViewport"
		petViewport.Size = UDim2.new(0, 100, 0, 100)
		petViewport.Position = UDim2.new(0.5, 0, 0, 10)
		petViewport.AnchorPoint = Vector2.new(0.5, 0)
		petViewport.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		petViewport.BackgroundTransparency = 0
		petViewport.Parent = petTemplate

		-- Add name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0, 20)
		nameLabel.Position = UDim2.new(0, 0, 0, 115)
		nameLabel.Text = "Pet Name"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = petTemplate

		-- Add rarity label
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Name = "RarityLabel"
		rarityLabel.Size = UDim2.new(1, 0, 0, 20)
		rarityLabel.Position = UDim2.new(0, 0, 0, 135)
		rarityLabel.Text = "Common"
		rarityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		rarityLabel.Font = Enum.Font.Gotham
		rarityLabel.TextSize = 12
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Parent = petTemplate

		-- Add corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = petTemplate

		local viewportCorner = Instance.new("UICorner")
		viewportCorner.CornerRadius = UDim.new(0, 8)
		viewportCorner.Parent = petViewport
	end

	-- Clone the template
	local petDisplay = petTemplate:Clone()
	petDisplay.Name = pet.name .. "_" .. (pet.id or "0")
	petDisplay.Visible = true

	-- Update pet information
	local nameLabel = petDisplay:FindFirstChild("NameLabel")
	if nameLabel then
		nameLabel.Text = pet.name
	end

	local rarityLabel = petDisplay:FindFirstChild("RarityLabel")
	if rarityLabel then
		rarityLabel.Text = pet.rarity

		-- Color based on rarity
		if pet.rarity == "Common" then
			rarityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		elseif pet.rarity == "Rare" then
			rarityLabel.TextColor3 = Color3.fromRGB(30, 144, 255)
		elseif pet.rarity == "Epic" then
			rarityLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
		elseif pet.rarity == "Legendary" then
			rarityLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		end
	end

	-- Try to setup viewport model
	local petViewport = petDisplay:FindFirstChild("PetViewport")
	if petViewport then
		setupPetModel(petViewport, pet)
	end

	return petDisplay
end

-- Function to setup 3D model in viewport
function setupPetModel(viewport, pet)
	-- Make sure we have a camera
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(0, 0, 5), Vector3.new(0, 0, 0))
	viewport.CurrentCamera = camera
	camera.Parent = viewport

	-- Create world model
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	-- Try to find model in ReplicatedStorage
	local modelName = pet.modelName or (pet.name:find("Corgi") and "Corgi" or "RedPanda")
	local success, model = pcall(function()
		if ReplicatedStorage:FindFirstChild("PetModels") and 
			ReplicatedStorage.PetModels:FindFirstChild(modelName) then
			return ReplicatedStorage.PetModels:FindFirstChild(modelName):Clone()
		end
		return nil
	end)

	if not success or not model then
		-- Create fallback model
		model = createFallbackModel(pet)
	end

	if model then
		model.Parent = worldModel

		-- Set up rotation
		spawn(function()
			local angle = 0
			game:GetService("RunService").RenderStepped:Connect(function(dt)
				if model and model.Parent then
					angle = angle + dt * 0.5
					if model.PrimaryPart then
						model:SetPrimaryPartCFrame(
							CFrame.new(Vector3.new(0, 0, 0)) * 
								CFrame.Angles(0, angle, 0)
						)
					end
				end
			end)
		end)
	end
end

-- Function to create a fallback pet model
function createFallbackModel(pet)
	local model = Instance.new("Model")
	model.Name = pet.name

	-- Create body part
	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2, 2, 2)
	body.Position = Vector3.new(0, 0, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	-- Color based on pet type and rarity
	if pet.name:find("Corgi") then
		body.Color = Color3.fromRGB(240, 195, 137) -- Tan
	elseif pet.name:find("RedPanda") then
		body.Color = Color3.fromRGB(188, 74, 60) -- Reddish
	elseif pet.name:find("Hamster") then
		body.Color = Color3.fromRGB(220, 180, 130) -- Light brown
	else
		body.Color = Color3.fromRGB(200, 200, 200) -- Gray default
	end

	-- Apply rarity effects
	if pet.rarity == "Rare" then
		body.Material = Enum.Material.Neon
		body.Color = body.Color:Lerp(Color3.fromRGB(30, 144, 255), 0.3)
	elseif pet.rarity == "Epic" then
		body.Material = Enum.Material.Neon
		body.Color = body.Color:Lerp(Color3.fromRGB(138, 43, 226), 0.4)
	elseif pet.rarity == "Legendary" then
		body.Material = Enum.Material.Neon
		body.Color = body.Color:Lerp(Color3.fromRGB(255, 215, 0), 0.5)
	end

	-- Create eyes
	local rightEye = Instance.new("Part")
	rightEye.Shape = Enum.PartType.Ball
	rightEye.Size = Vector3.new(0.4, 0.4, 0.4)
	rightEye.Position = Vector3.new(0.5, 0.3, -0.8)
	rightEye.Color = Color3.fromRGB(0, 0, 0)
	rightEye.Anchored = true
	rightEye.CanCollide = false
	rightEye.Parent = model

	local leftEye = Instance.new("Part")
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.4, 0.4, 0.4)
	leftEye.Position = Vector3.new(-0.5, 0.3, -0.8)
	leftEye.Color = Color3.fromRGB(0, 0, 0)
	leftEye.Anchored = true
	leftEye.CanCollide = false
	leftEye.Parent = model

	-- Set primary part
	model.PrimaryPart = body

	return model
end

-- Function to update tab content
function updateTabContent(tabName)
	local contentContainer = UpgradesFrame:FindFirstChild("ContentContainer")
	if not contentContainer then return end

	local contentFrame = contentContainer:FindFirstChild(tabName .. "Content")
	if not contentFrame then return end

	-- Clear existing content (except layouts)
	for _, child in pairs(contentFrame:GetChildren()) do
		if not child:IsA("UIGridLayout") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	if tabName == "Pets" then
		updatePetsTab(contentFrame)
	elseif tabName == "Upgrades" then
		updateUpgradesTab(contentFrame)
	elseif tabName == "Areas" then
		updateAreasTab(contentFrame)
	end
end

-- Update the Pets tab
function updatePetsTab(contentFrame)
	-- Look for existing template
	local template = UpgradesFrame:FindFirstChild("PetTemplate")

	-- Show empty message if no pets
	if not playerData.pets or #playerData.pets == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 50)
		emptyLabel.Position = UDim2.new(0, 10, 0, 10)
		emptyLabel.Text = "You haven't collected any pets yet! Click on pets in the world to collect them."
		emptyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 18
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.TextWrapped = true
		emptyLabel.Parent = contentFrame
		return
	end

	-- Add each pet
	for i, pet in ipairs(playerData.pets) do
		local petDisplay = createPetDisplay(pet, template)
		petDisplay.LayoutOrder = i
		petDisplay.Parent = contentFrame
	end

	-- Update canvas size (handled by GridLayout callback)
end

-- Update the Upgrades tab
function updateUpgradesTab(contentFrame)
	-- Get upgrade data
	local upgrades = playerData.upgrades or {}
	local upgradesList = {
		{ id = "Collection Speed", name = "Collection Speed", description = "Collect pets faster", maxLevel = 10 },
		{ id = "Pet Capacity", name = "Pet Capacity", description = "Carry more pets at once", maxLevel = 5 },
		{ id = "Collection Value", name = "Collection Value", description = "Increase the value of collected pets", maxLevel = 10 },
		-- Add more upgrades here based on your game
		{ id = "walkSpeed", name = "Walk Speed", description = "Increases your walking speed", maxLevel = 10 },
		{ id = "stamina", name = "Stamina", description = "Increases your maximum stamina", maxLevel = 5 }
	}

	-- Add each upgrade
	for i, upgradeInfo in ipairs(upgradesList) do
		-- Get current level
		local currentLevel = upgrades[upgradeInfo.id] or 1

		-- Create upgrade item
		local upgradeItem = Instance.new("Frame")
		upgradeItem.Name = "Upgrade_" .. upgradeInfo.id
		upgradeItem.Size = UDim2.new(0.9, 0, 0, 80)
		upgradeItem.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		upgradeItem.BorderSizePixel = 0
		upgradeItem.LayoutOrder = i

		-- Add title
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, -20, 0, 30)
		titleLabel.Position = UDim2.new(0, 10, 0, 5)
		titleLabel.Text = upgradeInfo.name
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 18
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Parent = upgradeItem

		-- Add description
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescLabel"
		descLabel.Size = UDim2.new(0.7, -20, 0, 20)
		descLabel.Position = UDim2.new(0, 10, 0, 35)
		descLabel.Text = upgradeInfo.description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 14
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.BackgroundTransparency = 1
		descLabel.Parent = upgradeItem

		-- Add level indicator
		local levelLabel = Instance.new("TextLabel")
		levelLabel.Name = "LevelLabel"
		levelLabel.Size = UDim2.new(0.3, 0, 0, 20)
		levelLabel.Position = UDim2.new(0.7, 0, 0, 35)
		levelLabel.Text = "Level: " .. currentLevel .. "/" .. upgradeInfo.maxLevel
		levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		levelLabel.Font = Enum.Font.GothamBold
		levelLabel.TextSize = 14
		levelLabel.BackgroundTransparency = 1
		levelLabel.Parent = upgradeItem

		-- Add progress bar
		local progressBg = Instance.new("Frame")
		progressBg.Name = "ProgressBg"
		progressBg.Size = UDim2.new(1, -20, 0, 10)
		progressBg.Position = UDim2.new(0, 10, 0, 60)
		progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		progressBg.BorderSizePixel = 0
		progressBg.Parent = upgradeItem

		local progressFill = Instance.new("Frame")
		progressFill.Name = "ProgressFill"
		progressFill.Size = UDim2.new(currentLevel / upgradeInfo.maxLevel, 0, 1, 0)
		progressFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		progressFill.BorderSizePixel = 0
		progressFill.Parent = progressBg

		-- Add corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = upgradeItem

		local progressCorner = Instance.new("UICorner")
		progressCorner.CornerRadius = UDim.new(0, 4)
		progressCorner.Parent = progressBg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 4)
		fillCorner.Parent = progressFill

		upgradeItem.Parent = contentFrame
	end
end

-- Update the Areas tab
function updateAreasTab(contentFrame)
	-- Define areas
	local areasList = {
		{ name = "Starter Meadow", description = "The beginning area with basic pets.", cost = 0 },
		{ name = "Mystic Forest", description = "A magical forest with rare pets.", cost = 1000 },
		{ name = "Dragon's Lair", description = "Home to legendary pets.", cost = 10000 }
	}

	-- Get unlocked areas
	local unlockedAreas = playerData.unlockedAreas or {"Starter Meadow"}

	-- Add each area
	for i, areaInfo in ipairs(areasList) do
		-- Check if area is unlocked
		local isUnlocked = false
		for _, area in ipairs(unlockedAreas) do
			if area == areaInfo.name then
				isUnlocked = true
				break
			end
		end

		-- Create area item
		local areaItem = Instance.new("Frame")
		areaItem.Name = "Area_" .. areaInfo.name
		areaItem.Size = UDim2.new(0.9, 0, 0, 100)
		areaItem.BackgroundColor3 = isUnlocked and 
			Color3.fromRGB(50, 80, 50) or -- Unlocked color
			Color3.fromRGB(50, 50, 50)    -- Locked color
		areaItem.BorderSizePixel = 0
		areaItem.LayoutOrder = i

		-- Add title
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, -20, 0, 30)
		titleLabel.Position = UDim2.new(0, 10, 0, 5)
		titleLabel.Text = areaInfo.name
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 20
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Parent = areaItem

		-- Add description
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescLabel"
		descLabel.Size = UDim2.new(0.7, -20, 0, 40)
		descLabel.Position = UDim2.new(0, 10, 0, 35)
		descLabel.Text = areaInfo.description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 14
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.BackgroundTransparency = 1
		descLabel.Parent = areaItem

		-- Add status label
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "StatusLabel"
		statusLabel.Size = UDim2.new(0.3, -10, 0, 30)
		statusLabel.Position = UDim2.new(0.7, 0, 0, 40)
		statusLabel.Text = isUnlocked and "UNLOCKED" or ("Cost: " .. areaInfo.cost)
		statusLabel.TextColor3 = isUnlocked and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 0)
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.TextSize = 16
		statusLabel.BackgroundTransparency = 1
		statusLabel.Parent = areaItem

		-- Add teleport button if unlocked
		if isUnlocked then
			local teleportButton = Instance.new("TextButton")
			teleportButton.Name = "TeleportButton"
			teleportButton.Size = UDim2.new(0.3, -20, 0, 30)
			teleportButton.Position = UDim2.new(0.7, 0, 0, 60)
			teleportButton.Text = "TELEPORT"
			teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			teleportButton.Font = Enum.Font.GothamBold
			teleportButton.TextSize = 14
			teleportButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
			teleportButton.BorderSizePixel = 0
			teleportButton.Parent = areaItem

			-- Add corner
			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0, 6)
			buttonCorner.Parent = teleportButton

			-- Connect teleport functionality
			teleportButton.MouseButton1Click:Connect(function()
				-- Find area in workspace
				local areaModel = workspace:FindFirstChild("Areas"):FindFirstChild(areaInfo.name)
				if areaModel then
					-- Try to find spawn point
					local spawnLocation = areaModel:FindFirstChild("SpawnLocation")
					if not spawnLocation then
						-- Look for a SpawnLocations folder
						local spawnFolder = areaModel:FindFirstChild("SpawnLocations")
						if spawnFolder and #spawnFolder:GetChildren() > 0 then
							spawnLocation = spawnFolder:GetChildren()[1]
						end
					end

					-- Teleport the player
					if spawnLocation and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						player.Character.HumanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
					else
						print("Could not find spawn location for area:", areaInfo.name)
					end
				else
					print("Could not find area in workspace:", areaInfo.name)
				end
			end)
		end

		-- Add corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = areaItem

		areaItem.Parent = contentFrame
	end
end

-- Initialize tabs when the script loads
updateCurrentTab()

print("Inventory Controller initialized!")