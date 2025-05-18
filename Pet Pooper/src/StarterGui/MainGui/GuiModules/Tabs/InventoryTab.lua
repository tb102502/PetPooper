-- Updated InventoryTab.lua (ModuleScript)
-- Simplified and cleaned up version
-- Place in StarterGui/MainGui/GuiModules/Tabs/InventoryTab.lua

local InventoryTab = {}

-- Module imports
local ViewportRenderer = require(script.Parent.Parent.Utility.ViewportRenderer)
local DataManager = require(script.Parent.Parent.Utility.DataManager)

-- Services
local TweenService = game:GetService("TweenService")

-- Tab frame reference
local inventoryFrame = nil
local petTemplate = nil

-- Initialize the tab
function InventoryTab.Initialize(frame, playerData)
	print("Initializing Inventory Tab...")

	-- Store references
	inventoryFrame = frame

	-- Create pet template
	petTemplate = InventoryTab.CreatePetTemplate()
	petTemplate.Parent = inventoryFrame

	-- Initial update
	InventoryTab.Update(playerData)

	print("Inventory Tab initialization complete!")
end

-- Create pet template
function InventoryTab.CreatePetTemplate()
	-- Use ViewportRenderer to create the template
	local template = ViewportRenderer.CreatePetTemplate()
	template.Name = "PetTemplate"
	template.Visible = false

	return template
end

-- Group pets by name and rarity
local function GroupPets(pets)
	local petGroups = {}

	for _, pet in ipairs(pets) do
		local key = pet.name .. "_" .. pet.rarity

		if not petGroups[key] then
			petGroups[key] = {
				name = pet.name,
				rarity = pet.rarity,
				modelName = pet.modelName,
				count = 1,
				level = pet.level,
				highestLevel = pet.level,
				pets = {pet}
			}
		else
			petGroups[key].count = petGroups[key].count + 1
			table.insert(petGroups[key].pets, pet)

			-- Track highest level
			if pet.level > petGroups[key].highestLevel then
				petGroups[key].highestLevel = pet.level
			end
		end
	end

	-- Convert to array and sort by rarity
	local groupedPets = {}
	for _, group in pairs(petGroups) do
		table.insert(groupedPets, group)
	end

	-- Sort by rarity (Legendary -> Epic -> Rare -> Common)
	local rarityOrder = {
		["Legendary"] = 1,
		["Epic"] = 2,
		["Rare"] = 3,
		["Common"] = 4
	}

	table.sort(groupedPets, function(a, b)
		return (rarityOrder[a.rarity] or 99) < (rarityOrder[b.rarity] or 99)
	end)

	return groupedPets
end

-- Create pet display frame
local function CreatePetDisplay(petGroup, layoutOrder)
	local petFrame = petTemplate:Clone()
	petFrame.Name = "PetGroup_" .. petGroup.name .. "_" .. petGroup.rarity
	petFrame.Visible = true
	petFrame.LayoutOrder = layoutOrder

	-- Update labels
	local nameLabel = petFrame:FindFirstChild("NameLabel")
	local rarityLabel = petFrame:FindFirstChild("RarityLabel")

	if nameLabel then nameLabel.Text = petGroup.name end
	if rarityLabel then
		rarityLabel.Text = petGroup.rarity

		-- Color based on rarity
		local rarityColors = {
			["Common"] = Color3.fromRGB(200, 200, 200),
			["Rare"] = Color3.fromRGB(30, 144, 255),
			["Epic"] = Color3.fromRGB(138, 43, 226),
			["Legendary"] = Color3.fromRGB(255, 215, 0)
		}

		rarityLabel.TextColor3 = rarityColors[petGroup.rarity] or Color3.fromRGB(150, 150, 150)
	end

	-- Add count indicator if more than 1
	if petGroup.count > 1 then
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(0, 50, 0, 50)
		countLabel.Position = UDim2.new(1, -5, 0, 5)
		countLabel.AnchorPoint = Vector2.new(1, 0)
		countLabel.Text = "x" .. petGroup.count
		countLabel.TextSize = 20
		countLabel.Font = Enum.Font.GothamBlack
		countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		countLabel.TextStrokeTransparency = 0
		countLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.ZIndex = 10
		countLabel.Parent = petFrame
	end

	-- Setup 3D model
	local petViewport = petFrame:FindFirstChild("PetViewport")
	if petViewport then
		local modelName = petGroup.modelName or 
			(petGroup.name:find("Corgi") and "Corgi" or "RedPanda")

		spawn(function()
			ViewportRenderer.SetupPetModel(petViewport, modelName, petGroup.rarity)
		end)
	end

	-- Add shimmer effect for high-rarity pets
	if petGroup.rarity == "Epic" or petGroup.rarity == "Legendary" then
		InventoryTab.AddShimmerEffect(petFrame)
	end

	-- Make clickable
	local clickButton = Instance.new("TextButton")
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.Position = UDim2.new(0, 0, 0, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.ZIndex = 5
	clickButton.Parent = petFrame

	clickButton.MouseButton1Click:Connect(function()
		InventoryTab.ShowPetDetails(petGroup)
	end)

	return petFrame
end

-- Add shimmer effect to pet frame
function InventoryTab.AddShimmerEffect(petFrame)
	local shimmer = petFrame:FindFirstChild("Shimmer")
	if not shimmer then return end

	-- Create shimmer overlay
	local shimmerOverlay = Instance.new("Frame")
	shimmerOverlay.Name = "ShimmerOverlay"
	shimmerOverlay.Size = UDim2.new(3, 0, 0, 3)
	shimmerOverlay.Position = UDim2.new(-1, 0, 0, 0)
	shimmerOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shimmerOverlay.BackgroundTransparency = 0.7
	shimmerOverlay.BorderSizePixel = 0
	shimmerOverlay.Rotation = 45
	shimmerOverlay.ZIndex = 4
	shimmerOverlay.Parent = shimmer

	-- Animate shimmer
	spawn(function()
		while petFrame and petFrame.Parent do
			-- Reset position
			shimmerOverlay.Position = UDim2.new(-1, 0, 0, math.random(-20, 120))

			-- Animate across frame
			local tween = TweenService:Create(
				shimmerOverlay,
				TweenInfo.new(1, Enum.EasingStyle.Linear),
				{Position = UDim2.new(1, 0, 0, shimmerOverlay.Position.Y.Offset)}
			)
			tween:Play()

			wait(math.random(3, 6))
		end
	end)
end

-- Show pet details panel
function InventoryTab.ShowPetDetails(petGroup)
	-- Remove existing panel
	local existingPanel = inventoryFrame:FindFirstChild("PetDetailsPanel")
	if existingPanel then
		existingPanel:Destroy()
	end

	-- Create details panel
	local detailsPanel = Instance.new("Frame")
	detailsPanel.Name = "PetDetailsPanel"
	detailsPanel.Size = UDim2.new(0, 0, 0, 0)
	detailsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	detailsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	detailsPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	detailsPanel.BorderSizePixel = 0
	detailsPanel.ZIndex = 20
	detailsPanel.Parent = inventoryFrame

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = detailsPanel

	-- Add title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = petGroup.name
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.ZIndex = 21
	titleLabel.Parent = detailsPanel

	-- Add close button
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
	closeButton.ZIndex = 22
	closeButton.Parent = detailsPanel

	-- Rounded button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.5, 0)
	buttonCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		detailsPanel:Destroy()
	end)

	-- Animate panel appearing
	local tween = TweenService:Create(
		detailsPanel,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0.7, 0, 0.8, 0)}
	)
	tween:Play()
end

-- Update inventory display
function InventoryTab.Update(playerData)
	if not inventoryFrame then 
		warn("Inventory frame not found")
		return 
	end

	print("Updating inventory with " .. #(playerData.pets or {}) .. " pets")

	-- Clear existing displays
	for _, child in pairs(inventoryFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:find("PetGroup_") then
			child:Destroy()
		end
	end

	-- Show empty message if no pets
	if not playerData.pets or #playerData.pets == 0 then
		local emptyMessage = Instance.new("TextLabel")
		emptyMessage.Name = "EmptyMessage"
		emptyMessage.Size = UDim2.new(1, -20, 0, 60)
		emptyMessage.Position = UDim2.new(0, 10, 0, 50)
		emptyMessage.Text = "No pets collected yet!\nClick on pets in the world to collect them!"
		emptyMessage.TextSize = 18
		emptyMessage.Font = Enum.Font.GothamBold
		emptyMessage.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyMessage.TextWrapped = true
		emptyMessage.BackgroundTransparency = 1
		emptyMessage.Parent = inventoryFrame
		return
	end

	-- Group and display pets
	local groupedPets = GroupPets(playerData.pets)

	-- Add UIGridLayout for proper positioning
	local gridLayout = inventoryFrame:FindFirstChild("GridLayout")
	if not gridLayout then
		gridLayout = Instance.new("UIGridLayout")
		gridLayout.Name = "GridLayout"
		gridLayout.CellSize = UDim2.new(0, 120, 0, 160)
		gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.Parent = inventoryFrame
	end

	-- Create displays for each pet group
	for i, petGroup in ipairs(groupedPets) do
		local petDisplay = CreatePetDisplay(petGroup, i)
		petDisplay.Parent = inventoryFrame
	end
end

return InventoryTab