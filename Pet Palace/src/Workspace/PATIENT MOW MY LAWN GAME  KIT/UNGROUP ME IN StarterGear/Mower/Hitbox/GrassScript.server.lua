local Replicated = game:GetService("ReplicatedStorage")
local folder = Replicated:WaitForChild("Events")
local GrassMowed = folder:WaitForChild("GrassMowed")
local GrassAMT = require(script.Parent.Parent:WaitForChild("MowerConfig"))
local plr = script.Parent.Parent.Parent.Parent
script.Parent.Touched:Connect(function(hit)
	if hit.Name == "Grass" then
		if hit.Size == Vector3.new(2,4,2) then		
plr.leaderstats.Trimmings.Value += require(script.Parent.Parent.MowerConfig).TrimmingsPerGrass
				GrassMowed:Fire(GrassAMT.TrimmingsPerGrass, hit)
				
			end
		end
end)