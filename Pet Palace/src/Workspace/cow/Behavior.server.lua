local cow = script.Parent
local humanoid = cow.Humanoid
local rootpart = cow.HumanoidRootPart

while true do
	if math.random(1, 7) == 1 then
		humanoid.Sit = true
		wait(math.random(20, 60))
		humanoid.Sit = false
	else
		humanoid:MoveTo(rootpart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
		wait(math.random(5, 10))
	end
end