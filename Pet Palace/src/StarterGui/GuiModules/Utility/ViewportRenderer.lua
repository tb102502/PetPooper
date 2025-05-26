-- FixedViewportRenderer.lua
-- Place in StarterGui/GuiModules/Utility/
-- Fixes issues with pet viewports not showing properly

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

	print("Setting up viewport for: " .. modelName .. " (" .. rarity .. ")")

	-- Set background color based on rarity (more vivid colors)
	local backgroundColor
	if rarity == "Common" then
		backgroundColor = Color3.fromRGB(200, 200, 200) -- Lighter gray
	elseif rarity == "Rare" then
		backgroundColor = Color3.fromRGB(50, 120, 220) -- Brighter blue
	elseif rarity == "Epic" then
		backgroundColor = Color3.fromRGB(128, 70, 190) -- Brighter purple
	elseif rarity == "Legendary" then
		backgroundColor = Color3.fromRGB(220, 180, 20) -- Brighter gold
	else
		backgroundColor = Color3.fromRGB(50, 50, 50) -- Default dark
	end

	-- Apply background color
	viewport.BackgroundColor3 = backgroundColor

	-- Clear previous viewport contents
	for _, child in pairs(viewport:GetChildren()) do
		if child:IsA("Camera") or child:IsA("Model") or child:IsA("WorldModel") then
			child:Destroy()
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
		print("Found and cloned model: " .. modelName)
	else
		-- Create a fallback model with better coloring
		print("Creating fallback model for: " .. modelName)
		model = Instance.new("Model")
		model.Name = modelName

		-- Create a simple part as the body with better coloring
		local body = Instance.new("Part")
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(2, 1.5, 2.5)
		body.Position = Vector3.new(0, 0, 0)
		body.Anchored = true
		body.CanCollide = false
		body.Name = "Body"

		-- Head part
		local head = Instance.new("Part")
		head.Shape = modelName == "Corgi" and Enum.PartType.Block or Enum.PartType.Ball
		head.Size = Vector3.new(1.5, 1.5, 1.5)
		head.Position = Vector3.new(0, 0.75, 1)
		head.Anchored = true
		head.CanCollide = false
		head.Name = "Head"

		-- Color based on pet type and rarity
		local bodyColor, headColor

		if modelName == "Corgi" then
			bodyColor = Color3.fromRGB(240, 195, 137) -- Tan for Corgi
			headColor = Color3.fromRGB(250, 210, 150) -- Lighter tan for head
		elseif modelName == "RedPanda" then
			bodyColor = Color3.fromRGB(188, 74, 60) -- Reddish for RedPanda
			headColor = Color3.fromRGB(200, 90, 75) -- Lighter reddish for head
		elseif modelName == "Hamster" then
			bodyColor = Color3.fromRGB(220, 180, 130) -- Light brown for Hamster
			headColor = Color3.fromRGB(230, 195, 150) -- Lighter brown for head
		elseif modelName == "Goat" then
			bodyColor = Color3.fromRGB(180, 180, 180) -- Gray for Goat
			headColor = Color3.fromRGB(200, 200, 200) -- Lighter gray for head
		elseif modelName == "Panda" then
			bodyColor = Color3.fromRGB(240, 240, 240) -- White for Panda
			headColor = bodyColor
		else
			bodyColor = Color3.fromRGB(230, 230, 230) -- Default light gray
			headColor = bodyColor
		end

		-- Apply rarity effects
		if rarity == "Rare" then
			-- Add slightly blue tint
			bodyColor = bodyColor:Lerp(Color3.fromRGB(100, 150, 255), 0.2)
			headColor = headColor:Lerp(Color3.fromRGB(100, 150, 255), 0.2)
		elseif rarity == "Epic" then
			-- Add purple tint
			bodyColor = bodyColor:Lerp(Color3.fromRGB(180, 80, 255), 0.3)
			headColor = headColor:Lerp(Color3.fromRGB(180, 80, 255), 0.3)
		elseif rarity == "Legendary" then
			-- Add gold tint
			bodyColor = bodyColor:Lerp(Color3.fromRGB(255, 215, 0), 0.4)
			headColor = headColor:Lerp(Color3.fromRGB(255, 215, 0), 0.4)
		end

		body.Color = bodyColor
		head.Color = headColor

		-- Set material based on rarity
		if rarity == "Common" then
			body.Material = Enum.Material.SmoothPlastic
			head.Material = Enum.Material.SmoothPlastic
		elseif rarity == "Rare" then
			body.Material = Enum.Material.Glass
			head.Material = Enum.Material.Glass
			body.Reflectance = 0.2
			head.Reflectance = 0.2
		elseif rarity == "Epic" then
			body.Material = Enum.Material.Neon
			head.Material = Enum.Material.Neon
			body.Reflectance = 0.1
			head.Reflectance = 0.1
		elseif rarity == "Legendary" then
			body.Material = Enum.Material.ForceField
			head.Material = Enum.Material.ForceField
			body.Reflectance = 0.4
			head.Reflectance = 0.4
		end

		-- Add eyes
		local rightEye = Instance.new("Part")
		rightEye.Shape = Enum.PartType.Ball
		rightEye.Size = Vector3.new(0.3, 0.3, 0.3)
		rightEye.Position = Vector3.new(0.3, 0.9, 1.6)
		rightEye.Color = Color3.fromRGB(0, 0, 0)
		rightEye.Material = Enum.Material.SmoothPlastic
		rightEye.Anchored = true
		rightEye.CanCollide = false
		rightEye.Name = "RightEye"

		local leftEye = Instance.new("Part")
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.3, 0.3, 0.3)
		leftEye.Position = Vector3.new(-0.3, 0.9, 1.6)
		leftEye.Color = Color3.fromRGB(0, 0, 0)
		leftEye.Material = Enum.Material.SmoothPlastic
		leftEye.Anchored = true
		leftEye.CanCollide = false
		leftEye.Name = "LeftEye"

		-- Add ears for certain pets
		if modelName == "Corgi" or modelName == "Hamster" then
			local rightEar = Instance.new("Part")
			rightEar.Shape = Enum.PartType.Cylinder
			rightEar.Size = Vector3.new(0.2, 0.5, 0.2)
			rightEar.CFrame = CFrame.new(0.5, 1.5, 0.8) * CFrame.Angles(0, 0, math.rad(90))
			rightEar.Color = bodyColor
			rightEar.Material = body.Material
			rightEar.Anchored = true
			rightEar.CanCollide = false
			rightEar.Name = "RightEar"

			local leftEar = rightEar:Clone()
			leftEar.Position = Vector3.new(-0.5, 1.5, 0.8)
			leftEar.Name = "LeftEar"

			rightEar.Parent = model
			leftEar.Parent = model
		end

		-- Add parts to model
		body.Parent = model
		head.Parent = model
		rightEye.Parent = model
		leftEye.Parent = model

		-- Set primary part
		model.PrimaryPart = body
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
		end
	end

	-- Add the model to the WorldModel
	model.Parent = worldModel

	-- Add lighting effects based on rarity
	if rarity == "Epic" or rarity == "Legendary" then
		local lightPart = Instance.new("Part")
		lightPart.Size = Vector3.new(0.1, 0.1, 0.1)
		lightPart.Transparency = 1
		lightPart.Anchored = true
		lightPart.CanCollide = false
		lightPart.Position = Vector3.new(0, 0, 0)
		lightPart.Parent = worldModel

		local pointLight = Instance.new("PointLight")
		pointLight.Range = 10
		pointLight.Brightness = 2

		if rarity == "Epic" then
			pointLight.Color = Color3.fromRGB(138, 43, 226) -- Purple
		else -- Legendary
			pointLight.Color = Color3.fromRGB(255, 215, 0) -- Gold
		end

		pointLight.Parent = lightPart
	end

	-- Position camera for best viewing
	if model and model.PrimaryPart then
		local modelSize = Vector3.new(3, 3, 3) -- Default size

		-- Position camera at an angle for better view
		local cameraPosition = Vector3.new(3, 2, 4)
		local lookAt = Vector3.new(0, 0.5, 0)

		camera.CFrame = CFrame.new(cameraPosition, lookAt)

		-- Add ambient lighting
		local ambientLight = Instance.new("PointLight")
		ambientLight.Range = 10
		ambientLight.Brightness = 1
		ambientLight.Color = Color3.fromRGB(255, 255, 255)
		ambientLight.Parent = camera
	end

	-- Start model rotation
	local modelId = "model_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
	activePetModels[modelId] = {
		model = model,
		speed = (rarity == "Legendary" and 40) or 
			(rarity == "Epic" and 30) or 
			(rarity == "Rare" and 25) or 20, -- Faster rotation for rarer pets
		startTime = tick()
	}

	return model
end

-- Function to create a 3D viewport-based pet template
function ViewportRenderer.CreatePetTemplate()
	local petTemplate = Instance.new("Frame")
	petTemplate.Name = "PetTemplate"
	petTemplate.Size = UDim2.new(0, 120, 0, 160)
	petTemplate.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	petTemplate.BorderColor3 = Color3.fromRGB(200, 200, 200)
	petTemplate.BorderSizePixel = 2
	petTemplate.Visible = false

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = petTemplate

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

	petViewport.Parent = petTemplate

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

	-- Create text labels
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 115)
	nameLabel.Text = "Pet Name"
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
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

	-- Add shimmer effect holder for high-rarity pets
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

-- Add shimmer effect to pet frame
function ViewportRenderer.AddShimmerEffect(petFrame, rarity)
	if not petFrame then return end

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

	-- Color the shimmer by rarity
	if rarity == "Epic" then
		shimmerOverlay.BackgroundColor3 = Color3.fromRGB(180, 120, 255) -- Purple
	elseif rarity == "Legendary" then
		shimmerOverlay.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	end

	-- Animate shimmer
	spawn(function()
		while petFrame and petFrame.Parent do
			-- Reset position
			shimmerOverlay.Position = UDim2.new(-1, 0, 0, math.random(-20, 120))

			-- Animate across frame
			local tween = game:GetService("TweenService"):Create(
				shimmerOverlay,
				TweenInfo.new(1, Enum.EasingStyle.Linear),
				{Position = UDim2.new(1, 0, 0, shimmerOverlay.Position.Y.Offset)}
			)
			tween:Play()

			wait(math.random(3, 6))
		end
	end)
end

-- Update pet rotation on RenderStepped
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

return ViewportRenderer