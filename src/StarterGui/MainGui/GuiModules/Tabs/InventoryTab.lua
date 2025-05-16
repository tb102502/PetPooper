-- InventoryTab.lua (ModuleScript)
-- Place in StarterGui/MainGui/GuiModules/Tabs/InventoryTab.lua

local InventoryTab = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- References
local player = Players.LocalPlayer
local ViewportRenderer = require(script.Parent.Parent.Utility.ViewportRenderer)

-- Tab frame reference
local inventoryFrame = nil

-- Pet template
local petTemplate = nil

-- Currently selected pet for details
local selectedPet = nil

-- Initialize the tab
function InventoryTab.Initialize(frame, playerData)
	print("Initializing Inventory Tab...")

	-- Store references
	inventoryFrame = frame

	-- Create pet template if it doesn't exist
	petTemplate = inventoryFrame:FindFirstChild("PetTemplate")
	if not petTemplate then
		petTemplate = InventoryTab.CreatePetTemplate()
		petTemplate.Parent = inventoryFrame
	end

	print("Inventory Tab initialization complete!")

	-- Initial update
	InventoryTab.Update(playerData)
end

-- Create pet template
function InventoryTab.CreatePetTemplate()
	local template = Instance.new("Frame")
	template.Name = "PetTemplate"
	template.Size = UDim2.new(0, 120, 0, 160)
	template.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	template.BorderColor3 = Color3.fromRGB(200, 200, 200)
	template.BorderSizePixel = 2
	template.Visible = false

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
	shadow.Parent = template

	-- Add rounded corners to the template
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = template

	-- Create ViewportFrame for 3D pet display
	local petViewport = Instance.new("ViewportFrame")
	petViewport.Name = "PetViewport"
	petViewport.Size = UDim2.new(0, 100, 0, 100)
	petViewport.Position = UDim2.new(0.5, 0, 0, 10)
	petViewport.AnchorPoint = Vector2.new(0.5, 0)
	petViewport.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	petViewport.BackgroundTransparency = 0
	petViewport.BorderSizePixel = 0
	petViewport.LightColor = Color3.fromRGB(255, 255, 255)
	petViewport.LightDirection = Vector3.new(-1, -1, -1)
	petViewport.Ambient = Color3.fromRGB(150, 150, 150)

	-- Add rounded corners to viewport
	local viewportCorner = Instance.new("UICorner")
	viewportCorner.CornerRadius = UDim.new(0, 8)
	viewportCorner.Parent = petViewport

	petViewport.Parent = template

	-- Add rarity indicator
	local rarityIndicator = Instance.new("Frame")
	rarityIndicator.Name = "RarityIndicator"
	rarityIndicator.Size = UDim2.new(1, 0, 0, 4)
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
	nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent = template

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, -10, 0, 20)
	rarityLabel.Position = UDim2.new(0, 5, 0, 135)
	rarityLabel.Text = "Common"
	rarityLabel.TextSize = 12
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Parent = template

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
	shimmer.Parent = template

	return template
end

-- Update inventory display
function InventoryTab.Update(playerData)
	if not inventoryFrame then 
		warn("Inventory frame not found")
		return 
	end

	print("Updating inventory with " .. #playerData.pets .. " pets")

	-- Clear existing pet displays and empty message
	for _, child in pairs(inventoryFrame:GetChildren()) do
		if child:IsA("Frame") and 
			child.Name ~= "PetTemplate" and 
			child.Name ~= "ViewportTester" and 
			child.Name ~= "PetDetailsPanel" then
			child:Destroy()
		end
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
				level = pet.level,
				highestLevel = pet.level
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
				ViewportRenderer.SetupPetModel(petViewport, modelName, petGroup.rarity)
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
			InventoryTab.ShowPetDetails(petGroup)
		end)

		petFrame.Parent = inventoryFrame
	end
end

-- Show pet details panel
function InventoryTab.ShowPetDetails(petGroup)
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
		ViewportRenderer.SetupPetModel(detailViewport, modelName, petGroup.rarity)
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

return InventoryTab