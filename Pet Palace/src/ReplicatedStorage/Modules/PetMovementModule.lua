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
	local movementScript = Instance.new("Script")
	movementScript.Name = "PetMovement"

	-- Paste the original Movement script code here
	movementScript.Source = [[
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

	movementScript.Parent = pet

	-- Return the pet for chaining
	return pet
end

-- Function to change a pet's movement behavior
function PetMovementModule.changeMovement(pet, newMovementType, newConfig)
	if not pet then return end

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

-- Other utility functions can be added here

return PetMovementModule