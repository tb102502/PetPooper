local animation = script:WaitForChild('Normal')
local humanoid = script.Parent:WaitForChild('Humanoid')
local origSpeed = script.Parent.Humanoid.WalkSpeed
local chaseSpeed = script.Parent.ChaseWalkspeed.Value
local dance = humanoid:LoadAnimation(animation)
dance:Play()
local dance2

if script.Parent.ChangeAnim.Value then
	local animation2 = script.Parent.ChangeAnim:WaitForChild("Chase")
	dance2 = humanoid:LoadAnimation(animation2)
end
script.Parent.Chasing.Changed:Connect(function()
	if script.Parent.ChangeAnim.Value then
		if script.Parent.Chasing.Value == true then
			script.Parent.Humanoid.WalkSpeed = chaseSpeed
			dance:Stop()
			dance2:Play()
		else
			script.Parent.Humanoid.WalkSpeed = origSpeed
			dance:Play()
			dance2:Stop()
		end
	else
		if script.Parent.Chasing.Value == true then
			script.Parent.Humanoid.WalkSpeed = chaseSpeed
			dance:AdjustSpeed(1.5)
		else
			script.Parent.Humanoid.WalkSpeed = origSpeed
			dance:AdjustSpeed(1)
		end
	end
end)