-- ViewportRenderer.lua
-- Handles creating and managing 3D viewports for pets
-- Place in StarterGui/MainGui/GuiModules/Utility/

local ViewportRenderer = {}

-- Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local activePetModels = {}
local isInitialized = false

-- Initialize the renderer
function ViewportRenderer.Initialize()
	if isInitialized then return end

	isInitialized = true
	print("ViewportRenderer initialized")
end

-- Function to setup a pet model in a ViewportFrame
function ViewportRenderer.SetupPetModel(viewport, modelName, rarity)
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
		local modelCFrame

		-- Try to use GetPivot for modern Roblox
		local success, modelPivot = pcall(function()
			return model:GetPivot()
		end)

		if success then
			modelCFrame = modelPivot
		else
			-- Fallback for older Roblox versions
			modelCFrame = model.PrimaryPart.CFrame
		end

		local offset = CFrame.new() - modelCFrame.Position

		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CFrame = part.CFrame * offset
			end
		end

		-- Calculate model size
		local modelSize
		success, modelSize = pcall(function()
			return model:GetExtentsSize()
		end)

		if not success then
			-- Fallback size estimation
			modelSize = Vector3.new(3, 3, 3)
		end

		local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z)

		-- Position camera closer for larger appearance
		local distance = maxSize * 1.2 -- Closer camera

		-- Set camera to a slightly lower angled position
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
	local function RotatePetModel(model, speed)
		if not model or not model.Parent then return end

		-- Track this model for rotation
		local modelId = tostring(model:GetFullName())

		-- Store rotation info
		activePetModels[modelId] = {
			model = model,
			speed = speed or 20,
			startTime = tick()
		}
	end

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

-- Connect to RenderStepped to update all active pet models
RunService.RenderStepped:Connect(function(dt)
	for modelId, modelData in pairs(activePetModels) do
		local model = modelData.model

		-- Check if model still exists
		if not model or not model.Parent then
			activePetModels[modelId] = nil
			continue
		end

		-- Skip if no primary part
		if not model.PrimaryPart then
			continue
		end

		-- Calculate rotation angle based on time
		local elapsedTime = tick() - modelData.startTime
		local rotationAngle = elapsedTime * math.rad(modelData.speed)

		-- Apply rotation
		model:SetPrimaryPartCFrame(
			CFrame.new(model.PrimaryPart.Position) * 
				CFrame.Angles(0, rotationAngle, 0)
		)
	end
end)

-- Function to create a 3D viewport-based pet template
function ViewportRenderer.CreatePetTemplate()
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

return ViewportRenderer