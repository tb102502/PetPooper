-- PetInitializer.lua
-- Place this in ServerScriptService
-- Centralizes pet creation and initialization

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PetMovementModule = require(Modules:WaitForChild("PetMovementModule"))
local PetJumpModule = require(Modules:WaitForChild("PetJumpModule"))

local PetInitializer = {}

-- Function to fully initialize a pet with both movement and jumping
function PetInitializer.SetupPet(pet, movementConfig, jumpSettings)
	if not pet then
		warn("PetInitializer: Cannot setup nil pet")
		return nil
	end

	-- Configure pet rarity-specific behaviors
	local rarity = pet:GetAttribute("Rarity") or "Common"

	-- Default configs based on rarity if none provided
	movementConfig = movementConfig or {}
	jumpSettings = jumpSettings or {}

	-- Set defaults based on rarity
	if rarity == "Common" then
		movementConfig.moveSpeed = movementConfig.moveSpeed or 2
		movementConfig.wanderRadius = movementConfig.wanderRadius or 5
		jumpSettings.jumpHeight = jumpSettings.jumpHeight or 2
	elseif rarity == "Rare" then
		movementConfig.moveSpeed = movementConfig.moveSpeed or 2.5
		movementConfig.wanderRadius = movementConfig.wanderRadius or 7
		jumpSettings.jumpHeight = jumpSettings.jumpHeight or 2.5
	elseif rarity == "Epic" then
		movementConfig.moveSpeed = movementConfig.moveSpeed or 3
		movementConfig.wanderRadius = movementConfig.wanderRadius or 10
		jumpSettings.jumpHeight = jumpSettings.jumpHeight or 3
	elseif rarity == "Legendary" then
		movementConfig.moveSpeed = movementConfig.moveSpeed or 3.5
		movementConfig.wanderRadius = movementConfig.wanderRadius or 15
		jumpSettings.jumpHeight = jumpSettings.jumpHeight or 4

		-- Legendary pets have special movement behavior
		movementConfig.movementType = movementConfig.movementType or PetMovementModule.MovementTypes.ORBIT
	end

	-- Initialize pet behaviors
	PetMovementModule.initPet(pet, movementConfig)
	PetJumpModule.initJumping(pet, jumpSettings)

	-- Add any visual effects based on rarity
	AddRarityEffects(pet, rarity)

	return pet
end

-- Helper function to add visual effects based on rarity
function AddRarityEffects(pet, rarity)
	if rarity == "Epic" or rarity == "Legendary" then
		-- Create an attachment for particles
		local primaryPart = pet.PrimaryPart or pet:FindFirstChild("HumanoidRootPart") or pet:FindFirstChild("Torso")
		if not primaryPart then return end

		local attachment = Instance.new("Attachment")
		attachment.Parent = primaryPart

		-- Create particle emitter
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxassetid://6880496507" -- Star/sparkle texture
		particles.LightEmission = 0.5
		particles.Lifetime = NumberRange.new(0.5, 1.5)
		particles.Speed = NumberRange.new(0.5, 1)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.4),
			NumberSequenceKeypoint.new(1, 1)
		})

		-- Different settings based on rarity
		if rarity == "Epic" then
			particles.Color = ColorSequence.new(Color3.fromRGB(138, 43, 226)) -- Purple
			particles.Size = NumberSequence.new(0.15)
			particles.Rate = 10
			particles.Name = "EpicParticles"
		else -- Legendary
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Gold
			particles.Size = NumberSequence.new(0.25)
			particles.Rate = 20
			particles.Name = "LegendaryParticles"

			-- Add extra glow for legendary
			local pointLight = Instance.new("PointLight")
			pointLight.Color = Color3.fromRGB(255, 215, 0)
			pointLight.Range = 10
			pointLight.Brightness = 1
			pointLight.Parent = primaryPart
		end

		particles.Parent = attachment
	end
end

-- Function to create a pet model if one doesn't exist in ReplicatedStorage
function PetInitializer.CreateBasicPetModel(name, modelType, position)
	local model = Instance.new("Model")
	model.Name = name

	-- Create a humanoid for animations
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	-- Create a humanoid root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 0.5
	rootPart.CanCollide = false
	rootPart.Anchored = true
	rootPart.Position = position
	rootPart.Parent = model

	-- Create a head part
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Shape = modelType == "Corgi" and Enum.PartType.Block or Enum.PartType.Ball
	head.Position = position + Vector3.new(0, 1, 0)
	head.Anchored = true
	head.CanCollide = false

	-- Set color based on model type
	if modelType == "Corgi" then
		head.Color = Color3.fromRGB(240, 195, 137) -- Tan
	elseif modelType == "RedPanda" then
		head.Color = Color3.fromRGB(188, 74, 60) -- Reddish
	elseif modelType == "Panda" then
		head.Color = Color3.fromRGB(240, 240, 240) -- White
	elseif modelType == "Goat" then
		head.Color = Color3.fromRGB(180, 180, 180) -- Gray
	elseif modelType == "Hamster" then
		head.Color = Color3.fromRGB(220, 180, 130) -- Light brown
	else
		head.Color = Color3.fromRGB(188, 74, 60) -- Default reddish
	end

	head.Parent = model

	-- Create a body part
	local body = Instance.new("Part")
	body.Name = "Torso"
	body.Size = Vector3.new(2, 2, 3)
	body.Position = position + Vector3.new(0, 0, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Color = head.Color
	body.Parent = model

	-- Create eyes
	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Shape = Enum.PartType.Ball
	rightEye.Size = Vector3.new(0.4, 0.4, 0.4)
	rightEye.Position = head.Position + Vector3.new(0.5, 0.3, -0.8)
	rightEye.Color = Color3.fromRGB(0, 0, 0)
	rightEye.Anchored = true
	rightEye.CanCollide = false
	rightEye.Parent = model

	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.4, 0.4, 0.4)
	leftEye.Position = head.Position + Vector3.new(-0.5, 0.3, -0.8)
	leftEye.Color = Color3.fromRGB(0, 0, 0)
	leftEye.Anchored = true
	leftEye.CanCollide = false
	leftEye.Parent = model

	-- Set the primary part
	model.PrimaryPart = rootPart

	-- Add a ClickDetector for interaction
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = rootPart

	return model
end

return PetInitializer