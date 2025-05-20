-- RevisedPetSystem.lua
-- Place in ServerScriptService
-- This is a system that avoids generating script source code dynamically

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RevisedPetSystem = {}

-- Create necessary folders
local function ensureFolder(parent, name)
	if not parent:FindFirstChild(name) then
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
		print("Created folder: " .. name .. " in " .. parent.Name)
		return folder
	end
	return parent:FindFirstChild(name)
end

-- Create template folders
local PetTemplates = ensureFolder(ServerScriptService, "PetTemplates")
local Modules = ensureFolder(ReplicatedStorage, "Modules")

-- Create template scripts if they don't exist
if not PetTemplates:FindFirstChild("MovementScript") then
	local script = Instance.new("Script")
	script.Name = "MovementScript"
	script.Enabled = false -- Will be enabled when cloned

	-- We only need to define this once since we'll be cloning it
	script.Source = [[
local myHuman = script.Parent:WaitForChild("Humanoid")
local myRoot = script.Parent:WaitForChild("Torso")
local pathArgs = {
	["AgentRadius"] = 2,
	["AgentHeight"] = 3
}

if id then
	print(id.Value)
end

function findDist(torso)
	return (myRoot.Position - torso.Position).Magnitude
end

function findTarget()
	local dist = 65
	local target = nil
	for i,v in ipairs(workspace:GetChildren()) do
		local human = v:FindFirstChild("Humanoid")
		if human and v.Name ~= script.Parent.Name then
			local torso = human.Parent:FindFirstChild("Torso") or human.Parent:FindFirstChild("HumanoidRootPart")
			if torso then
				if findDist(torso) < dist and human.Health > 0 then
					target = torso
					dist = findDist(torso)
				end
			end
			
		end
	end
	return target
end

function getUnstuck()
	myHuman:Move(Vector3.new(math.random(-1,1),0,math.random(-1,1)))
	myHuman.Jump = true
	wait(1)
end

function checkSight(target)
	local ray = Ray.new(myRoot.Position, (target.Position - myRoot.Position).Unit * 20)
	local hit,position = workspace:FindPartOnRayWithIgnoreList(ray,{script.Parent})
	if hit then
		if hit:IsDescendantOf(target.Parent) then
			return true
		end
	end
	return false
end

function pathToTarget(target)
	local path = game:GetService("PathfindingService"):CreatePath(pathArgs)
	path:ComputeAsync(myRoot.Position,target.Position)
	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		for i,v in ipairs(waypoints) do
			if v.Action == Enum.PathWaypointAction.Jump then
				myHuman.Jump = true
			end
			myHuman:MoveTo(v.Position)
			spawn(function()
				wait(0.3)
				if myHuman.WalkToPoint.Y > myRoot.Position.Y then
					myHuman.Jump = true
				end
			end)
			local moveSucess = myHuman.MoveToFinished:Wait()
			if not moveSucess then
				getUnstuck()
				break
			end
			if checkSight(target) and math.abs(math.abs(myRoot.Position.Y) - math.abs(target.Position.Y)) < 3 then
				break
			end
			if (target.Position - waypoints[#waypoints].Position).Magnitude > 30 then
				break
			end
			if i % 5 == 0 then
				if findTarget() ~= target then
					break
				end
			end
		end
	else
		getUnstuck()
		print("Path failed")
	end
end

debounce = false

function main()
	local target = findTarget()
	if target then
		if checkSight(target) and math.abs(math.abs(myRoot.Position.Y) - math.abs(target.Position.Y)) < 3 then
			myHuman:MoveTo(target.Position)
			if findDist(target) < 10 then
				pathToTarget(target)
			end
		end
	else
		local torso = script.Parent:FindFirstChild("Torso")
		script.Parent.Humanoid:MoveTo(Vector3.new(math.random(-100,100),0,math.random(-100,100)), torso) 
	end
end

while wait() do
	if myHuman.Health < 1 then
		break
	end
	main()
end
]]

	script.Parent = PetTemplates
	print("Created MovementScript template")
end

if not PetTemplates:FindFirstChild("JumpScript") then
	local script = Instance.new("Script")
	script.Name = "JumpScript"
	script.Enabled = false -- Will be enabled when cloned

	script.Source = [[
-- SimplifiedJumpScript.lua
-- This script only applies vertical movement for jumping
-- and lets the existing Movement script handle all animations

local pet = script.Parent
local jumpWaitTime = math.random(5, 10) -- Random time between jumps
local jumpHeight = pet:GetAttribute("JumpHeight") or 2 -- How high the pet jumps

-- Function to safely get a reference part for applying jumps
local function getJumpReference()
	if pet.PrimaryPart then
		return pet.PrimaryPart
	end

	if pet:FindFirstChild("HumanoidRootPart") then
		return pet.HumanoidRootPart
	end

	if pet:FindFirstChild("Torso") then
		return pet.Torso
	end

	-- Last resort, find any BasePart
	for _, part in pairs(pet:GetChildren()) do
		if part:IsA("BasePart") then
			return part
		end
	end

	return nil
end

-- Main jump loop
while wait(jumpWaitTime) do
	-- Reset wait time for next jump
	jumpWaitTime = math.random(5, 10)

	-- Simple flag to indicate to any other scripts that the pet is jumping
	-- Movement scripts can check this attribute if they need to coordinate
	pet:SetAttribute("IsJumping", true)

	-- Get reference part
	local referencePart = getJumpReference()
	if not referencePart then 
		pet:SetAttribute("IsJumping", false)
		continue 
	end

	-- Store original position
	local originalY = referencePart.Position.Y

	-- Apply vertical impulse force (no animation, just physics)
	if referencePart:IsA("BasePart") and not referencePart.Anchored then
		-- If parts are unanchored, use physics (velocity)
		referencePart.Velocity = Vector3.new(
			referencePart.Velocity.X,
			jumpHeight * 10, -- Convert height to appropriate velocity
			referencePart.Velocity.Z
		)
	else
		-- If parts are anchored, we need to directly modify position
		-- Let's just add a simple upward offset - no animation
		if pet.PrimaryPart then
			local currentCFrame = pet:GetPrimaryPartCFrame()
			pet:SetPrimaryPartCFrame(currentCFrame + Vector3.new(0, jumpHeight, 0))

			-- Wait a brief moment
			wait(0.2)

			-- Return to original height
			pet:SetPrimaryPartCFrame(CFrame.new(
				currentCFrame.X, 
				originalY, 
				currentCFrame.Z
				) * currentCFrame.Rotation)
		else
			-- Just move the reference part
			local originalPosition = referencePart.Position
			referencePart.Position = Vector3.new(
				originalPosition.X,
				originalPosition.Y + jumpHeight,
				originalPosition.Z
			)

			-- Wait a brief moment
			wait(0.2)

			-- Return to original height
			referencePart.Position = Vector3.new(
				originalPosition.X,
				originalY,
				originalPosition.Z
			)
		end
	end

	-- Clear jumping flag
	wait(0.3)
	pet:SetAttribute("IsJumping", false)
end
]]

	script.Parent = PetTemplates
	print("Created JumpScript template")
end

-- Function to set up pet with proper behaviors
function RevisedPetSystem.SetupPet(pet, config)
	if not pet then return nil end

	-- Default configs
	config = config or {}
	local rarity = pet:GetAttribute("Rarity") or "Common"

	-- Set jump height based on rarity
	local jumpHeight = 2 -- Default
	if rarity == "Rare" then
		jumpHeight = 2.5
	elseif rarity == "Epic" then
		jumpHeight = 3
	elseif rarity == "Legendary" then
		jumpHeight = 4
	end

	-- Apply jump height attribute
	pet:SetAttribute("JumpHeight", config.jumpHeight or jumpHeight)

	-- Clone and add the scripts
	local movementTemplate = PetTemplates:FindFirstChild("MovementScript")
	local jumpTemplate = PetTemplates:FindFirstChild("JumpScript")

	if movementTemplate and jumpTemplate then
		-- Add movement script
		local movementScript = movementTemplate:Clone()
		movementScript.Name = "PetMovement"
		movementScript.Enabled = true
		movementScript.Parent = pet

		-- Add jump script
		local jumpScript = jumpTemplate:Clone()
		jumpScript.Name = "PetJump"
		jumpScript.Enabled = true
		jumpScript.Parent = pet

		print("Added behavior scripts to pet: " .. pet.Name)
	else
		warn("Could not find template scripts!")
	end

	-- Add visual effects based on rarity
	AddRarityEffects(pet, rarity)

	return pet
end

-- Function to add visual effects
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

-- Function to create a basic pet model
function RevisedPetSystem.CreateBasicPetModel(name, modelType, position)
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

-- A module script that provides pet-related functionality without using dynamic source generation
local function createPetSystemModule()
	if not Modules:FindFirstChild("PetSystem") then
		local module = Instance.new("ModuleScript")
		module.Name = "PetSystem"
		module.Source = [[
-- PetSystem Module
-- Safe version without dynamic code generation

local PetSystem = {}

-- References
local ServerScriptService = game:GetService("ServerScriptService")
local RevisedPetSystem = require(ServerScriptService:WaitForChild("RevisedPetSystem"))

-- Function to set up a pet
function PetSystem.SetupPet(pet, config)
    return RevisedPetSystem.SetupPet(pet, config)
end

-- Function to create a basic pet model
function PetSystem.CreateBasicPetModel(name, modelType, position)
    return RevisedPetSystem.CreateBasicPetModel(name, modelType, position)
end

return PetSystem
]]
		module.Parent = Modules
		print("Created PetSystem module")
	end
end

-- Create the module
createPetSystemModule()

return RevisedPetSystem