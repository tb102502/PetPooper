-- PetMovementModule.lua
-- Place this in ReplicatedStorage/Modules/
-- Centralized module for pet movement behaviors

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
	idleMovementChance = 0.1
}

-- Function to initialize a pet with movement behavior
function PetMovementModule.initPet(pet, movementConfig)
	if not pet then return pet end

	-- Merge settings with defaults
	movementConfig = movementConfig or {}
	for key, defaultValue in pairs(PetMovementModule.DefaultConfig) do
		if movementConfig[key] == nil then
			movementConfig[key] = defaultValue
		end
	end

	-- Store settings on the pet as attributes
	for key, value in pairs(movementConfig) do
		pet:SetAttribute("movement_" .. key, value)
	end

	-- Reference to the template script
	local ServerScriptService = game:GetService("ServerScriptService")
	local templatesFolder = ServerScriptService:FindFirstChild("PetTemplates")
	if not templatesFolder then
		warn("PetTemplates folder not found!")
		return pet
	end

	-- Find the movement script template
	local movementTemplate = templatesFolder:FindFirstChild("MovementScript")
	if not movementTemplate then
		warn("MovementScript template not found!")
		return pet
	end

	-- Clone the template script and add to pet
	local newScript = movementTemplate:Clone()
	newScript.Name = "PetMovement"
	newScript.Enabled = true
	newScript.Parent = pet

	return pet
end
-- Paste the original MovementScript code here
function PetMovementModule.adjustMovementSettings(pet, newMovementConfig)
	if not pet then return pet end

	-- Update movement settings attributes
	for key, value in pairs(newMovementConfig) do
		pet:SetAttribute("movement_" .. key, value)
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

-- Other utility functions can be added here

return PetMovementModule