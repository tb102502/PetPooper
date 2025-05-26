-- Add this to a ServerScript that runs when the game starts
-- Place in ServerScriptService to set up the necessary pet models

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the PetModels folder if it doesn't exist
local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
if not petModelsFolder then
	petModelsFolder = Instance.new("Folder")
	petModelsFolder.Name = "PetModels"
	petModelsFolder.Parent = ReplicatedStorage
	print("Created PetModels folder in ReplicatedStorage")
end

-- Function to create a basic fallback model if you don't have actual models
local function CreateBasicPetModel(name, mainColor)
	local model = Instance.new("Model")
	model.Name = name

	-- Create humanoid for R6 animation compatibility
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	-- Create parts
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Shape = Enum.PartType.Ball
	head.Color = mainColor
	head.Position = rootPart.Position + Vector3.new(0, 0.5, 0)
	head.Parent = model

	local body = Instance.new("Part")
	body.Name = "Torso"
	body.Size = Vector3.new(2, 2, 3)
	body.Color = mainColor
	body.Position = rootPart.Position + Vector3.new(0, -1, 0)
	body.Parent = model

	-- Add legs
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Color = mainColor
	rightLeg.Position = rootPart.Position + Vector3.new(1, -3, 0)
	rightLeg.Parent = model

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Color = mainColor
	leftLeg.Position = rootPart.Position + Vector3.new(-1, -3, 0)
	leftLeg.Parent = model

	-- Add facial features
	local eye1 = Instance.new("Part")
	eye1.Name = "RightEye"
	eye1.Shape = Enum.PartType.Ball
	eye1.Size = Vector3.new(0.4, 0.4, 0.4)
	eye1.Color = Color3.fromRGB(0, 0, 0)
	eye1.Position = head.Position + Vector3.new(0.5, 0.3, -0.8)
	eye1.Parent = model

	local eye2 = Instance.new("Part")
	eye2.Name = "LeftEye"
	eye2.Shape = Enum.PartType.Ball
	eye2.Size = Vector3.new(0.4, 0.4, 0.4)
	eye2.Color = Color3.fromRGB(0, 0, 0)
	eye2.Position = head.Position + Vector3.new(-0.5, 0.3, -0.8)
	eye2.Parent = model

	-- Set primary part
	model.PrimaryPart = rootPart

	return model
end

-- Create basic models if they don't exist
if not petModelsFolder:FindFirstChild("Corgi") then
	local corgiModel = CreateBasicPetModel("Corgi", Color3.fromRGB(240, 195, 137)) -- Tan color
	corgiModel.Parent = petModelsFolder
	print("Created fallback Corgi model")
end

if not petModelsFolder:FindFirstChild("RedPanda") then
	local pandaModel = CreateBasicPetModel("RedPanda", Color3.fromRGB(188, 74, 60)) -- Reddish color
	pandaModel.Parent = petModelsFolder
	print("Created fallback RedPanda model")
end

print("Pet model setup in ReplicatedStorage complete")