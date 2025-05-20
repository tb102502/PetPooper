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