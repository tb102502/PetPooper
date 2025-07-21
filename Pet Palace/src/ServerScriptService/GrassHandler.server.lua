local Replicated = game:GetService("ReplicatedStorage")
local folder = Replicated:WaitForChild("Events")
local GrassMowed = folder:WaitForChild("GrassMowed")
local Info = TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0);
local Size = {Size = Vector3.new(2,0.4,2)}
local Size1 = {Size = Vector3.new(2,4,2)}
GrassMowed.Event:Connect(function(plr, hit,GrassAmmount)
	local GrassMowed = game:GetService("TweenService"):Create(hit, Info, Size)
	local GrassRegen = game:GetService("TweenService"):Create(hit,Info,Size1)
	GrassMowed:Play()
	task.wait(require(Replicated.GameConfig).GrassCD)
	GrassRegen:Play()
end)
