-- ModuleInitializer.server.lua
-- Place in ServerScriptService
-- This script ensures all required modules are created and available

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Function to safely create a folder if it doesn't exist
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

-- Create necessary folders
local Modules = ensureFolder(ReplicatedStorage, "Modules")
local ServerModules = ensureFolder(ServerStorage, "Modules")

-- Function to create a ModuleScript if it doesn't exist
local function createModuleScript(parent, name, source)
	if not parent:FindFirstChild(name) then
		local moduleScript = Instance.new("ModuleScript")
		moduleScript.Name = name
		moduleScript.Source = source
		moduleScript.Parent = parent
		print("Created ModuleScript: " .. name .. " in " .. parent.Name)
		return moduleScript
	end
	return parent:FindFirstChild(name)
end

-- Define the source for PetMovementModule
local petMovementSource = [[
-- PetMovementModule.lua
-- Module for centralized pet movement behaviors

local PetMovementModule = {}

-- Movement types
PetMovementModule.MovementTypes = {
    IDLE = "idle",
    WANDER = "wander",
    FOLLOW = "follow",
    ORBIT = "orbit"
}

-- Default configuration
PetMovementModule.DefaultConfig = {
    movementType = PetMovementModule.MovementTypes.WANDER,
    moveSpeed = 2,
    wanderRadius = 5,
    followDistance = 3,
    orbitRadius = 5,
    idleJumpChance = 0.1
}

-- Function to initialize a pet with movement behavior
function PetMovementModule.initPet(pet, config)
    if not pet then return end
    
    -- Merge config with defaults
    config = config or {}
    for key, defaultValue in pairs(PetMovementModule.DefaultConfig) do
        if config[key] == nil then
            config[key] = defaultValue
        end
    end
    
    -- Store config on the pet
    for key, value in pairs(config) do
        pet:SetAttribute(key, value)
    end
    
    -- Create a script that handles the pet's movement
    local script = Instance.new("Script")
    script.Name = "PetMovement"
    
    -- Paste the original Movement script code here
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

script.Parent = pet

-- Return the pet for chaining
return pet
end

-- Function to change a pet's movement behavior
function PetMovementModule.changeMovement(pet, newMovementType, newConfig)
	if not pet then return pet end

	newConfig = newConfig or {}
	newConfig.movementType = newMovementType

	-- Update pet attributes
	for key, value in pairs(newConfig) do
		pet:SetAttribute(key, value)
	end

	-- Find and restart the movement script
	local movementScript = pet:FindFirstChild("PetMovement")
	if movementScript then
		movementScript.Disabled = true
		wait(0.1)
		movementScript.Disabled = false
	end

	return pet
end

return PetMovementModule
]]

-- Define the source for PetJumpModule
local petJumpSource = [[
-- PetJumpModule.lua
-- Module for centralized pet jumping behaviors

local PetJumpModule = {}

-- Default jump settings
PetJumpModule.DefaultSettings = {
    minWaitTime = 5,
    maxWaitTime = 10,
    jumpHeight = 2
}

-- Function to initialize jumping for a pet
function PetJumpModule.initJumping(pet, settings)
    if not pet then return pet end
    
    -- Merge settings with defaults
    settings = settings or {}
    for key, defaultValue in pairs(PetJumpModule.DefaultSettings) do
        if settings[key] == nil then
            settings[key] = defaultValue
        end
    end
    
    -- Store settings on the pet
    for key, value in pairs(settings) do
        pet:SetAttribute("jump_" .. key, value)
    end
    
    -- Create a script that handles the pet's jumping
    local script = Instance.new("Script")
    script.Name = "PetJump"
    
    -- Paste the original JumpScript code here
    script.Source = [[
-- SimplifiedJumpScript.lua
-- This script only applies vertical movement for jumping
-- and lets the existing Movement script handle all animations

local pet = script.Parent
local jumpWaitTime = math.random(pet:GetAttribute("jump_minWaitTime") or 5, 
                                 pet:GetAttribute("jump_maxWaitTime") or 10)
local jumpHeight = pet:GetAttribute("jump_jumpHeight") or 2

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
	jumpWaitTime = math.random(pet:GetAttribute("jump_minWaitTime") or 5, 
                              pet:GetAttribute("jump_maxWaitTime") or 10)

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

script.Parent = pet

-- Return the pet for chaining
return pet
end

-- Function to adjust jump settings for a pet
function PetJumpModule.adjustJumpSettings(pet, newSettings)
	if not pet then return pet end

	-- Update jump settings attributes
	for key, value in pairs(newSettings) do
		pet:SetAttribute("jump_" .. key, value)
	end

	-- Find and restart the jump script
	local jumpScript = pet:FindFirstChild("PetJump")
	if jumpScript then
		jumpScript.Disabled = true
		wait(0.1)
		jumpScript.Disabled = false
	end

	return pet
end

return PetJumpModule
]]

-- Define the source for the PetInitializer
local petInitializerSource = [[
-- PetInitializer.lua
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
]]

-- Create the modules
createModuleScript(Modules, "PetMovementModule", petMovementSource)
createModuleScript(Modules, "PetJumpModule", petJumpSource)
createModuleScript(ServerScriptService, "PetInitializer", petInitializerSource)

-- Check if the scripts were created successfully
if not Modules:FindFirstChild("PetMovementModule") or 
	not Modules:FindFirstChild("PetJumpModule") or 
	not ServerScriptService:FindFirstChild("PetInitializer") then
	warn("Some modules failed to create properly!")
end

-- Create the updated pet spawner script
local updatedPetSpawnerSource = [[
-- Updated PetSpawner.server.lua
-- Modified to use the centralized pet modules
print("Running updated pet spawner")

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for modules to be available
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PetInitializer = require(ServerScriptService:WaitForChild("PetInitializer"))

-- DIAGNOSTIC FUNCTION
local function DEBUG_LOG(message)
    print("PET_SPAWNER_DEBUG: " .. message)
end

-- Main spawning code goes here (abbreviated)
DEBUG_LOG("Initializing pet system with centralized modules")

-- Make sure Areas folder exists
if not workspace:FindFirstChild("Areas") then
    local areasFolder = Instance.new("Folder")
    areasFolder.Name = "Areas"
    areasFolder.Parent = workspace
    DEBUG_LOG("Created Areas folder in workspace")
end

-- Basic starter area if needed
if not workspace.Areas:FindFirstChild("Starter Meadow") then
    local starterArea = Instance.new("Folder")
    starterArea.Name = "Starter Meadow"
    starterArea.Parent = workspace.Areas
    
    local petsFolder = Instance.new("Folder")
    petsFolder.Name = "Pets"
    petsFolder.Parent = starterArea
    
    DEBUG_LOG("Created basic Starter Meadow area")
end

-- Create a test pet to verify the system works
local function createTestPet()
    local testPet = PetInitializer.CreateBasicPetModel(
        "Test Corgi", 
        "Corgi", 
        Vector3.new(0, 10, 0)
    )
    
    testPet:SetAttribute("PetType", "Common Corgi")
    testPet:SetAttribute("Rarity", "Common") 
    testPet:SetAttribute("Value", 1)
    
    PetInitializer.SetupPet(testPet)
    
    testPet.Parent = workspace.Areas["Starter Meadow"].Pets
    
    DEBUG_LOG("Created test pet to verify system")
end

-- If in Studio, create a test pet
if RunService:IsStudio() then
    createTestPet()
end

DEBUG_LOG("Updated pet system initialized")
]]

-- Create or update the PetSpawner script
local existingSpawner = ServerScriptService:FindFirstChild("PetSpawner")
if existingSpawner then
	-- Rename the old one for backup
	existingSpawner.Name = "PetSpawner_Original"
	print("Renamed original PetSpawner to PetSpawner_Original for backup")
end

local newSpawner = Instance.new("Script")
newSpawner.Name = "PetSpawner"
newSpawner.Source = updatedPetSpawnerSource
newSpawner.Parent = ServerScriptService
print("Created updated PetSpawner script")

print("Module Initialization complete!")